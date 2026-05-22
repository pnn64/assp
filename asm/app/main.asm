default rel
%include "assp.inc"

extern assp_os_close
extern assp_os_counter
extern assp_os_counter_frequency
extern assp_os_exit
extern assp_os_file_size
extern assp_os_open_readonly
extern assp_os_read
extern assp_os_stdout
extern assp_os_write
%ifdef ASSP_STARTUP_TRACE
extern assp_os_trace
%endif
%ifdef ASSP_UNIX
extern assp_os_argc
extern assp_os_argv
%else
extern assp_os_command_line
%endif

extern assp_chart_hash_pair
extern assp_md5_hex
extern assp_count_mines_nonfake_4
extern assp_count_mines_nonfake_8
extern assp_count_gimmick_scroll_segments
extern assp_count_gimmick_speed_segments
extern assp_count_note_stats_4
extern assp_count_note_stats_8
extern assp_collect_bitmasks_compact_4
extern assp_collect_bitmasks_minimized_4
extern assp_count_anchors_bitmasks_4
extern assp_count_anchors_minimized_4
extern assp_count_default_patterns_bitmasks_4
extern assp_count_default_patterns_minimized_4
extern assp_count_facing_steps_bitmasks_4
extern assp_count_facing_steps_minimized_4
extern assp_pattern_percentages_centi
extern assp_count_timing_fakes_4
extern assp_count_timing_fakes_8
extern assp_count_timing_segments
extern assp_count_timing_note_stats_4
extern assp_count_timing_note_stats_8
extern assp_count_timing_note_stats_no_holds_4
extern assp_count_timing_note_stats_no_holds_8
extern assp_count_note_charts
extern assp_chart_owns_timing_by_index
extern assp_supported_step_type_lanes
extern assp_find_chart_bpms_by_index
extern assp_find_chart_by_index
extern assp_find_next_chart
extern assp_find_chart_timing_tags_by_index
extern assp_find_chart_tag_by_index
extern assp_find_global_bpms
extern assp_find_global_tag
extern assp_find_tag_in_range
extern assp_find_global_timing_tags
extern assp_find_timing_tags_in_range
extern assp_range_owns_timing
extern assp_bpm_average_centi
extern assp_bpm_display_range
extern assp_bpm_median_centi
extern assp_elapsed_ms_bpm_only
extern assp_elapsed_ms_with_events
extern assp_last_beat_milli_4
extern assp_last_beat_milli_8
extern assp_measure_densities_4
extern assp_measure_densities_8
extern assp_measure_equally_spaced_minimized_4
extern assp_measure_equally_spaced_minimized_8
extern assp_measure_nps_milli_from_bpms
extern assp_measure_nps_milli_with_events
extern assp_nps_peak_milli_from_bpms
extern assp_nps_median_centi
extern assp_tier_bpm_centi
extern assp_matrix_rating_centi
extern assp_minimize_chart_4
extern assp_minimize_chart_8
extern assp_normalize_float_digits
extern assp_parse_bpm_map
extern assp_parse_timing_seconds_map
extern assp_parse_offset_ms
extern assp_parse_offset_us
extern assp_parse_tech_notation
extern assp_count_step_tech_brackets_minimized_4
extern assp_count_step_tech_brackets_minimized_8
extern assp_step_parity_bpm_row_times_4
extern assp_step_parity_bpm_row_times_8
extern assp_step_parity_hold_head_ends_4
extern assp_step_parity_hold_head_ends_8
extern assp_step_parity_prepare_hold_rows_4
extern assp_step_parity_prepare_hold_rows_8
extern assp_step_parity_count_prepared_rows_4
extern assp_step_parity_count_prepared_rows_8
extern assp_normalize_label_tag
extern assp_chart_name_tag_allowed
extern assp_resolve_difficulty_label
extern assp_resolve_display_bpm
extern assp_steps_timing_allowed
extern assp_trim_ascii_bytes
extern assp_stream_counts_from_densities
extern assp_stream_percentages_centi
extern assp_stream_segments_from_densities
extern assp_stream_tokens_from_densities
extern assp_format_stream_segments
extern assp_format_stream_tokens

global start

%ifdef ASSP_PHASE_PROFILE
global profile_step_dp_transition_cycles
global profile_step_dp_hash_cycles
global profile_step_dp_score_cycles
global profile_step_dp_copy_cycles
global profile_step_dp_transition_count
global profile_step_dp_hash_probe_count
global profile_step_dp_score_clean_count
global profile_step_dp_score_full_count
global profile_step_dp_write_count
global profile_step_dp_skip_count
%endif

%define FILE_BUFFER_CAP 8388608
%define DENSITY_CAP 131072
%define TEXT_BUFFER_CAP 1048576
%define PRINT_BUFFER_CAP 2097152
%define BPM_BUFFER_CAP 65536
%define BPM_SEGMENT_CAP 4096
%define MINIMIZED_BUFFER_CAP 2097152
%define ROW_SCRATCH_CAP 2097152
%define TECH_BUFFER_CAP 16384
%define METADATA_BUFFER_CAP 65536
%define PARITY_ROW_CAP 262144
%define PARITY_FAST_STATE_CAP 64
%define PARITY_STATE_CAP 512
%define PARITY_FAST_BACKTRACK_CAP (PARITY_ROW_CAP * PARITY_FAST_STATE_CAP)
%define PARITY_BACKTRACK_CAP (PARITY_ROW_CAP * PARITY_STATE_CAP)
%define MONO_THRESHOLD 6
%define ASSP_OS_INVALID_HANDLE -1

%ifdef ASSP_PHASE_PROFILE
    %macro profile_init_call 0
        call profile_init
    %endmacro
    %macro profile_finish_call 0
        call profile_finish
    %endmacro
    %macro profile_begin_call 0
        call profile_begin
    %endmacro
    %macro profile_end_call 1
        lea rcx, [%1]
        call profile_end
    %endmacro
%else
    %macro profile_init_call 0
    %endmacro
    %macro profile_finish_call 0
    %endmacro
    %macro profile_begin_call 0
    %endmacro
    %macro profile_end_call 1
    %endmacro
%endif

%ifdef ASSP_STARTUP_TRACE
    %macro app_trace 1
        push rax
        push rcx
        push rdx
        push r8
        push r9
        push r10
        push r11
        sub rsp, 40
        lea rcx, [%1]
        mov edx, %1_end - %1
        call assp_os_trace
        add rsp, 40
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx
        pop rcx
        pop rax
    %endmacro
%else
    %macro app_trace 1
    %endmacro
%endif

%macro json_z 1
    lea rcx, [%1]
    call print_z
%endmacro

%macro json_u64 2
    lea rcx, [%1]
    call print_z
    mov rcx, %2
    call print_u64
%endmacro

%macro json_u32 2
    lea rcx, [%1]
    call print_z
    mov ecx, %2
    call print_u64
%endmacro

section .text

start:
    sub rsp, 40
    app_trace trace_app_start

    call init_stdout
    call parse_args
    app_trace trace_app_args
    cmp qword [usage_mode], 1
    je show_usage
    cmp qword [usage_mode], 2
    je show_usage_fail
    cmp qword [input_path], 0
    je show_usage_fail
    profile_init_call

    app_trace trace_app_read
    profile_begin_call
    call read_file
    profile_end_call profile_read_file_ticks
    test eax, eax
    jz fail_read
    app_trace trace_app_read_done

    app_trace trace_app_hash
    profile_begin_call
    call prepare_file_md5
    profile_end_call profile_file_md5_ticks
    test eax, eax
    jz fail_hash
    app_trace trace_app_hash_done

    cmp qword [json_mode], 0
    je .check_list
    call print_json_all_charts
    test eax, eax
    jz fail_notes
    cmp qword [profile_mode], 0
    je .finish_json
    call print_flush
.finish_json:
    profile_finish_call
    xor ecx, ecx
    call exit_app

.check_list:
    cmp qword [list_mode], 0
    je .check_all
    call print_chart_list
    xor ecx, ecx
    call exit_app

.check_all:
    cmp qword [all_mode], 0
    je .single_chart
    call print_all_charts
    test eax, eax
    jz fail_notes
    cmp qword [profile_mode], 0
    je .finish_all
    call print_flush
.finish_all:
    profile_finish_call
    xor ecx, ecx
    call exit_app

.single_chart:
    app_trace trace_app_single_chart
    call run_selected_chart
    test eax, eax
    jz fail_notes
    cmp qword [profile_mode], 0
    je .finish_single
    call print_flush
.finish_single:
    profile_finish_call
    xor ecx, ecx
    call exit_app

exit_app:
    sub rsp, 40
    mov [exit_code_tmp], ecx
    call print_flush
    mov ecx, [exit_code_tmp]
    call assp_os_exit

show_usage:
    lea rcx, [msg_usage]
    call print_z
    xor ecx, ecx
    call exit_app

show_usage_fail:
    lea rcx, [msg_usage]
    call print_z
    mov ecx, 1
    call exit_app

run_selected_chart:
    sub rsp, 40

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    lea r9, [chart_info]
    profile_begin_call
    call assp_find_chart_by_index
    profile_end_call profile_find_chart_ticks
    test eax, eax
    jz fail_notes
    add rsp, 40
    jmp run_loaded_chart

run_loaded_chart:
    sub rsp, 40

    mov rcx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    profile_begin_call
    call assp_supported_step_type_lanes
    profile_end_call profile_lane_ticks
    cmp rax, 4
    je .supported_lanes
    cmp rax, 8
    jne fail_lanes
.supported_lanes:
    mov [chart_lanes], rax

    cmp qword [globals_prepared], 0
    jne .globals_ready
    profile_begin_call
    call prepare_global_metadata
    profile_end_call profile_global_ticks
    profile_begin_call
    call prepare_global_normalized_metadata
    profile_end_call profile_global_ticks
    test eax, eax
    jz fail_metadata
    profile_begin_call
    call prepare_global_bpm_data
    profile_end_call profile_global_ticks
    test eax, eax
    jz fail_hash
    mov qword [globals_prepared], 1
.globals_ready:
    profile_begin_call
    call prepare_chart_metadata
    profile_end_call profile_chart_metadata_ticks
    profile_begin_call
    call prepare_difficulty_label
    profile_end_call profile_chart_metadata_ticks
    test eax, eax
    jz fail_metadata
    profile_begin_call
    call prepare_tech_notation
    profile_end_call profile_tech_notation_ticks
    test eax, eax
    jz fail_tech

    profile_begin_call
    call prepare_hash
    profile_end_call profile_hash_ticks
    test eax, eax
    jz fail_hash

    profile_begin_call
    call prepare_offset
    profile_end_call profile_timing_ticks
    test eax, eax
    jz fail_duration

    profile_begin_call
    call prepare_timing_events
    profile_end_call profile_timing_ticks
    test eax, eax
    jz fail_duration

    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [note_stats]
    profile_begin_call
    cmp qword [chart_lanes], 8
    je .count_stats_8
    call assp_count_note_stats_4
    jmp .count_stats_done
.count_stats_8:
    call assp_count_note_stats_8
.count_stats_done:
    profile_end_call profile_note_stats_ticks
    test eax, eax
    jz fail_stats
    mov rax, [note_stats + ASSP_NOTE_STATS_STEPS]
    mov [raw_total_steps], rax

    profile_begin_call
    call prepare_tech_counts
    profile_end_call profile_tech_counts_ticks
    test eax, eax
    jz fail_tech

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [density_buffer]
    mov r9d, DENSITY_CAP
    profile_begin_call
    cmp qword [chart_lanes], 8
    je .measure_density_fill_8
    call assp_measure_densities_4
    jmp .measure_density_fill_done
.measure_density_fill_8:
    call assp_measure_densities_8
.measure_density_fill_done:
    profile_end_call profile_density_ticks
    mov [measure_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    profile_begin_call
    call prepare_selected_normalized_metadata
    profile_end_call profile_selected_metadata_ticks
    test eax, eax
    jz fail_metadata

    profile_begin_call
    call prepare_selected_normalized_timing_maps
    profile_end_call profile_selected_metadata_ticks
    test eax, eax
    jz fail_metadata

    profile_begin_call
    call prepare_bpm_range
    profile_end_call profile_bpm_range_ticks
    test eax, eax
    jz fail_duration

    profile_begin_call
    call prepare_mines_nonfake
    profile_end_call profile_mines_fakes_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_timing_fakes
    profile_end_call profile_mines_fakes_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_timing_stats
    profile_end_call profile_mines_fakes_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_nps
    profile_end_call profile_nps_ticks
    test eax, eax
    jz fail_nps

    profile_begin_call
    call prepare_equally_spaced
    profile_end_call profile_nps_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_default_patterns
    profile_end_call profile_patterns_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_anchors
    profile_end_call profile_patterns_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_facing_steps
    profile_end_call profile_patterns_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_pattern_percentages
    profile_end_call profile_patterns_ticks
    test eax, eax
    jz fail_stats

    profile_begin_call
    call prepare_tier_bpm
    profile_end_call profile_bpm_range_ticks

    profile_begin_call
    call prepare_duration
    profile_end_call profile_timing_ticks
    test eax, eax
    jz fail_duration

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_counts]
    profile_begin_call
    call assp_stream_counts_from_densities
    profile_end_call profile_streams_ticks
    test eax, eax
    jz fail_stats

    lea rcx, [stream_counts]
    mov rdx, [measure_count]
    lea r8, [stream_percent_centi]
    lea r9, [adjusted_stream_percent_centi]
    lea rax, [break_percent_centi]
    mov [rsp + 32], rax
    profile_begin_call
    call assp_stream_percentages_centi
    profile_end_call profile_streams_ticks
    test eax, eax
    jz fail_stats

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_segment_buffer]
    mov r9d, DENSITY_CAP
    profile_begin_call
    call assp_stream_segments_from_densities
    profile_end_call profile_streams_ticks
    mov [stream_segment_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_token_buffer]
    mov r9d, DENSITY_CAP
    profile_begin_call
    call assp_stream_tokens_from_densities
    profile_end_call profile_streams_ticks
    mov [stream_token_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    cmp qword [quiet_mode], 0
    jne .skip_report
    profile_begin_call
    call print_report
    profile_end_call profile_print_ticks
.skip_report:
    mov eax, ASSP_TRUE

.done:
    add rsp, 40
    ret

fail_read:
    lea rcx, [msg_read_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_notes:
    lea rcx, [msg_notes_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_lanes:
    lea rcx, [msg_lanes_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_stats:
    lea rcx, [msg_stats_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_density:
    lea rcx, [msg_density_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_hash:
    lea rcx, [msg_hash_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_metadata:
    lea rcx, [msg_metadata_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_nps:
    lea rcx, [msg_nps_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_duration:
    lea rcx, [msg_duration_fail]
    call print_z
    mov ecx, 1
    call exit_app

fail_tech:
    lea rcx, [msg_tech_fail]
    call print_z
    mov ecx, 1
    call exit_app

prepare_file_md5:
    sub rsp, 40

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [file_md5_hash]
    call assp_md5_hex
    test eax, eax
    jz .fail

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

init_stdout:
    sub rsp, 40
    call assp_os_stdout
    mov [stdout_handle], rax
    add rsp, 40
    ret

profile_init:
    cmp qword [profile_mode], 0
    je .done
    sub rsp, 40

    lea r10, [profile_counters_begin]
    lea r11, [profile_counters_end]
    xor eax, eax
.zero_loop:
    cmp r10, r11
    jae .query_frequency
    mov [r10], rax
    add r10, 8
    jmp .zero_loop

.query_frequency:
    lea rcx, [profile_frequency]
    call assp_os_counter_frequency
    lea rcx, [profile_total_start_tick]
    call assp_os_counter

    add rsp, 40
.done:
    ret

profile_begin:
    cmp qword [profile_mode], 0
    je .done
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    sub rsp, 32

    lea rcx, [profile_qpc_tmp]
    call assp_os_counter
    mov rax, [profile_qpc_tmp]
    mov [profile_start_tick], rax

    add rsp, 32
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
.done:
    ret

profile_end:
    cmp qword [profile_mode], 0
    je .done
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    sub rsp, 32

    mov [profile_accum_ptr], rcx
    lea rcx, [profile_qpc_tmp]
    call assp_os_counter
    mov rax, [profile_qpc_tmp]
    sub rax, [profile_start_tick]
    mov r10, [profile_accum_ptr]
    add [r10], rax

    add rsp, 32
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
.done:
    ret

profile_finish:
    cmp qword [profile_mode], 0
    je .done
    sub rsp, 40

    lea rcx, [profile_qpc_tmp]
    call assp_os_counter
    mov rax, [profile_qpc_tmp]
    sub rax, [profile_total_start_tick]
    mov [profile_total_ticks], rax

    add rsp, 40
    call print_profile_summary
.done:
    ret

print_profile_summary:
    sub rsp, 40
    lea rcx, [label_profile_frequency]
    mov rdx, [profile_frequency]
    call print_field
    lea rcx, [label_profile_total]
    mov rdx, [profile_total_ticks]
    call print_field
    lea rcx, [label_profile_read_file]
    mov rdx, [profile_read_file_ticks]
    call print_field
    lea rcx, [label_profile_file_md5]
    mov rdx, [profile_file_md5_ticks]
    call print_field
    lea rcx, [label_profile_find_chart]
    mov rdx, [profile_find_chart_ticks]
    call print_field
    lea rcx, [label_profile_lane]
    mov rdx, [profile_lane_ticks]
    call print_field
    lea rcx, [label_profile_global]
    mov rdx, [profile_global_ticks]
    call print_field
    lea rcx, [label_profile_chart_metadata]
    mov rdx, [profile_chart_metadata_ticks]
    call print_field
    lea rcx, [label_profile_tech_notation]
    mov rdx, [profile_tech_notation_ticks]
    call print_field
    lea rcx, [label_profile_hash]
    mov rdx, [profile_hash_ticks]
    call print_field
    lea rcx, [label_profile_timing]
    mov rdx, [profile_timing_ticks]
    call print_field
    lea rcx, [label_profile_note_stats]
    mov rdx, [profile_note_stats_ticks]
    call print_field
    lea rcx, [label_profile_tech_counts]
    mov rdx, [profile_tech_counts_ticks]
    call print_field
    lea rcx, [label_profile_density]
    mov rdx, [profile_density_ticks]
    call print_field
    lea rcx, [label_profile_selected_metadata]
    mov rdx, [profile_selected_metadata_ticks]
    call print_field
    lea rcx, [label_profile_bpm_range]
    mov rdx, [profile_bpm_range_ticks]
    call print_field
    lea rcx, [label_profile_mines_fakes]
    mov rdx, [profile_mines_fakes_ticks]
    call print_field
    lea rcx, [label_profile_nps]
    mov rdx, [profile_nps_ticks]
    call print_field
    lea rcx, [label_profile_patterns]
    mov rdx, [profile_patterns_ticks]
    call print_field
    lea rcx, [label_profile_streams]
    mov rdx, [profile_streams_ticks]
    call print_field
    lea rcx, [label_profile_print]
    mov rdx, [profile_print_ticks]
    call print_field
    lea rcx, [label_profile_write_calls]
    mov rdx, [profile_write_calls]
    call print_field
    lea rcx, [label_profile_write_bytes]
    mov rdx, [profile_write_bytes]
    call print_field
    lea rcx, [label_profile_step_row_times]
    mov rdx, [profile_step_row_times_ticks]
    call print_field
    lea rcx, [label_profile_step_hold_ends]
    mov rdx, [profile_step_hold_ends_ticks]
    call print_field
    lea rcx, [label_profile_step_prepare_rows]
    mov rdx, [profile_step_prepare_rows_ticks]
    call print_field
    lea rcx, [label_profile_step_dp_fast]
    mov rdx, [profile_step_dp_fast_ticks]
    call print_field
    lea rcx, [label_profile_step_dp_full]
    mov rdx, [profile_step_dp_full_ticks]
    call print_field
    lea rcx, [label_profile_step_fallback]
    mov rdx, [profile_step_fallback_ticks]
    call print_field
    lea rcx, [label_profile_step_dp_transition_cycles]
    mov rdx, [profile_step_dp_transition_cycles]
    call print_field
    lea rcx, [label_profile_step_dp_hash_cycles]
    mov rdx, [profile_step_dp_hash_cycles]
    call print_field
    lea rcx, [label_profile_step_dp_score_cycles]
    mov rdx, [profile_step_dp_score_cycles]
    call print_field
    lea rcx, [label_profile_step_dp_copy_cycles]
    mov rdx, [profile_step_dp_copy_cycles]
    call print_field
    lea rcx, [label_profile_step_dp_transition_count]
    mov rdx, [profile_step_dp_transition_count]
    call print_field
    lea rcx, [label_profile_step_dp_hash_probe_count]
    mov rdx, [profile_step_dp_hash_probe_count]
    call print_field
    lea rcx, [label_profile_step_dp_score_clean_count]
    mov rdx, [profile_step_dp_score_clean_count]
    call print_field
    lea rcx, [label_profile_step_dp_score_full_count]
    mov rdx, [profile_step_dp_score_full_count]
    call print_field
    lea rcx, [label_profile_step_dp_write_count]
    mov rdx, [profile_step_dp_write_count]
    call print_field
    lea rcx, [label_profile_step_dp_skip_count]
    mov rdx, [profile_step_dp_skip_count]
    call print_field
    add rsp, 40
    ret

parse_args:
    push rsi
    sub rsp, 32

    mov qword [input_path], 0
    mov qword [chart_index], 0
    mov qword [list_mode], 0
    mov qword [all_mode], 1
    mov qword [quiet_mode], 0
    mov qword [json_mode], 0
    mov qword [profile_mode], 0
    mov qword [usage_mode], 0
    mov qword [globals_prepared], 0
    mov qword [global_timing_prepared], 0

%ifdef ASSP_UNIX
    mov rax, [assp_os_argc]
    cmp rax, 1
    jbe .done
    mov rdx, [assp_os_argv]
    test rdx, rdx
    jz .done
    mov rsi, [rdx + 8]
    test rsi, rsi
    jz .done
    cmp byte [rsi], '?'
    je .store_usage
    cmp byte [rsi], '-'
    jne .unix_store_path
    mov al, [rsi + 1]
    cmp al, 'h'
    je .store_usage
    cmp al, 'H'
    je .store_usage
    cmp al, '-'
    jne .unix_store_path
    mov al, [rsi + 2]
    cmp al, 'h'
    je .store_usage
    cmp al, 'H'
    je .store_usage
.unix_store_path:
    mov [input_path], rsi
    cmp rax, 2
    jbe .done
    mov rsi, [rdx + 16]
    test rsi, rsi
    jz .done
    jmp .parse_chart
%else
    call assp_os_command_line
    mov rsi, rax
    test rsi, rsi
    jz .done

    cmp byte [rsi], '"'
    jne .skip_exe_plain
    inc rsi
.skip_exe_quote:
    mov al, [rsi]
    test al, al
    jz .done
    inc rsi
    cmp al, '"'
    jne .skip_exe_quote
    jmp .skip_spaces

.skip_exe_plain:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    jbe .skip_spaces
    inc rsi
    jmp .skip_exe_plain

.skip_spaces:
    mov al, [rsi]
    cmp al, ' '
    ja .path_start
    test al, al
    jz .done
    inc rsi
    jmp .skip_spaces

.path_start:
    cmp al, '-'
    jne .check_help_question
    mov al, [rsi + 1]
    cmp al, 'h'
    je .store_usage
    cmp al, 'H'
    je .store_usage
    cmp al, '-'
    jne .check_help_question
    mov al, [rsi + 2]
    cmp al, 'h'
    je .store_usage
    cmp al, 'H'
    je .store_usage

.check_help_question:
    cmp byte [rsi], '?'
    je .store_usage
    cmp al, '"'
    jne .path_plain
    inc rsi
    mov [input_path], rsi
.path_quote_loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, '"'
    je .path_quote_end
    inc rsi
    jmp .path_quote_loop

.path_quote_end:
    mov byte [rsi], 0
    inc rsi
    jmp .skip_arg_spaces

.path_plain:
    mov [input_path], rsi
.path_plain_loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    jbe .path_plain_end
    inc rsi
    jmp .path_plain_loop

.path_plain_end:
    mov byte [rsi], 0
    inc rsi

.skip_arg_spaces:
    mov al, [rsi]
    cmp al, ' '
    ja .parse_chart
    test al, al
    jz .done
    inc rsi
    jmp .skip_arg_spaces
%endif

.parse_chart:
    cmp byte [rsi], 'a'
    je .store_all
    cmp byte [rsi], 'A'
    je .store_all
    cmp byte [rsi], 'b'
    je .store_quiet_all
    cmp byte [rsi], 'B'
    je .store_quiet_all
    cmp byte [rsi], 'l'
    je .store_list
    cmp byte [rsi], 'L'
    je .store_list
    cmp byte [rsi], 'j'
    je .store_json
    cmp byte [rsi], 'J'
    je .store_json
    cmp byte [rsi], 'p'
    je .store_profile
    cmp byte [rsi], 'P'
    je .store_profile
    cmp byte [rsi], 'q'
    je .store_quiet_all
    cmp byte [rsi], 'Q'
    je .store_quiet_all
    cmp byte [rsi], '-'
    jne .parse_chart_number
    cmp byte [rsi + 1], '-'
    jne .parse_chart_number
    cmp byte [rsi + 2], 'l'
    je .store_list
    cmp byte [rsi + 2], 'L'
    je .store_list
    cmp byte [rsi + 2], 'j'
    je .store_json
    cmp byte [rsi + 2], 'J'
    je .store_json
    cmp byte [rsi + 2], 'a'
    je .store_all
    cmp byte [rsi + 2], 'A'
    je .store_all
    cmp byte [rsi + 2], 'b'
    je .store_quiet_all
    cmp byte [rsi + 2], 'B'
    je .store_quiet_all
    cmp byte [rsi + 2], 'p'
    je .store_profile
    cmp byte [rsi + 2], 'P'
    je .store_profile
    cmp byte [rsi + 2], 'q'
    je .store_quiet_all
    cmp byte [rsi + 2], 'Q'
    je .store_quiet_all

.parse_chart_number:
    movzx rdx, byte [rsi]
    cmp dl, '0'
    jb .store_usage_error
    cmp dl, '9'
    ja .store_usage_error
    xor rax, rax
.chart_loop:
    movzx rdx, byte [rsi]
    cmp dl, '0'
    jb .store_chart
    cmp dl, '9'
    ja .store_chart
    imul rax, rax, 10
    sub edx, '0'
    add rax, rdx
    inc rsi
    jmp .chart_loop

.store_chart:
    mov qword [all_mode], 0
    mov [chart_index], rax
    jmp .done

.store_list:
    mov qword [list_mode], 1
    jmp .done

.store_all:
    mov qword [all_mode], 1
    jmp .done

.store_quiet_all:
    mov qword [all_mode], 1
    mov qword [quiet_mode], 1
    jmp .done

.store_json:
    mov qword [all_mode], 1
    mov qword [quiet_mode], 1
    mov qword [json_mode], 1
    jmp .done

.store_profile:
    mov qword [all_mode], 1
    mov qword [profile_mode], 1
    jmp .done

.store_usage:
    mov qword [usage_mode], 1
    jmp .done

.store_usage_error:
    mov qword [usage_mode], 2

.done:
    add rsp, 32
    pop rsi
    ret

read_file:
    sub rsp, 72

    mov qword [file_handle], 0
    mov qword [file_size], 0
    mov dword [file_bytes_read], 0

    app_trace trace_read_open
    mov rcx, [input_path]
    call assp_os_open_readonly
    cmp rax, ASSP_OS_INVALID_HANDLE
    je .fail
    mov [file_handle], rax
    app_trace trace_read_open_done

    app_trace trace_read_size
    mov rcx, rax
    lea rdx, [file_size]
    call assp_os_file_size
    test eax, eax
    jz .close_fail
    app_trace trace_read_size_done

    mov rax, [file_size]
    test rax, rax
    jz .close_fail
    cmp rax, FILE_BUFFER_CAP
    ja .close_fail

    app_trace trace_read_body
    mov rcx, [file_handle]
    lea rdx, [file_buffer]
    mov r8d, eax
    lea r9, [file_bytes_read]
    mov qword [rsp + 32], 0
    call assp_os_read
    test eax, eax
    jz .close_fail
    app_trace trace_read_body_done

    mov rcx, [file_handle]
    call assp_os_close
    mov qword [file_handle], 0

    mov eax, [file_bytes_read]
    cmp rax, [file_size]
    jne .fail

    mov [file_len], rax
    mov eax, ASSP_TRUE
    jmp .done

.close_fail:
    mov rcx, [file_handle]
    test rcx, rcx
    jz .fail
    call assp_os_close
    mov qword [file_handle], 0

.fail:
    app_trace trace_read_fail
    xor eax, eax

.done:
    add rsp, 72
    ret

find_current_chart_tag:
    sub rsp, 56

    mov r10, r8
    test r10, r10
    jz .fail
    mov qword [r10 + ASSP_BYTE_SLICE_PTR], 0
    mov qword [r10 + ASSP_BYTE_SLICE_LEN], 0

    cmp qword [timing_format_sm], 0
    jne .fail
    cmp qword [chart_info + ASSP_CHART_INFO_META_LEN], 0
    je .fail

    mov [rsp + 32], r10
    mov r9, rdx
    mov r8, rcx
    mov rcx, [chart_info + ASSP_CHART_INFO_META_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_META_LEN]
    call assp_find_tag_in_range
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

zero_chart_timing_tags:
    lea r10, [chart_timing_tags]
    xor eax, eax
    xor ecx, ecx
.loop:
    cmp ecx, ASSP_TIMING_TAGS_SIZE
    jae .done
    mov [r10 + rcx], rax
    add ecx, 8
    jmp .loop
.done:
    ret

find_current_chart_timing_tags:
    sub rsp, 40

    call zero_chart_timing_tags
    cmp qword [timing_format_sm], 0
    jne .fail
    cmp qword [chart_info + ASSP_CHART_INFO_META_LEN], 0
    je .fail

    mov rcx, [chart_info + ASSP_CHART_INFO_META_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_META_LEN]
    lea r8, [chart_timing_tags]
    call assp_find_timing_tags_in_range
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

current_chart_owns_timing:
    sub rsp, 40

    cmp qword [timing_format_sm], 0
    jne .fail
    cmp qword [chart_info + ASSP_CHART_INFO_META_LEN], 0
    je .fail

    mov rcx, [chart_info + ASSP_CHART_INFO_META_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_META_LEN]
    call assp_range_owns_timing
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

print_all_charts:
    sub rsp, 40

    mov qword [chart_index], 0
    mov qword [chart_count], 0
    mov qword [chart_cursor], 0

.loop:
    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_cursor]
    lea r9, [chart_info]
    profile_begin_call
    call assp_find_next_chart
    profile_end_call profile_find_chart_ticks
    test eax, eax
    jz .done_loop

    mov rax, [chart_index]
    mov [chart_info + ASSP_CHART_INFO_INDEX], rax
    call run_loaded_chart
    test eax, eax
    jz .fail
    mov rax, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    add rax, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea rdx, [file_buffer]
    sub rax, rdx
    mov [chart_cursor], rax
    inc qword [chart_index]
    inc qword [chart_count]
    jmp .loop

.done_loop:
    cmp qword [chart_count], 0
    je .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

print_json_all_charts:
    sub rsp, 40

    mov qword [chart_index], 0
    mov qword [chart_count], 0
    mov qword [chart_cursor], 0

.loop:
    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_cursor]
    lea r9, [chart_info]
    profile_begin_call
    call assp_find_next_chart
    profile_end_call profile_find_chart_ticks
    test eax, eax
    jz .done_loop

    mov rax, [chart_index]
    mov [chart_info + ASSP_CHART_INFO_INDEX], rax
    call run_loaded_chart
    test eax, eax
    jz .fail

    cmp qword [chart_count], 0
    jne .print_comma
    call print_json_root_start
    jmp .print_chart

.print_comma:
    json_z comma

.print_chart:
    call print_json_chart

    mov rax, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    add rax, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea rdx, [file_buffer]
    sub rax, rdx
    mov [chart_cursor], rax
    inc qword [chart_index]
    inc qword [chart_count]
    jmp .loop

.done_loop:
    cmp qword [chart_count], 0
    je .fail
    json_z json_root_end
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

input_path_is_sm:
    mov r10, [input_path]
    test r10, r10
    jz .false
    mov r11, r10

.scan:
    cmp byte [r11], 0
    je .check_len
    inc r11
    jmp .scan

.check_len:
    mov rax, r11
    sub rax, r10
    cmp rax, 3
    jb .false
    cmp byte [r11 - 3], '.'
    jne .false
    mov al, [r11 - 2]
    or al, 20h
    cmp al, 's'
    jne .false
    mov al, [r11 - 1]
    or al, 20h
    cmp al, 'm'
    jne .false
    mov eax, ASSP_TRUE
    ret

.false:
    xor eax, eax
    ret

print_chart_list:
    push r12
    sub rsp, 40

    lea rcx, [msg_header]
    call print_z
    lea rcx, [label_file]
    call print_z
    mov rcx, [input_path]
    call print_z
    lea rcx, [newline]
    call print_z

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    call assp_count_note_charts
    mov [chart_count], rax

    lea rcx, [label_charts]
    mov rdx, [chart_count]
    call print_field

    xor r12d, r12d
.list_loop:
    cmp r12, [chart_count]
    jae .done
    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, r12
    lea r9, [chart_info]
    call assp_find_chart_by_index
    test eax, eax
    jz .done
    call print_chart_line
    inc r12
    jmp .list_loop

.done:
    add rsp, 40
    pop r12
    ret

prepare_global_bpm_data:
    sub rsp, 40

    mov qword [global_bpms_len], 0
    mov qword [bpms_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [bpms_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [bpms_slice]
    call assp_find_global_bpms
    test eax, eax
    jz .success

    mov rcx, [bpms_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [bpms_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [global_bpm_buffer]
    mov r9d, BPM_BUFFER_CAP
    call assp_normalize_float_digits
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_BUFFER_CAP
    ja .fail
    mov [global_bpms_len], rax

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_hash:
    sub rsp, 56

    mov qword [bpms_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [bpms_slice + ASSP_BYTE_SLICE_LEN], 0
    lea rax, [bpm_buffer]
    mov [hash_bpms_ptr], rax
    mov qword [normalized_bpms_len], 0

    lea rcx, [tag_bpms]
    mov edx, tag_bpms_end - tag_bpms
    lea r8, [bpms_slice]
    call find_current_chart_tag
    test eax, eax
    jz .use_global_bpms

.normalize_bpms:
    mov rcx, [bpms_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [bpms_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [bpm_buffer]
    mov r9d, BPM_BUFFER_CAP
    call assp_normalize_float_digits
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_BUFFER_CAP
    ja .fail
    mov [normalized_bpms_len], rax
    jmp .measure_minimized

.use_global_bpms:
    lea rax, [global_bpm_buffer]
    mov [hash_bpms_ptr], rax
    mov rax, [global_bpms_len]
    mov [normalized_bpms_len], rax

.measure_minimized:
    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [minimized_buffer]
    mov r9d, MINIMIZED_BUFFER_CAP
    lea rax, [row_scratch]
    mov [rsp + 32], rax
    mov qword [rsp + 40], ROW_SCRATCH_CAP
    cmp qword [chart_lanes], 8
    je .measure_minimized_fill_8
    call assp_minimize_chart_4
    jmp .measure_minimized_fill_done
.measure_minimized_fill_8:
    call assp_minimize_chart_8
.measure_minimized_fill_done:
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, MINIMIZED_BUFFER_CAP
    ja .fail
    lea r10, [minimized_buffer]
.trim_hash_newlines:
    test rax, rax
    jz .hash_len_ready
    cmp byte [r10 + rax - 1], 10
    jne .hash_len_ready
    dec rax
    jmp .trim_hash_newlines

.hash_len_ready:
    mov [minimized_chart_len], rax

    lea rcx, [minimized_buffer]
    mov rdx, rax
    mov r8, [hash_bpms_ptr]
    mov r9, [normalized_bpms_len]
    lea rax, [hash_pair]
    mov [rsp + 32], rax
    call assp_chart_hash_pair
    test eax, eax
    jz .fail

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

prepare_nps:
    sub rsp, 104

    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jnz .with_events

.bpm_only:
    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    lea rax, [nps_buffer]
    mov [rsp + 32], rax
    mov qword [rsp + 40], DENSITY_CAP
    call assp_measure_nps_milli_from_bpms
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, DENSITY_CAP
    ja .fail
    mov [nps_count], rax
    jmp .peak

.with_events:
    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    lea rax, [stop_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [stop_segment_count]
    mov [rsp + 40], rax
    lea rax, [delay_segment_buffer]
    mov [rsp + 48], rax
    mov rax, [delay_segment_count]
    mov [rsp + 56], rax
    lea rax, [warp_segment_buffer]
    mov [rsp + 64], rax
    mov rax, [warp_segment_count]
    mov [rsp + 72], rax
    lea rax, [nps_buffer]
    mov [rsp + 80], rax
    mov qword [rsp + 88], DENSITY_CAP
    call assp_measure_nps_milli_with_events
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, DENSITY_CAP
    ja .fail
    mov [nps_count], rax

.peak:
    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jnz .peak_scan
    cmp qword [bpm_segment_count], 1
    jne .peak_scan
    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    call assp_nps_peak_milli_from_bpms
    cmp rax, ASSP_NOT_FOUND
    je .peak_scan
    mov [rsp + 96], rax
    jmp .store_peak

.peak_scan:
    xor r8d, r8d
    xor r9d, r9d
    lea r10, [nps_buffer]
.peak_loop:
    cmp r8, [nps_count]
    jae .peak_done
    mov eax, [r10 + r8 * 4]
    cmp rax, r9
    jbe .peak_next
    mov r9, rax
.peak_next:
    inc r8
    jmp .peak_loop

.peak_done:
    mov [rsp + 96], r9
    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jnz .store_peak
    cmp qword [bpm_segment_count], 1
    jne .store_peak
    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    call assp_nps_peak_milli_from_bpms
    cmp rax, ASSP_NOT_FOUND
    je .store_peak
    mov [rsp + 96], rax

.store_peak:
    mov r9, [rsp + 96]
    mov [peak_nps_milli], r9
    mov rax, r9
    add rax, 5
    xor edx, edx
    mov r11d, 10
    div r11
    mov [max_nps_centi], rax
    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jnz .median_generic
    cmp qword [bpm_segment_count], 1
    jne .median_bpm_only
    call prepare_fixed_median_nps_f32
    mov [median_nps_centi], rax
    jmp .success

.median_bpm_only:
    call prepare_bpm_median_nps_f32
    mov [median_nps_centi], rax
    jmp .success

.median_generic:
    call prepare_events_median_nps_f32
    mov [median_nps_centi], rax

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 104
    ret

prepare_tier_bpm:
    sub rsp, 40

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    call assp_tier_bpm_centi
    mov [tier_bpm_centi], rax

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    call assp_matrix_rating_centi
    mov [matrix_rating_centi], rax

    add rsp, 40
    ret

prepare_equally_spaced:
    sub rsp, 40

    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [equally_spaced_buffer]
    mov r9d, DENSITY_CAP
    cmp qword [chart_lanes], 8
    je .fill_8
    call assp_measure_equally_spaced_minimized_4
    jmp .fill_done
.fill_8:
    call assp_measure_equally_spaced_minimized_8
.fill_done:
    cmp rax, DENSITY_CAP
    ja .fail
    mov [equally_spaced_count], rax

    xor r8d, r8d
    xor r9d, r9d
    lea r10, [equally_spaced_buffer]
.sum_loop:
    cmp r8, [equally_spaced_count]
    jae .sum_done
    cmp byte [r10 + r8], 0
    je .sum_next
    inc r9
.sum_next:
    inc r8
    jmp .sum_loop

.sum_done:
    mov [equally_spaced_measures], r9
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_default_patterns:
    sub rsp, 40

    mov qword [pattern_bitmask_count], 0
    xor r8d, r8d
    lea r9, [default_pattern_counts]
.zero_loop:
    cmp r8d, ASSP_PATTERN_COUNT
    jae .zero_done
    mov dword [r9 + r8 * 4], 0
    inc r8d
    jmp .zero_loop

.zero_done:
    cmp qword [chart_lanes], 4
    jne .success

    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [pattern_bitmask_buffer]
    mov r9d, PARITY_ROW_CAP
    call assp_collect_bitmasks_compact_4
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [pattern_bitmask_count], rax

    lea rcx, [pattern_bitmask_buffer]
    mov rdx, [pattern_bitmask_count]
    lea r8, [default_pattern_counts]
    call assp_count_default_patterns_bitmasks_4
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_anchors:
    sub rsp, 40

    mov dword [anchor_counts + 0], 0
    mov dword [anchor_counts + 4], 0
    mov dword [anchor_counts + 8], 0
    mov dword [anchor_counts + 12], 0

    cmp qword [chart_lanes], 4
    jne .success

    lea rcx, [pattern_bitmask_buffer]
    mov rdx, [pattern_bitmask_count]
    lea r8, [anchor_counts]
    call assp_count_anchors_bitmasks_4
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_facing_steps:
    sub rsp, 40

    mov dword [facing_counts + 0], 0
    mov dword [facing_counts + 4], 0

    cmp qword [chart_lanes], 4
    jne .success

    lea rcx, [pattern_bitmask_buffer]
    mov rdx, [pattern_bitmask_count]
    mov r8d, MONO_THRESHOLD
    lea r9, [facing_counts]
    call assp_count_facing_steps_bitmasks_4
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_pattern_percentages:
    sub rsp, 40

    mov rcx, [raw_total_steps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    mov r8d, [facing_counts + 0]
    add r8d, [facing_counts + 4]
    lea r9, [candle_percent_centi]
    lea rax, [mono_percent_centi]
    mov [rsp + 32], rax
    call assp_pattern_percentages_centi
    test eax, eax
    jz .fail

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_timing_events:
    sub rsp, 56

    mov qword [bpm_segment_count], 0
    mov qword [bpm_report_count], 0
    mov qword [stop_segment_count], 0
    mov qword [delay_segment_count], 0
    mov qword [warp_segment_count], 0
    mov qword [warp_stats_segment_count], 0
    mov qword [fake_segment_count], 0
    mov qword [stop_report_count], 0
    mov qword [delay_report_count], 0
    mov qword [warp_report_count], 0
    mov qword [speed_report_count], 0
    mov qword [scroll_report_count], 0

    cmp qword [global_timing_prepared], 0
    jne .global_timing_ready
    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [global_timing_tags]
    call assp_find_global_timing_tags
    test eax, eax
    jz .fail
    call prepare_global_normalized_timing_maps
    test eax, eax
    jz .fail
    mov qword [global_timing_prepared], 1
.global_timing_ready:

    call find_current_chart_timing_tags

    cmp qword [timing_allow_steps], 0
    je .select_bpms
    cmp qword [chart_has_own_timing], 0
    jne .select_bpms
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_time_signatures_slice + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_labels_slice + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_tickcounts_slice + ASSP_BYTE_SLICE_PTR], 0
    jne .set_own_timing
    cmp qword [chart_combos_slice + ASSP_BYTE_SLICE_PTR], 0
    je .select_bpms

.set_own_timing:
    mov qword [chart_has_own_timing], ASSP_TRUE

.select_bpms:
    cmp qword [chart_has_own_timing], 0
    je .global_bpms
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_LEN]
    jmp .parse_bpms
.global_bpms:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_LEN]
.parse_bpms:
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    lea r8, [bpm_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [bpm_segment_count], rax
    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    call tidy_bpm_segments_in_place
    mov [bpm_segment_count], rax
    test rax, rax
    jnz .parse_bpm_report
    mov qword [bpm_segment_buffer + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    mov qword [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI], 60000
    mov qword [bpm_segment_count], 1
.parse_bpm_report:
    cmp qword [timing_format_sm], 0
    jne .select_stops
    mov rcx, [rsp + 32]
    mov rdx, [rsp + 40]
    lea r8, [bpm_report_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_timing_seconds_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [bpm_report_count], rax
    lea rcx, [bpm_report_segment_buffer]
    mov rdx, [bpm_report_count]
    call tidy_bpm_segments_in_place
    mov [bpm_report_count], rax
    test rax, rax
    jnz .select_stops
    mov qword [bpm_report_segment_buffer + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    mov qword [bpm_report_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI], 60000000
    mov qword [bpm_report_count], 1

.select_stops:
    cmp qword [chart_has_own_timing], 0
    je .global_stops
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_LEN]
    jmp .parse_stops
.global_stops:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_LEN]
.parse_stops:
    lea r8, [stop_report_count]
    call count_timing_report_segments
    test eax, eax
    jz .fail
    lea r8, [stop_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_timing_seconds_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [stop_segment_count], rax

    cmp qword [chart_has_own_timing], 0
    je .global_delays
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_LEN]
    jmp .parse_delays
.global_delays:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_LEN]
.parse_delays:
    lea r8, [delay_report_count]
    call count_timing_report_segments
    test eax, eax
    jz .fail
    lea r8, [delay_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_timing_seconds_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [delay_segment_count], rax

    cmp qword [chart_has_own_timing], 0
    je .global_warps
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_LEN]
    jmp .parse_warps
.global_warps:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_LEN]
.parse_warps:
    lea r8, [warp_report_count]
    call count_timing_report_segments
    test eax, eax
    jz .fail
    lea r8, [warp_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [warp_segment_count], rax
    lea rcx, [warp_segment_buffer]
    mov rdx, [warp_segment_count]
    call tidy_row_segments_in_place
    mov [warp_segment_count], rax

    cmp qword [chart_has_own_timing], 0
    je .global_speeds
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_LEN]
    jmp .count_speeds
.global_speeds:
    lea rcx, [normalized_speeds_buffer]
    mov rdx, [normalized_speeds_len]
.count_speeds:
    call assp_count_gimmick_speed_segments
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [speed_report_count], rax

    cmp qword [chart_has_own_timing], 0
    je .global_scrolls
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_LEN]
    jmp .count_scrolls
.global_scrolls:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_LEN]
.count_scrolls:
    call assp_count_gimmick_scroll_segments
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [scroll_report_count], rax

    cmp qword [chart_has_own_timing], 0
    je .global_fakes
    mov rcx, [chart_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_LEN]
    jmp .parse_fakes
.global_fakes:
    mov rcx, [global_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_LEN]
.parse_fakes:
    lea r8, [fake_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [fake_segment_count], rax
    lea rcx, [fake_segment_buffer]
    mov rdx, [fake_segment_count]
    call tidy_row_segments_in_place
    mov [fake_segment_count], rax
    call prepare_warp_stats_segments

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

; rcx = assp_bpm_segment buffer, rdx = segment count.
; rax = tidied count. Matches RSSP tidy_bpms for sorted parsed BPMs.
tidy_bpm_segments_in_place:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .empty
    test rdx, rdx
    jz .empty

    mov rbx, rcx
    mov rsi, rdx
    xor r8d, r8d
    xor r9d, r9d

.collapse_loop:
    cmp r8, rsi
    jae .force_first
    mov r10, r8
    shl r10, 4
    mov r12, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r13, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r8

.same_beat_loop:
    cmp r8, rsi
    jae .store_last_for_beat
    mov r10, r8
    shl r10, 4
    cmp [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    jne .store_last_for_beat
    mov r13, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r8
    jmp .same_beat_loop

.store_last_for_beat:
    mov r11, r9
    shl r11, 4
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], r13
    inc r9
    jmp .collapse_loop

.force_first:
    test r9, r9
    jz .empty
    mov qword [rbx + ASSP_BPM_SEGMENT_BEAT_MILLI], 0

    xor r8d, r8d
    xor r10d, r10d
    xor r15d, r15d

.dedupe_loop:
    cmp r8, r9
    jae .done
    mov r11, r8
    shl r11, 4
    mov r12, [rbx + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r13, [rbx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    test r15d, r15d
    jz .keep
    cmp r13, r14
    je .skip

.keep:
    mov r11, r10
    shl r11, 4
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], r13
    mov r14, r13
    mov r15d, ASSP_TRUE
    inc r10

.skip:
    inc r8
    jmp .dedupe_loop

.done:
    mov rax, r10
    jmp .pop_done

.empty:
    xor eax, eax

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = assp_bpm_segment buffer, rdx = segment count.
; rax = tidied count. Matches RSSP tidy_row_segments for fakes/warps.
tidy_row_segments_in_place:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    test rcx, rcx
    jz .empty
    test rdx, rdx
    jz .empty

    mov rbx, rcx
    mov rsi, rdx
    xor r8d, r8d

.quantize_loop:
    cmp r8, rsi
    jae .collapse
    mov r10, r8
    shl r10, 4
    mov rcx, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    imul rax, rax, 1000
    cqo
    mov r11d, 48
    idiv r11
    mov [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    inc r8
    jmp .quantize_loop

.collapse:
    xor r8d, r8d
    xor r9d, r9d

.collapse_loop:
    cmp r8, rsi
    jae .done
    mov r10, r8
    shl r10, 4
    mov r12, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r13, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r8

.same_row_loop:
    cmp r8, rsi
    jae .store_last_for_row
    mov r10, r8
    shl r10, 4
    cmp [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    jne .store_last_for_row
    mov r13, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r8
    jmp .same_row_loop

.store_last_for_row:
    mov r11, r9
    shl r11, 4
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    mov [rbx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], r13
    inc r9
    jmp .collapse_loop

.done:
    mov rax, r9
    jmp .pop_done

.empty:
    xor eax, eax

.pop_done:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

milli_to_row48_f32_even:
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel app_const_thousand_f32]
    mulss xmm0, [rel app_const_48_f32]
    cvtss2si rax, xmm0
    ret

prepare_warp_stats_segments:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    lea rbx, [warp_segment_buffer]
    mov rsi, [warp_segment_count]
    lea rdi, [warp_stats_segment_buffer]
    xor r13d, r13d
    xor r14d, r14d

.loop:
    cmp r13, rsi
    jae .done
    mov r10, r13
    shl r10, 4
    mov r12, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r15, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]

.advance_loop:
    test r15, r15
    jle .next
    mov rcx, r12
    call milli_to_row48_f32_even
    mov rcx, rax
    call timing_row_has_stop_or_delay
    test eax, eax
    jz .store

    mov rcx, r12
    call milli_to_row48_f32_even
    inc rax
    imul rax, rax, 1000
    cqo
    mov r11d, 48
    idiv r11
    mov r10, rax
    sub r10, r12
    cmp r10, r15
    jge .next
    sub r15, r10
    mov r12, rax
    jmp .advance_loop

.store:
    mov r10, r14
    shl r10, 4
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], r12
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI], r15
    inc r14

.next:
    inc r13
    jmp .loop

.done:
    mov [warp_stats_segment_count], r14
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = note row. eax = 1 when a positive stop or delay starts on that row.
timing_row_has_stop_or_delay:
    push rbx
    push rsi
    push r12
    push r13

    mov r12, rcx
    lea rbx, [stop_segment_buffer]
    mov rsi, [stop_segment_count]
    xor r13d, r13d
.stop_loop:
    cmp r13, rsi
    jae .delays
    mov r10, r13
    shl r10, 4
    cmp qword [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI], 0
    jle .stop_next
    mov rcx, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, r12
    je .yes
.stop_next:
    inc r13
    jmp .stop_loop

.delays:
    lea rbx, [delay_segment_buffer]
    mov rsi, [delay_segment_count]
    xor r13d, r13d
.delay_loop:
    cmp r13, rsi
    jae .no
    mov r10, r13
    shl r10, 4
    cmp qword [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI], 0
    jle .delay_next
    mov rcx, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, r12
    je .yes
.delay_next:
    inc r13
    jmp .delay_loop

.yes:
    mov eax, ASSP_TRUE
    jmp .done
.no:
    xor eax, eax

.done:
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret

prepare_global_normalized_timing_maps:
    sub rsp, 40

    mov qword [normalized_stops_len], 0
    mov qword [normalized_delays_len], 0
    mov qword [normalized_warps_len], 0
    mov qword [normalized_speeds_len], 0
    mov qword [normalized_scrolls_len], 0
    mov qword [normalized_fakes_len], 0

    mov ecx, ASSP_TIMING_TAGS_STOPS
    lea rdx, [normalized_stops_buffer]
    lea r8, [normalized_stops_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_DELAYS
    lea rdx, [normalized_delays_buffer]
    lea r8, [normalized_delays_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_WARPS
    lea rdx, [normalized_warps_buffer]
    lea r8, [normalized_warps_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_SPEEDS
    lea rdx, [normalized_speeds_buffer]
    lea r8, [normalized_speeds_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_SCROLLS
    lea rdx, [normalized_scrolls_buffer]
    lea r8, [normalized_scrolls_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_FAKES
    lea rdx, [normalized_fakes_buffer]
    lea r8, [normalized_fakes_len]
    call normalize_global_timing_tag
    test eax, eax
    jz .fail

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_selected_normalized_timing_maps:
    sub rsp, 40

    mov qword [selected_normalized_bpms_len], 0
    mov qword [selected_normalized_stops_len], 0
    mov qword [selected_normalized_delays_len], 0
    mov qword [selected_normalized_warps_len], 0
    mov qword [selected_normalized_fakes_len], 0
    mov qword [selected_normalized_speeds_len], 0
    mov qword [selected_normalized_scrolls_len], 0

    mov ecx, ASSP_TIMING_TAGS_BPMS
    lea rdx, [selected_normalized_bpms_buffer]
    lea r8, [selected_normalized_bpms_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_STOPS
    lea rdx, [selected_normalized_stops_buffer]
    lea r8, [selected_normalized_stops_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_DELAYS
    lea rdx, [selected_normalized_delays_buffer]
    lea r8, [selected_normalized_delays_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_WARPS
    lea rdx, [selected_normalized_warps_buffer]
    lea r8, [selected_normalized_warps_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_FAKES
    lea rdx, [selected_normalized_fakes_buffer]
    lea r8, [selected_normalized_fakes_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_SPEEDS
    lea rdx, [selected_normalized_speeds_buffer]
    lea r8, [selected_normalized_speeds_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov ecx, ASSP_TIMING_TAGS_SCROLLS
    lea rdx, [selected_normalized_scrolls_buffer]
    lea r8, [selected_normalized_scrolls_len]
    call normalize_selected_timing_tag
    test eax, eax
    jz .fail

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

; ecx = ASSP_TIMING_TAGS_* offset, rdx = output buffer, r8 = output length slot.
normalize_global_timing_tag:
    sub rsp, 40

    mov [rsp + 32], r8
    mov r10, rcx
    mov r11, rdx
    lea rax, [global_timing_tags]
    mov rcx, [rax + r10 + ASSP_BYTE_SLICE_PTR]
    mov rdx, [rax + r10 + ASSP_BYTE_SLICE_LEN]
    mov r8, r11
    mov r9d, BPM_BUFFER_CAP
    call assp_normalize_float_digits
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_BUFFER_CAP
    ja .fail
    mov r8, [rsp + 32]
    mov [r8], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

; ecx = ASSP_TIMING_TAGS_* offset, rdx = output buffer, r8 = output length slot.
normalize_selected_timing_tag:
    sub rsp, 40

    mov [rsp + 32], r8
    mov r10, rcx
    mov r11, rdx
    lea rax, [global_timing_tags]
    cmp qword [chart_has_own_timing], 0
    je .selected
    lea rax, [chart_timing_tags]

.selected:
    mov rcx, [rax + r10 + ASSP_BYTE_SLICE_PTR]
    mov rdx, [rax + r10 + ASSP_BYTE_SLICE_LEN]
    mov r8, r11
    mov r9d, BPM_BUFFER_CAP
    call assp_normalize_float_digits
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_BUFFER_CAP
    ja .fail
    mov r8, [rsp + 32]
    mov [r8], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

count_timing_report_segments:
    sub rsp, 56

    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    mov [rsp + 48], r8
    call assp_count_timing_segments
    cmp rax, ASSP_NOT_FOUND
    je .fail

    mov r8, [rsp + 48]
    mov [r8], rax
    mov rcx, [rsp + 32]
    mov rdx, [rsp + 40]
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

prepare_bpm_range:
    sub rsp, 40

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    lea r8, [min_bpm]
    lea r9, [max_bpm]
    call assp_bpm_display_range
    test eax, eax
    jz .done

    call prepare_raw_bpm_range

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    call assp_bpm_average_centi
    mov [average_bpm_centi], rax

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    call assp_bpm_median_centi
    mov [median_bpm_centi], rax

    call prepare_display_bpm_range
    mov eax, ASSP_TRUE

.done:
    add rsp, 40
    ret

prepare_raw_bpm_range:
    mov qword [raw_min_bpm_milli], 0
    mov qword [raw_max_bpm_milli], 0

    mov rdx, [bpm_segment_count]
    test rdx, rdx
    jz .done

    lea rcx, [bpm_segment_buffer]
    mov r8, 0x7fffffffffffffff
    mov r9, 0x8000000000000000
    xor r10d, r10d

.loop:
    cmp r10, rdx
    jae .store
    mov r11, r10
    shl r11, 4
    mov rax, [rcx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, r8
    jge .check_max
    mov r8, rax
.check_max:
    cmp rax, r9
    jle .next
    mov r9, rax
.next:
    inc r10
    jmp .loop

.store:
    test r8, r8
    jge .min_ok
    xor r8d, r8d
.min_ok:
    test r9, r9
    jge .max_ok
    xor r9d, r9d
.max_ok:
    mov [raw_min_bpm_milli], r8
    mov [raw_max_bpm_milli], r9

.done:
    ret

prepare_display_bpm_range:
    sub rsp, 72

    call prepare_actual_display_bpm_text_range

    mov rcx, [display_bpm_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [display_bpm_slice + ASSP_BYTE_SLICE_LEN]

    mov r8, [raw_min_bpm_milli]
    mov r9, [raw_max_bpm_milli]
    lea rax, [display_min_bpm]
    mov [rsp + 32], rax
    lea rax, [display_max_bpm]
    mov [rsp + 40], rax
    lea rax, [display_text_min_bpm]
    mov [rsp + 48], rax
    lea rax, [display_text_max_bpm]
    mov [rsp + 56], rax
    lea rax, [display_bpm_range_flag]
    mov [rsp + 64], rax
    call assp_resolve_display_bpm
    add rsp, 72
    ret

prepare_actual_display_bpm_text_range:
    mov qword [display_text_min_bpm], 0
    mov qword [display_text_max_bpm], 0
    mov qword [display_bpm_range_flag], 0

    mov rax, [raw_min_bpm_milli]
    call display_milli_to_text_int
    mov [display_text_min_bpm], rax
    mov rax, [raw_max_bpm_milli]
    call display_milli_to_text_int
    mov [display_text_max_bpm], rax
    xor eax, eax
    mov r10, [raw_min_bpm_milli]
    cmp r10, [raw_max_bpm_milli]
    setne al
    mov [display_bpm_range_flag], rax

    ret

display_milli_to_text_int:
    test rax, rax
    jg .round
    xor eax, eax
    ret
.round:
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_thousand_f32]
    divss xmm0, [rel app_const_60_f32]
    mulss xmm0, [rel app_const_60_f32]
    cvtss2si rax, xmm0
    ret

prepare_mines_nonfake:
    sub rsp, 72

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_stats_segment_buffer]
    mov r9, [warp_stats_segment_count]
    lea rax, [fake_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [fake_segment_count]
    mov [rsp + 40], rax
    lea rax, [row_scratch]
    mov [rsp + 48], rax
    mov qword [rsp + 56], ROW_SCRATCH_CAP
    cmp qword [chart_lanes], 8
    je .count_8
    call assp_count_mines_nonfake_4
    jmp .count_done
.count_8:
    call assp_count_mines_nonfake_8
.count_done:
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [mines_nonfake], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 72
    ret

prepare_timing_fakes:
    sub rsp, 72

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_stats_segment_buffer]
    mov r9, [warp_stats_segment_count]
    lea rax, [fake_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [fake_segment_count]
    mov [rsp + 40], rax
    lea rax, [row_scratch]
    mov [rsp + 48], rax
    mov qword [rsp + 56], ROW_SCRATCH_CAP
    cmp qword [chart_lanes], 8
    je .count_8
    call assp_count_timing_fakes_4
    jmp .count_done
.count_8:
    call assp_count_timing_fakes_8
.count_done:
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [timing_fakes], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 72
    ret

prepare_timing_stats:
    sub rsp, 88

    mov rax, [warp_segment_count]
    or rax, [fake_segment_count]
    jnz .recompute

    mov rax, [note_stats + ASSP_NOTE_STATS_HOLDS]
    or rax, [note_stats + ASSP_NOTE_STATS_ROLLS]
    jz .success
    jmp .holds

.recompute:
    mov rax, [note_stats + ASSP_NOTE_STATS_HOLDS]
    or rax, [note_stats + ASSP_NOTE_STATS_ROLLS]
    jz .no_holds

.holds:
    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_stats_segment_buffer]
    mov r9, [warp_stats_segment_count]
    lea rax, [fake_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [fake_segment_count]
    mov [rsp + 40], rax
    lea rax, [note_stats]
    mov [rsp + 48], rax
    lea rax, [row_scratch]
    mov [rsp + 56], rax
    mov qword [rsp + 64], ROW_SCRATCH_CAP * 8
    cmp qword [chart_lanes], 8
    je .count_holds_8
    call assp_count_timing_note_stats_4
    jmp .count_done
.count_holds_8:
    call assp_count_timing_note_stats_8
    jmp .count_done

.no_holds:
    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_stats_segment_buffer]
    mov r9, [warp_stats_segment_count]
    lea rax, [fake_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [fake_segment_count]
    mov [rsp + 40], rax
    lea rax, [note_stats]
    mov [rsp + 48], rax
    lea rax, [row_scratch]
    mov [rsp + 56], rax
    mov qword [rsp + 64], ROW_SCRATCH_CAP
    cmp qword [chart_lanes], 8
    je .count_8
    call assp_count_timing_note_stats_no_holds_4
    jmp .count_done
.count_8:
    call assp_count_timing_note_stats_no_holds_8
.count_done:
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 88
    ret

prepare_global_metadata:
    sub rsp, 40

    mov qword [title_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [title_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [subtitle_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [subtitle_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [artist_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [artist_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [genre_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [genre_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [title_trans_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [title_trans_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [subtitle_trans_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [subtitle_trans_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [artist_trans_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [artist_trans_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [music_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [music_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [banner_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [banner_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [background_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [background_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [cdtitle_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [cdtitle_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [jacket_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [jacket_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [sample_start_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [sample_start_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [sample_length_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [sample_length_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [version_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [version_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [timing_format_sm], 0
    mov qword [timing_allow_steps], 0
    mov qword [chart_name_tag_allowed], 0
    mov qword [global_attacks_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_attacks_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_display_bpm_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_display_bpm_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_time_signatures_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_time_signatures_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_labels_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_labels_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_tickcounts_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_tickcounts_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_combos_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_combos_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [global_offset_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [global_offset_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_title]
    mov r9d, tag_title_end - tag_title
    lea rax, [title_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_subtitle]
    mov r9d, tag_subtitle_end - tag_subtitle
    lea rax, [subtitle_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_artist]
    mov r9d, tag_artist_end - tag_artist
    lea rax, [artist_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_genre]
    mov r9d, tag_genre_end - tag_genre
    lea rax, [genre_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_title_trans]
    mov r9d, tag_title_trans_end - tag_title_trans
    lea rax, [title_trans_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_subtitle_trans]
    mov r9d, tag_subtitle_trans_end - tag_subtitle_trans
    lea rax, [subtitle_trans_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_artist_trans]
    mov r9d, tag_artist_trans_end - tag_artist_trans
    lea rax, [artist_trans_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_music]
    mov r9d, tag_music_end - tag_music
    lea rax, [music_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_banner]
    mov r9d, tag_banner_end - tag_banner
    lea rax, [banner_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_background]
    mov r9d, tag_background_end - tag_background
    lea rax, [background_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_cdtitle]
    mov r9d, tag_cdtitle_end - tag_cdtitle
    lea rax, [cdtitle_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_jacket]
    mov r9d, tag_jacket_end - tag_jacket
    lea rax, [jacket_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_sample_start]
    mov r9d, tag_sample_start_end - tag_sample_start
    lea rax, [sample_start_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_sample_length]
    mov r9d, tag_sample_length_end - tag_sample_length
    lea rax, [sample_length_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_version]
    mov r9d, tag_version_end - tag_version
    lea rax, [version_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    call input_path_is_sm
    mov [timing_format_sm], rax
    mov rcx, [version_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [version_slice + ASSP_BYTE_SLICE_LEN]
    mov r8d, eax
    call assp_steps_timing_allowed
    mov [timing_allow_steps], rax
    mov rcx, [version_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [version_slice + ASSP_BYTE_SLICE_LEN]
    mov r8d, [timing_format_sm]
    call assp_chart_name_tag_allowed
    mov [chart_name_tag_allowed], rax

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_attacks]
    mov r9d, tag_attacks_end - tag_attacks
    lea rax, [global_attacks_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_display_bpm]
    mov r9d, tag_display_bpm_end - tag_display_bpm
    lea rax, [global_display_bpm_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_time_signatures]
    mov r9d, tag_time_signatures_end - tag_time_signatures
    lea rax, [global_time_signatures_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_labels]
    mov r9d, tag_labels_end - tag_labels
    lea rax, [global_labels_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_tickcounts]
    mov r9d, tag_tickcounts_end - tag_tickcounts
    lea rax, [global_tickcounts_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_combos]
    mov r9d, tag_combos_end - tag_combos
    lea rax, [global_combos_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_offset]
    mov r9d, tag_offset_end - tag_offset
    lea rax, [global_offset_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag

    cmp qword [artist_slice + ASSP_BYTE_SLICE_LEN], 0
    jne .done
    cmp qword [artist_trans_slice + ASSP_BYTE_SLICE_LEN], 0
    jne .done
    lea rax, [unknown_artist]
    mov [artist_slice + ASSP_BYTE_SLICE_PTR], rax
    mov [artist_trans_slice + ASSP_BYTE_SLICE_PTR], rax
    mov qword [artist_slice + ASSP_BYTE_SLICE_LEN], unknown_artist_end - unknown_artist
    mov qword [artist_trans_slice + ASSP_BYTE_SLICE_LEN], unknown_artist_end - unknown_artist

.done:
    add rsp, 40
    ret

prepare_global_normalized_metadata:
    sub rsp, 40

    mov qword [normalized_time_signatures_len], 0
    mov qword [normalized_labels_len], 0
    mov qword [normalized_tickcounts_len], 0
    mov qword [normalized_combos_len], 0

    mov rcx, [global_time_signatures_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_time_signatures_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [normalized_time_signatures_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [normalized_time_signatures_len], rax

    mov rcx, [global_labels_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_labels_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [normalized_labels_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_normalize_label_tag
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [normalized_labels_len], rax

    mov rcx, [global_tickcounts_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_tickcounts_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [normalized_tickcounts_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [normalized_tickcounts_len], rax

    mov rcx, [global_combos_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_combos_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [normalized_combos_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [normalized_combos_len], rax

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_selected_normalized_metadata:
    sub rsp, 40

    mov qword [selected_normalized_time_signatures_len], 0
    mov qword [selected_normalized_labels_len], 0
    mov qword [selected_normalized_tickcounts_len], 0
    mov qword [selected_normalized_combos_len], 0

    cmp qword [chart_has_own_timing], 0
    je .global_time_signatures
    mov rcx, [chart_time_signatures_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_time_signatures_slice + ASSP_BYTE_SLICE_LEN]
    jmp .normalize_time_signatures
.global_time_signatures:
    mov rcx, [global_time_signatures_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_time_signatures_slice + ASSP_BYTE_SLICE_LEN]
.normalize_time_signatures:
    lea r8, [selected_normalized_time_signatures_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [selected_normalized_time_signatures_len], rax

    cmp qword [chart_has_own_timing], 0
    je .global_labels
    mov rcx, [chart_labels_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_labels_slice + ASSP_BYTE_SLICE_LEN]
    jmp .normalize_labels
.global_labels:
    mov rcx, [global_labels_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_labels_slice + ASSP_BYTE_SLICE_LEN]
.normalize_labels:
    lea r8, [selected_normalized_labels_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_normalize_label_tag
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [selected_normalized_labels_len], rax

    cmp qword [chart_has_own_timing], 0
    je .global_tickcounts
    mov rcx, [chart_tickcounts_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_tickcounts_slice + ASSP_BYTE_SLICE_LEN]
    jmp .normalize_tickcounts
.global_tickcounts:
    mov rcx, [global_tickcounts_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_tickcounts_slice + ASSP_BYTE_SLICE_LEN]
.normalize_tickcounts:
    lea r8, [selected_normalized_tickcounts_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [selected_normalized_tickcounts_len], rax

    cmp qword [chart_has_own_timing], 0
    je .global_combos
    mov rcx, [chart_combos_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [chart_combos_slice + ASSP_BYTE_SLICE_LEN]
    jmp .normalize_combos
.global_combos:
    mov rcx, [global_combos_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_combos_slice + ASSP_BYTE_SLICE_LEN]
.normalize_combos:
    lea r8, [selected_normalized_combos_buffer]
    mov r9d, METADATA_BUFFER_CAP
    call assp_trim_ascii_bytes
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [selected_normalized_combos_len], rax

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 40
    ret

prepare_chart_metadata:
    sub rsp, 56

    mov qword [chart_name_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_name_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_music_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_music_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_attacks_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_attacks_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [display_bpm_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [display_bpm_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_time_signatures_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_time_signatures_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_labels_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_labels_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_tickcounts_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_tickcounts_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [chart_combos_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [chart_combos_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [step_artist_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [step_artist_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [tag_chart_name]
    mov edx, tag_chart_name_end - tag_chart_name
    lea r8, [chart_name_slice]
    call find_current_chart_tag

    lea rcx, [tag_music]
    mov edx, tag_music_end - tag_music
    lea r8, [chart_music_slice]
    call find_current_chart_tag

    lea rcx, [tag_attacks]
    mov edx, tag_attacks_end - tag_attacks
    lea r8, [chart_attacks_slice]
    call find_current_chart_tag

    lea rcx, [tag_display_bpm]
    mov edx, tag_display_bpm_end - tag_display_bpm
    lea r8, [display_bpm_slice]
    call find_current_chart_tag

    lea rcx, [tag_time_signatures]
    mov edx, tag_time_signatures_end - tag_time_signatures
    lea r8, [chart_time_signatures_slice]
    call find_current_chart_tag

    lea rcx, [tag_labels]
    mov edx, tag_labels_end - tag_labels
    lea r8, [chart_labels_slice]
    call find_current_chart_tag

    lea rcx, [tag_tickcounts]
    mov edx, tag_tickcounts_end - tag_tickcounts
    lea r8, [chart_tickcounts_slice]
    call find_current_chart_tag

    lea rcx, [tag_combos]
    mov edx, tag_combos_end - tag_combos
    lea r8, [chart_combos_slice]
    call find_current_chart_tag

    lea rcx, [tag_credit]
    mov edx, tag_credit_end - tag_credit
    lea r8, [step_artist_slice]
    call find_current_chart_tag

.set_sm_step_artist:
    cmp qword [timing_format_sm], 0
    je .done
    mov rax, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov [step_artist_slice + ASSP_BYTE_SLICE_PTR], rax
    mov rax, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    mov [step_artist_slice + ASSP_BYTE_SLICE_LEN], rax

.done:
    add rsp, 56
    ret

prepare_difficulty_label:
    sub rsp, 88

    mov qword [difficulty_label_len], 0
    mov rcx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_LEN]
    cmp qword [chart_name_tag_allowed], 0
    je .legacy_description
    mov r8, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov r9, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    jmp .resolve

.legacy_description:
    lea r8, [newline]
    xor r9d, r9d

.resolve:
    mov rax, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov [rsp + 32], rax
    mov rax, [chart_info + ASSP_CHART_INFO_METER_LEN]
    mov [rsp + 40], rax
    mov rax, [timing_format_sm]
    mov [rsp + 48], rax
    lea rax, [difficulty_label_buffer]
    mov [rsp + 56], rax
    mov qword [rsp + 64], METADATA_BUFFER_CAP
    call assp_resolve_difficulty_label
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, METADATA_BUFFER_CAP
    ja .fail
    mov [difficulty_label_len], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 88
    ret

prepare_tech_notation:
    sub rsp, 56

    mov qword [tech_notation_len], 0
    cmp qword [timing_format_sm], 0
    je .ssc_credit
    lea rcx, [newline]
    xor edx, edx
    jmp .description

.ssc_credit:
    mov rcx, [step_artist_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [step_artist_slice + ASSP_BYTE_SLICE_LEN]

.description:
    cmp qword [chart_name_tag_allowed], 0
    je .legacy_description
    mov r8, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov r9, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    jmp .parse
.legacy_description:
    lea r8, [newline]
    xor r9d, r9d
.parse:
    lea rax, [tech_notation_buffer]
    mov [rsp + 32], rax
    mov qword [rsp + 40], TECH_BUFFER_CAP
    call assp_parse_tech_notation
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, TECH_BUFFER_CAP
    ja .fail
    mov [tech_notation_len], rax
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

prepare_step_parity_bpm_4:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    mov rax, [offset_ms]
    mov [rsp + 32], rax
    lea rax, [parity_row_seconds]
    mov [rsp + 40], rax
    lea rax, [parity_row_ms]
    mov [rsp + 48], rax
    lea rax, [parity_row_beats]
    mov [rsp + 56], rax
    mov qword [rsp + 64], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_bpm_row_times_4
    profile_end_call profile_step_row_times_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_source_row_count], rax
    add rsp, 152
    call prepare_step_parity_rows_4
    ret

.fail:
    xor eax, eax

.done:
    add rsp, 152
    ret

prepare_step_parity_rows_4:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [parity_row_beats]
    mov r9, [parity_source_row_count]
    lea rax, [parity_hold_end_beats]
    mov [rsp + 32], rax
    mov qword [rsp + 40], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_hold_head_ends_4
    profile_end_call profile_step_hold_ends_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, [parity_source_row_count]
    jne .fail

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [parity_row_seconds]
    lea r9, [parity_row_ms]
    lea rax, [parity_row_beats]
    mov [rsp + 32], rax
    lea rax, [parity_hold_end_beats]
    mov [rsp + 40], rax
    mov rax, [parity_source_row_count]
    mov [rsp + 48], rax
    lea rax, [parity_note_counts]
    mov [rsp + 56], rax
    lea rax, [parity_tech_masks]
    mov [rsp + 64], rax
    lea rax, [parity_note_masks]
    mov [rsp + 72], rax
    lea rax, [parity_hold_masks]
    mov [rsp + 80], rax
    lea rax, [parity_mine_masks]
    mov [rsp + 88], rax
    lea rax, [parity_prev_live_holds]
    mov [rsp + 96], rax
    lea rax, [parity_prepared_row_seconds]
    mov [rsp + 104], rax
    lea rax, [parity_prepared_row_ms]
    mov [rsp + 112], rax
    mov qword [rsp + 120], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_prepare_hold_rows_4
    profile_end_call profile_step_prepare_rows_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_prepared_row_count], rax
    app_trace trace_app_parity_prepared

    lea rdx, [parity_prepared_rows]
    lea rax, [parity_note_counts]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS], rax
    lea rax, [parity_tech_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS], rax
    lea rax, [parity_note_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS], rax
    lea rax, [parity_hold_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS], rax
    lea rax, [parity_mine_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS], rax
    lea rax, [parity_prev_live_holds]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS], rax
    lea rax, [parity_prepared_row_seconds]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS], rax
    lea rax, [parity_prepared_row_ms]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_MS], rax
    mov rax, [parity_prepared_row_count]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_COUNT], rax

    lea rdx, [parity_workspace]
    lea rax, [parity_out_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS], rax
    mov qword [rdx + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENT_CAP], PARITY_ROW_CAP * 4
    lea rax, [parity_prev_states]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREV_STATES], rax
    lea rax, [parity_prev_costs]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREV_COSTS], rax
    lea rax, [parity_next_states]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_NEXT_STATES], rax
    lea rax, [parity_next_costs]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_NEXT_COSTS], rax
    lea rax, [parity_predecessors]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREDECESSORS], rax
    lea rax, [parity_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PLACEMENTS], rax
    lea rax, [parity_hits]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_HITS], rax
    lea rax, [parity_keys]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_KEYS], rax
    lea rax, [parity_fast_backtrack_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS], rax
    lea rax, [parity_fast_backtrack_predecessors]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS], rax
    mov qword [rdx + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP], PARITY_FAST_STATE_CAP

    lea rcx, [parity_prepared_rows]
    lea rdx, [parity_workspace]
    lea r8, [tech_counts]
    app_trace trace_app_parity_fast
    profile_begin_call
    call assp_step_parity_count_prepared_rows_4
    profile_end_call profile_step_dp_fast_ticks
    test eax, eax
    jnz .success

    app_trace trace_app_parity_full
    lea rax, [parity_backtrack_placements]
    mov [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS], rax
    lea rax, [parity_backtrack_predecessors]
    mov [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS], rax
    mov qword [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP], PARITY_STATE_CAP
    lea rcx, [parity_prepared_rows]
    lea rdx, [parity_workspace]
    lea r8, [tech_counts]
    profile_begin_call
    call assp_step_parity_count_prepared_rows_4
    profile_end_call profile_step_dp_full_ticks
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 152
    ret

prepare_step_parity_events_4:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    mov rax, [offset_ms]
    mov [rsp + 32], rax
    lea rax, [parity_row_seconds]
    mov [rsp + 40], rax
    lea rax, [parity_row_ms]
    mov [rsp + 48], rax
    lea rax, [parity_row_beats]
    mov [rsp + 56], rax
    mov qword [rsp + 64], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_bpm_row_times_4
    profile_end_call profile_step_row_times_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_source_row_count], rax

    mov qword [rsp + 96], 0
    profile_begin_call
.row_time_loop:
    mov r10, [rsp + 96]
    cmp r10, [parity_source_row_count]
    jae .row_time_done

    lea r11, [parity_row_beats]
    movss xmm0, [r11 + r10 * 4]
    mulss xmm0, [rel app_const_thousand_f32]
    cvtss2si rax, xmm0

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    lea r8, [stop_segment_buffer]
    mov r9, [stop_segment_count]
    lea r11, [delay_segment_buffer]
    mov [rsp + 32], r11
    mov r11, [delay_segment_count]
    mov [rsp + 40], r11
    lea r11, [warp_segment_buffer]
    mov [rsp + 48], r11
    mov r11, [warp_segment_count]
    mov [rsp + 56], r11
    mov [rsp + 64], rax
    call assp_elapsed_ms_with_events
    sub rax, [offset_ms]

    mov r10, [rsp + 96]
    lea r11, [parity_row_ms]
    mov [r11 + r10 * 4], eax
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_thousand_f32]
    lea r11, [parity_row_seconds]
    movss [r11 + r10 * 4], xmm0

    inc qword [rsp + 96]
    jmp .row_time_loop

.row_time_done:
    profile_end_call profile_step_row_times_ticks
    add rsp, 152
    call prepare_step_parity_rows_4
    ret

.fail:
    xor eax, eax
    add rsp, 152
    ret

prepare_step_parity_bpm_8:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    mov rax, [offset_ms]
    mov [rsp + 32], rax
    lea rax, [parity_row_seconds]
    mov [rsp + 40], rax
    lea rax, [parity_row_ms]
    mov [rsp + 48], rax
    lea rax, [parity_row_beats]
    mov [rsp + 56], rax
    mov qword [rsp + 64], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_bpm_row_times_8
    profile_end_call profile_step_row_times_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_source_row_count], rax
    add rsp, 152
    call prepare_step_parity_rows_8
    ret

.fail:
    xor eax, eax

.done:
    add rsp, 152
    ret

prepare_step_parity_rows_8:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [parity_row_beats]
    mov r9, [parity_source_row_count]
    lea rax, [parity_hold_end_beats]
    mov [rsp + 32], rax
    mov qword [rsp + 40], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_hold_head_ends_8
    profile_end_call profile_step_hold_ends_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, [parity_source_row_count]
    jne .fail

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [parity_row_seconds]
    lea r9, [parity_row_ms]
    lea rax, [parity_row_beats]
    mov [rsp + 32], rax
    lea rax, [parity_hold_end_beats]
    mov [rsp + 40], rax
    mov rax, [parity_source_row_count]
    mov [rsp + 48], rax
    lea rax, [parity_note_counts]
    mov [rsp + 56], rax
    lea rax, [parity_tech_masks]
    mov [rsp + 64], rax
    lea rax, [parity_note_masks]
    mov [rsp + 72], rax
    lea rax, [parity_hold_masks]
    mov [rsp + 80], rax
    lea rax, [parity_mine_masks]
    mov [rsp + 88], rax
    lea rax, [parity_prev_live_holds]
    mov [rsp + 96], rax
    lea rax, [parity_prepared_row_seconds]
    mov [rsp + 104], rax
    lea rax, [parity_prepared_row_ms]
    mov [rsp + 112], rax
    mov qword [rsp + 120], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_prepare_hold_rows_8
    profile_end_call profile_step_prepare_rows_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_prepared_row_count], rax
    app_trace trace_app_parity_prepared

    lea rdx, [parity_prepared_rows]
    lea rax, [parity_note_counts]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS], rax
    lea rax, [parity_tech_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS], rax
    lea rax, [parity_note_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS], rax
    lea rax, [parity_hold_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS], rax
    lea rax, [parity_mine_masks]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS], rax
    lea rax, [parity_prev_live_holds]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS], rax
    lea rax, [parity_prepared_row_seconds]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS], rax
    lea rax, [parity_prepared_row_ms]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_MS], rax
    mov rax, [parity_prepared_row_count]
    mov [rdx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_COUNT], rax

    lea rdx, [parity_workspace]
    lea rax, [parity_out_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS], rax
    mov qword [rdx + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENT_CAP], PARITY_ROW_CAP * 8
    lea rax, [parity_prev_states]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREV_STATES], rax
    lea rax, [parity_prev_costs]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREV_COSTS], rax
    lea rax, [parity_next_states]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_NEXT_STATES], rax
    lea rax, [parity_next_costs]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_NEXT_COSTS], rax
    lea rax, [parity_predecessors]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PREDECESSORS], rax
    lea rax, [parity_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_PLACEMENTS], rax
    lea rax, [parity_hits]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_HITS], rax
    lea rax, [parity_keys]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_KEYS], rax
    lea rax, [parity_fast_backtrack_placements]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS], rax
    lea rax, [parity_fast_backtrack_predecessors]
    mov [rdx + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS], rax
    mov qword [rdx + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP], PARITY_FAST_STATE_CAP

    lea rcx, [parity_prepared_rows]
    lea rdx, [parity_workspace]
    lea r8, [tech_counts]
    app_trace trace_app_parity_fast
    profile_begin_call
    call assp_step_parity_count_prepared_rows_8
    profile_end_call profile_step_dp_fast_ticks
    test eax, eax
    jnz .success

    app_trace trace_app_parity_full
    lea rax, [parity_backtrack_placements]
    mov [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS], rax
    lea rax, [parity_backtrack_predecessors]
    mov [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS], rax
    mov qword [parity_workspace + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP], PARITY_STATE_CAP
    lea rcx, [parity_prepared_rows]
    lea rdx, [parity_workspace]
    lea r8, [tech_counts]
    profile_begin_call
    call assp_step_parity_count_prepared_rows_8
    profile_end_call profile_step_dp_full_ticks
    test eax, eax
    jz .fail

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 152
    ret

prepare_step_parity_events_8:
    sub rsp, 152

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [bpm_segment_buffer]
    mov r9, [bpm_segment_count]
    mov rax, [offset_ms]
    mov [rsp + 32], rax
    lea rax, [parity_row_seconds]
    mov [rsp + 40], rax
    lea rax, [parity_row_ms]
    mov [rsp + 48], rax
    lea rax, [parity_row_beats]
    mov [rsp + 56], rax
    mov qword [rsp + 64], PARITY_ROW_CAP
    profile_begin_call
    call assp_step_parity_bpm_row_times_8
    profile_end_call profile_step_row_times_ticks
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, PARITY_ROW_CAP
    ja .fail
    mov [parity_source_row_count], rax

    mov qword [rsp + 96], 0
    profile_begin_call
.row_time_loop:
    mov r10, [rsp + 96]
    cmp r10, [parity_source_row_count]
    jae .row_time_done

    lea r11, [parity_row_beats]
    movss xmm0, [r11 + r10 * 4]
    mulss xmm0, [rel app_const_thousand_f32]
    cvtss2si rax, xmm0

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    lea r8, [stop_segment_buffer]
    mov r9, [stop_segment_count]
    lea r11, [delay_segment_buffer]
    mov [rsp + 32], r11
    mov r11, [delay_segment_count]
    mov [rsp + 40], r11
    lea r11, [warp_segment_buffer]
    mov [rsp + 48], r11
    mov r11, [warp_segment_count]
    mov [rsp + 56], r11
    mov [rsp + 64], rax
    call assp_elapsed_ms_with_events
    sub rax, [offset_ms]

    mov r10, [rsp + 96]
    lea r11, [parity_row_ms]
    mov [r11 + r10 * 4], eax
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_thousand_f32]
    lea r11, [parity_row_seconds]
    movss [r11 + r10 * 4], xmm0

    inc qword [rsp + 96]
    jmp .row_time_loop

.row_time_done:
    profile_end_call profile_step_row_times_ticks
    add rsp, 152
    call prepare_step_parity_rows_8
    ret

.fail:
    xor eax, eax
    add rsp, 152
    ret

prepare_tech_counts:
    sub rsp, 40

    cmp qword [chart_lanes], 8
    je .count_8

    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jz .count_4_bpm
    cmp qword [fake_segment_count], 0
    jne .count_4_brackets

    call prepare_step_parity_events_4
    test eax, eax
    jnz .done
    jmp .count_4_brackets

.count_4_bpm:
    call prepare_step_parity_bpm_4
    test eax, eax
    jnz .done

.count_4_brackets:
    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [tech_counts]
    profile_begin_call
    call assp_count_step_tech_brackets_minimized_4
    profile_end_call profile_step_fallback_ticks
    jmp .done

.count_8:
    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jz .count_8_bpm
    cmp qword [fake_segment_count], 0
    jne .count_8_brackets
    call prepare_step_parity_events_8
    test eax, eax
    jnz .done
    jmp .count_8_brackets

.count_8_bpm:
    call prepare_step_parity_bpm_8
    test eax, eax
    jnz .done

.count_8_brackets:
    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [tech_counts]
    profile_begin_call
    call assp_count_step_tech_brackets_minimized_8
    profile_end_call profile_step_fallback_ticks

.done:
    add rsp, 40
    ret

prepare_offset:
    sub rsp, 56

    mov qword [offset_ms], 0
    mov qword [offset_us], 0
    mov qword [chart_has_own_timing], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_LEN], 0

    mov rcx, [global_offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_offset_slice + ASSP_BYTE_SLICE_LEN]
    test rcx, rcx
    jz .chart_offset
    call assp_parse_offset_ms
    mov [offset_ms], rax
    mov rcx, [global_offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [global_offset_slice + ASSP_BYTE_SLICE_LEN]
    call assp_parse_offset_us
    mov [offset_us], rax

.chart_offset:
    cmp qword [timing_allow_steps], 0
    je .success

    mov qword [offset_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [tag_offset]
    mov edx, tag_offset_end - tag_offset
    lea r8, [offset_slice]
    call find_current_chart_tag
    test eax, eax
    jz .success

    mov qword [chart_has_own_timing], ASSP_TRUE
    mov rcx, [offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [offset_slice + ASSP_BYTE_SLICE_LEN]
    call assp_parse_offset_ms
    mov [offset_ms], rax
    mov rcx, [offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [offset_slice + ASSP_BYTE_SLICE_LEN]
    call assp_parse_offset_us
    mov [offset_us], rax

.success:
    mov eax, ASSP_TRUE
    add rsp, 56
    ret

prepare_duration:
    sub rsp, 80

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    cmp qword [chart_lanes], 8
    je .last_beat_8
    call assp_last_beat_milli_4
    jmp .last_beat_done
.last_beat_8:
    call assp_last_beat_milli_8
.last_beat_done:
    cmp rax, ASSP_NOT_FOUND
    je .fail
    mov [last_beat_milli], rax
    test rax, rax
    jz .zero_duration

    mov rax, [stop_segment_count]
    or rax, [delay_segment_count]
    or rax, [warp_segment_count]
    jz .bpm_only

    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    lea r8, [stop_segment_buffer]
    mov r9, [stop_segment_count]
    lea rax, [delay_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [delay_segment_count]
    mov [rsp + 40], rax
    lea rax, [warp_segment_buffer]
    mov [rsp + 48], rax
    mov rax, [warp_segment_count]
    mov [rsp + 56], rax
    mov rax, [last_beat_milli]
    mov [rsp + 64], rax
    call assp_elapsed_ms_with_events
    sub rax, [offset_ms]
    mov [duration_ms], rax
    call store_duration_ms_as_f32
    jmp .success

.bpm_only:
    call prepare_duration_bpm_f32
    lea rcx, [bpm_segment_buffer]
    mov rdx, [bpm_segment_count]
    mov r8, [last_beat_milli]
    call assp_elapsed_ms_bpm_only
    sub rax, [offset_ms]
    mov [duration_ms], rax

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax
    jmp .done

.zero_duration:
    mov qword [duration_ms], 0
    xorps xmm0, xmm0
    movss [duration_seconds_f32], xmm0
    mov eax, ASSP_TRUE

.done:
    add rsp, 80
    ret

store_duration_ms_as_f32:
    cvtsi2ss xmm0, qword [duration_ms]
    divss xmm0, [rel app_const_thousand_f32]
    movss [duration_seconds_f32], xmm0
    ret

prepare_duration_bpm_f32:
    push rbx
    push rsi
    push r12
    push r13
    push r14
    push r15

    mov rax, [last_beat_milli]
    test rax, rax
    jle .zero
    cmp qword [bpm_segment_count], 0
    je .zero

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm6, xmm6
    subss xmm6, xmm7
    movaps xmm7, xmm6

    mov rcx, [last_beat_milli]
    call milli_to_row48_f32_even
    mov r15, rax

    mov rax, [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    lea rbx, [bpm_segment_buffer]
    xor rsi, rsi
    xor r12, r12
    mov r13, [bpm_segment_count]

.loop:
    cmp rsi, r13
    jae .tail
    mov r14, rsi
    shl r14, 4
    mov rcx, [rbx + r14 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, r15
    jg .tail
    cmp rax, r12
    jle .set_bpm
    mov rcx, rax
    sub rcx, r12
    call add_rows_to_duration_f32
    mov r12, rax

.set_bpm:
    mov rax, [rbx + r14 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0
    inc rsi
    jmp .loop

.tail:
    cmp r15, r12
    jle .store
    mov rcx, r15
    sub rcx, r12
    call add_rows_to_duration_f32

.store:
    movss [duration_seconds_f32], xmm7
    jmp .done

.zero:
    xorps xmm0, xmm0
    movss [duration_seconds_f32], xmm0

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret

bpm_milli_to_bps_f32:
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_thousand_f32]
    divss xmm0, [rel app_const_60_f32]
    ret

add_rows_to_duration_f32:
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel app_const_48_f32]
    divss xmm0, xmm6
    addss xmm7, xmm0
    ret

prepare_bpm_median_nps_f32:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    mov rdi, [measure_count]
    test rdi, rdi
    jz .zero
    mov r12, [bpm_segment_count]
    test r12, r12
    jz .zero

    lea rbx, [bpm_segment_buffer]
    mov rax, [rbx + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm0, xmm0
    subss xmm0, xmm7
    movaps xmm7, xmm0
    cvtss2sd xmm5, xmm7

    lea r14, [density_buffer]
    xor esi, esi
    xor r13d, r13d
    xor r15d, r15d

.fill_loop:
    cmp r15, rdi
    jae .median

    mov r11, r15
    inc r11
    imul r11, 192

    xor esi, esi
    xor r13d, r13d
    mov rax, [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm0, xmm0
    subss xmm0, xmm7
    movaps xmm7, xmm0

.advance_loop:
    cmp rsi, r12
    jae .tail
    mov r10, rsi
    shl r10, 4
    mov rcx, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, r11
    jg .tail
    cmp rax, r13
    jle .set_bpm
    mov rcx, rax
    sub rcx, r13
    call add_rows_to_duration_f32
    mov r13, rax

.set_bpm:
    mov r10, rsi
    shl r10, 4
    mov rax, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0
    inc rsi
    jmp .advance_loop

.tail:
    cmp r11, r13
    jle .have_end
    mov rcx, r11
    sub rcx, r13
    call add_rows_to_duration_f32
    mov r13, r11

.have_end:
    cvtss2sd xmm1, xmm7
    movapd xmm2, xmm1
    subsd xmm2, xmm5
    movapd xmm5, xmm1

    xorpd xmm3, xmm3
    mov eax, [r14 + r15 * 4]
    test eax, eax
    jz .store
    ucomisd xmm2, [rel app_const_0_12_f64]
    jbe .store
    cvtsi2sd xmm3, rax
    divsd xmm3, xmm2

.store:
    lea rdx, [nps_raw_buffer]
    movsd [rdx + r15 * 8], xmm3
    inc r15
    jmp .fill_loop

.median:
    call copy_nps_sort_buffer
    mov rax, rdi
    shr rax, 1
    lea rsi, [nps_sort_buffer]
    test rdi, 1
    jz .even

.odd:
    mov r8, rax
    call kth_nps_f64_value
    jmp .round

.even:
    mov r8, rax
    dec r8
    call kth_nps_f64_value
    movsd [rsp], xmm0
    mov rax, rdi
    shr rax, 1
    mov r8, rax
    call kth_nps_f64_value
    addsd xmm0, [rsp]
    mulsd xmm0, [rel app_const_half_f64]

.round:
    mulsd xmm0, [rel app_const_100_f64]
    cvtsd2si rax, xmm0
    jmp .done

.zero:
    xor eax, eax

.done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

%define RAW_EVT_BPM_IDX 0
%define RAW_EVT_STOP_IDX 8
%define RAW_EVT_DELAY_IDX 16
%define RAW_EVT_WARP_IDX 24
%define RAW_EVT_IS_WARPING 32
%define RAW_EVT_WARP_DEST_ROW 40
%define RAW_EVT_LAST_ROW 48
%define RAW_EVT_MEASURE_IDX 56
%define RAW_EVT_BEST_ROW 64
%define RAW_EVT_BEST_TYPE 72
%define RAW_EVT_TARGET_ROW 80
%define RAW_EVT_MEDIAN_TMP 88
%define RAW_EVT_LOCAL_SIZE 112

prepare_events_median_nps_f32:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, RAW_EVT_LOCAL_SIZE

    mov rdi, [measure_count]
    test rdi, rdi
    jz .zero

    lea rbx, [bpm_segment_buffer]
    lea r12, [stop_segment_buffer]
    lea r13, [delay_segment_buffer]
    lea r14, [warp_segment_buffer]
    lea r15, [density_buffer]

    mov qword [rsp + RAW_EVT_BPM_IDX], 0
    mov qword [rsp + RAW_EVT_STOP_IDX], 0
    mov qword [rsp + RAW_EVT_DELAY_IDX], 0
    mov qword [rsp + RAW_EVT_WARP_IDX], 0
    mov qword [rsp + RAW_EVT_IS_WARPING], 0
    mov qword [rsp + RAW_EVT_WARP_DEST_ROW], 0
    mov qword [rsp + RAW_EVT_LAST_ROW], 0
    mov qword [rsp + RAW_EVT_MEASURE_IDX], 0

    mov rax, [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm0, xmm0
    subss xmm0, xmm7
    movaps xmm7, xmm0
    cvtss2sd xmm5, xmm7

.fill_loop:
    mov rax, [rsp + RAW_EVT_MEASURE_IDX]
    cmp rax, rdi
    jae .median
    inc rax
    imul rax, 192
    mov [rsp + RAW_EVT_TARGET_ROW], rax

    mov qword [rsp + RAW_EVT_BPM_IDX], 0
    mov qword [rsp + RAW_EVT_STOP_IDX], 0
    mov qword [rsp + RAW_EVT_DELAY_IDX], 0
    mov qword [rsp + RAW_EVT_WARP_IDX], 0
    mov qword [rsp + RAW_EVT_IS_WARPING], 0
    mov qword [rsp + RAW_EVT_WARP_DEST_ROW], 0
    mov qword [rsp + RAW_EVT_LAST_ROW], 0

    mov rax, [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm0, xmm0
    subss xmm0, xmm7
    movaps xmm7, xmm0

.select_loop:
    mov rax, 0x7fffffffffffffff
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 0

    cmp qword [rsp + RAW_EVT_IS_WARPING], 0
    je .check_bpm
    mov r8, [rsp + RAW_EVT_WARP_DEST_ROW]
    mov [rsp + RAW_EVT_BEST_ROW], r8
    mov qword [rsp + RAW_EVT_BEST_TYPE], 1

.check_bpm:
    mov rax, [rsp + RAW_EVT_BPM_IDX]
    cmp rax, [bpm_segment_count]
    jae .check_delay
    mov r10, rax
    shl r10, 4
    mov rcx, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, [rsp + RAW_EVT_BEST_ROW]
    jge .check_delay
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 2

.check_delay:
    mov rax, [rsp + RAW_EVT_DELAY_IDX]
    cmp rax, [delay_segment_count]
    jae .check_marker
    mov r10, rax
    shl r10, 4
    mov rcx, [r13 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, [rsp + RAW_EVT_BEST_ROW]
    jge .check_marker
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 3

.check_marker:
    mov rax, [rsp + RAW_EVT_TARGET_ROW]
    cmp rax, [rsp + RAW_EVT_BEST_ROW]
    jge .check_stop
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 4

.check_stop:
    mov rax, [rsp + RAW_EVT_STOP_IDX]
    cmp rax, [stop_segment_count]
    jae .check_warp
    mov r10, rax
    shl r10, 4
    mov rcx, [r12 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, [rsp + RAW_EVT_BEST_ROW]
    jge .check_warp
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 5

.check_warp:
    mov rax, [rsp + RAW_EVT_WARP_IDX]
    cmp rax, [warp_segment_count]
    jae .apply_selected
    mov r10, rax
    shl r10, 4
    mov rcx, [r14 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call milli_to_row48_f32_even
    cmp rax, [rsp + RAW_EVT_BEST_ROW]
    jge .apply_selected
    mov [rsp + RAW_EVT_BEST_ROW], rax
    mov qword [rsp + RAW_EVT_BEST_TYPE], 6

.apply_selected:
    cmp qword [rsp + RAW_EVT_BEST_TYPE], 0
    je .store_measure

    mov r8, [rsp + RAW_EVT_BEST_ROW]
    cmp qword [rsp + RAW_EVT_IS_WARPING], 0
    jne .dispatch_event
    mov r9, [rsp + RAW_EVT_LAST_ROW]
    cmp r8, r9
    jle .dispatch_event
    mov rcx, r8
    sub rcx, r9
    call add_rows_to_duration_f32

.dispatch_event:
    mov rax, [rsp + RAW_EVT_BEST_TYPE]
    cmp rax, 4
    je .store_measure
    cmp rax, 1
    je .apply_warp_dest
    cmp rax, 2
    je .apply_bpm
    cmp rax, 3
    je .apply_delay
    cmp rax, 5
    je .apply_stop
    jmp .apply_warp

.apply_warp_dest:
    mov qword [rsp + RAW_EVT_IS_WARPING], 0
    jmp .event_done

.apply_bpm:
    mov rax, [rsp + RAW_EVT_BPM_IDX]
    mov r10, rax
    shl r10, 4
    mov rax, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0
    inc qword [rsp + RAW_EVT_BPM_IDX]
    jmp .event_done

.apply_delay:
    mov rax, [rsp + RAW_EVT_DELAY_IDX]
    mov r10, rax
    shl r10, 4
    mov rax, [r13 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_million_f32]
    addss xmm7, xmm0
    inc qword [rsp + RAW_EVT_DELAY_IDX]
    jmp .event_done

.apply_stop:
    mov rax, [rsp + RAW_EVT_STOP_IDX]
    mov r10, rax
    shl r10, 4
    mov rax, [r12 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_million_f32]
    addss xmm7, xmm0
    inc qword [rsp + RAW_EVT_STOP_IDX]
    jmp .event_done

.apply_warp:
    mov rax, [rsp + RAW_EVT_WARP_IDX]
    mov r10, rax
    shl r10, 4
    mov rcx, [r14 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    add rcx, [r14 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call milli_to_row48_f32_even
    cmp rax, [rsp + RAW_EVT_WARP_DEST_ROW]
    jle .warp_dest_ready
    mov [rsp + RAW_EVT_WARP_DEST_ROW], rax
.warp_dest_ready:
    mov qword [rsp + RAW_EVT_IS_WARPING], 1
    inc qword [rsp + RAW_EVT_WARP_IDX]

.event_done:
    mov rax, [rsp + RAW_EVT_BEST_ROW]
    mov [rsp + RAW_EVT_LAST_ROW], rax
    jmp .select_loop

.store_measure:
    mov rax, [rsp + RAW_EVT_BEST_ROW]
    mov [rsp + RAW_EVT_LAST_ROW], rax

    cvtss2sd xmm1, xmm7
    movapd xmm2, xmm1
    subsd xmm2, xmm5
    movapd xmm5, xmm1

    xorpd xmm3, xmm3
    mov rax, [rsp + RAW_EVT_MEASURE_IDX]
    mov r11d, [r15 + rax * 4]
    test r11d, r11d
    jz .store_raw
    ucomisd xmm2, [rel app_const_0_12_f64]
    jbe .store_raw
    cvtsi2sd xmm3, r11
    divsd xmm3, xmm2

.store_raw:
    lea rdx, [nps_raw_buffer]
    mov rax, [rsp + RAW_EVT_MEASURE_IDX]
    movsd [rdx + rax * 8], xmm3
    inc qword [rsp + RAW_EVT_MEASURE_IDX]
    jmp .fill_loop

.median:
    call copy_nps_sort_buffer
    mov rax, rdi
    shr rax, 1
    lea rsi, [nps_sort_buffer]
    test rdi, 1
    jz .even

.odd:
    mov r8, rax
    call kth_nps_f64_value
    jmp .round

.even:
    mov r8, rax
    dec r8
    call kth_nps_f64_value
    movsd [rsp + RAW_EVT_MEDIAN_TMP], xmm0
    mov rax, rdi
    shr rax, 1
    mov r8, rax
    call kth_nps_f64_value
    addsd xmm0, [rsp + RAW_EVT_MEDIAN_TMP]
    mulsd xmm0, [rel app_const_half_f64]

.round:
    mulsd xmm0, [rel app_const_100_f64]
    cvtsd2si rax, xmm0
    jmp .done

.zero:
    xor eax, eax

.done:
    add rsp, RAW_EVT_LOCAL_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

prepare_fixed_median_nps_f32:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 32

    mov rdi, [measure_count]
    test rdi, rdi
    jz .zero

    mov rax, [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI]
    test rax, rax
    jle .zero
    call bpm_milli_to_bps_f32
    movaps xmm6, xmm0

    cvtsi2ss xmm7, qword [offset_us]
    divss xmm7, [rel app_const_million_f32]
    xorps xmm0, xmm0
    subss xmm0, xmm7
    movaps xmm7, xmm0
    cvtss2sd xmm5, xmm7

    lea rbx, [density_buffer]
    lea r12, [nps_raw_buffer]
    xor rsi, rsi

.fill_loop:
    cmp rsi, rdi
    jae .median

    mov rax, rsi
    inc rax
    imul rax, 192
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_48_f32]
    divss xmm0, xmm6
    addss xmm0, xmm7

    cvtss2sd xmm1, xmm0
    movapd xmm2, xmm1
    subsd xmm2, xmm5
    movapd xmm5, xmm1

    xorpd xmm3, xmm3
    mov r13d, [rbx + rsi * 4]
    test r13d, r13d
    jz .store
    ucomisd xmm2, [rel app_const_0_12_f64]
    jbe .store
    cvtsi2sd xmm3, r13
    divsd xmm3, xmm2

.store:
    movsd [r12 + rsi * 8], xmm3
    inc rsi
    jmp .fill_loop

.median:
    call copy_nps_sort_buffer
    mov rax, rdi
    shr rax, 1
    lea rsi, [nps_sort_buffer]
    test rdi, 1
    jz .even

.odd:
    mov r8, rax
    call kth_nps_f64_value
    jmp .round

.even:
    mov r8, rax
    dec r8
    call kth_nps_f64_value
    movsd [rsp], xmm0
    mov rax, rdi
    shr rax, 1
    mov r8, rax
    call kth_nps_f64_value
    addsd xmm0, [rsp]
    mulsd xmm0, [rel app_const_half_f64]

.round:
    mulsd xmm0, [rel app_const_100_f64]
    cvtsd2si rax, xmm0
    jmp .done

.zero:
    xor eax, eax

.done:
    add rsp, 32
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

copy_nps_sort_buffer:
    xor r10d, r10d
    lea r11, [nps_raw_buffer]
    lea rax, [nps_sort_buffer]

.loop:
    cmp r10, rdi
    jae .done
    mov rdx, [r11 + r10 * 8]
    mov [rax + r10 * 8], rdx
    inc r10
    jmp .loop

.done:
    ret

; rsi = f64 values, rdi = count, r8 = kth index. xmm0 = kth value.
kth_nps_f64_value:
    test rdi, rdi
    jz .zero
    xor r10d, r10d
    mov r11, rdi
    dec r11

.select_loop:
    cmp r10, r11
    jne .partition
    movsd xmm0, [rsi + r10 * 8]
    ret

.partition:
    mov r9, r10
    add r9, r11
    shr r9, 1
    movsd xmm2, [rsi + r9 * 8]
    mov rcx, r10
    mov rdx, r11

.partition_loop:
.scan_left:
    movsd xmm0, [rsi + rcx * 8]
    ucomisd xmm0, xmm2
    jae .scan_right
    inc rcx
    jmp .scan_left

.scan_right:
    movsd xmm1, [rsi + rdx * 8]
    ucomisd xmm1, xmm2
    jbe .maybe_swap
    dec rdx
    jmp .scan_right

.maybe_swap:
    cmp rcx, rdx
    jae .partition_done
    movsd [rsi + rcx * 8], xmm1
    movsd [rsi + rdx * 8], xmm0
    inc rcx
    test rdx, rdx
    jz .partition_done
    dec rdx
    jmp .partition_loop

.partition_done:
    cmp r8, rdx
    jbe .select_left
    lea r10, [rdx + 1]
    jmp .select_loop

.select_left:
    mov r11, rdx
    jmp .select_loop

.zero:
    xorpd xmm0, xmm0
    ret

print_report:
    sub rsp, 40

    lea rcx, [msg_header]
    call print_z
    lea rcx, [label_file]
    call print_z
    mov rcx, [input_path]
    call print_z
    lea rcx, [newline]
    call print_z

    lea rcx, [label_title]
    mov rdx, [title_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [title_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_subtitle]
    mov rdx, [subtitle_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [subtitle_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_artist]
    mov rdx, [artist_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [artist_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_genre]
    mov rdx, [genre_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [genre_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_title_trans]
    mov rdx, [title_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [title_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_subtitle_trans]
    mov rdx, [subtitle_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [subtitle_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_artist_trans]
    mov rdx, [artist_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [artist_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_title_translated]
    mov rdx, [title_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [title_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_subtitle_translated]
    mov rdx, [subtitle_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [subtitle_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_artist_translated]
    mov rdx, [artist_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [artist_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_unescaped_slice_field
    lea rcx, [label_music]
    mov rdx, [music_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [music_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_banner]
    mov rdx, [banner_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [banner_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_background]
    mov rdx, [background_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [background_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_cdtitle]
    mov rdx, [cdtitle_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [cdtitle_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_jacket]
    mov rdx, [jacket_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [jacket_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_sample_start]
    mov rdx, [sample_start_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [sample_start_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_sample_length]
    mov rdx, [sample_length_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [sample_length_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_version]
    mov rdx, [version_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [version_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_timing_format_sm]
    mov rdx, [timing_format_sm]
    call print_field
    lea rcx, [label_steps_timing_allowed]
    mov rdx, [timing_allow_steps]
    call print_field
    lea rcx, [label_chart_name_tag_allowed]
    mov rdx, [chart_name_tag_allowed]
    call print_field

    lea rcx, [label_chart]
    mov rdx, [chart_index]
    call print_field
    lea rcx, [label_step_type]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call print_slice_field
    lea rcx, [label_steps_type]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call print_slice_field
    lea rcx, [label_difficulty]
    lea rdx, [difficulty_label_buffer]
    mov r8, [difficulty_label_len]
    call print_slice_field
    lea rcx, [label_raw_difficulty]
    mov rdx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_DIFFICULTY_LEN]
    call print_slice_field
    lea rcx, [label_meter]
    mov rdx, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_METER_LEN]
    call print_slice_field
    lea rcx, [label_rating]
    mov rdx, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_METER_LEN]
    call print_slice_field
    lea rcx, [label_description]
    cmp qword [chart_name_tag_allowed], 0
    je .legacy_description
    mov rdx, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    jmp .print_description
.legacy_description:
    lea rdx, [newline]
    xor r8d, r8d
.print_description:
    call print_slice_field
    lea rcx, [label_chart_name]
    cmp qword [chart_name_tag_allowed], 0
    je .legacy_chart_name
    mov rdx, [chart_name_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_name_slice + ASSP_BYTE_SLICE_LEN]
    jmp .print_chart_name
.legacy_chart_name:
    mov rdx, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_DESC_LEN]
.print_chart_name:
    call print_slice_field
    lea rcx, [label_step_artist]
    mov rdx, [step_artist_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [step_artist_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_step_artists]
    mov rdx, [step_artist_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [step_artist_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_tech_notation]
    lea rdx, [tech_notation_buffer]
    mov r8, [tech_notation_len]
    call print_slice_field
    lea rcx, [label_crossovers]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_CROSSOVERS]
    call print_field
    lea rcx, [label_footswitches]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_FOOTSWITCHES]
    call print_field
    lea rcx, [label_up_footswitches]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]
    call print_field
    lea rcx, [label_down_footswitches]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    call print_field
    lea rcx, [label_sideswitches]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_SIDESWITCHES]
    call print_field
    lea rcx, [label_jacks]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_JACKS]
    call print_field
    lea rcx, [label_brackets]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_BRACKETS]
    call print_field
    lea rcx, [label_doublesteps]
    mov edx, [tech_counts + ASSP_TECH_COUNTS_DOUBLESTEPS]
    call print_field
    lea rcx, [label_chart_music]
    mov rdx, [chart_music_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_music_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_attacks]
    mov rdx, [chart_attacks_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_attacks_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_attacks]
    mov rdx, [global_attacks_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_attacks_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_selected_attacks]
    lea rdx, [chart_attacks_slice]
    lea r8, [global_attacks_slice]
    call print_chart_or_global_tag_by_ptr
    lea rcx, [label_chart_time_signatures]
    mov rdx, [chart_time_signatures_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_time_signatures_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_labels]
    mov rdx, [chart_labels_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_labels_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_tickcounts]
    mov rdx, [chart_tickcounts_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_tickcounts_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_combos]
    mov rdx, [chart_combos_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_combos_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_time_signatures]
    mov rdx, [global_time_signatures_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_time_signatures_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_labels]
    mov rdx, [global_labels_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_labels_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_tickcounts]
    mov rdx, [global_tickcounts_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_tickcounts_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_combos]
    mov rdx, [global_combos_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_combos_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_selected_time_signatures]
    lea rdx, [chart_time_signatures_slice]
    lea r8, [global_time_signatures_slice]
    call print_selected_metadata_tag
    lea rcx, [label_selected_labels]
    lea rdx, [chart_labels_slice]
    lea r8, [global_labels_slice]
    call print_selected_metadata_tag
    lea rcx, [label_selected_tickcounts]
    lea rdx, [chart_tickcounts_slice]
    lea r8, [global_tickcounts_slice]
    call print_selected_metadata_tag
    lea rcx, [label_selected_combos]
    lea rdx, [chart_combos_slice]
    lea r8, [global_combos_slice]
    call print_selected_metadata_tag
    lea rcx, [label_normalized_time_signatures]
    lea rdx, [normalized_time_signatures_buffer]
    mov r8, [normalized_time_signatures_len]
    call print_slice_field
    lea rcx, [label_normalized_labels]
    lea rdx, [normalized_labels_buffer]
    mov r8, [normalized_labels_len]
    call print_slice_field
    lea rcx, [label_normalized_tickcounts]
    lea rdx, [normalized_tickcounts_buffer]
    mov r8, [normalized_tickcounts_len]
    call print_slice_field
    lea rcx, [label_normalized_combos]
    lea rdx, [normalized_combos_buffer]
    mov r8, [normalized_combos_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_time_signatures]
    lea rdx, [selected_normalized_time_signatures_buffer]
    mov r8, [selected_normalized_time_signatures_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_labels]
    lea rdx, [selected_normalized_labels_buffer]
    mov r8, [selected_normalized_labels_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_tickcounts]
    lea rdx, [selected_normalized_tickcounts_buffer]
    mov r8, [selected_normalized_tickcounts_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_combos]
    lea rdx, [selected_normalized_combos_buffer]
    mov r8, [selected_normalized_combos_len]
    call print_slice_field
    lea rcx, [label_global_bpms]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_stops]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_delays]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_warps]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_speeds]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_scrolls]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_fakes]
    mov rdx, [global_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_bpms]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_BPMS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_stops]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_delays]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_DELAYS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_warps]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_WARPS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_speeds]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_SPEEDS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_scrolls]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_SCROLLS + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_fakes]
    mov rdx, [chart_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_PTR]
    mov r8, [chart_timing_tags + ASSP_TIMING_TAGS_FAKES + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_chart_display_bpm]
    mov rdx, [display_bpm_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [display_bpm_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_global_display_bpm]
    mov rdx, [global_display_bpm_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [global_display_bpm_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_selected_display_bpm]
    lea rdx, [display_bpm_slice]
    lea r8, [global_display_bpm_slice]
    call print_chart_or_global_tag_by_len
    lea rcx, [label_file_md5_hash]
    lea rdx, [file_md5_hash]
    mov r8d, 32
    call print_slice_field
    lea rcx, [label_hash]
    lea rdx, [hash_pair]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_sha1]
    lea rdx, [hash_pair]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_sha1_hash]
    lea rdx, [hash_pair]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_bpm_neutral_hash]
    lea rdx, [hash_pair + 16]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_bpm_neutral_sha1]
    lea rdx, [hash_pair + 16]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_bpm_neutral_sha1_hash]
    lea rdx, [hash_pair + 16]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_hash_bpms]
    mov rdx, [hash_bpms_ptr]
    mov r8, [normalized_bpms_len]
    call print_slice_field
    lea rcx, [label_bpm_data]
    lea rdx, [global_bpm_buffer]
    mov r8, [global_bpms_len]
    call print_slice_field
    lea rcx, [label_normalized_bpms]
    lea rdx, [global_bpm_buffer]
    mov r8, [global_bpms_len]
    call print_slice_field
    lea rcx, [label_normalized_stops]
    lea rdx, [normalized_stops_buffer]
    mov r8, [normalized_stops_len]
    call print_slice_field
    lea rcx, [label_normalized_delays]
    lea rdx, [normalized_delays_buffer]
    mov r8, [normalized_delays_len]
    call print_slice_field
    lea rcx, [label_normalized_warps]
    lea rdx, [normalized_warps_buffer]
    mov r8, [normalized_warps_len]
    call print_slice_field
    lea rcx, [label_normalized_speeds]
    lea rdx, [normalized_speeds_buffer]
    mov r8, [normalized_speeds_len]
    call print_slice_field
    lea rcx, [label_normalized_scrolls]
    lea rdx, [normalized_scrolls_buffer]
    mov r8, [normalized_scrolls_len]
    call print_slice_field
    lea rcx, [label_normalized_fakes]
    lea rdx, [normalized_fakes_buffer]
    mov r8, [normalized_fakes_len]
    call print_slice_field
    lea rcx, [label_bpms_formatted]
    cmp qword [timing_format_sm], 0
    jne .print_bpms_milli
    cmp qword [bpm_report_count], 0
    je .print_bpms_milli
    lea rdx, [bpm_report_segment_buffer]
    mov r8, [bpm_report_count]
    call print_bpm_micro_segments_field
    jmp .printed_bpms
.print_bpms_milli:
    lea rdx, [bpm_segment_buffer]
    mov r8, [bpm_segment_count]
    call print_bpm_segments_field
.printed_bpms:
    lea rcx, [label_stops_formatted]
    lea rdx, [stop_segment_buffer]
    mov r8, [stop_segment_count]
    call print_second_segments_field
    lea rcx, [label_delays_formatted]
    lea rdx, [delay_segment_buffer]
    mov r8, [delay_segment_count]
    call print_second_segments_field
    lea rcx, [label_warps_formatted]
    lea rdx, [warp_segment_buffer]
    mov r8, [warp_segment_count]
    call print_row_segments_field
    lea rcx, [label_fakes_formatted]
    lea rdx, [fake_segment_buffer]
    mov r8, [fake_segment_count]
    call print_row_segments_field
    lea rcx, [label_selected_bpms]
    mov edx, ASSP_TIMING_TAGS_BPMS
    call print_selected_timing_tag
    lea rcx, [label_selected_stops]
    mov edx, ASSP_TIMING_TAGS_STOPS
    call print_selected_timing_tag
    lea rcx, [label_selected_delays]
    mov edx, ASSP_TIMING_TAGS_DELAYS
    call print_selected_timing_tag
    lea rcx, [label_selected_warps]
    mov edx, ASSP_TIMING_TAGS_WARPS
    call print_selected_timing_tag
    lea rcx, [label_selected_fakes]
    mov edx, ASSP_TIMING_TAGS_FAKES
    call print_selected_timing_tag
    lea rcx, [label_selected_speeds]
    mov edx, ASSP_TIMING_TAGS_SPEEDS
    call print_selected_timing_tag
    lea rcx, [label_selected_scrolls]
    mov edx, ASSP_TIMING_TAGS_SCROLLS
    call print_selected_timing_tag
    lea rcx, [label_selected_normalized_bpms]
    lea rdx, [selected_normalized_bpms_buffer]
    mov r8, [selected_normalized_bpms_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_stops]
    lea rdx, [selected_normalized_stops_buffer]
    mov r8, [selected_normalized_stops_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_delays]
    lea rdx, [selected_normalized_delays_buffer]
    mov r8, [selected_normalized_delays_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_warps]
    lea rdx, [selected_normalized_warps_buffer]
    mov r8, [selected_normalized_warps_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_fakes]
    lea rdx, [selected_normalized_fakes_buffer]
    mov r8, [selected_normalized_fakes_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_speeds]
    lea rdx, [selected_normalized_speeds_buffer]
    mov r8, [selected_normalized_speeds_len]
    call print_slice_field
    lea rcx, [label_selected_normalized_scrolls]
    lea rdx, [selected_normalized_scrolls_buffer]
    mov r8, [selected_normalized_scrolls_len]
    call print_slice_field
    lea rcx, [label_offset]
    mov rdx, [offset_ms]
    call print_fixed3_field
    lea rcx, [label_chart_offset_seconds]
    mov rdx, [offset_ms]
    call print_fixed3_field
    lea rcx, [label_beat0_offset_seconds]
    mov rdx, [offset_ms]
    call print_milli6_field
    lea rcx, [label_beat0_group_offset_seconds]
    xor edx, edx
    call print_milli6_field
    lea rcx, [label_chart_has_own_timing]
    mov rdx, [chart_has_own_timing]
    call print_field
    lea rcx, [label_display_bpm]
    mov rdx, [display_bpm_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [display_bpm_slice + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    lea rcx, [label_bpm]
    mov rdx, [min_bpm]
    mov r8, [max_bpm]
    call print_bpm_field
    lea rcx, [label_display_bpm_resolved]
    mov rdx, [display_text_min_bpm]
    mov r8, [display_text_max_bpm]
    mov r9, [display_bpm_range_flag]
    call print_display_bpm_field
    lea rcx, [label_min_bpm]
    mov rdx, [min_bpm]
    call print_field
    lea rcx, [label_max_bpm]
    mov rdx, [max_bpm]
    call print_field
    lea rcx, [label_display_bpm_min]
    mov rdx, [display_min_bpm]
    call print_fixed3_field
    lea rcx, [label_display_bpm_max]
    mov rdx, [display_max_bpm]
    call print_fixed3_field
    lea rcx, [label_average_bpm]
    mov rdx, [average_bpm_centi]
    call print_fixed2_field
    lea rcx, [label_median_bpm]
    mov rdx, [median_bpm_centi]
    call print_fixed2_field
    lea rcx, [label_measures]
    mov rdx, [measure_count]
    call print_field
    lea rcx, [label_equally_spaced_measures]
    mov rdx, [equally_spaced_measures]
    call print_field
    lea rcx, [label_notes_per_measure]
    lea rdx, [density_buffer]
    mov r8, [measure_count]
    call print_u32_array_field
    lea rcx, [label_nps_per_measure]
    lea rdx, [nps_buffer]
    mov r8, [nps_count]
    call print_milli3_array_field
    lea rcx, [label_equally_spaced_per_measure]
    lea rdx, [equally_spaced_buffer]
    mov r8, [equally_spaced_count]
    call print_bool_array_field
    lea rcx, [label_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_candle_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_candle_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_candle_percent]
    mov rdx, [candle_percent_centi]
    call print_fixed2_field
    lea rcx, [label_total_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_left_foot_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_right_foot_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_candles_percent]
    mov rdx, [candle_percent_centi]
    call print_fixed2_field
    lea rcx, [label_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_box_lr]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    call print_field
    lea rcx, [label_box_ud]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    call print_field
    lea rcx, [label_box_corner]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_box_ld]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    call print_field
    lea rcx, [label_box_lu]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    call print_field
    lea rcx, [label_box_rd]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    call print_field
    lea rcx, [label_box_ru]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_total_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_lr_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    call print_field
    lea rcx, [label_ud_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    call print_field
    lea rcx, [label_corner_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_ld_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    call print_field
    lea rcx, [label_lu_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    call print_field
    lea rcx, [label_rd_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    call print_field
    lea rcx, [label_ru_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_field
    lea rcx, [label_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_tower_lr]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    call print_field
    lea rcx, [label_tower_ud]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    call print_field
    lea rcx, [label_tower_corner]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_tower_ld]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    call print_field
    lea rcx, [label_tower_lu]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    call print_field
    lea rcx, [label_tower_rd]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    call print_field
    lea rcx, [label_tower_ru]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]
    call print_field
    lea rcx, [label_triangle_ldl]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    call print_field
    lea rcx, [label_triangle_lul]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    call print_field
    lea rcx, [label_triangle_rdr]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    call print_field
    lea rcx, [label_triangle_rur]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]
    call print_field
    lea rcx, [label_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_staircase_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    call print_field
    lea rcx, [label_staircase_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    call print_field
    lea rcx, [label_staircase_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_staircase_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_alt_staircase_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    call print_field
    lea rcx, [label_alt_staircase_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    call print_field
    lea rcx, [label_alt_staircase_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    call print_field
    lea rcx, [label_alt_staircase_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_double_staircase_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    call print_field
    lea rcx, [label_double_staircase_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    call print_field
    lea rcx, [label_double_staircase_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_double_staircase_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_sweep_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    call print_field
    lea rcx, [label_sweep_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    call print_field
    lea rcx, [label_sweep_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    call print_field
    lea rcx, [label_sweep_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_candle_sweep_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_candle_sweep_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_candle_sweep_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_candle_sweep_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_copter_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    call print_field
    lea rcx, [label_copter_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    call print_field
    lea rcx, [label_copter_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    call print_field
    lea rcx, [label_copter_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_spiral_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    call print_field
    lea rcx, [label_spiral_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    call print_field
    lea rcx, [label_spiral_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    call print_field
    lea rcx, [label_spiral_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_turbo_candle_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_turbo_candle_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_turbo_candle_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_turbo_candle_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_hip_breaker_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    call print_field
    lea rcx, [label_hip_breaker_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    call print_field
    lea rcx, [label_hip_breaker_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    call print_field
    lea rcx, [label_hip_breaker_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_dorito_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    call print_field
    lea rcx, [label_dorito_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    call print_field
    lea rcx, [label_dorito_inv_left]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    call print_field
    lea rcx, [label_dorito_inv_right]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    call print_field
    lea rcx, [label_luchi_left_du]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    call print_field
    lea rcx, [label_luchi_left_ud]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    call print_field
    lea rcx, [label_luchi_right_du]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    call print_field
    lea rcx, [label_luchi_right_ud]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    call print_field
    lea rcx, [label_total_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_lr_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    call print_field
    lea rcx, [label_ud_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    call print_field
    lea rcx, [label_corner_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_ld_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    call print_field
    lea rcx, [label_lu_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    call print_field
    lea rcx, [label_rd_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    call print_field
    lea rcx, [label_ru_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_field
    lea rcx, [label_total_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]
    call print_field
    lea rcx, [label_ldl_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    call print_field
    lea rcx, [label_lul_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    call print_field
    lea rcx, [label_rdr_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    call print_field
    lea rcx, [label_rur_triangles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]
    call print_field
    lea rcx, [label_total_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    call print_field
    lea rcx, [label_right_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    call print_field
    lea rcx, [label_right_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    call print_field
    lea rcx, [label_right_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    call print_field
    lea rcx, [label_right_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_right_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_candle_sweeps]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    call print_field
    lea rcx, [label_right_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_copters]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    call print_field
    lea rcx, [label_right_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_spirals]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    call print_field
    lea rcx, [label_right_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_turbo_candles]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    call print_field
    lea rcx, [label_right_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_hip_breakers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_left_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    call print_field
    lea rcx, [label_right_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    call print_field
    lea rcx, [label_left_inv_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    call print_field
    lea rcx, [label_right_inv_doritos]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    call print_field
    lea rcx, [label_total_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    call print_field
    lea rcx, [label_left_du_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    call print_field
    lea rcx, [label_left_ud_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    call print_field
    lea rcx, [label_right_du_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    call print_field
    lea rcx, [label_right_ud_luchis]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    call print_field
    lea rcx, [label_anchors]
    mov edx, [anchor_counts + 0]
    add edx, [anchor_counts + 4]
    add edx, [anchor_counts + 8]
    add edx, [anchor_counts + 12]
    call print_field
    lea rcx, [label_anchor_left]
    mov edx, [anchor_counts + 0]
    call print_field
    lea rcx, [label_anchor_down]
    mov edx, [anchor_counts + 4]
    call print_field
    lea rcx, [label_anchor_up]
    mov edx, [anchor_counts + 8]
    call print_field
    lea rcx, [label_anchor_right]
    mov edx, [anchor_counts + 12]
    call print_field
    lea rcx, [label_total_anchors]
    mov edx, [anchor_counts + 0]
    add edx, [anchor_counts + 4]
    add edx, [anchor_counts + 8]
    add edx, [anchor_counts + 12]
    call print_field
    lea rcx, [label_left_anchors]
    mov edx, [anchor_counts + 0]
    call print_field
    lea rcx, [label_down_anchors]
    mov edx, [anchor_counts + 4]
    call print_field
    lea rcx, [label_up_anchors]
    mov edx, [anchor_counts + 8]
    call print_field
    lea rcx, [label_right_anchors]
    mov edx, [anchor_counts + 12]
    call print_field
    lea rcx, [label_mono_total]
    mov edx, [facing_counts + 0]
    add edx, [facing_counts + 4]
    call print_field
    lea rcx, [label_facing_left]
    mov edx, [facing_counts + 0]
    call print_field
    lea rcx, [label_facing_right]
    mov edx, [facing_counts + 4]
    call print_field
    lea rcx, [label_mono_percent]
    mov rdx, [mono_percent_centi]
    call print_fixed2_field
    lea rcx, [label_total_mono]
    mov edx, [facing_counts + 0]
    add edx, [facing_counts + 4]
    call print_field
    lea rcx, [label_left_face_mono]
    mov edx, [facing_counts + 0]
    call print_field
    lea rcx, [label_right_face_mono]
    mov edx, [facing_counts + 4]
    call print_field
    lea rcx, [label_max_nps]
    mov rdx, [max_nps_centi]
    call print_fixed2_field
    lea rcx, [label_peak_nps]
    mov rdx, [max_nps_centi]
    call print_fixed2_field
    lea rcx, [label_peak_nps_milli]
    mov rdx, [peak_nps_milli]
    call print_field
    lea rcx, [label_median_nps]
    mov rdx, [median_nps_centi]
    call print_fixed2_field
    lea rcx, [label_tier_bpm]
    mov rdx, [tier_bpm_centi]
    call print_fixed2_field
    lea rcx, [label_matrix_rating]
    mov rdx, [matrix_rating_centi]
    call print_fixed2_field
    lea rcx, [label_last_beat_milli]
    mov rdx, [last_beat_milli]
    call print_field
    lea rcx, [label_duration_seconds]
    movss xmm0, [duration_seconds_f32]
    call print_f32_field
    lea rcx, [label_duration_ms]
    mov rdx, [duration_ms]
    call print_field
    lea rcx, [label_length]
    mov rdx, [duration_ms]
    call print_duration_field
    lea rcx, [label_stops]
    mov rdx, [stop_report_count]
    call print_field
    lea rcx, [label_stops_freezes]
    mov rdx, [stop_report_count]
    call print_field
    lea rcx, [label_delays]
    mov rdx, [delay_report_count]
    call print_field
    lea rcx, [label_warps]
    mov rdx, [warp_report_count]
    call print_field
    lea rcx, [label_speeds]
    mov rdx, [speed_report_count]
    call print_field
    lea rcx, [label_scrolls]
    mov rdx, [scroll_report_count]
    call print_field
    lea rcx, [label_total_streams]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN16]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN20]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN24]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN32]
    call print_field
    lea rcx, [label_stream16]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN16]
    call print_field
    lea rcx, [label_stream20]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN20]
    call print_field
    lea rcx, [label_stream24]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN24]
    call print_field
    lea rcx, [label_stream32]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN32]
    call print_field
    lea rcx, [label_sn_breaks]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_SN_BREAKS]
    call print_field
    lea rcx, [label_total_breaks]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_TOTAL_BREAKS]
    call print_field
    lea rcx, [label_stream_percent]
    mov rdx, [stream_percent_centi]
    call print_fixed2_field
    lea rcx, [label_adjusted_stream_percent]
    mov rdx, [adjusted_stream_percent_centi]
    call print_fixed2_field
    lea rcx, [label_break_percent]
    mov rdx, [break_percent_centi]
    call print_fixed2_field
    lea rcx, [label_stream_segments]
    mov rdx, [stream_segment_count]
    call print_field
    lea rcx, [label_stream_sequences]
    lea rdx, [stream_segment_buffer]
    mov r8, [stream_segment_count]
    call print_stream_sequences_field
    lea rcx, [label_stream_tokens]
    mov rdx, [stream_token_count]
    call print_field
    lea rcx, [label_breakdown_detailed]
    mov edx, ASSP_BREAKDOWN_DETAILED
    call print_token_breakdown
    lea rcx, [label_sn_detailed_breakdown]
    mov edx, ASSP_BREAKDOWN_DETAILED
    call print_token_breakdown
    lea rcx, [label_breakdown_partial]
    mov edx, ASSP_BREAKDOWN_PARTIAL
    call print_token_breakdown
    lea rcx, [label_sn_partial_breakdown]
    mov edx, ASSP_BREAKDOWN_PARTIAL
    call print_token_breakdown
    lea rcx, [label_breakdown_simplified]
    mov edx, ASSP_BREAKDOWN_SIMPLIFIED
    call print_token_breakdown
    lea rcx, [label_sn_simple_breakdown]
    mov edx, ASSP_BREAKDOWN_SIMPLIFIED
    call print_token_breakdown
    lea rcx, [label_stream_breakdown_detailed]
    mov edx, ASSP_STREAM_BREAKDOWN_DETAILED
    call print_segment_breakdown
    lea rcx, [label_detailed_breakdown]
    mov edx, ASSP_STREAM_BREAKDOWN_DETAILED
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_partial]
    mov edx, ASSP_STREAM_BREAKDOWN_PARTIAL
    call print_segment_breakdown
    lea rcx, [label_partial_breakdown]
    mov edx, ASSP_STREAM_BREAKDOWN_PARTIAL
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_simple]
    mov edx, ASSP_STREAM_BREAKDOWN_SIMPLE
    call print_segment_breakdown
    lea rcx, [label_simple_breakdown]
    mov edx, ASSP_STREAM_BREAKDOWN_SIMPLE
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_total]
    mov edx, ASSP_STREAM_BREAKDOWN_TOTAL
    call print_segment_breakdown
    lea rcx, [label_rows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_ROWS]
    call print_field
    lea rcx, [label_total_steps]
    mov rdx, [note_stats + ASSP_NOTE_STATS_STEPS]
    call print_field
    lea rcx, [label_steps]
    mov rdx, [note_stats + ASSP_NOTE_STATS_STEPS]
    call print_field
    lea rcx, [label_total_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_ARROWS]
    call print_field
    lea rcx, [label_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_ARROWS]
    call print_field
    lea rcx, [label_jumps]
    mov rdx, [note_stats + ASSP_NOTE_STATS_JUMPS]
    call print_field
    lea rcx, [label_hands]
    mov rdx, [note_stats + ASSP_NOTE_STATS_HANDS]
    call print_field
    lea rcx, [label_holds]
    mov rdx, [note_stats + ASSP_NOTE_STATS_HOLDS]
    call print_field
    lea rcx, [label_rolls]
    mov rdx, [note_stats + ASSP_NOTE_STATS_ROLLS]
    call print_field
    lea rcx, [label_mines]
    mov rdx, [note_stats + ASSP_NOTE_STATS_MINES]
    call print_field
    lea rcx, [label_mines_nonfake]
    mov rdx, [mines_nonfake]
    call print_field
    lea rcx, [label_lifts]
    mov rdx, [note_stats + ASSP_NOTE_STATS_LIFTS]
    call print_field
    lea rcx, [label_fakes]
    mov rdx, [note_stats + ASSP_NOTE_STATS_FAKES]
    call print_field
    lea rcx, [label_timing_fakes]
    mov rdx, [timing_fakes]
    call print_field
    lea rcx, [label_left]
    mov rdx, [note_stats + ASSP_NOTE_STATS_LEFT]
    call print_field
    lea rcx, [label_left_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_LEFT]
    call print_field
    lea rcx, [label_down]
    mov rdx, [note_stats + ASSP_NOTE_STATS_DOWN]
    call print_field
    lea rcx, [label_down_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_DOWN]
    call print_field
    lea rcx, [label_up]
    mov rdx, [note_stats + ASSP_NOTE_STATS_UP]
    call print_field
    lea rcx, [label_up_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_UP]
    call print_field
    lea rcx, [label_right]
    mov rdx, [note_stats + ASSP_NOTE_STATS_RIGHT]
    call print_field
    lea rcx, [label_right_arrows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_RIGHT]
    call print_field
    lea rcx, [label_bad_rows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_MALFORMED_ROWS]
    call print_field

    add rsp, 40
    ret

print_chart_line:
    sub rsp, 40
    lea rcx, [label_chart]
    call print_z
    mov rcx, [chart_info + ASSP_CHART_INFO_INDEX]
    call print_u64
    lea rcx, [space]
    call print_z
    mov rcx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call print_raw
    lea rcx, [space]
    call print_z
    mov rcx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_LEN]
    call print_raw
    lea rcx, [space]
    call print_z
    mov rcx, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_METER_LEN]
    call print_raw
    lea rcx, [space]
    call print_z
    mov rcx, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    call print_raw
    lea rcx, [newline]
    call print_z
    add rsp, 40
    ret

print_json_root_start:
    sub rsp, 40

    json_z json_root_open
    lea rcx, [json_key_title]
    mov rdx, [title_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [title_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_subtitle]
    mov rdx, [subtitle_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [subtitle_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_artist]
    mov rdx, [artist_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [artist_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_title_trans]
    mov rdx, [title_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [title_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_subtitle_trans]
    mov rdx, [subtitle_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [subtitle_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_artist_trans]
    mov rdx, [artist_trans_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [artist_trans_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_unescaped_string_field
    lea rcx, [json_key_length]
    call print_z
    call print_json_duration_string
    lea rcx, [json_key_bpm]
    call print_z
    mov rcx, [min_bpm]
    mov rdx, [max_bpm]
    call print_json_bpm_value
    lea rcx, [json_key_min_bpm]
    mov rdx, [min_bpm]
    call print_json_u64_field
    lea rcx, [json_key_max_bpm]
    mov rdx, [max_bpm]
    call print_json_u64_field
    lea rcx, [json_key_average_bpm]
    mov rdx, [average_bpm_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_median_bpm]
    mov rdx, [median_bpm_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_bpm_data]
    lea rdx, [global_bpm_buffer]
    mov r8, [global_bpms_len]
    call print_json_string_field
    lea rcx, [json_key_offset]
    mov rdx, [offset_ms]
    call print_json_fixed3_field
    json_z json_key_charts

    add rsp, 40
    ret

print_json_string_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    call print_z
    mov rdx, [rsp + 32]
    mov r8, [rsp + 40]
    call print_json_slice_value
    add rsp, 72
    ret

print_json_unescaped_string_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    call print_z
    mov rdx, [rsp + 32]
    mov r8, [rsp + 40]
    call print_json_unescaped_slice_value
    add rsp, 72
    ret

print_json_u64_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_u64
    add rsp, 56
    ret

print_json_u32_field:
    sub rsp, 56
    mov [rsp + 32], edx
    call print_z
    mov ecx, [rsp + 32]
    call print_u64
    add rsp, 56
    ret

print_json_fixed2_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_fixed2_inline
    add rsp, 56
    ret

print_json_fixed3_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_fixed3_inline
    add rsp, 56
    ret

print_json_nps_max_field:
    sub rsp, 72
    call print_z

    xorpd xmm0, xmm0
    xor r8d, r8d
    lea r9, [nps_raw_buffer]

.loop:
    cmp r8, [nps_count]
    jae .print
    movsd xmm1, [r9 + r8 * 8]
    ucomisd xmm1, xmm0
    jbe .next
    movapd xmm0, xmm1
.next:
    inc r8
    jmp .loop

.print:
    call print_f64_sig6_inline
    add rsp, 72
    ret

print_json_slice_value:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z quote

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_string
    mov r10, [rsp + 32]
    movzx eax, byte [r10 + rax]
    call print_json_byte
    inc qword [rsp + 48]
    jmp .loop

.done_string:
    json_z quote
    add rsp, 88
    ret

print_json_unescaped_slice_value:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z quote

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_string
    mov r10, [rsp + 32]
    cmp byte [r10 + rax], '\'
    jne .current
    inc qword [rsp + 48]
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_string
    mov r10, [rsp + 32]

.current:
    movzx eax, byte [r10 + rax]
    call print_json_byte
    inc qword [rsp + 48]
    jmp .loop

.done_string:
    json_z quote
    add rsp, 88
    ret

print_json_byte:
    sub rsp, 56
    mov [rsp + 32], al
    cmp al, '"'
    je .quote
    cmp al, '\'
    je .slash
    cmp al, 10
    je .line_feed
    cmp al, 13
    je .carriage_return
    cmp al, 9
    je .tab
    cmp al, 8
    je .backspace
    cmp al, 12
    je .form_feed
    cmp al, 20h
    jb .unicode
    lea rcx, [rsp + 32]
    mov edx, 1
    call print_raw
    jmp .done

.quote:
    json_z json_escape_quote
    jmp .done
.slash:
    json_z json_escape_slash
    jmp .done
.line_feed:
    json_z json_escape_lf
    jmp .done
.carriage_return:
    json_z json_escape_cr
    jmp .done
.tab:
    json_z json_escape_tab
    jmp .done
.backspace:
    json_z json_escape_bs
    jmp .done
.form_feed:
    json_z json_escape_ff
    jmp .done
.unicode:
    json_z json_escape_u00
    movzx eax, byte [rsp + 32]
    shr al, 4
    lea r10, [hex_digits]
    mov al, [r10 + rax]
    mov [rsp + 40], al
    lea rcx, [rsp + 40]
    mov edx, 1
    call print_raw
    movzx eax, byte [rsp + 32]
    and al, 0fh
    lea r10, [hex_digits]
    mov al, [r10 + rax]
    mov [rsp + 40], al
    lea rcx, [rsp + 40]
    mov edx, 1
    call print_raw

.done:
    add rsp, 56
    ret

print_json_duration_string:
    sub rsp, 56
    json_z quote
    mov rax, [duration_ms]
    xor edx, edx
    mov r9d, 1000
    div r9
    mov rcx, rax
    call print_u64
    json_z quote
    add rsp, 56
    ret

print_json_bpm_value:
    sub rsp, 56
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    cmp rcx, rdx
    jne .range
    call print_u64
    jmp .done

.range:
    json_z quote
    mov rcx, [rsp + 32]
    call print_u64
    json_z minus
    mov rcx, [rsp + 40]
    call print_u64
    json_z quote

.done:
    add rsp, 56
    ret

print_json_display_bpm_value:
    sub rsp, 56
    json_z quote
    mov rcx, [display_text_min_bpm]
    call print_u64
    cmp qword [display_bpm_range_flag], 0
    je .close
    json_z json_space_dash_space
    mov rcx, [display_text_max_bpm]
    call print_u64
.close:
    json_z quote
    add rsp, 56
    ret

print_fixed2_inline:
    sub rsp, 72
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    json_z minus
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 100
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    json_z dot
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    json_z zero_digit

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    add rsp, 72
    ret

print_fixed3_inline:
    sub rsp, 72
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    json_z minus
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    json_z dot
    mov rax, [rsp + 40]
    cmp rax, 100
    jae .fraction
    json_z zero_digit
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    json_z zero_digit

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    add rsp, 72
    ret

print_f64_sig6_inline:
    sub rsp, 72

    xorpd xmm1, xmm1
    ucomisd xmm0, xmm1
    jp .zero
    je .zero
    jb .zero

    mov edx, 6
    mov ecx, 1000000
    ucomisd xmm0, [rel app_const_1_f64]
    jb .scale_ready
    mov edx, 5
    mov ecx, 100000
    ucomisd xmm0, [rel app_const_10_f64]
    jb .scale_ready
    mov edx, 4
    mov ecx, 10000
    ucomisd xmm0, [rel app_const_100_f64]
    jb .scale_ready
    mov edx, 3
    mov ecx, 1000
    ucomisd xmm0, [rel app_const_1000_f64]
    jb .scale_ready
    mov edx, 2
    mov ecx, 100
    ucomisd xmm0, [rel app_const_10000_f64]
    jb .scale_ready
    mov edx, 1
    mov ecx, 10
    ucomisd xmm0, [rel app_const_100000_f64]
    jb .scale_ready
    xor edx, edx
    mov ecx, 1

.scale_ready:
    mov [rsp + 32], rdx
    cvtsi2sd xmm1, rcx
    mulsd xmm0, xmm1
    cvtsd2si rcx, xmm0
    mov rdx, [rsp + 32]
    call print_scaled_inline
    jmp .done

.zero:
    xor ecx, ecx
    mov edx, 1
    call print_scaled_inline

.done:
    add rsp, 72
    ret

print_scaled_inline:
    sub rsp, 104
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    json_z minus

.positive:
    mov qword [rsp + 48], 1
    mov r10, [rsp + 40]

.divisor_loop:
    test r10, r10
    jz .divisor_ready
    mov rax, [rsp + 48]
    imul rax, rax, 10
    mov [rsp + 48], rax
    dec r10
    jmp .divisor_loop

.divisor_ready:
    mov rax, [rsp + 32]
    xor edx, edx
    mov r11, [rsp + 48]
    div r11
    mov [rsp + 56], rdx
    mov rcx, rax
    call print_u64

    cmp qword [rsp + 40], 0
    je .done
    json_z dot

    mov rax, [rsp + 48]
    xor edx, edx
    mov r11d, 10
    div r11
    mov [rsp + 64], rax
    mov r10, [rsp + 40]

.fraction_loop:
    test r10, r10
    jz .done
    mov [rsp + 72], r10
    mov rax, [rsp + 56]
    xor edx, edx
    mov r11, [rsp + 64]
    div r11
    mov [rsp + 56], rdx
    mov rcx, rax
    call print_u64
    mov rax, [rsp + 64]
    xor edx, edx
    mov r11d, 10
    div r11
    mov [rsp + 64], rax
    mov r10, [rsp + 72]
    dec r10
    jmp .fraction_loop

.done:
    add rsp, 104
    ret

print_json_u32_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .value
    json_z comma

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    mov ecx, [r10 + rax * 4]
    call print_u64
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_milli3_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .value
    json_z comma

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    mov ecx, [r10 + rax * 4]
    call print_milli3_inline
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_f64_sig6_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .value
    json_z comma

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    movsd xmm0, [r10 + rax * 8]
    call print_f64_sig6_inline
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_bool_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .value
    json_z comma

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    cmp byte [r10 + rax], 0
    je .false
    json_z true_text
    jmp .next
.false:
    json_z false_text
.next:
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_bpm_segments_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .segment
    json_z comma

.segment:
    mov r10, [rsp + 48]
    imul r10, ASSP_BPM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    json_z open_bracket
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    json_z comma
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_milli_bpm_itg6_inline
    json_z close_bracket
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_second_segments_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .segment
    json_z comma

.segment:
    mov r10, [rsp + 48]
    imul r10, ASSP_BPM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    json_z open_bracket
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    json_z comma
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_microseconds_f32_6_inline
    json_z close_bracket
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_row_segments_array:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .segment
    json_z comma

.segment:
    mov r10, [rsp + 48]
    imul r10, ASSP_BPM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    json_z open_bracket
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    json_z comma
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_milli_as_row48_f32_6_inline
    json_z close_bracket
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_bpm_segments_string:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z quote

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_string
    test rax, rax
    jz .segment
    json_z comma

.segment:
    mov r10, [rsp + 48]
    imul r10, ASSP_BPM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    json_z equals
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_milli_bpm_itg6_inline
    inc qword [rsp + 48]
    jmp .loop

.done_string:
    json_z quote
    add rsp, 88
    ret

print_json_stream_sequences:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    json_z open_bracket

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .done_array
    test rax, rax
    jz .sequence
    json_z comma

.sequence:
    mov r10, [rsp + 48]
    imul r10, ASSP_STREAM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    json_z stream_sequence_start_key
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_STREAM_SEGMENT_START]
    call print_u64
    json_z stream_sequence_end_key
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_STREAM_SEGMENT_END]
    call print_u64
    json_z stream_sequence_break_key
    mov r10, [rsp + 56]
    cmp qword [r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    je .false
    json_z true_text
    jmp .close
.false:
    json_z false_text
.close:
    json_z close_brace
    inc qword [rsp + 48]
    jmp .loop

.done_array:
    json_z close_bracket
    add rsp, 88
    ret

print_json_token_breakdown_field:
    sub rsp, 88
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx
    lea rcx, [stream_token_buffer]
    mov rdx, [stream_token_count]
    mov r8d, [rsp + 48]
    lea r9, [text_buffer]
    mov qword [rsp + 32], TEXT_BUFFER_CAP
    call assp_format_stream_tokens
    cmp rax, TEXT_BUFFER_CAP
    ja .too_long
    mov [rsp + 56], rax
    mov rcx, [rsp + 40]
    call print_z
    lea rdx, [text_buffer]
    mov r8, [rsp + 56]
    call print_json_slice_value
    jmp .done

.too_long:
    mov rcx, [rsp + 40]
    call print_z
    lea rdx, [msg_breakdown_too_long]
    mov r8d, msg_breakdown_too_long_end - msg_breakdown_too_long - 1
    call print_json_slice_value

.done:
    add rsp, 88
    ret

print_json_segment_breakdown_field:
    sub rsp, 88
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx
    lea rcx, [stream_segment_buffer]
    mov rdx, [stream_segment_count]
    mov r8d, [rsp + 48]
    lea r9, [text_buffer]
    mov qword [rsp + 32], TEXT_BUFFER_CAP
    call assp_format_stream_segments
    cmp rax, TEXT_BUFFER_CAP
    ja .too_long
    mov [rsp + 56], rax
    mov rcx, [rsp + 40]
    call print_z
    lea rdx, [text_buffer]
    mov r8, [rsp + 56]
    call print_json_slice_value
    jmp .done

.too_long:
    mov rcx, [rsp + 40]
    call print_z
    lea rdx, [msg_breakdown_too_long]
    mov r8d, msg_breakdown_too_long_end - msg_breakdown_too_long - 1
    call print_json_slice_value

.done:
    add rsp, 88
    ret

print_json_chart:
    sub rsp, 40

    json_z json_chart_open
    lea rcx, [json_key_step_type_first]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call print_json_string_field
    lea rcx, [json_key_difficulty]
    lea rdx, [difficulty_label_buffer]
    mov r8, [difficulty_label_len]
    call print_json_string_field
    lea rcx, [json_key_tier_bpm]
    mov rdx, [tier_bpm_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_rating]
    mov rdx, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_METER_LEN]
    call print_json_string_field
    lea rcx, [json_key_matrix_rating]
    mov rdx, [matrix_rating_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_step_artists]
    mov rdx, [step_artist_slice + ASSP_BYTE_SLICE_PTR]
    mov r8, [step_artist_slice + ASSP_BYTE_SLICE_LEN]
    call print_json_string_field
    lea rcx, [json_key_tech_notation]
    lea rdx, [tech_notation_buffer]
    mov r8, [tech_notation_len]
    call print_json_string_field
    lea rcx, [json_key_sha1]
    lea rdx, [hash_pair]
    mov r8d, 16
    call print_json_string_field
    lea rcx, [json_key_bpm_neutral_sha1]
    lea rdx, [hash_pair + 16]
    mov r8d, 16
    call print_json_string_field

    json_z json_chart_arrow_stats
    json_u64 json_key_total_arrows_first, [note_stats + ASSP_NOTE_STATS_ARROWS]
    json_u64 json_key_left_arrows, [note_stats + ASSP_NOTE_STATS_LEFT]
    json_u64 json_key_down_arrows, [note_stats + ASSP_NOTE_STATS_DOWN]
    json_u64 json_key_up_arrows, [note_stats + ASSP_NOTE_STATS_UP]
    json_u64 json_key_right_arrows, [note_stats + ASSP_NOTE_STATS_RIGHT]
    json_u64 json_key_total_steps, [note_stats + ASSP_NOTE_STATS_STEPS]
    json_u64 json_key_jumps, [note_stats + ASSP_NOTE_STATS_JUMPS]
    json_u64 json_key_hands, [note_stats + ASSP_NOTE_STATS_HANDS]
    json_u64 json_key_holds, [note_stats + ASSP_NOTE_STATS_HOLDS]
    json_u64 json_key_rolls, [note_stats + ASSP_NOTE_STATS_ROLLS]
    json_u64 json_key_mines, [note_stats + ASSP_NOTE_STATS_MINES]

    json_z json_chart_gimmicks
    json_u64 json_key_lifts_first, [note_stats + ASSP_NOTE_STATS_LIFTS]
    json_u64 json_key_fakes, [note_stats + ASSP_NOTE_STATS_FAKES]
    json_u64 json_key_stops_freezes, [stop_report_count]
    json_u64 json_key_speeds, [speed_report_count]
    json_u64 json_key_scrolls, [scroll_report_count]
    json_u64 json_key_delays, [delay_report_count]
    json_u64 json_key_warps, [warp_report_count]

    json_z json_chart_timing
    lea rcx, [json_key_beat0_offset_seconds_first]
    mov rdx, [offset_ms]
    call print_json_fixed3_field
    lea rcx, [json_key_beat0_group_offset_seconds]
    xor edx, edx
    call print_json_u64_field
    lea rcx, [json_key_hash_bpms]
    mov rdx, [hash_bpms_ptr]
    mov r8, [normalized_bpms_len]
    call print_json_string_field
    lea rcx, [json_key_bpms_formatted]
    call print_z
    lea rdx, [bpm_segment_buffer]
    mov r8, [bpm_segment_count]
    call print_json_bpm_segments_string
    lea rcx, [json_key_bpm_min]
    mov rdx, [raw_min_bpm_milli]
    call print_json_fixed3_field
    lea rcx, [json_key_bpm_max]
    mov rdx, [raw_max_bpm_milli]
    call print_json_fixed3_field
    json_z json_key_display_bpm
    call print_json_display_bpm_value
    lea rcx, [json_key_display_bpm_min]
    mov rdx, [display_min_bpm]
    call print_json_fixed3_field
    lea rcx, [json_key_display_bpm_max]
    mov rdx, [display_max_bpm]
    call print_json_fixed3_field
    json_z json_key_bpms
    lea rdx, [bpm_segment_buffer]
    mov r8, [bpm_segment_count]
    call print_json_bpm_segments_array
    json_z json_key_stops_array
    lea rdx, [stop_segment_buffer]
    mov r8, [stop_segment_count]
    call print_json_second_segments_array
    json_z json_key_delays_array
    lea rdx, [delay_segment_buffer]
    mov r8, [delay_segment_count]
    call print_json_second_segments_array
    json_z json_key_time_signatures
    json_z json_default_time_signatures
    json_z json_key_warps_array
    lea rdx, [warp_segment_buffer]
    mov r8, [warp_segment_count]
    call print_json_row_segments_array
    json_z json_key_labels
    json_z json_default_labels
    json_z json_key_tickcounts
    json_z json_default_tickcounts
    json_z json_key_combos
    json_z json_default_combos
    json_z json_key_speeds_array
    json_z json_default_speeds
    json_z json_key_scrolls_array
    json_z json_default_scrolls
    json_z json_key_fakes_array
    lea rdx, [fake_segment_buffer]
    mov r8, [fake_segment_count]
    call print_json_row_segments_array
    json_z json_key_duration_seconds
    movss xmm0, [duration_seconds_f32]
    call print_f32_dec6_inline

    json_z json_chart_stream_info
    lea rcx, [json_key_total_streams_first]
    mov rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN16]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN20]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN24]
    add rdx, [stream_counts + ASSP_STREAM_COUNTS_RUN32]
    call print_json_u64_field
    json_u64 json_key_16th_streams, [stream_counts + ASSP_STREAM_COUNTS_RUN16]
    json_u64 json_key_20th_streams, [stream_counts + ASSP_STREAM_COUNTS_RUN20]
    json_u64 json_key_24th_streams, [stream_counts + ASSP_STREAM_COUNTS_RUN24]
    json_u64 json_key_32nd_streams, [stream_counts + ASSP_STREAM_COUNTS_RUN32]
    json_u64 json_key_total_breaks, [stream_counts + ASSP_STREAM_COUNTS_TOTAL_BREAKS]
    json_u64 json_key_sn_breaks, [stream_counts + ASSP_STREAM_COUNTS_SN_BREAKS]
    lea rcx, [json_key_stream_percent]
    mov rdx, [stream_percent_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_adj_stream_percent]
    mov rdx, [adjusted_stream_percent_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_break_percent]
    mov rdx, [break_percent_centi]
    call print_json_fixed2_field
    json_z json_key_stream_sequences
    lea rdx, [stream_segment_buffer]
    mov r8, [stream_segment_count]
    call print_json_stream_sequences

    json_z json_chart_nps
    lea rcx, [json_key_max_nps_first]
    call print_json_nps_max_field
    lea rcx, [json_key_median_nps]
    mov rdx, [median_nps_centi]
    call print_json_fixed2_field
    json_z json_key_notes_per_measure
    lea rdx, [density_buffer]
    mov r8, [measure_count]
    call print_json_u32_array
    json_z json_key_nps_per_measure
    lea rdx, [nps_raw_buffer]
    mov r8, [nps_count]
    call print_json_f64_sig6_array
    json_z json_key_equally_spaced
    lea rdx, [equally_spaced_buffer]
    mov r8, [equally_spaced_count]
    call print_json_bool_array

    json_z json_chart_breakdown
    lea rcx, [json_key_sn_detailed_first]
    mov edx, ASSP_BREAKDOWN_DETAILED
    call print_json_token_breakdown_field
    lea rcx, [json_key_sn_partial]
    mov edx, ASSP_BREAKDOWN_PARTIAL
    call print_json_token_breakdown_field
    lea rcx, [json_key_sn_simple]
    mov edx, ASSP_BREAKDOWN_SIMPLIFIED
    call print_json_token_breakdown_field

    json_z json_chart_stream_breakdown
    lea rcx, [json_key_detailed_breakdown_first]
    mov edx, ASSP_STREAM_BREAKDOWN_DETAILED
    call print_json_segment_breakdown_field
    lea rcx, [json_key_partial_breakdown]
    mov edx, ASSP_STREAM_BREAKDOWN_PARTIAL
    call print_json_segment_breakdown_field
    lea rcx, [json_key_simple_breakdown]
    mov edx, ASSP_STREAM_BREAKDOWN_SIMPLE
    call print_json_segment_breakdown_field

    json_z json_chart_mono
    lea rcx, [json_key_total_candles_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_foot_candles, [default_pattern_counts + ASSP_PATTERN_CANDLE_LEFT * 4]
    json_u32 json_key_right_foot_candles, [default_pattern_counts + ASSP_PATTERN_CANDLE_RIGHT * 4]
    lea rcx, [json_key_candles_percent]
    mov rdx, [candle_percent_centi]
    call print_json_fixed2_field
    lea rcx, [json_key_total_mono]
    mov edx, [facing_counts + 0]
    add edx, [facing_counts + 4]
    call print_json_u32_field
    json_u32 json_key_left_face_mono, [facing_counts + 0]
    json_u32 json_key_right_face_mono, [facing_counts + 4]
    lea rcx, [json_key_mono_percent]
    mov rdx, [mono_percent_centi]
    call print_json_fixed2_field

    call print_json_pattern_counts

    json_z json_chart_tech_counts
    json_u32 json_key_crossovers_first, [tech_counts + ASSP_TECH_COUNTS_CROSSOVERS]
    json_u32 json_key_footswitches, [tech_counts + ASSP_TECH_COUNTS_FOOTSWITCHES]
    json_u32 json_key_up_footswitches, [tech_counts + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]
    json_u32 json_key_down_footswitches, [tech_counts + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    json_u32 json_key_sideswitches, [tech_counts + ASSP_TECH_COUNTS_SIDESWITCHES]
    json_u32 json_key_jacks, [tech_counts + ASSP_TECH_COUNTS_JACKS]
    json_u32 json_key_brackets, [tech_counts + ASSP_TECH_COUNTS_BRACKETS]
    json_u32 json_key_doublesteps, [tech_counts + ASSP_TECH_COUNTS_DOUBLESTEPS]
    json_z json_chart_close

    add rsp, 40
    ret

print_json_pattern_counts:
    sub rsp, 40

    json_z json_chart_pattern_counts
    lea rcx, [json_key_total_boxes_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_json_u32_field
    json_u32 json_key_lr_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_LR * 4]
    json_u32 json_key_ud_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_UD * 4]
    lea rcx, [json_key_corner_boxes]
    mov edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]
    call print_json_u32_field
    json_u32 json_key_ld_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LD * 4]
    json_u32 json_key_lu_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_LU * 4]
    json_u32 json_key_rd_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RD * 4]
    json_u32 json_key_ru_boxes, [default_pattern_counts + ASSP_PATTERN_BOX_CORNER_RU * 4]

    json_z json_pattern_anchors
    lea rcx, [json_key_total_anchors_first]
    mov edx, [anchor_counts + 0]
    add edx, [anchor_counts + 4]
    add edx, [anchor_counts + 8]
    add edx, [anchor_counts + 12]
    call print_json_u32_field
    json_u32 json_key_left_anchors, [anchor_counts + 0]
    json_u32 json_key_down_anchors, [anchor_counts + 4]
    json_u32 json_key_up_anchors, [anchor_counts + 8]
    json_u32 json_key_right_anchors, [anchor_counts + 12]

    json_z json_pattern_towers
    lea rcx, [json_key_total_towers_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_json_u32_field
    json_u32 json_key_lr_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_LR * 4]
    json_u32 json_key_ud_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_UD * 4]
    lea rcx, [json_key_corner_towers]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]
    call print_json_u32_field
    json_u32 json_key_ld_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LD * 4]
    json_u32 json_key_lu_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_LU * 4]
    json_u32 json_key_rd_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RD * 4]
    json_u32 json_key_ru_towers, [default_pattern_counts + ASSP_PATTERN_TOWER_CORNER_RU * 4]

    json_z json_pattern_triangles
    lea rcx, [json_key_total_triangles_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]
    call print_json_u32_field
    json_u32 json_key_ldl_triangles, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LDL * 4]
    json_u32 json_key_lul_triangles, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_LUL * 4]
    json_u32 json_key_rdr_triangles, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RDR * 4]
    json_u32 json_key_rur_triangles, [default_pattern_counts + ASSP_PATTERN_TRIANGLE_RUR * 4]

    json_z json_pattern_staircases
    lea rcx, [json_key_total_staircases_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_staircases, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_LEFT * 4]
    json_u32 json_key_right_staircases, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_RIGHT * 4]
    json_u32 json_key_left_inv_staircases, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_LEFT * 4]
    json_u32 json_key_right_inv_staircases, [default_pattern_counts + ASSP_PATTERN_STAIRCASE_INV_RIGHT * 4]
    lea rcx, [json_key_total_alt_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_alt_staircases, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_LEFT * 4]
    json_u32 json_key_right_alt_staircases, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_RIGHT * 4]
    json_u32 json_key_left_inv_alt_staircases, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_LEFT * 4]
    json_u32 json_key_right_inv_alt_staircases, [default_pattern_counts + ASSP_PATTERN_ALT_STAIRCASES_INV_RIGHT * 4]
    lea rcx, [json_key_total_double_staircases]
    mov edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_double_staircases, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_LEFT * 4]
    json_u32 json_key_right_double_staircases, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_RIGHT * 4]
    json_u32 json_key_left_inv_double_staircases, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_LEFT * 4]
    json_u32 json_key_right_inv_double_staircases, [default_pattern_counts + ASSP_PATTERN_D_STAIRCASE_INV_RIGHT * 4]

    json_z json_pattern_sweeps
    call print_json_quad_sweeps
    json_z json_pattern_candle_sweeps
    call print_json_quad_candle_sweeps
    json_z json_pattern_copters
    call print_json_quad_copters
    json_z json_pattern_spirals
    call print_json_quad_spirals
    json_z json_pattern_turbo_candles
    call print_json_quad_turbo_candles
    json_z json_pattern_hip_breakers
    call print_json_quad_hip_breakers
    json_z json_pattern_doritos
    call print_json_quad_doritos
    json_z json_pattern_luchis
    call print_json_quad_luchis
    json_z close_brace

    add rsp, 40
    ret

print_json_quad_sweeps:
    sub rsp, 40
    lea rcx, [json_key_total_sweeps_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_LEFT * 4]
    json_u32 json_key_right_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_RIGHT * 4]
    json_u32 json_key_left_inv_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_LEFT * 4]
    json_u32 json_key_right_inv_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_candle_sweeps:
    sub rsp, 40
    lea rcx, [json_key_total_candle_sweeps_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_candle_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_LEFT * 4]
    json_u32 json_key_right_candle_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_RIGHT * 4]
    json_u32 json_key_left_inv_candle_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_LEFT * 4]
    json_u32 json_key_right_inv_candle_sweeps, [default_pattern_counts + ASSP_PATTERN_SWEEP_CANDLE_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_copters:
    sub rsp, 40
    lea rcx, [json_key_total_copters_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_copters, [default_pattern_counts + ASSP_PATTERN_COPTER_LEFT * 4]
    json_u32 json_key_right_copters, [default_pattern_counts + ASSP_PATTERN_COPTER_RIGHT * 4]
    json_u32 json_key_left_inv_copters, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_LEFT * 4]
    json_u32 json_key_right_inv_copters, [default_pattern_counts + ASSP_PATTERN_COPTER_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_spirals:
    sub rsp, 40
    lea rcx, [json_key_total_spirals_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_spirals, [default_pattern_counts + ASSP_PATTERN_SPIRAL_LEFT * 4]
    json_u32 json_key_right_spirals, [default_pattern_counts + ASSP_PATTERN_SPIRAL_RIGHT * 4]
    json_u32 json_key_left_inv_spirals, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_LEFT * 4]
    json_u32 json_key_right_inv_spirals, [default_pattern_counts + ASSP_PATTERN_SPIRAL_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_turbo_candles:
    sub rsp, 40
    lea rcx, [json_key_total_turbo_candles_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_turbo_candles, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_LEFT * 4]
    json_u32 json_key_right_turbo_candles, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_RIGHT * 4]
    json_u32 json_key_left_inv_turbo_candles, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_LEFT * 4]
    json_u32 json_key_right_inv_turbo_candles, [default_pattern_counts + ASSP_PATTERN_TURBO_CANDLE_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_hip_breakers:
    sub rsp, 40
    lea rcx, [json_key_total_hip_breakers_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_hip_breakers, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_LEFT * 4]
    json_u32 json_key_right_hip_breakers, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_RIGHT * 4]
    json_u32 json_key_left_inv_hip_breakers, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_LEFT * 4]
    json_u32 json_key_right_inv_hip_breakers, [default_pattern_counts + ASSP_PATTERN_HIP_BREAKER_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_doritos:
    sub rsp, 40
    lea rcx, [json_key_total_doritos_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    call print_json_u32_field
    json_u32 json_key_left_doritos, [default_pattern_counts + ASSP_PATTERN_DORITO_LEFT * 4]
    json_u32 json_key_right_doritos, [default_pattern_counts + ASSP_PATTERN_DORITO_RIGHT * 4]
    json_u32 json_key_left_inv_doritos, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_LEFT * 4]
    json_u32 json_key_right_inv_doritos, [default_pattern_counts + ASSP_PATTERN_DORITO_INV_RIGHT * 4]
    add rsp, 40
    ret

print_json_quad_luchis:
    sub rsp, 40
    lea rcx, [json_key_total_luchis_first]
    mov edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    add edx, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    call print_json_u32_field
    json_u32 json_key_left_du_luchis, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_DU * 4]
    json_u32 json_key_left_ud_luchis, [default_pattern_counts + ASSP_PATTERN_LUCHI_LEFT_UD * 4]
    json_u32 json_key_right_du_luchis, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_DU * 4]
    json_u32 json_key_right_ud_luchis, [default_pattern_counts + ASSP_PATTERN_LUCHI_RIGHT_UD * 4]
    add rsp, 40
    ret

print_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_u64
    lea rcx, [newline]
    call print_z
    add rsp, 56
    ret

print_bpm_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    call print_z

    mov rcx, [rsp + 32]
    call print_u64
    mov rax, [rsp + 32]
    cmp rax, [rsp + 40]
    je .newline

    lea rcx, [minus]
    call print_z
    mov rcx, [rsp + 40]
    call print_u64

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_display_bpm_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov [rsp + 48], r9
    call print_z

    mov rcx, [rsp + 32]
    call print_u64
    cmp qword [rsp + 48], 0
    je .newline

    lea rcx, [space]
    call print_z
    lea rcx, [minus]
    call print_z
    lea rcx, [space]
    call print_z
    mov rcx, [rsp + 40]
    call print_u64

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_fixed2_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    call print_z

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 100
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    lea rcx, [zero_digit]
    call print_z

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_fixed3_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    call print_z

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 100
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    lea rcx, [zero_digit]
    call print_z

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_f32_field:
    sub rsp, 72
    movss [rsp + 32], xmm0
    call print_z
    movss xmm0, [rsp + 32]
    call print_f32_dec6_inline
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_duration_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    call print_z

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000
    div r9
    xor edx, edx
    mov r9d, 60
    div r9
    mov [rsp + 40], rdx

    mov rcx, rax
    call print_u64
    lea rcx, [minute_suffix]
    call print_z

    mov rax, [rsp + 40]
    cmp rax, 10
    jae .seconds
    lea rcx, [zero_digit]
    call print_z

.seconds:
    mov rcx, [rsp + 40]
    call print_u64
    lea rcx, [second_suffix]
    call print_z
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_selected_timing_tag:
    sub rsp, 72
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx

    lea r10, [global_timing_tags]
    cmp qword [chart_has_own_timing], 0
    je .selected
    lea r10, [chart_timing_tags]

.selected:
    add r10, [rsp + 40]
    mov rcx, [rsp + 32]
    mov rdx, [r10 + ASSP_BYTE_SLICE_PTR]
    mov r8, [r10 + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    add rsp, 72
    ret

print_selected_metadata_tag:
    sub rsp, 72
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    mov [rsp + 48], r8

    mov r10, [rsp + 48]
    cmp qword [chart_has_own_timing], 0
    je .selected
    mov r10, [rsp + 40]

.selected:
    mov rcx, [rsp + 32]
    mov rdx, [r10 + ASSP_BYTE_SLICE_PTR]
    mov r8, [r10 + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    add rsp, 72
    ret

print_chart_or_global_tag_by_ptr:
    sub rsp, 72
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    mov [rsp + 48], r8

    mov r10, [rsp + 40]
    cmp qword [r10 + ASSP_BYTE_SLICE_PTR], 0
    jne .selected
    mov r10, [rsp + 48]

.selected:
    mov rcx, [rsp + 32]
    mov rdx, [r10 + ASSP_BYTE_SLICE_PTR]
    mov r8, [r10 + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    add rsp, 72
    ret

print_chart_or_global_tag_by_len:
    sub rsp, 72
    mov [rsp + 32], rcx
    mov [rsp + 40], rdx
    mov [rsp + 48], r8

    mov r10, [rsp + 40]
    cmp qword [r10 + ASSP_BYTE_SLICE_LEN], 0
    jne .selected
    mov r10, [rsp + 48]

.selected:
    mov rcx, [rsp + 32]
    mov rdx, [r10 + ASSP_BYTE_SLICE_PTR]
    mov r8, [r10 + ASSP_BYTE_SLICE_LEN]
    call print_slice_field
    add rsp, 72
    ret

print_bpm_segments_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .segment
    lea rcx, [comma]
    call print_z

.segment:
    mov rax, [rsp + 48]
    imul rax, ASSP_BPM_SEGMENT_SIZE
    add rax, [rsp + 32]
    mov [rsp + 56], rax
    mov rcx, [rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    lea rcx, [equals]
    call print_z
    mov rax, [rsp + 56]
    mov rcx, [rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_milli_bpm_itg6_inline
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_bpm_micro_segments_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .segment
    lea rcx, [comma]
    call print_z

.segment:
    mov rax, [rsp + 48]
    imul rax, ASSP_BPM_SEGMENT_SIZE
    add rax, [rsp + 32]
    mov [rsp + 56], rax
    mov rcx, [rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    lea rcx, [equals]
    call print_z
    mov rax, [rsp + 56]
    mov rcx, [rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_micro_bpm_itg6_inline
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_second_segments_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .segment
    lea rcx, [comma]
    call print_z

.segment:
    mov rax, [rsp + 48]
    imul rax, ASSP_BPM_SEGMENT_SIZE
    add rax, [rsp + 32]
    mov [rsp + 56], rax
    mov rcx, [rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    lea rcx, [equals]
    call print_z
    mov rax, [rsp + 56]
    mov rcx, [rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_microseconds_f32_6_inline
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_row_segments_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .segment
    lea rcx, [comma]
    call print_z

.segment:
    mov rax, [rsp + 48]
    imul rax, ASSP_BPM_SEGMENT_SIZE
    add rax, [rsp + 32]
    mov [rsp + 56], rax
    mov rcx, [rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call print_milli_as_row48_f32_6_inline
    lea rcx, [equals]
    call print_z
    mov rax, [rsp + 56]
    mov rcx, [rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    call print_milli_as_row48_f32_6_inline
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_u32_array_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .value
    lea rcx, [comma]
    call print_z

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    mov ecx, [r10 + rax * 4]
    call print_u64
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_milli3_array_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .value
    lea rcx, [comma]
    call print_z

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    mov ecx, [r10 + rax * 4]
    call print_milli3_inline
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_bool_array_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .value
    lea rcx, [comma]
    call print_z

.value:
    mov rax, [rsp + 48]
    mov r10, [rsp + 32]
    cmp byte [r10 + rax], 0
    je .false
    lea rcx, [true_text]
    jmp .print
.false:
    lea rcx, [false_text]
.print:
    call print_z
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_stream_sequences_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z
    lea rcx, [open_bracket]
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    test rax, rax
    jz .sequence
    lea rcx, [comma]
    call print_z

.sequence:
    mov r10, [rsp + 48]
    imul r10, ASSP_STREAM_SEGMENT_SIZE
    add r10, [rsp + 32]
    mov [rsp + 56], r10
    lea rcx, [stream_sequence_start_key]
    call print_z
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_STREAM_SEGMENT_START]
    call print_u64
    lea rcx, [stream_sequence_end_key]
    call print_z
    mov r10, [rsp + 56]
    mov rcx, [r10 + ASSP_STREAM_SEGMENT_END]
    call print_u64
    lea rcx, [stream_sequence_break_key]
    call print_z
    mov r10, [rsp + 56]
    cmp qword [r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    je .false
    lea rcx, [true_text]
    jmp .print_kind
.false:
    lea rcx, [false_text]
.print_kind:
    call print_z
    lea rcx, [close_brace]
    call print_z
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [close_bracket]
    call print_z
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_milli6_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_milli6_inline
    lea rcx, [newline]
    call print_z
    add rsp, 56
    ret

print_milli6_inline:
    sub rsp, 72
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 100
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    lea rcx, [zero_digit]
    call print_z

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    lea rcx, [milli_to_six_tail]
    call print_z
    add rsp, 72
    ret

print_milli_as_row48_6_inline:
    sub rsp, 72
    call milli_to_row48
    mov rcx, rax
    call print_row48_6_inline
    add rsp, 72
    ret

print_milli_as_row48_f32_6_inline:
    sub rsp, 72
    call milli_to_row48
    cvtsi2ss xmm0, rax
    divss xmm0, [rel app_const_48_f32]
    call print_f32_dec6_inline
    add rsp, 72
    ret

print_milli_bpm_itg6_inline:
    sub rsp, 72
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel app_const_thousand_f32]
    divss xmm0, [rel app_const_60_f32]
    mulss xmm0, [rel app_const_60_f32]
    call print_f32_dec6_inline
    add rsp, 72
    ret

print_micro_bpm_itg6_inline:
    sub rsp, 72
    cvtsi2sd xmm0, rcx
    divsd xmm0, [rel app_const_million_f64]
    cvtsd2ss xmm0, xmm0
    divss xmm0, [rel app_const_60_f32]
    mulss xmm0, [rel app_const_60_f32]
    call print_f32_dec6_inline
    add rsp, 72
    ret

print_microseconds_f32_6_inline:
    sub rsp, 72
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel app_const_million_f32]
    call print_f32_dec6_inline
    add rsp, 72
    ret

print_f32_dec6_inline:
    sub rsp, 56
    cvtss2sd xmm0, xmm0
    mulsd xmm0, [rel app_const_million_f64]
    cvtsd2si rcx, xmm0
    call print_fixed6_scaled_inline
    add rsp, 56
    ret

print_fixed6_scaled_inline:
    sub rsp, 72
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000000
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rcx, [rsp + 40]
    call print_fraction6_inline
    add rsp, 72
    ret

milli_to_row48:
    mov rax, rcx
    test rax, rax
    jge .positive
    neg rax
    imul rax, 48
    add rax, 500
    xor edx, edx
    mov r9d, 1000
    div r9
    neg rax
    ret

.positive:
    imul rax, 48
    add rax, 500
    xor edx, edx
    mov r9d, 1000
    div r9
    ret

print_row48_6_inline:
    sub rsp, 88
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 48
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rax, [rsp + 40]
    imul rax, 1000000
    add rax, 24
    xor edx, edx
    mov r9d, 48
    div r9
    mov rcx, rax
    call print_fraction6_inline
    add rsp, 88
    ret

print_fraction6_inline:
    sub rsp, 72
    mov [rsp + 32], rcx
    mov rax, [rsp + 32]
    cmp rax, 100000
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 32]
    cmp rax, 10000
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 32]
    cmp rax, 1000
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 32]
    cmp rax, 100
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 32]
    cmp rax, 10
    jae .fraction
    lea rcx, [zero_digit]
    call print_z

.fraction:
    mov rcx, [rsp + 32]
    call print_u64
    add rsp, 72
    ret

print_milli3_inline:
    sub rsp, 72
    mov [rsp + 32], rcx

    mov rax, [rsp + 32]
    test rax, rax
    jge .positive
    neg rax
    mov [rsp + 32], rax
    lea rcx, [minus]
    call print_z
    mov rax, [rsp + 32]

.positive:
    xor edx, edx
    mov r9d, 1000
    div r9
    mov [rsp + 40], rdx
    mov rcx, rax
    call print_u64
    lea rcx, [dot]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 100
    jae .fraction
    lea rcx, [zero_digit]
    call print_z
    mov rax, [rsp + 40]
    cmp rax, 10
    jae .fraction
    lea rcx, [zero_digit]
    call print_z

.fraction:
    mov rcx, [rsp + 40]
    call print_u64
    add rsp, 72
    ret

print_slice_field:
    sub rsp, 72
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    call print_z
    mov rcx, [rsp + 32]
    mov rdx, [rsp + 40]
    call print_raw
    lea rcx, [newline]
    call print_z
    add rsp, 72
    ret

print_unescaped_slice_field:
    sub rsp, 88
    mov [rsp + 32], rdx
    mov [rsp + 40], r8
    mov qword [rsp + 48], 0
    call print_z

.loop:
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .newline
    mov r10, [rsp + 32]
    add r10, rax
    cmp byte [r10], '\'
    jne .print_current
    inc qword [rsp + 48]
    mov rax, [rsp + 48]
    cmp rax, [rsp + 40]
    jae .print_current
    mov r10, [rsp + 32]
    add r10, rax

.print_current:
    mov [rsp + 56], r10
    mov rcx, r10
    mov edx, 1
    call print_raw
    inc qword [rsp + 48]
    jmp .loop

.newline:
    lea rcx, [newline]
    call print_z
    add rsp, 88
    ret

print_token_breakdown:
    sub rsp, 80
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx

    lea rcx, [stream_token_buffer]
    mov rdx, [stream_token_count]
    mov r8d, [rsp + 48]
    lea r9, [text_buffer]
    mov qword [rsp + 32], TEXT_BUFFER_CAP
    call assp_format_stream_tokens
    cmp rax, TEXT_BUFFER_CAP
    ja .too_long

    mov [rsp + 56], rax
    mov rcx, [rsp + 40]
    call print_z
    lea rcx, [text_buffer]
    mov rdx, [rsp + 56]
    call print_raw
    lea rcx, [newline]
    call print_z
    jmp .done

.too_long:
    lea rcx, [msg_breakdown_too_long]
    call print_z

.done:
    add rsp, 80
    ret

print_segment_breakdown:
    sub rsp, 80
    mov [rsp + 40], rcx
    mov [rsp + 48], rdx

    lea rcx, [stream_segment_buffer]
    mov rdx, [stream_segment_count]
    mov r8d, [rsp + 48]
    lea r9, [text_buffer]
    mov qword [rsp + 32], TEXT_BUFFER_CAP
    call assp_format_stream_segments
    cmp rax, TEXT_BUFFER_CAP
    ja .too_long

    mov [rsp + 56], rax
    mov rcx, [rsp + 40]
    call print_z
    lea rcx, [text_buffer]
    mov rdx, [rsp + 56]
    call print_raw
    lea rcx, [newline]
    call print_z
    jmp .done

.too_long:
    lea rcx, [msg_breakdown_too_long]
    call print_z

.done:
    add rsp, 80
    ret

print_u64:
    mov rax, rcx
    lea r10, [num_buffer + 32]
    xor r8d, r8d
    mov r9d, 10

    test rax, rax
    jnz .loop
    dec r10
    mov byte [r10], '0'
    mov r8d, 1
    jmp .emit

.loop:
    xor edx, edx
    div r9
    add dl, '0'
    dec r10
    mov [r10], dl
    inc r8
    test rax, rax
    jnz .loop

.emit:
    mov rcx, r10
    mov rdx, r8
    sub rsp, 40
    call print_raw
    add rsp, 40
    ret

print_z:
    mov r10, rcx
    xor edx, edx
.len:
    cmp byte [r10 + rdx], 0
    je .emit
    inc rdx
    jmp .len
.emit:
    sub rsp, 40
    call print_raw
    add rsp, 40
    ret

print_raw:
    test rdx, rdx
    jz .done
    cmp rdx, PRINT_BUFFER_CAP
    ja .large_write

    mov rax, [print_buffer_len]
    mov r10, rax
    add r10, rdx
    cmp r10, PRINT_BUFFER_CAP
    jbe .copy_to_buffer

    mov [print_raw_ptr], rcx
    mov [print_raw_len], rdx
    sub rsp, 40
    call print_flush
    add rsp, 40
    mov rcx, [print_raw_ptr]
    mov rdx, [print_raw_len]
    xor eax, eax
    mov r10, rdx

.copy_to_buffer:
    push rsi
    push rdi
    mov rsi, rcx
    lea rdi, [print_buffer]
    add rdi, rax
    mov rcx, rdx
    rep movsb
    pop rdi
    pop rsi
    mov [print_buffer_len], r10
    jmp .done

.large_write:
    mov [print_raw_ptr], rcx
    mov [print_raw_len], rdx
    sub rsp, 40
    call print_flush
    add rsp, 40
    mov rcx, [print_raw_ptr]
    mov rdx, [print_raw_len]
    call print_write_direct
.done:
    ret

print_flush:
    mov rdx, [print_buffer_len]
    test rdx, rdx
    jz .done
    lea rcx, [print_buffer]
    call print_write_direct
    mov qword [print_buffer_len], 0
.done:
    ret

print_write_direct:
%ifdef ASSP_PHASE_PROFILE
    cmp qword [profile_mode], 0
    je .write
    inc qword [profile_write_calls]
    add [profile_write_bytes], rdx
.write:
%endif
    sub rsp, 48
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [stdout_handle]
    lea r9, [stdout_written]
    mov qword [rsp + 32], 0
    call assp_os_write
    add rsp, 48
    ret

section .data

trace_app_start db "assp app: start", 10
trace_app_start_end:
trace_app_args db "assp app: args parsed", 10
trace_app_args_end:
trace_app_read db "assp app: read file", 10
trace_app_read_end:
trace_app_read_done db "assp app: read done", 10
trace_app_read_done_end:
trace_read_open db "assp read: open", 10
trace_read_open_end:
trace_read_open_done db "assp read: open done", 10
trace_read_open_done_end:
trace_read_size db "assp read: size", 10
trace_read_size_end:
trace_read_size_done db "assp read: size done", 10
trace_read_size_done_end:
trace_read_body db "assp read: body", 10
trace_read_body_end:
trace_read_body_done db "assp read: body done", 10
trace_read_body_done_end:
trace_read_fail db "assp read: fail", 10
trace_read_fail_end:
trace_app_hash db "assp app: md5", 10
trace_app_hash_end:
trace_app_hash_done db "assp app: md5 done", 10
trace_app_hash_done_end:
trace_app_single_chart db "assp app: single chart", 10
trace_app_single_chart_end:
trace_app_parity_prepared db "assp app: parity prepared", 10
trace_app_parity_prepared_end:
trace_app_parity_fast db "assp app: parity fast", 10
trace_app_parity_fast_end:
trace_app_parity_full db "assp app: parity full", 10
trace_app_parity_full_end:

app_const_thousand_f32 dd 1000.0
app_const_48_f32 dd 48.0
app_const_60_f32 dd 60.0
app_const_million_f32 dd 1000000.0
app_const_0_12_f64 dq 0.12
app_const_half_f64 dq 0.5
app_const_1_f64 dq 1.0
app_const_10_f64 dq 10.0
app_const_100_f64 dq 100.0
app_const_1000_f64 dq 1000.0
app_const_10000_f64 dq 10000.0
app_const_100000_f64 dq 100000.0
app_const_million_f64 dq 1000000.0
tag_title db "#TITLE:"
tag_title_end:
tag_subtitle db "#SUBTITLE:"
tag_subtitle_end:
tag_artist db "#ARTIST:"
tag_artist_end:
tag_genre db "#GENRE:"
tag_genre_end:
tag_title_trans db "#TITLETRANSLIT:"
tag_title_trans_end:
tag_subtitle_trans db "#SUBTITLETRANSLIT:"
tag_subtitle_trans_end:
tag_artist_trans db "#ARTISTTRANSLIT:"
tag_artist_trans_end:
tag_music db "#MUSIC:"
tag_music_end:
tag_attacks db "#ATTACKS:"
tag_attacks_end:
tag_banner db "#BANNER:"
tag_banner_end:
tag_background db "#BACKGROUND:"
tag_background_end:
tag_cdtitle db "#CDTITLE:"
tag_cdtitle_end:
tag_jacket db "#JACKET:"
tag_jacket_end:
tag_sample_start db "#SAMPLESTART:"
tag_sample_start_end:
tag_sample_length db "#SAMPLELENGTH:"
tag_sample_length_end:
tag_version db "#VERSION:"
tag_version_end:
tag_time_signatures db "#TIMESIGNATURES:"
tag_time_signatures_end:
tag_labels db "#LABELS:"
tag_labels_end:
tag_tickcounts db "#TICKCOUNTS:"
tag_tickcounts_end:
tag_combos db "#COMBOS:"
tag_combos_end:
tag_bpms db "#BPMS:"
tag_bpms_end:
tag_offset db "#OFFSET:"
tag_offset_end:
tag_chart_name db "#CHARTNAME:"
tag_chart_name_end:
tag_display_bpm db "#DISPLAYBPM:"
tag_display_bpm_end:
tag_credit db "#CREDIT:"
tag_credit_end:
msg_header db "assp standalone", 13, 10, 0
msg_usage db "Usage: assp <simfile_path> [chart_index|all|list|quiet|bench|profile]", 13, 10
          db "       assp <simfile_path> --json", 13, 10
          db "       assp --help", 13, 10
          db "Default: analyze every chart in the file.", 13, 10, 0
msg_read_fail db "failed to read input file", 13, 10, 0
msg_notes_fail db "failed to find selected #NOTES chart", 13, 10, 0
msg_lanes_fail db "unsupported step type; standalone currently supports dance-single and dance-double", 13, 10, 0
msg_stats_fail db "assembly note stat counter failed", 13, 10, 0
msg_density_fail db "chart has too many measures for the density buffer", 13, 10, 0
msg_hash_fail db "assembly hash pipeline failed", 13, 10, 0
msg_metadata_fail db "assembly metadata normalization failed", 13, 10, 0
msg_nps_fail db "assembly nps pipeline failed", 13, 10, 0
msg_duration_fail db "assembly duration pipeline failed", 13, 10, 0
msg_tech_fail db "assembly tech parser/analyzer failed", 13, 10, 0
msg_breakdown_too_long db "breakdown output exceeded text buffer", 13, 10, 0
msg_breakdown_too_long_end:
unknown_artist db "Unknown artist"
unknown_artist_end:
label_file db "file: ", 0
label_title db "title: ", 0
label_subtitle db "subtitle: ", 0
label_artist db "artist: ", 0
label_genre db "genre: ", 0
label_title_trans db "title_trans: ", 0
label_subtitle_trans db "subtitle_trans: ", 0
label_artist_trans db "artist_trans: ", 0
label_title_translated db "title_translated: ", 0
label_subtitle_translated db "subtitle_translated: ", 0
label_artist_translated db "artist_translated: ", 0
label_music db "music: ", 0
label_banner db "banner: ", 0
label_background db "background: ", 0
label_cdtitle db "cdtitle: ", 0
label_jacket db "jacket: ", 0
label_sample_start db "sample_start: ", 0
label_sample_length db "sample_length: ", 0
label_version db "version: ", 0
label_timing_format_sm db "timing_format_sm: ", 0
label_steps_timing_allowed db "steps_timing_allowed: ", 0
label_chart_name_tag_allowed db "chart_name_tag_allowed: ", 0
label_charts db "charts: ", 0
label_chart db "chart: ", 0
label_step_type db "step_type: ", 0
label_steps_type db "steps_type: ", 0
label_difficulty db "difficulty: ", 0
label_raw_difficulty db "raw_difficulty: ", 0
label_meter db "meter: ", 0
label_rating db "rating: ", 0
label_description db "description: ", 0
label_chart_name db "chart_name: ", 0
label_step_artist db "step_artist: ", 0
label_step_artists db "step_artists: ", 0
label_tech_notation db "tech_notation: ", 0
label_crossovers db "crossovers: ", 0
label_footswitches db "footswitches: ", 0
label_up_footswitches db "up_footswitches: ", 0
label_down_footswitches db "down_footswitches: ", 0
label_sideswitches db "sideswitches: ", 0
label_jacks db "jacks: ", 0
label_brackets db "brackets: ", 0
label_doublesteps db "doublesteps: ", 0
label_chart_music db "chart_music: ", 0
label_chart_attacks db "chart_attacks: ", 0
label_global_attacks db "global_attacks: ", 0
label_selected_attacks db "selected_attacks: ", 0
label_chart_time_signatures db "chart_time_signatures: ", 0
label_chart_labels db "chart_labels: ", 0
label_chart_tickcounts db "chart_tickcounts: ", 0
label_chart_combos db "chart_combos: ", 0
label_global_time_signatures db "global_time_signatures: ", 0
label_global_labels db "global_labels: ", 0
label_global_tickcounts db "global_tickcounts: ", 0
label_global_combos db "global_combos: ", 0
label_selected_time_signatures db "selected_time_signatures: ", 0
label_selected_labels db "selected_labels: ", 0
label_selected_tickcounts db "selected_tickcounts: ", 0
label_selected_combos db "selected_combos: ", 0
label_normalized_time_signatures db "normalized_time_signatures: ", 0
label_normalized_labels db "normalized_labels: ", 0
label_normalized_tickcounts db "normalized_tickcounts: ", 0
label_normalized_combos db "normalized_combos: ", 0
label_selected_normalized_time_signatures db "selected_normalized_time_signatures: ", 0
label_selected_normalized_labels db "selected_normalized_labels: ", 0
label_selected_normalized_tickcounts db "selected_normalized_tickcounts: ", 0
label_selected_normalized_combos db "selected_normalized_combos: ", 0
label_global_bpms db "global_bpms: ", 0
label_global_stops db "global_stops: ", 0
label_global_delays db "global_delays: ", 0
label_global_warps db "global_warps: ", 0
label_global_speeds db "global_speeds: ", 0
label_global_scrolls db "global_scrolls: ", 0
label_global_fakes db "global_fakes: ", 0
label_chart_bpms db "chart_bpms: ", 0
label_chart_stops db "chart_stops: ", 0
label_chart_delays db "chart_delays: ", 0
label_chart_warps db "chart_warps: ", 0
label_chart_speeds db "chart_speeds: ", 0
label_chart_scrolls db "chart_scrolls: ", 0
label_chart_fakes db "chart_fakes: ", 0
label_chart_display_bpm db "chart_display_bpm: ", 0
label_hash db "hash: ", 0
label_sha1 db "sha1: ", 0
label_sha1_hash db "sha1_hash: ", 0
label_bpm_neutral_hash db "bpm_neutral_hash: ", 0
label_bpm_neutral_sha1 db "bpm_neutral_sha1: ", 0
label_bpm_neutral_sha1_hash db "bpm_neutral_sha1_hash: ", 0
label_hash_bpms db "hash_bpms: ", 0
label_bpm_data db "bpm_data: ", 0
label_normalized_bpms db "normalized_bpms: ", 0
label_normalized_stops db "normalized_stops: ", 0
label_normalized_delays db "normalized_delays: ", 0
label_normalized_warps db "normalized_warps: ", 0
label_normalized_speeds db "normalized_speeds: ", 0
label_normalized_scrolls db "normalized_scrolls: ", 0
label_normalized_fakes db "normalized_fakes: ", 0
label_bpms_formatted db "bpms_formatted: ", 0
label_stops_formatted db "stops_formatted: ", 0
label_delays_formatted db "delays_formatted: ", 0
label_warps_formatted db "warps_formatted: ", 0
label_fakes_formatted db "fakes_formatted: ", 0
label_selected_bpms db "selected_bpms: ", 0
label_selected_stops db "selected_stops: ", 0
label_selected_delays db "selected_delays: ", 0
label_selected_warps db "selected_warps: ", 0
label_selected_fakes db "selected_fakes: ", 0
label_selected_speeds db "selected_speeds: ", 0
label_selected_scrolls db "selected_scrolls: ", 0
label_selected_normalized_bpms db "selected_normalized_bpms: ", 0
label_selected_normalized_stops db "selected_normalized_stops: ", 0
label_selected_normalized_delays db "selected_normalized_delays: ", 0
label_selected_normalized_warps db "selected_normalized_warps: ", 0
label_selected_normalized_fakes db "selected_normalized_fakes: ", 0
label_selected_normalized_speeds db "selected_normalized_speeds: ", 0
label_selected_normalized_scrolls db "selected_normalized_scrolls: ", 0
label_global_display_bpm db "global_display_bpm: ", 0
label_selected_display_bpm db "selected_display_bpm: ", 0
label_file_md5_hash db "file_md5_hash: ", 0
label_offset db "offset: ", 0
label_chart_offset_seconds db "chart_offset_seconds: ", 0
label_beat0_offset_seconds db "beat0_offset_seconds: ", 0
label_beat0_group_offset_seconds db "beat0_group_offset_seconds: ", 0
label_chart_has_own_timing db "chart_has_own_timing: ", 0
label_display_bpm db "display_bpm_tag: ", 0
label_bpm db "bpm: ", 0
label_display_bpm_resolved db "display_bpm: ", 0
label_min_bpm db "min_bpm: ", 0
label_max_bpm db "max_bpm: ", 0
label_display_bpm_min db "display_bpm_min: ", 0
label_display_bpm_max db "display_bpm_max: ", 0
label_average_bpm db "average_bpm: ", 0
label_median_bpm db "median_bpm: ", 0
label_measures db "measures: ", 0
label_equally_spaced_measures db "equally_spaced_measures: ", 0
label_notes_per_measure db "notes_per_measure: ", 0
label_nps_per_measure db "nps_per_measure: ", 0
label_equally_spaced_per_measure db "equally_spaced_per_measure: ", 0
label_candles db "candles: ", 0
label_candle_left db "candle_left: ", 0
label_candle_right db "candle_right: ", 0
label_candle_percent db "candle_percent: ", 0
label_total_candles db "total_candles: ", 0
label_left_foot_candles db "left_foot_candles: ", 0
label_right_foot_candles db "right_foot_candles: ", 0
label_candles_percent db "candles_percent: ", 0
label_boxes db "boxes: ", 0
label_box_lr db "box_lr: ", 0
label_box_ud db "box_ud: ", 0
label_box_corner db "box_corner: ", 0
label_box_ld db "box_ld: ", 0
label_box_lu db "box_lu: ", 0
label_box_rd db "box_rd: ", 0
label_box_ru db "box_ru: ", 0
label_total_boxes db "total_boxes: ", 0
label_lr_boxes db "lr_boxes: ", 0
label_ud_boxes db "ud_boxes: ", 0
label_corner_boxes db "corner_boxes: ", 0
label_ld_boxes db "ld_boxes: ", 0
label_lu_boxes db "lu_boxes: ", 0
label_rd_boxes db "rd_boxes: ", 0
label_ru_boxes db "ru_boxes: ", 0
label_towers db "towers: ", 0
label_tower_lr db "tower_lr: ", 0
label_tower_ud db "tower_ud: ", 0
label_tower_corner db "tower_corner: ", 0
label_tower_ld db "tower_ld: ", 0
label_tower_lu db "tower_lu: ", 0
label_tower_rd db "tower_rd: ", 0
label_tower_ru db "tower_ru: ", 0
label_triangles db "triangles: ", 0
label_triangle_ldl db "triangle_ldl: ", 0
label_triangle_lul db "triangle_lul: ", 0
label_triangle_rdr db "triangle_rdr: ", 0
label_triangle_rur db "triangle_rur: ", 0
label_staircases db "staircases: ", 0
label_staircase_left db "staircase_left: ", 0
label_staircase_right db "staircase_right: ", 0
label_staircase_inv_left db "staircase_inv_left: ", 0
label_staircase_inv_right db "staircase_inv_right: ", 0
label_alt_staircases db "alt_staircases: ", 0
label_alt_staircase_left db "alt_staircase_left: ", 0
label_alt_staircase_right db "alt_staircase_right: ", 0
label_alt_staircase_inv_left db "alt_staircase_inv_left: ", 0
label_alt_staircase_inv_right db "alt_staircase_inv_right: ", 0
label_double_staircases db "double_staircases: ", 0
label_double_staircase_left db "double_staircase_left: ", 0
label_double_staircase_right db "double_staircase_right: ", 0
label_double_staircase_inv_left db "double_staircase_inv_left: ", 0
label_double_staircase_inv_right db "double_staircase_inv_right: ", 0
label_sweeps db "sweeps: ", 0
label_sweep_left db "sweep_left: ", 0
label_sweep_right db "sweep_right: ", 0
label_sweep_inv_left db "sweep_inv_left: ", 0
label_sweep_inv_right db "sweep_inv_right: ", 0
label_candle_sweeps db "candle_sweeps: ", 0
label_candle_sweep_left db "candle_sweep_left: ", 0
label_candle_sweep_right db "candle_sweep_right: ", 0
label_candle_sweep_inv_left db "candle_sweep_inv_left: ", 0
label_candle_sweep_inv_right db "candle_sweep_inv_right: ", 0
label_copters db "copters: ", 0
label_copter_left db "copter_left: ", 0
label_copter_right db "copter_right: ", 0
label_copter_inv_left db "copter_inv_left: ", 0
label_copter_inv_right db "copter_inv_right: ", 0
label_spirals db "spirals: ", 0
label_spiral_left db "spiral_left: ", 0
label_spiral_right db "spiral_right: ", 0
label_spiral_inv_left db "spiral_inv_left: ", 0
label_spiral_inv_right db "spiral_inv_right: ", 0
label_turbo_candles db "turbo_candles: ", 0
label_turbo_candle_left db "turbo_candle_left: ", 0
label_turbo_candle_right db "turbo_candle_right: ", 0
label_turbo_candle_inv_left db "turbo_candle_inv_left: ", 0
label_turbo_candle_inv_right db "turbo_candle_inv_right: ", 0
label_hip_breakers db "hip_breakers: ", 0
label_hip_breaker_left db "hip_breaker_left: ", 0
label_hip_breaker_right db "hip_breaker_right: ", 0
label_hip_breaker_inv_left db "hip_breaker_inv_left: ", 0
label_hip_breaker_inv_right db "hip_breaker_inv_right: ", 0
label_doritos db "doritos: ", 0
label_dorito_left db "dorito_left: ", 0
label_dorito_right db "dorito_right: ", 0
label_dorito_inv_left db "dorito_inv_left: ", 0
label_dorito_inv_right db "dorito_inv_right: ", 0
label_luchis db "luchis: ", 0
label_luchi_left_du db "luchi_left_du: ", 0
label_luchi_left_ud db "luchi_left_ud: ", 0
label_luchi_right_du db "luchi_right_du: ", 0
label_luchi_right_ud db "luchi_right_ud: ", 0
label_total_towers db "total_towers: ", 0
label_lr_towers db "lr_towers: ", 0
label_ud_towers db "ud_towers: ", 0
label_corner_towers db "corner_towers: ", 0
label_ld_towers db "ld_towers: ", 0
label_lu_towers db "lu_towers: ", 0
label_rd_towers db "rd_towers: ", 0
label_ru_towers db "ru_towers: ", 0
label_total_triangles db "total_triangles: ", 0
label_ldl_triangles db "ldl_triangles: ", 0
label_lul_triangles db "lul_triangles: ", 0
label_rdr_triangles db "rdr_triangles: ", 0
label_rur_triangles db "rur_triangles: ", 0
label_total_staircases db "total_staircases: ", 0
label_left_staircases db "left_staircases: ", 0
label_right_staircases db "right_staircases: ", 0
label_left_inv_staircases db "left_inv_staircases: ", 0
label_right_inv_staircases db "right_inv_staircases: ", 0
label_total_alt_staircases db "total_alt_staircases: ", 0
label_left_alt_staircases db "left_alt_staircases: ", 0
label_right_alt_staircases db "right_alt_staircases: ", 0
label_left_inv_alt_staircases db "left_inv_alt_staircases: ", 0
label_right_inv_alt_staircases db "right_inv_alt_staircases: ", 0
label_total_double_staircases db "total_double_staircases: ", 0
label_left_double_staircases db "left_double_staircases: ", 0
label_right_double_staircases db "right_double_staircases: ", 0
label_left_inv_double_staircases db "left_inv_double_staircases: ", 0
label_right_inv_double_staircases db "right_inv_double_staircases: ", 0
label_total_sweeps db "total_sweeps: ", 0
label_left_sweeps db "left_sweeps: ", 0
label_right_sweeps db "right_sweeps: ", 0
label_left_inv_sweeps db "left_inv_sweeps: ", 0
label_right_inv_sweeps db "right_inv_sweeps: ", 0
label_total_candle_sweeps db "total_candle_sweeps: ", 0
label_left_candle_sweeps db "left_candle_sweeps: ", 0
label_right_candle_sweeps db "right_candle_sweeps: ", 0
label_left_inv_candle_sweeps db "left_inv_candle_sweeps: ", 0
label_right_inv_candle_sweeps db "right_inv_candle_sweeps: ", 0
label_total_copters db "total_copters: ", 0
label_left_copters db "left_copters: ", 0
label_right_copters db "right_copters: ", 0
label_left_inv_copters db "left_inv_copters: ", 0
label_right_inv_copters db "right_inv_copters: ", 0
label_total_spirals db "total_spirals: ", 0
label_left_spirals db "left_spirals: ", 0
label_right_spirals db "right_spirals: ", 0
label_left_inv_spirals db "left_inv_spirals: ", 0
label_right_inv_spirals db "right_inv_spirals: ", 0
label_total_turbo_candles db "total_turbo_candles: ", 0
label_left_turbo_candles db "left_turbo_candles: ", 0
label_right_turbo_candles db "right_turbo_candles: ", 0
label_left_inv_turbo_candles db "left_inv_turbo_candles: ", 0
label_right_inv_turbo_candles db "right_inv_turbo_candles: ", 0
label_total_hip_breakers db "total_hip_breakers: ", 0
label_left_hip_breakers db "left_hip_breakers: ", 0
label_right_hip_breakers db "right_hip_breakers: ", 0
label_left_inv_hip_breakers db "left_inv_hip_breakers: ", 0
label_right_inv_hip_breakers db "right_inv_hip_breakers: ", 0
label_total_doritos db "total_doritos: ", 0
label_left_doritos db "left_doritos: ", 0
label_right_doritos db "right_doritos: ", 0
label_left_inv_doritos db "left_inv_doritos: ", 0
label_right_inv_doritos db "right_inv_doritos: ", 0
label_total_luchis db "total_luchis: ", 0
label_left_du_luchis db "left_du_luchis: ", 0
label_left_ud_luchis db "left_ud_luchis: ", 0
label_right_du_luchis db "right_du_luchis: ", 0
label_right_ud_luchis db "right_ud_luchis: ", 0
label_anchors db "anchors: ", 0
label_anchor_left db "anchor_left: ", 0
label_anchor_down db "anchor_down: ", 0
label_anchor_up db "anchor_up: ", 0
label_anchor_right db "anchor_right: ", 0
label_total_anchors db "total_anchors: ", 0
label_left_anchors db "left_anchors: ", 0
label_down_anchors db "down_anchors: ", 0
label_up_anchors db "up_anchors: ", 0
label_right_anchors db "right_anchors: ", 0
label_mono_total db "mono_total: ", 0
label_facing_left db "facing_left: ", 0
label_facing_right db "facing_right: ", 0
label_mono_percent db "mono_percent: ", 0
label_total_mono db "total_mono: ", 0
label_left_face_mono db "left_face_mono: ", 0
label_right_face_mono db "right_face_mono: ", 0
label_max_nps db "max_nps: ", 0
label_peak_nps db "peak_nps: ", 0
label_peak_nps_milli db "peak_nps_milli: ", 0
label_median_nps db "median_nps: ", 0
label_tier_bpm db "tier_bpm: ", 0
label_matrix_rating db "matrix_rating: ", 0
label_last_beat_milli db "last_beat_milli: ", 0
label_duration_seconds db "duration_seconds: ", 0
label_duration_ms db "duration_ms: ", 0
label_length db "length: ", 0
label_stops db "stops: ", 0
label_stops_freezes db "stops_freezes: ", 0
label_delays db "delays: ", 0
label_warps db "warps: ", 0
label_speeds db "speeds: ", 0
label_scrolls db "scrolls: ", 0
label_total_streams db "total_streams: ", 0
label_stream16 db "16th_streams: ", 0
label_stream20 db "20th_streams: ", 0
label_stream24 db "24th_streams: ", 0
label_stream32 db "32nd_streams: ", 0
label_sn_breaks db "sn_breaks: ", 0
label_total_breaks db "total_breaks: ", 0
label_stream_percent db "stream_percent: ", 0
label_adjusted_stream_percent db "adj_stream_percent: ", 0
label_break_percent db "break_percent: ", 0
label_stream_segments db "stream_segments: ", 0
label_stream_sequences db "stream_sequences: ", 0
label_stream_tokens db "stream_tokens: ", 0
label_breakdown_detailed db "breakdown_detailed: ", 0
label_sn_detailed_breakdown db "sn_detailed_breakdown: ", 0
label_breakdown_partial db "breakdown_partial: ", 0
label_sn_partial_breakdown db "sn_partial_breakdown: ", 0
label_breakdown_simplified db "breakdown_simplified: ", 0
label_sn_simple_breakdown db "sn_simple_breakdown: ", 0
label_stream_breakdown_detailed db "stream_breakdown_detailed: ", 0
label_detailed_breakdown db "detailed_breakdown: ", 0
label_stream_breakdown_partial db "stream_breakdown_partial: ", 0
label_partial_breakdown db "partial_breakdown: ", 0
label_stream_breakdown_simple db "stream_breakdown_simple: ", 0
label_simple_breakdown db "simple_breakdown: ", 0
label_stream_breakdown_total db "stream_breakdown_total: ", 0
label_rows db "rows: ", 0
label_total_steps db "total_steps: ", 0
label_steps db "steps: ", 0
label_total_arrows db "total_arrows: ", 0
label_arrows db "arrows: ", 0
label_jumps db "jumps: ", 0
label_hands db "hands: ", 0
label_holds db "holds: ", 0
label_rolls db "rolls: ", 0
label_mines db "mines: ", 0
label_mines_nonfake db "mines_nonfake: ", 0
label_lifts db "lifts: ", 0
label_fakes db "fakes: ", 0
label_timing_fakes db "timing_fakes: ", 0
label_left db "left: ", 0
label_left_arrows db "left_arrows: ", 0
label_down db "down: ", 0
label_down_arrows db "down_arrows: ", 0
label_up db "up: ", 0
label_up_arrows db "up_arrows: ", 0
label_right db "right: ", 0
label_right_arrows db "right_arrows: ", 0
label_bad_rows db "malformed_rows: ", 0
label_profile_frequency db "profile_frequency: ", 0
label_profile_total db "profile_total_ticks: ", 0
label_profile_read_file db "profile_read_file_ticks: ", 0
label_profile_file_md5 db "profile_file_md5_ticks: ", 0
label_profile_find_chart db "profile_find_chart_ticks: ", 0
label_profile_lane db "profile_lane_ticks: ", 0
label_profile_global db "profile_global_ticks: ", 0
label_profile_chart_metadata db "profile_chart_metadata_ticks: ", 0
label_profile_tech_notation db "profile_tech_notation_ticks: ", 0
label_profile_hash db "profile_hash_ticks: ", 0
label_profile_timing db "profile_timing_ticks: ", 0
label_profile_note_stats db "profile_note_stats_ticks: ", 0
label_profile_tech_counts db "profile_tech_counts_ticks: ", 0
label_profile_density db "profile_density_ticks: ", 0
label_profile_selected_metadata db "profile_selected_metadata_ticks: ", 0
label_profile_bpm_range db "profile_bpm_range_ticks: ", 0
label_profile_mines_fakes db "profile_mines_fakes_ticks: ", 0
label_profile_nps db "profile_nps_ticks: ", 0
label_profile_patterns db "profile_patterns_ticks: ", 0
label_profile_streams db "profile_streams_ticks: ", 0
label_profile_print db "profile_print_ticks: ", 0
label_profile_write_calls db "profile_write_calls: ", 0
label_profile_write_bytes db "profile_write_bytes: ", 0
label_profile_step_row_times db "profile_step_row_times_ticks: ", 0
label_profile_step_hold_ends db "profile_step_hold_ends_ticks: ", 0
label_profile_step_prepare_rows db "profile_step_prepare_rows_ticks: ", 0
label_profile_step_dp_fast db "profile_step_dp_fast_ticks: ", 0
label_profile_step_dp_full db "profile_step_dp_full_ticks: ", 0
label_profile_step_fallback db "profile_step_fallback_ticks: ", 0
label_profile_step_dp_transition_cycles db "profile_step_dp_transition_cycles: ", 0
label_profile_step_dp_hash_cycles db "profile_step_dp_hash_cycles: ", 0
label_profile_step_dp_score_cycles db "profile_step_dp_score_cycles: ", 0
label_profile_step_dp_copy_cycles db "profile_step_dp_copy_cycles: ", 0
label_profile_step_dp_transition_count db "profile_step_dp_transition_count: ", 0
label_profile_step_dp_hash_probe_count db "profile_step_dp_hash_probe_count: ", 0
label_profile_step_dp_score_clean_count db "profile_step_dp_score_clean_count: ", 0
label_profile_step_dp_score_full_count db "profile_step_dp_score_full_count: ", 0
label_profile_step_dp_write_count db "profile_step_dp_write_count: ", 0
label_profile_step_dp_skip_count db "profile_step_dp_skip_count: ", 0
space db " ", 0
comma db ",", 0
equals db "=", 0
minus db "-", 0
colon db ":", 0
open_bracket db "[", 0
close_bracket db "]", 0
close_brace db "}", 0
stream_sequence_start_key db '{"stream_start":', 0
stream_sequence_end_key db ',"stream_end":', 0
stream_sequence_break_key db ',"is_break":', 0
dot db ".", 0
zero_digit db "0", 0
milli_to_six_tail db "000", 0
minute_suffix db "m ", 0
second_suffix db "s", 0
true_text db "true", 0
false_text db "false", 0
quote db '"', 0
json_root_open db "{", 0
json_root_end db "]}", 13, 10, 0
json_key_title db '"title":', 0
json_key_subtitle db ',"subtitle":', 0
json_key_artist db ',"artist":', 0
json_key_title_trans db ',"title_trans":', 0
json_key_subtitle_trans db ',"subtitle_trans":', 0
json_key_artist_trans db ',"artist_trans":', 0
json_key_length db ',"length":', 0
json_key_bpm db ',"bpm":', 0
json_key_min_bpm db ',"min_bpm":', 0
json_key_max_bpm db ',"max_bpm":', 0
json_key_average_bpm db ',"average_bpm":', 0
json_key_median_bpm db ',"median_bpm":', 0
json_key_bpm_data db ',"bpm_data":', 0
json_key_offset db ',"offset":', 0
json_key_charts db ',"charts":[', 0
json_escape_quote db '\"', 0
json_escape_slash db '\\', 0
json_escape_lf db '\n', 0
json_escape_cr db '\r', 0
json_escape_tab db '\t', 0
json_escape_bs db '\b', 0
json_escape_ff db '\f', 0
json_escape_u00 db '\u00', 0
json_space_dash_space db " - ", 0
hex_digits db "0123456789abcdef"
json_chart_open db '{"chart_info":{', 0
json_key_step_type_first db '"step_type":', 0
json_key_difficulty db ',"difficulty":', 0
json_key_tier_bpm db ',"tier_bpm":', 0
json_key_rating db ',"rating":', 0
json_key_matrix_rating db ',"matrix_rating":', 0
json_key_step_artists db ',"step_artists":', 0
json_key_tech_notation db ',"tech_notation":', 0
json_key_sha1 db ',"sha1":', 0
json_key_bpm_neutral_sha1 db ',"bpm_neutral_sha1":', 0
json_chart_arrow_stats db '},"arrow_stats":{', 0
json_key_total_arrows_first db '"total_arrows":', 0
json_key_left_arrows db ',"left_arrows":', 0
json_key_down_arrows db ',"down_arrows":', 0
json_key_up_arrows db ',"up_arrows":', 0
json_key_right_arrows db ',"right_arrows":', 0
json_key_total_steps db ',"total_steps":', 0
json_key_jumps db ',"jumps":', 0
json_key_hands db ',"hands":', 0
json_key_holds db ',"holds":', 0
json_key_rolls db ',"rolls":', 0
json_key_mines db ',"mines":', 0
json_chart_gimmicks db '},"gimmicks":{', 0
json_key_lifts_first db '"lifts":', 0
json_key_fakes db ',"fakes":', 0
json_key_stops_freezes db ',"stops_freezes":', 0
json_key_speeds db ',"speeds":', 0
json_key_scrolls db ',"scrolls":', 0
json_key_delays db ',"delays":', 0
json_key_warps db ',"warps":', 0
json_chart_timing db '},"timing":{', 0
json_key_beat0_offset_seconds_first db '"beat0_offset_seconds":', 0
json_key_beat0_group_offset_seconds db ',"beat0_group_offset_seconds":', 0
json_key_hash_bpms db ',"hash_bpms":', 0
json_key_bpms_formatted db ',"bpms_formatted":', 0
json_key_bpm_min db ',"bpm_min":', 0
json_key_bpm_max db ',"bpm_max":', 0
json_key_display_bpm db ',"display_bpm":', 0
json_key_display_bpm_min db ',"display_bpm_min":', 0
json_key_display_bpm_max db ',"display_bpm_max":', 0
json_key_bpms db ',"bpms":', 0
json_key_stops_array db ',"stops":', 0
json_key_delays_array db ',"delays":', 0
json_key_time_signatures db ',"time_signatures":', 0
json_default_time_signatures db '[[0,4,4]]', 0
json_key_warps_array db ',"warps":', 0
json_key_labels db ',"labels":', 0
json_default_labels db '[[0,"Song Start"]]', 0
json_key_tickcounts db ',"tickcounts":', 0
json_default_tickcounts db '[[0,4]]', 0
json_key_combos db ',"combos":', 0
json_default_combos db '[[0,1,1]]', 0
json_key_speeds_array db ',"speeds":', 0
json_default_speeds db '[[0,1,0,0]]', 0
json_key_scrolls_array db ',"scrolls":', 0
json_default_scrolls db '[[0,1]]', 0
json_key_fakes_array db ',"fakes":', 0
json_key_duration_seconds db ',"duration_seconds":', 0
json_chart_stream_info db '},"stream_info":{', 0
json_key_total_streams_first db '"total_streams":', 0
json_key_16th_streams db ',"16th_streams":', 0
json_key_20th_streams db ',"20th_streams":', 0
json_key_24th_streams db ',"24th_streams":', 0
json_key_32nd_streams db ',"32nd_streams":', 0
json_key_total_breaks db ',"total_breaks":', 0
json_key_sn_breaks db ',"sn_breaks":', 0
json_key_stream_percent db ',"stream_percent":', 0
json_key_adj_stream_percent db ',"adj_stream_percent":', 0
json_key_break_percent db ',"break_percent":', 0
json_key_stream_sequences db ',"stream_sequences":', 0
json_chart_nps db '},"nps":{', 0
json_key_max_nps_first db '"max_nps":', 0
json_key_median_nps db ',"median_nps":', 0
json_key_notes_per_measure db ',"notes_per_measure":', 0
json_key_nps_per_measure db ',"nps_per_measure":', 0
json_key_equally_spaced db ',"equally_spaced_per_measure":', 0
json_chart_breakdown db '},"breakdown":{', 0
json_key_sn_detailed_first db '"sn_detailed_breakdown":', 0
json_key_sn_partial db ',"sn_partial_breakdown":', 0
json_key_sn_simple db ',"sn_simple_breakdown":', 0
json_chart_stream_breakdown db '},"stream_breakdown":{', 0
json_key_detailed_breakdown_first db '"detailed_breakdown":', 0
json_key_partial_breakdown db ',"partial_breakdown":', 0
json_key_simple_breakdown db ',"simple_breakdown":', 0
json_chart_mono db '},"mono_candle_stats":{', 0
json_key_total_candles_first db '"total_candles":', 0
json_key_left_foot_candles db ',"left_foot_candles":', 0
json_key_right_foot_candles db ',"right_foot_candles":', 0
json_key_candles_percent db ',"candles_percent":', 0
json_key_total_mono db ',"total_mono":', 0
json_key_left_face_mono db ',"left_face_mono":', 0
json_key_right_face_mono db ',"right_face_mono":', 0
json_key_mono_percent db ',"mono_percent":', 0
json_chart_pattern_counts db '},"pattern_counts":{"boxes":{', 0
json_key_total_boxes_first db '"total_boxes":', 0
json_key_lr_boxes db ',"lr_boxes":', 0
json_key_ud_boxes db ',"ud_boxes":', 0
json_key_corner_boxes db ',"corner_boxes":', 0
json_key_ld_boxes db ',"ld_boxes":', 0
json_key_lu_boxes db ',"lu_boxes":', 0
json_key_rd_boxes db ',"rd_boxes":', 0
json_key_ru_boxes db ',"ru_boxes":', 0
json_pattern_anchors db '},"anchors":{', 0
json_key_total_anchors_first db '"total_anchors":', 0
json_key_left_anchors db ',"left_anchors":', 0
json_key_down_anchors db ',"down_anchors":', 0
json_key_up_anchors db ',"up_anchors":', 0
json_key_right_anchors db ',"right_anchors":', 0
json_pattern_towers db '},"towers":{', 0
json_key_total_towers_first db '"total_towers":', 0
json_key_lr_towers db ',"lr_towers":', 0
json_key_ud_towers db ',"ud_towers":', 0
json_key_corner_towers db ',"corner_towers":', 0
json_key_ld_towers db ',"ld_towers":', 0
json_key_lu_towers db ',"lu_towers":', 0
json_key_rd_towers db ',"rd_towers":', 0
json_key_ru_towers db ',"ru_towers":', 0
json_pattern_triangles db '},"triangles":{', 0
json_key_total_triangles_first db '"total_triangles":', 0
json_key_ldl_triangles db ',"ldl_triangles":', 0
json_key_lul_triangles db ',"lul_triangles":', 0
json_key_rdr_triangles db ',"rdr_triangles":', 0
json_key_rur_triangles db ',"rur_triangles":', 0
json_pattern_staircases db '},"staircases":{', 0
json_key_total_staircases_first db '"total_staircases":', 0
json_key_left_staircases db ',"left_staircases":', 0
json_key_right_staircases db ',"right_staircases":', 0
json_key_left_inv_staircases db ',"left_inv_staircases":', 0
json_key_right_inv_staircases db ',"right_inv_staircases":', 0
json_key_total_alt_staircases db ',"total_alt_staircases":', 0
json_key_left_alt_staircases db ',"left_alt_staircases":', 0
json_key_right_alt_staircases db ',"right_alt_staircases":', 0
json_key_left_inv_alt_staircases db ',"left_inv_alt_staircases":', 0
json_key_right_inv_alt_staircases db ',"right_inv_alt_staircases":', 0
json_key_total_double_staircases db ',"total_double_staircases":', 0
json_key_left_double_staircases db ',"left_double_staircases":', 0
json_key_right_double_staircases db ',"right_double_staircases":', 0
json_key_left_inv_double_staircases db ',"left_inv_double_staircases":', 0
json_key_right_inv_double_staircases db ',"right_inv_double_staircases":', 0
json_pattern_sweeps db '},"sweeps":{', 0
json_key_total_sweeps_first db '"total_sweeps":', 0
json_key_left_sweeps db ',"left_sweeps":', 0
json_key_right_sweeps db ',"right_sweeps":', 0
json_key_left_inv_sweeps db ',"left_inv_sweeps":', 0
json_key_right_inv_sweeps db ',"right_inv_sweeps":', 0
json_pattern_candle_sweeps db '},"candle_sweeps":{', 0
json_key_total_candle_sweeps_first db '"total_candle_sweeps":', 0
json_key_left_candle_sweeps db ',"left_candle_sweeps":', 0
json_key_right_candle_sweeps db ',"right_candle_sweeps":', 0
json_key_left_inv_candle_sweeps db ',"left_inv_candle_sweeps":', 0
json_key_right_inv_candle_sweeps db ',"right_inv_candle_sweeps":', 0
json_pattern_copters db '},"copters":{', 0
json_key_total_copters_first db '"total_copters":', 0
json_key_left_copters db ',"left_copters":', 0
json_key_right_copters db ',"right_copters":', 0
json_key_left_inv_copters db ',"left_inv_copters":', 0
json_key_right_inv_copters db ',"right_inv_copters":', 0
json_pattern_spirals db '},"spirals":{', 0
json_key_total_spirals_first db '"total_spirals":', 0
json_key_left_spirals db ',"left_spirals":', 0
json_key_right_spirals db ',"right_spirals":', 0
json_key_left_inv_spirals db ',"left_inv_spirals":', 0
json_key_right_inv_spirals db ',"right_inv_spirals":', 0
json_pattern_turbo_candles db '},"turbo_candles":{', 0
json_key_total_turbo_candles_first db '"total_turbo_candles":', 0
json_key_left_turbo_candles db ',"left_turbo_candles":', 0
json_key_right_turbo_candles db ',"right_turbo_candles":', 0
json_key_left_inv_turbo_candles db ',"left_inv_turbo_candles":', 0
json_key_right_inv_turbo_candles db ',"right_inv_turbo_candles":', 0
json_pattern_hip_breakers db '},"hip_breakers":{', 0
json_key_total_hip_breakers_first db '"total_hip_breakers":', 0
json_key_left_hip_breakers db ',"left_hip_breakers":', 0
json_key_right_hip_breakers db ',"right_hip_breakers":', 0
json_key_left_inv_hip_breakers db ',"left_inv_hip_breakers":', 0
json_key_right_inv_hip_breakers db ',"right_inv_hip_breakers":', 0
json_pattern_doritos db '},"doritos":{', 0
json_key_total_doritos_first db '"total_doritos":', 0
json_key_left_doritos db ',"left_doritos":', 0
json_key_right_doritos db ',"right_doritos":', 0
json_key_left_inv_doritos db ',"left_inv_doritos":', 0
json_key_right_inv_doritos db ',"right_inv_doritos":', 0
json_pattern_luchis db '},"luchis":{', 0
json_key_total_luchis_first db '"total_luchis":', 0
json_key_left_du_luchis db ',"left_du_luchis":', 0
json_key_left_ud_luchis db ',"left_ud_luchis":', 0
json_key_right_du_luchis db ',"right_du_luchis":', 0
json_key_right_ud_luchis db ',"right_ud_luchis":', 0
json_chart_tech_counts db '},"tech_counts":{', 0
json_key_crossovers_first db '"crossovers":', 0
json_key_footswitches db ',"footswitches":', 0
json_key_up_footswitches db ',"up_footswitches":', 0
json_key_down_footswitches db ',"down_footswitches":', 0
json_key_sideswitches db ',"sideswitches":', 0
json_key_jacks db ',"jacks":', 0
json_key_brackets db ',"brackets":', 0
json_key_doublesteps db ',"doublesteps":', 0
json_chart_close db '}}', 0
newline db 13, 10, 0

section .bss

stdout_handle resq 1
stdout_written resd 1
exit_code_tmp resd 1
input_path resq 1
chart_index resq 1
chart_lanes resq 1
list_mode resq 1
all_mode resq 1
quiet_mode resq 1
json_mode resq 1
profile_mode resq 1
usage_mode resq 1
globals_prepared resq 1
global_timing_prepared resq 1
chart_count resq 1
chart_cursor resq 1
measure_count resq 1
stream_segment_count resq 1
stream_token_count resq 1
equally_spaced_count resq 1
file_handle resq 1
file_size resq 1
file_len resq 1
file_bytes_read resd 1
print_buffer_len resq 1
print_raw_ptr resq 1
print_raw_len resq 1
profile_frequency resq 1
profile_total_start_tick resq 1
profile_start_tick resq 1
profile_qpc_tmp resq 1
profile_accum_ptr resq 1
profile_counters_begin:
profile_total_ticks resq 1
profile_read_file_ticks resq 1
profile_file_md5_ticks resq 1
profile_find_chart_ticks resq 1
profile_lane_ticks resq 1
profile_global_ticks resq 1
profile_chart_metadata_ticks resq 1
profile_tech_notation_ticks resq 1
profile_hash_ticks resq 1
profile_timing_ticks resq 1
profile_note_stats_ticks resq 1
profile_tech_counts_ticks resq 1
profile_density_ticks resq 1
profile_selected_metadata_ticks resq 1
profile_bpm_range_ticks resq 1
profile_mines_fakes_ticks resq 1
profile_nps_ticks resq 1
profile_patterns_ticks resq 1
profile_streams_ticks resq 1
profile_print_ticks resq 1
profile_write_calls resq 1
profile_write_bytes resq 1
profile_step_row_times_ticks resq 1
profile_step_hold_ends_ticks resq 1
profile_step_prepare_rows_ticks resq 1
profile_step_dp_fast_ticks resq 1
profile_step_dp_full_ticks resq 1
profile_step_fallback_ticks resq 1
profile_step_dp_transition_cycles resq 1
profile_step_dp_hash_cycles resq 1
profile_step_dp_score_cycles resq 1
profile_step_dp_copy_cycles resq 1
profile_step_dp_transition_count resq 1
profile_step_dp_hash_probe_count resq 1
profile_step_dp_score_clean_count resq 1
profile_step_dp_score_full_count resq 1
profile_step_dp_write_count resq 1
profile_step_dp_skip_count resq 1
profile_counters_end:
chart_info resb ASSP_CHART_INFO_SIZE
bpms_slice resb ASSP_BYTE_SLICE_SIZE
offset_slice resb ASSP_BYTE_SLICE_SIZE
global_offset_slice resb ASSP_BYTE_SLICE_SIZE
title_slice resb ASSP_BYTE_SLICE_SIZE
subtitle_slice resb ASSP_BYTE_SLICE_SIZE
artist_slice resb ASSP_BYTE_SLICE_SIZE
genre_slice resb ASSP_BYTE_SLICE_SIZE
title_trans_slice resb ASSP_BYTE_SLICE_SIZE
subtitle_trans_slice resb ASSP_BYTE_SLICE_SIZE
artist_trans_slice resb ASSP_BYTE_SLICE_SIZE
music_slice resb ASSP_BYTE_SLICE_SIZE
banner_slice resb ASSP_BYTE_SLICE_SIZE
background_slice resb ASSP_BYTE_SLICE_SIZE
cdtitle_slice resb ASSP_BYTE_SLICE_SIZE
jacket_slice resb ASSP_BYTE_SLICE_SIZE
sample_start_slice resb ASSP_BYTE_SLICE_SIZE
sample_length_slice resb ASSP_BYTE_SLICE_SIZE
version_slice resb ASSP_BYTE_SLICE_SIZE
global_attacks_slice resb ASSP_BYTE_SLICE_SIZE
global_display_bpm_slice resb ASSP_BYTE_SLICE_SIZE
global_time_signatures_slice resb ASSP_BYTE_SLICE_SIZE
global_labels_slice resb ASSP_BYTE_SLICE_SIZE
global_tickcounts_slice resb ASSP_BYTE_SLICE_SIZE
global_combos_slice resb ASSP_BYTE_SLICE_SIZE
chart_name_slice resb ASSP_BYTE_SLICE_SIZE
chart_music_slice resb ASSP_BYTE_SLICE_SIZE
chart_attacks_slice resb ASSP_BYTE_SLICE_SIZE
display_bpm_slice resb ASSP_BYTE_SLICE_SIZE
chart_time_signatures_slice resb ASSP_BYTE_SLICE_SIZE
chart_labels_slice resb ASSP_BYTE_SLICE_SIZE
chart_tickcounts_slice resb ASSP_BYTE_SLICE_SIZE
chart_combos_slice resb ASSP_BYTE_SLICE_SIZE
step_artist_slice resb ASSP_BYTE_SLICE_SIZE
global_timing_tags resb ASSP_TIMING_TAGS_SIZE
chart_timing_tags resb ASSP_TIMING_TAGS_SIZE
note_stats resb ASSP_NOTE_STATS_SIZE
tech_counts resb ASSP_TECH_COUNTS_SIZE
stream_counts resb ASSP_STREAM_COUNTS_SIZE
num_buffer resb 32
raw_total_steps resq 1
hash_bpms_ptr resq 1
normalized_bpms_len resq 1
global_bpms_len resq 1
normalized_time_signatures_len resq 1
normalized_labels_len resq 1
normalized_tickcounts_len resq 1
normalized_combos_len resq 1
selected_normalized_time_signatures_len resq 1
selected_normalized_labels_len resq 1
selected_normalized_tickcounts_len resq 1
selected_normalized_combos_len resq 1
normalized_stops_len resq 1
normalized_delays_len resq 1
normalized_warps_len resq 1
normalized_speeds_len resq 1
normalized_scrolls_len resq 1
normalized_fakes_len resq 1
selected_normalized_bpms_len resq 1
selected_normalized_stops_len resq 1
selected_normalized_delays_len resq 1
selected_normalized_warps_len resq 1
selected_normalized_fakes_len resq 1
selected_normalized_speeds_len resq 1
selected_normalized_scrolls_len resq 1
bpm_segment_count resq 1
bpm_report_count resq 1
stop_segment_count resq 1
delay_segment_count resq 1
warp_segment_count resq 1
warp_stats_segment_count resq 1
fake_segment_count resq 1
tech_notation_len resq 1
difficulty_label_len resq 1
stop_report_count resq 1
delay_report_count resq 1
warp_report_count resq 1
speed_report_count resq 1
scroll_report_count resq 1
minimized_chart_len resq 1
pattern_bitmask_count resq 1
parity_source_row_count resq 1
parity_prepared_row_count resq 1
nps_count resq 1
peak_nps_milli resq 1
max_nps_centi resq 1
median_nps_centi resq 1
tier_bpm_centi resq 1
matrix_rating_centi resq 1
equally_spaced_measures resq 1
candle_percent_centi resq 1
mono_percent_centi resq 1
stream_percent_centi resq 1
adjusted_stream_percent_centi resq 1
break_percent_centi resq 1
last_beat_milli resq 1
offset_ms resq 1
offset_us resq 1
min_bpm resq 1
max_bpm resq 1
raw_min_bpm_milli resq 1
raw_max_bpm_milli resq 1
display_min_bpm resq 1
display_max_bpm resq 1
display_text_min_bpm resq 1
display_text_max_bpm resq 1
display_bpm_range_flag resq 1
average_bpm_centi resq 1
median_bpm_centi resq 1
mines_nonfake resq 1
timing_fakes resq 1
chart_has_own_timing resq 1
timing_format_sm resq 1
timing_allow_steps resq 1
chart_name_tag_allowed resq 1
duration_ms resq 1
duration_seconds_f32 resd 1
file_md5_hash resb 32
hash_pair resb 32
tech_notation_buffer resb TECH_BUFFER_CAP
normalized_time_signatures_buffer resb METADATA_BUFFER_CAP
normalized_labels_buffer resb METADATA_BUFFER_CAP
normalized_tickcounts_buffer resb METADATA_BUFFER_CAP
normalized_combos_buffer resb METADATA_BUFFER_CAP
selected_normalized_time_signatures_buffer resb METADATA_BUFFER_CAP
selected_normalized_labels_buffer resb METADATA_BUFFER_CAP
selected_normalized_tickcounts_buffer resb METADATA_BUFFER_CAP
selected_normalized_combos_buffer resb METADATA_BUFFER_CAP
difficulty_label_buffer resb METADATA_BUFFER_CAP
bpm_buffer resb BPM_BUFFER_CAP
global_bpm_buffer resb BPM_BUFFER_CAP
normalized_stops_buffer resb BPM_BUFFER_CAP
normalized_delays_buffer resb BPM_BUFFER_CAP
normalized_warps_buffer resb BPM_BUFFER_CAP
normalized_speeds_buffer resb BPM_BUFFER_CAP
normalized_scrolls_buffer resb BPM_BUFFER_CAP
normalized_fakes_buffer resb BPM_BUFFER_CAP
selected_normalized_bpms_buffer resb BPM_BUFFER_CAP
selected_normalized_stops_buffer resb BPM_BUFFER_CAP
selected_normalized_delays_buffer resb BPM_BUFFER_CAP
selected_normalized_warps_buffer resb BPM_BUFFER_CAP
selected_normalized_fakes_buffer resb BPM_BUFFER_CAP
selected_normalized_speeds_buffer resb BPM_BUFFER_CAP
selected_normalized_scrolls_buffer resb BPM_BUFFER_CAP
bpm_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
bpm_report_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
stop_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
delay_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
warp_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
warp_stats_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
fake_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
nps_buffer resd DENSITY_CAP
nps_raw_buffer resq DENSITY_CAP
nps_sort_buffer resq DENSITY_CAP
equally_spaced_buffer resb DENSITY_CAP
default_pattern_counts resd ASSP_PATTERN_COUNT
anchor_counts resd 4
facing_counts resd 2
pattern_bitmask_buffer resb PARITY_ROW_CAP
parity_prepared_rows resb ASSP_STEP_PARITY_PREPARED_ROWS4_SIZE
parity_workspace resb ASSP_STEP_PARITY_WORKSPACE4_SIZE
alignb 16
parity_row_seconds resd PARITY_ROW_CAP
parity_row_ms resd PARITY_ROW_CAP
parity_row_beats resd PARITY_ROW_CAP
parity_prepared_row_seconds resd PARITY_ROW_CAP
parity_prepared_row_ms resd PARITY_ROW_CAP
parity_hold_end_beats resd PARITY_ROW_CAP * 8
parity_note_counts resb PARITY_ROW_CAP
parity_tech_masks resb PARITY_ROW_CAP
parity_note_masks resb PARITY_ROW_CAP
parity_hold_masks resb PARITY_ROW_CAP
parity_mine_masks resb PARITY_ROW_CAP
parity_prev_live_holds resb PARITY_ROW_CAP
parity_out_placements resb PARITY_ROW_CAP * 8
alignb 16
parity_prev_states resb PARITY_STATE_CAP * ASSP_STEP_PARITY_STATE8_SIZE
parity_next_states resb PARITY_STATE_CAP * ASSP_STEP_PARITY_STATE8_SIZE
parity_prev_costs resd PARITY_STATE_CAP
parity_next_costs resd PARITY_STATE_CAP
parity_predecessors resd PARITY_STATE_CAP
parity_placements resb PARITY_STATE_CAP * 8
parity_hits resb PARITY_STATE_CAP * 5
parity_keys resd PARITY_STATE_CAP
row_scratch resq ROW_SCRATCH_CAP
minimized_buffer resb MINIMIZED_BUFFER_CAP
density_buffer resd DENSITY_CAP
stream_segment_buffer resb DENSITY_CAP * ASSP_STREAM_SEGMENT_SIZE
stream_token_buffer resb DENSITY_CAP * ASSP_STREAM_TOKEN_SIZE
text_buffer resb TEXT_BUFFER_CAP
file_buffer resb FILE_BUFFER_CAP
print_buffer resb PRINT_BUFFER_CAP
alignb 16
parity_fast_backtrack_placements resb PARITY_FAST_BACKTRACK_CAP * 8
parity_fast_backtrack_predecessors resd PARITY_FAST_BACKTRACK_CAP
alignb 16
parity_backtrack_placements resb PARITY_BACKTRACK_CAP * 8
parity_backtrack_predecessors resd PARITY_BACKTRACK_CAP
