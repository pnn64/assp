use assp::{
    NoteStats, count_note_stats_minimized_4, count_note_stats_minimized_8, find_chart_by_index,
};
use rssp_core::stats::minimize_chart_and_count_with_lanes;

fn minimized_row_count(data: &[u8], lanes: usize) -> u64 {
    data.split(|&b| b == b'\n')
        .filter(|line| line.len() >= lanes && line[0] != b',' && line[0] != b';')
        .count() as u64
}

fn assert_stats_match_rssp(data: &[u8], lanes: usize) {
    let asm = if lanes == 8 {
        count_note_stats_minimized_8(data).unwrap()
    } else {
        count_note_stats_minimized_4(data).unwrap()
    };
    let (minimized, rust, _) = minimize_chart_and_count_with_lanes(data, lanes);

    assert_eq!(
        asm,
        NoteStats {
            rows: minimized_row_count(&minimized, lanes),
            steps: u64::from(rust.total_steps),
            arrows: u64::from(rust.total_arrows),
            jumps: u64::from(rust.jumps),
            hands: u64::from(rust.hands),
            holds: u64::from(rust.holds),
            rolls: u64::from(rust.rolls),
            mines: u64::from(rust.mines),
            lifts: u64::from(rust.lifts),
            fakes: u64::from(rust.fakes),
            left: u64::from(rust.left),
            down: u64::from(rust.down),
            up: u64::from(rust.up),
            right: u64::from(rust.right),
            malformed_rows: 0,
        }
    );
}

#[test]
fn simple_counts_match_rssp_core() {
    assert_stats_match_rssp(
        b"
0000
1000
0100
0011
MM00
,
2000
0000
3000
0004
0003
L00F
;
",
        4,
    );
}

#[test]
fn active_hold_hands_match_rssp_core() {
    assert_stats_match_rssp(
        b"
2200
0010
3330
;
",
        4,
    );
}

#[test]
fn phantom_holds_match_rssp_core() {
    assert_stats_match_rssp(
        b"
2000
1000
3000
,
0400
0000
;
",
        4,
    );
}

#[test]
fn simple_8_panel_counts_match_rssp_core() {
    assert_stats_match_rssp(
        b"
00000000
10000001
01001000
00110010
MM000000
,
20000004
00000000
30000003
00040000
00030000
L00F0000
;
",
        8,
    );
}

#[test]
fn active_8_panel_hold_hands_match_rssp_core() {
    assert_stats_match_rssp(
        b"
22000000
00100001
33300000
;
",
        8,
    );
}

#[test]
fn phantom_8_panel_holds_match_rssp_core() {
    assert_stats_match_rssp(
        b"
20000000
10000000
30000000
,
00004000
00000000
;
",
        8,
    );
}

#[test]
fn sm_fixture_chart_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 0).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    assert_stats_match_rssp(notes, 4);
}
