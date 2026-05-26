use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;
use std::os::raw::c_int;

use assp::{BpmSegment, NoteStats, find_chart_by_index};

unsafe extern "C" {
    fn assp_count_note_stats_4(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
    fn assp_count_note_stats_8(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
    fn assp_count_mines_nonfake_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> usize;
    fn assp_count_mines_nonfake_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> usize;
    fn assp_count_timing_fakes_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> usize;
    fn assp_count_timing_fakes_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> usize;
    fn assp_count_timing_note_stats_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        out: *mut NoteStats,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> c_int;
    fn assp_count_timing_note_stats_no_holds_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        out: *mut NoteStats,
        scratch: *mut u8,
        scratch_cap: usize,
    ) -> c_int;
    fn assp_count_timing_note_stats_8(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_count: usize,
        fakes: *const BpmSegment,
        fake_count: usize,
        out: *mut NoteStats,
        scratch: *mut u8,
        scratch_cap: usize,
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
                    b'2'
                } else if row == rows_per_measure / 2 && lane == measure % lanes {
                    b'3'
                } else if row % 4 == 0 && lane == (measure + lane + row) % lanes {
                    b'1'
                } else if row % 11 == 0 && lane == (measure + 1) % lanes {
                    b'M'
                } else if row % 13 == 0 && lane == (measure + 2) % lanes {
                    b'F'
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

fn timing_ranges(count: usize, spacing: i64) -> Vec<BpmSegment> {
    (0..count)
        .map(|i| BpmSegment {
            beat_milli: i as i64 * spacing,
            bpm_milli: spacing / 3,
        })
        .collect()
}

#[test]
#[ignore]
fn note_stats_cycles() {
    let camellia = include_bytes!("../fixtures/camellia_mix.ssc").as_slice();
    let camellia_notes = chart_notes(camellia, 4);
    let double = include_bytes!("../fixtures/dance_double_timing_holds.ssc").as_slice();
    let double_notes = chart_notes(double, 0);
    let timing_holds = include_bytes!("../fixtures/timing_holds.ssc").as_slice();
    let timing_holds_notes = chart_notes(timing_holds, 0);
    let synthetic4 = synthetic_chart(4, 512, 16);
    let synthetic8 = synthetic_chart(8, 512, 16);
    let warps = timing_ranges(32, 8000);
    let fakes = timing_ranges(32, 6000);

    let mut stats = NoteStats::default();
    let mut scratch4 = vec![0u8; synthetic4.len().saturating_mul(8).max(1024)];
    let mut scratch8 = vec![0u8; synthetic8.len().saturating_mul(8).max(1024)];
    let mut row_scratch4 = vec![[0u8; 4]; synthetic4.len() / 4 + 1];
    let mut row_scratch8 = vec![[0u8; 8]; synthetic8.len() / 8 + 1];

    bench(
        || unsafe {
            black_box(assp_count_note_stats_4(
                black_box(camellia_notes.as_ptr()),
                camellia_notes.len(),
                black_box(&mut stats),
            ));
        },
        "note_stats_4_camellia",
        1000,
        camellia_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_note_stats_8(
                black_box(double_notes.as_ptr()),
                double_notes.len(),
                black_box(&mut stats),
            ));
        },
        "note_stats_8_double",
        1000,
        double_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_note_stats_4(
                black_box(timing_holds_notes.as_ptr()),
                timing_holds_notes.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(&mut stats),
                black_box(scratch4.as_mut_ptr()),
                scratch4.len(),
            ));
        },
        "timing_note_stats_4_fixture",
        1000,
        timing_holds_notes.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_note_stats_4(
                black_box(synthetic4.as_ptr()),
                synthetic4.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(&mut stats),
                black_box(scratch4.as_mut_ptr()),
                scratch4.len(),
            ));
        },
        "timing_note_stats_4_synthetic",
        100,
        synthetic4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_note_stats_8(
                black_box(synthetic8.as_ptr()),
                synthetic8.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(&mut stats),
                black_box(scratch8.as_mut_ptr()),
                scratch8.len(),
            ));
        },
        "timing_note_stats_8_synthetic",
        100,
        synthetic8.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_note_stats_no_holds_4(
                black_box(synthetic4.as_ptr()),
                synthetic4.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(&mut stats),
                black_box(row_scratch4.as_mut_ptr().cast::<u8>()),
                row_scratch4.len(),
            ));
        },
        "timing_note_stats_no_holds_4_synthetic",
        100,
        synthetic4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_mines_nonfake_4(
                black_box(synthetic4.as_ptr()),
                synthetic4.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(row_scratch4.as_mut_ptr().cast::<u8>()),
                row_scratch4.len(),
            ));
        },
        "mines_nonfake_4_synthetic",
        100,
        synthetic4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_fakes_4(
                black_box(synthetic4.as_ptr()),
                synthetic4.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(row_scratch4.as_mut_ptr().cast::<u8>()),
                row_scratch4.len(),
            ));
        },
        "timing_fakes_4_synthetic",
        100,
        synthetic4.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_mines_nonfake_8(
                black_box(synthetic8.as_ptr()),
                synthetic8.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(row_scratch8.as_mut_ptr().cast::<u8>()),
                row_scratch8.len(),
            ));
        },
        "mines_nonfake_8_synthetic",
        100,
        synthetic8.len(),
    );

    bench(
        || unsafe {
            black_box(assp_count_timing_fakes_8(
                black_box(synthetic8.as_ptr()),
                synthetic8.len(),
                black_box(warps.as_ptr()),
                warps.len(),
                black_box(fakes.as_ptr()),
                fakes.len(),
                black_box(row_scratch8.as_mut_ptr().cast::<u8>()),
                row_scratch8.len(),
            ));
        },
        "timing_fakes_8_synthetic",
        100,
        synthetic8.len(),
    );
}
