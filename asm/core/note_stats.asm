default rel
%include "assp.inc"

global assp_count_note_stats_4

section .text

%macro bump_arrow 1
    inc qword [rbx + ASSP_NOTE_STATS_ARROWS]
    inc qword [rbx + %1]
    inc r13d
%endmacro

%macro count_lane 2
    mov al, [rsi + %1]
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
    bump_arrow %2
    jmp %%done

%%hold:
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_HOLDS]
    inc r14d
    jmp %%done

%%roll:
    bump_arrow %2
    inc qword [rbx + ASSP_NOTE_STATS_ROLLS]
    inc r14d
    jmp %%done

%%end:
    inc r15d
    jmp %%done

%%mine:
    inc qword [rbx + ASSP_NOTE_STATS_MINES]
    jmp %%done

%%lift:
    inc qword [rbx + ASSP_NOTE_STATS_LIFTS]
    jmp %%done

%%fake:
    inc qword [rbx + ASSP_NOTE_STATS_FAKES]

%%done:
%endmacro

%macro invalid_lane_break 1
    mov al, [rsi + %1]
    cmp al, 10
    je .malformed_row
    cmp al, 13
    je .malformed_row
    cmp al, ','
    je .malformed_row
    cmp al, ';'
    je .malformed_row
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

    invalid_lane_break 0
    invalid_lane_break 1
    invalid_lane_break 2
    invalid_lane_break 3

    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d

    count_lane 0, ASSP_NOTE_STATS_LEFT
    count_lane 1, ASSP_NOTE_STATS_DOWN
    count_lane 2, ASSP_NOTE_STATS_UP
    count_lane 3, ASSP_NOTE_STATS_RIGHT

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
    mov eax, r12d
    sub eax, r15d
    jns .store_empty_active
    xor eax, eax

.store_empty_active:
    mov r12d, eax
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
    mov eax, ASSP_TRUE
    jmp .done

.fail:
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

