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
- `assp_count_timing_segments`
- `assp_count_gimmick_speed_segments`
- `assp_count_gimmick_scroll_segments`
- `assp_count_note_charts`
- `assp_supported_step_type_lanes`
- `assp_find_chart_by_index`
- `assp_find_global_bpms`
- `assp_find_chart_bpms_by_index`
- `assp_find_global_tag`
- `assp_find_chart_tag_by_index`
- `assp_find_global_timing_tags`
- `assp_find_chart_timing_tags_by_index`
- `assp_chart_owns_timing_by_index`
- `assp_normalize_float_digits`
- `assp_trim_ascii_bytes`
- `assp_normalize_label_tag`
- `assp_resolve_display_bpm`
- `assp_steps_timing_allowed`
- `assp_chart_name_tag_allowed`
- `assp_resolve_difficulty_label`
- `assp_parse_tech_notation`
- `assp_parse_bpm_map`
- `assp_parse_offset_ms`
- `assp_bpm_display_range`
- `assp_bpm_average_centi`
- `assp_bpm_median_centi`
- `assp_bpm_at_beat_milli`
- `assp_tier_bpm_centi`
- `assp_elapsed_ms_bpm_only`
- `assp_elapsed_ms_with_events`
- `assp_measure_nps_milli_from_bpms`
- `assp_measure_nps_milli_with_events`
- `assp_nps_median_centi`
- `assp_last_beat_milli_4`
- `assp_last_beat_milli_8`
- `assp_measure_densities_4`
- `assp_measure_densities_8`
- `assp_measure_equally_spaced_minimized_4`
- `assp_measure_equally_spaced_minimized_8`
- `assp_count_anchors_minimized_4`
- `assp_count_facing_steps_minimized_4`
- `assp_count_basic_patterns_minimized_4`
- `assp_count_default_patterns_minimized_4`
- `assp_pattern_percentages_centi`
- `assp_minimize_measure_4`
- `assp_minimize_measure_8`
- `assp_minimize_chart_4`
- `assp_minimize_chart_8`
- `assp_sha1_short_hex2`
- `assp_chart_hash_pair`
- `assp_md5_hex`
- `assp_stream_counts_from_densities`
- `assp_stream_percentages_centi`
- `assp_stream_segments_from_densities`
- `assp_stream_tokens_from_densities`
- `assp_format_stream_tokens`
- `assp_format_stream_segments`
- `assp_count_note_stats_4`
- `assp_count_note_stats_8`
- `assp_count_mines_nonfake_4`
- `assp_count_mines_nonfake_8`
- `assp_count_timing_fakes_4`
- `assp_count_timing_fakes_8`
- `assp_count_timing_note_stats_4`
- `assp_count_timing_note_stats_8`
- `assp_count_timing_note_stats_no_holds_4`
- `assp_count_timing_note_stats_no_holds_8`

`assp_count_note_stats_4` is an initial 4-panel note-data counter. It counts
tap arrows, holds, rolls, mines, lifts, fakes, steps, jumps, hands, and per-lane
arrow totals from a note-data byte slice. The standalone report feeds this
counter with `assp_minimize_chart_4` output so note stats are based on
RSSP-style minimized rows; phantom hold/roll starts are corrected with RSSP's
matching-end rule.
`assp_count_note_stats_8` provides the same RSSP-style row/stat counting and
phantom hold correction for 8-panel chart data.
`assp_count_timing_segments` counts non-empty comma-separated timing-map
segments, matching RSSP's stop/delay/warp-style report counters.
`assp_count_gimmick_speed_segments` and
`assp_count_gimmick_scroll_segments` count non-default `#SPEEDS` and
`#SCROLLS` segments, matching RSSP's report-side gimmick filtering.
`assp_supported_step_type_lanes` resolves RSSP-supported StepMania step types:
`dance-single` / `dance_single` to 4 lanes, and `dance-double` /
`dance_double` to 8 lanes.
`assp_count_mines_nonfake_4` minimizes 4-panel note data by measure, then
counts mine rows outside parsed warp and fake timing ranges.
`assp_count_mines_nonfake_8` provides the same nonfake mine-row count for
8-panel chart data.
`assp_count_timing_fakes_4` minimizes 4-panel note data by measure, then
counts objects treated as fakes by warp/fake timing ranges, along with literal
fake notes on judgable rows.
`assp_count_timing_fakes_8` provides the same timing-fake object count for
8-panel chart data.
`assp_count_timing_note_stats_4` and `assp_count_timing_note_stats_8` produce
RSSP-style timing-aware stats for charts with holds, rolls, warps, or fakes.
The no-hold variants keep a smaller fast path for charts without holds or
rolls.
`assp_measure_densities_4` counts per-measure step-row densities and matches
RSSP's density output for the bundled SM and SSC fixtures.
`assp_measure_densities_8` provides the same density primitive for 8-panel
chart data.
`assp_measure_equally_spaced_minimized_4` and
`assp_measure_equally_spaced_minimized_8` compute RSSP's per-measure
equally-spaced flags from already-minimized note data.
`assp_count_anchors_minimized_4` counts RSSP-style left/down/up/right anchors
from minimized 4-panel note rows.
`assp_count_facing_steps_minimized_4` counts RSSP-style left-facing and
right-facing mono sequences from minimized 4-panel note rows.
`assp_count_basic_patterns_minimized_4` counts RSSP's default candle and
box-family patterns from minimized 4-panel note rows.
`assp_count_default_patterns_minimized_4` counts RSSP's full 62-entry default
pattern set from minimized 4-panel note rows.
`assp_pattern_percentages_centi` computes RSSP's two-decimal candle and mono
percentages from total steps, candle counts, and mono counts.
`assp_minimize_measure_4` and `assp_minimize_measure_8` apply RSSP's
per-measure row reduction for 4-panel and 8-panel charts, which is the first
piece of the minimized-note/hash pipeline.
`assp_minimize_chart_4` and `assp_minimize_chart_8` emit RSSP-style minimized
note data using caller-provided scratch storage.
`assp_sha1_short_hex2` computes RSSP's short lowercase SHA1 hex string for two
concatenated byte slices, used by chart hashing.
`assp_chart_hash_pair` writes RSSP's normal and BPM-neutral short SHA1 hashes
for minimized chart data.
`assp_md5_hex` writes a full lowercase MD5 hex digest for RSSP-compatible
`file_md5_hash` report output.
`assp_find_global_bpms` and `assp_find_chart_bpms_by_index` select the raw BPM
tag used for chart hashing, and `assp_normalize_float_digits` converts timing
maps to RSSP's three-decimal hash input format.
`assp_trim_ascii_bytes` trims ASCII timing metadata values for RSSP-style
normalized `#TIMESIGNATURES`, `#TICKCOUNTS`, and `#COMBOS` report fields.
`assp_normalize_label_tag` keeps the first MSD parameter from `#LABELS`,
removes ASCII backslash escapes, and drops ASCII control bytes for the
standalone report's normalized global and selected label fields.
`assp_resolve_display_bpm` resolves `#DISPLAYBPM` tags to whole-number display
min/max values with RSSP's fallback behavior.
`assp_steps_timing_allowed` applies RSSP's `#VERSION` and file-extension gate
for SSC chart-local timing data.
`assp_chart_name_tag_allowed` applies RSSP's `#VERSION` gate for whether SSC
`#CHARTNAME` is treated as the chart name or the legacy description field is
used instead.
`assp_resolve_difficulty_label` resolves old SM aliases, canonical SSC labels,
description fallback, and meter fallback to RSSP's chart difficulty label.
`assp_find_global_tag` and `assp_find_chart_tag_by_index` provide generic
tag extraction for `#TAG:` sections. Implemented simfile tag names are matched
case-insensitively, following RSSP's parser behavior. The timing-tag collectors
gather the RSSP timing maps currently needed for timing parity work: BPMS,
STOPS, DELAYS, WARPS, SPEEDS, SCROLLS, and FAKES.
`assp_parse_tech_notation` extracts RSSP's known compact tech notation tokens
from chart credit and description text with the same greedy longest-prefix
rules, `No Tech` skipping, and measure-data filtering.
`assp_chart_owns_timing_by_index` checks the RSSP chart-local timing ownership
predicate for SSC `#NOTEDATA` blocks.
`assp_parse_bpm_map` parses BPM timing maps into sorted fixed-point
beat/BPM pairs, with both fields stored as signed thousandths.
`assp_bpm_display_range` computes RSSP-style rounded min/max display BPMs,
including the same high-gimmick BPM filtering and fallback behavior.
`assp_bpm_average_centi` computes RSSP-style average display BPM rounded to two
decimal places.
`assp_bpm_median_centi` computes RSSP-style median display BPM rounded to two
decimal places.
`assp_tier_bpm_centi` computes RSSP's density-adjusted tier BPM from measure
densities and active BPM changes.
`assp_parse_offset_ms` parses `#OFFSET` values into signed milliseconds for
duration adjustment.
`assp_bpm_at_beat_milli` and `assp_measure_nps_milli_from_bpms` provide the
first fixed-point NPS path from parsed BPM maps and per-measure densities.
`assp_measure_nps_milli_with_events` computes measure NPS from elapsed
measure durations when stops, delays, or warps are present.
`assp_nps_median_centi` computes the median of a fixed-point per-measure NPS
vector rounded to two decimal places.
`assp_last_beat_milli_4` and `assp_last_beat_milli_8` find the last object beat
for 4-panel and 8-panel note data, and `assp_elapsed_ms_bpm_only` computes
BPM-only elapsed time in milliseconds.
`assp_elapsed_ms_with_events` extends that fixed-point duration path with RSSP's
BPM, stop, delay, and warp event ordering.
The standalone timing path applies RSSP's chart-local timing ownership rule:
`.sm` files always allow step timing, while `.ssc` files allow it only when
`#VERSION` is at least `0.70`. When step timing is allowed and a chart defines
any local timing tag or offset, global timing maps are not mixed into that
chart's duration/NPS timing context. Chart-local `#TIMESIGNATURES:`,
`#LABELS:`, `#TICKCOUNTS:`, and `#COMBOS:` tags also mark the chart as owning
timing, matching RSSP's timing-data ownership check. The standalone report
normalizes the selected chart/global metadata scope with that same ownership
rule, and prints selected normalized timing maps from the same chart/global
timing scope.
The chart name/description report path also follows RSSP's legacy SSC rule:
for parsed SSC versions below `0.74`, `description` is reported as empty and
the raw description field is reported as `chart_name`.
Chart difficulty output is resolved with RSSP's alias and fallback rules, with
the original raw difficulty still reported separately.
`assp_stream_counts_from_densities` classifies 16th/20th/24th/32nd stream
measures, SN breaks, and total break measures from those densities.
`assp_stream_percentages_centi` computes RSSP-style stream, adjusted stream,
and break percentages rounded to two decimal places.
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

Run the timing-aware hold fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\timing_holds.ssc 0
```

Run the basic dance-double fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\dance_double_basic.ssc 0
```

Run the dance-double timing fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\dance_double_timing.ssc 0
```

Run the dance-double timing hold fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\dance_double_timing_holds.ssc 0
```

Run the metadata-owned timing fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\chart_own_metadata_timing.ssc 0
```

Run the legacy SSC split-timing gate fixture:

```powershell
.\assp\target\assp.exe .\assp\fixtures\legacy_split_timing_disabled.ssc 0
```

The standalone executable currently scans SSC files for chart metadata and
`#NOTES:` / `#NOTES2:` tags. The second argument is a zero-based chart index, or
`list` to print chart indexes with step type, difficulty, meter, and
description. SM `#NOTES:` / `#NOTES2:` blocks are also split into their five
metadata fields before chart rows are passed to the stat counter. The standalone
report path currently supports `dance-single` and `dance-double` charts. Chart
reports include simfile title/artist/translit metadata, genre, media/artwork
tags, sample timing tags, SSC version, split-timing allowance, chart-name tag
allowance, resolved and raw difficulty, chart name, credit/step-artist metadata,
parsed tech notation, chart-local
music/attacks/timing metadata tags, chart-local raw timing tags, global
attacks/display-BPM tags, resolved display BPM ranges, global raw timing tags,
RSSP-style chart hashes, normalized global BPM data, normalized global timing
maps, file MD5 hashes, normalized global/selected timing metadata, normalized hash BPMs,
normalized selected timing maps, RSSP-compatible hash and step-artist aliases,
formatted timing BPM/stop/delay/warp/fake maps, global and selected timing
metadata tags, selected raw timing tags, chart display-BPM tags,
chart offset seconds, beat-zero timing offsets, timing ownership,
RSSP-style display BPM aliases,
min/max/average/median display BPMs, tier BPM, max/peak/median NPS,
per-measure note/NPS vectors, per-measure equally-spaced flags,
equally-spaced measure counts, formatted length,
density-derived stream counts, total stream counts, stream percentages,
stream sequence start/end/break details,
RSSP default pattern aggregates including candle/box/tower/triangle,
staircases, sweeps, copters, spirals, turbo candles, hip breakers, doritos, and
luchis, candle/mono percentages, RSSP-compatible default-pattern aliases,
anchors, mono/facing-step counts,
duration seconds, fixed-point duration metrics with stops/stops-freezes aliases,
delays, warps, token/SN breakdown aliases,
segment/stream breakdown aliases,
stop/delay/warp/speed/scroll timing segment counts, offset adjustment, and note
stats with rating, total step/arrow and lane-arrow aliases, nonfake mine, and
timing-fake counts.

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
5. Continue pattern and tech-count parity.
