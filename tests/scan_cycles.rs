use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

unsafe extern "C" {
    fn assp_find_byte(data: *const u8, len: usize, byte: u32) -> usize;
    fn assp_count_timing_segments(data: *const u8, len: usize) -> usize;
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

#[test]
#[ignore]
fn scan_cycles() {
    let mut long = vec![b'a'; 1 << 20];
    let short = vec![b'a'; 31];
    let mut timing = Vec::with_capacity(256 * 20);
    for i in 0..256 {
        if i != 0 {
            timing.push(b',');
        }
        if i % 11 == 0 {
            timing.extend_from_slice(b"  ");
        } else {
            timing.extend_from_slice(format!("{}=120.000", i * 4).as_bytes());
        }
    }
    long[(1 << 20) - 1] = b'#';

    bench(
        || unsafe {
            black_box(assp_find_byte(
                black_box(long.as_ptr()),
                black_box(long.len()),
                b'#' as u32,
            ));
        },
        "find_byte_1m_last",
        1_000,
        long.len(),
    );

    bench(
        || unsafe {
            black_box(assp_find_byte(
                black_box(long.as_ptr()),
                black_box(long.len()),
                b'z' as u32,
            ));
        },
        "find_byte_1m_missing",
        1_000,
        long.len(),
    );

    bench(
        || unsafe {
            black_box(assp_find_byte(
                black_box(short.as_ptr()),
                black_box(short.len()),
                b'z' as u32,
            ));
        },
        "find_byte_31_missing",
        1_000_000,
        short.len(),
    );

    bench(
        || unsafe {
            black_box(assp_find_byte(
                black_box(long.as_ptr()),
                black_box(long.len()),
                b'a' as u32,
            ));
        },
        "find_byte_first",
        1_000_000,
        1,
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_segments(
                black_box(timing.as_ptr()),
                black_box(timing.len()),
            ));
        },
        "count_timing_segments_256",
        100_000,
        timing.len(),
    );
}
