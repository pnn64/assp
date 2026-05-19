[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Fixture,
    [int]$Runs = 3,
    [string]$RawOutput,
    [switch]$NoBuild,
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

if ($ExtraArgs.Count -ne 0) {
    throw "Unexpected argument(s): $($ExtraArgs -join ' '). Quote paths that contain spaces."
}
if ($Runs -lt 1) {
    throw "-Runs must be one or greater."
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

function Read-Profile([string]$path) {
    $profile = @{}
    foreach ($match in Select-String -Path $path -Pattern '^profile_([^:]+):\s*(\d+)') {
        $profile[$match.Matches[0].Groups[1].Value] = [double]$match.Matches[0].Groups[2].Value
    }
    if (!$profile.ContainsKey("frequency") -or !$profile.ContainsKey("total_ticks")) {
        throw "No profile fields were found in $path. Run assp.exe with chart argument 'profile'."
    }
    [pscustomobject]$profile
}

if (!$Fixture) {
    $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
}
$resolvedFixture = Resolve-InputPath $Fixture "Fixture"

if (!$RawOutput) {
    $RawOutput = Join-Path $target "assp_phase_profile_raw.txt"
}
if (![System.IO.Path]::IsPathRooted($RawOutput)) {
    $RawOutput = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $RawOutput))
}
$rawDir = [System.IO.Path]::GetDirectoryName($RawOutput)
if (![string]::IsNullOrWhiteSpace($rawDir)) {
    New-Item -ItemType Directory -Force $rawDir | Out-Null
}

if (!$NoBuild) {
    & (Join-Path $root "build.ps1") -PhaseProfile
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} elseif (!(Test-Path -LiteralPath $asspExe)) {
    throw "ASSP executable was not found at $asspExe. Omit -NoBuild or run .\build.ps1 first."
}

$profiles = @()
for ($run = 1; $run -le $Runs; $run++) {
    $runPath = if ($Runs -eq 1) {
        $RawOutput
    } else {
        $dir = [System.IO.Path]::GetDirectoryName($RawOutput)
        $name = [System.IO.Path]::GetFileNameWithoutExtension($RawOutput)
        $ext = [System.IO.Path]::GetExtension($RawOutput)
        Join-Path $dir "$name.$run$ext"
    }

    & $asspExe $resolvedFixture profile *> $runPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $profiles += Read-Profile $runPath
}

$freq = [double]$profiles[0].frequency
$totalAvg = ($profiles | ForEach-Object { $_.total_ticks } | Measure-Object -Average).Average
$allKeys = $profiles[0].PSObject.Properties.Name |
    Where-Object { $_ -notin @("frequency", "total_ticks") -and $_ -notmatch '^write_' }
$keys = $allKeys | Where-Object { $_ -notmatch '_(cycles|count)$' }
$cycleKeys = $allKeys | Where-Object { $_ -match '_cycles$' }
$countKeys = $allKeys | Where-Object { $_ -match '_count$' }

$rows = foreach ($key in $keys) {
    $avg = ($profiles | ForEach-Object { $_.$key } | Measure-Object -Average).Average
    [pscustomobject]@{
        Phase = $key
        Milliseconds = $avg / $freq * 1000.0
        Percent = $avg / $totalAvg * 100.0
        Ticks = [int64]$avg
    }
}

$rows |
    Sort-Object Milliseconds -Descending |
    Format-Table Phase,
        @{n = "ms"; e = { "{0:N3}" -f $_.Milliseconds }},
        @{n = "pct"; e = { "{0:N2}" -f $_.Percent }},
        Ticks -AutoSize

$writeCalls = ($profiles | ForEach-Object { $_.write_calls } | Measure-Object -Average).Average
$writeBytes = ($profiles | ForEach-Object { $_.write_bytes } | Measure-Object -Average).Average
Write-Host ("write_calls avg: {0:N0}" -f $writeCalls)
Write-Host ("write_bytes avg: {0:N0}" -f $writeBytes)
Write-Host ("total avg ms: {0:N3}" -f ($totalAvg / $freq * 1000.0))

if ($cycleKeys.Count -gt 0) {
    $cycleRows = foreach ($key in $cycleKeys) {
        $avg = ($profiles | ForEach-Object { $_.$key } | Measure-Object -Average).Average
        [pscustomobject]@{
            Counter = $key
            Cycles = $avg
        }
    }
    $cycleTotal = ($cycleRows | ForEach-Object { $_.Cycles } | Measure-Object -Sum).Sum
    Write-Host ""
    $cycleRows |
        Sort-Object Cycles -Descending |
        Format-Table Counter,
            @{n = "cycles"; e = { "{0:N0}" -f $_.Cycles }},
            @{n = "pct"; e = { if ($cycleTotal -gt 0) { "{0:N2}" -f ($_.Cycles / $cycleTotal * 100.0) } else { "0.00" } }} -AutoSize
}

if ($countKeys.Count -gt 0) {
    Write-Host ""
    $countRows = foreach ($key in ($countKeys | Sort-Object)) {
        $avg = ($profiles | ForEach-Object { $_.$key } | Measure-Object -Average).Average
        [pscustomobject]@{
            Counter = $key
            Average = $avg
        }
    }
    $countRows |
        Format-Table Counter,
            @{n = "avg"; e = { "{0:N0}" -f $_.Average }} -AutoSize
}
