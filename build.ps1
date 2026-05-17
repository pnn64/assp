param(
    [switch]$Release = $true,
    [switch]$DebugBuild,
    [switch]$RunFixture,
    [string]$Fixture,
    [int]$Chart = 0,
    [switch]$ListCharts
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($DebugBuild) {
    $Release = $false
}

if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw "cargo was not found on PATH."
}

if (!(Get-Command nasm -ErrorAction SilentlyContinue)) {
    throw "nasm was not found on PATH."
}

Push-Location $root
try {
    $cargoArgs = @("build", "--bin", "asmssp")
    if ($Release) {
        $cargoArgs += "--release"
        $profile = "release"
    } else {
        $profile = "debug"
    }

    & cargo @cargoArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $exe = Join-Path $root "target\$profile\asmssp.exe"
    Write-Host "built $exe"

    if ($RunFixture -or $Fixture) {
        if (!$Fixture) {
            $Fixture = Join-Path $root "..\rssp\crates\rssp\benches\fixtures\camellia_mix.ssc"
        }

        $resolvedFixture = (Resolve-Path $Fixture).Path
        $runArgs = @($resolvedFixture)
        if ($ListCharts) {
            $runArgs += "--list"
        } else {
            $runArgs += @("--chart", $Chart)
        }

        Write-Host "running $exe $($runArgs -join ' ')"
        & $exe @runArgs
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
} finally {
    Pop-Location
}

