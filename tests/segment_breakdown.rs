use assp::{
    STREAM_BREAKDOWN_DETAILED, STREAM_BREAKDOWN_PARTIAL, STREAM_BREAKDOWN_SIMPLE,
    STREAM_BREAKDOWN_TOTAL, find_chart_by_index, format_stream_segments, measure_densities_4,
    stream_segments_from_densities,
};
use rssp_core::stats::{StreamBreakdownLevel, stream_breakdown};

fn assert_segment_breakdown_match(densities: &[u32]) {
    let segments = stream_segments_from_densities(densities);
    let dens_usize: Vec<usize> = densities.iter().map(|&d| d as usize).collect();

    let levels = [
        (STREAM_BREAKDOWN_DETAILED, StreamBreakdownLevel::Detailed),
        (STREAM_BREAKDOWN_PARTIAL, StreamBreakdownLevel::Partial),
        (STREAM_BREAKDOWN_SIMPLE, StreamBreakdownLevel::Simple),
        (STREAM_BREAKDOWN_TOTAL, StreamBreakdownLevel::Total),
    ];

    for (asm_level, rust_level) in levels {
        let asm = format_stream_segments(&segments, asm_level);
        let asm = std::str::from_utf8(&asm).unwrap();
        let rust = stream_breakdown(&dens_usize, rust_level);
        assert_eq!(asm, rust);
    }
}

#[test]
fn synthetic_segment_breakdowns_match_rssp_core() {
    assert_segment_breakdown_match(&[0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0]);
    assert_segment_breakdown_match(&[16, 0, 16, 0, 0, 16, 16, 0, 0, 0, 0, 20, 20, 33]);
}

#[test]
fn empty_segment_breakdowns_match_rssp_core() {
    assert_segment_breakdown_match(&[]);
    assert_segment_breakdown_match(&[0, 4, 8, 12]);
}

#[test]
fn ssc_fixture_segment_breakdowns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_segment_breakdown_match(&densities);
}

#[test]
fn sm_fixture_segment_breakdowns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_segment_breakdown_match(&densities);
}
