use asmssp::{NoteStats, count_note_stats_4};
use rssp_core::stats::minimize_chart_and_count_with_lanes;

fn assert_stats_match_rssp(data: &[u8]) {
    let asm = count_note_stats_4(data).unwrap();
    let (_, rust, _) = minimize_chart_and_count_with_lanes(data, 4);

    assert_eq!(
        asm,
        NoteStats {
            rows: asm.rows,
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
    );
}
