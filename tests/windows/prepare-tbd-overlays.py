"""One-shot RC migration: retain canonical stubs and add complete alternate trees.

Run from a main checkout whose vendor/lib contains migration commit 300f9e0.
Not part of the build; the resulting files are reviewed and committed to lib.
"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2] / "vendor" / "lib"
BASE = "6f2af307568e6b8c52181d26314b0cd69ffaf188"
MODERN = "300f9e005d2b358ad7da1cb5d96f2cfb7c98ec9a"


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def main():
    # Never modify canonical files through checkout symlinks.
    changed = git("diff", "--name-only", BASE, MODERN).decode().splitlines()
    for profile in ("modern",):
        destination = ROOT / "tbd" / profile
        if destination.exists():
            raise SystemExit(f"Refusing to overwrite {destination}")
        for record in git("ls-tree", "-rz", MODERN).split(b"\0"):
            if not record:
                continue
            meta, name_bytes = record.split(b"\t", 1)
            mode, kind, oid = meta.decode().split()
            name = name_bytes.decode()
            if not name.endswith(".tbd"):
                continue
            target = destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if mode == "120000":
                # Materialize aliases so Windows core.symlinks=false clones work.
                alias = git("cat-file", "blob", oid).decode()
                content = git("show", f"{MODERN}:{(pathlib.PurePosixPath(name).parent / alias).as_posix()}")
            else:
                content = git("cat-file", "blob", oid)
            target.write_bytes(b"\n".join(line.rstrip(b" \t\r") for line in content.split(b"\n")))
    for name in changed:
        (ROOT / name).write_bytes(git("show", f"{BASE}:{name}"))


if __name__ == "__main__":
    main()
