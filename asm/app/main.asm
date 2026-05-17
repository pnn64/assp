default rel
%include "assp.inc"
%include "win64.inc"

extern CloseHandle
extern CreateFileA
extern ExitProcess
extern GetCommandLineA
extern GetFileSizeEx
extern GetStdHandle
extern ReadFile
extern WriteFile

extern assp_chart_hash_pair
extern assp_count_mines_nonfake_4
extern assp_count_mines_nonfake_8
extern assp_count_note_stats_4
extern assp_count_note_stats_8
extern assp_count_timing_fakes_4
extern assp_count_timing_fakes_8
extern assp_count_timing_note_stats_no_holds_4
extern assp_count_note_charts
extern assp_chart_owns_timing_by_index
extern assp_supported_step_type_lanes
extern assp_find_chart_bpms_by_index
extern assp_find_chart_by_index
extern assp_find_chart_timing_tags_by_index
extern assp_find_chart_tag_by_index
extern assp_find_global_bpms
extern assp_find_global_tag
extern assp_find_global_timing_tags
extern assp_elapsed_ms_bpm_only
extern assp_elapsed_ms_with_events
extern assp_last_beat_milli_4
extern assp_last_beat_milli_8
extern assp_measure_densities_4
extern assp_measure_densities_8
extern assp_measure_nps_milli_from_bpms
extern assp_measure_nps_milli_with_events
extern assp_minimize_chart_4
extern assp_minimize_chart_8
extern assp_normalize_float_digits
extern assp_parse_bpm_map
extern assp_parse_offset_ms
extern assp_stream_counts_from_densities
extern assp_stream_segments_from_densities
extern assp_stream_tokens_from_densities
extern assp_format_stream_segments
extern assp_format_stream_tokens

global start

%define FILE_BUFFER_CAP 8388608
%define DENSITY_CAP 131072
%define TEXT_BUFFER_CAP 1048576
%define BPM_BUFFER_CAP 65536
%define BPM_SEGMENT_CAP 4096
%define MINIMIZED_BUFFER_CAP 2097152
%define ROW_SCRATCH_CAP 262144

section .text

start:
    sub rsp, 40

    call init_stdout
    call parse_args

    call read_file
    test eax, eax
    jz fail_read

    cmp qword [list_mode], 0
    je .run_chart
    call print_chart_list
    xor ecx, ecx
    call ExitProcess

.run_chart:
    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    lea r9, [chart_info]
    call assp_find_chart_by_index
    test eax, eax
    jz fail_notes

    mov rcx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call assp_supported_step_type_lanes
    cmp rax, 4
    je .supported_lanes
    cmp rax, 8
    jne fail_lanes
.supported_lanes:
    mov [chart_lanes], rax

    call prepare_hash
    test eax, eax
    jz fail_hash

    lea rcx, [minimized_buffer]
    mov rdx, [minimized_chart_len]
    lea r8, [note_stats]
    cmp qword [chart_lanes], 8
    je .count_stats_8
    call assp_count_note_stats_4
    jmp .count_stats_done
.count_stats_8:
    call assp_count_note_stats_8
.count_stats_done:
    test eax, eax
    jz fail_stats

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    xor r8d, r8d
    xor r9d, r9d
    cmp qword [chart_lanes], 8
    je .measure_density_count_8
    call assp_measure_densities_4
    jmp .measure_density_count_done
.measure_density_count_8:
    call assp_measure_densities_8
.measure_density_count_done:
    mov [measure_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [density_buffer]
    mov r9d, DENSITY_CAP
    cmp qword [chart_lanes], 8
    je .measure_density_fill_8
    call assp_measure_densities_4
    jmp .measure_density_fill_done
.measure_density_fill_8:
    call assp_measure_densities_8
.measure_density_fill_done:

    call prepare_offset
    test eax, eax
    jz fail_duration

    call prepare_timing_events
    test eax, eax
    jz fail_duration

    call prepare_mines_nonfake
    test eax, eax
    jz fail_stats

    call prepare_timing_fakes
    test eax, eax
    jz fail_stats

    call prepare_timing_stats_no_holds
    test eax, eax
    jz fail_stats

    call prepare_nps
    test eax, eax
    jz fail_nps

    call prepare_duration
    test eax, eax
    jz fail_duration

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_counts]
    call assp_stream_counts_from_densities
    test eax, eax
    jz fail_stats

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    xor r8d, r8d
    xor r9d, r9d
    call assp_stream_segments_from_densities
    mov [stream_segment_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_segment_buffer]
    mov r9d, DENSITY_CAP
    call assp_stream_segments_from_densities

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    xor r8d, r8d
    xor r9d, r9d
    call assp_stream_tokens_from_densities
    mov [stream_token_count], rax
    cmp rax, DENSITY_CAP
    ja fail_density

    lea rcx, [density_buffer]
    mov rdx, [measure_count]
    lea r8, [stream_token_buffer]
    mov r9d, DENSITY_CAP
    call assp_stream_tokens_from_densities

    call print_report
    xor ecx, ecx
    call ExitProcess

fail_read:
    lea rcx, [msg_read_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_notes:
    lea rcx, [msg_notes_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_lanes:
    lea rcx, [msg_lanes_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_stats:
    lea rcx, [msg_stats_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_density:
    lea rcx, [msg_density_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_hash:
    lea rcx, [msg_hash_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_nps:
    lea rcx, [msg_nps_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_duration:
    lea rcx, [msg_duration_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

init_stdout:
    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    add rsp, 40
    ret

parse_args:
    push rsi
    sub rsp, 32

    lea rax, [default_fixture]
    mov [input_path], rax
    mov qword [chart_index], 0
    mov qword [list_mode], 0

    call GetCommandLineA
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

.parse_chart:
    cmp byte [rsi], 'l'
    je .store_list
    cmp byte [rsi], 'L'
    je .store_list
    cmp byte [rsi], '-'
    jne .parse_chart_number
    cmp byte [rsi + 1], '-'
    jne .parse_chart_number
    cmp byte [rsi + 2], 'l'
    je .store_list
    cmp byte [rsi + 2], 'L'
    je .store_list

.parse_chart_number:
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
    mov [chart_index], rax
    jmp .done

.store_list:
    mov qword [list_mode], 1

.done:
    add rsp, 32
    pop rsi
    ret

read_file:
    sub rsp, 72

    mov qword [file_handle], 0
    mov qword [file_size], 0
    mov dword [file_bytes_read], 0

    mov rcx, [input_path]
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword [rsp + 32], OPEN_EXISTING
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je .fail
    mov [file_handle], rax

    mov rcx, rax
    lea rdx, [file_size]
    call GetFileSizeEx
    test eax, eax
    jz .close_fail

    mov rax, [file_size]
    test rax, rax
    jz .close_fail
    cmp rax, FILE_BUFFER_CAP
    ja .close_fail

    mov rcx, [file_handle]
    lea rdx, [file_buffer]
    mov r8d, eax
    lea r9, [file_bytes_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test eax, eax
    jz .close_fail

    mov rcx, [file_handle]
    call CloseHandle
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
    call CloseHandle
    mov qword [file_handle], 0

.fail:
    xor eax, eax

.done:
    add rsp, 72
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

prepare_hash:
    sub rsp, 56

    mov qword [bpms_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [bpms_slice + ASSP_BYTE_SLICE_LEN], 0
    mov qword [bpm_segment_count], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    lea r9, [bpms_slice]
    call assp_find_chart_bpms_by_index
    test eax, eax
    jnz .normalize_bpms

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [bpms_slice]
    call assp_find_global_bpms
    test eax, eax
    jnz .normalize_bpms

    mov qword [normalized_bpms_len], 0
    jmp .parse_bpms

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

.parse_bpms:
    mov rcx, [bpms_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [bpms_slice + ASSP_BYTE_SLICE_LEN]
    lea r8, [bpm_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [bpm_segment_count], rax

.measure_minimized:
    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    xor r8d, r8d
    xor r9d, r9d
    lea rax, [row_scratch]
    mov [rsp + 32], rax
    mov qword [rsp + 40], ROW_SCRATCH_CAP
    cmp qword [chart_lanes], 8
    je .measure_minimized_count_8
    call assp_minimize_chart_4
    jmp .measure_minimized_count_done
.measure_minimized_count_8:
    call assp_minimize_chart_8
.measure_minimized_count_done:
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, MINIMIZED_BUFFER_CAP
    ja .fail
    mov [minimized_chart_len], rax

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
    mov [minimized_chart_len], rax

    lea rcx, [minimized_buffer]
    mov rdx, rax
    lea r8, [bpm_buffer]
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
    mov [peak_nps_milli], r9
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 104
    ret

prepare_timing_events:
    sub rsp, 56

    mov qword [bpm_segment_count], 0
    mov qword [stop_segment_count], 0
    mov qword [delay_segment_count], 0
    mov qword [warp_segment_count], 0
    mov qword [fake_segment_count], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [global_timing_tags]
    call assp_find_global_timing_tags
    test eax, eax
    jz .fail

    lea r10, [chart_timing_tags]
    xor eax, eax
    mov r11d, ASSP_TIMING_TAGS_SIZE / 8
.zero_chart_tags:
    mov [r10], rax
    add r10, 8
    dec r11d
    jnz .zero_chart_tags

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    lea r9, [chart_timing_tags]
    call assp_find_chart_timing_tags_by_index

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    call assp_chart_owns_timing_by_index
    test eax, eax
    jz .select_bpms

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
    lea r8, [bpm_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [bpm_segment_count], rax
    test rax, rax
    jnz .select_stops
    mov qword [bpm_segment_buffer + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    mov qword [bpm_segment_buffer + ASSP_BPM_SEGMENT_BPM_MILLI], 60000
    mov qword [bpm_segment_count], 1

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
    lea r8, [stop_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
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
    lea r8, [delay_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
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
    lea r8, [warp_segment_buffer]
    mov r9d, BPM_SEGMENT_CAP
    call assp_parse_bpm_map
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, BPM_SEGMENT_CAP
    ja .fail
    mov [warp_segment_count], rax

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

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 56
    ret

prepare_mines_nonfake:
    sub rsp, 72

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_segment_buffer]
    mov r9, [warp_segment_count]
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
    lea r8, [warp_segment_buffer]
    mov r9, [warp_segment_count]
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

prepare_timing_stats_no_holds:
    sub rsp, 88

    cmp qword [chart_lanes], 4
    jne .success

    mov rax, [note_stats + ASSP_NOTE_STATS_HOLDS]
    or rax, [note_stats + ASSP_NOTE_STATS_ROLLS]
    jnz .success

    mov rcx, [chart_info + ASSP_CHART_INFO_NOTES_PTR]
    mov rdx, [chart_info + ASSP_CHART_INFO_NOTES_LEN]
    lea r8, [warp_segment_buffer]
    mov r9, [warp_segment_count]
    lea rax, [fake_segment_buffer]
    mov [rsp + 32], rax
    mov rax, [fake_segment_count]
    mov [rsp + 40], rax
    lea rax, [note_stats]
    mov [rsp + 48], rax
    lea rax, [row_scratch]
    mov [rsp + 56], rax
    mov qword [rsp + 64], ROW_SCRATCH_CAP
    call assp_count_timing_note_stats_no_holds_4
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

prepare_offset:
    sub rsp, 56

    mov qword [offset_ms], 0
    mov qword [chart_has_own_timing], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    lea r8, [tag_offset]
    mov r9d, tag_offset_end - tag_offset
    lea rax, [offset_slice]
    mov [rsp + 32], rax
    call assp_find_global_tag
    test eax, eax
    jz .chart_offset

    mov rcx, [offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [offset_slice + ASSP_BYTE_SLICE_LEN]
    call assp_parse_offset_ms
    mov [offset_ms], rax

.chart_offset:
    mov qword [offset_slice + ASSP_BYTE_SLICE_PTR], 0
    mov qword [offset_slice + ASSP_BYTE_SLICE_LEN], 0

    lea rcx, [file_buffer]
    mov rdx, [file_len]
    mov r8, [chart_index]
    lea r9, [tag_offset]
    mov qword [rsp + 32], tag_offset_end - tag_offset
    lea rax, [offset_slice]
    mov [rsp + 40], rax
    call assp_find_chart_tag_by_index
    test eax, eax
    jz .success

    mov qword [chart_has_own_timing], ASSP_TRUE
    mov rcx, [offset_slice + ASSP_BYTE_SLICE_PTR]
    mov rdx, [offset_slice + ASSP_BYTE_SLICE_LEN]
    call assp_parse_offset_ms
    mov [offset_ms], rax

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
    jmp .success

.bpm_only:
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
    mov eax, ASSP_TRUE

.done:
    add rsp, 80
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

    lea rcx, [label_chart]
    mov rdx, [chart_index]
    call print_field
    lea rcx, [label_step_type]
    mov rdx, [chart_info + ASSP_CHART_INFO_STEP_TYPE_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_STEP_TYPE_LEN]
    call print_slice_field
    lea rcx, [label_difficulty]
    mov rdx, [chart_info + ASSP_CHART_INFO_DIFFICULTY_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_DIFFICULTY_LEN]
    call print_slice_field
    lea rcx, [label_meter]
    mov rdx, [chart_info + ASSP_CHART_INFO_METER_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_METER_LEN]
    call print_slice_field
    lea rcx, [label_description]
    mov rdx, [chart_info + ASSP_CHART_INFO_DESC_PTR]
    mov r8, [chart_info + ASSP_CHART_INFO_DESC_LEN]
    call print_slice_field
    lea rcx, [label_hash]
    lea rdx, [hash_pair]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_bpm_neutral_hash]
    lea rdx, [hash_pair + 16]
    mov r8d, 16
    call print_slice_field
    lea rcx, [label_hash_bpms]
    lea rdx, [bpm_buffer]
    mov r8, [normalized_bpms_len]
    call print_slice_field
    lea rcx, [label_measures]
    mov rdx, [measure_count]
    call print_field
    lea rcx, [label_peak_nps_milli]
    mov rdx, [peak_nps_milli]
    call print_field
    lea rcx, [label_last_beat_milli]
    mov rdx, [last_beat_milli]
    call print_field
    lea rcx, [label_duration_ms]
    mov rdx, [duration_ms]
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
    lea rcx, [label_stream_segments]
    mov rdx, [stream_segment_count]
    call print_field
    lea rcx, [label_stream_tokens]
    mov rdx, [stream_token_count]
    call print_field
    lea rcx, [label_breakdown_detailed]
    mov edx, ASSP_BREAKDOWN_DETAILED
    call print_token_breakdown
    lea rcx, [label_breakdown_partial]
    mov edx, ASSP_BREAKDOWN_PARTIAL
    call print_token_breakdown
    lea rcx, [label_breakdown_simplified]
    mov edx, ASSP_BREAKDOWN_SIMPLIFIED
    call print_token_breakdown
    lea rcx, [label_stream_breakdown_detailed]
    mov edx, ASSP_STREAM_BREAKDOWN_DETAILED
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_partial]
    mov edx, ASSP_STREAM_BREAKDOWN_PARTIAL
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_simple]
    mov edx, ASSP_STREAM_BREAKDOWN_SIMPLE
    call print_segment_breakdown
    lea rcx, [label_stream_breakdown_total]
    mov edx, ASSP_STREAM_BREAKDOWN_TOTAL
    call print_segment_breakdown
    lea rcx, [label_rows]
    mov rdx, [note_stats + ASSP_NOTE_STATS_ROWS]
    call print_field
    lea rcx, [label_steps]
    mov rdx, [note_stats + ASSP_NOTE_STATS_STEPS]
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
    lea rcx, [label_down]
    mov rdx, [note_stats + ASSP_NOTE_STATS_DOWN]
    call print_field
    lea rcx, [label_up]
    mov rdx, [note_stats + ASSP_NOTE_STATS_UP]
    call print_field
    lea rcx, [label_right]
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
    sub rsp, 56
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [stdout_handle]
    lea r9, [stdout_written]
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 56
    ret

section .data

default_fixture db "fixtures\camellia_mix.ssc", 0
tag_offset db "#OFFSET:"
tag_offset_end:
msg_header db "assp standalone", 13, 10, 0
msg_read_fail db "failed to read input file", 13, 10, 0
msg_notes_fail db "failed to find selected #NOTES chart", 13, 10, 0
msg_lanes_fail db "unsupported step type; standalone currently supports dance-single and dance-double", 13, 10, 0
msg_stats_fail db "assembly note stat counter failed", 13, 10, 0
msg_density_fail db "chart has too many measures for the density buffer", 13, 10, 0
msg_hash_fail db "assembly hash pipeline failed", 13, 10, 0
msg_nps_fail db "assembly nps pipeline failed", 13, 10, 0
msg_duration_fail db "assembly duration pipeline failed", 13, 10, 0
msg_breakdown_too_long db "breakdown output exceeded text buffer", 13, 10, 0
label_file db "file: ", 0
label_charts db "charts: ", 0
label_chart db "chart: ", 0
label_step_type db "step_type: ", 0
label_difficulty db "difficulty: ", 0
label_meter db "meter: ", 0
label_description db "description: ", 0
label_hash db "hash: ", 0
label_bpm_neutral_hash db "bpm_neutral_hash: ", 0
label_hash_bpms db "hash_bpms: ", 0
label_measures db "measures: ", 0
label_peak_nps_milli db "peak_nps_milli: ", 0
label_last_beat_milli db "last_beat_milli: ", 0
label_duration_ms db "duration_ms: ", 0
label_stream16 db "16th_streams: ", 0
label_stream20 db "20th_streams: ", 0
label_stream24 db "24th_streams: ", 0
label_stream32 db "32nd_streams: ", 0
label_sn_breaks db "sn_breaks: ", 0
label_total_breaks db "total_breaks: ", 0
label_stream_segments db "stream_segments: ", 0
label_stream_tokens db "stream_tokens: ", 0
label_breakdown_detailed db "breakdown_detailed: ", 0
label_breakdown_partial db "breakdown_partial: ", 0
label_breakdown_simplified db "breakdown_simplified: ", 0
label_stream_breakdown_detailed db "stream_breakdown_detailed: ", 0
label_stream_breakdown_partial db "stream_breakdown_partial: ", 0
label_stream_breakdown_simple db "stream_breakdown_simple: ", 0
label_stream_breakdown_total db "stream_breakdown_total: ", 0
label_rows db "rows: ", 0
label_steps db "steps: ", 0
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
label_down db "down: ", 0
label_up db "up: ", 0
label_right db "right: ", 0
label_bad_rows db "malformed_rows: ", 0
space db " ", 0
newline db 13, 10, 0

section .bss

stdout_handle resq 1
stdout_written resd 1
input_path resq 1
chart_index resq 1
chart_lanes resq 1
list_mode resq 1
chart_count resq 1
measure_count resq 1
stream_segment_count resq 1
stream_token_count resq 1
file_handle resq 1
file_size resq 1
file_len resq 1
file_bytes_read resd 1
chart_info resb ASSP_CHART_INFO_SIZE
bpms_slice resb ASSP_BYTE_SLICE_SIZE
offset_slice resb ASSP_BYTE_SLICE_SIZE
global_timing_tags resb ASSP_TIMING_TAGS_SIZE
chart_timing_tags resb ASSP_TIMING_TAGS_SIZE
note_stats resb ASSP_NOTE_STATS_SIZE
stream_counts resb ASSP_STREAM_COUNTS_SIZE
num_buffer resb 32
normalized_bpms_len resq 1
bpm_segment_count resq 1
stop_segment_count resq 1
delay_segment_count resq 1
warp_segment_count resq 1
fake_segment_count resq 1
minimized_chart_len resq 1
nps_count resq 1
peak_nps_milli resq 1
last_beat_milli resq 1
offset_ms resq 1
mines_nonfake resq 1
timing_fakes resq 1
chart_has_own_timing resq 1
duration_ms resq 1
hash_pair resb 32
bpm_buffer resb BPM_BUFFER_CAP
bpm_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
stop_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
delay_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
warp_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
fake_segment_buffer resb BPM_SEGMENT_CAP * ASSP_BPM_SEGMENT_SIZE
nps_buffer resd DENSITY_CAP
row_scratch resq ROW_SCRATCH_CAP
minimized_buffer resb MINIMIZED_BUFFER_CAP
density_buffer resd DENSITY_CAP
stream_segment_buffer resb DENSITY_CAP * ASSP_STREAM_SEGMENT_SIZE
stream_token_buffer resb DENSITY_CAP * ASSP_STREAM_TOKEN_SIZE
text_buffer resb TEXT_BUFFER_CAP
file_buffer resb FILE_BUFFER_CAP
