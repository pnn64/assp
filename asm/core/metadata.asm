default rel
%include "assp.inc"

global assp_trim_ascii_bytes
global assp_normalize_label_tag
global assp_resolve_display_bpm
global assp_steps_timing_allowed

section .text

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

; rcx = DISPLAYBPM tag bytes, rdx = len, r8 = actual min BPM,
; r9 = actual max BPM, [rsp+40] = out min BPM, [rsp+48] = out max BPM.
; Outputs are whole BPMs formatted like RSSP's rate=1 display values.
; eax = 1 on valid output pointers, 0 otherwise.
assp_resolve_display_bpm:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r14, [rsp + 96]
    mov r15, [rsp + 104]
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

    mov r12, r8
    mov rax, rdx
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
