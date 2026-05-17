use assp::{
    BREAKDOWN_DETAILED, BREAKDOWN_PARTIAL, BREAKDOWN_SIMPLIFIED, find_chart_by_index,
    format_stream_tokens, measure_densities_4, stream_tokens_from_densities,
};
use rssp_core::stats::{BreakdownMode, generate_breakdown};

fn assert_breakdown_match(densities: &[u32]) {
    let tokens = stream_tokens_from_densities(densities);
    let dens_usize: Vec<usize> = densities.iter().map(|&d| d as usize).collect();

    let modes = [
        (BREAKDOWN_DETAILED, BreakdownMode::Detailed),
        (BREAKDOWN_PARTIAL, BreakdownMode::Partial),
        (BREAKDOWN_SIMPLIFIED, BreakdownMode::Simplified),
    ];

    for (asm_mode, rust_mode) in modes {
        let asm = format_stream_tokens(&tokens, asm_mode);
        let asm = std::str::from_utf8(&asm).unwrap();
        let rust = generate_breakdown(&dens_usize, rust_mode);
        assert_eq!(asm, rust);
    }
}

#[test]
fn synthetic_breakdowns_match_rssp_core() {
    assert_breakdown_match(&[0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0]);
    assert_breakdown_match(&[16, 0, 16, 0, 0, 16, 20, 4, 20, 0, 24, 24, 33]);
}

#[test]
fn empty_breakdowns_match_rssp_core() {
    assert_breakdown_match(&[]);
    assert_breakdown_match(&[0, 4, 8, 12]);
}

#[test]
fn ssc_fixture_breakdowns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_breakdown_match(&densities);
}

#[test]
fn sm_fixture_breakdowns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_breakdown_match(&densities);
}
