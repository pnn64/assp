default rel
%include "assp.inc"

global assp_count_anchors_minimized_4
global assp_collect_bitmasks_minimized_4
global assp_collect_bitmasks_compact_4
global assp_count_anchors_bitmasks_4
global assp_count_facing_steps_bitmasks_4
global assp_count_facing_steps_minimized_4
global assp_count_basic_patterns_minimized_4
global assp_count_default_patterns_minimized_4
global assp_count_default_patterns_bitmasks_4
global assp_pattern_percentages_centi

section .text

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = out bitmasks,
; r9 = output capacity. Returns count or ASSP_NOT_FOUND on failure.
assp_collect_bitmasks_minimized_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 32

    test r8, r8
    jz .collect_fail
    test rdx, rdx
    jz .collect_empty
    test rcx, rcx
    jz .collect_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d

.collect_line_loop:
    cmp rsi, rdi
    jae .collect_success

    mov r10, rsi
.collect_find_line_end:
    cmp r10, rdi
    jae .collect_line_end_found
    cmp byte [r10], 10
    je .collect_line_end_found
    inc r10
    jmp .collect_find_line_end

.collect_line_end_found:
    mov r11, r10
    cmp r11, rsi
    jbe .collect_trim_cr_done
    cmp byte [r11 - 1], 13
    jne .collect_trim_cr_done
    dec r11
.collect_trim_cr_done:
    cmp r10, rdi
    jae .collect_next_is_end
    inc r10
.collect_next_is_end:
    mov [rsp], r10

    cmp rsi, r11
    jae .collect_line_done
    mov al, [rsi]
    cmp al, ','
    je .collect_line_done
    cmp al, ';'
    je .collect_success

    lea rax, [rsi + 4]
    cmp rax, r11
    ja .collect_line_done

    cmp r13, r12
    jae .collect_fail

    lea r11, [rel note_active_pair_table]
    movzx eax, word [rsi]
    movzx ecx, byte [r11 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r11 + rax]
    shl eax, 2
    or ecx, eax
    mov [rbx + r13], cl
    inc r13

.collect_line_done:
    mov rsi, [rsp]
    jmp .collect_line_loop

.collect_empty:
    xor eax, eax
    jmp .collect_done

.collect_success:
    mov rax, r13
    jmp .collect_done

.collect_fail:
    mov rax, ASSP_NOT_FOUND

.collect_done:
    add rsp, 32
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = ASSP-minimized 4-panel note-data bytes, rdx = len, r8 = out bitmasks,
; r9 = output capacity. Returns count or ASSP_NOT_FOUND on failure.
; This fast path assumes rows are already normalized as "dddd\n" and measure
; separators as ",\n", which is what assp_minimize_chart_4 emits.
assp_collect_bitmasks_compact_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13

    test r8, r8
    jz .compact_fail
    test rdx, rdx
    jz .compact_empty
    test rcx, rcx
    jz .compact_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d
    lea r11, [note_active_pair_table]

.compact_loop:
    cmp rsi, rdi
    jae .compact_success

    cmp byte [rsi], ','
    jne .compact_row
    inc rsi
    cmp rsi, rdi
    jae .compact_success
    cmp byte [rsi], 10
    jne .compact_loop
    inc rsi
    jmp .compact_loop

.compact_row:
    lea rax, [rsi + 4]
    cmp rax, rdi
    ja .compact_fail
    cmp r13, r12
    jae .compact_fail

    movzx eax, word [rsi]
    movzx ecx, byte [r11 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r11 + rax]
    shl eax, 2
    or ecx, eax
    mov [rbx + r13], cl
    inc r13

    add rsi, 4
    cmp rsi, rdi
    jae .compact_success
    cmp byte [rsi], 13
    jne .compact_skip_lf
    inc rsi
    cmp rsi, rdi
    jae .compact_success
.compact_skip_lf:
    cmp byte [rsi], 10
    jne .compact_loop
    inc rsi
    jmp .compact_loop

.compact_empty:
    xor eax, eax
    jmp .compact_done

.compact_success:
    mov rax, r13
    jmp .compact_done

.compact_fail:
    mov rax, ASSP_NOT_FOUND

.compact_done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = bitmask bytes, rdx = count, r8 = u32[4] output.
; out[0..4] = left/down/up/right anchors. eax = 1 on success.
assp_count_anchors_bitmasks_4:
    test r8, r8
    jz .anchors_bits_fail
    mov dword [r8 + 0], 0
    mov dword [r8 + 4], 0
    mov dword [r8 + 8], 0
    mov dword [r8 + 12], 0
    test rdx, rdx
    jz .anchors_bits_success
    test rcx, rcx
    jz .anchors_bits_fail
    cmp rdx, 5
    jb .anchors_bits_success

    xor r9d, r9d
    lea r10, [rdx - 4]
.anchors_bits_loop:
    cmp r9, r10
    jae .anchors_bits_success
    movzx eax, byte [rcx + r9]
    and al, [rcx + r9 + 2]
    and al, [rcx + r9 + 4]
    test al, 1
    jz .anchors_bits_down
    inc dword [r8 + 0]
.anchors_bits_down:
    test al, 2
    jz .anchors_bits_up
    inc dword [r8 + 4]
.anchors_bits_up:
    test al, 4
    jz .anchors_bits_right
    inc dword [r8 + 8]
.anchors_bits_right:
    test al, 8
    jz .anchors_bits_next
    inc dword [r8 + 12]
.anchors_bits_next:
    inc r9
    jmp .anchors_bits_loop

.anchors_bits_success:
    mov eax, ASSP_TRUE
    ret
.anchors_bits_fail:
    xor eax, eax
    ret

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

    lea r11, [rel note_active_pair_table]
    movzx eax, word [rsi]
    movzx ecx, byte [r11 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r11 + rax]
    shl eax, 2
    or ecx, eax

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

    lea r10, [note_active_pair_table]
    movzx eax, word [rsi]
    movzx ecx, byte [r10 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r10 + rax]
    shl eax, 2
    or ecx, eax

    lea r10, [facing_mask_to_arrow]
    movzx ecx, byte [r10 + rcx]
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
    lea r10, [facing_forced_foot_table]
    movzx eax, byte [r10 + rcx]
    mov [rsp + 0], rax
    jmp .facing_line_done

.facing_continue_sequence:
    mov eax, r15d
    lea eax, [rax + rax * 4]
    add eax, ecx
    lea r10, [facing_dir_table]
    movzx edx, byte [r10 + rax]

    mov eax, [rsp + 0]
    lea eax, [rax + rax * 4]
    add eax, ecx
    lea r10, [facing_foot_table]
    movzx eax, byte [r10 + rax]
    mov r10d, eax
    and r10d, 3
    mov [rsp + 0], r10
    test al, 4
    jz .facing_step
    call .facing_finalize
    xor r13d, r13d
    xor r14d, r14d

.facing_step:
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

; rcx = bitmask bytes, rdx = count, r8 = mono threshold,
; r9 = u32[2] output. out[0..2] = left-facing/right-facing mono counts.
; eax = 1 on success, 0 on failure.
assp_count_facing_steps_bitmasks_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    test r9, r9
    jz .bits_facing_fail
    mov rbx, r9
    mov dword [rbx + 0], 0
    mov dword [rbx + 4], 0
    mov [rsp + 0], r8

    test rdx, rdx
    jz .bits_facing_success
    test rcx, rcx
    jz .bits_facing_fail

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d

.bits_facing_loop:
    cmp rsi, rdi
    jae .bits_facing_eof

    movzx eax, byte [rsi]
    and eax, 15
    lea r10, [facing_mask_to_arrow]
    movzx ecx, byte [r10 + rax]
    test ecx, ecx
    jnz .bits_facing_has_arrow

    test r14d, r14d
    jz .bits_facing_next
    call .bits_facing_finalize
    xor r12d, r12d
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    jmp .bits_facing_next

.bits_facing_has_arrow:
    test r14d, r14d
    jnz .bits_facing_continue
    xor r12d, r12d
    mov r13d, 1
    lea r10, [facing_forced_foot_table]
    movzx r15d, byte [r10 + rcx]
    mov r14d, ecx
    jmp .bits_facing_next

.bits_facing_continue:
    mov eax, r14d
    lea eax, [rax + rax * 4]
    add eax, ecx
    lea r10, [facing_dir_table]
    movzx edx, byte [r10 + rax]

    mov eax, r15d
    lea eax, [rax + rax * 4]
    add eax, ecx
    lea r10, [facing_foot_table]
    movzx eax, byte [r10 + rax]
    mov r15d, eax
    and r15d, 3
    test al, 4
    jz .bits_facing_step
    call .bits_facing_finalize
    xor r12d, r12d
    xor r13d, r13d

.bits_facing_step:
    test r12d, r12d
    jz .bits_facing_wait
    cmp r12d, 1
    je .bits_facing_left

.bits_facing_right:
    cmp edx, 1
    jne .bits_facing_inc_count
    call .bits_facing_finalize
    mov r12d, 1
    mov r13d, 1
    jmp .bits_facing_step_done

.bits_facing_left:
    cmp edx, 2
    jne .bits_facing_inc_count
    call .bits_facing_finalize
    mov r12d, 2
    mov r13d, 1
    jmp .bits_facing_step_done

.bits_facing_wait:
    cmp edx, 1
    jne .bits_facing_wait_right
    mov r12d, 1
    inc r13
    jmp .bits_facing_step_done
.bits_facing_wait_right:
    cmp edx, 2
    jne .bits_facing_inc_count
    mov r12d, 2

.bits_facing_inc_count:
    inc r13

.bits_facing_step_done:
    mov r14d, ecx

.bits_facing_next:
    inc rsi
    jmp .bits_facing_loop

.bits_facing_eof:
    test r14d, r14d
    jz .bits_facing_success
    call .bits_facing_finalize

.bits_facing_success:
    mov eax, ASSP_TRUE
    jmp .bits_facing_done

.bits_facing_fail:
    xor eax, eax

.bits_facing_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.bits_facing_finalize:
    cmp r13, [rsp + 8]
    jb .bits_facing_finalize_done
    cmp r12d, 1
    je .bits_facing_finalize_left
    cmp r12d, 2
    jne .bits_facing_finalize_done
    add dword [rbx + 4], r13d
    ret
.bits_facing_finalize_left:
    add dword [rbx + 0], r13d
.bits_facing_finalize_done:
    ret

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = assp_basic_patterns* out.
; Counts RSSP's default candle and box-family patterns. eax = 1 on success.
assp_count_basic_patterns_minimized_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40

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
    lea r13, [default_pattern_dfa_goto]
    lea r14, [default_pattern_dfa_output_lens]
    lea r15, [default_pattern_dfa_output_starts]
    lea r9, [basic_pattern_offset_table]

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

    lea r11, [rel note_active_pair_table]
    movzx eax, word [rsi]
    movzx ecx, byte [r11 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r11 + rax]
    shl eax, 2
    or ecx, eax

    movzx ecx, cl
    mov r10d, r12d
    shl r10d, 4
    add r10d, ecx
    movzx r12d, word [r13 + r10 * 2]

    movzx ecx, byte [r14 + r12]
    test ecx, ecx
    jz .basic_line_done

    movzx edx, word [r15 + r12 * 2]
    lea r11, [default_pattern_dfa_outputs]
    add r11, rdx
.basic_output_loop:
    movzx eax, byte [r11]
    sub eax, ASSP_PATTERN_BOX_LR
    cmp eax, ASSP_PATTERN_CANDLE_RIGHT - ASSP_PATTERN_BOX_LR
    ja .basic_output_next
    movzx eax, byte [r9 + rax]
    inc dword [rbx + rax]
.basic_output_next:
    inc r11
    dec ecx
    jnz .basic_output_loop

.basic_line_done:
    mov rsi, [rsp + 16]
    jmp .basic_line_loop

.basic_success:
    mov eax, ASSP_TRUE
    jmp .basic_done

.basic_fail:
    xor eax, eax

.basic_done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 4-panel note-data bytes, rdx = len, r8 = u32[62] output.
; Counts RSSP's full default PatternVariant set. eax = 1 on success.
; rcx = bitmask bytes, rdx = count, r8 = u32[62] output.
; Counts RSSP's full default PatternVariant set. eax = 1 on success.
assp_count_default_patterns_bitmasks_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32

    test r8, r8
    jz .bits_default_fail
    mov rbx, r8
    mov rsi, rcx

    mov rdi, r8
    xor eax, eax
    mov ecx, ASSP_PATTERN_COUNT
    rep stosd

    test rdx, rdx
    jz .bits_default_success
    test rsi, rsi
    jz .bits_default_fail

    lea rdi, [rsi + rdx]
    xor r12d, r12d
    lea r13, [default_pattern_dfa_goto]
    lea r14, [default_pattern_dfa_output_lens]
    lea r15, [default_pattern_dfa_output_starts]

.bits_default_loop:
    cmp rsi, rdi
    jae .bits_default_success

    movzx eax, byte [rsi]
    and eax, 15
    mov r10d, r12d
    shl r10d, 4
    add r10d, eax
    movzx r12d, word [r13 + r10 * 2]

    movzx ecx, byte [r14 + r12]
    test ecx, ecx
    jz .bits_default_next

    movzx edx, word [r15 + r12 * 2]
    lea r11, [default_pattern_dfa_outputs]
    add r11, rdx
.bits_default_output_loop:
    movzx eax, byte [r11]
    inc dword [rbx + rax * 4]
    inc r11
    dec ecx
    jnz .bits_default_output_loop

.bits_default_next:
    inc rsi
    jmp .bits_default_loop

.bits_default_success:
    mov eax, ASSP_TRUE
    jmp .bits_default_done

.bits_default_fail:
    xor eax, eax

.bits_default_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
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
    lea r13, [default_pattern_dfa_goto]
    lea r14, [default_pattern_dfa_output_lens]
    lea r15, [default_pattern_dfa_output_starts]

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

    lea r11, [rel note_active_pair_table]
    movzx eax, word [rsi]
    movzx ecx, byte [r11 + rax]
    movzx eax, word [rsi + 2]
    movzx eax, byte [r11 + rax]
    shl eax, 2
    or ecx, eax

    movzx ecx, cl
    mov r10d, r12d
    shl r10d, 4
    add r10d, ecx
    movzx r12d, word [r13 + r10 * 2]

    movzx ecx, byte [r14 + r12]
    test ecx, ecx
    jz .default_line_done

    movzx edx, word [r15 + r12 * 2]
    lea r11, [default_pattern_dfa_outputs]
    add r11, rdx
.default_output_loop:
    movzx eax, byte [r11]
    inc dword [rbx + rax * 4]
    inc r11
    dec ecx
    jnz .default_output_loop

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
    mov rbx, r11
    call .round_percent_centi_f64
    mov [r9], rax

.percent_mono:
    mov eax, r8d
    mov rbx, rcx
    call .round_percent_centi_f64
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

.round_percent_centi_f64:
    cvtsi2sd xmm0, rax
    cvtsi2sd xmm1, rbx
    divsd xmm0, xmm1
    mulsd xmm0, [rel patterns_f64_100]
    mulsd xmm0, [rel patterns_f64_100]
    cvtsd2si rax, xmm0
    ret

section .rdata

patterns_f64_100 dq 100.0

basic_pattern_offset_table:
    db ASSP_BASIC_PATTERNS_BOX_LR
    db ASSP_BASIC_PATTERNS_BOX_UD
    db ASSP_BASIC_PATTERNS_BOX_LD
    db ASSP_BASIC_PATTERNS_BOX_LU
    db ASSP_BASIC_PATTERNS_BOX_RD
    db ASSP_BASIC_PATTERNS_BOX_RU
    db ASSP_BASIC_PATTERNS_CANDLE_LEFT
    db ASSP_BASIC_PATTERNS_CANDLE_RIGHT

align 64
note_active_pair_table:
%assign i 0
%rep 65536
%assign lo (i & 0ffh)
%assign hi ((i >> 8) & 0ffh)
%assign mask 0
%if lo = '1' || lo = '2' || lo = '4'
%assign mask mask | 1
%endif
%if hi = '1' || hi = '2' || hi = '4'
%assign mask mask | 2
%endif
    db mask
%assign i i+1
%endrep

align 64
%include "default_pattern_dfa.inc"

facing_mask_to_arrow:
    db 0, 1, 2, 0, 3, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0

facing_forced_foot_table:
    db 0, 1, 0, 0, 2

facing_dir_table:
    db 0, 0, 0, 0, 0
    db 0, 0, 2, 1, 0
    db 0, 2, 0, 0, 1
    db 0, 1, 0, 0, 2
    db 0, 0, 1, 2, 0

facing_foot_table:
    db 0, 1, 0, 0, 2
    db 2, 5, 2, 2, 2
    db 1, 1, 1, 1, 6

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
