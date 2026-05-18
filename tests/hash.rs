use assp::{
    chart_hash_pair, find_bpms_for_chart, find_chart_by_index, md5_hex, minimize_chart_4,
    normalize_float_digits, sha1_short_hex2,
};
use rssp_core::hash::{compute_chart_hash, compute_chart_hash_pair};

fn assert_short_hash_match(first: &[u8], second: &str) {
    let asm = sha1_short_hex2(first, second.as_bytes()).unwrap();
    let asm = std::str::from_utf8(&asm).unwrap();
    let rust = compute_chart_hash(first, second);

    assert_eq!(asm, rust);
}

fn assert_hash_pair_match(chart_data: &[u8], bpms: &str) {
    let (asm_hash, asm_neutral) = chart_hash_pair(chart_data, bpms.as_bytes()).unwrap();
    let asm_hash = std::str::from_utf8(&asm_hash).unwrap();
    let asm_neutral = std::str::from_utf8(&asm_neutral).unwrap();
    let (rust_hash, rust_neutral) = compute_chart_hash_pair(chart_data, bpms);

    assert_eq!(asm_hash, rust_hash);
    assert_eq!(asm_neutral, rust_neutral);
}

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn truncate_hash_newlines(data: &mut Vec<u8>) {
    while data.last() == Some(&b'\n') {
        data.pop();
    }
}

fn assert_fixture_hash_pipeline(data: &[u8], index: usize) {
    let chart = find_chart_by_index(data, index).unwrap();
    let chart_start = chart.note_data as usize - data.as_ptr() as usize;
    let notes = &data[chart_start..chart_start + chart.note_data_len];
    let mut minimized = minimize_chart_4(notes).unwrap();
    truncate_hash_newlines(&mut minimized);

    let bpms = find_bpms_for_chart(data, index).unwrap();
    let raw_bpms = slice_from(data, bpms.data, bpms.len);
    let normalized = normalize_float_digits(raw_bpms).unwrap();
    let normalized = std::str::from_utf8(&normalized).unwrap();

    assert_hash_pair_match(&minimized, normalized);
}

fn assert_fixture_report_hashes(
    data: &[u8],
    index: usize,
    expected_hash: &str,
    expected_neutral: &str,
) {
    let chart = find_chart_by_index(data, index).unwrap();
    let chart_start = chart.note_data as usize - data.as_ptr() as usize;
    let notes = &data[chart_start..chart_start + chart.note_data_len];
    let mut minimized = minimize_chart_4(notes).unwrap();
    truncate_hash_newlines(&mut minimized);

    let bpms = find_bpms_for_chart(data, index).unwrap();
    let raw_bpms = slice_from(data, bpms.data, bpms.len);
    let normalized = normalize_float_digits(raw_bpms).unwrap();
    let (hash, neutral) = chart_hash_pair(&minimized, &normalized).unwrap();

    assert_eq!(std::str::from_utf8(&hash).unwrap(), expected_hash);
    assert_eq!(std::str::from_utf8(&neutral).unwrap(), expected_neutral);
}

#[test]
fn sha1_short_hex_matches_known_vectors() {
    assert_eq!(
        std::str::from_utf8(&sha1_short_hex2(b"", b"").unwrap()).unwrap(),
        "da39a3ee5e6b4b0d"
    );
    assert_eq!(
        std::str::from_utf8(&sha1_short_hex2(b"abc", b"").unwrap()).unwrap(),
        "a9993e364706816a"
    );
}

#[test]
fn md5_hex_matches_known_vectors() {
    assert_eq!(
        std::str::from_utf8(&md5_hex(b"").unwrap()).unwrap(),
        "d41d8cd98f00b204e9800998ecf8427e"
    );
    assert_eq!(
        std::str::from_utf8(&md5_hex(b"abc").unwrap()).unwrap(),
        "900150983cd24fb0d6963f7d28e17f72"
    );
    assert_eq!(
        std::str::from_utf8(&md5_hex(b"The quick brown fox jumps over the lazy dog").unwrap())
            .unwrap(),
        "9e107d9d372bb6826bd81d3542a419d6"
    );
}

#[test]
fn two_slice_hash_matches_rssp_core() {
    assert_short_hash_match(b"1000\n0100\n0010\n0001\n", "0.000=140.000");
    assert_short_hash_match(
        b"1000\n0000\n,\n0100\n0001\n",
        "0.000=140.000,64.000=175.000",
    );
}

#[test]
fn chart_hash_pair_matches_rssp_core() {
    assert_hash_pair_match(b"1000\n0100\n0010\n0001\n", "0.000=140.000");
    assert_hash_pair_match(
        b"1000\n0000\n,\n0100\n0001\n",
        "0.000=140.000,64.000=175.000",
    );
}

#[test]
fn ssc_fixture_hash_input_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let minimized = minimize_chart_4(notes).unwrap();

    assert_short_hash_match(&minimized, "0.000=240.000");
    assert_hash_pair_match(&minimized, "0.000=240.000");
}

#[test]
fn sm_fixture_hash_input_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let minimized = minimize_chart_4(notes).unwrap();

    assert_short_hash_match(&minimized, "0.000=120.000");
    assert_hash_pair_match(&minimized, "0.000=120.000");
}

#[test]
fn fixture_hash_pipeline_matches_rssp_core() {
    assert_fixture_hash_pipeline(include_bytes!("../fixtures/camellia_mix.ssc"), 4);
    assert_fixture_hash_pipeline(include_bytes!("../fixtures/200000_step_challenge.sm"), 4);
}

#[test]
fn fixture_report_hashes_match_rssp_cli() {
    assert_fixture_report_hashes(
        include_bytes!("../fixtures/camellia_mix.ssc"),
        4,
        "9dd8b279739ae8da",
        "4791540518d770c5",
    );
    assert_fixture_report_hashes(
        include_bytes!("../fixtures/200000_step_challenge.sm"),
        4,
        "56b8ceeeb9f0d24e",
        "fb40ca35ce60b5f1",
    );
}
