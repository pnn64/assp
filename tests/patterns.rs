use assp::{
    BasicPatterns, PATTERN_COUNT, count_anchors_4, count_anchors_minimized_4,
    count_basic_patterns_4, count_basic_patterns_minimized_4, count_default_patterns_4,
    count_default_patterns_minimized_4, count_facing_steps_4, count_facing_steps_minimized_4,
    find_chart_by_index,
};
use rssp_core::{
    patterns::{PatternVariant, count_anchors, count_facing_steps, detect_default_patterns},
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

fn facing_array(bitmasks: &[u8], mono_threshold: usize) -> [u32; 2] {
    let (left, right) = count_facing_steps(bitmasks, mono_threshold);
    [left, right]
}

fn basic_patterns(bitmasks: &[u8]) -> BasicPatterns {
    let counts = detect_default_patterns(bitmasks);
    BasicPatterns {
        candle_left: counts[PatternVariant::CandleLeft as usize],
        candle_right: counts[PatternVariant::CandleRight as usize],
        box_lr: counts[PatternVariant::BoxLR as usize],
        box_ud: counts[PatternVariant::BoxUD as usize],
        box_ld: counts[PatternVariant::BoxCornerLD as usize],
        box_lu: counts[PatternVariant::BoxCornerLU as usize],
        box_rd: counts[PatternVariant::BoxCornerRD as usize],
        box_ru: counts[PatternVariant::BoxCornerRU as usize],
    }
}

fn default_patterns(bitmasks: &[u8]) -> [u32; PATTERN_COUNT] {
    detect_default_patterns(bitmasks)
}

fn chart_notes(data: &[u8], index: usize) -> &[u8] {
    let chart = find_chart_by_index(data, index).unwrap();
    let start = chart.note_data as usize - data.as_ptr() as usize;
    &data[start..start + chart.note_data_len]
}

fn minimized_from_pattern_strings(patterns: &[&[u8]]) -> Vec<u8> {
    let mut out = Vec::new();
    for pattern in patterns {
        for &ch in *pattern {
            let row = match ch {
                b'L' => b"1000",
                b'D' => b"0100",
                b'U' => b"0010",
                b'R' => b"0001",
                _ => b"0000",
            };
            out.extend_from_slice(row);
            out.push(b'\n');
        }
        out.extend_from_slice(b"0000\n");
    }
    out.extend_from_slice(b";\n");
    out
}

const DEFAULT_PATTERN_STRINGS: &[&[u8]] = &[
    b"ULD",
    b"DLU",
    b"URD",
    b"DRU",
    b"LRLR",
    b"RLRL",
    b"UDUD",
    b"DUDU",
    b"LDLD",
    b"DLDL",
    b"LULU",
    b"ULUL",
    b"RDRD",
    b"DRDR",
    b"RURU",
    b"URUR",
    b"LDUR",
    b"RUDL",
    b"LUDR",
    b"RDUL",
    b"RUR",
    b"LUL",
    b"LDL",
    b"RDR",
    b"LDUDL",
    b"RUDUR",
    b"LUDUL",
    b"RDUDR",
    b"LDURUDL",
    b"RUDLDUR",
    b"LUDRDUL",
    b"RDULUDR",
    b"LRLRL",
    b"RLRLR",
    b"UDUDU",
    b"DUDUD",
    b"LDLDL",
    b"DLDLD",
    b"LULUL",
    b"ULULU",
    b"RDRDR",
    b"DRDRD",
    b"RURUR",
    b"URURU",
    b"LUDRLUDR",
    b"RDULRDUL",
    b"LDURLDUR",
    b"RDULRDUL",
    b"LUDRLDUR",
    b"RDULRUDL",
    b"LDURLUDR",
    b"RUDLRDUL",
    b"LDLUL",
    b"LULDL",
    b"RURDR",
    b"RDRUR",
    b"LDURDULDUR",
    b"RUDLUDRUDL",
    b"LUDRUDLUDR",
    b"RDULDURDUL",
    b"LDUDLUDUL",
    b"RUDURDUDR",
    b"LUDULDUDL",
    b"RDUDRUDUR",
    b"LDURDR",
    b"RUDLUL",
    b"LUDRUR",
    b"RDULDL",
    b"LDLUDRUR",
    b"RURDULDL",
    b"LULDURDR",
    b"RDRUDLUL",
    b"LDURDRUDL",
    b"RUDLULDUR",
    b"LUDRURDUL",
    b"RDULDLUDR",
];

#[test]
fn synthetic_default_patterns_match_rssp_core() {
    let minimized = minimized_from_pattern_strings(DEFAULT_PATTERN_STRINGS);
    let bitmasks = bitmasks_from_minimized(&minimized);

    assert_eq!(
        count_default_patterns_minimized_4(&minimized).unwrap(),
        default_patterns(&bitmasks)
    );
}

#[test]
fn empty_default_patterns_match_rssp_core() {
    assert_eq!(
        count_default_patterns_minimized_4(b"").unwrap(),
        [0; PATTERN_COUNT]
    );
    assert_eq!(
        count_default_patterns_minimized_4(b"1000\n0011\n0100\n;\n").unwrap(),
        default_patterns(&bitmasks_from_minimized(b"1000\n0011\n0100\n;\n"))
    );
}

#[test]
fn synthetic_basic_patterns_match_rssp_core() {
    let minimized = b"
0010
1000
0100
0100
1000
0010
0010
0001
0100
0100
0001
0010
1000
0001
1000
0001
0100
0010
0100
0010
1000
0100
1000
0100
0001
0010
0001
0010
0001
0100
0001
0100
;
";
    let bitmasks = bitmasks_from_minimized(minimized);

    assert_eq!(
        count_basic_patterns_minimized_4(minimized).unwrap(),
        basic_patterns(&bitmasks)
    );
}

#[test]
fn empty_basic_patterns_match_rssp_core() {
    assert_eq!(
        count_basic_patterns_minimized_4(b"").unwrap(),
        BasicPatterns::default()
    );
    assert_eq!(
        count_basic_patterns_minimized_4(b"1000\n0011\n0100\n;\n").unwrap(),
        BasicPatterns::default()
    );
}

#[test]
fn synthetic_facing_steps_match_rssp_core() {
    let minimized = b"
1000
0010
1000
0010
1000
0010
0000
0001
0100
0001
0100
0001
0100
;
";
    let bitmasks = bitmasks_from_minimized(minimized);

    assert_eq!(
        count_facing_steps_minimized_4(minimized, 0).unwrap(),
        facing_array(&bitmasks, 0)
    );
    assert_eq!(
        count_facing_steps_minimized_4(minimized, 6).unwrap(),
        facing_array(&bitmasks, 6)
    );
}

#[test]
fn empty_facing_steps_match_rssp_core() {
    assert_eq!(count_facing_steps_minimized_4(b"", 0).unwrap(), [0, 0]);
    assert_eq!(
        count_facing_steps_minimized_4(b"1000\n0011\n0100\n;\n", 0).unwrap(),
        [0, 0]
    );
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
fn ssc_fixture_default_patterns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_default_patterns_4(notes).unwrap(),
        default_patterns(&bitmasks)
    );
}

#[test]
fn ssc_fixture_basic_patterns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_basic_patterns_4(notes).unwrap(),
        basic_patterns(&bitmasks)
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
fn ssc_fixture_facing_steps_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_facing_steps_4(notes, 0).unwrap(),
        facing_array(&bitmasks, 0)
    );
    assert_eq!(
        count_facing_steps_4(notes, 6).unwrap(),
        facing_array(&bitmasks, 6)
    );
}

#[test]
fn sm_fixture_default_patterns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_default_patterns_4(notes).unwrap(),
        default_patterns(&bitmasks)
    );
}

#[test]
fn sm_fixture_basic_patterns_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_basic_patterns_4(notes).unwrap(),
        basic_patterns(&bitmasks)
    );
}

#[test]
fn sm_fixture_anchor_counts_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(count_anchors_4(notes).unwrap(), anchors_array(&bitmasks));
}

#[test]
fn sm_fixture_facing_steps_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let notes = chart_notes(simfile, 4);
    let (_, _, _, _, _, _, bitmasks) = minimize_chart_rows_bits(notes);

    assert_eq!(
        count_facing_steps_4(notes, 0).unwrap(),
        facing_array(&bitmasks, 0)
    );
    assert_eq!(
        count_facing_steps_4(notes, 6).unwrap(),
        facing_array(&bitmasks, 6)
    );
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
