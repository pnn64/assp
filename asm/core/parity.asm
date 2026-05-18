default rel
%include "assp.inc"

global assp_step_parity_permutations_4
global assp_step_parity_result_state_no_holds_4
global assp_step_parity_result_state_holds_4
global assp_step_parity_row_transitions_4
global assp_step_parity_row_key_candidates_4
global assp_step_parity_action_flags_4
global assp_step_parity_basic_action_costs_4

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

section .rdata
cost_mine_weight dd 10000.0
cost_bracket_jack_weight dd 20.0
cost_doublestep_weight dd 850.0
cost_missed_footswitch_weight dd 500.0
