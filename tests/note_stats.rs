use assp::{
    ByteSlice, NoteStats, count_mines_nonfake_4, count_mines_nonfake_8, count_note_stats_4,
    count_note_stats_8, count_note_stats_minimized_4, count_timing_fakes_4, count_timing_fakes_8,
    count_timing_note_stats_no_holds_4, find_chart_by_index, find_chart_timing_tags_by_index,
    parse_bpm_map,
};
use rssp_core::{
    bpm,
    stats::{compute_timing_aware_stats, minimize_chart_for_hash},
    timing::{TimingFormat, timing_data_from_chart_data},
};

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn tag_str(data: &[u8], slice: ByteSlice) -> Option<&str> {
    if slice.data.is_null() {
        None
    } else {
        std::str::from_utf8(slice_from(data, slice.data, slice.len)).ok()
    }
}

fn minimized_row_count(data: &[u8]) -> u64 {
    minimize_chart_for_hash(data, 4)
        .split(|&b| b == b'\n')
        .filter(|line| line.len() >= 4 && line[0] != b',' && line[0] != b';')
        .count() as u64
}

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
fn counts_basic_8_panel_note_rows() {
    let stats = count_note_stats_8(
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
    )
    .unwrap();

    assert_eq!(
        stats,
        NoteStats {
            rows: 11,
            steps: 5,
            arrows: 10,
            jumps: 4,
            hands: 1,
            holds: 1,
            rolls: 2,
            mines: 2,
            lifts: 1,
            fakes: 1,
            left: 3,
            down: 1,
            up: 2,
            right: 4,
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
fn counts_minimized_note_rows_when_requested() {
    let raw = count_note_stats_4(
        b"
1000
0000
0100
0000
;
",
    )
    .unwrap();
    let minimized = count_note_stats_minimized_4(
        b"
1000
0000
0100
0000
;
",
    )
    .unwrap();

    assert_eq!(raw.rows, 4);
    assert_eq!(minimized.rows, 2);
    assert_eq!(minimized.steps, 2);
    assert_eq!(minimized.arrows, 2);
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

#[test]
fn counts_8_panel_nonfake_mines_after_measure_minimization() {
    let data = b"
10000000
00000000
0000M000
00000000
,
0000000m
00000000
M0000000
00000000
;
";
    let warps = b"2=1";
    let fakes = b"4=0.5";
    let asm_warps = parse_bpm_map(warps).unwrap();
    let asm_fakes = parse_bpm_map(fakes).unwrap();
    let rust_warps = bpm::parse_bpm_map(std::str::from_utf8(warps).unwrap());
    let rust_fakes = bpm::parse_bpm_map(std::str::from_utf8(fakes).unwrap());

    assert_eq!(
        count_mines_nonfake_8(data, &asm_warps, &asm_fakes).unwrap(),
        u64::from(bpm::compute_mines_nonfake(
            data,
            8,
            &rust_warps,
            &rust_fakes
        ))
    );
    assert_eq!(count_mines_nonfake_8(data, &asm_warps, &asm_fakes), Some(1));
}

#[test]
fn counts_timing_fakes_after_measure_minimization() {
    let data = b"
1000
0000
M0F0
0000
,
F000
0000
0010
0000
;
";
    let warps = parse_bpm_map(b"2=1").unwrap();
    let fakes = parse_bpm_map(b"6=0.5").unwrap();

    assert_eq!(count_timing_fakes_4(data, &[], &[]), Some(2));
    assert_eq!(count_timing_fakes_4(data, &warps, &fakes), Some(4));
}

#[test]
fn counts_8_panel_timing_fakes_after_measure_minimization() {
    let data = b"
10000000
00000000
M000F000
00000000
,
F0000001
00000000
00001000
00000000
;
";
    let warps = parse_bpm_map(b"2=1").unwrap();
    let fakes = parse_bpm_map(b"6=0.5").unwrap();

    let timing = timing_data_from_chart_data(
        0.0,
        0.0,
        Some("0=120"),
        "0=120",
        None,
        "",
        None,
        "",
        Some("2=1"),
        "",
        None,
        "",
        None,
        "",
        Some("6=0.5"),
        "",
        TimingFormat::Ssc,
        false,
    );
    let rust = compute_timing_aware_stats(data, 8, &timing);

    assert_eq!(count_timing_fakes_8(data, &[], &[]), Some(2));
    assert_eq!(
        count_timing_fakes_8(data, &warps, &fakes).unwrap(),
        u64::from(rust.fakes)
    );
    assert_eq!(count_timing_fakes_8(data, &warps, &fakes), Some(4));
}

#[test]
fn fixture_timing_fakes_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/timing_fakes.ssc");
    let chart = find_chart_by_index(simfile, 0).unwrap();
    let notes = slice_from(simfile, chart.note_data, chart.note_data_len);
    let tags = find_chart_timing_tags_by_index(simfile, 0).unwrap();

    let warps = parse_bpm_map(tag_str(simfile, tags.warps).unwrap().as_bytes()).unwrap();
    let fakes = parse_bpm_map(tag_str(simfile, tags.fakes).unwrap().as_bytes()).unwrap();
    let asm = count_timing_fakes_4(notes, &warps, &fakes).unwrap();
    let asm_stats = count_timing_note_stats_no_holds_4(notes, &warps, &fakes).unwrap();

    let timing = timing_data_from_chart_data(
        0.0,
        0.0,
        tag_str(simfile, tags.bpms),
        "0=120",
        tag_str(simfile, tags.stops),
        "",
        tag_str(simfile, tags.delays),
        "",
        tag_str(simfile, tags.warps),
        "",
        tag_str(simfile, tags.speeds),
        "",
        tag_str(simfile, tags.scrolls),
        "",
        tag_str(simfile, tags.fakes),
        "",
        TimingFormat::Ssc,
        false,
    );
    let rust = compute_timing_aware_stats(notes, 4, &timing);

    assert_eq!(asm, u64::from(rust.fakes));
    assert_eq!(asm, 4);
    assert_eq!(
        asm_stats,
        NoteStats {
            rows: minimized_row_count(notes),
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
    assert_eq!(asm_stats.steps, 1);
    assert_eq!(asm_stats.arrows, 1);
    assert_eq!(asm_stats.mines, 0);
    assert_eq!(asm_stats.fakes, 4);
}
