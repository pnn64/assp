use assp::{
    bpm_at_beat_milli, find_bpms_for_chart, find_chart_by_index, measure_densities_4,
    measure_nps_milli_from_bpms, measure_nps_milli_with_events, nps_median_centi, parse_bpm_map,
    tier_bpm_centi,
};
use rssp_core::{bpm, math, nps};

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn rust_nps_milli(densities: &[u32], bpms: &[u8]) -> Vec<u32> {
    let densities: Vec<usize> = densities.iter().map(|&v| v as usize).collect();
    nps::compute_measure_nps_vec(
        &densities,
        &bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap()),
    )
    .into_iter()
    .map(|v| (v * 1000.0).round() as u32)
    .collect()
}

fn assert_nps_match(densities: &[u32], bpms: &[u8]) {
    let parsed = parse_bpm_map(bpms).unwrap();
    let asm = measure_nps_milli_from_bpms(densities, &parsed).unwrap();
    assert_eq!(asm, rust_nps_milli(densities, bpms));
    assert_nps_median_match(&asm);
}

fn rust_nps_milli_with_events(
    densities: &[u32],
    bpms: &[u8],
    stops: &[u8],
    delays: &[u8],
    warps: &[u8],
) -> Vec<u32> {
    let bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    let stops = bpm::parse_bpm_map(std::str::from_utf8(stops).unwrap());
    let delays = bpm::parse_bpm_map(std::str::from_utf8(delays).unwrap());
    let warps = bpm::parse_bpm_map(std::str::from_utf8(warps).unwrap());
    let mut start = bpm::get_elapsed_time(0.0, &bpms, &stops, &delays, &warps);

    densities
        .iter()
        .enumerate()
        .map(|(i, &d)| {
            let end = bpm::get_elapsed_time((i as f64 + 1.0) * 4.0, &bpms, &stops, &delays, &warps);
            let dur = end - start;
            start = end;
            if d == 0 || dur <= 0.12 {
                0
            } else {
                (d as f64 / dur * 1000.0).round() as u32
            }
        })
        .collect()
}

fn assert_event_nps_match(
    densities: &[u32],
    bpms: &[u8],
    stops: &[u8],
    delays: &[u8],
    warps: &[u8],
) {
    let parsed_bpms = parse_bpm_map(bpms).unwrap();
    let parsed_stops = parse_bpm_map(stops).unwrap();
    let parsed_delays = parse_bpm_map(delays).unwrap();
    let parsed_warps = parse_bpm_map(warps).unwrap();
    let asm = measure_nps_milli_with_events(
        densities,
        &parsed_bpms,
        &parsed_stops,
        &parsed_delays,
        &parsed_warps,
    )
    .unwrap();

    assert_eq!(
        asm,
        rust_nps_milli_with_events(densities, bpms, stops, delays, warps)
    );
    assert_nps_median_match(&asm);
}

fn assert_nps_median_match(nps_milli: &[u32]) {
    let rust_values: Vec<_> = nps_milli.iter().map(|&v| v as f64 / 1000.0).collect();
    let (_, median) = nps::get_nps_stats(&rust_values);
    let rust = math::round_dp(median, 2);
    assert_eq!(
        nps_median_centi(nps_milli),
        (rust * 100.0).round_ties_even() as i64
    );
}

fn assert_tier_bpm_match(densities: &[u32], bpms: &[u8]) {
    let parsed = parse_bpm_map(bpms).unwrap();
    let densities_usize: Vec<_> = densities.iter().map(|&v| v as usize).collect();
    let rust_bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    let rust = math::round_dp(bpm::compute_tier_bpm(&densities_usize, &rust_bpms, 4.0), 2);
    assert_eq!(
        tier_bpm_centi(densities, &parsed),
        (rust * 100.0).round_ties_even() as i64
    );
}

#[test]
fn selects_bpm_at_measure_beats() {
    let bpms = parse_bpm_map(b"8=240,4=120").unwrap();

    assert_eq!(bpm_at_beat_milli(&bpms, 0), 120000);
    assert_eq!(bpm_at_beat_milli(&bpms, 4000), 120000);
    assert_eq!(bpm_at_beat_milli(&bpms, 8000), 240000);
    assert_eq!(bpm_at_beat_milli(&bpms, 12000), 240000);
}

#[test]
fn computes_measure_nps_like_rssp_core() {
    assert_nps_match(&[], b"0=120");
    assert_nps_match(&[0, 16, 20, 24, 32, 8], b"0=120,8=240,16=10001,20=175");
    assert_nps_match(&[16, 16], b"");
}

#[test]
fn computes_measure_nps_with_timing_events() {
    assert_event_nps_match(&[16, 16], b"0=60", b"2=1", b"", b"");
    assert_event_nps_match(&[16, 16], b"0=60", b"", b"2=1", b"");
    assert_event_nps_match(&[16, 16], b"0=60", b"", b"", b"0=4");
}

#[test]
fn computes_median_nps_from_fixed_point_vector() {
    assert_nps_median_match(&[]);
    assert_nps_median_match(&[0, 8000, 16000]);
    assert_nps_median_match(&[10010, 10020]);
    assert_nps_median_match(&[10020, 10030]);
    assert_nps_median_match(&[0, 0, 2500, 5000, 7500, 10000]);
}

#[test]
fn computes_tier_bpm_like_rssp_core() {
    assert_tier_bpm_match(&[16, 16, 16, 16], b"0=120");
    assert_tier_bpm_match(&[20, 20, 20, 20], b"0=120");
    assert_tier_bpm_match(&[16, 16, 16], b"0=120");
    assert_tier_bpm_match(&[16, 20, 20, 20, 20], b"0=120");
    assert_tier_bpm_match(&[16, 16, 16, 16, 16, 16], b"0=120,8=240");
    assert_tier_bpm_match(&[0, 0], b"0=120,8=240");
    assert_tier_bpm_match(&[32, 32, 32, 32], b"0=120,8=15000");
    assert_tier_bpm_match(&[0, 0], b"0=12000,8=15000");
}

#[test]
fn fixture_measure_nps_matches_rssp_core() {
    for simfile in [
        include_bytes!("../fixtures/camellia_mix.ssc").as_slice(),
        include_bytes!("../fixtures/200000_step_challenge.sm").as_slice(),
    ] {
        let chart = find_chart_by_index(simfile, 4).unwrap();
        let note_data = slice_from(simfile, chart.note_data, chart.note_data_len);
        let densities = measure_densities_4(note_data);
        let bpms = find_bpms_for_chart(simfile, 4).unwrap();
        let bpms = slice_from(simfile, bpms.data, bpms.len);

        assert_nps_match(&densities, bpms);
    }
}
