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
size_t assp_measure_densities_4(
    const uint8_t *data,
    size_t len,
    uint32_t *out,
    size_t out_cap
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
int32_t assp_count_note_stats_4(
    const uint8_t *data,
    size_t len,
    assp_note_stats *out
);

#ifdef __cplusplus
}
#endif

#endif
