default rel
%include "assp.inc"

global assp_count_note_stats_4
global assp_count_mines_nonfake_4
global assp_count_timing_fakes_4

extern assp_minimize_measure_4

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

    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear
    mov eax, [r15 + r13 * 4]
    call row_has_mine
    test eax, eax
    jz .next

    mov rax, [rsp + 64]
    imul rax, 4000
    mov r8, rax
    mov rax, r13
    imul rax, 4000
    xor edx, edx
    div qword [rsp + 48]
    add r8, rax

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
    cmp ah, 'M'
    je .yes
    cmp ah, 'm'
    je .yes
    shr eax, 16
    cmp al, 'M'
    je .yes
    cmp al, 'm'
    je .yes
    cmp ah, 'M'
    je .yes
    cmp ah, 'm'
    je .yes
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
    xor r9d, r9d
.loop:
    cmp r9, rdx
    jae .no
    mov rax, r9
    shl rax, 4
    mov r10, [rcx + rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    test r10, r10
    jle .next
    mov r11, [rcx + rax + ASSP_BPM_SEGMENT_BEAT_MILLI]
    cmp r8, r11
    jl .next
    add r11, r10
    cmp r8, r11
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

    xor r13d, r13d
.row_loop:
    cmp r13, [rsp + 48]
    jae .clear

    mov rax, [rsp + 64]
    imul rax, 4000
    mov r8, rax
    mov rax, r13
    imul rax, 4000
    xor edx, edx
    div qword [rsp + 48]
    add r8, rax

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
