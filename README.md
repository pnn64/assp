# asmssp

`asmssp` is the assembly port of `rssp`, the Rust StepMania simfile parser.

The runnable program is standalone NASM x86-64 assembly. The optional Rust
crate in this directory is only a parity-test harness for calling core assembly
routines from existing Rust tests; `build.ps1` does not use Cargo or compile
Rust code.

## Current Shape

- NASM x86-64 source lives under `asm/`.
- `asm/app/main.asm` owns the standalone executable entrypoint.
- `asm/core/` owns parser and chart-analysis routines.
- Shared ABI constants live in `include/asmssp.inc`.
- C callers can use `include/asmssp.h`.
- Optional Rust tests call core assembly functions through `src/abi.rs`.

The first implemented pieces are:

- `asmssp_version`
- `asmssp_find_byte`
- `asmssp_count_note_stats_4`

`asmssp_count_note_stats_4` is an initial 4-panel note-data counter. It counts
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
.\asmssp\build.ps1
```

The executable is written to:

```text
asmssp\target\asmssp.exe
```

Run the local Camellia fixture:

```powershell
.\asmssp\build.ps1 -RunFixture
```

Run a specific chart, where Camellia has chart indexes `0..4`:

```powershell
.\asmssp\build.ps1 -RunFixture -Chart 4
```

Run the built executable directly against any `.sm` or `.ssc` file:

```powershell
.\asmssp\target\asmssp.exe .\asmssp\fixtures\camellia_mix.ssc 4
```

The standalone executable currently scans SSC files for `#NOTES:` tags and
uses the second argument as a zero-based chart index.

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
