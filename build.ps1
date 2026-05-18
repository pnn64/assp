param(
    [switch]$RunFixture,
    [string]$Fixture,
    [int]$Chart = 0,
    [switch]$ListCharts,
    [switch]$CompareRssp,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $root "target"
$exe = Join-Path $target "assp.exe"
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

if (($RunFixture -or $Fixture) -and !$CompareRssp) {
    if (!$Fixture) {
        $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
    }

    $resolvedFixture = (Resolve-Path $Fixture).Path
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

if ($CompareRssp) {
    if ($ListCharts) {
        throw "-CompareRssp compares one chart; omit -ListCharts."
    }
    if (!(Get-Command cargo -ErrorAction SilentlyContinue)) {
        throw "cargo was not found on PATH. It is needed only for -CompareRssp."
    }
    if (!$Fixture) {
        $Fixture = Join-Path $root "fixtures\camellia_mix.ssc"
    }

    $resolvedFixture = (Resolve-Path $Fixture).Path
    $workspace = Split-Path -Parent $root
    $rsspManifest = Join-Path $workspace "rssp\crates\rssp-cli\Cargo.toml"
    if (!(Test-Path $rsspManifest)) {
        throw "RSSP CLI manifest was not found at $rsspManifest."
    }

    $asspLines = & $exe $resolvedFixture $Chart
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $assp = @{}
    foreach ($line in $asspLines) {
        if ($line -match '^([^:]+):\s*(.*)$') {
            $assp[$matches[1]] = $matches[2].Trim()
        }
    }

    $jsonText = & cargo run --quiet --manifest-path $rsspManifest --bin rssp -- $resolvedFixture --json --skip-tech
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $rssp = $jsonText | ConvertFrom-Json
    if ($Chart -lt 0 -or $Chart -ge $rssp.charts.Count) {
        throw "Chart index $Chart is outside RSSP chart range 0..$($rssp.charts.Count - 1)."
    }

    $chartJson = $rssp.charts[$Chart]
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $numberStyles = [System.Globalization.NumberStyles]::Float
    $failures = New-Object System.Collections.Generic.List[string]

    function Get-AsspField([string]$name) {
        if (!$assp.ContainsKey($name)) {
            $failures.Add("missing ASSP field '$name'")
            return $null
        }
        $assp[$name]
    }

    function Compare-Text([string]$name, [string]$expected) {
        $actual = Get-AsspField $name
        if ($null -ne $actual -and $actual -ne $expected) {
            $failures.Add("$name expected '$expected' but got '$actual'")
        }
    }

    function Compare-Int([string]$name, [int64]$expected) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actual = [int64]::Parse($actualText, $culture)
        if ($actual -ne $expected) {
            $failures.Add("$name expected $expected but got $actual")
        }
    }

    function Compare-Float([string]$name, [double]$expected, [double]$tolerance = 0.01) {
        $actualText = Get-AsspField $name
        if ($null -eq $actualText) {
            return
        }
        $actual = [double]::Parse($actualText, $numberStyles, $culture)
        if ([math]::Abs($actual - $expected) -gt $tolerance) {
            $failures.Add("$name expected $expected but got $actual")
        }
    }

    Compare-Text "step_type" ([string]$chartJson.chart_info.step_type)
    Compare-Text "difficulty" ([string]$chartJson.chart_info.difficulty)
    Compare-Text "rating" ([string]$chartJson.chart_info.rating)
    Compare-Text "sha1" ([string]$chartJson.chart_info.sha1)
    Compare-Text "bpm_neutral_sha1" ([string]$chartJson.chart_info.bpm_neutral_sha1)

    Compare-Float "tier_bpm" ([double]$chartJson.chart_info.tier_bpm)
    Compare-Float "matrix_rating" ([double]$chartJson.chart_info.matrix_rating)
    Compare-Float "median_nps" ([double]$chartJson.nps.median_nps)

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

    if ($failures.Count -ne 0) {
        Write-Host "RSSP parity check failed:"
        foreach ($failure in $failures) {
            Write-Host "  $failure"
        }
        exit 1
    }

    Write-Host "RSSP parity check passed for $resolvedFixture chart $Chart."
}
