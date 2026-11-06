# Windows troubleshooting

## `THEOS` is empty

The installer writes a user-level variable. Close and reopen PowerShell or CMD, then check:

```powershell
$env:THEOS
```

For a one-process test, set it explicitly with `$env:THEOS = 'C:\path\to\theos'`.

## The verifier reports missing SDK or linker

This is a real blocker. Install or configure a legally obtained iOS SDK and a linker that
emits Apple Mach-O. `clang-cl`, `link.exe`, and MinGW linkers do not satisfy that
requirement. Do not bypass the check with a fake executable — the packaging path is only
meaningful when a real linker, a real signature and a real Debian archive are involved.

## `You do not have any SDKs in <THEOS>/sdks.`

No usable SDK was found. Point `THEOS_SDKROOT` (or `IOS_SDK_ROOT`) at a complete
`iPhoneOS<version>.sdk` directory, or place one under `<THEOS>/sdks`. An incomplete tree
fails earlier with `invalid iPhoneOS SDK: expected usr/include and usr/lib`.

## `ld64.lld: error: .../X.tbd: unhandled file type`

The stub is a TBD **v1** document (it starts with a bare `---` and carries `archs:` /
`platform:`). Linker frontends sniff the first line for a `!tapi-tbd` tag and treat an
untagged file as an unknown binary. Every `.tbd` under `vendor/lib` must begin with an
explicit tag (`--- !tapi-tbd-v3` or `--- !tapi-tbd` for v4). The Windows port migrated the
vendored stubs to v3; if you add a new v1 stub you will see this error again. Note that
`ld64.lld` also rejects a v3 stub that lists simulator arches (`i386`, `x86_64`) together
with device arches; such a stub needs explicit v4 `targets:` instead.

## Signing fails with `WindowsLogosProbe.dylib.<tag>.unsigned` or `Permission denied`

`ldid` derives its temporary file from the raw path string, so a path that mixes `\` and
`/` produces an unopenable name. The Windows recipes route signing through
`bin/theos-windows.py codesign`, which normalizes the path to native separators before
invoking the real signer. If you call `ldid` yourself, pass a normalized path.

## `process_begin: CreateProcess(NULL, env bash ... fakeroot.sh ...) failed`

The host has no `bash.exe`, and a recipe is still using the POSIX fakeroot shim or another
legacy Bash recipe. The Windows platform file defines a native fakeroot backend
(`theos-windows.py fakeroot`) that records staging metadata for the `.deb` builder, so the
packaging path itself needs no Bash. Recipes outside that path (Swift, Xcode, remote
install) still do; install Git for Windows or set `THEOS_WINDOWS_REQUIRE_BASH=1` to get an
explicit early error instead.

## `You are missing a filter property list`

The tweak has no `<Name>.plist` or `Filter.plist` next to its sources. This is correct
Theos behaviour. Add one, for example:

```text
{ Filter = { Bundles = ( "com.apple.springboard" ); }; }
```

## `bash.exe not found; native helper-backed Windows operations are available...`

Informational only. The message is printed when a sub-make starts on a host without Bash.
The verified tweak/`.deb` graph does not use Bash.

## `-Werror` turns a generated warning into a build failure

`-Werror` (and `-c warnings=error` for Logos) are upstream Theos defaults, not port
additions. Build with `GO_EASY_ON_ME=1` to relax them, or fix the warning.

## Paths with spaces

The Python helper handles space-containing paths, and the Windows helper test suite runs
its fixtures under `%TEMP%\theos path with spaces ...`. If a recipe fails on a path with
spaces, it is most likely a remaining Bash-syntax recipe rather than the native path
handling.

## Objective-C or Logos compilation fails

Check all of: Clang language support, the Logos preprocessor (needs `perl`), target
headers, SDK headers, runtime libraries, and the linker. A host Windows Objective-C
compiler alone is insufficient for a tweak. With the SDK in place,
`bin/test-windows-toolchain.ps1` separates compiler problems from SDK problems.

## `.deb` creation fails

The Windows `.deb` builder writes a standard Debian `ar` archive containing
`debian-binary`, `control.tar.gz` and `data.tar.gz` itself; no `dpkg-deb` is required. If
it fails, check that the staging directory contains `DEBIAN/control` with a valid
`Architecture`, and inspect the artifact with `bin/theos-windows.py deb-info`. Windows'
bundled `tar.exe` (libarchive/bsdtar) can unpack the result as an independent check:

```powershell
tar -tf package.deb
```

## Package verifies but installs nothing on the device

The `.deb` is a real ARM64 package, but installation has not been exercised on a device in
this environment. Confirm the install prefix matches the target scheme: rootful payloads
install under `Library/...`, rootless payloads under `var/jb/Library/...`. Rebuild with
`THEOS_PACKAGE_SCHEME=rootless` for rootless jailbreaks.

## Updating or removing Theos

Update with Git inside `$env:THEOS` and re-run submodule initialization. To remove the
checkout, delete the chosen install directory after checking `$env:THEOS`; then remove the
user-level `THEOS` and PATH entries through Windows Environment Variables settings or
PowerShell.
