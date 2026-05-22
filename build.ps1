[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$RunFixture,
    [string]$Fixture,
    [string]$Pack,
    [int]$Chart = 0,
    [switch]$ListCharts,
    [switch]$CompareRssp,
    [switch]$CompareAllCharts,
    [switch]$CompareFixtures,
    [string]$Report,
    [switch]$KeepGoing,
    [switch]$Clean,
    [switch]$ProfileSymbols,
    [switch]$PhaseProfile,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($root)) {
    $root = (Get-Location).Path
}
$target = Join-Path $root "target"
$exe = Join-Path $target "assp.exe"
$pdb = Join-Path $target "assp.pdb"
$map = Join-Path $target "assp.map"
$include = (Join-Path $root "include") + [System.IO.Path]::DirectorySeparatorChar

if ($ExtraArgs.Count -ne 0) {
    throw "Unexpected argument(s): $($ExtraArgs -join ' '). Quote paths that contain spaces, for example: -Pack `".\fixtures\ITL Online 2026`""
}

if ($Pack -and !$CompareRssp -and !$CompareAllCharts -and !$CompareFixtures) {
    $CompareAllCharts = $true
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
    [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $path))
}

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
    $nasmArgs = @("-f", "win64", "-I$include", "-DASSP_STANDALONE_EXE", "-DASSP_WINDOWS")
    if ($ProfileSymbols) {
        $nasmArgs += @("-g", "-F", "cv8")
    }
    if ($PhaseProfile) {
        $nasmArgs += "-DASSP_PHASE_PROFILE"
    }
    $nasmArgs += @($asm.FullName, "-o", $obj)
    & nasm @nasmArgs
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

if ($ProfileSymbols) {
    $linkArgs += @(
        "/debug",
        "/pdb:$pdb",
        "/map:$map",
        "/mapinfo:exports"
    )
}

& $linkerPath @linkFlavorArgs @linkArgs
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "built $exe"

if (($RunFixture -or $Fixture) -and !$CompareRssp -and !$CompareAllCharts -and !$CompareFixtures) {
    if (!$Fixture) {
        $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
    }

    $resolvedFixture = Resolve-InputPath $Fixture "Fixture"
    if ($ListCharts) {
        $runArgs = @($resolvedFixture, "list")
    } else {
        $runArgs = @($resolvedFixture, $Chart)
    }

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

if ($CompareRssp -or $CompareAllCharts -or $CompareFixtures) {
    if ($ListCharts) {
        throw "RSSP comparison mode compares report data; omit -ListCharts."
    }
    if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
        throw "cargo was not found on PATH. It is needed only for RSSP comparison mode."
    }
    if ($CompareFixtures -and $Fixture) {
        throw "CompareFixtures uses every bundled fixture; omit -Fixture."
    }
    if ($Pack -and ($Fixture -or $CompareFixtures)) {
        throw "Pack comparison uses every simfile under one folder; omit -Fixture and -CompareFixtures."
    }
    if ($Pack -and !$CompareAllCharts) {
        throw "Pack comparison checks every chart; use -CompareAllCharts -Pack <folder>."
    }
    if (!$Fixture -and !$CompareFixtures -and !$Pack) {
        $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
    }

    $workspace = Split-Path -Parent $root
    $rsspManifest = Join-Path $workspace "rssp\crates\rssp-cli\Cargo.toml"
    if (!(Test-Path $rsspManifest)) {
        throw "RSSP CLI manifest was not found at $rsspManifest."
    }

    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $numberStyles = [System.Globalization.NumberStyles]::Float

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

    $fixturePaths = @()
    $resolvedPack = $null
    if ($CompareFixtures) {
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

    $reportPath = $null
    if ($Report) {
        $reportPath = Resolve-OutputPath $Report "Report"
        $reportDir = [System.IO.Path]::GetDirectoryName($reportPath)
        if (![string]::IsNullOrWhiteSpace($reportDir)) {
            New-Item -ItemType Directory -Force $reportDir | Out-Null
        }
        Set-Content -LiteralPath $reportPath -Value @(
            "assp RSSP parity report",
            "generated: $([DateTime]::Now.ToString("s"))",
            "files: $($fixturePaths.Count)",
            ""
        )
    }

    function Write-ParityLine([string]$line) {
        Write-Host $line
        if ($reportPath) {
            Add-Content -LiteralPath $reportPath -Value $line
        }
    }

    function Get-AsspField([string]$name) {
        if (!$assp.ContainsKey($name)) {
            $failures.Add("$failurePrefix missing ASSP field '$name'")
            return $null
        }
        $assp[$name]
    }

    function Compare-Text([string]$name, [string]$expected) {
        $actual = Get-AsspField $name
        if ($null -ne $actual -and $actual -ne $expected) {
            $failures.Add("$failurePrefix $name expected '$expected' but got '$actual'")
        }
    }

    function Compare-TextField([string]$actualName, [string]$expectedName, [string]$expected) {
        $actual = Get-AsspField $actualName
        if ($null -ne $actual -and $actual -ne $expected) {
            $failures.Add("$failurePrefix $expectedName expected '$expected' but got '$actual'")
        }
    }

    function Compare-Int([string]$name, [int64]$expected) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actual = [int64]::Parse($actualText, $culture)
        if ($actual -ne $expected) {
            $failures.Add("$failurePrefix $name expected $expected but got $actual")
        }
    }

    function Compare-IntField([string]$actualName, [string]$expectedName, [int64]$expected) {
        $actualText = Get-AsspField $actualName
        if ($null -eq $actualText) {
            return
        }
        $actual = [int64]::Parse($actualText, $culture)
        if ($actual -ne $expected) {
            $failures.Add("$failurePrefix $expectedName expected $expected but got $actual")
        }
    }

    function Compare-Float([string]$name, [double]$expected, [double]$tolerance = 0.01) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actual = [double]::Parse($actualText, $numberStyles, $culture)
        if ([math]::Abs($actual - $expected) -gt $tolerance) {
            $failures.Add("$failurePrefix $name expected $expected but got $actual")
        }
    }

    function Compare-FloatField([string]$actualName, [string]$expectedName, [double]$expected, [double]$tolerance = 0.01) {
        $actualText = Get-AsspField $actualName
        if ($null -eq $actualText) {
            return
        }
        $actual = [double]::Parse($actualText, $numberStyles, $culture)
        if ([math]::Abs($actual - $expected) -gt $tolerance) {
            $failures.Add("$failurePrefix $expectedName expected $expected but got $actual")
        }
    }

    function Round-SigFigsItg([double]$value) {
        if ($value -eq 0.0 -or [double]::IsNaN($value) -or [double]::IsInfinity($value)) {
            return $value
        }

        $singleValue = [double]([single]$value)
        $abs = [math]::Abs($singleValue)
        if ($abs -ge 1.0 -and $abs -lt 1000000.0) {
            if ($abs -lt 10.0) {
                $scale = 100000.0
            } elseif ($abs -lt 100.0) {
                $scale = 10000.0
            } elseif ($abs -lt 1000.0) {
                $scale = 1000.0
            } elseif ($abs -lt 10000.0) {
                $scale = 100.0
            } elseif ($abs -lt 100000.0) {
                $scale = 10.0
            } else {
                $scale = 1.0
            }
        } else {
            $magnitude = [math]::Floor([math]::Log10($abs))
            $power = 5 - [int]$magnitude
            if ($power -lt -300 -or $power -gt 300) {
                return $value
            }
            $scale = [math]::Pow(10.0, $power)
        }

        $rounded = [math]::Round($singleValue * $scale, 0, [System.MidpointRounding]::ToEven) / $scale
        if ([double]::IsNaN($rounded) -or [double]::IsInfinity($rounded)) {
            return $value
        }
        $rounded
    }

    function Compare-FloatItg([string]$name, [double]$expected, [double]$tolerance = 0.001) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actual = Round-SigFigsItg ([double]::Parse($actualText, $numberStyles, $culture))
        if ([math]::Abs($actual - $expected) -gt $tolerance) {
            $failures.Add("$failurePrefix $name expected $expected but got $actual")
        }
    }

    function Format-TimingPairs($pairs) {
        $items = @()
        foreach ($pair in @($pairs)) {
            if ($null -eq $pair) {
                continue
            }
            $beat = [double]$pair[0]
            $value = [double]$pair[1]
            $items += ("{0:F6}={1:F6}" -f $beat, $value)
        }
        $items -join ","
    }

    function Format-StreamSequences($sequences) {
        $items = @()
        foreach ($sequence in @($sequences)) {
            if ($null -eq $sequence) {
                continue
            }
            $start = [int64]$sequence.stream_start
            $end = [int64]$sequence.stream_end
            $isBreak = ([string]$sequence.is_break).ToLowerInvariant()
            $items += ('{{"stream_start":{0},"stream_end":{1},"is_break":{2}}}' -f $start, $end, $isBreak)
        }
        "[" + ($items -join ",") + "]"
    }

    function Split-AsspItems([string]$text) {
        if ($text.Length -eq 0) {
            return @()
        }
        @($text -split "," | Where-Object { $_.Length -ne 0 })
    }

    function Compare-IntArray([string]$name, $expectedValues) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actualItems = @(Split-AsspItems $actualText)
        $expected = @($expectedValues)
        if ($actualItems.Count -ne $expected.Count) {
            $failures.Add("$failurePrefix $name length expected $($expected.Count) but got $($actualItems.Count)")
            return
        }
        for ($i = 0; $i -lt $expected.Count; $i++) {
            $actual = [int64]::Parse($actualItems[$i].Trim(), $culture)
            if ($actual -ne [int64]$expected[$i]) {
                $failures.Add("$failurePrefix $name[$i] expected $($expected[$i]) but got $actual")
                return
            }
        }
    }

    function Compare-FloatArray([string]$name, $expectedValues, [double]$tolerance = 0.01) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actualItems = @(Split-AsspItems $actualText)
        $expected = @($expectedValues)
        if ($actualItems.Count -ne $expected.Count) {
            $failures.Add("$failurePrefix $name length expected $($expected.Count) but got $($actualItems.Count)")
            return
        }
        for ($i = 0; $i -lt $expected.Count; $i++) {
            $actual = [double]::Parse($actualItems[$i].Trim(), $numberStyles, $culture)
            $expectedValue = [double]$expected[$i]
            if ([math]::Abs($actual - $expectedValue) -gt $tolerance) {
                $failures.Add("$failurePrefix $name[$i] expected $expectedValue but got $actual")
                return
            }
        }
    }

    function Compare-BoolArray([string]$name, $expectedValues) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actualItems = @(Split-AsspItems $actualText)
        $expected = @($expectedValues)
        if ($actualItems.Count -ne $expected.Count) {
            $failures.Add("$failurePrefix $name length expected $($expected.Count) but got $($actualItems.Count)")
            return
        }
        for ($i = 0; $i -lt $expected.Count; $i++) {
            $actual = $actualItems[$i].Trim().ToLowerInvariant()
            $expectedValue = ([string]$expected[$i]).ToLowerInvariant()
            if ($actual -ne $expectedValue) {
                $failures.Add("$failurePrefix $name[$i] expected $expectedValue but got $actual")
                return
            }
        }
    }

    function Test-TechSliceComparable($techCounts) {
        if ($null -eq $techCounts) {
            return $false
        }
        return ([int64]$techCounts.crossovers -eq 0) -and
            ([int64]$techCounts.footswitches -eq 0) -and
            ([int64]$techCounts.up_footswitches -eq 0) -and
            ([int64]$techCounts.down_footswitches -eq 0) -and
            ([int64]$techCounts.sideswitches -eq 0) -and
            ([int64]$techCounts.jacks -eq 0) -and
            ([int64]$techCounts.doublesteps -eq 0)
    }

    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($fixturePath in $fixturePaths) {
        $resolvedFixture = Resolve-InputPath $fixturePath "Fixture"
        $fixtureName = [System.IO.Path]::GetFileName($resolvedFixture)
        Write-ParityLine "comparing $resolvedFixture"
        $fixtureFailureStart = $failures.Count
        $jsonText = & cargo run --quiet --manifest-path $rsspManifest --bin rssp -- $resolvedFixture --json
        if ($LASTEXITCODE -ne 0) {
            $message = "$fixtureName RSSP CLI failed with exit code $LASTEXITCODE"
            if ($KeepGoing) {
                $failures.Add($message)
                continue
            }
            throw $message
        }
        try {
            $rssp = $jsonText | ConvertFrom-Json
        } catch {
            $message = "$fixtureName RSSP JSON output could not be parsed: $($_.Exception.Message)"
            if ($KeepGoing) {
                $failures.Add($message)
                continue
            }
            throw $message
        }
        $chartIndexes = @()
        if ($CompareAllCharts -or $CompareFixtures) {
            for ($i = 0; $i -lt $rssp.charts.Count; $i++) {
                $chartIndexes += $i
            }
        } else {
            if ($Chart -lt 0 -or $Chart -ge $rssp.charts.Count) {
                $message = "$fixtureName chart index $Chart is outside RSSP chart range 0..$($rssp.charts.Count - 1)."
                if ($KeepGoing) {
                    $failures.Add($message)
                    continue
                }
                throw $message
            }
            $chartIndexes = @($Chart)
        }

        foreach ($chartIndex in $chartIndexes) {
            $failurePrefix = "$fixtureName chart $chartIndex"
            $asspLines = & $exe $resolvedFixture $chartIndex
            if ($LASTEXITCODE -ne 0) {
                $message = "$failurePrefix ASSP executable failed with exit code $LASTEXITCODE"
                if ($KeepGoing) {
                    $failures.Add($message)
                    continue
                }
                throw $message
            }

            $assp = @{}
            foreach ($line in $asspLines) {
                if ($line -match '^([^:]+):\s*(.*)$') {
                    $assp[$matches[1]] = $matches[2].Trim()
                }
            }

            $chartJson = $rssp.charts[$chartIndex]

            Compare-Text "title" ([string]$rssp.title)
            Compare-Text "subtitle" ([string]$rssp.subtitle)
            Compare-Text "artist" ([string]$rssp.artist)
            Compare-Text "title_trans" ([string]$rssp.title_trans)
            Compare-Text "subtitle_trans" ([string]$rssp.subtitle_trans)
            Compare-Text "artist_trans" ([string]$rssp.artist_trans)
            Compare-Text "bpm_data" ([string]$rssp.bpm_data)
            Compare-Float "offset" ([double]$rssp.offset) 0.001

            Compare-Text "step_type" ([string]$chartJson.chart_info.step_type)
            Compare-Text "difficulty" ([string]$chartJson.chart_info.difficulty)
            Compare-Text "rating" ([string]$chartJson.chart_info.rating)
            Compare-Text "step_artists" ([string]$chartJson.chart_info.step_artists)
            Compare-Text "tech_notation" ([string]$chartJson.chart_info.tech_notation)
            if (Test-TechSliceComparable $chartJson.tech_counts) {
                Compare-Int "crossovers" ([int64]$chartJson.tech_counts.crossovers)
                Compare-Int "footswitches" ([int64]$chartJson.tech_counts.footswitches)
                Compare-Int "up_footswitches" ([int64]$chartJson.tech_counts.up_footswitches)
                Compare-Int "down_footswitches" ([int64]$chartJson.tech_counts.down_footswitches)
                Compare-Int "sideswitches" ([int64]$chartJson.tech_counts.sideswitches)
                Compare-Int "jacks" ([int64]$chartJson.tech_counts.jacks)
                Compare-Int "brackets" ([int64]$chartJson.tech_counts.brackets)
                Compare-Int "doublesteps" ([int64]$chartJson.tech_counts.doublesteps)
            }
            Compare-Text "sha1" ([string]$chartJson.chart_info.sha1)
            Compare-Text "bpm_neutral_sha1" ([string]$chartJson.chart_info.bpm_neutral_sha1)

            Compare-Float "tier_bpm" ([double]$chartJson.chart_info.tier_bpm)
            Compare-Float "matrix_rating" ([double]$chartJson.chart_info.matrix_rating)
            Compare-Float "max_nps" ([double]$chartJson.nps.max_nps)
            Compare-Float "median_nps" ([double]$chartJson.nps.median_nps)
            Compare-IntArray "notes_per_measure" $chartJson.nps.notes_per_measure
            Compare-FloatArray "nps_per_measure" $chartJson.nps.nps_per_measure
            Compare-BoolArray "equally_spaced_per_measure" $chartJson.nps.equally_spaced_per_measure

            Compare-Float "beat0_offset_seconds" ([double]$chartJson.timing.beat0_offset_seconds)
            Compare-Float "beat0_group_offset_seconds" ([double]$chartJson.timing.beat0_group_offset_seconds)
            Compare-Text "hash_bpms" ([string]$chartJson.timing.hash_bpms)
            Compare-Text "bpms_formatted" ([string]$chartJson.timing.bpms_formatted)
            Compare-Text "stops_formatted" (Format-TimingPairs $chartJson.timing.stops)
            Compare-Text "delays_formatted" (Format-TimingPairs $chartJson.timing.delays)
            Compare-Text "warps_formatted" (Format-TimingPairs $chartJson.timing.warps)
            Compare-Text "fakes_formatted" (Format-TimingPairs $chartJson.timing.fakes)
            Compare-IntField "min_bpm" "bpm_min" ([int64]$chartJson.timing.bpm_min)
            Compare-IntField "max_bpm" "bpm_max" ([int64]$chartJson.timing.bpm_max)
            Compare-Text "display_bpm" ([string]$chartJson.timing.display_bpm)
            Compare-Float "display_bpm_min" ([double]$chartJson.timing.display_bpm_min) 0.001
            Compare-Float "display_bpm_max" ([double]$chartJson.timing.display_bpm_max) 0.001
            Compare-FloatItg "duration_seconds" ([double]$chartJson.timing.duration_seconds)

            Compare-Text "sn_detailed_breakdown" ([string]$chartJson.breakdown.sn_detailed_breakdown)
            Compare-Text "sn_partial_breakdown" ([string]$chartJson.breakdown.sn_partial_breakdown)
            Compare-Text "sn_simple_breakdown" ([string]$chartJson.breakdown.sn_simple_breakdown)
            Compare-TextField "stream_breakdown_detailed" "detailed_breakdown" ([string]$chartJson.stream_breakdown.detailed_breakdown)
            Compare-TextField "stream_breakdown_partial" "partial_breakdown" ([string]$chartJson.stream_breakdown.partial_breakdown)
            Compare-TextField "stream_breakdown_simple" "simple_breakdown" ([string]$chartJson.stream_breakdown.simple_breakdown)

            Compare-Int "total_candles" ([int64]$chartJson.mono_candle_stats.total_candles)
            Compare-Int "left_foot_candles" ([int64]$chartJson.mono_candle_stats.left_foot_candles)
            Compare-Int "right_foot_candles" ([int64]$chartJson.mono_candle_stats.right_foot_candles)
            Compare-Float "candles_percent" ([double]$chartJson.mono_candle_stats.candles_percent)
            Compare-Int "total_mono" ([int64]$chartJson.mono_candle_stats.total_mono)
            Compare-Int "left_face_mono" ([int64]$chartJson.mono_candle_stats.left_face_mono)
            Compare-Int "right_face_mono" ([int64]$chartJson.mono_candle_stats.right_face_mono)
            Compare-Float "mono_percent" ([double]$chartJson.mono_candle_stats.mono_percent)

            Compare-Int "total_boxes" ([int64]$chartJson.pattern_counts.boxes.total_boxes)
            Compare-Int "lr_boxes" ([int64]$chartJson.pattern_counts.boxes.lr_boxes)
            Compare-Int "ud_boxes" ([int64]$chartJson.pattern_counts.boxes.ud_boxes)
            Compare-Int "corner_boxes" ([int64]$chartJson.pattern_counts.boxes.corner_boxes)
            Compare-Int "ld_boxes" ([int64]$chartJson.pattern_counts.boxes.ld_boxes)
            Compare-Int "lu_boxes" ([int64]$chartJson.pattern_counts.boxes.lu_boxes)
            Compare-Int "rd_boxes" ([int64]$chartJson.pattern_counts.boxes.rd_boxes)
            Compare-Int "ru_boxes" ([int64]$chartJson.pattern_counts.boxes.ru_boxes)
            Compare-Int "total_anchors" ([int64]$chartJson.pattern_counts.anchors.total_anchors)
            Compare-Int "left_anchors" ([int64]$chartJson.pattern_counts.anchors.left_anchors)
            Compare-Int "down_anchors" ([int64]$chartJson.pattern_counts.anchors.down_anchors)
            Compare-Int "up_anchors" ([int64]$chartJson.pattern_counts.anchors.up_anchors)
            Compare-Int "right_anchors" ([int64]$chartJson.pattern_counts.anchors.right_anchors)
            Compare-Int "total_towers" ([int64]$chartJson.pattern_counts.towers.total_towers)
            Compare-Int "lr_towers" ([int64]$chartJson.pattern_counts.towers.lr_towers)
            Compare-Int "ud_towers" ([int64]$chartJson.pattern_counts.towers.ud_towers)
            Compare-Int "corner_towers" ([int64]$chartJson.pattern_counts.towers.corner_towers)
            Compare-Int "ld_towers" ([int64]$chartJson.pattern_counts.towers.ld_towers)
            Compare-Int "lu_towers" ([int64]$chartJson.pattern_counts.towers.lu_towers)
            Compare-Int "rd_towers" ([int64]$chartJson.pattern_counts.towers.rd_towers)
            Compare-Int "ru_towers" ([int64]$chartJson.pattern_counts.towers.ru_towers)
            Compare-Int "total_triangles" ([int64]$chartJson.pattern_counts.triangles.total_triangles)
            Compare-Int "ldl_triangles" ([int64]$chartJson.pattern_counts.triangles.ldl_triangles)
            Compare-Int "lul_triangles" ([int64]$chartJson.pattern_counts.triangles.lul_triangles)
            Compare-Int "rdr_triangles" ([int64]$chartJson.pattern_counts.triangles.rdr_triangles)
            Compare-Int "rur_triangles" ([int64]$chartJson.pattern_counts.triangles.rur_triangles)
            Compare-Int "total_staircases" ([int64]$chartJson.pattern_counts.staircases.total_staircases)
            Compare-Int "left_staircases" ([int64]$chartJson.pattern_counts.staircases.left_staircases)
            Compare-Int "right_staircases" ([int64]$chartJson.pattern_counts.staircases.right_staircases)
            Compare-Int "left_inv_staircases" ([int64]$chartJson.pattern_counts.staircases.left_inv_staircases)
            Compare-Int "right_inv_staircases" ([int64]$chartJson.pattern_counts.staircases.right_inv_staircases)
            Compare-Int "total_alt_staircases" ([int64]$chartJson.pattern_counts.staircases.total_alt_staircases)
            Compare-Int "left_alt_staircases" ([int64]$chartJson.pattern_counts.staircases.left_alt_staircases)
            Compare-Int "right_alt_staircases" ([int64]$chartJson.pattern_counts.staircases.right_alt_staircases)
            Compare-Int "left_inv_alt_staircases" ([int64]$chartJson.pattern_counts.staircases.left_inv_alt_staircases)
            Compare-Int "right_inv_alt_staircases" ([int64]$chartJson.pattern_counts.staircases.right_inv_alt_staircases)
            Compare-Int "total_double_staircases" ([int64]$chartJson.pattern_counts.staircases.total_double_staircases)
            Compare-Int "left_double_staircases" ([int64]$chartJson.pattern_counts.staircases.left_double_staircases)
            Compare-Int "right_double_staircases" ([int64]$chartJson.pattern_counts.staircases.right_double_staircases)
            Compare-Int "left_inv_double_staircases" ([int64]$chartJson.pattern_counts.staircases.left_inv_double_staircases)
            Compare-Int "right_inv_double_staircases" ([int64]$chartJson.pattern_counts.staircases.right_inv_double_staircases)
            Compare-Int "total_sweeps" ([int64]$chartJson.pattern_counts.sweeps.total_sweeps)
            Compare-Int "left_sweeps" ([int64]$chartJson.pattern_counts.sweeps.left_sweeps)
            Compare-Int "right_sweeps" ([int64]$chartJson.pattern_counts.sweeps.right_sweeps)
            Compare-Int "left_inv_sweeps" ([int64]$chartJson.pattern_counts.sweeps.left_inv_sweeps)
            Compare-Int "right_inv_sweeps" ([int64]$chartJson.pattern_counts.sweeps.right_inv_sweeps)
            Compare-Int "total_candle_sweeps" ([int64]$chartJson.pattern_counts.candle_sweeps.total_candle_sweeps)
            Compare-Int "left_candle_sweeps" ([int64]$chartJson.pattern_counts.candle_sweeps.left_candle_sweeps)
            Compare-Int "right_candle_sweeps" ([int64]$chartJson.pattern_counts.candle_sweeps.right_candle_sweeps)
            Compare-Int "left_inv_candle_sweeps" ([int64]$chartJson.pattern_counts.candle_sweeps.left_inv_candle_sweeps)
            Compare-Int "right_inv_candle_sweeps" ([int64]$chartJson.pattern_counts.candle_sweeps.right_inv_candle_sweeps)
            Compare-Int "total_copters" ([int64]$chartJson.pattern_counts.copters.total_copters)
            Compare-Int "left_copters" ([int64]$chartJson.pattern_counts.copters.left_copters)
            Compare-Int "right_copters" ([int64]$chartJson.pattern_counts.copters.right_copters)
            Compare-Int "left_inv_copters" ([int64]$chartJson.pattern_counts.copters.left_inv_copters)
            Compare-Int "right_inv_copters" ([int64]$chartJson.pattern_counts.copters.right_inv_copters)
            Compare-Int "total_spirals" ([int64]$chartJson.pattern_counts.spirals.total_spirals)
            Compare-Int "left_spirals" ([int64]$chartJson.pattern_counts.spirals.left_spirals)
            Compare-Int "right_spirals" ([int64]$chartJson.pattern_counts.spirals.right_spirals)
            Compare-Int "left_inv_spirals" ([int64]$chartJson.pattern_counts.spirals.left_inv_spirals)
            Compare-Int "right_inv_spirals" ([int64]$chartJson.pattern_counts.spirals.right_inv_spirals)
            Compare-Int "total_turbo_candles" ([int64]$chartJson.pattern_counts.turbo_candles.total_turbo_candles)
            Compare-Int "left_turbo_candles" ([int64]$chartJson.pattern_counts.turbo_candles.left_turbo_candles)
            Compare-Int "right_turbo_candles" ([int64]$chartJson.pattern_counts.turbo_candles.right_turbo_candles)
            Compare-Int "left_inv_turbo_candles" ([int64]$chartJson.pattern_counts.turbo_candles.left_inv_turbo_candles)
            Compare-Int "right_inv_turbo_candles" ([int64]$chartJson.pattern_counts.turbo_candles.right_inv_turbo_candles)
            Compare-Int "total_hip_breakers" ([int64]$chartJson.pattern_counts.hip_breakers.total_hip_breakers)
            Compare-Int "left_hip_breakers" ([int64]$chartJson.pattern_counts.hip_breakers.left_hip_breakers)
            Compare-Int "right_hip_breakers" ([int64]$chartJson.pattern_counts.hip_breakers.right_hip_breakers)
            Compare-Int "left_inv_hip_breakers" ([int64]$chartJson.pattern_counts.hip_breakers.left_inv_hip_breakers)
            Compare-Int "right_inv_hip_breakers" ([int64]$chartJson.pattern_counts.hip_breakers.right_inv_hip_breakers)
            Compare-Int "total_doritos" ([int64]$chartJson.pattern_counts.doritos.total_doritos)
            Compare-Int "left_doritos" ([int64]$chartJson.pattern_counts.doritos.left_doritos)
            Compare-Int "right_doritos" ([int64]$chartJson.pattern_counts.doritos.right_doritos)
            Compare-Int "left_inv_doritos" ([int64]$chartJson.pattern_counts.doritos.left_inv_doritos)
            Compare-Int "right_inv_doritos" ([int64]$chartJson.pattern_counts.doritos.right_inv_doritos)
            Compare-Int "total_luchis" ([int64]$chartJson.pattern_counts.luchis.total_luchis)
            Compare-Int "left_du_luchis" ([int64]$chartJson.pattern_counts.luchis.left_du_luchis)
            Compare-Int "left_ud_luchis" ([int64]$chartJson.pattern_counts.luchis.left_ud_luchis)
            Compare-Int "right_du_luchis" ([int64]$chartJson.pattern_counts.luchis.right_du_luchis)
            Compare-Int "right_ud_luchis" ([int64]$chartJson.pattern_counts.luchis.right_ud_luchis)

            Compare-Int "total_arrows" ([int64]$chartJson.arrow_stats.total_arrows)
            Compare-Int "left_arrows" ([int64]$chartJson.arrow_stats.left_arrows)
            Compare-Int "down_arrows" ([int64]$chartJson.arrow_stats.down_arrows)
            Compare-Int "up_arrows" ([int64]$chartJson.arrow_stats.up_arrows)
            Compare-Int "right_arrows" ([int64]$chartJson.arrow_stats.right_arrows)
            Compare-Int "total_steps" ([int64]$chartJson.arrow_stats.total_steps)
            Compare-Int "jumps" ([int64]$chartJson.arrow_stats.jumps)
            Compare-Int "hands" ([int64]$chartJson.arrow_stats.hands)
            Compare-Int "holds" ([int64]$chartJson.arrow_stats.holds)
            Compare-Int "rolls" ([int64]$chartJson.arrow_stats.rolls)
            Compare-Int "mines" ([int64]$chartJson.arrow_stats.mines)
            Compare-Int "lifts" ([int64]$chartJson.gimmicks.lifts)
            Compare-Int "fakes" ([int64]$chartJson.gimmicks.fakes)
            Compare-Int "stops_freezes" ([int64]$chartJson.gimmicks.stops_freezes)
            Compare-Int "delays" ([int64]$chartJson.gimmicks.delays)
            Compare-Int "warps" ([int64]$chartJson.gimmicks.warps)
            Compare-Int "speeds" ([int64]$chartJson.gimmicks.speeds)
            Compare-Int "scrolls" ([int64]$chartJson.gimmicks.scrolls)

            Compare-Int "total_streams" ([int64]$chartJson.stream_info.total_streams)
            Compare-Int "16th_streams" ([int64]$chartJson.stream_info.'16th_streams')
            Compare-Int "20th_streams" ([int64]$chartJson.stream_info.'20th_streams')
            Compare-Int "24th_streams" ([int64]$chartJson.stream_info.'24th_streams')
            Compare-Int "32nd_streams" ([int64]$chartJson.stream_info.'32nd_streams')
            Compare-Int "total_breaks" ([int64]$chartJson.stream_info.total_breaks)
            Compare-Int "sn_breaks" ([int64]$chartJson.stream_info.sn_breaks)
            Compare-Float "stream_percent" ([double]$chartJson.stream_info.stream_percent)
            Compare-Float "adj_stream_percent" ([double]$chartJson.stream_info.adj_stream_percent)
            Compare-Float "break_percent" ([double]$chartJson.stream_info.break_percent)
            Compare-Int "stream_segments" ([int64]@($chartJson.stream_info.stream_sequences).Count)
            Compare-Text "stream_sequences" (Format-StreamSequences $chartJson.stream_info.stream_sequences)
        }

        if ($failures.Count -eq $fixtureFailureStart -and !$CompareFixtures) {
            $chartList = $chartIndexes -join ", "
            Write-ParityLine "RSSP parity check passed for $resolvedFixture chart(s) $chartList."
        } elseif ($failures.Count -eq $fixtureFailureStart) {
            $chartList = $chartIndexes -join ", "
            Write-ParityLine "RSSP parity check passed for $fixtureName chart(s) $chartList."
        }
    }

    if ($failures.Count -ne 0) {
        Write-ParityLine "RSSP parity check failed:"
        foreach ($failure in $failures) {
            Write-ParityLine "  $failure"
        }
        if ($reportPath) {
            Write-Host "wrote parity report $reportPath"
        }
        exit 1
    }

    if ($CompareFixtures) {
        Write-ParityLine "RSSP parity check passed for all bundled fixtures."
    } elseif ($Pack) {
        Write-ParityLine "RSSP parity check passed for $($fixturePaths.Count) pack file(s) under $resolvedPack."
    }
    if ($reportPath) {
        Write-Host "wrote parity report $reportPath"
    }
}
