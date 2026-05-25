default rel
%include "assp.inc"

global assp_count_note_stats_4
global assp_count_note_stats_8
global assp_count_mines_nonfake_4
global assp_count_mines_nonfake_8
global assp_count_timing_fakes_4
global assp_count_timing_fakes_8
global assp_count_timing_note_stats_4
global assp_count_timing_note_stats_8
global assp_count_timing_note_stats_no_holds_4
global assp_count_timing_note_stats_no_holds_8

extern assp_minimize_measure_4
extern assp_minimize_measure_8

section .text

; base slot, measure-index slot, row-count slot.
%macro init_beat_walk 3
    mov rax, [rsp + %2]
    imul rax, 4000
    mov [rsp + %1], rax
    mov eax, 4000
    xor edx, edx
    div qword [rsp + %3]
    mov [rsp + %1 + 8], rax
    mov [rsp + %1 + 16], rdx
    mov qword [rsp + %1 + 24], 0
%endmacro

; base slot, row-count slot.
%macro advance_beat_walk 2
    mov rax, [rsp + %1 + 8]
    add [rsp + %1], rax
    mov rax, [rsp + %1 + 24]
    add rax, [rsp + %1 + 16]
    cmp rax, [rsp + %2]
    jb %%store_err
    sub rax, [rsp + %2]
    inc qword [rsp + %1]
%%store_err:
    mov [rsp + %1 + 24], rax
%endmacro

%macro bump_arrow 1
    inc qword [rbx + ASSP_NOTE_STATS_ARROWS]
    inc qword [rbx + %1]
    inc r13d
%endmacro

%macro mark_phantom_if_active 1
    cmp qword [rsp + %1], 0
    je %%done
    mov qword [rsp + 16], 1
%%done:
%endmacro

%macro count_lane 3
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%tap
    cmp al, '2'
    je %%hold
    cmp al, '4'
    je %%roll
    cmp al, '3'
    je %%end
    cmp al, 'M'
    je %%mine_upper
    cmp al, 'm'
    je %%mine
    cmp al, 'L'
    je %%lift_upper
    cmp al, 'l'
    je %%lift
    cmp al, 'F'
    je %%fake_upper
    cmp al, 'f'
    je %%fake
    jmp %%done

%%tap:
    mark_phantom_if_active %3
    bump_arrow %2
    jmp %%done

%%hold:
    inc qword [rsp + %3]
    inc qword [rsp]
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_HOLDS]
    inc r14d
    jmp %%done

%%roll:
    inc qword [rsp + %3]
    inc qword [rsp]
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_ROLLS]
    inc r14d
    jmp %%done

%%end:
    inc qword [rsp + 8]
    cmp qword [rsp + %3], 0
    je %%end_active
    dec qword [rsp + %3]
%%end_active:
    inc r15d
    jmp %%done

%%mine_upper:
    inc r11d
    mark_phantom_if_active %3
    inc qword [rbx + ASSP_NOTE_STATS_MINES]
    jmp %%done

%%mine:
    inc r11d
    inc qword [rbx + ASSP_NOTE_STATS_MINES]
    jmp %%done

%%lift_upper:
    mark_phantom_if_active %3
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_LIFTS]
    jmp %%done

%%lift:
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_LIFTS]
    jmp %%done

%%fake_upper:
    inc r11d
    mark_phantom_if_active %3
    inc qword [rbx + ASSP_NOTE_STATS_FAKES]
    jmp %%done

%%fake:
    inc r11d
    inc qword [rbx + ASSP_NOTE_STATS_FAKES]

%%done:
%endmacro

%macro bump_masked_arrow 1
    inc r13d
    inc qword [rbx + ASSP_NOTE_STATS_ARROWS]
    inc qword [rbx + %1]
%endmacro

%macro count_masked_lane 2
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%tap
    cmp al, '2'
    je %%hold
    cmp al, '4'
    je %%roll
    cmp al, '3'
    je %%end
    cmp al, 'M'
    je %%mine
    cmp al, 'm'
    je %%mine
    cmp al, 'L'
    je %%lift
    cmp al, 'l'
    je %%lift
    cmp al, 'F'
    je %%fake
    cmp al, 'f'
    je %%fake
    jmp %%done

%%tap:
    bump_masked_arrow %2
    jmp %%done

%%hold:
    mov ecx, %1
    call hold_start_has_end
    test eax, eax
    jz %%done
    bump_masked_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_HOLDS]
    inc r14d
    jmp %%done

%%roll:
    mov ecx, %1
    call hold_start_has_end
    test eax, eax
    jz %%done
    bump_masked_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_ROLLS]
    inc r14d
    jmp %%done

%%end:
    inc r15d
    jmp %%done

%%mine:
    inc r11d
    inc qword [rbx + ASSP_NOTE_STATS_MINES]
    jmp %%done

%%lift:
    bump_masked_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_LIFTS]
    jmp %%done

%%fake:
    inc r11d
    inc qword [rbx + ASSP_NOTE_STATS_FAKES]

%%done:
%endmacro

%macro invalid_lane_break 2
    mov al, [rsi + %1]
    cmp al, 10
    je %2
    cmp al, 13
    je %2
    cmp al, ','
    je %2
    cmp al, ';'
    je %2
%endmacro

; rcx = note-data bytes, rdx = byte length, r8 = out assp_note_stats.
; eax = 1 on success, 0 on invalid pointers.
assp_count_note_stats_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64

    test r8, r8
    jz .fail
    test rdx, rdx
    jz .zero_only
    test rcx, rcx
    jz .fail

.zero_only:
    mov rbx, r8
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx

.zero:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero

    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d

.line_loop:
    cmp rsi, rdi
    jae .success

.trim_line:
    cmp rsi, rdi
    jae .success
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    je .trim_advance
    cmp al, 13
    je .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_line

.line_start:
    cmp al, 10
    je .consume_one
    cmp al, ','
    je .skip_line
    cmp al, ';'
    je .success
    cmp al, '/'
    je .skip_line

    lea rax, [rsi + 4]
    cmp rax, rdi
    ja .malformed_row

    cmp dword [rsi], 30303030h
    je .zero_row
    test r12d, r12d
    jnz .full_row
    mov eax, [rsi]
    mov r10d, eax
    and r10d, 0fefefefeh
    cmp r10d, 30303030h
    je .tap_only_row

.full_row:
    invalid_lane_break 0, .malformed_row
    invalid_lane_break 1, .malformed_row
    invalid_lane_break 2, .malformed_row
    invalid_lane_break 3, .malformed_row

    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    xor r11d, r11d

    count_lane 0, ASSP_NOTE_STATS_LEFT, 24
    count_lane 1, ASSP_NOTE_STATS_DOWN, 32
    count_lane 2, ASSP_NOTE_STATS_UP, 40
    count_lane 3, ASSP_NOTE_STATS_RIGHT, 48

    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    test r13d, r13d
    jz .row_no_step

    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r13d, 2
    jb .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.check_hand:
    mov eax, r12d
    add eax, r13d
    cmp eax, 3
    jb .update_active
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]

.update_active:
    mov eax, r12d
    add eax, r14d
    sub eax, r15d
    jns .store_active
    xor eax, eax

.store_active:
    mov r12d, eax
    jmp .skip_line

.row_no_step:
    test r11d, r11d
    jz .row_no_step_update
    cmp r12d, 3
    jb .row_no_step_update
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.row_no_step_update:
    mov eax, r12d
    sub eax, r15d
    jns .store_empty_active
    xor eax, eax

.store_empty_active:
    mov r12d, eax
    jmp .skip_line

.zero_row:
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    jmp .skip_line

.malformed_row:
    inc qword [rbx + ASSP_NOTE_STATS_MALFORMED_ROWS]
    jmp .skip_line

.tap_only_row:
    xor eax, 30303030h
    mov r10d, eax
    and r10d, 1
    mov r11d, eax
    shr r11d, 7
    and r11d, 2
    or r10d, r11d
    mov r11d, eax
    shr r11d, 14
    and r11d, 4
    or r10d, r11d
    mov r11d, eax
    shr r11d, 21
    and r11d, 8
    or r10d, r11d

    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    inc qword [rbx + ASSP_NOTE_STATS_STEPS]

    test r10b, 1
    jz .tap_only_down
    inc qword [rbx + ASSP_NOTE_STATS_LEFT]
.tap_only_down:
    test r10b, 2
    jz .tap_only_up
    inc qword [rbx + ASSP_NOTE_STATS_DOWN]
.tap_only_up:
    test r10b, 4
    jz .tap_only_right
    inc qword [rbx + ASSP_NOTE_STATS_UP]
.tap_only_right:
    test r10b, 8
    jz .tap_only_count
    inc qword [rbx + ASSP_NOTE_STATS_RIGHT]

.tap_only_count:
    lea r11, [rel note_stats_popcount4]
    movzx eax, byte [r11 + r10]
    add qword [rbx + ASSP_NOTE_STATS_ARROWS], rax
    cmp eax, 2
    jb .tap_only_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.tap_only_hand:
    mov r11d, r12d
    add r11d, eax
    cmp r11d, 3
    jb .tap_only_phantom_check
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]

.tap_only_phantom_check:
    jmp .skip_line

.consume_one:
    inc rsi
    jmp .line_loop

.skip_line:
    cmp rsi, rdi
    jae .success
    mov al, [rsi]
    inc rsi
    cmp al, 10
    jne .skip_line
    jmp .line_loop

.success:
    mov rax, [rsp]
    test rax, rax
    jz .success_true
    cmp rax, [rsp + 8]
    jne .recount_without_phantoms
    cmp qword [rsp + 16], 0
    jne .recount_without_phantoms
    mov rax, [rsp + 24]
    or rax, [rsp + 32]
    or rax, [rsp + 40]
    or rax, [rsp + 48]
    jnz .recount_without_phantoms

.success_true:
    mov eax, ASSP_TRUE
    jmp .done

.recount_without_phantoms:
    mov rax, [rbx + ASSP_NOTE_STATS_STEPS]
    mov [rsp + 56], rax

    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.recount_zero:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .recount_zero

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d

.recount_line_loop:
    cmp rsi, rdi
    jae .recount_success

.recount_trim_line:
    cmp rsi, rdi
    jae .recount_success
    mov al, [rsi]
    cmp al, ' '
    je .recount_trim_advance
    cmp al, 9
    je .recount_trim_advance
    cmp al, 13
    je .recount_trim_advance
    jmp .recount_line_start

.recount_trim_advance:
    inc rsi
    jmp .recount_trim_line

.recount_line_start:
    cmp al, 10
    je .recount_consume_one
    cmp al, ','
    je .recount_skip_line
    cmp al, ';'
    je .recount_success
    cmp al, '/'
    je .recount_skip_line

    lea rax, [rsi + 4]
    cmp rax, rdi
    ja .recount_malformed_row

    cmp dword [rsi], 30303030h
    je .recount_zero_row
    invalid_lane_break 0, .recount_malformed_row
    invalid_lane_break 1, .recount_malformed_row
    invalid_lane_break 2, .recount_malformed_row
    invalid_lane_break 3, .recount_malformed_row

    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    xor r11d, r11d

    count_masked_lane 0, ASSP_NOTE_STATS_LEFT
    count_masked_lane 1, ASSP_NOTE_STATS_DOWN
    count_masked_lane 2, ASSP_NOTE_STATS_UP
    count_masked_lane 3, ASSP_NOTE_STATS_RIGHT

    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    test r13d, r13d
    jz .recount_row_no_step

    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r13d, 2
    jb .recount_check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.recount_check_hand:
    mov eax, r12d
    add eax, r13d
    cmp eax, 3
    jb .recount_update_active
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]

.recount_update_active:
    mov eax, r12d
    add eax, r14d
    sub eax, r15d
    jns .recount_store_active
    xor eax, eax

.recount_store_active:
    mov r12d, eax
    jmp .recount_skip_line

.recount_row_no_step:
    test r11d, r11d
    jz .recount_row_no_step_update
    cmp r12d, 3
    jb .recount_row_no_step_update
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.recount_row_no_step_update:
    mov eax, r12d
    sub eax, r15d
    jns .recount_store_empty_active
    xor eax, eax

.recount_store_empty_active:
    mov r12d, eax
    jmp .recount_skip_line

.recount_zero_row:
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    jmp .recount_skip_line

.recount_malformed_row:
    inc qword [rbx + ASSP_NOTE_STATS_MALFORMED_ROWS]
    jmp .recount_skip_line

.recount_consume_one:
    inc rsi
    jmp .recount_line_loop

.recount_skip_line:
    cmp rsi, rdi
    jae .recount_success
    mov al, [rsi]
    inc rsi
    cmp al, 10
    jne .recount_skip_line
    jmp .recount_line_loop

.recount_success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
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

; rcx = note-data bytes, rdx = byte length, r8 = out assp_note_stats.
; eax = 1 on success, 0 on invalid pointers.
assp_count_note_stats_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 96

    test r8, r8
    jz .fail
    test rdx, rdx
    jz .zero_only
    test rcx, rcx
    jz .fail

.zero_only:
    mov rbx, r8
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx

.zero:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero

    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], 0
    mov qword [rsp + 88], 0

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d

.line_loop:
    cmp rsi, rdi
    jae .success

.trim_line:
    cmp rsi, rdi
    jae .success
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    je .trim_advance
    cmp al, 13
    je .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_line

.line_start:
    cmp al, 10
    je .consume_one
    cmp al, ','
    je .skip_line
    cmp al, ';'
    je .success
    cmp al, '/'
    je .skip_line

    lea rax, [rsi + 8]
    cmp rax, rdi
    ja .malformed_row

    cmp dword [rsi], 30303030h
    jne .not_zero_row
    cmp dword [rsi + 4], 30303030h
    je .zero_row
.not_zero_row:
    invalid_lane_break 0, .malformed_row
    invalid_lane_break 1, .malformed_row
    invalid_lane_break 2, .malformed_row
    invalid_lane_break 3, .malformed_row
    invalid_lane_break 4, .malformed_row
    invalid_lane_break 5, .malformed_row
    invalid_lane_break 6, .malformed_row
    invalid_lane_break 7, .malformed_row

    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    xor r11d, r11d

    count_lane 0, ASSP_NOTE_STATS_LEFT, 24
    count_lane 1, ASSP_NOTE_STATS_DOWN, 32
    count_lane 2, ASSP_NOTE_STATS_UP, 40
    count_lane 3, ASSP_NOTE_STATS_RIGHT, 48
    count_lane 4, ASSP_NOTE_STATS_LEFT, 56
    count_lane 5, ASSP_NOTE_STATS_DOWN, 64
    count_lane 6, ASSP_NOTE_STATS_UP, 72
    count_lane 7, ASSP_NOTE_STATS_RIGHT, 80

    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    test r13d, r13d
    jz .row_no_step

    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r13d, 2
    jb .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.check_hand:
    mov eax, r12d
    add eax, r13d
    cmp eax, 3
    jb .update_active
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]

.update_active:
    mov eax, r12d
    add eax, r14d
    sub eax, r15d
    jns .store_active
    xor eax, eax

.store_active:
    mov r12d, eax
    jmp .skip_line

.row_no_step:
    test r11d, r11d
    jz .row_no_step_update
    cmp r12d, 3
    jb .row_no_step_update
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.row_no_step_update:
    mov eax, r12d
    sub eax, r15d
    jns .store_empty_active
    xor eax, eax

.store_empty_active:
    mov r12d, eax
    jmp .skip_line

.zero_row:
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    jmp .skip_line

.malformed_row:
    inc qword [rbx + ASSP_NOTE_STATS_MALFORMED_ROWS]
    jmp .skip_line

.consume_one:
    inc rsi
    jmp .line_loop

.skip_line:
    cmp rsi, rdi
    jae .success
    mov al, [rsi]
    inc rsi
    cmp al, 10
    jne .skip_line
    jmp .line_loop

.success:
    mov rax, [rsp]
    test rax, rax
    jz .success_true
    cmp rax, [rsp + 8]
    jne .recount_without_phantoms
    cmp qword [rsp + 16], 0
    jne .recount_without_phantoms
    mov rax, [rsp + 24]
    or rax, [rsp + 32]
    or rax, [rsp + 40]
    or rax, [rsp + 48]
    or rax, [rsp + 56]
    or rax, [rsp + 64]
    or rax, [rsp + 72]
    or rax, [rsp + 80]
    jnz .recount_without_phantoms

.success_true:
    mov eax, ASSP_TRUE
    jmp .done

.recount_without_phantoms:
    mov rax, [rbx + ASSP_NOTE_STATS_STEPS]
    mov [rsp + 88], rax

    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.recount_zero:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .recount_zero

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d

.recount_line_loop:
    cmp rsi, rdi
    jae .recount_success

.recount_trim_line:
    cmp rsi, rdi
    jae .recount_success
    mov al, [rsi]
    cmp al, ' '
    je .recount_trim_advance
    cmp al, 9
    je .recount_trim_advance
    cmp al, 13
    je .recount_trim_advance
    jmp .recount_line_start

.recount_trim_advance:
    inc rsi
    jmp .recount_trim_line

.recount_line_start:
    cmp al, 10
    je .recount_consume_one
    cmp al, ','
    je .recount_skip_line
    cmp al, ';'
    je .recount_success
    cmp al, '/'
    je .recount_skip_line

    lea rax, [rsi + 8]
    cmp rax, rdi
    ja .recount_malformed_row

    cmp dword [rsi], 30303030h
    jne .recount_not_zero_row
    cmp dword [rsi + 4], 30303030h
    je .recount_zero_row
.recount_not_zero_row:
    invalid_lane_break 0, .recount_malformed_row
    invalid_lane_break 1, .recount_malformed_row
    invalid_lane_break 2, .recount_malformed_row
    invalid_lane_break 3, .recount_malformed_row
    invalid_lane_break 4, .recount_malformed_row
    invalid_lane_break 5, .recount_malformed_row
    invalid_lane_break 6, .recount_malformed_row
    invalid_lane_break 7, .recount_malformed_row

    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    xor r11d, r11d

    count_masked_lane 0, ASSP_NOTE_STATS_LEFT
    count_masked_lane 1, ASSP_NOTE_STATS_DOWN
    count_masked_lane 2, ASSP_NOTE_STATS_UP
    count_masked_lane 3, ASSP_NOTE_STATS_RIGHT
    count_masked_lane 4, ASSP_NOTE_STATS_LEFT
    count_masked_lane 5, ASSP_NOTE_STATS_DOWN
    count_masked_lane 6, ASSP_NOTE_STATS_UP
    count_masked_lane 7, ASSP_NOTE_STATS_RIGHT

    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    test r13d, r13d
    jz .recount_row_no_step

    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r13d, 2
    jb .recount_check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.recount_check_hand:
    mov eax, r12d
    add eax, r13d
    cmp eax, 3
    jb .recount_update_active
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]

.recount_update_active:
    mov eax, r12d
    add eax, r14d
    sub eax, r15d
    jns .recount_store_active
    xor eax, eax

.recount_store_active:
    mov r12d, eax
    jmp .recount_skip_line

.recount_row_no_step:
    test r11d, r11d
    jz .recount_row_no_step_update
    cmp r12d, 3
    jb .recount_row_no_step_update
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.recount_row_no_step_update:
    mov eax, r12d
    sub eax, r15d
    jns .recount_store_empty_active
    xor eax, eax

.recount_store_empty_active:
    mov r12d, eax
    jmp .recount_skip_line

.recount_zero_row:
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]
    jmp .recount_skip_line

.recount_malformed_row:
    inc qword [rbx + ASSP_NOTE_STATS_MALFORMED_ROWS]
    jmp .recount_skip_line

.recount_consume_one:
    inc rsi
    jmp .recount_line_loop

.recount_skip_line:
    cmp rsi, rdi
    jae .recount_success
    mov al, [rsi]
    inc rsi
    cmp al, 10
    jne .recount_skip_line
    jmp .recount_line_loop

.recount_success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rsi = current row start, rdi = data end, ecx = lane offset.
; eax = 1 when this hold/roll start is matched by a future end.
hold_start_has_end:
    mov r8, rsi
.current_line_end:
    cmp r8, rdi
    jae .no
    mov al, [r8]
    inc r8
    cmp al, 10
    jne .current_line_end

    mov r9d, 1
.line_loop:
    cmp r8, rdi
    jae .no

    mov r10, r8
    mov r11, r8
.find_line_end:
    cmp r11, rdi
    jae .line_end_found
    cmp byte [r11], 10
    je .line_end_found
    inc r11
    jmp .find_line_end

.line_end_found:
    mov r8, r11
    cmp r8, rdi
    jae .trim_line
    inc r8

.trim_line:
    cmp r10, r11
    jae .line_loop
    mov al, [r10]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    je .trim_advance
    cmp al, 13
    je .trim_advance
    jmp .line_start

.trim_advance:
    inc r10
    jmp .trim_line

.line_start:
    mov al, [r10]
    cmp al, '/'
    je .line_loop
    cmp al, ','
    je .line_loop
    cmp al, ';'
    je .no

    mov rdx, r10
    add rdx, rcx
    cmp rdx, r11
    jae .line_loop

    mov al, [rdx]
    cmp al, '1'
    je .no
    cmp al, 'M'
    je .no
    cmp al, 'L'
    je .no
    cmp al, 'F'
    je .no
    cmp al, '2'
    je .push
    cmp al, '4'
    je .push
    cmp al, '3'
    je .pop
    jmp .line_loop

.push:
    cmp r9d, 8
    jae .line_loop
    inc r9d
    jmp .line_loop

.pop:
    test r9d, r9d
    jz .line_loop
    dec r9d
    jz .yes
    jmp .line_loop

.yes:
    mov eax, ASSP_TRUE
    ret

.no:
    xor eax, eax
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = row scratch,
; arg 8 = scratch row cap. rax = nonfake mine count, or ASSP_NOT_FOUND.
assp_count_mines_nonfake_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r13, [rsp + 96]
    mov r14, [rsp + 104]
    mov r15, [rsp + 112]
    mov r12, [rsp + 120]
    sub rsp, 64

    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r13
    mov [rsp + 56], r14
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .success
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r14, r14
    jz .check_scratch_ptr
    test r13, r13
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 4]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov ecx, [rsi]
    mov [r15 + rax * 4], ecx
    inc qword [rsp]
    jmp .line_done

.comma:
    call mines_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid
    inc qword [rsp + 16]
    jmp .line_done

.semi:
    call mines_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call mines_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid

.success:
    mov rax, [rsp + 8]
    jmp .done

.invalid:
    mov rax, ASSP_NOT_FOUND

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

mines_finalize_measure:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_4

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 64, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear
    mov eax, [r15 + r13 * 4]
    call row_has_mine
    test eax, eax
    jz .next

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range
    test eax, eax
    jnz .next
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range
    test eax, eax
    jnz .next
    inc qword [rsp + 56]

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 72], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

row_has_mine:
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp al, 'F'
    je .yes
    cmp al, 'f'
    je .yes
    cmp ah, 'M'
    je .yes
    cmp ah, 'm'
    je .yes
    cmp ah, 'F'
    je .yes
    cmp ah, 'f'
    je .yes
    shr eax, 16
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp al, 'F'
    je .yes
    cmp al, 'f'
    je .yes
    cmp ah, 'M'
    je .yes
    cmp ah, 'm'
    je .yes
    cmp ah, 'F'
    je .yes
    cmp ah, 'f'
    je .yes
    xor eax, eax
    ret
.yes:
    mov eax, ASSP_TRUE
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = row scratch,
; arg 8 = scratch row cap. rax = nonfake mine count, or ASSP_NOT_FOUND.
assp_count_mines_nonfake_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r13, [rsp + 96]
    mov r14, [rsp + 104]
    mov r15, [rsp + 112]
    mov r12, [rsp + 120]
    sub rsp, 64

    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r13
    mov [rsp + 56], r14
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .success
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r14, r14
    jz .check_scratch_ptr
    test r13, r13
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 8]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov rcx, [rsi]
    mov [r15 + rax * 8], rcx
    inc qword [rsp]
    jmp .line_done

.comma:
    call mines_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid
    inc qword [rsp + 16]
    jmp .line_done

.semi:
    call mines_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call mines_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid

.success:
    mov rax, [rsp + 8]
    jmp .done

.invalid:
    mov rax, ASSP_NOT_FOUND

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

mines_finalize_measure_8:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_8

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 64, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear
    mov rax, [r15 + r13 * 8]
    call row_has_mine_8
    test eax, eax
    jz .next

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range
    test eax, eax
    jnz .next
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range
    test eax, eax
    jnz .next
    inc qword [rsp + 56]

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 72], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

row_has_mine_8:
    mov rdx, rax
    mov ecx, 8
.loop:
    mov al, dl
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp al, 'F'
    je .yes
    cmp al, 'f'
    je .yes
    shr rdx, 8
    dec ecx
    jnz .loop
    xor eax, eax
    ret
.yes:
    mov eax, ASSP_TRUE
    ret

; rcx = segments, rdx = count, r8 = beat_milli. eax = 1 when beat is in range.
beat_in_timing_range:
    test rdx, rdx
    jz .no
    test rcx, rcx
    jz .no
    mov r10, rcx
    mov rcx, r8
    call note_stats_milli_to_row48_f32_even
    mov r8, rax
    cvtsi2ss xmm2, rax
    divss xmm2, [rel note_stats_const_48_f32]
    xor r9d, r9d
    mov r11, -1
.loop:
    cmp r9, rdx
    jae .check_candidate
    mov rax, r9
    shl rax, 4
    mov rcx, [r10 + rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call note_stats_milli_to_row48_f32_even
    cmp r8, rax
    jl .check_candidate
    mov r11, r9
.next:
    inc r9
    jmp .loop

.check_candidate:
    cmp r11, -1
    je .no
    mov rax, r11
    shl rax, 4
    mov rcx, [r10 + rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    test rcx, rcx
    jle .no
    add rcx, [r10 + rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel note_stats_const_thousand_f32]
    ucomiss xmm2, xmm0
    jb .yes
    jmp .no
.yes:
    mov eax, ASSP_TRUE
    ret
.no:
    xor eax, eax
    ret

; rcx = segments, rdx = count, r8 = beat_milli. eax = 1 when beat is in a
; row-sized timing range. Used for ITGmania-style timing note filtering.
beat_in_timing_range_rows:
    test rdx, rdx
    jz .no
    test rcx, rcx
    jz .no
    mov r10, rcx
    mov rcx, r8
    call note_stats_milli_to_row48_f32_even
    mov r8, rax
    xor r9d, r9d
.loop:
    cmp r9, rdx
    jae .no
    mov rax, r9
    shl rax, 4
    mov rcx, [r10 + rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    test rcx, rcx
    jle .next
    call note_stats_milli_to_row48_f32_even
    test rax, rax
    jle .next
    mov r11, rax
    mov rax, r9
    shl rax, 4
    mov rcx, [r10 + rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    call note_stats_milli_to_row48_f32_even
    cmp r8, rax
    jl .next
    add rax, r11
    cmp r8, rax
    jl .yes
.next:
    inc r9
    jmp .loop
.yes:
    mov eax, ASSP_TRUE
    ret
.no:
    xor eax, eax
    ret

note_stats_milli_to_row48_f32_even:
    cvtsi2ss xmm0, rcx
    divss xmm0, [rel note_stats_const_thousand_f32]
    mulss xmm0, [rel note_stats_const_48_f32]
    cvtss2si rax, xmm0
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = row scratch,
; arg 8 = scratch row cap. rax = timing-aware fake object count, or ASSP_NOT_FOUND.
assp_count_timing_fakes_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r13, [rsp + 96]
    mov r14, [rsp + 104]
    mov r15, [rsp + 112]
    mov r12, [rsp + 120]
    sub rsp, 64

    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r13
    mov [rsp + 56], r14
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .success
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r14, r14
    jz .check_scratch_ptr
    test r13, r13
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 4]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov ecx, [rsi]
    mov [r15 + rax * 4], ecx
    inc qword [rsp]
    jmp .line_done

.comma:
    call timing_fakes_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid
    inc qword [rsp + 16]
    jmp .line_done

.semi:
    call timing_fakes_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call timing_fakes_finalize_measure
    cmp qword [rsp + 24], 0
    jne .invalid

.success:
    mov rax, [rsp + 8]
    jmp .done

.invalid:
    mov rax, ASSP_NOT_FOUND

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

timing_fakes_finalize_measure:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_4

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 64, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range
    test eax, eax
    jnz .nonjudgable
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range
    test eax, eax
    jnz .nonjudgable

    mov eax, [r15 + r13 * 4]
    call row_literal_fake_count
    add qword [rsp + 56], rax
    jmp .next

.nonjudgable:
    mov eax, [r15 + r13 * 4]
    call row_fake_object_count
    add qword [rsp + 56], rax

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 72], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

row_literal_fake_count:
    xor ecx, ecx
    cmp al, 'F'
    je .lane0
    cmp al, 'f'
    jne .check1
.lane0:
    inc ecx
.check1:
    cmp ah, 'F'
    je .lane1
    cmp ah, 'f'
    jne .check2
.lane1:
    inc ecx
.check2:
    shr eax, 16
    cmp al, 'F'
    je .lane2
    cmp al, 'f'
    jne .check3
.lane2:
    inc ecx
.check3:
    cmp ah, 'F'
    je .lane3
    cmp ah, 'f'
    jne .done
.lane3:
    inc ecx
.done:
    mov eax, ecx
    ret

row_fake_object_count:
    xor ecx, ecx
    call fake_object_lane_low
    cmp ah, '1'
    je .lane1
    cmp ah, '2'
    je .lane1
    cmp ah, '4'
    je .lane1
    cmp ah, 'M'
    je .lane1
    cmp ah, 'm'
    je .lane1
    cmp ah, 'L'
    je .lane1
    cmp ah, 'l'
    je .lane1
    cmp ah, 'F'
    je .lane1
    cmp ah, 'f'
    jne .upper
.lane1:
    inc ecx
.upper:
    shr eax, 16
    call fake_object_lane_low
    cmp ah, '1'
    je .lane3
    cmp ah, '2'
    je .lane3
    cmp ah, '4'
    je .lane3
    cmp ah, 'M'
    je .lane3
    cmp ah, 'm'
    je .lane3
    cmp ah, 'L'
    je .lane3
    cmp ah, 'l'
    je .lane3
    cmp ah, 'F'
    je .lane3
    cmp ah, 'f'
    jne .done
.lane3:
    inc ecx
.done:
    mov eax, ecx
    ret

fake_object_lane_low:
    cmp al, '1'
    je .yes
    cmp al, '2'
    je .yes
    cmp al, '4'
    je .yes
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp al, 'L'
    je .yes
    cmp al, 'l'
    je .yes
    cmp al, 'F'
    je .yes
    cmp al, 'f'
    jne .no
.yes:
    inc ecx
.no:
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = row scratch,
; arg 8 = scratch row cap. rax = timing-aware fake object count, or ASSP_NOT_FOUND.
assp_count_timing_fakes_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r13, [rsp + 96]
    mov r14, [rsp + 104]
    mov r15, [rsp + 112]
    mov r12, [rsp + 120]
    sub rsp, 64

    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r13
    mov [rsp + 56], r14
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .success
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r14, r14
    jz .check_scratch_ptr
    test r13, r13
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 8]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov rcx, [rsi]
    mov [r15 + rax * 8], rcx
    inc qword [rsp]
    jmp .line_done

.comma:
    call timing_fakes_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid
    inc qword [rsp + 16]
    jmp .line_done

.semi:
    call timing_fakes_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call timing_fakes_finalize_measure_8
    cmp qword [rsp + 24], 0
    jne .invalid

.success:
    mov rax, [rsp + 8]
    jmp .done

.invalid:
    mov rax, ASSP_NOT_FOUND

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

timing_fakes_finalize_measure_8:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_8

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 64, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range
    test eax, eax
    jnz .nonjudgable
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range
    test eax, eax
    jnz .nonjudgable

    mov rax, [r15 + r13 * 8]
    call row_literal_fake_count_8
    add qword [rsp + 56], rax
    jmp .next

.nonjudgable:
    mov rax, [r15 + r13 * 8]
    call row_fake_object_count_8
    add qword [rsp + 56], rax

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 72], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

row_literal_fake_count_8:
    mov rdx, rax
    xor ecx, ecx
    mov r8d, 8
.loop:
    mov al, dl
    cmp al, 'F'
    je .count
    cmp al, 'f'
    jne .next
.count:
    inc ecx
.next:
    shr rdx, 8
    dec r8d
    jnz .loop
    mov eax, ecx
    ret

row_fake_object_count_8:
    mov rdx, rax
    xor ecx, ecx
    mov r8d, 8
.loop:
    mov al, dl
    cmp al, '1'
    je .count
    cmp al, '2'
    je .count
    cmp al, '4'
    je .count
    cmp al, 'M'
    je .count
    cmp al, 'm'
    je .count
    cmp al, 'L'
    je .count
    cmp al, 'l'
    je .count
    cmp al, 'F'
    je .count
    cmp al, 'f'
    jne .next
.count:
    inc ecx
.next:
    shr rdx, 8
    dec r8d
    jnz .loop
    mov eax, ecx
    ret

%define TS4_RAW_COUNT 0
%define TS4_MEASURE_INDEX 8
%define TS4_TOTAL_ROWS 16
%define TS4_ROW_CAP 24
%define TS4_RAW_BASE 32
%define TS4_ROWS_BASE 40
%define TS4_BEATS_BASE 48
%define TS4_TEXT_BASE 56
%define TS4_FAKE_PTR 64
%define TS4_FAKE_COUNT 72
%define TS4_WARP_PTR 80
%define TS4_WARP_COUNT 88
%define TS4_OUT 96
%define TS4_STATUS 104
%define TS4_CURRENT_ROW 112
%define TS4_MIN_COUNT 120
%define TS4_DEPTHS 128
%define TS4_LIFTS 136
%define TS4_BEAT_WALK 144

%macro timing_stats_4_finalize_measure 0
    cmp qword [rsp + TS4_RAW_COUNT], 0
    je %%clear

    mov rcx, [rsp + TS4_RAW_BASE]
    mov rdx, [rsp + TS4_RAW_COUNT]
    mov r8, rcx
    mov r9, [rsp + TS4_ROW_CAP]
    call assp_minimize_measure_4

    cmp rax, [rsp + TS4_ROW_CAP]
    ja %%invalid
    test rax, rax
    jz %%clear

    mov [rsp + TS4_MIN_COUNT], rax
    init_beat_walk TS4_BEAT_WALK, TS4_MEASURE_INDEX, TS4_MIN_COUNT
    xor r13d, r13d
%%append_loop:
    cmp r13, [rsp + TS4_MIN_COUNT]
    jae %%clear

    mov r10, [rsp + TS4_TOTAL_ROWS]
    cmp r10, [rsp + TS4_ROW_CAP]
    jae %%invalid

    mov r11, [rsp + TS4_RAW_BASE]
    mov ecx, [r11 + r13 * 4]
    mov r11, [rsp + TS4_ROWS_BASE]
    mov [r11 + r10 * 4], ecx

    mov r11, [rsp + TS4_BEATS_BASE]
    mov rax, [rsp + TS4_BEAT_WALK]
    mov [r11 + r10 * 8], rax

    inc qword [rsp + TS4_TOTAL_ROWS]
    advance_beat_walk TS4_BEAT_WALK, TS4_MIN_COUNT
    inc r13
    jmp %%append_loop

%%invalid:
    mov qword [rsp + TS4_STATUS], ASSP_NOT_FOUND

%%clear:
    mov qword [rsp + TS4_RAW_COUNT], 0
%endmacro

%macro timing_filter_judgable_lane_4 2
    mov eax, [rsp + TS4_CURRENT_ROW]
    shr eax, %2
    and eax, 0xff
    cmp al, '2'
    je %%hold_start
    cmp al, '4'
    je %%hold_start
    cmp al, '3'
    je %%end
    cmp al, 'L'
    je %%lift
    cmp al, 'l'
    je %%lift
    jmp %%store

%%lift:
    inc qword [rsp + TS4_LIFTS]
    mov eax, '1'
    jmp %%store

%%hold_start:
    mov rcx, [rsp + TS4_ROWS_BASE]
    mov rdx, [rsp + TS4_TOTAL_ROWS]
    mov r8, r12
    mov r9d, %1
    call timing_hold_start_has_end_4
    test eax, eax
    jnz %%reload
    mov eax, '0'
    jmp %%store

%%reload:
    inc byte [rsp + TS4_DEPTHS + %1]
    mov eax, [rsp + TS4_CURRENT_ROW]
    shr eax, %2
    and eax, 0xff
    jmp %%store

%%end:
    cmp byte [rsp + TS4_DEPTHS + %1], 0
    je %%zero
    dec byte [rsp + TS4_DEPTHS + %1]
    mov eax, '3'
    jmp %%store

%%zero:
    mov eax, '0'

%%store:
    shl eax, %2
    or r13d, eax
%endmacro

%macro timing_filter_fake_lane_4 2
    mov eax, [rsp + TS4_CURRENT_ROW]
    shr eax, %2
    and eax, 0xff
    cmp al, '1'
    je %%fake
    cmp al, 'M'
    je %%fake
    cmp al, 'm'
    je %%fake
    cmp al, 'L'
    je %%fake
    cmp al, 'l'
    je %%fake
    cmp al, 'F'
    je %%fake
    cmp al, 'f'
    je %%fake
    cmp al, '2'
    je %%hold_start
    cmp al, '4'
    je %%hold_start
    cmp al, '3'
    je %%end
    jmp %%done

%%hold_start:
    mov rcx, [rsp + TS4_ROWS_BASE]
    mov rdx, [rsp + TS4_TOTAL_ROWS]
    mov r8, r12
    mov r9d, %1
    call timing_hold_start_has_end_4
    test eax, eax
    jnz %%fake
    jmp %%done

%%end:
    cmp byte [rsp + TS4_DEPTHS + %1], 0
    je %%done
    dec byte [rsp + TS4_DEPTHS + %1]
    mov eax, '3'
    shl eax, %2
    or r13d, eax
    jmp %%done

%%fake:
    mov eax, 'F'
    shl eax, %2
    or r13d, eax

%%done:
%endmacro

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = out stats,
; arg 8 = byte scratch, arg 9 = scratch byte cap. eax = 1 on success.
assp_count_timing_note_stats_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    mov r13, [rsp + 112]
    mov r15, [rsp + 120]
    mov r12, [rsp + 128]
    sub rsp, 176

    mov [rsp + TS4_OUT], r13
    mov [rsp + TS4_WARP_PTR], r8
    mov [rsp + TS4_WARP_COUNT], r9
    mov [rsp + TS4_FAKE_PTR], r10
    mov [rsp + TS4_FAKE_COUNT], r11
    mov qword [rsp + TS4_RAW_COUNT], 0
    mov qword [rsp + TS4_MEASURE_INDEX], 0
    mov qword [rsp + TS4_TOTAL_ROWS], 0
    mov qword [rsp + TS4_STATUS], 0

    test r13, r13
    jz .invalid
    test rdx, rdx
    jz .zero_out
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r11, r11
    jz .check_scratch_ptr
    test r10, r10
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

.zero_out:
    mov rbx, [rsp + TS4_OUT]
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.zero_loop:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero_loop

    test rdx, rdx
    jz .success

    mov rsi, rcx
    lea rdi, [rcx + rdx]

    mov rax, r12
    xor edx, edx
    mov r10d, 24
    div r10
    test rax, rax
    jz .invalid
    mov [rsp + TS4_ROW_CAP], rax

    mov [rsp + TS4_RAW_BASE], r15
    lea r10, [r15 + rax * 4]
    mov [rsp + TS4_ROWS_BASE], r10
    lea r11, [r10 + rax * 4]
    mov [rsp + TS4_BEATS_BASE], r11
    lea r10, [r11 + rax * 8]
    mov [rsp + TS4_TEXT_BASE], r10

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 4]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp + TS4_RAW_COUNT]
    cmp rax, [rsp + TS4_ROW_CAP]
    jae .invalid
    mov r10, [rsp + TS4_RAW_BASE]
    mov ecx, [rsi]
    mov [r10 + rax * 4], ecx
    inc qword [rsp + TS4_RAW_COUNT]
    jmp .line_done

.comma:
    timing_stats_4_finalize_measure
    cmp qword [rsp + TS4_STATUS], 0
    jne .invalid
    inc qword [rsp + TS4_MEASURE_INDEX]
    jmp .line_done

.semi:
    timing_stats_4_finalize_measure
    cmp qword [rsp + TS4_STATUS], 0
    jne .invalid
    jmp .transform_rows

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    timing_stats_4_finalize_measure
    cmp qword [rsp + TS4_STATUS], 0
    jne .invalid

.transform_rows:
    cmp qword [rsp + TS4_TOTAL_ROWS], 0
    je .success

    mov dword [rsp + TS4_DEPTHS], 0
    mov qword [rsp + TS4_LIFTS], 0
    xor r12d, r12d
.transform_loop:
    cmp r12, [rsp + TS4_TOTAL_ROWS]
    jae .count_filtered

    mov r10, [rsp + TS4_ROWS_BASE]
    mov eax, [r10 + r12 * 4]
    mov [rsp + TS4_CURRENT_ROW], eax

    mov r10, [rsp + TS4_BEATS_BASE]
    mov r8, [r10 + r12 * 8]
    mov rcx, [rsp + TS4_WARP_PTR]
    mov rdx, [rsp + TS4_WARP_COUNT]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable_row
    mov r10, [rsp + TS4_BEATS_BASE]
    mov r8, [r10 + r12 * 8]
    mov rcx, [rsp + TS4_FAKE_PTR]
    mov rdx, [rsp + TS4_FAKE_COUNT]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable_row

    xor r13d, r13d
    timing_filter_judgable_lane_4 0, 0
    timing_filter_judgable_lane_4 1, 8
    timing_filter_judgable_lane_4 2, 16
    timing_filter_judgable_lane_4 3, 24
    mov eax, r13d
    jmp .write_row

.nonjudgable_row:
    xor r13d, r13d
    timing_filter_fake_lane_4 0, 0
    timing_filter_fake_lane_4 1, 8
    timing_filter_fake_lane_4 2, 16
    timing_filter_fake_lane_4 3, 24
    mov eax, r13d

.write_row:
    mov r10, [rsp + TS4_TEXT_BASE]
    mov r11, r12
    imul r11, 5
    mov [r10 + r11], eax
    mov byte [r10 + r11 + 4], 10
    inc r12
    jmp .transform_loop

.count_filtered:
    mov rcx, [rsp + TS4_TEXT_BASE]
    mov rax, [rsp + TS4_TOTAL_ROWS]
    lea rdx, [rax + rax * 4]
    mov r8, [rsp + TS4_OUT]
    call assp_count_note_stats_4
    test eax, eax
    jz .invalid
    mov r8, [rsp + TS4_OUT]
    mov rax, [rsp + TS4_LIFTS]
    add [r8 + ASSP_NOTE_STATS_LIFTS], rax

.success:
    mov eax, ASSP_TRUE
    jmp .done

.invalid:
    xor eax, eax

.done:
    add rsp, 176
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = packed 4-lane rows, rdx = row count, r8 = start row, r9 = lane offset.
; eax = 1 when the hold or roll start has a future matching end.
timing_hold_start_has_end_4:
    mov r10, r8
    inc r10
    mov r11d, 1
.loop:
    cmp r10, rdx
    jae .no
    lea rax, [rcx + r10 * 4]
    mov al, [rax + r9]
    cmp al, '1'
    je .no
    cmp al, 'M'
    je .no
    cmp al, 'L'
    je .no
    cmp al, 'F'
    je .no
    cmp al, '2'
    je .push
    cmp al, '4'
    je .push
    cmp al, '3'
    je .pop
    inc r10
    jmp .loop

.push:
    cmp r11d, 8
    jae .push_done
    inc r11d
.push_done:
    inc r10
    jmp .loop

.pop:
    test r11d, r11d
    jz .pop_done
    dec r11d
    jz .yes
.pop_done:
    inc r10
    jmp .loop

.yes:
    mov eax, ASSP_TRUE
    ret

.no:
    xor eax, eax
    ret

%define TS8_RAW_COUNT 0
%define TS8_MEASURE_INDEX 8
%define TS8_TOTAL_ROWS 16
%define TS8_ROW_CAP 24
%define TS8_RAW_BASE 32
%define TS8_ROWS_BASE 40
%define TS8_BEATS_BASE 48
%define TS8_TEXT_BASE 56
%define TS8_FAKE_PTR 64
%define TS8_FAKE_COUNT 72
%define TS8_WARP_PTR 80
%define TS8_WARP_COUNT 88
%define TS8_OUT 96
%define TS8_STATUS 104
%define TS8_CURRENT_ROW 112
%define TS8_MIN_COUNT 120
%define TS8_DEPTHS 128
%define TS8_LIFTS 136
%define TS8_BEAT_WALK 144

%macro timing_stats_8_finalize_measure 0
    cmp qword [rsp + TS8_RAW_COUNT], 0
    je %%clear

    mov rcx, [rsp + TS8_RAW_BASE]
    mov rdx, [rsp + TS8_RAW_COUNT]
    mov r8, rcx
    mov r9, [rsp + TS8_ROW_CAP]
    call assp_minimize_measure_8

    cmp rax, [rsp + TS8_ROW_CAP]
    ja %%invalid
    test rax, rax
    jz %%clear

    mov [rsp + TS8_MIN_COUNT], rax
    init_beat_walk TS8_BEAT_WALK, TS8_MEASURE_INDEX, TS8_MIN_COUNT
    xor r13d, r13d
%%append_loop:
    cmp r13, [rsp + TS8_MIN_COUNT]
    jae %%clear

    mov r10, [rsp + TS8_TOTAL_ROWS]
    cmp r10, [rsp + TS8_ROW_CAP]
    jae %%invalid

    mov r11, [rsp + TS8_RAW_BASE]
    mov rcx, [r11 + r13 * 8]
    mov r11, [rsp + TS8_ROWS_BASE]
    mov [r11 + r10 * 8], rcx

    mov r11, [rsp + TS8_BEATS_BASE]
    mov rax, [rsp + TS8_BEAT_WALK]
    mov [r11 + r10 * 8], rax

    inc qword [rsp + TS8_TOTAL_ROWS]
    advance_beat_walk TS8_BEAT_WALK, TS8_MIN_COUNT
    inc r13
    jmp %%append_loop

%%invalid:
    mov qword [rsp + TS8_STATUS], ASSP_NOT_FOUND

%%clear:
    mov qword [rsp + TS8_RAW_COUNT], 0
%endmacro

%macro timing_filter_judgable_lane_8 2
    mov rax, [rsp + TS8_CURRENT_ROW]
    shr rax, %2
    and eax, 0xff
    cmp al, '2'
    je %%hold_start
    cmp al, '4'
    je %%hold_start
    cmp al, '3'
    je %%end
    cmp al, 'L'
    je %%lift
    cmp al, 'l'
    je %%lift
    jmp %%store

%%lift:
    inc qword [rsp + TS8_LIFTS]
    mov eax, '1'
    jmp %%store

%%hold_start:
    mov rcx, [rsp + TS8_ROWS_BASE]
    mov rdx, [rsp + TS8_TOTAL_ROWS]
    mov r8, r12
    mov r9d, %1
    call timing_hold_start_has_end_8
    test eax, eax
    jnz %%reload
    mov eax, '0'
    jmp %%store

%%reload:
    inc byte [rsp + TS8_DEPTHS + %1]
    mov rax, [rsp + TS8_CURRENT_ROW]
    shr rax, %2
    and eax, 0xff
    jmp %%store

%%end:
    cmp byte [rsp + TS8_DEPTHS + %1], 0
    je %%zero
    dec byte [rsp + TS8_DEPTHS + %1]
    mov eax, '3'
    jmp %%store

%%zero:
    mov eax, '0'

%%store:
    shl rax, %2
    or r13, rax
%endmacro

%macro timing_filter_fake_lane_8 2
    mov rax, [rsp + TS8_CURRENT_ROW]
    shr rax, %2
    and eax, 0xff
    cmp al, '1'
    je %%fake
    cmp al, 'M'
    je %%fake
    cmp al, 'm'
    je %%fake
    cmp al, 'L'
    je %%fake
    cmp al, 'l'
    je %%fake
    cmp al, 'F'
    je %%fake
    cmp al, 'f'
    je %%fake
    cmp al, '2'
    je %%hold_start
    cmp al, '4'
    je %%hold_start
    cmp al, '3'
    je %%end
    jmp %%done

%%hold_start:
    mov rcx, [rsp + TS8_ROWS_BASE]
    mov rdx, [rsp + TS8_TOTAL_ROWS]
    mov r8, r12
    mov r9d, %1
    call timing_hold_start_has_end_8
    test eax, eax
    jnz %%fake
    jmp %%done

%%end:
    cmp byte [rsp + TS8_DEPTHS + %1], 0
    je %%done
    dec byte [rsp + TS8_DEPTHS + %1]
    mov eax, '3'
    shl rax, %2
    or r13, rax
    jmp %%done

%%fake:
    mov eax, 'F'
    shl rax, %2
    or r13, rax

%%done:
%endmacro

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = out stats,
; arg 8 = byte scratch, arg 9 = scratch byte cap. eax = 1 on success.
assp_count_timing_note_stats_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    mov r13, [rsp + 112]
    mov r15, [rsp + 120]
    mov r12, [rsp + 128]
    sub rsp, 176

    mov [rsp + TS8_OUT], r13
    mov [rsp + TS8_WARP_PTR], r8
    mov [rsp + TS8_WARP_COUNT], r9
    mov [rsp + TS8_FAKE_PTR], r10
    mov [rsp + TS8_FAKE_COUNT], r11
    mov qword [rsp + TS8_RAW_COUNT], 0
    mov qword [rsp + TS8_MEASURE_INDEX], 0
    mov qword [rsp + TS8_TOTAL_ROWS], 0
    mov qword [rsp + TS8_STATUS], 0

    test r13, r13
    jz .invalid
    test rdx, rdx
    jz .zero_out
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r11, r11
    jz .check_scratch_ptr
    test r10, r10
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

.zero_out:
    mov rbx, [rsp + TS8_OUT]
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.zero_loop:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero_loop

    test rdx, rdx
    jz .success

    mov rsi, rcx
    lea rdi, [rcx + rdx]

    mov rax, r12
    xor edx, edx
    mov r10d, 40
    div r10
    test rax, rax
    jz .invalid
    mov [rsp + TS8_ROW_CAP], rax

    mov [rsp + TS8_RAW_BASE], r15
    lea r10, [r15 + rax * 8]
    mov [rsp + TS8_ROWS_BASE], r10
    lea r11, [r10 + rax * 8]
    mov [rsp + TS8_BEATS_BASE], r11
    lea r10, [r11 + rax * 8]
    mov [rsp + TS8_TEXT_BASE], r10

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 8]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp + TS8_RAW_COUNT]
    cmp rax, [rsp + TS8_ROW_CAP]
    jae .invalid
    mov r10, [rsp + TS8_RAW_BASE]
    mov rcx, [rsi]
    mov [r10 + rax * 8], rcx
    inc qword [rsp + TS8_RAW_COUNT]
    jmp .line_done

.comma:
    timing_stats_8_finalize_measure
    cmp qword [rsp + TS8_STATUS], 0
    jne .invalid
    inc qword [rsp + TS8_MEASURE_INDEX]
    jmp .line_done

.semi:
    timing_stats_8_finalize_measure
    cmp qword [rsp + TS8_STATUS], 0
    jne .invalid
    jmp .transform_rows

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    timing_stats_8_finalize_measure
    cmp qword [rsp + TS8_STATUS], 0
    jne .invalid

.transform_rows:
    cmp qword [rsp + TS8_TOTAL_ROWS], 0
    je .success

    mov qword [rsp + TS8_DEPTHS], 0
    mov qword [rsp + TS8_LIFTS], 0
    xor r12d, r12d
.transform_loop:
    cmp r12, [rsp + TS8_TOTAL_ROWS]
    jae .count_filtered

    mov r10, [rsp + TS8_ROWS_BASE]
    mov rax, [r10 + r12 * 8]
    mov [rsp + TS8_CURRENT_ROW], rax

    mov r10, [rsp + TS8_BEATS_BASE]
    mov r8, [r10 + r12 * 8]
    mov rcx, [rsp + TS8_WARP_PTR]
    mov rdx, [rsp + TS8_WARP_COUNT]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable_row
    mov r10, [rsp + TS8_BEATS_BASE]
    mov r8, [r10 + r12 * 8]
    mov rcx, [rsp + TS8_FAKE_PTR]
    mov rdx, [rsp + TS8_FAKE_COUNT]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable_row

    xor r13d, r13d
    timing_filter_judgable_lane_8 0, 0
    timing_filter_judgable_lane_8 1, 8
    timing_filter_judgable_lane_8 2, 16
    timing_filter_judgable_lane_8 3, 24
    timing_filter_judgable_lane_8 4, 32
    timing_filter_judgable_lane_8 5, 40
    timing_filter_judgable_lane_8 6, 48
    timing_filter_judgable_lane_8 7, 56
    mov rax, r13
    jmp .write_row

.nonjudgable_row:
    xor r13d, r13d
    timing_filter_fake_lane_8 0, 0
    timing_filter_fake_lane_8 1, 8
    timing_filter_fake_lane_8 2, 16
    timing_filter_fake_lane_8 3, 24
    timing_filter_fake_lane_8 4, 32
    timing_filter_fake_lane_8 5, 40
    timing_filter_fake_lane_8 6, 48
    timing_filter_fake_lane_8 7, 56
    mov rax, r13

.write_row:
    mov r10, [rsp + TS8_TEXT_BASE]
    mov r11, r12
    imul r11, 9
    mov [r10 + r11], rax
    mov byte [r10 + r11 + 8], 10
    inc r12
    jmp .transform_loop

.count_filtered:
    mov rcx, [rsp + TS8_TEXT_BASE]
    mov rax, [rsp + TS8_TOTAL_ROWS]
    lea rdx, [rax + rax * 8]
    mov r8, [rsp + TS8_OUT]
    call assp_count_note_stats_8
    test eax, eax
    jz .invalid
    mov r8, [rsp + TS8_OUT]
    mov rax, [rsp + TS8_LIFTS]
    add [r8 + ASSP_NOTE_STATS_LIFTS], rax

.success:
    mov eax, ASSP_TRUE
    jmp .done

.invalid:
    xor eax, eax

.done:
    add rsp, 176
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = packed 8-lane rows, rdx = row count, r8 = start row, r9 = lane offset.
; eax = 1 when the hold or roll start has a future matching end.
timing_hold_start_has_end_8:
    mov r10, r8
    inc r10
    mov r11d, 1
.loop:
    cmp r10, rdx
    jae .no
    lea rax, [rcx + r10 * 8]
    mov al, [rax + r9]
    cmp al, '1'
    je .no
    cmp al, 'M'
    je .no
    cmp al, 'L'
    je .no
    cmp al, 'F'
    je .no
    cmp al, '2'
    je .push
    cmp al, '4'
    je .push
    cmp al, '3'
    je .pop
    inc r10
    jmp .loop

.push:
    cmp r11d, 8
    jae .push_done
    inc r11d
.push_done:
    inc r10
    jmp .loop

.pop:
    test r11d, r11d
    jz .pop_done
    dec r11d
    jz .yes
.pop_done:
    inc r10
    jmp .loop

.yes:
    mov eax, ASSP_TRUE
    ret

.no:
    xor eax, eax
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = out stats,
; arg 8 = row scratch, arg 9 = scratch row cap. eax = 1 on success.
assp_count_timing_note_stats_no_holds_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    mov r13, [rsp + 112]
    mov r15, [rsp + 120]
    mov r12, [rsp + 128]
    sub rsp, 64

    mov [rsp + 24], r13
    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r10
    mov [rsp + 56], r11
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0

    test r13, r13
    jz .invalid
    test rdx, rdx
    jz .zero_out
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r11, r11
    jz .check_scratch_ptr
    test r10, r10
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

.zero_out:
    mov rbx, [rsp + 24]
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.zero_loop:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero_loop

    test rdx, rdx
    jz .success

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 4]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov ecx, [rsi]
    mov [r15 + rax * 4], ecx
    inc qword [rsp]
    jmp .line_done

.comma:
    call timing_stats_no_holds_finalize_measure
    cmp qword [rsp + 16], 0
    jne .invalid
    inc qword [rsp + 8]
    jmp .line_done

.semi:
    call timing_stats_no_holds_finalize_measure
    cmp qword [rsp + 16], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call timing_stats_no_holds_finalize_measure
    cmp qword [rsp + 16], 0
    jne .invalid

.success:
    mov eax, ASSP_TRUE
    jmp .done

.invalid:
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

timing_stats_no_holds_finalize_measure:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_4

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 56, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear

    mov rbx, [rsp + 72]
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable

    mov eax, [r15 + r13 * 4]
    call process_no_hold_judgable_row
    jmp .next

.nonjudgable:
    mov eax, [r15 + r13 * 4]
    call row_no_hold_fake_object_count
    add qword [rbx + ASSP_NOTE_STATS_FAKES], rax

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 64], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

process_no_hold_judgable_row:
    mov r10d, eax
    xor r8d, r8d
    xor r9d, r9d
    mov dl, r10b
    mov r11d, ASSP_NOTE_STATS_LEFT
    call process_no_hold_lane
    mov edx, r10d
    shr edx, 8
    mov r11d, ASSP_NOTE_STATS_DOWN
    call process_no_hold_lane
    mov edx, r10d
    shr edx, 16
    mov r11d, ASSP_NOTE_STATS_UP
    call process_no_hold_lane
    mov edx, r10d
    shr edx, 24
    mov r11d, ASSP_NOTE_STATS_RIGHT
    call process_no_hold_lane

    test r8d, r8d
    jz .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r8d, 2
    jb .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.check_hand:
    test r9d, r9d
    jz .done
    cmp r8d, 3
    jb .done
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.done:
    ret

process_no_hold_lane:
    mov al, dl
    cmp al, '1'
    je .tap
    cmp al, 'L'
    je .lift
    cmp al, 'l'
    je .lift
    cmp al, 'M'
    je .mine
    cmp al, 'm'
    je .mine
    cmp al, 'F'
    je .fake
    cmp al, 'f'
    je .fake
    ret
.tap:
    mov r9d, 1
    inc r8d
    inc qword [rbx + ASSP_NOTE_STATS_ARROWS]
    inc qword [rbx + r11]
    ret
.lift:
    mov r9d, 1
    inc r8d
    inc qword [rbx + ASSP_NOTE_STATS_ARROWS]
    inc qword [rbx + ASSP_NOTE_STATS_LIFTS]
    inc qword [rbx + r11]
    ret
.mine:
    mov r9d, 1
    inc qword [rbx + ASSP_NOTE_STATS_MINES]
    ret
.fake:
    mov r9d, 1
    inc qword [rbx + ASSP_NOTE_STATS_FAKES]
    ret

row_no_hold_fake_object_count:
    xor ecx, ecx
    call no_hold_fake_object_lane_low
    cmp ah, '1'
    je .lane1
    cmp ah, 'M'
    je .lane1
    cmp ah, 'm'
    je .lane1
    cmp ah, 'L'
    je .lane1
    cmp ah, 'l'
    je .lane1
    cmp ah, 'F'
    je .lane1
    cmp ah, 'f'
    jne .upper
.lane1:
    inc ecx
.upper:
    shr eax, 16
    call no_hold_fake_object_lane_low
    cmp ah, '1'
    je .lane3
    cmp ah, 'M'
    je .lane3
    cmp ah, 'm'
    je .lane3
    cmp ah, 'L'
    je .lane3
    cmp ah, 'l'
    je .lane3
    cmp ah, 'F'
    je .lane3
    cmp ah, 'f'
    jne .done
.lane3:
    inc ecx
.done:
    mov eax, ecx
    ret

no_hold_fake_object_lane_low:
    cmp al, '1'
    je .yes
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp al, 'L'
    je .yes
    cmp al, 'l'
    je .yes
    cmp al, 'F'
    je .yes
    cmp al, 'f'
    jne .no
.yes:
    inc ecx
.no:
    ret

; rcx = note-data bytes, rdx = byte length, r8 = warp segments, r9 = warp count,
; stack arg 5 = fake segments, arg 6 = fake count, arg 7 = out stats,
; arg 8 = row scratch, arg 9 = scratch row cap. eax = 1 on success.
assp_count_timing_note_stats_no_holds_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    mov r13, [rsp + 112]
    mov r15, [rsp + 120]
    mov r12, [rsp + 128]
    sub rsp, 64

    mov [rsp + 24], r13
    mov [rsp + 32], r8
    mov [rsp + 40], r9
    mov [rsp + 48], r10
    mov [rsp + 56], r11
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0

    test r13, r13
    jz .invalid
    test rdx, rdx
    jz .zero_out
    test rcx, rcx
    jz .invalid
    test r9, r9
    jz .check_fakes_ptr
    test r8, r8
    jz .invalid

.check_fakes_ptr:
    test r11, r11
    jz .check_scratch_ptr
    test r10, r10
    jz .invalid

.check_scratch_ptr:
    test r12, r12
    jz .invalid
    test r15, r15
    jz .invalid

.zero_out:
    mov rbx, [rsp + 24]
    xor eax, eax
    mov r9d, ASSP_NOTE_STATS_SIZE / 8
    mov r10, rbx
.zero_loop:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero_loop

    test rdx, rdx
    jz .success

    mov rsi, rcx
    lea rdi, [rcx + rdx]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov rbx, rsi
.find_line_end:
    cmp rbx, rdi
    jae .line_end_found
    cmp byte [rbx], 10
    je .line_end_found
    inc rbx
    jmp .find_line_end

.line_end_found:
    mov r14, rbx
    cmp r14, rdi
    jae .trim_left
    inc r14

.trim_left:
    cmp rsi, rbx
    jae .line_done
    mov al, [rsi]
    cmp al, ' '
    je .trim_advance
    cmp al, 9
    jb .line_start
    cmp al, 13
    jbe .trim_advance
    jmp .line_start

.trim_advance:
    inc rsi
    jmp .trim_left

.line_start:
    mov al, [rsi]
    cmp al, '/'
    je .line_done
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semi

    lea rax, [rsi + 8]
    cmp rax, rbx
    ja .line_done

    mov rax, [rsp]
    cmp rax, r12
    jae .invalid
    mov rcx, [rsi]
    mov [r15 + rax * 8], rcx
    inc qword [rsp]
    jmp .line_done

.comma:
    call timing_stats_no_holds_finalize_measure_8
    cmp qword [rsp + 16], 0
    jne .invalid
    inc qword [rsp + 8]
    jmp .line_done

.semi:
    call timing_stats_no_holds_finalize_measure_8
    cmp qword [rsp + 16], 0
    jne .invalid
    jmp .success

.line_done:
    mov rsi, r14
    jmp .line_loop

.eof:
    call timing_stats_no_holds_finalize_measure_8
    cmp qword [rsp + 16], 0
    jne .invalid

.success:
    mov eax, ASSP_TRUE
    jmp .done

.invalid:
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

timing_stats_no_holds_finalize_measure_8:
    sub rsp, 40
    cmp qword [rsp + 48], 0
    je .clear

    mov rcx, r15
    mov rdx, [rsp + 48]
    mov r8, r15
    mov r9, r12
    call assp_minimize_measure_8

    cmp rax, r12
    ja .invalid
    mov [rsp + 48], rax
    test rax, rax
    jz .clear

    init_beat_walk 0, 56, 48
    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear

    mov rbx, [rsp + 72]
    inc qword [rbx + ASSP_NOTE_STATS_ROWS]

    mov r8, [rsp]

    mov rcx, [rsp + 80]
    mov rdx, [rsp + 88]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable
    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    call beat_in_timing_range_rows
    test eax, eax
    jnz .nonjudgable

    mov rax, [r15 + r13 * 8]
    call process_no_hold_judgable_row_8
    jmp .next

.nonjudgable:
    mov rax, [r15 + r13 * 8]
    call row_no_hold_fake_object_count_8
    add qword [rbx + ASSP_NOTE_STATS_FAKES], rax

.next:
    advance_beat_walk 0, 48
    inc r13
    jmp .row_loop

.invalid:
    mov qword [rsp + 64], ASSP_NOT_FOUND

.clear:
    mov qword [rsp + 48], 0
    add rsp, 40
    ret

process_no_hold_judgable_row_8:
    mov r10, rax
    xor r8d, r8d
    xor r9d, r9d
    mov dl, r10b
    mov r11d, ASSP_NOTE_STATS_LEFT
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 8
    mov r11d, ASSP_NOTE_STATS_DOWN
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 16
    mov r11d, ASSP_NOTE_STATS_UP
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 24
    mov r11d, ASSP_NOTE_STATS_RIGHT
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 32
    mov r11d, ASSP_NOTE_STATS_LEFT
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 40
    mov r11d, ASSP_NOTE_STATS_DOWN
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 48
    mov r11d, ASSP_NOTE_STATS_UP
    call process_no_hold_lane
    mov rdx, r10
    shr rdx, 56
    mov r11d, ASSP_NOTE_STATS_RIGHT
    call process_no_hold_lane

    test r8d, r8d
    jz .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_STEPS]
    cmp r8d, 2
    jb .check_hand
    inc qword [rbx + ASSP_NOTE_STATS_JUMPS]

.check_hand:
    test r9d, r9d
    jz .done
    cmp r8d, 3
    jb .done
    inc qword [rbx + ASSP_NOTE_STATS_HANDS]
.done:
    ret

row_no_hold_fake_object_count_8:
    mov rdx, rax
    xor ecx, ecx
    mov r8d, 8
.loop:
    mov al, dl
    cmp al, '1'
    je .count
    cmp al, 'M'
    je .count
    cmp al, 'm'
    je .count
    cmp al, 'L'
    je .count
    cmp al, 'l'
    je .count
    cmp al, 'F'
    je .count
    cmp al, 'f'
    jne .next
.count:
    inc ecx
.next:
    shr rdx, 8
    dec r8d
    jnz .loop
    mov eax, ecx
    ret

section .rdata
align 16
note_stats_popcount4 db 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
align 4
note_stats_const_thousand_f32 dd 1000.0
note_stats_const_48_f32 dd 48.0
