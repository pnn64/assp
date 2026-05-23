use assp::{
    StepParityActionCosts4, StepParityActionFlags4, StepParityBasicCosts4,
    StepParityBracketTapCosts4, StepParityDistanceCosts4, StepParityElapsedCosts4,
    StepParityOrientationCosts4, StepParityState4, StepParityState8, StepParitySwitchCosts4,
    TechCounts, calculate_step_tech_counts_from_placements_4,
    calculate_step_tech_counts_from_placements_8, count_step_tech_brackets_minimized_4,
    count_step_tech_brackets_minimized_8, find_bpms_for_chart, find_chart_by_index,
    find_global_tag, minimize_chart_4, parse_offset_us, parse_tech_notation,
    step_parity_action_cost_4, step_parity_action_cost_8, step_parity_action_flags_4,
    step_parity_action_flags_8, step_parity_basic_action_costs_4, step_parity_basic_action_costs_8,
    step_parity_bpm_row_times_4, step_parity_bpm_row_times_8,
    step_parity_bracket_tap_action_costs_4, step_parity_bracket_tap_action_costs_8,
    step_parity_count_hold_rows_4, step_parity_count_hold_rows_8,
    step_parity_count_prepared_rows_4, step_parity_count_prepared_rows_8,
    step_parity_distance_action_costs_4, step_parity_distance_action_costs_8,
    step_parity_elapsed_action_costs_4, step_parity_elapsed_action_costs_8,
    step_parity_hold_head_ends_4, step_parity_hold_head_ends_8,
    step_parity_orientation_action_costs_4, step_parity_orientation_action_costs_8,
    step_parity_permutations_4, step_parity_permutations_8, step_parity_place_rows_4,
    step_parity_place_rows_8, step_parity_prepare_hold_rows_4, step_parity_prepare_hold_rows_8,
    step_parity_prepare_tap_rows_4, step_parity_result_state_holds_4,
    step_parity_result_state_holds_8, step_parity_result_state_no_holds_4,
    step_parity_result_state_no_holds_8, step_parity_row_best_candidates_4,
    step_parity_row_best_candidates_8, step_parity_row_key_candidates_4,
    step_parity_row_key_candidates_8, step_parity_row_transitions_4, step_parity_row_transitions_8,
    step_parity_switch_action_costs_4, step_parity_switch_action_costs_8,
};
use std::collections::HashSet;

fn parse(credit: &str, description: &str) -> String {
    String::from_utf8(parse_tech_notation(credit.as_bytes(), description.as_bytes()).unwrap())
        .unwrap()
}

fn assert_matches_rssp(credit: &str, description: &str) {
    assert_eq!(
        parse(credit, description),
        rssp_core::tech::parse_tech_notation(credit, description)
    );
}

fn assert_only_brackets(counts: TechCounts, brackets: u32) {
    assert_eq!(
        counts,
        TechCounts {
            brackets,
            ..TechCounts::default()
        }
    );
}

fn assert_brackets_match_rssp(data: &[u8], lanes: usize, counts: TechCounts) {
    let expected = rssp_core::step_parity::analyze_lanes(data, &[(0.0, 120.0)], 0.0, lanes);
    assert_eq!(counts.brackets, expected.brackets);
    assert_only_brackets(counts, expected.brackets);
}

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn step_counts_subset(counts: rssp_core::step_parity::TechCounts) -> TechCounts {
    TechCounts {
        crossovers: counts.crossovers,
        footswitches: counts.footswitches,
        up_footswitches: counts.up_footswitches,
        down_footswitches: counts.down_footswitches,
        sideswitches: counts.sideswitches,
        jacks: counts.jacks,
        brackets: counts.brackets,
        doublesteps: counts.doublesteps,
    }
}

fn bpm_row_times(beats: &[f32], bpms: &[(f64, f64)], offset: f64) -> (Vec<f32>, Vec<i32>) {
    let seconds: Vec<f32> = if bpms.len() == 1 && bpms[0].0 == 0.0 {
        let start = (-offset) as f32;
        let bps = bpms[0].1 as f32 / 60.0;
        beats.iter().map(|&beat| start + beat / bps).collect()
    } else {
        beats
            .iter()
            .map(|&beat| {
                (rssp_core::bpm::get_elapsed_time(f64::from(beat), bpms, &[], &[], &[]) - offset)
                    as f32
            })
            .collect()
    };
    let mut row_ms = Vec::with_capacity(seconds.len());
    for (idx, &second) in seconds.iter().enumerate() {
        if idx == 0 {
            row_ms.push((f64::from(second) * 1000.0).floor() as i32);
        } else {
            let elapsed = f64::from(second - seconds[idx - 1]);
            row_ms.push(row_ms[idx - 1] + (elapsed * 1000.0).floor() as i32);
        }
    }
    (seconds, row_ms)
}

fn timing_row_times(beats: &[f32], timing: &rssp_core::timing::TimingData) -> (Vec<f32>, Vec<i32>) {
    let seconds: Vec<f32> = beats
        .iter()
        .map(|&beat| rssp_core::timing::get_time_for_beat(timing, f64::from(beat)) as f32)
        .collect();
    let mut row_ms = Vec::with_capacity(seconds.len());
    for (idx, &second) in seconds.iter().enumerate() {
        if idx == 0 {
            row_ms.push((f64::from(second) * 1000.0).floor() as i32);
        } else {
            let elapsed = f64::from(second - seconds[idx - 1]);
            row_ms.push(row_ms[idx - 1] + (elapsed * 1000.0).floor() as i32);
        }
    }
    (seconds, row_ms)
}

fn trim_ws(mut bytes: &[u8]) -> &[u8] {
    while bytes.first().is_some_and(u8::is_ascii_whitespace) {
        bytes = &bytes[1..];
    }
    while bytes.last().is_some_and(u8::is_ascii_whitespace) {
        bytes = &bytes[..bytes.len() - 1];
    }
    bytes
}

fn nonzero_row_beats_4(minimized: &[u8]) -> Vec<f32> {
    nonzero_row_beats(minimized, 4)
}

fn nonzero_row_beats_8(minimized: &[u8]) -> Vec<f32> {
    nonzero_row_beats(minimized, 8)
}

fn nonzero_row_beats(minimized: &[u8], lanes: usize) -> Vec<f32> {
    let mut beats = Vec::new();
    for (measure_idx, measure) in minimized.split(|&b| b == b',').enumerate() {
        let lines: Vec<_> = measure
            .split(|&b| b == b'\n')
            .map(trim_ws)
            .filter(|line| line.len() >= lanes)
            .collect();
        if lines.is_empty() {
            continue;
        }

        let start = measure_idx as f32 * 4.0;
        let step = 4.0 / lines.len() as f32;
        for (row_idx, line) in lines.iter().enumerate() {
            if line[..lanes].iter().all(|&b| b == b'0') {
                continue;
            }
            let beat = (row_idx as f32).mul_add(step, start);
            let row = rssp_core::timing::beat_to_note_row(f64::from(beat));
            beats.push(rssp_core::timing::note_row_to_beat(row) as f32);
        }
    }
    beats
}

fn assert_bpm_only_fixture_step_parity(data: &[u8], chart_idx: usize) {
    let chart = find_chart_by_index(data, chart_idx).unwrap();
    let notes = slice_from(data, chart.note_data, chart.note_data_len);
    let asm_minimized = minimize_chart_4(notes).unwrap();
    let (rust_minimized, _, _, _all_row_beats, _) =
        rssp_core::stats::minimize_chart_count_rows(notes, 4);
    assert_eq!(asm_minimized, rust_minimized);
    let row_beats = nonzero_row_beats_4(&asm_minimized);

    let bpms = find_bpms_for_chart(data, chart_idx).unwrap();
    let bpms_bytes = slice_from(data, bpms.data, bpms.len);
    let mut bpms = rssp_core::bpm::parse_bpm_map(std::str::from_utf8(bpms_bytes).unwrap());
    if bpms.is_empty() {
        bpms.push((0.0, 60.0));
    }
    let offset_us = find_global_tag(data, b"OFFSET")
        .map(|slice| parse_offset_us(slice_from(data, slice.data, slice.len)))
        .unwrap_or(0);
    let offset = offset_us as f64 / 1_000_000.0;
    let (row_seconds, row_ms) = bpm_row_times(&row_beats, &bpms, offset);
    let asm_bpms = assp::parse_bpm_map(bpms_bytes).unwrap();
    let (asm_row_seconds, asm_row_ms, asm_row_beats) =
        step_parity_bpm_row_times_4(&asm_minimized, &asm_bpms, offset_us as i64).unwrap();
    assert_eq!(asm_row_beats, row_beats, "row beats for chart {chart_idx}");
    assert_eq!(asm_row_ms, row_ms, "row milliseconds for chart {chart_idx}");
    assert_eq!(asm_row_seconds.len(), row_seconds.len());
    for (actual, expected) in asm_row_seconds.iter().zip(row_seconds.iter()) {
        assert!((actual - expected).abs() <= 0.00001);
    }

    let rows = step_parity_prepare_hold_rows_4(
        &asm_minimized,
        &asm_row_seconds,
        &asm_row_ms,
        &asm_row_beats,
    )
    .unwrap();
    let actual_placements = step_parity_place_rows_4(
        &rows.note_counts,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        4096,
    )
    .unwrap();
    let expected_placements = expected_place_rows(
        &rows.note_counts,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
    );
    assert_eq!(
        actual_placements, expected_placements,
        "local placement mirror mismatch for chart {chart_idx}"
    );

    let actual = step_parity_count_prepared_rows_4(
        &rows.note_counts,
        &rows.tech_masks,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        &rows.row_ms,
        4096,
    )
    .unwrap();
    let bpms_string = std::str::from_utf8(bpms_bytes).unwrap();
    let timing = rssp_core::timing::timing_data_from_chart_data(
        offset,
        0.0,
        None,
        bpms_string,
        None,
        "",
        None,
        "",
        None,
        "",
        None,
        "",
        None,
        "",
        None,
        "",
        rssp_core::timing::TimingFormat::Sm,
        true,
    );
    let expected = expected_timing_rows_counts(notes, &timing);

    assert_eq!(actual, step_counts_subset(expected), "chart {chart_idx}");
}

#[test]
fn computes_double_bpm_row_times_for_right_pad_rows() {
    let data = b"00001000\n00000000\n10000000\n,\n00000001\n;\n";
    let row_beats = nonzero_row_beats_8(data);
    let bpms = [(0.0, 120.0)];
    let (row_seconds, row_ms) = bpm_row_times(&row_beats, &bpms, 0.0);
    let asm_bpms = assp::parse_bpm_map(b"0.000=120.000").unwrap();
    let (asm_row_seconds, asm_row_ms, asm_row_beats) =
        step_parity_bpm_row_times_8(data, &asm_bpms, 0).unwrap();

    assert_eq!(asm_row_beats, row_beats);
    assert_eq!(asm_row_ms, row_ms);
    assert_eq!(asm_row_seconds.len(), row_seconds.len());
    for (actual, expected) in asm_row_seconds.iter().zip(row_seconds.iter()) {
        assert!((actual - expected).abs() <= 0.00001);
    }
}

fn assert_timing_step_parity_counts(
    minimized: &[u8],
    timing: &rssp_core::timing::TimingData,
    label: &str,
) {
    let row_beats = nonzero_row_beats_4(minimized);
    let (row_seconds, row_ms) = timing_row_times(&row_beats, timing);

    let rows =
        step_parity_prepare_hold_rows_4(minimized, &row_seconds, &row_ms, &row_beats).unwrap();
    let actual_placements = step_parity_place_rows_4(
        &rows.note_counts,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        4096,
    )
    .unwrap();
    let expected_placements = expected_place_rows(
        &rows.note_counts,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
    );
    assert_eq!(
        actual_placements, expected_placements,
        "local placement mirror mismatch for {label}"
    );

    let actual = placement_counts(
        &rows.tech_masks,
        &rows.note_counts,
        &rows.row_ms,
        &actual_placements,
    );
    let expected = rssp_core::step_parity::analyze_timing_lanes(minimized, timing, 4);

    assert_eq!(actual, step_counts_subset(expected), "{label}");
}

fn placement_counts(
    tech_masks: &[u8],
    note_counts: &[u8],
    row_ms: &[i32],
    placements: &[[u8; 4]],
) -> TechCounts {
    let placements: Vec<u8> = placements.iter().flatten().copied().collect();
    calculate_step_tech_counts_from_placements_4(tech_masks, note_counts, row_ms, &placements)
        .unwrap()
}

fn placement_counts_8(
    tech_masks: &[u8],
    note_counts: &[u8],
    row_ms: &[i32],
    placements: &[[u8; 8]],
) -> TechCounts {
    let placements: Vec<u8> = placements.iter().flatten().copied().collect();
    calculate_step_tech_counts_from_placements_8(tech_masks, note_counts, row_ms, &placements)
        .unwrap()
}

fn expected_timing_rows_counts(
    notes: &[u8],
    timing: &rssp_core::timing::TimingData,
) -> rssp_core::step_parity::TechCounts {
    let (_, stats, _, rows, row_to_beat, _) = rssp_core::stats::minimize_rows_typed::<4>(notes);
    let has_holds = stats.holds != 0 || stats.rolls != 0;
    let mut scratch = rssp_core::step_parity::timing_rows_scratch::<4>().unwrap();
    rssp_core::step_parity::analyze_timing_rows_known_holds(
        &rows,
        &row_to_beat,
        timing,
        has_holds,
        &mut scratch,
    )
}

fn expected_permutations_4(mask: u8) -> Vec<[u8; 4]> {
    fn rec(mask: u8, col: usize, used: u8, placement: &mut [u8; 4], out: &mut Vec<[u8; 4]>) {
        if col == 4 {
            if valid_placement(placement) {
                out.push(*placement);
            }
            return;
        }

        if mask & (1 << col) == 0 {
            placement[col] = 0;
            rec(mask, col + 1, used, placement, out);
            return;
        }

        for foot in 1..=4 {
            let foot_mask = 1 << (foot - 1);
            if used & foot_mask != 0 {
                continue;
            }
            placement[col] = foot;
            rec(mask, col + 1, used | foot_mask, placement, out);
            placement[col] = 0;
        }
    }

    let mut out = Vec::new();
    rec(mask & 0x0f, 0, 0, &mut [0; 4], &mut out);
    out
}

fn valid_placement(placement: &[u8; 4]) -> bool {
    let mut pos = [u8::MAX; 5];
    for (col, &foot) in placement.iter().enumerate() {
        if foot != 0 {
            pos[foot as usize] = col as u8;
        }
    }

    if (pos[1] == u8::MAX && pos[2] != u8::MAX) || (pos[3] == u8::MAX && pos[4] != u8::MAX) {
        return false;
    }
    if pos[1] != u8::MAX && pos[2] != u8::MAX && pos[1] + pos[2] == 3 {
        return false;
    }
    if pos[3] != u8::MAX && pos[4] != u8::MAX && pos[3] + pos[4] == 3 {
        return false;
    }
    true
}

fn expected_permutations_8(mask: u8) -> Vec<[u8; 8]> {
    fn rec(mask: u8, col: usize, used: u8, placement: &mut [u8; 8], out: &mut Vec<[u8; 8]>) {
        if col == 8 {
            if valid_placement_8(placement) {
                out.push(*placement);
            }
            return;
        }

        if mask & (1 << col) == 0 {
            placement[col] = 0;
            rec(mask, col + 1, used, placement, out);
            return;
        }

        for foot in 1..=4 {
            let foot_mask = 1 << (foot - 1);
            if used & foot_mask != 0 {
                continue;
            }
            placement[col] = foot;
            rec(mask, col + 1, used | foot_mask, placement, out);
            placement[col] = 0;
        }
    }

    let mut out = Vec::new();
    rec(mask, 0, 0, &mut [0; 8], &mut out);
    out
}

fn expected_row_permutations_8(note_mask: u8, hold_mask: u8) -> Vec<[u8; 8]> {
    let union = expected_permutations_8(note_mask | hold_mask);
    if !union.is_empty() {
        return union;
    }

    let note = expected_permutations_8(note_mask);
    if note.is_empty() { vec![[0; 8]] } else { note }
}

fn valid_placement_8(placement: &[u8; 8]) -> bool {
    let mut pos = [u8::MAX; 5];
    for (col, &foot) in placement.iter().enumerate() {
        if foot != 0 {
            pos[foot as usize] = col as u8;
        }
    }

    if (pos[1] == u8::MAX && pos[2] != u8::MAX) || (pos[3] == u8::MAX && pos[4] != u8::MAX) {
        return false;
    }
    bracket_ok_8(pos[1], pos[2]) && bracket_ok_8(pos[3], pos[4])
}

fn bracket_ok_8(a: u8, b: u8) -> bool {
    if a == u8::MAX || b == u8::MAX {
        return true;
    }
    const POINTS: [(i32, i32); 8] = [
        (0, 1),
        (1, 0),
        (1, 2),
        (2, 1),
        (3, 1),
        (4, 0),
        (4, 2),
        (5, 1),
    ];
    let (ax, ay) = POINTS[a as usize];
    let (bx, by) = POINTS[b as usize];
    let dx = ax - bx;
    let dy = ay - by;
    dx * dx + dy * dy <= 2
}

fn expected_result_state(
    initial: StepParityState4,
    placement: [u8; 4],
    active_mask: u8,
    hold_mask: u8,
) -> (StepParityState4, [i8; 5], u32) {
    let mut combined = [0; 4];
    let mut hit = [-1; 5];
    let mut moved_mask = 0u8;
    let mut holding_mask = 0u8;

    for col in 0..4 {
        if active_mask & (1 << col) == 0 {
            continue;
        }
        let foot = placement[col];
        if !(1..=4).contains(&foot) {
            continue;
        }
        combined[col] = foot;
        hit[foot as usize] = col as i8;
        let foot_mask = 1 << (foot - 1);
        let bit = 1 << col;
        if hold_mask & bit != 0 {
            holding_mask |= foot_mask;
        }
        if hold_mask & bit == 0 || initial.combined_columns[col] != foot {
            moved_mask |= foot_mask;
        }
    }

    let moved_left = moved_mask & 0b0011 != 0;
    let moved_right = moved_mask & 0b1100 != 0;
    let mut where_feet_are = [-1; 5];
    let mut occupied_mask = 0u8;
    let mut key = 0u32;

    for col in 0..4 {
        let mut foot = combined[col];
        if foot == 0 {
            let prev = initial.combined_columns[col];
            foot = match prev {
                1 | 3 if moved_mask & (1 << (prev - 1)) == 0 => prev,
                2 if !moved_left => prev,
                4 if !moved_right => prev,
                _ => 0,
            };
        }
        combined[col] = foot;
        key |= u32::from(foot) << (col * 3);
        if foot != 0 {
            where_feet_are[foot as usize] = col as i8;
            occupied_mask |= 1 << col;
        }
    }

    key |= u32::from(moved_mask) << 24;
    key |= u32::from(holding_mask) << 28;
    (
        StepParityState4 {
            combined_columns: combined,
            where_feet_are,
            occupied_mask,
            moved_mask,
            holding_mask,
        },
        hit,
        key,
    )
}

fn expected_result_state_8(
    initial: StepParityState8,
    placement: [u8; 8],
    active_mask: u8,
    hold_mask: u8,
) -> (StepParityState8, [i8; 5], u32) {
    let mut combined = [0; 8];
    let mut hit = [-1; 5];
    let mut moved_mask = 0u8;
    let mut holding_mask = 0u8;

    for col in 0..8 {
        if active_mask & (1 << col) == 0 {
            continue;
        }
        let foot = placement[col];
        if !(1..=4).contains(&foot) {
            continue;
        }
        combined[col] = foot;
        hit[foot as usize] = col as i8;
        let foot_mask = 1 << (foot - 1);
        let bit = 1 << col;
        if hold_mask & bit != 0 {
            holding_mask |= foot_mask;
        }
        if hold_mask & bit == 0 || initial.combined_columns[col] != foot {
            moved_mask |= foot_mask;
        }
    }

    let moved_left = moved_mask & 0b0011 != 0;
    let moved_right = moved_mask & 0b1100 != 0;
    let mut where_feet_are = [-1; 5];
    let mut occupied_mask = 0u8;
    let mut key = 0u32;

    for col in 0..8 {
        let mut foot = combined[col];
        if foot == 0 {
            let prev = initial.combined_columns[col];
            foot = match prev {
                1 | 3 if moved_mask & (1 << (prev - 1)) == 0 => prev,
                2 if !moved_left => prev,
                4 if !moved_right => prev,
                _ => 0,
            };
        }
        combined[col] = foot;
        key |= u32::from(foot) << (col * 3);
        if foot != 0 {
            where_feet_are[foot as usize] = col as i8;
            occupied_mask |= 1 << col;
        }
    }

    key |= u32::from(moved_mask) << 24;
    key |= u32::from(holding_mask) << 28;
    (
        StepParityState8 {
            combined_columns: combined,
            where_feet_are,
            occupied_mask,
            moved_mask,
            holding_mask,
        },
        hit,
        key,
    )
}

fn expected_action_flags(
    initial: StepParityState4,
    result: StepParityState4,
    hit: [i8; 5],
) -> StepParityActionFlags4 {
    let left_moved_not_holding = initial.moved_mask & !initial.holding_mask & 0b0011 != 0;
    let right_moved_not_holding = initial.moved_mask & !initial.holding_mask & 0b1100 != 0;
    let moved_left = result.moved_mask & 0b0011 != 0;
    let moved_right = result.moved_mask & 0b1100 != 0;
    let did_jump = left_moved_not_holding && right_moved_not_holding;

    let did_jack = |heel: u8, toe: u8, moved: bool, moved_not_holding: bool| {
        if did_jump || !moved || !moved_not_holding {
            return false;
        }
        [heel, toe].into_iter().any(|foot| {
            let col = hit[foot as usize];
            col >= 0
                && initial.combined_columns[col as usize] == foot
                && result.holding_mask & (1 << (foot - 1)) == 0
        })
    };

    StepParityActionFlags4 {
        moved_left: u8::from(moved_left),
        moved_right: u8::from(moved_right),
        did_jump: u8::from(did_jump),
        jacked_left: u8::from(did_jack(1, 2, moved_left, left_moved_not_holding)),
        jacked_right: u8::from(did_jack(3, 4, moved_right, right_moved_not_holding)),
        left_moved_not_holding: u8::from(left_moved_not_holding),
        right_moved_not_holding: u8::from(right_moved_not_holding),
    }
}

fn expected_action_flags_8(
    initial: StepParityState8,
    result: StepParityState8,
    hit: [i8; 5],
) -> StepParityActionFlags4 {
    let left_moved_not_holding = initial.moved_mask & !initial.holding_mask & 0b0011 != 0;
    let right_moved_not_holding = initial.moved_mask & !initial.holding_mask & 0b1100 != 0;
    let moved_left = result.moved_mask & 0b0011 != 0;
    let moved_right = result.moved_mask & 0b1100 != 0;
    let did_jump = left_moved_not_holding && right_moved_not_holding;

    let did_jack = |heel: u8, toe: u8, moved: bool, moved_not_holding: bool| {
        if did_jump || !moved || !moved_not_holding {
            return false;
        }
        [heel, toe].into_iter().any(|foot| {
            let col = hit[foot as usize];
            col >= 0
                && initial.combined_columns[col as usize] == foot
                && result.holding_mask & (1 << (foot - 1)) == 0
        })
    };

    StepParityActionFlags4 {
        moved_left: u8::from(moved_left),
        moved_right: u8::from(moved_right),
        did_jump: u8::from(did_jump),
        jacked_left: u8::from(did_jack(1, 2, moved_left, left_moved_not_holding)),
        jacked_right: u8::from(did_jack(3, 4, moved_right, right_moved_not_holding)),
        left_moved_not_holding: u8::from(left_moved_not_holding),
        right_moved_not_holding: u8::from(right_moved_not_holding),
    }
}

fn expected_basic_costs(
    result: StepParityState4,
    flags: StepParityActionFlags4,
    multi_active: bool,
    mine_mask: u8,
    prev_row_has_live_hold: bool,
) -> StepParityBasicCosts4 {
    let mine = if mine_mask & result.occupied_mask != 0 {
        10000.0
    } else {
        0.0
    };

    let bracket_jack = if multi_active
        && result.holding_mask == 0
        && flags.did_jump == 0
        && flags.moved_left != flags.moved_right
    {
        let left = flags.jacked_left != 0 && result.moved_mask & 0b0011 == 0b0011;
        let right = flags.jacked_right != 0 && result.moved_mask & 0b1100 == 0b1100;
        20.0 * f32::from(left as u8 + right as u8)
    } else {
        0.0
    };

    let did_double_step =
        (flags.moved_left != 0 && flags.jacked_left == 0 && flags.left_moved_not_holding != 0)
            || (flags.moved_right != 0
                && flags.jacked_right == 0
                && flags.right_moved_not_holding != 0);
    let doublestep = if flags.moved_left != flags.moved_right
        && flags.did_jump == 0
        && result.holding_mask == 0
        && did_double_step
        && !prev_row_has_live_hold
    {
        850.0
    } else {
        0.0
    };

    let missed_footswitch = if mine_mask != 0 && (flags.jacked_left != 0 || flags.jacked_right != 0)
    {
        500.0
    } else {
        0.0
    };

    StepParityBasicCosts4 {
        mine,
        bracket_jack,
        doublestep,
        missed_footswitch,
        total: mine + bracket_jack + doublestep + missed_footswitch,
    }
}

fn expected_basic_costs_8(
    result: StepParityState8,
    flags: StepParityActionFlags4,
    multi_active: bool,
    mine_mask: u8,
    prev_row_has_live_hold: bool,
) -> StepParityBasicCosts4 {
    let mine = if mine_mask & result.occupied_mask != 0 {
        10000.0
    } else {
        0.0
    };

    let bracket_jack = if multi_active
        && result.holding_mask == 0
        && flags.did_jump == 0
        && flags.moved_left != flags.moved_right
    {
        let left = flags.jacked_left != 0 && result.moved_mask & 0b0011 == 0b0011;
        let right = flags.jacked_right != 0 && result.moved_mask & 0b1100 == 0b1100;
        20.0 * f32::from(left as u8 + right as u8)
    } else {
        0.0
    };

    let did_double_step =
        (flags.moved_left != 0 && flags.jacked_left == 0 && flags.left_moved_not_holding != 0)
            || (flags.moved_right != 0
                && flags.jacked_right == 0
                && flags.right_moved_not_holding != 0);
    let doublestep = if flags.moved_left != flags.moved_right
        && flags.did_jump == 0
        && result.holding_mask == 0
        && did_double_step
        && !prev_row_has_live_hold
    {
        850.0
    } else {
        0.0
    };

    let missed_footswitch = if mine_mask != 0 && (flags.jacked_left != 0 || flags.jacked_right != 0)
    {
        500.0
    } else {
        0.0
    };

    StepParityBasicCosts4 {
        mine,
        bracket_jack,
        doublestep,
        missed_footswitch,
        total: mine + bracket_jack + doublestep + missed_footswitch,
    }
}

fn expected_elapsed_costs(
    flags: StepParityActionFlags4,
    note_count: u8,
    elapsed: f32,
) -> StepParityElapsedCosts4 {
    let moved_left = flags.moved_left != 0;
    let moved_right = flags.moved_right != 0;
    let slow_bracket = if elapsed > 0.15f32 && moved_left != moved_right && note_count >= 2 {
        (elapsed - 0.15f32) * 300.0f32
    } else {
        0.0
    };
    let jack = if elapsed < 0.1f32
        && moved_left != moved_right
        && (flags.jacked_left != 0 || flags.jacked_right != 0)
    {
        let ts = 0.1f32 - elapsed;
        if ts > 0.0 {
            (1.0f32 / ts - 1.0f32 / 0.1f32) * 30.0f32
        } else {
            0.0
        }
    } else {
        0.0
    };

    StepParityElapsedCosts4 {
        slow_bracket,
        jack,
        total: slow_bracket + jack,
    }
}

fn expected_switch_costs(
    initial: StepParityState4,
    result: StepParityState4,
    placement: [u8; 4],
    active_mask: u8,
    side_mask: u8,
    mine_mask: u8,
    elapsed: f32,
) -> StepParitySwitchCosts4 {
    let footswitch = if mine_mask == 0 && (0.2f32..0.4f32).contains(&elapsed) {
        let mut cost = 0.0;
        for col in 0..4 {
            if active_mask & (1 << col) == 0 {
                continue;
            }
            let res = placement[col];
            let init = initial.combined_columns[col];
            if init == 0 || res == 0 {
                continue;
            }
            let other_part = match res {
                1 => 2,
                2 => 1,
                3 => 4,
                4 => 3,
                _ => 0,
            };
            if init != res && init != other_part {
                let time_scaled = elapsed - 0.2f32;
                cost = (time_scaled / (0.2f32 + time_scaled)) * 325.0f32;
                break;
            }
        }
        cost
    } else {
        0.0
    };

    let mut sideswitch = 0.0;
    for col in 0..4 {
        if side_mask & (1 << col) == 0 {
            continue;
        }
        let res = placement[col];
        let init = initial.combined_columns[col];
        if init != res
            && res != 0
            && init != 0
            && init <= 4
            && result.moved_mask & (1 << (init - 1)) == 0
        {
            sideswitch += 130.0;
        }
    }

    StepParitySwitchCosts4 {
        footswitch,
        sideswitch,
        total: footswitch + sideswitch,
    }
}

fn expected_switch_costs_8(
    initial: StepParityState8,
    result: StepParityState8,
    placement: [u8; 8],
    active_mask: u8,
    side_mask: u8,
    mine_mask: u8,
    elapsed: f32,
) -> StepParitySwitchCosts4 {
    let footswitch = if mine_mask == 0 && (0.2f32..0.4f32).contains(&elapsed) {
        let mut cost = 0.0;
        for col in 0..8 {
            if active_mask & (1 << col) == 0 {
                continue;
            }
            let res = placement[col];
            let init = initial.combined_columns[col];
            if init == 0 || res == 0 {
                continue;
            }
            let other_part = match res {
                1 => 2,
                2 => 1,
                3 => 4,
                4 => 3,
                _ => 0,
            };
            if init != res && init != other_part {
                let time_scaled = elapsed - 0.2f32;
                cost = (time_scaled / (0.2f32 + time_scaled)) * 325.0f32;
                break;
            }
        }
        cost
    } else {
        0.0
    };

    let mut sideswitch = 0.0;
    for col in 0..8 {
        if side_mask & (1 << col) == 0 {
            continue;
        }
        let res = placement[col];
        let init = initial.combined_columns[col];
        if init != res
            && res != 0
            && init != 0
            && init <= 4
            && result.moved_mask & (1 << (init - 1)) == 0
        {
            sideswitch += 130.0;
        }
    }

    StepParitySwitchCosts4 {
        footswitch,
        sideswitch,
        total: footswitch + sideswitch,
    }
}

fn expected_bracket_tap_costs(
    initial: StepParityState4,
    hit: [i8; 5],
    hold_mask: u8,
    elapsed: f32,
) -> StepParityBracketTapCosts4 {
    let pair_cost = |heel: i8, toe: i8, moved_mask: u8| -> f32 {
        if heel < 0 || toe < 0 {
            return 0.0;
        }
        let heel = heel as usize;
        let toe = toe as usize;
        let hm = hold_mask & (1 << heel) != 0;
        let tm = hold_mask & (1 << toe) != 0;
        if hm == tm {
            return 0.0;
        }
        let jack_penalty = if initial.moved_mask & moved_mask != 0 {
            1.0f32 / elapsed
        } else {
            1.0
        };
        400.0 * jack_penalty
    };

    let left = pair_cost(hit[1], hit[2], 0b0011);
    let right = pair_cost(hit[3], hit[4], 0b1100);
    StepParityBracketTapCosts4 {
        left,
        right,
        total: left + right,
    }
}

fn expected_bracket_tap_costs_8(
    initial: StepParityState8,
    hit: [i8; 5],
    hold_mask: u8,
    elapsed: f32,
) -> StepParityBracketTapCosts4 {
    let pair_cost = |heel: i8, toe: i8, moved_mask: u8| -> f32 {
        if heel < 0 || toe < 0 {
            return 0.0;
        }
        let heel = heel as usize;
        let toe = toe as usize;
        let hm = hold_mask & (1 << heel) != 0;
        let tm = hold_mask & (1 << toe) != 0;
        if hm == tm {
            return 0.0;
        }
        let jack_penalty = if initial.moved_mask & moved_mask != 0 {
            1.0f32 / elapsed
        } else {
            1.0
        };
        400.0 * jack_penalty
    };

    let left = pair_cost(hit[1], hit[2], 0b0011);
    let right = pair_cost(hit[3], hit[4], 0b1100);
    StepParityBracketTapCosts4 {
        left,
        right,
        total: left + right,
    }
}

fn expected_distance_costs(
    initial: StepParityState4,
    result: StepParityState4,
    hit: [i8; 5],
    hold_mask: u8,
    elapsed: f32,
) -> StepParityDistanceCosts4 {
    fn dist(a: usize, b: usize) -> f32 {
        const SQRT2: f32 = 1.4142135;
        const DIST: [[f32; 4]; 4] = [
            [0.0, SQRT2, SQRT2, 2.0],
            [SQRT2, 0.0, 2.0, SQRT2],
            [SQRT2, 2.0, 0.0, SQRT2],
            [2.0, SQRT2, SQRT2, 0.0],
        ];
        DIST[a][b]
    }

    let mut hold_switch = 0.0;
    let mut mask = hold_mask & result.occupied_mask;
    while mask != 0 {
        let col = mask.trailing_zeros() as usize;
        mask &= mask - 1;
        let foot = result.combined_columns[col];
        let init = initial.combined_columns[col];
        let switched = matches!(foot, 1 | 2) && !matches!(init, 1 | 2)
            || matches!(foot, 3 | 4) && !matches!(init, 3 | 4);
        if switched {
            let prev = initial.where_feet_are[foot as usize];
            hold_switch += if prev < 0 {
                55.0
            } else {
                dist(col, prev as usize) * 55.0
            };
        }
    }

    const OTHER: [usize; 5] = [0, 2, 1, 4, 3];
    let mut big_movement = 0.0;
    for foot in 1..=4 {
        if result.moved_mask & (1 << (foot - 1)) == 0 {
            continue;
        }
        let init_pos = initial.where_feet_are[foot];
        if init_pos < 0 {
            continue;
        }
        let res_pos = hit[foot];
        if res_pos < 0 {
            continue;
        }
        let mut cost = (dist(init_pos as usize, res_pos as usize) * 6.0) / elapsed;
        let other_pos = hit[OTHER[foot]];
        if other_pos >= 0 {
            if other_pos == init_pos {
                continue;
            }
            cost *= 0.2;
        }
        big_movement += cost;
    }

    StepParityDistanceCosts4 {
        hold_switch,
        big_movement,
        total: hold_switch + big_movement,
    }
}

fn expected_distance_costs_8(
    initial: StepParityState8,
    result: StepParityState8,
    hit: [i8; 5],
    hold_mask: u8,
    elapsed: f32,
) -> StepParityDistanceCosts4 {
    fn dist(a: usize, b: usize) -> f32 {
        const SQRT2: f32 = 1.4142135623731;
        const SQRT5: f32 = 2.23606797749979;
        const SQRT13: f32 = 3.60555127546399;
        const SQRT17: f32 = 4.12310562561766;
        const DIST: [[f32; 8]; 8] = [
            [0.0, SQRT2, SQRT2, 2.0, 3.0, SQRT17, SQRT17, 5.0],
            [SQRT2, 0.0, 2.0, SQRT2, SQRT5, 3.0, SQRT13, SQRT17],
            [SQRT2, 2.0, 0.0, SQRT2, SQRT5, SQRT13, 3.0, SQRT17],
            [2.0, SQRT2, SQRT2, 0.0, 1.0, SQRT5, SQRT5, 3.0],
            [3.0, SQRT5, SQRT5, 1.0, 0.0, SQRT2, SQRT2, 2.0],
            [SQRT17, 3.0, SQRT13, SQRT5, SQRT2, 0.0, 2.0, SQRT2],
            [SQRT17, SQRT13, 3.0, SQRT5, SQRT2, 2.0, 0.0, SQRT2],
            [5.0, SQRT17, SQRT17, 3.0, 2.0, SQRT2, SQRT2, 0.0],
        ];
        DIST[a][b]
    }

    let mut hold_switch = 0.0;
    let mut mask = hold_mask & result.occupied_mask;
    while mask != 0 {
        let col = mask.trailing_zeros() as usize;
        mask &= mask - 1;
        let foot = result.combined_columns[col];
        let init = initial.combined_columns[col];
        let switched = matches!(foot, 1 | 2) && !matches!(init, 1 | 2)
            || matches!(foot, 3 | 4) && !matches!(init, 3 | 4);
        if switched {
            let prev = initial.where_feet_are[foot as usize];
            hold_switch += if prev < 0 {
                55.0
            } else {
                dist(col, prev as usize) * 55.0
            };
        }
    }

    const OTHER: [usize; 5] = [0, 2, 1, 4, 3];
    let mut big_movement = 0.0;
    for foot in 1..=4 {
        if result.moved_mask & (1 << (foot - 1)) == 0 {
            continue;
        }
        let init_pos = initial.where_feet_are[foot];
        if init_pos < 0 {
            continue;
        }
        let res_pos = hit[foot];
        if res_pos < 0 {
            continue;
        }
        let mut cost = (dist(init_pos as usize, res_pos as usize) * 6.0) / elapsed;
        let other_pos = hit[OTHER[foot]];
        if other_pos >= 0 {
            if other_pos == init_pos {
                continue;
            }
            cost *= 0.2;
        }
        big_movement += cost;
    }

    StepParityDistanceCosts4 {
        hold_switch,
        big_movement,
        total: hold_switch + big_movement,
    }
}

fn expected_orientation_costs(
    initial: StepParityState4,
    result: StepParityState4,
    hit: [i8; 5],
) -> StepParityOrientationCosts4 {
    #[derive(Clone, Copy, Default)]
    struct Point {
        x: f32,
        y: f32,
    }

    const COLS: [Point; 4] = [
        Point { x: 0.0, y: 1.0 },
        Point { x: 1.0, y: 0.0 },
        Point { x: 1.0, y: 2.0 },
        Point { x: 2.0, y: 1.0 },
    ];

    let avg_point = |a: i8, b: i8| -> Point {
        match (a >= 0, b >= 0) {
            (false, false) => Point::default(),
            (false, true) => COLS[b as usize],
            (true, false) => COLS[a as usize],
            (true, true) => {
                let a = COLS[a as usize];
                let b = COLS[b as usize];
                Point {
                    x: (a.x + b.x) / 2.0,
                    y: (a.y + b.y) / 2.0,
                }
            }
        }
    };

    let facing_penalty = |v: f32| -> f32 {
        let base = -(v.min(0.0));
        if base > 0.0 {
            ((base as f64).powf(1.8) * 100.0) as f32
        } else {
            0.0
        }
    };

    let facing = |a: i8, b: i8, x_axis: bool| -> f32 {
        if a < 0 || b < 0 || a == b {
            return 0.0;
        }
        let a = COLS[a as usize];
        let b = COLS[b as usize];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let dist = (dx * dx + dy * dy).sqrt();
        if dist == 0.0 {
            return 0.0;
        }
        let n = if x_axis { dx / dist } else { dy / dist };
        let mut m = (n as f64).powf(4.0) as f32;
        if n <= 0.0 {
            m = -m;
        }
        facing_penalty(m)
    };

    let left_pos = avg_point(hit[1], hit[2]);
    let right_pos = avg_point(hit[3], hit[4]);
    let crossed = right_pos.x < left_pos.x;
    let backward = |heel: i8, toe: i8| -> bool {
        heel >= 0 && toe >= 0 && COLS[toe as usize].y < COLS[heel as usize].y
    };
    let twisted_foot = if !crossed && (backward(hit[3], hit[4]) || backward(hit[1], hit[2])) {
        100_000.0
    } else {
        0.0
    };

    let lh = result.where_feet_are[1];
    let mut lt = result.where_feet_are[2];
    let rh = result.where_feet_are[3];
    let mut rt = result.where_feet_are[4];
    if lt < 0 {
        lt = lh;
    }
    if rt < 0 {
        rt = rh;
    }
    let facing_cost = (facing(lh, rh, true)
        + facing(lt, rt, true)
        + facing(lh, lt, false)
        + facing(rh, rt, false))
        * 2.0;

    let prev_left = avg_point(initial.where_feet_are[1], initial.where_feet_are[2]);
    let prev_right = avg_point(initial.where_feet_are[3], initial.where_feet_are[4]);
    let left = avg_point(lh, lt);
    let right = avg_point(rh, rt);
    let spin = if right.x < left.x
        && prev_right.x < prev_left.x
        && ((right.y < left.y && prev_right.y > prev_left.y)
            || (right.y > left.y && prev_right.y < prev_left.y))
    {
        1000.0
    } else {
        0.0
    };

    StepParityOrientationCosts4 {
        twisted_foot,
        facing: facing_cost,
        spin,
        total: twisted_foot + facing_cost + spin,
    }
}

fn expected_orientation_costs_8(
    initial: StepParityState8,
    result: StepParityState8,
    hit: [i8; 5],
) -> StepParityOrientationCosts4 {
    #[derive(Clone, Copy, Default)]
    struct Point {
        x: f32,
        y: f32,
    }

    const COLS: [Point; 8] = [
        Point { x: 0.0, y: 1.0 },
        Point { x: 1.0, y: 0.0 },
        Point { x: 1.0, y: 2.0 },
        Point { x: 2.0, y: 1.0 },
        Point { x: 3.0, y: 1.0 },
        Point { x: 4.0, y: 0.0 },
        Point { x: 4.0, y: 2.0 },
        Point { x: 5.0, y: 1.0 },
    ];

    let valid = |c: i8| c >= 0 && (c as usize) < COLS.len();
    let avg_point = |a: i8, b: i8| -> Point {
        match (valid(a), valid(b)) {
            (false, false) => Point::default(),
            (false, true) => COLS[b as usize],
            (true, false) => COLS[a as usize],
            (true, true) => {
                let a = COLS[a as usize];
                let b = COLS[b as usize];
                Point {
                    x: (a.x + b.x) / 2.0,
                    y: (a.y + b.y) / 2.0,
                }
            }
        }
    };

    let facing_penalty = |v: f32| -> f32 {
        let base = -(v.min(0.0));
        if base > 0.0 {
            ((base as f64).powf(1.8) * 100.0) as f32
        } else {
            0.0
        }
    };

    let facing = |a: i8, b: i8, x_axis: bool| -> f32 {
        if !valid(a) || !valid(b) || a == b {
            return 0.0;
        }
        let a = COLS[a as usize];
        let b = COLS[b as usize];
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        let dist = (dx * dx + dy * dy).sqrt();
        if dist == 0.0 {
            return 0.0;
        }
        let n = if x_axis { dx / dist } else { dy / dist };
        let mut m = (n as f64).powf(4.0) as f32;
        if n <= 0.0 {
            m = -m;
        }
        facing_penalty(m)
    };

    let left_pos = avg_point(hit[1], hit[2]);
    let right_pos = avg_point(hit[3], hit[4]);
    let crossed = right_pos.x < left_pos.x;
    let backward = |heel: i8, toe: i8| -> bool {
        valid(heel) && valid(toe) && COLS[toe as usize].y < COLS[heel as usize].y
    };
    let twisted_foot = if !crossed && (backward(hit[3], hit[4]) || backward(hit[1], hit[2])) {
        100_000.0
    } else {
        0.0
    };

    let lh = result.where_feet_are[1];
    let mut lt = result.where_feet_are[2];
    let rh = result.where_feet_are[3];
    let mut rt = result.where_feet_are[4];
    if lt < 0 {
        lt = lh;
    }
    if rt < 0 {
        rt = rh;
    }
    let facing_cost = (facing(lh, rh, true)
        + facing(lt, rt, true)
        + facing(lh, lt, false)
        + facing(rh, rt, false))
        * 2.0;

    let prev_left = avg_point(initial.where_feet_are[1], initial.where_feet_are[2]);
    let prev_right = avg_point(initial.where_feet_are[3], initial.where_feet_are[4]);
    let left = avg_point(lh, lt);
    let right = avg_point(rh, rt);
    let spin = if right.x < left.x
        && prev_right.x < prev_left.x
        && ((right.y < left.y && prev_right.y > prev_left.y)
            || (right.y > left.y && prev_right.y < prev_left.y))
    {
        1000.0
    } else {
        0.0
    };

    StepParityOrientationCosts4 {
        twisted_foot,
        facing: facing_cost,
        spin,
        total: twisted_foot + facing_cost + spin,
    }
}

#[allow(clippy::too_many_arguments)]
fn expected_action_costs(
    initial: StepParityState4,
    result: StepParityState4,
    placement: [u8; 4],
    hit: [i8; 5],
    note_count: u8,
    active_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed: f32,
) -> StepParityActionCosts4 {
    let flags = expected_action_flags(initial, result, hit);
    let basic = expected_basic_costs(
        result,
        flags,
        active_mask.count_ones() > 1,
        mine_mask,
        prev_row_has_live_hold,
    );
    let elapsed_costs = expected_elapsed_costs(flags, note_count, elapsed);
    let switch = expected_switch_costs(
        initial,
        result,
        placement,
        active_mask,
        side_mask,
        mine_mask,
        elapsed,
    );
    let bracket_tap = expected_bracket_tap_costs(initial, hit, hold_mask, elapsed);
    let distance = expected_distance_costs(initial, result, hit, hold_mask, elapsed);
    let orientation = expected_orientation_costs(initial, result, hit);
    let twisted_foot = if active_mask.count_ones() > 1 {
        orientation.twisted_foot
    } else {
        0.0
    };

    let mut out = StepParityActionCosts4 {
        mine: basic.mine,
        hold_switch: distance.hold_switch,
        bracket_tap: bracket_tap.total,
        bracket_jack: basic.bracket_jack,
        doublestep: basic.doublestep,
        slow_bracket: elapsed_costs.slow_bracket,
        twisted_foot,
        facing: orientation.facing,
        spin: orientation.spin,
        footswitch: switch.footswitch,
        sideswitch: switch.sideswitch,
        missed_footswitch: basic.missed_footswitch,
        jack: elapsed_costs.jack,
        big_movement: distance.big_movement,
        total: 0.0,
    };
    out.total = out.mine
        + out.hold_switch
        + out.bracket_tap
        + out.bracket_jack
        + out.doublestep
        + out.slow_bracket
        + out.twisted_foot
        + out.facing
        + out.spin
        + out.footswitch
        + out.sideswitch
        + out.missed_footswitch
        + out.jack
        + out.big_movement;
    out
}

#[allow(clippy::too_many_arguments)]
fn expected_action_costs_8(
    initial: StepParityState8,
    result: StepParityState8,
    placement: [u8; 8],
    hit: [i8; 5],
    note_count: u8,
    active_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed: f32,
) -> StepParityActionCosts4 {
    let flags = expected_action_flags_8(initial, result, hit);
    let basic = expected_basic_costs_8(
        result,
        flags,
        active_mask.count_ones() > 1,
        mine_mask,
        prev_row_has_live_hold,
    );
    let elapsed_costs = expected_elapsed_costs(flags, note_count, elapsed);
    let switch = expected_switch_costs_8(
        initial,
        result,
        placement,
        active_mask,
        side_mask,
        mine_mask,
        elapsed,
    );
    let bracket_tap = expected_bracket_tap_costs_8(initial, hit, hold_mask, elapsed);
    let distance = expected_distance_costs_8(initial, result, hit, hold_mask, elapsed);
    let orientation = expected_orientation_costs_8(initial, result, hit);
    let twisted_foot = if active_mask.count_ones() > 1 {
        orientation.twisted_foot
    } else {
        0.0
    };

    let mut out = StepParityActionCosts4 {
        mine: basic.mine,
        hold_switch: distance.hold_switch,
        bracket_tap: bracket_tap.total,
        bracket_jack: basic.bracket_jack,
        doublestep: basic.doublestep,
        slow_bracket: elapsed_costs.slow_bracket,
        twisted_foot,
        facing: orientation.facing,
        spin: orientation.spin,
        footswitch: switch.footswitch,
        sideswitch: switch.sideswitch,
        missed_footswitch: basic.missed_footswitch,
        jack: elapsed_costs.jack,
        big_movement: distance.big_movement,
        total: 0.0,
    };
    out.total = out.mine
        + out.hold_switch
        + out.bracket_tap
        + out.bracket_jack
        + out.doublestep
        + out.slow_bracket
        + out.twisted_foot
        + out.facing
        + out.spin
        + out.footswitch
        + out.sideswitch
        + out.missed_footswitch
        + out.jack
        + out.big_movement;
    out
}

#[allow(clippy::too_many_arguments)]
fn expected_best_row_candidates(
    initial_states: &[StepParityState4],
    initial_costs: &[f32],
    note_count: u8,
    note_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed: f32,
) -> Vec<(u32, [u8; 4], StepParityState4, [i8; 5], u32, f32)> {
    let active_mask = note_mask | hold_mask;
    let mut out: Vec<(u32, [u8; 4], StepParityState4, [i8; 5], u32, f32)> = Vec::new();
    for (pred, initial) in initial_states.iter().copied().enumerate() {
        for placement in expected_permutations_4(active_mask) {
            let (state, hit, key) =
                expected_result_state(initial, placement, active_mask, hold_mask);
            let action = expected_action_costs(
                initial,
                state,
                placement,
                hit,
                note_count,
                active_mask,
                hold_mask,
                mine_mask,
                side_mask,
                prev_row_has_live_hold,
                elapsed,
            );
            let cost = initial_costs[pred] + action.total;
            if let Some(existing) = out.iter_mut().find(|candidate| candidate.4 == key) {
                if cost < existing.5 {
                    *existing = (pred as u32, placement, state, hit, key, cost);
                }
            } else {
                out.push((pred as u32, placement, state, hit, key, cost));
            }
        }
    }
    out
}

#[allow(clippy::too_many_arguments)]
fn expected_best_row_candidates_8(
    initial_states: &[StepParityState8],
    initial_costs: &[f32],
    note_count: u8,
    note_mask: u8,
    hold_mask: u8,
    mine_mask: u8,
    side_mask: u8,
    prev_row_has_live_hold: bool,
    elapsed: f32,
) -> Vec<(u32, [u8; 8], StepParityState8, [i8; 5], u32, f32)> {
    let active_mask = note_mask | hold_mask;
    let placements = expected_row_permutations_8(note_mask, hold_mask);
    let mut out: Vec<(u32, [u8; 8], StepParityState8, [i8; 5], u32, f32)> = Vec::new();
    for (pred, initial) in initial_states.iter().copied().enumerate() {
        for placement in placements.iter().copied() {
            let (state, hit, key) =
                expected_result_state_8(initial, placement, active_mask, hold_mask);
            let action = expected_action_costs_8(
                initial,
                state,
                placement,
                hit,
                note_count,
                active_mask,
                hold_mask,
                mine_mask,
                side_mask,
                prev_row_has_live_hold,
                elapsed,
            );
            let cost = initial_costs[pred] + action.total;
            if let Some(existing) = out.iter_mut().find(|candidate| candidate.4 == key) {
                if cost < existing.5 {
                    *existing = (pred as u32, placement, state, hit, key, cost);
                }
            } else {
                out.push((pred as u32, placement, state, hit, key, cost));
            }
        }
    }
    out
}

fn expected_place_rows(
    note_counts: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
) -> Vec<[u8; 4]> {
    expected_place_states(
        note_counts,
        note_masks,
        hold_masks,
        mine_masks,
        prev_row_live_holds,
        row_seconds,
    )
    .into_iter()
    .map(|state| state.combined_columns)
    .collect()
}

fn expected_place_rows_8(
    note_counts: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
) -> Vec<[u8; 8]> {
    let mut states = vec![StepParityState8::default()];
    let mut costs = vec![0.0f32];
    let mut prev_second = row_seconds[0] - 1.0;
    let mut backtrack: Vec<Vec<(usize, StepParityState8)>> = Vec::new();

    for i in 0..note_counts.len() {
        let elapsed = row_seconds[i] - prev_second;
        prev_second = row_seconds[i];
        let active_mask = note_masks[i] | hold_masks[i];
        let candidates = expected_best_row_candidates_8(
            &states,
            &costs,
            note_counts[i],
            note_masks[i],
            hold_masks[i],
            mine_masks[i],
            active_mask & 0b1001_1001,
            prev_row_live_holds[i] != 0,
            elapsed,
        );

        states = candidates
            .iter()
            .map(|(_, _, state, _, _, _)| *state)
            .collect();
        costs = candidates.iter().map(|candidate| candidate.5).collect();
        backtrack.push(
            candidates
                .iter()
                .map(|(pred, _, state, _, _, _)| (*pred as usize, *state))
                .collect(),
        );
    }

    let mut idx = costs
        .iter()
        .enumerate()
        .min_by(|(_, a), (_, b)| a.total_cmp(b))
        .map(|(idx, _)| idx)
        .unwrap();

    let mut out = Vec::with_capacity(note_counts.len());
    for row in backtrack.iter().rev() {
        let (pred, state) = row[idx];
        out.push(state.combined_columns);
        idx = pred;
    }
    out.reverse();
    out
}

fn expected_place_states(
    note_counts: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
) -> Vec<StepParityState4> {
    let mut states = vec![StepParityState4::default()];
    let mut costs = vec![0.0f32];
    let mut prev_second = row_seconds[0] - 1.0;
    let mut backtrack: Vec<Vec<(usize, StepParityState4)>> = Vec::new();

    for i in 0..note_counts.len() {
        let elapsed = row_seconds[i] - prev_second;
        prev_second = row_seconds[i];
        let active_mask = note_masks[i] | hold_masks[i];
        let candidates = expected_best_row_candidates(
            &states,
            &costs,
            note_counts[i],
            note_masks[i],
            hold_masks[i],
            mine_masks[i],
            active_mask & 0b1001,
            prev_row_live_holds[i] != 0,
            elapsed,
        );

        states = candidates
            .iter()
            .map(|(_, _, state, _, _, _)| *state)
            .collect();
        costs = candidates.iter().map(|candidate| candidate.5).collect();
        backtrack.push(
            candidates
                .iter()
                .map(|(pred, _, state, _, _, _)| (*pred as usize, *state))
                .collect(),
        );
    }

    let mut idx = costs
        .iter()
        .enumerate()
        .min_by(|(_, a), (_, b)| a.total_cmp(b))
        .map(|(idx, _)| idx)
        .unwrap();
    let mut placements = vec![StepParityState4::default(); note_counts.len()];
    for row in (0..note_counts.len()).rev() {
        let (pred, placement) = backtrack[row][idx];
        placements[row] = placement;
        idx = pred;
    }
    placements
}

#[test]
fn parses_known_tech_list_like_rssp_core() {
    const KNOWN: &str = concat!(
        "24ths 32nds br BR BR+ BR- BT BT+ BT- bu BU BU+ BU- ",
        "BXF BXF+ BXF- bXF bXF+ bXF- BxF BXf BxF+ BxF- ",
        "bXf bXf+ bXf- bxF bxF+ bxF- B+XF BX-F BX-F+ BX+F+ ",
        "B+X-F B-X-F- B-XF+ ds DS DS++ DS+ DS- dr DR DR+ DR- ",
        "dt dt- DT DT+ DT- FL FL+ FL- fs FS FS+ FS- FX FX+ FX- ",
        "GH GH+ GH- HA HA+ HA- HS HS+ HS- ITL+ ja ja- JA JA+ JA- ",
        "ju ju- JU JU+ JU- JUMPS JUMPS+ JUMPS- KS KS+ KS- KT KT+ KT- ",
        "LOL ma ma- MA MA+ MA- MD MD+ MD- rh rh- RH RH+ RH- Rolls- ",
        "RS RS+ RS- SC SC+ SC- SDS SDS+ SDS- SJ SJ+ SJ- SK SK+ SK- ",
        "SS SS+ SS- SKT SKT+ SKT- SPD SPD+ SPD- STR STR+ STR- ",
        "TR TR+ TR- WA WA+ WA- XMOD XMOD+ XMOD- xo XO XO+ XO-"
    );

    assert_matches_rssp(KNOWN, "");
}

#[test]
fn skips_no_tech_measure_data_and_invalid_chunks_like_rssp_core() {
    assert_matches_rssp("No Tech STR+bad /--- 1234", "FS-,No Tech BXF");
}

#[test]
fn parses_concatenated_chunks_with_longest_prefixes_like_rssp_core() {
    assert_matches_rssp("BXF+BX-F+B-X-F-", "BT+JUMPS+Rolls-");
}

#[test]
fn combines_credit_and_description_like_rssp_core() {
    assert_matches_rssp("STR+ FS-", "BXF,24ths 32nds");
}

#[test]
fn enumerates_step_parity_permutations_like_rssp_row_rules() {
    for mask in 0..16 {
        assert_eq!(
            step_parity_permutations_4(mask),
            expected_permutations_4(mask),
            "mask {mask:04b}"
        );
    }
}

#[test]
fn enumerates_double_step_parity_permutations_like_rssp_row_rules() {
    for mask in 0..=u8::MAX {
        assert_eq!(
            step_parity_permutations_8(mask),
            expected_permutations_8(mask),
            "mask {mask:08b}"
        );
    }
}

#[test]
fn calculates_no_hold_result_state_like_rssp_core() {
    let start = StepParityState4::default();
    let cases = [
        (start, [1, 0, 0, 0], 0b0001),
        (
            StepParityState4 {
                combined_columns: [1, 2, 0, 0],
                ..StepParityState4::default()
            },
            [0, 0, 3, 0],
            0b0100,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 2, 0, 0],
                ..StepParityState4::default()
            },
            [0, 0, 0, 1],
            0b1000,
        ),
    ];

    for (initial, placement, active_mask) in cases {
        assert_eq!(
            step_parity_result_state_no_holds_4(&initial, &placement, active_mask).unwrap(),
            expected_result_state(initial, placement, active_mask, 0)
        );
    }
}

#[test]
fn calculates_hold_result_state_like_rssp_core() {
    let initial = StepParityState4 {
        combined_columns: [1, 0, 3, 0],
        ..StepParityState4::default()
    };
    let cases = [
        ([1, 0, 0, 0], 0b0001, 0b0001),
        ([2, 0, 3, 0], 0b0101, 0b0100),
        ([0, 4, 0, 0], 0b0010, 0b0010),
    ];

    for (placement, active_mask, hold_mask) in cases {
        assert_eq!(
            step_parity_result_state_holds_4(&initial, &placement, active_mask, hold_mask).unwrap(),
            expected_result_state(initial, placement, active_mask, hold_mask)
        );
    }
}

#[test]
fn calculates_double_no_hold_result_state_like_rssp_core() {
    let start = StepParityState8::default();
    let cases = [
        (start, [1, 0, 0, 0, 0, 0, 0, 0], 0b0000_0001),
        (
            StepParityState8 {
                combined_columns: [1, 2, 0, 0, 0, 0, 0, 0],
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 3, 0, 0, 0],
            0b0001_0000,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 0, 3, 4],
                ..StepParityState8::default()
            },
            [0, 0, 1, 0, 0, 0, 0, 0],
            0b0000_0100,
        ),
    ];

    for (initial, placement, active_mask) in cases {
        assert_eq!(
            step_parity_result_state_no_holds_8(&initial, &placement, active_mask).unwrap(),
            expected_result_state_8(initial, placement, active_mask, 0)
        );
    }
}

#[test]
fn calculates_double_hold_result_state_like_rssp_core() {
    let initial = StepParityState8 {
        combined_columns: [1, 0, 0, 0, 0, 0, 3, 0],
        ..StepParityState8::default()
    };
    let cases = [
        ([1, 0, 0, 0, 0, 0, 0, 0], 0b0000_0001, 0b0000_0001),
        ([0, 2, 0, 0, 0, 0, 3, 0], 0b0100_0010, 0b0100_0000),
        ([0, 0, 0, 0, 0, 0, 0, 4], 0b1000_0000, 0b1000_0000),
    ];

    for (placement, active_mask, hold_mask) in cases {
        assert_eq!(
            step_parity_result_state_holds_8(&initial, &placement, active_mask, hold_mask).unwrap(),
            expected_result_state_8(initial, placement, active_mask, hold_mask)
        );
    }
}

#[test]
fn enumerates_double_row_transitions_from_parity_states_like_rssp_core() {
    let initial_states = [
        StepParityState8::default(),
        StepParityState8 {
            combined_columns: [1, 2, 0, 0, 0, 0, 0, 0],
            where_feet_are: [-1, 0, 1, -1, -1],
            occupied_mask: 0b0000_0011,
            ..StepParityState8::default()
        },
        StepParityState8 {
            combined_columns: [0, 0, 0, 0, 0, 0, 3, 4],
            where_feet_are: [-1, -1, -1, 6, 7],
            occupied_mask: 0b1100_0000,
            ..StepParityState8::default()
        },
    ];

    for initial in initial_states {
        for active_mask in 0..=u8::MAX {
            let hold_masks = [
                0,
                active_mask & 0b0000_0011,
                active_mask & 0b1100_0000,
                active_mask,
            ];
            for hold_mask in hold_masks {
                let note_mask = active_mask & !hold_mask;
                let actual = step_parity_row_transitions_8(&initial, note_mask, hold_mask);
                let expected: Vec<_> = expected_permutations_8(active_mask)
                    .into_iter()
                    .map(|placement| {
                        let (state, hit, key) =
                            expected_result_state_8(initial, placement, active_mask, hold_mask);
                        (placement, state, hit, key)
                    })
                    .collect();
                let actual: Vec<_> = actual
                    .into_iter()
                    .map(|t| (t.placement, t.state, t.hit, t.key))
                    .collect();
                assert_eq!(
                    actual, expected,
                    "active={active_mask:08b} hold={hold_mask:08b}"
                );
            }
        }
    }
}

#[test]
fn enumerates_row_transitions_from_parity_states_like_rssp_core() {
    let initial_states = [
        StepParityState4::default(),
        StepParityState4 {
            combined_columns: [1, 2, 0, 0],
            where_feet_are: [-1, 0, 1, -1, -1],
            occupied_mask: 0b0011,
            ..StepParityState4::default()
        },
        StepParityState4 {
            combined_columns: [0, 0, 3, 4],
            where_feet_are: [-1, -1, -1, 2, 3],
            occupied_mask: 0b1100,
            ..StepParityState4::default()
        },
    ];

    for initial in initial_states {
        for active_mask in 0..16 {
            let hold_masks = [0, active_mask & 0b0011, active_mask & 0b1100, active_mask];
            for hold_mask in hold_masks {
                let note_mask = active_mask & !hold_mask;
                let actual = step_parity_row_transitions_4(&initial, note_mask, hold_mask);
                let expected: Vec<_> = expected_permutations_4(active_mask)
                    .into_iter()
                    .map(|placement| {
                        let (state, hit, key) =
                            expected_result_state(initial, placement, active_mask, hold_mask);
                        (placement, state, hit, key)
                    })
                    .collect();
                let actual: Vec<_> = actual
                    .into_iter()
                    .map(|t| (t.placement, t.state, t.hit, t.key))
                    .collect();
                assert_eq!(
                    actual, expected,
                    "active={active_mask:04b} hold={hold_mask:04b}"
                );
            }
        }
    }
}

#[test]
fn dedupes_row_candidates_by_state_key_like_rssp_row_map() {
    let initial_states = [
        StepParityState4::default(),
        StepParityState4 {
            combined_columns: [1, 0, 0, 0],
            where_feet_are: [-1, 0, -1, -1, -1],
            occupied_mask: 0b0001,
            ..StepParityState4::default()
        },
        StepParityState4 {
            combined_columns: [0, 0, 3, 0],
            where_feet_are: [-1, -1, -1, 2, -1],
            occupied_mask: 0b0100,
            ..StepParityState4::default()
        },
    ];

    let note_mask = 0b0101u8;
    let hold_mask = 0b0000;
    let mut seen = HashSet::new();
    let mut expected = Vec::new();
    for (pred, initial) in initial_states.iter().copied().enumerate() {
        for placement in expected_permutations_4(note_mask | hold_mask) {
            let (state, hit, key) = expected_result_state(initial, placement, note_mask, hold_mask);
            if seen.insert(key) {
                expected.push((pred as u32, placement, state, hit, key));
            }
        }
    }

    let actual: Vec<_> = step_parity_row_key_candidates_4(&initial_states, note_mask, hold_mask)
        .unwrap()
        .into_iter()
        .map(|c| {
            (
                c.predecessor,
                c.transition.placement,
                c.transition.state,
                c.transition.hit,
                c.transition.key,
            )
        })
        .collect();

    assert!(expected.len() < initial_states.len() * expected_permutations_4(note_mask).len());
    assert_eq!(actual, expected);
}

#[test]
fn dedupes_double_row_candidates_by_state_key_like_rssp_row_map() {
    let initial_states = [
        StepParityState8::default(),
        StepParityState8 {
            combined_columns: [1, 0, 0, 0, 0, 0, 0, 0],
            where_feet_are: [-1, 0, -1, -1, -1],
            occupied_mask: 0b0000_0001,
            ..StepParityState8::default()
        },
        StepParityState8 {
            combined_columns: [0, 0, 0, 0, 0, 0, 3, 0],
            where_feet_are: [-1, -1, -1, 6, -1],
            occupied_mask: 0b0100_0000,
            ..StepParityState8::default()
        },
    ];

    let note_mask = 0b0001_0101u8;
    let hold_mask = 0b0100_0000u8;
    let active_mask = note_mask | hold_mask;
    let mut seen = HashSet::new();
    let mut expected = Vec::new();
    for (pred, initial) in initial_states.iter().copied().enumerate() {
        for placement in expected_permutations_8(active_mask) {
            let (state, hit, key) =
                expected_result_state_8(initial, placement, active_mask, hold_mask);
            if seen.insert(key) {
                expected.push((pred as u32, placement, state, hit, key));
            }
        }
    }

    let actual: Vec<_> = step_parity_row_key_candidates_8(&initial_states, note_mask, hold_mask)
        .unwrap()
        .into_iter()
        .map(|c| {
            (
                c.predecessor,
                c.transition.placement,
                c.transition.state,
                c.transition.hit,
                c.transition.key,
            )
        })
        .collect();

    assert!(expected.len() < initial_states.len() * expected_permutations_8(active_mask).len());
    assert_eq!(actual, expected);
}

#[test]
fn selects_best_row_candidates_by_state_key_like_rssp_dp() {
    let initial_states = [StepParityState4::default(), StepParityState4::default()];
    let initial_costs = [50.0f32, 1.0];
    let note_mask = 0b0101u8;
    let hold_mask = 0;
    let note_count = note_mask.count_ones() as u8;
    let mine_mask = 0;
    let side_mask = note_mask & 0b1001;
    let elapsed = 0.25f32;
    let expected = expected_best_row_candidates(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        false,
        elapsed,
    );

    let actual: Vec<_> = step_parity_row_best_candidates_4(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        false,
        elapsed,
    )
    .unwrap()
    .into_iter()
    .map(|c| {
        (
            c.predecessor,
            c.transition.placement,
            c.transition.state,
            c.transition.hit,
            c.transition.key,
            c.cost,
        )
    })
    .collect();

    assert!(actual.iter().all(|candidate| candidate.0 == 1));
    assert_eq!(actual, expected);
}

#[test]
fn selects_best_double_row_candidates_by_state_key_like_rssp_dp() {
    let initial_states = [StepParityState8::default(), StepParityState8::default()];
    let initial_costs = [50.0f32, 1.0];
    let note_mask = 0b0101_0000u8;
    let hold_mask = 0;
    let note_count = note_mask.count_ones() as u8;
    let mine_mask = 0;
    let side_mask = note_mask & 0b1001_1001;
    let elapsed = 0.25f32;
    let expected = expected_best_row_candidates_8(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        false,
        elapsed,
    );

    let actual: Vec<_> = step_parity_row_best_candidates_8(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        false,
        elapsed,
    )
    .unwrap()
    .into_iter()
    .map(|c| {
        (
            c.predecessor,
            c.transition.placement,
            c.transition.state,
            c.transition.hit,
            c.transition.key,
            c.cost,
        )
    })
    .collect();

    assert!(actual.iter().all(|candidate| candidate.0 == 1));
    assert_eq!(actual, expected);
}

#[test]
fn falls_back_to_double_note_permutations_when_hold_union_has_no_valid_row() {
    let initial_states = [StepParityState8::default()];
    let initial_costs = [0.0f32];
    let note_mask = 0b0000_0100u8;
    let hold_mask = 0b0001_0010u8;
    let note_count = note_mask.count_ones() as u8;
    let mine_mask = 0;
    let side_mask = (note_mask | hold_mask) & 0b1001_1001;
    let elapsed = 0.125f32;
    let expected = expected_best_row_candidates_8(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        true,
        elapsed,
    );

    assert!(expected_permutations_8(note_mask | hold_mask).is_empty());
    assert!(!expected_permutations_8(note_mask).is_empty());
    assert!(step_parity_row_transitions_8(&initial_states[0], note_mask, hold_mask).is_empty());

    let actual: Vec<_> = step_parity_row_best_candidates_8(
        &initial_states,
        &initial_costs,
        note_count,
        note_mask,
        hold_mask,
        mine_mask,
        side_mask,
        true,
        elapsed,
    )
    .unwrap()
    .into_iter()
    .map(|c| {
        (
            c.predecessor,
            c.transition.placement,
            c.transition.state,
            c.transition.hit,
            c.transition.key,
            c.cost,
        )
    })
    .collect();

    assert!(!actual.is_empty());
    assert!(
        actual
            .iter()
            .all(|(_, placement, _, _, _, _)| placement[2] != 0
                && placement[1] == 0
                && placement[4] == 0)
    );
    assert_eq!(actual, expected);
}

#[test]
fn rejects_row_best_candidates_with_mismatched_costs() {
    assert!(
        step_parity_row_best_candidates_4(
            &[StepParityState4::default()],
            &[],
            1,
            1,
            0,
            0,
            1,
            false,
            0.25
        )
        .is_none()
    );
    assert!(
        step_parity_row_best_candidates_8(
            &[StepParityState8::default()],
            &[],
            1,
            1,
            0,
            0,
            1,
            false,
            0.25
        )
        .is_none()
    );
}

#[test]
fn places_prepared_rows_by_backtracking_best_step_parity_path() {
    let note_masks = [0b0001u8, 0b0010, 0b0001, 0b0101];
    let note_counts = note_masks.map(|mask| mask.count_ones() as u8);
    let hold_masks = [0u8; 4];
    let mine_masks = [0u8, 0, 0b0001, 0];
    let prev_row_live_holds = [0u8; 4];
    let row_seconds = [0.0f32, 0.125, 0.25, 0.5];

    let expected = expected_place_rows(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
    );
    let actual = step_parity_place_rows_4(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
        256,
    )
    .unwrap();

    assert_eq!(actual, expected);
}

#[test]
fn places_double_prepared_rows_by_backtracking_best_step_parity_path() {
    let note_masks = [0b0001_0000u8, 0b0010_0000, 0b0001_0000, 0b0101_0000];
    let note_counts = note_masks.map(|mask| mask.count_ones() as u8);
    let hold_masks = [0u8; 4];
    let mine_masks = [0u8, 0, 0b0001_0000, 0];
    let prev_row_live_holds = [0u8; 4];
    let row_seconds = [0.0f32, 0.125, 0.25, 0.5];

    let expected = expected_place_rows_8(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
    );
    let actual = step_parity_place_rows_8(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
        256,
    )
    .unwrap();

    assert_eq!(actual, expected);
}

#[test]
fn places_double_row_with_unplaceable_hold_union_using_note_fallback() {
    let note_masks = [0b0000_0100u8];
    let note_counts = [1u8];
    let hold_masks = [0b0001_0010u8];
    let mine_masks = [0u8];
    let prev_row_live_holds = [1u8];
    let row_seconds = [0.0f32];

    let expected = expected_place_rows_8(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
    );
    let actual = step_parity_place_rows_8(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
        256,
    )
    .unwrap();

    assert_eq!(actual, expected);
}

#[test]
fn rejects_prepared_row_placement_when_state_cap_is_too_small() {
    let note_masks = [0b0001u8];
    let note_counts = [1u8];
    let hold_masks = [0u8];
    let mine_masks = [0u8];
    let prev_row_live_holds = [0u8];
    let row_seconds = [0.0f32];

    assert!(
        step_parity_place_rows_4(
            &note_counts,
            &note_masks,
            &hold_masks,
            &mine_masks,
            &prev_row_live_holds,
            &row_seconds,
            1,
        )
        .is_none()
    );
    assert!(
        step_parity_place_rows_8(
            &note_counts,
            &note_masks,
            &hold_masks,
            &mine_masks,
            &prev_row_live_holds,
            &row_seconds,
            1,
        )
        .is_none()
    );
}

#[test]
fn prepares_tap_rows_from_minimized_note_data() {
    let rows = step_parity_prepare_tap_rows_4(
        b"1000\n0000\n0L00\n0011\n;\n",
        &[0.0, 0.125, 0.25],
        &[0, 125, 250],
    )
    .unwrap();

    assert_eq!(rows.note_counts, [1, 1, 2]);
    assert_eq!(rows.tech_masks, [0b0001, 0b0010, 0b1100]);
    assert_eq!(rows.note_masks, [0b0001, 0, 0b1100]);
    assert_eq!(rows.hold_masks, [0, 0, 0]);
    assert_eq!(rows.mine_masks, [0, 0, 0]);
    assert_eq!(rows.prev_row_live_holds, [0, 0, 0]);
    assert_eq!(rows.row_seconds, [0.0, 0.125, 0.25]);
    assert_eq!(rows.row_ms, [0, 125, 250]);
}

#[test]
fn prepares_same_row_mines_with_tap_rows() {
    let rows = step_parity_prepare_tap_rows_4(b"M100\n;\n", &[0.125], &[125]).unwrap();

    assert_eq!(rows.note_counts, [1]);
    assert_eq!(rows.tech_masks, [0b0010]);
    assert_eq!(rows.note_masks, [0b0010]);
    assert_eq!(rows.hold_masks, [0]);
    assert_eq!(rows.mine_masks, [0b0001]);
    assert_eq!(rows.prev_row_live_holds, [0]);
    assert_eq!(rows.row_seconds, [0.125]);
    assert_eq!(rows.row_ms, [125]);
}

#[test]
fn carries_mine_only_rows_to_next_tap_row() {
    let rows =
        step_parity_prepare_tap_rows_4(b"M000\n0100\n;\n", &[0.125, 0.25], &[125, 250]).unwrap();

    assert_eq!(rows.note_counts, [1]);
    assert_eq!(rows.tech_masks, [0b0010]);
    assert_eq!(rows.note_masks, [0b0010]);
    assert_eq!(rows.hold_masks, [0]);
    assert_eq!(rows.mine_masks, [0b0001]);
    assert_eq!(rows.prev_row_live_holds, [0]);
    assert_eq!(rows.row_seconds, [0.25]);
    assert_eq!(rows.row_ms, [250]);
}

#[test]
fn computes_hold_head_end_beats_for_step_parity_rows() {
    let hold_ends =
        step_parity_hold_head_ends_4(b"2000\n0000\n0100\n3000\n;\n", &[0.0, 0.5, 1.0]).unwrap();

    assert_eq!(
        hold_ends,
        [
            [1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0],
        ]
    );
}

#[test]
fn cancels_pending_hold_heads_like_rssp_prepass() {
    let hold_ends =
        step_parity_hold_head_ends_4(b"2400\nM000\n0300\n;\n", &[0.0, 0.5, 1.0]).unwrap();

    assert_eq!(
        hold_ends,
        [
            [-1.0, 1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0],
        ]
    );
}

#[test]
fn computes_double_hold_head_end_beats_for_step_parity_rows() {
    let hold_ends = step_parity_hold_head_ends_8(
        b"20000000\n00000000\n00001000\n30000000\n;\n",
        &[0.0, 1.0, 1.5],
    )
    .unwrap();

    assert_eq!(
        hold_ends,
        [
            [1.5, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
        ]
    );

    let hold_ends = step_parity_hold_head_ends_8(b"20000000\n30000000\n;\n", &[0.0, 0.5]).unwrap();
    assert_eq!(
        hold_ends,
        [
            [0.5, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
            [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0],
        ]
    );
}

#[test]
fn prepares_hold_rows_with_live_hold_masks() {
    let rows = step_parity_prepare_hold_rows_4(
        b"2000\n0100\n3100\n1000\n;\n",
        &[0.0, 0.5, 1.0, 1.5],
        &[0, 500, 1000, 1500],
        &[0.0, 0.5, 1.0, 1.5],
    )
    .unwrap();

    assert_eq!(rows.note_counts, [1, 1, 1, 1]);
    assert_eq!(rows.tech_masks, [0b0001, 0b0010, 0b0010, 0b0001]);
    assert_eq!(rows.note_masks, [0b0001, 0b0010, 0b0010, 0b0001]);
    assert_eq!(rows.hold_masks, [0, 0b0001, 0b0001, 0]);
    assert_eq!(rows.mine_masks, [0, 0, 0, 0]);
    assert_eq!(rows.prev_row_live_holds, [0, 0, 1, 0]);
    assert_eq!(rows.row_seconds, [0.0, 0.5, 1.0, 1.5]);
    assert_eq!(rows.row_ms, [0, 500, 1000, 1500]);
}

#[test]
fn prepares_double_hold_rows_with_live_hold_masks() {
    let rows = step_parity_prepare_hold_rows_8(
        b"20000000\n00001000\n30001000\n10000000\n;\n",
        &[0.0, 0.5, 1.0, 1.5],
        &[0, 500, 1000, 1500],
        &[0.0, 0.5, 1.0, 1.5],
    )
    .unwrap();

    assert_eq!(rows.note_counts, [1, 1, 1, 1]);
    assert_eq!(
        rows.tech_masks,
        [0b0000_0001, 0b0001_0000, 0b0001_0000, 0b0000_0001]
    );
    assert_eq!(
        rows.note_masks,
        [0b0000_0001, 0b0001_0000, 0b0001_0000, 0b0000_0001]
    );
    assert_eq!(rows.hold_masks, [0, 0b0000_0001, 0b0000_0001, 0]);
    assert_eq!(rows.mine_masks, [0, 0, 0, 0]);
    assert_eq!(rows.prev_row_live_holds, [0, 0, 1, 0]);
    assert_eq!(rows.row_seconds, [0.0, 0.5, 1.0, 1.5]);
    assert_eq!(rows.row_ms, [0, 500, 1000, 1500]);
}

#[test]
fn ignores_hold_heads_without_tails_in_hold_row_preparer() {
    let rows =
        step_parity_prepare_hold_rows_4(b"2000\n0100\n;\n", &[0.0, 0.5], &[0, 500], &[0.0, 0.5])
            .unwrap();

    assert_eq!(rows.note_counts, [1]);
    assert_eq!(rows.tech_masks, [0b0010]);
    assert_eq!(rows.note_masks, [0b0010]);
    assert_eq!(rows.hold_masks, [0]);
    assert_eq!(rows.prev_row_live_holds, [0]);
    assert_eq!(rows.row_seconds, [0.5]);
    assert_eq!(rows.row_ms, [500]);
}

#[test]
fn collapses_same_second_hold_rows_like_rssp_counter() {
    let rows = step_parity_prepare_hold_rows_4(
        b"2000\n0100\n3000\n;\n",
        &[0.0, 0.0, 1.0],
        &[0, 0, 1000],
        &[0.0, 0.5, 1.0],
    )
    .unwrap();

    assert_eq!(rows.note_counts, [2]);
    assert_eq!(rows.tech_masks, [0b0011]);
    assert_eq!(rows.note_masks, [0b0011]);
    assert_eq!(rows.hold_masks, [0]);
    assert_eq!(rows.prev_row_live_holds, [0]);
    assert_eq!(rows.row_seconds, [0.0]);
    assert_eq!(rows.row_ms, [0]);
}

#[test]
fn counts_hold_prepared_rows_after_step_parity_backtracking() {
    let rows = step_parity_prepare_hold_rows_4(
        b"2000\n0100\n3100\n1000\n;\n",
        &[0.0, 0.5, 1.0, 1.5],
        &[0, 500, 1000, 1500],
        &[0.0, 0.5, 1.0, 1.5],
    )
    .unwrap();
    let placements = expected_place_rows(
        &rows.note_counts,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
    );
    let expected = placement_counts(
        &rows.tech_masks,
        &rows.note_counts,
        &rows.row_ms,
        &placements,
    );

    let actual = step_parity_count_prepared_rows_4(
        &rows.note_counts,
        &rows.tech_masks,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        &rows.row_ms,
        256,
    )
    .unwrap();

    assert_eq!(actual, expected);
}

#[test]
fn counts_double_prepared_rows_after_step_parity_backtracking() {
    let note_masks = [0b0001_0000u8, 0b0010_0000, 0b0001_0000, 0b0101_0000];
    let tech_masks = note_masks;
    let note_counts = note_masks.map(|mask| mask.count_ones() as u8);
    let hold_masks = [0u8; 4];
    let mine_masks = [0u8, 0, 0b0001_0000, 0];
    let prev_row_live_holds = [0u8; 4];
    let row_seconds = [0.0f32, 0.125, 0.25, 0.5];
    let row_ms = [0, 125, 250, 500];
    let placements = expected_place_rows_8(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
    );
    let expected = placement_counts_8(&tech_masks, &note_counts, &row_ms, &placements);

    let actual = step_parity_count_prepared_rows_8(
        &note_counts,
        &tech_masks,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
        &row_ms,
        256,
    )
    .unwrap();

    assert_eq!(actual, expected);
}

#[test]
fn counts_hold_rows_through_prepare_and_backtrack_wrapper() {
    let data = b"2000\n0100\n3100\n1000\n;\n";
    let seconds = [0.0, 0.5, 1.0, 1.5];
    let row_ms = [0, 500, 1000, 1500];
    let beats = [0.0, 0.5, 1.0, 1.5];
    let rows = step_parity_prepare_hold_rows_4(data, &seconds, &row_ms, &beats).unwrap();
    let expected = step_parity_count_prepared_rows_4(
        &rows.note_counts,
        &rows.tech_masks,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        &rows.row_ms,
        256,
    )
    .unwrap();

    assert_eq!(
        step_parity_count_hold_rows_4(data, &seconds, &row_ms, &beats, 256),
        Some(expected)
    );
}

#[test]
fn counts_double_hold_rows_through_prepare_and_backtrack_wrapper() {
    let data = b"20000000\n00001000\n30001000\n10000000\n;\n";
    let seconds = [0.0, 0.5, 1.0, 1.5];
    let row_ms = [0, 500, 1000, 1500];
    let beats = [0.0, 0.5, 1.0, 1.5];
    let rows = step_parity_prepare_hold_rows_8(data, &seconds, &row_ms, &beats).unwrap();
    let expected = step_parity_count_prepared_rows_8(
        &rows.note_counts,
        &rows.tech_masks,
        &rows.note_masks,
        &rows.hold_masks,
        &rows.mine_masks,
        &rows.prev_row_live_holds,
        &rows.row_seconds,
        &rows.row_ms,
        256,
    )
    .unwrap();

    assert_eq!(
        step_parity_count_hold_rows_8(data, &seconds, &row_ms, &beats, 256),
        Some(expected)
    );
}

#[test]
fn bpm_only_fixture_step_parity_counts_match_rssp_core() {
    for (data, charts) in [
        (
            include_bytes!("../fixtures/200000_step_challenge.sm").as_slice(),
            0..5,
        ),
        (
            include_bytes!("../fixtures/camellia_mix.ssc").as_slice(),
            0..5,
        ),
    ] {
        for chart_idx in charts {
            assert_bpm_only_fixture_step_parity(data, chart_idx);
        }
    }
}

#[test]
fn timing_event_step_parity_counts_match_rssp_core() {
    let data = b"1000
1000
0100
0100
0011
0000
0001
0001
,
2000
0100
3000
0000
1000
1000
0011
0000
";
    let minimized = minimize_chart_4(data).unwrap();
    let timing = rssp_core::timing::timing_data_from_chart_data(
        0.0,
        0.0,
        Some("0.000=120.000"),
        "",
        Some("0.500=0.500"),
        "",
        Some("5.000=0.250"),
        "",
        None,
        "",
        None,
        "",
        None,
        "",
        None,
        "",
        rssp_core::timing::TimingFormat::Ssc,
        false,
    );

    assert_timing_step_parity_counts(&minimized, &timing, "synthetic timing events");
}

#[test]
fn rejects_unsupported_rows_in_tap_row_preparer() {
    assert!(step_parity_prepare_tap_rows_4(b"2000\n;\n", &[0.0], &[0]).is_none());
    assert!(step_parity_prepare_tap_rows_4(b"1000\n;\n", &[], &[]).is_none());
}

#[test]
fn counts_prepared_rows_after_step_parity_backtracking() {
    let note_masks = [0b0001u8, 0b0001];
    let tech_masks = note_masks;
    let note_counts = note_masks.map(|mask| mask.count_ones() as u8);
    let hold_masks = [0u8; 2];
    let mine_masks = [0u8; 2];
    let prev_row_live_holds = [0u8; 2];
    let row_seconds = [0.0f32, 0.125];
    let row_ms = [0, 125];
    let placements = expected_place_rows(
        &note_counts,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
    );
    let expected = placement_counts(&tech_masks, &note_counts, &row_ms, &placements);

    let actual = step_parity_count_prepared_rows_4(
        &note_counts,
        &tech_masks,
        &note_masks,
        &hold_masks,
        &mine_masks,
        &prev_row_live_holds,
        &row_seconds,
        &row_ms,
        256,
    )
    .unwrap();

    assert_ne!(expected, TechCounts::default());
    assert_eq!(actual, expected);
}

#[test]
fn calculates_action_flags_like_rssp_cost_prelude() {
    let cases = [
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [1, 0, 0, 0],
            0b0001,
            0,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 3, 0],
                moved_mask: 0b0101,
                ..StepParityState4::default()
            },
            [1, 0, 3, 0],
            0b0101,
            0,
        ),
        (
            StepParityState4 {
                combined_columns: [0, 0, 3, 0],
                moved_mask: 0b0100,
                holding_mask: 0b0100,
                ..StepParityState4::default()
            },
            [0, 0, 3, 0],
            0b0100,
            0b0100,
        ),
        (
            StepParityState4 {
                combined_columns: [0, 0, 3, 0],
                moved_mask: 0b0100,
                ..StepParityState4::default()
            },
            [0, 0, 3, 0],
            0b0100,
            0,
        ),
    ];

    for (initial, placement, active_mask, hold_mask) in cases {
        let (result, hit, _) = if hold_mask == 0 {
            step_parity_result_state_no_holds_4(&initial, &placement, active_mask).unwrap()
        } else {
            step_parity_result_state_holds_4(&initial, &placement, active_mask, hold_mask).unwrap()
        };
        assert_eq!(
            step_parity_action_flags_4(&initial, &result, &hit).unwrap(),
            expected_action_flags(initial, result, hit)
        );
    }
}

#[test]
fn calculates_double_action_flags_like_rssp_cost_prelude() {
    let cases = [
        (
            StepParityState8 {
                combined_columns: [1, 0, 0, 0, 0, 0, 0, 0],
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [1, 0, 0, 0, 0, 0, 0, 0],
            0b0000_0001,
            0,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 0, 3, 0],
                moved_mask: 0b0100,
                holding_mask: 0b0100,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 0, 0, 3, 0],
            0b0100_0000,
            0b0100_0000,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 0, 3, 0],
                moved_mask: 0b0100,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 0, 0, 3, 0],
            0b0100_0000,
            0,
        ),
    ];

    for (initial, placement, active_mask, hold_mask) in cases {
        let (result, hit, _) = if hold_mask == 0 {
            step_parity_result_state_no_holds_8(&initial, &placement, active_mask).unwrap()
        } else {
            step_parity_result_state_holds_8(&initial, &placement, active_mask, hold_mask).unwrap()
        };
        assert_eq!(
            step_parity_action_flags_8(&initial, &result, &hit).unwrap(),
            expected_action_flags_8(initial, result, hit)
        );
    }
}

#[test]
fn calculates_basic_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState4 {
                occupied_mask: 0b0001,
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            false,
            0b0001,
            false,
        ),
        (
            StepParityState4 {
                moved_mask: 0b0011,
                ..StepParityState4::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                jacked_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            true,
            0,
            false,
        ),
        (
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            false,
            0,
            false,
        ),
        (
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            false,
            0,
            true,
        ),
        (
            StepParityState4 {
                occupied_mask: 0b0100,
                moved_mask: 0b1100,
                ..StepParityState4::default()
            },
            StepParityActionFlags4 {
                moved_right: 1,
                jacked_right: 1,
                right_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            true,
            0b0100,
            false,
        ),
    ];

    for (result, flags, multi_active, mine_mask, prev_live_hold) in cases {
        assert_eq!(
            step_parity_basic_action_costs_4(
                &result,
                &flags,
                multi_active,
                mine_mask,
                prev_live_hold
            )
            .unwrap(),
            expected_basic_costs(result, flags, multi_active, mine_mask, prev_live_hold)
        );
    }
}

#[test]
fn calculates_double_basic_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState8 {
                occupied_mask: 0b0001_0000,
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            false,
            0b0001_0000,
            false,
        ),
        (
            StepParityState8 {
                moved_mask: 0b0011,
                ..StepParityState8::default()
            },
            StepParityActionFlags4 {
                moved_left: 1,
                jacked_left: 1,
                left_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            true,
            0,
            false,
        ),
        (
            StepParityState8 {
                occupied_mask: 0b0100_0000,
                moved_mask: 0b1100,
                ..StepParityState8::default()
            },
            StepParityActionFlags4 {
                moved_right: 1,
                jacked_right: 1,
                right_moved_not_holding: 1,
                ..StepParityActionFlags4::default()
            },
            true,
            0b0100_0000,
            false,
        ),
    ];

    for (result, flags, multi_active, mine_mask, prev_live_hold) in cases {
        assert_eq!(
            step_parity_basic_action_costs_8(
                &result,
                &flags,
                multi_active,
                mine_mask,
                prev_live_hold
            )
            .unwrap(),
            expected_basic_costs_8(result, flags, multi_active, mine_mask, prev_live_hold)
        );
    }
}

#[test]
fn calculates_elapsed_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityActionFlags4 {
                moved_left: 1,
                ..StepParityActionFlags4::default()
            },
            2,
            0.25f32,
        ),
        (
            StepParityActionFlags4 {
                moved_left: 1,
                jacked_left: 1,
                ..StepParityActionFlags4::default()
            },
            1,
            0.05f32,
        ),
        (
            StepParityActionFlags4 {
                moved_left: 1,
                moved_right: 1,
                jacked_left: 1,
                ..StepParityActionFlags4::default()
            },
            2,
            0.25f32,
        ),
        (
            StepParityActionFlags4 {
                moved_right: 1,
                jacked_right: 1,
                ..StepParityActionFlags4::default()
            },
            2,
            0.1f32,
        ),
    ];

    for (flags, note_count, elapsed) in cases {
        assert_eq!(
            step_parity_elapsed_action_costs_4(&flags, note_count, elapsed).unwrap(),
            expected_elapsed_costs(flags, note_count, elapsed)
        );
    }
}

#[test]
fn calculates_double_elapsed_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityActionFlags4 {
                moved_left: 1,
                ..StepParityActionFlags4::default()
            },
            2,
            0.25f32,
        ),
        (
            StepParityActionFlags4 {
                moved_left: 1,
                jacked_left: 1,
                ..StepParityActionFlags4::default()
            },
            1,
            0.05f32,
        ),
        (
            StepParityActionFlags4 {
                moved_right: 1,
                jacked_right: 1,
                ..StepParityActionFlags4::default()
            },
            2,
            0.1f32,
        ),
    ];

    for (flags, note_count, elapsed) in cases {
        assert_eq!(
            step_parity_elapsed_action_costs_8(&flags, note_count, elapsed).unwrap(),
            expected_elapsed_costs(flags, note_count, elapsed)
        );
    }
}

#[test]
fn calculates_switch_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                ..StepParityState4::default()
            },
            StepParityState4::default(),
            [3, 0, 0, 0],
            0b0001,
            0,
            0,
            0.3f32,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                ..StepParityState4::default()
            },
            StepParityState4::default(),
            [2, 0, 0, 0],
            0b0001,
            0,
            0,
            0.3f32,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                ..StepParityState4::default()
            },
            StepParityState4::default(),
            [3, 0, 0, 0],
            0b0001,
            0,
            1,
            0.3f32,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                ..StepParityState4::default()
            },
            StepParityState4::default(),
            [3, 0, 0, 0],
            0,
            0b0001,
            0,
            0.125f32,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                ..StepParityState4::default()
            },
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [3, 0, 0, 0],
            0,
            0b0001,
            0,
            0.125f32,
        ),
    ];

    for (initial, result, placement, active_mask, side_mask, mine_mask, elapsed) in cases {
        assert_eq!(
            step_parity_switch_action_costs_4(
                &initial,
                &result,
                &placement,
                active_mask,
                side_mask,
                mine_mask,
                elapsed
            )
            .unwrap(),
            expected_switch_costs(
                initial,
                result,
                placement,
                active_mask,
                side_mask,
                mine_mask,
                elapsed
            )
        );
    }
}

#[test]
fn calculates_double_switch_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 1, 0, 0],
                ..StepParityState8::default()
            },
            StepParityState8::default(),
            [0, 0, 0, 0, 0, 3, 0, 0],
            0b0010_0000,
            0,
            0,
            0.3f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 1, 0, 0],
                ..StepParityState8::default()
            },
            StepParityState8::default(),
            [0, 0, 0, 0, 0, 2, 0, 0],
            0b0010_0000,
            0,
            0,
            0.3f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 1, 0, 0, 0],
                ..StepParityState8::default()
            },
            StepParityState8::default(),
            [0, 0, 0, 0, 3, 0, 0, 0],
            0,
            0b0001_0000,
            0,
            0.125f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 1, 0, 0, 0],
                ..StepParityState8::default()
            },
            StepParityState8 {
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 3, 0, 0, 0],
            0,
            0b0001_0000,
            0,
            0.125f32,
        ),
    ];

    for (initial, result, placement, active_mask, side_mask, mine_mask, elapsed) in cases {
        assert_eq!(
            step_parity_switch_action_costs_8(
                &initial,
                &result,
                &placement,
                active_mask,
                side_mask,
                mine_mask,
                elapsed
            )
            .unwrap(),
            expected_switch_costs_8(
                initial,
                result,
                placement,
                active_mask,
                side_mask,
                mine_mask,
                elapsed
            )
        );
    }
}

#[test]
fn calculates_bracket_tap_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState4::default(),
            [-1, 0, 1, -1, -1],
            0b0001,
            0.25f32,
        ),
        (
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [-1, 0, 1, -1, -1],
            0b0001,
            0.25f32,
        ),
        (
            StepParityState4::default(),
            [-1, -1, -1, 2, 3],
            0b1000,
            0.5f32,
        ),
        (
            StepParityState4::default(),
            [-1, 0, 1, 2, 3],
            0b1010,
            0.5f32,
        ),
        (
            StepParityState4::default(),
            [-1, 0, -1, 2, 3],
            0b0001,
            0.25f32,
        ),
    ];

    for (initial, hit, hold_mask, elapsed) in cases {
        assert_eq!(
            step_parity_bracket_tap_action_costs_4(&initial, &hit, hold_mask, elapsed).unwrap(),
            expected_bracket_tap_costs(initial, hit, hold_mask, elapsed)
        );
    }
}

#[test]
fn calculates_double_bracket_tap_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState8::default(),
            [-1, 4, 5, -1, -1],
            0b0001_0000,
            0.25f32,
        ),
        (
            StepParityState8 {
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [-1, 4, 5, -1, -1],
            0b0001_0000,
            0.25f32,
        ),
        (
            StepParityState8::default(),
            [-1, -1, -1, 6, 7],
            0b1000_0000,
            0.5f32,
        ),
        (
            StepParityState8::default(),
            [-1, 0, 1, 6, 7],
            0b1000_0010,
            0.5f32,
        ),
    ];

    for (initial, hit, hold_mask, elapsed) in cases {
        assert_eq!(
            step_parity_bracket_tap_action_costs_8(&initial, &hit, hold_mask, elapsed).unwrap(),
            expected_bracket_tap_costs_8(initial, hit, hold_mask, elapsed)
        );
    }
}

#[test]
fn calculates_distance_action_cost_terms_like_rssp_core() {
    let missing_prev = StepParityState4 {
        combined_columns: [0, 0, 0, 0],
        where_feet_are: [-1; 5],
        ..StepParityState4::default()
    };
    let foot_on_left = StepParityState4 {
        combined_columns: [3, 0, 0, 0],
        where_feet_are: [-1, -1, -1, 0, -1],
        ..StepParityState4::default()
    };
    let same_side = StepParityState4 {
        combined_columns: [0, 1, 0, 0],
        where_feet_are: [-1, 1, -1, -1, -1],
        ..StepParityState4::default()
    };
    let moved_left = StepParityState4 {
        where_feet_are: [-1, 0, -1, -1, -1],
        ..StepParityState4::default()
    };

    let cases = [
        (
            missing_prev,
            StepParityState4 {
                combined_columns: [0, 3, 0, 0],
                occupied_mask: 0b0010,
                ..StepParityState4::default()
            },
            [-1, -1, -1, 1, -1],
            0b0010,
            0.5f32,
        ),
        (
            foot_on_left,
            StepParityState4 {
                combined_columns: [0, 0, 0, 3],
                occupied_mask: 0b1000,
                ..StepParityState4::default()
            },
            [-1, -1, -1, 3, -1],
            0b1000,
            0.5f32,
        ),
        (
            same_side,
            StepParityState4 {
                combined_columns: [0, 2, 0, 0],
                occupied_mask: 0b0010,
                ..StepParityState4::default()
            },
            [-1, -1, 1, -1, -1],
            0b0010,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [-1, 3, -1, -1, -1],
            0,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [-1, 3, 0, -1, -1],
            0,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState4 {
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [-1, 3, 1, -1, -1],
            0,
            0.5f32,
        ),
    ];

    for (initial, result, hit, hold_mask, elapsed) in cases {
        assert_eq!(
            step_parity_distance_action_costs_4(&initial, &result, &hit, hold_mask, elapsed)
                .unwrap(),
            expected_distance_costs(initial, result, hit, hold_mask, elapsed)
        );
    }
}

#[test]
fn calculates_double_distance_action_cost_terms_like_rssp_core() {
    let missing_prev = StepParityState8 {
        combined_columns: [0; 8],
        where_feet_are: [-1; 5],
        ..StepParityState8::default()
    };
    let foot_on_left = StepParityState8 {
        combined_columns: [0, 0, 0, 0, 3, 0, 0, 0],
        where_feet_are: [-1, -1, -1, 4, -1],
        ..StepParityState8::default()
    };
    let same_side = StepParityState8 {
        combined_columns: [0, 0, 0, 0, 0, 1, 0, 0],
        where_feet_are: [-1, 5, -1, -1, -1],
        ..StepParityState8::default()
    };
    let moved_left = StepParityState8 {
        where_feet_are: [-1, 4, -1, -1, -1],
        ..StepParityState8::default()
    };

    let cases = [
        (
            missing_prev,
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 3, 0, 0],
                occupied_mask: 0b0010_0000,
                ..StepParityState8::default()
            },
            [-1, -1, -1, 5, -1],
            0b0010_0000,
            0.5f32,
        ),
        (
            foot_on_left,
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 0, 0, 3],
                occupied_mask: 0b1000_0000,
                ..StepParityState8::default()
            },
            [-1, -1, -1, 7, -1],
            0b1000_0000,
            0.5f32,
        ),
        (
            same_side,
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 2, 0, 0],
                occupied_mask: 0b0010_0000,
                ..StepParityState8::default()
            },
            [-1, -1, 5, -1, -1],
            0b0010_0000,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState8 {
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [-1, 7, -1, -1, -1],
            0,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState8 {
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [-1, 7, 4, -1, -1],
            0,
            0.5f32,
        ),
        (
            moved_left,
            StepParityState8 {
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [-1, 7, 5, -1, -1],
            0,
            0.5f32,
        ),
    ];

    for (initial, result, hit, hold_mask, elapsed) in cases {
        assert_eq!(
            step_parity_distance_action_costs_8(&initial, &result, &hit, hold_mask, elapsed)
                .unwrap(),
            expected_distance_costs_8(initial, result, hit, hold_mask, elapsed)
        );
    }
}

#[test]
fn calculates_orientation_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState4::default(),
            StepParityState4::default(),
            [-1, 2, 1, 3, -1],
        ),
        (
            StepParityState4::default(),
            StepParityState4::default(),
            [-1, 3, -1, 2, 1],
        ),
        (
            StepParityState4::default(),
            StepParityState4 {
                where_feet_are: [-1, 3, -1, 0, -1],
                ..StepParityState4::default()
            },
            [-1, -1, -1, -1, -1],
        ),
        (
            StepParityState4 {
                where_feet_are: [-1, 3, -1, 1, -1],
                ..StepParityState4::default()
            },
            StepParityState4 {
                where_feet_are: [-1, 3, -1, 2, -1],
                ..StepParityState4::default()
            },
            [-1, -1, -1, -1, -1],
        ),
        (
            StepParityState4::default(),
            StepParityState4::default(),
            [-1, 3, -1, 2, 1],
        ),
    ];

    for (initial, result, hit) in cases {
        assert_eq!(
            step_parity_orientation_action_costs_4(&initial, &result, &hit).unwrap(),
            expected_orientation_costs(initial, result, hit)
        );
    }
}

#[test]
fn calculates_double_orientation_action_cost_terms_like_rssp_core() {
    let cases = [
        (
            StepParityState8::default(),
            StepParityState8::default(),
            [-1, 6, 5, 7, -1],
        ),
        (
            StepParityState8::default(),
            StepParityState8::default(),
            [-1, 6, 5, 0, -1],
        ),
        (
            StepParityState8::default(),
            StepParityState8 {
                where_feet_are: [-1, 7, -1, 0, -1],
                ..StepParityState8::default()
            },
            [-1, -1, -1, -1, -1],
        ),
        (
            StepParityState8 {
                where_feet_are: [-1, 7, -1, 2, -1],
                ..StepParityState8::default()
            },
            StepParityState8 {
                where_feet_are: [-1, 6, -1, 1, -1],
                ..StepParityState8::default()
            },
            [-1, -1, -1, -1, -1],
        ),
        (
            StepParityState8 {
                where_feet_are: [-1, 6, 5, 2, 1],
                ..StepParityState8::default()
            },
            StepParityState8 {
                where_feet_are: [-1, 4, 5, 2, 1],
                ..StepParityState8::default()
            },
            [-1, -1, -1, -1, -1],
        ),
    ];

    for (initial, result, hit) in cases {
        assert_eq!(
            step_parity_orientation_action_costs_8(&initial, &result, &hit).unwrap(),
            expected_orientation_costs_8(initial, result, hit)
        );
    }
}

#[test]
fn calculates_full_action_cost_like_rssp_core_order() {
    let cases = [
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                where_feet_are: [-1, 0, -1, -1, -1],
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [1, 0, 0, 0],
            0b0001,
            0,
            0b0001,
            0,
            false,
            0.05f32,
        ),
        (
            StepParityState4 {
                combined_columns: [1, 0, 0, 0],
                where_feet_are: [-1, 0, -1, -1, -1],
                moved_mask: 0b0001,
                ..StepParityState4::default()
            },
            [3, 0, 0, 0],
            0b0001,
            0,
            0,
            0,
            false,
            0.3f32,
        ),
        (
            StepParityState4 {
                combined_columns: [0, 3, 0, 0],
                where_feet_are: [-1, -1, -1, 1, -1],
                ..StepParityState4::default()
            },
            [0, 1, 0, 0],
            0b0010,
            0b0010,
            0,
            0,
            false,
            0.25f32,
        ),
        (
            StepParityState4 {
                combined_columns: [0, 0, 3, 0],
                where_feet_are: [-1, -1, -1, 2, -1],
                moved_mask: 0b0100,
                ..StepParityState4::default()
            },
            [1, 0, 4, 0],
            0b0101,
            0,
            0b0100,
            0b0001,
            false,
            0.25f32,
        ),
    ];

    for (
        initial,
        placement,
        active_mask,
        hold_mask,
        mine_mask,
        side_mask,
        prev_live_hold,
        elapsed,
    ) in cases
    {
        let (result, hit, _) = if hold_mask == 0 {
            step_parity_result_state_no_holds_4(&initial, &placement, active_mask).unwrap()
        } else {
            step_parity_result_state_holds_4(&initial, &placement, active_mask, hold_mask).unwrap()
        };
        let expected = expected_action_costs(
            initial,
            result,
            placement,
            hit,
            active_mask.count_ones() as u8,
            active_mask,
            hold_mask,
            mine_mask,
            side_mask,
            prev_live_hold,
            elapsed,
        );
        assert_eq!(
            step_parity_action_cost_4(
                &initial,
                &result,
                &placement,
                &hit,
                active_mask.count_ones() as u8,
                active_mask,
                hold_mask,
                mine_mask,
                side_mask,
                prev_live_hold,
                elapsed,
            )
            .unwrap(),
            expected
        );
    }
}

#[test]
fn calculates_double_full_action_cost_like_rssp_core_order() {
    let cases = [
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 1, 0, 0, 0],
                where_feet_are: [-1, 4, -1, -1, -1],
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 1, 0, 0, 0],
            0b0001_0000,
            0,
            0b0001_0000,
            0,
            false,
            0.05f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 1, 0, 0, 0],
                where_feet_are: [-1, 4, -1, -1, -1],
                moved_mask: 0b0001,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 3, 0, 0, 0],
            0b0001_0000,
            0,
            0,
            0,
            false,
            0.3f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 3, 0, 0],
                where_feet_are: [-1, -1, -1, 5, -1],
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 0, 1, 0, 0],
            0b0010_0000,
            0b0010_0000,
            0,
            0,
            false,
            0.25f32,
        ),
        (
            StepParityState8 {
                combined_columns: [0, 0, 0, 0, 0, 0, 3, 0],
                where_feet_are: [-1, -1, -1, 6, -1],
                moved_mask: 0b0100,
                ..StepParityState8::default()
            },
            [0, 0, 0, 0, 1, 0, 4, 0],
            0b0101_0000,
            0,
            0b0100_0000,
            0b0001_0000,
            false,
            0.25f32,
        ),
    ];

    for (
        initial,
        placement,
        active_mask,
        hold_mask,
        mine_mask,
        side_mask,
        prev_live_hold,
        elapsed,
    ) in cases
    {
        let (result, hit, _) = if hold_mask == 0 {
            step_parity_result_state_no_holds_8(&initial, &placement, active_mask).unwrap()
        } else {
            step_parity_result_state_holds_8(&initial, &placement, active_mask, hold_mask).unwrap()
        };
        let expected = expected_action_costs_8(
            initial,
            result,
            placement,
            hit,
            active_mask.count_ones() as u8,
            active_mask,
            hold_mask,
            mine_mask,
            side_mask,
            prev_live_hold,
            elapsed,
        );
        assert_eq!(
            step_parity_action_cost_8(
                &initial,
                &result,
                &placement,
                &hit,
                active_mask.count_ones() as u8,
                active_mask,
                hold_mask,
                mine_mask,
                side_mask,
                prev_live_hold,
                elapsed,
            )
            .unwrap(),
            expected
        );
    }
}

#[test]
fn counts_single_panel_timing_hold_fixture_bracket_like_rssp_core() {
    let data = b"2000\n0000\n0100\n3000\n,\n4000\n0000\n0011\n3000\n";
    let counts = count_step_tech_brackets_minimized_4(data).unwrap();
    assert_brackets_match_rssp(data, 4, counts);
}

#[test]
fn calculates_jacks_and_doublesteps_from_parity_placements() {
    assert_eq!(
        placement_counts(&[1, 1], &[1, 1], &[0, 125], &[[1, 0, 0, 0], [1, 0, 0, 0]]),
        TechCounts {
            jacks: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts(&[1, 2], &[1, 1], &[0, 125], &[[1, 0, 0, 0], [0, 1, 0, 0]]),
        TechCounts {
            doublesteps: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn calculates_switches_from_parity_placements() {
    assert_eq!(
        placement_counts(&[2, 2], &[1, 1], &[0, 125], &[[0, 1, 0, 0], [0, 3, 0, 0]]),
        TechCounts {
            footswitches: 1,
            down_footswitches: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts(&[4, 4], &[1, 1], &[0, 125], &[[0, 0, 1, 0], [0, 0, 3, 0]]),
        TechCounts {
            footswitches: 1,
            up_footswitches: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts(&[1, 1], &[1, 1], &[0, 125], &[[1, 0, 0, 0], [3, 0, 0, 0]]),
        TechCounts {
            sideswitches: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn calculates_brackets_and_crossovers_from_parity_placements() {
    assert_eq!(
        placement_counts(&[1, 3], &[1, 2], &[0, 125], &[[1, 0, 0, 0], [1, 2, 0, 0]]),
        TechCounts {
            brackets: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts(&[8, 1], &[1, 1], &[0, 125], &[[0, 0, 0, 1], [3, 0, 0, 0]]),
        TechCounts {
            crossovers: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn calculates_double_jacks_and_doublesteps_from_parity_placements() {
    assert_eq!(
        placement_counts_8(
            &[32, 32],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 1, 0, 0]],
        ),
        TechCounts {
            jacks: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts_8(
            &[32, 64],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 0, 1, 0]],
        ),
        TechCounts {
            doublesteps: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn calculates_double_switches_from_parity_placements() {
    assert_eq!(
        placement_counts_8(
            &[32, 32],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 3, 0, 0]],
        ),
        TechCounts {
            footswitches: 1,
            down_footswitches: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts_8(
            &[64, 64],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0, 3, 0]],
        ),
        TechCounts {
            footswitches: 1,
            up_footswitches: 1,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts_8(
            &[128, 128],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 0, 0, 0, 1], [0, 0, 0, 0, 0, 0, 0, 3]],
        ),
        TechCounts {
            sideswitches: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn calculates_double_brackets_and_crossovers_from_parity_placements() {
    assert_eq!(
        placement_counts_8(
            &[0, 195],
            &[0, 4],
            &[0, 125],
            &[[0; 8], [1, 2, 0, 0, 0, 0, 3, 4]],
        ),
        TechCounts {
            brackets: 2,
            ..TechCounts::default()
        }
    );

    assert_eq!(
        placement_counts_8(
            &[16, 4],
            &[1, 1],
            &[0, 125],
            &[[0, 0, 0, 0, 1, 0, 0, 0], [0, 0, 3, 0, 0, 0, 0, 0]],
        ),
        TechCounts {
            crossovers: 1,
            ..TechCounts::default()
        }
    );
}

#[test]
fn skips_single_panel_first_row_brackets_like_rssp_core() {
    let counts = count_step_tech_brackets_minimized_4(b"0011\n").unwrap();
    assert_only_brackets(counts, 0);
}

#[test]
fn skips_single_panel_no_hold_bracketable_jump_like_rssp_core() {
    let data = b"1000\n0011\n";
    let counts = count_step_tech_brackets_minimized_4(data).unwrap();
    assert_brackets_match_rssp(data, 4, counts);
}

#[test]
fn skips_double_panel_no_hold_bracketable_jump_like_rssp_core() {
    let data = b"10000000\n00000000\n00000001\n00000000\n,\n00000000\n00110000\n0000000M\n";
    let counts = count_step_tech_brackets_minimized_8(data).unwrap();
    assert_brackets_match_rssp(data, 8, counts);
}

#[test]
fn counts_double_panel_timing_hold_fixture_bracket_like_rssp_core() {
    let data =
        b"20000000\n00000000\n01000000\n30000000\n,\n00004000\n00000000\n00110000\n00003000\n";
    let counts = count_step_tech_brackets_minimized_8(data).unwrap();
    assert_brackets_match_rssp(data, 8, counts);
}
