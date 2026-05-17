default rel
%include "assp.inc"

global assp_minimize_measure_4

section .text

; rcx = contiguous 4-byte note rows, rdx = row count, r8 = optional output rows,
; r9 = output row cap. rax = minimized row count.
assp_minimize_measure_4:
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
    mov rbx, r8
    mov r12, r9
    xor r14d, r14d

    cmp rdi, 2
    jb .copy

    mov r15d, 2

.reduce_loop:
    mov rax, r15
    dec rax
    test rdi, rax
    jnz .copy

    mov r10, r15
    shr r10, 1

.check_rows:
    cmp r10, rdi
    jae .can_reduce
    cmp dword [rsi + r10 * 4], 0x30303030
    jne .copy
    add r10, r15
    jmp .check_rows

.can_reduce:
    inc r14d
    shl r15, 1
    jmp .reduce_loop

.copy:
    mov r11d, 1
    mov ecx, r14d
    shl r11, cl

    mov rax, rdi
    shr rax, cl

    test rbx, rbx
    jz .done
    test r12, r12
    jz .done

    mov r13, rax
    cmp r13, r12
    jbe .copy_init
    mov r13, r12

.copy_init:
    xor r10d, r10d

.copy_loop:
    cmp r10, r13
    jae .done
    mov rdx, r10
    imul rdx, r11
    mov ecx, [rsi + rdx * 4]
    mov [rbx + r10 * 4], ecx
    inc r10
    jmp .copy_loop

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
