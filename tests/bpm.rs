use assp::{find_bpms_for_chart, normalize_float_digits};
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

#[test]
fn normalizes_decimal_timing_map() {
    assert_normalized(b"");
    assert_normalized(b" 0=140 ");
    assert_normalized(b"0.000000=175.000000");
    assert_normalized(b"1.2345=2.3454, 2.0004=3.0005");
    assert_normalized(b"bad,1=2,3=x,4=5");
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
