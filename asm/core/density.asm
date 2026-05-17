default rel
%include "assp.inc"

global assp_measure_densities_4
global assp_measure_densities_8

section .text

; rcx = note-data bytes, rdx = len, r8 = optional u32 output, r9 = output cap.
; rax = total measure count. Writes up to out_cap densities when out is non-null.
assp_measure_densities_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .zero

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d
    xor r14d, r14d

    cmp rsi, rdi
    jae .eof

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov r10, rsi
.find_line_end:
    cmp r10, rdi
    jae .line_end_found
    cmp byte [r10], 10
    je .line_end_found
    inc r10
    jmp .find_line_end

.line_end_found:
    mov r11, r10
    cmp r10, rdi
    jae .next_is_end
    inc r10
.next_is_end:
    mov r15, r10

.trim_left:
    cmp rsi, r11
    jae .line_done
    cmp byte [rsi], ' '
    ja .line_start
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
    cmp rax, r11
    ja .line_done

    cmp byte [rsi + 0], '1'
    je .step_row
    cmp byte [rsi + 0], '2'
    je .step_row
    cmp byte [rsi + 0], '4'
    je .step_row
    cmp byte [rsi + 1], '1'
    je .step_row
    cmp byte [rsi + 1], '2'
    je .step_row
    cmp byte [rsi + 1], '4'
    je .step_row
    cmp byte [rsi + 2], '1'
    je .step_row
    cmp byte [rsi + 2], '2'
    je .step_row
    cmp byte [rsi + 2], '4'
    je .step_row
    cmp byte [rsi + 3], '1'
    je .step_row
    cmp byte [rsi + 3], '2'
    je .step_row
    cmp byte [rsi + 3], '4'
    jne .line_done

.step_row:
    inc r14d
    jmp .line_done

.comma:
    call store_density
    xor r14d, r14d
    jmp .line_done

.semi:
    call store_density
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    call store_density
    jmp .done

.zero:
    xor eax, eax
    jmp .pop_done

.done:
    mov rax, r13

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

store_density:
    test rbx, rbx
    jz .count
    cmp r13, r12
    jae .count
    mov [rbx + r13 * 4], r14d
.count:
    inc r13
    ret

; rcx = note-data bytes, rdx = len, r8 = optional u32 output, r9 = output cap.
; rax = total measure count. Writes up to out_cap densities when out is non-null.
assp_measure_densities_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .zero

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d
    xor r14d, r14d

    cmp rsi, rdi
    jae .eof

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov r10, rsi
.find_line_end:
    cmp r10, rdi
    jae .line_end_found
    cmp byte [r10], 10
    je .line_end_found
    inc r10
    jmp .find_line_end

.line_end_found:
    mov r11, r10
    cmp r10, rdi
    jae .next_is_end
    inc r10
.next_is_end:
    mov r15, r10

.trim_left:
    cmp rsi, r11
    jae .line_done
    cmp byte [rsi], ' '
    ja .line_start
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
    cmp rax, r11
    ja .line_done

    cmp byte [rsi + 0], '1'
    je .step_row
    cmp byte [rsi + 0], '2'
    je .step_row
    cmp byte [rsi + 0], '4'
    je .step_row
    cmp byte [rsi + 1], '1'
    je .step_row
    cmp byte [rsi + 1], '2'
    je .step_row
    cmp byte [rsi + 1], '4'
    je .step_row
    cmp byte [rsi + 2], '1'
    je .step_row
    cmp byte [rsi + 2], '2'
    je .step_row
    cmp byte [rsi + 2], '4'
    je .step_row
    cmp byte [rsi + 3], '1'
    je .step_row
    cmp byte [rsi + 3], '2'
    je .step_row
    cmp byte [rsi + 3], '4'
    je .step_row
    cmp byte [rsi + 4], '1'
    je .step_row
    cmp byte [rsi + 4], '2'
    je .step_row
    cmp byte [rsi + 4], '4'
    je .step_row
    cmp byte [rsi + 5], '1'
    je .step_row
    cmp byte [rsi + 5], '2'
    je .step_row
    cmp byte [rsi + 5], '4'
    je .step_row
    cmp byte [rsi + 6], '1'
    je .step_row
    cmp byte [rsi + 6], '2'
    je .step_row
    cmp byte [rsi + 6], '4'
    je .step_row
    cmp byte [rsi + 7], '1'
    je .step_row
    cmp byte [rsi + 7], '2'
    je .step_row
    cmp byte [rsi + 7], '4'
    jne .line_done

.step_row:
    inc r14d
    jmp .line_done

.comma:
    call store_density
    xor r14d, r14d
    jmp .line_done

.semi:
    call store_density
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    call store_density
    jmp .done

.zero:
    xor eax, eax
    jmp .pop_done

.done:
    mov rax, r13

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
