use assp::{
    STREAM_TOKEN_BREAK, STREAM_TOKEN_RUN16, STREAM_TOKEN_RUN20, STREAM_TOKEN_RUN24,
    STREAM_TOKEN_RUN32, find_chart_by_index, measure_densities_4, stream_tokens_from_densities,
};
use rssp_core::stats::{RunDensity, categorize_measure_density};

fn expected_tokens(densities: &[u32]) -> Vec<(u32, usize)> {
    let dens: Vec<usize> = densities.iter().map(|&d| d as usize).collect();
    let Some(start) = dens.iter().position(|&d| d >= 16) else {
        return Vec::new();
    };
    let end = dens.iter().rposition(|&d| d >= 16).unwrap();
    let mut out = Vec::new();
    let mut cur = token_kind(categorize_measure_density(dens[start]));
    let mut len = 1usize;

    if start < end {
        for &density in &dens[start + 1..=end] {
            let next = token_kind(categorize_measure_density(density));
            if next == cur {
                len += 1;
            } else {
                out.push((cur, len));
                cur = next;
                len = 1;
            }
        }
    }
    out.push((cur, len));
    out
}

fn token_kind(kind: RunDensity) -> u32 {
    match kind {
        RunDensity::Run32 => STREAM_TOKEN_RUN32,
        RunDensity::Run24 => STREAM_TOKEN_RUN24,
        RunDensity::Run20 => STREAM_TOKEN_RUN20,
        RunDensity::Run16 => STREAM_TOKEN_RUN16,
        RunDensity::Break => STREAM_TOKEN_BREAK,
    }
}

fn assert_stream_tokens_match(densities: &[u32]) {
    let asm: Vec<_> = stream_tokens_from_densities(densities)
        .into_iter()
        .map(|t| (t.kind, t.len))
        .collect();

    assert_eq!(asm, expected_tokens(densities));
}

#[test]
fn synthetic_stream_tokens_match_rssp_core() {
    assert_stream_tokens_match(&[0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0]);
}

#[test]
fn empty_stream_tokens_match_rssp_core() {
    assert_stream_tokens_match(&[]);
    assert_stream_tokens_match(&[0, 4, 8, 12]);
}

#[test]
fn ssc_fixture_stream_tokens_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_tokens_match(&densities);
}

#[test]
fn sm_fixture_stream_tokens_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let densities = measure_densities_4(notes);

    assert_stream_tokens_match(&densities);
}
