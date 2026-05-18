default rel
%include "assp.inc"

global assp_matrix_rating_centi

section .text

%define MAT_COUNTS 0
%define MAT_BEST 32
%define MAT_CANDIDATE 40
%define MAT_SIZE 96

%define DIFF_COUNT 0
%define DIFF_NUM 8
%define DIFF_DEN 16
%define DIFF_EFFECTIVE 24
%define DIFF_DIFF1 32
%define DIFF_DIFF2 40
%define DIFF_TMPQ 48
%define DIFF_TMPD 56
%define DIFF_BPM1 60
%define DIFF_BPM2 64
%define DIFF_RANGE 68
%define DIFF_SIZE 96

%define ROW_COUNT 0
%define ROW_TMPQ 8
%define ROW_RATIO 16
%define ROW_LN_A 24
%define ROW_LN_B 32
%define ROW_LN_C 40
%define ROW_TMPD 48
%define ROW_BASE 52
%define ROW_START 56
%define ROW_END 60
%define ROW_SIZE 80

; rcx = densities, rdx = density count, r8 = bpm segments, r9 = bpm count.
; rax = matrix rating rounded to cents.
assp_matrix_rating_centi:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, MAT_SIZE

    xor r15, r15
    test rdx, rdx
    jz .done
    test r9, r9
    jz .done

    mov rsi, rcx
    mov rdi, r8
    mov r12, rdx
    mov r13, r9
    xor r14, r14

.bpm_loop:
    cmp r14, r13
    jae .done

    mov rax, r14
    shl rax, 4
    mov rax, [rdi + rax + ASSP_BPM_SEGMENT_BPM_MILLI]
    mov [rsp + MAT_CANDIDATE], rax
    test rax, rax
    jle .next_bpm

    xor rbx, rbx
.dup_loop:
    cmp rbx, r14
    jae .not_duplicate
    mov rcx, rbx
    shl rcx, 4
    cmp [rdi + rcx + ASSP_BPM_SEGMENT_BPM_MILLI], rax
    je .next_bpm
    inc rbx
    jmp .dup_loop

.not_duplicate:
    mov qword [rsp + MAT_COUNTS], 0
    mov qword [rsp + MAT_COUNTS + 8], 0
    mov qword [rsp + MAT_COUNTS + 16], 0
    mov qword [rsp + MAT_COUNTS + 24], 0

    xor rbx, rbx                    ; measure index
    xor r10, r10                    ; active bpm index
    mov r11, 0x7fffffffffffffff     ; next bpm beat
    cmp r13, 1
    jbe .measure_loop
    mov r11, [rdi + ASSP_BPM_SEGMENT_SIZE + ASSP_BPM_SEGMENT_BEAT_MILLI]

.measure_loop:
    cmp rbx, r12
    jae .score_counts

    mov rax, rbx
    imul rax, rax, 4000
.advance_bpm:
    cmp r10, r13
    jae .after_advance
    cmp rax, r11
    jl .after_advance
    inc r10
    mov r11, 0x7fffffffffffffff
    mov rcx, r10
    inc rcx
    cmp rcx, r13
    jae .advance_bpm
    shl rcx, 4
    mov r11, [rdi + rcx + ASSP_BPM_SEGMENT_BEAT_MILLI]
    jmp .advance_bpm

.after_advance:
    mov rcx, r10
    shl rcx, 4
    mov rcx, [rdi + rcx + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp rcx, [rsp + MAT_CANDIDATE]
    jne .next_measure

    mov eax, [rsi + rbx * 4]
    cmp eax, 16
    jb .next_measure
    cmp eax, 20
    jb .inc_run16
    cmp eax, 24
    jb .inc_run20
    cmp eax, 32
    jb .inc_run24
    inc qword [rsp + MAT_COUNTS + 24]
    jmp .next_measure
.inc_run16:
    inc qword [rsp + MAT_COUNTS]
    jmp .next_measure
.inc_run20:
    inc qword [rsp + MAT_COUNTS + 8]
    jmp .next_measure
.inc_run24:
    inc qword [rsp + MAT_COUNTS + 16]

.next_measure:
    inc rbx
    jmp .measure_loop

.score_counts:
    mov rcx, [rsp + MAT_CANDIDATE]

    mov r9, [rsp + MAT_COUNTS]
    test r9, r9
    jz .score_run20
    mov rdx, 1
    mov r8, 1
    call matrix_get_difficulty_centi
    cmp rax, r15
    cmova r15, rax

.score_run20:
    mov r9, [rsp + MAT_COUNTS + 8]
    test r9, r9
    jz .score_run24
    mov rcx, [rsp + MAT_CANDIDATE]
    mov rdx, 5
    mov r8, 4
    call matrix_get_difficulty_centi
    cmp rax, r15
    cmova r15, rax

.score_run24:
    mov r9, [rsp + MAT_COUNTS + 16]
    test r9, r9
    jz .score_run32
    mov rcx, [rsp + MAT_CANDIDATE]
    mov rdx, 3
    mov r8, 2
    call matrix_get_difficulty_centi
    cmp rax, r15
    cmova r15, rax

.score_run32:
    mov r9, [rsp + MAT_COUNTS + 24]
    test r9, r9
    jz .next_bpm
    mov rcx, [rsp + MAT_CANDIDATE]
    mov rdx, 2
    mov r8, 1
    call matrix_get_difficulty_centi
    cmp rax, r15
    cmova r15, rax

.next_bpm:
    inc r14
    jmp .bpm_loop

.done:
    mov rax, r15
    add rsp, MAT_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = bpm milli, rdx = multiplier numerator, r8 = multiplier denominator,
; r9 = measure count. rax = rounded difficulty * 100.
matrix_get_difficulty_centi:
    push rbx
    push rsi
    push rdi
    sub rsp, DIFF_SIZE

    mov [rsp + DIFF_COUNT], r9
    mov [rsp + DIFF_NUM], rdx
    mov [rsp + DIFF_DEN], r8

    mov rax, rcx
    imul rax, rdx
    mov [rsp + DIFF_TMPQ], rax
    mov r10, 1000
    imul r10, r8
    mov [rsp + DIFF_DEN], r10
    fild qword [rsp + DIFF_TMPQ]
    fild qword [rsp + DIFF_DEN]
    fdivp st1, st0
    fstp qword [rsp + DIFF_EFFECTIVE]

    mov rax, [rsp + DIFF_TMPQ]
    mov r10, [rsp + DIFF_DEN]
    mov r11, r10
    imul r11, 500
    cmp rax, r11
    jg .above_max_bpm
    mov r11, r10
    imul r11, 80
    cmp rax, r11
    jl .below_min_bpm

    xor rdx, rdx
    div r10
    cmp rax, 80
    jl .bpm_zero_min
    sub rax, 80
    xor rdx, rdx
    mov r10, 10
    div r10
    imul rax, rax, 10
    add rax, 80
    mov [rsp + DIFF_BPM1], eax
    test rdx, rdx
    jz .same_bpm_key
    add eax, 10
    mov [rsp + DIFF_BPM2], eax
    jmp .have_bpm_keys

.same_bpm_key:
    mov [rsp + DIFF_BPM2], eax
    jmp .have_bpm_keys

.bpm_zero_min:
    mov dword [rsp + DIFF_BPM1], 0
    mov dword [rsp + DIFF_BPM2], 80
    jmp .have_bpm_keys

.above_max_bpm:
    mov dword [rsp + DIFF_BPM1], 490
    mov dword [rsp + DIFF_BPM2], 500
    jmp .have_bpm_keys

.below_min_bpm:
    mov dword [rsp + DIFF_BPM1], 80
    mov dword [rsp + DIFF_BPM2], 90

.have_bpm_keys:
    mov eax, [rsp + DIFF_BPM1]
    sub eax, 80
    cdq
    mov ecx, 10
    idiv ecx
    movsxd rcx, eax
    mov rdx, [rsp + DIFF_COUNT]
    call matrix_calc_row_diff
    fstp qword [rsp + DIFF_DIFF1]

    mov eax, [rsp + DIFF_BPM1]
    cmp eax, [rsp + DIFF_BPM2]
    je .round_diff1

    mov eax, [rsp + DIFF_BPM2]
    sub eax, 80
    cdq
    mov ecx, 10
    idiv ecx
    movsxd rcx, eax
    mov rdx, [rsp + DIFF_COUNT]
    call matrix_calc_row_diff
    fstp qword [rsp + DIFF_DIFF2]

    fld qword [rsp + DIFF_DIFF2]
    fsub qword [rsp + DIFF_DIFF1]
    fstp qword [rsp + DIFF_TMPQ]
    fld qword [rsp + DIFF_EFFECTIVE]
    fisub dword [rsp + DIFF_BPM1]
    mov eax, [rsp + DIFF_BPM2]
    sub eax, [rsp + DIFF_BPM1]
    mov [rsp + DIFF_RANGE], eax
    fidiv dword [rsp + DIFF_RANGE]
    fmul qword [rsp + DIFF_TMPQ]
    fadd qword [rsp + DIFF_DIFF1]
    jmp .round_st0

.round_diff1:
    fld qword [rsp + DIFF_DIFF1]

.round_st0:
    fmul qword [matrix_hundred]
    fistp qword [rsp + DIFF_TMPQ]
    mov rax, [rsp + DIFF_TMPQ]
    add rsp, DIFF_SIZE
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = difficulty table row index, rdx = measure count. ST0 = difficulty.
matrix_calc_row_diff:
    push rbx
    push rsi
    push rdi
    sub rsp, ROW_SIZE

    mov [rsp + ROW_COUNT], rdx
    test rdx, rdx
    jnz .nonzero_count
    fldz
    jmp .ret

.nonzero_count:
    imul rax, rcx, 13
    lea rsi, [matrix_diff_table]
    add rsi, rax
    lea r11, [matrix_measure_keys]

    cmp rdx, 8
    jae .find_lower
    movzx eax, byte [rsi]
    mov [rsp + ROW_TMPD], eax
    mov qword [rsp + ROW_TMPQ], 8
    fild qword [rsp + ROW_TMPQ]
    fild qword [rsp + ROW_COUNT]
    fdivp st1, st0
    fstp qword [rsp + ROW_RATIO]
    fldln2
    fld qword [rsp + ROW_RATIO]
    fyl2x
    fstp qword [rsp + ROW_LN_A]
    fild dword [rsp + ROW_TMPD]
    fsub qword [rsp + ROW_LN_A]
    fldz
    fcomip st0, st1
    jbe .ret
    fstp st0
    fldz
    jmp .ret

.find_lower:
    mov ebx, 12
.lower_loop:
    mov eax, [r11 + rbx * 4]
    cmp rdx, rax
    jae .have_lower
    dec ebx
    jmp .lower_loop

.have_lower:
    movzx eax, byte [rsi + rbx]
    mov [rsp + ROW_BASE], eax
    movzx ecx, byte [rsi + 12]
    cmp eax, ecx
    je .plateau

    xor edi, edi
.range_start_loop:
    movzx ecx, byte [rsi + rdi]
    cmp ecx, eax
    je .have_range_start
    inc edi
    jmp .range_start_loop

.have_range_start:
    mov ecx, [r11 + rdi * 4]
    mov [rsp + ROW_START], ecx
    cmp rdx, rcx
    ja .find_range_end
    fild dword [rsp + ROW_BASE]
    jmp .ret

.find_range_end:
    inc edi
.range_end_loop:
    movzx ecx, byte [rsi + rdi]
    cmp ecx, eax
    ja .have_range_end
    inc edi
    jmp .range_end_loop

.have_range_end:
    mov ecx, [r11 + rdi * 4]
    mov [rsp + ROW_END], ecx
    fild qword [rsp + ROW_COUNT]
    fstp qword [rsp + ROW_RATIO]
    fldln2
    fld qword [rsp + ROW_RATIO]
    fyl2x
    fstp qword [rsp + ROW_LN_A]

    fild dword [rsp + ROW_START]
    fstp qword [rsp + ROW_RATIO]
    fldln2
    fld qword [rsp + ROW_RATIO]
    fyl2x
    fstp qword [rsp + ROW_LN_B]

    fild dword [rsp + ROW_END]
    fstp qword [rsp + ROW_RATIO]
    fldln2
    fld qword [rsp + ROW_RATIO]
    fyl2x
    fstp qword [rsp + ROW_LN_C]

    fld qword [rsp + ROW_LN_A]
    fsub qword [rsp + ROW_LN_B]
    fstp qword [rsp + ROW_RATIO]
    fld qword [rsp + ROW_LN_C]
    fsub qword [rsp + ROW_LN_B]
    fstp qword [rsp + ROW_LN_A]
    fld qword [rsp + ROW_RATIO]
    fdiv qword [rsp + ROW_LN_A]
    fild dword [rsp + ROW_BASE]
    faddp st1, st0
    jmp .ret

.plateau:
    xor edi, edi
.plateau_start_loop:
    movzx ecx, byte [rsi + rdi]
    cmp ecx, eax
    je .have_plateau_start
    inc edi
    jmp .plateau_start_loop

.have_plateau_start:
    mov ecx, [r11 + rdi * 4]
    mov [rsp + ROW_START], ecx
    cmp rdx, rcx
    ja .scale_plateau
    fild dword [rsp + ROW_BASE]
    jmp .ret

.scale_plateau:
    fild qword [rsp + ROW_COUNT]
    fidiv dword [rsp + ROW_START]
    fstp qword [rsp + ROW_RATIO]
    fldln2
    fld qword [rsp + ROW_RATIO]
    fyl2x
    fstp qword [rsp + ROW_LN_A]
    fild dword [rsp + ROW_BASE]
    fadd qword [rsp + ROW_LN_A]

.ret:
    add rsp, ROW_SIZE
    pop rdi
    pop rsi
    pop rbx
    ret

section .rdata

matrix_hundred dq 100.0
matrix_measure_keys dd 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512

matrix_diff_table:
    ; 80
    db 7, 7, 8, 8, 9, 9, 9, 10, 10, 10, 10, 11, 11
    ; 90
    db 7, 8, 8, 9, 9, 9, 10, 10, 11, 11, 11, 12, 12
    ; 100
    db 8, 8, 9, 9, 10, 10, 10, 11, 11, 11, 11, 12, 12
    ; 110
    db 8, 9, 9, 10, 10, 10, 11, 11, 12, 12, 12, 13, 13
    ; 120
    db 9, 9, 10, 10, 11, 11, 12, 12, 12, 13, 13, 13, 13
    ; 130
    db 9, 10, 10, 11, 11, 12, 12, 13, 13, 13, 14, 14, 14
    ; 140
    db 10, 10, 11, 11, 12, 12, 13, 13, 13, 14, 14, 14, 15
    ; 150
    db 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 15, 16
    ; 160
    db 11, 11, 12, 12, 12, 13, 14, 14, 15, 15, 16, 16, 16
    ; 170
    db 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17
    ; 180
    db 12, 12, 13, 13, 13, 14, 15, 15, 16, 16, 17, 17, 18
    ; 190
    db 12, 13, 13, 14, 14, 15, 15, 16, 17, 17, 18, 18, 19
    ; 200
    db 13, 13, 14, 14, 15, 15, 16, 17, 17, 18, 19, 19, 20
    ; 210
    db 13, 14, 14, 15, 15, 16, 17, 18, 18, 19, 20, 20, 21
    ; 220
    db 14, 14, 15, 16, 16, 17, 18, 19, 19, 20, 21, 22, 22
    ; 230
    db 14, 15, 16, 16, 17, 18, 19, 20, 20, 21, 22, 22, 23
    ; 240
    db 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 23, 24, 24
    ; 250
    db 16, 17, 18, 18, 19, 20, 21, 22, 23, 24, 24, 25, 25
    ; 260
    db 17, 18, 19, 19, 21, 22, 23, 23, 24, 25, 25, 26, 26
    ; 270
    db 18, 19, 20, 21, 22, 23, 24, 25, 25, 26, 26, 27, 27
    ; 280
    db 19, 20, 21, 22, 23, 24, 25, 26, 26, 27, 27, 28, 28
    ; 290
    db 20, 21, 22, 23, 24, 25, 26, 27, 27, 28, 28, 29, 29
    ; 300
    db 21, 22, 23, 24, 24, 25, 26, 27, 28, 29, 30, 30, 30
    ; 310
    db 22, 23, 24, 24, 25, 26, 27, 28, 29, 29, 30, 31, 31
    ; 320
    db 22, 23, 24, 25, 26, 27, 28, 29, 30, 30, 31, 32, 32
    ; 330
    db 23, 24, 25, 26, 26, 28, 29, 30, 31, 31, 32, 32, 33
    ; 340
    db 24, 25, 26, 27, 27, 29, 30, 31, 31, 32, 32, 33, 34
    ; 350
    db 25, 26, 27, 28, 28, 30, 30, 31, 32, 33, 33, 34, 35
    ; 360
    db 26, 27, 27, 28, 29, 30, 31, 32, 33, 34, 34, 35, 36
    ; 370
    db 27, 28, 28, 29, 30, 32, 32, 33, 34, 34, 35, 36, 37
    ; 380
    db 28, 29, 29, 30, 31, 33, 34, 34, 35, 36, 36, 37, 38
    ; 390
    db 29, 30, 31, 32, 33, 34, 35, 35, 36, 37, 37, 38, 39
    ; 400
    db 30, 31, 32, 33, 34, 35, 36, 37, 37, 38, 39, 39, 40
    ; 410
    db 31, 32, 33, 34, 35, 36, 37, 38, 38, 39, 40, 40, 41
    ; 420
    db 32, 33, 34, 35, 36, 37, 38, 39, 39, 40, 41, 42, 42
    ; 430
    db 33, 34, 35, 36, 37, 38, 39, 39, 40, 41, 42, 43, 43
    ; 440
    db 34, 35, 36, 37, 38, 39, 40, 40, 41, 42, 43, 44, 44
    ; 450
    db 35, 36, 37, 38, 39, 40, 40, 41, 42, 43, 44, 45, 45
    ; 460
    db 36, 37, 38, 39, 40, 41, 41, 42, 43, 44, 45, 46, 46
    ; 470
    db 37, 38, 39, 40, 41, 42, 42, 43, 44, 45, 46, 47, 47
    ; 480
    db 38, 39, 40, 41, 42, 43, 43, 44, 45, 46, 47, 48, 48
    ; 490
    db 39, 40, 41, 42, 43, 44, 44, 45, 46, 47, 48, 49, 49
    ; 500
    db 40, 41, 42, 43, 44, 45, 45, 46, 47, 48, 49, 50, 50
