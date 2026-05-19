use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{find_chart_by_index, last_beat_milli_4, last_beat_milli_8};

#[inline(always)]
fn ticks() -> u64 {
    unsafe {
        _mm_lfence();
        let t = _rdtsc();
        _mm_lfence();
        t
    }
}

fn bench(mut f: impl FnMut(), name: &str, iters: usize, bytes_per_iter: usize) {
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
        median / bytes_per_iter.max(1) as f64
    );
}

fn chart_notes(data: &[u8], chart: usize) -> &[u8] {
    let info = find_chart_by_index(data, chart).unwrap();
    let start = info.note_data as usize - data.as_ptr() as usize;
    &data[start..start + info.note_data_len]
}

fn synthetic_notes(lanes: usize, measures: usize, rows_per_measure: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(measures * rows_per_measure * (lanes + 1));
    for measure in 0..measures {
        for row in 0..rows_per_measure {
            for lane in 0..lanes {
                let ch = match (measure + row + lane) % 23 {
                    0 => b'1',
                    5 => b'M',
                    9 => b'L',
                    13 => b'F',
                    17 => b'K',
                    19 => b'2',
                    20 => b'3',
                    _ => b'0',
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
fn duration_cycles() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let big = include_bytes!("../fixtures/200000_step_challenge.sm").as_slice();
    let big_notes = chart_notes(big, 0);
    let double = include_bytes!("../fixtures/dance_double_timing_holds.ssc").as_slice();
    let double_notes = chart_notes(double, 0);
    let synthetic_4 = synthetic_notes(4, 4096, 16);
    let synthetic_8 = synthetic_notes(8, 4096, 16);

    bench(
        || {
            black_box(last_beat_milli_4(black_box(camellia_notes)).unwrap());
        },
        "last_beat_4_camellia",
        300,
        camellia_notes.len(),
    );

    bench(
        || {
            black_box(last_beat_milli_4(black_box(big_notes)).unwrap());
        },
        "last_beat_4_200k",
        100,
        big_notes.len(),
    );

    bench(
        || {
            black_box(last_beat_milli_8(black_box(double_notes)).unwrap());
        },
        "last_beat_8_double",
        10_000,
        double_notes.len(),
    );

    bench(
        || {
            black_box(last_beat_milli_4(black_box(&synthetic_4)).unwrap());
        },
        "last_beat_4_synthetic",
        100,
        synthetic_4.len(),
    );

    bench(
        || {
            black_box(last_beat_milli_8(black_box(&synthetic_8)).unwrap());
        },
        "last_beat_8_synthetic",
        100,
        synthetic_8.len(),
    );
}
