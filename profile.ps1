[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Fixture,
    [string]$Chart = "all",
    [string]$Output,
    [switch]$NoBuild,
    [switch]$KeepOutput,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($root)) {
    $root = (Get-Location).Path
}

$target = Join-Path $root "target"
$asspExe = Join-Path $target "assp.exe"
$profileOutput = Join-Path $target "assp_profile_output.txt"

if ($ExtraArgs.Count -ne 0) {
    throw "Unexpected argument(s): $($ExtraArgs -join ' '). Quote paths that contain spaces."
}

function Resolve-InputPath([string]$path, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "$label path is empty."
    }
    $resolved = @(Resolve-Path -LiteralPath $path -ErrorAction SilentlyContinue)
    if ($resolved.Count -eq 0) {
        throw "$label path was not found: $path"
    }
    $resolved[0].ProviderPath
}

function Resolve-OutputPath([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "Output path is empty."
    }
    if ([System.IO.Path]::IsPathRooted($path)) {
        return [System.IO.Path]::GetFullPath($path)
    }
    [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $path))
}

if (!$Fixture) {
    $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
}
$resolvedFixture = Resolve-InputPath $Fixture "Fixture"

if (!$Output) {
    $stamp = [DateTime]::Now.ToString("yyyyMMdd_HHmmss")
    $Output = Join-Path $target "assp_cpu_$stamp.etl"
}
$etl = Resolve-OutputPath $Output
$etlDir = [System.IO.Path]::GetDirectoryName($etl)
if (![string]::IsNullOrWhiteSpace($etlDir)) {
    New-Item -ItemType Directory -Force $etlDir | Out-Null
}

if (!$NoBuild) {
    & (Join-Path $root "build.ps1") -ProfileSymbols
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} elseif (!(Test-Path -LiteralPath $asspExe)) {
    throw "ASSP executable was not found at $asspExe. Omit -NoBuild or run .\build.ps1 -ProfileSymbols first."
}

$xperf = Get-Command xperf.exe -ErrorAction SilentlyContinue
if (!$xperf) {
    throw "xperf.exe was not found. Install Windows Performance Toolkit."
}

Write-Host "recording CPU samples to $etl"
Write-Host "profiling $asspExe `"$resolvedFixture`" $Chart"

try {
    & $xperf.Source -stop 2>$null | Out-Null
} catch {
    # No active kernel logger is fine; this is just best-effort cleanup.
}
& $xperf.Source -on SysProf -stackwalk Profile -BufferSize 1024 -MaxFile 1024 -FileMode Circular
if ($LASTEXITCODE -ne 0) {
    throw "xperf could not start the kernel profiling session. Run PowerShell as Administrator."
}

try {
    if ($KeepOutput) {
        & $asspExe $resolvedFixture $Chart
    } else {
        & $asspExe $resolvedFixture $Chart *> $profileOutput
    }
    $exitCode = $LASTEXITCODE
} finally {
    & $xperf.Source -d $etl
}

if ($exitCode -ne 0) {
    throw "ASSP exited with code $exitCode while profiling."
}

Write-Host "wrote $etl"
Write-Host "open it in Windows Performance Analyzer and filter CPU Usage (Sampled) to assp.exe."
Write-Host "Symbols: target\assp.pdb and target\assp.map"
