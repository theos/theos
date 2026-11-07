#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
stage="$tmp/stage"
mkdir -p "$stage/DEBIAN" "$stage/usr/lib"
cat > "$stage/DEBIAN/control" <<'EOF'
Package: org.theos.posix-smoke
Name: Theos POSIX packaging smoke
Version: 1.0
Architecture: iphoneos-arm64
Description: SDK-free POSIX package builder smoke test
EOF
printf 'smoke-payload\n' > "$stage/usr/lib/smoke.txt"
chmod 755 "$stage/DEBIAN"
chmod 644 "$stage/DEBIAN/control"

command -v fakeroot >/dev/null
perl -MArchive::Tar -e 'exit 0'
state="$tmp/fakeroot.state"
fakeroot -s "$state" -- perl "$root/vendor/dm.pl/dm.pl" \
  -Zgzip -z9 -b "$stage" "$tmp/smoke.deb"
test -s "$tmp/smoke.deb"
python3 - "$tmp/smoke.deb" <<'PY'
import gzip
import io
import sys
import tarfile
from pathlib import Path

raw = Path(sys.argv[1]).read_bytes()
assert raw.startswith(b"!<arch>\n"), "missing Debian ar magic"
offset = 8
members = {}
while offset < len(raw):
    header = raw[offset:offset + 60]
    assert len(header) == 60 and header[58:60] == b"`\n", "invalid ar header"
    name = header[:16].decode("ascii").strip().rstrip("/")
    size = int(header[48:58].decode("ascii").strip())
    start = offset + 60
    members[name] = raw[start:start + size]
    offset = start + size + (size % 2)
assert members["debian-binary"] == b"2.0\n"
assert {"control.tar.gz", "data.tar.gz"}.issubset(members)
with tarfile.open(fileobj=io.BytesIO(members["control.tar.gz"]), mode="r:gz") as archive:
    entries = {item.name.removeprefix("./"): item for item in archive.getmembers()}
    control = archive.extractfile(entries["control"]).read().decode()
    assert "Package: org.theos.posix-smoke" in control
    for item in archive.getmembers():
        assert (item.uid, item.gid) == (0, 0), (item.name, item.uid, item.gid)
    assert entries["control"].mode & 0o777 == 0o644
with tarfile.open(fileobj=io.BytesIO(members["data.tar.gz"]), mode="r:gz") as archive:
    entries = {item.name.removeprefix("./"): item for item in archive.getmembers()}
    for item in archive.getmembers():
        assert (item.uid, item.gid) == (0, 0), (item.name, item.uid, item.gid)
        if item.isdir():
            assert item.mode & 0o777 == 0o755, (item.name, oct(item.mode))
    payload = entries["usr/lib/smoke.txt"]
    assert payload.mode & 0o777 == 0o644
    assert archive.extractfile(payload).read() == b"smoke-payload\n"
print("PASS: fakeroot and dm.pl emitted root-owned gzip Debian members with expected modes")
PY
if command -v dpkg-deb >/dev/null 2>&1; then
  dpkg-deb --info "$tmp/smoke.deb"
  dpkg-deb --contents "$tmp/smoke.deb"
fi
rm -f "$state"
