use assp::{
    StreamCounts as AsmStreamCounts, find_chart_by_index, measure_densities_4,
    stream_counts_from_densities, stream_percentages_centi,
};
use rssp_core::stats::compute_stream_counts;

fn round_percent_centi(value: f64) -> i64 {
    (rssp_core::math::round_dp(value, 2) * 100.0).round_ties_even() as i64
}

fn rust_stream_percentages(counts: &AsmStreamCounts, total_measures: usize) -> (i64, i64, i64) {
    let total_streams =
        counts.run16_streams + counts.run20_streams + counts.run24_streams + counts.run32_streams;
    let total_breaks = counts.total_breaks;
    let adjusted = if total_streams + total_breaks > 0 {
        total_streams as f64 / (total_streams + total_breaks) as f64 * 100.0
    } else {
        0.0
    };
    let stream = if total_measures > 0 {
        total_streams as f64 / total_measures as f64 * 100.0
    } else {
        0.0
    };
    (
        round_percent_centi(stream),
        round_percent_centi(adjusted),
        round_percent_centi(100.0 - adjusted),
    )
}

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
    assert_eq!(
        stream_percentages_centi(&asm, densities.len()).unwrap(),
        rust_stream_percentages(&asm, densities.len())
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
