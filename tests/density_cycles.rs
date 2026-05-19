use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{find_chart_by_index, minimize_chart_4, minimize_chart_8};

unsafe extern "C" {
    fn assp_measure_densities_4(
        data: *const u8,
        len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_densities_8(
        data: *const u8,
        len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_equally_spaced_minimized_4(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_equally_spaced_minimized_8(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
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

#[test]
#[ignore]
fn density_cycles() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let big = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let big_notes = chart_notes(big, 0);
    let double = include_bytes!("../fixtures/dance_double_timing_holds.ssc").as_slice();
    let double_notes = chart_notes(double, 0);
    let camellia_min = minimize_chart_4(camellia_notes).unwrap();
    let double_min = minimize_chart_8(double_notes).unwrap();

    let mut density_out = vec![0u32; 131_072];
    let mut bool_out = vec![0u8; 131_072];

    bench(
        || unsafe {
            black_box(assp_measure_densities_4(
                black_box(camellia_notes.as_ptr()),
                camellia_notes.len(),
                black_box(density_out.as_mut_ptr()),
                density_out.len(),
            ));
        },
        "density_4_camellia",
        300,
        camellia_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_measure_densities_4(
                black_box(big_notes.as_ptr()),
                big_notes.len(),
                black_box(density_out.as_mut_ptr()),
                density_out.len(),
            ));
        },
        "density_4_200k",
        80,
        big_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_measure_densities_8(
                black_box(double_notes.as_ptr()),
                double_notes.len(),
                black_box(density_out.as_mut_ptr()),
                density_out.len(),
            ));
        },
        "density_8_double",
        10_000,
        double_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_measure_equally_spaced_minimized_4(
                black_box(camellia_min.as_ptr()),
                camellia_min.len(),
                black_box(bool_out.as_mut_ptr()),
                bool_out.len(),
            ));
        },
        "equally_min_4_camellia",
        300,
        camellia_min.len(),
    );

    bench(
        || unsafe {
            black_box(assp_measure_equally_spaced_minimized_8(
                black_box(double_min.as_ptr()),
                double_min.len(),
                black_box(bool_out.as_mut_ptr()),
                bool_out.len(),
            ));
        },
        "equally_min_8_double",
        10_000,
        double_min.len(),
    );
}
