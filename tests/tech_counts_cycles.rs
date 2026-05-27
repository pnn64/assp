use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;
use std::os::raw::c_int;

use assp::TechCounts;

unsafe extern "C" {
    fn assp_calculate_step_tech_counts_from_placements_4(
        tech_masks: *const u8,
        note_counts: *const u8,
        row_ms: *const i32,
        placements: *const u8,
        row_count: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_calculate_step_tech_counts_from_placements_seconds_4(
        tech_masks: *const u8,
        note_counts: *const u8,
        row_seconds: *const f32,
        placements: *const u8,
        row_count: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_calculate_step_tech_counts_from_placements_8(
        tech_masks: *const u8,
        note_counts: *const u8,
        row_ms: *const i32,
        placements: *const u8,
        row_count: usize,
        out: *mut TechCounts,
    ) -> c_int;
    fn assp_calculate_step_tech_counts_from_placements_seconds_8(
        tech_masks: *const u8,
        note_counts: *const u8,
        row_seconds: *const f32,
        placements: *const u8,
        row_count: usize,
        out: *mut TechCounts,
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
        "{name}: {median:.0} cycles/call, {:.3} cycles/unit",
        median / work_units.max(1) as f64
    );
}

fn synthetic_rows(row_count: usize) -> (Vec<u8>, Vec<u8>, Vec<i32>, Vec<f32>, Vec<u8>) {
    let row_patterns = [
        (0b0010u8, 1u8, [0u8, 1, 0, 0]),
        (0b0010, 1, [0, 3, 0, 0]),
        (0b0100, 1, [0, 0, 2, 0]),
        (0b0100, 1, [0, 0, 4, 0]),
        (0b0011, 2, [1, 2, 0, 0]),
        (0b1100, 2, [0, 0, 3, 4]),
        (0b1001, 2, [1, 0, 0, 4]),
        (0b0110, 2, [0, 2, 3, 0]),
    ];

    let mut tech_masks = Vec::with_capacity(row_count);
    let mut note_counts = Vec::with_capacity(row_count);
    let mut row_ms = Vec::with_capacity(row_count);
    let mut row_seconds = Vec::with_capacity(row_count);
    let mut placements = Vec::with_capacity(row_count * 4);
    let mut ms = 0i32;
    let mut seconds = 0.0f32;

    for row in 0..row_count {
        let (mask, count, placement) = row_patterns[row % row_patterns.len()];
        tech_masks.push(mask);
        note_counts.push(count);
        row_ms.push(ms);
        row_seconds.push(seconds);
        placements.extend_from_slice(&placement);
        let delta_ms = if row % 5 == 0 { 120 } else { 80 };
        ms += delta_ms;
        seconds += delta_ms as f32 / 1000.0;
    }

    (tech_masks, note_counts, row_ms, row_seconds, placements)
}

fn synthetic_rows8(row_count: usize) -> (Vec<u8>, Vec<u8>, Vec<i32>, Vec<f32>, Vec<u8>) {
    let row_patterns = [
        (0b0000_0010u8, 1u8, [0u8, 1, 0, 0, 0, 0, 0, 0]),
        (0b0000_0100, 1, [0, 0, 3, 0, 0, 0, 0, 0]),
        (0b0010_0000, 1, [0, 0, 0, 0, 0, 2, 0, 0]),
        (0b0100_0000, 1, [0, 0, 0, 0, 0, 0, 4, 0]),
        (0b0000_0011, 2, [1, 2, 0, 0, 0, 0, 0, 0]),
        (0b1100_0000, 2, [0, 0, 0, 0, 0, 0, 3, 4]),
        (0b0001_1000, 2, [0, 0, 0, 1, 4, 0, 0, 0]),
        (0b0110_0110, 4, [0, 2, 3, 0, 0, 2, 3, 0]),
    ];

    let mut tech_masks = Vec::with_capacity(row_count);
    let mut note_counts = Vec::with_capacity(row_count);
    let mut row_ms = Vec::with_capacity(row_count);
    let mut row_seconds = Vec::with_capacity(row_count);
    let mut placements = Vec::with_capacity(row_count * 8);
    let mut ms = 0i32;
    let mut seconds = 0.0f32;

    for row in 0..row_count {
        let (mask, count, placement) = row_patterns[row % row_patterns.len()];
        tech_masks.push(mask);
        note_counts.push(count);
        row_ms.push(ms);
        row_seconds.push(seconds);
        placements.extend_from_slice(&placement);
        let delta_ms = if row % 5 == 0 { 120 } else { 80 };
        ms += delta_ms;
        seconds += delta_ms as f32 / 1000.0;
    }

    (tech_masks, note_counts, row_ms, row_seconds, placements)
}

#[test]
#[ignore]
fn tech_counts_cycles() {
    let row_count = 8192;
    let (tech_masks, note_counts, row_ms, row_seconds, placements) = synthetic_rows(row_count);
    let (tech_masks8, note_counts8, row_ms8, row_seconds8, placements8) =
        synthetic_rows8(row_count);
    let mut out = TechCounts::default();

    let ok = unsafe {
        assp_calculate_step_tech_counts_from_placements_4(
            tech_masks.as_ptr(),
            note_counts.as_ptr(),
            row_ms.as_ptr(),
            placements.as_ptr(),
            row_count,
            &mut out,
        )
    };
    assert_ne!(ok, 0);
    let ok = unsafe {
        assp_calculate_step_tech_counts_from_placements_8(
            tech_masks8.as_ptr(),
            note_counts8.as_ptr(),
            row_ms8.as_ptr(),
            placements8.as_ptr(),
            row_count,
            &mut out,
        )
    };
    assert_ne!(ok, 0);

    bench(
        || unsafe {
            black_box(assp_calculate_step_tech_counts_from_placements_4(
                black_box(tech_masks.as_ptr()),
                black_box(note_counts.as_ptr()),
                black_box(row_ms.as_ptr()),
                black_box(placements.as_ptr()),
                row_count,
                black_box(&mut out),
            ));
        },
        "tech_counts_ms_synthetic",
        5000,
        row_count,
    );

    bench(
        || unsafe {
            black_box(assp_calculate_step_tech_counts_from_placements_seconds_4(
                black_box(tech_masks.as_ptr()),
                black_box(note_counts.as_ptr()),
                black_box(row_seconds.as_ptr()),
                black_box(placements.as_ptr()),
                row_count,
                black_box(&mut out),
            ));
        },
        "tech_counts_seconds_synthetic",
        5000,
        row_count,
    );

    bench(
        || unsafe {
            black_box(assp_calculate_step_tech_counts_from_placements_8(
                black_box(tech_masks8.as_ptr()),
                black_box(note_counts8.as_ptr()),
                black_box(row_ms8.as_ptr()),
                black_box(placements8.as_ptr()),
                row_count,
                black_box(&mut out),
            ));
        },
        "tech_counts_8_ms_synthetic",
        5000,
        row_count,
    );

    bench(
        || unsafe {
            black_box(assp_calculate_step_tech_counts_from_placements_seconds_8(
                black_box(tech_masks8.as_ptr()),
                black_box(note_counts8.as_ptr()),
                black_box(row_seconds8.as_ptr()),
                black_box(placements8.as_ptr()),
                row_count,
                black_box(&mut out),
            ));
        },
        "tech_counts_8_seconds_synthetic",
        5000,
        row_count,
    );
}
