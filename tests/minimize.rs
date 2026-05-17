use assp::{
    find_chart_by_index, minimize_chart_4, minimize_chart_8, minimize_measure_4, minimize_measure_8,
};
use rssp_core::stats::{minimize_chart_for_hash, minimize_measure};

fn assert_measure_minimize_match(rows: &[[u8; 4]]) {
    let asm = minimize_measure_4(rows);
    let mut rust = rows.to_vec();
    minimize_measure(&mut rust);

    assert_eq!(asm, rust);
}

fn assert_measure_minimize_match_8(rows: &[[u8; 8]]) {
    let asm = minimize_measure_8(rows);
    let mut rust = rows.to_vec();
    minimize_measure(&mut rust);

    assert_eq!(asm, rust);
}

fn assert_chart_minimize_match(data: &[u8]) {
    let asm = minimize_chart_4(data).unwrap();
    let rust = minimize_chart_for_hash(data, 4);

    assert_eq!(asm, rust);
}

fn assert_chart_minimize_match_8(data: &[u8]) {
    let asm = minimize_chart_8(data).unwrap();
    let rust = minimize_chart_for_hash(data, 8);

    assert_eq!(asm, rust);
}

fn parse_measures_4(data: &[u8]) -> Vec<Vec<[u8; 4]>> {
    let mut out = Vec::new();
    let mut measure = Vec::new();

    for raw in data.split(|&b| b == b'\n') {
        let line = raw
            .strip_suffix(b"\r")
            .unwrap_or(raw)
            .iter()
            .skip_while(|b| b.is_ascii_whitespace())
            .copied()
            .collect::<Vec<_>>();

        if line.is_empty() || line[0] == b'/' {
            continue;
        }

        match line[0] {
            b',' => {
                out.push(std::mem::take(&mut measure));
            }
            b';' => {
                out.push(std::mem::take(&mut measure));
                return out;
            }
            _ if line.len() >= 4 => {
                measure.push([line[0], line[1], line[2], line[3]]);
            }
            _ => {}
        }
    }

    out.push(measure);
    out
}

fn rows(bytes: &[u8]) -> Vec<[u8; 4]> {
    bytes
        .chunks_exact(4)
        .map(|chunk| [chunk[0], chunk[1], chunk[2], chunk[3]])
        .collect()
}

fn rows_8(bytes: &[u8]) -> Vec<[u8; 8]> {
    bytes
        .chunks_exact(8)
        .map(|chunk| {
            [
                chunk[0], chunk[1], chunk[2], chunk[3], chunk[4], chunk[5], chunk[6], chunk[7],
            ]
        })
        .collect()
}

#[test]
fn synthetic_measure_minimization_matches_rssp_core() {
    assert_measure_minimize_match(&[]);
    assert_measure_minimize_match(&rows(b"1000000001000000"));
    assert_measure_minimize_match(&rows(b"1000000000000000"));
    assert_measure_minimize_match(&rows(b"10000000000000000000000000000000"));
    assert_measure_minimize_match(&rows(b"10000000010000000010000000010000"));
}

#[test]
fn synthetic_8_panel_measure_minimization_matches_rssp_core() {
    assert_measure_minimize_match_8(&[]);
    assert_measure_minimize_match_8(&rows_8(b"10000000"));
    assert_measure_minimize_match_8(&rows_8(b"10000000000000000100000000000000"));
    assert_measure_minimize_match_8(&rows_8(b"10000000000000000000000000000000"));
    assert_measure_minimize_match_8(&rows_8(
        b"1000000000000000000000000000000000000000000000000000000000000000",
    ));
    assert_measure_minimize_match_8(&rows_8(
        b"1000000000000000001000000000000000010000000000000000000100000000",
    ));
}

#[test]
fn synthetic_chart_minimization_matches_rssp_core() {
    assert_chart_minimize_match(b"");
    assert_chart_minimize_match(
        b"
1000
0000
0100
0000
,
0000
0010
0000
0001
;
",
    );
    assert_chart_minimize_match(
        b"
// ignored
1000
0000
0000
0000
;
",
    );
}

#[test]
fn synthetic_8_panel_chart_minimization_matches_rssp_core() {
    assert_chart_minimize_match_8(b"");
    assert_chart_minimize_match_8(b"10000000\n;");
    assert_chart_minimize_match_8(
        b"
10000000
00000000
01000000
00000000
,
00000000
00100000
00000000
00000001
;
",
    );
    assert_chart_minimize_match_8(
        b"
// ignored
10000000
00000000
00000000
00000000
;
",
    );
}

#[test]
fn fixture_measures_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    for measure in parse_measures_4(notes) {
        assert_measure_minimize_match(&measure);
    }
}

#[test]
fn ssc_fixture_chart_minimization_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    assert_chart_minimize_match(notes);
}

#[test]
fn sm_fixture_measures_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    for measure in parse_measures_4(notes) {
        assert_measure_minimize_match(&measure);
    }
}

#[test]
fn sm_fixture_chart_minimization_matches_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    assert_chart_minimize_match(notes);
}
