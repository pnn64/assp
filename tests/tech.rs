use assp::{
    StepParityActionCosts4, StepParityActionFlags4, StepParityBasicCosts4,
    StepParityBracketTapCosts4, StepParityDistanceCosts4, StepParityElapsedCosts4,
    StepParityOrientationCosts4, StepParityState4, StepParitySwitchCosts4, TechCounts,
    calculate_step_tech_counts_from_placements_4, count_step_tech_brackets_minimized_4,
    count_step_tech_brackets_minimized_8, parse_tech_notation, step_parity_action_cost_4,
    step_parity_action_flags_4, step_parity_basic_action_costs_4,
    step_parity_bracket_tap_action_costs_4, step_parity_count_prepared_rows_4,
    step_parity_distance_action_costs_4, step_parity_elapsed_action_costs_4,
    step_parity_orientation_action_costs_4, step_parity_permutations_4, step_parity_place_rows_4,
    step_parity_result_state_holds_4, step_parity_result_state_no_holds_4,
    step_parity_row_best_candidates_4, step_parity_row_key_candidates_4,
    step_parity_row_transitions_4, step_parity_switch_action_costs_4,
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

fn expected_place_rows(
    note_counts: &[u8],
    note_masks: &[u8],
    hold_masks: &[u8],
    mine_masks: &[u8],
    prev_row_live_holds: &[u8],
    row_seconds: &[f32],
) -> Vec<[u8; 4]> {
    let mut states = vec![StepParityState4::default()];
    let mut costs = vec![0.0f32];
    let mut prev_second = row_seconds[0] - 1.0;
    let mut backtrack: Vec<Vec<(usize, [u8; 4])>> = Vec::new();

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
                .map(|(pred, _, state, _, _, _)| (*pred as usize, state.combined_columns))
                .collect(),
        );
    }

    let mut idx = costs
        .iter()
        .enumerate()
        .min_by(|(_, a), (_, b)| a.total_cmp(b))
        .map(|(idx, _)| idx)
        .unwrap();
    let mut placements = vec![[0; 4]; note_counts.len()];
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
