default rel
%include "assp.inc"

global assp_trim_ascii_bytes
global assp_normalize_label_tag
global assp_resolve_display_bpm
global assp_chart_name_tag_allowed
global assp_resolve_difficulty_label
global assp_steps_timing_allowed

section .text

%define DIFF_ARG_METER_PTR 128
%define DIFF_ARG_METER_LEN 136
%define DIFF_ARG_IS_SM 144
%define DIFF_ARG_OUT_PTR 152
%define DIFF_ARG_OUT_CAP 160

%define DISPLAY_ARG_OUT_MIN 96
%define DISPLAY_ARG_OUT_MAX 104
%define DISPLAY_ARG_TEXT_MIN 112
%define DISPLAY_ARG_TEXT_MAX 120
%define DISPLAY_ARG_TEXT_RANGE 128

; rcx = #VERSION bytes, rdx = len, r8d = nonzero when the file is .sm.
; eax = 1 when RSSP allows chart-local step timing.
assp_steps_timing_allowed:
    test r8d, r8d
    jnz .true
    test rdx, rdx
    jz .false
    test rcx, rcx
    jz .false

    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .false
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .false
    cmp byte [r11 - 1], ' '
    ja .sign
    dec r11
    jmp .trim_right

.sign:
    cmp byte [r10], '+'
    jne .not_plus
    inc r10
    cmp r10, r11
    jae .false
    jmp .init

.not_plus:
    cmp byte [r10], '-'
    je .false

.init:
    xor r8d, r8d
    xor r9d, r9d
    mov edx, -1

.int_loop:
    cmp r10, r11
    jae .compare
    movzx eax, byte [r10]
    cmp al, '0'
    jb .maybe_dot
    cmp al, '9'
    ja .false
    mov r9d, ASSP_TRUE
    cmp al, '0'
    je .next_int
    mov r8d, ASSP_TRUE
.next_int:
    inc r10
    jmp .int_loop

.maybe_dot:
    cmp al, '.'
    jne .false
    inc r10

.frac_loop:
    cmp r10, r11
    jae .compare
    movzx eax, byte [r10]
    cmp al, '0'
    jb .false
    cmp al, '9'
    ja .false
    mov r9d, ASSP_TRUE
    cmp edx, -1
    jne .next_frac
    sub eax, '0'
    mov edx, eax
.next_frac:
    inc r10
    jmp .frac_loop

.compare:
    test r9d, r9d
    jz .false
    test r8d, r8d
    jnz .true
    cmp edx, 7
    jae .true

.false:
    xor eax, eax
    ret

.true:
    mov eax, ASSP_TRUE
    ret

; rcx = #VERSION bytes, rdx = len, r8d = nonzero when the file is .sm.
; eax = 1 when RSSP keeps #CHARTNAME/#DESCRIPTION as modern SSC fields.
assp_chart_name_tag_allowed:
    test r8d, r8d
    jnz .true
    test rdx, rdx
    jz .true
    test rcx, rcx
    jz .true

    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .true
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .true
    cmp byte [r11 - 1], ' '
    ja .sign
    dec r11
    jmp .trim_right

.sign:
    cmp byte [r10], '+'
    jne .not_plus
    inc r10
    cmp r10, r11
    jae .true
    jmp .init

.not_plus:
    cmp byte [r10], '-'
    je .false

.init:
    xor r8d, r8d
    xor r9d, r9d
    xor edx, edx
    xor ecx, ecx

.int_loop:
    cmp r10, r11
    jae .compare
    movzx eax, byte [r10]
    cmp al, '0'
    jb .maybe_dot
    cmp al, '9'
    ja .true
    mov r9d, ASSP_TRUE
    cmp al, '0'
    je .next_int
    mov r8d, ASSP_TRUE
.next_int:
    inc r10
    jmp .int_loop

.maybe_dot:
    cmp al, '.'
    jne .true
    inc r10

.frac_loop:
    cmp r10, r11
    jae .compare
    movzx eax, byte [r10]
    cmp al, '0'
    jb .true
    cmp al, '9'
    ja .true
    mov r9d, ASSP_TRUE
    cmp ecx, 2
    jae .next_frac
    sub eax, '0'
    test ecx, ecx
    jnz .second_frac
    imul eax, eax, 10
.second_frac:
    add edx, eax
    inc ecx
.next_frac:
    inc r10
    jmp .frac_loop

.compare:
    test r9d, r9d
    jz .true
    test r8d, r8d
    jnz .true
    cmp edx, 74
    jae .true

.false:
    xor eax, eax
    ret

.true:
    mov eax, ASSP_TRUE
    ret

; rcx = difficulty bytes, rdx = difficulty len, r8 = normalized description
; bytes, r9 = normalized description len, [rsp+40] = meter bytes,
; [rsp+48] = meter len, [rsp+56] = nonzero for .sm, [rsp+64] = out bytes,
; [rsp+72] = out cap.
; rax = bytes required/written, or ASSP_NOT_FOUND.
assp_resolve_difficulty_label:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    mov rsi, rcx
    mov rdi, rdx
    mov r12, r8
    mov r13, r9
    mov r14, [rsp + DIFF_ARG_METER_PTR]
    mov r15, [rsp + DIFF_ARG_METER_LEN]
    mov rbx, [rsp + DIFF_ARG_IS_SM]

    test ebx, ebx
    jz .ssc_raw
    mov rcx, rsi
    mov rdx, rdi
    call match_old_difficulty_label
    jmp .raw_done

.ssc_raw:
    mov rcx, rsi
    mov rdx, rdi
    call match_canonical_difficulty_label

.raw_done:
    test rax, rax
    jz .description_fallback
    test ebx, ebx
    jz .emit
    lea r10, [label_hard]
    cmp rax, r10
    jne .emit

    mov rcx, r12
    mov rdx, r13
    lea r8, [match_smaniac]
    mov r9d, match_smaniac_end - match_smaniac
    call match_trim_ci
    test eax, eax
    jnz .force_challenge
    mov rcx, r12
    mov rdx, r13
    lea r8, [match_challenge]
    mov r9d, match_challenge_end - match_challenge
    call match_trim_ci
    test eax, eax
    jz .emit_hard

.force_challenge:
    lea rax, [label_challenge]
    mov edx, label_challenge_end - label_challenge
    jmp .emit

.emit_hard:
    lea rax, [label_hard]
    mov edx, label_hard_end - label_hard
    jmp .emit

.description_fallback:
    mov rcx, r12
    mov rdx, r13
    call match_canonical_difficulty_label
    test rax, rax
    jnz .emit

    mov rcx, r14
    mov rdx, r15
    mov r8, rbx
    call meter_difficulty_label

.emit:
    mov r10, rax
    mov r11, rdx
    mov r8, [rsp + DIFF_ARG_OUT_PTR]
    mov r9, [rsp + DIFF_ARG_OUT_CAP]
    test r8, r8
    jz .success
    cmp r11, r9
    ja .fail
    xor ecx, ecx

.copy_loop:
    cmp rcx, r11
    jae .success
    mov al, [r10 + rcx]
    mov [r8 + rcx], al
    inc rcx
    jmp .copy_loop

.success:
    mov rax, r11
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

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

%macro try_difficulty 4
    mov rcx, rsi
    mov rdx, rdi
    lea r8, [%1]
    mov r9d, %2 - %1
    call match_ci
    test eax, eax
    jz %%next
    lea rax, [%3]
    mov edx, %4 - %3
    jmp .done
%%next:
%endmacro

%macro trim_difficulty_input 1
    test rdx, rdx
    jz %1
    test rcx, rcx
    jz %1
    mov rsi, rcx
    lea rdi, [rcx + rdx]
%%trim_left:
    cmp rsi, rdi
    jae %1
    cmp byte [rsi], ' '
    ja %%trim_right
    inc rsi
    jmp %%trim_left
%%trim_right:
    cmp rdi, rsi
    jbe %1
    cmp byte [rdi - 1], ' '
    ja %%len
    dec rdi
    jmp %%trim_right
%%len:
    sub rdi, rsi
%endmacro

match_canonical_difficulty_label:
    push rsi
    push rdi
    push r12
    sub rsp, 32
    trim_difficulty_input .not_found

    try_difficulty match_beginner, match_beginner_end, label_beginner, label_beginner_end
    try_difficulty match_easy, match_easy_end, label_easy, label_easy_end
    try_difficulty match_medium, match_medium_end, label_medium, label_medium_end
    try_difficulty match_hard, match_hard_end, label_hard, label_hard_end
    try_difficulty match_challenge, match_challenge_end, label_challenge, label_challenge_end
    try_difficulty match_edit, match_edit_end, label_edit, label_edit_end
.not_found:
    xor eax, eax
    xor edx, edx

.done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    ret

match_old_difficulty_label:
    push rsi
    push rdi
    push r12
    sub rsp, 32
    trim_difficulty_input .not_found

    try_difficulty match_beginner, match_beginner_end, label_beginner, label_beginner_end
    try_difficulty match_easy, match_easy_end, label_easy, label_easy_end
    try_difficulty match_basic, match_basic_end, label_easy, label_easy_end
    try_difficulty match_light, match_light_end, label_easy, label_easy_end
    try_difficulty match_medium, match_medium_end, label_medium, label_medium_end
    try_difficulty match_another, match_another_end, label_medium, label_medium_end
    try_difficulty match_trick, match_trick_end, label_medium, label_medium_end
    try_difficulty match_standard, match_standard_end, label_medium, label_medium_end
    try_difficulty match_difficult, match_difficult_end, label_medium, label_medium_end
    try_difficulty match_hard, match_hard_end, label_hard, label_hard_end
    try_difficulty match_ssr, match_ssr_end, label_hard, label_hard_end
    try_difficulty match_maniac, match_maniac_end, label_hard, label_hard_end
    try_difficulty match_heavy, match_heavy_end, label_hard, label_hard_end
    try_difficulty match_challenge, match_challenge_end, label_challenge, label_challenge_end
    try_difficulty match_expert, match_expert_end, label_challenge, label_challenge_end
    try_difficulty match_oni, match_oni_end, label_challenge, label_challenge_end
    try_difficulty match_smaniac, match_smaniac_end, label_challenge, label_challenge_end
    try_difficulty match_edit, match_edit_end, label_edit, label_edit_end
.not_found:
    xor eax, eax
    xor edx, edx

.done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    ret

; rcx = trimmed bytes, rdx = len, r8 = lowercase tag, r9 = tag len. eax = match.
match_ci:
    cmp rdx, r9
    jne .false
    mov r10, rcx
    xor ecx, ecx

.loop:
    cmp rcx, rdx
    jae .true
    mov al, [r10 + rcx]
    cmp al, 'A'
    jb .input_ready
    cmp al, 'Z'
    ja .input_ready
    or al, 20h
.input_ready:
    cmp al, [r8 + rcx]
    jne .false
    inc rcx
    jmp .loop

.true:
    mov eax, ASSP_TRUE
    ret
.false:
    xor eax, eax
    ret

; rcx = bytes, rdx = len, r8 = lowercase tag, r9 = tag len. eax = match.
match_trim_ci:
    test rdx, rdx
    jz .check_empty
    test rcx, rcx
    jz match_ci.false
    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .empty
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .empty
    cmp byte [r11 - 1], ' '
    ja .len
    dec r11
    jmp .trim_right

.empty:
    xor edx, edx
    mov rcx, r10
    jmp match_ci

.len:
    mov rdx, r11
    sub rdx, r10
    mov rcx, r10
    jmp match_ci

.check_empty:
    test r9, r9
    jnz match_ci.false
    mov eax, ASSP_TRUE
    ret

; rcx = meter bytes, rdx = len, r8 = nonzero for .sm. rax/rdx = label.
meter_difficulty_label:
    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .empty
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .empty
    cmp byte [r11 - 1], ' '
    ja .sign
    dec r11
    jmp .trim_right

.empty:
    test r8, r8
    jz .invalid
    mov eax, 1
    jmp .select

.sign:
    xor r9d, r9d
    cmp byte [r10], '+'
    je .plus
    cmp byte [r10], '-'
    jne .digits_init
    mov r9d, ASSP_TRUE
.plus:
    inc r10
    cmp r10, r11
    jae .invalid

.digits_init:
    xor eax, eax
    xor r8d, r8d

.digits:
    cmp r10, r11
    jae .digits_done
    movzx ecx, byte [r10]
    cmp cl, '0'
    jb .invalid
    cmp cl, '9'
    ja .invalid
    imul eax, eax, 10
    sub ecx, '0'
    add eax, ecx
    mov r8d, ASSP_TRUE
    inc r10
    jmp .digits

.digits_done:
    test r8d, r8d
    jz .invalid
    test r9d, r9d
    jz .select
    neg eax
    jmp .select

.invalid:
    xor eax, eax

.select:
    cmp eax, 1
    je .beginner
    cmp eax, 3
    jle .easy
    cmp eax, 6
    jle .medium
    lea rax, [label_hard]
    mov edx, label_hard_end - label_hard
    ret

.beginner:
    lea rax, [label_beginner]
    mov edx, label_beginner_end - label_beginner
    ret
.easy:
    lea rax, [label_easy]
    mov edx, label_easy_end - label_easy
    ret
.medium:
    lea rax, [label_medium]
    mov edx, label_medium_end - label_medium
    ret

; rcx = bytes, rdx = len, r8 = optional output bytes, r9 = output byte cap.
; rax = bytes required/written, or ASSP_NOT_FOUND.
assp_trim_ascii_bytes:
    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .empty
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .empty
    cmp byte [r11 - 1], ' '
    ja .copy
    dec r11
    jmp .trim_right

.copy:
    mov rax, r11
    sub rax, r10
    test r8, r8
    jz .done
    cmp rax, r9
    ja .invalid

    xor r11d, r11d
.copy_loop:
    cmp r11, rax
    jae .done
    mov cl, [r10 + r11]
    mov [r8 + r11], cl
    inc r11
    jmp .copy_loop

.empty:
    xor eax, eax
.done:
    ret

.invalid:
    mov rax, ASSP_NOT_FOUND
    ret

section .rdata

label_beginner db "Beginner"
label_beginner_end:
label_easy db "Easy"
label_easy_end:
label_medium db "Medium"
label_medium_end:
label_hard db "Hard"
label_hard_end:
label_challenge db "Challenge"
label_challenge_end:
label_edit db "Edit"
label_edit_end:

match_beginner db "beginner"
match_beginner_end:
match_easy db "easy"
match_easy_end:
match_basic db "basic"
match_basic_end:
match_light db "light"
match_light_end:
match_medium db "medium"
match_medium_end:
match_another db "another"
match_another_end:
match_trick db "trick"
match_trick_end:
match_standard db "standard"
match_standard_end:
match_difficult db "difficult"
match_difficult_end:
match_hard db "hard"
match_hard_end:
match_ssr db "ssr"
match_ssr_end:
match_maniac db "maniac"
match_maniac_end:
match_heavy db "heavy"
match_heavy_end:
match_challenge db "challenge"
match_challenge_end:
match_expert db "expert"
match_expert_end:
match_oni db "oni"
match_oni_end:
match_smaniac db "smaniac"
match_smaniac_end:
match_edit db "edit"
match_edit_end:

section .text

; rcx = DISPLAYBPM tag bytes, rdx = len, r8 = actual min BPM,
; r9 = actual max BPM, [rsp+40] = out min BPM, [rsp+48] = out max BPM.
; Optional text outputs: [rsp+56] = out text min, [rsp+64] = out text max,
; [rsp+72] = out text range flag. Numeric outputs keep RSSP JSON-cast
; parity; text outputs mirror RSSP's formatted display string.
; eax = 1 on valid output pointers, 0 otherwise.
assp_resolve_display_bpm:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r14, [rsp + DISPLAY_ARG_OUT_MIN]
    mov r15, [rsp + DISPLAY_ARG_OUT_MAX]
    mov rdi, [rsp + DISPLAY_ARG_TEXT_MIN]
    mov rsi, [rsp + DISPLAY_ARG_TEXT_MAX]
    mov rbx, [rsp + DISPLAY_ARG_TEXT_RANGE]
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail

    mov [r14], r8
    mov [r15], r9

    call resolve_display_bpm_pair
    test eax, eax
    jz .success

    test rdx, rdx
    jle .success
    test r8, r8
    jle .success

    mov r13, rdx
    mov r12, r8

    test rbx, rbx
    jz .text_min
    xor eax, eax
    cmp r13, r12
    setne al
    mov [rbx], rax
.text_min:
    test rdi, rdi
    jz .text_max
    mov rax, r13
    call resolve_display_milli_to_int
    mov [rdi], rax
.text_max:
    test rsi, rsi
    jz .numeric
    mov rax, r12
    call resolve_display_milli_to_int
    mov [rsi], rax

.numeric:
    mov rax, r13
    call resolve_display_milli_to_int
    mov r13, rax
    mov rax, r12
    call resolve_display_milli_to_int
    mov [r14], r13
    mov [r15], rax

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

; rcx = display BPM tag bytes, rdx = len.
; eax = 1 when a non-star tag was parsed, rdx = min milli, r8 = max milli.
resolve_display_bpm_pair:
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    test rdx, rdx
    jz .fail
    test rcx, rcx
    jz .fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]

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
    ja .check_star
    dec rdi
    jmp .trim_right

.check_star:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jne .find_colon_init
    cmp byte [rsi], '*'
    je .fail

.find_colon_init:
    mov r12, rdi
    mov r13, rsi
    xor r8d, r8d

.find_colon:
    cmp r13, rdi
    jae .parse_min
    mov al, [r13]
    cmp al, ':'
    jne .not_colon
    test r8b, 1
    jnz .colon_escaped
    mov r12, r13
    jmp .parse_min
.colon_escaped:
    xor r8d, r8d
    inc r13
    jmp .find_colon
.not_colon:
    cmp al, '\'
    jne .reset_bs
    inc r8
    inc r13
    jmp .find_colon
.reset_bs:
    xor r8d, r8d
    inc r13
    jmp .find_colon

.parse_min:
    mov rcx, rsi
    mov rdx, r12
    call resolve_display_milli_prefix
    test eax, eax
    jnz .store_min
    xor edx, edx
.store_min:
    mov rbx, rdx

    cmp r12, rdi
    jae .max_same_as_min
    lea rcx, [r12 + 1]
    mov rdx, rdi
    call resolve_display_milli_prefix
    test eax, eax
    jz .max_same_as_min
    mov r8, rdx
    jmp .success

.max_same_as_min:
    mov r8, rbx

.success:
    mov rdx, rbx
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax
    xor edx, edx
    xor r8d, r8d

.done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = segment start, rdx = segment end. eax = success, rdx = signed milli.
resolve_display_milli_prefix:
    push rsi
    push rdi
    push rbx
    push r12

    mov rsi, rcx
    mov rdi, rdx

.trim_left:
    cmp rsi, rdi
    jae .fail
    cmp byte [rsi], ' '
    ja .sign
    inc rsi
    jmp .trim_left

.sign:
    xor r12d, r12d
    cmp byte [rsi], '+'
    je .plus
    cmp byte [rsi], '-'
    jne .init
    mov r12d, ASSP_TRUE
.plus:
    inc rsi
    cmp rsi, rdi
    jae .fail

.init:
    xor ebx, ebx
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    mov r11d, 100

.int_loop:
    cmp rsi, rdi
    jae .scale_frac
    movzx eax, byte [rsi]
    cmp al, '0'
    jb .check_dot
    cmp al, '9'
    ja .scale_frac
    sub eax, '0'
    imul rbx, rbx, 10
    add rbx, rax
    mov r8d, ASSP_TRUE
    inc rsi
    jmp .int_loop

.check_dot:
    cmp al, '.'
    jne .scale_frac
    inc rsi

.frac_loop:
    cmp rsi, rdi
    jae .scale_frac
    movzx eax, byte [rsi]
    cmp al, '0'
    jb .scale_frac
    cmp al, '9'
    ja .scale_frac
    sub eax, '0'
    mov r8d, ASSP_TRUE
    cmp r9d, 3
    jae .round_digit
    imul eax, r11d
    add r10, rax
    xor edx, edx
    mov eax, r11d
    mov ecx, 10
    div ecx
    mov r11d, eax
    inc r9d
    inc rsi
    jmp .frac_loop

.round_digit:
    cmp r9d, 3
    jne .ignore_extra
    cmp eax, 5
    jb .ignore_extra
    inc r10
.ignore_extra:
    inc r9d
    inc rsi
    jmp .frac_loop

.scale_frac:
    test r8d, r8d
    jz .fail

.frac_done:
    imul rbx, rbx, 1000
    add rbx, r10
    test r12d, r12d
    jz .success
    neg rbx

.success:
    mov rdx, rbx
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax
    xor edx, edx

.done:
    pop r12
    pop rbx
    pop rdi
    pop rsi
    ret

; rax = positive milli. rax = integer BPM rounded like Rust {:.0}.
resolve_display_milli_to_int:
    xor edx, edx
    mov r8d, 1000
    div r8
    cmp rdx, 500
    ja .round_up
    jb .done
    test al, 1
    jz .done
.round_up:
    inc rax
.done:
    ret

; rcx = #LABELS value bytes, rdx = len, r8 = optional output bytes,
; r9 = output byte cap. Keeps the first unescaped MSD parameter, removes
; backslash escapes, and drops ASCII control bytes.
; rax = bytes required/written, or ASSP_NOT_FOUND.
assp_normalize_label_tag:
    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rsi, rcx
    lea r12, [rcx + rdx]
    mov r13, r12
    mov rdi, r8
    mov r14, r9

    xor r15d, r15d
    mov r10, rsi
.find_param_end:
    cmp r10, r12
    jae .normalize
    mov al, [r10]
    cmp al, ':'
    jne .not_colon
    test r15b, 1
    jnz .colon_escaped
    mov r13, r10
    jmp .normalize
.colon_escaped:
    xor r15d, r15d
    inc r10
    jmp .find_param_end
.not_colon:
    cmp al, '\'
    jne .reset_bs
    inc r15
    inc r10
    jmp .find_param_end
.reset_bs:
    xor r15d, r15d
    inc r10
    jmp .find_param_end

.normalize:
    xor ebx, ebx
.normalize_loop:
    cmp rsi, r13
    jae .success
    mov al, [rsi]
    inc rsi
    cmp al, '\'
    jne .maybe_emit
    cmp rsi, r13
    jae .maybe_emit
    mov al, [rsi]
    inc rsi

.maybe_emit:
    cmp al, ' '
    jb .normalize_loop
    cmp al, 7fh
    je .normalize_loop

    test rdi, rdi
    jz .count_only
    cmp rbx, r14
    jae .fail
    mov [rdi + rbx], al
.count_only:
    inc rbx
    jmp .normalize_loop

.success:
    mov rax, rbx
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.empty:
    xor eax, eax
    ret

.invalid:
    mov rax, ASSP_NOT_FOUND
    ret
