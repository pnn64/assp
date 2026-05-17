use asmssp::{count_note_charts, find_notes_by_index};

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

