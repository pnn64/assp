use asmssp::{count_note_charts, find_chart_by_index, find_notes_by_index};

#[test]
fn counts_notes_tags() {
    let data = b"#TITLE:X;#NOTES:0000\n;#NOTES:1000\n;";
    assert_eq!(count_note_charts(data), 2);
}

#[test]
fn finds_note_data_by_index() {
    let data = b"#TITLE:X;#NOTES:0000\n;#NOTES:1000\n;";
    let chart = find_notes_by_index(data, 1).unwrap();
    let start = chart.note_data as usize - data.as_ptr() as usize;

    assert_eq!(chart.index, 1);
    assert_eq!(&data[start..start + chart.note_data_len], b"1000\n;");
    assert!(find_notes_by_index(data, 2).is_none());
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

fn slice(data: &[u8], ptr: *const u8, len: usize) -> &[u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}
