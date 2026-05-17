use assp::{find_chart_by_index, minimize_chart_4, sha1_short_hex2};
use rssp_core::hash::compute_chart_hash;

fn assert_short_hash_match(first: &[u8], second: &str) {
    let asm = sha1_short_hex2(first, second.as_bytes()).unwrap();
    let asm = std::str::from_utf8(&asm).unwrap();
    let rust = compute_chart_hash(first, second);

    assert_eq!(asm, rust);
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
fn two_slice_hash_matches_rssp_core() {
    assert_short_hash_match(b"1000\n0100\n0010\n0001\n", "0.000=140.000");
    assert_short_hash_match(
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
}

#[test]
fn sm_fixture_hash_input_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];
    let minimized = minimize_chart_4(notes).unwrap();

    assert_short_hash_match(&minimized, "0.000=120.000");
}
