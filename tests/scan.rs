use assp::{find_byte, version};

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
