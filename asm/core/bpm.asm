default rel
%include "assp.inc"

global assp_normalize_float_digits

section .text

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

    mov r10, rsi
.find_comma:
    cmp r10, r12
    jae .entry_bounds
    cmp byte [r10], ','
    je .entry_bounds
    inc r10
    jmp .find_comma

.entry_bounds:
    mov [rsp], r10
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
    ja .find_equal
    dec r11
    jmp .trim_right

.find_equal:
    mov rax, rbx
.equal_loop:
    cmp rax, r11
    jae .skip_entry
    cmp byte [rax], '='
    je .parse_fields
    inc rax
    jmp .equal_loop

.parse_fields:
    mov [rsp + 8], rax
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

; rcx = number start, rdx = number end.
; rax = absolute thousandths, edx = negative flag. ASSP_NOT_FOUND on parse failure.
parse_dec3:
    push rbx
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

.check_dot:
    cmp al, '.'
    jne .finish_number
    inc rsi
    xor r10d, r10d
    xor r11d, r11d
    xor r12d, r12d
    mov ebx, 100
    jmp .frac_loop

.frac_loop:
    cmp rsi, rdi
    jae .finish_frac
    movzx eax, byte [rsi]
    cmp al, '0'
    jb .finish_frac
    cmp al, '9'
    ja .finish_frac
    sub eax, '0'
    inc r9
    cmp r10d, 3
    jae .round_digit
    imul eax, ebx
    add r11, rax
    xor edx, edx
    mov eax, ebx
    mov ecx, 10
    div ecx
    mov ebx, eax
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

.finish_frac:
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
    pop rbx
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
    mov al, '.'
    call emit_byte
    jc .done

    mov rax, rsi
    xor edx, edx
    mov r8d, 100
    div r8
    add al, '0'
    mov rsi, rdx
    call emit_byte
    jc .done

    mov rax, rsi
    xor edx, edx
    mov r8d, 10
    div r8
    add al, '0'
    mov rsi, rdx
    call emit_byte
    jc .done

    mov al, sil
    add al, '0'
    call emit_byte

.done:
    add rsp, 40
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
