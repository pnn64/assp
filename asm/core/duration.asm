default rel
%include "assp.inc"

global assp_last_beat_milli_4

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

; rcx = 4-panel note-data bytes, rdx = len.
; rax = last object beat in thousandths, or ASSP_NOT_FOUND on invalid input.
assp_last_beat_milli_4:
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

    xor eax, eax
    mov r10d, LOCAL_SIZE / 8
    mov r11, rsp
.zero_loop:
    mov [r11], rax
    add r11, 8
    dec r10d
    jnz .zero_loop

    mov rbx, rsp
    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r13d, r13d

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

    call scan_row_object
    test eax, eax
    jz .count_row
    mov qword [rbx + CUR_HAS], 1
    mov rax, [rbx + CUR_ROWS]
    mov [rbx + CUR_LAST_ROW], rax

.count_row:
    inc qword [rbx + CUR_ROWS]
    jmp .line_done

.comma:
    call finalize_measure
    inc r13
    jmp .line_done

.semi:
    call finalize_measure
    jmp .calc

.line_done:
    mov rsi, r15
    jmp .line_loop

.eof:
    call finalize_measure
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

    mov rax, [rbx + LAST_MEASURE]
    imul rax, rax, 192
    imul rax, r12
    mov r10, [rbx + LAST_ROW]
    imul r10, r10, 192
    add rax, r10

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

; rsi = row start. Uses DEPTHS local. eax = 1 if row has an object.
scan_row_object:
    xor r14d, r14d
    xor r8d, r8d
.lane_loop:
    cmp r8d, 4
    jae .done
    movzx eax, byte [rsi + r8]
    cmp al, '1'
    je .tap
    cmp al, 'M'
    je .tap
    cmp al, 'L'
    je .tap
    cmp al, 'F'
    je .tap
    cmp al, 'K'
    je .tap
    cmp al, '2'
    je .hold_start
    cmp al, '4'
    je .hold_start
    cmp al, '3'
    je .hold_end
    jmp .next

.tap:
    mov r14d, ASSP_TRUE
    mov dword [rbx + DEPTHS + r8 * 4], 0
    jmp .next

.hold_start:
    inc dword [rbx + DEPTHS + r8 * 4]
    jmp .next

.hold_end:
    cmp dword [rbx + DEPTHS + r8 * 4], 0
    je .next
    dec dword [rbx + DEPTHS + r8 * 4]
    mov r14d, ASSP_TRUE

.next:
    inc r8d
    jmp .lane_loop

.done:
    mov eax, r14d
    ret

; r13 = current measure index.
finalize_measure:
    cmp qword [rbx + CUR_HAS], 0
    je .clear
    mov qword [rbx + LAST_HAS], 1
    mov [rbx + LAST_MEASURE], r13
    mov rax, [rbx + CUR_LAST_ROW]
    mov [rbx + LAST_ROW], rax
    mov rax, [rbx + CUR_ROWS]
    mov [rbx + LAST_ROWS], rax

.clear:
    mov qword [rbx + CUR_ROWS], 0
    mov qword [rbx + CUR_LAST_ROW], 0
    mov qword [rbx + CUR_HAS], 0
    ret
