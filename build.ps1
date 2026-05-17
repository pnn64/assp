param(
    [switch]$RunFixture,
    [string]$Fixture,
    [int]$Chart = 0,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $root "target"
$exe = Join-Path $target "asmssp.exe"
$include = (Join-Path $root "include") + [System.IO.Path]::DirectorySeparatorChar

if (!(Get-Command nasm -ErrorAction SilentlyContinue)) {
    throw "nasm was not found on PATH."
}

if ($Clean -and (Test-Path $target)) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

New-Item -ItemType Directory -Force $target | Out-Null

$linkerCommand = Get-Command lld-link.exe -ErrorAction SilentlyContinue
$linkFlavorArgs = @()
if (!$linkerCommand) {
    $linkerCommand = Get-Command link.exe -ErrorAction SilentlyContinue
}
if (!$linkerCommand) {
    $rustLld = Get-ChildItem "$env:USERPROFILE\.rustup\toolchains" -Recurse -Filter rust-lld.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*x86_64-pc-windows-msvc*" } |
        Select-Object -First 1
    if ($rustLld) {
        $linkerCommand = $rustLld
        $linkFlavorArgs = @("-flavor", "link")
    }
}
if (!$linkerCommand) {
    throw "No Windows linker found. Install Visual Studio Build Tools, LLVM lld-link, or provide rust-lld.exe."
}
$linkerPath = if ($linkerCommand.Source) { $linkerCommand.Source } else { $linkerCommand.FullName }

$kitRoot = "C:\Program Files (x86)\Windows Kits\10\Lib"
$kitLib = Get-ChildItem $kitRoot -Directory |
    Sort-Object Name -Descending |
    ForEach-Object { Join-Path $_.FullName "um\x64" } |
    Where-Object { Test-Path (Join-Path $_ "Kernel32.Lib") } |
    Select-Object -First 1

if (!$kitLib) {
    throw "Windows SDK x64 import libraries were not found."
}

$objs = @()
foreach ($asm in Get-ChildItem (Join-Path $root "asm") -Recurse -Filter "*.asm" | Sort-Object FullName) {
    $rel = $asm.FullName.Substring((Join-Path $root "asm").Length).TrimStart('\', '/')
    $objName = ($rel -replace '[\\/]', '_') -replace '\.asm$', '.obj'
    $obj = Join-Path $target $objName
    & nasm -f win64 "-I$include" $asm.FullName -o $obj
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $objs += $obj
}

$linkArgs = @(
    "/nologo",
    "/machine:x64",
    "/subsystem:console",
    "/entry:start",
    "/nodefaultlib",
    "/out:$exe"
) + $objs + @((Join-Path $kitLib "Kernel32.Lib"))

& $linkerPath @linkFlavorArgs @linkArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "built $exe"

if ($RunFixture -or $Fixture) {
    if (!$Fixture) {
        $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
    }

    $resolvedFixture = (Resolve-Path $Fixture).Path
    $runArgs = @($resolvedFixture, $Chart)

    Write-Host "running $exe $($runArgs -join ' ')"
    Push-Location $root
    try {
        & $exe @runArgs
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }
}
