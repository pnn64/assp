use assp::{find_chart_by_index, minimize_measure_4};
use rssp_core::stats::minimize_measure;

fn assert_measure_minimize_match(rows: &[[u8; 4]]) {
    let asm = minimize_measure_4(rows);
    let mut rust = rows.to_vec();
    minimize_measure(&mut rust);

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

#[test]
fn synthetic_measure_minimization_matches_rssp_core() {
    assert_measure_minimize_match(&[]);
    assert_measure_minimize_match(&rows(b"1000000001000000"));
    assert_measure_minimize_match(&rows(b"1000000000000000"));
    assert_measure_minimize_match(&rows(b"10000000000000000000000000000000"));
    assert_measure_minimize_match(&rows(b"10000000010000000010000000010000"));
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
fn sm_fixture_measures_match_rssp_core() {
    let simfile = include_bytes!("../fixtures/200000_step_challenge.sm");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let start = chart.note_data as usize - simfile.as_ptr() as usize;
    let notes = &simfile[start..start + chart.note_data_len];

    for measure in parse_measures_4(notes) {
        assert_measure_minimize_match(&measure);
    }
}
