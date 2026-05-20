use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{
    StreamCounts, StreamSegment, StreamToken, BREAKDOWN_DETAILED, BREAKDOWN_SIMPLIFIED,
    STREAM_BREAKDOWN_DETAILED, STREAM_BREAKDOWN_TOTAL,
};

unsafe extern "C" {
    fn assp_stream_counts_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamCounts,
    ) -> i32;
    fn assp_stream_percentages_centi(
        counts: *const StreamCounts,
        total_measures: usize,
        out_stream_percent: *mut i64,
        out_adjusted_stream_percent: *mut i64,
        out_break_percent: *mut i64,
    ) -> i32;
    fn assp_stream_segments_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_stream_tokens_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamToken,
        out_cap: usize,
    ) -> usize;
    fn assp_format_stream_tokens(
        tokens: *const StreamToken,
        len: usize,
        mode: u32,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_format_stream_segments(
        segments: *const StreamSegment,
        len: usize,
        level: u32,
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
        "{name}: {median:.0} cycles/call, {:.3} cycles/unit",
        median / work_units.max(1) as f64
    );
}

fn synthetic_densities(len: usize) -> Vec<u32> {
    let pattern = [0, 0, 16, 17, 4, 20, 22, 0, 0, 24, 31, 32, 48, 0, 0, 12];
    (0..len).map(|i| pattern[i % pattern.len()]).collect()
}

fn stream_segments(densities: &[u32]) -> Vec<StreamSegment> {
    let count = unsafe {
        assp_stream_segments_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamSegment::default(); count];
    unsafe {
        assp_stream_segments_from_densities(
            densities.as_ptr(),
            densities.len(),
            out.as_mut_ptr(),
            out.len(),
        );
    }
    out
}

fn stream_tokens(densities: &[u32]) -> Vec<StreamToken> {
    let count = unsafe {
        assp_stream_tokens_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamToken::default(); count];
    unsafe {
        assp_stream_tokens_from_densities(
            densities.as_ptr(),
            densities.len(),
            out.as_mut_ptr(),
            out.len(),
        );
    }
    out
}

#[test]
#[ignore]
fn stream_cycles() {
    let densities = synthetic_densities(4096);
    let segments = stream_segments(&densities);
    let tokens = stream_tokens(&densities);
    let mut counts = StreamCounts::default();
    let mut segments_out = vec![StreamSegment::default(); segments.len()];
    let mut tokens_out = vec![StreamToken::default(); tokens.len()];
    let mut bytes = vec![0u8; 16384];
    let empty_segments: [StreamSegment; 0] = [];

    bench(
        || unsafe {
            black_box(assp_stream_counts_from_densities(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(&mut counts),
            ));
        },
        "stream_counts_4096",
        10_000,
        densities.len(),
    );

    bench(
        || unsafe {
            let mut stream = 0;
            let mut adjusted = 0;
            let mut breaks = 0;
            black_box(assp_stream_percentages_centi(
                black_box(&counts),
                densities.len(),
                black_box(&mut stream),
                black_box(&mut adjusted),
                black_box(&mut breaks),
            ));
        },
        "stream_percentages",
        100_000,
        1,
    );

    bench(
        || unsafe {
            black_box(assp_stream_segments_from_densities(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(segments_out.as_mut_ptr()),
                segments_out.len(),
            ));
        },
        "stream_segments_4096",
        10_000,
        densities.len(),
    );

    bench(
        || unsafe {
            black_box(assp_stream_tokens_from_densities(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(tokens_out.as_mut_ptr()),
                tokens_out.len(),
            ));
        },
        "stream_tokens_4096",
        10_000,
        densities.len(),
    );

    bench(
        || unsafe {
            black_box(assp_format_stream_tokens(
                black_box(tokens.as_ptr()),
                tokens.len(),
                BREAKDOWN_DETAILED,
                black_box(bytes.as_mut_ptr()),
                bytes.len(),
            ));
        },
        "format_tokens_detailed",
        10_000,
        tokens.len(),
    );

    bench(
        || unsafe {
            black_box(assp_format_stream_tokens(
                black_box(tokens.as_ptr()),
                tokens.len(),
                BREAKDOWN_SIMPLIFIED,
                black_box(bytes.as_mut_ptr()),
                bytes.len(),
            ));
        },
        "format_tokens_simplified",
        10_000,
        tokens.len(),
    );

    bench(
        || unsafe {
            black_box(assp_format_stream_segments(
                black_box(segments.as_ptr()),
                segments.len(),
                STREAM_BREAKDOWN_DETAILED,
                black_box(bytes.as_mut_ptr()),
                bytes.len(),
            ));
        },
        "format_segments_detailed",
        10_000,
        segments.len(),
    );

    bench(
        || unsafe {
            black_box(assp_format_stream_segments(
                black_box(segments.as_ptr()),
                segments.len(),
                STREAM_BREAKDOWN_TOTAL,
                black_box(bytes.as_mut_ptr()),
                bytes.len(),
            ));
        },
        "format_segments_total",
        10_000,
        segments.len(),
    );

    bench(
        || unsafe {
            black_box(assp_format_stream_segments(
                black_box(empty_segments.as_ptr()),
                0,
                STREAM_BREAKDOWN_DETAILED,
                black_box(bytes.as_mut_ptr()),
                bytes.len(),
            ));
        },
        "format_segments_empty",
        100_000,
        1,
    );
}
