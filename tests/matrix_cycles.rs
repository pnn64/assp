use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{BpmSegment, parse_bpm_map};
use assp::{find_bpms_for_chart, find_chart_by_index, matrix_rating_centi, measure_densities_4};

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

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn chart_notes(data: &[u8], chart: usize) -> &[u8] {
    let info = find_chart_by_index(data, chart).unwrap();
    slice_from(data, info.note_data, info.note_data_len)
}

fn chart_bpms(data: &[u8], chart: usize) -> Vec<BpmSegment> {
    let bpms = find_bpms_for_chart(data, chart).unwrap();
    parse_bpm_map(slice_from(data, bpms.data, bpms.len)).unwrap()
}

fn variable_bpms() -> Vec<BpmSegment> {
    (0..256)
        .map(|i| BpmSegment {
            beat_milli: i * 16_000,
            bpm_milli: 90_000 + (i % 13) * 7_500,
        })
        .collect()
}

#[test]
#[ignore]
fn matrix_cycles() {
    let fixed_densities: Vec<u32> = (0..4096)
        .map(|i| match i & 3 {
            0 => 16,
            1 => 20,
            2 => 24,
            _ => 32,
        })
        .collect();
    let fixed_bpms = [BpmSegment {
        beat_milli: 0,
        bpm_milli: 180_000,
    }];

    let variable_densities: Vec<u32> = (0..4096)
        .map(|i| match (i * 7 + i / 5) & 7 {
            0 => 0,
            1 => 12,
            2 => 16,
            3 => 19,
            4 => 20,
            5 => 24,
            6 => 31,
            _ => 32,
        })
        .collect();
    let variable_bpms = variable_bpms();

    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let camellia_densities = measure_densities_4(camellia_notes);
    let camellia_bpms = chart_bpms(camellia, 4);

    let big = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let big_notes = chart_notes(big, 0);
    let big_densities = measure_densities_4(big_notes);
    let big_bpms = chart_bpms(big, 0);

    bench(
        || {
            black_box(matrix_rating_centi(
                black_box(&fixed_densities),
                black_box(&fixed_bpms),
            ));
        },
        "matrix_fixed_4096",
        1_000,
        fixed_densities.len(),
    );

    bench(
        || {
            black_box(matrix_rating_centi(
                black_box(&variable_densities),
                black_box(&variable_bpms),
            ));
        },
        "matrix_variable_4096x256",
        30,
        variable_densities.len() * variable_bpms.len(),
    );

    bench(
        || {
            black_box(matrix_rating_centi(
                black_box(&camellia_densities),
                black_box(&camellia_bpms),
            ));
        },
        "matrix_camellia_chart",
        300,
        camellia_densities.len() * camellia_bpms.len().max(1),
    );

    bench(
        || {
            black_box(matrix_rating_centi(
                black_box(&big_densities),
                black_box(&big_bpms),
            ));
        },
        "matrix_200k_chart",
        300,
        big_densities.len() * big_bpms.len().max(1),
    );
}
