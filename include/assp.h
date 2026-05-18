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
#define ASSP_PATTERN_COUNT 62

typedef enum assp_pattern_variant {
    ASSP_PATTERN_ALT_STAIRCASES_LEFT = 0,
    ASSP_PATTERN_ALT_STAIRCASES_RIGHT = 1,
    ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT = 2,
    ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT = 3,
    ASSP_PATTERN_BOX_LR = 4,
    ASSP_PATTERN_BOX_UD = 5,
    ASSP_PATTERN_BOX_CORNER_LD = 6,
    ASSP_PATTERN_BOX_CORNER_LU = 7,
    ASSP_PATTERN_BOX_CORNER_RD = 8,
    ASSP_PATTERN_BOX_CORNER_RU = 9,
    ASSP_PATTERN_CANDLE_LEFT = 10,
    ASSP_PATTERN_CANDLE_RIGHT = 11,
    ASSP_PATTERN_COPTER_LEFT = 12,
    ASSP_PATTERN_COPTER_RIGHT = 13,
    ASSP_PATTERN_COPTER_INV_LEFT = 14,
    ASSP_PATTERN_COPTER_INV_RIGHT = 15,
    ASSP_PATTERN_DORITO_RIGHT = 16,
    ASSP_PATTERN_DORITO_LEFT = 17,
    ASSP_PATTERN_DORITO_INV_RIGHT = 18,
    ASSP_PATTERN_DORITO_INV_LEFT = 19,
    ASSP_PATTERN_D_STAIRCASE_LEFT = 20,
    ASSP_PATTERN_D_STAIRCASE_RIGHT = 21,
    ASSP_PATTERN_D_STAIRCASE_INV_LEFT = 22,
    ASSP_PATTERN_D_STAIRCASE_INV_RIGHT = 23,
    ASSP_PATTERN_HIP_BREAKER_LEFT = 24,
    ASSP_PATTERN_HIP_BREAKER_RIGHT = 25,
    ASSP_PATTERN_HIP_BREAKER_INV_LEFT = 26,
    ASSP_PATTERN_HIP_BREAKER_INV_RIGHT = 27,
    ASSP_PATTERN_LUCHI_LEFT_DU = 28,
    ASSP_PATTERN_LUCHI_LEFT_UD = 29,
    ASSP_PATTERN_LUCHI_RIGHT_UD = 30,
    ASSP_PATTERN_LUCHI_RIGHT_DU = 31,
    ASSP_PATTERN_SPIRAL_LEFT = 32,
    ASSP_PATTERN_SPIRAL_RIGHT = 33,
    ASSP_PATTERN_SPIRAL_INV_LEFT = 34,
    ASSP_PATTERN_SPIRAL_INV_RIGHT = 35,
    ASSP_PATTERN_STAIRCASE_LEFT = 36,
    ASSP_PATTERN_STAIRCASE_RIGHT = 37,
    ASSP_PATTERN_STAIRCASE_INV_LEFT = 38,
    ASSP_PATTERN_STAIRCASE_INV_RIGHT = 39,
    ASSP_PATTERN_SWEEP_CANDLE_LEFT = 40,
    ASSP_PATTERN_SWEEP_CANDLE_RIGHT = 41,
    ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT = 42,
    ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT = 43,
    ASSP_PATTERN_SWEEP_LEFT = 44,
    ASSP_PATTERN_SWEEP_RIGHT = 45,
    ASSP_PATTERN_SWEEP_INV_LEFT = 46,
    ASSP_PATTERN_SWEEP_INV_RIGHT = 47,
    ASSP_PATTERN_TOWER_LR = 48,
    ASSP_PATTERN_TOWER_UD = 49,
    ASSP_PATTERN_TOWER_CORNER_LD = 50,
    ASSP_PATTERN_TOWER_CORNER_LU = 51,
    ASSP_PATTERN_TOWER_CORNER_RD = 52,
    ASSP_PATTERN_TOWER_CORNER_RU = 53,
    ASSP_PATTERN_TRIANGLE_LDL = 54,
    ASSP_PATTERN_TRIANGLE_LUL = 55,
    ASSP_PATTERN_TRIANGLE_RDR = 56,
    ASSP_PATTERN_TRIANGLE_RUR = 57,
    ASSP_PATTERN_TURBO_CANDLE_LEFT = 58,
    ASSP_PATTERN_TURBO_CANDLE_RIGHT = 59,
    ASSP_PATTERN_TURBO_CANDLE_INV_LEFT = 60,
    ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT = 61,
} assp_pattern_variant;

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

typedef struct assp_tech_counts {
    uint32_t crossovers;
    uint32_t footswitches;
    uint32_t up_footswitches;
    uint32_t down_footswitches;
    uint32_t sideswitches;
    uint32_t jacks;
    uint32_t brackets;
    uint32_t doublesteps;
} assp_tech_counts;

typedef struct assp_step_parity_state4 {
    uint8_t combined_columns[4];
    int8_t where_feet_are[5];
    uint8_t occupied_mask;
    uint8_t moved_mask;
    uint8_t holding_mask;
} assp_step_parity_state4;

typedef struct assp_step_parity_action_flags4 {
    uint8_t moved_left;
    uint8_t moved_right;
    uint8_t did_jump;
    uint8_t jacked_left;
    uint8_t jacked_right;
    uint8_t left_moved_not_holding;
    uint8_t right_moved_not_holding;
} assp_step_parity_action_flags4;

typedef struct assp_step_parity_basic_costs4 {
    float mine;
    float bracket_jack;
    float doublestep;
    float missed_footswitch;
    float total;
} assp_step_parity_basic_costs4;

typedef struct assp_step_parity_elapsed_costs4 {
    float slow_bracket;
    float jack;
    float total;
} assp_step_parity_elapsed_costs4;

typedef struct assp_step_parity_switch_costs4 {
    float footswitch;
    float sideswitch;
    float total;
} assp_step_parity_switch_costs4;

typedef struct assp_step_parity_bracket_tap_costs4 {
    float left;
    float right;
    float total;
} assp_step_parity_bracket_tap_costs4;

typedef struct assp_step_parity_distance_costs4 {
    float hold_switch;
    float big_movement;
    float total;
} assp_step_parity_distance_costs4;

typedef struct assp_step_parity_orientation_costs4 {
    float twisted_foot;
    float facing;
    float spin;
    float total;
} assp_step_parity_orientation_costs4;

typedef struct assp_step_parity_action_costs4 {
    float mine;
    float hold_switch;
    float bracket_tap;
    float bracket_jack;
    float doublestep;
    float slow_bracket;
    float twisted_foot;
    float facing;
    float spin;
    float footswitch;
    float sideswitch;
    float missed_footswitch;
    float jack;
    float big_movement;
    float total;
} assp_step_parity_action_costs4;

typedef struct assp_step_parity_row_cost_ctx4 {
    uint32_t note_count;
    uint32_t note_mask;
    uint32_t hold_mask;
    uint32_t mine_mask;
    uint32_t side_mask;
    int32_t prev_row_has_live_hold;
    const float *elapsed_seconds;
} assp_step_parity_row_cost_ctx4;

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

typedef struct assp_basic_patterns {
    uint32_t candle_left;
    uint32_t candle_right;
    uint32_t box_lr;
    uint32_t box_ud;
    uint32_t box_ld;
    uint32_t box_lu;
    uint32_t box_rd;
    uint32_t box_ru;
} assp_basic_patterns;

uint32_t assp_version(void);
size_t assp_find_byte(const uint8_t *data, size_t len, uint32_t byte);
size_t assp_count_timing_segments(const uint8_t *data, size_t len);
size_t assp_count_gimmick_speed_segments(const uint8_t *data, size_t len);
size_t assp_count_gimmick_scroll_segments(const uint8_t *data, size_t len);
size_t assp_count_note_charts(const uint8_t *data, size_t len);
size_t assp_supported_step_type_lanes(const uint8_t *data, size_t len);
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
int32_t assp_chart_owns_timing_by_index(
    const uint8_t *data,
    size_t len,
    size_t index
);
size_t assp_normalize_float_digits(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
size_t assp_trim_ascii_bytes(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
size_t assp_normalize_label_tag(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_steps_timing_allowed(
    const uint8_t *version,
    size_t version_len,
    int32_t is_sm
);
int32_t assp_chart_name_tag_allowed(
    const uint8_t *version,
    size_t version_len,
    int32_t is_sm
);
size_t assp_resolve_difficulty_label(
    const uint8_t *difficulty,
    size_t difficulty_len,
    const uint8_t *description,
    size_t description_len,
    const uint8_t *meter,
    size_t meter_len,
    int32_t is_sm,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_resolve_display_bpm(
    const uint8_t *tag,
    size_t tag_len,
    int64_t actual_min_bpm,
    int64_t actual_max_bpm,
    int64_t *out_min_bpm,
    int64_t *out_max_bpm
);
size_t assp_parse_tech_notation(
    const uint8_t *credit,
    size_t credit_len,
    const uint8_t *description,
    size_t description_len,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_count_step_tech_brackets_minimized_4(
    const uint8_t *data,
    size_t len,
    assp_tech_counts *out
);
int32_t assp_count_step_tech_brackets_minimized_8(
    const uint8_t *data,
    size_t len,
    assp_tech_counts *out
);
int32_t assp_calculate_step_tech_counts_from_placements_4(
    const uint8_t *tech_masks,
    const uint8_t *note_counts,
    const int32_t *row_ms,
    const uint8_t *placements,
    size_t row_count,
    assp_tech_counts *out
);
size_t assp_step_parity_permutations_4(
    uint32_t mask,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_step_parity_result_state_no_holds_4(
    const assp_step_parity_state4 *initial,
    const uint8_t *placement,
    uint32_t active_mask,
    assp_step_parity_state4 *out_state,
    int8_t *out_hit,
    uint32_t *out_key
);
int32_t assp_step_parity_result_state_holds_4(
    const assp_step_parity_state4 *initial,
    const uint8_t *placement,
    uint32_t active_mask,
    uint32_t hold_mask,
    assp_step_parity_state4 *out_state,
    int8_t *out_hit,
    uint32_t *out_key
);
size_t assp_step_parity_row_transitions_4(
    const assp_step_parity_state4 *initial,
    uint32_t note_mask,
    uint32_t hold_mask,
    uint8_t *out_placements,
    assp_step_parity_state4 *out_states,
    int8_t *out_hits,
    uint32_t *out_keys,
    size_t out_cap
);
size_t assp_step_parity_row_key_candidates_4(
    const assp_step_parity_state4 *initial_states,
    size_t initial_state_count,
    uint32_t note_mask,
    uint32_t hold_mask,
    uint32_t *out_predecessors,
    uint8_t *out_placements,
    assp_step_parity_state4 *out_states,
    int8_t *out_hits,
    uint32_t *out_keys,
    size_t out_cap
);
int32_t assp_step_parity_action_flags_4(
    const assp_step_parity_state4 *initial,
    const assp_step_parity_state4 *result,
    const int8_t *hit,
    assp_step_parity_action_flags4 *out
);
int32_t assp_step_parity_basic_action_costs_4(
    const assp_step_parity_state4 *result,
    const assp_step_parity_action_flags4 *flags,
    uint32_t multi_active,
    uint32_t mine_mask,
    int32_t prev_row_has_live_hold,
    assp_step_parity_basic_costs4 *out
);
int32_t assp_step_parity_elapsed_action_costs_4(
    const assp_step_parity_action_flags4 *flags,
    uint32_t note_count,
    const float *elapsed_seconds,
    assp_step_parity_elapsed_costs4 *out
);
int32_t assp_step_parity_switch_action_costs_4(
    const assp_step_parity_state4 *initial,
    const assp_step_parity_state4 *result,
    const uint8_t *placement,
    uint32_t active_mask,
    uint32_t side_mask,
    uint32_t mine_mask,
    const float *elapsed_seconds,
    assp_step_parity_switch_costs4 *out
);
int32_t assp_step_parity_bracket_tap_action_costs_4(
    const assp_step_parity_state4 *initial,
    const int8_t *hit,
    uint32_t hold_mask,
    const float *elapsed_seconds,
    assp_step_parity_bracket_tap_costs4 *out
);
int32_t assp_step_parity_distance_action_costs_4(
    const assp_step_parity_state4 *initial,
    const assp_step_parity_state4 *result,
    const int8_t *hit,
    uint32_t hold_mask,
    const float *elapsed_seconds,
    assp_step_parity_distance_costs4 *out
);
int32_t assp_step_parity_orientation_action_costs_4(
    const assp_step_parity_state4 *initial,
    const assp_step_parity_state4 *result,
    const int8_t *hit,
    assp_step_parity_orientation_costs4 *out
);
int32_t assp_step_parity_action_cost_4(
    const assp_step_parity_state4 *initial,
    const assp_step_parity_state4 *result,
    const uint8_t *placement,
    const int8_t *hit,
    uint32_t note_count,
    uint32_t active_mask,
    uint32_t hold_mask,
    uint32_t mine_mask,
    uint32_t side_mask,
    int32_t prev_row_has_live_hold,
    const float *elapsed_seconds,
    assp_step_parity_action_costs4 *out
);
size_t assp_step_parity_row_best_candidates_4(
    const assp_step_parity_state4 *initial_states,
    const float *initial_costs,
    size_t initial_state_count,
    const assp_step_parity_row_cost_ctx4 *row_ctx,
    uint32_t *out_predecessors,
    uint8_t *out_placements,
    assp_step_parity_state4 *out_states,
    int8_t *out_hits,
    uint32_t *out_keys,
    float *out_costs,
    size_t out_cap
);
size_t assp_step_parity_place_rows_4(
    const uint8_t *note_counts,
    const uint8_t *note_masks,
    const uint8_t *hold_masks,
    const uint8_t *mine_masks,
    const uint8_t *prev_row_live_holds,
    const float *row_seconds,
    size_t row_count,
    uint8_t *out_placements,
    size_t out_placement_cap,
    assp_step_parity_state4 *scratch_prev_states,
    float *scratch_prev_costs,
    assp_step_parity_state4 *scratch_next_states,
    float *scratch_next_costs,
    uint32_t *scratch_predecessors,
    uint8_t *scratch_placements,
    int8_t *scratch_hits,
    uint32_t *scratch_keys,
    uint8_t *backtrack_placements,
    uint32_t *backtrack_predecessors,
    size_t state_cap
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
int32_t assp_bpm_display_range(
    const assp_bpm_segment *segments,
    size_t len,
    int64_t *out_min_bpm,
    int64_t *out_max_bpm
);
int64_t assp_bpm_average_centi(
    const assp_bpm_segment *segments,
    size_t len
);
int64_t assp_bpm_median_centi(
    const assp_bpm_segment *segments,
    size_t len
);
int64_t assp_bpm_at_beat_milli(
    const assp_bpm_segment *segments,
    size_t len,
    int64_t beat_milli
);
int64_t assp_tier_bpm_centi(
    const uint32_t *densities,
    size_t density_len,
    const assp_bpm_segment *bpms,
    size_t bpm_len
);
int64_t assp_matrix_rating_centi(
    const uint32_t *densities,
    size_t density_len,
    const assp_bpm_segment *bpms,
    size_t bpm_len
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
size_t assp_nps_peak_milli_from_bpms(
    const uint32_t *densities,
    size_t density_len,
    const assp_bpm_segment *bpms,
    size_t bpm_len
);
size_t assp_measure_densities_4(
    const uint8_t *data,
    size_t len,
    uint32_t *out,
    size_t out_cap
);
size_t assp_measure_densities_8(
    const uint8_t *data,
    size_t len,
    uint32_t *out,
    size_t out_cap
);
size_t assp_measure_equally_spaced_minimized_4(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
size_t assp_measure_equally_spaced_minimized_8(
    const uint8_t *data,
    size_t len,
    uint8_t *out,
    size_t out_cap
);
int32_t assp_count_anchors_minimized_4(
    const uint8_t *data,
    size_t len,
    uint32_t *out4
);
int32_t assp_count_facing_steps_minimized_4(
    const uint8_t *data,
    size_t len,
    size_t mono_threshold,
    uint32_t *out2
);
int32_t assp_count_basic_patterns_minimized_4(
    const uint8_t *data,
    size_t len,
    assp_basic_patterns *out
);
int32_t assp_count_default_patterns_minimized_4(
    const uint8_t *data,
    size_t len,
    uint32_t *out62
);
int32_t assp_pattern_percentages_centi(
    uint64_t total_steps,
    uint32_t candle_total,
    uint32_t mono_total,
    uint64_t *out_candle_percent,
    uint64_t *out_mono_percent
);
int64_t assp_nps_median_centi(
    const uint32_t *nps_milli,
    size_t len
);
size_t assp_last_beat_milli_4(
    const uint8_t *data,
    size_t len
);
size_t assp_last_beat_milli_8(
    const uint8_t *data,
    size_t len
);
size_t assp_minimize_measure_4(
    const uint8_t *rows,
    size_t row_count,
    uint8_t *out,
    size_t out_cap
);
size_t assp_minimize_measure_8(
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
size_t assp_minimize_chart_8(
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
int32_t assp_md5_hex(
    const uint8_t *data,
    size_t len,
    uint8_t *out32
);
int32_t assp_stream_counts_from_densities(
    const uint32_t *densities,
    size_t len,
    assp_stream_counts *out
);
int32_t assp_stream_percentages_centi(
    const assp_stream_counts *counts,
    size_t measure_count,
    int64_t *out_stream_percent,
    int64_t *out_adjusted_stream_percent,
    int64_t *out_break_percent
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
int32_t assp_count_note_stats_8(
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
size_t assp_count_mines_nonfake_8(
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
size_t assp_count_timing_fakes_8(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    uint8_t *row_scratch,
    size_t scratch_row_cap
);
int32_t assp_count_timing_note_stats_4(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    assp_note_stats *out,
    uint8_t *scratch,
    size_t scratch_byte_cap
);
int32_t assp_count_timing_note_stats_8(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    assp_note_stats *out,
    uint8_t *scratch,
    size_t scratch_byte_cap
);
int32_t assp_count_timing_note_stats_no_holds_4(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    assp_note_stats *out,
    uint8_t *row_scratch,
    size_t scratch_row_cap
);
int32_t assp_count_timing_note_stats_no_holds_8(
    const uint8_t *data,
    size_t len,
    const assp_bpm_segment *warps,
    size_t warp_len,
    const assp_bpm_segment *fakes,
    size_t fake_len,
    assp_note_stats *out,
    uint8_t *row_scratch,
    size_t scratch_row_cap
);

#ifdef __cplusplus
}
#endif

#endif
