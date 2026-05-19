use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::find_chart_by_index;

unsafe extern "C" {
    fn assp_minimize_measure_4(
        rows: *const u8,
        row_count: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_measure_8(
        rows: *const u8,
        row_count: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_chart_4(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
        row_scratch: *mut u8,
        row_scratch_cap: usize,
    ) -> usize;
    fn assp_minimize_chart_8(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
        row_scratch: *mut u8,
        row_scratch_cap: usize,
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
        "{name}: {median:.0} cycles/call, {:.3} cycles/unit",
        median / work_units.max(1) as f64
    );
}

fn chart_notes(data: &[u8], chart: usize) -> &[u8] {
    let info = find_chart_by_index(data, chart).unwrap();
    let start = info.note_data as usize - data.as_ptr() as usize;
    &data[start..start + info.note_data_len]
}

fn synthetic_chart(lanes: usize, measures: usize, rows_per_measure: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(measures * rows_per_measure * (lanes + 1));
    for measure in 0..measures {
        for row in 0..rows_per_measure {
            for lane in 0..lanes {
                let ch = if row == 0 && lane == measure % lanes {
                    b'1'
                } else if row % 8 == 0 && lane == (measure + 1) % lanes {
                    b'1'
                } else {
                    b'0'
                };
                data.push(ch);
            }
            data.push(b'\n');
        }
        data.extend_from_slice(b",\n");
    }
    data.push(b';');
    data
}

#[test]
#[ignore]
fn minimize_cycles() {
    let rows4: Vec<[u8; 4]> = (0..4096)
        .map(|i| {
            if i % 8 == 0 {
                [b'1', b'0', b'0', b'0']
            } else {
                [b'0'; 4]
            }
        })
        .collect();
    let rows8: Vec<[u8; 8]> = (0..4096)
        .map(|i| {
            if i % 8 == 0 {
                [b'1', b'0', b'0', b'0', b'0', b'0', b'0', b'0']
            } else {
                [b'0'; 8]
            }
        })
        .collect();
    let mut rows4_out = vec![[0u8; 4]; rows4.len()];
    let mut rows8_out = vec![[0u8; 8]; rows8.len()];

    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let big = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let big_notes = chart_notes(big, 0);
    let double = include_bytes!("../fixtures/dance_double_timing_holds.ssc").as_slice();
    let double_notes = chart_notes(double, 0);
    let synthetic4 = synthetic_chart(4, 4096, 16);
    let synthetic8 = synthetic_chart(8, 4096, 16);

    let mut out = vec![0u8; camellia_notes.len().max(big_notes.len()).max(synthetic8.len()) + 32];
    let mut scratch4 = vec![[0u8; 4]; out.len() / 4 + 1];
    let mut scratch8 = vec![[0u8; 8]; out.len() / 8 + 1];

    bench(
        || unsafe {
            black_box(assp_minimize_measure_4(
                black_box(rows4.as_ptr().cast::<u8>()),
                rows4.len(),
                black_box(rows4_out.as_mut_ptr().cast::<u8>()),
                rows4_out.len(),
            ));
        },
        "minimize_measure_4_4096",
        10_000,
        rows4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_measure_8(
                black_box(rows8.as_ptr().cast::<u8>()),
                rows8.len(),
                black_box(rows8_out.as_mut_ptr().cast::<u8>()),
                rows8_out.len(),
            ));
        },
        "minimize_measure_8_4096",
        10_000,
        rows8.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_chart_4(
                black_box(camellia_notes.as_ptr()),
                camellia_notes.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
                black_box(scratch4.as_mut_ptr().cast::<u8>()),
                scratch4.len(),
            ));
        },
        "minimize_chart_4_camellia",
        300,
        camellia_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_chart_4(
                black_box(big_notes.as_ptr()),
                big_notes.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
                black_box(scratch4.as_mut_ptr().cast::<u8>()),
                scratch4.len(),
            ));
        },
        "minimize_chart_4_200k",
        100,
        big_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_chart_8(
                black_box(double_notes.as_ptr()),
                double_notes.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
                black_box(scratch8.as_mut_ptr().cast::<u8>()),
                scratch8.len(),
            ));
        },
        "minimize_chart_8_double",
        10_000,
        double_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_chart_4(
                black_box(synthetic4.as_ptr()),
                synthetic4.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
                black_box(scratch4.as_mut_ptr().cast::<u8>()),
                scratch4.len(),
            ));
        },
        "minimize_chart_4_synthetic",
        100,
        synthetic4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_minimize_chart_8(
                black_box(synthetic8.as_ptr()),
                synthetic8.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
                black_box(scratch8.as_mut_ptr().cast::<u8>()),
                scratch8.len(),
            ));
        },
        "minimize_chart_8_synthetic",
        100,
        synthetic8.len(),
    );
}
