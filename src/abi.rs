use std::ffi::c_int;

pub const NOT_FOUND: usize = usize::MAX;
pub const STREAM_TOKEN_BREAK: u32 = 0;
pub const STREAM_TOKEN_RUN16: u32 = 16;
pub const STREAM_TOKEN_RUN20: u32 = 20;
pub const STREAM_TOKEN_RUN24: u32 = 24;
pub const STREAM_TOKEN_RUN32: u32 = 32;
pub const PATTERN_COUNT: usize = 62;
pub const BREAKDOWN_DETAILED: u32 = 0;
pub const BREAKDOWN_PARTIAL: u32 = 1;
pub const BREAKDOWN_SIMPLIFIED: u32 = 2;
pub const STREAM_BREAKDOWN_DETAILED: u32 = 0;
pub const STREAM_BREAKDOWN_PARTIAL: u32 = 1;
pub const STREAM_BREAKDOWN_SIMPLE: u32 = 2;
pub const STREAM_BREAKDOWN_TOTAL: u32 = 3;

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct NoteStats {
    pub rows: u64,
    pub steps: u64,
    pub arrows: u64,
    pub jumps: u64,
    pub hands: u64,
    pub holds: u64,
    pub rolls: u64,
    pub mines: u64,
    pub lifts: u64,
    pub fakes: u64,
    pub left: u64,
    pub down: u64,
    pub up: u64,
    pub right: u64,
    pub malformed_rows: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct TechCounts {
    pub crossovers: u32,
    pub footswitches: u32,
    pub up_footswitches: u32,
    pub down_footswitches: u32,
    pub sideswitches: u32,
    pub jacks: u32,
    pub brackets: u32,
    pub doublesteps: u32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StepParityState4 {
    pub combined_columns: [u8; 4],
    pub where_feet_are: [i8; 5],
    pub occupied_mask: u8,
    pub moved_mask: u8,
    pub holding_mask: u8,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StepParityActionFlags4 {
    pub moved_left: u8,
    pub moved_right: u8,
    pub did_jump: u8,
    pub jacked_left: u8,
    pub jacked_right: u8,
    pub left_moved_not_holding: u8,
    pub right_moved_not_holding: u8,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityBasicCosts4 {
    pub mine: f32,
    pub bracket_jack: f32,
    pub doublestep: f32,
    pub missed_footswitch: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityElapsedCosts4 {
    pub slow_bracket: f32,
    pub jack: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParitySwitchCosts4 {
    pub footswitch: f32,
    pub sideswitch: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityBracketTapCosts4 {
    pub left: f32,
    pub right: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityDistanceCosts4 {
    pub hold_switch: f32,
    pub big_movement: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityOrientationCosts4 {
    pub twisted_foot: f32,
    pub facing: f32,
    pub spin: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq)]
pub struct StepParityActionCosts4 {
    pub mine: f32,
    pub hold_switch: f32,
    pub bracket_tap: f32,
    pub bracket_jack: f32,
    pub doublestep: f32,
    pub slow_bracket: f32,
    pub twisted_foot: f32,
    pub facing: f32,
    pub spin: f32,
    pub footswitch: f32,
    pub sideswitch: f32,
    pub missed_footswitch: f32,
    pub jack: f32,
    pub big_movement: f32,
    pub total: f32,
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct StepParityRowCostCtx4 {
    pub note_count: u32,
    pub note_mask: u32,
    pub hold_mask: u32,
    pub mine_mask: u32,
    pub side_mask: u32,
    pub prev_row_has_live_hold: c_int,
    pub elapsed_seconds: *const f32,
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct StepParityPreparedRows4 {
    pub note_counts: *const u8,
    pub tech_masks: *const u8,
    pub note_masks: *const u8,
    pub hold_masks: *const u8,
    pub mine_masks: *const u8,
    pub prev_row_live_holds: *const u8,
    pub row_seconds: *const f32,
    pub row_ms: *const i32,
    pub row_count: usize,
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct StepParityWorkspace4 {
    pub out_placements: *mut u8,
    pub out_placement_cap: usize,
    pub prev_states: *mut StepParityState4,
    pub prev_costs: *mut f32,
    pub next_states: *mut StepParityState4,
    pub next_costs: *mut f32,
    pub predecessors: *mut u32,
    pub placements: *mut u8,
    pub hits: *mut i8,
    pub keys: *mut u32,
    pub backtrack_placements: *mut u8,
    pub backtrack_predecessors: *mut u32,
    pub state_cap: usize,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StepParityTransition4 {
    pub placement: [u8; 4],
    pub state: StepParityState4,
    pub hit: [i8; 5],
    pub key: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct StepParityRowCandidate4 {
    pub predecessor: u32,
    pub transition: StepParityTransition4,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct StepParityScoredRowCandidate4 {
    pub predecessor: u32,
    pub transition: StepParityTransition4,
    pub cost: f32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct StepParityPreparedRows4Owned {
    pub note_counts: Vec<u8>,
    pub tech_masks: Vec<u8>,
    pub note_masks: Vec<u8>,
    pub hold_masks: Vec<u8>,
    pub mine_masks: Vec<u8>,
    pub prev_row_live_holds: Vec<u8>,
    pub row_seconds: Vec<f32>,
    pub row_ms: Vec<i32>,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ChartRef {
    pub note_data: *const u8,
    pub note_data_len: usize,
    pub index: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ByteSlice {
    pub data: *const u8,
    pub len: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct TimingTags {
    pub bpms: ByteSlice,
    pub stops: ByteSlice,
    pub delays: ByteSlice,
    pub warps: ByteSlice,
    pub speeds: ByteSlice,
    pub scrolls: ByteSlice,
    pub fakes: ByteSlice,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct BpmSegment {
    pub beat_milli: i64,
    pub bpm_milli: i64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ChartInfo {
    pub note_data: *const u8,
    pub note_data_len: usize,
    pub index: usize,
    pub step_type: *const u8,
    pub step_type_len: usize,
    pub description: *const u8,
    pub description_len: usize,
    pub difficulty: *const u8,
    pub difficulty_len: usize,
    pub meter: *const u8,
    pub meter_len: usize,
    pub metadata: *const u8,
    pub metadata_len: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamCounts {
    pub run16_streams: u64,
    pub run20_streams: u64,
    pub run24_streams: u64,
    pub run32_streams: u64,
    pub total_breaks: u64,
    pub sn_breaks: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamSegment {
    pub start: usize,
    pub end: usize,
    pub is_break: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamToken {
    pub kind: u32,
    pub _padding: u32,
    pub len: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct BasicPatterns {
    pub candle_left: u32,
    pub candle_right: u32,
    pub box_lr: u32,
    pub box_ud: u32,
    pub box_ld: u32,
    pub box_lu: u32,
    pub box_rd: u32,
    pub box_ru: u32,
}

unsafe extern "C" {
    fn assp_version() -> u32;
    fn assp_find_byte(data: *const u8, len: usize, byte: u32) -> usize;
    fn assp_count_timing_segments(data: *const u8, len: usize) -> usize;
    fn assp_count_gimmick_speed_segments(data: *const u8, len: usize) -> usize;
    fn assp_count_gimmick_scroll_segments(data: *const u8, len: usize) -> usize;
    fn assp_count_note_charts(data: *const u8, len: usize) -> usize;
    fn assp_supported_step_type_lanes(data: *const u8, len: usize) -> usize;
    fn assp_find_notes_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ChartRef,
    ) -> c_int;
    fn assp_find_chart_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ChartInfo,
    ) -> c_int;
    fn assp_find_next_chart(
        data: *const u8,
        len: usize,
        start_offset: usize,
        out: *mut ChartInfo,
    ) -> c_int;
    fn assp_find_global_bpms(data: *const u8, len: usize, out: *mut ByteSlice) -> c_int;
    fn assp_find_chart_bpms_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_global_tag(
        data: *const u8,
        len: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_chart_tag_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_global_timing_tags(data: *const u8, len: usize, out: *mut TimingTags) -> c_int;
    fn assp_find_chart_timing_tags_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut TimingTags,
    ) -> c_int;
    fn assp_chart_owns_timing_by_index(data: *const u8, len: usize, index: usize) -> c_int;
    fn assp_normalize_float_digits(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_trim_ascii_bytes(data: *const u8, len: usize, out: *mut u8, out_cap: usize) -> usize;
    fn assp_normalize_label_tag(data: *const u8, len: usize, out: *mut u8, out_cap: usize)
    -> usize;
    fn assp_steps_timing_allowed(version: *const u8, version_len: usize, is_sm: c_int) -> c_int;
    fn assp_chart_name_tag_allowed(version: *const u8, version_len: usize, is_sm: c_int) -> c_int;
    fn assp_resolve_difficulty_label(
        difficulty: *const u8,
        difficulty_len: usize,
        description: *const u8,
        description_len: usize,
        meter: *const u8,
        meter_len: usize,
        is_sm: c_int,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_resolve_display_bpm(
        tag: *const u8,
        tag_len: usize,
        actual_min_bpm: i64,
        actual_max_bpm: i64,
        out_min_bpm: *mut i64,
        out_max_bpm: *mut i64,
    ) -> c_int;
    fn assp_parse_tech_notation(
        credit: *const u8,
        credit_len: usize,
        description: *const u8,
        description_len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_count_step_tech_brackets_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_count_step_tech_brackets_minimized_8(
        data: *const u8,
        len: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_calculate_step_tech_counts_from_placements_4(
        tech_masks: *const u8,
        note_counts: *const u8,
        row_ms: *const i32,
        placements: *const u8,
        row_count: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_step_parity_permutations_4(mask: u32, out: *mut u8, out_cap: usize) -> usize;
    fn assp_step_parity_result_state_no_holds_4(
        initial: *const StepParityState4,
        placement: *const u8,
        active_mask: u32,
        out_state: *mut StepParityState4,
        out_hit: *mut i8,
        out_key: *mut u32,
    ) -> c_int;
    fn assp_step_parity_result_state_holds_4(
        initial: *const StepParityState4,
        placement: *const u8,
        active_mask: u32,
        hold_mask: u32,
        out_state: *mut StepParityState4,
        out_hit: *mut i8,
        out_key: *mut u32,
    ) -> c_int;
    fn assp_step_parity_row_transitions_4(
        initial: *const StepParityState4,
        note_mask: u32,
        hold_mask: u32,
        out_placements: *mut u8,
        out_states: *mut StepParityState4,
        out_hits: *mut i8,
        out_keys: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_row_key_candidates_4(
        initial_states: *const StepParityState4,
        initial_state_count: usize,
        note_mask: u32,
        hold_mask: u32,
        out_predecessors: *mut u32,
        out_placements: *mut u8,
        out_states: *mut StepParityState4,
        out_hits: *mut i8,
        out_keys: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_action_flags_4(
        initial: *const StepParityState4,
        result: *const StepParityState4,
        hit: *const i8,
        out: *mut StepParityActionFlags4,
    ) -> c_int;
    fn assp_step_parity_basic_action_costs_4(
        result: *const StepParityState4,
        flags: *const StepParityActionFlags4,
        multi_active: u32,
        mine_mask: u32,
        prev_row_has_live_hold: c_int,
        out: *mut StepParityBasicCosts4,
    ) -> c_int;
    fn assp_step_parity_elapsed_action_costs_4(
        flags: *const StepParityActionFlags4,
        note_count: u32,
        elapsed_seconds: *const f32,
        out: *mut StepParityElapsedCosts4,
    ) -> c_int;
    fn assp_step_parity_switch_action_costs_4(
        initial: *const StepParityState4,
        result: *const StepParityState4,
        placement: *const u8,
        active_mask: u32,
        side_mask: u32,
        mine_mask: u32,
        elapsed_seconds: *const f32,
        out: *mut StepParitySwitchCosts4,
    ) -> c_int;
    fn assp_step_parity_bracket_tap_action_costs_4(
        initial: *const StepParityState4,
        hit: *const i8,
        hold_mask: u32,
        elapsed_seconds: *const f32,
        out: *mut StepParityBracketTapCosts4,
    ) -> c_int;
    fn assp_step_parity_distance_action_costs_4(
        initial: *const StepParityState4,
        result: *const StepParityState4,
        hit: *const i8,
        hold_mask: u32,
        elapsed_seconds: *const f32,
        out: *mut StepParityDistanceCosts4,
    ) -> c_int;
    fn assp_step_parity_orientation_action_costs_4(
        initial: *const StepParityState4,
        result: *const StepParityState4,
        hit: *const i8,
        out: *mut StepParityOrientationCosts4,
    ) -> c_int;
    fn assp_step_parity_action_cost_4(
        initial: *const StepParityState4,
        result: *const StepParityState4,
        placement: *const u8,
        hit: *const i8,
        note_count: u32,
        active_mask: u32,
        hold_mask: u32,
        mine_mask: u32,
        side_mask: u32,
        prev_row_has_live_hold: c_int,
        elapsed_seconds: *const f32,
        out: *mut StepParityActionCosts4,
    ) -> c_int;
    fn assp_step_parity_row_best_candidates_4(
        initial_states: *const StepParityState4,
        initial_costs: *const f32,
        initial_state_count: usize,
        row_ctx: *const StepParityRowCostCtx4,
        out_predecessors: *mut u32,
        out_placements: *mut u8,
        out_states: *mut StepParityState4,
        out_hits: *mut i8,
        out_keys: *mut u32,
        out_costs: *mut f32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_place_rows_4(
        note_counts: *const u8,
        note_masks: *const u8,
        hold_masks: *const u8,
        mine_masks: *const u8,
        prev_row_live_holds: *const u8,
        row_seconds: *const f32,
        row_count: usize,
        out_placements: *mut u8,
        out_placement_cap: usize,
        scratch_prev_states: *mut StepParityState4,
        scratch_prev_costs: *mut f32,
        scratch_next_states: *mut StepParityState4,
        scratch_next_costs: *mut f32,
        scratch_predecessors: *mut u32,
        scratch_placements: *mut u8,
        scratch_hits: *mut i8,
        scratch_keys: *mut u32,
        backtrack_placements: *mut u8,
        backtrack_predecessors: *mut u32,
        state_cap: usize,
    ) -> usize;
    fn assp_step_parity_count_prepared_rows_4(
        rows: *const StepParityPreparedRows4,
        workspace: *mut StepParityWorkspace4,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_step_parity_hold_head_ends_4(
        data: *const u8,
        len: usize,
        input_row_beats: *const f32,
        input_row_count: usize,
        out_hold_end_beats: *mut f32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_bpm_row_times_4(
        data: *const u8,
        len: usize,
        bpms: *const BpmSegment,
        bpm_count: usize,
        offset_ms: i64,
        out_row_seconds: *mut f32,
        out_row_ms: *mut i32,
        out_row_beats: *mut f32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_prepare_hold_rows_4(
        data: *const u8,
        len: usize,
        input_row_seconds: *const f32,
        input_row_ms: *const i32,
        input_row_beats: *const f32,
        input_hold_end_beats: *const f32,
        input_row_count: usize,
        out_note_counts: *mut u8,
        out_tech_masks: *mut u8,
        out_note_masks: *mut u8,
        out_hold_masks: *mut u8,
        out_mine_masks: *mut u8,
        out_prev_row_live_holds: *mut u8,
        out_row_seconds: *mut f32,
        out_row_ms: *mut i32,
        out_cap: usize,
    ) -> usize;
    fn assp_step_parity_prepare_tap_rows_4(
        data: *const u8,
        len: usize,
        input_row_seconds: *const f32,
        input_row_ms: *const i32,
        input_row_count: usize,
        out_note_counts: *mut u8,
        out_tech_masks: *mut u8,
        out_note_masks: *mut u8,
        out_hold_masks: *mut u8,
        out_mine_masks: *mut u8,
        out_prev_row_live_holds: *mut u8,
        out_row_seconds: *mut f32,
        out_row_ms: *mut i32,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_bpm_map(
        data: *const u8,
        len: usize,
        out: *mut BpmSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_offset_ms(data: *const u8, len: usize) -> i64;
    fn assp_bpm_display_range(
        segments: *const BpmSegment,
        len: usize,
        out_min_bpm: *mut i64,
        out_max_bpm: *mut i64,
    ) -> c_int;
    fn assp_bpm_average_centi(segments: *const BpmSegment, len: usize) -> i64;
    fn assp_bpm_median_centi(segments: *const BpmSegment, len: usize) -> i64;
    fn assp_bpm_at_beat_milli(segments: *const BpmSegment, len: usize, beat_milli: i64) -> i64;
    fn assp_tier_bpm_centi(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
    ) -> i64;
    fn assp_matrix_rating_centi(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
    ) -> i64;
    fn assp_elapsed_ms_bpm_only(
        segments: *const BpmSegment,
        len: usize,
        target_beat_milli: i64,
    ) -> i64;
    fn assp_elapsed_ms_with_events(
        bpms: *const BpmSegment,
        bpm_len: usize,
        stops: *const BpmSegment,
        stop_len: usize,
        delays: *const BpmSegment,
        delay_len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        target_beat_milli: i64,
    ) -> i64;
    fn assp_measure_nps_milli_from_bpms(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_nps_milli_with_events(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
        stops: *const BpmSegment,
        stop_len: usize,
        delays: *const BpmSegment,
        delay_len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_nps_peak_milli_from_bpms(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
    ) -> usize;
    fn assp_nps_median_centi(nps_milli: *const u32, len: usize) -> i64;
    fn assp_last_beat_milli_4(data: *const u8, len: usize) -> usize;
    fn assp_last_beat_milli_8(data: *const u8, len: usize) -> usize;
    fn assp_measure_densities_4(
        data: *const u8,
        len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_densities_8(
        data: *const u8,
        len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_equally_spaced_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_equally_spaced_minimized_8(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_count_anchors_minimized_4(data: *const u8, len: usize, out4: *mut u32) -> c_int;
    fn assp_count_facing_steps_minimized_4(
        data: *const u8,
        len: usize,
        mono_threshold: usize,
        out2: *mut u32,
    ) -> c_int;
    fn assp_count_basic_patterns_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut BasicPatterns,
    ) -> c_int;
    fn assp_count_default_patterns_minimized_4(
        data: *const u8,
        len: usize,
        out62: *mut u32,
    ) -> c_int;
    fn assp_pattern_percentages_centi(
        total_steps: u64,
        candle_total: u32,
        mono_total: u32,
        out_candle_percent: *mut u64,
        out_mono_percent: *mut u64,
    ) -> c_int;
    fn assp_minimize_measure_4(
        rows: *const u8,
        row_count: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_measure_8(
        rows: *const u8,
        row_count: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_chart_4(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
        row_scratch: *mut u8,
        row_scratch_cap: usize,
    ) -> usize;
    fn assp_minimize_chart_8(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
        row_scratch: *mut u8,
        row_scratch_cap: usize,
    ) -> usize;
    fn assp_sha1_short_hex2(
        first: *const u8,
        first_len: usize,
        second: *const u8,
        second_len: usize,
        out16: *mut u8,
    ) -> c_int;
    fn assp_chart_hash_pair(
        chart_data: *const u8,
        chart_data_len: usize,
        normalized_bpms: *const u8,
        normalized_bpms_len: usize,
        out32: *mut u8,
    ) -> c_int;
    fn assp_md5_hex(data: *const u8, len: usize, out32: *mut u8) -> c_int;
    fn assp_stream_counts_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamCounts,
    ) -> c_int;
    fn assp_stream_percentages_centi(
        counts: *const StreamCounts,
        measure_count: usize,
        out_stream_percent: *mut i64,
        out_adjusted_stream_percent: *mut i64,
        out_break_percent: *mut i64,
    ) -> c_int;
    fn assp_stream_segments_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_stream_tokens_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamToken,
        out_cap: usize,
    ) -> usize;
    fn assp_format_stream_tokens(
        tokens: *const StreamToken,
        len: usize,
        mode: u32,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_format_stream_segments(
        segments: *const StreamSegment,
        len: usize,
        level: u32,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_count_note_stats_4(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
    fn assp_count_note_stats_8(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
    fn assp_count_mines_nonfake_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> usize;
    fn assp_count_mines_nonfake_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> usize;
    fn assp_count_timing_fakes_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> usize;
    fn assp_count_timing_fakes_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> usize;
    fn assp_count_timing_note_stats_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        out: *mut NoteStats,
        scratch: *mut u8,
        scratch_byte_cap: usize,
    ) -> c_int;
    fn assp_count_timing_note_stats_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        out: *mut NoteStats,
        scratch: *mut u8,
        scratch_byte_cap: usize,
    ) -> c_int;
    fn assp_count_timing_note_stats_no_holds_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        out: *mut NoteStats,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> c_int;
    fn assp_count_timing_note_stats_no_holds_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        out: *mut NoteStats,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> c_int;
}

#[must_use]
pub fn version() -> u32 {
    unsafe { assp_version() }
}

#[must_use]
pub fn find_byte(data: &[u8], byte: u8) -> Option<usize> {
    let idx = unsafe { assp_find_byte(data.as_ptr(), data.len(), u32::from(byte)) };
    (idx != NOT_FOUND).then_some(idx)
}

#[must_use]
pub fn count_timing_segments(data: &[u8]) -> Option<usize> {
    let count = unsafe { assp_count_timing_segments(data.as_ptr(), data.len()) };
    (count != NOT_FOUND).then_some(count)
}

#[must_use]
pub fn count_gimmick_speed_segments(data: &[u8]) -> Option<usize> {
    let count = unsafe { assp_count_gimmick_speed_segments(data.as_ptr(), data.len()) };
    (count != NOT_FOUND).then_some(count)
}

#[must_use]
pub fn count_gimmick_scroll_segments(data: &[u8]) -> Option<usize> {
    let count = unsafe { assp_count_gimmick_scroll_segments(data.as_ptr(), data.len()) };
    (count != NOT_FOUND).then_some(count)
}

#[must_use]
pub fn count_note_charts(data: &[u8]) -> usize {
    unsafe { assp_count_note_charts(data.as_ptr(), data.len()) }
}

#[must_use]
pub fn supported_step_type_lanes(data: &[u8]) -> Option<usize> {
    match unsafe { assp_supported_step_type_lanes(data.as_ptr(), data.len()) } {
        4 => Some(4),
        8 => Some(8),
        _ => None,
    }
}

#[must_use]
pub fn find_notes_by_index(data: &[u8], index: usize) -> Option<ChartRef> {
    let mut chart = ChartRef::default();
    let ok = unsafe { assp_find_notes_by_index(data.as_ptr(), data.len(), index, &mut chart) };
    (ok != 0).then_some(chart)
}

#[must_use]
pub fn find_chart_by_index(data: &[u8], index: usize) -> Option<ChartInfo> {
    let mut chart = ChartInfo::default();
    let ok = unsafe { assp_find_chart_by_index(data.as_ptr(), data.len(), index, &mut chart) };
    (ok != 0).then_some(chart)
}

#[must_use]
pub fn find_next_chart(data: &[u8], start_offset: usize) -> Option<ChartInfo> {
    let mut chart = ChartInfo::default();
    let ok = unsafe { assp_find_next_chart(data.as_ptr(), data.len(), start_offset, &mut chart) };
    (ok != 0).then_some(chart)
}

#[must_use]
pub fn find_global_bpms(data: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe { assp_find_global_bpms(data.as_ptr(), data.len(), &mut slice) };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_chart_bpms_by_index(data: &[u8], index: usize) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe { assp_find_chart_bpms_by_index(data.as_ptr(), data.len(), index, &mut slice) };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_bpms_for_chart(data: &[u8], index: usize) -> Option<ByteSlice> {
    find_chart_bpms_by_index(data, index).or_else(|| find_global_bpms(data))
}

#[must_use]
pub fn find_global_tag(data: &[u8], tag: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe {
        assp_find_global_tag(
            data.as_ptr(),
            data.len(),
            tag.as_ptr(),
            tag.len(),
            &mut slice,
        )
    };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_chart_tag_by_index(data: &[u8], index: usize, tag: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe {
        assp_find_chart_tag_by_index(
            data.as_ptr(),
            data.len(),
            index,
            tag.as_ptr(),
            tag.len(),
            &mut slice,
        )
    };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_tag_for_chart(data: &[u8], index: usize, tag: &[u8]) -> Option<ByteSlice> {
    find_chart_tag_by_index(data, index, tag).or_else(|| find_global_tag(data, tag))
}

#[must_use]
pub fn find_global_timing_tags(data: &[u8]) -> Option<TimingTags> {
    let mut tags = TimingTags::default();
    let ok = unsafe { assp_find_global_timing_tags(data.as_ptr(), data.len(), &mut tags) };
    (ok != 0).then_some(tags)
}

#[must_use]
pub fn find_chart_timing_tags_by_index(data: &[u8], index: usize) -> Option<TimingTags> {
    let mut tags = TimingTags::default();
    let ok = unsafe {
        assp_find_chart_timing_tags_by_index(data.as_ptr(), data.len(), index, &mut tags)
    };
    (ok != 0).then_some(tags)
}

#[must_use]
pub fn chart_owns_timing_by_index(data: &[u8], index: usize) -> bool {
    unsafe { assp_chart_owns_timing_by_index(data.as_ptr(), data.len(), index) != 0 }
}

#[must_use]
pub fn normalize_float_digits(data: &[u8]) -> Option<Vec<u8>> {
    let count =
        unsafe { assp_normalize_float_digits(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_normalize_float_digits(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len())
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn trim_ascii_bytes(data: &[u8]) -> Option<Vec<u8>> {
    let count =
        unsafe { assp_trim_ascii_bytes(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_trim_ascii_bytes(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len())
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn normalize_label_tag(data: &[u8]) -> Option<Vec<u8>> {
    let count =
        unsafe { assp_normalize_label_tag(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_normalize_label_tag(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len())
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn steps_timing_allowed(version: Option<&[u8]>, is_sm: bool) -> bool {
    let version = version.unwrap_or_default();
    unsafe { assp_steps_timing_allowed(version.as_ptr(), version.len(), c_int::from(is_sm)) != 0 }
}

#[must_use]
pub fn chart_name_tag_allowed(version: Option<&[u8]>, is_sm: bool) -> bool {
    let version = version.unwrap_or_default();
    unsafe { assp_chart_name_tag_allowed(version.as_ptr(), version.len(), c_int::from(is_sm)) != 0 }
}

#[must_use]
pub fn resolve_difficulty_label(
    difficulty: &[u8],
    description: &[u8],
    meter: &[u8],
    is_sm: bool,
) -> Option<Vec<u8>> {
    let count = unsafe {
        assp_resolve_difficulty_label(
            difficulty.as_ptr(),
            difficulty.len(),
            description.as_ptr(),
            description.len(),
            meter.as_ptr(),
            meter.len(),
            c_int::from(is_sm),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_resolve_difficulty_label(
                difficulty.as_ptr(),
                difficulty.len(),
                description.as_ptr(),
                description.len(),
                meter.as_ptr(),
                meter.len(),
                c_int::from(is_sm),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn resolve_display_bpm(
    tag: &[u8],
    actual_min_bpm: i64,
    actual_max_bpm: i64,
) -> Option<(i64, i64)> {
    let mut out_min = 0;
    let mut out_max = 0;
    let ok = unsafe {
        assp_resolve_display_bpm(
            tag.as_ptr(),
            tag.len(),
            actual_min_bpm,
            actual_max_bpm,
            &mut out_min,
            &mut out_max,
        )
    };
    (ok != 0).then_some((out_min, out_max))
}

#[must_use]
pub fn parse_tech_notation(credit: &[u8], description: &[u8]) -> Option<Vec<u8>> {
    let count = unsafe {
        assp_parse_tech_notation(
            credit.as_ptr(),
            credit.len(),
            description.as_ptr(),
            description.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_parse_tech_notation(
                credit.as_ptr(),
                credit.len(),
                description.as_ptr(),
                description.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn count_step_tech_brackets_minimized_4(data: &[u8]) -> Option<TechCounts> {
    let mut counts = TechCounts::default();
    let ok = unsafe {
        assp_count_step_tech_brackets_minimized_4(data.as_ptr(), data.len(), &mut counts)
    };
    (ok != 0).then_some(counts)
}

#[must_use]
pub fn count_step_tech_brackets_minimized_8(data: &[u8]) -> Option<TechCounts> {
    let mut counts = TechCounts::default();
    let ok = unsafe {
        assp_count_step_tech_brackets_minimized_8(data.as_ptr(), data.len(), &mut counts)
    };
    (ok != 0).then_some(counts)
}

#[must_use]
pub fn calculate_step_tech_counts_from_placements_4(
    tech_masks: &[u8],
    note_counts: &[u8],
    row_ms: &[i32],
    placements: &[u8],
) -> Option<TechCounts> {
    let row_count = tech_masks.len();
    if note_counts.len() != row_count
        || row_ms.len() != row_count
        || placements.len() != row_count.saturating_mul(4)
    {
        return None;
    }

    let mut counts = TechCounts::default();
    let ok = unsafe {
        assp_calculate_step_tech_counts_from_placements_4(
            tech_masks.as_ptr(),
            note_counts.as_ptr(),
            row_ms.as_ptr(),
            placements.as_ptr(),
            row_count,
            &mut counts,
        )
    };
    (ok != 0).then_some(counts)
}

#[must_use]
pub fn step_parity_permutations_4(mask: u8) -> Vec<[u8; 4]> {
    let count =
        unsafe { assp_step_parity_permutations_4(u32::from(mask), std::ptr::null_mut(), 0) };
    let mut bytes = vec![0u8; count.saturating_mul(4)];
    if count != 0 {
        unsafe {
            assp_step_parity_permutations_4(u32::from(mask), bytes.as_mut_ptr(), count);
        }
    }
    bytes
        .chunks_exact(4)
        .map(|chunk| [chunk[0], chunk[1], chunk[2], chunk[3]])
        .collect()
}

#[must_use]
pub fn step_parity_result_state_no_holds_4(
    initial: &StepParityState4,
    placement: &[u8; 4],
    active_mask: u8,
) -> Option<(StepParityState4, [i8; 5], u32)> {
    let mut state = StepParityState4::default();
    let mut hit = [-1; 5];
    let mut key = 0;
    let ok = unsafe {
        assp_step_parity_result_state_no_holds_4(
            initial,
            placement.as_ptr(),
            u32::from(active_mask),
            &mut state,
            hit.as_mut_ptr(),
            &mut key,
        )
    };
    (ok != 0).then_some((state, hit, key))
}

#[must_use]
pub fn step_parity_result_state_holds_4(
    initial: &StepParityState4,
    placement: &[u8; 4],
    active_mask: u8,
    hold_mask: u8,
) -> Option<(StepParityState4, [i8; 5], u32)> {
    let mut state = StepParityState4::default();
    let mut hit = [-1; 5];
    let mut key = 0;
    let ok = unsafe {
        assp_step_parity_result_state_holds_4(
            initial,
            placement.as_ptr(),
            u32::from(active_mask),
            u32::from(hold_mask),
            &mut state,
            hit.as_mut_ptr(),
            &mut key,
        )
    };
    (ok != 0).then_some((state, hit, key))
}

#[must_use]
pub fn step_parity_row_transitions_4(
    initial: &StepParityState4,
    note_mask: u8,
    hold_mask: u8,
) -> Vec<StepParityTransition4> {
    let count = unsafe {
        assp_step_parity_row_transitions_4(
            initial,
            u32::from(note_mask),
            u32::from(hold_mask),
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            0,
        )
    };

    let mut placements = vec![0u8; count.saturating_mul(4)];
    let mut states = vec![StepParityState4::default(); count];
    let mut hits = vec![0i8; count.saturating_mul(5)];
    let mut keys = vec![0u32; count];
    if count != 0 {
        unsafe {
            assp_step_parity_row_transitions_4(
                initial,
                u32::from(note_mask),
                u32::from(hold_mask),
                placements.as_mut_ptr(),
                states.as_mut_ptr(),
                hits.as_mut_ptr(),
                keys.as_mut_ptr(),
                count,
            );
        }
    }

    (0..count)
        .map(|i| StepParityTransition4 {
            placement: [
                placements[i * 4],
                placements[i * 4 + 1],
                placements[i * 4 + 2],
                placements[i * 4 + 3],
            ],
            state: states[i],
            hit: [
                hits[i * 5],
                hits[i * 5 + 1],
                hits[i * 5 + 2],
                hits[i * 5 + 3],
                hits[i * 5 + 4],
            ],
            key: keys[i],
        })
        .collect()
}

#[must_use]
pub fn step_parity_row_key_candidates_4(
    initial_states: &[StepParityState4],
    note_mask: u8,
    hold_mask: u8,
) -> Option<Vec<StepParityRowCandidate4>> {
    let cap = initial_states.len().saturating_mul(24);
    let mut predecessors = vec![0u32; cap];
    let mut placements = vec![0u8; cap.saturating_mul(4)];
    let mut states = vec![StepParityState4::default(); cap];
    let mut hits = vec![0i8; cap.saturating_mul(5)];
    let mut keys = vec![0u32; cap];
    let count = unsafe {
        assp_step_parity_row_key_candidates_4(
            initial_states.as_ptr(),
            initial_states.len(),
            u32::from(note_mask),
            u32::from(hold_mask),
            predecessors.as_mut_ptr(),
            placements.as_mut_ptr(),
            states.as_mut_ptr(),
            hits.as_mut_ptr(),
            keys.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    Some(
        (0..count)
            .map(|i| StepParityRowCandidate4 {
                predecessor: predecessors[i],
                transition: StepParityTransition4 {
                    placement: [
                        placements[i * 4],
                        placements[i * 4 + 1],
                        placements[i * 4 + 2],
                        placements[i * 4 + 3],
                    ],
                    state: states[i],
                    hit: [
                        hits[i * 5],
                        hits[i * 5 + 1],
                        hits[i * 5 + 2],
                        hits[i * 5 + 3],
                        hits[i * 5 + 4],
                    ],
                    key: keys[i],
                },
            })
            .collect(),
    )
}

#[allow(clippy::too_many_arguments)]
#[must_use]
pub fn step_parity_row_best_candidates_4(
    initial_states: &[StepParityState4],
    initial_costs: &[f32],
    note_count: u8,
    note_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed_seconds: f32,
) -> Option<Vec<StepParityScoredRowCandidate4>> {
    if initial_states.len() != initial_costs.len() {
        return None;
    }

    let cap = initial_states.len().saturating_mul(24);
    let elapsed = elapsed_seconds;
    let ctx = StepParityRowCostCtx4 {
        note_count: u32::from(note_count),
        note_mask: u32::from(note_mask),
        hold_mask: u32::from(hold_mask),
        mine_mask: u32::from(mine_mask),
        side_mask: u32::from(side_mask),
        prev_row_has_live_hold: c_int::from(prev_row_has_live_hold),
        elapsed_seconds: &elapsed,
    };
    let mut predecessors = vec![0u32; cap];
    let mut placements = vec![0u8; cap.saturating_mul(4)];
    let mut states = vec![StepParityState4::default(); cap];
    let mut hits = vec![0i8; cap.saturating_mul(5)];
    let mut keys = vec![0u32; cap];
    let mut costs = vec![0.0f32; cap];
    let count = unsafe {
        assp_step_parity_row_best_candidates_4(
            initial_states.as_ptr(),
            initial_costs.as_ptr(),
            initial_states.len(),
            &ctx,
            predecessors.as_mut_ptr(),
            placements.as_mut_ptr(),
            states.as_mut_ptr(),
            hits.as_mut_ptr(),
            keys.as_mut_ptr(),
            costs.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    Some(
        (0..count)
            .map(|i| StepParityScoredRowCandidate4 {
                predecessor: predecessors[i],
                transition: StepParityTransition4 {
                    placement: [
                        placements[i * 4],
                        placements[i * 4 + 1],
                        placements[i * 4 + 2],
                        placements[i * 4 + 3],
                    ],
                    state: states[i],
                    hit: [
                        hits[i * 5],
                        hits[i * 5 + 1],
                        hits[i * 5 + 2],
                        hits[i * 5 + 3],
                        hits[i * 5 + 4],
                    ],
                    key: keys[i],
                },
                cost: costs[i],
            })
            .collect(),
    )
}

#[must_use]
pub fn step_parity_place_rows_4(
    note_counts: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
    state_cap: usize,
) -> Option<Vec<[u8; 4]>> {
    let row_count = note_counts.len();
    if note_masks.len() != row_count
        || hold_masks.len() != row_count
        || mine_masks.len() != row_count
        || prev_row_live_holds.len() != row_count
        || row_seconds.len() != row_count
    {
        return None;
    }
    if row_count == 0 {
        return Some(Vec::new());
    }
    if state_cap == 0 {
        return None;
    }

    let output_len = row_count.checked_mul(4)?;
    let scratch_placements_len = state_cap.checked_mul(4)?;
    let scratch_hits_len = state_cap.checked_mul(5)?;
    let backtrack_count = row_count.checked_mul(state_cap)?;
    let backtrack_placements_len = backtrack_count.checked_mul(4)?;

    let mut out_placements = vec![0u8; output_len];
    let mut scratch_prev_states = vec![StepParityState4::default(); state_cap];
    let mut scratch_prev_costs = vec![0.0f32; state_cap];
    let mut scratch_next_states = vec![StepParityState4::default(); state_cap];
    let mut scratch_next_costs = vec![0.0f32; state_cap];
    let mut scratch_predecessors = vec![0u32; state_cap];
    let mut scratch_placements = vec![0u8; scratch_placements_len];
    let mut scratch_hits = vec![0i8; scratch_hits_len];
    let mut scratch_keys = vec![0u32; state_cap];
    let mut backtrack_placements = vec![0u8; backtrack_placements_len];
    let mut backtrack_predecessors = vec![0u32; backtrack_count];
    let count = unsafe {
        assp_step_parity_place_rows_4(
            note_counts.as_ptr(),
            note_masks.as_ptr(),
            hold_masks.as_ptr(),
            mine_masks.as_ptr(),
            prev_row_live_holds.as_ptr(),
            row_seconds.as_ptr(),
            row_count,
            out_placements.as_mut_ptr(),
            out_placements.len(),
            scratch_prev_states.as_mut_ptr(),
            scratch_prev_costs.as_mut_ptr(),
            scratch_next_states.as_mut_ptr(),
            scratch_next_costs.as_mut_ptr(),
            scratch_predecessors.as_mut_ptr(),
            scratch_placements.as_mut_ptr(),
            scratch_hits.as_mut_ptr(),
            scratch_keys.as_mut_ptr(),
            backtrack_placements.as_mut_ptr(),
            backtrack_predecessors.as_mut_ptr(),
            state_cap,
        )
    };
    if count == NOT_FOUND || count != row_count {
        return None;
    }

    Some(
        out_placements
            .chunks_exact(4)
            .map(|row| [row[0], row[1], row[2], row[3]])
            .collect(),
    )
}

#[must_use]
pub fn step_parity_count_prepared_rows_4(
    note_counts: &[u8],
    tech_masks: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
    row_ms: &[i32],
    state_cap: usize,
) -> Option<TechCounts> {
    let row_count = note_counts.len();
    if tech_masks.len() != row_count
        || note_masks.len() != row_count
        || hold_masks.len() != row_count
        || mine_masks.len() != row_count
        || prev_row_live_holds.len() != row_count
        || row_seconds.len() != row_count
        || row_ms.len() != row_count
    {
        return None;
    }
    if row_count != 0 && state_cap == 0 {
        return None;
    }

    let output_len = row_count.checked_mul(4)?;
    let scratch_placements_len = state_cap.checked_mul(4)?;
    let scratch_hits_len = state_cap.checked_mul(5)?;
    let backtrack_count = row_count.checked_mul(state_cap)?;
    let backtrack_placements_len = backtrack_count.checked_mul(4)?;

    let mut out_placements = vec![0u8; output_len];
    let mut prev_states = vec![StepParityState4::default(); state_cap];
    let mut prev_costs = vec![0.0f32; state_cap];
    let mut next_states = vec![StepParityState4::default(); state_cap];
    let mut next_costs = vec![0.0f32; state_cap];
    let mut predecessors = vec![0u32; state_cap];
    let mut placements = vec![0u8; scratch_placements_len];
    let mut hits = vec![0i8; scratch_hits_len];
    let mut keys = vec![0u32; state_cap];
    let mut backtrack_placements = vec![0u8; backtrack_placements_len];
    let mut backtrack_predecessors = vec![0u32; backtrack_count];
    let rows = StepParityPreparedRows4 {
        note_counts: note_counts.as_ptr(),
        tech_masks: tech_masks.as_ptr(),
        note_masks: note_masks.as_ptr(),
        hold_masks: hold_masks.as_ptr(),
        mine_masks: mine_masks.as_ptr(),
        prev_row_live_holds: prev_row_live_holds.as_ptr(),
        row_seconds: row_seconds.as_ptr(),
        row_ms: row_ms.as_ptr(),
        row_count,
    };
    let mut workspace = StepParityWorkspace4 {
        out_placements: out_placements.as_mut_ptr(),
        out_placement_cap: out_placements.len(),
        prev_states: prev_states.as_mut_ptr(),
        prev_costs: prev_costs.as_mut_ptr(),
        next_states: next_states.as_mut_ptr(),
        next_costs: next_costs.as_mut_ptr(),
        predecessors: predecessors.as_mut_ptr(),
        placements: placements.as_mut_ptr(),
        hits: hits.as_mut_ptr(),
        keys: keys.as_mut_ptr(),
        backtrack_placements: backtrack_placements.as_mut_ptr(),
        backtrack_predecessors: backtrack_predecessors.as_mut_ptr(),
        state_cap,
    };
    let mut out = TechCounts::default();
    let ok = unsafe { assp_step_parity_count_prepared_rows_4(&rows, &mut workspace, &mut out) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_prepare_tap_rows_4(
    data: &[u8],
    input_row_seconds: &[f32],
    input_row_ms: &[i32],
) -> Option<StepParityPreparedRows4Owned> {
    if input_row_seconds.len() != input_row_ms.len() {
        return None;
    }

    let cap = data.len() / 4 + 1;
    let mut note_counts = vec![0u8; cap];
    let mut tech_masks = vec![0u8; cap];
    let mut note_masks = vec![0u8; cap];
    let mut hold_masks = vec![0u8; cap];
    let mut mine_masks = vec![0u8; cap];
    let mut prev_row_live_holds = vec![0u8; cap];
    let mut row_seconds = vec![0.0f32; cap];
    let mut row_ms = vec![0i32; cap];
    let count = unsafe {
        assp_step_parity_prepare_tap_rows_4(
            data.as_ptr(),
            data.len(),
            input_row_seconds.as_ptr(),
            input_row_ms.as_ptr(),
            input_row_seconds.len(),
            note_counts.as_mut_ptr(),
            tech_masks.as_mut_ptr(),
            note_masks.as_mut_ptr(),
            hold_masks.as_mut_ptr(),
            mine_masks.as_mut_ptr(),
            prev_row_live_holds.as_mut_ptr(),
            row_seconds.as_mut_ptr(),
            row_ms.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    note_counts.truncate(count);
    tech_masks.truncate(count);
    note_masks.truncate(count);
    hold_masks.truncate(count);
    mine_masks.truncate(count);
    prev_row_live_holds.truncate(count);
    row_seconds.truncate(count);
    row_ms.truncate(count);
    Some(StepParityPreparedRows4Owned {
        note_counts,
        tech_masks,
        note_masks,
        hold_masks,
        mine_masks,
        prev_row_live_holds,
        row_seconds,
        row_ms,
    })
}

#[must_use]
pub fn step_parity_hold_head_ends_4(data: &[u8], input_row_beats: &[f32]) -> Option<Vec<[f32; 4]>> {
    let cap = input_row_beats.len();
    let mut hold_end_beats = vec![-1.0f32; cap * 4];
    let count = unsafe {
        assp_step_parity_hold_head_ends_4(
            data.as_ptr(),
            data.len(),
            input_row_beats.as_ptr(),
            input_row_beats.len(),
            hold_end_beats.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    hold_end_beats.truncate(count * 4);
    Some(
        hold_end_beats
            .chunks_exact(4)
            .map(|chunk| [chunk[0], chunk[1], chunk[2], chunk[3]])
            .collect(),
    )
}

#[must_use]
pub fn step_parity_bpm_row_times_4(
    data: &[u8],
    bpms: &[BpmSegment],
    offset_ms: i64,
) -> Option<(Vec<f32>, Vec<i32>, Vec<f32>)> {
    let cap = data.len() / 4 + 1;
    let mut row_seconds = vec![0.0f32; cap];
    let mut row_ms = vec![0i32; cap];
    let mut row_beats = vec![0.0f32; cap];
    let count = unsafe {
        assp_step_parity_bpm_row_times_4(
            data.as_ptr(),
            data.len(),
            bpms.as_ptr(),
            bpms.len(),
            offset_ms,
            row_seconds.as_mut_ptr(),
            row_ms.as_mut_ptr(),
            row_beats.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    row_seconds.truncate(count);
    row_ms.truncate(count);
    row_beats.truncate(count);
    Some((row_seconds, row_ms, row_beats))
}

#[must_use]
pub fn step_parity_prepare_hold_rows_4(
    data: &[u8],
    input_row_seconds: &[f32],
    input_row_ms: &[i32],
    input_row_beats: &[f32],
) -> Option<StepParityPreparedRows4Owned> {
    if input_row_seconds.len() != input_row_ms.len()
        || input_row_seconds.len() != input_row_beats.len()
    {
        return None;
    }

    let cap = data.len() / 4 + 1;
    let mut hold_end_beats = vec![-1.0f32; input_row_beats.len() * 4];
    let source_count = unsafe {
        assp_step_parity_hold_head_ends_4(
            data.as_ptr(),
            data.len(),
            input_row_beats.as_ptr(),
            input_row_beats.len(),
            hold_end_beats.as_mut_ptr(),
            input_row_beats.len(),
        )
    };
    if source_count == NOT_FOUND {
        return None;
    }
    hold_end_beats.truncate(source_count * 4);

    let mut note_counts = vec![0u8; cap];
    let mut tech_masks = vec![0u8; cap];
    let mut note_masks = vec![0u8; cap];
    let mut hold_masks = vec![0u8; cap];
    let mut mine_masks = vec![0u8; cap];
    let mut prev_row_live_holds = vec![0u8; cap];
    let mut row_seconds = vec![0.0f32; cap];
    let mut row_ms = vec![0i32; cap];
    let count = unsafe {
        assp_step_parity_prepare_hold_rows_4(
            data.as_ptr(),
            data.len(),
            input_row_seconds.as_ptr(),
            input_row_ms.as_ptr(),
            input_row_beats.as_ptr(),
            hold_end_beats.as_ptr(),
            source_count,
            note_counts.as_mut_ptr(),
            tech_masks.as_mut_ptr(),
            note_masks.as_mut_ptr(),
            hold_masks.as_mut_ptr(),
            mine_masks.as_mut_ptr(),
            prev_row_live_holds.as_mut_ptr(),
            row_seconds.as_mut_ptr(),
            row_ms.as_mut_ptr(),
            cap,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    note_counts.truncate(count);
    tech_masks.truncate(count);
    note_masks.truncate(count);
    hold_masks.truncate(count);
    mine_masks.truncate(count);
    prev_row_live_holds.truncate(count);
    row_seconds.truncate(count);
    row_ms.truncate(count);
    Some(StepParityPreparedRows4Owned {
        note_counts,
        tech_masks,
        note_masks,
        hold_masks,
        mine_masks,
        prev_row_live_holds,
        row_seconds,
        row_ms,
    })
}

#[must_use]
pub fn step_parity_count_hold_rows_4(
    data: &[u8],
    input_row_seconds: &[f32],
    input_row_ms: &[i32],
    input_row_beats: &[f32],
    state_cap: usize,
) -> Option<TechCounts> {
    let rows =
        step_parity_prepare_hold_rows_4(data, input_row_seconds, input_row_ms, input_row_beats)?;
    step_parity_count_prepared_rows_4(
        &rows.note_counts,
        &rows.tech_masks,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        &rows.row_ms,
        state_cap,
    )
}

#[must_use]
pub fn step_parity_action_flags_4(
    initial: &StepParityState4,
    result: &StepParityState4,
    hit: &[i8; 5],
) -> Option<StepParityActionFlags4> {
    let mut out = StepParityActionFlags4::default();
    let ok = unsafe { assp_step_parity_action_flags_4(initial, result, hit.as_ptr(), &mut out) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_basic_action_costs_4(
    result: &StepParityState4,
    flags: &StepParityActionFlags4,
    multi_active: bool,
    mine_mask: u8,
    prev_row_has_live_hold: bool,
) -> Option<StepParityBasicCosts4> {
    let mut out = StepParityBasicCosts4::default();
    let ok = unsafe {
        assp_step_parity_basic_action_costs_4(
            result,
            flags,
            u32::from(multi_active),
            u32::from(mine_mask),
            c_int::from(prev_row_has_live_hold),
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_elapsed_action_costs_4(
    flags: &StepParityActionFlags4,
    note_count: u8,
    elapsed_seconds: f32,
) -> Option<StepParityElapsedCosts4> {
    let mut out = StepParityElapsedCosts4::default();
    let ok = unsafe {
        assp_step_parity_elapsed_action_costs_4(
            flags,
            u32::from(note_count),
            &elapsed_seconds,
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_switch_action_costs_4(
    initial: &StepParityState4,
    result: &StepParityState4,
    placement: &[u8; 4],
    active_mask: u8,
    side_mask: u8,
    mine_mask: u8,
    elapsed_seconds: f32,
) -> Option<StepParitySwitchCosts4> {
    let mut out = StepParitySwitchCosts4::default();
    let ok = unsafe {
        assp_step_parity_switch_action_costs_4(
            initial,
            result,
            placement.as_ptr(),
            u32::from(active_mask),
            u32::from(side_mask),
            u32::from(mine_mask),
            &elapsed_seconds,
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_bracket_tap_action_costs_4(
    initial: &StepParityState4,
    hit: &[i8; 5],
    hold_mask: u8,
    elapsed_seconds: f32,
) -> Option<StepParityBracketTapCosts4> {
    let mut out = StepParityBracketTapCosts4::default();
    let ok = unsafe {
        assp_step_parity_bracket_tap_action_costs_4(
            initial,
            hit.as_ptr(),
            u32::from(hold_mask),
            &elapsed_seconds,
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_distance_action_costs_4(
    initial: &StepParityState4,
    result: &StepParityState4,
    hit: &[i8; 5],
    hold_mask: u8,
    elapsed_seconds: f32,
) -> Option<StepParityDistanceCosts4> {
    let mut out = StepParityDistanceCosts4::default();
    let ok = unsafe {
        assp_step_parity_distance_action_costs_4(
            initial,
            result,
            hit.as_ptr(),
            u32::from(hold_mask),
            &elapsed_seconds,
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_orientation_action_costs_4(
    initial: &StepParityState4,
    result: &StepParityState4,
    hit: &[i8; 5],
) -> Option<StepParityOrientationCosts4> {
    let mut out = StepParityOrientationCosts4::default();
    let ok = unsafe {
        assp_step_parity_orientation_action_costs_4(initial, result, hit.as_ptr(), &mut out)
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn step_parity_action_cost_4(
    initial: &StepParityState4,
    result: &StepParityState4,
    placement: &[u8; 4],
    hit: &[i8; 5],
    note_count: u8,
    active_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed_seconds: f32,
) -> Option<StepParityActionCosts4> {
    let mut out = StepParityActionCosts4::default();
    let ok = unsafe {
        assp_step_parity_action_cost_4(
            initial,
            result,
            placement.as_ptr(),
            hit.as_ptr(),
            u32::from(note_count),
            u32::from(active_mask),
            u32::from(hold_mask),
            u32::from(mine_mask),
            u32::from(side_mask),
            c_int::from(prev_row_has_live_hold),
            &elapsed_seconds,
            &mut out,
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn parse_bpm_map(data: &[u8]) -> Option<Vec<BpmSegment>> {
    let count = unsafe { assp_parse_bpm_map(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![BpmSegment::default(); count];
    if count != 0 {
        let written =
            unsafe { assp_parse_bpm_map(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len()) };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn parse_offset_ms(data: &[u8]) -> i64 {
    unsafe { assp_parse_offset_ms(data.as_ptr(), data.len()) }
}

#[must_use]
pub fn bpm_display_range(segments: &[BpmSegment]) -> Option<(i64, i64)> {
    let mut min_bpm = 0;
    let mut max_bpm = 0;
    let ok = unsafe {
        assp_bpm_display_range(
            segments.as_ptr(),
            segments.len(),
            &mut min_bpm,
            &mut max_bpm,
        )
    };
    (ok != 0).then_some((min_bpm, max_bpm))
}

#[must_use]
pub fn bpm_average_centi(segments: &[BpmSegment]) -> i64 {
    unsafe { assp_bpm_average_centi(segments.as_ptr(), segments.len()) }
}

#[must_use]
pub fn bpm_median_centi(segments: &[BpmSegment]) -> i64 {
    unsafe { assp_bpm_median_centi(segments.as_ptr(), segments.len()) }
}

#[must_use]
pub fn bpm_at_beat_milli(segments: &[BpmSegment], beat_milli: i64) -> i64 {
    unsafe { assp_bpm_at_beat_milli(segments.as_ptr(), segments.len(), beat_milli) }
}

#[must_use]
pub fn tier_bpm_centi(densities: &[u32], bpms: &[BpmSegment]) -> i64 {
    unsafe {
        assp_tier_bpm_centi(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
        )
    }
}

#[must_use]
pub fn matrix_rating_centi(densities: &[u32], bpms: &[BpmSegment]) -> i64 {
    unsafe {
        assp_matrix_rating_centi(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
        )
    }
}

#[must_use]
pub fn elapsed_ms_bpm_only(segments: &[BpmSegment], target_beat_milli: i64) -> i64 {
    unsafe { assp_elapsed_ms_bpm_only(segments.as_ptr(), segments.len(), target_beat_milli) }
}

#[must_use]
pub fn elapsed_ms_with_events(
    bpms: &[BpmSegment],
    stops: &[BpmSegment],
    delays: &[BpmSegment],
    warps: &[BpmSegment],
    target_beat_milli: i64,
) -> i64 {
    if stops.is_empty() && delays.is_empty() && warps.is_empty() {
        return elapsed_ms_bpm_only(bpms, target_beat_milli);
    }

    unsafe {
        assp_elapsed_ms_with_events(
            bpms.as_ptr(),
            bpms.len(),
            stops.as_ptr(),
            stops.len(),
            delays.as_ptr(),
            delays.len(),
            warps.as_ptr(),
            warps.len(),
            target_beat_milli,
        )
    }
}

#[must_use]
pub fn measure_nps_milli_from_bpms(densities: &[u32], bpms: &[BpmSegment]) -> Option<Vec<u32>> {
    let count = unsafe {
        assp_measure_nps_milli_from_bpms(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_measure_nps_milli_from_bpms(
                densities.as_ptr(),
                densities.len(),
                bpms.as_ptr(),
                bpms.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn measure_nps_milli_with_events(
    densities: &[u32],
    bpms: &[BpmSegment],
    stops: &[BpmSegment],
    delays: &[BpmSegment],
    warps: &[BpmSegment],
) -> Option<Vec<u32>> {
    if stops.is_empty() && delays.is_empty() && warps.is_empty() {
        return measure_nps_milli_from_bpms(densities, bpms);
    }

    let count = unsafe {
        assp_measure_nps_milli_with_events(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
            stops.as_ptr(),
            stops.len(),
            delays.as_ptr(),
            delays.len(),
            warps.as_ptr(),
            warps.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_measure_nps_milli_with_events(
                densities.as_ptr(),
                densities.len(),
                bpms.as_ptr(),
                bpms.len(),
                stops.as_ptr(),
                stops.len(),
                delays.as_ptr(),
                delays.len(),
                warps.as_ptr(),
                warps.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn nps_peak_milli_from_bpms(densities: &[u32], bpms: &[BpmSegment]) -> Option<u32> {
    let peak = unsafe {
        assp_nps_peak_milli_from_bpms(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
        )
    };
    (peak != NOT_FOUND).then_some(peak as u32)
}

#[must_use]
pub fn nps_median_centi(nps_milli: &[u32]) -> i64 {
    unsafe { assp_nps_median_centi(nps_milli.as_ptr(), nps_milli.len()) }
}

#[must_use]
pub fn last_beat_milli_4(data: &[u8]) -> Option<usize> {
    let beat = unsafe { assp_last_beat_milli_4(data.as_ptr(), data.len()) };
    (beat != NOT_FOUND).then_some(beat)
}

#[must_use]
pub fn last_beat_milli_8(data: &[u8]) -> Option<usize> {
    let beat = unsafe { assp_last_beat_milli_8(data.as_ptr(), data.len()) };
    (beat != NOT_FOUND).then_some(beat)
}

#[must_use]
pub fn measure_densities_4(data: &[u8]) -> Vec<u32> {
    let count =
        unsafe { assp_measure_densities_4(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe { assp_measure_densities_4(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len()) };
    }
    out
}

#[must_use]
pub fn measure_densities_8(data: &[u8]) -> Vec<u32> {
    let count =
        unsafe { assp_measure_densities_8(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe { assp_measure_densities_8(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len()) };
    }
    out
}

#[must_use]
pub fn measure_equally_spaced_minimized_4(data: &[u8]) -> Vec<bool> {
    let count = unsafe {
        assp_measure_equally_spaced_minimized_4(data.as_ptr(), data.len(), std::ptr::null_mut(), 0)
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_measure_equally_spaced_minimized_4(
                data.as_ptr(),
                data.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out.into_iter().map(|v| v != 0).collect()
}

#[must_use]
pub fn measure_equally_spaced_minimized_8(data: &[u8]) -> Vec<bool> {
    let count = unsafe {
        assp_measure_equally_spaced_minimized_8(data.as_ptr(), data.len(), std::ptr::null_mut(), 0)
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_measure_equally_spaced_minimized_8(
                data.as_ptr(),
                data.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out.into_iter().map(|v| v != 0).collect()
}

#[must_use]
pub fn count_anchors_minimized_4(data: &[u8]) -> Option<[u32; 4]> {
    let mut out = [0; 4];
    let ok = unsafe { assp_count_anchors_minimized_4(data.as_ptr(), data.len(), out.as_mut_ptr()) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn count_facing_steps_minimized_4(data: &[u8], mono_threshold: usize) -> Option<[u32; 2]> {
    let mut out = [0; 2];
    let ok = unsafe {
        assp_count_facing_steps_minimized_4(
            data.as_ptr(),
            data.len(),
            mono_threshold,
            out.as_mut_ptr(),
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn count_basic_patterns_minimized_4(data: &[u8]) -> Option<BasicPatterns> {
    let mut out = BasicPatterns::default();
    let ok = unsafe { assp_count_basic_patterns_minimized_4(data.as_ptr(), data.len(), &mut out) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn count_default_patterns_minimized_4(data: &[u8]) -> Option<[u32; PATTERN_COUNT]> {
    let mut out = [0; PATTERN_COUNT];
    let ok = unsafe {
        assp_count_default_patterns_minimized_4(data.as_ptr(), data.len(), out.as_mut_ptr())
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn pattern_percentages_centi(
    total_steps: u64,
    candle_total: u32,
    mono_total: u32,
) -> Option<(u64, u64)> {
    let mut candle = 0;
    let mut mono = 0;
    let ok = unsafe {
        assp_pattern_percentages_centi(
            total_steps,
            candle_total,
            mono_total,
            &mut candle,
            &mut mono,
        )
    };
    (ok != 0).then_some((candle, mono))
}

#[must_use]
pub fn minimize_measure_4(rows: &[[u8; 4]]) -> Vec<[u8; 4]> {
    let count = unsafe {
        assp_minimize_measure_4(
            rows.as_ptr().cast::<u8>(),
            rows.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![[0; 4]; count];
    if count != 0 {
        unsafe {
            assp_minimize_measure_4(
                rows.as_ptr().cast::<u8>(),
                rows.len(),
                out.as_mut_ptr().cast::<u8>(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn minimize_measure_8(rows: &[[u8; 8]]) -> Vec<[u8; 8]> {
    let count = unsafe {
        assp_minimize_measure_8(
            rows.as_ptr().cast::<u8>(),
            rows.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![[0; 8]; count];
    if count != 0 {
        unsafe {
            assp_minimize_measure_8(
                rows.as_ptr().cast::<u8>(),
                rows.len(),
                out.as_mut_ptr().cast::<u8>(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn minimize_chart_4(data: &[u8]) -> Option<Vec<u8>> {
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let count = unsafe {
        assp_minimize_chart_4(
            data.as_ptr(),
            data.len(),
            std::ptr::null_mut(),
            0,
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    let count = unsafe {
        assp_minimize_chart_4(
            data.as_ptr(),
            data.len(),
            out.as_mut_ptr(),
            out.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(out)
}

#[must_use]
pub fn minimize_chart_8(data: &[u8]) -> Option<Vec<u8>> {
    let mut scratch = vec![[0; 8]; data.len() / 8 + 1];
    let count = unsafe {
        assp_minimize_chart_8(
            data.as_ptr(),
            data.len(),
            std::ptr::null_mut(),
            0,
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    let count = unsafe {
        assp_minimize_chart_8(
            data.as_ptr(),
            data.len(),
            out.as_mut_ptr(),
            out.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(out)
}

#[must_use]
pub fn measure_equally_spaced_4(data: &[u8]) -> Option<Vec<bool>> {
    let minimized = minimize_chart_4(data)?;
    Some(measure_equally_spaced_minimized_4(&minimized))
}

#[must_use]
pub fn measure_equally_spaced_8(data: &[u8]) -> Option<Vec<bool>> {
    let minimized = minimize_chart_8(data)?;
    Some(measure_equally_spaced_minimized_8(&minimized))
}

#[must_use]
pub fn count_anchors_4(data: &[u8]) -> Option<[u32; 4]> {
    let minimized = minimize_chart_4(data)?;
    count_anchors_minimized_4(&minimized)
}

#[must_use]
pub fn count_facing_steps_4(data: &[u8], mono_threshold: usize) -> Option<[u32; 2]> {
    let minimized = minimize_chart_4(data)?;
    count_facing_steps_minimized_4(&minimized, mono_threshold)
}

#[must_use]
pub fn count_basic_patterns_4(data: &[u8]) -> Option<BasicPatterns> {
    let minimized = minimize_chart_4(data)?;
    count_basic_patterns_minimized_4(&minimized)
}

#[must_use]
pub fn count_default_patterns_4(data: &[u8]) -> Option<[u32; PATTERN_COUNT]> {
    let minimized = minimize_chart_4(data)?;
    count_default_patterns_minimized_4(&minimized)
}

#[must_use]
pub fn sha1_short_hex2(first: &[u8], second: &[u8]) -> Option<[u8; 16]> {
    let mut out = [0; 16];
    let ok = unsafe {
        assp_sha1_short_hex2(
            first.as_ptr(),
            first.len(),
            second.as_ptr(),
            second.len(),
            out.as_mut_ptr(),
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn chart_hash_pair(chart_data: &[u8], normalized_bpms: &[u8]) -> Option<([u8; 16], [u8; 16])> {
    let mut out = [0; 32];
    let ok = unsafe {
        assp_chart_hash_pair(
            chart_data.as_ptr(),
            chart_data.len(),
            normalized_bpms.as_ptr(),
            normalized_bpms.len(),
            out.as_mut_ptr(),
        )
    };
    if ok == 0 {
        return None;
    }

    let mut hash = [0; 16];
    let mut neutral = [0; 16];
    hash.copy_from_slice(&out[..16]);
    neutral.copy_from_slice(&out[16..]);
    Some((hash, neutral))
}

#[must_use]
pub fn md5_hex(data: &[u8]) -> Option<[u8; 32]> {
    let mut out = [0; 32];
    let ok = unsafe { assp_md5_hex(data.as_ptr(), data.len(), out.as_mut_ptr()) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn stream_counts_from_densities(densities: &[u32]) -> Option<StreamCounts> {
    let mut out = StreamCounts::default();
    let ok =
        unsafe { assp_stream_counts_from_densities(densities.as_ptr(), densities.len(), &mut out) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn stream_percentages_centi(
    counts: &StreamCounts,
    measure_count: usize,
) -> Option<(i64, i64, i64)> {
    let mut stream_percent = 0;
    let mut adjusted_stream_percent = 0;
    let mut break_percent = 0;
    let ok = unsafe {
        assp_stream_percentages_centi(
            counts,
            measure_count,
            &mut stream_percent,
            &mut adjusted_stream_percent,
            &mut break_percent,
        )
    };
    (ok != 0).then_some((stream_percent, adjusted_stream_percent, break_percent))
}

#[must_use]
pub fn stream_segments_from_densities(densities: &[u32]) -> Vec<StreamSegment> {
    let count = unsafe {
        assp_stream_segments_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamSegment::default(); count];
    if count != 0 {
        unsafe {
            assp_stream_segments_from_densities(
                densities.as_ptr(),
                densities.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn stream_tokens_from_densities(densities: &[u32]) -> Vec<StreamToken> {
    let count = unsafe {
        assp_stream_tokens_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamToken::default(); count];
    if count != 0 {
        unsafe {
            assp_stream_tokens_from_densities(
                densities.as_ptr(),
                densities.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn format_stream_tokens(tokens: &[StreamToken], mode: u32) -> Vec<u8> {
    let count = unsafe {
        assp_format_stream_tokens(tokens.as_ptr(), tokens.len(), mode, std::ptr::null_mut(), 0)
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_format_stream_tokens(
                tokens.as_ptr(),
                tokens.len(),
                mode,
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn format_stream_segments(segments: &[StreamSegment], level: u32) -> Vec<u8> {
    let count = unsafe {
        assp_format_stream_segments(
            segments.as_ptr(),
            segments.len(),
            level,
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_format_stream_segments(
                segments.as_ptr(),
                segments.len(),
                level,
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn count_note_stats_4(data: &[u8]) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let ok = unsafe { assp_count_note_stats_4(data.as_ptr(), data.len(), &mut stats) };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_note_stats_8(data: &[u8]) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let ok = unsafe { assp_count_note_stats_8(data.as_ptr(), data.len(), &mut stats) };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_note_stats_minimized_4(data: &[u8]) -> Option<NoteStats> {
    let minimized = minimize_chart_4(data)?;
    count_note_stats_4(&minimized)
}

#[must_use]
pub fn count_note_stats_minimized_8(data: &[u8]) -> Option<NoteStats> {
    let minimized = minimize_chart_8(data)?;
    count_note_stats_8(&minimized)
}

#[must_use]
pub fn count_mines_nonfake_4(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<u64> {
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let count = unsafe {
        assp_count_mines_nonfake_4(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(count as u64)
}

#[must_use]
pub fn count_mines_nonfake_8(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<u64> {
    let mut scratch = vec![[0; 8]; data.len() / 8 + 1];
    let count = unsafe {
        assp_count_mines_nonfake_8(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(count as u64)
}

#[must_use]
pub fn count_timing_fakes_4(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<u64> {
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let count = unsafe {
        assp_count_timing_fakes_4(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(count as u64)
}

#[must_use]
pub fn count_timing_fakes_8(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<u64> {
    let mut scratch = vec![[0; 8]; data.len() / 8 + 1];
    let count = unsafe {
        assp_count_timing_fakes_8(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(count as u64)
}

#[must_use]
pub fn count_timing_note_stats_4(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let mut scratch = vec![0u8; data.len().saturating_mul(8).max(1024)];
    let ok = unsafe {
        assp_count_timing_note_stats_4(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            &mut stats,
            scratch.as_mut_ptr(),
            scratch.len(),
        )
    };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_timing_note_stats_8(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let mut scratch = vec![0u8; data.len().saturating_mul(8).max(1024)];
    let ok = unsafe {
        assp_count_timing_note_stats_8(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            &mut stats,
            scratch.as_mut_ptr(),
            scratch.len(),
        )
    };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_timing_note_stats_no_holds_4(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let ok = unsafe {
        assp_count_timing_note_stats_no_holds_4(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            &mut stats,
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_timing_note_stats_no_holds_8(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let mut scratch = vec![[0; 8]; data.len() / 8 + 1];
    let ok = unsafe {
        assp_count_timing_note_stats_no_holds_8(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            &mut stats,
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (ok != 0).then_some(stats)
}

#[cfg(test)]
mod tests {
    use super::{
        NoteStats, StepParityActionCosts4, StepParityActionFlags4, StepParityBasicCosts4,
        StepParityBracketTapCosts4, StepParityDistanceCosts4, StepParityElapsedCosts4,
        StepParityOrientationCosts4, StepParityPreparedRows4, StepParityRowCostCtx4,
        StepParityState4, StepParitySwitchCosts4, StepParityWorkspace4, TechCounts,
    };

    #[test]
    fn note_stats_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<NoteStats>(), 120);
        assert_eq!(std::mem::align_of::<NoteStats>(), 8);
    }

    #[test]
    fn tech_counts_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<TechCounts>(), 32);
        assert_eq!(std::mem::align_of::<TechCounts>(), 4);
    }

    #[test]
    fn step_parity_state4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityState4>(), 12);
        assert_eq!(std::mem::align_of::<StepParityState4>(), 1);
    }

    #[test]
    fn step_parity_action_flags4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityActionFlags4>(), 7);
        assert_eq!(std::mem::align_of::<StepParityActionFlags4>(), 1);
    }

    #[test]
    fn step_parity_basic_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityBasicCosts4>(), 20);
        assert_eq!(std::mem::align_of::<StepParityBasicCosts4>(), 4);
    }

    #[test]
    fn step_parity_elapsed_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityElapsedCosts4>(), 12);
        assert_eq!(std::mem::align_of::<StepParityElapsedCosts4>(), 4);
    }

    #[test]
    fn step_parity_switch_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParitySwitchCosts4>(), 12);
        assert_eq!(std::mem::align_of::<StepParitySwitchCosts4>(), 4);
    }

    #[test]
    fn step_parity_bracket_tap_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityBracketTapCosts4>(), 12);
        assert_eq!(std::mem::align_of::<StepParityBracketTapCosts4>(), 4);
    }

    #[test]
    fn step_parity_distance_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityDistanceCosts4>(), 12);
        assert_eq!(std::mem::align_of::<StepParityDistanceCosts4>(), 4);
    }

    #[test]
    fn step_parity_orientation_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityOrientationCosts4>(), 16);
        assert_eq!(std::mem::align_of::<StepParityOrientationCosts4>(), 4);
    }

    #[test]
    fn step_parity_action_costs4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityActionCosts4>(), 60);
        assert_eq!(std::mem::align_of::<StepParityActionCosts4>(), 4);
    }

    #[test]
    fn step_parity_row_cost_ctx4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityRowCostCtx4>(), 32);
        assert_eq!(std::mem::align_of::<StepParityRowCostCtx4>(), 8);
    }

    #[test]
    fn step_parity_prepared_rows4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityPreparedRows4>(), 72);
        assert_eq!(std::mem::align_of::<StepParityPreparedRows4>(), 8);
    }

    #[test]
    fn step_parity_workspace4_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<StepParityWorkspace4>(), 104);
        assert_eq!(std::mem::align_of::<StepParityWorkspace4>(), 8);
    }

    #[test]
    fn chart_ref_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ChartRef>(), 24);
        assert_eq!(std::mem::align_of::<super::ChartRef>(), 8);
    }

    #[test]
    fn byte_slice_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ByteSlice>(), 16);
        assert_eq!(std::mem::align_of::<super::ByteSlice>(), 8);
    }

    #[test]
    fn timing_tags_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::TimingTags>(), 112);
        assert_eq!(std::mem::align_of::<super::TimingTags>(), 8);
    }

    #[test]
    fn bpm_segment_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::BpmSegment>(), 16);
        assert_eq!(std::mem::align_of::<super::BpmSegment>(), 8);
    }

    #[test]
    fn chart_info_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ChartInfo>(), 104);
        assert_eq!(std::mem::align_of::<super::ChartInfo>(), 8);
    }

    #[test]
    fn stream_counts_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamCounts>(), 48);
        assert_eq!(std::mem::align_of::<super::StreamCounts>(), 8);
    }

    #[test]
    fn stream_segment_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamSegment>(), 24);
        assert_eq!(std::mem::align_of::<super::StreamSegment>(), 8);
    }

    #[test]
    fn stream_token_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamToken>(), 16);
        assert_eq!(std::mem::align_of::<super::StreamToken>(), 8);
    }

    #[test]
    fn basic_patterns_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::BasicPatterns>(), 32);
        assert_eq!(std::mem::align_of::<super::BasicPatterns>(), 4);
    }
}
