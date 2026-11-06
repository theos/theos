[CmdletBinding()]
param(
    [string]$InstallPath = (Join-Path $HOME 'theos'),
    [switch]$SkipPathUpdate
)

$ErrorActionPreference = 'Stop'

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH. Install Git for Windows and GNU Make/LLVM separately."
    }
}

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'The native Windows host currently requires Windows x64.'
}
Require-Command 'git'

$resolvedPath = [IO.Path]::GetFullPath($InstallPath)
if (Test-Path (Join-Path $resolvedPath '.git')) {
    Write-Host "Updating Theos checkout at $resolvedPath"
    git -C $resolvedPath pull --rebase=false
    if ($LASTEXITCODE -ne 0) { throw 'git pull failed.' }
    git -C $resolvedPath submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw 'git submodule update failed.' }
} elseif (Test-Path $resolvedPath) {
    if ((Get-ChildItem -Force $resolvedPath | Measure-Object).Count -ne 0) {
        throw "Install path exists and is not an empty Theos checkout: $resolvedPath"
    }
    git clone --recursive https://github.com/theos/theos.git $resolvedPath
} else {
    $parent = Split-Path -Parent $resolvedPath
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    git clone --recursive https://github.com/theos/theos.git $resolvedPath
}
if ($LASTEXITCODE -ne 0) { throw 'Theos checkout operation failed.' }

[Environment]::SetEnvironmentVariable('THEOS', $resolvedPath, 'User')
$env:THEOS = $resolvedPath
if (-not $SkipPathUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $binPath = Join-Path $resolvedPath 'bin'
    $entries = @($userPath -split ';' | Where-Object { $_ })
    if ($entries -notcontains $binPath) {
        [Environment]::SetEnvironmentVariable('Path', (@($entries) + $binPath) -join ';', 'User')
    }
}

Write-Host "Theos source installed at $resolvedPath"
Write-Host 'THEOS is set for this process and the current Windows user.'
Write-Host 'NOTE: native Windows build support is experimental; Apple SDK, Mach-O linker, and packaging tools are not installed by this script.'
& (Join-Path $PSScriptRoot 'test-windows.ps1') -TheosPath $resolvedPath
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Theos was installed, but the dependency check is incomplete. See WINDOWS.md before attempting a build.'
}
