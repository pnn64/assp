default rel
%include "assp.inc"

global assp_last_beat_milli_4
global assp_last_beat_milli_8

%define CUR_ROWS 0
%define CUR_LAST_ROW 8
%define CUR_HAS 16
%define LAST_MEASURE 24
%define LAST_ROW 32
%define LAST_ROWS 40
%define LAST_HAS 48
%define DEPTHS 56
%define LOCAL_SIZE 96

section .text

%macro ASSP_INIT_LAST_BEAT_LOCALS 0
    mov rsi, rcx
    xor eax, eax
    mov ecx, LOCAL_SIZE / 8
    mov rdi, rsp
    rep stosq

    mov rbx, rsp
    lea rdi, [rsi + rdx]
    lea r12, [rel duration_note_types]
    xor r13d, r13d
%endmacro

%macro ASSP_SCAN_ROW_OBJECT 1
    xor r14d, r14d
%if %1 = 4
    cmp dword [rsi], 30303030h
    je %%done
%endif
    xor r8d, r8d
%%lane_loop:
    cmp r8d, %1
    jae %%done
    movzx eax, byte [rsi + r8]
    movzx eax, byte [r12 + rax]
    cmp al, 1
    je %%tap
    cmp al, 2
    je %%hold_start
    cmp al, 3
    je %%hold_end
    jmp %%next

%%tap:
    mov r14d, ASSP_TRUE
    mov dword [rbx + DEPTHS + r8 * 4], 0
    jmp %%next

%%hold_start:
    inc dword [rbx + DEPTHS + r8 * 4]
    jmp %%next

%%hold_end:
    cmp dword [rbx + DEPTHS + r8 * 4], 0
    je %%next
    dec dword [rbx + DEPTHS + r8 * 4]
    mov r14d, ASSP_TRUE

%%next:
    inc r8d
    jmp %%lane_loop

%%done:
    mov eax, r14d
%endmacro

%macro ASSP_FINALIZE_MEASURE 0
    cmp qword [rbx + CUR_HAS], 0
    je %%clear
    mov qword [rbx + LAST_HAS], 1
    mov [rbx + LAST_MEASURE], r13
    mov rax, [rbx + CUR_LAST_ROW]
    mov [rbx + LAST_ROW], rax
    mov rax, [rbx + CUR_ROWS]
    mov [rbx + LAST_ROWS], rax

%%clear:
    mov qword [rbx + CUR_ROWS], 0
    mov qword [rbx + CUR_LAST_ROW], 0
    mov qword [rbx + CUR_HAS], 0
%endmacro

%macro ASSP_LAST_BEAT_MILLI 2
; rcx = %2-panel note-data bytes, rdx = len.
; rax = last object beat in thousandths, or ASSP_NOT_FOUND on invalid input.
%1:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, LOCAL_SIZE

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .invalid

    ASSP_INIT_LAST_BEAT_LOCALS

.line_loop:
    cmp rsi, rdi
    jae .eof

.fast_line:
    mov al, [rsi]
    cmp al, ';'
    je .semi
    cmp al, ','
    je .fast_comma
    cmp al, '/'
    je .find_line_end_slow
    cmp al, ' '
    jbe .find_line_end_slow

    lea r10, [rsi + %2]
    cmp r10, rdi
    ja .find_line_end_slow
    cmp byte [r10], 10
    je .fast_row_lf
    cmp byte [r10], 13
    je .fast_row_cr
    jmp .find_line_end_slow

.fast_row_lf:
    lea r15, [r10 + 1]
    jmp .scan_row

.fast_row_cr:
    lea r11, [r10 + 1]
    cmp r11, rdi
    jae .find_line_end_slow
    cmp byte [r11], 10
    jne .find_line_end_slow
    lea r15, [r10 + 2]
    jmp .scan_row

.fast_comma:
    lea r10, [rsi + 1]
    cmp r10, rdi
    jae .fast_comma_eof
    cmp byte [r10], 10
    je .fast_comma_lf
    cmp byte [r10], 13
    je .fast_comma_cr
    jmp .find_line_end_slow

.fast_comma_eof:
    mov r15, r10
    jmp .comma

.fast_comma_lf:
    lea r15, [rsi + 2]
    jmp .comma

.fast_comma_cr:
    lea r11, [r10 + 1]
    cmp r11, rdi
    jae .find_line_end_slow
    cmp byte [r11], 10
    jne .find_line_end_slow
    lea r15, [rsi + 3]
    jmp .comma

.find_line_end_slow:
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

    lea rax, [rsi + %2]
    cmp rax, r11
    ja .line_done

.scan_row:
    ASSP_SCAN_ROW_OBJECT %2
    test eax, eax
    jz .count_row
    mov qword [rbx + CUR_HAS], 1
    mov rax, [rbx + CUR_ROWS]
    mov [rbx + CUR_LAST_ROW], rax

.count_row:
    inc qword [rbx + CUR_ROWS]
    jmp .line_done

.comma:
    ASSP_FINALIZE_MEASURE
    inc r13
    jmp .line_done

.semi:
    ASSP_FINALIZE_MEASURE
    jmp .calc

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    ASSP_FINALIZE_MEASURE
    jmp .calc

.empty:
    xor eax, eax
    jmp .pop_done

.invalid:
    mov rax, ASSP_NOT_FOUND
    jmp .pop_done

.calc:
    cmp qword [rbx + LAST_HAS], 0
    je .empty
    mov r12, [rbx + LAST_ROWS]
    test r12, r12
    jz .empty

    ; Round the last object to RSSP's 192-row beat grid:
    ; ((measure * rows + row) * 192) / rows, ties to even.
    mov rax, [rbx + LAST_MEASURE]
    imul rax, r12
    add rax, [rbx + LAST_ROW]
    imul rax, rax, 192

    xor edx, edx
    div r12
    mov r10, rax
    mov r11, rdx
    shl r11, 1
    cmp r11, r12
    ja .round_row_up
    jb .row_done
    test r10, 1
    jz .row_done
.round_row_up:
    inc r10

.row_done:
    mov rax, r10
    imul rax, rax, 1000
    add rax, 24
    xor edx, edx
    mov r10d, 48
    div r10

.pop_done:
    add rsp, LOCAL_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
%endmacro

ASSP_LAST_BEAT_MILLI assp_last_beat_milli_4, 4
ASSP_LAST_BEAT_MILLI assp_last_beat_milli_8, 8

section .rdata

align 16
duration_note_types:
    times '1' db 0
    db 1
    db 2
    db 3
    db 2
    times 'F' - '4' - 1 db 0
    db 1
    times 'K' - 'F' - 1 db 0
    db 1
    db 1
    db 1
    times 256 - 'M' - 1 db 0
