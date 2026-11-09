#!/usr/bin/env python3
"""Select the modern vendored overlay only after real clang/LLD format probes.

Legacy-capable linkers keep canonical paths. Modern-only linkers must read both
v3 and v4. This command never rewrites vendor/lib or changes POSIX selection.
"""
import argparse
import pathlib
import subprocess
import tempfile
import sys


def choose(clang, library, scheme=""):
    with tempfile.TemporaryDirectory(prefix="theos-tapi-") as directory:
        tmp = pathlib.Path(directory)
        source = tmp / "probe.c"
        source.write_text("extern int theos_tapi_probe; int *probe(void) { return &theos_tapi_probe; }\n")
        obj = tmp / "probe.o"
        result = subprocess.run([clang, "-target", "arm64-apple-ios13.0", "-x", "c", "-c", str(source), "-o", str(obj)], capture_output=True, timeout=30)
        if result.returncode:
            raise RuntimeError("cannot compile TBD capability probe: " + result.stderr.decode(errors="replace"))
        bodies = [
            "---\narchs: [ arm64 ]\nplatform: ios\ninstall-name: /usr/lib/libtheos-tapi.dylib\nexports:\n  - archs: [ arm64 ]\n    symbols: [ _theos_tapi_probe ]\n...\n",
            "--- !tapi-tbd-v3\narchs: [ arm64 ]\nplatform: ios\ninstall-name: /usr/lib/libtheos-tapi.dylib\nexports:\n  - archs: [ arm64 ]\n    symbols: [ _theos_tapi_probe ]\n...\n",
            "--- !tapi-tbd\ntbd-version: 4\ntargets: [ arm64-ios ]\ninstall-name: /usr/lib/libtheos-tapi.dylib\nexports:\n  - targets: [ arm64-ios ]\n    symbols: [ _theos_tapi_probe ]\n...\n",
        ]
        supported = []
        for body in bodies:
            stub = tmp / "probe.tbd"
            stub.write_text(body)
            run = subprocess.run([clang, "-target", "arm64-apple-ios13.0", "-fuse-ld=lld", "-dynamiclib", "-nostdlib", str(obj), str(stub), "-o", str(tmp / "probe.dylib")], capture_output=True, timeout=30)
            supported.append(run.returncode == 0)
        if supported[0]:
            canonical = pathlib.Path(library)
            if scheme:
                canonical = canonical / "iphone" / scheme
            alias = canonical / "libsubstrate.tbd"
            if alias.is_file() and not alias.read_text(encoding="utf-8").startswith("---"):
                raise RuntimeError("legacy libsubstrate alias is not a readable stub; enable Git symlinks for this checkout")
            return "legacy"
        if not all(supported[1:]):
            raise RuntimeError(f"selected clang/LLD driver cannot read required v3 and v4 stubs (v1/v3/v4={supported})")
        if scheme not in ("", "rootless"):
            raise RuntimeError(f"modern TBD overlay has no verified scheme: {scheme}")
        canonical = pathlib.Path(library)
        overlay = canonical / "tbd" / "modern"
        if scheme:
            canonical = canonical / "iphone" / scheme
            overlay = overlay / "iphone" / scheme
        candidates = canonical.rglob("*.tbd") if scheme else canonical.glob("*.tbd")
        framework_stubs = canonical.glob("*.framework/*.tbd")
        entries = (*candidates, *framework_stubs)
        missing = [str(p.relative_to(canonical)) for p in entries
                   if not (overlay / p.relative_to(canonical)).is_file()]
        if not entries or not canonical.is_dir() or missing:
            raise RuntimeError(f"modern TBD overlay is incomplete for {scheme or 'rootful'}: {missing}")
        return "modern"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--clang", required=True)
    parser.add_argument("--library", required=True)
    parser.add_argument("--scheme", default="")
    args = parser.parse_args()
    try:
        print(choose(args.clang, args.library, args.scheme))
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"TBD selection failed: {error}", file=sys.stderr)
        print("unsupported")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
