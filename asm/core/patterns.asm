default rel
%include "assp.inc"

global assp_count_anchors_minimized_4

section .text

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = u32[4] output.
; out[0..4] = left/down/up/right anchors. eax = 1 on success, 0 on failure.
assp_count_anchors_minimized_4:
    push rsi
    push rdi
    push r12
    sub rsp, 32

    test r8, r8
    jz .fail
    mov r12, r8
    mov dword [r12 + 0], 0
    mov dword [r12 + 4], 0
    mov dword [r12 + 8], 0
    mov dword [r12 + 12], 0

    test rdx, rdx
    jz .success
    test rcx, rcx
    jz .fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov qword [rsp + 0], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0

.line_loop:
    cmp rsi, rdi
    jae .success

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
    cmp r11, rsi
    jbe .trim_cr_done
    cmp byte [r11 - 1], 13
    jne .trim_cr_done
    dec r11
.trim_cr_done:
    cmp r10, rdi
    jae .next_is_end
    inc r10
.next_is_end:
    mov r9, r10

    cmp rsi, r11
    jae .line_done
    mov al, [rsi]
    cmp al, ','
    je .line_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 4]
    cmp rax, r11
    ja .line_done

    xor ecx, ecx
    mov al, [rsi + 0]
    call .note_bit_0
    mov al, [rsi + 1]
    call .note_bit_1
    mov al, [rsi + 2]
    call .note_bit_2
    mov al, [rsi + 3]
    call .note_bit_3

    mov rax, [rsp + 16]
    cmp rax, 4
    jb .shift

    mov edx, [rsp + 0]
    and edx, [rsp + 8]
    and edx, ecx
    test dl, 1
    jz .check_down
    inc dword [r12 + 0]
.check_down:
    test dl, 2
    jz .check_up
    inc dword [r12 + 4]
.check_up:
    test dl, 4
    jz .check_right
    inc dword [r12 + 8]
.check_right:
    test dl, 8
    jz .shift
    inc dword [r12 + 12]

.shift:
    mov edx, [rsp + 4]
    mov [rsp + 0], edx
    mov edx, [rsp + 8]
    mov [rsp + 4], edx
    mov edx, [rsp + 12]
    mov [rsp + 8], edx
    mov [rsp + 12], ecx
    inc qword [rsp + 16]

.line_done:
    mov rsi, r9
    jmp .line_loop

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    ret

.note_bit_0:
    cmp al, '1'
    je .set_0
    cmp al, '2'
    je .set_0
    cmp al, '4'
    jne .bit_ret
.set_0:
    or ecx, 1
    ret

.note_bit_1:
    cmp al, '1'
    je .set_1
    cmp al, '2'
    je .set_1
    cmp al, '4'
    jne .bit_ret
.set_1:
    or ecx, 2
    ret

.note_bit_2:
    cmp al, '1'
    je .set_2
    cmp al, '2'
    je .set_2
    cmp al, '4'
    jne .bit_ret
.set_2:
    or ecx, 4
    ret

.note_bit_3:
    cmp al, '1'
    je .set_3
    cmp al, '2'
    je .set_3
    cmp al, '4'
    jne .bit_ret
.set_3:
    or ecx, 8
.bit_ret:
    ret
