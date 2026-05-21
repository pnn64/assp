# assp

`assp` is a standalone NASM x86-64 port of `rssp`, the Rust StepMania
simfile parser.

The executable is built from assembly. The Rust crate in this directory is only
an optional parity-test harness that calls assembly routines from Rust tests.
`build.ps1` does not compile or link Rust code unless one of the RSSP comparison
modes is requested.

## Layout

- `asm/app/main.asm`: standalone app flow, argument parsing, reports.
- `asm/app/linux64.asm`, `asm/app/freebsd64.asm`, `asm/app/win64.asm`:
  native OS entrypoints and file/clock/stdout primitives.
- `asm/core/`: parser, scanner, hashing, timing, density, pattern, and chart
  analysis routines.
- `include/assp.inc`: NASM ABI constants, layouts, and shared macros.
- `include/win64.inc`: Win32 constants for the standalone executable.
- `include/assp.h`: C ABI declarations for external callers.
- `src/`: Rust FFI wrappers used by tests.
- `tests/`: Rust parity and smoke tests for the assembly ABI.
- `fixtures/`: small checked-in simfiles used by tests and parity scripts.

For the full exported ABI, read `include/assp.h`. For Rust-side call shape and
test coverage, read `src/abi.rs` and `tests/`.

## Requirements

- Windows x64
- `nasm` on `PATH`
- A Windows x64 linker: Visual Studio Build Tools, `lld-link`, or Rust's
  `rust-lld`
- Windows SDK x64 import libraries
- `cargo` only for Rust tests or RSSP comparison modes

Linux and FreeBSD native builds use:

- `nasm`
- `ld`, `cc`, or `gcc`

## Build

From this directory:

```powershell
.\build.ps1
```

From the workspace root:

```powershell
.\assp\build.ps1
```

The Windows executable is written to `assp\target\assp.exe`.

From Linux or FreeBSD, build the native ELF64 executable:

```bash
sh build.sh
```

The target OS is auto-detected from `uname`. The executable is written to
`assp/target/assp`.

Useful native Unix build modes:

```bash
sh build.sh --clean
sh build.sh --target linux
sh build.sh --target freebsd
sh build.sh --profile-symbols
sh build.sh --phase-profile
sh build.sh --startup-trace
sh build.sh --run-fixture
```

`--target freebsd` selects the native FreeBSD syscall platform file. Build and
run it on FreeBSD for an executable that can actually execute those syscalls.
`--startup-trace` emits low-level FreeBSD startup breadcrumbs on stderr.

Useful build modes:

```powershell
.\build.ps1 -Clean
.\build.ps1 -ProfileSymbols
.\build.ps1 -PhaseProfile
```

## Run

Run the default Camellia fixture:

```powershell
.\build.ps1 -RunFixture
```

List charts in a simfile:

```powershell
.\target\assp.exe .\fixtures\camellia_mix.ssc list
```

Run one chart:

```powershell
.\target\assp.exe .\fixtures\camellia_mix.ssc 4
```

Process every chart in one process:

```powershell
.\target\assp.exe .\fixtures\camellia_mix.ssc all
```

Quiet all-chart modes:

```powershell
.\target\assp.exe .\fixtures\camellia_mix.ssc quiet
.\target\assp.exe .\fixtures\camellia_mix.ssc bench
```

`quiet` and `bench` process every chart without printing chart reports. `bench`
is intended for timing the parser/report computation without console output.

## RSSP Parity

The comparison modes build `assp.exe`, run the local RSSP Rust CLI, and compare
report fields.

Compare one chart:

```powershell
.\build.ps1 -CompareRssp -Fixture .\fixtures\camellia_mix.ssc -Chart 4
```

Compare every chart in one fixture:

```powershell
.\build.ps1 -CompareAllCharts -Fixture .\fixtures\camellia_mix.ssc
```

Compare every bundled fixture:

```powershell
.\build.ps1 -CompareFixtures
```

Compare a song pack recursively:

```powershell
.\build.ps1 -Pack "..\songs\MyPack" -Report .\target\my_pack_parity.log -KeepGoing
```

`-Pack` implies `-CompareAllCharts`. `-KeepGoing` keeps collecting mismatches
after a file fails. `-Report` writes the same pass/fail lines and mismatch list
to a log file.

## Benchmark And Profile

Process-level ASSP vs RSSP benchmark:

```powershell
.\bench.ps1 -Fixture .\fixtures\camellia_mix.ssc -AllCharts -Runs 5 -Warmup 1 -Report .\target\bench_camellia.csv
```

Benchmark a whole pack:

```powershell
.\bench.ps1 -Pack ".\fixtures\ITL Online 2026" -Runs 5 -Warmup 1 -Report .\target\bench_itl.csv
```

Use `-AsspNoReport` on all-chart benchmarks to run `assp.exe <file> bench` and
exclude text report formatting and output.

Capture an ETW CPU-sampling trace with symbols:

```powershell
.\profile.ps1 -Fixture .\fixtures\camellia_mix.ssc -Chart all -Output .\target\assp_cpu_camellia.etl
```

`profile.ps1` uses `xperf` and must run from an elevated PowerShell prompt.

Run the built-in phase timers without admin rights:

```powershell
.\phase-profile.ps1 -Fixture .\fixtures\camellia_mix.ssc -Runs 3
```

This builds with `-PhaseProfile` and reports average ticks, milliseconds, and
stage percentages for the major parser/report stages.

## Rust Harness

Run optional Rust tests:

```powershell
cargo test
```

The Cargo harness assembles `asm/core/` routines for ABI parity tests. It is not
part of the standalone executable build path.

## Porting Priorities

1. Keep byte scanning, chart extraction, and metadata parsing deterministic.
2. Preserve RSSP-compatible note minimization, hashing, timing, and report
   fields.
3. Prefer caller-owned buffers and fixed layouts at the assembly ABI boundary.
4. Extend full step-parity coverage before expanding standalone reporting.
