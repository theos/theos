# Theos on native Windows

Native Windows support is functional for iOS tweak builds. This repository contains a
PowerShell bootstrapper, an environment verifier, and a Python helper that replaces the
POSIX shell utilities Theos normally relies on. It does not bundle Apple SDKs, `ldid`,
or a Mach-O linker — those must be installed separately (see
[WINDOWS_BUILD.md](WINDOWS_BUILD.md)).

The verified pipeline on Windows x64 runs entirely without WSL and without `bash.exe`:
Logos preprocessing, Objective-C compilation against a user-supplied SDK, ARM64 dylib
linking with `ld64.lld`, `dsymutil`, `llvm-strip`, real `ldid` signing, fakeroot
metadata emulation, and Debian `.deb` creation for both rootful and rootless schemes.
Signing and the fakeroot stage are never skipped.

## Install

Open PowerShell as a normal user (not Administrator) and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
& .\bin\install-theos.ps1 -InstallPath "$HOME\theos"
```

The script requires Git for Windows to clone the checkout and sets the user-level `THEOS`
variable. Open a new PowerShell/CMD window after installation so persistent environment
changes are inherited. Use `-SkipPathUpdate` when you do not want to add Theos' `bin`
directory to the user PATH.

Git for Windows is **not** required at build time for the tweak/`.deb` path. The
installer never downloads an iOS SDK or claims that a linker is available.

## Verify, update, remove

```powershell
& "$env:THEOS\bin\manage-theos.ps1" -Action Health
& "$env:THEOS\bin\manage-theos.ps1" -Action Update
& "$env:THEOS\bin\manage-theos.ps1" -Action Uninstall -TheosPath "$env:THEOS"
```

`Health` runs the helper tests and dependency/toolchain checks. `0` means the required
command names and iOS SDK/linker candidates were found; it does not replace an
end-to-end build test. `2` means the environment is incomplete. `Uninstall` refuses to
delete a non-Git directory and removes only the explicitly selected Theos checkout plus
matching user-level THEOS/PATH entries.

## Toolchain setup and SDK

Install the pinned native toolchain with `bin/install-windows-toolchain.ps1`:

```powershell
& "$env:THEOS\bin\install-windows-toolchain.ps1" -PackageManager full-official -AddToUserPath
```

This mode verifies pinned downloads and installs LLVM/Clang (including `ld64.lld`,
`llvm-strip`, `dsymutil`, `llvm-objdump`), Strawberry Perl, GNU Make when missing, and a
native Procursus `ldid.exe`. It sets `THEOS_LLVM_BIN`, `THEOS_LD64_LLD` and `THEOS_LDID`
in the current PowerShell process, adds tool directories to the user PATH when requested,
and runs the toolchain probe. The Theos variables are not persisted as user environment
variables. Other package-manager modes may not install every tool; `-InstallMake` and
`-InstallPerl` are only used by the `choco`/`winget` modes.

Portable mode is an operator-configured, user-local example (the script does not enforce
non-administrator execution). It requires a pinned upstream Windows LLVM ZIP and its
independently verified SHA-256:

```powershell
& "$env:THEOS\bin\install-windows-toolchain.ps1" -PackageManager portable `
  -PortableUrl 'https://example.invalid/llvm-win64.zip' `
  -PortableSha256 '<64-hex-sha256>' `
  -PortableDestination "$HOME\theos-toolchain\llvm" -AddToUserPath
```

The URL and hash are intentionally supplied by the operator or CI configuration; the
repository does not hard-code a moving download or unverifiable checksum.

Set `THEOS_SDKROOT` or `IOS_SDK_ROOT` to a user-supplied `iPhoneOS<version>.sdk`
directory. The SDK must contain `usr/include`, `usr/lib/libSystem.tbd` (or
`libSystem.dylib`), and `System/Library/Frameworks`. Validate and probe native Clang
with:

```powershell
$env:THEOS_SDKROOT = 'C:\SDKs\iPhoneOS16.5.sdk'
& "$env:THEOS\bin\test-windows-toolchain.ps1" -SdkRoot $env:THEOS_SDKROOT
```

The compiler probe builds C, C++, Objective-C, and Objective-C++ source files as ARM64
Mach-O objects and inspects their headers. `arm64e` is probed separately and is
considered supported only if the actual object subtype matches. Native linking uses LLVM
LLD's Mach-O driver `ld64.lld`; ELF `ld.lld`, PE `lld-link`, MSVC link.exe, and MinGW ld
are not substitutes.

The SDK version is taken from the SDK directory name, or from `SDKSettings.plist` (XML or
binary) for an unversioned `iPhoneOS.sdk` directory. A missing SDK is a hard failure:
`You do not have any SDKs in <THEOS>/sdks.` (exit 2), and an invalid SDK root fails with
`invalid iPhoneOS SDK: expected usr/include and usr/lib`.

Apple SDK files are governed by the Xcode and Apple SDKs Agreement. Obtain them with your
own Apple account and use them only as that agreement permits. This repository neither
downloads nor redistributes SDK content; `sdks/*` is Git-ignored and only `sdks/.keep` is
tracked.

## Current boundary

The tested tweak → ARM64 dylib → signed `.deb` graph does not require Bash. Earlier
legacy Theos recipes still use Bash syntax (`[[ ]]`, loops, redirections); projects that
hit those recipes need `bash.exe` available and can set `THEOS_WINDOWS_REQUIRE_BASH=1` to
turn a missing Bash into an explicit early error instead of a confusing recipe failure.
`common.mk` prints an informational note when `bash.exe` is absent.

GNU Make 4.4 loads and runs the original Theos makefiles without Bash. Targets other than
`tweak` have not been built end-to-end on Windows (tools are covered by a dry run), and
the macOS/Linux behaviour of the Windows-specific branches was reviewed statically rather
than executed on those hosts.
