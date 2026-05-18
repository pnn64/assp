default rel
%include "assp.inc"

global assp_step_parity_permutations_4
global assp_step_parity_result_state_no_holds_4
global assp_step_parity_result_state_holds_4
global assp_step_parity_row_transitions_4
global assp_step_parity_row_key_candidates_4
global assp_step_parity_action_flags_4
global assp_step_parity_basic_action_costs_4
global assp_step_parity_elapsed_action_costs_4
global assp_step_parity_switch_action_costs_4
global assp_step_parity_bracket_tap_action_costs_4
global assp_step_parity_distance_action_costs_4
global assp_step_parity_orientation_action_costs_4
global assp_step_parity_action_cost_4
global assp_step_parity_row_best_candidates_4

section .text

%macro check_placement_col 1
    mov al, [rbp + %1]
    cmp al, 1
    je %%left_heel
    cmp al, 2
    je %%left_toe
    cmp al, 3
    je %%right_heel
    cmp al, 4
    je %%right_toe
    jmp %%done

%%left_heel:
    mov byte [rbp + 8], %1
    jmp %%done

%%left_toe:
    mov byte [rbp + 9], %1
    jmp %%done

%%right_heel:
    mov byte [rbp + 10], %1
    jmp %%done

%%right_toe:
    mov byte [rbp + 11], %1

%%done:
%endmacro

; ecx = 4-panel active column mask, rdx = optional output placements,
; r8 = output capacity in placements. Each placement is 4 bytes of Foot ids:
; 0 none, 1 left heel, 2 left toe, 3 right heel, 4 right toe.
; rax = total valid placement count. Writes up to out_cap placements.
assp_step_parity_permutations_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 40
    mov rbp, rsp

    mov r12d, ecx
    and r12d, 0fh
    mov r13, rdx
    mov r14, r8
    xor r15d, r15d

    xor ebx, ebx
    test r12b, 1
    jz .f0_loop
    mov ebx, 1

.f0_loop:
    mov [rbp], bl

    xor esi, esi
    test r12b, 2
    jz .f1_loop
    mov esi, 1

.f1_loop:
    mov [rbp + 1], sil

    xor edi, edi
    test r12b, 4
    jz .f2_loop
    mov edi, 1

.f2_loop:
    mov [rbp + 2], dil

    xor r10d, r10d
    test r12b, 8
    jz .f3_loop
    mov r10d, 1

.f3_loop:
    mov [rbp + 3], r10b
    call validate_emit_placement_4
    movzx r10d, byte [rbp + 3]
    test r12b, 8
    jz .f3_done
    inc r10d
    cmp r10d, 4
    jbe .f3_loop

.f3_done:
    test r12b, 4
    jz .f2_done
    inc edi
    cmp edi, 4
    jbe .f2_loop

.f2_done:
    test r12b, 2
    jz .f1_done
    inc esi
    cmp esi, 4
    jbe .f1_loop

.f1_done:
    test r12b, 1
    jz .done
    inc ebx
    cmp ebx, 4
    jbe .f0_loop

.done:
    mov rax, r15
    add rsp, 40
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

validate_emit_placement_4:
    mov al, [rbp]
    test al, al
    jz .dup_f1
    cmp al, [rbp + 1]
    je .reject
    cmp al, [rbp + 2]
    je .reject
    cmp al, [rbp + 3]
    je .reject

.dup_f1:
    mov al, [rbp + 1]
    test al, al
    jz .dup_f2
    cmp al, [rbp + 2]
    je .reject
    cmp al, [rbp + 3]
    je .reject

.dup_f2:
    mov al, [rbp + 2]
    test al, al
    jz .positions
    cmp al, [rbp + 3]
    je .reject

.positions:
    mov dword [rbp + 8], 0ffffffffh
    check_placement_col 0
    check_placement_col 1
    check_placement_col 2
    check_placement_col 3

    cmp byte [rbp + 8], 0ffh
    jne .left_has_heel
    cmp byte [rbp + 9], 0ffh
    jne .reject

.left_has_heel:
    cmp byte [rbp + 10], 0ffh
    jne .right_has_heel
    cmp byte [rbp + 11], 0ffh
    jne .reject

.right_has_heel:
    cmp byte [rbp + 8], 0ffh
    je .check_right_bracket
    cmp byte [rbp + 9], 0ffh
    je .check_right_bracket
    movzx eax, byte [rbp + 8]
    add al, [rbp + 9]
    cmp al, 3
    je .reject

.check_right_bracket:
    cmp byte [rbp + 10], 0ffh
    je .emit
    cmp byte [rbp + 11], 0ffh
    je .emit
    movzx eax, byte [rbp + 10]
    add al, [rbp + 11]
    cmp al, 3
    je .reject

.emit:
    mov rax, r15
    inc r15
    test r13, r13
    jz .done
    cmp rax, r14
    jae .done
    lea r11, [r13 + rax * 4]
    mov eax, [rbp]
    mov [r11], eax

.done:
    ret

.reject:
    ret

; rcx = initial assp_step_parity_state4, rdx = placement[4],
; r8d = active mask, r9 = out state, stack arg 5 = out hit[5],
; stack arg 6 = out key.
; eax = 1 on success, 0 on invalid required pointers.
assp_step_parity_result_state_no_holds_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, rcx
    mov r13, rdx
    mov r14d, r8d
    mov r15, r9
    mov rsi, [rsp + 96]
    mov rdi, [rsp + 104]

    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r15, r15
    jz .fail

    mov dword [r15 + ASSP_STEP_PARITY_STATE4_COMBINED], 0
    mov dword [r15 + ASSP_STEP_PARITY_STATE4_WHERE_FEET], 0ffffffffh
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4], 0ffh
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], 0
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_MOVED_MASK], 0
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    test rsi, rsi
    jz .scan_active
    mov dword [rsi], 0ffffffffh
    mov byte [rsi + 4], 0ffh

.scan_active:
    xor ebx, ebx
    xor r10d, r10d

.active_loop:
    bt r14d, r10d
    jnc .next_active
    movzx eax, byte [r13 + r10]
    test al, al
    jz .next_active
    cmp al, 4
    ja .next_active
    mov [r15 + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al
    test rsi, rsi
    jz .mark_moved
    mov byte [rsi + rax], r10b

.mark_moved:
    mov ecx, eax
    dec ecx
    mov eax, 1
    shl eax, cl
    or ebx, eax

.next_active:
    inc r10d
    cmp r10d, 4
    jb .active_loop

    xor r10d, r10d
    xor r11d, r11d
    xor edx, edx

.resolve_loop:
    movzx eax, byte [r15 + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    test al, al
    jnz .have_foot
    movzx eax, byte [r12 + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    cmp al, 1
    je .prev_heel
    cmp al, 3
    je .prev_heel
    cmp al, 2
    je .prev_left_toe
    cmp al, 4
    je .prev_right_toe
    jmp .next_resolve

.prev_heel:
    mov ecx, eax
    dec ecx
    mov r8d, 1
    shl r8d, cl
    test ebx, r8d
    jnz .next_resolve
    jmp .store_foot

.prev_left_toe:
    test bl, 3
    jnz .next_resolve
    mov eax, 2
    jmp .store_foot

.prev_right_toe:
    test bl, 12
    jnz .next_resolve
    mov eax, 4

.store_foot:
    mov [r15 + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al

.have_foot:
    mov ecx, r10d
    imul ecx, 3
    mov r8d, eax
    shl r8d, cl
    or r11d, r8d
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax], r10b
    mov ecx, r10d
    mov r8d, 1
    shl r8d, cl
    or edx, r8d

.next_resolve:
    inc r10d
    cmp r10d, 4
    jb .resolve_loop

    mov [r15 + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], dl
    mov [r15 + ASSP_STEP_PARITY_STATE4_MOVED_MASK], bl
    mov byte [r15 + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    mov eax, ebx
    shl eax, 24
    or eax, r11d
    test rdi, rdi
    jz .success
    mov [rdi], eax
    jmp .success

.fail:
    xor eax, eax
    jmp .done

.success:
    mov eax, ASSP_TRUE

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = initial assp_step_parity_state4, rdx = placement[4],
; r8d = active mask, r9d = hold mask, stack arg 5 = out state,
; stack arg 6 = out hit[5], stack arg 7 = out key.
; eax = 1 on success, 0 on invalid required pointers.
assp_step_parity_result_state_holds_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, rcx
    mov r13, rdx
    mov r14d, r8d
    mov r15d, r9d
    mov rbx, [rsp + 96]
    mov rsi, [rsp + 104]
    mov rdi, [rsp + 112]

    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test rbx, rbx
    jz .fail

    mov dword [rbx + ASSP_STEP_PARITY_STATE4_COMBINED], 0
    mov dword [rbx + ASSP_STEP_PARITY_STATE4_WHERE_FEET], 0ffffffffh
    mov byte [rbx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4], 0ffh
    mov byte [rbx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], 0
    mov byte [rbx + ASSP_STEP_PARITY_STATE4_MOVED_MASK], 0
    mov byte [rbx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    test rsi, rsi
    jz .scan_active
    mov dword [rsi], 0ffffffffh
    mov byte [rsi + 4], 0ffh

.scan_active:
    xor r11d, r11d
    xor r8d, r8d
    xor r10d, r10d

.active_loop:
    bt r14d, r10d
    jnc .next_active
    movzx eax, byte [r13 + r10]
    test al, al
    jz .next_active
    cmp al, 4
    ja .next_active
    mov [rbx + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al
    test rsi, rsi
    jz .check_hold
    mov byte [rsi + rax], r10b

.check_hold:
    mov ecx, eax
    dec ecx
    mov edx, 1
    shl edx, cl
    mov ecx, r10d
    mov r9d, 1
    shl r9d, cl
    test r15d, r9d
    jz .mark_moved
    or r8d, edx
    cmp [r12 + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al
    je .next_active

.mark_moved:
    or r11d, edx

.next_active:
    inc r10d
    cmp r10d, 4
    jb .active_loop

    mov r15d, r8d
    xor r10d, r10d
    xor r14d, r14d
    xor edx, edx

.resolve_loop:
    movzx eax, byte [rbx + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    test al, al
    jnz .have_foot
    movzx eax, byte [r12 + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    cmp al, 1
    je .prev_heel
    cmp al, 3
    je .prev_heel
    cmp al, 2
    je .prev_left_toe
    cmp al, 4
    je .prev_right_toe
    jmp .next_resolve

.prev_heel:
    mov ecx, eax
    dec ecx
    mov r8d, 1
    shl r8d, cl
    test r11d, r8d
    jnz .next_resolve
    jmp .store_foot

.prev_left_toe:
    test r11b, 3
    jnz .next_resolve
    mov eax, 2
    jmp .store_foot

.prev_right_toe:
    test r11b, 12
    jnz .next_resolve
    mov eax, 4

.store_foot:
    mov [rbx + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al

.have_foot:
    mov ecx, r10d
    imul ecx, 3
    mov r8d, eax
    shl r8d, cl
    or r14d, r8d
    mov byte [rbx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax], r10b
    mov ecx, r10d
    mov r8d, 1
    shl r8d, cl
    or edx, r8d

.next_resolve:
    inc r10d
    cmp r10d, 4
    jb .resolve_loop

    mov [rbx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], dl
    mov [rbx + ASSP_STEP_PARITY_STATE4_MOVED_MASK], r11b
    mov [rbx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], r15b
    mov eax, r11d
    shl eax, 24
    or eax, r14d
    mov ecx, r15d
    shl ecx, 28
    or eax, ecx
    test rdi, rdi
    jz .success
    mov [rdi], eax
    jmp .success

.fail:
    xor eax, eax
    jmp .done

.success:
    mov eax, ASSP_TRUE

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = initial assp_step_parity_state4, edx = row note mask,
; r8d = row hold mask, r9 = optional out placements[4 * cap],
; stack arg 5 = optional out states[12 * cap],
; stack arg 6 = optional out hits[5 * cap],
; stack arg 7 = optional out keys[4 * cap],
; stack arg 8 = output capacity in transitions.
; rax = total legal transition count.
assp_step_parity_row_transitions_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp

    mov r12, rcx
    mov r13d, edx
    or r13d, r8d
    and r13d, 0fh
    mov r14d, r8d
    and r14d, 0fh
    mov r15, r9
    mov rsi, [rsp + 104]
    mov rdi, [rsp + 112]
    mov rbx, [rsp + 120]
    mov rbp, [rsp + 128]

    test r12, r12
    jz .fail

    sub rsp, 216

    mov ecx, r13d
    lea rdx, [rsp + 64]
    mov r8d, 24
    call assp_step_parity_permutations_4
    mov [rsp + 200], rax
    mov qword [rsp + 192], 0

.loop:
    mov rax, [rsp + 192]
    cmp rax, [rsp + 200]
    jae .success

    lea rdx, [rsp + 64 + rax * 4]
    test r14d, r14d
    jnz .with_holds

    mov rcx, r12
    mov r8d, r13d
    lea r9, [rsp + 160]
    lea r10, [rsp + 176]
    mov [rsp + 32], r10
    lea r10, [rsp + 184]
    mov [rsp + 40], r10
    call assp_step_parity_result_state_no_holds_4
    jmp .maybe_emit

.with_holds:
    mov rcx, r12
    mov r8d, r13d
    mov r9d, r14d
    lea r10, [rsp + 160]
    mov [rsp + 32], r10
    lea r10, [rsp + 176]
    mov [rsp + 40], r10
    lea r10, [rsp + 184]
    mov [rsp + 48], r10
    call assp_step_parity_result_state_holds_4

.maybe_emit:
    mov rax, [rsp + 192]
    cmp rax, rbp
    jae .next

    test r15, r15
    jz .copy_state
    mov edx, [rsp + 64 + rax * 4]
    mov [r15 + rax * 4], edx

.copy_state:
    test rsi, rsi
    jz .copy_hit
    lea r10, [rax + rax * 2]
    lea r10, [rsi + r10 * 4]
    mov r11, [rsp + 160]
    mov [r10], r11
    mov edx, [rsp + 168]
    mov [r10 + 8], edx

.copy_hit:
    test rdi, rdi
    jz .copy_key
    lea r10, [rax + rax * 4]
    mov edx, [rsp + 176]
    mov [rdi + r10], edx
    mov dl, [rsp + 180]
    mov [rdi + r10 + 4], dl

.copy_key:
    test rbx, rbx
    jz .next
    mov edx, [rsp + 184]
    mov [rbx + rax * 4], edx

.next:
    inc qword [rsp + 192]
    jmp .loop

.success:
    mov rax, [rsp + 200]
    add rsp, 216
    jmp .done

.fail:
    xor eax, eax

.done:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = initial states, rdx = initial state count, r8d = row note mask,
; r9d = row hold mask, stack arg 5 = out predecessor indexes,
; stack arg 6 = out placements[4 * cap], stack arg 7 = out states[12 * cap],
; stack arg 8 = out hits[5 * cap], stack arg 9 = out keys[4 * cap],
; stack arg 10 = output capacity. Capacity must be at least state_count * 24.
; rax = unique row-state key count, or ASSP_NOT_FOUND on invalid input.
assp_step_parity_row_key_candidates_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp

    mov r12, rcx
    mov r13, rdx
    mov r14d, r8d
    mov r15d, r9d
    mov rbx, [rsp + 104]
    mov rsi, [rsp + 112]
    mov rdi, [rsp + 120]
    mov rbp, [rsp + 128]
    mov r10, [rsp + 136]
    mov r11, [rsp + 144]

    test r13, r13
    jz .zero_success
    test r12, r12
    jz .fail
    test rbx, rbx
    jz .fail
    test rsi, rsi
    jz .fail
    test rdi, rdi
    jz .fail
    test rbp, rbp
    jz .fail
    test r10, r10
    jz .fail

    mov rax, r13
    mov ecx, 24
    mul rcx
    jo .fail
    cmp r11, rax
    jb .fail

    sub rsp, 760
    mov [rsp + 720], r10
    mov [rsp + 728], r11
    mov qword [rsp + 688], 0
    mov qword [rsp + 696], 0

.state_loop:
    mov rax, [rsp + 696]
    cmp rax, r13
    jae .success

    lea rcx, [rax + rax * 2]
    lea rcx, [r12 + rcx * 4]
    mov edx, r14d
    mov r8d, r15d
    lea r9, [rsp + 64]
    lea r10, [rsp + 160]
    mov [rsp + 32], r10
    lea r10, [rsp + 448]
    mov [rsp + 40], r10
    lea r10, [rsp + 568]
    mov [rsp + 48], r10
    mov qword [rsp + 56], 24
    call assp_step_parity_row_transitions_4

    mov [rsp + 672], rax
    mov qword [rsp + 680], 0

.candidate_loop:
    mov rax, [rsp + 680]
    cmp rax, [rsp + 672]
    jae .next_state

    mov edx, [rsp + 568 + rax * 4]
    mov [rsp + 704], edx
    mov r10, [rsp + 720]
    xor ecx, ecx

.scan_keys:
    cmp rcx, [rsp + 688]
    jae .emit_candidate
    cmp [r10 + rcx * 4], edx
    je .skip_candidate
    inc rcx
    jmp .scan_keys

.emit_candidate:
    mov rax, [rsp + 688]

    mov edx, [rsp + 696]
    mov [rbx + rax * 4], edx

    mov rcx, [rsp + 680]
    mov edx, [rsp + 64 + rcx * 4]
    mov [rsi + rax * 4], edx

    lea r10, [rcx + rcx * 2]
    lea r10, [r10 * 4]
    lea r11, [rax + rax * 2]
    lea r11, [r11 * 4]
    mov rdx, [rsp + 160 + r10]
    mov [rdi + r11], rdx
    mov edx, [rsp + 168 + r10]
    mov [rdi + r11 + 8], edx

    lea r10, [rcx + rcx * 4]
    lea r11, [rax + rax * 4]
    mov edx, [rsp + 448 + r10]
    mov [rbp + r11], edx
    mov dl, [rsp + 452 + r10]
    mov [rbp + r11 + 4], dl

    mov r10, [rsp + 720]
    mov edx, [rsp + 704]
    mov [r10 + rax * 4], edx

    inc qword [rsp + 688]

.skip_candidate:
    inc qword [rsp + 680]
    jmp .candidate_loop

.next_state:
    inc qword [rsp + 696]
    jmp .state_loop

.success:
    mov rax, [rsp + 688]
    add rsp, 760
    jmp .done

.zero_success:
    xor eax, eax
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = initial assp_step_parity_state4, rdx = result state,
; r8 = hit[5], r9 = out assp_step_parity_action_flags4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_action_flags_4:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    test r8, r8
    jz .fail
    test r9, r9
    jz .fail

    mov dword [r9], 0
    mov dword [r9 + 3], 0

    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    movzx r10d, byte [rcx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK]
    not r10d
    and eax, r10d
    mov r10d, eax

    test r10b, 3
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_LEFT_MOVED_NOT_HOLDING]
    test r10b, 12
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_RIGHT_MOVED_NOT_HOLDING]

    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    test al, 3
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    test al, 12
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]

    mov al, [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_LEFT_MOVED_NOT_HOLDING]
    and al, [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_RIGHT_MOVED_NOT_HOLDING]
    mov [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_DID_JUMP], al

    test al, al
    jnz .success

    cmp byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT], 0
    je .check_right
    cmp byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_LEFT_MOVED_NOT_HOLDING], 0
    je .check_right
    mov r10d, 1
    call action_check_jack_foot_4
    test eax, eax
    jnz .left_jacked
    mov r10d, 2
    call action_check_jack_foot_4
    test eax, eax
    jz .check_right

.left_jacked:
    mov byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 1

.check_right:
    cmp byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT], 0
    je .success
    cmp byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_RIGHT_MOVED_NOT_HOLDING], 0
    je .success
    mov r10d, 3
    call action_check_jack_foot_4
    test eax, eax
    jnz .right_jacked
    mov r10d, 4
    call action_check_jack_foot_4
    test eax, eax
    jz .success

.right_jacked:
    mov byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 1

.success:
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = initial, rdx = result, r8 = hit[5], r10d = foot id.
; eax = boolean. Clobbers r11.
action_check_jack_foot_4:
    movsx eax, byte [r8 + r10]
    test eax, eax
    js .no
    cmp eax, 4
    jae .no
    cmp [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax], r10b
    jne .no
    lea r11d, [r10d - 1]
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK]
    bt eax, r11d
    jc .no
    mov eax, ASSP_TRUE
    ret

.no:
    xor eax, eax
    ret

; rcx = result state, rdx = action flags, r8d = multi-active row,
; r9d = mine|fake mine mask, stack arg 5 = prev row has live hold,
; stack arg 6 = out assp_step_parity_basic_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_basic_action_costs_4:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    mov r10, [rsp + 48]
    test r10, r10
    jz .fail

    xor eax, eax
    mov [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_MINE], eax
    mov [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_BRACKET_JACK], eax
    mov [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_DOUBLESTEP], eax
    mov [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_MISSED_FOOTSWITCH], eax
    mov [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_TOTAL], eax
    xorps xmm0, xmm0

    mov eax, r9d
    and al, [rcx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK]
    jz .bracket_jack
    movss xmm1, [rel cost_mine_weight]
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_MINE], xmm1
    addss xmm0, xmm1

.bracket_jack:
    test r8d, r8d
    jz .doublestep
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    jne .doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_DID_JUMP], 0
    jne .doublestep
    mov al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    cmp al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]
    je .doublestep

    xorps xmm2, xmm2
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 0
    je .right_bracket_jack
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    and eax, 3
    cmp eax, 3
    jne .right_bracket_jack
    addss xmm2, [rel cost_bracket_jack_weight]

.right_bracket_jack:
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 0
    je .store_bracket_jack
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    and eax, 12
    cmp eax, 12
    jne .store_bracket_jack
    addss xmm2, [rel cost_bracket_jack_weight]

.store_bracket_jack:
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_BRACKET_JACK], xmm2
    addss xmm0, xmm2

.doublestep:
    mov al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    cmp al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]
    je .missed_footswitch
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_DID_JUMP], 0
    jne .missed_footswitch
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    jne .missed_footswitch
    cmp dword [rsp + 40], 0
    jne .missed_footswitch

    xor eax, eax
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT], 0
    je .check_right_doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 0
    jne .check_right_doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_LEFT_MOVED_NOT_HOLDING], 0
    setne al

.check_right_doublestep:
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT], 0
    je .maybe_store_doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 0
    jne .maybe_store_doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_RIGHT_MOVED_NOT_HOLDING], 0
    setne cl
    or al, cl

.maybe_store_doublestep:
    test al, al
    jz .missed_footswitch
    movss xmm1, [rel cost_doublestep_weight]
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_DOUBLESTEP], xmm1
    addss xmm0, xmm1

.missed_footswitch:
    test r9d, r9d
    jz .finish
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 0
    jne .store_missed_footswitch
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 0
    je .finish

.store_missed_footswitch:
    movss xmm1, [rel cost_missed_footswitch_weight]
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_MISSED_FOOTSWITCH], xmm1
    addss xmm0, xmm1

.finish:
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_TOTAL], xmm0
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = action flags, edx = row note count, r8 = elapsed seconds f32 ptr,
; r9 = out assp_step_parity_elapsed_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_elapsed_action_costs_4:
    test rcx, rcx
    jz .fail
    test r8, r8
    jz .fail
    test r9, r9
    jz .fail

    xor eax, eax
    mov [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_SLOW_BRACKET], eax
    mov [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_JACK], eax
    mov [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_TOTAL], eax
    xorps xmm0, xmm0

.slow_bracket:
    cmp edx, 2
    jb .jack
    mov al, [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    cmp al, [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]
    je .jack
    movss xmm1, [r8]
    comiss xmm1, [rel cost_slow_bracket_threshold]
    jbe .jack
    subss xmm1, [rel cost_slow_bracket_threshold]
    mulss xmm1, [rel cost_slow_bracket_weight]
    movss [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_SLOW_BRACKET], xmm1
    addss xmm0, xmm1

.jack:
    mov al, [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    cmp al, [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]
    je .finish
    cmp byte [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 0
    jne .maybe_jack
    cmp byte [rcx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 0
    je .finish

.maybe_jack:
    movss xmm1, [r8]
    comiss xmm1, [rel cost_jack_threshold]
    jae .finish
    movss xmm2, [rel cost_jack_threshold]
    subss xmm2, xmm1
    xorps xmm3, xmm3
    comiss xmm2, xmm3
    jbe .finish
    movss xmm1, [rel cost_one]
    divss xmm1, xmm2
    movss xmm2, [rel cost_one]
    divss xmm2, [rel cost_jack_threshold]
    subss xmm1, xmm2
    mulss xmm1, [rel cost_jack_weight]
    movss [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_JACK], xmm1
    addss xmm0, xmm1

.finish:
    movss [r9 + ASSP_STEP_PARITY_ELAPSED_COSTS4_TOTAL], xmm0
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = initial, rdx = result, r8 = placement[4], r9d = active mask,
; stack arg 5 = side mask, stack arg 6 = mine mask,
; stack arg 7 = elapsed seconds f32 ptr,
; stack arg 8 = out assp_step_parity_switch_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_switch_action_costs_4:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    test r8, r8
    jz .fail
    mov r10, [rsp + 56]
    test r10, r10
    jz .fail
    mov r11, [rsp + 64]
    test r11, r11
    jz .fail

    xor eax, eax
    mov [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_FOOTSWITCH], eax
    mov [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_SIDESWITCH], eax
    mov [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_TOTAL], eax
    xorps xmm0, xmm0

.footswitch:
    cmp dword [rsp + 48], 0
    jne .sideswitch
    movss xmm1, [r10]
    comiss xmm1, [rel cost_slow_footswitch_threshold]
    jb .sideswitch
    comiss xmm1, [rel cost_slow_footswitch_ignore]
    jae .sideswitch

    xor eax, eax
    and r9d, 0fh

.footswitch_loop:
    cmp eax, 4
    jae .sideswitch
    bt r9d, eax
    jnc .next_footswitch_col
    movzx r10d, byte [r8 + rax]
    test r10d, r10d
    jz .next_footswitch_col
    cmp r10d, 4
    ja .next_footswitch_col
    movzx r11d, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax]
    test r11d, r11d
    jz .next_footswitch_col
    cmp r11d, r10d
    je .next_footswitch_col
    test r10b, 1
    jz .footswitch_even_part
    inc r10d
    jmp .check_footswitch_pair

.footswitch_even_part:
    dec r10d

.check_footswitch_pair:
    cmp r11d, r10d
    je .next_footswitch_col

    mov r10, [rsp + 56]
    movss xmm1, [r10]
    subss xmm1, [rel cost_slow_footswitch_threshold]
    movss xmm2, [rel cost_slow_footswitch_threshold]
    addss xmm2, xmm1
    divss xmm1, xmm2
    mulss xmm1, [rel cost_footswitch_weight]
    mov r11, [rsp + 64]
    movss [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_FOOTSWITCH], xmm1
    addss xmm0, xmm1
    jmp .sideswitch

.next_footswitch_col:
    inc eax
    jmp .footswitch_loop

.sideswitch:
    xorps xmm1, xmm1
    mov r10d, [rsp + 40]
    and r10d, 0fh
    xor eax, eax

.sideswitch_loop:
    cmp eax, 4
    jae .store_sideswitch
    bt r10d, eax
    jnc .next_sideswitch_col
    movzx r11d, byte [r8 + rax]
    test r11d, r11d
    jz .next_sideswitch_col
    movzx r9d, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax]
    test r9d, r9d
    jz .next_sideswitch_col
    cmp r9d, r11d
    je .next_sideswitch_col
    cmp r9d, 4
    ja .next_sideswitch_col
    movzx r11d, byte [rdx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    dec r9d
    bt r11d, r9d
    jc .next_sideswitch_col
    addss xmm1, [rel cost_sideswitch_weight]

.next_sideswitch_col:
    inc eax
    jmp .sideswitch_loop

.store_sideswitch:
    mov r11, [rsp + 64]
    movss [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_SIDESWITCH], xmm1
    addss xmm0, xmm1

.finish:
    movss [r11 + ASSP_STEP_PARITY_SWITCH_COSTS4_TOTAL], xmm0
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = initial, rdx = hit[5], r8d = hold mask,
; r9 = elapsed seconds f32 ptr,
; stack arg 5 = out assp_step_parity_bracket_tap_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_bracket_tap_action_costs_4:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    test r9, r9
    jz .fail
    mov r10, [rsp + 40]
    test r10, r10
    jz .fail

    xor eax, eax
    mov [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_LEFT], eax
    mov [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_RIGHT], eax
    mov [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_TOTAL], eax
    xorps xmm0, xmm0
    test r8d, r8d
    jz .finish

.left_pair:
    movsx eax, byte [rdx + 1]
    test eax, eax
    js .right_pair
    cmp eax, 4
    jae .right_pair
    movsx r10d, byte [rdx + 2]
    test r10d, r10d
    js .right_pair
    cmp r10d, 4
    jae .right_pair
    bt r8d, eax
    setc r11b
    bt r8d, r10d
    setc al
    cmp r11b, al
    je .right_pair
    movss xmm1, [rel cost_bracket_tap_weight]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    and eax, 3
    jz .store_left_pair
    movss xmm2, [rel cost_one]
    divss xmm2, [r9]
    mulss xmm1, xmm2

.store_left_pair:
    mov r10, [rsp + 40]
    movss [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_LEFT], xmm1
    addss xmm0, xmm1

.right_pair:
    movsx eax, byte [rdx + 3]
    test eax, eax
    js .finish
    cmp eax, 4
    jae .finish
    movsx r10d, byte [rdx + 4]
    test r10d, r10d
    js .finish
    cmp r10d, 4
    jae .finish
    bt r8d, eax
    setc r11b
    bt r8d, r10d
    setc al
    cmp r11b, al
    je .finish
    movss xmm1, [rel cost_bracket_tap_weight]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    and eax, 12
    jz .store_right_pair
    movss xmm2, [rel cost_one]
    divss xmm2, [r9]
    mulss xmm1, xmm2

.store_right_pair:
    mov r10, [rsp + 40]
    movss [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_RIGHT], xmm1
    addss xmm0, xmm1

.finish:
    mov r10, [rsp + 40]
    movss [r10 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_TOTAL], xmm0
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = initial, rdx = result, r8 = hit[5], r9d = hold mask,
; stack arg 5 = elapsed seconds f32 ptr,
; stack arg 6 = out assp_step_parity_distance_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_distance_action_costs_4:
    test rcx, rcx
    jz .fail
    test rdx, rdx
    jz .fail
    test r8, r8
    jz .fail
    mov r10, [rsp + 40]
    test r10, r10
    jz .fail
    mov r11, [rsp + 48]
    test r11, r11
    jz .fail

    xor eax, eax
    mov [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_HOLD_SWITCH], eax
    mov [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_BIG_MOVEMENT], eax
    mov [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_TOTAL], eax
    xorps xmm0, xmm0

.hold_switch:
    movzx r10d, byte [rdx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK]
    and r10d, r9d
    and r10d, 0fh
    xor eax, eax
    xorps xmm1, xmm1

.hold_switch_loop:
    cmp eax, 4
    jae .store_hold_switch
    bt r10d, eax
    jnc .next_hold_switch_col
    movzx r11d, byte [rdx + ASSP_STEP_PARITY_STATE4_COMBINED + rax]
    test r11d, r11d
    jz .next_hold_switch_col
    cmp r11d, 4
    ja .next_hold_switch_col
    movzx r9d, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax]

    cmp r11d, 3
    jae .result_right
    cmp r9d, 1
    jb .hold_switched
    cmp r9d, 2
    jbe .next_hold_switch_col
    jmp .hold_switched

.result_right:
    cmp r9d, 3
    jb .hold_switched
    cmp r9d, 4
    jbe .next_hold_switch_col

.hold_switched:
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + r11]
    test r9d, r9d
    js .hold_missing_prev
    cmp r9d, 4
    jae .hold_missing_prev
    mov r11d, eax
    shl r11d, 2
    add r11d, r9d
    movsxd r11, r11d
    lea r9, [rel dance_single_distances4]
    addss xmm1, [r9 + r11 * 4]
    jmp .next_hold_switch_col

.hold_missing_prev:
    addss xmm1, [rel cost_one]

.next_hold_switch_col:
    inc eax
    jmp .hold_switch_loop

.store_hold_switch:
    mulss xmm1, [rel cost_hold_switch_weight]
    mov r11, [rsp + 48]
    movss [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_HOLD_SWITCH], xmm1
    addss xmm0, xmm1

.big_movement:
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    and eax, 0fh
    xorps xmm1, xmm1
    xor r10d, r10d

.big_movement_loop:
    cmp r10d, 4
    jae .store_big_movement
    bt eax, r10d
    jnc .next_big_movement_foot
    mov r11d, r10d
    inc r11d
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + r11]
    test r9d, r9d
    js .next_big_movement_foot
    cmp r9d, 4
    jae .next_big_movement_foot
    movsx r11d, byte [r8 + r11]
    test r11d, r11d
    js .next_big_movement_foot
    cmp r11d, 4
    jae .next_big_movement_foot

    shl r9d, 2
    add r9d, r11d
    movsxd r9, r9d
    lea r11, [rel dance_single_distances4]
    movss xmm2, [r11 + r9 * 4]
    mulss xmm2, [rel cost_distance_weight]
    mov r11, [rsp + 40]
    divss xmm2, [r11]

    mov r11d, r10d
    xor r11d, 1
    add r11d, 1
    movsx r11d, byte [r8 + r11]
    test r11d, r11d
    js .add_big_movement
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + r10 + 1]
    cmp r11d, r9d
    je .next_big_movement_foot
    mulss xmm2, [rel cost_big_movement_other_part_factor]

.add_big_movement:
    addss xmm1, xmm2

.next_big_movement_foot:
    inc r10d
    jmp .big_movement_loop

.store_big_movement:
    mov r11, [rsp + 48]
    movss [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_BIG_MOVEMENT], xmm1
    addss xmm0, xmm1

.finish:
    movss [r11 + ASSP_STEP_PARITY_DISTANCE_COSTS4_TOTAL], xmm0
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = initial, rdx = result, r8 = hit[5],
; r9 = out assp_step_parity_orientation_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_orientation_action_costs_4:
    test rcx, rcx
    jz .fail_no_stack
    test rdx, rdx
    jz .fail_no_stack
    test r8, r8
    jz .fail_no_stack
    test r9, r9
    jz .fail_no_stack

    sub rsp, 72
    xor eax, eax
    mov [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TWISTED_FOOT], eax
    mov [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_FACING], eax
    mov [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_SPIN], eax
    mov [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TOTAL], eax
    xorps xmm0, xmm0

.twisted_foot:
    movsx r10d, byte [r8 + 1]
    movsx r11d, byte [r8 + 2]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    mov [rsp], eax

    movsx r10d, byte [r8 + 3]
    movsx r11d, byte [r8 + 4]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    cmp eax, [rsp]
    jl .facing

    movsx r10d, byte [r8 + 3]
    movsx r11d, byte [r8 + 4]
    call orientation_backward_4
    test eax, eax
    jnz .store_twisted_foot
    movsx r10d, byte [r8 + 1]
    movsx r11d, byte [r8 + 2]
    call orientation_backward_4
    test eax, eax
    jz .facing

.store_twisted_foot:
    movss xmm1, [rel cost_twisted_foot_weight]
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TWISTED_FOOT], xmm1
    addss xmm0, xmm1

.facing:
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    mov [rsp], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    test eax, eax
    jns .store_result_left_toe
    mov eax, [rsp]
.store_result_left_toe:
    mov [rsp + 4], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    mov [rsp + 8], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    test eax, eax
    jns .store_result_right_toe
    mov eax, [rsp + 8]
.store_result_right_toe:
    mov [rsp + 12], eax

    xorps xmm1, xmm1
    mov r10d, [rsp]
    mov r11d, [rsp + 8]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_facing_x4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp + 4]
    mov r11d, [rsp + 12]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_facing_x4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp]
    mov r11d, [rsp + 4]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_facing_y4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp + 8]
    mov r11d, [rsp + 12]
    call orientation_pair_idx_4
    lea r10, [rel dance_single_facing_y4]
    addss xmm1, [r10 + rax * 4]
    mulss xmm1, [rel cost_facing_weight]
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_FACING], xmm1
    addss xmm0, xmm1

.spin:
    movsx r10d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    movsx r11d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    call orientation_pair_avg_4
    mov [rsp + 16], eax
    mov [rsp + 20], r11d
    movsx r10d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    movsx r11d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    call orientation_pair_avg_4
    mov [rsp + 24], eax
    mov [rsp + 28], r11d
    mov r10d, [rsp]
    mov r11d, [rsp + 4]
    call orientation_pair_avg_4
    mov [rsp + 32], eax
    mov [rsp + 36], r11d
    mov r10d, [rsp + 8]
    mov r11d, [rsp + 12]
    call orientation_pair_avg_4
    mov [rsp + 40], eax
    mov [rsp + 44], r11d

    mov eax, [rsp + 40]
    cmp eax, [rsp + 32]
    jge .finish
    mov eax, [rsp + 24]
    cmp eax, [rsp + 16]
    jge .finish
    mov eax, [rsp + 44]
    cmp eax, [rsp + 36]
    jl .spin_right_lower
    jg .spin_right_higher
    jmp .finish

.spin_right_lower:
    mov eax, [rsp + 28]
    cmp eax, [rsp + 20]
    jg .store_spin
    jmp .finish

.spin_right_higher:
    mov eax, [rsp + 28]
    cmp eax, [rsp + 20]
    jge .finish

.store_spin:
    movss xmm1, [rel cost_spin_weight]
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_SPIN], xmm1
    addss xmm0, xmm1

.finish:
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TOTAL], xmm0
    add rsp, 72
    mov eax, ASSP_TRUE
    ret

.fail_no_stack:
    xor eax, eax
    ret

; r10d/r11d = signed column ids. eax = pair table index.
orientation_pair_idx_4:
    test r10d, r10d
    js .left_invalid
    cmp r10d, 4
    jb .left_ok
.left_invalid:
    mov r10d, 4
.left_ok:
    test r11d, r11d
    js .right_invalid
    cmp r11d, 4
    jb .right_ok
.right_invalid:
    mov r11d, 4
.right_ok:
    lea eax, [r10 + r10 * 4]
    add eax, r11d
    ret

; r10d/r11d = heel/toe columns. eax = boolean toe y < heel y.
orientation_backward_4:
    test r10d, r10d
    js .no
    cmp r10d, 4
    jae .no
    test r11d, r11d
    js .no
    cmp r11d, 4
    jae .no
    lea rax, [rel dance_single_col_y2]
    movzx r10d, byte [rax + r10]
    movzx r11d, byte [rax + r11]
    xor eax, eax
    cmp r11d, r10d
    setl al
    ret
.no:
    xor eax, eax
    ret

; r10d/r11d = signed column ids. eax = avg x2, r11d = avg y2.
orientation_pair_avg_4:
    call orientation_pair_idx_4
    lea r10, [rel dance_single_pair_avg_y2]
    movzx r11d, byte [r10 + rax]
    lea r10, [rel dance_single_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    ret

; rcx = initial, rdx = result, r8 = placement[4], r9 = hit[5],
; stack arg 5 = note count, stack arg 6 = active mask,
; stack arg 7 = hold mask, stack arg 8 = mine|fake mine mask,
; stack arg 9 = side mask, stack arg 10 = prev row has live hold,
; stack arg 11 = elapsed seconds f32 ptr,
; stack arg 12 = out assp_step_parity_action_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_action_cost_4:
    test rcx, rcx
    jz .fail_no_stack
    test rdx, rdx
    jz .fail_no_stack
    test r8, r8
    jz .fail_no_stack
    test r9, r9
    jz .fail_no_stack
    mov rax, [rsp + 88]
    test rax, rax
    jz .fail_no_stack
    mov rax, [rsp + 96]
    test rax, rax
    jz .fail_no_stack

    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 256

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9
    mov rsi, [rsp + 400]
    mov rdi, [rsp + 408]

    mov rcx, r12
    mov rdx, r13
    mov r8, r15
    lea r9, [rsp + 80]
    call assp_step_parity_action_flags_4
    test eax, eax
    jz .fail

    mov eax, [rsp + 360]
    and eax, 0fh
    mov ecx, eax
    dec ecx
    test eax, ecx
    setnz r8b
    movzx r8d, r8b
    mov eax, [rsp + 392]
    mov [rsp + 32], eax
    lea rax, [rsp + 96]
    mov [rsp + 40], rax
    mov rcx, r13
    lea rdx, [rsp + 80]
    mov r9d, [rsp + 376]
    call assp_step_parity_basic_action_costs_4
    test eax, eax
    jz .fail

    lea rcx, [rsp + 80]
    mov edx, [rsp + 352]
    mov r8, rsi
    lea r9, [rsp + 120]
    call assp_step_parity_elapsed_action_costs_4
    test eax, eax
    jz .fail

    mov eax, [rsp + 384]
    mov [rsp + 32], eax
    mov eax, [rsp + 376]
    mov [rsp + 40], eax
    mov [rsp + 48], rsi
    lea rax, [rsp + 136]
    mov [rsp + 56], rax
    mov rcx, r12
    mov rdx, r13
    mov r8, r14
    mov r9d, [rsp + 360]
    call assp_step_parity_switch_action_costs_4
    test eax, eax
    jz .fail

    lea rax, [rsp + 152]
    mov [rsp + 32], rax
    mov rcx, r12
    mov rdx, r15
    mov r8d, [rsp + 368]
    mov r9, rsi
    call assp_step_parity_bracket_tap_action_costs_4
    test eax, eax
    jz .fail

    mov [rsp + 32], rsi
    lea rax, [rsp + 168]
    mov [rsp + 40], rax
    mov rcx, r12
    mov rdx, r13
    mov r8, r15
    mov r9d, [rsp + 368]
    call assp_step_parity_distance_action_costs_4
    test eax, eax
    jz .fail

    mov rcx, r12
    mov rdx, r13
    mov r8, r15
    lea r9, [rsp + 184]
    call assp_step_parity_orientation_action_costs_4
    test eax, eax
    jz .fail

    xorps xmm0, xmm0
    movss xmm1, [rsp + 96 + ASSP_STEP_PARITY_BASIC_COSTS4_MINE]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_MINE], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 168 + ASSP_STEP_PARITY_DISTANCE_COSTS4_HOLD_SWITCH]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_HOLD_SWITCH], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 152 + ASSP_STEP_PARITY_BRACKET_TAP_COSTS4_TOTAL]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_BRACKET_TAP], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 96 + ASSP_STEP_PARITY_BASIC_COSTS4_BRACKET_JACK]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_BRACKET_JACK], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 96 + ASSP_STEP_PARITY_BASIC_COSTS4_DOUBLESTEP]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_DOUBLESTEP], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 120 + ASSP_STEP_PARITY_ELAPSED_COSTS4_SLOW_BRACKET]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_SLOW_BRACKET], xmm1
    addss xmm0, xmm1

    mov eax, [rsp + 360]
    and eax, 0fh
    mov ecx, eax
    dec ecx
    test eax, ecx
    jz .no_twisted_foot
    movss xmm1, [rsp + 184 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TWISTED_FOOT]
    jmp .store_twisted_foot
.no_twisted_foot:
    xorps xmm1, xmm1
.store_twisted_foot:
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_TWISTED_FOOT], xmm1
    addss xmm0, xmm1

    movss xmm1, [rsp + 184 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_FACING]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_FACING], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 184 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_SPIN]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_SPIN], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 136 + ASSP_STEP_PARITY_SWITCH_COSTS4_FOOTSWITCH]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_FOOTSWITCH], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 136 + ASSP_STEP_PARITY_SWITCH_COSTS4_SIDESWITCH]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_SIDESWITCH], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 96 + ASSP_STEP_PARITY_BASIC_COSTS4_MISSED_FOOTSWITCH]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_MISSED_FOOTSWITCH], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 120 + ASSP_STEP_PARITY_ELAPSED_COSTS4_JACK]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_JACK], xmm1
    addss xmm0, xmm1
    movss xmm1, [rsp + 168 + ASSP_STEP_PARITY_DISTANCE_COSTS4_BIG_MOVEMENT]
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_BIG_MOVEMENT], xmm1
    addss xmm0, xmm1
    movss [rdi + ASSP_STEP_PARITY_ACTION_COSTS4_TOTAL], xmm0

    add rsp, 256
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    mov eax, ASSP_TRUE
    ret

.fail:
    add rsp, 256
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
.fail_no_stack:
    xor eax, eax
    ret

; rcx = initial states, rdx = initial costs, r8 = initial state count,
; r9 = assp_step_parity_row_cost_ctx4,
; stack arg 5 = out predecessor indexes,
; stack arg 6 = out placements[4 * cap],
; stack arg 7 = out states[12 * cap],
; stack arg 8 = out hits[5 * cap],
; stack arg 9 = out keys[4 * cap],
; stack arg 10 = out costs[cap],
; stack arg 11 = output capacity. Capacity must be at least state_count * 24.
; rax = unique best row-state key count, or ASSP_NOT_FOUND on invalid input.
assp_step_parity_row_best_candidates_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9
    mov rbx, [rsp + 104]
    mov rsi, [rsp + 112]
    mov rdi, [rsp + 120]
    mov rbp, [rsp + 128]
    mov r10, [rsp + 136]
    mov r11, [rsp + 144]
    mov rax, [rsp + 152]

    test r14, r14
    jz .zero_success
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r15, r15
    jz .fail
    test rbx, rbx
    jz .fail
    test rsi, rsi
    jz .fail
    test rdi, rdi
    jz .fail
    test rbp, rbp
    jz .fail
    test r10, r10
    jz .fail
    test r11, r11
    jz .fail
    test qword [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS], -1
    jz .fail

    mov [rsp + 104], r10
    mov [rsp + 112], r11
    mov [rsp + 120], rax
    mov rax, r14
    mov ecx, 24
    mul rcx
    jo .fail
    cmp [rsp + 120], rax
    jb .fail

    sub rsp, 960
    mov qword [rsp + 784], 0
    mov qword [rsp + 792], 0

.state_loop:
    mov rax, [rsp + 792]
    cmp rax, r14
    jae .success

    lea rcx, [rax + rax * 2]
    lea rcx, [r12 + rcx * 4]
    mov edx, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    mov r8d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    lea r9, [rsp + 112]
    lea r10, [rsp + 208]
    mov [rsp + 32], r10
    lea r10, [rsp + 496]
    mov [rsp + 40], r10
    lea r10, [rsp + 616]
    mov [rsp + 48], r10
    mov qword [rsp + 56], 24
    call assp_step_parity_row_transitions_4

    mov [rsp + 776], rax
    mov qword [rsp + 800], 0

.candidate_loop:
    mov rax, [rsp + 800]
    cmp rax, [rsp + 776]
    jae .next_state

    mov edx, [rsp + 616 + rax * 4]
    mov [rsp + 808], edx
    mov r10, [rsp + 1064]
    xor ecx, ecx

.scan_keys:
    cmp rcx, [rsp + 784]
    jae .new_key
    cmp [r10 + rcx * 4], edx
    je .found_key
    inc rcx
    jmp .scan_keys

.new_key:
    mov [rsp + 816], rcx
    mov byte [rsp + 824], 1
    jmp .score_candidate

.found_key:
    mov [rsp + 816], rcx
    mov byte [rsp + 824], 0

.score_candidate:
    mov rax, [rsp + 800]
    lea rcx, [rax + rax * 2]
    lea rdx, [rsp + 208 + rcx * 4]
    lea r8, [rsp + 112 + rax * 4]
    lea rcx, [rax + rax * 4]
    lea r9, [rsp + 496 + rcx]
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_COUNT]
    mov [rsp + 32], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    or eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    mov [rsp + 40], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    mov [rsp + 48], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_MINE_MASK]
    mov [rsp + 56], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_SIDE_MASK]
    mov [rsp + 64], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_PREV_ROW_HAS_LIVE_HOLD]
    mov [rsp + 72], eax
    mov rax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS]
    mov [rsp + 80], rax
    lea rax, [rsp + 712]
    mov [rsp + 88], rax
    mov rax, [rsp + 792]
    lea rax, [rax + rax * 2]
    lea rcx, [r12 + rax * 4]
    call assp_step_parity_action_cost_4
    test eax, eax
    jz .fail_with_stack

    mov rax, [rsp + 792]
    movss xmm0, [r13 + rax * 4]
    addss xmm0, [rsp + 712 + ASSP_STEP_PARITY_ACTION_COSTS4_TOTAL]

    cmp byte [rsp + 824], 0
    jne .write_candidate
    mov r11, [rsp + 1072]
    mov rcx, [rsp + 816]
    comiss xmm0, [r11 + rcx * 4]
    jae .skip_candidate

.write_candidate:
    mov rax, [rsp + 816]
    cmp byte [rsp + 824], 0
    je .copy_candidate
    inc qword [rsp + 784]

.copy_candidate:
    mov rdx, [rsp + 792]
    mov [rbx + rax * 4], edx

    mov rcx, [rsp + 800]
    mov edx, [rsp + 112 + rcx * 4]
    mov [rsi + rax * 4], edx

    lea r10, [rcx + rcx * 2]
    lea r10, [r10 * 4]
    lea r11, [rax + rax * 2]
    lea r11, [r11 * 4]
    mov rdx, [rsp + 208 + r10]
    mov [rdi + r11], rdx
    mov edx, [rsp + 216 + r10]
    mov [rdi + r11 + 8], edx

    lea r10, [rcx + rcx * 4]
    lea r11, [rax + rax * 4]
    mov edx, [rsp + 496 + r10]
    mov [rbp + r11], edx
    mov dl, [rsp + 500 + r10]
    mov [rbp + r11 + 4], dl

    mov r10, [rsp + 1064]
    mov edx, [rsp + 808]
    mov [r10 + rax * 4], edx

    mov r10, [rsp + 1072]
    movss [r10 + rax * 4], xmm0

.skip_candidate:
    inc qword [rsp + 800]
    jmp .candidate_loop

.next_state:
    inc qword [rsp + 792]
    jmp .state_loop

.success:
    mov rax, [rsp + 784]
    add rsp, 960
    jmp .done

.fail_with_stack:
    add rsp, 960
.fail:
    mov rax, ASSP_NOT_FOUND
    jmp .done

.zero_success:
    xor eax, eax

.done:
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

section .rdata
cost_mine_weight dd 10000.0
cost_bracket_jack_weight dd 20.0
cost_doublestep_weight dd 850.0
cost_missed_footswitch_weight dd 500.0
cost_bracket_tap_weight dd 400.0
cost_slow_bracket_threshold dd 0.15
cost_slow_bracket_weight dd 300.0
cost_jack_threshold dd 0.1
cost_jack_weight dd 30.0
cost_slow_footswitch_threshold dd 0.2
cost_slow_footswitch_ignore dd 0.4
cost_footswitch_weight dd 325.0
cost_sideswitch_weight dd 130.0
cost_hold_switch_weight dd 55.0
cost_distance_weight dd 6.0
cost_big_movement_other_part_factor dd 0.2
cost_twisted_foot_weight dd 100000.0
cost_facing_weight dd 2.0
cost_spin_weight dd 1000.0
cost_one dd 1.0
dance_single_distances4:
    dd 0.0, 1.4142135623730951, 1.4142135623730951, 2.0
    dd 1.4142135623730951, 0.0, 2.0, 1.4142135623730951
    dd 1.4142135623730951, 2.0, 0.0, 1.4142135623730951
    dd 2.0, 1.4142135623730951, 1.4142135623730951, 0.0
dance_single_col_y2 db 2, 0, 4, 2
dance_single_pair_avg_x2:
    db 0, 1, 1, 2, 0
    db 1, 2, 2, 3, 2
    db 1, 2, 2, 3, 2
    db 2, 3, 3, 4, 4
    db 0, 2, 2, 4, 0
dance_single_pair_avg_y2:
    db 2, 1, 3, 2, 2
    db 1, 0, 2, 1, 0
    db 3, 2, 4, 3, 4
    db 2, 1, 3, 2, 2
    db 2, 0, 4, 2, 0
dance_single_facing_x4:
    dd 0.0, 0.0, 0.0, 0.0, 0.0
    dd 8.246923447, 0.0, 0.0, 0.0, 0.0
    dd 8.246923447, 0.0, 0.0, 0.0, 0.0
    dd 100.0, 8.246923447, 8.246923447, 0.0, 0.0
    dd 0.0, 0.0, 0.0, 0.0, 0.0
dance_single_facing_y4:
    dd 0.0, 8.246923447, 0.0, 0.0, 0.0
    dd 0.0, 0.0, 0.0, 0.0, 0.0
    dd 8.246923447, 100.0, 0.0, 8.246923447, 0.0
    dd 0.0, 8.246923447, 0.0, 0.0, 0.0
    dd 0.0, 0.0, 0.0, 0.0, 0.0
