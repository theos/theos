"""Independently inspect a produced .deb without relying on the build's own helpers.

Usage: python tests/windows/verify_package.py <path-to-deb> [--extract DIR] [--ldid ldid.exe]
                                              [--objdump llvm-objdump.exe]

Checks the Debian member layout, control metadata, tar ownership/mode metadata,
the payload dylib's Mach-O architecture, and its embedded code signature.
"""

import argparse
import hashlib
import io
import pathlib
import subprocess
import sys
import tarfile
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "bin"))
import importlib.util  # noqa: E402

_spec = importlib.util.spec_from_file_location("theos_windows", ROOT / "bin" / "theos-windows.py")
windows = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(windows)

def macho_header(ncmds=0, sizeofcmds=0):
    """Minimal 32-byte 64-bit Mach-O header (ARM64, MH_DYLIB)."""
    return (
        b"\xcf\xfa\xed\xfe"
        + (0x0100000C).to_bytes(4, "little")  # CPU_TYPE_ARM64
        + (0).to_bytes(4, "little")  # CPU_SUBTYPE_ARM64_ALL
        + (6).to_bytes(4, "little")  # MH_DYLIB
        + (ncmds).to_bytes(4, "little")
        + (sizeofcmds).to_bytes(4, "little")
        + (0).to_bytes(4, "little")  # flags
        + (0).to_bytes(4, "little")  # reserved
    )


# Negative controls: a valid ARM64 image with no load commands at all, and one
# carrying a LC_CODE_SIGNATURE command (used to prove the check has teeth).
UNSIGNED_HEADER = macho_header()
SIGNED_HEADER = (
    macho_header(1, 16) + (0x1D).to_bytes(4, "little") + (16).to_bytes(4, "little") + (0).to_bytes(8, "little")
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("package")
    parser.add_argument("--extract", default="")
    parser.add_argument("--ldid", default="ldid")
    parser.add_argument("--objdump", default="")
    parser.add_argument("--expect-arch", default="arm64")
    parser.add_argument("--expect-path", default="Library/MobileSubstrate/DynamicLibraries")
    arguments = parser.parse_args()

    raw = pathlib.Path(arguments.package).read_bytes()
    print(f"package: {arguments.package}")
    print(f"sha256: {hashlib.sha256(raw).hexdigest()}")
    print(f"size: {len(raw)} bytes")

    members = windows.read_ar_members(raw)
    print(f"ar members: {sorted(members)}")
    assert set(members) == {"debian-binary", "control.tar.gz", "data.tar.gz"}, "unexpected ar layout"
    assert members["debian-binary"] == b"2.0\n", "debian-binary must be 2.0"
    print("debian-binary: 2.0  OK")

    with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
        control_names = control.getnames()
        assert "control" in control_names, "DEBIAN/control missing"
        text = control.extractfile("control").read().decode("utf-8-sig")
        print(f"control files: {control_names}")
        print("--- control ---")
        print(text.strip())
        fields = {line.split(":", 1)[0].strip().casefold() for line in text.splitlines() if ":" in line}
        assert {"package", "version", "architecture"}.issubset(fields), "control fields incomplete"
        for member in control.getmembers():
            assert (member.uid, member.gid) == (0, 0), f"{member.name} is not root-owned"
        control_member = control.getmember("control")
        assert control_member.mode & 0o7777 == 0o644, (
            f"DEBIAN/control mode {oct(control_member.mode & 0o7777)} must be 0644"
        )

    dylib_member = None
    payload = None
    with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
        print("--- data members ---")
        for member in data.getmembers():
            print(
                f"  {member.name:<58} mode={oct(member.mode & 0o7777)} "
                f"{member.uid}:{member.gid} {member.uname}:{member.gname} size={member.size}"
            )
            assert (member.uid, member.gid) == (0, 0), f"{member.name} is not root-owned"
            assert member.uname in ("root", ""), f"{member.name} owner name invalid"
            if member.isdir():
                assert member.mode & 0o111, f"{member.name} directory is not traversable"
            if member.name.endswith(".dylib"):
                dylib_member = member
            if member.name.endswith(".plist"):
                assert member.mode & 0o7777 == 0o644, f"{member.name} mode must be 0644"
        assert dylib_member is not None, "no dylib in payload"
        # Scheme agnostic: rootful installs at Library/..., rootless under var/jb/.
        marker = f"{arguments.expect_path}/"
        assert marker in dylib_member.name, (
            f"dylib must install under {arguments.expect_path} (got {dylib_member.name})"
        )
        scheme_prefix = dylib_member.name.split(marker, 1)[0]
        assert dylib_member.mode & 0o111, "installed dylib must be executable"
        payload = data.extractfile(dylib_member).read()
        plists = [m.name for m in data.getmembers() if m.name.endswith(".plist")]
        kind = "rootful" if not scheme_prefix else "rootless"
        print(f"install prefix: '{scheme_prefix}' ({kind})")
        print(f"installed dylib: {dylib_member.name} ({len(payload)} bytes)")
        print(f"payload plists: {plists}")

    if arguments.extract:
        destination = pathlib.Path(arguments.extract)
        windows.extract_tar_bytes(members["control.tar.gz"], destination / "DEBIAN")
        windows.extract_tar_bytes(members["data.tar.gz"], destination)
        print(f"extracted to: {destination}")

    work = pathlib.Path(tempfile.mkdtemp())
    probe = work / pathlib.Path(dylib_member.name).name
    probe.write_bytes(payload)

    check = subprocess.run(
        [sys.executable, str(ROOT / "bin" / "theos-windows.py"), "macho-check", str(probe),
         "--arch", arguments.expect_arch, "--require-signature"],
        capture_output=True,
    )
    print(f"macho-check {arguments.expect_arch} + LC_CODE_SIGNATURE: "
          f"rc={check.returncode} {check.stdout.decode().strip()}")
    assert check.returncode == 0, check.stderr.decode() or "payload is not a signed ARM64 image"

    signed = subprocess.run([arguments.ldid, "-e", str(probe)], capture_output=True)
    print(f"ldid -e (packaged dylib): rc={signed.returncode} stderr={signed.stderr.decode().strip()[:120]}")
    assert signed.returncode == 0, "packaged dylib has no readable code signature"

    # Negative control: the same checks must fail for an unsigned Mach-O image.
    unsigned = work / "unsigned.dylib"
    unsigned.write_bytes(UNSIGNED_HEADER)
    control = subprocess.run([arguments.ldid, "-e", str(unsigned)], capture_output=True)
    print(f"ldid -e (unsigned control): rc={control.returncode}")
    assert control.returncode != 0, "signature check does not detect unsigned images"

    no_signature = subprocess.run(
        [sys.executable, str(ROOT / "bin" / "theos-windows.py"), "macho-check", str(unsigned),
         "--arch", arguments.expect_arch, "--require-signature"],
        capture_output=True,
    )
    print(f"macho-check --require-signature (unsigned control): rc={no_signature.returncode}")
    assert no_signature.returncode != 0, "LC_CODE_SIGNATURE check does not detect unsigned images"

    has_signature = work / "signed-header.dylib"
    has_signature.write_bytes(SIGNED_HEADER)
    positive = subprocess.run(
        [sys.executable, str(ROOT / "bin" / "theos-windows.py"), "macho-check", str(has_signature),
         "--arch", arguments.expect_arch, "--require-signature"],
        capture_output=True,
    )
    print(f"macho-check --require-signature (synthetic signed control): rc={positive.returncode}")
    assert positive.returncode == 0, "LC_CODE_SIGNATURE check rejects a signed image"

    if arguments.objdump:
        headers = subprocess.run([arguments.objdump, "--macho", "--private-headers", str(probe)], capture_output=True)
        present = b"LC_CODE_SIGNATURE" in headers.stdout
        print(f"llvm-objdump LC_CODE_SIGNATURE cross-check: {present}")
        assert present, "no LC_CODE_SIGNATURE load command"

    print("ALL PACKAGE CHECKS PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
