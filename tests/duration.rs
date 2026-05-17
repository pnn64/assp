use assp::{
    elapsed_ms_bpm_only, find_bpms_for_chart, find_chart_by_index, last_beat_milli_4, parse_bpm_map,
};
use rssp_core::bpm;

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn rust_last_beat_milli(data: &[u8]) -> usize {
    (bpm::compute_last_beat(data, 4) * 1000.0).round() as usize
}

fn rust_elapsed_ms(bpms: &[u8], target_beat_milli: i64) -> i64 {
    let target = target_beat_milli as f64 / 1000.0;
    let bpms = bpm::parse_bpm_map(std::str::from_utf8(bpms).unwrap());
    (bpm::get_elapsed_time(target, &bpms, &[], &[], &[]) * 1000.0).floor() as i64
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
