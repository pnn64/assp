default rel
%include "assp.inc"

global assp_normalize_float_digits
global assp_parse_bpm_map
global assp_parse_speed_map
global assp_parse_timing_seconds_map
global assp_parse_offset_ms
global assp_parse_offset_us
global assp_bpm_display_range
global assp_bpm_average_centi
global assp_bpm_median_centi
global assp_bpm_at_beat_milli
global assp_tier_bpm_centi
global assp_elapsed_ms_bpm_only
global assp_elapsed_us_bpm_only
global assp_elapsed_ms_with_events
global assp_elapsed_us_with_events
global assp_elapsed_seconds_f32_with_events
global assp_measure_nps_milli_from_bpms
global assp_measure_nps_milli_with_events
global assp_nps_peak_milli_from_bpms
global assp_nps_median_centi

section .text

%define EVT_WARP_LEN -64
%define EVT_TARGET -72
%define EVT_TIME -80
%define EVT_BEAT -88
%define EVT_BPM -96
%define EVT_WARP_END -104
%define EVT_I_BPM -112
%define EVT_I_STOP -120
%define EVT_I_DELAY -128
%define EVT_I_WARP -136
%define EVT_BEST_BEAT -144
%define EVT_BEST_VAL -152
%define EVT_BEST_TYPE -160
%define EVT_BEST_PRI -168
%define EVT_RETURN_US -176

%define F32_TIME -64
%define F32_BPS -68
%define F32_LAST_ROW -72
%define F32_TARGET_ROW -76
%define F32_WARP_DEST_ROW -80
%define F32_IS_WARPING -84
%define F32_BPM_IDX -96
%define F32_STOP_IDX -104
%define F32_DELAY_IDX -112
%define F32_WARP_IDX -120
%define F32_BEST_ROW -124
%define F32_BEST_TYPE -128

; NPS rbp frames save seven nonvolatile registers at -8..-56.
%define NPS_DENSITIES -64
%define NPS_DENSITY_LEN -72
%define NPS_BPMS -80
%define NPS_BPM_LEN -88

%define TIER_MAX_BPM 0
%define TIER_MAX_E 8
%define TIER_RUN_E 16
%define TIER_CAT 24
%define TIER_LEN 32
%define TIER_BPM_IDX 40
%define TIER_CUR_BPM 48
%define TIER_NEXT_BEAT 56
%define NPS_STOPS -96
%define NPS_STOP_LEN -104
%define NPS_DELAYS -112
%define NPS_DELAY_LEN -120
%define NPS_WARPS -128
%define NPS_WARP_LEN -136
%define NPS_OUT -144
%define NPS_OUT_CAP -152
%define NPS_INDEX -160
%define NPS_START_MS -168
%define NPS_END_MS -176
%define NPS_EVT_TARGET -184
%define NPS_EVT_TIME -192
%define NPS_EVT_BEAT -200
%define NPS_EVT_BPM -208
%define NPS_EVT_WARP_END -216
%define NPS_EVT_I_BPM -224
%define NPS_EVT_I_STOP -232
%define NPS_EVT_I_DELAY -240
%define NPS_EVT_I_WARP -248
%define NPS_EVT_BEST_BEAT -256
%define NPS_EVT_BEST_VAL -264
%define NPS_EVT_BEST_TYPE -272
%define NPS_EVT_BEST_PRI -280

%macro ASSP_CONSIDER_TIMING_EVENT 0
    cmp qword [rbp + EVT_BEST_TYPE], -1
    je %%store
    cmp r8, [rbp + EVT_BEST_BEAT]
    jl %%store
    jg %%done
    cmp r10, [rbp + EVT_BEST_PRI]
    jge %%done
%%store:
    mov [rbp + EVT_BEST_BEAT], r8
    mov [rbp + EVT_BEST_VAL], r9
    mov [rbp + EVT_BEST_PRI], r10
    mov [rbp + EVT_BEST_TYPE], r11
%%done:
%endmacro

%macro ASSP_NPS_CONSIDER_TIMING_EVENT 0
    cmp qword [rbp + NPS_EVT_BEST_TYPE], -1
    je %%store
    cmp r8, [rbp + NPS_EVT_BEST_BEAT]
    jl %%store
    jg %%done
    cmp r10, [rbp + NPS_EVT_BEST_PRI]
    jge %%done
%%store:
    mov [rbp + NPS_EVT_BEST_BEAT], r8
    mov [rbp + NPS_EVT_BEST_VAL], r9
    mov [rbp + NPS_EVT_BEST_PRI], r10
    mov [rbp + NPS_EVT_BEST_TYPE], r11
%%done:
%endmacro

; rcx = timing map bytes, rdx = len, r8 = optional output bytes,
; r9 = output byte cap. rax = bytes required/written, or ASSP_NOT_FOUND.
assp_normalize_float_digits:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov rsi, rcx
    lea r12, [rcx + rdx]
    mov rdi, r8
    mov r13, r9
    xor r14d, r14d
    xor r15d, r15d

.entry_loop:
    cmp rsi, r12
    jae .done

    mov qword [rsp + 8], 0
    mov r10, rsi

.scan_entry:
    cmp r10, r12
    jae .entry_scanned
    mov al, [r10]
    cmp al, ','
    je .entry_scanned
    cmp al, '='
    jne .scan_entry_next
    cmp qword [rsp + 8], 0
    jne .scan_entry_next
    mov [rsp + 8], r10
.scan_entry_next:
    inc r10
    jmp .scan_entry

.entry_scanned:
    mov [rsp], r10
    cmp qword [rsp + 8], 0
    je .skip_entry
    mov rbx, rsi
    mov r11, r10

.trim_left:
    cmp rbx, r11
    jae .skip_entry
    cmp byte [rbx], ' '
    ja .trim_right
    inc rbx
    jmp .trim_left

.trim_right:
    cmp r11, rbx
    jbe .skip_entry
    cmp byte [r11 - 1], ' '
    ja .parse_fields
    dec r11
    jmp .trim_right

.parse_fields:
    mov rax, [rsp + 8]
    mov [rsp + 16], r11

    mov rcx, rbx
    mov rdx, rax
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    mov [rsp + 24], rax
    mov [rsp + 32], edx

    mov rcx, [rsp + 8]
    inc rcx
    mov rdx, [rsp + 16]
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    mov [rsp + 40], rax
    mov [rsp + 48], edx

    test r15, r15
    jz .emit_left
    mov al, ','
    call emit_byte
    jc .invalid

.emit_left:
    mov rax, [rsp + 24]
    mov edx, [rsp + 32]
    call emit_scaled3
    jc .invalid

    mov al, '='
    call emit_byte
    jc .invalid

    mov rax, [rsp + 40]
    mov edx, [rsp + 48]
    call emit_scaled3
    jc .invalid

    mov r15d, ASSP_TRUE

.skip_entry:
    mov rsi, [rsp]
    cmp rsi, r12
    jae .done
    inc rsi
    jmp .entry_loop

.empty:
    xor r14d, r14d

.done:
    mov rax, r14
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = SPEEDS map bytes, rdx = len, r8 = optional assp_speed_segment output,
; r9 = output cap. rax = parsed segment count, or ASSP_NOT_FOUND.
; Beats are signed thousandths; ratios and delays are signed millionths.
; Invalid comma entries are skipped.
assp_parse_speed_map:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 96

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov rsi, rcx
    lea r12, [rcx + rdx]
    mov rdi, r8
    mov r13, r9
    xor r14d, r14d
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], 0

.entry_loop:
    cmp rsi, r12
    jae .sort

    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0
    mov r10, rsi

.scan_entry:
    cmp r10, r12
    jae .entry_scanned
    mov al, [r10]
    cmp al, ','
    je .entry_scanned
    cmp al, '='
    jne .scan_entry_next
    cmp qword [rsp + 8], 0
    jne .scan_eq2
    mov [rsp + 8], r10
    jmp .scan_entry_next
.scan_eq2:
    cmp qword [rsp + 16], 0
    jne .scan_eq3
    mov [rsp + 16], r10
    jmp .scan_entry_next
.scan_eq3:
    cmp qword [rsp + 24], 0
    jne .scan_entry_next
    mov [rsp + 24], r10
.scan_entry_next:
    inc r10
    jmp .scan_entry

.entry_scanned:
    mov [rsp], r10
    cmp qword [rsp + 8], 0
    je .skip_entry
    cmp qword [rsp + 16], 0
    je .skip_entry

    mov r11, r10
    mov rax, [rsp + 24]
    test rax, rax
    jz .store_delay_end
    mov r11, rax
.store_delay_end:
    mov [rsp + 64], r11

.parse_fields:
    mov rbx, rsi
    mov rdx, [rsp + 8]
    xor r15d, r15d

.trim_beat_right:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .check_row_suffix
    dec rdx
    jmp .trim_beat_right

.check_row_suffix:
    cmp byte [rdx - 1], 'r'
    je .row_suffix
    cmp byte [rdx - 1], 'R'
    jne .parse_beat_value
.row_suffix:
    mov r15d, ASSP_TRUE
    dec rdx
.trim_before_suffix:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .parse_beat_value
    dec rdx
    jmp .trim_before_suffix

.parse_beat_value:
    mov rcx, rbx
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .beat_positive
    neg rax
.beat_positive:
    test r15d, r15d
    jz .store_beat
    cqo
    mov r10d, 48
    idiv r10
.store_beat:
    mov [rsp + 32], rax

    mov rcx, [rsp + 8]
    inc rcx
    mov rdx, [rsp + 16]
    call parse_dec6
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .store_ratio
    neg rax
.store_ratio:
    mov [rsp + 40], rax

    mov rcx, [rsp + 16]
    inc rcx
    mov rdx, [rsp + 64]
    call parse_dec6
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .store_delay
    neg rax
.store_delay:
    mov [rsp + 48], rax

    xor eax, eax
    mov r10, [rsp + 24]
    test r10, r10
    jz .store_unit
    inc r10
    mov r11, [rsp]
.find_unit_end:
    cmp r10, r11
    jae .trim_unit_right
    cmp byte [r10], ' '
    ja .trim_unit_right
    inc r10
    jmp .find_unit_end
.trim_unit_right:
    cmp r11, r10
    jbe .store_unit
    cmp byte [r11 - 1], ' '
    ja .check_unit
    dec r11
    jmp .trim_unit_right
.check_unit:
    lea rbx, [r10 + 1]
    cmp rbx, r11
    jne .store_unit
    cmp byte [r10], '1'
    jne .store_unit
    mov eax, 1
.store_unit:
    mov [rsp + 56], rax

    test rdi, rdi
    jz .inc_count
    cmp r14, r13
    jae .inc_count
    mov r10, r14
    shl r10, 5
    mov rax, [rsp + 32]
    mov [rdi + r10 + ASSP_SPEED_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 40]
    mov [rdi + r10 + ASSP_SPEED_SEGMENT_RATIO_MICRO], rax
    mov rax, [rsp + 48]
    mov [rdi + r10 + ASSP_SPEED_SEGMENT_DELAY_MICRO], rax
    mov rax, [rsp + 56]
    mov [rdi + r10 + ASSP_SPEED_SEGMENT_UNIT], rax

    mov rax, [rsp + 32]
    test r14, r14
    jz .store_last_beat
    cmp rax, [rsp + 72]
    jge .store_last_beat
    mov qword [rsp + 80], 1
.store_last_beat:
    mov [rsp + 72], rax

.inc_count:
    inc r14

.skip_entry:
    mov rsi, [rsp]
    cmp rsi, r12
    jae .sort
    inc rsi
    jmp .entry_loop

.empty:
    xor r14d, r14d

.sort:
    test rdi, rdi
    jz .done
    cmp r14, 2
    jb .done
    cmp r14, r13
    ja .done
    cmp qword [rsp + 80], 0
    je .done

    mov r8d, 1
.sort_outer:
    cmp r8, r14
    jae .done
    mov r10, r8
    shl r10, 5
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_BEAT_MILLI]
    mov [rsp + 32], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_RATIO_MICRO]
    mov [rsp + 40], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_DELAY_MICRO]
    mov [rsp + 48], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_UNIT]
    mov [rsp + 56], rax
    mov r9, r8

.sort_inner:
    test r9, r9
    jz .sort_place
    mov r10, r9
    dec r10
    shl r10, 5
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_BEAT_MILLI]
    cmp rax, [rsp + 32]
    jle .sort_place

    mov r11, r9
    shl r11, 5
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_BEAT_MILLI], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_RATIO_MICRO]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_RATIO_MICRO], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_DELAY_MICRO]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_DELAY_MICRO], rax
    mov rax, [rdi + r10 + ASSP_SPEED_SEGMENT_UNIT]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_UNIT], rax
    dec r9
    jmp .sort_inner

.sort_place:
    mov r11, r9
    shl r11, 5
    mov rax, [rsp + 32]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 40]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_RATIO_MICRO], rax
    mov rax, [rsp + 48]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_DELAY_MICRO], rax
    mov rax, [rsp + 56]
    mov [rdi + r11 + ASSP_SPEED_SEGMENT_UNIT], rax
    inc r8
    jmp .sort_outer

.done:
    mov rax, r14
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = timing map bytes, rdx = len, r8 = optional assp_bpm_segment output,
; r9 = output cap. rax = parsed segment count, or ASSP_NOT_FOUND.
; Beats are signed thousandths; values are signed millionths of a second.
; Invalid comma entries are skipped.
assp_parse_timing_seconds_map:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov rsi, rcx
    lea r12, [rcx + rdx]
    mov rdi, r8
    mov r13, r9
    xor r14d, r14d
    mov qword [rsp + 56], 0
    mov qword [rsp + 64], 0

.entry_loop:
    cmp rsi, r12
    jae .sort

    mov qword [rsp + 8], 0
    mov r10, rsi

.scan_entry:
    cmp r10, r12
    jae .entry_scanned
    mov al, [r10]
    cmp al, ','
    je .entry_scanned
    cmp al, '='
    jne .scan_entry_next
    cmp qword [rsp + 8], 0
    jne .scan_entry_next
    mov [rsp + 8], r10
.scan_entry_next:
    inc r10
    jmp .scan_entry

.entry_scanned:
    mov [rsp], r10
    cmp qword [rsp + 8], 0
    je .skip_entry
    mov rbx, rsi
    mov r11, r10

.trim_left:
    cmp rbx, r11
    jae .skip_entry
    cmp byte [rbx], ' '
    ja .trim_right
    inc rbx
    jmp .trim_left

.trim_right:
    cmp r11, rbx
    jbe .skip_entry
    cmp byte [r11 - 1], ' '
    ja .parse_beat
    dec r11
    jmp .trim_right

.parse_beat:
    mov rax, [rsp + 8]
    mov [rsp + 16], r11
    mov rdx, rax
    xor r15d, r15d

.trim_beat_right:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .check_row_suffix
    dec rdx
    jmp .trim_beat_right

.check_row_suffix:
    cmp byte [rdx - 1], 'r'
    je .row_suffix
    cmp byte [rdx - 1], 'R'
    jne .parse_beat_value
.row_suffix:
    mov r15d, ASSP_TRUE
    dec rdx
.trim_before_suffix:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .parse_beat_value
    dec rdx
    jmp .trim_before_suffix

.parse_beat_value:
    mov rcx, rbx
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .beat_positive
    neg rax
.beat_positive:
    test r15d, r15d
    jz .store_beat
    cqo
    mov r10d, 48
    idiv r10
.store_beat:
    mov [rsp + 24], rax

    mov rcx, [rsp + 8]
    inc rcx
    mov rdx, [rsp + 16]
    call parse_dec6
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .store_value
    neg rax
.store_value:
    mov [rsp + 32], rax

    test rdi, rdi
    jz .inc_count
    cmp r14, r13
    jae .inc_count
    mov r10, r14
    shl r10, 4
    mov rax, [rsp + 24]
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 32]
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI], rax

    mov rax, [rsp + 24]
    test r14, r14
    jz .store_last_beat
    cmp rax, [rsp + 56]
    jge .store_last_beat
    mov qword [rsp + 64], 1
.store_last_beat:
    mov [rsp + 56], rax

.inc_count:
    inc r14

.skip_entry:
    mov rsi, [rsp]
    cmp rsi, r12
    jae .sort
    inc rsi
    jmp .entry_loop

.empty:
    xor r14d, r14d

.sort:
    test rdi, rdi
    jz .done
    cmp r14, 2
    jb .done
    cmp r14, r13
    ja .done
    cmp qword [rsp + 64], 0
    je .done

    mov r8d, 1
.sort_outer:
    cmp r8, r14
    jae .done
    mov r10, r8
    shl r10, 4
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov [rsp + 40], rax
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + 48], rax
    mov r9, r8

.sort_inner:
    test r9, r9
    jz .sort_place
    mov r10, r9
    dec r10
    shl r10, 4
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp rax, [rsp + 40]
    jle .sort_place

    mov r11, r9
    shl r11, 4
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], rax
    dec r9
    jmp .sort_inner

.sort_place:
    mov r11, r9
    shl r11, 4
    mov rax, [rsp + 40]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 48]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], rax
    inc r8
    jmp .sort_outer

.done:
    mov rax, r14
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = number start, rdx = number end.
; rax = absolute millionths, edx = negative flag. ASSP_NOT_FOUND on parse failure.
parse_dec6:
    push rsi
    push rdi
    push r12
    push r13

    mov rsi, rcx
    mov rdi, rdx

.trim_left:
    cmp rsi, rdi
    jae .fail
    cmp byte [rsi], ' '
    ja .trim_right
    inc rsi
    jmp .trim_left

.trim_right:
    cmp rdi, rsi
    jbe .fail
    cmp byte [rdi - 1], ' '
    ja .sign
    dec rdi
    jmp .trim_right

.sign:
    xor r13d, r13d
    cmp byte [rsi], '+'
    je .plus
    cmp byte [rsi], '-'
    jne .int_init
    mov r13d, ASSP_TRUE
.plus:
    inc rsi
    cmp rsi, rdi
    jae .fail

.int_init:
    xor r8d, r8d
    xor r9d, r9d

.int_loop:
    cmp rsi, rdi
    jae .finish_number
    movzx eax, byte [rsi]
    cmp al, 8
    je .int_skip_backspace
    cmp al, '0'
    jb .check_dot
    cmp al, '9'
    ja .finish_number
    sub eax, '0'
    imul r8, r8, 10
    add r8, rax
    inc r9
    inc rsi
    jmp .int_loop

.int_skip_backspace:
    inc rsi
    jmp .int_loop

.check_dot:
    cmp al, '.'
    jne .finish_number
    inc rsi
    xor r10d, r10d
    xor r11d, r11d
    xor r12d, r12d
    jmp .frac_loop

.frac_loop:
    cmp rsi, rdi
    jae .finish_frac
    movzx eax, byte [rsi]
    cmp al, 8
    je .frac_skip_backspace
    cmp al, '0'
    jb .finish_frac
    cmp al, '9'
    ja .finish_frac
    sub eax, '0'
    inc r9
    cmp r10d, 6
    jae .round_digit
    imul r11, r11, 10
    add r11, rax
    inc r10d
    inc rsi
    jmp .frac_loop

.round_digit:
    cmp r10d, 6
    jne .extra_digit
    mov r12d, eax
    inc r10d
    inc rsi
    jmp .frac_loop

.extra_digit:
    test eax, eax
    jz .extra_next
    or r10d, 0x80000000
.extra_next:
    inc rsi
    jmp .frac_loop

.frac_skip_backspace:
    inc rsi
    jmp .frac_loop

.finish_frac:
    mov ecx, r10d
    and ecx, 0x7fffffff
    mov eax, 6
    cmp ecx, eax
    cmova ecx, eax
    lea rdx, [rel bpm_dec6_frac_scale]
    imul r11, qword [rdx + rcx * 8]
    jmp .trailing

.finish_number:
    xor r11d, r11d
    xor r12d, r12d
    xor r10d, r10d

.trailing:
    cmp rsi, rdi
    jae .finish_scaled
    cmp byte [rsi], ' '
    ja .fail
    inc rsi
    jmp .trailing

.finish_scaled:
    test r9, r9
    jz .fail

    imul r8, r8, 1000000
    add r8, r11

    test r13d, r13d
    jnz .negative_round
    cmp r12d, 5
    jb .store
    inc r8
    jmp .store

.negative_round:
    cmp r12d, 5
    ja .round_negative
    jne .store
    test r8, r8
    jz .round_negative
    test r10d, 0x80000000
    jz .store
.round_negative:
    inc r8

.store:
    mov rax, r8
    mov edx, r13d
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret

; rcx = offset bytes, rdx = byte len. rax = signed offset milliseconds.
; Invalid or empty values match RSSP's parser fallback and return 0.
assp_parse_offset_ms:
    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero
    cmp byte [rcx], ' '
    jbe .zero
    cmp byte [rcx + rdx - 1], ' '
    jbe .zero

    add rdx, rcx
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .zero
    test edx, edx
    jz .done
    neg rax
    ret

.zero:
    xor eax, eax
.done:
    ret

; rcx = offset bytes, rdx = byte len. rax = signed offset microseconds.
; Invalid or empty values match RSSP's parser fallback and return 0.
assp_parse_offset_us:
    sub rsp, 40

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero
    cmp byte [rcx], ' '
    jbe .zero
    cmp byte [rcx + rdx - 1], ' '
    jbe .zero

    add rdx, rcx
    call parse_dec6
    cmp rax, ASSP_NOT_FOUND
    je .zero
    test edx, edx
    jz .done
    neg rax
    jmp .done

.zero:
    xor eax, eax
.done:
    cvtsi2sd xmm0, rax
    divsd xmm0, [rel nps_f64_1000000]
    cvtsd2ss xmm0, xmm0
    cvtss2sd xmm0, xmm0
    mulsd xmm0, [rel nps_f64_1000000]
    cvtsd2si rax, xmm0
    add rsp, 40
    ret

; rcx = BPM segments, rdx = count, r8 = out min BPM, r9 = out max BPM.
; Values are rounded to whole BPMs after RSSP display-BPM filtering.
; eax = 1 on success, 0 on invalid pointers.
assp_bpm_display_range:
    push rbx
    push rsi
    push rdi
    push r12

    test r8, r8
    jz .fail
    test r9, r9
    jz .fail

    mov r10, r8
    mov r11, r9

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .fail

    mov rbx, 0x7fffffffffffffff
    mov rsi, 0x8000000000000000
    xor r8d, r8d
    xor r9d, r9d

.display_loop:
    cmp r8, rdx
    jae .display_done
    mov r12, r8
    shl r12, 4
    mov rax, [rcx + r12 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, 0
    jle .display_next
    cmp rax, 10000000
    jge .display_next
    cmp rax, rbx
    jge .display_check_max
    mov rbx, rax
.display_check_max:
    cmp rax, rsi
    jle .display_count
    mov rsi, rax
.display_count:
    inc r9
.display_next:
    inc r8
    jmp .display_loop

.display_done:
    test r9, r9
    jnz .store

    mov rbx, 0x7fffffffffffffff
    mov rsi, 0x8000000000000000
    xor r8d, r8d
.fallback_loop:
    cmp r8, rdx
    jae .store
    mov r12, r8
    shl r12, 4
    mov rax, [rcx + r12 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, rbx
    jge .fallback_check_max
    mov rbx, rax
.fallback_check_max:
    cmp rax, rsi
    jle .fallback_next
    mov rsi, rax
.fallback_next:
    inc r8
    jmp .fallback_loop

.store:
    mov rax, rbx
    call clamp_round_bpm_milli
    mov [r10], rax
    mov rax, rsi
    call clamp_round_bpm_milli
    mov [r11], rax
    mov eax, ASSP_TRUE
    jmp .done

.zero:
    mov qword [r10], 0
    mov qword [r11], 0
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

clamp_round_bpm_milli:
    test rax, rax
    jg .round
    xor eax, eax
    ret
.round:
    xor edx, edx
    mov r12d, 1000
    div r12
    cmp rdx, 500
    ja .round_up
    jb .done
    test rax, 1
    jz .done
.round_up:
    inc rax
.done:
    ret

; rcx = BPM segments, rdx = count. rax = RSSP average display BPM * 100.
assp_bpm_average_centi:
    push rbx
    push rsi
    push r12

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero

    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
.display_loop:
    cmp r8, rdx
    jae .display_done
    mov r11, r8
    shl r11, 4
    mov rax, [rcx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, 0
    jle .display_next
    cmp rax, 10000000
    jge .display_next
    add r10, rax
    inc r9
.display_next:
    inc r8
    jmp .display_loop

.display_done:
    test r9, r9
    jnz .average

    xor r8d, r8d
    xor r10d, r10d
.fallback_loop:
    cmp r8, rdx
    jae .fallback_done
    mov r11, r8
    shl r11, 4
    add r10, [rcx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r8
    jmp .fallback_loop

.fallback_done:
    mov r9, rdx

.average:
    mov rax, r10
    mov rbx, r9
    imul rbx, rbx, 10
    call round_signed_div_ties_even
    jmp .done

.zero:
    xor eax, eax

.done:
    pop r12
    pop rsi
    pop rbx
    ret

; rcx = BPM segments, rdx = count. rax = RSSP median display BPM * 100.
assp_bpm_median_centi:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero

    mov rsi, rcx
    mov rdi, rdx

    xor r12d, r12d
    xor r13d, r13d
.display_count_loop:
    cmp r12, rdi
    jae .display_count_done
    mov r14, r12
    shl r14, 4
    mov rax, [rsi + r14 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, 0
    jle .display_count_next
    cmp rax, 10000000
    jge .display_count_next
    inc r13
.display_count_next:
    inc r12
    jmp .display_count_loop

.display_count_done:
    mov r14d, 1
    test r13, r13
    jnz .have_count
    mov r13, rdi
    xor r14d, r14d
.have_count:
    test r13, r13
    jz .zero

    mov rax, r13
    shr rax, 1
    test r13, 1
    jz .even

.odd:
    mov r8, rax
    mov r9, r14
    call kth_bpm_segment_value
    mov rbx, 10
    call round_signed_div_ties_even
    jmp .done

.even:
    mov r15, rax
    mov r8, r15
    dec r8
    mov r9, r14
    call kth_bpm_segment_value
    mov r12, rax
    mov r8, r15
    mov r9, r14
    call kth_bpm_segment_value
    add rax, r12
    mov rbx, 20
    call round_signed_div_ties_even
    jmp .done

.zero:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rsi = BPM segments, rdi = count, r8 = kth index, r9 = display-only flag.
; rax = kth BPM value in signed thousandths.
kth_bpm_segment_value:
    push rbx
    push r12
    push r13
    push r14
    push r15

    xor r10d, r10d
.candidate_loop:
    cmp r10, rdi
    jae .zero
    mov r13, r10
    shl r13, 4
    mov r11, [rsi + r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    test r9, r9
    jz .candidate_ok
    cmp r11, 0
    jle .candidate_next
    cmp r11, 10000000
    jge .candidate_next

.candidate_ok:
    xor r14d, r14d
    xor r15d, r15d
    xor r12d, r12d
.count_loop:
    cmp r12, rdi
    jae .check_candidate
    mov r13, r12
    shl r13, 4
    mov rbx, [rsi + r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    test r9, r9
    jz .count_value_ok
    cmp rbx, 0
    jle .count_next
    cmp rbx, 10000000
    jge .count_next

.count_value_ok:
    cmp rbx, r11
    jl .less
    jle .less_equal
    jmp .count_next
.less:
    inc r14
.less_equal:
    inc r15
.count_next:
    inc r12
    jmp .count_loop

.check_candidate:
    cmp r14, r8
    ja .candidate_next
    cmp r15, r8
    jbe .candidate_next
    mov rax, r11
    jmp .done

.candidate_next:
    inc r10
    jmp .candidate_loop

.zero:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rcx = u32 measure densities, rdx = density count,
; r8 = BPM segments, r9 = BPM count. rax = RSSP tier BPM * 100.
assp_tier_bpm_centi:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero
    test r9, r9
    jz .zero
    test r8, r8
    jz .zero

    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    mov r12, r9

    xor r10d, r10d
    xor r11d, r11d
.max_display_loop:
    cmp r10, r12
    jae .max_display_done
    mov r13, r10
    shl r13, 4
    mov rax, [rbx + r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, 0
    jle .max_display_next
    cmp rax, 10000000
    jge .max_display_next
    test r11, r11
    jz .first_display_max
    cmp rax, [rsp + TIER_MAX_BPM]
    jle .max_display_next
.first_display_max:
    mov [rsp + TIER_MAX_BPM], rax
    mov r11d, 1
.max_display_next:
    inc r10
    jmp .max_display_loop

.max_display_done:
    test r11, r11
    jnz .init_run_scan

    mov rax, [rbx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + TIER_MAX_BPM], rax
    mov r10d, 1
.max_fallback_loop:
    cmp r10, r12
    jae .init_run_scan
    mov r13, r10
    shl r13, 4
    mov rax, [rbx + r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rax, [rsp + TIER_MAX_BPM]
    jle .max_fallback_next
    mov [rsp + TIER_MAX_BPM], rax
.max_fallback_next:
    inc r10
    jmp .max_fallback_loop

.init_run_scan:
    mov rax, [rbx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + TIER_CUR_BPM], rax
    mov qword [rsp + TIER_BPM_IDX], 0
    cmp r12, 1
    ja .has_next_bpm
    mov rax, 0x7fffffffffffffff
    jmp .store_next_bpm
.has_next_bpm:
    mov rax, [rbx + ASSP_BPM_SEGMENT_SIZE + ASSP_BPM_SEGMENT_BEAT_MILLI]
.store_next_bpm:
    mov [rsp + TIER_NEXT_BEAT], rax
    mov qword [rsp + TIER_MAX_E], 0
    mov qword [rsp + TIER_RUN_E], 0
    mov qword [rsp + TIER_CAT], 0
    mov qword [rsp + TIER_LEN], 0

    xor r10d, r10d
.measure_loop:
    cmp r10, rdi
    jae .finish_scan

    mov rax, r10
    imul rax, rax, 4000
.bpm_advance_loop:
    cmp rax, [rsp + TIER_NEXT_BEAT]
    jl .bpm_ready
    mov r11, [rsp + TIER_BPM_IDX]
    inc r11
    mov [rsp + TIER_BPM_IDX], r11
    mov r13, r11
    shl r13, 4
    mov r14, [rbx + r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + TIER_CUR_BPM], r14
    lea r14, [r11 + 1]
    cmp r14, r12
    jae .next_bpm_inf
    mov r13, r14
    shl r13, 4
    mov r14, [rbx + r13 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov [rsp + TIER_NEXT_BEAT], r14
    jmp .bpm_advance_loop
.next_bpm_inf:
    mov r14, 0x7fffffffffffffff
    mov [rsp + TIER_NEXT_BEAT], r14
    jmp .bpm_advance_loop

.bpm_ready:
    mov eax, [rsi + r10 * 4]
    cmp eax, 16
    jb .break_measure
    mov r11d, 1
    cmp eax, 20
    jb .have_category
    mov r11d, 2
    cmp eax, 24
    jb .have_category
    mov r11d, 3
    cmp eax, 32
    jb .have_category
    mov r11d, 4
.have_category:
    cmp qword [rsp + TIER_LEN], 0
    je .start_run_measure
    cmp r11, [rsp + TIER_CAT]
    je .continue_run_measure
    call tier_commit_run
    mov qword [rsp + TIER_LEN], 0
    mov qword [rsp + TIER_RUN_E], 0

.start_run_measure:
    mov [rsp + TIER_CAT], r11
.continue_run_measure:
    inc qword [rsp + TIER_LEN]

    mov r14, [rsp + TIER_CUR_BPM]
    cmp r14, 0
    jle .measure_next
    cmp r14, 10000000
    jge .measure_next
    mov eax, [rsi + r10 * 4]
    imul rax, r14
    cmp rax, [rsp + TIER_RUN_E]
    jle .measure_next
    mov [rsp + TIER_RUN_E], rax
    jmp .measure_next

.break_measure:
    call tier_commit_run
    mov qword [rsp + TIER_CAT], 0
    mov qword [rsp + TIER_LEN], 0
    mov qword [rsp + TIER_RUN_E], 0

.measure_next:
    inc r10
    jmp .measure_loop

.finish_scan:
    call tier_commit_run
    mov rax, [rsp + TIER_MAX_E]
    test rax, rax
    jg .round_effective
    mov rax, [rsp + TIER_MAX_BPM]
    mov rbx, 10
    call round_signed_div_ties_even
    jmp .done

.round_effective:
    mov rbx, 160
    call round_signed_div_ties_even
    jmp .done

.zero:
    xor eax, eax

.done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

tier_commit_run:
    cmp qword [rsp + 8 + TIER_LEN], 4
    jb .done
    mov rax, [rsp + 8 + TIER_RUN_E]
    cmp rax, [rsp + 8 + TIER_MAX_E]
    jle .done
    mov [rsp + 8 + TIER_MAX_E], rax
.done:
    ret

; rcx = u32 NPS values in thousandths, rdx = count.
; rax = median NPS rounded to two decimal places.
assp_nps_median_centi:
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero

    mov rsi, rcx
    mov rdi, rdx
    mov rax, rdx
    shr rax, 1
    test rdx, 1
    jz .even

.odd:
    mov r8, rax
    call kth_nps_milli_value
    mov rbx, 10
    call round_signed_div_ties_even
    jmp .done

.even:
    mov r12, rax
    mov r8, r12
    dec r8
    call kth_nps_milli_value
    mov r13, rax
    mov r8, r12
    call kth_nps_milli_value
    add rax, r13
    mov rbx, 20
    call round_signed_div_ties_even
    jmp .done

.zero:
    xor eax, eax

.done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rsi = u32 NPS values, rdi = count, r8 = kth index. rax = kth value.
kth_nps_milli_value:
    push rbx
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 2048

    test rdi, rdi
    jz .zero

    mov rbx, rdi
    mov r14, r8
    xor r12d, r12d
    mov r13d, 24

.pass_loop:
    lea rdi, [rsp]
    xor eax, eax
    mov ecx, 256
    rep stosq

    xor r15d, r15d
.count_loop:
    cmp r15, rbx
    jae .select_bucket

    mov eax, [rsi + r15 * 4]
    cmp r13d, 24
    je .count_value
    mov ecx, r13d
    add ecx, 8
    mov edx, eax
    shr edx, cl
    cmp edx, r12d
    jne .count_next

.count_value:
    mov ecx, r13d
    mov edx, eax
    shr edx, cl
    and edx, 255
    inc qword [rsp + rdx * 8]

.count_next:
    inc r15
    jmp .count_loop

.select_bucket:
    xor r15d, r15d
.select_loop:
    mov rax, [rsp + r15 * 8]
    cmp r14, rax
    jb .bucket_found
    sub r14, rax
    inc r15d
    cmp r15d, 256
    jb .select_loop
    xor eax, eax
    jmp .done

.bucket_found:
    shl r12d, 8
    or r12d, r15d
    sub r13d, 8
    jns .pass_loop
    mov eax, r12d
    jmp .done

.zero:
    xor eax, eax

.done:
    add rsp, 2048
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rbx
    ret

; rax = signed numerator, rbx = positive denominator. rax = rounded quotient.
round_signed_div_ties_even:
    xor r10d, r10d
    test rax, rax
    jge .positive
    neg rax
    mov r10d, 1
.positive:
    xor edx, edx
    div rbx
    mov r11, rdx
    shl r11, 1
    cmp r11, rbx
    jb .apply_sign
    ja .round_up
    test al, 1
    jz .apply_sign
.round_up:
    inc rax
.apply_sign:
    test r10d, r10d
    jz .done
    neg rax
.done:
    ret

; rcx = assp_bpm_segment ptr, rdx = segment count, r8 = beat_milli.
; rax = active bpm_milli, or 0 when the map is empty/invalid.
assp_bpm_at_beat_milli:
    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero

    mov rax, [rcx + ASSP_BPM_SEGMENT_BPM_MILLI]
    xor r9d, r9d
.loop:
    cmp r9, rdx
    jae .done
    mov r10, r9
    shl r10, 4
    cmp [rcx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], r8
    jg .done
    mov rax, [rcx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r9
    jmp .loop
.zero:
    xor eax, eax
.done:
    ret

; rcx = assp_bpm_segment ptr, rdx = segment count, r8 = target beat_milli.
; rax = elapsed microseconds using only BPM changes.
assp_elapsed_us_bpm_only:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    xor edi, edi
    jmp assp_elapsed_bpm_only_common

; rcx = assp_bpm_segment ptr, rdx = segment count, r8 = target beat_milli.
; rax = elapsed milliseconds using only BPM changes.
assp_elapsed_ms_bpm_only:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov edi, 1

assp_elapsed_bpm_only_common:
    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .zero
    test r8, r8
    jle .zero

    mov rsi, rdx
    mov r15, r8
    xor eax, eax
    xor r12d, r12d
    mov r9d, 60000
    xor r10d, r10d

.loop:
    cmp r10, rsi
    jae .tail
    mov r11, r10
    shl r11, 4
    mov r13, [rcx + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp r13, 0
    jg .positive_beat
    mov r9, [rcx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r10
    jmp .loop

.positive_beat:
    cmp r13, r15
    jg .tail
    cmp r13, r12
    jle .set_change
    test r9, r9
    jle .set_change
    mov r14, r13
    sub r14, r12
    imul r14, r14, 60000000
    mov rbx, rax
    mov rax, r14
    cqo
    idiv r9
    add rax, rbx

.set_change:
    mov r12, r13
    mov r9, [rcx + r11 + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r10
    jmp .loop

.tail:
    cmp r15, r12
    jle .done
    test r9, r9
    jle .done
    mov r14, r15
    sub r14, r12
    imul r14, r14, 60000000
    mov rbx, rax
    mov rax, r14
    cqo
    idiv r9
    add rax, rbx
    jmp .done

.zero:
    xor eax, eax
    jmp .pop_done

.done:
    test edi, edi
    jz .pop_done

.to_millis:
    test rax, rax
    jle .pop_done
    add rax, 500
    xor edx, edx
    mov r9d, 1000
    div r9

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = BPM segments, rdx = BPM count, r8 = stop segments, r9 = stop count,
; stack arg 5 = delay segments, arg 6 = delay count, arg 7 = warp segments,
; arg 8 = warp count, arg 9 = target beat_milli.
; Stop and delay values are already microseconds.
; rax = elapsed microseconds using RSSP's BPM/stop/delay/warp event order.
assp_elapsed_us_with_events:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 128
    mov qword [rbp + EVT_RETURN_US], -1
    jmp assp_elapsed_events_common

; Stop and delay values are milliseconds.
; rax = elapsed milliseconds, rounded from microseconds.
assp_elapsed_ms_with_events:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 128
    mov qword [rbp + EVT_RETURN_US], 1000

assp_elapsed_events_common:
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov r13, [rbp + 48]
    mov r14, [rbp + 56]
    mov r15, [rbp + 64]
    mov rax, [rbp + 72]
    mov [rbp + EVT_WARP_LEN], rax
    mov rax, [rbp + 80]
    mov [rbp + EVT_TARGET], rax

    test rax, rax
    jle .zero
    test rsi, rsi
    jz .check_stops
    test rbx, rbx
    jz .zero
.check_stops:
    test r12, r12
    jz .check_delays
    test rdi, rdi
    jz .zero
.check_delays:
    test r14, r14
    jz .check_warps
    test r13, r13
    jz .zero
.check_warps:
    cmp qword [rbp + EVT_WARP_LEN], 0
    je .init
    test r15, r15
    jz .zero

.init:
    mov qword [rbp + EVT_TIME], 0
    mov qword [rbp + EVT_BEAT], 0
    mov qword [rbp + EVT_BPM], 60000
    mov qword [rbp + EVT_WARP_END], 0
    mov qword [rbp + EVT_I_BPM], 0
    mov qword [rbp + EVT_I_STOP], 0
    mov qword [rbp + EVT_I_DELAY], 0
    mov qword [rbp + EVT_I_WARP], 0

    test rsi, rsi
    jz .select_loop
    mov rax, [rbx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp rax, 0
    jg .select_loop
    mov rax, [rbx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rbp + EVT_BPM], rax

.select_loop:
    mov qword [rbp + EVT_BEST_TYPE], -1
    mov qword [rbp + EVT_BEST_PRI], 4

.check_bpm:
    mov rax, [rbp + EVT_I_BPM]
    cmp rax, rsi
    jae .check_stop
    mov rdx, rax
    shl rdx, 4
    mov r8, [rbx + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rbx + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    xor r10d, r10d
    xor r11d, r11d
    ASSP_CONSIDER_TIMING_EVENT

.check_stop:
    mov rax, [rbp + EVT_I_STOP]
    cmp rax, r12
    jae .check_delay
    mov rdx, rax
    shl rdx, 4
    mov r8, [rdi + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rdi + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 3
    mov r11d, 1
    ASSP_CONSIDER_TIMING_EVENT

.check_delay:
    mov rax, [rbp + EVT_I_DELAY]
    cmp rax, r14
    jae .check_warp
    mov rdx, rax
    shl rdx, 4
    mov r8, [r13 + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [r13 + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 1
    mov r11d, 2
    ASSP_CONSIDER_TIMING_EVENT

.check_warp:
    mov rax, [rbp + EVT_I_WARP]
    cmp rax, [rbp + EVT_WARP_LEN]
    jae .selected
    mov rdx, rax
    shl rdx, 4
    mov r8, [r15 + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [r15 + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 4
    mov r11d, 3
    ASSP_CONSIDER_TIMING_EVENT

.selected:
    cmp qword [rbp + EVT_BEST_TYPE], -1
    je .tail

    mov r8, [rbp + EVT_BEST_BEAT]
    mov rax, [rbp + EVT_TARGET]
    cmp r8, rax
    jl .advance_to_event
    jg .tail
    mov rax, [rbp + EVT_BEST_TYPE]
    cmp rax, 1
    je .tail
    cmp rax, 3
    je .tail
    jmp .advance_to_event

.advance_to_event:
    mov rax, [rbp + EVT_BEAT]
    cmp r8, rax
    jle .apply_event

    mov r10, rax
    mov r11, [rbp + EVT_WARP_END]
    cmp r10, r11
    jge .have_effective_beat
    mov r10, r11
.have_effective_beat:
    cmp r8, r10
    jle .store_event_beat
    mov r11, [rbp + EVT_BPM]
    test r11, r11
    jle .store_event_beat
    mov rax, r8
    sub rax, r10
    imul rax, rax, 60000000
    cqo
    idiv r11
    add [rbp + EVT_TIME], rax

.store_event_beat:
    mov [rbp + EVT_BEAT], r8

.apply_event:
    mov rax, [rbp + EVT_BEST_TYPE]
    test rax, rax
    jz .apply_bpm
    cmp rax, 1
    je .apply_stop
    cmp rax, 2
    je .apply_delay
    jmp .apply_warp

.apply_bpm:
    mov rax, [rbp + EVT_BEST_VAL]
    mov [rbp + EVT_BPM], rax
    inc qword [rbp + EVT_I_BPM]
    jmp .select_loop

.apply_stop:
    mov rax, [rbp + EVT_BEST_VAL]
    mov r10, [rbp + EVT_RETURN_US]
    test r10, r10
    jle .add_stop_time
    imul rax, r10
.add_stop_time:
    add [rbp + EVT_TIME], rax
    inc qword [rbp + EVT_I_STOP]
    jmp .select_loop

.apply_delay:
    mov rax, [rbp + EVT_BEST_VAL]
    mov r10, [rbp + EVT_RETURN_US]
    test r10, r10
    jle .add_delay_time
    imul rax, r10
.add_delay_time:
    add [rbp + EVT_TIME], rax
    inc qword [rbp + EVT_I_DELAY]
    jmp .select_loop

.apply_warp:
    mov rax, [rbp + EVT_BEST_BEAT]
    add rax, [rbp + EVT_BEST_VAL]
    cmp rax, [rbp + EVT_WARP_END]
    jle .warp_done
    mov [rbp + EVT_WARP_END], rax
.warp_done:
    inc qword [rbp + EVT_I_WARP]
    jmp .select_loop

.tail:
    mov r8, [rbp + EVT_TARGET]
    mov r10, [rbp + EVT_BEAT]
    mov r11, [rbp + EVT_WARP_END]
    cmp r10, r11
    jge .tail_have_effective
    mov r10, r11
.tail_have_effective:
    cmp r8, r10
    jle .done
    mov r11, [rbp + EVT_BPM]
    test r11, r11
    jle .done
    mov rax, r8
    sub rax, r10
    imul rax, rax, 60000000
    cqo
    idiv r11
    add [rbp + EVT_TIME], rax

.done:
    mov rax, [rbp + EVT_TIME]
    test rax, rax
    jle .pop_done
    cmp qword [rbp + EVT_RETURN_US], 0
    jl .pop_done
    add rax, 500
    xor edx, edx
    mov r9d, 1000
    div r9
    jmp .pop_done

.zero:
    xor eax, eax

.pop_done:
    add rsp, 128
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

; rcx = BPM segments, rdx = BPM count, r8 = stop segments, r9 = stop count,
; stack arg 5 = delay segments, arg 6 = delay count, arg 7 = warp segments,
; arg 8 = warp count, arg 9 = target beat_milli, arg 10 = offset_us.
; xmm0 = elapsed seconds using RSSP's f32 timing row event order.
assp_elapsed_seconds_f32_with_events:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 96

    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov r13, [rbp + 48]
    mov r14, [rbp + 56]
    mov r15, [rbp + 64]

    mov rax, [rbp + 80]
    test rsi, rsi
    jz .check_stops
    test rbx, rbx
    jz .zero
.check_stops:
    test r12, r12
    jz .check_delays
    test rdi, rdi
    jz .zero
.check_delays:
    test r14, r14
    jz .check_warps
    test r13, r13
    jz .zero
.check_warps:
    cmp qword [rbp + 72], 0
    je .init
    test r15, r15
    jz .zero

.init:
    cvtsi2ss xmm0, rax
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    mov [rbp + F32_TARGET_ROW], eax

    cvtsi2ss xmm0, qword [rbp + 88]
    divss xmm0, [rel nps_f32_million]
    xorps xmm1, xmm1
    subss xmm1, xmm0
    movss xmm0, xmm1
    movss [rbp + F32_TIME], xmm0
    mov dword [rbp + F32_LAST_ROW], 0
    mov dword [rbp + F32_WARP_DEST_ROW], 0
    mov dword [rbp + F32_IS_WARPING], 0
    mov qword [rbp + F32_BPM_IDX], 0
    mov qword [rbp + F32_STOP_IDX], 0
    mov qword [rbp + F32_DELAY_IDX], 0
    mov qword [rbp + F32_WARP_IDX], 0
    movss xmm0, [rel nps_f32_one]
    movss [rbp + F32_BPS], xmm0

.select_loop:
    mov dword [rbp + F32_BEST_ROW], 7fffffffh
    mov dword [rbp + F32_BEST_TYPE], -1

.check_warp_dest:
    cmp dword [rbp + F32_IS_WARPING], 0
    je .check_bpm
    mov eax, [rbp + F32_WARP_DEST_ROW]
    cmp eax, [rbp + F32_BEST_ROW]
    jge .check_bpm
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 5

.check_bpm:
    mov rax, [rbp + F32_BPM_IDX]
    cmp rax, rsi
    jae .check_delay
    mov r10, rax
    shl r10, 4
    mov r11, [rbx + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cvtsi2ss xmm0, r11
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    cmp eax, [rbp + F32_BEST_ROW]
    jge .check_delay
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 0

.check_delay:
    mov rax, [rbp + F32_DELAY_IDX]
    cmp rax, r14
    jae .check_marker
    mov r10, rax
    shl r10, 4
    mov r11, [r13 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cvtsi2ss xmm0, r11
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    cmp eax, [rbp + F32_BEST_ROW]
    jge .check_marker
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 1

.check_marker:
    mov eax, [rbp + F32_TARGET_ROW]
    cmp eax, [rbp + F32_BEST_ROW]
    jge .check_stop
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 2

.check_stop:
    mov rax, [rbp + F32_STOP_IDX]
    cmp rax, r12
    jae .check_warp
    mov r10, rax
    shl r10, 4
    mov r11, [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cvtsi2ss xmm0, r11
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    cmp eax, [rbp + F32_BEST_ROW]
    jge .check_warp
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 3

.check_warp:
    mov rax, [rbp + F32_WARP_IDX]
    cmp rax, [rbp + 72]
    jae .selected
    mov r10, rax
    shl r10, 4
    mov r11, [r15 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cvtsi2ss xmm0, r11
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    cmp eax, [rbp + F32_BEST_ROW]
    jge .selected
    mov [rbp + F32_BEST_ROW], eax
    mov dword [rbp + F32_BEST_TYPE], 4

.selected:
    cmp dword [rbp + F32_BEST_TYPE], -1
    je .done

    cmp dword [rbp + F32_IS_WARPING], 0
    jne .dt_done
    mov eax, [rbp + F32_BEST_ROW]
    sub eax, [rbp + F32_LAST_ROW]
    jle .dt_done
    cvtsi2ss xmm0, eax
    divss xmm0, [rel nps_f32_48]
    divss xmm0, [rbp + F32_BPS]
    addss xmm0, [rbp + F32_TIME]
    movss [rbp + F32_TIME], xmm0

.dt_done:
    mov eax, [rbp + F32_BEST_TYPE]
    cmp eax, 2
    je .done
    test eax, eax
    jz .apply_bpm
    cmp eax, 1
    je .apply_delay
    cmp eax, 3
    je .apply_stop
    cmp eax, 4
    je .apply_warp
    mov dword [rbp + F32_IS_WARPING], 0
    jmp .store_last_row

.apply_bpm:
    mov rax, [rbp + F32_BPM_IDX]
    mov r10, rax
    shl r10, 4
    mov r11, [rbx + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, r11
    divss xmm0, [rel nps_f32_1000]
    divss xmm0, [rel nps_f32_60]
    movss [rbp + F32_BPS], xmm0
    inc qword [rbp + F32_BPM_IDX]
    jmp .store_last_row

.apply_delay:
    mov rax, [rbp + F32_DELAY_IDX]
    mov r10, rax
    shl r10, 4
    mov r11, [r13 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, r11
    divss xmm0, [rel nps_f32_million]
    addss xmm0, [rbp + F32_TIME]
    movss [rbp + F32_TIME], xmm0
    inc qword [rbp + F32_DELAY_IDX]
    jmp .store_last_row

.apply_stop:
    mov rax, [rbp + F32_STOP_IDX]
    mov r10, rax
    shl r10, 4
    mov r11, [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, r11
    divss xmm0, [rel nps_f32_million]
    addss xmm0, [rbp + F32_TIME]
    movss [rbp + F32_TIME], xmm0
    inc qword [rbp + F32_STOP_IDX]
    jmp .store_last_row

.apply_warp:
    mov rax, [rbp + F32_WARP_IDX]
    mov r10, rax
    shl r10, 4
    mov r11, [r15 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    add r11, [r15 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cvtsi2ss xmm0, r11
    mulss xmm0, [rel nps_f32_48]
    divss xmm0, [rel nps_f32_1000]
    cvtss2si eax, xmm0
    cmp eax, [rbp + F32_WARP_DEST_ROW]
    jle .warp_dest_ready
    mov [rbp + F32_WARP_DEST_ROW], eax
.warp_dest_ready:
    mov dword [rbp + F32_IS_WARPING], 1
    inc qword [rbp + F32_WARP_IDX]

.store_last_row:
    mov eax, [rbp + F32_BEST_ROW]
    mov [rbp + F32_LAST_ROW], eax
    jmp .select_loop

.zero:
    xorps xmm0, xmm0
    jmp .pop_done

.done:
    movss xmm0, [rbp + F32_TIME]

.pop_done:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

; rcx = u32 densities, rdx = density len, r8 = assp_bpm_segment ptr,
; r9 = bpm len, stack arg 5 = optional u32 output, stack arg 6 = output cap.
; rax = density len, or ASSP_NOT_FOUND on invalid input.
assp_measure_nps_milli_from_bpms:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rbx, [rsp + 96]
    mov r12, [rsp + 104]
    sub rsp, 64

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

.check_bpms:
    test r9, r9
    jz .init
    test r8, r8
    jz .invalid

.init:
    mov rsi, rcx
    mov rdi, rdx
    mov r13, r8
    mov r14, r9
    xor r15d, r15d
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 60000
    mov qword [rsp + 32], 0

    test rbx, rbx
    jz .done
    cmp r14, 1
    jne .check_empty_bpms
    cmp qword [r13 + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    jle .single_bpm_init
.check_empty_bpms:
    test r14, r14
    jz .loop

.timed_init_loop:
    mov rax, [rsp + 32]
    cmp rax, r14
    jae .loop
    mov r10, rax
    shl r10, 4
    cmp qword [r13 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    jg .loop
    mov r11, [r13 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + 24], r11
    inc qword [rsp + 32]
    jmp .timed_init_loop

.single_bpm_init:
    mov r11, [r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    test r11, r11
    jle .zero_fill
    mov rax, 240000000000
    xor edx, edx
    div r11
    cmp rax, 120000
    jbe .zero_fill
    mov [rsp + 40], rax
    xor r15d, r15d

.single_loop:
    cmp r15, rdi
    jae .done

    xor eax, eax
    mov r11d, [rsi + r15 * 4]
    test r11d, r11d
    jz .single_store

    mov rax, r11
    imul rax, rax, 1000000000
    mov r10, [rsp + 40]
    mov r9, r10
    shr r9, 1
    add rax, r9
    xor edx, edx
    div r10

.single_store:
    cmp r15, r12
    jae .single_next
    mov [rbx + r15 * 4], eax

.single_next:
    inc r15
    jmp .single_loop

.zero_fill:
    xor r15d, r15d

.zero_fill_loop:
    cmp r15, rdi
    jae .done
    cmp r15, r12
    jae .zero_fill_next
    mov dword [rbx + r15 * 4], 0

.zero_fill_next:
    inc r15
    jmp .zero_fill_loop

.loop:
    cmp r15, rdi
    jae .done

    xor eax, eax
    test r14, r14
    jz .store
    mov rax, r15
    inc rax
    imul r8, rax, 4000

.timed_advance_loop:
    mov rax, [rsp + 32]
    cmp rax, r14
    jae .timed_tail
    mov rdx, rax
    shl rdx, 4
    mov r9, [r13 + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp r9, r8
    jg .timed_tail

    mov r10, [rsp + 16]
    cmp r9, r10
    jle .timed_set_event
    mov r11, [rsp + 24]
    test r11, r11
    jle .timed_set_event
    mov rax, r9
    sub rax, r10
    imul rax, rax, 60000000
    xor edx, edx
    div r11
    add [rsp + 8], rax

.timed_set_event:
    mov [rsp + 16], r9
    mov rax, [rsp + 32]
    shl rax, 4
    mov rax, [r13 + rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + 24], rax
    inc qword [rsp + 32]
    jmp .timed_advance_loop

.timed_tail:
    mov rax, [rsp + 8]
    mov r10, [rsp + 16]
    cmp r8, r10
    jle .timed_have_end
    mov r11, [rsp + 24]
    test r11, r11
    jle .timed_update_beat
    mov rax, r8
    sub rax, r10
    imul rax, rax, 60000000
    xor edx, edx
    div r11
    add rax, [rsp + 8]
    mov [rsp + 8], rax

.timed_update_beat:
    mov [rsp + 16], r8
    mov rax, [rsp + 8]

.timed_have_end:
    mov r10, rax
    sub r10, [rsp]
    mov [rsp], rax
    cmp r10, 120000
    jg .timed_check_density
    xor eax, eax
    jmp .store

.timed_check_density:
    mov r11d, [rsi + r15 * 4]
    test r11d, r11d
    jnz .timed_calc_nps
    xor eax, eax
    jmp .store

.timed_calc_nps:
    mov rax, r11
    imul rax, rax, 1000000000
    mov r9, r10
    shr r9, 1
    add rax, r9
    xor edx, edx
    div r10
    jmp .store

.zero_nps:
    xor eax, eax

.store:
    test rbx, rbx
    jz .next
    cmp r15, r12
    jae .next
    mov [rbx + r15 * 4], eax

.next:
    inc r15
    jmp .loop

.empty:
    xor eax, eax
    jmp .pop_done

.done:
    mov rax, rdi
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = u32 densities, rdx = density len, r8 = assp_bpm_segment ptr,
; r9 = bpm len. rax = peak NPS in thousandths, or ASSP_NOT_FOUND.
assp_nps_peak_milli_from_bpms:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .empty
    test r8, r8
    jz .invalid

    mov rbx, rcx
    mov rdi, rdx
    mov rsi, r8
    mov r12, r9
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d

    cmp r12, 1
    je .single_bpm_init
    mov r8, [rsi + ASSP_BPM_SEGMENT_BPM_MILLI]

.multi_loop:
    cmp r13, rdi
    jae .done

    xor eax, eax
    mov r11d, [rbx + r13 * 4]
    test r11d, r11d
    jz .multi_next

    mov r10, r13
    imul r10, r10, 4000
.multi_bpm_loop:
    cmp r15, r12
    jae .multi_got_bpm
    mov rdx, r15
    shl rdx, 4
    cmp [rsi + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI], r10
    jg .multi_got_bpm
    mov r8, [rsi + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    inc r15
    jmp .multi_bpm_loop

.multi_got_bpm:
    mov rax, r8
    test rax, rax
    jle .multi_next
    cmp rax, 10000000
    jge .multi_next
    imul rax, r11
    add rax, 120
    xor edx, edx
    mov r10d, 240
    div r10
    cmp rax, r14
    jbe .multi_next
    mov r14, rax

.multi_next:
    inc r13
    jmp .multi_loop

.single_bpm_init:
    mov rax, [rsi + ASSP_BPM_SEGMENT_BPM_MILLI]
    test rax, rax
    jle .empty
    cvtsi2ss xmm5, rax
    divss xmm5, [rel nps_f32_60000]

.single_loop:
    cmp r13, rdi
    jae .done

    mov r11d, [rbx + r13 * 4]
    test r11d, r11d
    jz .single_next

    mov rax, r13
    imul rax, rax, 192
    cvtsi2ss xmm0, rax
    divss xmm0, [rel nps_f32_48]
    divss xmm0, xmm5
    cvtss2sd xmm0, xmm0

    mov rax, r13
    inc rax
    imul rax, rax, 192
    cvtsi2ss xmm1, rax
    divss xmm1, [rel nps_f32_48]
    divss xmm1, xmm5
    cvtss2sd xmm1, xmm1
    subsd xmm1, xmm0
    comisd xmm1, [rel nps_f64_0_12]
    jbe .single_next

    cvtsi2sd xmm2, r11
    divsd xmm2, xmm1
    mulsd xmm2, [rel nps_f64_1000]
    cvtsd2si rax, xmm2
    cmp rax, r14
    jbe .single_next
    mov r14, rax

.single_next:
    inc r13
    jmp .single_loop

.empty:
    xor eax, eax
    jmp .pop_done

.done:
    mov rax, r14
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = u32 densities, rdx = density len, r8 = BPM segments, r9 = BPM count,
; stack arg 5 = stop segments, arg 6 = stop count, arg 7 = delay segments,
; arg 8 = delay count, arg 9 = warp segments, arg 10 = warp count,
; arg 11 = optional u32 output, arg 12 = output cap.
; rax = density len, or ASSP_NOT_FOUND on invalid input.
assp_measure_nps_milli_with_events:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 264

    mov [rbp + NPS_DENSITIES], rcx
    mov [rbp + NPS_DENSITY_LEN], rdx
    mov [rbp + NPS_BPMS], r8
    mov [rbp + NPS_BPM_LEN], r9
    mov rax, [rbp + 48]
    mov [rbp + NPS_STOPS], rax
    mov rax, [rbp + 56]
    mov [rbp + NPS_STOP_LEN], rax
    mov rax, [rbp + 64]
    mov [rbp + NPS_DELAYS], rax
    mov rax, [rbp + 72]
    mov [rbp + NPS_DELAY_LEN], rax
    mov rax, [rbp + 80]
    mov [rbp + NPS_WARPS], rax
    mov rax, [rbp + 88]
    mov [rbp + NPS_WARP_LEN], rax
    mov rax, [rbp + 96]
    mov [rbp + NPS_OUT], rax
    mov rax, [rbp + 104]
    mov [rbp + NPS_OUT_CAP], rax

    cmp qword [rbp + NPS_DENSITY_LEN], 0
    je .empty
    cmp qword [rbp + NPS_DENSITIES], 0
    je .invalid
    cmp qword [rbp + NPS_BPM_LEN], 0
    je .check_stops
    cmp qword [rbp + NPS_BPMS], 0
    je .invalid
.check_stops:
    cmp qword [rbp + NPS_STOP_LEN], 0
    je .check_delays
    cmp qword [rbp + NPS_STOPS], 0
    je .invalid
.check_delays:
    cmp qword [rbp + NPS_DELAY_LEN], 0
    je .check_warps
    cmp qword [rbp + NPS_DELAYS], 0
    je .invalid
.check_warps:
    cmp qword [rbp + NPS_WARP_LEN], 0
    je .check_output
    cmp qword [rbp + NPS_WARPS], 0
    je .invalid
.check_output:
    cmp qword [rbp + NPS_OUT], 0
    je .done

.init:
    mov qword [rbp + NPS_INDEX], 0
    mov qword [rbp + NPS_START_MS], 0
    mov qword [rbp + NPS_EVT_TIME], 0
    mov qword [rbp + NPS_EVT_BEAT], 0
    mov qword [rbp + NPS_EVT_BPM], 60000
    mov qword [rbp + NPS_EVT_WARP_END], 0
    mov qword [rbp + NPS_EVT_I_BPM], 0
    mov qword [rbp + NPS_EVT_I_STOP], 0
    mov qword [rbp + NPS_EVT_I_DELAY], 0
    mov qword [rbp + NPS_EVT_I_WARP], 0

    cmp qword [rbp + NPS_BPM_LEN], 0
    je .loop
    mov rbx, [rbp + NPS_BPMS]
    mov rax, [rbx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp rax, 0
    jg .loop
    mov rax, [rbx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rbp + NPS_EVT_BPM], rax

.loop:
    mov r15, [rbp + NPS_INDEX]
    cmp r15, [rbp + NPS_DENSITY_LEN]
    jae .done

    mov rax, r15
    inc rax
    imul rax, rax, 4000
    mov [rbp + NPS_EVT_TARGET], rax
    jmp .event_select_loop

.event_select_loop:
    mov qword [rbp + NPS_EVT_BEST_TYPE], -1
    mov qword [rbp + NPS_EVT_BEST_PRI], 4

.event_check_bpm:
    mov rax, [rbp + NPS_EVT_I_BPM]
    cmp rax, [rbp + NPS_BPM_LEN]
    jae .event_check_stop
    mov rbx, [rbp + NPS_BPMS]
    mov rdx, rax
    shl rdx, 4
    mov r8, [rbx + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rbx + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    xor r10d, r10d
    xor r11d, r11d
    ASSP_NPS_CONSIDER_TIMING_EVENT

.event_check_stop:
    mov rax, [rbp + NPS_EVT_I_STOP]
    cmp rax, [rbp + NPS_STOP_LEN]
    jae .event_check_delay
    mov rbx, [rbp + NPS_STOPS]
    mov rdx, rax
    shl rdx, 4
    mov r8, [rbx + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rbx + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 3
    mov r11d, 1
    ASSP_NPS_CONSIDER_TIMING_EVENT

.event_check_delay:
    mov rax, [rbp + NPS_EVT_I_DELAY]
    cmp rax, [rbp + NPS_DELAY_LEN]
    jae .event_check_warp
    mov rbx, [rbp + NPS_DELAYS]
    mov rdx, rax
    shl rdx, 4
    mov r8, [rbx + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rbx + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 1
    mov r11d, 2
    ASSP_NPS_CONSIDER_TIMING_EVENT

.event_check_warp:
    mov rax, [rbp + NPS_EVT_I_WARP]
    cmp rax, [rbp + NPS_WARP_LEN]
    jae .event_selected
    mov rbx, [rbp + NPS_WARPS]
    mov rdx, rax
    shl rdx, 4
    mov r8, [rbx + rdx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov r9, [rbx + rdx + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov r10d, 4
    mov r11d, 3
    ASSP_NPS_CONSIDER_TIMING_EVENT

.event_selected:
    cmp qword [rbp + NPS_EVT_BEST_TYPE], -1
    je .event_tail

    mov r8, [rbp + NPS_EVT_BEST_BEAT]
    mov rax, [rbp + NPS_EVT_TARGET]
    cmp r8, rax
    jl .event_advance_to_event
    jg .event_tail
    mov rax, [rbp + NPS_EVT_BEST_TYPE]
    cmp rax, 1
    je .event_tail
    cmp rax, 3
    je .event_tail
    jmp .event_advance_to_event

.event_advance_to_event:
    mov rax, [rbp + NPS_EVT_BEAT]
    cmp r8, rax
    jle .event_apply

    mov r10, rax
    mov r11, [rbp + NPS_EVT_WARP_END]
    cmp r10, r11
    jge .event_have_effective_beat
    mov r10, r11
.event_have_effective_beat:
    cmp r8, r10
    jle .event_store_beat
    mov r11, [rbp + NPS_EVT_BPM]
    test r11, r11
    jle .event_store_beat
    mov rax, r8
    sub rax, r10
    imul rax, rax, 60000000
    cqo
    idiv r11
    add [rbp + NPS_EVT_TIME], rax

.event_store_beat:
    mov [rbp + NPS_EVT_BEAT], r8

.event_apply:
    mov rax, [rbp + NPS_EVT_BEST_TYPE]
    test rax, rax
    jz .event_apply_bpm
    cmp rax, 1
    je .event_apply_stop
    cmp rax, 2
    je .event_apply_delay
    jmp .event_apply_warp

.event_apply_bpm:
    mov rax, [rbp + NPS_EVT_BEST_VAL]
    mov [rbp + NPS_EVT_BPM], rax
    inc qword [rbp + NPS_EVT_I_BPM]
    jmp .event_select_loop

.event_apply_stop:
    mov rax, [rbp + NPS_EVT_BEST_VAL]
    imul rax, 1000
    add [rbp + NPS_EVT_TIME], rax
    inc qword [rbp + NPS_EVT_I_STOP]
    jmp .event_select_loop

.event_apply_delay:
    mov rax, [rbp + NPS_EVT_BEST_VAL]
    imul rax, 1000
    add [rbp + NPS_EVT_TIME], rax
    inc qword [rbp + NPS_EVT_I_DELAY]
    jmp .event_select_loop

.event_apply_warp:
    mov rax, [rbp + NPS_EVT_BEST_BEAT]
    add rax, [rbp + NPS_EVT_BEST_VAL]
    cmp rax, [rbp + NPS_EVT_WARP_END]
    jle .event_warp_done
    mov [rbp + NPS_EVT_WARP_END], rax
.event_warp_done:
    inc qword [rbp + NPS_EVT_I_WARP]
    jmp .event_select_loop

.event_tail:
    mov r8, [rbp + NPS_EVT_TARGET]
    mov r10, [rbp + NPS_EVT_BEAT]
    mov r11, [rbp + NPS_EVT_WARP_END]
    cmp r10, r11
    jge .event_tail_have_effective
    mov r10, r11
.event_tail_have_effective:
    cmp r8, r10
    jle .event_store_target_beat
    mov r11, [rbp + NPS_EVT_BPM]
    test r11, r11
    jle .event_store_target_beat
    mov rax, r8
    sub rax, r10
    imul rax, rax, 60000000
    cqo
    idiv r11
    add [rbp + NPS_EVT_TIME], rax

.event_store_target_beat:
    mov rax, [rbp + NPS_EVT_TARGET]
    mov [rbp + NPS_EVT_BEAT], rax
    mov rax, [rbp + NPS_EVT_TIME]
    test rax, rax
    jle .event_zero
    add rax, 500
    xor edx, edx
    mov r9d, 1000
    div r9
    jmp .event_elapsed_done

.event_zero:
    xor eax, eax

.event_elapsed_done:
    mov [rbp + NPS_END_MS], rax

    xor eax, eax
    mov rsi, [rbp + NPS_DENSITIES]
    mov r11d, [rsi + r15 * 4]
    test r11d, r11d
    jz .store

    mov r12, [rbp + NPS_END_MS]
    sub r12, [rbp + NPS_START_MS]
    cmp r12, 120
    jle .store

    mov rax, r11
    imul rax, rax, 1000000
    mov r10, r12
    shr r10, 1
    add rax, r10
    xor edx, edx
    div r12

.store:
    mov rbx, [rbp + NPS_OUT]
    test rbx, rbx
    jz .next
    cmp r15, [rbp + NPS_OUT_CAP]
    jae .next
    mov [rbx + r15 * 4], eax

.next:
    mov rax, [rbp + NPS_END_MS]
    mov [rbp + NPS_START_MS], rax
    inc qword [rbp + NPS_INDEX]
    jmp .loop

.empty:
    xor eax, eax
    jmp .pop_done

.done:
    mov rax, [rbp + NPS_DENSITY_LEN]
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 264
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

section .rdata
align 8
nps_f32_48 dd 48.0
nps_f32_60 dd 60.0
nps_f32_1000 dd 1000.0
nps_f32_60000 dd 60000.0
nps_f32_million dd 1000000.0
nps_f32_one dd 1.0
nps_f64_0_12 dq 0.12
nps_f64_1000 dq 1000.0
nps_f64_1000000 dq 1000000.0
bpm_dec3_frac_scale dq 1000, 100, 10, 1
bpm_dec6_frac_scale dq 1000000, 100000, 10000, 1000, 100, 10, 1
align 16
bpm_frac3_emit:
%assign i 0
%rep 1000
    db '.', '0' + (i / 100), '0' + ((i / 10) % 10), '0' + (i % 10)
%assign i i+1
%endrep

section .text

; rcx = number start, rdx = number end.
; rax = absolute thousandths, edx = negative flag. ASSP_NOT_FOUND on parse failure.
parse_dec3:
    push rsi
    push rdi
    push r12
    push r13

    mov rsi, rcx
    mov rdi, rdx

.trim_left:
    cmp rsi, rdi
    jae .fail
    cmp byte [rsi], ' '
    ja .trim_right
    inc rsi
    jmp .trim_left

.trim_right:
    cmp rdi, rsi
    jbe .fail
    cmp byte [rdi - 1], ' '
    ja .sign
    dec rdi
    jmp .trim_right

.sign:
    xor r13d, r13d
    cmp byte [rsi], '+'
    je .plus
    cmp byte [rsi], '-'
    jne .int_init
    mov r13d, ASSP_TRUE
.plus:
    inc rsi
    cmp rsi, rdi
    jae .fail

.int_init:
    xor r8d, r8d
    xor r9d, r9d

.int_loop:
    cmp rsi, rdi
    jae .finish_number
    movzx eax, byte [rsi]
    cmp al, 8
    je .int_skip_backspace
    cmp al, '0'
    jb .check_dot
    cmp al, '9'
    ja .finish_number
    sub eax, '0'
    imul r8, r8, 10
    add r8, rax
    inc r9
    inc rsi
    jmp .int_loop

.int_skip_backspace:
    inc rsi
    jmp .int_loop

.check_dot:
    cmp al, '.'
    jne .finish_number
    inc rsi
    xor r10d, r10d
    xor r11d, r11d
    xor r12d, r12d
    jmp .frac_loop

.frac_loop:
    cmp rsi, rdi
    jae .finish_frac
    movzx eax, byte [rsi]
    cmp al, 8
    je .frac_skip_backspace
    cmp al, '0'
    jb .finish_frac
    cmp al, '9'
    ja .finish_frac
    sub eax, '0'
    inc r9
    cmp r10d, 3
    jae .round_digit
    imul r11, r11, 10
    add r11, rax
    inc r10d
    inc rsi
    jmp .frac_loop

.round_digit:
    cmp r10d, 3
    jne .extra_digit
    mov r12d, eax
    inc r10d
    inc rsi
    jmp .frac_loop

.extra_digit:
    test eax, eax
    jz .extra_next
    or r10d, 0x80000000
.extra_next:
    inc rsi
    jmp .frac_loop

.frac_skip_backspace:
    inc rsi
    jmp .frac_loop

.finish_frac:
    mov ecx, r10d
    and ecx, 0x7fffffff
    mov eax, 3
    cmp ecx, eax
    cmova ecx, eax
    lea rdx, [rel bpm_dec3_frac_scale]
    imul r11, qword [rdx + rcx * 8]
    jmp .trailing

.finish_number:
    xor r11d, r11d
    xor r12d, r12d
    xor r10d, r10d

.trailing:
    cmp rsi, rdi
    jae .finish_scaled
    cmp byte [rsi], ' '
    ja .fail
    inc rsi
    jmp .trailing

.finish_scaled:
    test r9, r9
    jz .fail

    imul r8, r8, 1000
    add r8, r11

    test r13d, r13d
    jnz .negative_round
    cmp r12d, 5
    jb .store
    inc r8
    jmp .store

.negative_round:
    cmp r12d, 5
    ja .round_negative
    jne .store
    test r8, r8
    jz .round_negative
    test r10d, 0x80000000
    jz .store
.round_negative:
    inc r8

.store:
    mov rax, r8
    mov edx, r13d
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    ret

; rax = absolute thousandths, edx = negative flag.
; Uses rdi/r13/r14 as the output state. CF = overflow.
emit_scaled3:
    push rbx
    push rsi
    sub rsp, 40

    mov rbx, rax
    test edx, edx
    jz .split
    test rbx, rbx
    jz .split
    mov al, '-'
    call emit_byte
    jc .done

.split:
    mov rax, rbx
    xor edx, edx
    mov r8d, 1000
    div r8
    mov rbx, rax
    mov rsi, rdx

    test rbx, rbx
    jnz .int_digits
    mov al, '0'
    call emit_byte
    jc .done
    jmp .frac

.int_digits:
    lea r10, [rsp + 32]
    mov r11, r10
.int_loop:
    xor edx, edx
    mov rax, rbx
    mov r8d, 10
    div r8
    add dl, '0'
    dec r10
    mov [r10], dl
    mov rbx, rax
    test rbx, rbx
    jnz .int_loop

.emit_int:
    cmp r10, r11
    jae .frac
    mov al, [r10]
    call emit_byte
    jc .done
    inc r10
    jmp .emit_int

.frac:
    test rdi, rdi
    jz .frac_count
    mov rax, r14
    add rax, 4
    cmp rax, r13
    ja .overflow
    lea r10, [rel bpm_frac3_emit]
    mov eax, [r10 + rsi * 4]
    mov [rdi + r14], eax
    add r14, 4
    clc
    jmp .done

.frac_count:
    add r14, 4
    clc
    jmp .done

.overflow:
    stc

.done:
    lea rsp, [rsp + 40]
    pop rsi
    pop rbx
    ret

; al = byte. Uses rdi/r13/r14 as the output state. CF = overflow.
emit_byte:
    test rdi, rdi
    jz .count
    cmp r14, r13
    jae .overflow
    mov [rdi + r14], al
.count:
    inc r14
    clc
    ret
.overflow:
    stc
    ret

; rcx = BPM map bytes, rdx = len, r8 = optional assp_bpm_segment output,
; r9 = output cap. rax = parsed segment count, or ASSP_NOT_FOUND.
; Values are signed thousandths. Invalid comma entries are skipped.
assp_parse_bpm_map:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov rsi, rcx
    lea r12, [rcx + rdx]
    mov rdi, r8
    mov r13, r9
    xor r14d, r14d
    mov qword [rsp + 56], 0
    mov qword [rsp + 64], 0

.entry_loop:
    cmp rsi, r12
    jae .sort

    mov qword [rsp + 8], 0
    mov r10, rsi

.scan_entry:
    cmp r10, r12
    jae .entry_scanned
    mov al, [r10]
    cmp al, ','
    je .entry_scanned
    cmp al, '='
    jne .scan_entry_next
    cmp qword [rsp + 8], 0
    jne .scan_entry_next
    mov [rsp + 8], r10
.scan_entry_next:
    inc r10
    jmp .scan_entry

.entry_scanned:
    mov [rsp], r10
    cmp qword [rsp + 8], 0
    je .skip_entry
    mov rbx, rsi
    mov r11, r10

.trim_left:
    cmp rbx, r11
    jae .skip_entry
    cmp byte [rbx], ' '
    ja .trim_right
    inc rbx
    jmp .trim_left

.trim_right:
    cmp r11, rbx
    jbe .skip_entry
    cmp byte [r11 - 1], ' '
    ja .parse_beat
    dec r11
    jmp .trim_right

.parse_beat:
    mov rax, [rsp + 8]
    mov [rsp + 16], r11
    mov rdx, rax
    xor r15d, r15d

.trim_beat_right:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .check_row_suffix
    dec rdx
    jmp .trim_beat_right

.check_row_suffix:
    cmp byte [rdx - 1], 'r'
    je .row_suffix
    cmp byte [rdx - 1], 'R'
    jne .parse_beat_value
.row_suffix:
    mov r15d, ASSP_TRUE
    dec rdx
.trim_before_suffix:
    cmp rdx, rbx
    jbe .skip_entry
    cmp byte [rdx - 1], ' '
    ja .parse_beat_value
    dec rdx
    jmp .trim_before_suffix

.parse_beat_value:
    mov rcx, rbx
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .beat_positive
    neg rax
.beat_positive:
    test r15d, r15d
    jz .store_beat
    cqo
    mov r10d, 48
    idiv r10
.store_beat:
    mov [rsp + 24], rax

    mov rcx, [rsp + 8]
    inc rcx
    mov rdx, [rsp + 16]
    call parse_dec3
    cmp rax, ASSP_NOT_FOUND
    je .skip_entry
    test edx, edx
    jz .store_bpm
    neg rax
.store_bpm:
    mov [rsp + 32], rax

    test rdi, rdi
    jz .inc_count
    cmp r14, r13
    jae .inc_count
    mov r10, r14
    shl r10, 4
    mov rax, [rsp + 24]
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 32]
    mov [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI], rax

    mov rax, [rsp + 24]
    test r14, r14
    jz .store_last_beat
    cmp rax, [rsp + 56]
    jge .store_last_beat
    mov qword [rsp + 64], 1
.store_last_beat:
    mov [rsp + 56], rax

.inc_count:
    inc r14

.skip_entry:
    mov rsi, [rsp]
    cmp rsi, r12
    jae .sort
    inc rsi
    jmp .entry_loop

.empty:
    xor r14d, r14d

.sort:
    test rdi, rdi
    jz .done
    cmp r14, 2
    jb .done
    cmp r14, r13
    ja .done
    cmp qword [rsp + 64], 0
    je .done

    mov r8d, 1
.sort_outer:
    cmp r8, r14
    jae .done
    mov r10, r8
    shl r10, 4
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    mov [rsp + 40], rax
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + 48], rax
    mov r9, r8

.sort_inner:
    test r9, r9
    jz .sort_place
    mov r10, r9
    dec r10
    shl r10, 4
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp rax, [rsp + 40]
    jle .sort_place

    mov r11, r9
    shl r11, 4
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rdi + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], rax
    dec r9
    jmp .sort_inner

.sort_place:
    mov r11, r9
    shl r11, 4
    mov rax, [rsp + 40]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BEAT_MILLI], rax
    mov rax, [rsp + 48]
    mov [rdi + r11 + ASSP_BPM_SEGMENT_BPM_MILLI], rax
    inc r8
    jmp .sort_outer

.done:
    mov rax, r14
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
