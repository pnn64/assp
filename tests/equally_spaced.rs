use assp::{
    find_chart_by_index, measure_equally_spaced_4, measure_equally_spaced_8,
    measure_equally_spaced_minimized_4, measure_equally_spaced_minimized_8, minimize_chart_4,
    minimize_chart_8,
};
use rssp_core::nps;

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn assert_equally_spaced_4(data: &[u8]) {
    let expected = nps::measure_equally_spaced(data, 4);
    assert_eq!(measure_equally_spaced_4(data).unwrap(), expected);

    let minimized = minimize_chart_4(data).unwrap();
    assert_eq!(measure_equally_spaced_minimized_4(&minimized), expected);
}

fn assert_equally_spaced_8(data: &[u8]) {
    let expected = nps::measure_equally_spaced(data, 8);
    assert_eq!(measure_equally_spaced_8(data).unwrap(), expected);

    let minimized = minimize_chart_8(data).unwrap();
    assert_eq!(measure_equally_spaced_minimized_8(&minimized), expected);
}

#[test]
fn synthetic_4_panel_spacing_matches_rssp_core() {
    assert_equally_spaced_4(b"");
    assert_equally_spaced_4(
        b"
1000
0100
0010
0001
;
",
    );
    assert_equally_spaced_4(
        b"
1000
0000
0100
0000
,
1000
0100
0010
0001
;
",
    );
    assert_equally_spaced_4(
        b"
0000
0000
1000
0000
,
0000
0000
0010
0000
;
",
    );
}

#[test]
fn synthetic_8_panel_spacing_matches_rssp_core() {
    assert_equally_spaced_8(
        b"
10000000
01000000
00100000
00010000
;
",
    );
    assert_equally_spaced_8(
        b"
10000000
00000000
00001000
00000000
,
10000000
01000000
00100000
00010000
;
",
    );
    assert_equally_spaced_8(
        b"
00000000
00000000
10000000
00000000
,
00000000
00000000
00000001
00000000
;
",
    );
}

#[test]
fn fixture_spacing_matches_rssp_core() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let chart = find_chart_by_index(camellia, 4).unwrap();
    let note_data = slice_from(camellia, chart.note_data, chart.note_data_len);
    assert_equally_spaced_4(note_data);

    let sm = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let chart = find_chart_by_index(sm, 4).unwrap();
    let note_data = slice_from(sm, chart.note_data, chart.note_data_len);
    assert_equally_spaced_4(note_data);

    let double = include_bytes!("../fixtures/dance_double_timing_holds.ssc").as_slice();
    let chart = find_chart_by_index(double, 0).unwrap();
    let note_data = slice_from(double, chart.note_data, chart.note_data_len);
    assert_equally_spaced_8(note_data);
}
