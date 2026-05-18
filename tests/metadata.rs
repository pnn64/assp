use assp::{find_global_tag, normalize_label_tag, trim_ascii_bytes};
use rssp_core::parse::{clean_tag, decode_bytes, unescape_tag};

fn first_param(bytes: &[u8]) -> &[u8] {
    let mut bs_run = 0usize;
    for (idx, &b) in bytes.iter().enumerate() {
        if b == b':' && bs_run.is_multiple_of(2) {
            return &bytes[..idx];
        }
        if b == b'\\' {
            bs_run += 1;
        } else {
            bs_run = 0;
        }
    }
    bytes
}

fn rust_label(bytes: &[u8]) -> String {
    let decoded = decode_bytes(first_param(bytes));
    let unescaped = unescape_tag(decoded.as_ref());
    clean_tag(unescaped.as_ref()).into_owned()
}

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

#[test]
fn trims_ascii_metadata_like_str_trim_for_ascii() {
    for input in [
        b"".as_slice(),
        b"0.000=4=4".as_slice(),
        b" \r\n\t0.000=4=4 \n ".as_slice(),
        b"\t 0.000=4,4.000=8 \r".as_slice(),
        b" \n\t ".as_slice(),
    ] {
        let asm = trim_ascii_bytes(input).unwrap();
        let rust = std::str::from_utf8(input).unwrap().trim().as_bytes();
        assert_eq!(asm, rust);
    }
}

#[test]
fn normalizes_ascii_labels_like_rssp_tag_cleanup() {
    for input in [
        b"0.000=Intro".as_slice(),
        b"0.000=Intro\\:A,4.000=Drop:ignored".as_slice(),
        b"0.000=Intro\r\n,4.000=Drop".as_slice(),
        b"0.000=Back\\\\slash".as_slice(),
    ] {
        let asm = normalize_label_tag(input).unwrap();
        assert_eq!(std::str::from_utf8(&asm).unwrap(), rust_label(input));
    }
}

#[test]
fn normalizes_fixture_global_time_signatures() {
    let data = include_bytes!("../fixtures/camellia_mix.ssc");
    let tag = find_global_tag(data, b"#TIMESIGNATURES:").unwrap();
    let raw = slice_from(data, tag.data, tag.len);

    let asm = trim_ascii_bytes(raw).unwrap();
    assert_eq!(std::str::from_utf8(&asm).unwrap(), "0.000000=4=4");
}
