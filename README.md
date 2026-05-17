# asmssp

`asmssp` is the assembly port of `rssp`, the Rust StepMania simfile parser.

This is intentionally starting as a small, testable core rather than a CLI.
The assembly routines expose a C ABI, and the Rust crate in this directory is
only a build and parity-test harness.

## Current Shape

- NASM x86-64 source lives under `asm/`.
- Shared ABI constants live in `include/asmssp.inc`.
- C callers can use `include/asmssp.h`.
- Rust tests call the assembly functions through `src/abi.rs`.

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

- Rust MSVC toolchain
- `nasm` on `PATH`

```powershell
cargo test
```

The build script assembles all `.asm` files under `asm/` and links the objects
into the Rust test binaries.

## Intended Porting Path

1. Lock down byte scanners and row classifiers.
2. Bring over RSSP's chart minimization and stat counting.
3. Add `.sm` / `.ssc` section extraction.
4. Add hash generation and compare against RSSP hash tests.
5. Expand into timing, NPS, stream breakdown, and pattern parity.

