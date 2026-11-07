#!/usr/bin/env python3
"""Check a POSIX-built gzip Debian tweak package and its signed Mach-O payload."""
import argparse
import hashlib
import io
import pathlib
import subprocess
import sys
import tarfile
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests" / "windows"))
from verify_package import windows  # Uses the existing ar and Mach-O reader.

parser = argparse.ArgumentParser()
parser.add_argument("package", type=pathlib.Path)
parser.add_argument("--ldid", required=True)
parser.add_argument("--scheme", choices=("rootful", "rootless"), required=True)
args = parser.parse_args()
raw = args.package.read_bytes()
print("sha256:", hashlib.sha256(raw).hexdigest())
parts = windows.read_ar_members(raw)
assert parts["debian-binary"] == b"2.0\n"
assert "control.tar.gz" in parts and "data.tar.gz" in parts
with tarfile.open(fileobj=io.BytesIO(parts["control.tar.gz"]), mode="r:gz") as archive:
    entries = {m.name.removeprefix("./"): m for m in archive.getmembers()}
    control = archive.extractfile(entries["control"]).read().decode()
    for field in ("Package:", "Version:", "Architecture:"):
        assert any(line.startswith(field) for line in control.splitlines()), field
    assert all((m.uid, m.gid) == (0, 0) for m in archive.getmembers())
with tarfile.open(fileobj=io.BytesIO(parts["data.tar.gz"]), mode="r:gz") as archive:
    entries = {m.name.removeprefix("./"): m for m in archive.getmembers()}
    prefix = ("var/jb/" if args.scheme == "rootless" else "") + "Library/MobileSubstrate/DynamicLibraries/"
    dylibs = [m for name, m in entries.items() if name.startswith(prefix) and name.endswith(".dylib")]
    assert len(dylibs) == 1, f"expected one dylib under {prefix}"
    assert all((m.uid, m.gid) == (0, 0) for m in archive.getmembers())
    assert dylibs[0].mode & 0o111
    payload = archive.extractfile(dylibs[0]).read()
with tempfile.TemporaryDirectory() as directory:
    dylib = pathlib.Path(directory) / "probe.dylib"
    dylib.write_bytes(payload)
    subprocess.run([sys.executable, str(ROOT / "bin" / "theos-windows.py"), "macho-check", str(dylib), "--arch", "arm64", "--require-signature"], check=True)
    subprocess.run([args.ldid, "-e", str(dylib)], check=True, stdout=subprocess.DEVNULL)
print(f"PASS: {args.scheme} ARM64 signed package")
