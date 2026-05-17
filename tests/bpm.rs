use assp::{
    BpmSegment, bpm_average_centi, bpm_display_range, bpm_median_centi, find_bpms_for_chart,
    normalize_float_digits, parse_bpm_map,
};
use rssp_core::bpm;

fn assert_normalized(input: &[u8]) {
    let asm = normalize_float_digits(input).unwrap();
    let rust = bpm::normalize_float_digits(std::str::from_utf8(input).unwrap());
    assert_eq!(std::str::from_utf8(&asm).unwrap(), rust);
}

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn rust_bpm_segments(input: &[u8]) -> Vec<BpmSegment> {
    bpm::parse_bpm_map(std::str::from_utf8(input).unwrap())
        .into_iter()
        .map(|(beat, bpm)| BpmSegment {
            beat_milli: (beat * 1000.0).round() as i64,
            bpm_milli: (bpm * 1000.0).round() as i64,
        })
        .collect()
}

fn assert_bpm_map(input: &[u8]) {
    assert_eq!(parse_bpm_map(input).unwrap(), rust_bpm_segments(input));
}

fn assert_bpm_range(input: &[u8]) {
    let segments = parse_bpm_map(input).unwrap();
    let rust_map: Vec<_> = segments
        .iter()
        .map(|s| (s.beat_milli as f64 / 1000.0, s.bpm_milli as f64 / 1000.0))
        .collect();
    let rust = bpm::compute_bpm_range(&rust_map);
    assert_eq!(
        bpm_display_range(&segments).unwrap(),
        (i64::from(rust.0), i64::from(rust.1))
    );
}

fn assert_average_bpm(input: &[u8]) {
    let segments = parse_bpm_map(input).unwrap();
    let rust_values: Vec<_> = segments
        .iter()
        .map(|s| s.bpm_milli as f64 / 1000.0)
        .collect();
    let (_, average) = bpm::compute_bpm_stats(&rust_values);
    assert_eq!(
        bpm_average_centi(&segments),
        (average * 100.0).round_ties_even() as i64
    );
}

fn assert_median_bpm(input: &[u8]) {
    let segments = parse_bpm_map(input).unwrap();
    let rust_values: Vec<_> = segments
        .iter()
        .map(|s| s.bpm_milli as f64 / 1000.0)
        .collect();
    let (median, _) = bpm::compute_bpm_stats(&rust_values);
    assert_eq!(
        bpm_median_centi(&segments),
        (median * 100.0).round_ties_even() as i64
    );
}

#[test]
fn normalizes_decimal_timing_map() {
    assert_normalized(b"");
    assert_normalized(b" 0=140 ");
    assert_normalized(b"0.000000=175.000000");
    assert_normalized(b"1.2345=2.3454, 2.0004=3.0005");
    assert_normalized(b"bad,1=2,3=x,4=5");
}

#[test]
fn parses_bpm_map_like_rssp_core() {
    assert_bpm_map(b"");
    assert_bpm_map(b"0=140");
    assert_bpm_map(b"4.000=175.500, 2.000=120.000");
    assert_bpm_map(b"bad,1=2,3=x,4=5");
    assert_bpm_map(b"48r=100.000,96R=200.000");
}

#[test]
fn computes_display_bpm_range_like_rssp_core() {
    assert_bpm_range(b"");
    assert_bpm_range(b"0=140");
    assert_bpm_range(b"0=120.499,4=175.500");
    assert_bpm_range(b"0=120,4=15000,8=-10");
    assert_bpm_range(b"0=12000,4=15000");
    assert_bpm_range(b"0=-10,4=-5");
}

#[test]
fn computes_average_bpm_like_rssp_core() {
    assert_average_bpm(b"");
    assert_average_bpm(b"0=140");
    assert_average_bpm(b"0=120.499,4=175.500");
    assert_average_bpm(b"0=120,4=15000,8=-10");
    assert_average_bpm(b"0=12000,4=15000");
    assert_average_bpm(b"0=-10,4=-5");
    assert_average_bpm(b"0=1.025,4=1.075");
}

#[test]
fn computes_median_bpm_like_rssp_core() {
    assert_median_bpm(b"");
    assert_median_bpm(b"0=140");
    assert_median_bpm(b"0=120.499,4=175.500,8=130.250");
    assert_median_bpm(b"0=120.499,4=175.500");
    assert_median_bpm(b"0=120,4=15000,8=-10");
    assert_median_bpm(b"0=12000,4=15000");
    assert_median_bpm(b"0=-10,4=-5");
    assert_median_bpm(b"0=1.025");
    assert_median_bpm(b"0=1.025,4=1.075");
}

#[test]
fn normalizes_negative_decimal_like_rssp_core() {
    assert_normalized(b"-1.2344=-2.3455,-0.0005=-0.0006");
}

#[test]
fn normalizes_fixture_bpms_for_hash_input() {
    let ssc = include_bytes!("../fixtures/camellia_mix.ssc");
    let sm = include_bytes!("../fixtures/200000_step_challenge.sm");

    let ssc_bpms = find_bpms_for_chart(ssc, 4).unwrap();
    let ssc_raw = slice_from(ssc, ssc_bpms.data, ssc_bpms.len);
    assert_eq!(
        std::str::from_utf8(&normalize_float_digits(ssc_raw).unwrap()).unwrap(),
        "0.000=175.000"
    );

    let sm_bpms = find_bpms_for_chart(sm, 4).unwrap();
    let sm_raw = slice_from(sm, sm_bpms.data, sm_bpms.len);
    assert_eq!(
        std::str::from_utf8(&normalize_float_digits(sm_raw).unwrap()).unwrap(),
        "0.000=140.000"
    );
}

#[test]
fn parses_fixture_bpms_for_timing_input() {
    let ssc = include_bytes!("../fixtures/camellia_mix.ssc");
    let sm = include_bytes!("../fixtures/200000_step_challenge.sm");

    let ssc_bpms = find_bpms_for_chart(ssc, 4).unwrap();
    let ssc_raw = slice_from(ssc, ssc_bpms.data, ssc_bpms.len);
    assert_eq!(
        parse_bpm_map(ssc_raw).unwrap(),
        vec![BpmSegment {
            beat_milli: 0,
            bpm_milli: 175000
        }]
    );

    let sm_bpms = find_bpms_for_chart(sm, 4).unwrap();
    let sm_raw = slice_from(sm, sm_bpms.data, sm_bpms.len);
    assert_eq!(
        parse_bpm_map(sm_raw).unwrap(),
        vec![BpmSegment {
            beat_milli: 0,
            bpm_milli: 140000
        }]
    );
}
