[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$PacksDir,
    [string]$BaselineDir,
    [string]$AsspExe,
    [string]$RunnerExe,
    [ValidateSet("auto", "hash", "path")]
    [string]$BaselineLayout = "auto",
    [string]$BaselineSuffix,
    [ValidateSet("mixed", "json")]
    [string]$CompareMode = "mixed",
    [string]$Filter,
    [string[]]$Skip = @(),
    [switch]$Exact,
    [switch]$Update,
    [switch]$List,
    [switch]$Quiet,
    [switch]$NoBuild,
    [switch]$KeepTemp,
    [switch]$IncludeRaw,
    [int]$Jobs,
    [int]$MaxFailures = 50,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($root)) {
    $root = (Get-Location).Path
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

function Resolve-OutputPath([string]$path, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "$label path is empty."
    }
    if ([System.IO.Path]::IsPathRooted($path)) {
        return [System.IO.Path]::GetFullPath($path)
    }
    [System.IO.Path]::GetFullPath((Join-Path $root $path))
}

function Strip-Separator([string[]]$args) {
    if ($args.Count -eq 0) {
        return @()
    }
    if ($args[0] -ne "--") {
        return $args
    }
    if ($args.Count -eq 1) {
        return @()
    }
    return $args[1..($args.Count - 1)]
}

if (!$PacksDir) {
    $PacksDir = Join-Path (Split-Path -Parent $root) "assp\tests\data\packs"
}
if (!$BaselineDir) {
    $BaselineDir = Join-Path $root "tests\data\baseline"
}
if (!$AsspExe) {
    $AsspExe = Join-Path $root "target\assp.exe"
}
if (!$RunnerExe) {
    $RunnerExe = Join-Path $root "target\debug\examples\assp_baseline.exe"
}

$resolvedPacks = Resolve-InputPath $PacksDir "Packs"
$resolvedBaseline = Resolve-OutputPath $BaselineDir "Baseline"

if (!$NoBuild) {
    & (Join-Path $root "build.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $cargoArgs = @("build", "--manifest-path", (Join-Path $root "Cargo.toml"), "--example", "assp_baseline")
    if ($Quiet) {
        $cargoArgs += "--quiet"
    }
    & cargo @cargoArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$resolvedAssp = Resolve-InputPath $AsspExe "ASSP executable"
$resolvedRunner = Resolve-InputPath $RunnerExe "ASSP baseline runner"

$runnerArgs = @(
    "--packs-dir", $resolvedPacks,
    "--baseline-dir", $resolvedBaseline,
    "--assp-exe", $resolvedAssp,
    "--baseline-layout", $BaselineLayout,
    "--compare-mode", $CompareMode
)

if ($Quiet) {
    $runnerArgs += "--quiet"
}
if ($List) {
    $runnerArgs += "--list"
}
if ($Exact) {
    $runnerArgs += "--exact"
}
if ($Update) {
    $runnerArgs += "--update"
}
if ($KeepTemp) {
    $runnerArgs += "--keep-temp"
}
if ($IncludeRaw) {
    $runnerArgs += "--include-raw"
}
if ($Jobs -gt 0) {
    $runnerArgs += "--jobs"
    $runnerArgs += $Jobs.ToString()
}
if ($MaxFailures -ge 0) {
    $runnerArgs += "--max-failures"
    $runnerArgs += $MaxFailures.ToString()
}
if (![string]::IsNullOrWhiteSpace($BaselineSuffix)) {
    $runnerArgs += "--baseline-suffix"
    $runnerArgs += $BaselineSuffix
}
foreach ($skipPattern in $Skip) {
    $runnerArgs += "--skip"
    $runnerArgs += $skipPattern
}
if (![string]::IsNullOrWhiteSpace($Filter)) {
    $runnerArgs += "--filter"
    $runnerArgs += $Filter
}
$runnerArgs += @(Strip-Separator $ExtraArgs)

& $resolvedRunner @runnerArgs
exit $LASTEXITCODE
