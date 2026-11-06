[CmdletBinding()]
param(
    [ValidateSet('choco', 'winget', 'portable', 'llvm-official', 'full-official')]
    [string]$PackageManager = 'choco',
    [switch]$InstallMake,
    [switch]$InstallPerl,
    [string]$PortableUrl,
    [Parameter(Mandatory = $false)][ValidatePattern('^[0-9a-fA-F]{64}$')][string]$PortableSha256,
    [string]$PortableDestination = (Join-Path $HOME 'theos-toolchain\llvm'),
    [string]$CacheDirectory = (Join-Path $HOME 'theos-toolchain\cache'),
    [string]$TheosPath = $env:THEOS,
    [switch]$AddToUserPath,
    [switch]$ConfigureTheos
)

$ErrorActionPreference = 'Stop'
function Require([string]$name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "$name is required to install the Windows toolchain." }
}
function Download-Verified([string]$url, [string]$sha256, [string]$destination, [string]$cacheDirectory) {
    if (-not $url -or -not $sha256) { throw 'Portable mode requires -PortableUrl and a 64-character -PortableSha256.' }
    if ($url -notmatch '^https://') { throw 'Toolchain downloads must use HTTPS.' }
    New-Item -ItemType Directory -Force -Path $cacheDirectory | Out-Null
    $leaf = [Uri]::UnescapeDataString([IO.Path]::GetFileName(([Uri]$url).AbsolutePath))
    $archive = Join-Path $cacheDirectory $leaf
    if (-not (Test-Path -LiteralPath $archive)) { Invoke-WebRequest -Uri $url -OutFile $archive }
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actual -ne $sha256.ToUpperInvariant()) { throw "SHA-256 mismatch: expected $sha256, got $actual" }
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    $reuseMarker = Join-Path $destination '.theos-toolchain-installed'
    if (Test-Path $reuseMarker) {
        Write-Host "Verified archive already extracted under $destination; reusing it."
        return
    }
    if ($archive.EndsWith('.tar.zst', [StringComparison]::OrdinalIgnoreCase)) {
        $sevenZip = Get-Command 7z.exe,7za.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
        if (-not $sevenZip -or -not $tar) { throw 'Extracting official .tar.zst requires 7-Zip and tar.exe.' }
        & $sevenZip.Source x '-y' "-o$cacheDirectory" $archive
        if ($LASTEXITCODE -ne 0) { throw 'LLVM Zstandard decompression failed.' }
        $tarPath = $archive -replace '\.tar\.zst$', '.tar'
        & $tar.Source -xf $tarPath -C $destination
        if ($LASTEXITCODE -ne 0) { throw 'LLVM tar extraction failed.' }
    } else {
        $sevenZip = Get-Command 7z.exe,7za.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($archive.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase) -and $sevenZip) {
            & $sevenZip.Source x '-y' "-o$destination" $archive
        } else {
            $extractor = Join-Path $PSScriptRoot 'theos-windows.py'
            & python $extractor extract $archive $destination
        }
        if ($LASTEXITCODE -ne 0) { throw 'Toolchain archive extraction failed.' }
    }
    New-Item -ItemType File -Force -Path $reuseMarker | Out-Null
}

function Add-UserPath([string]$directory) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @($userPath -split ';' | Where-Object { $_ })
    if ($entries -notcontains $directory) { [Environment]::SetEnvironmentVariable('Path', (@($entries) + $directory) -join ';', 'User') }
}

switch ($PackageManager) {
    'full-official' {
        if (-not [Environment]::Is64BitOperatingSystem) { throw 'The official toolchain artifacts require Windows x64.' }
        $PortableUrl = 'https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.5/clang%2Bllvm-23.1.5-x86_64-pc-windows-msvc.tar.zst'
        $PortableSha256 = 'b2be33385ddc86e83511417a060de927ae8b09d1f3017cc3cdce5c73cd5029d7'
        $PortableDestination = Join-Path $HOME 'theos-toolchain\llvm-23.1.5'
        $llvmUrl = 'https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.5/clang%2Bllvm-23.1.5-x86_64-pc-windows-msvc.tar.zst'
        $llvmHash = 'b2be33385ddc86e83511417a060de927ae8b09d1f3017cc3cdce5c73cd5029d7'
        Download-Verified $llvmUrl $llvmHash $PortableDestination $CacheDirectory
        $ldidUrl = 'https://github.com/ProcursusTeam/ldid/releases/download/v2.1.5-procursus7/ldid_w64_x86_64.exe'
        $ldidHash = '77a3f012e09619f8cfb5902eba38a00b973da5561ac592c530efb68155f7e6f3'
        $ldidArchive = Join-Path $CacheDirectory 'ldid-v2.1.5-procursus7-w64-x86_64.exe'
        if (-not (Test-Path $ldidArchive)) { Invoke-WebRequest -Uri $ldidUrl -OutFile $ldidArchive }
        $actualLdidHash = (Get-FileHash -LiteralPath $ldidArchive -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualLdidHash -ne $ldidHash) { throw "ldid SHA-256 mismatch: expected $ldidHash, got $actualLdidHash" }
        $ldidInstall = Join-Path $HOME 'theos-toolchain\ldid-v2.1.5'
        New-Item -ItemType Directory -Force -Path $ldidInstall | Out-Null
        $ldidExe = Join-Path $ldidInstall 'ldid.exe'
        Copy-Item -LiteralPath $ldidArchive -Destination $ldidExe -Force
        $ldidPe = & python (Join-Path $PSScriptRoot 'theos-windows.py') pe-info $ldidExe
        if ($LASTEXITCODE -ne 0 -or $ldidPe -ne 'x86_64') { throw "ldid is not a native Windows x64 executable: $ldidPe" }
        $perlUrl = 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54231_64bit/strawberry-perl-5.42.3.1-64bit-portable.zip'
        $perlHash = '6a081a811781c30aca51dbc036afd93092af91e3297901f02c17043795a10690'
        $perlDestination = Join-Path $HOME 'theos-toolchain\strawberry-perl-5.42.3.1'
        Download-Verified $perlUrl $perlHash $perlDestination $CacheDirectory
        $perlExecutable = Get-ChildItem -LiteralPath $perlDestination -Filter perl.exe -File -Recurse | Select-Object -First 1
        if (-not $perlExecutable) { throw 'Strawberry Perl archive did not contain perl.exe.' }
        $makeCommand = Get-Command make.exe -ErrorAction SilentlyContinue
        if (-not $makeCommand) { winget install --id ezwinports.make --exact --scope user --accept-source-agreements --accept-package-agreements --silent; if ($LASTEXITCODE -ne 0) { throw 'GNU Make installation failed.' }; $makeCommand = Get-Command make.exe -ErrorAction SilentlyContinue }
        if (-not $makeCommand) { throw 'GNU Make package installed but make.exe is not discoverable in PATH.' }
        $llvmExecutable = Get-ChildItem -LiteralPath $PortableDestination -Filter clang.exe -File -Recurse | Select-Object -First 1
        if (-not $llvmExecutable) { throw 'LLVM archive did not contain clang.exe.' }
        $llvmBin = $llvmExecutable.Directory.FullName
        $clangxx = Join-Path $llvmBin 'clang++.exe'
        if (-not (Test-Path $clangxx)) { throw 'LLVM archive is missing clang++.exe.' }
        $peInfo = & python (Join-Path $PSScriptRoot 'theos-windows.py') pe-info $llvmExecutable.FullName
        if ($LASTEXITCODE -ne 0 -or $peInfo -ne 'x86_64') { throw "clang.exe architecture validation failed: $peInfo" }
        $env:PATH = "$llvmBin;$($perlExecutable.Directory.FullName);$(Join-Path $perlDestination 'c\bin');$env:PATH"
        $env:THEOS_LLVM_BIN = $llvmBin
        $env:THEOS_LD64_LLD = Join-Path $llvmBin 'ld64.lld.exe'
        $env:THEOS_LDID = $ldidExe
        $toolPaths = @($llvmBin, $perlExecutable.Directory.FullName, (Join-Path $perlDestination 'c\bin'), $ldidInstall)
        if ($AddToUserPath) { foreach ($toolPath in $toolPaths) { Add-UserPath $toolPath } }
        if ($env:GITHUB_PATH) { foreach ($toolPath in $toolPaths) { Add-Content -LiteralPath $env:GITHUB_PATH -Value $toolPath } }
        if ($env:GITHUB_ENV) {
            Add-Content -LiteralPath $env:GITHUB_ENV -Value "THEOS_LLVM_BIN=$llvmBin"
            Add-Content -LiteralPath $env:GITHUB_ENV -Value "THEOS_LD64_LLD=$(Join-Path $llvmBin 'ld64.lld.exe')"
            Add-Content -LiteralPath $env:GITHUB_ENV -Value "THEOS_LDID=$ldidExe"
        }
    }
    'llvm-official' {
        if (-not [Environment]::Is64BitOperatingSystem) { throw 'The official LLVM artifact requires Windows x64.' }
        $PortableUrl = 'https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.5/clang%2Bllvm-23.1.5-x86_64-pc-windows-msvc.tar.zst'
        $PortableSha256 = 'b2be33385ddc86e83511417a060de927ae8b09d1f3017cc3cdce5c73cd5029d7'
        $archiveTool = Get-Command tar.exe -ErrorAction SilentlyContinue
        $sevenZip = Get-Command 7z.exe,7za.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $archiveTool -and -not $sevenZip) { throw 'Windows tar.exe/bsdtar or 7-Zip is required to unpack the official zstd artifact.' }
        Download-Verified $PortableUrl $PortableSha256 $PortableDestination $CacheDirectory
        $archivePath = Join-Path $CacheDirectory ([IO.Path]::GetFileName(([Uri]$PortableUrl).AbsolutePath))
        if ($sevenZip) {
            & $sevenZip.Source x '-y' "-o$CacheDirectory" $archivePath
            if ($LASTEXITCODE -ne 0) { throw 'Verified LLVM zstd decompression failed.' }
            $tarPath = [IO.Path]::ChangeExtension($archivePath, '.tar')
            & $archiveTool.Source -xf $tarPath -C $PortableDestination
        } else {
            & $archiveTool.Source -xf $archivePath -C $PortableDestination
        }
        if ($LASTEXITCODE -ne 0) { throw 'Verified LLVM archive extraction failed.' }
        $installedClang = Get-ChildItem -LiteralPath $PortableDestination -Filter clang.exe -File -Recurse | Select-Object -First 1
        if (-not $installedClang) { throw 'Verified LLVM archive did not contain clang.exe.' }
        $env:PATH = "$($installedClang.Directory.FullName);$env:PATH"
        if ($AddToUserPath) { Add-UserPath $installedClang.Directory.FullName }
    }
    'portable' {
        Download-Verified $PortableUrl $PortableSha256 $PortableDestination $CacheDirectory
        $clang = Get-ChildItem -LiteralPath $PortableDestination -Filter clang.exe -File -Recurse | Select-Object -First 1
        if (-not $clang) { throw 'Verified archive did not contain clang.exe.' }
        $llvmBin = $clang.Directory.FullName
        $extractor = Join-Path $PSScriptRoot 'theos-windows.py'
        $peInfo = & python $extractor pe-info $clang.FullName
        if ($LASTEXITCODE -ne 0 -or $peInfo -ne 'x86_64') { throw "clang.exe is not a native Windows x64 executable: $peInfo" }
        $clangxx = Join-Path $llvmBin 'clang++.exe'
        if (-not (Test-Path $clangxx)) { throw 'LLVM archive is missing clang++.exe.' }
        $peInfo = & python $extractor pe-info $clangxx
        if ($LASTEXITCODE -ne 0 -or $peInfo -ne 'x86_64') { throw "clang++.exe is not a native Windows x64 executable: $peInfo" }
        $machoLinker = Get-ChildItem -LiteralPath $PortableDestination -Filter ld64.lld.exe -File -Recurse | Select-Object -First 1
        if ($machoLinker) { Write-Host "Mach-O linker included: $($machoLinker.FullName)" } else { Write-Warning 'This LLVM archive has no ld64.lld.exe; install/build Mach-O LLD separately.' }
        if ($AddToUserPath) { Add-UserPath $llvmBin }
        $env:PATH = "$llvmBin;$env:PATH"
        if ($ConfigureTheos) {
            if (-not $TheosPath -or -not (Test-Path (Join-Path $TheosPath 'makefiles/common.mk'))) { throw 'ConfigureTheos requires -TheosPath pointing to a Theos checkout.' }
            $rcDir = Join-Path $HOME '.config\theos'
            New-Item -ItemType Directory -Force -Path $rcDir | Out-Null
            $rcFile = Join-Path $rcDir 'rc.mk'
            $lines = @()
            if (Test-Path $rcFile) { $lines = @(Get-Content -LiteralPath $rcFile | Where-Object { $_ -notmatch '^THEOS_(LD64_LLD|LLVM_BIN)\s*[:?+]?=' }) }
            $linkerValue = if ($machoLinker) { $machoLinker.FullName.Replace('\', '/') } else { '' }
            $lines += "THEOS_LLVM_BIN := $($llvmBin.Replace('\', '/'))"
            if ($linkerValue) { $lines += "THEOS_LD64_LLD := $linkerValue" }
            Set-Content -LiteralPath $rcFile -Value $lines -Encoding ascii
            Write-Host "Configured Theos user settings at $rcFile"
        }
        Write-Host "Portable LLVM installed at $llvmBin"
    }
    'choco' {
        Require 'choco'
        choco install llvm -y --no-progress
        if ($InstallMake) { choco install make -y --no-progress }
        if ($InstallPerl) { choco install strawberryperl -y --no-progress }
    }
    'winget' {
        Require 'winget'
        winget install --id LLVM.LLVM --exact --accept-source-agreements --accept-package-agreements
        if ($InstallMake) { winget install --id GnuWin32.Make --exact --accept-source-agreements --accept-package-agreements }
        if ($InstallPerl) { winget install --id StrawberryPerl.StrawberryPerl --exact --accept-source-agreements --accept-package-agreements }
    }
}

$clang = Get-Command clang.exe,clang -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $clang) { throw 'Installation finished without a discoverable Clang executable.' }
Write-Host '=== Theos Windows toolchain installation report ==='
Write-Host "OSArchitecture: $([Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
Write-Host "ProcessArchitecture: $([Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
foreach ($tool in @('clang', 'clang++', 'make', 'perl', 'ld64.lld', 'ldid')) {
    $found = Get-Command $tool -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { Write-Host ("{0}: {1}" -f $tool, $found.Source) } else { Write-Host ("{0}: NOT INSTALLED" -f $tool) }
}
$sdk = if ($env:THEOS_SDKROOT) { $env:THEOS_SDKROOT } elseif ($env:IOS_SDK_ROOT) { $env:IOS_SDK_ROOT } else { $null }
if ($sdk) { Write-Host "iPhoneOS SDK candidate: $sdk (user supplied)" } else { Write-Host 'iPhoneOS SDK: NOT SET; provide THEOS_SDKROOT or IOS_SDK_ROOT' }
Write-Host "LLVM/Clang available at $($clang.Source)"
Write-Host 'Compiler object generation is independent of SDK; SDK headers and ld64.lld are required for iOS dynamic-library linking.'
Write-Host 'ldid is required only when signing/entitlements are requested.'
& (Join-Path $PSScriptRoot 'test-windows-toolchain.ps1')
exit $LASTEXITCODE
