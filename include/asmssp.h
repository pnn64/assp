#ifndef ASMSSP_H
#define ASMSSP_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ASMSSP_NOT_FOUND ((size_t)-1)

typedef struct asmssp_note_stats {
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
} asmssp_note_stats;

typedef struct asmssp_chart_ref {
    const uint8_t *note_data;
    size_t note_data_len;
    size_t index;
} asmssp_chart_ref;

uint32_t asmssp_version(void);
size_t asmssp_find_byte(const uint8_t *data, size_t len, uint32_t byte);
size_t asmssp_count_note_charts(const uint8_t *data, size_t len);
int32_t asmssp_find_notes_by_index(
    const uint8_t *data,
    size_t len,
    size_t index,
    asmssp_chart_ref *out
);
int32_t asmssp_count_note_stats_4(
    const uint8_t *data,
    size_t len,
    asmssp_note_stats *out
);

#ifdef __cplusplus
}
#endif

#endif
