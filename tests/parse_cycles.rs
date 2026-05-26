use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::BpmSegment;

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct SpeedSegment {
    beat_milli: i64,
    ratio_micro: i64,
    delay_micro: i64,
    unit: i64,
}

unsafe extern "C" {
    fn assp_normalize_float_digits(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_bpm_map(
        data: *const u8,
        len: usize,
        out: *mut BpmSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_timing_seconds_map(
        data: *const u8,
        len: usize,
        out: *mut BpmSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_speed_map(
        data: *const u8,
        len: usize,
        out: *mut SpeedSegment,
        out_cap: usize,
    ) -> usize;
    fn assp_parse_offset_ms(data: *const u8, len: usize) -> i64;
    fn assp_parse_offset_us(data: *const u8, len: usize) -> i64;
    fn assp_count_gimmick_speed_segments(data: *const u8, len: usize) -> usize;
    fn assp_count_gimmick_scroll_segments(data: *const u8, len: usize) -> usize;
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

fn bpm_map(entries: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(entries * 20);
    for i in 0..entries {
        if i != 0 {
            data.push(b',');
        }
        let beat = i * 4;
        let bpm = 90 + i % 180;
        data.extend_from_slice(
            format!("{beat}.{:03}={bpm}.{:03}", i % 1000, (i * 37) % 1000).as_bytes(),
        );
    }
    data
}

fn normalize_map(entries: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(entries * 24);
    for i in 0..entries {
        if i != 0 {
            data.push(b',');
        }
        let beat = i * 4;
        let value = 90 + i % 180;
        data.extend_from_slice(
            format!(
                " {beat}.{:04} = {value}.{:04} ",
                i % 10000,
                (i * 37) % 10000
            )
            .as_bytes(),
        );
    }
    data
}

fn scroll_map(entries: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(entries * 24);
    for i in 0..entries {
        if i != 0 {
            data.push(b',');
        }
        let beat = i * 2;
        let value = if i % 7 == 0 { "1.0000009" } else { "0.875001" };
        data.extend_from_slice(format!("{beat}.{:03}={value}", i % 1000).as_bytes());
    }
    data
}

fn seconds_map(entries: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(entries * 24);
    for i in 0..entries {
        if i != 0 {
            data.push(b',');
        }
        let beat = i * 3;
        let value = if i % 9 == 0 { "-0.125000" } else { "0.250001" };
        data.extend_from_slice(format!("{beat}.{:03}={value}", i % 1000).as_bytes());
    }
    data
}

fn speed_map(entries: usize) -> Vec<u8> {
    let mut data = Vec::with_capacity(entries * 32);
    for i in 0..entries {
        if i != 0 {
            data.push(b',');
        }
        let beat = i * 2;
        let value = if i % 5 == 0 { "1.000000" } else { "1.250001" };
        data.extend_from_slice(format!("{beat}.{:03}={value}=4.000000=0", i % 1000).as_bytes());
    }
    data
}

#[test]
#[ignore]
fn parse_cycles() {
    let bpm = bpm_map(256);
    let normalized = normalize_map(256);
    let seconds = seconds_map(256);
    let scrolls = scroll_map(256);
    let speeds = speed_map(256);
    let offset_ms = b"-12345.6789";
    let offset_us = b"-12345.6789019";
    let mut bytes_out = vec![0u8; normalized.len()];
    let mut out = vec![BpmSegment::default(); 256];
    let mut speed_out = vec![SpeedSegment::default(); 256];

    bench(
        || unsafe {
            black_box(assp_normalize_float_digits(
                black_box(normalized.as_ptr()),
                black_box(normalized.len()),
                black_box(bytes_out.as_mut_ptr()),
                black_box(bytes_out.len()),
            ));
        },
        "normalize_float_digits_256",
        10_000,
        256,
    );

    bench(
        || unsafe {
            black_box(assp_parse_bpm_map(
                black_box(bpm.as_ptr()),
                black_box(bpm.len()),
                black_box(out.as_mut_ptr()),
                black_box(out.len()),
            ));
        },
        "parse_bpm_map_256",
        10_000,
        256,
    );

    bench(
        || unsafe {
            black_box(assp_parse_timing_seconds_map(
                black_box(seconds.as_ptr()),
                black_box(seconds.len()),
                black_box(out.as_mut_ptr()),
                black_box(out.len()),
            ));
        },
        "parse_timing_seconds_map_256",
        10_000,
        256,
    );

    bench(
        || unsafe {
            black_box(assp_parse_speed_map(
                black_box(speeds.as_ptr()),
                black_box(speeds.len()),
                black_box(speed_out.as_mut_ptr()),
                black_box(speed_out.len()),
            ));
        },
        "parse_speed_map_256",
        10_000,
        256,
    );

    bench(
        || unsafe {
            black_box(assp_parse_offset_ms(
                black_box(offset_ms.as_ptr()),
                black_box(offset_ms.len()),
            ));
        },
        "parse_offset_ms_decimal",
        1_000_000,
        1,
    );

    bench(
        || unsafe {
            black_box(assp_parse_offset_us(
                black_box(offset_us.as_ptr()),
                black_box(offset_us.len()),
            ));
        },
        "parse_offset_us_decimal",
        1_000_000,
        1,
    );

    bench(
        || unsafe {
            black_box(assp_count_gimmick_scroll_segments(
                black_box(scrolls.as_ptr()),
                black_box(scrolls.len()),
            ));
        },
        "count_scroll_segments_256",
        10_000,
        256,
    );

    bench(
        || unsafe {
            black_box(assp_count_gimmick_speed_segments(
                black_box(speeds.as_ptr()),
                black_box(speeds.len()),
            ));
        },
        "count_speed_segments_256",
        10_000,
        256,
    );
}
