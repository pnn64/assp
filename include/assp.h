#ifndef ASSP_H
#define ASSP_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ASSP_NOT_FOUND ((size_t)-1)
#define ASSP_BREAKDOWN_DETAILED 0
#define ASSP_BREAKDOWN_PARTIAL 1
#define ASSP_BREAKDOWN_SIMPLIFIED 2
#define ASSP_STREAM_BREAKDOWN_DETAILED 0
#define ASSP_STREAM_BREAKDOWN_PARTIAL 1
#define ASSP_STREAM_BREAKDOWN_SIMPLE 2
#define ASSP_STREAM_BREAKDOWN_TOTAL 3

typedef struct assp_note_stats {
    uint64_t rows;
    uint64_t steps;
    uint64_t arrows;
    uint64_t jumps;
    uint64_t hands;
    uint64_t holds;
    uint64_t rolls;
    uint64_t mines;
    uint64_t lifts;
    uint64_t fakes;
    uint64_t left;
    uint64_t down;
    uint64_t up;
    uint64_t right;
    uint64_t malformed_rows;
} assp_note_stats;

typedef struct assp_chart_ref {
    const uint8_t *note_data;
    size_t note_data_len;
    size_t index;
} assp_chart_ref;

typedef struct assp_byte_slice {
    const uint8_t *data;
    size_t len;
} assp_byte_slice;

typedef struct assp_timing_tags {
    assp_byte_slice bpms;
    assp_byte_slice stops;
    assp_byte_slice delays;
    assp_byte_slice warps;
    assp_byte_slice speeds;
    assp_byte_slice scrolls;
    assp_byte_slice fakes;
} assp_timing_tags;

typedef struct assp_bpm_segment {
    int64_t beat_milli;
    int64_t bpm_milli;
} assp_bpm_segment;

typedef struct assp_chart_info {
    const uint8_t *note_data;
    size_t note_data_len;
    size_t index;
    const uint8_t *step_type;
    size_t step_type_len;
    const uint8_t *description;
    size_t description_len;
    const uint8_t *difficulty;
    size_t difficulty_len;
    const uint8_t *meter;
    size_t meter_len;
} assp_chart_info;

typedef struct assp_stream_counts {
    uint64_t run16_streams;
    uint64_t run20_streams;
    uint64_t run24_streams;
    uint64_t run32_streams;
    uint64_t total_breaks;
    uint64_t sn_breaks;
} assp_stream_counts;

typedef struct assp_stream_segment {
    size_t start;
    size_t end;
    uint64_t is_break;
} assp_stream_segment;

typedef struct assp_stream_token {
    uint32_t kind;
    uint32_t _padding;
    size_t len;
} assp_stream_token;

uint32_t assp_version(void);
size_t assp_find_byte(const uint8_t *data, size_t len, uint32_t byte);
size_t assp_count_note_charts(const uint8_t *data, size_t len);
int32_t assp_find_notes_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    assp_chart_ref *out
);
int32_t assp_find_chart_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    assp_chart_info *out
);
int32_t assp_find_global_bpms(
    const uint8_t *data,
    size_t len,
    assp_byte_slice *out
);
int32_t assp_find_chart_bpms_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    assp_byte_slice *out
);
int32_t assp_find_global_tag(
    const uint8_t *data,
    size_t len,
    const uint8_t *tag,
    size_t tag_len,
    assp_byte_slice *out
);
int32_t assp_find_chart_tag_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    const uint8_t *tag,
    size_t tag_len,
    assp_byte_slice *out
);
int32_t assp_find_global_timing_tags(
    const uint8_t *data,
    size_t len,
    assp_timing_tags *out
);
int32_t assp_find_chart_timing_tags_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    assp_timing_tags *out
);
size_t assp_normalize_float_digits(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
size_t assp_parse_bpm_map(
    const uint8_t *data,
    size_t len,
    assp_bpm_segment *out,
    size_t out_cap
);
int64_t assp_parse_offset_ms(
    const uint8_t *data,
    size_t len
);
int64_t assp_bpm_at_beat_milli(
    const assp_bpm_segment *segments,
    size_t len,
    int64_t beat_milli
);
int64_t assp_elapsed_ms_bpm_only(
    const assp_bpm_segment *segments,
    size_t len,
    int64_t target_beat_milli
);
int64_t assp_elapsed_ms_with_events(
    const assp_bpm_segment *bpms,
    size_t bpm_len,
    const assp_bpm_segment *stops,
    size_t stop_len,
    const assp_bpm_segment *delays,
    size_t delay_len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    int64_t target_beat_milli
);
size_t assp_measure_nps_milli_from_bpms(
    const uint32_t *densities,
    size_t density_len,
    const assp_bpm_segment *bpms,
    size_t bpm_len,
    uint32_t *out,
    size_t out_cap
);
size_t assp_measure_nps_milli_with_events(
    const uint32_t *densities,
    size_t density_len,
    const assp_bpm_segment *bpms,
    size_t bpm_len,
    const assp_bpm_segment *stops,
    size_t stop_len,
    const assp_bpm_segment *delays,
    size_t delay_len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    uint32_t *out,
    size_t out_cap
);
size_t assp_measure_densities_4(
    const uint8_t *data,
    size_t len,
    uint32_t *out,
    size_t out_cap
);
size_t assp_last_beat_milli_4(
    const uint8_t *data,
    size_t len
);
size_t assp_minimize_measure_4(
    const uint8_t *rows,
    size_t row_count,
    uint8_t *out,
    size_t out_cap
);
size_t assp_minimize_chart_4(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap,
    uint8_t *row_scratch,
    size_t row_scratch_cap
);
int32_t assp_sha1_short_hex2(
    const uint8_t *first,
    size_t first_len,
    const uint8_t *second,
    size_t second_len,
    uint8_t *out16
);
int32_t assp_chart_hash_pair(
    const uint8_t *chart_data,
    size_t chart_data_len,
    const uint8_t *normalized_bpms,
    size_t normalized_bpms_len,
    uint8_t *out32
);
int32_t assp_stream_counts_from_densities(
    const uint32_t *densities,
    size_t len,
    assp_stream_counts *out
);
size_t assp_stream_segments_from_densities(
    const uint32_t *densities,
    size_t len,
    assp_stream_segment *out,
    size_t out_cap
);
size_t assp_stream_tokens_from_densities(
    const uint32_t *densities,
    size_t len,
    assp_stream_token *out,
    size_t out_cap
);
size_t assp_format_stream_tokens(
    const assp_stream_token *tokens,
    size_t len,
    uint32_t mode,
    uint8_t *out,
    size_t out_cap
);
size_t assp_format_stream_segments(
    const assp_stream_segment *segments,
    size_t len,
    uint32_t level,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_count_note_stats_4(
    const uint8_t *data,
    size_t len,
    assp_note_stats *out
);
size_t assp_count_mines_nonfake_4(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    uint8_t *row_scratch,
    size_t scratch_row_cap
);
size_t assp_count_timing_fakes_4(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    uint8_t *row_scratch,
    size_t scratch_row_cap
);

#ifdef __cplusplus
}
#endif

#endif
