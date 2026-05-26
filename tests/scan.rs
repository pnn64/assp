use assp::{
    count_gimmick_scroll_segments, count_gimmick_speed_segments, count_timing_segments, find_byte,
    version,
};

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

#[test]
fn counts_nondefault_speed_segments() {
    assert_eq!(count_gimmick_speed_segments(b""), Some(0));
    assert_eq!(count_gimmick_speed_segments(b"0=1.000"), Some(0));
    assert_eq!(
        count_gimmick_speed_segments(b"0=1.,4=1.000000,8=1.0000009,12=1.000002"),
        Some(1)
    );
    assert_eq!(
        count_gimmick_speed_segments(b"0=1.000,4=2.000,8=1.000=4=0,12=0.250=0=0,16=bad"),
        Some(2)
    );
    assert_eq!(
        count_gimmick_speed_segments(
            b"0=1.25=4=0,4=0.875=4=0,8=1.0000009=4=0,12=1.0000019=4=0"
        ),
        Some(3)
    );
}

#[test]
fn counts_nondefault_scroll_segments() {
    assert_eq!(count_gimmick_scroll_segments(b""), Some(0));
    assert_eq!(
        count_gimmick_scroll_segments(b"0=1,4=0.5,8=1.25,12=-1,16=bad"),
        Some(3)
    );
    assert_eq!(
        count_gimmick_scroll_segments(b"0=1.0000009,1=1.000002,2=0.999998"),
        Some(2)
    );
}
