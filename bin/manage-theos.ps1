[CmdletBinding()]
param(
    [ValidateSet('Update', 'Health', 'Uninstall')]
    [string]$Action = 'Health',
    [string]$TheosPath = $env:THEOS,
    [switch]$KeepUserPathEntry
)

$ErrorActionPreference = 'Stop'

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH."
    }
}

if (-not $TheosPath) { throw 'THEOS is not set. Pass -TheosPath explicitly.' }
$resolved = [IO.Path]::GetFullPath($TheosPath)
$gitDir = Join-Path $resolved '.git'

switch ($Action) {
    'Update' {
        Require-Command 'git'
        if (-not (Test-Path $gitDir)) { throw "$resolved is not a Git checkout." }
        git -C $resolved pull --rebase=false
        if ($LASTEXITCODE -ne 0) { throw 'git pull failed.' }
        git -C $resolved submodule update --init --recursive
        if ($LASTEXITCODE -ne 0) { throw 'git submodule update failed.' }
        $bash = Get-Command bash.exe -ErrorAction SilentlyContinue
        if (-not $bash) { throw 'Updating Theos requires bash.exe (Git for Windows).' }
        & $bash.Source (Join-Path $resolved 'bin/post-update')
        if ($LASTEXITCODE -ne 0) { throw 'Theos post-update failed.' }
        Write-Host "Updated Theos at $resolved"
    }
    'Health' {
        if (-not (Test-Path (Join-Path $resolved 'makefiles/common.mk'))) { throw "$resolved is not a Theos checkout." }
        & (Join-Path $resolved 'bin/test-windows.ps1') -TheosPath $resolved
        exit $LASTEXITCODE
    }
    'Uninstall' {
        if (-not (Test-Path $resolved)) { Write-Host "Nothing to remove at $resolved"; exit 0 }
        if (-not (Test-Path $gitDir)) { throw "Refusing to remove non-Git directory: $resolved" }
        $userTheos = [Environment]::GetEnvironmentVariable('THEOS', 'User')
        if ($userTheos -and ([IO.Path]::GetFullPath($userTheos) -eq $resolved)) {
            [Environment]::SetEnvironmentVariable('THEOS', $null, 'User')
        }
        if (-not $KeepUserPathEntry) {
            $bin = Join-Path $resolved 'bin'
            $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
            $entries = @($userPath -split ';' | Where-Object { $_ -and ([IO.Path]::GetFullPath($_) -ne $resolved -and [IO.Path]::GetFullPath($_) -ne $bin) })
            [Environment]::SetEnvironmentVariable('Path', ($entries -join ';'), 'User')
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
        Write-Host "Removed Theos checkout at $resolved"
    }
}
