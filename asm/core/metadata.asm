default rel
%include "assp.inc"

global assp_trim_ascii_bytes
global assp_normalize_label_tag

section .text

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
