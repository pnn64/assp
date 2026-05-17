use assp::{find_chart_by_index, measure_densities_4, stream_segments_from_densities};
use rssp_core::stats::stream_sequences;

fn assert_stream_segments_match(densities: &[u32]) {
    let asm: Vec<_> = stream_segments_from_densities(densities)
        .into_iter()
        .map(|s| (s.start, s.end, s.is_break != 0))
        .collect();
    let dens_usize: Vec<usize> = densities.iter().map(|&d| d as usize).collect();
    let rust: Vec<_> = stream_sequences(&dens_usize)
        .into_iter()
        .map(|s| (s.start, s.end, s.is_break))
        .collect();

    assert_eq!(asm, rust);
}

#[test]
fn synthetic_stream_segments_match_rssp_core() {
    assert_stream_segments_match(&[0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0]);
}

#[test]
fn empty_stream_segments_match_rssp_core() {
    assert_stream_segments_match(&[]);
    assert_stream_segments_match(&[0, 4, 8, 12]);
}

#[test]
fn ssc_fixture_stream_segments_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_segments_match(&densities);
}

#[test]
fn sm_fixture_stream_segments_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_segments_match(&densities);
}
