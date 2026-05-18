use assp::{count_timing_segments, find_byte, version};

#[test]
fn version_is_initial_project_version() {
    assert_eq!(version(), 0x0000_0100);
}

#[test]
fn finds_first_matching_byte() {
    assert_eq!(find_byte(b"abc#def#ghi", b'#'), Some(3));
    assert_eq!(find_byte(b"abc#def#ghi", b'g'), Some(8));
    assert_eq!(find_byte(b"abc#def#ghi", b'z'), None);
    assert_eq!(find_byte(b"", b'z'), None);
}

#[test]
fn counts_nonempty_timing_segments() {
    assert_eq!(count_timing_segments(b""), Some(0));
    assert_eq!(count_timing_segments(b"0=120"), Some(1));
    assert_eq!(count_timing_segments(b"0=120,4=150,8=90"), Some(3));
    assert_eq!(count_timing_segments(b" , 0=120 , , 4=150 "), Some(2));
    assert_eq!(count_timing_segments(b"\r\n,\t,  "), Some(0));
}
