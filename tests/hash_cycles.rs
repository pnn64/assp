use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{
    chart_hash_pair, find_bpms_for_chart, find_chart_by_index, md5_hex, minimize_chart_4,
    normalize_float_digits, sha1_short_hex2,
};

fn slice_from<'a>(data: &'a [u8], ptr: *const u8, len: usize) -> &'a [u8] {
    let start = ptr as usize - data.as_ptr() as usize;
    &data[start..start + len]
}

fn truncate_hash_newlines(data: &mut Vec<u8>) {
    while data.last() == Some(&b'\n') {
        data.pop();
    }
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
    let cycles_per_byte = median / bytes_per_iter.max(1) as f64;
    println!("{name}: {median:.0} cycles/call, {cycles_per_byte:.3} cycles/byte");
}

#[test]
#[ignore]
fn hash_cycles_camellia_chart() {
    let simfile = include_bytes!("../fixtures/camellia_mix.ssc");
    let chart = find_chart_by_index(simfile, 4).unwrap();
    let notes = slice_from(simfile, chart.note_data, chart.note_data_len);
    let mut minimized = minimize_chart_4(notes).unwrap();
    truncate_hash_newlines(&mut minimized);

    let bpms = find_bpms_for_chart(simfile, 4).unwrap();
    let raw_bpms = slice_from(simfile, bpms.data, bpms.len);
    let normalized = normalize_float_digits(raw_bpms).unwrap();

    let chart_hash_bytes = minimized.len() + normalized.len() + "0.000=0.000".len();

    bench(
        || {
            black_box(chart_hash_pair(black_box(&minimized), black_box(&normalized)).unwrap());
        },
        "chart_hash_pair",
        100,
        chart_hash_bytes,
    );
    bench(
        || {
            black_box(sha1_short_hex2(black_box(&minimized), black_box(&normalized)).unwrap());
        },
        "sha1_short_hex2_chart",
        100,
        minimized.len() + normalized.len(),
    );
    bench(
        || {
            black_box(md5_hex(black_box(simfile)).unwrap());
        },
        "md5_hex_file",
        100,
        simfile.len(),
    );

    bench(
        || {
            black_box(sha1_short_hex2(black_box(b"abc"), black_box(b"def")).unwrap());
        },
        "sha1_short_hex2_6b",
        100_000,
        6,
    );

    bench(
        || {
            black_box(md5_hex(black_box(b"The quick brown fox jumps over the lazy dog")).unwrap());
        },
        "md5_hex_43b",
        100_000,
        43,
    );
}
