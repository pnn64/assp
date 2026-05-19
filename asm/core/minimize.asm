default rel
%include "assp.inc"

global assp_minimize_measure_4
global assp_minimize_measure_8
global assp_minimize_chart_4
global assp_minimize_chart_8

section .text

%macro ASSP_MINIMIZE_MEASURE 2
; rcx = contiguous %2-byte note rows, rdx = row count,
; r8 = optional output rows, r9 = output row cap.
; rax = minimized row count.
%1:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rdx, rdx
    jz %%zero
    test rcx, rcx
    jz %%zero

    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    mov r12, r9
    xor r14d, r14d

    cmp rdi, 2
    jb %%copy

    mov r15d, 2

%%reduce_loop:
    mov rax, r15
    dec rax
    test rdi, rax
    jnz %%copy

    mov r10, r15
    shr r10, 1

%%check_rows:
    cmp r10, rdi
    jae %%can_reduce
%if %2 = 4
    cmp dword [rsi + r10 * 4], 0x30303030
%elif %2 = 8
    mov rax, 0x3030303030303030
    cmp [rsi + r10 * 8], rax
%endif
    jne %%copy
    add r10, r15
    jmp %%check_rows

%%can_reduce:
    inc r14d
    shl r15, 1
    jmp %%reduce_loop

%%copy:
    mov ecx, r14d
    mov rax, rdi
    shr rax, cl

    test rbx, rbx
    jz %%done
    test r12, r12
    jz %%done

    mov r13, rax
    cmp r13, r12
    jbe %%copy_init
    mov r13, r12

%%copy_init:
    mov ecx, r14d
    mov r11d, %2
    shl r11, cl
    mov rdx, rsi
    mov r15, rbx
    xor r10d, r10d

%%copy_loop:
    cmp r10, r13
    jae %%done
%if %2 = 4
    mov ecx, [rdx]
    mov [r15], ecx
%elif %2 = 8
    mov rcx, [rdx]
    mov [r15], rcx
%endif
    add rdx, r11
    add r15, %2
    inc r10
    jmp %%copy_loop

%%zero:
    xor eax, eax

%%done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
%endmacro

ASSP_MINIMIZE_MEASURE assp_minimize_measure_4, 4
ASSP_MINIMIZE_MEASURE assp_minimize_measure_8, 8

%macro ASSP_APPEND_BYTE 0
    test rbx, rbx
    jz %%count
    cmp r13, r12
    jae %%count
    mov [rbx + r13], al
%%count:
    inc r13
%endmacro

%macro ASSP_APPEND_ROW 1
    test rbx, rbx
    jz %%count_only
    mov rax, r13
    add rax, %1 + 1
    cmp rax, r12
    ja %%slow
%if %1 = 4
    mov eax, [r11 + r10 * 4]
    mov [rbx + r13], eax
    mov byte [rbx + r13 + 4], 10
%elif %1 = 8
    mov rax, [r11 + r10 * 8]
    mov [rbx + r13], rax
    mov byte [rbx + r13 + 8], 10
%endif
    add r13, %1 + 1
    jmp %%done

%%slow:
%if %1 = 4
    mov ecx, [r11 + r10 * 4]
    mov al, cl
    ASSP_APPEND_BYTE
    mov al, ch
    ASSP_APPEND_BYTE
    shr ecx, 16
    mov al, cl
    ASSP_APPEND_BYTE
    mov al, ch
    ASSP_APPEND_BYTE
%elif %1 = 8
    mov rcx, [r11 + r10 * 8]
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
    shr rcx, 8
    mov al, cl
    ASSP_APPEND_BYTE
%endif
    mov al, 10
    ASSP_APPEND_BYTE
    jmp %%done

%%count_only:
    add r13, %1 + 1

%%done:
%endmacro

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
    ASSP_APPEND_BYTE
    mov al, 10
    ASSP_APPEND_BYTE
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

    ; Safe in place: minimized rows are copied from a nondecreasing source index.
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
    ASSP_APPEND_ROW 4
    inc r10
    jmp .row_loop

.clear:
    mov qword [rsp + 24], 0

.done:
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
    ASSP_APPEND_BYTE
    mov al, 10
    ASSP_APPEND_BYTE
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

    ; Safe in place: minimized rows are copied from a nondecreasing source index.
    sub rsp, 32
    mov rcx, [rsp + 40]
    mov rdx, [rsp + 56]
    mov r8, rcx
    mov r9, [rsp + 48]
    call assp_minimize_measure_8
    add rsp, 32
    mov [rsp + 40], rax

    xor r10d, r10d
.row_loop:
    cmp r10, [rsp + 40]
    jae .clear
    mov r11, [rsp + 8]
    ASSP_APPEND_ROW 8
    inc r10
    jmp .row_loop

.clear:
    mov qword [rsp + 24], 0

.done:
    ret
