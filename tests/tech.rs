use assp::{
    TechCounts, count_step_tech_brackets_minimized_4, count_step_tech_brackets_minimized_8,
    parse_tech_notation,
};

fn parse(credit: &str, description: &str) -> String {
    String::from_utf8(parse_tech_notation(credit.as_bytes(), description.as_bytes()).unwrap())
        .unwrap()
}

fn assert_matches_rssp(credit: &str, description: &str) {
    assert_eq!(
        parse(credit, description),
        rssp_core::tech::parse_tech_notation(credit, description)
    );
}

fn assert_only_brackets(counts: TechCounts, brackets: u32) {
    assert_eq!(
        counts,
        TechCounts {
            brackets,
            ..TechCounts::default()
        }
    );
}

fn assert_brackets_match_rssp(data: &[u8], lanes: usize, counts: TechCounts) {
    let expected = rssp_core::step_parity::analyze_lanes(data, &[(0.0, 120.0)], 0.0, lanes);
    assert_eq!(counts.brackets, expected.brackets);
    assert_only_brackets(counts, expected.brackets);
}

fn assert_basic_tech_match_rssp(data: &[u8], lanes: usize, counts: TechCounts) {
    let expected = rssp_core::step_parity::analyze_lanes(data, &[(0.0, 120.0)], 0.0, lanes);
    assert_eq!(
        counts,
        TechCounts {
            crossovers: expected.crossovers,
            brackets: expected.brackets,
            ..TechCounts::default()
        }
    );
}

#[test]
fn parses_known_tech_list_like_rssp_core() {
    const KNOWN: &str = concat!(
        "24ths 32nds br BR BR+ BR- BT BT+ BT- bu BU BU+ BU- ",
        "BXF BXF+ BXF- bXF bXF+ bXF- BxF BXf BxF+ BxF- ",
        "bXf bXf+ bXf- bxF bxF+ bxF- B+XF BX-F BX-F+ BX+F+ ",
        "B+X-F B-X-F- B-XF+ ds DS DS++ DS+ DS- dr DR DR+ DR- ",
        "dt dt- DT DT+ DT- FL FL+ FL- fs FS FS+ FS- FX FX+ FX- ",
        "GH GH+ GH- HA HA+ HA- HS HS+ HS- ITL+ ja ja- JA JA+ JA- ",
        "ju ju- JU JU+ JU- JUMPS JUMPS+ JUMPS- KS KS+ KS- KT KT+ KT- ",
        "LOL ma ma- MA MA+ MA- MD MD+ MD- rh rh- RH RH+ RH- Rolls- ",
        "RS RS+ RS- SC SC+ SC- SDS SDS+ SDS- SJ SJ+ SJ- SK SK+ SK- ",
        "SS SS+ SS- SKT SKT+ SKT- SPD SPD+ SPD- STR STR+ STR- ",
        "TR TR+ TR- WA WA+ WA- XMOD XMOD+ XMOD- xo XO XO+ XO-"
    );

    assert_matches_rssp(KNOWN, "");
}

#[test]
fn skips_no_tech_measure_data_and_invalid_chunks_like_rssp_core() {
    assert_matches_rssp("No Tech STR+bad /--- 1234", "FS-,No Tech BXF");
}

#[test]
fn parses_concatenated_chunks_with_longest_prefixes_like_rssp_core() {
    assert_matches_rssp("BXF+BX-F+B-X-F-", "BT+JUMPS+Rolls-");
}

#[test]
fn combines_credit_and_description_like_rssp_core() {
    assert_matches_rssp("STR+ FS-", "BXF,24ths 32nds");
}

#[test]
fn counts_single_panel_timing_hold_fixture_bracket_like_rssp_core() {
    let data = b"2000\n0000\n0100\n3000\n,\n4000\n0000\n0011\n3000\n";
    let counts = count_step_tech_brackets_minimized_4(data).unwrap();
    assert_brackets_match_rssp(data, 4, counts);
}

#[test]
fn counts_single_panel_three_row_crossovers_like_rssp_core() {
    for data in [
        b"1000\n0100\n0001\n".as_slice(),
        b"0001\n0100\n1000\n".as_slice(),
        b"1000\n0010\n0001\n".as_slice(),
        b"0001\n0010\n1000\n".as_slice(),
    ] {
        let counts = count_step_tech_brackets_minimized_4(data).unwrap();
        assert_basic_tech_match_rssp(data, 4, counts);
    }
}

#[test]
fn skips_single_panel_non_crossover_tap_patterns_like_rssp_core() {
    for data in [
        b"0100\n1000\n0001\n".as_slice(),
        b"0010\n0001\n1000\n".as_slice(),
        b"1000\n0100\n0010\n0001\n".as_slice(),
        b"0001\n0010\n0100\n1000\n".as_slice(),
    ] {
        let counts = count_step_tech_brackets_minimized_4(data).unwrap();
        assert_basic_tech_match_rssp(data, 4, counts);
    }
}

#[test]
fn skips_single_panel_first_row_brackets_like_rssp_core() {
    let counts = count_step_tech_brackets_minimized_4(b"0011\n").unwrap();
    assert_only_brackets(counts, 0);
}

#[test]
fn skips_single_panel_no_hold_bracketable_jump_like_rssp_core() {
    let data = b"1000\n0011\n";
    let counts = count_step_tech_brackets_minimized_4(data).unwrap();
    assert_brackets_match_rssp(data, 4, counts);
}

#[test]
fn skips_double_panel_no_hold_bracketable_jump_like_rssp_core() {
    let data = b"10000000\n00000000\n00000001\n00000000\n,\n00000000\n00110000\n0000000M\n";
    let counts = count_step_tech_brackets_minimized_8(data).unwrap();
    assert_brackets_match_rssp(data, 8, counts);
}

#[test]
fn counts_double_panel_timing_hold_fixture_bracket_like_rssp_core() {
    let data =
        b"20000000\n00000000\n01000000\n30000000\n,\n00004000\n00000000\n00110000\n00003000\n";
    let counts = count_step_tech_brackets_minimized_8(data).unwrap();
    assert_brackets_match_rssp(data, 8, counts);
}
