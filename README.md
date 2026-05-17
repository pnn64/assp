# assp

`assp` is the assembly port of `rssp`, the Rust StepMania simfile parser.

The runnable program is standalone NASM x86-64 assembly. The optional Rust
crate in this directory is only a parity-test harness for calling core assembly
routines from existing Rust tests; `build.ps1` does not use Cargo or compile
Rust code.

## Current Shape

- NASM x86-64 source lives under `asm/`.
- `asm/app/main.asm` owns the standalone executable entrypoint.
- `asm/core/` owns parser and chart-analysis routines.
- Shared ABI constants live in `include/assp.inc`.
- C callers can use `include/assp.h`.
- Optional Rust tests call core assembly functions through `src/abi.rs`.

The first implemented pieces are:

- `assp_version`
- `assp_find_byte`
- `assp_count_note_charts`
- `assp_find_chart_by_index`
- `assp_count_note_stats_4`

`assp_count_note_stats_4` is an initial 4-panel note-data counter. It counts
tap arrows, holds, rolls, mines, lifts, fakes, steps, jumps, hands, and per-lane
arrow totals from a note-data byte slice. It does not yet do RSSP's full
measure minimization or phantom-hold correction.

## Build And Test

Requirements:

- `nasm` on `PATH`
- A Windows x64 linker and Windows SDK import libraries

Build the standalone assembly executable:

```powershell
.\build.ps1
```

From the repository root, the same script can be run as:

```powershell
.\assp\build.ps1
```

The executable is written to:

```text
assp\target\assp.exe
```

Run the local Camellia fixture:

```powershell
.\assp\build.ps1 -RunFixture
```

List the local Camellia fixture chart indexes:

```powershell
.\assp\build.ps1 -RunFixture -ListCharts
```

Run a specific chart, where Camellia has chart indexes `0..4`:

```powershell
.\assp\build.ps1 -RunFixture -Chart 4
```

Run the built executable directly against any `.sm` or `.ssc` file:

```powershell
.\assp\target\assp.exe .\assp\fixtures\camellia_mix.ssc 4
```

The standalone executable currently scans SSC files for chart metadata and
`#NOTES:` tags. The second argument is a zero-based chart index, or `list` to
print chart indexes with step type, difficulty, meter, and description.
SM `#NOTES:` blocks are also split into their five metadata fields before chart
rows are passed to the stat counter.

Run the optional Rust parity tests:

```powershell
cargo test
```

The Cargo harness assembles only `asm/core/` routines. It is not part of the
standalone executable build path.

## Intended Porting Path

1. Lock down byte scanners and row classifiers.
2. Bring over RSSP's chart minimization and stat counting.
3. Add `.sm` / `.ssc` section extraction.
4. Add hash generation and compare against RSSP hash tests.
5. Expand into timing, NPS, stream breakdown, and pattern parity.
