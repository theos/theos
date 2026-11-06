# Building Theos projects from Windows

A standard project Makefile stays syntactically unchanged:

```make
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Example
Example_FILES = Tweak.x
Example_CFLAGS = -fobjc-arc
Example_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
```

On a native Windows host, `make clean` and `make package FINALPACKAGE=1` are verified to
run the complete iOS tweak pipeline without WSL, without `bash.exe`, and without
disabling code signing or the fakeroot metadata stage:

```
Logos preprocessing -> Objective-C compile (SDK headers) -> ARM64 Mach-O link (ld64.lld)
  -> dsymutil -> llvm-strip -> ldid signing -> fakeroot metadata -> .deb
```

Verified artifact produced by this port:

```
tests/windows/logos-tweak/packages/com.example.windowslogos_1.0_iphoneos-arm64.deb
2256 bytes, SHA-256 db4a2639b2d09e7f45af2b4a1878cc85cd0c6781bfb01f2b970fb9e0097edab4
```

Two builds from a wiped tree (`.theos/`, `packages/` and the fakeroot state removed
between runs) produced byte-identical packages.

## Prerequisites

| Component | Requirement | Notes |
| --- | --- | --- |
| Python | Python 3 with the standard library | Used by `bin/theos-windows.py`; Python 3.11 was used for the verified Windows run. The minimum supported version is not independently version-gated by the scripts. |
| GNU Make | 4.4.x | `winget install ezwinports.make` |
| LLVM/Clang | 23.x, x86_64 Windows | Must include `clang.exe`, `ld64.lld.exe`, `llvm-strip.exe`, `dsymutil.exe`, `llvm-objdump.exe` |
| Perl | Any modern | Only needed for Logos preprocessing (Strawberry Perl 5.42 verified) |
| ldid | Procursus Windows x64 | Real signing; set `THEOS_LDID` |
| iOS SDK | Legally obtained | See below; not downloaded or redistributed by this repository |

Install the pinned toolchain automatically:

```powershell
& "$env:THEOS\bin\install-windows-toolchain.ps1" -PackageManager full-official -AddToUserPath
```

In `full-official` mode the installer verifies pinned LLVM, ldid and Strawberry Perl
archives, installs GNU Make if it is missing, sets `THEOS_LLVM_BIN`, `THEOS_LD64_LLD` and
`THEOS_LDID` for the current PowerShell process, and writes them to `GITHUB_ENV`/`GITHUB_PATH`
when running in Actions. `-AddToUserPath` persists tool directories, not these Theos
variables. It never bundles or downloads an Apple SDK. Other package-manager modes have
different coverage; verify their final tool report before building.

## Environment

```powershell
$env:THEOS          = (Get-Location).Path          # or an installed checkout
$env:THEOS_SDKROOT  = Join-Path $env:THEOS 'sdks\iPhoneOS16.5.sdk'
$env:IOS_SDK_ROOT   = $env:THEOS_SDKROOT           # older projects read this name
$env:THEOS_LLVM_BIN = 'C:\path\to\llvm\bin'        # optional when LLVM is on PATH
$env:THEOS_LDID     = Join-Path $env:THEOS_LLVM_BIN 'ldid.exe'
```

Check the environment before building:

```powershell
& "$env:THEOS\bin\test-windows.ps1"
& "$env:THEOS\bin\test-windows-toolchain.ps1" -SdkRoot $env:THEOS_SDKROOT
```

## Building and packaging

```powershell
Set-Location $env:THEOS\tests\windows\logos-tweak   # or your own project
make clean
make package FINALPACKAGE=1
```

The package is written to `packages/<id>_<version>_<architecture>.deb`. Both Debian
packaging schemes are verified natively:

```powershell
# rootful (default): payload installs at /Library/...
make package FINALPACKAGE=1

# rootless: payload installs under /var/jb
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

A tweak must ship a filter plist (`<Name>.plist` or `Filter.plist`) next to its
sources; without one Theos aborts with "You are missing a filter property list",
which is correct upstream behaviour rather than a Windows issue.

## Verifying the package

`tests/windows/verify_package.py` inspects the artifact without trusting the build's own
packaging code. It re-parses the `ar` and tar structures and checks:

- `debian-binary` is `2.0`, and the members are exactly `control.tar.gz`/`data.tar.gz`;
- `DEBIAN/control` is present, mode `0644`, and carries Package/Version/Architecture;
- every member is `0:0 root:wheel`, directories are `0755`, plists `0644`;
- the installed dylib is executable and located under
  `Library/MobileSubstrate/DynamicLibraries` (rootful) or
  `var/jb/Library/MobileSubstrate/DynamicLibraries` (rootless);
- the payload is an **ARM64** Mach-O carrying a `LC_CODE_SIGNATURE` load command;
- `ldid -e` succeeds on the packaged dylib and **fails** on an unsigned control image.

```powershell
$deb = (Get-ChildItem packages -Filter '*.deb').FullName
python "$env:THEOS\tests\windows\verify_package.py" $deb `
  --ldid $env:THEOS_LDID --objdump (Join-Path $env:THEOS_LLVM_BIN 'llvm-objdump.exe')
python "$env:THEOS\bin\theos-windows.py" deb-info $deb
```

As an independent cross-check, Windows' bundled `bsdtar` (libarchive) can list and
extract the archive:

```powershell
tar -tf $deb                 # debian-binary, control.tar.gz, data.tar.gz
tar -xzf (Join-Path $d 'data.tar.gz')
```

Run the whole end-to-end check, including both packaging schemes, with:

```powershell
& "$env:THEOS\bin\test-windows-e2e.ps1"
```

It generates a stock tweak project in `%TEMP%`, builds rootful and rootless packages,
and verifies each one. Its preflight exits `2` when the Theos checkout, `make`, `clang`,
`clang++`, `perl`, linker, ldid, or SDK is missing. Invalid SDKs and failures during the
actual build or package verification raise an error instead; they are not all mapped to
exit code `2`.

## Obtaining a genuine iPhoneOS SDK

This checkout does not download or redistribute Apple SDK files, and no SDK content is
tracked by Git (`sdks/*` is ignored; only `sdks/.keep` is committed). Apple SDK files are
governed by the Xcode and Apple SDKs Agreement: you must obtain them through your own
Apple account and use them only as that agreement permits. Do not commit, publish, or
redistribute SDK contents, and never supply Apple credentials, cookies, or tokens to
build tooling.

The supported acquisition path is:

1. On an authorized Mac, obtain Xcode from Apple's Mac App Store or Apple Developer
   downloads (`https://developer.apple.com/download/all/`) using your own Apple account.
   Accept the current Xcode and Apple SDK terms and verify the intended use is permitted.
2. Locate the SDK inside the installed Xcode bundle:

   ```text
   Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk
   ```

   ```bash
   DEVELOPER_DIR="$(xcode-select -p)"
   xcodebuild -showsdks
   ls "$DEVELOPER_DIR/Platforms/iPhoneOS.platform/Developer/SDKs"
   SDK="$DEVELOPER_DIR/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk"
   test -f "$SDK/SDKSettings.plist" && test -f "$SDK/usr/lib/libSystem.tbd"
   ditto "$SDK" "/Volumes/Shared/theos-sdks/$(basename "$SDK")"
   plutil -p "/Volumes/Shared/theos-sdks/$(basename "$SDK")/SDKSettings.plist"
   ```

3. Copy the complete directory, preserving symlinks and file contents, into the Windows
   checkout as `sdks/iPhoneOS<version>.sdk`. Do not assemble an SDK from headers, `.tbd`
   files, or frameworks taken from unrelated sources; a hand-built tree will fail
   validation, and faking missing components is not supported.

   For a Hackintosh on the same machine: boot macOS, copy the SDK to an exFAT/NTFS
   volume, then copy it into the checkout. Windows cannot read APFS natively — do not
   mount or modify an APFS partition with an untrusted driver.

4. On Windows, validate the copied SDK before building:

   ```powershell
   $env:THEOS = (Get-Location).Path
   $env:THEOS_SDKROOT = Join-Path $env:THEOS 'sdks\iPhoneOS<version>.sdk'
   $env:IOS_SDK_ROOT  = $env:THEOS_SDKROOT
   python "$env:THEOS\bin\theos-windows.py" sdk-info $env:THEOS_SDKROOT --platform iPhoneOS
   ```

   Validation must report `usr/include`, `usr/lib` containing `libSystem.tbd` or
   `libSystem.dylib`, and `System/Library/Frameworks`. The version is read from the
   directory name, or from `SDKSettings.plist` (XML or binary) for an unversioned
   `iPhoneOS.sdk` directory.

   With no SDK present, the build stops with Theos' own error
   (`You do not have any SDKs in <THEOS>/sdks.`) and exit code 2; an invalid SDK root
   fails with `invalid iPhoneOS SDK: expected usr/include and usr/lib`. Both are hard
   failures — the port never falls back to a partial or fabricated build.

5. Build and inspect the result as shown above. Preserve the build log and verify the
   produced `.deb`, dylib architecture and signature; a successful `sdk-info` run alone
   is not evidence of a link or package build.

## Scope of what is verified

Verified natively on Windows x64 with LLVM 23.1.5, GNU Make 4.4.1, Strawberry Perl
5.42.3.1, Procursus ldid and a user-supplied `iPhoneOS16.5.sdk`:

- ARM64 Mach-O objects for C, C++, Objective-C and Objective-C++;
- vendored Logos preprocessing with the default (MobileSubstrate) generator;
- ARM64 dylib linking with `ld64.lld`, including `-framework CydiaSubstrate`;
- `dsymutil`, `llvm-strip`, and `ldid` signing with `LC_CODE_SIGNATURE`;
- `.deb` creation for rootful and rootless schemes, with root:wheel ownership,
  correct modes, directory entries and deterministic output;
- `make clean` followed by `make package FINALPACKAGE=1` with no Bash on PATH.

Not verified in this environment, and therefore not claimed:

- macOS and Linux builds of these changes (no such host was available);
- Theos targets other than `tweak` built end-to-end on Windows (tools are exercised by a
  dry run; applications, libraries, frameworks, bundles and Swift were not);
- the still Bash-based recipes (Swift/Xcode/remote install);
- installation of the produced `.deb` on a real device, or `dpkg-deb` on a Debian host;
- the GitHub Actions Windows workflow's remote run (no GitHub CLI/token available here).
