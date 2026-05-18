default rel
%include "assp.inc"

global assp_count_anchors_minimized_4
global assp_count_facing_steps_minimized_4

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

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = mono threshold,
; r9 = u32[2] output. out[0..2] = left-facing/right-facing mono counts.
; eax = 1 on success, 0 on failure.
assp_count_facing_steps_minimized_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    test r9, r9
    jz .facing_fail
    mov rbx, r9
    mov dword [rbx + 0], 0
    mov dword [rbx + 4], 0

    test rdx, rdx
    jz .facing_success
    test rcx, rcx
    jz .facing_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov r12, r8
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    mov qword [rsp + 0], 0

.facing_line_loop:
    cmp rsi, rdi
    jae .facing_eof

    mov r10, rsi
.facing_find_line_end:
    cmp r10, rdi
    jae .facing_line_end_found
    cmp byte [r10], 10
    je .facing_line_end_found
    inc r10
    jmp .facing_find_line_end

.facing_line_end_found:
    mov r11, r10
    cmp r11, rsi
    jbe .facing_trim_cr_done
    cmp byte [r11 - 1], 13
    jne .facing_trim_cr_done
    dec r11
.facing_trim_cr_done:
    cmp r10, rdi
    jae .facing_next_is_end
    inc r10
.facing_next_is_end:
    mov [rsp + 8], r10

    cmp rsi, r11
    jae .facing_line_done
    mov al, [rsi]
    cmp al, ','
    je .facing_line_done
    cmp al, ';'
    je .facing_eof

    lea rax, [rsi + 4]
    cmp rax, r11
    ja .facing_line_done

    xor ecx, ecx
    mov al, [rsi + 0]
    cmp al, '1'
    je .facing_set_0
    cmp al, '2'
    je .facing_set_0
    cmp al, '4'
    jne .facing_col_1
.facing_set_0:
    or ecx, 1
.facing_col_1:
    mov al, [rsi + 1]
    cmp al, '1'
    je .facing_set_1
    cmp al, '2'
    je .facing_set_1
    cmp al, '4'
    jne .facing_col_2
.facing_set_1:
    or ecx, 2
.facing_col_2:
    mov al, [rsi + 2]
    cmp al, '1'
    je .facing_set_2
    cmp al, '2'
    je .facing_set_2
    cmp al, '4'
    jne .facing_col_3
.facing_set_2:
    or ecx, 4
.facing_col_3:
    mov al, [rsi + 3]
    cmp al, '1'
    je .facing_set_3
    cmp al, '2'
    je .facing_set_3
    cmp al, '4'
    jne .facing_mask_done
.facing_set_3:
    or ecx, 8

.facing_mask_done:
    cmp ecx, 1
    je .facing_arrow_left
    cmp ecx, 2
    je .facing_arrow_down
    cmp ecx, 4
    je .facing_arrow_up
    cmp ecx, 8
    je .facing_arrow_right
    xor ecx, ecx
    jmp .facing_apply_arrow
.facing_arrow_left:
    mov ecx, 1
    jmp .facing_apply_arrow
.facing_arrow_down:
    mov ecx, 2
    jmp .facing_apply_arrow
.facing_arrow_up:
    mov ecx, 3
    jmp .facing_apply_arrow
.facing_arrow_right:
    mov ecx, 4

.facing_apply_arrow:
    test ecx, ecx
    jnz .facing_has_arrow
    test r15, r15
    jz .facing_line_done
    call .facing_finalize
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    mov qword [rsp + 0], 0
    jmp .facing_line_done

.facing_has_arrow:
    test r15, r15
    jnz .facing_continue_sequence
    xor r13d, r13d
    mov r14d, 1
    mov r15, rcx
    call .facing_forced_foot
    mov [rsp + 0], rax
    jmp .facing_line_done

.facing_continue_sequence:
    xor edx, edx
    cmp r15, 1
    je .facing_prev_left
    cmp r15, 2
    je .facing_prev_down
    cmp r15, 3
    je .facing_prev_up
    jmp .facing_prev_right

.facing_prev_left:
    cmp ecx, 3
    je .facing_dir_left
    cmp ecx, 2
    je .facing_dir_right
    jmp .facing_dir_done
.facing_prev_down:
    cmp ecx, 4
    je .facing_dir_left
    cmp ecx, 1
    je .facing_dir_right
    jmp .facing_dir_done
.facing_prev_up:
    cmp ecx, 1
    je .facing_dir_left
    cmp ecx, 4
    je .facing_dir_right
    jmp .facing_dir_done
.facing_prev_right:
    cmp ecx, 2
    je .facing_dir_left
    cmp ecx, 3
    je .facing_dir_right
    jmp .facing_dir_done
.facing_dir_left:
    mov edx, 1
    jmp .facing_dir_done
.facing_dir_right:
    mov edx, 2

.facing_dir_done:
    mov [rsp + 16], rcx
    call .facing_forced_foot
    mov r10, rax
    mov rax, [rsp + 0]
    test rax, rax
    jz .facing_store_new_foot
    test r10, r10
    jz .facing_use_opposite
    cmp rax, 1
    je .facing_expected_right
    mov r11d, 1
    jmp .facing_check_expected
.facing_expected_right:
    mov r11d, 2
.facing_check_expected:
    cmp r10, r11
    je .facing_store_new_foot
    call .facing_finalize
    xor r13d, r13d
    xor r14d, r14d
    jmp .facing_store_new_foot

.facing_use_opposite:
    cmp rax, 1
    je .facing_opp_right
    mov r10d, 1
    jmp .facing_store_new_foot
.facing_opp_right:
    mov r10d, 2

.facing_store_new_foot:
    mov [rsp + 0], r10
    mov rcx, [rsp + 16]

    test r13, r13
    jz .facing_state_wait
    cmp r13, 1
    je .facing_state_left

.facing_state_right:
    cmp edx, 1
    jne .facing_inc_count
    call .facing_finalize
    mov r13d, 1
    mov r14d, 1
    jmp .facing_step_done

.facing_state_left:
    cmp edx, 2
    jne .facing_inc_count
    call .facing_finalize
    mov r13d, 2
    mov r14d, 1
    jmp .facing_step_done

.facing_state_wait:
    cmp edx, 1
    jne .facing_wait_right
    mov r13d, 1
    inc r14
    jmp .facing_step_done
.facing_wait_right:
    cmp edx, 2
    jne .facing_inc_count
    mov r13d, 2

.facing_inc_count:
    inc r14

.facing_step_done:
    mov r15, rcx

.facing_line_done:
    mov rsi, [rsp + 8]
    jmp .facing_line_loop

.facing_eof:
    test r15, r15
    jz .facing_success
    call .facing_finalize

.facing_success:
    mov eax, ASSP_TRUE
    jmp .facing_done

.facing_fail:
    xor eax, eax

.facing_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.facing_finalize:
    cmp r14, r12
    jb .facing_finalize_done
    cmp r13, 1
    je .facing_finalize_left
    cmp r13, 2
    jne .facing_finalize_done
    add dword [rbx + 4], r14d
    ret
.facing_finalize_left:
    add dword [rbx + 0], r14d
.facing_finalize_done:
    ret

.facing_forced_foot:
    cmp ecx, 1
    je .facing_force_left
    cmp ecx, 4
    je .facing_force_right
    xor eax, eax
    ret
.facing_force_left:
    mov eax, 1
    ret
.facing_force_right:
    mov eax, 2
    ret
