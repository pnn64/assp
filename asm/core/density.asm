default rel
%include "assp.inc"

global assp_measure_densities_4
global assp_measure_densities_8
global assp_measure_equally_spaced_minimized_4
global assp_measure_equally_spaced_minimized_8

section .text

%macro ASSP_ROW_STEP_FLAG4 2
    cmp dword [%1], 30303030h
    jne %%check
    xor eax, eax
    jmp %%done

%%check:
    movzx eax, word [%1]
    movzx ecx, word [%1 + 2]
    movzx eax, byte [%2 + rax]
    or al, [%2 + rcx]
    movzx eax, al

%%done:
%endmacro

%macro ASSP_ROW_STEP_FLAG 3
%if %2 == 4
    ASSP_ROW_STEP_FLAG4 %1, %3
%else
    cmp dword [%1], 30303030h
    jne %%check_both
    cmp dword [%1 + 4], 30303030h
    jne %%check_hi
    xor eax, eax
    jmp %%done
%%check_hi:
    ASSP_ROW_STEP_FLAG4 %1 + 4, %3
    jmp %%done
%%check_both:
    ASSP_ROW_STEP_FLAG4 %1, %3
    test eax, eax
    jnz %%done
    ASSP_ROW_STEP_FLAG4 %1 + 4, %3
%endif
%%done:
%endmacro

%macro ASSP_STORE_DENSITY 0
    test rbx, rbx
    jz %%count
    cmp r13, r12
    jae %%count
    mov [rbx + r13 * 4], r14d
%%count:
    inc r13
%endmacro

%macro ASSP_STORE_EQUALLY 0
    test rbx, rbx
    jz %%count
    cmp r13, r12
    jae %%count
    xor eax, eax
    cmp r14, r15
    jne %%write
    mov al, 1
%%write:
    mov [rbx + r13], al
%%count:
    inc r13
%endmacro

%macro ASSP_EQUALLY_SPACED_MINIMIZED 2
; rcx = minimized note-data bytes, rdx = len, r8 = optional u8 output, r9 = output cap.
; rax = total measure count. Writes 1 for equally spaced measures and 0 otherwise.
align 32
%1:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz %%zero

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    lea r8, [rel density_note_step_pair_table]

%%line_loop:
    cmp rsi, rdi
    jae %%eof

    mov al, [rsi]
    cmp al, 10
    je %%fast_blank_lf
    cmp al, 13
    je %%fast_blank_cr
    cmp al, ','
    je %%fast_comma
    cmp al, ';'
    je %%fast_semi

    lea rax, [rsi + %2]
    cmp rax, rdi
    ja %%slow_line
    mov al, [rsi + %2]
    cmp al, 10
    je %%fast_row_lf
    cmp al, 13
    je %%fast_row_cr
    jmp %%slow_line

%%fast_blank_lf:
    inc rsi
    jmp %%line_loop

%%fast_blank_cr:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae %%eof
    cmp byte [rsi + 1], 10
    jne %%slow_line
    lea rsi, [rsi + 2]
    jmp %%line_loop

%%fast_comma:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae %%slow_line
    cmp byte [rsi + 1], 10
    je %%fast_comma_lf
    cmp byte [rsi + 1], 13
    jne %%slow_line
    lea rax, [rsi + 2]
    cmp rax, rdi
    jae %%slow_line
    cmp byte [rsi + 2], 10
    jne %%slow_line
    ASSP_STORE_EQUALLY
    xor r14d, r14d
    xor r15d, r15d
    lea rsi, [rsi + 3]
    jmp %%line_loop
%%fast_comma_lf:
    ASSP_STORE_EQUALLY
    xor r14d, r14d
    xor r15d, r15d
    lea rsi, [rsi + 2]
    jmp %%line_loop

%%fast_semi:
    ASSP_STORE_EQUALLY
    jmp %%done

%%fast_row_lf:
%if %2 = 4
    cmp dword [rsi], 30303030h
%elif %2 = 8
    cmp qword [rsi], 3030303030303030h
%endif
    je %%zero_run_lf
    inc r14
    ASSP_ROW_STEP_FLAG rsi, %2, r8
    add r15, rax
    lea rsi, [rsi + %2 + 1]
    jmp %%line_loop

%%zero_run_lf:
    xor r11d, r11d
%%zero_run_loop:
    inc r11
    lea rsi, [rsi + %2 + 1]
    cmp rsi, rdi
    jae %%zero_run_done
    lea rax, [rsi + %2]
    cmp rax, rdi
    jae %%zero_run_done
%if %2 = 4
    cmp dword [rsi], 30303030h
%elif %2 = 8
    cmp qword [rsi], 3030303030303030h
%endif
    jne %%zero_run_done
    cmp byte [rax], 10
    je %%zero_run_loop
%%zero_run_done:
    add r14, r11
    jmp %%line_loop

%%fast_row_cr:
    lea rax, [rsi + %2 + 1]
    cmp rax, rdi
    jae %%slow_line
    cmp byte [rsi + %2 + 1], 10
    jne %%slow_line
    inc r14
    ASSP_ROW_STEP_FLAG rsi, %2, r8
    add r15, rax
    lea rsi, [rsi + %2 + 2]
    jmp %%line_loop

%%slow_line:
    mov r10, rsi
%%find_line_end:
    cmp r10, rdi
    jae %%line_end_found
    cmp byte [r10], 10
    je %%line_end_found
    inc r10
    jmp %%find_line_end

%%line_end_found:
    mov r11, r10
    cmp r11, rsi
    jbe %%trim_cr_done
    cmp byte [r11 - 1], 13
    jne %%trim_cr_done
    dec r11
%%trim_cr_done:
    cmp r10, rdi
    jae %%next_is_end
    inc r10
%%next_is_end:
    mov r9, r10

    cmp rsi, r11
    jae %%line_done
    mov al, [rsi]
    cmp al, ','
    je %%comma
    cmp al, ';'
    je %%semi

    lea rax, [rsi + %2]
    cmp rax, r11
    ja %%line_done

    inc r14
    ASSP_ROW_STEP_FLAG rsi, %2, r8
    add r15, rax
    jmp %%line_done

%%comma:
    ASSP_STORE_EQUALLY
    xor r14d, r14d
    xor r15d, r15d
    jmp %%line_done

%%semi:
    ASSP_STORE_EQUALLY
    jmp %%done

%%line_done:
    mov rsi, r9
    jmp %%line_loop

%%eof:
    ASSP_STORE_EQUALLY
    jmp %%done

%%zero:
    xor eax, eax
    jmp %%pop_done

%%done:
    mov rax, r13

%%pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
%endmacro

ASSP_EQUALLY_SPACED_MINIMIZED assp_measure_equally_spaced_minimized_4, 4
ASSP_EQUALLY_SPACED_MINIMIZED assp_measure_equally_spaced_minimized_8, 8

; rcx = note-data bytes, rdx = len, r8 = optional u32 output, r9 = output cap.
; rax = total measure count. Writes up to out_cap densities when out is non-null.
align 32
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
    lea r8, [rel density_note_step_pair_table]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov al, [rsi]
    cmp al, 10
    je .fast_blank_lf
    cmp al, 13
    je .fast_blank_cr
    cmp al, ' '
    jbe .slow_line
    cmp al, '/'
    je .slow_line
    cmp al, ','
    je .fast_comma
    cmp al, ';'
    je .fast_semi

    lea rax, [rsi + 4]
    cmp rax, rdi
    ja .slow_line
    mov al, [rsi + 4]
    cmp al, 10
    je .fast_row_lf
    cmp al, 13
    je .fast_row_cr
    jmp .slow_line

.fast_blank_lf:
    inc rsi
    jmp .line_loop

.fast_blank_cr:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae .eof
    cmp byte [rsi + 1], 10
    jne .slow_line
    lea rsi, [rsi + 2]
    jmp .line_loop

.fast_comma:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 1], 10
    je .fast_comma_lf
    cmp byte [rsi + 1], 13
    jne .slow_line
    lea rax, [rsi + 2]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 2], 10
    jne .slow_line
    ASSP_STORE_DENSITY
    xor r14d, r14d
    lea rsi, [rsi + 3]
    jmp .line_loop
.fast_comma_lf:
    ASSP_STORE_DENSITY
    xor r14d, r14d
    lea rsi, [rsi + 2]
    jmp .line_loop

.fast_semi:
    ASSP_STORE_DENSITY
    jmp .done

.fast_row_lf:
    cmp dword [rsi], 30303030h
    je .zero_run_lf
    ASSP_ROW_STEP_FLAG rsi, 4, r8
    add r14d, eax
    lea rsi, [rsi + 5]
    jmp .line_loop

.zero_run_lf:
    lea rsi, [rsi + 5]
    cmp rsi, rdi
    jae .line_loop
    lea rax, [rsi + 4]
    cmp rax, rdi
    jae .line_loop
    cmp dword [rsi], 30303030h
    jne .line_loop
    cmp byte [rax], 10
    je .zero_run_lf
    jmp .line_loop

.fast_row_cr:
    lea rax, [rsi + 5]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 5], 10
    jne .slow_line
    ASSP_ROW_STEP_FLAG rsi, 4, r8
    add r14d, eax
    lea rsi, [rsi + 6]
    jmp .line_loop

.slow_line:
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

    ASSP_ROW_STEP_FLAG rsi, 4, r8
    add r14d, eax
    jmp .line_done

.comma:
    ASSP_STORE_DENSITY
    xor r14d, r14d
    jmp .line_done

.semi:
    ASSP_STORE_DENSITY
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    ASSP_STORE_DENSITY
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

section .rdata
align 64
density_note_step_pair_table:
%assign i 0
%rep 65536
%assign lo (i & 0ffh)
%assign hi ((i >> 8) & 0ffh)
%if lo = '1' || lo = '2' || lo = '4' || hi = '1' || hi = '2' || hi = '4'
    db 1
%else
    db 0
%endif
%assign i i+1
%endrep

section .text

; rcx = note-data bytes, rdx = len, r8 = optional u32 output, r9 = output cap.
; rax = total measure count. Writes up to out_cap densities when out is non-null.
align 32
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
    lea r8, [rel density_note_step_pair_table]

.line_loop:
    cmp rsi, rdi
    jae .eof

    mov al, [rsi]
    cmp al, 10
    je .fast_blank_lf
    cmp al, 13
    je .fast_blank_cr
    cmp al, ' '
    jbe .slow_line
    cmp al, '/'
    je .slow_line
    cmp al, ','
    je .fast_comma
    cmp al, ';'
    je .fast_semi

    lea rax, [rsi + 8]
    cmp rax, rdi
    ja .slow_line
    mov al, [rsi + 8]
    cmp al, 10
    je .fast_row_lf
    cmp al, 13
    je .fast_row_cr
    jmp .slow_line

.fast_blank_lf:
    inc rsi
    jmp .line_loop

.fast_blank_cr:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae .eof
    cmp byte [rsi + 1], 10
    jne .slow_line
    lea rsi, [rsi + 2]
    jmp .line_loop

.fast_comma:
    lea rax, [rsi + 1]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 1], 10
    je .fast_comma_lf
    cmp byte [rsi + 1], 13
    jne .slow_line
    lea rax, [rsi + 2]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 2], 10
    jne .slow_line
    ASSP_STORE_DENSITY
    xor r14d, r14d
    lea rsi, [rsi + 3]
    jmp .line_loop
.fast_comma_lf:
    ASSP_STORE_DENSITY
    xor r14d, r14d
    lea rsi, [rsi + 2]
    jmp .line_loop

.fast_semi:
    ASSP_STORE_DENSITY
    jmp .done

.fast_row_lf:
    cmp qword [rsi], 3030303030303030h
    je .zero_run_lf
    ASSP_ROW_STEP_FLAG rsi, 8, r8
    add r14d, eax
    lea rsi, [rsi + 9]
    jmp .line_loop

.zero_run_lf:
    lea rsi, [rsi + 9]
    cmp rsi, rdi
    jae .line_loop
    lea rax, [rsi + 8]
    cmp rax, rdi
    jae .line_loop
    cmp qword [rsi], 3030303030303030h
    jne .line_loop
    cmp byte [rax], 10
    je .zero_run_lf
    jmp .line_loop

.fast_row_cr:
    lea rax, [rsi + 9]
    cmp rax, rdi
    jae .slow_line
    cmp byte [rsi + 9], 10
    jne .slow_line
    ASSP_ROW_STEP_FLAG rsi, 8, r8
    add r14d, eax
    lea rsi, [rsi + 10]
    jmp .line_loop

.slow_line:
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

    ASSP_ROW_STEP_FLAG rsi, 8, r8
    add r14d, eax
    jmp .line_done

.comma:
    ASSP_STORE_DENSITY
    xor r14d, r14d
    jmp .line_done

.semi:
    ASSP_STORE_DENSITY
    jmp .done

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    ASSP_STORE_DENSITY
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
