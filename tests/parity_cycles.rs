use std::arch::x86_64::{_mm_lfence, _rdtsc};
use std::hint::black_box;

use assp::{NOT_FOUND, StepParityRowCostCtx4, StepParityState4, step_parity_row_transitions_4};

unsafe extern "C" {
    fn assp_step_parity_row_best_candidates_4(
        initial_states: *const StepParityState4,
        initial_costs: *const f32,
        initial_state_count: usize,
        row_ctx: *const StepParityRowCostCtx4,
        out_predecessors: *mut u32,
        out_placements: *mut u8,
        out_states: *mut StepParityState4,
        out_hits: *mut i8,
        out_keys: *mut u32,
        out_costs: *mut f32,
        out_cap: usize,
    ) -> usize;

    fn assp_step_parity_place_rows_4(
        note_counts: *const u8,
        note_masks: *const u8,
        hold_masks: *const u8,
        mine_masks: *const u8,
        prev_row_live_holds: *const u8,
        row_seconds: *const f32,
        row_count: usize,
        out_placements: *mut u8,
        out_placement_cap: usize,
        scratch_prev_states: *mut StepParityState4,
        scratch_prev_costs: *mut f32,
        scratch_next_states: *mut StepParityState4,
        scratch_next_costs: *mut f32,
        scratch_predecessors: *mut u32,
        scratch_placements: *mut u8,
        scratch_hits: *mut i8,
        scratch_keys: *mut u32,
        backtrack_placements: *mut u8,
        backtrack_predecessors: *mut u32,
        state_cap: usize,
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

fn parity_rows(row_count: usize) -> (Vec<u8>, Vec<u8>, Vec<u8>, Vec<u8>, Vec<u8>, Vec<f32>) {
    let masks = [
        0b0001u8, 0b0010, 0b0100, 0b1000, 0b0101, 0b1010, 0b0011, 0b1100, 0b0110, 0b1001, 0b1111,
        0b0001,
    ];
    let mut note_counts = Vec::with_capacity(row_count);
    let mut note_masks = Vec::with_capacity(row_count);
    let mut hold_masks = Vec::with_capacity(row_count);
    let mut mine_masks = Vec::with_capacity(row_count);
    let mut prev_row_live_holds = Vec::with_capacity(row_count);
    let mut row_seconds = Vec::with_capacity(row_count);

    for row in 0..row_count {
        let mask = masks[row % masks.len()];
        note_counts.push(mask.count_ones() as u8);
        note_masks.push(mask);
        hold_masks.push(0);
        mine_masks.push(if row % 17 == 0 { mask & 0b1001 } else { 0 });
        prev_row_live_holds.push(0);
        row_seconds.push(row as f32 * 0.125);
    }

    (
        note_counts,
        note_masks,
        hold_masks,
        mine_masks,
        prev_row_live_holds,
        row_seconds,
    )
}

#[test]
#[ignore]
fn parity_row_best_cycles() {
    let seed = StepParityState4::default();
    let transitions = step_parity_row_transitions_4(&seed, 0b1111, 0);
    let initial_states: Vec<_> = transitions
        .iter()
        .cycle()
        .take(64)
        .map(|transition| transition.state)
        .collect();
    let initial_costs: Vec<_> = (0..initial_states.len())
        .map(|i| (initial_states.len() - i) as f32 * 0.25)
        .collect();
    let cap = initial_states.len() * 24;
    let elapsed = 0.08f32;
    let ctx = StepParityRowCostCtx4 {
        note_count: 2,
        note_mask: 0b0011,
        hold_mask: 0,
        mine_mask: 0,
        side_mask: 0b0001,
        prev_row_has_live_hold: 0,
        elapsed_seconds: &elapsed,
    };
    let mut predecessors = vec![0u32; cap];
    let mut placements = vec![0u8; cap * 4];
    let mut states = vec![StepParityState4::default(); cap];
    let mut hits = vec![0i8; cap * 5];
    let mut keys = vec![0u32; cap];
    let mut costs = vec![0.0f32; cap];
    let state_count = initial_states.len();

    let mut run = || unsafe {
        assp_step_parity_row_best_candidates_4(
            black_box(initial_states.as_ptr()),
            black_box(initial_costs.as_ptr()),
            state_count,
            &ctx,
            predecessors.as_mut_ptr(),
            placements.as_mut_ptr(),
            states.as_mut_ptr(),
            hits.as_mut_ptr(),
            keys.as_mut_ptr(),
            costs.as_mut_ptr(),
            cap,
        )
    };

    let count = run();
    assert_ne!(count, NOT_FOUND);
    assert!(count > 0);

    bench(
        || {
            black_box(run());
        },
        "parity_row_best_64_states",
        2000,
        state_count,
    );
}

#[test]
#[ignore]
fn parity_row_best_single_clean_cycles() {
    let seed = StepParityState4::default();
    let transitions = step_parity_row_transitions_4(&seed, 0b1111, 0);
    let initial_states: Vec<_> = transitions
        .iter()
        .cycle()
        .take(64)
        .map(|transition| transition.state)
        .collect();
    let initial_costs: Vec<_> = (0..initial_states.len())
        .map(|i| (initial_states.len() - i) as f32 * 0.25)
        .collect();
    let cap = initial_states.len() * 24;
    let elapsed = 0.08f32;
    let ctx = StepParityRowCostCtx4 {
        note_count: 1,
        note_mask: 0b0001,
        hold_mask: 0,
        mine_mask: 0,
        side_mask: 0,
        prev_row_has_live_hold: 0,
        elapsed_seconds: &elapsed,
    };
    let mut predecessors = vec![0u32; cap];
    let mut placements = vec![0u8; cap * 4];
    let mut states = vec![StepParityState4::default(); cap];
    let mut hits = vec![0i8; cap * 5];
    let mut keys = vec![0u32; cap];
    let mut costs = vec![0.0f32; cap];
    let state_count = initial_states.len();

    let mut run = || unsafe {
        assp_step_parity_row_best_candidates_4(
            black_box(initial_states.as_ptr()),
            black_box(initial_costs.as_ptr()),
            state_count,
            &ctx,
            predecessors.as_mut_ptr(),
            placements.as_mut_ptr(),
            states.as_mut_ptr(),
            hits.as_mut_ptr(),
            keys.as_mut_ptr(),
            costs.as_mut_ptr(),
            cap,
        )
    };

    let count = run();
    assert_ne!(count, NOT_FOUND);
    assert!(count > 0);

    bench(
        || {
            black_box(run());
        },
        "parity_row_best_single_clean_64_states",
        2000,
        state_count,
    );
}

#[test]
#[ignore]
fn parity_place_rows_cycles() {
    let row_count = 256;
    let state_cap = 4096;
    let (note_counts, note_masks, hold_masks, mine_masks, prev_row_live_holds, row_seconds) =
        parity_rows(row_count);

    let mut out_placements = vec![0u8; row_count * 4];
    let mut scratch_prev_states = vec![StepParityState4::default(); state_cap];
    let mut scratch_prev_costs = vec![0.0f32; state_cap];
    let mut scratch_next_states = vec![StepParityState4::default(); state_cap];
    let mut scratch_next_costs = vec![0.0f32; state_cap];
    let mut scratch_predecessors = vec![0u32; state_cap];
    let mut scratch_placements = vec![0u8; state_cap * 4];
    let mut scratch_hits = vec![0i8; state_cap * 5];
    let mut scratch_keys = vec![0u32; state_cap];
    let mut backtrack_placements = vec![0u8; row_count * state_cap * 4];
    let mut backtrack_predecessors = vec![0u32; row_count * state_cap];

    let mut run = || unsafe {
        assp_step_parity_place_rows_4(
            black_box(note_counts.as_ptr()),
            black_box(note_masks.as_ptr()),
            black_box(hold_masks.as_ptr()),
            black_box(mine_masks.as_ptr()),
            black_box(prev_row_live_holds.as_ptr()),
            black_box(row_seconds.as_ptr()),
            row_count,
            out_placements.as_mut_ptr(),
            out_placements.len(),
            scratch_prev_states.as_mut_ptr(),
            scratch_prev_costs.as_mut_ptr(),
            scratch_next_states.as_mut_ptr(),
            scratch_next_costs.as_mut_ptr(),
            scratch_predecessors.as_mut_ptr(),
            scratch_placements.as_mut_ptr(),
            scratch_hits.as_mut_ptr(),
            scratch_keys.as_mut_ptr(),
            backtrack_placements.as_mut_ptr(),
            backtrack_predecessors.as_mut_ptr(),
            state_cap,
        )
    };

    let count = run();
    assert_ne!(count, NOT_FOUND);
    assert_eq!(count, row_count);

    bench(
        || {
            black_box(run());
        },
        "parity_place_rows_256_cap4096",
        10,
        row_count,
    );
}
