use assp::{count_anchors_4, count_anchors_minimized_4, find_chart_by_index};
use rssp_core::{
    patterns::count_anchors,
    stats::{minimize_chart_for_hash, minimize_chart_rows_bits},
};

fn bitmasks_from_minimized(data: &[u8]) -> Vec<u8> {
    data.split(|&b| b == b'\n')
        .filter_map(|raw| {
            let line = raw.strip_suffix(b"\r").unwrap_or(raw);
            if line.len() < 4 || matches!(line.first(), Some(b',' | b';') | None) {
                return None;
            }
            Some((0..4).fold(0u8, |mask, i| {
                mask | if matches!(line[i], b'1' | b'2' | b'4') {
                    1 << i
                } else {
                    0
                }
            }))
        })
        .collect()
}

fn anchors_array(bitmasks: &[u8]) -> [u32; 4] {
    let (left, down, up, right) = count_anchors(bitmasks);
    [left, down, up, right]
}

fn chart_notes(data: &[u8], index: usize) -> &[u8] {
    let chart = find_chart_by_index(data, index).unwrap();
    let start = chart.note_data as usize - data.as_ptr() as usize;
    &data[start..start + chart.note_data_len]
}

#[test]
fn synthetic_anchor_counts_match_rssp_core() {
    let minimized = b"
1000
0000
1000
0000
1000
0100
0010
0100
0010
0100
;
";
    let bitmasks = bitmasks_from_minimized(minimized);
    assert_eq!(
        count_anchors_minimized_4(minimized).unwrap(),
        anchors_array(&bitmasks)
    );
}

#[test]
fn empty_anchor_counts_match_rssp_core() {
    assert_eq!(count_anchors_minimized_4(b"").unwrap(), [0, 0, 0, 0]);
    assert_eq!(
        count_anchors_minimized_4(b"1000\n0000\n1000\n;\n").unwrap(),
        [0, 0, 0, 0]
    );
}

#[test]
fn ssc_fixture_anchor_counts_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(count_anchors_4(notes).unwrap(), anchors_array(&bitmasks));
}

#[test]
fn sm_fixture_anchor_counts_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(count_anchors_4(notes).unwrap(), anchors_array(&bitmasks));
}

#[test]
fn minimized_anchor_counts_match_rssp_hash_rows() {
    let notes = b"
1000
0000
0100
0000
,
0010
0000
0001
0000
;
";
    let minimized = minimize_chart_for_hash(notes, 4);
    let bitmasks = bitmasks_from_minimized(&minimized);

    assert_eq!(
        count_anchors_minimized_4(&minimized).unwrap(),
        anchors_array(&bitmasks)
    );
}
