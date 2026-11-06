[CmdletBinding()]
param(
    [string]$Clang = 'clang',
    [ValidateSet('arm64', 'arm64e')]
    [string]$Arch = 'arm64',
    [string]$SdkRoot = $(if ($env:THEOS_SDKROOT) { $env:THEOS_SDKROOT } else { $env:IOS_SDK_ROOT }),
    [string]$Linker = $env:THEOS_LD64_LLD,
    [string]$Ldid = $env:THEOS_LDID,
    [string]$OutputDirectory = (Join-Path $env:TEMP 'theos-windows-toolchain-probe')
)

$ErrorActionPreference = 'Stop'
$clangCommand = Get-Command $Clang -ErrorAction SilentlyContinue
if (-not $clangCommand) { throw "Clang not found: $Clang" }
$clangPath = if ($clangCommand.Source) { $clangCommand.Source } else { $Clang }
$helper = Join-Path $PSScriptRoot 'theos-windows.py'

& python $helper compile-probe $clangPath $OutputDirectory --arch $Arch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$linkerCommand = if ($Linker) { Get-Command $Linker -ErrorAction SilentlyContinue } else { Get-Command ld64.lld.exe,ld64.lld,ld64 -ErrorAction SilentlyContinue | Select-Object -First 1 }
if ($linkerCommand) {
    $linkerPath = if ($linkerCommand.Source) { $linkerCommand.Source } else { $linkerCommand.FullName }
    $minimalObject = Join-Path $OutputDirectory 'probe.c.o'
    $minimalDylib = Join-Path $OutputDirectory 'probe-no-sdk.dylib'
    if (-not (Test-Path $minimalObject)) { throw "Expected compiler probe object missing: $minimalObject" }
    & $linkerPath -arch arm64 -platform_version ios 13.0 13.0 -dylib -install_name '@rpath/probe-no-sdk.dylib' $minimalObject -o $minimalDylib
    if ($LASTEXITCODE -ne 0) { throw 'ld64.lld failed to link SDK-independent Mach-O dylib.' }
    & python $helper macho-check $minimalDylib --arch arm64
    if ($LASTEXITCODE -ne 0) { throw 'SDK-independent linker output is not ARM64 Mach-O.' }
    $objdump = Join-Path (Split-Path -Parent $clangPath) 'llvm-objdump.exe'
    if (Test-Path $objdump) { & $objdump --macho --private-headers $minimalDylib | Select-String -Pattern 'MH_MAGIC_64|DYLIB|LC_BUILD_VERSION|platform ios' | ForEach-Object { Write-Host $_.Line } }
    Write-Host "PASS: ld64.lld produced SDK-independent ARM64 dylib $minimalDylib"
} else {
    Write-Host 'SKIP: ld64.lld is not installed; Mach-O linking not tested.'
}

if ($SdkRoot) {
    & python $helper sdk-info $SdkRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $linkerCommand = if ($Linker) { Get-Command $Linker -ErrorAction SilentlyContinue } else { Get-Command ld64.lld.exe,ld64.lld,ld64 -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $linkerCommand) { throw 'Mach-O linker ld64.lld was not found; ELF ld.lld and PE lld-link are not substitutes.' }
    $linkerPath = if ($linkerCommand.Source) { $linkerCommand.Source } else { $linkerCommand.FullName }
    & $linkerPath --help *> $null
    if ($LASTEXITCODE -ne 0) { throw "Mach-O linker failed to execute: $linkerPath" }
    Write-Host "Mach-O linker candidate: $linkerPath"
    $probeObject = Join-Path $OutputDirectory 'probe.c.o'
    $probeDylib = Join-Path $OutputDirectory 'probe.dylib'
    & $clangPath -target "$Arch-apple-ios13.0" -isysroot $SdkRoot -dynamiclib -fuse-ld=$linkerPath $probeObject -o $probeDylib
    if ($LASTEXITCODE -ne 0) { throw 'Clang + ld64.lld failed to link the probe dylib against the selected iOS SDK.' }
    & python $helper macho-check $probeDylib --arch $Arch
    if ($LASTEXITCODE -ne 0) { throw 'Linked output did not validate as an ARM Mach-O dylib.' }
    Write-Host "PASS: linked real Mach-O dylib: $probeDylib"

    $ldid = if ($Ldid) { Get-Command $Ldid -ErrorAction SilentlyContinue } else { Get-Command ldid.exe,ldid -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($ldid) {
        $ldidPath = if ($ldid.Source) { $ldid.Source } else { $ldid }
        & $ldidPath -S $probeDylib
        if ($LASTEXITCODE -ne 0) { throw 'ldid failed to sign the real Mach-O probe dylib.' }
        & $ldidPath -e $probeDylib *> $null
        if ($LASTEXITCODE -ne 0) { throw 'ldid could not read entitlements after signing the Mach-O probe.' }
        Write-Host 'PASS: ldid modified and re-read the real Mach-O probe dylib.'
    } else {
        Write-Host 'SKIP: signing; set THEOS_LDID to test actual Mach-O modification.'
    }
} else {
    Write-Host 'SKIP: SDK/link probe; set THEOS_SDKROOT or IOS_SDK_ROOT to a user-supplied iPhoneOS SDK.'
}

if (-not $SdkRoot) {
    $ldid = if ($Ldid) { Get-Command $Ldid -ErrorAction SilentlyContinue } else { Get-Command ldid.exe,ldid -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if ($ldid) {
        $ldidPath = if ($ldid.Source) { $ldid.Source } else { $ldid }
        $signProbe = Join-Path $OutputDirectory 'probe-no-sdk.dylib'
        if (-not (Test-Path $signProbe)) { throw "Expected linker probe missing for ldid test: $signProbe" }
        & $ldidPath -S $signProbe
        if ($LASTEXITCODE -ne 0) { throw "ldid failed to sign SDK-independent Mach-O: $ldidPath" }
        & $ldidPath -e $signProbe *> $null
        if ($LASTEXITCODE -ne 0) { throw "ldid failed to read signed Mach-O: $ldidPath" }
        Write-Host "PASS: ldid signed SDK-independent Mach-O $signProbe"
    } else {
        Write-Host 'SKIP: ldid probe; set THEOS_LDID to a native Windows-compatible ldid executable.'
    }
}
