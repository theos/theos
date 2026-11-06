[CmdletBinding()]
param([string]$TheosPath = $env:THEOS)

$ErrorActionPreference = 'Stop'
$failed = $false

if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Error 'FAIL: Windows x64 is required.'
    exit 1
}
if (-not $TheosPath -or -not (Test-Path (Join-Path $TheosPath 'makefiles/common.mk'))) {
    Write-Error 'FAIL: THEOS does not point to a Theos checkout.'
    exit 1
}
Write-Host 'PASS: Windows x64 and Theos checkout detected.'
$testRoot = Join-Path $TheosPath 'tests/windows'
if (Test-Path (Join-Path $testRoot 'test_helper.py')) {
    python -m unittest discover -s $testRoot -v
    if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: Windows helper integration tests'; $failed = $true } else { Write-Host 'PASS: Windows helper integration tests' }
}
if ((Get-Command make -ErrorAction SilentlyContinue) -and (Get-Command bash -ErrorAction SilentlyContinue)) {
    $project = Join-Path $testRoot 'project'
    $env:THEOS = $TheosPath
    make -C $project -n all THEOS=$TheosPath
    if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: Windows GNU Make parse smoke'; $failed = $true } else { Write-Host 'PASS: Windows GNU Make parse smoke' }
} else {
    Write-Host 'SKIP: Windows GNU Make parse smoke requires make and bash'
}

$tools = @('make', 'clang', 'tar', 'python')
$optionalTools = @('bash', 'ldid')
foreach ($tool in $tools) {
    $command = Get-Command $tool -ErrorAction SilentlyContinue
    if ($command) {
        & $command.Source --version *> $null
        if ($LASTEXITCODE -ne 0 -and $tool -in @('clang', 'make', 'bash', 'python')) {
            Write-Host "BROKEN: $tool could not execute --version"
            $failed = $true
        } else {
            Write-Host "FOUND: $tool ($($command.Source))"
        }
    } else {
        Write-Host "MISSING: $tool"
        $failed = $true
    }
}
foreach ($tool in $optionalTools) {
    $command = Get-Command $tool -ErrorAction SilentlyContinue
    if ($command) { Write-Host "FOUND (optional): $tool ($($command.Source))" } else { Write-Host "MISSING (optional): $tool" }
}

$iosSdks = @(Get-ChildItem (Join-Path $TheosPath 'sdks') -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^iPhoneOS.*\.sdk$' })
$sdkRoot = if ($env:THEOS_SDKROOT) { $env:THEOS_SDKROOT } elseif ($env:IOS_SDK_ROOT) { $env:IOS_SDK_ROOT } else { $null }
if (-not $sdkRoot) {
    $sdk = Get-ChildItem (Join-Path $TheosPath 'sdks') -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^iPhoneOS.*\.sdk$' } | Select-Object -First 1
    if ($sdk) { $sdkRoot = $sdk.FullName }
}
if ($sdkRoot) {
    & python (Join-Path $TheosPath 'bin/theos-windows.py') sdk-info $sdkRoot *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "FOUND: validated iOS SDK $sdkRoot" } else { Write-Host "INVALID: iOS SDK at $sdkRoot"; $failed = $true }
} else { Write-Host 'MISSING: iPhoneOS SDK (set THEOS_SDKROOT or IOS_SDK_ROOT)'; $failed = $true }
$linker = if ($env:THEOS_LD64_LLD) { Get-Command $env:THEOS_LD64_LLD -ErrorAction SilentlyContinue } else { Get-Command ld64.lld.exe,ld64.lld,ld64 -ErrorAction SilentlyContinue | Select-Object -First 1 }
if (-not $linker) {
    $linker = Get-ChildItem (Join-Path $TheosPath 'toolchain') -Filter '*-apple-darwin*-ld*' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
}
if ($linker) {
    $linkerPath = if ($linker.Source) { $linker.Source } elseif ($linker.Path) { $linker.Path } else { $linker.FullName }
    & $linkerPath --help *> $null
    if ($LASTEXITCODE -eq 0 -and $linkerPath -match 'ld64(\.lld)?(\.exe)?$') { Write-Host "FOUND: Mach-O linker $linkerPath" } else { Write-Host "UNVERIFIED: linker candidate $linkerPath"; $failed = $true }
} else { Write-Host 'MISSING: ld64.lld or compatible Apple Mach-O linker'; $failed = $true }
if (Test-Path (Join-Path $TheosPath 'bin/theos-windows.py')) { Write-Host 'FOUND: native Windows Debian builder' }

if ($failed) {
    Write-Host 'ENVIRONMENT CHECK INCOMPLETE: native build capability has not been established.'
    exit 2
}
Write-Host 'Dependency presence check passed. This does not prove end-to-end project builds.'
