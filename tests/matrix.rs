use assp::{
    find_bpms_for_chart, find_chart_by_index, matrix_rating_centi, measure_densities_4,
    parse_bpm_map,
};
use rssp_core::{bpm, math, matrix};

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn rust_matrix_centi(densities: &[u32], bpms: &[u8]) -> i64 {
    let densities: Vec<_> = densities.iter().map(|&v| v as usize).collect();
    let bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    let rating = math::round_dp(matrix::compute_matrix_rating(&densities, &bpms), 2);
    (rating * 100.0).round_ties_even() as i64
}

fn assert_matrix_match(densities: &[u32], bpms: &[u8]) {
    let parsed = parse_bpm_map(bpms).unwrap();
    assert_eq!(
        matrix_rating_centi(densities, &parsed),
        rust_matrix_centi(densities, bpms),
        "densities={densities:?} bpms={}",
        std::str::from_utf8(bpms).unwrap()
    );
}

#[test]
fn handles_empty_matrix_inputs() {
    assert_matrix_match(&[], b"0=120");
    assert_eq!(matrix_rating_centi(&[16, 16], &[]), 0);
}

#[test]
fn computes_fixed_bpm_matrix_rating_like_rssp_core() {
    assert_matrix_match(&[16, 16, 16, 16], b"0=120");
    assert_matrix_match(&[16, 16, 16, 16, 16, 16, 16, 16], b"0=120");
    assert_matrix_match(&[20, 20, 20, 20, 20], b"0=120");
    assert_matrix_match(&[24, 24, 24, 24, 24, 24], b"0=180");
    assert_matrix_match(&[32, 32, 32, 32, 32, 32, 32, 32], b"0=240");
    assert_matrix_match(&[0, 4, 8, 12], b"0=120");
}

#[test]
fn computes_variable_bpm_matrix_rating_like_rssp_core() {
    assert_matrix_match(
        &[16, 16, 20, 20, 24, 24, 32, 32, 16, 20, 24, 32],
        b"0=120,8=240",
    );
    assert_matrix_match(
        &[16, 16, 16, 16, 20, 20, 20, 20, 32, 32, 32, 32],
        b"0=120,4=150,8=120",
    );
    assert_matrix_match(&[16, 16, 16, 16, 16], b"0=79.5");
    assert_matrix_match(&[16, 16, 16, 16, 16], b"0=500.5");
    assert_matrix_match(&[16, 16, 16, 16, 16], b"0=120.5");
}

#[test]
fn fixture_matrix_rating_matches_rssp_core() {
    for simfile in [
        include_bytes!("../fixtures/camellia_mix.ssc").as_slice(),
        include_bytes!("../fixtures/200000_step_challenge.sm").as_slice(),
    ] {
        let chart = find_chart_by_index(simfile, 4).unwrap();
        let note_data = slice_from(simfile, chart.note_data, chart.note_data_len);
        let densities = measure_densities_4(note_data);
        let bpms = find_bpms_for_chart(simfile, 4).unwrap();
        let bpms = slice_from(simfile, bpms.data, bpms.len);

        assert_matrix_match(&densities, bpms);
    }
}
