use assp::{
    ByteSlice, TimingTags, elapsed_ms_bpm_only, elapsed_ms_with_events, find_bpms_for_chart,
    find_chart_by_index, find_chart_timing_tags_by_index, find_global_timing_tags,
    last_beat_milli_4, parse_bpm_map, parse_offset_ms,
};
use rssp_core::{bpm, parse::parse_offset_seconds};

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn tag_slice<'a>(data: &'a [u8], slice: ByteSlice) -> &'a [u8] {
    if slice.data.is_null() {
        &[]
    } else {
        slice_from(data, slice.data, slice.len)
    }
}

fn has_timing_tags(tags: TimingTags) -> bool {
    [
        tags.bpms.data,
        tags.stops.data,
        tags.delays.data,
        tags.warps.data,
        tags.speeds.data,
        tags.scrolls.data,
        tags.fakes.data,
    ]
    .iter()
    .any(|ptr| !ptr.is_null())
}

fn rust_last_beat_milli(data: &[u8]) -> usize {
    (bpm::compute_last_beat(data, 4) * 1000.0).round() as usize
}

fn rust_elapsed_ms(bpms: &[u8], target_beat_milli: i64) -> i64 {
    let target = target_beat_milli as f64 / 1000.0;
    let bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    (bpm::get_elapsed_time(target, &bpms, &[], &[], &[]) * 1000.0).floor() as i64
}

fn rust_elapsed_ms_with_events(
    bpms: &[u8],
    stops: &[u8],
    delays: &[u8],
    warps: &[u8],
    target_beat_milli: i64,
) -> i64 {
    let target = target_beat_milli as f64 / 1000.0;
    let bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    let stops = bpm::parse_bpm_map(std::str::from_utf8(stops).unwrap());
    let delays = bpm::parse_bpm_map(std::str::from_utf8(delays).unwrap());
    let warps = bpm::parse_bpm_map(std::str::from_utf8(warps).unwrap());
    (bpm::get_elapsed_time(target, &bpms, &stops, &delays, &warps) * 1000.0).floor() as i64
}

fn assert_elapsed_match(bpms: &[u8], target_beat_milli: i64) {
    let parsed = parse_bpm_map(bpms).unwrap();
    assert_eq!(
        elapsed_ms_bpm_only(&parsed, target_beat_milli),
        rust_elapsed_ms(bpms, target_beat_milli),
        "{} @ {}",
        std::str::from_utf8(bpms).unwrap(),
        target_beat_milli
    );
}

fn assert_event_elapsed_match(
    bpms: &[u8],
    stops: &[u8],
    delays: &[u8],
    warps: &[u8],
    target_beat_milli: i64,
) {
    let parsed_bpms = parse_bpm_map(bpms).unwrap();
    let parsed_stops = parse_bpm_map(stops).unwrap();
    let parsed_delays = parse_bpm_map(delays).unwrap();
    let parsed_warps = parse_bpm_map(warps).unwrap();

    assert_eq!(
        elapsed_ms_with_events(
            &parsed_bpms,
            &parsed_stops,
            &parsed_delays,
            &parsed_warps,
            target_beat_milli,
        ),
        rust_elapsed_ms_with_events(bpms, stops, delays, warps, target_beat_milli),
        "bpms={} stops={} delays={} warps={} @ {}",
        std::str::from_utf8(bpms).unwrap(),
        std::str::from_utf8(stops).unwrap(),
        std::str::from_utf8(delays).unwrap(),
        std::str::from_utf8(warps).unwrap(),
        target_beat_milli
    );
}

fn rust_offset_ms(offset: &[u8]) -> i64 {
    (parse_offset_seconds(Some(offset)) * 1000.0).round() as i64
}

#[test]
fn computes_last_beat_like_rssp_core() {
    let data = b"
1000
0000
0100
0000
,
0000
0011
000M
;";

    assert_eq!(last_beat_milli_4(data).unwrap(), rust_last_beat_milli(data));
    assert_eq!(last_beat_milli_4(b"0000\n0000\n;").unwrap(), 0);
}

#[test]
fn parses_offsets_like_rssp_core() {
    for raw in [
        b"0.008000".as_slice(),
        b"0.009".as_slice(),
        b"-1.2504".as_slice(),
        b" 2.5 ".as_slice(),
    ] {
        assert_eq!(parse_offset_ms(raw), rust_offset_ms(raw));
    }

    assert_eq!(parse_offset_ms(b""), 0);
    assert_eq!(parse_offset_ms(b"not an offset"), 0);
}

#[test]
fn computes_bpm_only_elapsed_time() {
    assert_elapsed_match(b"", 16000);
    assert_elapsed_match(b"0=120", 16000);
    assert_eq!(
        parse_bpm_map(b"0=120,8=240,16=60").unwrap(),
        vec![
            assp::BpmSegment {
                beat_milli: 0,
                bpm_milli: 120000
            },
            assp::BpmSegment {
                beat_milli: 8000,
                bpm_milli: 240000
            },
            assp::BpmSegment {
                beat_milli: 16000,
                bpm_milli: 60000
            },
        ]
    );
    assert_elapsed_match(b"0=120,8=240,16=60", 20000);
    assert_elapsed_match(b"-4=180,4=120", 12000);
}

#[test]
fn computes_elapsed_time_with_timing_events() {
    assert_event_elapsed_match(b"0=120", b"4=1.500", b"", b"", 8000);
    assert_event_elapsed_match(b"0=120,8=240", b"", b"6=0.250", b"", 12000);
    assert_event_elapsed_match(b"0=120", b"", b"", b"4=4", 12000);
    assert_event_elapsed_match(b"0=120,4=240", b"4=1", b"", b"8=4", 16000);
    assert_event_elapsed_match(b"", b"2=0.500", b"", b"", 6000);
}

#[test]
fn fixture_bpm_only_duration_matches_rssp_core() {
    for simfile in [
        include_bytes!("../fixtures/camellia_mix.ssc").as_slice(),
        include_bytes!("../fixtures/200000_step_challenge.sm").as_slice(),
    ] {
        let chart = find_chart_by_index(simfile, 4).unwrap();
        let note_data = slice_from(simfile, chart.note_data, chart.note_data_len);
        let last_beat = last_beat_milli_4(note_data).unwrap();
        assert_eq!(last_beat, rust_last_beat_milli(note_data));

        let bpms = find_bpms_for_chart(simfile, 4).unwrap();
        let bpms = slice_from(simfile, bpms.data, bpms.len);
        assert_elapsed_match(bpms, last_beat as i64);
    }
}

#[test]
fn chart_local_timing_owns_duration_context() {
    let simfile = include_bytes!("../fixtures/chart_own_timing.ssc");
    let chart = find_chart_by_index(simfile, 0).unwrap();
    let note_data = slice_from(simfile, chart.note_data, chart.note_data_len);
    let last_beat = last_beat_milli_4(note_data).unwrap();
    assert_eq!(last_beat, 4000);

    let global = find_global_timing_tags(simfile).unwrap();
    let chart = find_chart_timing_tags_by_index(simfile, 0).unwrap();
    assert!(has_timing_tags(chart));

    let bpms = parse_bpm_map(tag_slice(simfile, chart.bpms)).unwrap();
    let stops = parse_bpm_map(tag_slice(simfile, chart.stops)).unwrap();
    let delays = parse_bpm_map(tag_slice(simfile, chart.delays)).unwrap();
    let warps = parse_bpm_map(tag_slice(simfile, chart.warps)).unwrap();
    assert_eq!(
        elapsed_ms_with_events(&bpms, &stops, &delays, &warps, 4000),
        5000
    );

    let global_bpms = parse_bpm_map(tag_slice(simfile, global.bpms)).unwrap();
    assert_eq!(
        elapsed_ms_with_events(&global_bpms, &stops, &delays, &warps, 4000),
        3000
    );
}
