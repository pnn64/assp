use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::BpmSegment;

unsafe extern "C" {
    fn assp_bpm_display_range(
        segments: *const BpmSegment,
        len: usize,
        out_min: *mut i64,
        out_max: *mut i64,
    ) -> i32;
    fn assp_measure_nps_milli_from_bpms(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_nps_peak_milli_from_bpms(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
    ) -> usize;
    fn assp_nps_median_centi(nps_milli: *const u32, len: usize) -> i64;
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
    let cycles_per_unit = median / work_units.max(1) as f64;
    println!("{name}: {median:.0} cycles/call, {cycles_per_unit:.3} cycles/unit");
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
fn bpm_nps_cycles() {
    let bpms = variable_bpms();
    let single_bpm = [BpmSegment {
        beat_milli: 0,
        bpm_milli: 175_000,
    }];
    let densities: Vec<u32> = (0..4096).map(|i| 16 + (i % 5) as u32 * 4).collect();
    let mut out = vec![0u32; densities.len()];
    let nps_values: Vec<u32> = (0..4096)
        .map(|i| ((i * 17 + (i / 3) * 29) % 48_000) as u32)
        .collect();

    bench(
        || unsafe {
            black_box(assp_measure_nps_milli_from_bpms(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(bpms.as_ptr()),
                bpms.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
            ));
        },
        "measure_nps_variable_bpms",
        100,
        densities.len(),
    );

    bench(
        || unsafe {
            black_box(assp_measure_nps_milli_from_bpms(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(single_bpm.as_ptr()),
                single_bpm.len(),
                black_box(out.as_mut_ptr()),
                out.len(),
            ));
        },
        "measure_nps_single_bpm",
        100,
        densities.len(),
    );

    bench(
        || unsafe {
            black_box(assp_nps_peak_milli_from_bpms(
                black_box(densities.as_ptr()),
                densities.len(),
                black_box(bpms.as_ptr()),
                bpms.len(),
            ));
        },
        "nps_peak_variable_bpms",
        100,
        densities.len(),
    );

    bench(
        || unsafe {
            black_box(assp_nps_median_centi(
                black_box(nps_values.as_ptr()),
                nps_values.len(),
            ));
        },
        "nps_median_4096",
        10,
        nps_values.len(),
    );

    bench(
        || unsafe {
            let mut min_bpm = 0;
            let mut max_bpm = 0;
            black_box(assp_bpm_display_range(
                black_box(bpms.as_ptr()),
                bpms.len(),
                &mut min_bpm,
                &mut max_bpm,
            ));
            black_box((min_bpm, max_bpm));
        },
        "bpm_display_range_256",
        10_000,
        bpms.len(),
    );
}
