use assp::{
    StepParityActionFlags4, StepParityState4, TechCounts,
    calculate_step_tech_counts_from_placements_4, count_step_tech_brackets_minimized_4,
    count_step_tech_brackets_minimized_8, parse_tech_notation, step_parity_action_flags_4,
    step_parity_permutations_4, step_parity_result_state_holds_4,
    step_parity_result_state_no_holds_4, step_parity_row_key_candidates_4,
    step_parity_row_transitions_4,
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

    let note_mask = 0b0101;
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
