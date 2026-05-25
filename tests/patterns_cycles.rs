use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;
use std::os::raw::c_int;

use assp::{BasicPatterns, PATTERN_COUNT, find_chart_by_index, minimize_chart_4};

unsafe extern "C" {
    fn assp_count_anchors_minimized_4(data: *const u8, len: usize, out: *mut u32) -> c_int;
    fn assp_count_facing_steps_minimized_4(
        data: *const u8,
        len: usize,
        mono_threshold: usize,
        out: *mut u32,
    ) -> c_int;
    fn assp_count_basic_patterns_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut BasicPatterns,
    ) -> c_int;
    fn assp_count_default_patterns_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut u32,
    ) -> c_int;
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

fn chart_notes(data: &[u8], chart: usize) -> &[u8] {
    let info = find_chart_by_index(data, chart).unwrap();
    let start = info.note_data as usize - data.as_ptr() as usize;
    &data[start..start + info.note_data_len]
}

fn synthetic_chart(measures: usize, rows_per_measure: usize) -> Vec<u8> {
    let rows = [
        b"1000\n", b"0100\n", b"0010\n", b"0001\n", b"0011\n", b"1100\n", b"0000\n",
    ];
    let mut out = Vec::with_capacity(measures * rows_per_measure * 5 + measures * 2 + 2);
    for measure in 0..measures {
        for row in 0..rows_per_measure {
            out.extend_from_slice(rows[(measure + row) % rows.len()]);
        }
        out.extend_from_slice(b",\n");
    }
    out.extend_from_slice(b";\n");
    out
}

#[test]
#[ignore]
fn patterns_cycles() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let big = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let big_notes = chart_notes(big, 0);
    let camellia_min = minimize_chart_4(camellia_notes).unwrap();
    let big_min = minimize_chart_4(big_notes).unwrap();
    let synthetic = synthetic_chart(4096, 16);
    let synthetic_min = minimize_chart_4(&synthetic).unwrap();

    let mut basic = BasicPatterns::default();
    let mut default = [0u32; PATTERN_COUNT];
    let mut anchors = [0u32; 4];
    let mut facing = [0u32; 2];

    bench(
        || unsafe {
            black_box(assp_count_default_patterns_minimized_4(
                black_box(camellia_min.as_ptr()),
                black_box(camellia_min.len()),
                black_box(default.as_mut_ptr()),
            ));
        },
        "default_patterns_min_4_camellia",
        300,
        camellia_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_default_patterns_minimized_4(
                black_box(big_min.as_ptr()),
                black_box(big_min.len()),
                black_box(default.as_mut_ptr()),
            ));
        },
        "default_patterns_min_4_200k",
        300,
        big_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_default_patterns_minimized_4(
                black_box(synthetic_min.as_ptr()),
                black_box(synthetic_min.len()),
                black_box(default.as_mut_ptr()),
            ));
        },
        "default_patterns_min_4_synthetic",
        100,
        synthetic_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_basic_patterns_minimized_4(
                black_box(camellia_min.as_ptr()),
                black_box(camellia_min.len()),
                black_box(&mut basic),
            ));
        },
        "basic_patterns_min_4_camellia",
        300,
        camellia_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_anchors_minimized_4(
                black_box(camellia_min.as_ptr()),
                black_box(camellia_min.len()),
                black_box(anchors.as_mut_ptr()),
            ));
        },
        "anchors_min_4_camellia",
        300,
        camellia_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_facing_steps_minimized_4(
                black_box(camellia_min.as_ptr()),
                black_box(camellia_min.len()),
                black_box(0),
                black_box(facing.as_mut_ptr()),
            ));
        },
        "facing_min_4_camellia",
        300,
        camellia_min.len(),
    );
}
