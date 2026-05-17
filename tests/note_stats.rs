use assp::{NoteStats, count_mines_nonfake_4, count_note_stats_4, parse_bpm_map};
use rssp_core::bpm;

#[test]
fn counts_basic_4_panel_note_rows() {
    let stats = count_note_stats_4(
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
    )
    .unwrap();

    assert_eq!(
        stats,
        NoteStats {
            rows: 11,
            steps: 5,
            arrows: 6,
            jumps: 1,
            hands: 0,
            holds: 1,
            rolls: 1,
            mines: 2,
            lifts: 1,
            fakes: 1,
            left: 2,
            down: 1,
            up: 1,
            right: 2,
            malformed_rows: 0,
        }
    );
}

#[test]
fn counts_hands_with_active_holds() {
    let stats = count_note_stats_4(
        b"
2200
0010
3330
;
",
    )
    .unwrap();

    assert_eq!(stats.rows, 3);
    assert_eq!(stats.steps, 2);
    assert_eq!(stats.arrows, 3);
    assert_eq!(stats.holds, 2);
    assert_eq!(stats.hands, 1);
}

#[test]
fn reports_short_nonempty_rows_as_malformed() {
    let stats = count_note_stats_4(b"100\n0000\n;").unwrap();

    assert_eq!(stats.rows, 1);
    assert_eq!(stats.malformed_rows, 1);
}

#[test]
fn counts_nonfake_mines_after_measure_minimization() {
    let data = b"
1000
0000
M000
0000
,
m000
0000
M000
0000
;
";
    let warps = b"2=1";
    let fakes = b"4=0.5";
    let asm_warps = parse_bpm_map(warps).unwrap();
    let asm_fakes = parse_bpm_map(fakes).unwrap();
    let rust_warps = bpm::parse_bpm_map(std::str::from_utf8(warps).unwrap());
    let rust_fakes = bpm::parse_bpm_map(std::str::from_utf8(fakes).unwrap());

    assert_eq!(
        count_mines_nonfake_4(data, &asm_warps, &asm_fakes).unwrap(),
        u64::from(bpm::compute_mines_nonfake(
            data,
            4,
            &rust_warps,
            &rust_fakes
        ))
    );
    assert_eq!(count_mines_nonfake_4(data, &asm_warps, &asm_fakes), Some(1));
}
