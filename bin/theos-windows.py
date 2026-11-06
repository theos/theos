#!/usr/bin/env python3
"""Native Windows host helpers used by Theos make recipes."""
import argparse
import glob
import gzip
import hashlib
import io
import json
import os
import plistlib
import re
import shutil
import shlex
import subprocess
import tarfile
import time
import zipfile
import sys
from pathlib import Path


def path(value):
    return Path(value).expanduser()


def control_field(filename, name):
    for line in path(filename).read_text(encoding="utf-8-sig").splitlines():
        key, sep, value = line.partition(":")
        if sep and key.strip().casefold() == name.casefold():
            return value.strip()
    raise KeyError(f"control field not found: {name}")


_DEBIAN_MAINTAINER_SCRIPTS = {"preinst", "postinst", "prerm", "postrm", "extrainst_"}
_EXECUTABLE_SUFFIXES = {".dylib", ".so", ".bundle"}
_MACHO_MAGICS = {
    b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xcf", b"\xfe\xed\xfa\xce",
    b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca",
}
# MH_EXECUTE, MH_DYLIB, MH_BUNDLE
_MACHO_EXECUTABLE_FILE_TYPES = {0x2, 0x6, 0x8}
_ROOTTREE_UID = 0
_ROOTTREE_GID = 0


def macho_file_type(header):
    """Return the Mach-O file type from a header prefix, or None if not Mach-O."""
    if len(header) < 16 or header[:4] not in _MACHO_MAGICS:
        return None
    if header[:4] in (b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe"):
        return int.from_bytes(header[12:16], "little")
    if header[:4] in (b"\xfe\xed\xfa\xcf", b"\xfe\xed\xfa\xce"):
        return int.from_bytes(header[12:16], "big")
    # Fat archives carry executable slices; treat them as executable.
    return 0x2


def default_file_mode(name, source=None):
    """Deterministic mode for a packaged path.

    Windows has no POSIX ownership database, so the native packager derives the
    modes that Theos' Bash fakeroot would have exposed to dpkg-deb/dm.pl:
    Debian control data stays 0644, maintainer scripts stay executable, and any
    installed Mach-O executable/dylib/bundle is installed executable.
    """
    directory, _, base = name.rpartition("/")
    if directory in ("DEBIAN", "") and base in _DEBIAN_MAINTAINER_SCRIPTS:
        return 0o755
    if name in ("control", "DEBIAN/control"):
        return 0o644
    if source is not None:
        try:
            with source.open("rb") as stream:
                header = stream.read(16)
        except OSError:
            header = b""
        if macho_file_type(header) in _MACHO_EXECUTABLE_FILE_TYPES:
            return 0o755
    if path(name).suffix.casefold() in _EXECUTABLE_SUFFIXES:
        return 0o755
    return 0o644


def load_metadata_manifest(filename):
    """Load an optional staging metadata manifest produced by `fakeroot`."""
    if not filename:
        return {}
    source = path(filename)
    if not source.is_file():
        return {}
    try:
        data = json.loads(source.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}
    entries = data.get("paths", data) if isinstance(data, dict) else {}
    if not isinstance(entries, dict):
        return {}
    manifest = {}
    for name, entry in entries.items():
        if not isinstance(entry, dict):
            continue
        manifest[str(name).replace("\\", "/")] = entry
    return manifest


def staging_metadata(root):
    """Record the metadata the Windows packager will write for a staging tree."""
    root_path = path(root).resolve()
    entries = {}
    for item in sorted(root_path.rglob("*"), key=lambda value: value.relative_to(root_path).as_posix()):
        name = item.relative_to(root_path).as_posix()
        if name.split("/")[0] == "_theos_fakeroot.json":
            continue
        if item.is_dir():
            entries[name] = {"type": "dir", "mode": 0o755, "uid": _ROOTTREE_UID, "gid": _ROOTTREE_GID}
        elif item.is_symlink():
            entries[name] = {"type": "symlink", "mode": 0o777, "uid": _ROOTTREE_UID, "gid": _ROOTTREE_GID}
        elif item.is_file():
            entries[name] = {"type": "file", "mode": default_file_mode(name, item), "uid": _ROOTTREE_UID, "gid": _ROOTTREE_GID}
    return entries


def tar_gz_bytes(root, include_control=False, manifest=None, compresslevel=9):
    """Build a deterministic gzipped tar with explicit POSIX metadata.

    Directory entries (including empty directories) and symlinks are emitted so
    the archive matches what dm.pl/dpkg-deb would produce under fakeroot.
    """
    root_path = path(root).resolve()
    manifest = manifest or {}
    level = max(0, min(9, compresslevel))
    buffer = io.BytesIO()
    with gzip.GzipFile(fileobj=buffer, mode="wb", compresslevel=level, mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode="w", format=tarfile.GNU_FORMAT) as archive:
            for item in sorted(root_path.rglob("*"), key=lambda value: value.relative_to(root_path).as_posix()):
                relative = item.relative_to(root_path)
                if not include_control and relative.parts[0] == "DEBIAN":
                    continue
                name = relative.as_posix()
                override = manifest.get(name) or {}
                info = tarfile.TarInfo(name)
                info.uid = _ROOTTREE_UID
                info.gid = _ROOTTREE_GID
                info.uname = "root"
                info.gname = "wheel"
                info.mtime = 0
                if item.is_dir():
                    info.type = tarfile.DIRTYPE
                    info.mode = int(override.get("mode", 0o755))
                    info.size = 0
                    archive.addfile(info)
                elif item.is_symlink():
                    info.type = tarfile.SYMTYPE
                    info.mode = int(override.get("mode", 0o777))
                    info.size = 0
                    info.linkname = os.readlink(item)
                    archive.addfile(info)
                elif item.is_file():
                    info.type = tarfile.REGTYPE
                    info.mode = int(override.get("mode", default_file_mode(name, item)))
                    info.size = item.stat().st_size
                    with item.open("rb") as stream:
                        archive.addfile(info, stream)
    return buffer.getvalue()


def ar_member(name, data):
    encoded = name.encode("ascii")[:16].ljust(16, b" ")
    header = encoded + f"0           0     0     100644  {len(data):>10}`\n".encode("ascii")
    return header + data + (b"\n" if len(data) % 2 else b"")


def optimize_plists(directory):
    """Convert XML plists to binary plists, matching bin/convert_xml_plist.sh.

    The POSIX script is a no-op when plutil/plistutil/ply are missing; plistlib
    provides the same conversion natively so the step still does its job here.
    Files that are not plists (for example .strings) are left untouched.
    """
    root = path(directory)
    converted = 0
    for item in sorted(root.rglob("*")):
        if not item.is_file() or item.suffix.casefold() not in (".plist", ".strings"):
            continue
        try:
            data = item.read_bytes()
        except OSError:
            continue
        if data.startswith(b"bplist"):
            continue
        try:
            value = plistlib.loads(data)
            item.write_bytes(plistlib.dumps(value, fmt=plistlib.FMT_BINARY, sort_keys=False))
            converted += 1
        except (OSError, ValueError, TypeError):
            continue
    return converted


def read_ar_members(raw):
    """Parse a Debian `ar` archive into an ordered {name: payload} mapping."""
    if not raw.startswith(b"!<arch>\n"):
        raise ValueError("not a Debian ar archive")
    members, offset = {}, 8
    while offset < len(raw):
        if offset + 60 > len(raw) or raw[offset + 58:offset + 60] != b"`\n":
            raise ValueError("invalid ar member")
        name = raw[offset:offset + 16].decode("ascii").strip().rstrip("/")
        try:
            size = int(raw[offset + 48:offset + 58].decode("ascii").strip())
        except ValueError as error:
            raise ValueError("invalid ar member size") from error
        start = offset + 60
        end = start + size
        padded_end = end + (size % 2)
        if end > len(raw) or padded_end > len(raw):
            raise ValueError("truncated ar member")
        if name in members:
            raise ValueError(f"duplicate ar member: {name}")
        members[name] = raw[start:end]
        offset = padded_end
    return members


def extract_tar_bytes(data, destination):
    """Extract an in-memory tar safely, rejecting traversal and links."""
    root = path(destination).resolve()
    root.mkdir(parents=True, exist_ok=True)
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:*") as bundle:
        for member in bundle.getmembers():
            target = (root / member.name).resolve()
            if target != root and root not in target.parents:
                raise ValueError(f"archive member escapes destination: {member.name}")
            if member.issym() or member.islnk():
                raise ValueError(f"archive links are not allowed: {member.name}")
        bundle.extractall(root)


def extract_tar_safe(archive, destination):
    root = path(destination).resolve()
    with tarfile.open(archive, mode="r:*") as bundle:
        members = bundle.getmembers()
        for member in members:
            target = (root / member.name).resolve()
            if target != root and root not in target.parents:
                raise ValueError(f"archive member escapes destination: {member.name}")
            if member.issym() or member.islnk():
                raise ValueError(f"archive links are not allowed: {member.name}")
        bundle.extractall(root)


_CANONICAL_COMMANDS = {"cp": ("copy",), "mv": ("move",)}


def canonical_command(name):
    """Map a subcommand alias to its canonical name.

    argparse stores the alias as typed in `args.command`, so dispatching on the
    canonical name alone would silently skip aliased subcommands.
    """
    for canonical, alias_names in _CANONICAL_COMMANDS.items():
        if name in alias_names:
            return canonical
    return name


def main(argv=None):
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    mkdir = sub.add_parser("mkdir"); mkdir.add_argument("paths", nargs="+")
    remove = sub.add_parser("rm"); remove.add_argument("-r", "--recursive", action="store_true"); remove.add_argument("-f", "--force", action="store_true"); remove.add_argument("paths", nargs="+")
    touch = sub.add_parser("touch"); touch.add_argument("paths", nargs="+")
    copy = sub.add_parser("cp", aliases=list(_CANONICAL_COMMANDS["cp"])); copy.add_argument("--exclude", action="append", default=[]); copy.add_argument("--merge", action="store_true"); copy.add_argument("--ignore-missing", action="store_true"); copy.add_argument("source"); copy.add_argument("destination")
    move = sub.add_parser("mv", aliases=list(_CANONICAL_COMMANDS["mv"])); move.add_argument("source"); move.add_argument("destination")
    read = sub.add_parser("read"); read.add_argument("path")
    field = sub.add_parser("control-field"); field.add_argument("path"); field.add_argument("name")
    control = sub.add_parser("control-file"); control.add_argument("source"); control.add_argument("destination"); control.add_argument("--architecture", required=True); control.add_argument("--version", required=True); control.add_argument("--stage", required=True); control.add_argument("--libswift", default=""); control.add_argument("--libswift-version", default=""); control.add_argument("--orion", default="")
    size = sub.add_parser("installed-size"); size.add_argument("path")
    hash_cmd = sub.add_parser("hash"); hash_cmd.add_argument("algorithm", choices=sorted(hashlib.algorithms_available), default="md5"); hash_cmd.add_argument("path", nargs="?"); hash_cmd.add_argument("--length", type=int, default=0); hash_cmd.add_argument("--value")
    exists = sub.add_parser("exists"); exists.add_argument("path"); exists.add_argument("--kind", choices=["any", "file", "dir"], default="any")
    which = sub.add_parser("which"); which.add_argument("executable")
    tool_version = sub.add_parser("tool-version"); tool_version.add_argument("executable"); tool_version.add_argument("arguments", nargs=argparse.REMAINDER)
    pe_info = sub.add_parser("pe-info"); pe_info.add_argument("path")
    macho = sub.add_parser("macho-check"); macho.add_argument("path"); macho.add_argument("--arch", choices=["arm64", "arm64e"], default="arm64"); macho.add_argument("--require-signature", action="store_true")
    sdk = sub.add_parser("sdk-info"); sdk.add_argument("path"); sdk.add_argument("--platform", default="iPhoneOS"); sdk.add_argument("--version-only", action="store_true")
    compile_probe = sub.add_parser("compile-probe"); compile_probe.add_argument("compiler", nargs="?"); compile_probe.add_argument("output_dir"); compile_probe.add_argument("--arch", choices=["arm64", "arm64e"], default="arm64")
    check_files = sub.add_parser("check-files"); check_files.add_argument("paths", nargs="+")
    copy_list = sub.add_parser("copy-list"); copy_list.add_argument("--destination", required=True); copy_list.add_argument("paths", nargs="+")
    extract = sub.add_parser("extract"); extract.add_argument("archive"); extract.add_argument("destination")
    target_args = sub.add_parser("target-args"); target_args.add_argument("value")
    sort_versions = sub.add_parser("sort-versions"); sort_versions.add_argument("values", nargs="+")
    package_version = sub.add_parser("package-version"); package_version.add_argument("project_dir"); package_version.add_argument("data_dir"); package_version.add_argument("package"); package_version.add_argument("version")
    subprojects = sub.add_parser("subprojects"); subprojects.add_argument("--make", required=True); subprojects.add_argument("--makefile", required=True); subprojects.add_argument("--operation", required=True); subprojects.add_argument("--instance-type", default=""); subprojects.add_argument("--instance", default=""); subprojects.add_argument("--build-dir", required=True); subprojects.add_argument("--makeflags", default=""); subprojects.add_argument("--subprojects", nargs="*", default=[]); subprojects.add_argument("--cwd"); subprojects.add_argument("--aggregate", action="store_true"); subprojects.add_argument("--no-keep-going", action="store_true")
    scheme_stage = sub.add_parser("scheme-stage"); scheme_stage.add_argument("stage"); scheme_stage.add_argument("scheme_stage"); scheme_stage.add_argument("staging_tmp")
    logos = sub.add_parser("logos"); logos.add_argument("--perl", default="perl"); logos.add_argument("--script", required=True); logos.add_argument("--output", required=True); logos.add_argument("--flags", default=""); logos.add_argument("source")
    ipa = sub.add_parser("ipa"); ipa.add_argument("stage"); ipa.add_argument("output"); ipa.add_argument("--compression", type=int, default=6)
    rpm_spec = sub.add_parser("rpm-spec"); rpm_spec.add_argument("source"); rpm_spec.add_argument("destination"); rpm_spec.add_argument("--release", default=""); rpm_spec.add_argument("--append-files", action="store_true")
    sign_tree = sub.add_parser("sign-tree"); sign_tree.add_argument("root"); sign_tree.add_argument("signer"); sign_tree.add_argument("flags", nargs=argparse.REMAINDER)
    remove_glob = sub.add_parser("remove-glob"); remove_glob.add_argument("root"); remove_glob.add_argument("pattern")
    deb = sub.add_parser("deb"); deb.add_argument("stage"); deb.add_argument("output"); deb.add_argument("--compression", type=int, default=9); deb.add_argument("--manifest", default="")
    deb_info = sub.add_parser("deb-info"); deb_info.add_argument("path")
    deb_extract = sub.add_parser("deb-extract"); deb_extract.add_argument("path"); deb_extract.add_argument("--control", required=True); deb_extract.add_argument("--data", required=True)
    codesign = sub.add_parser("codesign"); codesign.add_argument("--signer", required=True); codesign.add_argument("--flags", default=""); codesign.add_argument("path")
    plists = sub.add_parser("optimize-plists"); plists.add_argument("--directory", required=True)
    fakeroot = sub.add_parser("fakeroot"); fakeroot.add_argument("--persistence", required=True); fakeroot.add_argument("-c", "--clear", action="store_true"); fakeroot.add_argument("-r", "--required", action="store_true"); fakeroot.add_argument("--record-stage", default=""); fakeroot.add_argument("arguments", nargs=argparse.REMAINDER)
    run = sub.add_parser("run"); run.add_argument("executable"); run.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)
    args.command = canonical_command(args.command)
    try:
        if args.command == "mkdir":
            for item in args.paths: path(item).mkdir(parents=True, exist_ok=True)
        elif args.command == "rm":
            for pattern in args.paths:
                matches = glob.glob(pattern) or ([] if args.force else [pattern])
                for item in matches:
                    target = path(item)
                    if not target.exists() and not target.is_symlink():
                        if not args.force: raise FileNotFoundError(str(target))
                    elif target.is_dir() and not target.is_symlink():
                        shutil.rmtree(target) if args.recursive else target.rmdir()
                    else: target.unlink()
        elif args.command == "touch":
            for item in args.paths:
                target = path(item); target.parent.mkdir(parents=True, exist_ok=True); target.touch(exist_ok=True)
        elif args.command in ("cp", "copy"):
            src, dst = path(args.source), path(args.destination)
            if not src.exists():
                # Mirrors the POSIX staging recipe's `[ -d layout ] && … || true`
                # tolerance for optional trees such as an absent layout/ directory.
                if args.ignore_missing: return 0
                raise ValueError(f"source does not exist: {src}")
            if src.is_dir():
                root = dst if args.merge else dst / src.name
                root.mkdir(parents=True, exist_ok=True)
                for item in src.iterdir():
                    if item.name in args.exclude: continue
                    target = root / item.name
                    shutil.copytree(item, target, dirs_exist_ok=True) if item.is_dir() else shutil.copy2(item, target)
            else:
                if dst.is_dir() or str(args.destination).endswith(("/", "\\")):
                    dst = dst / src.name
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
        elif args.command == "mv":
            source, destination = path(args.source), path(args.destination)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(source), str(destination))
        elif args.command == "read":
            sys.stdout.write(path(args.path).read_text(encoding="utf-8-sig").rstrip("\r\n"))
        elif args.command == "control-field": print(control_field(args.path, args.name))
        elif args.command == "control-file":
            source = path(args.source).read_text(encoding="utf-8-sig")
            values = {"${LIBSWIFT}": args.libswift, "${LIBSWIFT_VERSION}": args.libswift_version, "${ORION}": args.orion}
            lines = []
            for line in source.splitlines():
                key = line.partition(":")[0].strip().casefold()
                if key in ("version", "architecture"): continue
                for old, new in values.items(): line = line.replace(old, new)
                if line.strip(): lines.append(line)
            lines += [f"Architecture: {args.architecture}", f"Version: {args.version}", f"Installed-Size: {sum(p.stat().st_size for p in path(args.stage).rglob('*') if p.is_file()) // 1024}"]
            destination = path(args.destination); destination.parent.mkdir(parents=True, exist_ok=True); destination.write_text("\n".join(lines) + "\n", encoding="utf-8")
        elif args.command == "installed-size": print((sum(p.stat().st_size for p in path(args.path).rglob("*") if p.is_file()) + 1023) // 1024)
        elif args.command == "hash":
            if args.value is not None:
                digest_text = hashlib.new(args.algorithm, args.value.encode()).hexdigest()
            else:
                digest = hashlib.new(args.algorithm)
                source = open(args.path, "rb") if args.path else sys.stdin.buffer
                if args.path:
                    with source as stream:
                        for chunk in iter(lambda: stream.read(1048576), b""): digest.update(chunk)
                else:
                    for chunk in iter(lambda: source.read(1048576), b""): digest.update(chunk)
                digest_text = digest.hexdigest()
            print(digest_text[:args.length] if args.length else digest_text)
        elif args.command == "exists":
            target = path(args.path); ok = target.exists() if args.kind == "any" else target.is_file() if args.kind == "file" else target.is_dir()
            return 0 if ok else 1
        elif args.command == "compile-probe":
            compiler = args.compiler or shutil.which("clang")
            if not compiler: raise ValueError("native clang was not found")
            out = path(args.output_dir); out.mkdir(parents=True, exist_ok=True)
            target = f"{args.arch}-apple-ios13.0"
            fixtures = [("probe.c", "int c_probe(void) { return 1; }\n"), ("probe.cpp", "int cpp_probe() { return 2; }\n"), ("probe.m", "int objc_probe(void) { return 3; }\n"), ("probe.mm", "int objcpp_probe() { return 4; }\n")]
            for filename, source in fixtures:
                src, obj = out / filename, out / (filename + ".o")
                src.write_text(source, encoding="utf-8")
                result = subprocess.run([compiler, "-target", target, "-c", str(src), "-o", str(obj)], capture_output=True, text=True, check=False)
                if result.returncode: raise ValueError(f"clang failed for {filename}: {result.stderr.strip()}")
                data = obj.read_bytes()
                if len(data) < 12: raise ValueError(f"clang output is truncated: {obj}")
                magic = data[:4]
                if magic not in (b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf"):
                    raise ValueError(f"clang did not produce Mach-O for {filename}")
                endian = "little" if magic == b"\xcf\xfa\xed\xfe" else "big"
                cpu = int.from_bytes(data[4:8], endian)
                subtype = int.from_bytes(data[8:12], endian) & 0xff
                if cpu != 0x0100000C or subtype != (2 if args.arch == "arm64e" else 0):
                    raise ValueError(f"unexpected Mach-O architecture in {obj}: cpu=0x{cpu:x} subtype={subtype}")
                print(f"PASS: {filename} -> Mach-O {args.arch}")
        elif args.command == "sdk-info":
            sdk_root = path(args.path)
            required = [sdk_root / "usr" / "include", sdk_root / "usr" / "lib"]
            if not sdk_root.is_dir() or any(not item.is_dir() for item in required):
                raise ValueError(f"invalid {args.platform} SDK: expected usr/include and usr/lib")
            libraries = list((sdk_root / "usr" / "lib").glob("libSystem.tbd")) + list((sdk_root / "usr" / "lib").glob("libSystem.dylib"))
            if not libraries:
                raise ValueError(f"invalid {args.platform} SDK: usr/lib must contain libSystem.tbd or libSystem.dylib")
            frameworks = sdk_root / "System" / "Library" / "Frameworks"
            if not frameworks.is_dir():
                raise ValueError(f"invalid {args.platform} SDK: missing System/Library/Frameworks")
            name = sdk_root.name
            prefix = args.platform.casefold()
            if not name.casefold().startswith(prefix) or not name.casefold().endswith(".sdk"):
                raise ValueError(f"SDK directory must be named {args.platform}<version>.sdk or {args.platform}.sdk")
            version = name[len(args.platform):-4]
            if not version:
                settings = sdk_root / "SDKSettings.plist"
                if not settings.is_file():
                    raise ValueError(f"cannot determine SDK version: missing versioned directory name and {settings.name}")
                with settings.open("rb") as stream:
                    metadata = plistlib.load(stream)
                version = str(metadata.get("Version", metadata.get("CanonicalName", "")))
                version_match = re.search(r"\d+(?:\.\d+)*", version)
                version = version_match.group(0) if version_match else ""
            if not version or any(part == "" or not part.isdigit() for part in version.split(".")):
                raise ValueError(f"invalid SDK version in {name} or SDKSettings.plist")
            if args.version_only:
                print(version)
            else:
                print(f"platform={args.platform}")
                print(f"version={version}")
                print(f"path={sdk_root.resolve()}")
                print(f"include={ (sdk_root / 'usr' / 'include').resolve() }")
                print(f"library={ (sdk_root / 'usr' / 'lib').resolve() }")
                print(f"frameworks={frameworks.resolve()}")
                private_frameworks = sdk_root / "System" / "Library" / "PrivateFrameworks"
                if private_frameworks.is_dir():
                    print(f"private_frameworks={private_frameworks.resolve()}")
        elif args.command == "macho-check":
            data = path(args.path).read_bytes()
            if len(data) < 8: raise ValueError("Mach-O file is truncated")
            magic = data[:4]
            expected = 2 if args.arch == "arm64e" else 0
            arm64_cpu = 0x0100000C
            thin = {b"\xcf\xfa\xed\xfe": "little", b"\xfe\xed\xfa\xcf": "big"}
            fat = {b"\xca\xfe\xba\xbe": ("big", 20), b"\xbe\xba\xfe\xca": ("little", 20), b"\xca\xfe\xba\xbf": ("big", 32), b"\xbf\xba\xfe\xca": ("little", 32)}
            if magic in thin:
                endian = thin[magic]
                if len(data) < 12: raise ValueError("Mach-O header is truncated")
                cpu = int.from_bytes(data[4:8], endian)
                subtype = int.from_bytes(data[8:12], endian, signed=False)
                slices = [(cpu, subtype)]
            elif magic in fat:
                endian, entry_size = fat[magic]
                count = int.from_bytes(data[4:8], endian)
                table_end = 8 + count * entry_size
                if table_end > len(data): raise ValueError("fat Mach-O architecture table is truncated")
                slices = []
                for offset in range(8, table_end, entry_size):
                    cpu = int.from_bytes(data[offset:offset + 4], endian)
                    subtype = int.from_bytes(data[offset + 4:offset + 8], endian, signed=False)
                    slices.append((cpu, subtype))
            else:
                raise ValueError("not a supported Mach-O file")
            if not any(cpu == arm64_cpu and (subtype & 0xff) == expected for cpu, subtype in slices):
                raise ValueError(f"no {args.arch} ARM64 slice found")
            if args.require_signature:
                # LC_CODE_SIGNATURE is what makes an ARM64 image loadable on a
                # device; verify the actual load commands rather than trusting
                # the presence of a signature blob.
                if magic not in thin:
                    raise ValueError("--require-signature requires a thin Mach-O image")
                header_size = 32 if magic in (b"\xcf\xfa\xed\xfe", b"\xfe\xed\xfa\xcf") else 28
                if len(data) < header_size:
                    raise ValueError("Mach-O header is truncated")
                ncmds = int.from_bytes(data[16:20], endian)
                offset = header_size
                for _ in range(ncmds):
                    if offset + 8 > len(data):
                        raise ValueError("Mach-O load commands are truncated")
                    cmd = int.from_bytes(data[offset:offset + 4], endian)
                    size = int.from_bytes(data[offset + 4:offset + 8], endian)
                    if cmd == 0x1D:
                        print("LC_CODE_SIGNATURE")
                        break
                    if size < 8:
                        raise ValueError("Mach-O load command has an invalid size")
                    offset += size
                else:
                    raise ValueError("no LC_CODE_SIGNATURE load command found")
            print(args.arch)
        elif args.command == "which":
            executable = shutil.which(args.executable)
            if executable: print(executable)
            return 0 if executable else 1
        elif args.command == "tool-version":
            result = subprocess.run([args.executable, *args.arguments], capture_output=True, text=True, check=False)
            if result.stdout: print(result.stdout.splitlines()[0])
            elif result.stderr: print(result.stderr.splitlines()[0])
            return result.returncode
        elif args.command == "pe-info":
            data = path(args.path).read_bytes()
            if len(data) < 64 or data[:2] != b"MZ": raise ValueError("not a PE executable")
            offset = int.from_bytes(data[0x3c:0x40], "little")
            if offset + 6 > len(data) or data[offset:offset + 4] != b"PE\0\0": raise ValueError("invalid PE signature")
            machine = int.from_bytes(data[offset + 4:offset + 6], "little")
            names = {0x8664: "x86_64", 0xAA64: "arm64", 0x14C: "x86"}
            if machine not in names: raise ValueError(f"unsupported PE machine: 0x{machine:04x}")
            print(names[machine])
        elif args.command == "sign-tree":
            root = path(args.root)
            signables = []
            for item in root.rglob("*"):
                if item.is_file() and item.suffix.casefold() == ".dylib": signables.append(item)
                if item.is_dir() and item.suffix.casefold() in {".app", ".appex", ".framework", ".bundle"}:
                    plist = item / "Info.plist"
                    if plist.is_file():
                        try:
                            executable = plistlib.loads(plist.read_bytes()).get("CFBundleExecutable")
                            if executable: signables.append(item / executable)
                        except (ValueError, KeyError):
                            pass
            for item in sorted(set(signables), key=lambda value: len(value.parts), reverse=True):
                if not item.is_file(): continue
                result = subprocess.run([args.signer, *args.flags, str(item)], check=False)
                if result.returncode: return result.returncode
        elif args.command == "remove-glob":
            root = path(args.root)
            for item in root.rglob(args.pattern):
                if item.is_file(): item.unlink()
        elif args.command == "copy-list":
            destination = path(args.destination); destination.mkdir(parents=True, exist_ok=True)
            for item in args.paths:
                source = path(item)
                if not source.exists():
                    print(f"Ignoring missing path {item}.", file=sys.stderr)
                    continue
                target = destination / source.name
                if source.is_dir(): shutil.copytree(source, target, dirs_exist_ok=True)
                else: shutil.copy2(source, target)
        elif args.command == "check-files":
            missing = [item for item in args.paths if not path(item).is_file()]
            if missing:
                for item in missing: print(f"File {item} does not exist.", file=sys.stderr)
                return 1
        elif args.command == "extract":
            archive, target = path(args.archive), path(args.destination)
            target.mkdir(parents=True, exist_ok=True)
            if zipfile.is_zipfile(archive):
                with zipfile.ZipFile(archive) as bundle: bundle.extractall(target)
            else:
                extract_tar_safe(archive, target)
        elif args.command == "target-args":
            for index, value in enumerate(args.value.split(":")):
                if value: print(f"export __THEOS_TARGET_ARG_{index} := {value};")
        elif args.command == "sort-versions":
            def version_key(value):
                parts = value.split(".")
                if not parts or any(not part.isdigit() for part in parts):
                    raise ValueError(f"invalid dotted numeric SDK version: {value}")
                return tuple(int(part) for part in parts)
            print(" ".join(sorted(args.values, key=version_key)))
        elif args.command == "package-version":
            project_dir, data_dir = path(args.project_dir), path(args.data_dir)
            package_dir = data_dir / "packages"
            if not package_dir.is_dir():
                legacy = project_dir / ".debmake"
                data_dir.mkdir(parents=True, exist_ok=True)
                if legacy.is_dir(): shutil.move(str(legacy), str(package_dir))
                else: package_dir.mkdir(parents=True, exist_ok=True)
            version_file = package_dir / f"{args.package}-{args.version}"
            try:
                current = version_file.read_text(encoding="utf-8").strip()
                build_number_text = current.rsplit("-", 1)[-1].split("+", 1)[0].split("~", 1)[0]
                build_number = int(build_number_text) + 1
            except FileNotFoundError:
                build_number = 1
            except ValueError as error:
                raise ValueError(f"invalid build number in {version_file}") from error
            temp_file = version_file.with_suffix(version_file.suffix + ".tmp")
            temp_file.write_text(str(build_number), encoding="ascii")
            temp_file.replace(version_file)
            print(build_number)
        elif args.command == "scheme-stage":
            stage, scheme, staging_tmp = path(args.stage), path(args.scheme_stage), path(args.staging_tmp)
            scheme.mkdir(parents=True, exist_ok=True)
            for item in stage.iterdir():
                if item.name == "DEBIAN": continue
                shutil.move(str(item), str(scheme / item.name))
            if staging_tmp.exists():
                for item in staging_tmp.iterdir():
                    shutil.move(str(item), str(stage / item.name))
                staging_tmp.rmdir()
        elif args.command == "logos":
            command = [args.perl, args.script, *shlex.split(args.flags), args.source]
            with open(args.output, "wb") as output:
                result = subprocess.run(command, stdout=output, check=False)
            return result.returncode
        elif args.command == "subprojects":
            for entry in args.subprojects:
                directory = entry.split(":", 1)[0]
                child_build = "." if args.build_dir == "." else str(path(args.build_dir) / directory)
                command = [args.make, "-C", directory, "-f", args.makefile]
                if args.no_keep_going: command.append("--no-keep-going")
                if args.makeflags: command.extend(args.makeflags.split())
                command.extend([args.operation, f"THEOS_BUILD_DIR={child_build}"])
                result = subprocess.run(command, cwd=args.cwd, check=False)
                if result.returncode: return result.returncode
        elif args.command == "ipa":
            stage, output = path(args.stage), path(args.output)
            output.parent.mkdir(parents=True, exist_ok=True)
            compression = zipfile.ZIP_STORED if args.compression <= 0 else zipfile.ZIP_DEFLATED
            with zipfile.ZipFile(output, "w", compression=compression, compresslevel=max(0, min(9, args.compression))) as archive:
                for item in stage.rglob("*"):
                    if item.is_file(): archive.write(item, item.relative_to(stage).as_posix())
        elif args.command == "rpm-spec":
            source = path(args.source).read_text(encoding="utf-8-sig").splitlines()
            lines = [line for line in source if not line.casefold().startswith("source0:")]
            if args.release:
                lines = [f"Release: {args.release}" if line.casefold().startswith("release:") else line for line in lines]
            if args.append_files: lines.extend(["%files", "/*"])
            destination = path(args.destination); destination.parent.mkdir(parents=True, exist_ok=True); destination.write_text("\n".join(lines) + "\n", encoding="utf-8")
        elif args.command == "deb":
            stage, output = path(args.stage), path(args.output)
            control_dir = stage / "DEBIAN"
            if not control_dir.is_dir() or not (control_dir / "control").is_file():
                raise ValueError("Debian stage requires DEBIAN/control")
            manifest = load_metadata_manifest(args.manifest)
            level = max(0, min(9, args.compression))
            control_data = tar_gz_bytes(control_dir, include_control=True, manifest=manifest, compresslevel=level)
            data_data = tar_gz_bytes(stage, manifest=manifest, compresslevel=level)
            output.parent.mkdir(parents=True, exist_ok=True)
            with output.open("wb") as stream:
                stream.write(b"!<arch>\n")
                stream.write(ar_member("debian-binary", b"2.0\n"))
                stream.write(ar_member("control.tar.gz", control_data))
                stream.write(ar_member("data.tar.gz", data_data))
        elif args.command == "deb-info":
            raw = path(args.path).read_bytes()
            members = read_ar_members(raw)
            required = {"debian-binary", "control.tar.gz", "data.tar.gz"}
            if set(members) != required or members["debian-binary"] != b"2.0\n": raise ValueError("invalid Debian package members")
            with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as control:
                if "control" not in control.getnames(): raise ValueError("Debian control member missing")
                control_stream = control.extractfile("control")
                control_text = control_stream.read().decode("utf-8-sig") if control_stream else ""
                required_fields = {line.partition(":")[0].strip().casefold() for line in control_text.splitlines() if ":" in line}
                if not {"package", "version", "architecture"}.issubset(required_fields): raise ValueError("Debian control metadata is incomplete")
                if int(control.getmember("control").mode) & 0o777 != 0o644: raise ValueError("Debian control must be mode 0644")
            with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as data:
                payloads = data.getnames()
                if not payloads: raise ValueError("Debian data archive is empty")
                for member in data.getmembers():
                    if member.name.startswith("/") or ".." in member.name.split("/"): raise ValueError(f"unsafe Debian member path: {member.name}")
                    if (member.uid, member.gid) != (_ROOTTREE_UID, _ROOTTREE_GID): raise ValueError(f"Debian member is not root-owned: {member.name}")
                    if member.uname not in ("root", "") or member.gname not in ("wheel", "root", ""): raise ValueError(f"Debian member owner names are invalid: {member.name}")
            print("debian-binary control.tar.gz data.tar.gz")
        elif args.command == "deb-extract":
            members = read_ar_members(path(args.path).read_bytes())
            if "control.tar.gz" not in members or "data.tar.gz" not in members: raise ValueError("invalid Debian package members")
            extract_tar_bytes(members["control.tar.gz"], args.control)
            extract_tar_bytes(members["data.tar.gz"], args.data)
        elif args.command == "codesign":
            target = path(args.path)
            if not target.is_file(): raise ValueError(f"codesign target does not exist: {target}")
            # ldid (and other Darwin signers) build their temporary output path by
            # splitting on the host separator, so a path that mixes "\" and "/"
            # is mangled into an unopenable name. Hand the signer a native path.
            native = os.path.normpath(str(target))
            command = [args.signer]
            if args.flags.strip(): command.extend(args.flags.split())
            command.append(native)
            result = subprocess.run(command, check=False)
            return result.returncode
        elif args.command == "optimize-plists":
            print(f"theos-windows: optimized {optimize_plists(args.directory)} plist file(s)")
        elif args.command == "fakeroot":
            state = path(args.persistence)
            manifest = state.with_name(state.name + ".json")
            if args.clear:
                for item in (state, manifest):
                    if item.is_file(): item.unlink()
                return 0
            state.parent.mkdir(parents=True, exist_ok=True)
            state.touch(exist_ok=True)
            if args.record_stage:
                entries = staging_metadata(args.record_stage)
                manifest.write_text(json.dumps({"paths": entries}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            command = list(args.arguments)
            if command and command[0] == "--": command = command[1:]
            if command:
                return subprocess.run(command, check=False).returncode
            return 0
        elif args.command == "run":
            return subprocess.run([args.executable, *args.arguments], check=False).returncode
        else:
            # Never fall through silently: an unhandled subcommand used to look like
            # a successful no-op, which silently dropped build outputs.
            raise ValueError(f"unhandled command: {args.command}")
    except (OSError, ValueError, KeyError) as error:
        print(f"theos-windows: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__": raise SystemExit(main())
