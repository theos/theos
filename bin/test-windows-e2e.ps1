[CmdletBinding()]
param(
    [string]$TheosPath = $env:THEOS,
    [string]$SdkRoot = $(if ($env:THEOS_SDKROOT) { $env:THEOS_SDKROOT } else { $env:IOS_SDK_ROOT }),
    [string]$OutputDirectory = (Join-Path $env:TEMP 'theos-windows-e2e')
)

$ErrorActionPreference = 'Stop'
$missing = @('make', 'clang', 'clang++', 'perl') | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
$linker = if ($env:THEOS_LD64_LLD) { Get-Command $env:THEOS_LD64_LLD -ErrorAction SilentlyContinue } else { Get-Command ld64.lld.exe,ld64.lld,ld64 -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (-not $linker) { $missing += 'ld64.lld' }
$ldid = if ($env:THEOS_LDID) { Get-Command $env:THEOS_LDID -ErrorAction SilentlyContinue } else { Get-Command ldid.exe,ldid -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (-not $ldid) { $missing += 'ldid (THEOS_LDID)' }
if (-not $SdkRoot) { $missing += 'THEOS_SDKROOT/IOS_SDK_ROOT' }
if (-not $TheosPath -or -not (Test-Path (Join-Path $TheosPath 'makefiles/common.mk'))) { $missing += 'THEOS checkout' }
if ($missing.Count) {
    [Console]::Error.WriteLine("End-to-end Windows tweak build requires $($missing -join ', ')")
    exit 2
}
$helper = Join-Path $TheosPath 'bin/theos-windows.py'
& python $helper sdk-info $SdkRoot
if ($LASTEXITCODE -ne 0) { throw 'The supplied SDK failed validation.' }
$project = Join-Path $OutputDirectory 'tweak'
if (Test-Path $project) { Remove-Item -LiteralPath $project -Recurse -Force }
New-Item -ItemType Directory -Force -Path $project | Out-Null
@'
TARGET := iphone:clang:latest:13.0
ARCHS := arm64
include $(THEOS)/makefiles/common.mk

PACKAGE_VERSION := 1.0
TWEAK_NAME := WindowsE2E
WindowsE2E_FILES := Tweak.x
include $(THEOS_MAKE_PATH)/tweak.mk
'@ | Set-Content -LiteralPath (Join-Path $project 'Makefile') -Encoding ascii
@'
#import <Foundation/Foundation.h>

%hook NSObject
- (id)init { return %orig; }
%end
'@ | Set-Content -LiteralPath (Join-Path $project 'Tweak.x') -Encoding ascii
@'
{ Filter = { Bundles = ( "com.apple.springboard" ); }; }
'@ | Set-Content -LiteralPath (Join-Path $project 'WindowsE2E.plist') -Encoding ascii
@"
Package: com.theos.windows-e2e
Name: Windows E2E Tweak
Version: 1.0
Architecture: iphoneos-arm64
Description: Native Windows Theos E2E probe
Maintainer: Theos
Author: Theos
Section: Tweaks
"@.TrimStart() | Set-Content -LiteralPath (Join-Path $project 'control') -Encoding ascii
$env:THEOS = $TheosPath
$env:THEOS_SDKROOT = $SdkRoot
$env:IOS_SDK_ROOT = $SdkRoot
$env:THEOS_LDID = $ldid.Source
$verifier = Join-Path $TheosPath 'tests/windows/verify_package.py'

$schemes = @(
    [pscustomobject]@{ Name = 'rootful'; Prefix = ''; Extra = @() },
    [pscustomobject]@{ Name = 'rootless'; Prefix = 'var/jb/'; Extra = @('THEOS_PACKAGE_SCHEME=rootless') }
)

foreach ($scheme in $schemes) {
    Write-Host "=== packaging scheme: $($scheme.Name) ==="
    make -C $project clean
    if ($LASTEXITCODE -ne 0) { throw "End-to-end clean failed ($($scheme.Name))." }
    $packageDir = Join-Path $project 'packages'
    if (Test-Path $packageDir) { Remove-Item -LiteralPath $packageDir -Recurse -Force }
    $makeArgs = @('-C', $project, 'package', 'FINALPACKAGE=1', "THEOS=$TheosPath", "THEOS_SDKROOT=$SdkRoot") + $scheme.Extra
    & make @makeArgs
    if ($LASTEXITCODE -ne 0) { throw "End-to-end Theos tweak package build failed ($($scheme.Name))." }
    $packages = @(Get-ChildItem -LiteralPath $packageDir -Filter '*.deb' -File -ErrorAction SilentlyContinue)
    if ($packages.Count -ne 1) { throw "End-to-end build did not produce exactly one .deb package ($($scheme.Name))." }
    & python $helper deb-info $packages[0].FullName
    if ($LASTEXITCODE -ne 0) { throw "Generated package failed Debian member inspection ($($scheme.Name))." }
    $verifyOut = & python $verifier $packages[0].FullName --ldid $ldid.Source --expect-arch arm64 2>&1
    $verifyText = ($verifyOut | Out-String)
    $verifyOut | ForEach-Object { $_ }
    if ($LASTEXITCODE -ne 0) { throw "Generated package failed architecture/signature verification ($($scheme.Name))." }
    if ($verifyText -notmatch [regex]::Escape("install prefix: '$($scheme.Prefix)'")) {
        throw "Package install prefix does not match the $($scheme.Name) scheme."
    }
    Write-Host "PASS: $($scheme.Name) package generated and verified: $($packages[0].FullName)"
}
