use assp::parse_tech_notation;

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
