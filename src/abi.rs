use std::ffi::c_int;

pub const NOT_FOUND: usize = usize::MAX;
pub const STREAM_TOKEN_BREAK: u32 = 0;
pub const STREAM_TOKEN_RUN16: u32 = 16;
pub const STREAM_TOKEN_RUN20: u32 = 20;
pub const STREAM_TOKEN_RUN24: u32 = 24;
pub const STREAM_TOKEN_RUN32: u32 = 32;
pub const BREAKDOWN_DETAILED: u32 = 0;
pub const BREAKDOWN_PARTIAL: u32 = 1;
pub const BREAKDOWN_SIMPLIFIED: u32 = 2;
pub const STREAM_BREAKDOWN_DETAILED: u32 = 0;
pub const STREAM_BREAKDOWN_PARTIAL: u32 = 1;
pub const STREAM_BREAKDOWN_SIMPLE: u32 = 2;
pub const STREAM_BREAKDOWN_TOTAL: u32 = 3;

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct NoteStats {
    pub rows: u64,
    pub steps: u64,
    pub arrows: u64,
    pub jumps: u64,
    pub hands: u64,
    pub holds: u64,
    pub rolls: u64,
    pub mines: u64,
    pub lifts: u64,
    pub fakes: u64,
    pub left: u64,
    pub down: u64,
    pub up: u64,
    pub right: u64,
    pub malformed_rows: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ChartRef {
    pub note_data: *const u8,
    pub note_data_len: usize,
    pub index: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ByteSlice {
    pub data: *const u8,
    pub len: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct TimingTags {
    pub bpms: ByteSlice,
    pub stops: ByteSlice,
    pub delays: ByteSlice,
    pub warps: ByteSlice,
    pub speeds: ByteSlice,
    pub scrolls: ByteSlice,
    pub fakes: ByteSlice,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct BpmSegment {
    pub beat_milli: i64,
    pub bpm_milli: i64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ChartInfo {
    pub note_data: *const u8,
    pub note_data_len: usize,
    pub index: usize,
    pub step_type: *const u8,
    pub step_type_len: usize,
    pub description: *const u8,
    pub description_len: usize,
    pub difficulty: *const u8,
    pub difficulty_len: usize,
    pub meter: *const u8,
    pub meter_len: usize,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamCounts {
    pub run16_streams: u64,
    pub run20_streams: u64,
    pub run24_streams: u64,
    pub run32_streams: u64,
    pub total_breaks: u64,
    pub sn_breaks: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamSegment {
    pub start: usize,
    pub end: usize,
    pub is_break: u64,
}

#[repr(C)]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct StreamToken {
    pub kind: u32,
    pub _padding: u32,
    pub len: usize,
}

unsafe extern "C" {
    fn assp_version() -> u32;
    fn assp_find_byte(data: *const u8, len: usize, byte: u32) -> usize;
    fn assp_count_note_charts(data: *const u8, len: usize) -> usize;
    fn assp_find_notes_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ChartRef,
    ) -> c_int;
    fn assp_find_chart_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ChartInfo,
    ) -> c_int;
    fn assp_find_global_bpms(data: *const u8, len: usize, out: *mut ByteSlice) -> c_int;
    fn assp_find_chart_bpms_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_global_tag(
        data: *const u8,
        len: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_chart_tag_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        tag: *const u8,
        tag_len: usize,
        out: *mut ByteSlice,
    ) -> c_int;
    fn assp_find_global_timing_tags(data: *const u8, len: usize, out: *mut TimingTags) -> c_int;
    fn assp_find_chart_timing_tags_by_index(
        data: *const u8,
        len: usize,
        index: usize,
        out: *mut TimingTags,
    ) -> c_int;
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
    fn assp_parse_offset_ms(data: *const u8, len: usize) -> i64;
    fn assp_bpm_at_beat_milli(segments: *const BpmSegment, len: usize, beat_milli: i64) -> i64;
    fn assp_elapsed_ms_bpm_only(
        segments: *const BpmSegment,
        len: usize,
        target_beat_milli: i64,
    ) -> i64;
    fn assp_elapsed_ms_with_events(
        bpms: *const BpmSegment,
        bpm_len: usize,
        stops: *const BpmSegment,
        stop_len: usize,
        delays: *const BpmSegment,
        delay_len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        target_beat_milli: i64,
    ) -> i64;
    fn assp_measure_nps_milli_from_bpms(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_measure_nps_milli_with_events(
        densities: *const u32,
        density_len: usize,
        bpms: *const BpmSegment,
        bpm_len: usize,
        stops: *const BpmSegment,
        stop_len: usize,
        delays: *const BpmSegment,
        delay_len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_last_beat_milli_4(data: *const u8, len: usize) -> usize;
    fn assp_measure_densities_4(
        data: *const u8,
        len: usize,
        out: *mut u32,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_measure_4(
        rows: *const u8,
        row_count: usize,
        out: *mut u8,
        out_cap: usize,
    ) -> usize;
    fn assp_minimize_chart_4(
        data: *const u8,
        len: usize,
        out: *mut u8,
        out_cap: usize,
        row_scratch: *mut u8,
        row_scratch_cap: usize,
    ) -> usize;
    fn assp_sha1_short_hex2(
        first: *const u8,
        first_len: usize,
        second: *const u8,
        second_len: usize,
        out16: *mut u8,
    ) -> c_int;
    fn assp_chart_hash_pair(
        chart_data: *const u8,
        chart_data_len: usize,
        normalized_bpms: *const u8,
        normalized_bpms_len: usize,
        out32: *mut u8,
    ) -> c_int;
    fn assp_stream_counts_from_densities(
        densities: *const u32,
        len: usize,
        out: *mut StreamCounts,
    ) -> c_int;
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
    fn assp_count_note_stats_4(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
    fn assp_count_mines_nonfake_4(
        data: *const u8,
        len: usize,
        warps: *const BpmSegment,
        warp_len: usize,
        fakes: *const BpmSegment,
        fake_len: usize,
        row_scratch: *mut u8,
        scratch_row_cap: usize,
    ) -> usize;
}

#[must_use]
pub fn version() -> u32 {
    unsafe { assp_version() }
}

#[must_use]
pub fn find_byte(data: &[u8], byte: u8) -> Option<usize> {
    let idx = unsafe { assp_find_byte(data.as_ptr(), data.len(), u32::from(byte)) };
    (idx != NOT_FOUND).then_some(idx)
}

#[must_use]
pub fn count_note_charts(data: &[u8]) -> usize {
    unsafe { assp_count_note_charts(data.as_ptr(), data.len()) }
}

#[must_use]
pub fn find_notes_by_index(data: &[u8], index: usize) -> Option<ChartRef> {
    let mut chart = ChartRef::default();
    let ok = unsafe { assp_find_notes_by_index(data.as_ptr(), data.len(), index, &mut chart) };
    (ok != 0).then_some(chart)
}

#[must_use]
pub fn find_chart_by_index(data: &[u8], index: usize) -> Option<ChartInfo> {
    let mut chart = ChartInfo::default();
    let ok = unsafe { assp_find_chart_by_index(data.as_ptr(), data.len(), index, &mut chart) };
    (ok != 0).then_some(chart)
}

#[must_use]
pub fn find_global_bpms(data: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe { assp_find_global_bpms(data.as_ptr(), data.len(), &mut slice) };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_chart_bpms_by_index(data: &[u8], index: usize) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe { assp_find_chart_bpms_by_index(data.as_ptr(), data.len(), index, &mut slice) };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_bpms_for_chart(data: &[u8], index: usize) -> Option<ByteSlice> {
    find_chart_bpms_by_index(data, index).or_else(|| find_global_bpms(data))
}

#[must_use]
pub fn find_global_tag(data: &[u8], tag: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe {
        assp_find_global_tag(
            data.as_ptr(),
            data.len(),
            tag.as_ptr(),
            tag.len(),
            &mut slice,
        )
    };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_chart_tag_by_index(data: &[u8], index: usize, tag: &[u8]) -> Option<ByteSlice> {
    let mut slice = ByteSlice::default();
    let ok = unsafe {
        assp_find_chart_tag_by_index(
            data.as_ptr(),
            data.len(),
            index,
            tag.as_ptr(),
            tag.len(),
            &mut slice,
        )
    };
    (ok != 0).then_some(slice)
}

#[must_use]
pub fn find_tag_for_chart(data: &[u8], index: usize, tag: &[u8]) -> Option<ByteSlice> {
    find_chart_tag_by_index(data, index, tag).or_else(|| find_global_tag(data, tag))
}

#[must_use]
pub fn find_global_timing_tags(data: &[u8]) -> Option<TimingTags> {
    let mut tags = TimingTags::default();
    let ok = unsafe { assp_find_global_timing_tags(data.as_ptr(), data.len(), &mut tags) };
    (ok != 0).then_some(tags)
}

#[must_use]
pub fn find_chart_timing_tags_by_index(data: &[u8], index: usize) -> Option<TimingTags> {
    let mut tags = TimingTags::default();
    let ok = unsafe {
        assp_find_chart_timing_tags_by_index(data.as_ptr(), data.len(), index, &mut tags)
    };
    (ok != 0).then_some(tags)
}

#[must_use]
pub fn normalize_float_digits(data: &[u8]) -> Option<Vec<u8>> {
    let count =
        unsafe { assp_normalize_float_digits(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_normalize_float_digits(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len())
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn parse_bpm_map(data: &[u8]) -> Option<Vec<BpmSegment>> {
    let count = unsafe { assp_parse_bpm_map(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![BpmSegment::default(); count];
    if count != 0 {
        let written =
            unsafe { assp_parse_bpm_map(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len()) };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn parse_offset_ms(data: &[u8]) -> i64 {
    unsafe { assp_parse_offset_ms(data.as_ptr(), data.len()) }
}

#[must_use]
pub fn bpm_at_beat_milli(segments: &[BpmSegment], beat_milli: i64) -> i64 {
    unsafe { assp_bpm_at_beat_milli(segments.as_ptr(), segments.len(), beat_milli) }
}

#[must_use]
pub fn elapsed_ms_bpm_only(segments: &[BpmSegment], target_beat_milli: i64) -> i64 {
    unsafe { assp_elapsed_ms_bpm_only(segments.as_ptr(), segments.len(), target_beat_milli) }
}

#[must_use]
pub fn elapsed_ms_with_events(
    bpms: &[BpmSegment],
    stops: &[BpmSegment],
    delays: &[BpmSegment],
    warps: &[BpmSegment],
    target_beat_milli: i64,
) -> i64 {
    if stops.is_empty() && delays.is_empty() && warps.is_empty() {
        return elapsed_ms_bpm_only(bpms, target_beat_milli);
    }

    unsafe {
        assp_elapsed_ms_with_events(
            bpms.as_ptr(),
            bpms.len(),
            stops.as_ptr(),
            stops.len(),
            delays.as_ptr(),
            delays.len(),
            warps.as_ptr(),
            warps.len(),
            target_beat_milli,
        )
    }
}

#[must_use]
pub fn measure_nps_milli_from_bpms(densities: &[u32], bpms: &[BpmSegment]) -> Option<Vec<u32>> {
    let count = unsafe {
        assp_measure_nps_milli_from_bpms(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_measure_nps_milli_from_bpms(
                densities.as_ptr(),
                densities.len(),
                bpms.as_ptr(),
                bpms.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn measure_nps_milli_with_events(
    densities: &[u32],
    bpms: &[BpmSegment],
    stops: &[BpmSegment],
    delays: &[BpmSegment],
    warps: &[BpmSegment],
) -> Option<Vec<u32>> {
    if stops.is_empty() && delays.is_empty() && warps.is_empty() {
        return measure_nps_milli_from_bpms(densities, bpms);
    }

    let count = unsafe {
        assp_measure_nps_milli_with_events(
            densities.as_ptr(),
            densities.len(),
            bpms.as_ptr(),
            bpms.len(),
            stops.as_ptr(),
            stops.len(),
            delays.as_ptr(),
            delays.len(),
            warps.as_ptr(),
            warps.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    if count != 0 {
        let written = unsafe {
            assp_measure_nps_milli_with_events(
                densities.as_ptr(),
                densities.len(),
                bpms.as_ptr(),
                bpms.len(),
                stops.as_ptr(),
                stops.len(),
                delays.as_ptr(),
                delays.len(),
                warps.as_ptr(),
                warps.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
        if written == NOT_FOUND {
            return None;
        }
    }
    Some(out)
}

#[must_use]
pub fn last_beat_milli_4(data: &[u8]) -> Option<usize> {
    let beat = unsafe { assp_last_beat_milli_4(data.as_ptr(), data.len()) };
    (beat != NOT_FOUND).then_some(beat)
}

#[must_use]
pub fn measure_densities_4(data: &[u8]) -> Vec<u32> {
    let count =
        unsafe { assp_measure_densities_4(data.as_ptr(), data.len(), std::ptr::null_mut(), 0) };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe { assp_measure_densities_4(data.as_ptr(), data.len(), out.as_mut_ptr(), out.len()) };
    }
    out
}

#[must_use]
pub fn minimize_measure_4(rows: &[[u8; 4]]) -> Vec<[u8; 4]> {
    let count = unsafe {
        assp_minimize_measure_4(
            rows.as_ptr().cast::<u8>(),
            rows.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![[0; 4]; count];
    if count != 0 {
        unsafe {
            assp_minimize_measure_4(
                rows.as_ptr().cast::<u8>(),
                rows.len(),
                out.as_mut_ptr().cast::<u8>(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn minimize_chart_4(data: &[u8]) -> Option<Vec<u8>> {
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let count = unsafe {
        assp_minimize_chart_4(
            data.as_ptr(),
            data.len(),
            std::ptr::null_mut(),
            0,
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    if count == NOT_FOUND {
        return None;
    }

    let mut out = vec![0; count];
    let count = unsafe {
        assp_minimize_chart_4(
            data.as_ptr(),
            data.len(),
            out.as_mut_ptr(),
            out.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(out)
}

#[must_use]
pub fn sha1_short_hex2(first: &[u8], second: &[u8]) -> Option<[u8; 16]> {
    let mut out = [0; 16];
    let ok = unsafe {
        assp_sha1_short_hex2(
            first.as_ptr(),
            first.len(),
            second.as_ptr(),
            second.len(),
            out.as_mut_ptr(),
        )
    };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn chart_hash_pair(chart_data: &[u8], normalized_bpms: &[u8]) -> Option<([u8; 16], [u8; 16])> {
    let mut out = [0; 32];
    let ok = unsafe {
        assp_chart_hash_pair(
            chart_data.as_ptr(),
            chart_data.len(),
            normalized_bpms.as_ptr(),
            normalized_bpms.len(),
            out.as_mut_ptr(),
        )
    };
    if ok == 0 {
        return None;
    }

    let mut hash = [0; 16];
    let mut neutral = [0; 16];
    hash.copy_from_slice(&out[..16]);
    neutral.copy_from_slice(&out[16..]);
    Some((hash, neutral))
}

#[must_use]
pub fn stream_counts_from_densities(densities: &[u32]) -> Option<StreamCounts> {
    let mut out = StreamCounts::default();
    let ok =
        unsafe { assp_stream_counts_from_densities(densities.as_ptr(), densities.len(), &mut out) };
    (ok != 0).then_some(out)
}

#[must_use]
pub fn stream_segments_from_densities(densities: &[u32]) -> Vec<StreamSegment> {
    let count = unsafe {
        assp_stream_segments_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamSegment::default(); count];
    if count != 0 {
        unsafe {
            assp_stream_segments_from_densities(
                densities.as_ptr(),
                densities.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn stream_tokens_from_densities(densities: &[u32]) -> Vec<StreamToken> {
    let count = unsafe {
        assp_stream_tokens_from_densities(
            densities.as_ptr(),
            densities.len(),
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![StreamToken::default(); count];
    if count != 0 {
        unsafe {
            assp_stream_tokens_from_densities(
                densities.as_ptr(),
                densities.len(),
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn format_stream_tokens(tokens: &[StreamToken], mode: u32) -> Vec<u8> {
    let count = unsafe {
        assp_format_stream_tokens(tokens.as_ptr(), tokens.len(), mode, std::ptr::null_mut(), 0)
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_format_stream_tokens(
                tokens.as_ptr(),
                tokens.len(),
                mode,
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn format_stream_segments(segments: &[StreamSegment], level: u32) -> Vec<u8> {
    let count = unsafe {
        assp_format_stream_segments(
            segments.as_ptr(),
            segments.len(),
            level,
            std::ptr::null_mut(),
            0,
        )
    };
    let mut out = vec![0; count];
    if count != 0 {
        unsafe {
            assp_format_stream_segments(
                segments.as_ptr(),
                segments.len(),
                level,
                out.as_mut_ptr(),
                out.len(),
            )
        };
    }
    out
}

#[must_use]
pub fn count_note_stats_4(data: &[u8]) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let ok = unsafe { assp_count_note_stats_4(data.as_ptr(), data.len(), &mut stats) };
    (ok != 0).then_some(stats)
}

#[must_use]
pub fn count_note_stats_minimized_4(data: &[u8]) -> Option<NoteStats> {
    let minimized = minimize_chart_4(data)?;
    count_note_stats_4(&minimized)
}

#[must_use]
pub fn count_mines_nonfake_4(
    data: &[u8],
    warps: &[BpmSegment],
    fakes: &[BpmSegment],
) -> Option<u64> {
    let mut scratch = vec![[0; 4]; data.len() / 4 + 1];
    let count = unsafe {
        assp_count_mines_nonfake_4(
            data.as_ptr(),
            data.len(),
            warps.as_ptr(),
            warps.len(),
            fakes.as_ptr(),
            fakes.len(),
            scratch.as_mut_ptr().cast::<u8>(),
            scratch.len(),
        )
    };
    (count != NOT_FOUND).then_some(count as u64)
}

#[cfg(test)]
mod tests {
    use super::NoteStats;

    #[test]
    fn note_stats_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<NoteStats>(), 120);
        assert_eq!(std::mem::align_of::<NoteStats>(), 8);
    }

    #[test]
    fn chart_ref_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ChartRef>(), 24);
        assert_eq!(std::mem::align_of::<super::ChartRef>(), 8);
    }

    #[test]
    fn byte_slice_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ByteSlice>(), 16);
        assert_eq!(std::mem::align_of::<super::ByteSlice>(), 8);
    }

    #[test]
    fn timing_tags_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::TimingTags>(), 112);
        assert_eq!(std::mem::align_of::<super::TimingTags>(), 8);
    }

    #[test]
    fn bpm_segment_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::BpmSegment>(), 16);
        assert_eq!(std::mem::align_of::<super::BpmSegment>(), 8);
    }

    #[test]
    fn chart_info_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ChartInfo>(), 88);
        assert_eq!(std::mem::align_of::<super::ChartInfo>(), 8);
    }

    #[test]
    fn stream_counts_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamCounts>(), 48);
        assert_eq!(std::mem::align_of::<super::StreamCounts>(), 8);
    }

    #[test]
    fn stream_segment_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamSegment>(), 24);
        assert_eq!(std::mem::align_of::<super::StreamSegment>(), 8);
    }

    #[test]
    fn stream_token_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::StreamToken>(), 16);
        assert_eq!(std::mem::align_of::<super::StreamToken>(), 8);
    }
}
