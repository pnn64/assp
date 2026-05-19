default rel
%include "assp.inc"

global assp_count_anchors_minimized_4
global assp_count_facing_steps_minimized_4
global assp_count_basic_patterns_minimized_4
global assp_count_default_patterns_minimized_4
global assp_pattern_percentages_centi

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

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = assp_basic_patterns* out.
; Counts RSSP's default candle and box-family patterns. eax = 1 on success.
assp_count_basic_patterns_minimized_4:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32

    test r8, r8
    jz .basic_fail
    mov rbx, r8
    mov qword [rbx + 0], 0
    mov qword [rbx + 8], 0
    mov qword [rbx + 16], 0
    mov qword [rbx + 24], 0

    test rdx, rdx
    jz .basic_success
    test rcx, rcx
    jz .basic_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
    mov dword [rsp + 0], 0
    mov dword [rsp + 4], 0
    mov dword [rsp + 8], 0

.basic_line_loop:
    cmp rsi, rdi
    jae .basic_success

    mov r10, rsi
.basic_find_line_end:
    cmp r10, rdi
    jae .basic_line_end_found
    cmp byte [r10], 10
    je .basic_line_end_found
    inc r10
    jmp .basic_find_line_end

.basic_line_end_found:
    mov r11, r10
    cmp r11, rsi
    jbe .basic_trim_cr_done
    cmp byte [r11 - 1], 13
    jne .basic_trim_cr_done
    dec r11
.basic_trim_cr_done:
    cmp r10, rdi
    jae .basic_next_is_end
    inc r10
.basic_next_is_end:
    mov [rsp + 16], r10

    cmp rsi, r11
    jae .basic_line_done
    mov al, [rsi]
    cmp al, ','
    je .basic_line_done
    cmp al, ';'
    je .basic_success

    lea rax, [rsi + 4]
    cmp rax, r11
    ja .basic_line_done

    xor ecx, ecx
    mov al, [rsi + 0]
    cmp al, '1'
    je .basic_set_0
    cmp al, '2'
    je .basic_set_0
    cmp al, '4'
    jne .basic_col_1
.basic_set_0:
    or ecx, 1
.basic_col_1:
    mov al, [rsi + 1]
    cmp al, '1'
    je .basic_set_1
    cmp al, '2'
    je .basic_set_1
    cmp al, '4'
    jne .basic_col_2
.basic_set_1:
    or ecx, 2
.basic_col_2:
    mov al, [rsi + 2]
    cmp al, '1'
    je .basic_set_2
    cmp al, '2'
    je .basic_set_2
    cmp al, '4'
    jne .basic_col_3
.basic_set_2:
    or ecx, 4
.basic_col_3:
    mov al, [rsi + 3]
    cmp al, '1'
    je .basic_set_3
    cmp al, '2'
    je .basic_set_3
    cmp al, '4'
    jne .basic_mask_done
.basic_set_3:
    or ecx, 8

.basic_mask_done:
    cmp r12, 2
    jb .basic_boxes

    mov eax, [rsp + 4]
    mov edx, [rsp + 8]
    cmp eax, 4
    jne .basic_candle_dlu
    cmp edx, 1
    jne .basic_candle_dlu
    cmp ecx, 2
    jne .basic_candle_right_urd
    inc dword [rbx + ASSP_BASIC_PATTERNS_CANDLE_LEFT]
    jmp .basic_candle_right_urd

.basic_candle_dlu:
    cmp eax, 2
    jne .basic_candle_right_urd
    cmp edx, 1
    jne .basic_candle_right_urd
    cmp ecx, 4
    jne .basic_candle_right_urd
    inc dword [rbx + ASSP_BASIC_PATTERNS_CANDLE_LEFT]

.basic_candle_right_urd:
    cmp eax, 4
    jne .basic_candle_right_dru
    cmp edx, 8
    jne .basic_candle_right_dru
    cmp ecx, 2
    jne .basic_boxes
    inc dword [rbx + ASSP_BASIC_PATTERNS_CANDLE_RIGHT]
    jmp .basic_boxes

.basic_candle_right_dru:
    cmp eax, 2
    jne .basic_boxes
    cmp edx, 8
    jne .basic_boxes
    cmp ecx, 4
    jne .basic_boxes
    inc dword [rbx + ASSP_BASIC_PATTERNS_CANDLE_RIGHT]

.basic_boxes:
    cmp r12, 3
    jb .basic_shift

    mov eax, [rsp + 0]
    mov edx, [rsp + 4]
    mov r10d, [rsp + 8]

    cmp eax, 1
    jne .basic_box_lr_rev
    cmp edx, 8
    jne .basic_box_lr_rev
    cmp r10d, 1
    jne .basic_box_lr_rev
    cmp ecx, 8
    jne .basic_box_ud
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LR]
    jmp .basic_box_ud
.basic_box_lr_rev:
    cmp eax, 8
    jne .basic_box_ud
    cmp edx, 1
    jne .basic_box_ud
    cmp r10d, 8
    jne .basic_box_ud
    cmp ecx, 1
    jne .basic_box_ud
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LR]

.basic_box_ud:
    cmp eax, 4
    jne .basic_box_ud_rev
    cmp edx, 2
    jne .basic_box_ud_rev
    cmp r10d, 4
    jne .basic_box_ud_rev
    cmp ecx, 2
    jne .basic_box_ld
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_UD]
    jmp .basic_box_ld
.basic_box_ud_rev:
    cmp eax, 2
    jne .basic_box_ld
    cmp edx, 4
    jne .basic_box_ld
    cmp r10d, 2
    jne .basic_box_ld
    cmp ecx, 4
    jne .basic_box_ld
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_UD]

.basic_box_ld:
    cmp eax, 1
    jne .basic_box_ld_rev
    cmp edx, 2
    jne .basic_box_ld_rev
    cmp r10d, 1
    jne .basic_box_ld_rev
    cmp ecx, 2
    jne .basic_box_lu
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LD]
    jmp .basic_box_lu
.basic_box_ld_rev:
    cmp eax, 2
    jne .basic_box_lu
    cmp edx, 1
    jne .basic_box_lu
    cmp r10d, 2
    jne .basic_box_lu
    cmp ecx, 1
    jne .basic_box_lu
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LD]

.basic_box_lu:
    cmp eax, 1
    jne .basic_box_lu_rev
    cmp edx, 4
    jne .basic_box_lu_rev
    cmp r10d, 1
    jne .basic_box_lu_rev
    cmp ecx, 4
    jne .basic_box_rd
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LU]
    jmp .basic_box_rd
.basic_box_lu_rev:
    cmp eax, 4
    jne .basic_box_rd
    cmp edx, 1
    jne .basic_box_rd
    cmp r10d, 4
    jne .basic_box_rd
    cmp ecx, 1
    jne .basic_box_rd
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_LU]

.basic_box_rd:
    cmp eax, 8
    jne .basic_box_rd_rev
    cmp edx, 2
    jne .basic_box_rd_rev
    cmp r10d, 8
    jne .basic_box_rd_rev
    cmp ecx, 2
    jne .basic_box_ru
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_RD]
    jmp .basic_box_ru
.basic_box_rd_rev:
    cmp eax, 2
    jne .basic_box_ru
    cmp edx, 8
    jne .basic_box_ru
    cmp r10d, 2
    jne .basic_box_ru
    cmp ecx, 8
    jne .basic_box_ru
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_RD]

.basic_box_ru:
    cmp eax, 8
    jne .basic_box_ru_rev
    cmp edx, 4
    jne .basic_box_ru_rev
    cmp r10d, 8
    jne .basic_box_ru_rev
    cmp ecx, 4
    jne .basic_shift
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_RU]
    jmp .basic_shift
.basic_box_ru_rev:
    cmp eax, 4
    jne .basic_shift
    cmp edx, 8
    jne .basic_shift
    cmp r10d, 4
    jne .basic_shift
    cmp ecx, 8
    jne .basic_shift
    inc dword [rbx + ASSP_BASIC_PATTERNS_BOX_RU]

.basic_shift:
    mov edx, [rsp + 4]
    mov [rsp + 0], edx
    mov edx, [rsp + 8]
    mov [rsp + 4], edx
    mov [rsp + 8], ecx
    inc r12

.basic_line_done:
    mov rsi, [rsp + 16]
    jmp .basic_line_loop

.basic_success:
    mov eax, ASSP_TRUE
    jmp .basic_done

.basic_fail:
    xor eax, eax

.basic_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = u32[62] output.
; Counts RSSP's full default PatternVariant set. eax = 1 on success.
assp_count_default_patterns_minimized_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

    test r8, r8
    jz .default_fail
    mov rbx, r8

    xor eax, eax
.default_zero_loop:
    cmp eax, ASSP_PATTERN_COUNT
    jae .default_zero_done
    mov dword [rbx + rax * 4], 0
    inc eax
    jmp .default_zero_loop

.default_zero_done:
    test rdx, rdx
    jz .default_success
    test rcx, rcx
    jz .default_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
    xor r13d, r13d

.default_line_loop:
    cmp rsi, rdi
    jae .default_success

    mov r10, rsi
.default_find_line_end:
    cmp r10, rdi
    jae .default_line_end_found
    cmp byte [r10], 10
    je .default_line_end_found
    inc r10
    jmp .default_find_line_end

.default_line_end_found:
    mov r11, r10
    cmp r11, rsi
    jbe .default_trim_cr_done
    cmp byte [r11 - 1], 13
    jne .default_trim_cr_done
    dec r11
.default_trim_cr_done:
    cmp r10, rdi
    jae .default_next_is_end
    inc r10
.default_next_is_end:
    mov [rsp + 16], r10

    cmp rsi, r11
    jae .default_line_done
    mov al, [rsi]
    cmp al, ','
    je .default_line_done
    cmp al, ';'
    je .default_success

    lea rax, [rsi + 4]
    cmp rax, r11
    ja .default_line_done

    xor ecx, ecx
    mov al, [rsi + 0]
    cmp al, '1'
    je .default_set_0
    cmp al, '2'
    je .default_set_0
    cmp al, '4'
    jne .default_col_1
.default_set_0:
    or ecx, 1
.default_col_1:
    mov al, [rsi + 1]
    cmp al, '1'
    je .default_set_1
    cmp al, '2'
    je .default_set_1
    cmp al, '4'
    jne .default_col_2
.default_set_1:
    or ecx, 2
.default_col_2:
    mov al, [rsi + 2]
    cmp al, '1'
    je .default_set_2
    cmp al, '2'
    je .default_set_2
    cmp al, '4'
    jne .default_col_3
.default_set_2:
    or ecx, 4
.default_col_3:
    mov al, [rsi + 3]
    cmp al, '1'
    je .default_set_3
    cmp al, '2'
    je .default_set_3
    cmp al, '4'
    jne .default_mask_done
.default_set_3:
    or ecx, 8

.default_mask_done:
    shl r13, 4
    movzx ecx, cl
    or r13, rcx
    inc r12

    lea r14, [default_pattern_table]
    lea r15, [default_pattern_table_end]
.default_pattern_loop:
    cmp r14, r15
    jae .default_line_done
    movzx eax, byte [r14 + 1]
    cmp r12, rax
    jb .default_next_pattern

    mov r11, r13
    lea r10, [default_pattern_len_masks]
    and r11, [r10 + rax * 8]
    cmp r11, [r14 + 4]
    jne .default_next_pattern

    movzx eax, byte [r14]
    inc dword [rbx + rax * 4]

.default_next_pattern:
    add r14, 16
    jmp .default_pattern_loop

.default_line_done:
    mov rsi, [rsp + 16]
    jmp .default_line_loop

.default_success:
    mov eax, ASSP_TRUE
    jmp .default_done

.default_fail:
    xor eax, eax

.default_done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = total steps, rdx = candle total, r8 = mono total,
; r9 = out candle percent centi, stack arg 5 = out mono percent centi.
; Matches RSSP's two-decimal ties-even percentage rounding. eax = 1 on success.
assp_pattern_percentages_centi:
    push rbp
    mov rbp, rsp
    push rbx

    mov r10, [rbp + 48]
    test r9, r9
    jz .percent_fail
    test r10, r10
    jz .percent_fail

    mov qword [r9], 0
    mov qword [r10], 0

    cmp rcx, 1
    jbe .percent_success

    mov r11, rcx
    dec r11
    shr r11, 1
    test r11, r11
    jz .percent_mono

    mov eax, edx
    imul rax, rax, 10000
    mov rbx, r11
    call .round_unsigned_div_ties_even
    mov [r9], rax

.percent_mono:
    mov eax, r8d
    imul rax, rax, 10000
    mov rbx, rcx
    call .round_unsigned_div_ties_even
    mov r10, [rbp + 48]
    mov [r10], rax

.percent_success:
    mov eax, ASSP_TRUE
    jmp .percent_done

.percent_fail:
    xor eax, eax

.percent_done:
    pop rbx
    pop rbp
    ret

.round_unsigned_div_ties_even:
    xor edx, edx
    div rbx
    mov r10, rdx
    shl r10, 1
    cmp r10, rbx
    jb .round_done
    ja .round_up
    test al, 1
    jz .round_done
.round_up:
    inc rax
.round_done:
    ret

section .rdata

%macro PAT3 4
    db %1, 3, 0, 0
    dq ((%2 << 8) | (%3 << 4) | %4)
    dd 0
%endmacro

%macro PAT4 5
    db %1, 4, 0, 0
    dq ((%2 << 12) | (%3 << 8) | (%4 << 4) | %5)
    dd 0
%endmacro

%macro PAT5 6
    db %1, 5, 0, 0
    dq ((%2 << 16) | (%3 << 12) | (%4 << 8) | (%5 << 4) | %6)
    dd 0
%endmacro

%macro PAT6 7
    db %1, 6, 0, 0
    dq ((%2 << 20) | (%3 << 16) | (%4 << 12) | (%5 << 8) | (%6 << 4) | %7)
    dd 0
%endmacro

%macro PAT7 8
    db %1, 7, 0, 0
    dq ((%2 << 24) | (%3 << 20) | (%4 << 16) | (%5 << 12) | (%6 << 8) | (%7 << 4) | %8)
    dd 0
%endmacro

%macro PAT8 9
    db %1, 8, 0, 0
    dq ((%2 << 28) | (%3 << 24) | (%4 << 20) | (%5 << 16) | (%6 << 12) | (%7 << 8) | (%8 << 4) | %9)
    dd 0
%endmacro

%macro PAT9 10
    db %1, 9, 0, 0
    dq ((%2 << 32) | (%3 << 28) | (%4 << 24) | (%5 << 20) | (%6 << 16) | (%7 << 12) | (%8 << 8) | (%9 << 4) | %10)
    dd 0
%endmacro

%macro PAT10 11
    db %1, 10, 0, 0
    dq ((%2 << 36) | (%3 << 32) | (%4 << 28) | (%5 << 24) | (%6 << 20) | (%7 << 16) | (%8 << 12) | (%9 << 8) | (%10 << 4) | %11)
    dd 0
%endmacro

default_pattern_len_masks:
    dq 0
    dq 0
    dq 0
    dq 0fffh
    dq 0ffffh
    dq 0fffffh
    dq 0ffffffh
    dq 0fffffffh
    dq 0ffffffffh
    dq 0fffffffffh
    dq 0ffffffffffh

default_pattern_table:
    PAT3 10, 4, 1, 2
    PAT3 10, 2, 1, 4
    PAT3 11, 4, 8, 2
    PAT3 11, 2, 8, 4
    PAT4 4, 1, 8, 1, 8
    PAT4 4, 8, 1, 8, 1
    PAT4 5, 4, 2, 4, 2
    PAT4 5, 2, 4, 2, 4
    PAT4 6, 1, 2, 1, 2
    PAT4 6, 2, 1, 2, 1
    PAT4 7, 1, 4, 1, 4
    PAT4 7, 4, 1, 4, 1
    PAT4 8, 8, 2, 8, 2
    PAT4 8, 2, 8, 2, 8
    PAT4 9, 8, 4, 8, 4
    PAT4 9, 4, 8, 4, 8
    PAT4 36, 1, 2, 4, 8
    PAT4 37, 8, 4, 2, 1
    PAT4 38, 1, 4, 2, 8
    PAT4 39, 8, 2, 4, 1
    PAT3 57, 8, 4, 8
    PAT3 55, 1, 4, 1
    PAT3 54, 1, 2, 1
    PAT3 56, 8, 2, 8
    PAT5 17, 1, 2, 4, 2, 1
    PAT5 16, 8, 4, 2, 4, 8
    PAT5 19, 1, 4, 2, 4, 1
    PAT5 18, 8, 2, 4, 2, 8
    PAT7 44, 1, 2, 4, 8, 4, 2, 1
    PAT7 45, 8, 4, 2, 1, 2, 4, 8
    PAT7 46, 1, 4, 2, 8, 2, 4, 1
    PAT7 47, 8, 2, 4, 1, 4, 2, 8
    PAT5 48, 1, 8, 1, 8, 1
    PAT5 48, 8, 1, 8, 1, 8
    PAT5 49, 4, 2, 4, 2, 4
    PAT5 49, 2, 4, 2, 4, 2
    PAT5 50, 1, 2, 1, 2, 1
    PAT5 50, 2, 1, 2, 1, 2
    PAT5 51, 1, 4, 1, 4, 1
    PAT5 51, 4, 1, 4, 1, 4
    PAT5 52, 8, 2, 8, 2, 8
    PAT5 52, 2, 8, 2, 8, 2
    PAT5 53, 8, 4, 8, 4, 8
    PAT5 53, 4, 8, 4, 8, 4
    PAT8 20, 1, 4, 2, 8, 1, 4, 2, 8
    PAT8 21, 8, 2, 4, 1, 8, 2, 4, 1
    PAT8 22, 1, 2, 4, 8, 1, 2, 4, 8
    PAT8 23, 8, 2, 4, 1, 8, 2, 4, 1
    PAT8 0, 1, 4, 2, 8, 1, 2, 4, 8
    PAT8 1, 8, 2, 4, 1, 8, 4, 2, 1
    PAT8 2, 1, 2, 4, 8, 1, 4, 2, 8
    PAT8 3, 8, 4, 2, 1, 8, 2, 4, 1
    PAT5 28, 1, 2, 1, 4, 1
    PAT5 29, 1, 4, 1, 2, 1
    PAT5 30, 8, 4, 8, 2, 8
    PAT5 31, 8, 2, 8, 4, 8
    PAT10 12, 1, 2, 4, 8, 2, 4, 1, 2, 4, 8
    PAT10 13, 8, 4, 2, 1, 4, 2, 8, 4, 2, 1
    PAT10 14, 1, 4, 2, 8, 4, 2, 1, 4, 2, 8
    PAT10 15, 8, 2, 4, 1, 2, 4, 8, 2, 4, 1
    PAT9 24, 1, 2, 4, 2, 1, 4, 2, 4, 1
    PAT9 25, 8, 4, 2, 4, 8, 2, 4, 2, 8
    PAT9 26, 1, 4, 2, 4, 1, 2, 4, 2, 1
    PAT9 27, 8, 2, 4, 2, 8, 4, 2, 4, 8
    PAT6 32, 1, 2, 4, 8, 2, 8
    PAT6 33, 8, 4, 2, 1, 4, 1
    PAT6 34, 1, 4, 2, 8, 4, 8
    PAT6 35, 8, 2, 4, 1, 2, 1
    PAT8 58, 1, 2, 1, 4, 2, 8, 4, 8
    PAT8 59, 8, 4, 8, 2, 4, 1, 2, 1
    PAT8 60, 1, 4, 1, 2, 4, 8, 2, 8
    PAT8 61, 8, 2, 8, 4, 2, 1, 4, 1
    PAT9 40, 1, 2, 4, 8, 2, 8, 4, 2, 1
    PAT9 41, 8, 4, 2, 1, 4, 1, 2, 4, 8
    PAT9 42, 1, 4, 2, 8, 4, 8, 2, 4, 1
    PAT9 43, 8, 2, 4, 1, 2, 1, 4, 2, 8
default_pattern_table_end:
