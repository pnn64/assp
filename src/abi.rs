use std::ffi::c_int;

pub const NOT_FOUND: usize = usize::MAX;

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
    fn assp_count_note_stats_4(data: *const u8, len: usize, out: *mut NoteStats) -> c_int;
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
pub fn count_note_stats_4(data: &[u8]) -> Option<NoteStats> {
    let mut stats = NoteStats::default();
    let ok = unsafe { assp_count_note_stats_4(data.as_ptr(), data.len(), &mut stats) };
    (ok != 0).then_some(stats)
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
    fn chart_info_layout_is_c_abi() {
        assert_eq!(std::mem::size_of::<super::ChartInfo>(), 88);
        assert_eq!(std::mem::align_of::<super::ChartInfo>(), 8);
    }
}
