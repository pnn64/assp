default rel
%include "assp.inc"

global assp_minimize_measure_4
global assp_minimize_measure_8
global assp_minimize_chart_4
global assp_minimize_chart_8

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

; rcx = contiguous 8-byte note rows, rdx = row count, r8 = optional output rows,
; r9 = output row cap. rax = minimized row count.
assp_minimize_measure_8:
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
    mov rax, 0x3030303030303030
    cmp [rsi + r10 * 8], rax
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
    mov rcx, [rsi + rdx * 8]
    mov [rbx + r10 * 8], rcx
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

; rcx = note-data bytes, rdx = len, r8 = optional output bytes,
; r9 = output byte cap, stack arg 5 = row scratch, stack arg 6 = scratch row cap.
; rax = bytes required/written, or ASSP_NOT_FOUND when scratch/input is invalid.
assp_minimize_chart_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    sub rsp, 64
    mov [rsp], r10
    mov [rsp + 8], r11
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .init
    test rcx, rcx
    jz .invalid

.init:
    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d

    cmp rsi, rdi
    jae .eof

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov r14, rsi
.find_line_end:
    cmp r14, rdi
    jae .line_end_found
    cmp byte [r14], 10
    je .line_end_found
    inc r14
    jmp .find_line_end

.line_end_found:
    mov r15, r14
    cmp r15, rdi
    jae .trim_left
    inc r15

.trim_left:
    cmp rsi, r14
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
    cmp rax, r14
    ja .line_done

    mov r10, [rsp]
    test r10, r10
    jz .invalid
    mov r11, [rsp + 16]
    cmp r11, [rsp + 8]
    jae .invalid
    mov eax, [rsi]
    mov [r10 + r11 * 4], eax
    inc qword [rsp + 16]
    jmp .line_done

.comma:
    call chart_finalize_measure
    mov al, ','
    call chart_append_byte
    mov al, 10
    call chart_append_byte
    jmp .line_done

.semi:
    call chart_finalize_measure
    mov qword [rsp + 24], 1
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    cmp qword [rsp + 24], 0
    jne .done
    call chart_finalize_measure

.done:
    mov rax, r13
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

chart_finalize_measure:
    cmp qword [rsp + 24], 0
    je .done

    sub rsp, 32
    mov rcx, [rsp + 40]
    mov rdx, [rsp + 56]
    mov r8, rcx
    mov r9, [rsp + 48]
    call assp_minimize_measure_4
    add rsp, 32
    mov [rsp + 40], rax

    xor r10d, r10d
.row_loop:
    cmp r10, [rsp + 40]
    jae .clear
    mov r11, [rsp + 8]
    mov ecx, [r11 + r10 * 4]
    mov al, cl
    call chart_append_byte
    mov al, ch
    call chart_append_byte
    shr ecx, 16
    mov al, cl
    call chart_append_byte
    mov al, ch
    call chart_append_byte
    mov al, 10
    call chart_append_byte
    inc r10
    jmp .row_loop

.clear:
    mov qword [rsp + 24], 0

.done:
    ret

chart_append_byte:
    test rbx, rbx
    jz .count
    cmp r13, r12
    jae .count
    mov [rbx + r13], al
.count:
    inc r13
    ret

; rcx = note-data bytes, rdx = len, r8 = optional output bytes,
; r9 = output byte cap, stack arg 5 = row scratch, stack arg 6 = scratch row cap.
; rax = bytes required/written, or ASSP_NOT_FOUND when scratch/input is invalid.
assp_minimize_chart_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    mov r11, [rsp + 104]
    sub rsp, 64
    mov [rsp], r10
    mov [rsp + 8], r11
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdx, rdx
    jz .init
    test rcx, rcx
    jz .invalid

.init:
    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d

    cmp rsi, rdi
    jae .eof

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov r14, rsi
.find_line_end:
    cmp r14, rdi
    jae .line_end_found
    cmp byte [r14], 10
    je .line_end_found
    inc r14
    jmp .find_line_end

.line_end_found:
    mov r15, r14
    cmp r15, rdi
    jae .trim_left
    inc r15

.trim_left:
    cmp rsi, r14
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
    cmp rax, r14
    ja .line_done

    mov r10, [rsp]
    test r10, r10
    jz .invalid
    mov r11, [rsp + 16]
    cmp r11, [rsp + 8]
    jae .invalid
    mov rax, [rsi]
    mov [r10 + r11 * 8], rax
    inc qword [rsp + 16]
    jmp .line_done

.comma:
    call chart_finalize_measure_8
    mov al, ','
    call chart_append_byte
    mov al, 10
    call chart_append_byte
    jmp .line_done

.semi:
    call chart_finalize_measure_8
    mov qword [rsp + 24], 1
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    cmp qword [rsp + 24], 0
    jne .done
    call chart_finalize_measure_8

.done:
    mov rax, r13
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

chart_finalize_measure_8:
    cmp qword [rsp + 24], 0
    je .done

    mov rax, [rsp + 24]
    xor r8d, r8d

    cmp rax, 2
    jb .minimized_count

    mov r9d, 2

.reduce_loop:
    mov rdx, r9
    dec rdx
    test rax, rdx
    jnz .minimized_count

    mov r10, r9
    shr r10, 1

.check_rows:
    cmp r10, rax
    jae .can_reduce
    mov r11, [rsp + 8]
    mov rdx, 0x3030303030303030
    cmp [r11 + r10 * 8], rdx
    jne .minimized_count
    add r10, r9
    jmp .check_rows

.can_reduce:
    inc r8
    shl r9, 1
    jmp .reduce_loop

.minimized_count:
    mov ecx, r8d
    mov r10d, 1
    shl r10, cl

    mov rax, [rsp + 24]
    shr rax, cl
    mov [rsp + 40], rax

    test r8, r8
    jz .output_rows

    mov r9, [rsp + 8]
    xor r11d, r11d

.copy_loop:
    cmp r11, [rsp + 40]
    jae .output_rows
    mov rdx, r11
    imul rdx, r10
    mov rcx, [r9 + rdx * 8]
    mov [r9 + r11 * 8], rcx
    inc r11
    jmp .copy_loop

.output_rows:
    xor r10d, r10d
.row_loop:
    cmp r10, [rsp + 40]
    jae .clear
    mov r11, [rsp + 8]
    mov rcx, [r11 + r10 * 8]
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    shr rcx, 8
    mov al, cl
    call chart_append_byte
    mov al, 10
    call chart_append_byte
    inc r10
    jmp .row_loop

.clear:
    mov qword [rsp + 24], 0

.done:
    ret
