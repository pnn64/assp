use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;
use std::os::raw::c_int;

use assp::{ByteSlice, ChartInfo, TimingTags};

unsafe extern "C" {
    fn assp_count_note_charts(data: *const u8, len: usize) -> usize;
    fn assp_find_chart_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ChartInfo,
    ) -> c_int;
    fn assp_find_global_tag(
        data: *const u8,
        len: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_tag_in_range(
        data: *const u8,
        len: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_global_timing_tags(data: *const u8, len: usize, out: *mut TimingTags) -> c_int;
    fn assp_find_timing_tags_in_range(data: *const u8, len: usize, out: *mut TimingTags) -> c_int;
    fn assp_find_chart_timing_tags_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut TimingTags,
    ) -> c_int;
    fn assp_range_owns_timing(data: *const u8, len: usize) -> c_int;
    fn assp_chart_owns_timing_by_index(data: *const u8, len: usize, index: usize) -> c_int;
}

#[inline(always)]
fn ticks() -> u64 {
    unsafe {
        _mm_lfence();
        let t = _rdtsc();
        _mm_lfence();
        t
    }
}

fn bench(mut f: impl FnMut(), name: &str, iters: usize, work_units: usize) {
    let mut samples = Vec::with_capacity(17);
    for _ in 0..17 {
        let start = ticks();
        for _ in 0..iters {
            f();
        }
        let elapsed = ticks() - start;
        samples.push(elapsed as f64 / iters as f64);
    }
    samples.sort_by(|a, b| a.total_cmp(b));
    let median = samples[samples.len() / 2];
    println!(
        "{name}: {median:.0} cycles/call, {:.3} cycles/byte",
        median / work_units.max(1) as f64
    );
}

fn long_value(seed: usize, len: usize) -> String {
    let mut value = String::with_capacity(len);
    for i in 0..len {
        let b = b'a' + ((seed + i) % 26) as u8;
        value.push(b as char);
    }
    value
}

fn global_metadata_without_timing(tags: usize, value_len: usize) -> Vec<u8> {
    let mut data = Vec::new();
    for i in 0..tags {
        data.extend_from_slice(b"#TITLE");
        data.extend_from_slice(i.to_string().as_bytes());
        data.push(b':');
        data.extend_from_slice(long_value(i, value_len).as_bytes());
        data.push(b';');
    }
    data.extend_from_slice(b"#NOTES:0000\n;\n");
    data
}

fn chart_metadata_without_timing(tags: usize, value_len: usize) -> Vec<u8> {
    let mut data = b"#BPMS:0.000=140.000;\n#NOTEDATA:;\n#STEPSTYPE:dance-single;\n".to_vec();
    for i in 0..tags {
        data.extend_from_slice(b"#DISPLAYBPM");
        data.extend_from_slice(i.to_string().as_bytes());
        data.push(b':');
        data.extend_from_slice(long_value(i, value_len).as_bytes());
        data.extend_from_slice(b";\n");
    }
    data.extend_from_slice(b"#NOTES:\n1000\n;\n");
    data
}

fn chart_metadata_with_timing(tags: usize, value_len: usize) -> Vec<u8> {
    let mut data = b"#TITLE:X;\n#NOTEDATA:;\n#STEPSTYPE:dance-single;\n".to_vec();
    for i in 0..tags {
        data.extend_from_slice(b"#DISPLAYBPM");
        data.extend_from_slice(i.to_string().as_bytes());
        data.push(b':');
        data.extend_from_slice(long_value(i, value_len).as_bytes());
        data.extend_from_slice(b";\n");
    }
    data.extend_from_slice(b"#BPMS:0.000=175.000;\n#STOPS:4.000=0.250;\n#DELAYS:8.000=0.125;\n");
    data.extend_from_slice(
        b"#WARPS:12.000=4.000;\n#SPEEDS:0.000=1.500=0.000=0;\n#SCROLLS:0.000=1.000;\n#FAKES:16.000=4.000;\n",
    );
    data.extend_from_slice(b"#NOTES:\n1000\n;\n");
    data
}

fn chart_metadata_range(data: &[u8]) -> &[u8] {
    let mut info = ChartInfo::default();
    let ok = unsafe {
        assp_find_chart_by_index(
            data.as_ptr(),
            data.len(),
            0,
            black_box(&mut info as *mut ChartInfo),
        )
    };
    assert_ne!(ok, 0);
    let start = info.metadata as usize - data.as_ptr() as usize;
    &data[start..start + info.metadata_len]
}

#[test]
#[ignore]
fn simfile_cycles() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let big_sm = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let global_no_timing = global_metadata_without_timing(96, 384);
    let chart_no_timing = chart_metadata_without_timing(96, 384);
    let chart_with_timing = chart_metadata_with_timing(48, 256);
    let chart_no_timing_range = chart_metadata_range(&chart_no_timing);
    let chart_with_timing_range = chart_metadata_range(&chart_with_timing);

    bench(
        || unsafe {
            black_box(assp_count_note_charts(
                black_box(big_sm.as_ptr()),
                black_box(big_sm.len()),
            ));
        },
        "count_note_charts big sm",
        50,
        big_sm.len(),
    );

    bench(
        || unsafe {
            let mut info = ChartInfo::default();
            black_box(assp_find_chart_by_index(
                black_box(camellia.as_ptr()),
                black_box(camellia.len()),
                black_box(4),
                black_box(&mut info as *mut ChartInfo),
            ));
        },
        "find_chart_by_index camellia",
        200,
        camellia.len(),
    );

    bench(
        || unsafe {
            let mut out = ByteSlice::default();
            black_box(assp_find_global_tag(
                black_box(global_no_timing.as_ptr()),
                black_box(global_no_timing.len()),
                black_box(b"#MISSING:".as_ptr()),
                black_box(b"#MISSING:".len()),
                black_box(&mut out as *mut ByteSlice),
            ));
        },
        "find_global_tag missing long metadata",
        50,
        global_no_timing.len(),
    );

    bench(
        || unsafe {
            let mut out = ByteSlice::default();
            black_box(assp_find_tag_in_range(
                black_box(chart_no_timing_range.as_ptr()),
                black_box(chart_no_timing_range.len()),
                black_box(b"#MISSING:".as_ptr()),
                black_box(b"#MISSING:".len()),
                black_box(&mut out as *mut ByteSlice),
            ));
        },
        "find_tag_in_range missing chart metadata",
        50,
        chart_no_timing_range.len(),
    );

    bench(
        || unsafe {
            let mut tags = TimingTags::default();
            black_box(assp_find_global_timing_tags(
                black_box(global_no_timing.as_ptr()),
                black_box(global_no_timing.len()),
                black_box(&mut tags as *mut TimingTags),
            ));
        },
        "find_global_timing_tags no timing",
        25,
        global_no_timing.len(),
    );

    bench(
        || unsafe {
            let mut tags = TimingTags::default();
            black_box(assp_find_timing_tags_in_range(
                black_box(chart_with_timing_range.as_ptr()),
                black_box(chart_with_timing_range.len()),
                black_box(&mut tags as *mut TimingTags),
            ));
        },
        "find_timing_tags_in_range all tags",
        25,
        chart_with_timing_range.len(),
    );

    bench(
        || unsafe {
            let mut tags = TimingTags::default();
            black_box(assp_find_chart_timing_tags_by_index(
                black_box(chart_with_timing.as_ptr()),
                black_box(chart_with_timing.len()),
                black_box(0),
                black_box(&mut tags as *mut TimingTags),
            ));
        },
        "find_chart_timing_tags_by_index all tags",
        25,
        chart_with_timing.len(),
    );

    bench(
        || unsafe {
            black_box(assp_range_owns_timing(
                black_box(chart_no_timing_range.as_ptr()),
                black_box(chart_no_timing_range.len()),
            ));
        },
        "range_owns_timing no timing",
        25,
        chart_no_timing_range.len(),
    );

    bench(
        || unsafe {
            black_box(assp_chart_owns_timing_by_index(
                black_box(chart_no_timing.as_ptr()),
                black_box(chart_no_timing.len()),
                black_box(0),
            ));
        },
        "chart_owns_timing_by_index no timing",
        25,
        chart_no_timing.len(),
    );
}
