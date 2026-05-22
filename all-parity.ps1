[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$RsspPath,
    [string]$AsspExe,
    [string]$Filter,
    [string[]]$Skip = @(),
    [switch]$NoBuild,
    [switch]$Quiet,
    [switch]$Exact,
    [switch]$List,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArgs
)

$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($root)) {
    $root = (Get-Location).Path
}

if (!$RsspPath) {
    $RsspPath = Join-Path (Split-Path -Parent $root) "rssp"
}
if (!$AsspExe) {
    $AsspExe = Join-Path $root "target\assp.exe"
}

function Resolve-ExistingPath([string]$path, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "$label path is empty."
    }
    $resolved = @(Resolve-Path -LiteralPath $path -ErrorAction SilentlyContinue)
    if ($resolved.Count -eq 0) {
        throw "$label path was not found: $path"
    }
    $resolved[0].ProviderPath
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

$resolvedRssp = Resolve-ExistingPath $RsspPath "RSSP"
$rsspManifest = Join-Path $resolvedRssp "Cargo.toml"
if (!(Test-Path -LiteralPath $rsspManifest)) {
    throw "RSSP Cargo.toml was not found at $rsspManifest. Pass -RsspPath with the RSSP repository root."
}

if (!$NoBuild) {
    & (Join-Path $root "build.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$resolvedAsspExe = Resolve-ExistingPath $AsspExe "ASSP executable"
$passThrough = @()
if ($Quiet) {
    $passThrough += "--quiet"
}
if ($List) {
    $passThrough += "--list"
}
if ($Exact) {
    $passThrough += "--exact"
}
foreach ($skipPattern in $Skip) {
    $passThrough += "--skip"
    $passThrough += $skipPattern
}
if (![string]::IsNullOrWhiteSpace($Filter)) {
    $passThrough += $Filter
}
$passThrough += @(Strip-Separator $TestArgs)

$oldBackend = $env:RSSP_ALL_PARITY_BACKEND
$oldAsspExe = $env:ASSP_EXE
$exitCode = 0

try {
    $env:RSSP_ALL_PARITY_BACKEND = "assp"
    $env:ASSP_EXE = $resolvedAsspExe

    $cargoArgs = @("test", "--manifest-path", $rsspManifest, "--test", "all_parity", "--") + $passThrough
    & cargo @cargoArgs
    $exitCode = $LASTEXITCODE
}
finally {
    if ($null -eq $oldBackend) {
        Remove-Item Env:RSSP_ALL_PARITY_BACKEND -ErrorAction SilentlyContinue
    } else {
        $env:RSSP_ALL_PARITY_BACKEND = $oldBackend
    }

    if ($null -eq $oldAsspExe) {
        Remove-Item Env:ASSP_EXE -ErrorAction SilentlyContinue
    } else {
        $env:ASSP_EXE = $oldAsspExe
    }
}

exit $exitCode
