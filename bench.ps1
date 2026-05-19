[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Fixture,
    [string]$Pack,
    [switch]$BundledFixtures,
    [int]$Chart = 0,
    [switch]$AllCharts,
    [int]$Warmup = 1,
    [int]$Runs = 5,
    [string]$Report,
    [switch]$NoBuild,
    [switch]$AsspNoReport,
    [switch]$Quiet,
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
$workspace = Split-Path -Parent $root
$rsspManifest = Join-Path $workspace "rssp\crates\rssp-cli\Cargo.toml"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

if ($ExtraArgs.Count -ne 0) {
    throw "Unexpected argument(s): $($ExtraArgs -join ' '). Quote paths that contain spaces, for example: -Pack `".\fixtures\ITL Online 2026`""
}
if ($Warmup -lt 0) {
    throw "-Warmup must be zero or greater."
}
if ($Runs -lt 1) {
    throw "-Runs must be one or greater."
}
if ($Chart -lt 0) {
    throw "-Chart must be zero or greater."
}
if ($AsspNoReport -and !$AllCharts -and !$Pack -and !$BundledFixtures) {
    throw "-AsspNoReport applies to all-chart benchmarks. Add -AllCharts, -Pack, or -BundledFixtures."
}
$script:asspNoReport = [bool]$AsspNoReport

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
    [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $path))
}

function Get-SimfilePaths([string]$directory, [bool]$recursive) {
    $search = if ($recursive) {
        [System.IO.SearchOption]::AllDirectories
    } else {
        [System.IO.SearchOption]::TopDirectoryOnly
    }
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($pattern in @("*.sm", "*.ssc")) {
        foreach ($path in [System.IO.Directory]::EnumerateFiles($directory, $pattern, $search)) {
            $paths.Add($path)
        }
    }
    @($paths | Sort-Object)
}

function Format-Number([double]$value, [string]$format) {
    $value.ToString($format, $culture)
}

function Get-CommandOutputHead($output) {
    $lines = @($output | Select-Object -First 12)
    if ($lines.Count -eq 0) {
        return ""
    }
    $lines -join [Environment]::NewLine
}

function Get-RsspChartCount([string]$path) {
    $jsonText = & $script:rsspExe $path --json 2>&1
    if ($LASTEXITCODE -ne 0) {
        $head = Get-CommandOutputHead $jsonText
        throw "RSSP chart discovery failed for $path with exit code $LASTEXITCODE.`n$head"
    }
    try {
        $rssp = $jsonText | ConvertFrom-Json
    } catch {
        throw "RSSP chart discovery produced invalid JSON for $path`: $($_.Exception.Message)"
    }
    if ($null -eq $rssp.charts) {
        throw "RSSP chart discovery did not return a charts array for $path."
    }
    [int]$rssp.charts.Count
}

function Measure-Rssp([string]$path) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & $script:rsspExe $path --json 2>&1
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    if ($exitCode -ne 0) {
        $head = Get-CommandOutputHead $output
        throw "RSSP failed for $path with exit code $exitCode.`n$head"
    }
    $sw.Elapsed.TotalMilliseconds
}

function Measure-Assp([string]$path, [object]$chartArg) {
    $effectiveChartArg = $chartArg
    if ($script:asspNoReport -and [string]$chartArg -eq "all") {
        $effectiveChartArg = "bench"
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & $script:asspExe $path $effectiveChartArg 2>&1
    $exitCode = $LASTEXITCODE
    $sw.Stop()
    if ($exitCode -ne 0) {
        $head = Get-CommandOutputHead $output
        throw "ASSP failed for $path chart $effectiveChartArg with exit code $exitCode.`n$head"
    }
    $sw.Elapsed.TotalMilliseconds
}

$inputKinds = 0
if ($Fixture) { $inputKinds++ }
if ($Pack) { $inputKinds++ }
if ($BundledFixtures) { $inputKinds++ }
if ($inputKinds -gt 1) {
    throw "Choose only one input mode: -Fixture, -Pack, or -BundledFixtures."
}
if ($inputKinds -eq 0) {
    $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
}
if ($Pack -or $BundledFixtures) {
    $AllCharts = $true
}
if ($AsspNoReport -and !$AllCharts) {
    throw "-AsspNoReport applies to all-chart benchmarks. Add -AllCharts."
}

if (!$NoBuild) {
    & (Join-Path $root "build.ps1")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} elseif (!(Test-Path -LiteralPath $asspExe)) {
    throw "ASSP executable was not found at $asspExe. Omit -NoBuild or run .\build.ps1 first."
}

if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw "cargo was not found on PATH. It is needed to build the RSSP release CLI."
}
if (!(Test-Path -LiteralPath $rsspManifest)) {
    throw "RSSP CLI manifest was not found at $rsspManifest."
}

$metadataJson = & cargo metadata --format-version 1 --no-deps --manifest-path $rsspManifest 2>&1
if ($LASTEXITCODE -ne 0) {
    $head = Get-CommandOutputHead $metadataJson
    throw "cargo metadata failed for RSSP.`n$head"
}
$metadata = $metadataJson | ConvertFrom-Json
$rsspExe = Join-Path ([string]$metadata.target_directory) "release\rssp.exe"
if (!$NoBuild) {
    if (!$Quiet) {
        Write-Host "building RSSP release CLI"
    }
    & cargo build --release --quiet --manifest-path $rsspManifest --bin rssp
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} elseif (!$Quiet) {
    Write-Host "using existing RSSP release CLI"
}
if (!(Test-Path -LiteralPath $rsspExe)) {
    throw "RSSP executable was not found at $rsspExe. Omit -NoBuild or run cargo build --release --manifest-path $rsspManifest --bin rssp first."
}

$fixturePaths = @()
if ($BundledFixtures) {
    $fixturePaths = @(Get-SimfilePaths (Join-Path $root "fixtures") $false)
} elseif ($Pack) {
    $resolvedPack = Resolve-InputPath $Pack "Pack"
    if (!(Test-Path -LiteralPath $resolvedPack -PathType Container)) {
        throw "Pack path is not a directory: $resolvedPack"
    }
    $fixturePaths = @(Get-SimfilePaths $resolvedPack $true)
    if ($fixturePaths.Count -eq 0) {
        $allFiles = @([System.IO.Directory]::EnumerateFiles($resolvedPack, "*", [System.IO.SearchOption]::AllDirectories))
        $allDirs = @([System.IO.Directory]::EnumerateDirectories($resolvedPack, "*", [System.IO.SearchOption]::AllDirectories))
        throw "No .sm or .ssc files found under $resolvedPack. Scanned $($allFiles.Count) file(s) in $($allDirs.Count) folder(s). Expected a normal pack layout like Pack\SongFolder\song.sm or Pack\SongFolder\song.ssc."
    }
} else {
    $fixturePaths = @(Resolve-InputPath $Fixture "Fixture")
}
if ($fixturePaths.Count -eq 0) {
    throw "No fixture files were selected."
}

if (!$Quiet) {
    Write-Host "discovering chart counts for $($fixturePaths.Count) file(s)"
    if ($AsspNoReport) {
        Write-Host "ASSP no-report mode enabled; this measures compute without report formatting/output"
    }
}
$jobs = New-Object System.Collections.Generic.List[object]
$selectedChartCount = 0
foreach ($path in $fixturePaths) {
    $chartCount = Get-RsspChartCount $path
    if ($chartCount -le 0) {
        throw "RSSP reported no charts for $path."
    }

    $charts = New-Object System.Collections.Generic.List[int]
    if ($AllCharts) {
        for ($i = 0; $i -lt $chartCount; $i++) {
            $charts.Add($i)
        }
    } else {
        if ($Chart -ge $chartCount) {
            throw "Chart index $Chart is outside RSSP chart range 0..$($chartCount - 1) for $path."
        }
        $charts.Add($Chart)
    }

    $chartArray = [int[]]$charts.ToArray()
    $selectedChartCount += $chartArray.Count
    $jobs.Add([pscustomobject]@{
        File = $path
        ChartCount = $chartCount
        Charts = $chartArray
    })
}

if ($Warmup -gt 0 -and !$Quiet) {
    Write-Host "warming up $Warmup run(s)"
}
for ($warmupRun = 1; $warmupRun -le $Warmup; $warmupRun++) {
    $index = 0
    foreach ($job in $jobs) {
        $index++
        if (!$Quiet) {
            Write-Progress -Activity "Benchmark warmup" -Status "$index / $($jobs.Count)" -PercentComplete (($index * 100.0) / $jobs.Count)
        }
        [void](Measure-Rssp $job.File)
        if ($AllCharts) {
            [void](Measure-Assp $job.File "all")
        } else {
            foreach ($chart in $job.Charts) {
                [void](Measure-Assp $job.File $chart)
            }
        }
    }
}
if (!$Quiet) {
    Write-Progress -Activity "Benchmark warmup" -Completed
}

$rows = New-Object System.Collections.Generic.List[object]
for ($run = 1; $run -le $Runs; $run++) {
    $index = 0
    foreach ($job in $jobs) {
        $index++
        if (!$Quiet) {
            Write-Progress -Activity "Benchmarking RSSP vs ASSP" -Status "run $run / $Runs, file $index / $($jobs.Count)" -PercentComplete (($index * 100.0) / $jobs.Count)
        }

        $rsspMs = Measure-Rssp $job.File
        $asspMs = 0.0
        if ($AllCharts) {
            $asspMs = Measure-Assp $job.File "all"
        } else {
            foreach ($chart in $job.Charts) {
                $asspMs += Measure-Assp $job.File $chart
            }
        }
        $speedup = 0.0
        if ($asspMs -gt 0.0) {
            $speedup = $rsspMs / $asspMs
        }

        $rows.Add([pscustomobject]@{
            run = $run
            file = $job.File
            selected_charts = $job.Charts.Count
            total_charts = $job.ChartCount
            rssp_ms = [Math]::Round($rsspMs, 3)
            assp_ms = [Math]::Round($asspMs, 3)
            speedup = [Math]::Round($speedup, 3)
        })
    }
}
if (!$Quiet) {
    Write-Progress -Activity "Benchmarking RSSP vs ASSP" -Completed
}

$rsspTotal = [double](($rows | Measure-Object -Property rssp_ms -Sum).Sum)
$asspTotal = [double](($rows | Measure-Object -Property assp_ms -Sum).Sum)
$speedupTotal = 0.0
if ($asspTotal -gt 0.0) {
    $speedupTotal = $rsspTotal / $asspTotal
}
$asspLabel = if ($AsspNoReport) { "ASSP no-report" } else { "ASSP" }
$timedFiles = $fixturePaths.Count * $Runs
$timedCharts = $selectedChartCount * $Runs

Write-Host "benchmarked $($fixturePaths.Count) file(s), $selectedChartCount selected chart(s), $Runs run(s)"
Write-Host "RSSP total: $(Format-Number $rsspTotal "0.###") ms; avg/file: $(Format-Number ($rsspTotal / $timedFiles) "0.###") ms"
if ($AllCharts) {
    Write-Host "$asspLabel total: $(Format-Number $asspTotal "0.###") ms; avg/selected-chart: $(Format-Number ($asspTotal / $timedCharts) "0.###") ms; avg/file: $(Format-Number ($asspTotal / $timedFiles) "0.###") ms"
} else {
    Write-Host "$asspLabel total: $(Format-Number $asspTotal "0.###") ms; avg/chart-process: $(Format-Number ($asspTotal / $timedCharts) "0.###") ms; avg/file-sum: $(Format-Number ($asspTotal / $timedFiles) "0.###") ms"
}
Write-Host "RSSP/$asspLabel process-level speedup: $(Format-Number $speedupTotal "0.###")x"

if ($Report) {
    $reportPath = Resolve-OutputPath $Report "Report"
    $reportDir = [System.IO.Path]::GetDirectoryName($reportPath)
    if (![string]::IsNullOrWhiteSpace($reportDir)) {
        New-Item -ItemType Directory -Force $reportDir | Out-Null
    }
    $rows | Export-Csv -LiteralPath $reportPath -NoTypeInformation
    Write-Host "wrote $reportPath"
}
