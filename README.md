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
- `assp_find_global_bpms`
- `assp_find_chart_bpms_by_index`
- `assp_find_global_tag`
- `assp_find_chart_tag_by_index`
- `assp_find_global_timing_tags`
- `assp_find_chart_timing_tags_by_index`
- `assp_normalize_float_digits`
- `assp_parse_bpm_map`
- `assp_parse_offset_ms`
- `assp_bpm_at_beat_milli`
- `assp_elapsed_ms_bpm_only`
- `assp_elapsed_ms_with_events`
- `assp_measure_nps_milli_from_bpms`
- `assp_measure_nps_milli_with_events`
- `assp_last_beat_milli_4`
- `assp_measure_densities_4`
- `assp_minimize_measure_4`
- `assp_minimize_chart_4`
- `assp_sha1_short_hex2`
- `assp_chart_hash_pair`
- `assp_stream_counts_from_densities`
- `assp_stream_segments_from_densities`
- `assp_stream_tokens_from_densities`
- `assp_format_stream_tokens`
- `assp_format_stream_segments`
- `assp_count_note_stats_4`
- `assp_count_mines_nonfake_4`
- `assp_count_timing_fakes_4`
- `assp_count_timing_note_stats_no_holds_4`

`assp_count_note_stats_4` is an initial 4-panel note-data counter. It counts
tap arrows, holds, rolls, mines, lifts, fakes, steps, jumps, hands, and per-lane
arrow totals from a note-data byte slice. The standalone report feeds this
counter with `assp_minimize_chart_4` output so note stats are based on
RSSP-style minimized rows; phantom-hold correction is still not complete.
`assp_count_mines_nonfake_4` minimizes 4-panel note data by measure, then
counts mine rows outside parsed warp and fake timing ranges.
`assp_count_timing_fakes_4` minimizes 4-panel note data by measure, then
counts objects treated as fakes by warp/fake timing ranges, along with literal
fake notes on judgable rows.
`assp_count_timing_note_stats_no_holds_4` produces RSSP-style timing-aware
stats for 4-panel charts with no holds or rolls; the standalone report uses it
when that fast path applies.
`assp_measure_densities_4` counts per-measure step-row densities and matches
RSSP's density output for the bundled SM and SSC fixtures.
`assp_minimize_measure_4` applies RSSP's per-measure row reduction for 4-panel
charts, which is the first piece of the minimized-note/hash pipeline.
`assp_minimize_chart_4` emits RSSP-style minimized 4-panel note data using
caller-provided scratch storage.
`assp_sha1_short_hex2` computes RSSP's short lowercase SHA1 hex string for two
concatenated byte slices, used by chart hashing.
`assp_chart_hash_pair` writes RSSP's normal and BPM-neutral short SHA1 hashes
for minimized chart data.
`assp_find_global_bpms` and `assp_find_chart_bpms_by_index` select the raw BPM
tag used for chart hashing, and `assp_normalize_float_digits` converts timing
maps to RSSP's three-decimal hash input format.
`assp_find_global_tag` and `assp_find_chart_tag_by_index` provide generic
exact-tag extraction for `#TAG:` sections. The timing-tag collectors gather the
RSSP timing maps currently needed for timing parity work: BPMS, STOPS, DELAYS,
WARPS, SPEEDS, SCROLLS, and FAKES.
`assp_parse_bpm_map` parses BPM timing maps into sorted fixed-point
beat/BPM pairs, with both fields stored as signed thousandths.
`assp_parse_offset_ms` parses `#OFFSET` values into signed milliseconds for
duration adjustment.
`assp_bpm_at_beat_milli` and `assp_measure_nps_milli_from_bpms` provide the
first fixed-point NPS path from parsed BPM maps and per-measure densities.
`assp_measure_nps_milli_with_events` computes measure NPS from elapsed
measure durations when stops, delays, or warps are present.
`assp_last_beat_milli_4` finds the last object beat for 4-panel note data, and
`assp_elapsed_ms_bpm_only` computes BPM-only elapsed time in milliseconds.
`assp_elapsed_ms_with_events` extends that fixed-point duration path with RSSP's
BPM, stop, delay, and warp event ordering.
The standalone timing path applies RSSP's chart-local timing ownership rule:
when an SSC chart defines any local timing tag or offset, global timing maps are
not mixed into that chart's duration/NPS timing context. Chart-local
`#TIMESIGNATURES:`, `#LABELS:`, `#TICKCOUNTS:`, and `#COMBOS:` tags also mark
the chart as owning timing, matching RSSP's timing-data ownership check.
`assp_stream_counts_from_densities` classifies 16th/20th/24th/32nd stream
measures, SN breaks, and total break measures from those densities.
`assp_stream_segments_from_densities` emits stream and break ranges from the
same measure densities.
`assp_stream_tokens_from_densities` compresses RSSP's active stream range into
break/run tokens for later breakdown formatting.
`assp_format_stream_tokens` formats those tokens into RSSP-style detailed,
partial, or simplified breakdown text using caller-owned output storage.
`assp_format_stream_segments` formats segment ranges into RSSP's stream
breakdown text, including detailed, partial, simple, and total views.

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

Run the timing-fake fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\timing_fakes.ssc 0
```

Run the metadata-owned timing fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\chart_own_metadata_timing.ssc 0
```

The standalone executable currently scans SSC files for chart metadata and
`#NOTES:` / `#NOTES2:` tags. The second argument is a zero-based chart index, or
`list` to print chart indexes with step type, difficulty, meter, and
description. SM `#NOTES:` / `#NOTES2:` blocks are also split into their five
metadata fields before chart rows are passed to the stat counter. Chart reports
include RSSP-style chart hashes, normalized hash BPMs, peak NPS in thousandths,
density-derived stream counts, fixed-point duration metrics with
stops/delays/warps, token breakdowns, segment breakdowns, offset adjustment, and
note stats with nonfake mine and timing-fake counts.

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
4. Expand timing extraction beyond BPM tags.
5. Add NPS, duration, and pattern parity.
