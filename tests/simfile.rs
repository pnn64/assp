use assp::{
    chart_owns_timing_by_index, count_note_charts, find_bpms_for_chart, find_chart_bpms_by_index,
    find_chart_by_index, find_chart_tag_by_index, find_chart_timing_tags_by_index,
    find_global_bpms, find_global_tag, find_global_timing_tags, find_notes_by_index,
    find_tag_for_chart,
};

#[test]
fn counts_notes_tags() {
    let data = b"#TITLE:X;#NOTES:0000\n;#NOTES2:1000\n;#NOTES:0100\n;";
    assert_eq!(count_note_charts(data), 3);
}

#[test]
fn finds_note_data_by_index() {
    let data = b"#TITLE:X;#NOTES:0000\n;#NOTES2:1000\n;";
    let chart = find_notes_by_index(data, 1).unwrap();
    let start = chart.note_data as usize - data.as_ptr() as usize;

    assert_eq!(chart.index, 1);
    assert_eq!(&data[start..start + chart.note_data_len], b"1000\n;");
    assert!(find_notes_by_index(data, 2).is_none());
}

#[test]
fn treats_notes2_as_chart_note_data() {
    let data = b"#TITLE:X;
#BPMS:0.000=140.000;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#BPMS:0.000=175.000;
#NOTES2:
1000
;";
    let chart = find_chart_by_index(data, 0).unwrap();
    let bpms = find_chart_bpms_by_index(data, 0).unwrap();

    assert_eq!(
        slice(data, chart.note_data, chart.note_data_len),
        b"\n1000\n;"
    );
    assert_eq!(slice(data, bpms.data, bpms.len), b"0.000=175.000");
}

#[test]
fn finds_ssc_chart_metadata() {
    let data = b"#NOTEDATA:;
#STEPSTYPE:dance-single;
#DESCRIPTION:cmmf;
#DIFFICULTY:Challenge;
#METER:20;
#NOTES:
1000
;";
    let chart = find_chart_by_index(data, 0).unwrap();

    assert_eq!(
        slice(data, chart.step_type, chart.step_type_len),
        b"dance-single"
    );
    assert_eq!(
        slice(data, chart.description, chart.description_len),
        b"cmmf"
    );
    assert_eq!(
        slice(data, chart.difficulty, chart.difficulty_len),
        b"Challenge"
    );
    assert_eq!(slice(data, chart.meter, chart.meter_len), b"20");
    assert_eq!(
        slice(data, chart.note_data, chart.note_data_len),
        b"\n1000\n;"
    );
}

#[test]
fn matches_simfile_tags_case_insensitively() {
    let data = b"#title:X;
#bpms:0.000=140.000;
#notedata:;
#stepstype:dance-single;
#description:lower tags;
#difficulty:Challenge;
#meter:9;
#labels:0.000=local;
#stops:4.000=0.500;
#notes2:
1000
;";
    let chart = find_chart_by_index(data, 0).unwrap();
    let bpms = find_global_bpms(data).unwrap();
    let labels = find_chart_tag_by_index(data, 0, b"#LABELS:").unwrap();
    let tags = find_chart_timing_tags_by_index(data, 0).unwrap();

    assert_eq!(count_note_charts(data), 1);
    assert_eq!(slice(data, bpms.data, bpms.len), b"0.000=140.000");
    assert_eq!(
        slice(data, chart.step_type, chart.step_type_len),
        b"dance-single"
    );
    assert_eq!(
        slice(data, chart.description, chart.description_len),
        b"lower tags"
    );
    assert_eq!(
        slice(data, chart.difficulty, chart.difficulty_len),
        b"Challenge"
    );
    assert_eq!(slice(data, chart.meter, chart.meter_len), b"9");
    assert_eq!(
        slice(data, chart.note_data, chart.note_data_len),
        b"\n1000\n;"
    );
    assert_eq!(slice(data, labels.data, labels.len), b"0.000=local");
    assert_eq!(slice(data, tags.stops.data, tags.stops.len), b"4.000=0.500");
    assert!(chart_owns_timing_by_index(data, 0));
}

#[test]
fn finds_sm_chart_metadata_and_note_rows() {
    let data = b"#TITLE:X;
#NOTES2:
     dance-single:
     1sts?:
     Beginner:
     1:
     0,0,0,0,0:
0001
0000
;";
    let chart = find_chart_by_index(data, 0).unwrap();

    assert_eq!(
        slice(data, chart.step_type, chart.step_type_len),
        b"dance-single"
    );
    assert_eq!(
        slice(data, chart.description, chart.description_len),
        b"1sts?"
    );
    assert_eq!(
        slice(data, chart.difficulty, chart.difficulty_len),
        b"Beginner"
    );
    assert_eq!(slice(data, chart.meter, chart.meter_len), b"1");
    assert_eq!(
        slice(data, chart.note_data, chart.note_data_len),
        b"\n0001\n0000\n;"
    );
}

#[test]
fn finds_global_bpms() {
    let data = b"#TITLE:X;#BPMS:0.000=140.000,64.000=175.000;#NOTES:0000\n;";
    let bpms = find_global_bpms(data).unwrap();

    assert_eq!(
        slice(data, bpms.data, bpms.len),
        b"0.000=140.000,64.000=175.000"
    );
}

#[test]
fn finds_global_timing_tag() {
    let data = b"#TITLE:X;#BPMS:0.000=140.000;#STOPS:64.000=1.500;#NOTES:0000\n;";
    let stops = find_global_tag(data, b"#STOPS:").unwrap();

    assert_eq!(slice(data, stops.data, stops.len), b"64.000=1.500");
    assert!(find_global_tag(data, b"").is_none());
}

#[test]
fn finds_global_timing_tags() {
    let data = b"#TITLE:X;
#BPMS:0.000=140.000;
#STOPS:64.000=1.500;
#DELAYS:96.000=0.250;
#WARPS:128.000=4.000;
#SPEEDS:0.000=1.000=0.000=0;
#SCROLLS:0.000=1.000;
#FAKES:192.000=4.000;
#NOTES:0000
;";
    let tags = find_global_timing_tags(data).unwrap();

    assert_eq!(slice(data, tags.bpms.data, tags.bpms.len), b"0.000=140.000");
    assert_eq!(
        slice(data, tags.stops.data, tags.stops.len),
        b"64.000=1.500"
    );
    assert_eq!(
        slice(data, tags.delays.data, tags.delays.len),
        b"96.000=0.250"
    );
    assert_eq!(
        slice(data, tags.warps.data, tags.warps.len),
        b"128.000=4.000"
    );
    assert_eq!(
        slice(data, tags.speeds.data, tags.speeds.len),
        b"0.000=1.000=0.000=0"
    );
    assert_eq!(
        slice(data, tags.scrolls.data, tags.scrolls.len),
        b"0.000=1.000"
    );
    assert_eq!(
        slice(data, tags.fakes.data, tags.fakes.len),
        b"192.000=4.000"
    );
}

#[test]
fn treats_freezes_as_stop_timing_tags() {
    let data = b"#TITLE:X;
#FREEZES:16.000=0.250;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#FREEZES:32.000=0.500;
#NOTES:
1000
;";
    let global_tags = find_global_timing_tags(data).unwrap();
    let chart_tags = find_chart_timing_tags_by_index(data, 0).unwrap();

    assert_eq!(
        slice(data, global_tags.stops.data, global_tags.stops.len),
        b"16.000=0.250"
    );
    assert_eq!(
        slice(data, chart_tags.stops.data, chart_tags.stops.len),
        b"32.000=0.500"
    );

    let empty_stops = b"#STOPS:;#FREEZES:16.000=0.250;#NOTES:0000\n;";
    let tags = find_global_timing_tags(empty_stops).unwrap();
    assert_eq!(slice(empty_stops, tags.stops.data, tags.stops.len), b"");
}

#[test]
fn empty_chart_timing_tag_overrides_global_tag() {
    let data = b"#STOPS:16.000=0.250;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#STOPS:;
#NOTES:
1000
;";
    let stops = find_tag_for_chart(data, 0, b"#STOPS:").unwrap();
    let tags = find_chart_timing_tags_by_index(data, 0).unwrap();

    assert_eq!(slice(data, stops.data, stops.len), b"");
    assert_eq!(slice(data, tags.stops.data, tags.stops.len), b"");
}

#[test]
fn finds_chart_local_bpms() {
    let data = b"#BPMS:0.000=140.000;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#BPMS:0.000=175.000;
#NOTES:
1000
;";
    let bpms = find_chart_bpms_by_index(data, 0).unwrap();

    assert_eq!(slice(data, bpms.data, bpms.len), b"0.000=175.000");
}

#[test]
fn finds_chart_local_timing_tag() {
    let data = b"#STOPS:64.000=1.000;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#STOPS:64.000=2.000;
#DELAYS:96.000=0.500;
#NOTES:
1000
;";
    let stops = find_chart_tag_by_index(data, 0, b"#STOPS:").unwrap();
    let delays = find_chart_tag_by_index(data, 0, b"#DELAYS:").unwrap();

    assert_eq!(slice(data, stops.data, stops.len), b"64.000=2.000");
    assert_eq!(slice(data, delays.data, delays.len), b"96.000=0.500");
}

#[test]
fn finds_chart_metadata_timing_ownership_tag() {
    let data = include_bytes!("../fixtures/chart_own_metadata_timing.ssc");
    let labels = find_chart_tag_by_index(data, 0, b"#LABELS:").unwrap();

    assert_eq!(slice(data, labels.data, labels.len), b"0.000=local");
}

#[test]
fn detects_chart_owned_timing_tags() {
    let data = include_bytes!("../fixtures/chart_own_metadata_timing.ssc");
    assert!(chart_owns_timing_by_index(data, 0));

    let offset = b"#NOTEDATA:;
#STEPSTYPE:dance-single;
#OFFSET:0.125;
#NOTES:
1000
;";
    assert!(chart_owns_timing_by_index(offset, 0));

    let freezes = b"#NOTEDATA:;
#STEPSTYPE:dance-single;
#FREEZES:16.000=0.250;
#NOTES:
1000
;";
    assert!(chart_owns_timing_by_index(freezes, 0));

    let global_only = b"#BPMS:0.000=140.000;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#NOTES:
1000
;";
    assert!(!chart_owns_timing_by_index(global_only, 0));
    assert!(!chart_owns_timing_by_index(global_only, 1));
}

#[test]
fn finds_chart_local_timing_tags() {
    let data = b"#BPMS:0.000=140.000;
#STOPS:64.000=1.000;
#NOTEDATA:;
#STEPSTYPE:dance-single;
#BPMS:0.000=175.000;
#STOPS:64.000=2.000;
#DELAYS:96.000=0.500;
#NOTES:
1000
;";
    let tags = find_chart_timing_tags_by_index(data, 0).unwrap();

    assert_eq!(slice(data, tags.bpms.data, tags.bpms.len), b"0.000=175.000");
    assert_eq!(
        slice(data, tags.stops.data, tags.stops.len),
        b"64.000=2.000"
    );
    assert_eq!(
        slice(data, tags.delays.data, tags.delays.len),
        b"96.000=0.500"
    );
    assert_eq!(tags.warps.len, 0);
}

#[test]
fn falls_back_to_global_bpms_for_sm_chart() {
    let data = b"#TITLE:X;
#BPMS:0.000=140.000;
#NOTES:
     dance-single:
     1sts?:
     Beginner:
     1:
     0,0,0,0,0:
0001
;";
    assert!(find_chart_bpms_by_index(data, 0).is_none());

    let bpms = find_bpms_for_chart(data, 0).unwrap();
    assert_eq!(slice(data, bpms.data, bpms.len), b"0.000=140.000");
}

#[test]
fn falls_back_to_global_timing_tag_for_sm_chart() {
    let data = b"#TITLE:X;
#STOPS:64.000=1.000;
#NOTES:
     dance-single:
     1sts?:
     Beginner:
     1:
     0,0,0,0,0:
0001
;";
    assert!(find_chart_tag_by_index(data, 0, b"#STOPS:").is_none());

    let stops = find_tag_for_chart(data, 0, b"#STOPS:").unwrap();
    assert_eq!(slice(data, stops.data, stops.len), b"64.000=1.000");
}

#[test]
fn fixture_bpms_selection_matches_expected_scope() {
    let ssc = include_bytes!("../fixtures/camellia_mix.ssc");
    let sm = include_bytes!("../fixtures/200000_step_challenge.sm");

    let ssc_local = find_chart_bpms_by_index(ssc, 4).unwrap();
    assert_eq!(
        slice(ssc, ssc_local.data, ssc_local.len),
        b"0.000000=175.000000"
    );

    let sm_bpms = find_bpms_for_chart(sm, 4).unwrap();
    assert_eq!(slice(sm, sm_bpms.data, sm_bpms.len), b"0.000=140.000");
}

fn slice(data: &[u8], ptr: *const u8, len: usize) -> &[u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}
