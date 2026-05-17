use assp::{find_chart_by_index, measure_densities_4};
use rssp_core::stats::measure_densities;

fn assert_density_match(data: &[u8]) {
    let asm = measure_densities_4(data);
    let rust: Vec<u32> = measure_densities(data, 4)
        .into_iter()
        .map(|v| v as u32)
        .collect();
    assert_eq!(asm, rust);
}

#[test]
fn simple_measure_densities_match_rssp_core() {
    assert_density_match(
        b"
1000
0000
0100
0000
,
0000
0011
000M
;
",
    );
}

#[test]
fn ssc_fixture_density_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    assert_density_match(notes);
}

#[test]
fn sm_fixture_density_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    assert_density_match(notes);
}
