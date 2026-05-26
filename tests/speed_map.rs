#[repr(C)]
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
struct SpeedSegment {
    beat_milli: i64,
    ratio_micro: i64,
    delay_micro: i64,
    unit: i64,
}

unsafe extern "C" {
    fn assp_parse_speed_map(
        data: *const u8,
        len: usize,
        out: *mut SpeedSegment,
        out_cap: usize,
    ) -> usize;
}

fn parse_speed_map(input: &[u8]) -> Vec<SpeedSegment> {
    let count =
        unsafe { assp_parse_speed_map(input.as_ptr(), input.len(), std::ptr::null_mut(), 0) };
    assert_ne!(count, usize::MAX);

    let mut out = vec![SpeedSegment::default(); count];
    let written =
        unsafe { assp_parse_speed_map(input.as_ptr(), input.len(), out.as_mut_ptr(), count) };
    assert_eq!(written, count);
    out
}

#[test]
fn parses_speed_map_entries() {
    let parsed =
        parse_speed_map(b"4.000=1.250000=-0.500000=1, bad, 0.000=0.500000=0.000000=0, 48r=2=1");

    assert_eq!(
        parsed,
        vec![
            SpeedSegment {
                beat_milli: 0,
                ratio_micro: 500_000,
                delay_micro: 0,
                unit: 0,
            },
            SpeedSegment {
                beat_milli: 1_000,
                ratio_micro: 2_000_000,
                delay_micro: 1_000_000,
                unit: 0,
            },
            SpeedSegment {
                beat_milli: 4_000,
                ratio_micro: 1_250_000,
                delay_micro: -500_000,
                unit: 1,
            },
        ]
    );
}
