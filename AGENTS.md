# asmssp Guidance

`asmssp` is the x86-64 assembly port of `rssp`.

The runnable program must be standalone assembly built by `build.ps1`, not by
Cargo. Rust code in this project exists only as an optional parity-test harness.
Core parser, scanner, hashing, and chart-analysis behavior belongs in NASM
source under `asm/`.

## Structure

- `asm/core/`: pure byte-slice parser and analysis routines.
- `asm/app/`: standalone executable entrypoint and app-facing I/O.
- `include/asmssp.inc`: NASM constants, ABI layout, and shared macros.
- `include/win64.inc`: Win32 constants used by standalone assembly modules.
- `include/asmssp.h`: C ABI for external callers and future harnesses.
- `src/`: Rust FFI declarations and safe wrappers used by tests.
- `tests/`: Rust parity and smoke tests that call the assembly ABI.

## Assembly Rules

- Use NASM syntax and the Windows x64 calling convention first.
- Export a small C ABI; keep structs plain, fixed-width, and documented.
- Prefer byte-slice APIs: pointer + length in, caller-owned output buffers out.
- Do not allocate in assembly core routines.
- Preserve all nonvolatile registers touched by a routine.
- Return `0` for failure and nonzero for success unless a function documents a
  different sentinel.
- Keep parser logic deterministic and bounded. Invalid input must not crash.

## Porting Order

1. Small byte scanners and classifiers.
2. Chart row/stat counting.
3. Section extraction for `.sm` and `.ssc`.
4. Hash/minimized-note pipeline.
5. Timing, density, and pattern analysis.
6. CLI/reporting only after the core ABI is stable.
