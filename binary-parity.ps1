[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$PacksDir,
    [string]$AsspExe,
    [string]$RsspExe,
    [ValidateSet("owned", "full")]
    [string]$CompareMode = "owned",
    [string]$Filter,
    [string[]]$Skip = @(),
    [switch]$Exact,
    [switch]$List,
    [switch]$Quiet,
    [switch]$KeepTemp,
    [switch]$IncludeZst,
    [switch]$RawOnly,
    [string]$ZstdExe,
    [int]$MaxFailures = 50,
    [double]$Epsilon = 0.000001
)

# Portable binary-vs-binary parity runner.
#
# Drop this script in a folder with:
#   assp.exe
#   rssp.exe
#   packs\<song pack folders>
#
# Then run:
#   powershell -ExecutionPolicy Bypass -File .\binary-parity.ps1
#
# Raw .sm/.ssc files and compressed .sm.zst/.ssc.zst files are scanned by
# default. Compressed inputs require zstd.exe next to this script, zstd on PATH,
# or -ZstdExe. Use -RawOnly to skip compressed inputs.
#
# Default compare mode is "owned": it checks the RSSP-owned fields used by the
# current ASSP parity model. Use -CompareMode full for strict whole-JSON checks.

$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "assp-binary-parity-$PID"

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

function Resolve-DefaultFile([string[]]$candidates, [string]$label) {
    foreach ($candidate in $candidates) {
        if (![string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }
    throw "$label was not found. Pass -$label or place it next to this script."
}

function Get-RelativePath([string]$basePath, [string]$path) {
    $baseFull = [System.IO.Path]::GetFullPath($basePath)
    if (!$baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $baseFull += [System.IO.Path]::DirectorySeparatorChar
    }
    $pathFull = [System.IO.Path]::GetFullPath($path)
    $baseUri = New-Object System.Uri($baseFull)
    $pathUri = New-Object System.Uri($pathFull)
    [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString()).Replace("/", "\")
}

function Test-Number($value) {
    $value -is [byte] -or $value -is [sbyte] -or
        $value -is [int16] -or $value -is [uint16] -or
        $value -is [int32] -or $value -is [uint32] -or
        $value -is [int64] -or $value -is [uint64] -or
        $value -is [single] -or $value -is [double] -or
        $value -is [decimal]
}

function Test-JsonObject($value) {
    $null -ne $value -and $value -is [pscustomobject]
}

function Test-JsonArray($value) {
    $null -ne $value -and $value -is [System.Array] -and -not ($value -is [string])
}

function Convert-ToBriefJson($value) {
    if ($null -eq $value) {
        return "null"
    }
    $text = $value | ConvertTo-Json -Compress -Depth 100
    if ($text.Length -gt 240) {
        return $text.Substring(0, 237) + "..."
    }
    $text
}

function Format-Micros([int64]$micros) {
    "$micros microseconds"
}

function Compare-JsonValue($expected, $actual, [string]$path, [double]$epsilon) {
    if (Test-Number $expected) {
        if (!(Test-Number $actual)) {
            return "$path type mismatch: expected $(Convert-ToBriefJson $expected), actual $(Convert-ToBriefJson $actual)"
        }
        if ([Math]::Abs([double]$expected - [double]$actual) -le $epsilon) {
            return $null
        }
        return "$path mismatch: expected $(Convert-ToBriefJson $expected), actual $(Convert-ToBriefJson $actual)"
    }

    if (Test-JsonArray $expected) {
        if (!(Test-JsonArray $actual)) {
            return "$path type mismatch: expected array, actual $(Convert-ToBriefJson $actual)"
        }
        if ($expected.Count -ne $actual.Count) {
            return "$path.len mismatch: expected $($expected.Count), actual $($actual.Count)"
        }
        for ($i = 0; $i -lt $expected.Count; $i++) {
            $diff = Compare-JsonValue $expected[$i] $actual[$i] "$path[$i]" $epsilon
            if ($diff) {
                return $diff
            }
        }
        return $null
    }

    if (Test-JsonObject $expected) {
        if (!(Test-JsonObject $actual)) {
            return "$path type mismatch: expected object, actual $(Convert-ToBriefJson $actual)"
        }
        $expectedNames = @($expected.PSObject.Properties.Name)
        $actualNames = @($actual.PSObject.Properties.Name)
        foreach ($name in $expectedNames) {
            if ($actualNames -notcontains $name) {
                return "$path.$name missing from actual"
            }
            $diff = Compare-JsonValue $expected.$name $actual.$name "$path.$name" $epsilon
            if ($diff) {
                return $diff
            }
        }
        foreach ($name in $actualNames) {
            if ($expectedNames -notcontains $name) {
                return "$path.$name extra in actual"
            }
        }
        return $null
    }

    if ($expected -eq $actual) {
        return $null
    }
    "$path mismatch: expected $(Convert-ToBriefJson $expected), actual $(Convert-ToBriefJson $actual)"
}

function Try-GetPath($value, [string]$path, [ref]$out) {
    $current = $value
    foreach ($part in $path.Split(".")) {
        if (!(Test-JsonObject $current)) {
            return $false
        }
        $property = $current.PSObject.Properties[$part]
        if ($null -eq $property) {
            return $false
        }
        $current = $property.Value
    }
    $out.Value = $current
    $true
}

function Get-ChartKey($chart) {
    $stepType = $chart.chart_info.step_type
    if ([string]::IsNullOrWhiteSpace($stepType)) {
        $stepType = $chart.step_type
    }
    $difficulty = $chart.chart_info.difficulty
    if ([string]::IsNullOrWhiteSpace($difficulty)) {
        $difficulty = $chart.difficulty
    }
    "$stepType`n$difficulty"
}

function Format-ChartLabel([string]$key, [int]$ordinal, $chart) {
    $parts = $key.Split("`n")
    $rating = $chart.chart_info.rating
    if ([string]::IsNullOrWhiteSpace($rating)) {
        $rating = $chart.meter
    }
    if ([string]::IsNullOrWhiteSpace($rating)) {
        return "$($parts[0]) $($parts[1]) #$($ordinal + 1)"
    }
    "$($parts[0]) $($parts[1]) [$rating]"
}

function New-ChartIndex($charts) {
    $index = @{}
    for ($i = 0; $i -lt $charts.Count; $i++) {
        $key = Get-ChartKey $charts[$i]
        if (!$index.ContainsKey($key)) {
            $index[$key] = New-Object System.Collections.Generic.List[int]
        }
        $index[$key].Add($i)
    }
    $index
}

function Compare-PathValue($label, $field, $expectedChart, $actualChart, [double]$epsilon) {
    $expected = $null
    $actual = $null
    $hasExpected = Try-GetPath $expectedChart $field ([ref]$expected)
    $hasActual = Try-GetPath $actualChart $field ([ref]$actual)
    if (!$hasExpected -or !$hasActual) {
        return "$label`: mismatch at $field from RSSP: expected $(if ($hasExpected) { Convert-ToBriefJson $expected } else { 'missing' }), actual $(if ($hasActual) { Convert-ToBriefJson $actual } else { 'missing' })"
    }
    $diff = Compare-JsonValue $expected $actual $field $epsilon
    if ($diff) {
        return "$label`: $diff"
    }
    $null
}

function Compare-OwnedOutput($rssp, $assp, [double]$epsilon) {
    if (!(Test-JsonArray $rssp.charts) -or !(Test-JsonArray $assp.charts)) {
        return "top-level charts array missing"
    }

    $rsspIndex = New-ChartIndex $rssp.charts
    $asspIndex = New-ChartIndex $assp.charts
    $allKeys = @($rsspIndex.Keys + $asspIndex.Keys | Sort-Object -Unique)
    foreach ($key in $allKeys) {
        if (!$rsspIndex.ContainsKey($key)) {
            return "extra ASSP chart for $($key.Replace("`n", " "))"
        }
        if (!$asspIndex.ContainsKey($key)) {
            return "missing ASSP chart for $($key.Replace("`n", " "))"
        }
        if ($rsspIndex[$key].Count -ne $asspIndex[$key].Count) {
            return "chart count mismatch for $($key.Replace("`n", " ")): expected $($rsspIndex[$key].Count), actual $($asspIndex[$key].Count)"
        }

        for ($i = 0; $i -lt $rsspIndex[$key].Count; $i++) {
            $expected = $rssp.charts[$rsspIndex[$key][$i]]
            $actual = $assp.charts[$asspIndex[$key][$i]]
            $label = Format-ChartLabel $key $i $expected
            foreach ($field in @(
                    "chart_info.matrix_rating",
                    "breakdown",
                    "stream_info.sn_breaks",
                    "mono_candle_stats",
                    "pattern_counts.boxes",
                    "pattern_counts.anchors"
                )) {
                $diff = Compare-PathValue $label $field $expected $actual $epsilon
                if ($diff) {
                    return $diff
                }
            }
        }
    }
    $null
}

function Invoke-ProcessText([string]$exe, [string[]]$processArgs) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $exe @processArgs 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    $text = ($output | Out-String)
    [pscustomobject]@{
        ExitCode = $exitCode
        Stdout = $text
        Stderr = ""
    }
}

function Invoke-JsonProgram([string]$exe, [string]$inputPath, [string]$label) {
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = Invoke-ProcessText -exe $exe -processArgs @($inputPath, "--json")
    } finally {
        $watch.Stop()
    }
    $micros = [int64][Math]::Round($watch.Elapsed.TotalMilliseconds * 1000.0)
    if ($result.ExitCode -ne 0) {
        $text = ($result.Stderr + $result.Stdout).Trim()
        if ($text.Length -gt 500) {
            $text = $text.Substring(0, 500) + "..."
        }
        throw "$label exited with code $($result.ExitCode): $text"
    }
    try {
        $json = $result.Stdout | ConvertFrom-Json
    } catch {
        throw "$label produced invalid JSON: $($_.Exception.Message)"
    }
    [pscustomobject]@{
        Json = $json
        Micros = $micros
    }
}

function Resolve-ZstdExe {
    if (![string]::IsNullOrWhiteSpace($ZstdExe)) {
        return Resolve-InputPath $ZstdExe "zstd executable"
    }
    foreach ($candidate in @((Join-Path $root "zstd.exe"), (Join-Path $root "zstd"))) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }
    $command = Get-Command zstd -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    $command = Get-Command zstd.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    $null
}

function Expand-Zst([string]$sourcePath, [string]$relativePath, [string]$zstd) {
    if ([string]::IsNullOrWhiteSpace($zstd)) {
        throw "found compressed input but zstd is not available: $relativePath"
    }
    $name = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)
    $dest = Join-Path $tempDir ([Guid]::NewGuid().ToString("N") + "-" + $name)
    $result = Invoke-ProcessText -exe $zstd -processArgs @("-d", "-q", "-f", "-o", $dest, $sourcePath)
    if ($result.ExitCode -ne 0) {
        throw "zstd failed for $relativePath`: $(($result.Stderr + $result.Stdout).Trim())"
    }
    $dest
}

if (!$PacksDir) {
    $PacksDir = Join-Path $root "packs"
}
if (!$AsspExe) {
    $AsspExe = Resolve-DefaultFile @(
        (Join-Path $root "assp.exe"),
        (Join-Path $root "target\assp.exe")
    ) "AsspExe"
} else {
    $AsspExe = Resolve-InputPath $AsspExe "ASSP executable"
}
if (!$RsspExe) {
    $RsspExe = Resolve-DefaultFile @(
        (Join-Path $root "rssp.exe"),
        (Join-Path $root "target\rssp.exe")
    ) "RsspExe"
} else {
    $RsspExe = Resolve-InputPath $RsspExe "RSSP executable"
}

$PacksDir = Resolve-InputPath $PacksDir "packs directory"
$zstd = Resolve-ZstdExe

$extensions = @("*.sm", "*.ssc")
if (!$RawOnly) {
    $extensions += @("*.sm.zst", "*.ssc.zst")
}

$tests = New-Object System.Collections.Generic.List[object]
foreach ($extension in $extensions) {
    foreach ($file in Get-ChildItem -LiteralPath $PacksDir -Recurse -File -Filter $extension) {
        $relative = Get-RelativePath $PacksDir $file.FullName
        if (![string]::IsNullOrWhiteSpace($Filter)) {
            $needle = $Filter.Replace("/", "\")
            if ($Exact) {
                if ($relative -ne $needle) {
                    continue
                }
            } elseif ($relative -notlike "*$needle*") {
                continue
            }
        }
        $skipFile = $false
        foreach ($skipPattern in $Skip) {
            if ($relative -like "*$($skipPattern.Replace("/", "\"))*") {
                $skipFile = $true
                break
            }
        }
        if ($skipFile) {
            continue
        }
        $tests.Add([pscustomobject]@{
            Path = $file.FullName
            Relative = $relative
            Compressed = $file.Name.EndsWith(".zst", [StringComparison]::OrdinalIgnoreCase)
        })
    }
}

$tests = @($tests | Sort-Object Relative)
if ($List) {
    $tests | ForEach-Object { $_.Relative }
    exit 0
}

if ($tests.Count -eq 0) {
    Write-Error "no simfiles found under $PacksDir"
    exit 2
}

if (!$zstd -and @($tests | Where-Object { $_.Compressed } | Select-Object -First 1).Count -gt 0) {
    Write-Host "error: compressed simfiles were selected, but zstd was not found."
    Write-Host "place zstd.exe next to this script, add zstd to PATH, pass -ZstdExe, or use -RawOnly."
    exit 2
}

New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$failures = New-Object System.Collections.Generic.List[object]
$passed = 0
$asspTotalMicros = [int64]0
$rsspTotalMicros = [int64]0
$asspWins = 0
$rsspWins = 0
$ties = 0

try {
    foreach ($test in $tests) {
        if (!$Quiet) {
            Write-Host "test $($test.Relative) ..." -NoNewline
        }

        $inputPath = $test.Path
        try {
            if ($test.Compressed) {
                $inputPath = Expand-Zst $test.Path $test.Relative $zstd
            }

            $rsspRun = Invoke-JsonProgram $RsspExe $inputPath "RSSP"
            $asspRun = Invoke-JsonProgram $AsspExe $inputPath "ASSP"
            $diff = if ($CompareMode -eq "full") {
                Compare-JsonValue $rsspRun.Json $asspRun.Json "json" $Epsilon
            } else {
                Compare-OwnedOutput $rsspRun.Json $asspRun.Json $Epsilon
            }

            if ($diff) {
                throw $diff
            }

            $passed++
            $asspTotalMicros += $asspRun.Micros
            $rsspTotalMicros += $rsspRun.Micros
            if ($asspRun.Micros -lt $rsspRun.Micros) {
                $asspWins++
                $winner = "assp wins"
            } elseif ($rsspRun.Micros -lt $asspRun.Micros) {
                $rsspWins++
                $winner = "rssp wins"
            } else {
                $ties++
                $winner = "tie"
            }
            if (!$Quiet) {
                Write-Host " ok [assp $(Format-Micros $asspRun.Micros)] vs. [rssp $(Format-Micros $rsspRun.Micros)] - $winner"
            }
        } catch {
            if (!$Quiet) {
                Write-Host " FAILED"
            }
            $failures.Add([pscustomobject]@{
                Name = $test.Relative
                Message = $_.Exception.Message
            })
            if ($MaxFailures -gt 0 -and $failures.Count -ge $MaxFailures) {
                break
            }
        }
    }
} finally {
    if (!$KeepTemp) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "$($failures.Count) failures:"
    foreach ($failure in $failures) {
        Write-Host "$($failure.Name):"
        Write-Host "  $($failure.Message)"
    }
    if ($MaxFailures -gt 0 -and $failures.Count -ge $MaxFailures) {
        Write-Host "stopped after reaching the failure limit ($MaxFailures)"
        Write-Host "pass -MaxFailures 0 to collect every failure"
    }
    if ($passed -gt 0) {
        $asspAvgMicros = [int64][Math]::Round($asspTotalMicros / [double]$passed)
        $rsspAvgMicros = [int64][Math]::Round($rsspTotalMicros / [double]$passed)
        Write-Host ""
        Write-Host "timing summary for $passed matched simfiles:"
        Write-Host "  assp avg analysis time: $(Format-Micros $asspAvgMicros) ($asspWins wins)"
        Write-Host "  rssp avg analysis time: $(Format-Micros $rsspAvgMicros) ($rsspWins wins)"
        Write-Host "  ties: $ties"
    }
    exit 1
}

Write-Host "ok: $passed selected simfiles matched ASSP/RSSP ($CompareMode mode)"
if ($passed -gt 0) {
    $asspAvgMicros = [int64][Math]::Round($asspTotalMicros / [double]$passed)
    $rsspAvgMicros = [int64][Math]::Round($rsspTotalMicros / [double]$passed)
    Write-Host "assp avg analysis time: $(Format-Micros $asspAvgMicros) ($asspWins wins)"
    Write-Host "rssp avg analysis time: $(Format-Micros $rsspAvgMicros) ($rsspWins wins)"
    Write-Host "ties: $ties"
}
