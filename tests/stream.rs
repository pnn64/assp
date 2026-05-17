use assp::{
    StreamCounts as AsmStreamCounts, find_chart_by_index, measure_densities_4,
    stream_counts_from_densities,
};
use rssp_core::stats::compute_stream_counts;

fn assert_stream_counts_match(densities: &[u32]) {
    let asm = stream_counts_from_densities(densities).unwrap();
    let dens_usize: Vec<usize> = densities.iter().map(|&d| d as usize).collect();
    let rust = compute_stream_counts(&dens_usize);

    assert_eq!(
        asm,
        AsmStreamCounts {
            run16_streams: u64::from(rust.run16_streams),
            run20_streams: u64::from(rust.run20_streams),
            run24_streams: u64::from(rust.run24_streams),
            run32_streams: u64::from(rust.run32_streams),
            total_breaks: u64::from(rust.total_breaks),
            sn_breaks: u64::from(rust.sn_breaks),
        }
    );
}

#[test]
fn synthetic_stream_counts_match_rssp_core() {
    assert_stream_counts_match(&[0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0]);
}

#[test]
fn empty_stream_counts_match_rssp_core() {
    assert_stream_counts_match(&[]);
    assert_stream_counts_match(&[0, 4, 8, 12]);
}

#[test]
fn ssc_fixture_stream_counts_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_counts_match(&densities);
}

#[test]
fn sm_fixture_stream_counts_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_counts_match(&densities);
}
