default rel
%include "assp.inc"

extern assp_calculate_step_tech_counts_from_placements_4
extern assp_calculate_step_tech_counts_from_placements_seconds_4
extern assp_calculate_step_tech_counts_from_placements_seconds_8

global assp_step_parity_permutations_4
global assp_step_parity_permutations_8
global assp_step_parity_result_state_no_holds_4
global assp_step_parity_result_state_holds_4
global assp_step_parity_result_state_no_holds_8
global assp_step_parity_result_state_holds_8
global assp_step_parity_row_transitions_4
global assp_step_parity_row_transitions_8
global assp_step_parity_row_key_candidates_4
global assp_step_parity_row_key_candidates_8
global assp_step_parity_action_flags_4
global assp_step_parity_action_flags_8
global assp_step_parity_basic_action_costs_4
global assp_step_parity_basic_action_costs_8
global assp_step_parity_elapsed_action_costs_4
global assp_step_parity_elapsed_action_costs_8
global assp_step_parity_switch_action_costs_4
global assp_step_parity_switch_action_costs_8
global assp_step_parity_bracket_tap_action_costs_4
global assp_step_parity_bracket_tap_action_costs_8
global assp_step_parity_distance_action_costs_4
global assp_step_parity_distance_action_costs_8
global assp_step_parity_orientation_action_costs_4
global assp_step_parity_orientation_action_costs_8
global assp_step_parity_action_cost_4
global assp_step_parity_action_cost_8
global assp_step_parity_row_best_candidates_4
global assp_step_parity_row_best_candidates_8
global assp_step_parity_place_rows_4
global assp_step_parity_place_rows_8
global assp_step_parity_count_prepared_rows_4
global assp_step_parity_count_prepared_rows_8
global assp_step_parity_hold_head_ends_4
global assp_step_parity_hold_head_ends_8
global assp_step_parity_bpm_row_times_4
global assp_step_parity_bpm_row_times_micro_4
global assp_step_parity_bpm_row_times_8
global assp_step_parity_bpm_row_times_micro_8
global assp_step_parity_prepare_hold_rows_4
global assp_step_parity_prepare_hold_rows_8
global assp_step_parity_prepare_tap_rows_4

%ifdef ASSP_PHASE_PROFILE
extern profile_step_dp_transition_cycles
extern profile_step_dp_hash_cycles
extern profile_step_dp_score_cycles
extern profile_step_dp_copy_cycles
extern profile_step_dp_transition_count
extern profile_step_dp_hash_probe_count
extern profile_step_dp_score_clean_count
extern profile_step_dp_score_full_count
extern profile_step_dp_write_count
extern profile_step_dp_skip_count

%macro ASSP_PROFILE_TSC_BEGIN 0
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [rsp + 888], rax
%endmacro

%macro ASSP_PROFILE_TSC_END 1
    rdtsc
    shl rdx, 32
    or rax, rdx
    sub rax, [rsp + 888]
    add qword [rel %1], rax
%endmacro

%macro ASSP_PROFILE_INC 1
    inc qword [rel %1]
%endmacro
%else
%macro ASSP_PROFILE_TSC_BEGIN 0
%endmacro

%macro ASSP_PROFILE_TSC_END 1
%endmacro

%macro ASSP_PROFILE_INC 1
%endmacro
%endif

section .text

; ecx = 4-panel active column mask, rdx = optional output placements,
; r8 = output capacity in placements. Each placement is 4 bytes of Foot ids:
; 0 none, 1 left heel, 2 left toe, 3 right heel, 4 right toe.
; rax = total valid placement count. Writes up to out_cap placements.
assp_step_parity_permutations_4:
    and ecx, 0fh
    lea r10, [rel step_parity_perm4_counts]
    movzx eax, byte [r10 + rcx]
    test rdx, rdx
    jz .done
    test r8, r8
    jz .done

    lea r10, [rel step_parity_perm4_offsets]
    movzx r10d, byte [r10 + rcx]
    lea r11, [rel step_parity_perm4_values]
    lea r11, [r11 + r10 * 4]
    mov r10, rax
    cmp r8, r10
    cmovb r10, r8

.copy_loop:
    test r10, r10
    jz .done
    mov r9d, [r11]
    mov [rdx], r9d
    add r11, 4
    add rdx, 4
    dec r10
    jmp .copy_loop

.done:
    ret

; ecx = 8-panel active column mask, rdx = optional output placements,
; r8 = output capacity in placements. Each placement is 8 bytes of Foot ids:
; 0 none, 1 left heel, 2 left toe, 3 right heel, 4 right toe.
; rax = total valid placement count. Writes up to out_cap placements.
assp_step_parity_permutations_8:
    and ecx, 0ffh
    lea r10, [rel step_parity_perm8_counts]
    movzx eax, byte [r10 + rcx]
    test rdx, rdx
    jz .done
    test r8, r8
    jz .done

    lea r10, [rel step_parity_perm8_offsets]
    movzx r10d, word [r10 + rcx * 2]
    lea r11, [rel step_parity_perm8_values]
    lea r11, [r11 + r10 * 8]
    mov r10, rax
    cmp r8, r10
    cmovb r10, r8

.copy_loop:
    test r10, r10
    jz .done
    mov r9, [r11]
    mov [rdx], r9
    add r11, 8
    add rdx, 8
    dec r10
    jmp .copy_loop

.done:
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

; rcx = initial assp_step_parity_state8, rdx = placement[8],
; r8d = active mask, r9 = out state, stack arg 5 = out hit[5],
; stack arg 6 = out key.
; eax = 1 on success, 0 on invalid required pointers.
assp_step_parity_result_state_no_holds_8:
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

    mov qword [r15 + ASSP_STEP_PARITY_STATE8_COMBINED], 0
    mov dword [r15 + ASSP_STEP_PARITY_STATE8_WHERE_FEET], 0ffffffffh
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 4], 0ffh
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK], 0
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_MOVED_MASK], 0
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], 0
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
    mov [r15 + ASSP_STEP_PARITY_STATE8_COMBINED + r10], al
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
    cmp r10d, 8
    jb .active_loop

    xor r10d, r10d
    xor r11d, r11d
    xor edx, edx

.resolve_loop:
    movzx eax, byte [r15 + ASSP_STEP_PARITY_STATE8_COMBINED + r10]
    test al, al
    jnz .have_foot
    movzx eax, byte [r12 + ASSP_STEP_PARITY_STATE8_COMBINED + r10]
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
    mov [r15 + ASSP_STEP_PARITY_STATE8_COMBINED + r10], al

.have_foot:
    mov ecx, r10d
    imul ecx, 3
    mov r8d, eax
    shl r8d, cl
    or r11d, r8d
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_WHERE_FEET + rax], r10b
    mov ecx, r10d
    mov r8d, 1
    shl r8d, cl
    or edx, r8d

.next_resolve:
    inc r10d
    cmp r10d, 8
    jb .resolve_loop

    mov [r15 + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK], dl
    mov [r15 + ASSP_STEP_PARITY_STATE8_MOVED_MASK], bl
    mov byte [r15 + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], 0
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

; rcx = initial assp_step_parity_state8, rdx = placement[8],
; r8d = active mask, r9d = hold mask, stack arg 5 = out state,
; stack arg 6 = out hit[5], stack arg 7 = out key.
; eax = 1 on success, 0 on invalid required pointers.
assp_step_parity_result_state_holds_8:
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

    mov qword [rbx + ASSP_STEP_PARITY_STATE8_COMBINED], 0
    mov dword [rbx + ASSP_STEP_PARITY_STATE8_WHERE_FEET], 0ffffffffh
    mov byte [rbx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 4], 0ffh
    mov byte [rbx + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK], 0
    mov byte [rbx + ASSP_STEP_PARITY_STATE8_MOVED_MASK], 0
    mov byte [rbx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], 0
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
    mov [rbx + ASSP_STEP_PARITY_STATE8_COMBINED + r10], al
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
    cmp [r12 + ASSP_STEP_PARITY_STATE8_COMBINED + r10], al
    je .next_active

.mark_moved:
    or r11d, edx

.next_active:
    inc r10d
    cmp r10d, 8
    jb .active_loop

    mov r15d, r8d
    xor r10d, r10d
    xor r14d, r14d
    xor edx, edx

.resolve_loop:
    movzx eax, byte [rbx + ASSP_STEP_PARITY_STATE8_COMBINED + r10]
    test al, al
    jnz .have_foot
    movzx eax, byte [r12 + ASSP_STEP_PARITY_STATE8_COMBINED + r10]
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
    mov [rbx + ASSP_STEP_PARITY_STATE8_COMBINED + r10], al

.have_foot:
    mov ecx, r10d
    imul ecx, 3
    mov r8d, eax
    shl r8d, cl
    or r14d, r8d
    mov byte [rbx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + rax], r10b
    mov ecx, r10d
    mov r8d, 1
    shl r8d, cl
    or edx, r8d

.next_resolve:
    inc r10d
    cmp r10d, 8
    jb .resolve_loop

    mov [rbx + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK], dl
    mov [rbx + ASSP_STEP_PARITY_STATE8_MOVED_MASK], r11b
    mov [rbx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], r15b
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

; rcx = initial assp_step_parity_state8, edx = row note mask,
; r8d = row hold mask, r9 = optional out placements[8 * cap],
; stack arg 5 = optional out states[16 * cap],
; stack arg 6 = optional out hits[5 * cap],
; stack arg 7 = optional out keys[4 * cap],
; stack arg 8 = output capacity in transitions.
; rax = total legal transition count.
assp_step_parity_row_transitions_8:
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
    and r13d, 0ffh
    mov r14d, r8d
    and r14d, 0ffh
    mov r15, r9
    mov rsi, [rsp + 104]
    mov rdi, [rsp + 112]
    mov rbx, [rsp + 120]
    mov rbp, [rsp + 128]

    test r12, r12
    jz .fail

    sub rsp, 320

    mov ecx, r13d
    lea rdx, [rsp + 64]
    mov r8d, 24
    call assp_step_parity_permutations_8
    mov [rsp + 304], rax
    mov qword [rsp + 296], 0

.loop:
    mov rax, [rsp + 296]
    cmp rax, [rsp + 304]
    jae .success

    lea rdx, [rsp + 64 + rax * 8]
    test r14d, r14d
    jnz .with_holds

    mov rcx, r12
    mov r8d, r13d
    lea r9, [rsp + 256]
    lea r10, [rsp + 272]
    mov [rsp + 32], r10
    lea r10, [rsp + 280]
    mov [rsp + 40], r10
    call assp_step_parity_result_state_no_holds_8
    jmp .maybe_emit

.with_holds:
    mov rcx, r12
    mov r8d, r13d
    mov r9d, r14d
    lea r10, [rsp + 256]
    mov [rsp + 32], r10
    lea r10, [rsp + 272]
    mov [rsp + 40], r10
    lea r10, [rsp + 280]
    mov [rsp + 48], r10
    call assp_step_parity_result_state_holds_8

.maybe_emit:
    mov rax, [rsp + 296]
    cmp rax, rbp
    jae .next

    test r15, r15
    jz .copy_state
    mov rdx, [rsp + 64 + rax * 8]
    mov [r15 + rax * 8], rdx

.copy_state:
    test rsi, rsi
    jz .copy_hit
    mov r10, rax
    shl r10, 4
    mov rdx, [rsp + 256]
    mov [rsi + r10], rdx
    mov rdx, [rsp + 264]
    mov [rsi + r10 + 8], rdx

.copy_hit:
    test rdi, rdi
    jz .copy_key
    lea r10, [rax + rax * 4]
    mov edx, [rsp + 272]
    mov [rdi + r10], edx
    mov dl, [rsp + 276]
    mov [rdi + r10 + 4], dl

.copy_key:
    test rbx, rbx
    jz .next
    mov edx, [rsp + 280]
    mov [rbx + rax * 4], edx

.next:
    inc qword [rsp + 296]
    jmp .loop

.success:
    mov rax, [rsp + 304]
    add rsp, 320
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

; rcx = initial states, rdx = initial state count, r8d = row note mask,
; r9d = row hold mask, stack arg 5 = out predecessor indexes,
; stack arg 6 = out placements[8 * cap], stack arg 7 = out states[16 * cap],
; stack arg 8 = out hits[5 * cap], stack arg 9 = out keys[4 * cap],
; stack arg 10 = output capacity. Capacity must be at least state_count * 24.
; rax = unique row-state key count, or ASSP_NOT_FOUND on invalid input.
assp_step_parity_row_key_candidates_8:
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

    sub rsp, 928
    mov [rsp + 888], r10
    mov [rsp + 896], r11
    mov qword [rsp + 848], 0
    mov qword [rsp + 856], 0

.state_loop:
    mov rax, [rsp + 856]
    cmp rax, r13
    jae .success

    mov rcx, rax
    shl rcx, 4
    add rcx, r12
    mov edx, r14d
    mov r8d, r15d
    lea r9, [rsp + 64]
    lea r10, [rsp + 256]
    mov [rsp + 32], r10
    lea r10, [rsp + 640]
    mov [rsp + 40], r10
    lea r10, [rsp + 760]
    mov [rsp + 48], r10
    mov qword [rsp + 56], 24
    call assp_step_parity_row_transitions_8

    mov [rsp + 864], rax
    mov qword [rsp + 872], 0

.candidate_loop:
    mov rax, [rsp + 872]
    cmp rax, [rsp + 864]
    jae .next_state

    mov edx, [rsp + 760 + rax * 4]
    mov [rsp + 880], edx
    mov r10, [rsp + 888]
    xor ecx, ecx

.scan_keys:
    cmp rcx, [rsp + 848]
    jae .emit_candidate
    cmp [r10 + rcx * 4], edx
    je .skip_candidate
    inc rcx
    jmp .scan_keys

.emit_candidate:
    mov rax, [rsp + 848]

    mov edx, [rsp + 856]
    mov [rbx + rax * 4], edx

    mov rcx, [rsp + 872]
    mov rdx, [rsp + 64 + rcx * 8]
    mov [rsi + rax * 8], rdx

    mov r10, rcx
    shl r10, 4
    mov r11, rax
    shl r11, 4
    mov rdx, [rsp + 256 + r10]
    mov [rdi + r11], rdx
    mov rdx, [rsp + 264 + r10]
    mov [rdi + r11 + 8], rdx

    lea r10, [rcx + rcx * 4]
    lea r11, [rax + rax * 4]
    mov edx, [rsp + 640 + r10]
    mov [rbp + r11], edx
    mov dl, [rsp + 644 + r10]
    mov [rbp + r11 + 4], dl

    mov r10, [rsp + 888]
    mov edx, [rsp + 880]
    mov [r10 + rax * 4], edx

    inc qword [rsp + 848]

.skip_candidate:
    inc qword [rsp + 872]
    jmp .candidate_loop

.next_state:
    inc qword [rsp + 856]
    jmp .state_loop

.success:
    mov rax, [rsp + 848]
    add rsp, 928
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

; rcx = initial assp_step_parity_state8, rdx = result state,
; r8 = hit[5], r9 = out assp_step_parity_action_flags4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_action_flags_8:
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

    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
    movzx r10d, byte [rcx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK]
    not r10d
    and eax, r10d
    mov r10d, eax

    test r10b, 3
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_LEFT_MOVED_NOT_HOLDING]
    test r10b, 12
    setnz byte [r9 + ASSP_STEP_PARITY_ACTION_FLAGS4_RIGHT_MOVED_NOT_HOLDING]

    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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
    call action_check_jack_foot_8
    test eax, eax
    jnz .left_jacked
    mov r10d, 2
    call action_check_jack_foot_8
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
    call action_check_jack_foot_8
    test eax, eax
    jnz .right_jacked
    mov r10d, 4
    call action_check_jack_foot_8
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
action_check_jack_foot_8:
    movsx eax, byte [r8 + r10]
    test eax, eax
    js .no
    cmp eax, 8
    jae .no
    cmp [rcx + ASSP_STEP_PARITY_STATE8_COMBINED + rax], r10b
    jne .no
    lea r11d, [r10d - 1]
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK]
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

; rcx = result state8, rdx = action flags, r8d = multi-active row,
; r9d = mine|fake mine mask, stack arg 5 = prev row has live hold,
; stack arg 6 = out assp_step_parity_basic_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_basic_action_costs_8:
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
    and al, [rcx + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK]
    jz .bracket_jack
    movss xmm1, [rel cost_mine_weight]
    movss [r10 + ASSP_STEP_PARITY_BASIC_COSTS4_MINE], xmm1
    addss xmm0, xmm1

.bracket_jack:
    test r8d, r8d
    jz .doublestep
    cmp byte [rcx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], 0
    jne .doublestep
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_DID_JUMP], 0
    jne .doublestep
    mov al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_LEFT]
    cmp al, [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_MOVED_RIGHT]
    je .doublestep

    xorps xmm2, xmm2
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_LEFT], 0
    je .right_bracket_jack
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
    and eax, 3
    cmp eax, 3
    jne .right_bracket_jack
    addss xmm2, [rel cost_bracket_jack_weight]

.right_bracket_jack:
    cmp byte [rdx + ASSP_STEP_PARITY_ACTION_FLAGS4_JACKED_RIGHT], 0
    je .store_bracket_jack
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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
    cmp byte [rcx + ASSP_STEP_PARITY_STATE8_HOLDING_MASK], 0
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

; Same inputs/output as assp_step_parity_elapsed_action_costs_4.
assp_step_parity_elapsed_action_costs_8:
    jmp assp_step_parity_elapsed_action_costs_4

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

; rcx = initial state8, rdx = result state8, r8 = placement[8], r9d = active mask,
; stack arg 5 = side mask, stack arg 6 = mine mask,
; stack arg 7 = elapsed seconds f32 ptr,
; stack arg 8 = out assp_step_parity_switch_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_switch_action_costs_8:
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
    and r9d, 0ffh

.footswitch_loop:
    cmp eax, 8
    jae .sideswitch
    bt r9d, eax
    jnc .next_footswitch_col
    movzx r10d, byte [r8 + rax]
    test r10d, r10d
    jz .next_footswitch_col
    cmp r10d, 4
    ja .next_footswitch_col
    movzx r11d, byte [rcx + ASSP_STEP_PARITY_STATE8_COMBINED + rax]
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
    and r10d, 0ffh
    xor eax, eax

.sideswitch_loop:
    cmp eax, 8
    jae .store_sideswitch
    bt r10d, eax
    jnc .next_sideswitch_col
    movzx r11d, byte [r8 + rax]
    test r11d, r11d
    jz .next_sideswitch_col
    movzx r9d, byte [rcx + ASSP_STEP_PARITY_STATE8_COMBINED + rax]
    test r9d, r9d
    jz .next_sideswitch_col
    cmp r9d, r11d
    je .next_sideswitch_col
    cmp r9d, 4
    ja .next_sideswitch_col
    movzx r11d, byte [rdx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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

; rcx = initial state8, rdx = hit[5], r8d = hold mask,
; r9 = elapsed seconds f32 ptr,
; stack arg 5 = out assp_step_parity_bracket_tap_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_bracket_tap_action_costs_8:
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
    cmp eax, 8
    jae .right_pair
    movsx r10d, byte [rdx + 2]
    test r10d, r10d
    js .right_pair
    cmp r10d, 8
    jae .right_pair
    bt r8d, eax
    setc r11b
    bt r8d, r10d
    setc al
    cmp r11b, al
    je .right_pair
    movss xmm1, [rel cost_bracket_tap_weight]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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
    cmp eax, 8
    jae .finish
    movsx r10d, byte [rdx + 4]
    test r10d, r10d
    js .finish
    cmp r10d, 8
    jae .finish
    bt r8d, eax
    setc r11b
    bt r8d, r10d
    setc al
    cmp r11b, al
    je .finish
    movss xmm1, [rel cost_bracket_tap_weight]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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

; rcx = initial state8, rdx = result state8, r8 = hit[5], r9d = hold mask,
; stack arg 5 = elapsed seconds f32 ptr,
; stack arg 6 = out assp_step_parity_distance_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_distance_action_costs_8:
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
    movzx r10d, byte [rdx + ASSP_STEP_PARITY_STATE8_OCCUPIED_MASK]
    and r10d, r9d
    and r10d, 0ffh
    xor eax, eax
    xorps xmm1, xmm1

.hold_switch_loop:
    cmp eax, 8
    jae .store_hold_switch
    bt r10d, eax
    jnc .next_hold_switch_col
    movzx r11d, byte [rdx + ASSP_STEP_PARITY_STATE8_COMBINED + rax]
    test r11d, r11d
    jz .next_hold_switch_col
    cmp r11d, 4
    ja .next_hold_switch_col
    movzx r9d, byte [rcx + ASSP_STEP_PARITY_STATE8_COMBINED + rax]

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
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + r11]
    test r9d, r9d
    js .hold_missing_prev
    cmp r9d, 8
    jae .hold_missing_prev
    mov r11d, eax
    shl r11d, 3
    add r11d, r9d
    movsxd r11, r11d
    lea r9, [rel dance_double_distances8]
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
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_MOVED_MASK]
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
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + r11]
    test r9d, r9d
    js .next_big_movement_foot
    cmp r9d, 8
    jae .next_big_movement_foot
    movsx r11d, byte [r8 + r11]
    test r11d, r11d
    js .next_big_movement_foot
    cmp r11d, 8
    jae .next_big_movement_foot

    shl r9d, 3
    add r9d, r11d
    movsxd r9, r9d
    lea r11, [rel dance_double_distances8]
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
    movsx r9d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + r10 + 1]
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

; rcx = initial state8, rdx = result state8, r8 = hit[5],
; r9 = out assp_step_parity_orientation_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_orientation_action_costs_8:
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
    call orientation_pair_idx_8
    lea r10, [rel dance_double_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    mov [rsp], eax

    movsx r10d, byte [r8 + 3]
    movsx r11d, byte [r8 + 4]
    call orientation_pair_idx_8
    lea r10, [rel dance_double_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    cmp eax, [rsp]
    jl .facing

    movsx r10d, byte [r8 + 3]
    movsx r11d, byte [r8 + 4]
    call orientation_backward_8
    test eax, eax
    jnz .store_twisted_foot
    movsx r10d, byte [r8 + 1]
    movsx r11d, byte [r8 + 2]
    call orientation_backward_8
    test eax, eax
    jz .facing

.store_twisted_foot:
    movss xmm1, [rel cost_twisted_foot_weight]
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_TWISTED_FOOT], xmm1
    addss xmm0, xmm1

.facing:
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 1]
    mov [rsp], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 2]
    test eax, eax
    jns .store_result_left_toe
    mov eax, [rsp]
.store_result_left_toe:
    mov [rsp + 4], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 3]
    mov [rsp + 8], eax
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 4]
    test eax, eax
    jns .store_result_right_toe
    mov eax, [rsp + 8]
.store_result_right_toe:
    mov [rsp + 12], eax

    xorps xmm1, xmm1
    mov r10d, [rsp]
    mov r11d, [rsp + 8]
    call orientation_pair_idx_8
    lea r10, [rel dance_double_facing_x4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp + 4]
    mov r11d, [rsp + 12]
    call orientation_pair_idx_8
    lea r10, [rel dance_double_facing_x4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp]
    mov r11d, [rsp + 4]
    call orientation_pair_idx_8
    lea r10, [rel dance_double_facing_y4]
    addss xmm1, [r10 + rax * 4]
    mov r10d, [rsp + 8]
    mov r11d, [rsp + 12]
    call orientation_pair_idx_8
    lea r10, [rel dance_double_facing_y4]
    addss xmm1, [r10 + rax * 4]
    mulss xmm1, [rel cost_facing_weight]
    movss [r9 + ASSP_STEP_PARITY_ORIENTATION_COSTS4_FACING], xmm1
    addss xmm0, xmm1

.spin:
    movsx r10d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 1]
    movsx r11d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 2]
    call orientation_pair_avg_8
    mov [rsp + 16], eax
    mov [rsp + 20], r11d
    movsx r10d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 3]
    movsx r11d, byte [rcx + ASSP_STEP_PARITY_STATE8_WHERE_FEET + 4]
    call orientation_pair_avg_8
    mov [rsp + 24], eax
    mov [rsp + 28], r11d
    mov r10d, [rsp]
    mov r11d, [rsp + 4]
    call orientation_pair_avg_8
    mov [rsp + 32], eax
    mov [rsp + 36], r11d
    mov r10d, [rsp + 8]
    mov r11d, [rsp + 12]
    call orientation_pair_avg_8
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

; r10d/r11d = signed column ids. eax = pair table index.
orientation_pair_idx_8:
    test r10d, r10d
    js .left_invalid
    cmp r10d, 8
    jb .left_ok
.left_invalid:
    mov r10d, 8
.left_ok:
    test r11d, r11d
    js .right_invalid
    cmp r11d, 8
    jb .right_ok
.right_invalid:
    mov r11d, 8
.right_ok:
    lea eax, [r10 + r10 * 8]
    add eax, r11d
    ret

; r10d/r11d = heel/toe columns. eax = boolean toe y < heel y.
orientation_backward_8:
    test r10d, r10d
    js .no
    cmp r10d, 8
    jae .no
    test r11d, r11d
    js .no
    cmp r11d, 8
    jae .no
    lea rax, [rel dance_double_col_y2]
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
orientation_pair_avg_8:
    call orientation_pair_idx_8
    lea r10, [rel dance_double_pair_avg_y2]
    movzx r11d, byte [r10 + rax]
    lea r10, [rel dance_double_pair_avg_x2]
    movzx eax, byte [r10 + rax]
    ret

%macro ASSP_PAIR_IDX_EAX 2
    lea r11, [rel step_parity_col_norm]
    movzx eax, byte %1
    movzx eax, byte [r11 + rax]
    movzx ecx, byte %2
    movzx ecx, byte [r11 + rcx]
    lea eax, [rax + rax * 4]
    add eax, ecx
%endmacro

%macro ASSP_PAIR_IDX_NORM_EAX 2
    mov eax, dword %1
    lea eax, [rax + rax * 4]
    add eax, dword %2
%endmacro

; Internal row-DP hot path. Same inputs as assp_step_parity_action_cost_4
; except there is no output breakdown pointer; stack arg 8 points at row-local
; slow bracket, footswitch, and jack costs; returns total cost in xmm0.
step_parity_action_cost_total_4:
    sub rsp, 128
    mov [rsp + 96], rcx
    mov [rsp + 104], rdx
    mov [rsp + 112], r8
    mov [rsp + 120], r9

    xorps xmm0, xmm0

    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    mov [rsp + 12], eax
    movzx r10d, byte [rcx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK]
    not r10d
    and eax, r10d
    xor r10d, r10d
    test al, 3
    jz .flag_right_moved_not_holding
    or r10b, 32
.flag_right_moved_not_holding:
    test al, 12
    jz .flag_result_moved
    or r10b, 64

.flag_result_moved:
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    mov [rsp + 4], eax
    test al, 3
    jz .flag_result_right
    or r10b, 1
.flag_result_right:
    test al, 12
    jz .flag_holding
    or r10b, 2

.flag_holding:
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK]
    mov [rsp + 8], eax
    mov eax, r10d
    and eax, 96
    cmp eax, 96
    jne .store_flags
    or r10b, 4
.store_flags:
    mov [rsp], r10b

    mov eax, [rsp + 176]
    and eax, 0fh
    mov ecx, eax
    dec ecx
    test eax, ecx
    setnz byte [rsp + 72]

    mov rcx, [rsp + 96]
    mov rdx, [rsp + 104]
    mov r9, [rsp + 120]
    test r10b, 4
    jnz .cost_mine
    test r10b, 1
    jz .check_jacked_right
    test r10b, 32
    jz .check_jacked_right
    movsx eax, byte [r9 + 1]
    test eax, eax
    js .check_left_toe_jack
    cmp eax, 4
    jae .check_left_toe_jack
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax], 1
    jne .check_left_toe_jack
    test byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 1
    jz .mark_jacked_left
.check_left_toe_jack:
    movsx eax, byte [r9 + 2]
    test eax, eax
    js .check_jacked_right
    cmp eax, 4
    jae .check_jacked_right
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax], 2
    jne .check_jacked_right
    test byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 2
    jnz .check_jacked_right
.mark_jacked_left:
    or byte [rsp], 8

.check_jacked_right:
    mov r10b, [rsp]
    test r10b, 2
    jz .cost_mine
    test r10b, 64
    jz .cost_mine
    movsx eax, byte [r9 + 3]
    test eax, eax
    js .check_right_toe_jack
    cmp eax, 4
    jae .check_right_toe_jack
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax], 3
    jne .check_right_toe_jack
    test byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 4
    jz .mark_jacked_right
.check_right_toe_jack:
    movsx eax, byte [r9 + 4]
    test eax, eax
    js .cost_mine
    cmp eax, 4
    jae .cost_mine
    cmp byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + rax], 4
    jne .cost_mine
    test byte [rdx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 8
    jnz .cost_mine
.mark_jacked_right:
    or byte [rsp], 16

.cost_mine:
    mov eax, [rsp + 192]
    test eax, eax
    jz .cost_hold
    mov rdx, [rsp + 104]
    and al, [rdx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK]
    jz .cost_hold
    addss xmm0, [rel cost_mine_weight]

.cost_hold:
    mov r10d, [rsp + 184]
    test r10d, r10d
    jz .cost_bracket_jack

    mov rdx, [rsp + 104]
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK]
    and r10d, eax
    and r10d, 0fh
    jz .cost_bracket_tap
    xorps xmm1, xmm1
    xor r11d, r11d

.hold_switch_loop:
    cmp r11d, 4
    jae .hold_switch_done
    bt r10d, r11d
    jnc .next_hold_switch
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_COMBINED + r11]
    test eax, eax
    jz .next_hold_switch
    cmp eax, 4
    ja .next_hold_switch
    mov rcx, [rsp + 96]
    movzx r8d, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r11]
    cmp eax, 3
    jae .hold_result_right
    cmp r8d, 1
    jb .hold_switched
    cmp r8d, 2
    jbe .next_hold_switch
    jmp .hold_switched
.hold_result_right:
    cmp r8d, 3
    jb .hold_switched
    cmp r8d, 4
    jbe .next_hold_switch

.hold_switched:
    movsx r8d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax]
    test r8d, r8d
    js .hold_missing_prev
    cmp r8d, 4
    jae .hold_missing_prev
    mov eax, r11d
    shl eax, 2
    add eax, r8d
    lea r8, [rel dance_single_distances4]
    addss xmm1, [r8 + rax * 4]
    mov rdx, [rsp + 104]
    jmp .next_hold_switch

.hold_missing_prev:
    addss xmm1, [rel cost_one]

.next_hold_switch:
    inc r11d
    jmp .hold_switch_loop

.hold_switch_done:
    mulss xmm1, [rel cost_hold_switch_weight]
    addss xmm0, xmm1

.cost_bracket_tap:
    mov r9, [rsp + 120]
    mov r10d, [rsp + 184]
    movsx eax, byte [r9 + 1]
    test eax, eax
    js .right_bracket_tap
    cmp eax, 4
    jae .right_bracket_tap
    movsx ecx, byte [r9 + 2]
    test ecx, ecx
    js .right_bracket_tap
    cmp ecx, 4
    jae .right_bracket_tap
    bt r10d, eax
    setc r11b
    bt r10d, ecx
    setc al
    cmp r11b, al
    je .right_bracket_tap
    movss xmm1, [rel cost_bracket_tap_weight]
    test dword [rsp + 12], 3
    jz .add_left_bracket_tap
    movss xmm2, [rel cost_one]
    mov rdx, [rsp + 216]
    divss xmm2, [rdx]
    mulss xmm1, xmm2
.add_left_bracket_tap:
    addss xmm0, xmm1

.right_bracket_tap:
    mov r9, [rsp + 120]
    mov r10d, [rsp + 184]
    movsx eax, byte [r9 + 3]
    test eax, eax
    js .cost_bracket_jack
    cmp eax, 4
    jae .cost_bracket_jack
    movsx ecx, byte [r9 + 4]
    test ecx, ecx
    js .cost_bracket_jack
    cmp ecx, 4
    jae .cost_bracket_jack
    bt r10d, eax
    setc r11b
    bt r10d, ecx
    setc al
    cmp r11b, al
    je .cost_bracket_jack
    movss xmm1, [rel cost_bracket_tap_weight]
    test dword [rsp + 12], 12
    jz .add_right_bracket_tap
    movss xmm2, [rel cost_one]
    mov rdx, [rsp + 216]
    divss xmm2, [rdx]
    mulss xmm1, xmm2
.add_right_bracket_tap:
    addss xmm0, xmm1

.cost_bracket_jack:
    cmp byte [rsp + 72], 0
    je .cost_doublestep
    cmp dword [rsp + 8], 0
    jne .cost_doublestep
    test byte [rsp], 4
    jnz .cost_doublestep
    movzx eax, byte [rsp]
    mov ecx, eax
    shr ecx, 1
    xor ecx, eax
    test ecx, 1
    jz .cost_doublestep
    test al, 8
    jz .right_bracket_jack
    mov ecx, [rsp + 4]
    and ecx, 3
    cmp ecx, 3
    jne .right_bracket_jack
    addss xmm0, [rel cost_bracket_jack_weight]
.right_bracket_jack:
    test byte [rsp], 16
    jz .cost_doublestep
    mov ecx, [rsp + 4]
    and ecx, 12
    cmp ecx, 12
    jne .cost_doublestep
    addss xmm0, [rel cost_bracket_jack_weight]

.cost_doublestep:
    movzx eax, byte [rsp]
    mov ecx, eax
    shr ecx, 1
    xor ecx, eax
    test ecx, 1
    jz .cost_slow_bracket
    test al, 4
    jnz .cost_slow_bracket
    cmp dword [rsp + 8], 0
    jne .cost_slow_bracket
    cmp dword [rsp + 208], 0
    jne .cost_slow_bracket
    test al, 1
    jz .check_right_doublestep_fast
    test al, 8
    jnz .check_right_doublestep_fast
    test al, 32
    jnz .add_doublestep
.check_right_doublestep_fast:
    test al, 2
    jz .cost_slow_bracket
    test al, 16
    jnz .cost_slow_bracket
    test al, 64
    jz .cost_slow_bracket
.add_doublestep:
    addss xmm0, [rel cost_doublestep_weight]

.cost_slow_bracket:
    cmp dword [rsp + 168], 2
    jb .cost_twisted_foot
    movzx eax, byte [rsp]
    mov ecx, eax
    shr ecx, 1
    xor ecx, eax
    test ecx, 1
    jz .cost_twisted_foot
    mov rdx, [rsp + 224]
    addss xmm0, [rdx]

.cost_twisted_foot:
    cmp byte [rsp + 72], 0
    je .cost_facing
    mov r9, [rsp + 120]
    movsx eax, byte [r9 + 1]
    mov [rsp + 16], eax
    movsx eax, byte [r9 + 2]
    mov [rsp + 20], eax
    movsx eax, byte [r9 + 3]
    mov [rsp + 24], eax
    movsx eax, byte [r9 + 4]
    mov [rsp + 28], eax
    ASSP_PAIR_IDX_EAX [rsp + 16], [rsp + 20]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx r10d, byte [r11 + rax]
    mov [rsp + 32], r10d
    ASSP_PAIR_IDX_EAX [rsp + 24], [rsp + 28]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx r10d, byte [r11 + rax]
    cmp r10d, [rsp + 32]
    jl .cost_facing

    mov eax, [rsp + 24]
    test eax, eax
    js .check_left_backward
    cmp eax, 4
    jae .check_left_backward
    mov ecx, [rsp + 28]
    test ecx, ecx
    js .check_left_backward
    cmp ecx, 4
    jae .check_left_backward
    lea r11, [rel dance_single_col_y2]
    movzx eax, byte [r11 + rax]
    movzx ecx, byte [r11 + rcx]
    cmp ecx, eax
    jl .add_twisted_foot

.check_left_backward:
    mov eax, [rsp + 16]
    test eax, eax
    js .cost_facing
    cmp eax, 4
    jae .cost_facing
    mov ecx, [rsp + 20]
    test ecx, ecx
    js .cost_facing
    cmp ecx, 4
    jae .cost_facing
    lea r11, [rel dance_single_col_y2]
    movzx eax, byte [r11 + rax]
    movzx ecx, byte [r11 + rcx]
    cmp ecx, eax
    jge .cost_facing

.add_twisted_foot:
    addss xmm0, [rel cost_twisted_foot_weight]

.cost_facing:
    mov rdx, [rsp + 104]
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    mov [rsp + 16], eax
    movsx ecx, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    test ecx, ecx
    jns .store_result_left_toe_fast
    mov ecx, eax
.store_result_left_toe_fast:
    mov [rsp + 20], ecx
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    mov [rsp + 24], eax
    movsx ecx, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    test ecx, ecx
    jns .store_result_right_toe_fast
    mov ecx, eax
.store_result_right_toe_fast:
    mov [rsp + 28], ecx

    xorps xmm1, xmm1
    ASSP_PAIR_IDX_EAX [rsp + 16], [rsp + 24]
    lea r11, [rel dance_single_facing_x4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_EAX [rsp + 20], [rsp + 28]
    lea r11, [rel dance_single_facing_x4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_EAX [rsp + 16], [rsp + 20]
    lea r11, [rel dance_single_facing_y4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_EAX [rsp + 24], [rsp + 28]
    lea r11, [rel dance_single_facing_y4]
    addss xmm1, [r11 + rax * 4]
    mulss xmm1, [rel cost_facing_weight]
    addss xmm0, xmm1

.cost_spin:
    ASSP_PAIR_IDX_EAX [rsp + 16], [rsp + 20]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 48], ecx
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 52], ecx
    ASSP_PAIR_IDX_EAX [rsp + 24], [rsp + 28]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 56], ecx
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 60], ecx

    mov rcx, [rsp + 96]
    movsx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    mov [rsp + 32], eax
    movsx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    mov [rsp + 36], eax
    movsx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    mov [rsp + 40], eax
    movsx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    mov [rsp + 44], eax

    ASSP_PAIR_IDX_EAX [rsp + 32], [rsp + 36]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 32], ecx
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 36], ecx
    ASSP_PAIR_IDX_EAX [rsp + 40], [rsp + 44]
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 40], ecx
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 44], ecx

    mov eax, [rsp + 56]
    cmp eax, [rsp + 48]
    jge .cost_footswitch
    mov eax, [rsp + 40]
    cmp eax, [rsp + 32]
    jge .cost_footswitch
    mov eax, [rsp + 60]
    cmp eax, [rsp + 52]
    jl .spin_right_lower_fast
    jg .spin_right_higher_fast
    jmp .cost_footswitch
.spin_right_lower_fast:
    mov eax, [rsp + 44]
    cmp eax, [rsp + 36]
    jg .add_spin
    jmp .cost_footswitch
.spin_right_higher_fast:
    mov eax, [rsp + 44]
    cmp eax, [rsp + 36]
    jge .cost_footswitch
.add_spin:
    addss xmm0, [rel cost_spin_weight]

.cost_footswitch:
    cmp dword [rsp + 192], 0
    jne .cost_sideswitch
    mov rdx, [rsp + 224]
    movss xmm1, [rdx + 4]
    xorps xmm2, xmm2
    comiss xmm1, xmm2
    jbe .cost_sideswitch
    mov r10d, [rsp + 176]
    and r10d, 0fh
    xor r11d, r11d

.footswitch_loop_fast:
    cmp r11d, 4
    jae .cost_sideswitch
    bt r10d, r11d
    jnc .next_footswitch_fast
    mov r8, [rsp + 112]
    movzx eax, byte [r8 + r11]
    test eax, eax
    jz .next_footswitch_fast
    cmp eax, 4
    ja .next_footswitch_fast
    mov rcx, [rsp + 96]
    movzx edx, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r11]
    test edx, edx
    jz .next_footswitch_fast
    cmp edx, eax
    je .next_footswitch_fast
    mov ecx, eax
    test al, 1
    jz .footswitch_even_fast
    inc ecx
    jmp .check_footswitch_pair_fast
.footswitch_even_fast:
    dec ecx
.check_footswitch_pair_fast:
    cmp edx, ecx
    je .next_footswitch_fast
    addss xmm0, xmm1
    jmp .cost_sideswitch

.next_footswitch_fast:
    inc r11d
    jmp .footswitch_loop_fast

.cost_sideswitch:
    mov r10d, [rsp + 200]
    and r10d, 0fh
    jz .cost_missed_footswitch
    xor r11d, r11d

.sideswitch_loop_fast:
    cmp r11d, 4
    jae .cost_missed_footswitch
    bt r10d, r11d
    jnc .next_sideswitch_fast
    mov r8, [rsp + 112]
    movzx eax, byte [r8 + r11]
    test eax, eax
    jz .next_sideswitch_fast
    mov rcx, [rsp + 96]
    movzx edx, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r11]
    test edx, edx
    jz .next_sideswitch_fast
    cmp edx, eax
    je .next_sideswitch_fast
    mov ecx, edx
    dec ecx
    mov eax, [rsp + 4]
    bt eax, ecx
    jc .next_sideswitch_fast
    addss xmm0, [rel cost_sideswitch_weight]

.next_sideswitch_fast:
    inc r11d
    jmp .sideswitch_loop_fast

.cost_missed_footswitch:
    cmp dword [rsp + 192], 0
    je .cost_jack
    test byte [rsp], 24
    jz .cost_jack
    addss xmm0, [rel cost_missed_footswitch_weight]

.cost_jack:
    movzx eax, byte [rsp]
    mov ecx, eax
    shr ecx, 1
    xor ecx, eax
    test ecx, 1
    jz .cost_big_movement
    test al, 24
    jz .cost_big_movement
    mov rdx, [rsp + 224]
    addss xmm0, [rdx + 8]

.cost_big_movement:
    mov r10d, [rsp + 4]
    and r10d, 0fh
    xor r11d, r11d

.big_movement_loop_fast:
    cmp r11d, 4
    jae .fast_done
    bt r10d, r11d
    jnc .next_big_movement_fast
    mov rcx, [rsp + 96]
    lea eax, [r11d + 1]
    movsx r8d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax]
    test r8d, r8d
    js .next_big_movement_fast
    cmp r8d, 4
    jae .next_big_movement_fast
    mov r9, [rsp + 120]
    movsx eax, byte [r9 + r11 + 1]
    test eax, eax
    js .next_big_movement_fast
    cmp eax, 4
    jae .next_big_movement_fast
    mov ecx, r8d
    shl ecx, 2
    add ecx, eax
    lea rdx, [rel dance_single_distances4]
    movss xmm2, [rdx + rcx * 4]
    mulss xmm2, [rel cost_distance_weight]
    mov rdx, [rsp + 216]
    divss xmm2, [rdx]

    mov eax, r11d
    xor eax, 1
    inc eax
    movsx eax, byte [r9 + rax]
    test eax, eax
    js .add_big_movement_fast
    cmp eax, r8d
    je .next_big_movement_fast
    mulss xmm2, [rel cost_big_movement_other_part_factor]

.add_big_movement_fast:
    addss xmm0, xmm2

.next_big_movement_fast:
    inc r11d
    jmp .big_movement_loop_fast

.fast_done:
    add rsp, 128
    ret

; Internal hot scorer for rows with one tap, no holds, no mines, no sides.
; rcx = initial, rdx = result, r8 = placement[4], r9d = active column,
; stack arg 5 = prev row has live hold, stack arg 6 = elapsed seconds f32 ptr,
; stack arg 7 = row-local big movement cost table.
step_parity_action_cost_single_tap_clean_4:
    sub rsp, 96
    mov [rsp + 64], rcx
    mov [rsp + 72], rdx

    movzx r10d, byte [r8 + r9]
    xorps xmm0, xmm0

    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_MOVED_MASK]
    movzx r11d, byte [rcx + ASSP_STEP_PARITY_STATE4_HOLDING_MASK]
    not r11d
    and eax, r11d
    xor r11d, r11d
    test al, 3
    jz .single_flag_right_not_holding
    or r11b, 32
.single_flag_right_not_holding:
    test al, 12
    jz .single_flag_current_moved
    or r11b, 64

.single_flag_current_moved:
    cmp r10d, 3
    jae .single_moved_right
    or r11b, 1
    jmp .single_check_jump
.single_moved_right:
    or r11b, 2

.single_check_jump:
    mov eax, r11d
    and eax, 96
    cmp eax, 96
    jne .single_check_jack
    or r11b, 4

.single_check_jack:
    test r11b, 4
    jnz .single_store_flags
    mov rdx, [rsp + 64]
    movzx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_COMBINED + r9]
    cmp eax, r10d
    jne .single_store_flags
    cmp r10d, 3
    jae .single_check_right_jack
    test r11b, 32
    jz .single_store_flags
    or r11b, 8
    jmp .single_store_flags
.single_check_right_jack:
    test r11b, 64
    jz .single_store_flags
    or r11b, 16

.single_store_flags:
    mov [rsp], r11b

.single_doublestep:
    test r11b, 4
    jnz .single_facing
    cmp dword [rsp + 136], 0
    jne .single_facing
    cmp r10d, 3
    jae .single_right_doublestep
    test r11b, 8
    jnz .single_facing
    test r11b, 32
    jz .single_facing
    addss xmm0, [rel cost_doublestep_weight]
    jmp .single_facing
.single_right_doublestep:
    test r11b, 16
    jnz .single_facing
    test r11b, 64
    jz .single_facing
    addss xmm0, [rel cost_doublestep_weight]

.single_facing:
    mov rdx, [rsp + 72]
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    movsx ecx, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    test ecx, ecx
    cmovs ecx, eax
    mov r11d, 4
    cmp eax, r11d
    cmovae eax, r11d
    cmp ecx, r11d
    cmovae ecx, r11d
    mov [rsp + 24], eax
    mov [rsp + 28], ecx

    movsx r8d, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    movsx eax, byte [rdx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    test eax, eax
    cmovs eax, r8d
    cmp r8d, r11d
    cmovae r8d, r11d
    cmp eax, r11d
    cmovae eax, r11d
    mov [rsp + 32], r8d
    mov [rsp + 36], eax

    xorps xmm1, xmm1
    ASSP_PAIR_IDX_NORM_EAX [rsp + 24], [rsp + 32]
    lea r11, [rel dance_single_facing_x4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_NORM_EAX [rsp + 28], [rsp + 36]
    lea r11, [rel dance_single_facing_x4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_NORM_EAX [rsp + 24], [rsp + 28]
    lea r11, [rel dance_single_facing_y4]
    addss xmm1, [r11 + rax * 4]
    ASSP_PAIR_IDX_NORM_EAX [rsp + 32], [rsp + 36]
    lea r11, [rel dance_single_facing_y4]
    addss xmm1, [r11 + rax * 4]
    mulss xmm1, [rel cost_facing_weight]
    addss xmm0, xmm1

.single_spin:
    ASSP_PAIR_IDX_NORM_EAX [rsp + 24], [rsp + 28]
    mov [rsp + 56], eax
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 40], ecx
    ASSP_PAIR_IDX_NORM_EAX [rsp + 32], [rsp + 36]
    mov [rsp + 60], eax
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 48], ecx
    cmp ecx, [rsp + 40]
    jge .single_footswitch

    mov eax, [rsp + 56]
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 44], ecx
    mov eax, [rsp + 60]
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 52], ecx

    mov rcx, [rsp + 64]
    movsx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 1]
    movsx edx, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 2]
    movsx r8d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 3]
    movsx ecx, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4]
    mov r11d, 4
    cmp eax, r11d
    cmovae eax, r11d
    cmp edx, r11d
    cmovae edx, r11d
    cmp r8d, r11d
    cmovae r8d, r11d
    cmp ecx, r11d
    cmovae ecx, r11d
    mov [rsp + 24], eax
    mov [rsp + 28], edx
    mov [rsp + 32], r8d
    mov [rsp + 36], ecx

    ASSP_PAIR_IDX_NORM_EAX [rsp + 24], [rsp + 28]
    mov [rsp + 56], eax
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 24], ecx
    ASSP_PAIR_IDX_NORM_EAX [rsp + 32], [rsp + 36]
    mov [rsp + 60], eax
    lea r11, [rel dance_single_pair_avg_x2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 32], ecx
    cmp ecx, [rsp + 24]
    jge .single_footswitch

    mov eax, [rsp + 56]
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 28], ecx
    mov eax, [rsp + 60]
    lea r11, [rel dance_single_pair_avg_y2]
    movzx ecx, byte [r11 + rax]
    mov [rsp + 36], ecx

    mov eax, [rsp + 52]
    cmp eax, [rsp + 44]
    jl .single_spin_right_lower
    jg .single_spin_right_higher
    jmp .single_footswitch
.single_spin_right_lower:
    mov eax, [rsp + 36]
    cmp eax, [rsp + 28]
    jg .single_add_spin
    jmp .single_footswitch
.single_spin_right_higher:
    mov eax, [rsp + 36]
    cmp eax, [rsp + 28]
    jge .single_footswitch
.single_add_spin:
    addss xmm0, [rel cost_spin_weight]

.single_footswitch:
    mov rdx, [rsp + 144]
    movss xmm1, [rdx]
    comiss xmm1, [rel cost_slow_footswitch_threshold]
    jb .single_jack
    comiss xmm1, [rel cost_slow_footswitch_ignore]
    jae .single_jack
    mov rcx, [rsp + 64]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r9]
    test eax, eax
    jz .single_jack
    cmp eax, r10d
    je .single_jack
    mov ecx, r10d
    test cl, 1
    jz .single_other_part_even
    inc ecx
    jmp .single_check_other_part
.single_other_part_even:
    dec ecx
.single_check_other_part:
    cmp eax, ecx
    je .single_jack
    subss xmm1, [rel cost_slow_footswitch_threshold]
    movss xmm2, xmm1
    mov rdx, [rsp + 144]
    divss xmm2, [rdx]
    mulss xmm2, [rel cost_footswitch_weight]
    addss xmm0, xmm2

.single_jack:
    movzx eax, byte [rsp]
    test al, 24
    jz .single_big_movement
    mov rdx, [rsp + 152]
    addss xmm0, [rdx]

.single_big_movement:
    mov rcx, [rsp + 64]
    mov eax, r10d
    movsx r8d, byte [rcx + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax]
    test r8d, r8d
    js .single_done
    cmp r8d, 4
    jae .single_done
    mov rdx, [rsp + 152]
    movss xmm2, [rdx + r8 * 4 + 4]
    addss xmm0, xmm2

.single_done:
    add rsp, 96
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

; rcx = initial state8, rdx = result state8, r8 = placement[8], r9 = hit[5],
; stack arg 5 = note count, stack arg 6 = active mask,
; stack arg 7 = hold mask, stack arg 8 = mine|fake mine mask,
; stack arg 9 = side mask, stack arg 10 = prev row has live hold,
; stack arg 11 = elapsed seconds f32 ptr,
; stack arg 12 = out assp_step_parity_action_costs4.
; eax = 1 on success, 0 on invalid pointers.
assp_step_parity_action_cost_8:
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
    call assp_step_parity_action_flags_8
    test eax, eax
    jz .fail

    mov eax, [rsp + 360]
    and eax, 0ffh
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
    call assp_step_parity_basic_action_costs_8
    test eax, eax
    jz .fail

    lea rcx, [rsp + 80]
    mov edx, [rsp + 352]
    mov r8, rsi
    lea r9, [rsp + 120]
    call assp_step_parity_elapsed_action_costs_8
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
    call assp_step_parity_switch_action_costs_8
    test eax, eax
    jz .fail

    lea rax, [rsp + 152]
    mov [rsp + 32], rax
    mov rcx, r12
    mov rdx, r15
    mov r8d, [rsp + 368]
    mov r9, rsi
    call assp_step_parity_bracket_tap_action_costs_8
    test eax, eax
    jz .fail

    mov [rsp + 32], rsi
    lea rax, [rsp + 168]
    mov [rsp + 40], rax
    mov rcx, r12
    mov rdx, r13
    mov r8, r15
    mov r9d, [rsp + 368]
    call assp_step_parity_distance_action_costs_8
    test eax, eax
    jz .fail

    mov rcx, r12
    mov rdx, r13
    mov r8, r15
    lea r9, [rsp + 184]
    call assp_step_parity_orientation_action_costs_8
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
    and eax, 0ffh
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

; rcx = initial state8 array, rdx = initial cost array,
; r8 = initial state count, r9 = assp_step_parity_row_cost_ctx4,
; stack arg 5 = out predecessor indexes,
; stack arg 6 = out placements[8 * cap],
; stack arg 7 = out states[16 * cap],
; stack arg 8 = out hits[5 * cap],
; stack arg 9 = out keys[4 * cap],
; stack arg 10 = out costs[cap],
; stack arg 11 = output capacity. Capacity must hold row-key candidates.
; rax = unique best row-state key count, or ASSP_NOT_FOUND on invalid input.
assp_step_parity_row_best_candidates_8:
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
    jz .fail_no_stack
    test r13, r13
    jz .fail_no_stack
    test r15, r15
    jz .fail_no_stack
    test rbx, rbx
    jz .fail_no_stack
    test rsi, rsi
    jz .fail_no_stack
    test rdi, rdi
    jz .fail_no_stack
    test rbp, rbp
    jz .fail_no_stack
    test r10, r10
    jz .fail_no_stack
    test r11, r11
    jz .fail_no_stack
    test rax, rax
    jz .fail_no_stack
    test qword [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS], -1
    jz .fail_no_stack

    sub rsp, 1216
    mov [rsp + 104], r10
    mov [rsp + 112], r11
    mov [rsp + 120], rax
    mov qword [rsp + 136], 0
    mov qword [rsp + 144], 0

.state_loop:
    mov rax, [rsp + 144]
    cmp rax, r14
    jae .success

    mov rcx, rax
    shl rcx, 4
    lea rcx, [r12 + rcx]
    mov edx, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    mov r8d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    lea r9, [rsp + 256]
    lea rax, [rsp + 448]
    mov [rsp + 32], rax
    lea rax, [rsp + 832]
    mov [rsp + 40], rax
    lea rax, [rsp + 960]
    mov [rsp + 48], rax
    mov qword [rsp + 56], 24
    call assp_step_parity_row_transitions_8
    cmp rax, ASSP_NOT_FOUND
    jne .transitions_ready
    jmp .fail

.transitions_ready:
    test rax, rax
    jnz .have_transitions
    mov ecx, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    and ecx, 0ffh
    lea rdx, [rsp + 256]
    mov r8d, 24
    call assp_step_parity_permutations_8
    test rax, rax
    jnz .fallback_perms_ready
    mov qword [rsp + 256], 0
    mov eax, 1

.fallback_perms_ready:
    mov [rsp + 128], rax
    mov qword [rsp + 248], 0

.fallback_build_loop:
    mov rax, [rsp + 248]
    cmp rax, [rsp + 128]
    jae .fallback_done

    mov rcx, [rsp + 144]
    shl rcx, 4
    lea rcx, [r12 + rcx]
    mov rdx, [rsp + 248]
    lea rdx, [rsp + 256 + rdx * 8]
    mov r8d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    or r8d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    and r8d, 0ffh
    mov r9d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    and r9d, 0ffh
    test r9d, r9d
    jnz .fallback_build_holds

    mov rax, [rsp + 248]
    shl rax, 4
    lea r9, [rsp + 448 + rax]
    mov rax, [rsp + 248]
    lea r10, [rax + rax * 4]
    lea r10, [rsp + 832 + r10]
    mov [rsp + 32], r10
    mov rax, [rsp + 248]
    lea r10, [rsp + 960 + rax * 4]
    mov [rsp + 40], r10
    call assp_step_parity_result_state_no_holds_8
    test eax, eax
    jz .fail
    jmp .fallback_next

.fallback_build_holds:
    mov rax, [rsp + 248]
    shl rax, 4
    lea r10, [rsp + 448 + rax]
    mov [rsp + 32], r10
    mov rax, [rsp + 248]
    lea r10, [rax + rax * 4]
    lea r10, [rsp + 832 + r10]
    mov [rsp + 40], r10
    mov rax, [rsp + 248]
    lea r10, [rsp + 960 + rax * 4]
    mov [rsp + 48], r10
    call assp_step_parity_result_state_holds_8
    test eax, eax
    jz .fail

.fallback_next:
    inc qword [rsp + 248]
    jmp .fallback_build_loop

.fallback_done:
    mov rax, [rsp + 128]

.have_transitions:
    mov [rsp + 128], rax
    mov qword [rsp + 152], 0

.candidate_loop:
    mov rax, [rsp + 152]
    cmp rax, [rsp + 128]
    jae .next_state

    mov rax, [rsp + 144]
    mov [rsp + 232], eax
    mov rcx, rax
    shl rcx, 4
    lea rcx, [r12 + rcx]

    mov rax, [rsp + 152]
    mov rdx, rax
    shl rdx, 4
    lea rdx, [rsp + 448 + rdx]
    lea r8, [rsp + 256 + rax * 8]
    lea r9, [rax + rax * 4]
    lea r9, [rsp + 832 + r9]

    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_COUNT]
    mov [rsp + 32], eax
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    or eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    and eax, 0ffh
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
    lea rax, [rsp + 160]
    mov [rsp + 88], rax
    call assp_step_parity_action_cost_8
    test eax, eax
    jnz .action_cost_ready
    jmp .fail

.action_cost_ready:

    mov eax, [rsp + 232]
    movss xmm0, [r13 + rax * 4]
    addss xmm0, [rsp + 160 + ASSP_STEP_PARITY_ACTION_COSTS4_TOTAL]
    movss [rsp + 224], xmm0

    mov rax, [rsp + 152]
    mov eax, [rsp + 960 + rax * 4]
    mov [rsp + 236], eax

    xor r11d, r11d
.search_loop:
    cmp r11, [rsp + 136]
    jae .append_candidate
    mov r10, [rsp + 104]
    mov eax, [r10 + r11 * 4]
    cmp eax, [rsp + 236]
    je .found_key
    inc r11
    jmp .search_loop

.found_key:
    mov r10, [rsp + 112]
    movss xmm0, [r10 + r11 * 4]
    movss xmm1, [rsp + 224]
    comiss xmm0, xmm1
    jbe .next_candidate
    mov byte [rsp + 240], 0
    jmp .store_candidate

.append_candidate:
    mov r11, [rsp + 136]
    cmp r11, [rsp + 120]
    jb .append_candidate_ready
    jmp .fail

.append_candidate_ready:
    mov byte [rsp + 240], 1

.store_candidate:
    mov eax, [rsp + 232]
    mov [rbx + r11 * 4], eax

    mov rax, [rsp + 152]
    mov r10, [rsp + 256 + rax * 8]
    mov [rsi + r11 * 8], r10

    mov rax, [rsp + 152]
    shl rax, 4
    movdqu xmm2, [rsp + 448 + rax]
    mov r10, r11
    shl r10, 4
    movdqu [rdi + r10], xmm2

    mov rax, [rsp + 152]
    lea rax, [rax + rax * 4]
    mov edx, [rsp + 832 + rax]
    mov r10, r11
    lea r10, [r10 + r10 * 4]
    mov [rbp + r10], edx
    mov dl, [rsp + 832 + rax + 4]
    mov [rbp + r10 + 4], dl

    mov r10, [rsp + 104]
    mov eax, [rsp + 236]
    mov [r10 + r11 * 4], eax

    mov r10, [rsp + 112]
    movss xmm0, [rsp + 224]
    movss [r10 + r11 * 4], xmm0

    cmp byte [rsp + 240], 0
    je .next_candidate
    inc qword [rsp + 136]

.next_candidate:
    inc qword [rsp + 152]
    jmp .candidate_loop

.next_state:
    inc qword [rsp + 144]
    jmp .state_loop

.success:
    mov rax, [rsp + 136]
    add rsp, 1216
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.fail:
    add rsp, 1216
.fail_no_stack:
    mov rax, ASSP_NOT_FOUND
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.zero_success:
    xor eax, eax
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

%macro ASSP_INLINE_SINGLE_COL_RESOLVE 1
    movzx eax, byte [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + %1]
    test al, al
    jnz %%have_foot
    movzx eax, byte [r10 + ASSP_STEP_PARITY_STATE4_COMBINED + %1]
    cmp al, 1
    je %%prev_left_heel
    cmp al, 3
    je %%prev_right_heel
    cmp al, 2
    je %%prev_left_toe
    cmp al, 4
    je %%prev_right_toe
    jmp %%done

%%prev_left_heel:
    test dl, 1
    jnz %%done
    jmp %%store_foot

%%prev_right_heel:
    test dl, 4
    jnz %%done
    jmp %%store_foot

%%prev_left_toe:
    test dl, 3
    jnz %%done
    mov eax, 2
    jmp %%store_foot

%%prev_right_toe:
    test dl, 12
    jnz %%done
    mov eax, 4

%%store_foot:
    mov [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + %1], al

%%have_foot:
    mov r8d, eax
%if %1 != 0
    shl r8d, %1 * 3
%endif
    or r11d, r8d
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax], %1
    or ecx, 1 << %1

%%done:
%endmacro

%macro ASSP_INLINE_SINGLE_COL_STATE 0
    movzx eax, byte [rdx + r8]
    mov dword [r9 + ASSP_STEP_PARITY_STATE4_COMBINED], 0
    mov dword [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET], 0ffffffffh
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4], 0ffh

    lea rdx, [rsp + 496]
    mov dword [rdx], 0ffffffffh
    mov byte [rdx + 4], 0ffh

    mov [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + r8], al
    mov byte [rdx + rax], r8b
    lea rdx, [rel step_parity_foot_masks]
    movzx edx, byte [rdx + rax]

    xor r11d, r11d
    xor ecx, ecx
    ASSP_INLINE_SINGLE_COL_RESOLVE 0
    ASSP_INLINE_SINGLE_COL_RESOLVE 1
    ASSP_INLINE_SINGLE_COL_RESOLVE 2
    ASSP_INLINE_SINGLE_COL_RESOLVE 3

    mov [r9 + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], cl
    mov [r9 + ASSP_STEP_PARITY_STATE4_MOVED_MASK], dl
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    mov eax, edx
    shl eax, 24
    or eax, r11d
    mov [rsp + 616], eax
%endmacro

%macro ASSP_INLINE_NO_HOLD_ACTIVE 1
    test r8d, 1 << %1
    jz %%done
    movzx eax, byte [rdx + %1]
    test al, al
    jz %%done
    cmp al, 4
    ja %%done
    mov [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + %1], al
    mov byte [rsp + 496 + rax], %1
    lea ecx, [rax - 1]
    mov eax, 1
    shl eax, cl
    or r11d, eax
%%done:
%endmacro

%macro ASSP_INLINE_NO_HOLD_RESOLVE 1
    movzx eax, byte [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + %1]
    test al, al
    jnz %%have_foot
    movzx eax, byte [r10 + ASSP_STEP_PARITY_STATE4_COMBINED + %1]
    cmp al, 1
    je %%prev_left_heel
    cmp al, 3
    je %%prev_right_heel
    cmp al, 2
    je %%prev_left_toe
    cmp al, 4
    je %%prev_right_toe
    jmp %%done

%%prev_left_heel:
    test r11b, 1
    jnz %%done
    jmp %%store_foot

%%prev_right_heel:
    test r11b, 4
    jnz %%done
    jmp %%store_foot

%%prev_left_toe:
    test r11b, 3
    jnz %%done
    mov eax, 2
    jmp %%store_foot

%%prev_right_toe:
    test r11b, 12
    jnz %%done
    mov eax, 4

%%store_foot:
    mov [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + %1], al

%%have_foot:
    mov edx, eax
%if %1 != 0
    shl edx, %1 * 3
%endif
    or r8d, edx
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax], %1
    or ecx, 1 << %1

%%done:
%endmacro

%macro ASSP_INLINE_NO_HOLD_STATE 0
    mov dword [r9 + ASSP_STEP_PARITY_STATE4_COMBINED], 0
    mov dword [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET], 0ffffffffh
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4], 0ffh

    mov dword [rsp + 496], 0ffffffffh
    mov byte [rsp + 500], 0ffh

    xor r11d, r11d
    ASSP_INLINE_NO_HOLD_ACTIVE 0
    ASSP_INLINE_NO_HOLD_ACTIVE 1
    ASSP_INLINE_NO_HOLD_ACTIVE 2
    ASSP_INLINE_NO_HOLD_ACTIVE 3

    xor r8d, r8d
    xor ecx, ecx
    ASSP_INLINE_NO_HOLD_RESOLVE 0
    ASSP_INLINE_NO_HOLD_RESOLVE 1
    ASSP_INLINE_NO_HOLD_RESOLVE 2
    ASSP_INLINE_NO_HOLD_RESOLVE 3

    mov [r9 + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], cl
    mov [r9 + ASSP_STEP_PARITY_STATE4_MOVED_MASK], r11b
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    mov eax, r11d
    shl eax, 24
    or eax, r8d
    mov [rsp + 616], eax
%endmacro

; rcx = initial states, rdx = initial costs, r8 = initial state count,
; r9 = assp_step_parity_row_cost_ctx4,
; stack arg 5 = out predecessor indexes,
; stack arg 6 = out placements[4 * cap],
; stack arg 7 = out states[12 * cap],
; stack arg 8 = out hits[5 * cap],
; stack arg 9 = out keys[4 * cap],
; stack arg 10 = out costs[cap],
; stack arg 11 = output capacity. Capacity must hold the unique row states.
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
    test rax, rax
    jz .fail

    sub rsp, 1216
    mov qword [rsp + 784], 0
    mov qword [rsp + 792], 0

    mov ecx, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    or ecx, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    and ecx, 0fh
    lea r10, [rel step_parity_perm4_counts]
    movzx eax, byte [r10 + rcx]
    mov [rsp + 928], rax
    lea r10, [rel step_parity_perm4_offsets]
    movzx r10d, byte [r10 + rcx]
    lea r11, [rel step_parity_perm4_values]
    lea r11, [r11 + r10 * 4]
    mov [rsp + 952], r11

    mov rax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS]
    mov dword [rsp + 832], 0
    movss xmm0, [rax]
    comiss xmm0, [rel cost_slow_bracket_threshold]
    jbe .row_slow_bracket_ready
    subss xmm0, [rel cost_slow_bracket_threshold]
    mulss xmm0, [rel cost_slow_bracket_weight]
    movss [rsp + 832], xmm0
.row_slow_bracket_ready:
    mov dword [rsp + 836], 0
    movss xmm1, [rax]
    comiss xmm1, [rel cost_slow_footswitch_threshold]
    jb .row_footswitch_ready
    comiss xmm1, [rel cost_slow_footswitch_ignore]
    jae .row_footswitch_ready
    movss xmm2, xmm1
    subss xmm2, [rel cost_slow_footswitch_threshold]
    movss xmm3, [rel cost_slow_footswitch_threshold]
    addss xmm3, xmm2
    divss xmm2, xmm3
    mulss xmm2, [rel cost_footswitch_weight]
    movss [rsp + 836], xmm2
.row_footswitch_ready:
    mov dword [rsp + 840], 0
    movss xmm0, [rax]
    comiss xmm0, [rel cost_jack_threshold]
    jae .row_jack_cost_ready
    movss xmm1, [rel cost_jack_threshold]
    subss xmm1, xmm0
    xorps xmm2, xmm2
    comiss xmm1, xmm2
    jbe .row_jack_cost_ready
    movss xmm0, [rel cost_one]
    divss xmm0, xmm1
    movss xmm1, [rel cost_one]
    divss xmm1, [rel cost_jack_threshold]
    subss xmm0, xmm1
    mulss xmm0, [rel cost_jack_weight]
    movss [rsp + 840], xmm0
.row_jack_cost_ready:
    cmp qword [rsp + 1336], 128
    ja .hash_ready
    pxor xmm0, xmm0
    movdqu [rsp + 960], xmm0
    movdqu [rsp + 976], xmm0
    movdqu [rsp + 992], xmm0
    movdqu [rsp + 1008], xmm0
    movdqu [rsp + 1024], xmm0
    movdqu [rsp + 1040], xmm0
    movdqu [rsp + 1056], xmm0
    movdqu [rsp + 1072], xmm0
%ifdef ASSP_STANDALONE_EXE
    inc dword [rel step_parity_fast_key_generation]
    cmp dword [rel step_parity_fast_key_generation], 65536
    jb .fast_key_generation_ready
    mov dword [rel step_parity_fast_key_generation], 1
    lea r10, [rel step_parity_fast_key_entries]
    xor eax, eax
    mov ecx, 65536
.clear_fast_key_entries:
    mov [r10], eax
    add r10, 4
    dec ecx
    jnz .clear_fast_key_entries
.fast_key_generation_ready:
%endif
.hash_ready:
    mov dword [rsp + 944], -1
    mov byte [rsp + 900], 0
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    test eax, eax
    jnz .state_loop_fast
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    and eax, 0fh
    test eax, eax
    jz .state_loop_fast
    mov ecx, eax
    dec ecx
    test eax, ecx
    jnz .state_loop_fast
    bsf eax, eax
    mov [rsp + 944], eax
    cmp dword [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_MINE_MASK], 0
    jne .single_clean_flag_ready
    cmp dword [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_SIDE_MASK], 0
    jne .single_clean_flag_ready
    mov byte [rsp + 900], 1
.single_clean_flag_ready:
    mov rax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS]
    movss xmm0, [rsp + 840]
    movss [rsp + 908], xmm0
    mov ecx, [rsp + 944]
    lea r10, [rel dance_single_distances4]
    movss xmm0, [r10 + rcx * 4]
    mulss xmm0, [rel cost_distance_weight]
    divss xmm0, [rax]
    movss [rsp + 912], xmm0
    movss xmm0, [r10 + rcx * 4 + 16]
    mulss xmm0, [rel cost_distance_weight]
    divss xmm0, [rax]
    movss [rsp + 916], xmm0
    movss xmm0, [r10 + rcx * 4 + 32]
    mulss xmm0, [rel cost_distance_weight]
    divss xmm0, [rax]
    movss [rsp + 920], xmm0
    movss xmm0, [r10 + rcx * 4 + 48]
    mulss xmm0, [rel cost_distance_weight]
    divss xmm0, [rax]
    movss [rsp + 924], xmm0
.state_loop_fast:
    mov rax, [rsp + 792]
    cmp rax, r14
    jae .success

    mov qword [rsp + 800], 0
    mov rax, [rsp + 792]
    lea rcx, [rax + rax * 2]
    lea rcx, [r12 + rcx * 4]
    mov [rsp + 880], rcx
    movss xmm0, [r13 + rax * 4]
    movss [rsp + 896], xmm0
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK]
    or eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    mov [rsp + 904], eax

.perm_loop_fast:
    mov rax, [rsp + 800]
    cmp rax, [rsp + 928]
    jae .next_state_fast

    mov rdx, [rsp + 952]
    lea rdx, [rdx + rax * 4]
    mov [rsp + 936], rdx
    mov rcx, [rsp + 880]
    mov r8d, [rsp + 904]
    mov r10d, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK]
    ASSP_PROFILE_TSC_BEGIN
    test r10d, r10d
    jnz .transition_with_holds_fast
    cmp dword [rsp + 944], -1
    jne .transition_single_no_hold_fast

    lea r9, [rsp + 208]
    mov r10, rcx
    mov rdx, [rsp + 936]
    ASSP_INLINE_NO_HOLD_STATE
    jmp .transition_done_fast

.transition_single_no_hold_fast:
    mov r10, rcx
    mov rdx, [rsp + 936]
    mov r8d, [rsp + 944]
    lea r9, [rsp + 208]
    ASSP_INLINE_SINGLE_COL_STATE
    jmp .transition_done_fast

.transition_with_holds_fast:
    mov r9d, r10d
    lea r10, [rsp + 208]
    mov [rsp + 32], r10
    lea r10, [rsp + 496]
    mov [rsp + 40], r10
    lea r10, [rsp + 616]
    mov [rsp + 48], r10
    mov rdx, [rsp + 936]
    call step_parity_result_state_holds_fast_4

.transition_done_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_transition_cycles
    ASSP_PROFILE_INC profile_step_dp_transition_count
    ASSP_PROFILE_TSC_BEGIN
    mov edx, [rsp + 616]
    mov [rsp + 808], edx
    mov r10, [rsp + 1320]
    cmp qword [rsp + 1336], 128
    ja .scan_keys_linear_fast
    cmp qword [rsp + 784], 128
    jae .scan_keys_linear_fast
    mov r9d, edx
    imul r9d, r9d, 09e3779b9h
    and r9d, 127

.scan_key_hash_fast:
    cmp byte [rsp + r9 + 960], 0
    je .new_key_hash_fast
    movzx ecx, byte [rsp + r9 + 1088]
    cmp [r10 + rcx * 4], edx
    je .found_key_fast
    inc r9d
    and r9d, 127
    jmp .scan_key_hash_fast

.scan_keys_linear_fast:
    xor ecx, ecx

.scan_key_linear_fast:
    cmp rcx, [rsp + 784]
    jae .new_key_linear_fast
    cmp [r10 + rcx * 4], edx
    je .found_key_fast
    inc rcx
    jmp .scan_key_linear_fast

.new_key_linear_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_hash_cycles
    ASSP_PROFILE_INC profile_step_dp_hash_probe_count
    cmp rcx, [rsp + 1336]
    jae .fail_with_stack
    mov [rsp + 816], rcx
    mov byte [rsp + 824], 3
    jmp .score_candidate_fast

%ifdef ASSP_STANDALONE_EXE
.scan_key_direct_no_hold_fast:
    mov r9d, edx
    and r9d, 0fffh
    mov ecx, edx
    shr ecx, 12
    and ecx, 0f000h
    or r9d, ecx
    lea r11, [rel step_parity_fast_key_entries]
    mov eax, [rel step_parity_fast_key_generation]
    mov ecx, [r11 + r9 * 4]
    cmp cx, ax
    jne .new_key_direct_no_hold_fast
    shr ecx, 16
    ASSP_PROFILE_TSC_END profile_step_dp_hash_cycles
    ASSP_PROFILE_INC profile_step_dp_hash_probe_count
    jmp .found_key_fast_after_profile

.new_key_direct_no_hold_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_hash_cycles
    ASSP_PROFILE_INC profile_step_dp_hash_probe_count
    mov rcx, [rsp + 784]
    cmp rcx, [rsp + 1336]
    jae .fail_with_stack
    mov [rsp + 816], rcx
    lea r11, [rel step_parity_fast_key_entries]
    mov eax, [rel step_parity_fast_key_generation]
    mov edx, ecx
    shl edx, 16
    or edx, eax
    mov [r11 + r9 * 4], edx
    mov byte [rsp + 824], 2
    jmp .score_candidate_fast
%endif

.new_key_hash_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_hash_cycles
    ASSP_PROFILE_INC profile_step_dp_hash_probe_count
    mov rcx, [rsp + 784]
    cmp rcx, [rsp + 1336]
    jae .fail_with_stack
    mov [rsp + 816], rcx
    mov [rsp + 828], r9d
    mov byte [rsp + 824], 1
    jmp .score_candidate_fast

.found_key_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_hash_cycles
    ASSP_PROFILE_INC profile_step_dp_hash_probe_count
.found_key_fast_after_profile:
    mov [rsp + 816], rcx
    mov byte [rsp + 824], 0
    mov r11, [rsp + 1328]
    movss xmm0, [rsp + 896]
    comiss xmm0, [r11 + rcx * 4]
    jae .skip_candidate_fast_counted

.score_candidate_fast:
    cmp byte [rsp + 900], 0
    je .score_candidate_full_fast
    ASSP_PROFILE_INC profile_step_dp_score_clean_count
    ASSP_PROFILE_TSC_BEGIN
    lea rdx, [rsp + 208]
    mov r8, [rsp + 936]
    mov r9d, [rsp + 944]
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_PREV_ROW_HAS_LIVE_HOLD]
    mov [rsp + 32], eax
    mov rax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS]
    mov [rsp + 40], rax
    lea rax, [rsp + 908]
    mov [rsp + 48], rax
    mov rcx, [rsp + 880]
    call step_parity_action_cost_single_tap_clean_4
    jmp .score_candidate_done_fast

.score_candidate_full_fast:
    ASSP_PROFILE_INC profile_step_dp_score_full_count
    ASSP_PROFILE_TSC_BEGIN
    lea rdx, [rsp + 208]
    mov r8, [rsp + 936]
    lea r9, [rsp + 496]
    mov eax, [r15 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_COUNT]
    mov [rsp + 32], eax
    mov eax, [rsp + 904]
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
    lea rax, [rsp + 832]
    mov [rsp + 88], rax
    mov rcx, [rsp + 880]
    call step_parity_action_cost_total_4

.score_candidate_done_fast:
    ASSP_PROFILE_TSC_END profile_step_dp_score_cycles
    addss xmm0, [rsp + 896]

    cmp byte [rsp + 824], 0
    jne .write_candidate_fast
    mov r11, [rsp + 1328]
    mov rcx, [rsp + 816]
    comiss xmm0, [r11 + rcx * 4]
    jae .skip_candidate_fast_counted

.write_candidate_fast:
    ASSP_PROFILE_TSC_BEGIN
    ASSP_PROFILE_INC profile_step_dp_write_count
    mov rax, [rsp + 816]
    cmp byte [rsp + 824], 0
    je .copy_candidate_fast
    cmp byte [rsp + 824], 3
    je .commit_linear_candidate_fast
%ifdef ASSP_STANDALONE_EXE
    cmp byte [rsp + 824], 2
    je .commit_direct_candidate_fast
%endif
    mov edx, [rsp + 828]
    mov byte [rsp + rdx + 960], 1
    mov [rsp + rdx + 1088], al
    inc qword [rsp + 784]
    jmp .copy_candidate_fast

.commit_linear_candidate_fast:
    inc qword [rsp + 784]
    jmp .copy_candidate_fast

%ifdef ASSP_STANDALONE_EXE
.commit_direct_candidate_fast:
    inc qword [rsp + 784]
%endif

.copy_candidate_fast:
    mov rdx, [rsp + 792]
    mov [rbx + rax * 4], edx

    mov rdx, [rsp + 936]
    mov edx, [rdx]
    mov [rsi + rax * 4], edx

    lea r10, [rax + rax * 2]
    lea r10, [r10 * 4]
    mov rdx, [rsp + 208]
    mov [rdi + r10], rdx
    mov edx, [rsp + 216]
    mov [rdi + r10 + 8], edx

    lea r11, [rax + rax * 4]
    mov edx, [rsp + 496]
    mov [rbp + r11], edx
    mov dl, [rsp + 500]
    mov [rbp + r11 + 4], dl

    mov r10, [rsp + 1320]
    mov edx, [rsp + 808]
    mov [r10 + rax * 4], edx

    mov r10, [rsp + 1328]
    movss [r10 + rax * 4], xmm0
    ASSP_PROFILE_TSC_END profile_step_dp_copy_cycles
%ifdef ASSP_PHASE_PROFILE
    jmp .skip_candidate_fast
%endif

.skip_candidate_fast_counted:
    ASSP_PROFILE_INC profile_step_dp_skip_count

.skip_candidate_fast:
    inc qword [rsp + 800]
    jmp .perm_loop_fast

.next_state_fast:
    inc qword [rsp + 792]
    jmp .state_loop_fast

.success:
    mov rax, [rsp + 784]
    add rsp, 1216
    jmp .done

.fail_with_stack:
    add rsp, 1216
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

; Internal row-DP state constructor for rows with holds.
; rcx = initial state, rdx = placement[4], r8d = active mask,
; r9d = hold mask, stack arg 5 = out state, stack arg 6 = out hit[5],
; stack arg 7 = out key.
step_parity_result_state_holds_fast_4:
    sub rsp, 40
    mov [rsp], rcx
    mov [rsp + 8], rdx
    mov rax, [rsp + 80]
    mov [rsp + 16], rax
    mov dword [rsp + 24], 0
    mov dword [rsp + 28], 0

    mov dword [rax + ASSP_STEP_PARITY_STATE4_COMBINED], 0
    mov dword [rax + ASSP_STEP_PARITY_STATE4_WHERE_FEET], 0ffffffffh
    mov byte [rax + ASSP_STEP_PARITY_STATE4_WHERE_FEET + 4], 0ffh
    mov byte [rax + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], 0
    mov byte [rax + ASSP_STEP_PARITY_STATE4_MOVED_MASK], 0
    mov byte [rax + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], 0
    mov rax, [rsp + 88]
    mov dword [rax], 0ffffffffh
    mov byte [rax + 4], 0ffh

    xor r10d, r10d
.fast_hold_active_loop:
    bt r8d, r10d
    jnc .fast_hold_next_active
    mov rdx, [rsp + 8]
    movzx eax, byte [rdx + r10]
    test al, al
    jz .fast_hold_next_active
    cmp al, 4
    ja .fast_hold_next_active
    mov rdx, [rsp + 16]
    mov [rdx + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al
    mov rdx, [rsp + 88]
    mov byte [rdx + rax], r10b

    mov ecx, eax
    dec ecx
    mov r11d, 1
    shl r11d, cl
    mov ecx, r10d
    mov edx, 1
    shl edx, cl
    test r9d, edx
    jz .fast_hold_mark_moved
    or dword [rsp + 28], r11d
    mov rcx, [rsp]
    cmp [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al
    je .fast_hold_next_active

.fast_hold_mark_moved:
    or dword [rsp + 24], r11d

.fast_hold_next_active:
    inc r10d
    cmp r10d, 4
    jb .fast_hold_active_loop

    mov r9, [rsp + 16]
    xor r10d, r10d
    xor r11d, r11d
    xor edx, edx

.fast_hold_resolve_loop:
    movzx eax, byte [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    test al, al
    jnz .fast_hold_have_foot
    mov rcx, [rsp]
    movzx eax, byte [rcx + ASSP_STEP_PARITY_STATE4_COMBINED + r10]
    cmp al, 1
    je .fast_hold_prev_heel
    cmp al, 3
    je .fast_hold_prev_heel
    cmp al, 2
    je .fast_hold_prev_left_toe
    cmp al, 4
    je .fast_hold_prev_right_toe
    jmp .fast_hold_next_resolve

.fast_hold_prev_heel:
    mov ecx, eax
    dec ecx
    mov r8d, 1
    shl r8d, cl
    test dword [rsp + 24], r8d
    jnz .fast_hold_next_resolve
    jmp .fast_hold_store_foot

.fast_hold_prev_left_toe:
    test byte [rsp + 24], 3
    jnz .fast_hold_next_resolve
    mov eax, 2
    jmp .fast_hold_store_foot

.fast_hold_prev_right_toe:
    test byte [rsp + 24], 12
    jnz .fast_hold_next_resolve
    mov eax, 4

.fast_hold_store_foot:
    mov [r9 + ASSP_STEP_PARITY_STATE4_COMBINED + r10], al

.fast_hold_have_foot:
    mov ecx, r10d
    imul ecx, 3
    mov r8d, eax
    shl r8d, cl
    or r11d, r8d
    mov byte [r9 + ASSP_STEP_PARITY_STATE4_WHERE_FEET + rax], r10b
    mov ecx, r10d
    mov r8d, 1
    shl r8d, cl
    or edx, r8d

.fast_hold_next_resolve:
    inc r10d
    cmp r10d, 4
    jb .fast_hold_resolve_loop

    mov [r9 + ASSP_STEP_PARITY_STATE4_OCCUPIED_MASK], dl
    mov eax, [rsp + 24]
    mov [r9 + ASSP_STEP_PARITY_STATE4_MOVED_MASK], al
    mov ecx, [rsp + 28]
    mov [r9 + ASSP_STEP_PARITY_STATE4_HOLDING_MASK], cl
    shl eax, 24
    or eax, r11d
    shl ecx, 28
    or eax, ecx
    mov rdx, [rsp + 96]
    mov [rdx], eax
    add rsp, 40
    ret

; rcx = note counts[row_count], rdx = note masks[row_count],
; r8 = hold masks[row_count], r9 = mine masks[row_count],
; stack arg 5 = prev-row-live-hold flags[row_count],
; stack arg 6 = row seconds f32[row_count],
; stack arg 7 = row count,
; stack arg 8 = out combined placements[4 * row_count],
; stack arg 9 = output byte capacity,
; stack arg 10 = scratch previous states[state_cap],
; stack arg 11 = scratch previous costs[state_cap],
; stack arg 12 = scratch next states[state_cap],
; stack arg 13 = scratch next costs[state_cap],
; stack arg 14 = scratch predecessor indexes[state_cap],
; stack arg 15 = scratch row placements[4 * state_cap],
; stack arg 16 = scratch row hits[5 * state_cap],
; stack arg 17 = scratch row keys[state_cap],
; stack arg 18 = backtrack combined placements[4 * state_cap * row_count],
; stack arg 19 = backtrack predecessor indexes[state_cap * row_count],
; stack arg 20 = state capacity.
; rax = row count on success, or ASSP_NOT_FOUND on invalid input/capacity.
assp_step_parity_place_rows_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 256

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9

    mov rax, [rsp + 376]
    test rax, rax
    jz .zero_success

    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp qword [rsp + 360], 0
    je .fail
    cmp qword [rsp + 368], 0
    je .fail
    cmp qword [rsp + 384], 0
    je .fail
    cmp qword [rsp + 400], 0
    je .fail
    cmp qword [rsp + 408], 0
    je .fail
    cmp qword [rsp + 416], 0
    je .fail
    cmp qword [rsp + 424], 0
    je .fail
    cmp qword [rsp + 432], 0
    je .fail
    cmp qword [rsp + 440], 0
    je .fail
    cmp qword [rsp + 448], 0
    je .fail
    cmp qword [rsp + 456], 0
    je .fail
    cmp qword [rsp + 464], 0
    je .fail
    cmp qword [rsp + 472], 0
    je .fail
    cmp qword [rsp + 480], 0
    je .fail

    mov rax, [rsp + 376]
    shl rax, 2
    jc .fail
    cmp [rsp + 392], rax
    jb .fail

    mov rax, [rsp + 400]
    xor ecx, ecx
    mov [rax], rcx
    mov [rax + 8], ecx
    mov rax, [rsp + 408]
    mov [rax], ecx

    mov rax, [rsp + 400]
    mov [rsp + 168], rax
    mov rax, [rsp + 408]
    mov [rsp + 176], rax
    mov rax, [rsp + 416]
    mov [rsp + 184], rax
    mov rax, [rsp + 424]
    mov [rsp + 192], rax
    mov qword [rsp + 152], 1
    mov qword [rsp + 160], 0

    mov rax, [rsp + 368]
    movss xmm0, [rax]
    subss xmm0, [rel cost_one]
    movss [rsp + 224], xmm0

.row_loop:
    mov rax, [rsp + 160]
    cmp rax, [rsp + 376]
    jae .choose_best

    mov rdx, [rsp + 368]
    movss xmm0, [rdx + rax * 4]
    movss xmm1, xmm0
    subss xmm1, [rsp + 224]
    movss [rsp + 144], xmm1
    movss [rsp + 224], xmm0

    movzx ecx, byte [r12 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_COUNT], ecx
    movzx ecx, byte [r13 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK], ecx
    movzx edx, byte [r14 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK], edx
    movzx ecx, byte [r15 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_MINE_MASK], ecx
    movzx ecx, byte [r13 + rax]
    or ecx, edx
    and ecx, 9
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_SIDE_MASK], ecx
    mov rdx, [rsp + 360]
    movzx ecx, byte [rdx + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_PREV_ROW_HAS_LIVE_HOLD], ecx
    lea rcx, [rsp + 144]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS], rcx

    mov rcx, [rsp + 168]
    mov rdx, [rsp + 176]
    mov r8, [rsp + 152]
    lea r9, [rsp + 112]
    mov rax, [rsp + 432]
    mov [rsp + 32], rax
    mov rax, [rsp + 440]
    mov [rsp + 40], rax
    mov rax, [rsp + 184]
    mov [rsp + 48], rax
    mov rax, [rsp + 448]
    mov [rsp + 56], rax
    mov rax, [rsp + 456]
    mov [rsp + 64], rax
    mov rax, [rsp + 192]
    mov [rsp + 72], rax
    mov rax, [rsp + 480]
    mov [rsp + 80], rax
    call assp_step_parity_row_best_candidates_4
    cmp rax, ASSP_NOT_FOUND
    je .fail
    test rax, rax
    jz .fail
    mov [rsp + 200], rax

    mov r9, [rsp + 160]
    imul r9, [rsp + 480]
    xor rcx, rcx
.store_backtrack_loop:
    cmp rcx, [rsp + 200]
    jae .swap_rows

    lea rax, [r9 + rcx]

    mov rdx, [rsp + 432]
    mov edx, [rdx + rcx * 4]
    mov r8, [rsp + 472]
    mov [r8 + rax * 4], edx

    mov rdx, [rsp + 184]
    lea r8, [rcx + rcx * 2]
    mov edx, [rdx + r8 * 4]
    mov r8, [rsp + 464]
    mov [r8 + rax * 4], edx

    inc rcx
    jmp .store_backtrack_loop

.swap_rows:
    mov rax, [rsp + 168]
    mov rdx, [rsp + 184]
    mov [rsp + 168], rdx
    mov [rsp + 184], rax
    mov rax, [rsp + 176]
    mov rdx, [rsp + 192]
    mov [rsp + 176], rdx
    mov [rsp + 192], rax
    mov rax, [rsp + 200]
    mov [rsp + 152], rax
    inc qword [rsp + 160]
    jmp .row_loop

.choose_best:
    mov rdx, [rsp + 176]
    xor ecx, ecx
    movss xmm0, [rdx]
    mov rax, 1
.best_loop:
    cmp rax, [rsp + 152]
    jae .backtrack
    movss xmm1, [rdx + rax * 4]
    comiss xmm1, xmm0
    jae .next_best
    movss xmm0, xmm1
    mov rcx, rax
.next_best:
    inc rax
    jmp .best_loop

.backtrack:
    mov [rsp + 208], rcx
    mov rsi, [rsp + 376]
.backtrack_loop:
    test rsi, rsi
    jz .success
    dec rsi

    mov rax, rsi
    imul rax, [rsp + 480]
    add rax, [rsp + 208]

    mov rdx, [rsp + 464]
    mov ecx, [rdx + rax * 4]
    mov rdx, [rsp + 384]
    mov [rdx + rsi * 4], ecx

    mov rdx, [rsp + 472]
    mov ecx, [rdx + rax * 4]
    mov [rsp + 208], rcx
    jmp .backtrack_loop

.success:
    mov rax, [rsp + 376]
    add rsp, 256
    jmp .done

.zero_success:
    xor eax, eax
    add rsp, 256
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND
    add rsp, 256

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

; rcx = note counts[row_count], rdx = note masks[row_count],
; r8 = hold masks[row_count], r9 = mine masks[row_count],
; stack arg 5 = prev-row-live-hold flags[row_count],
; stack arg 6 = row seconds f32[row_count],
; stack arg 7 = row count,
; stack arg 8 = out combined placements[8 * row_count],
; stack arg 9 = output byte capacity,
; stack arg 10 = scratch previous states[state_cap],
; stack arg 11 = scratch previous costs[state_cap],
; stack arg 12 = scratch next states[state_cap],
; stack arg 13 = scratch next costs[state_cap],
; stack arg 14 = scratch predecessor indexes[state_cap],
; stack arg 15 = scratch row placements[8 * state_cap],
; stack arg 16 = scratch row hits[5 * state_cap],
; stack arg 17 = scratch row keys[state_cap],
; stack arg 18 = backtrack combined placements[8 * state_cap * row_count],
; stack arg 19 = backtrack predecessor indexes[state_cap * row_count],
; stack arg 20 = state capacity.
; rax = row count on success, or ASSP_NOT_FOUND on invalid input/capacity.
assp_step_parity_place_rows_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 256

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9

    mov rax, [rsp + 376]
    test rax, rax
    jz .zero_success

    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp qword [rsp + 360], 0
    je .fail
    cmp qword [rsp + 368], 0
    je .fail
    cmp qword [rsp + 384], 0
    je .fail
    cmp qword [rsp + 400], 0
    je .fail
    cmp qword [rsp + 408], 0
    je .fail
    cmp qword [rsp + 416], 0
    je .fail
    cmp qword [rsp + 424], 0
    je .fail
    cmp qword [rsp + 432], 0
    je .fail
    cmp qword [rsp + 440], 0
    je .fail
    cmp qword [rsp + 448], 0
    je .fail
    cmp qword [rsp + 456], 0
    je .fail
    cmp qword [rsp + 464], 0
    je .fail
    cmp qword [rsp + 472], 0
    je .fail
    cmp qword [rsp + 480], 0
    je .fail

    mov rax, [rsp + 376]
    shl rax, 3
    jc .fail
    cmp [rsp + 392], rax
    jb .fail

    mov rax, [rsp + 400]
    xor ecx, ecx
    mov [rax], rcx
    mov [rax + 8], rcx
    mov rax, [rsp + 408]
    mov [rax], ecx

    mov rax, [rsp + 400]
    mov [rsp + 168], rax
    mov rax, [rsp + 408]
    mov [rsp + 176], rax
    mov rax, [rsp + 416]
    mov [rsp + 184], rax
    mov rax, [rsp + 424]
    mov [rsp + 192], rax
    mov qword [rsp + 152], 1
    mov qword [rsp + 160], 0

    mov rax, [rsp + 368]
    movss xmm0, [rax]
    subss xmm0, [rel cost_one]
    movss [rsp + 224], xmm0

.row_loop:
    mov rax, [rsp + 160]
    cmp rax, [rsp + 376]
    jae .choose_best

    mov rdx, [rsp + 368]
    movss xmm0, [rdx + rax * 4]
    movss xmm1, xmm0
    subss xmm1, [rsp + 224]
    movss [rsp + 144], xmm1
    movss [rsp + 224], xmm0

    movzx ecx, byte [r12 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_COUNT], ecx
    movzx ecx, byte [r13 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_NOTE_MASK], ecx
    movzx edx, byte [r14 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_HOLD_MASK], edx
    movzx ecx, byte [r15 + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_MINE_MASK], ecx
    movzx ecx, byte [r13 + rax]
    or ecx, edx
    and ecx, 099h
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_SIDE_MASK], ecx
    mov rdx, [rsp + 360]
    movzx ecx, byte [rdx + rax]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_PREV_ROW_HAS_LIVE_HOLD], ecx
    lea rcx, [rsp + 144]
    mov [rsp + 112 + ASSP_STEP_PARITY_ROW_COST_CTX4_ELAPSED_SECONDS], rcx

    mov rcx, [rsp + 168]
    mov rdx, [rsp + 176]
    mov r8, [rsp + 152]
    lea r9, [rsp + 112]
    mov rax, [rsp + 432]
    mov [rsp + 32], rax
    mov rax, [rsp + 440]
    mov [rsp + 40], rax
    mov rax, [rsp + 184]
    mov [rsp + 48], rax
    mov rax, [rsp + 448]
    mov [rsp + 56], rax
    mov rax, [rsp + 456]
    mov [rsp + 64], rax
    mov rax, [rsp + 192]
    mov [rsp + 72], rax
    mov rax, [rsp + 480]
    mov [rsp + 80], rax
    call assp_step_parity_row_best_candidates_8
    cmp rax, ASSP_NOT_FOUND
    je .fail
    test rax, rax
    jnz .row_candidates_ready
    jmp .fail

.row_candidates_ready:
    mov [rsp + 200], rax

    mov r9, [rsp + 160]
    imul r9, [rsp + 480]
    xor rcx, rcx
.store_backtrack_loop:
    cmp rcx, [rsp + 200]
    jae .swap_rows

    lea rax, [r9 + rcx]

    mov rdx, [rsp + 432]
    mov edx, [rdx + rcx * 4]
    mov r8, [rsp + 472]
    mov [r8 + rax * 4], edx

    mov rdx, [rsp + 184]
    mov r8, rcx
    shl r8, 4
    mov rdx, [rdx + r8]
    mov r8, [rsp + 464]
    mov [r8 + rax * 8], rdx

    inc rcx
    jmp .store_backtrack_loop

.swap_rows:
    mov rax, [rsp + 168]
    mov rdx, [rsp + 184]
    mov [rsp + 168], rdx
    mov [rsp + 184], rax
    mov rax, [rsp + 176]
    mov rdx, [rsp + 192]
    mov [rsp + 176], rdx
    mov [rsp + 192], rax
    mov rax, [rsp + 200]
    mov [rsp + 152], rax
    inc qword [rsp + 160]
    jmp .row_loop

.choose_best:
    mov rdx, [rsp + 176]
    xor ecx, ecx
    movss xmm0, [rdx]
    mov rax, 1
.best_loop:
    cmp rax, [rsp + 152]
    jae .backtrack
    movss xmm1, [rdx + rax * 4]
    comiss xmm1, xmm0
    jae .next_best
    movss xmm0, xmm1
    mov rcx, rax
.next_best:
    inc rax
    jmp .best_loop

.backtrack:
    mov [rsp + 208], rcx
    mov rsi, [rsp + 376]
.backtrack_loop:
    test rsi, rsi
    jz .success
    dec rsi

    mov rax, rsi
    imul rax, [rsp + 480]
    add rax, [rsp + 208]

    mov rdx, [rsp + 464]
    mov rcx, [rdx + rax * 8]
    mov rdx, [rsp + 384]
    mov [rdx + rsi * 8], rcx

    mov rdx, [rsp + 472]
    mov ecx, [rdx + rax * 4]
    mov [rsp + 208], rcx
    jmp .backtrack_loop

.success:
    mov rax, [rsp + 376]
    add rsp, 256
    jmp .done

.zero_success:
    xor eax, eax
    add rsp, 256
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND
    add rsp, 256

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

; rcx = assp_step_parity_prepared_rows4,
; rdx = assp_step_parity_workspace4, r8 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers/capacity.
assp_step_parity_count_prepared_rows_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 160

    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8

    test rdi, rdi
    jz .fail_no_zero
    xor eax, eax
    mov [rdi], rax
    mov [rdi + 8], rax
    mov [rdi + 16], rax
    mov [rdi + 24], rax

    test rbx, rbx
    jz .fail
    test rsi, rsi
    jz .fail

    mov r12, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_COUNT]
    cmp r12, 0
    je .count_rows

    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_MS], 0
    je .fail
    cmp qword [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS], 0
    je .fail

    mov rcx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS]
    mov rdx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS]
    mov r8, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS]
    mov r9, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS]
    mov rax, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS]
    mov [rsp + 32], rax
    mov rax, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS]
    mov [rsp + 40], rax
    mov [rsp + 48], r12
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS]
    mov [rsp + 56], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENT_CAP]
    mov [rsp + 64], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREV_STATES]
    mov [rsp + 72], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREV_COSTS]
    mov [rsp + 80], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_NEXT_STATES]
    mov [rsp + 88], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_NEXT_COSTS]
    mov [rsp + 96], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREDECESSORS]
    mov [rsp + 104], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PLACEMENTS]
    mov [rsp + 112], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_HITS]
    mov [rsp + 120], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_KEYS]
    mov [rsp + 128], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS]
    mov [rsp + 136], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS]
    mov [rsp + 144], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP]
    mov [rsp + 152], rax
    call assp_step_parity_place_rows_4
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, r12
    jne .fail

.count_rows:
    mov rcx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS]
    mov rdx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS]
    mov r8, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS]
    mov r9, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS]
    mov [rsp + 32], r12
    mov [rsp + 40], rdi
    call assp_calculate_step_tech_counts_from_placements_seconds_4
    jmp .done

.fail:
    xor eax, eax
    jmp .done

.fail_no_zero:
    xor eax, eax

.done:
    add rsp, 160
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = assp_step_parity_prepared_rows4,
; rdx = assp_step_parity_workspace8, r8 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers/capacity.
assp_step_parity_count_prepared_rows_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 160

    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8

    test rdi, rdi
    jz .fail_no_zero
    xor eax, eax
    mov [rdi], rax
    mov [rdi + 8], rax
    mov [rdi + 16], rax
    mov [rdi + 24], rax

    test rbx, rbx
    jz .fail
    test rsi, rsi
    jz .fail

    mov r12, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_COUNT]
    cmp r12, 0
    je .count_rows

    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS], 0
    je .fail
    cmp qword [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_MS], 0
    je .fail
    cmp qword [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS], 0
    je .fail

    mov rcx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS]
    mov rdx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_MASKS]
    mov r8, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_HOLD_MASKS]
    mov r9, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_MINE_MASKS]
    mov rax, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_PREV_ROW_LIVE_HOLDS]
    mov [rsp + 32], rax
    mov rax, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS]
    mov [rsp + 40], rax
    mov [rsp + 48], r12
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS]
    mov [rsp + 56], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENT_CAP]
    mov [rsp + 64], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREV_STATES]
    mov [rsp + 72], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREV_COSTS]
    mov [rsp + 80], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_NEXT_STATES]
    mov [rsp + 88], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_NEXT_COSTS]
    mov [rsp + 96], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PREDECESSORS]
    mov [rsp + 104], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_PLACEMENTS]
    mov [rsp + 112], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_HITS]
    mov [rsp + 120], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_KEYS]
    mov [rsp + 128], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PLACEMENTS]
    mov [rsp + 136], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_BACKTRACK_PREDECESSORS]
    mov [rsp + 144], rax
    mov rax, [rsi + ASSP_STEP_PARITY_WORKSPACE4_STATE_CAP]
    mov [rsp + 152], rax
    call assp_step_parity_place_rows_8
    cmp rax, ASSP_NOT_FOUND
    je .fail
    cmp rax, r12
    jne .fail

.count_rows:
    mov rcx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_TECH_MASKS]
    mov rdx, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_NOTE_COUNTS]
    mov r8, [rbx + ASSP_STEP_PARITY_PREPARED_ROWS4_ROW_SECONDS]
    mov r9, [rsi + ASSP_STEP_PARITY_WORKSPACE4_OUT_PLACEMENTS]
    mov [rsp + 32], r12
    mov [rsp + 40], rdi
    call assp_calculate_step_tech_counts_from_placements_seconds_8
    jmp .done

.fail:
    xor eax, eax
    jmp .done

.fail_no_zero:
    xor eax, eax

.done:
    add rsp, 160
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

%macro prepare_flush_current4 0
    cmp qword [rsp + 16], 0
    je %%done
    mov rax, [rsp]
    cmp rax, [rsp + 272]
    jae .fail

    mov ecx, [rsp + 40]
    mov [r15 + rax], cl
    mov ecx, [rsp + 44]
    mov [rbx + rax], cl
    mov ecx, [rsp + 48]
    mov [rdi + rax], cl
    mov byte [rbp + rax], 0
    mov rdx, [rsp + 240]
    mov ecx, [rsp + 36]
    mov [rdx + rax], cl
    mov rdx, [rsp + 248]
    mov byte [rdx + rax], 0
    mov rdx, [rsp + 256]
    mov ecx, [rsp + 24]
    mov [rdx + rax * 4], ecx
    mov rdx, [rsp + 264]
    mov ecx, [rsp + 28]
    mov [rdx + rax * 4], ecx
    inc qword [rsp]
    mov qword [rsp + 16], 0
%%done:
%endmacro

%macro prepare_reset_current4 0
    mov qword [rsp + 16], 1
    mov eax, [rsp + 56]
    mov [rsp + 24], eax
    mov eax, [rsp + 60]
    mov [rsp + 28], eax
    mov eax, [rsp + 32]
    mov [rsp + 36], eax
    mov dword [rsp + 32], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0
%endmacro

%macro prepare_ensure_current4 0
    cmp qword [rsp + 16], 0
    je %%reset
    mov eax, [rsp + 56]
    cmp eax, [rsp + 24]
    je %%done
    prepare_flush_current4
%%reset:
    prepare_reset_current4
%%done:
%endmacro

%macro prepare_add_note4 2
    prepare_ensure_current4
    test dword [rsp + 44], %1
    jnz %%seen
    inc dword [rsp + 40]
%%seen:
    or dword [rsp + 44], %1
%if %2
    or dword [rsp + 48], %1
%endif
%endmacro

%macro prepare_add_mine4 1
    mov eax, [rsp + 56]
    and eax, 7fffffffh
    cmp qword [rsp + 16], 0
    je %%pending
    mov ecx, [rsp + 56]
    cmp ecx, [rsp + 24]
    jne %%pending
    cmp qword [rsp], 0
    je %%pending
    test eax, eax
    jz %%clear_next
    or dword [rsp + 36], %1
    jmp %%done
%%clear_next:
    and dword [rsp + 36], ~%1
    jmp %%done
%%pending:
    test eax, eax
    jz %%clear_pending
    or dword [rsp + 32], %1
    jmp %%done
%%clear_pending:
    and dword [rsp + 32], ~%1
%%done:
%endmacro

%macro prepare_process_char4 2
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%tap
    cmp al, 'L'
    je %%lift
    cmp al, 'M'
    je %%mine
    jmp .fail
%%tap:
    prepare_add_note4 %2, 1
    jmp %%done
%%lift:
    prepare_add_note4 %2, 0
    jmp %%done
%%mine:
    prepare_add_mine4 %2
%%done:
%endmacro

%macro hold_head_end_col4 1
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%invalidate
    cmp al, '2'
    je %%start
    cmp al, '4'
    je %%start
    cmp al, '3'
    je %%end_hold
    cmp al, 'L'
    je %%invalidate
    cmp al, 'M'
    je %%invalidate
    cmp al, 'F'
    je %%invalidate
    jmp .fail
%%start:
    mov [rsp + (%1 * 8)], rbx
    jmp %%done
%%end_hold:
    mov rax, [rsp + (%1 * 8)]
    cmp rax, ASSP_NOT_FOUND
    je %%done
    movss xmm0, [r13 + rbx * 4]
    mulss xmm0, [rel rows_per_beat_f32]
    cvtss2si ecx, xmm0
    movss xmm1, [r13 + rax * 4]
    mulss xmm1, [rel rows_per_beat_f32]
    cvtss2si edx, xmm1
    sub ecx, edx
    cvtsi2ss xmm0, ecx
    divss xmm0, [rel rows_per_beat_f32]
    addss xmm0, [r13 + rax * 4]
    shl rax, 4
    movss [rdi + rax + (%1 * 4)], xmm0
%%invalidate:
    mov qword [rsp + (%1 * 8)], ASSP_NOT_FOUND
%%done:
%endmacro

%macro hold_head_end_col8 1
    mov al, [rsi + %1]
    cmp al, '2'
    je %%start
    cmp al, '4'
    je %%start
    cmp al, '3'
    je %%end_hold
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%invalidate
    cmp al, 'L'
    je %%invalidate
    cmp al, 'M'
    je %%invalidate
    cmp al, 'F'
    je %%invalidate
    jmp .fail
%%start:
    mov [rsp + (%1 * 8)], rbx
    jmp %%done
%%end_hold:
    mov rax, [rsp + (%1 * 8)]
    cmp rax, ASSP_NOT_FOUND
    je %%done
    movss xmm0, [r13 + rbx * 4]
    mulss xmm0, [rel rows_per_beat_f32]
    cvtss2si ecx, xmm0
    movss xmm1, [r13 + rax * 4]
    mulss xmm1, [rel rows_per_beat_f32]
    cvtss2si edx, xmm1
    sub ecx, edx
    cvtsi2ss xmm0, ecx
    divss xmm0, [rel rows_per_beat_f32]
    addss xmm0, [r13 + rax * 4]
    shl rax, 5
    movss [rdi + rax + (%1 * 4)], xmm0
%%invalidate:
    mov qword [rsp + (%1 * 8)], ASSP_NOT_FOUND
%%done:
%endmacro

; rcx = minimized 4-panel note-data, rdx = byte length,
; r8 = row beats for each non-empty source row,
; r9 = source row beat count,
; stack arg 5 = out hold end beats as row-major f32[rows][4],
; stack arg 6 = output source row capacity.
; rax = consumed non-empty source row count, or ASSP_NOT_FOUND.
assp_step_parity_hold_head_ends_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 32

    mov rsi, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov rdi, [rsp + 136]
    mov r15, [rsp + 144]

    test r12, r12
    jz .empty
    test rsi, rsi
    jz .fail

    mov qword [rsp], ASSP_NOT_FOUND
    mov qword [rsp + 8], ASSP_NOT_FOUND
    mov qword [rsp + 16], ASSP_NOT_FOUND
    mov qword [rsp + 24], ASSP_NOT_FOUND
    lea r12, [rsi + r12]
    xor ebx, ebx

.line_loop:
    cmp rsi, r12
    jae .success

.trim_left:
    cmp rsi, r12
    jae .success
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
    je .skip_to_next_line
    cmp al, ','
    je .measure_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 4]
    cmp rax, r12
    ja .success

    cmp dword [rsi], 30303030h
    je .row_done

    cmp rbx, r14
    jae .fail
    cmp rbx, r15
    jae .fail
    test r13, r13
    jz .fail
    test rdi, rdi
    jz .fail

    mov rax, rbx
    shl rax, 4
    mov ecx, [rel hold_end_none]
    mov [rdi + rax], ecx
    mov [rdi + rax + 4], ecx
    mov [rdi + rax + 8], ecx
    mov [rdi + rax + 12], ecx

    hold_head_end_col4 0
    hold_head_end_col4 1
    hold_head_end_col4 2
    hold_head_end_col4 3
    inc rbx

.row_done:
    add rsi, 4
    jmp .skip_to_next_line

.measure_done:
    inc rsi
    jmp .line_loop

.skip_to_next_line:
    cmp rsi, r12
    jae .success
    mov al, [rsi]
    cmp al, ';'
    je .success
    inc rsi
    cmp al, 10
    je .line_loop
    cmp al, ','
    je .line_loop
    jmp .skip_to_next_line

.empty:
    xor eax, eax
    jmp .done

.success:
    mov rax, rbx
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 32
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 8-panel note-data, rdx = byte length,
; r8 = row beats for each non-empty source row,
; r9 = source row beat count,
; stack arg 5 = out hold end beats as row-major f32[rows][8],
; stack arg 6 = output source row capacity.
; rax = consumed non-empty source row count, or ASSP_NOT_FOUND.
assp_step_parity_hold_head_ends_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 64

    mov rsi, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov rdi, [rsp + 168]
    mov r15, [rsp + 176]

    test r12, r12
    jz .empty
    test rsi, rsi
    jz .fail

    mov qword [rsp], ASSP_NOT_FOUND
    mov qword [rsp + 8], ASSP_NOT_FOUND
    mov qword [rsp + 16], ASSP_NOT_FOUND
    mov qword [rsp + 24], ASSP_NOT_FOUND
    mov qword [rsp + 32], ASSP_NOT_FOUND
    mov qword [rsp + 40], ASSP_NOT_FOUND
    mov qword [rsp + 48], ASSP_NOT_FOUND
    mov qword [rsp + 56], ASSP_NOT_FOUND
    lea r12, [rsi + r12]
    xor ebx, ebx

.line_loop:
    cmp rsi, r12
    jae .success

.trim_left:
    cmp rsi, r12
    jae .success
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
    je .skip_to_next_line
    cmp al, ','
    je .measure_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 8]
    cmp rax, r12
    ja .success

    cmp dword [rsi], 30303030h
    jne .nonzero_row
    cmp dword [rsi + 4], 30303030h
    je .row_done

.nonzero_row:
    cmp rbx, r14
    jae .fail
    cmp rbx, r15
    jae .fail
    test r13, r13
    jz .fail
    test rdi, rdi
    jz .fail

    mov rax, rbx
    shl rax, 5
    mov ecx, [rel hold_end_none]
    mov [rdi + rax], ecx
    mov [rdi + rax + 4], ecx
    mov [rdi + rax + 8], ecx
    mov [rdi + rax + 12], ecx
    mov [rdi + rax + 16], ecx
    mov [rdi + rax + 20], ecx
    mov [rdi + rax + 24], ecx
    mov [rdi + rax + 28], ecx

    hold_head_end_col8 0
    hold_head_end_col8 1
    hold_head_end_col8 2
    hold_head_end_col8 3
    hold_head_end_col8 4
    hold_head_end_col8 5
    hold_head_end_col8 6
    hold_head_end_col8 7
    inc rbx

.row_done:
    add rsi, 8
    jmp .skip_to_next_line

.measure_done:
    inc rsi
    jmp .line_loop

.skip_to_next_line:
    cmp rsi, r12
    jae .success
    mov al, [rsi]
    cmp al, ';'
    je .success
    inc rsi
    cmp al, 10
    je .line_loop
    cmp al, ','
    je .line_loop
    jmp .skip_to_next_line

.empty:
    xor eax, eax
    jmp .done

.success:
    mov rax, rbx
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 64
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 4-panel note-data, rdx = byte length,
; r8 = BPM segments, r9 = BPM segment count, stack arg 5 = offset microseconds,
; stack arg 6 = out row seconds, stack arg 7 = out row milliseconds,
; stack arg 8 = out row beats, stack arg 9 = output row capacity.
; Emits one time row for each nonzero source row used by RSSP step parity.
; rax = emitted row count, or ASSP_NOT_FOUND.
assp_step_parity_bpm_row_times_4:
    xor eax, eax
    jmp step_parity_bpm_row_times_4_entry

; Same as assp_step_parity_bpm_row_times_4, but BPM values are millionths.
assp_step_parity_bpm_row_times_micro_4:
    mov eax, ASSP_TRUE

step_parity_bpm_row_times_4_entry:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    sub rsp, 112
    mov [rbp - 88], eax

    mov rsi, rcx
    lea rbx, [rcx + rdx]
    mov r13, r8
    mov r14, r9
    mov r15, [rbp + 104]
    mov rax, [rbp + 112]
    mov [rbp - 8], rax
    mov rax, [rbp + 120]
    mov [rbp - 16], rax
    mov rax, [rbp + 128]
    mov [rbp - 24], rax
    mov rax, [rbp + 136]
    mov [rbp - 32], rax

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .fail
    test r14, r14
    jz .check_outputs
    test r13, r13
    jz .fail

.check_outputs:
    cmp qword [rbp - 8], 0
    je .fail
    cmp qword [rbp - 16], 0
    je .fail
    cmp qword [rbp - 24], 0
    je .fail

    xor r12d, r12d
    mov qword [rbp - 40], 0
    mov dword [rbp - 48], 0
    mov dword [rbp - 52], 0
    mov dword [rbp - 56], 1

.measure_loop:
    cmp rsi, rbx
    jae .success
    mov [rbp - 64], rsi
    mov rdi, rsi
.find_measure_end:
    cmp rdi, rbx
    jae .measure_end_found
    mov al, [rdi]
    cmp al, ','
    je .measure_end_found
    cmp al, ';'
    je .measure_end_found
    inc rdi
    jmp .find_measure_end

.measure_end_found:
    mov [rbp - 72], rdi
    xor r9d, r9d
    mov r10, [rbp - 64]
.count_line_loop:
    cmp r10, rdi
    jae .count_done
    mov r11, r10
.count_trim:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    cmp al, 10
    je .count_blank_line
    cmp al, ' '
    je .count_trim_advance
    cmp al, 9
    jb .count_nonempty
    cmp al, 13
    jbe .count_trim_advance
    jmp .count_nonempty
.count_trim_advance:
    inc r11
    jmp .count_trim
.count_blank_line:
    lea r10, [r11 + 1]
    jmp .count_line_loop
.count_nonempty:
    cmp al, '/'
    je .count_skip_comment
    inc r9
.count_skip_line:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .count_skip_line
    mov r10, r11
    jmp .count_line_loop
.count_skip_comment:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .count_skip_comment
    mov r10, r11
    jmp .count_line_loop

.count_done:
    test r9, r9
    jz .advance_measure
    mov [rbp - 80], r9
    xor r8d, r8d
    mov r10, [rbp - 64]
.emit_line_loop:
    mov rdi, [rbp - 72]
    cmp r10, rdi
    jae .advance_measure
    mov r11, r10
.emit_trim:
    cmp r11, rdi
    jae .advance_measure
    mov al, [r11]
    cmp al, 10
    je .emit_blank_line
    cmp al, ' '
    je .emit_trim_advance
    cmp al, 9
    jb .emit_nonempty
    cmp al, 13
    jbe .emit_trim_advance
    jmp .emit_nonempty
.emit_trim_advance:
    inc r11
    jmp .emit_trim
.emit_blank_line:
    lea r10, [r11 + 1]
    jmp .emit_line_loop

.emit_nonempty:
    cmp al, '/'
    je .emit_skip_comment
    lea rax, [r11 + 4]
    cmp rax, rdi
    ja .fail
    cmp dword [r11], 30303030h
    je .emit_counted_zero
    mov rax, [rbp - 40]
    cmp rax, [rbp - 32]
    jae .fail

    cvtsi2ss xmm0, r8
    movss xmm1, [rel const_four_f32]
    cvtsi2ss xmm2, qword [rbp - 80]
    divss xmm1, xmm2
    mulss xmm0, xmm1
    cvtsi2ss xmm3, r12
    mulss xmm3, [rel const_four_f32]
    addss xmm0, xmm3
    movss xmm4, xmm0
    mulss xmm4, [rel rows_per_beat_f32]
    cvtss2si ecx, xmm4
    cvtsi2ss xmm0, ecx
    divss xmm0, [rel rows_per_beat_f32]

    mov rdx, [rbp - 24]
    movss [rdx + rax * 4], xmm0
    cmp r14, 1
    jne .emit_general_time
    cmp qword [r13 + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    jne .emit_general_time
    call fixed_bpm_row_time_seconds4
    jmp .emit_time_done
.emit_general_time:
    call bpm_row_time_seconds4
.emit_time_done:
    mov rax, [rbp - 40]
    mov rdx, [rbp - 8]
    movss [rdx + rax * 4], xmm0

    cmp dword [rbp - 56], 0
    je .elapsed_ms
    movss xmm1, xmm0
    mulss xmm1, [rel const_thousand_f32]
    call floor_ss_to_i32_4
    mov [rbp - 52], eax
    mov dword [rbp - 56], 0
    jmp .store_ms

.elapsed_ms:
    movss xmm1, xmm0
    subss xmm1, [rbp - 48]
    mulss xmm1, [rel const_thousand_f32]
    call floor_ss_to_i32_4
    add eax, [rbp - 52]
    mov [rbp - 52], eax

.store_ms:
    movss [rbp - 48], xmm0
    mov rax, [rbp - 40]
    mov rdx, [rbp - 16]
    mov ecx, [rbp - 52]
    mov [rdx + rax * 4], ecx
    inc qword [rbp - 40]

.emit_counted_zero:
    inc r8
.emit_skip_line:
    cmp r11, [rbp - 72]
    jae .advance_measure
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .emit_skip_line
    mov r10, r11
    jmp .emit_line_loop
.emit_skip_comment:
    cmp r11, [rbp - 72]
    jae .advance_measure
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .emit_skip_comment
    mov r10, r11
    jmp .emit_line_loop

.advance_measure:
    mov rdi, [rbp - 72]
    cmp rdi, rbx
    jae .success
    mov al, [rdi]
    lea rsi, [rdi + 1]
    cmp al, ';'
    je .success
    inc r12
    jmp .measure_loop

.empty:
    xor eax, eax
    jmp .done

.success:
    mov rax, [rbp - 40]
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 112
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 8-panel note-data, rdx = byte length,
; r8 = BPM segments, r9 = BPM segment count, stack arg 5 = offset microseconds,
; stack arg 6 = out row seconds, stack arg 7 = out row milliseconds,
; stack arg 8 = out row beats, stack arg 9 = output row capacity.
; Emits one time row for each nonzero source row used by RSSP step parity.
; rax = emitted row count, or ASSP_NOT_FOUND.
assp_step_parity_bpm_row_times_8:
    xor eax, eax
    jmp step_parity_bpm_row_times_8_entry

; Same as assp_step_parity_bpm_row_times_8, but BPM values are millionths.
assp_step_parity_bpm_row_times_micro_8:
    mov eax, ASSP_TRUE

step_parity_bpm_row_times_8_entry:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    sub rsp, 112
    mov [rbp - 88], eax

    mov rsi, rcx
    lea rbx, [rcx + rdx]
    mov r13, r8
    mov r14, r9
    mov r15, [rbp + 104]
    mov rax, [rbp + 112]
    mov [rbp - 8], rax
    mov rax, [rbp + 120]
    mov [rbp - 16], rax
    mov rax, [rbp + 128]
    mov [rbp - 24], rax
    mov rax, [rbp + 136]
    mov [rbp - 32], rax

    test rdx, rdx
    jz .empty
    test rcx, rcx
    jz .fail
    test r14, r14
    jz .check_outputs
    test r13, r13
    jz .fail

.check_outputs:
    cmp qword [rbp - 8], 0
    je .fail
    cmp qword [rbp - 16], 0
    je .fail
    cmp qword [rbp - 24], 0
    je .fail

    xor r12d, r12d
    mov qword [rbp - 40], 0
    mov dword [rbp - 48], 0
    mov dword [rbp - 52], 0
    mov dword [rbp - 56], 1

.measure_loop:
    cmp rsi, rbx
    jae .success
    mov [rbp - 64], rsi
    mov rdi, rsi
.find_measure_end:
    cmp rdi, rbx
    jae .measure_end_found
    mov al, [rdi]
    cmp al, ','
    je .measure_end_found
    cmp al, ';'
    je .measure_end_found
    inc rdi
    jmp .find_measure_end

.measure_end_found:
    mov [rbp - 72], rdi
    xor r9d, r9d
    mov r10, [rbp - 64]
.count_line_loop:
    cmp r10, rdi
    jae .count_done
    mov r11, r10
.count_trim:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    cmp al, 10
    je .count_blank_line
    cmp al, ' '
    je .count_trim_advance
    cmp al, 9
    jb .count_nonempty
    cmp al, 13
    jbe .count_trim_advance
    jmp .count_nonempty
.count_trim_advance:
    inc r11
    jmp .count_trim
.count_blank_line:
    lea r10, [r11 + 1]
    jmp .count_line_loop
.count_nonempty:
    cmp al, '/'
    je .count_skip_comment
    inc r9
.count_skip_line:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .count_skip_line
    mov r10, r11
    jmp .count_line_loop
.count_skip_comment:
    cmp r11, rdi
    jae .count_done
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .count_skip_comment
    mov r10, r11
    jmp .count_line_loop

.count_done:
    test r9, r9
    jz .advance_measure
    mov [rbp - 80], r9
    xor r8d, r8d
    mov r10, [rbp - 64]
.emit_line_loop:
    mov rdi, [rbp - 72]
    cmp r10, rdi
    jae .advance_measure
    mov r11, r10
.emit_trim:
    cmp r11, rdi
    jae .advance_measure
    mov al, [r11]
    cmp al, 10
    je .emit_blank_line
    cmp al, ' '
    je .emit_trim_advance
    cmp al, 9
    jb .emit_nonempty
    cmp al, 13
    jbe .emit_trim_advance
    jmp .emit_nonempty
.emit_trim_advance:
    inc r11
    jmp .emit_trim
.emit_blank_line:
    lea r10, [r11 + 1]
    jmp .emit_line_loop

.emit_nonempty:
    cmp al, '/'
    je .emit_skip_comment
    lea rax, [r11 + 8]
    cmp rax, rdi
    ja .fail
    cmp dword [r11], 30303030h
    jne .emit_nonzero_row
    cmp dword [r11 + 4], 30303030h
    je .emit_counted_zero
.emit_nonzero_row:
    mov rax, [rbp - 40]
    cmp rax, [rbp - 32]
    jae .fail

    cvtsi2ss xmm0, r8
    movss xmm1, [rel const_four_f32]
    cvtsi2ss xmm2, qword [rbp - 80]
    divss xmm1, xmm2
    mulss xmm0, xmm1
    cvtsi2ss xmm3, r12
    mulss xmm3, [rel const_four_f32]
    addss xmm0, xmm3
    movss xmm4, xmm0
    mulss xmm4, [rel rows_per_beat_f32]
    cvtss2si ecx, xmm4
    cvtsi2ss xmm0, ecx
    divss xmm0, [rel rows_per_beat_f32]

    mov rdx, [rbp - 24]
    movss [rdx + rax * 4], xmm0
    cmp r14, 1
    jne .emit_general_time
    cmp qword [r13 + ASSP_BPM_SEGMENT_BEAT_MILLI], 0
    jne .emit_general_time
    call fixed_bpm_row_time_seconds4
    jmp .emit_time_done
.emit_general_time:
    call bpm_row_time_seconds4
.emit_time_done:
    mov rax, [rbp - 40]
    mov rdx, [rbp - 8]
    movss [rdx + rax * 4], xmm0

    cmp dword [rbp - 56], 0
    je .elapsed_ms
    movss xmm1, xmm0
    mulss xmm1, [rel const_thousand_f32]
    call floor_ss_to_i32_4
    mov [rbp - 52], eax
    mov dword [rbp - 56], 0
    jmp .store_ms

.elapsed_ms:
    movss xmm1, xmm0
    subss xmm1, [rbp - 48]
    mulss xmm1, [rel const_thousand_f32]
    call floor_ss_to_i32_4
    add eax, [rbp - 52]
    mov [rbp - 52], eax

.store_ms:
    movss [rbp - 48], xmm0
    mov rax, [rbp - 40]
    mov rdx, [rbp - 16]
    mov ecx, [rbp - 52]
    mov [rdx + rax * 4], ecx
    inc qword [rbp - 40]

.emit_counted_zero:
    inc r8
.emit_skip_line:
    cmp r11, [rbp - 72]
    jae .advance_measure
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .emit_skip_line
    mov r10, r11
    jmp .emit_line_loop
.emit_skip_comment:
    cmp r11, [rbp - 72]
    jae .advance_measure
    mov al, [r11]
    inc r11
    cmp al, 10
    jne .emit_skip_comment
    mov r10, r11
    jmp .emit_line_loop

.advance_measure:
    mov rdi, [rbp - 72]
    cmp rdi, rbx
    jae .success
    mov al, [rdi]
    lea rsi, [rdi + 1]
    cmp al, ';'
    je .success
    inc r12
    jmp .measure_loop

.empty:
    xor eax, eax
    jmp .done

.success:
    mov rax, [rbp - 40]
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 112
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; xmm0 = target beat f32, r13/r14 = BPM segment array/count,
; r15 = offset microseconds. Returns second f32 in xmm0.
bpm_row_time_seconds4:
    push r11
    mov r11d, ecx
    xor edx, edx
    xor eax, eax

    movss xmm2, [rel cost_one]
    test r14, r14
    jz .start_time
    cmp dword [rbp - 88], 0
    jne .initial_bpm_micro
    cvtsi2ss xmm2, qword [r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    divss xmm2, [rel const_thousand_f32]
    jmp .initial_bpm_scaled
.initial_bpm_micro:
    cvtsi2sd xmm2, qword [r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    divsd xmm2, [rel const_million_f64]
    cvtsd2ss xmm2, xmm2
.initial_bpm_scaled:
    divss xmm2, [rel const_sixty_f32]

.start_time:
    cvtsi2ss xmm0, r15
    divss xmm0, [rel const_million_f32]
    xorps xmm1, xmm1
    subss xmm1, xmm0
    movaps xmm0, xmm1

.change_loop:
    cmp rax, r14
    jae .marker
    mov r10, rax
    shl r10, 4
    cvtsi2ss xmm4, qword [r13 + r10 + ASSP_BPM_SEGMENT_BEAT_MILLI]
    divss xmm4, [rel const_thousand_f32]
    mulss xmm4, [rel rows_per_beat_f32]
    cvtss2si r9d, xmm4
    cmp r9d, r11d
    jg .marker

    mov ecx, r9d
    sub ecx, edx
    cvtsi2ss xmm3, ecx
    divss xmm3, [rel rows_per_beat_f32]
    divss xmm3, xmm2
    addss xmm0, xmm3

    cmp dword [rbp - 88], 0
    jne .change_bpm_micro
    cvtsi2ss xmm2, qword [r13 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    divss xmm2, [rel const_thousand_f32]
    jmp .change_bpm_scaled
.change_bpm_micro:
    cvtsi2sd xmm2, qword [r13 + r10 + ASSP_BPM_SEGMENT_BPM_MILLI]
    divsd xmm2, [rel const_million_f64]
    cvtsd2ss xmm2, xmm2
.change_bpm_scaled:
    divss xmm2, [rel const_sixty_f32]
    mov edx, r9d
    inc rax
    jmp .change_loop

.marker:
    mov ecx, r11d
    sub ecx, edx
    cvtsi2ss xmm3, ecx
    divss xmm3, [rel rows_per_beat_f32]
    divss xmm3, xmm2
    addss xmm0, xmm3
    pop r11
    ret

; xmm1 = value to floor. eax = floor(value).
floor_ss_to_i32_4:
    cvttss2si eax, xmm1
    cvtsi2ss xmm2, eax
    ucomiss xmm2, xmm1
    jbe .done
    dec eax
.done:
    ret

; ecx = quantized note row, r13 = one BPM segment at beat 0,
; r15 = offset microseconds. xmm0 = seconds matching rssp fixed timing.
fixed_bpm_row_time_seconds4:
    cvtsi2ss xmm0, ecx
    divss xmm0, [rel rows_per_beat_f32]
    mov rax, [r13 + ASSP_BPM_SEGMENT_BPM_MILLI]
    cmp dword [rbp - 88], 0
    jne .fixed_bpm_micro
    cvtsi2ss xmm1, rax
    divss xmm1, [rel const_thousand_f32]
    jmp .fixed_bpm_scaled
.fixed_bpm_micro:
    cvtsi2sd xmm1, rax
    divsd xmm1, [rel const_million_f64]
    cvtsd2ss xmm1, xmm1
.fixed_bpm_scaled:
    divss xmm1, [rel const_sixty_f32]
    divss xmm0, xmm1
    cvtsi2ss xmm2, r15
    divss xmm2, [rel const_million_f32]
    subss xmm0, xmm2
    ret

%macro prepare_hold_reset_current4 0
    mov qword [rsp + 16], 1
    mov eax, [rsp + 56]
    mov [rsp + 24], eax
    mov eax, [rsp + 60]
    mov [rsp + 28], eax
    mov eax, [rsp + 64]
    mov [rsp + 68], eax
    mov eax, [rsp + 32]
    mov [rsp + 36], eax
    mov dword [rsp + 32], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0
    mov eax, [rel hold_end_none]
    mov [rsp + 72], eax
    mov [rsp + 76], eax
    mov [rsp + 80], eax
    mov [rsp + 84], eax
%endmacro

%macro prepare_hold_live_col4 2
    test r10d, %2
    jz %%done
    movss xmm0, [rsp + 72 + (%1 * 4)]
    comiss xmm0, [rsp + 68]
    jbe %%done
    mov ecx, 1
%%done:
%endmacro

%macro prepare_hold_inherit_col4 2
    movss xmm0, [rsp + 88 + (%1 * 4)]
    comiss xmm0, [rsp + 68]
    jb %%done
    mov eax, [rsp + 72 + (%1 * 4)]
    cmp eax, [rel hold_end_none]
    jne %%done
    or r10d, %2
    movss [rsp + 72 + (%1 * 4)], xmm0
%%done:
%endmacro

%macro prepare_hold_flush_current4 0
    cmp qword [rsp + 16], 0
    je %%done
    mov rax, [rsp]
    cmp rax, [rsp + 320]
    jae .fail

    xor r10d, r10d
    prepare_hold_inherit_col4 0, 1
    prepare_hold_inherit_col4 1, 2
    prepare_hold_inherit_col4 2, 4
    prepare_hold_inherit_col4 3, 8

    mov rax, [rsp]
    mov ecx, [rsp + 40]
    mov [r15 + rax], cl
    mov ecx, [rsp + 44]
    mov [rbx + rax], cl
    mov ecx, [rsp + 48]
    mov [rdi + rax], cl
    mov [rbp + rax], r10b
    mov rdx, [rsp + 288]
    mov ecx, [rsp + 36]
    mov [rdx + rax], cl
    mov rdx, [rsp + 296]
    mov ecx, [rsp + 104]
    mov [rdx + rax], cl
    mov rdx, [rsp + 304]
    mov ecx, [rsp + 24]
    mov [rdx + rax * 4], ecx
    mov rdx, [rsp + 312]
    mov ecx, [rsp + 28]
    mov [rdx + rax * 4], ecx

    xor ecx, ecx
    prepare_hold_live_col4 0, 1
    prepare_hold_live_col4 1, 2
    prepare_hold_live_col4 2, 4
    prepare_hold_live_col4 3, 8
    mov [rsp + 104], ecx

    mov eax, [rsp + 72]
    mov [rsp + 88], eax
    mov eax, [rsp + 76]
    mov [rsp + 92], eax
    mov eax, [rsp + 80]
    mov [rsp + 96], eax
    mov eax, [rsp + 84]
    mov [rsp + 100], eax

    inc qword [rsp]
    mov qword [rsp + 16], 0
%%done:
%endmacro

%macro prepare_hold_ensure_current4 0
    cmp qword [rsp + 16], 0
    je %%reset
    mov eax, [rsp + 56]
    cmp eax, [rsp + 24]
    je %%done
    prepare_hold_flush_current4
%%reset:
    prepare_hold_reset_current4
%%done:
%endmacro

%macro prepare_hold_add_note4 2
    prepare_hold_ensure_current4
    test dword [rsp + 44], %1
    jnz %%seen
    inc dword [rsp + 40]
%%seen:
    or dword [rsp + 44], %1
%if %2
    or dword [rsp + 48], %1
%endif
%endmacro

%macro prepare_hold_add_head4 2
    mov rax, [rsp + 8]
    shl rax, 4
    mov rdx, [rsp + 240]
    mov ecx, [rdx + rax + (%2 * 4)]
    cmp ecx, [rel hold_end_none]
    je %%done
    mov [rsp + 108], ecx
    prepare_hold_add_note4 %1, 1
    mov ecx, [rsp + 108]
    mov [rsp + 72 + (%2 * 4)], ecx
%%done:
%endmacro

%macro prepare_hold_add_mine4 1
    mov eax, [rsp + 56]
    and eax, 7fffffffh
    cmp qword [rsp + 16], 0
    je %%pending
    mov ecx, [rsp + 56]
    cmp ecx, [rsp + 24]
    jne %%pending
    cmp qword [rsp], 0
    je %%pending
    test eax, eax
    jz %%clear_next
    or dword [rsp + 36], %1
    jmp %%done
%%clear_next:
    and dword [rsp + 36], ~%1
    jmp %%done
%%pending:
    test eax, eax
    jz %%clear_pending
    or dword [rsp + 32], %1
    jmp %%done
%%clear_pending:
    and dword [rsp + 32], ~%1
%%done:
%endmacro

%macro prepare_hold_process_char4 2
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%tap
    cmp al, 'L'
    je %%lift
    cmp al, 'M'
    je %%mine
    cmp al, '2'
    je %%head
    cmp al, '4'
    je %%head
    cmp al, '3'
    je %%done
    cmp al, 'F'
    je %%done
    jmp .fail
%%tap:
    prepare_hold_add_note4 %2, 1
    jmp %%done
%%lift:
    prepare_hold_add_note4 %2, 0
    jmp %%done
%%mine:
    prepare_hold_add_mine4 %2
    jmp %%done
%%head:
    prepare_hold_add_head4 %2, %1
%%done:
%endmacro

%macro prepare_hold_reset_current8 0
    mov qword [rsp + 16], 1
    mov eax, [rsp + 56]
    mov [rsp + 24], eax
    mov eax, [rsp + 60]
    mov [rsp + 28], eax
    mov eax, [rsp + 64]
    mov [rsp + 68], eax
    mov eax, [rsp + 32]
    mov [rsp + 36], eax
    mov dword [rsp + 32], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0
    mov eax, [rel hold_end_none]
    mov [rsp + 72], eax
    mov [rsp + 76], eax
    mov [rsp + 80], eax
    mov [rsp + 84], eax
    mov [rsp + 88], eax
    mov [rsp + 92], eax
    mov [rsp + 96], eax
    mov [rsp + 100], eax
%endmacro

%macro prepare_hold_live_col8 2
    test r10d, %2
    jz %%done
    movss xmm0, [rsp + 72 + (%1 * 4)]
    comiss xmm0, [rsp + 68]
    jbe %%done
    mov ecx, 1
%%done:
%endmacro

%macro prepare_hold_inherit_col8 2
    movss xmm0, [rsp + 104 + (%1 * 4)]
    comiss xmm0, [rsp + 68]
    jb %%done
    mov eax, [rsp + 72 + (%1 * 4)]
    cmp eax, [rel hold_end_none]
    jne %%done
    or r10d, %2
    movss [rsp + 72 + (%1 * 4)], xmm0
%%done:
%endmacro

%macro prepare_hold_flush_current8 0
    cmp qword [rsp + 16], 0
    je %%done
    mov rax, [rsp]
    cmp rax, [rsp + 352]
    jae .fail

    xor r10d, r10d
    prepare_hold_inherit_col8 0, 1
    prepare_hold_inherit_col8 1, 2
    prepare_hold_inherit_col8 2, 4
    prepare_hold_inherit_col8 3, 8
    prepare_hold_inherit_col8 4, 16
    prepare_hold_inherit_col8 5, 32
    prepare_hold_inherit_col8 6, 64
    prepare_hold_inherit_col8 7, 128

    mov rax, [rsp]
    mov ecx, [rsp + 40]
    mov [r15 + rax], cl
    mov ecx, [rsp + 44]
    mov [rbx + rax], cl
    mov ecx, [rsp + 48]
    mov [rdi + rax], cl
    mov [rbp + rax], r10b
    mov rdx, [rsp + 320]
    mov ecx, [rsp + 36]
    mov [rdx + rax], cl
    mov rdx, [rsp + 328]
    mov ecx, [rsp + 136]
    mov [rdx + rax], cl
    mov rdx, [rsp + 336]
    mov ecx, [rsp + 24]
    mov [rdx + rax * 4], ecx
    mov rdx, [rsp + 344]
    mov ecx, [rsp + 28]
    mov [rdx + rax * 4], ecx

    xor ecx, ecx
    prepare_hold_live_col8 0, 1
    prepare_hold_live_col8 1, 2
    prepare_hold_live_col8 2, 4
    prepare_hold_live_col8 3, 8
    prepare_hold_live_col8 4, 16
    prepare_hold_live_col8 5, 32
    prepare_hold_live_col8 6, 64
    prepare_hold_live_col8 7, 128
    mov [rsp + 136], ecx

    mov eax, [rsp + 72]
    mov [rsp + 104], eax
    mov eax, [rsp + 76]
    mov [rsp + 108], eax
    mov eax, [rsp + 80]
    mov [rsp + 112], eax
    mov eax, [rsp + 84]
    mov [rsp + 116], eax
    mov eax, [rsp + 88]
    mov [rsp + 120], eax
    mov eax, [rsp + 92]
    mov [rsp + 124], eax
    mov eax, [rsp + 96]
    mov [rsp + 128], eax
    mov eax, [rsp + 100]
    mov [rsp + 132], eax

    inc qword [rsp]
    mov qword [rsp + 16], 0
%%done:
%endmacro

%macro prepare_hold_ensure_current8 0
    cmp qword [rsp + 16], 0
    je %%reset
    mov eax, [rsp + 56]
    cmp eax, [rsp + 24]
    je %%done
    prepare_hold_flush_current8
%%reset:
    prepare_hold_reset_current8
%%done:
%endmacro

%macro prepare_hold_add_note8 2
    prepare_hold_ensure_current8
    test dword [rsp + 44], %1
    jnz %%seen
    inc dword [rsp + 40]
%%seen:
    or dword [rsp + 44], %1
%if %2
    or dword [rsp + 48], %1
%endif
%endmacro

%macro prepare_hold_add_head8 2
    mov rax, [rsp + 8]
    shl rax, 5
    mov rdx, [rsp + 272]
    mov ecx, [rdx + rax + (%2 * 4)]
    cmp ecx, [rel hold_end_none]
    je %%done
    mov [rsp + 140], ecx
    prepare_hold_add_note8 %1, 1
    mov ecx, [rsp + 140]
    mov [rsp + 72 + (%2 * 4)], ecx
%%done:
%endmacro

%macro prepare_hold_add_mine8 1
    mov eax, [rsp + 56]
    and eax, 7fffffffh
    cmp qword [rsp + 16], 0
    je %%pending
    mov ecx, [rsp + 56]
    cmp ecx, [rsp + 24]
    jne %%pending
    cmp qword [rsp], 0
    je %%pending
    test eax, eax
    jz %%clear_next
    or dword [rsp + 36], %1
    jmp %%done
%%clear_next:
    and dword [rsp + 36], ~%1
    jmp %%done
%%pending:
    test eax, eax
    jz %%clear_pending
    or dword [rsp + 32], %1
    jmp %%done
%%clear_pending:
    and dword [rsp + 32], ~%1
%%done:
%endmacro

%macro prepare_hold_process_char8 2
    mov al, [rsi + %1]
    cmp al, '0'
    je %%done
    cmp al, '1'
    je %%tap
    cmp al, 'L'
    je %%lift
    cmp al, 'M'
    je %%mine
    cmp al, '2'
    je %%head
    cmp al, '4'
    je %%head
    cmp al, '3'
    je %%done
    cmp al, 'F'
    je %%done
    jmp .fail
%%tap:
    prepare_hold_add_note8 %2, 1
    jmp %%done
%%lift:
    prepare_hold_add_note8 %2, 0
    jmp %%done
%%mine:
    prepare_hold_add_mine8 %2
    jmp %%done
%%head:
    prepare_hold_add_head8 %2, %1
%%done:
%endmacro

; rcx = minimized 4-panel note-data, rdx = byte length,
; r8 = input row seconds for each non-empty source row,
; r9 = input row milliseconds for each non-empty source row,
; stack arg 5 = input row beats for each non-empty source row,
; stack arg 6 = input hold end beats as row-major f32[rows][4],
; stack arg 7 = input source row count,
; stack arg 8 = out note counts,
; stack arg 9 = out tech masks,
; stack arg 10 = out note masks,
; stack arg 11 = out hold masks,
; stack arg 12 = out mine masks,
; stack arg 13 = out prev-row-live-hold flags,
; stack arg 14 = out row seconds,
; stack arg 15 = out row milliseconds,
; stack arg 16 = output row capacity.
; rax = prepared row count, or ASSP_NOT_FOUND.
assp_step_parity_prepare_hold_rows_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 128

    mov rsi, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov r15, [rsp + 256]
    mov rbx, [rsp + 264]
    mov rdi, [rsp + 272]
    mov rbp, [rsp + 280]

    test r12, r12
    jz .init
    test rsi, rsi
    jz .fail

.init:
    test r12, r12
    jnz .check_outputs
    xor eax, eax
    jmp .done

.check_outputs:
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    cmp qword [rsp + 232], 0
    je .fail
    cmp qword [rsp + 240], 0
    je .fail
    test r15, r15
    jz .fail
    test rbx, rbx
    jz .fail
    test rdi, rdi
    jz .fail
    test rbp, rbp
    jz .fail
    cmp qword [rsp + 288], 0
    je .fail
    cmp qword [rsp + 296], 0
    je .fail
    cmp qword [rsp + 304], 0
    je .fail
    cmp qword [rsp + 312], 0
    je .fail
    cmp qword [rsp + 320], 0
    je .fail

    lea r12, [rsi + r12]
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov dword [rsp + 32], 0
    mov dword [rsp + 36], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0
    mov eax, [rel hold_end_none]
    mov [rsp + 88], eax
    mov [rsp + 92], eax
    mov [rsp + 96], eax
    mov [rsp + 100], eax
    mov dword [rsp + 104], 0

.line_loop:
    cmp rsi, r12
    jae .success

.trim_left:
    cmp rsi, r12
    jae .success
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
    je .skip_to_next_line
    cmp al, ','
    je .measure_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 4]
    cmp rax, r12
    ja .success

    cmp dword [rsi], 30303030h
    je .row_done

    mov rax, [rsp + 8]
    cmp rax, [rsp + 248]
    jae .fail
    mov ecx, [r13 + rax * 4]
    mov [rsp + 56], ecx
    mov ecx, [r14 + rax * 4]
    mov [rsp + 60], ecx
    mov rdx, [rsp + 232]
    mov ecx, [rdx + rax * 4]
    mov [rsp + 64], ecx

    prepare_hold_process_char4 0, 1
    prepare_hold_process_char4 1, 2
    prepare_hold_process_char4 2, 4
    prepare_hold_process_char4 3, 8
    inc qword [rsp + 8]

.row_done:
    add rsi, 4
    jmp .skip_to_next_line

.measure_done:
    inc rsi
    jmp .line_loop

.skip_to_next_line:
    cmp rsi, r12
    jae .success
    mov al, [rsi]
    cmp al, ';'
    je .success
    inc rsi
    cmp al, 10
    je .line_loop
    cmp al, ','
    je .line_loop
    jmp .skip_to_next_line

.success:
    prepare_hold_flush_current4
    mov rax, [rsp]
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 128
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 8-panel note-data, rdx = byte length,
; r8 = input row seconds for each non-empty source row,
; r9 = input row milliseconds for each non-empty source row,
; stack arg 5 = input row beats for each non-empty source row,
; stack arg 6 = input hold end beats as row-major f32[rows][8],
; stack arg 7 = input source row count,
; stack arg 8 = out note counts,
; stack arg 9 = out tech masks,
; stack arg 10 = out note masks,
; stack arg 11 = out hold masks,
; stack arg 12 = out mine masks,
; stack arg 13 = out prev-row-live-hold flags,
; stack arg 14 = out row seconds,
; stack arg 15 = out row milliseconds,
; stack arg 16 = output row capacity.
; rax = prepared row count, or ASSP_NOT_FOUND.
assp_step_parity_prepare_hold_rows_8:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 160

    mov rsi, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov r15, [rsp + 288]
    mov rbx, [rsp + 296]
    mov rdi, [rsp + 304]
    mov rbp, [rsp + 312]

    test r12, r12
    jz .init
    test rsi, rsi
    jz .fail

.init:
    test r12, r12
    jnz .check_outputs
    xor eax, eax
    jmp .done

.check_outputs:
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    cmp qword [rsp + 264], 0
    je .fail
    cmp qword [rsp + 272], 0
    je .fail
    test r15, r15
    jz .fail
    test rbx, rbx
    jz .fail
    test rdi, rdi
    jz .fail
    test rbp, rbp
    jz .fail
    cmp qword [rsp + 320], 0
    je .fail
    cmp qword [rsp + 328], 0
    je .fail
    cmp qword [rsp + 336], 0
    je .fail
    cmp qword [rsp + 344], 0
    je .fail
    cmp qword [rsp + 352], 0
    je .fail

    lea r12, [rsi + r12]
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov dword [rsp + 32], 0
    mov dword [rsp + 36], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0
    mov eax, [rel hold_end_none]
    mov [rsp + 104], eax
    mov [rsp + 108], eax
    mov [rsp + 112], eax
    mov [rsp + 116], eax
    mov [rsp + 120], eax
    mov [rsp + 124], eax
    mov [rsp + 128], eax
    mov [rsp + 132], eax
    mov dword [rsp + 136], 0

.line_loop:
    cmp rsi, r12
    jae .success

.trim_left:
    cmp rsi, r12
    jae .success
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
    je .skip_to_next_line
    cmp al, ','
    je .measure_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 8]
    cmp rax, r12
    ja .success

    cmp dword [rsi], 30303030h
    jne .nonzero_row
    cmp dword [rsi + 4], 30303030h
    je .row_done

.nonzero_row:
    mov rax, [rsp + 8]
    cmp rax, [rsp + 280]
    jae .fail
    mov ecx, [r13 + rax * 4]
    mov [rsp + 56], ecx
    mov ecx, [r14 + rax * 4]
    mov [rsp + 60], ecx
    mov rdx, [rsp + 264]
    mov ecx, [rdx + rax * 4]
    mov [rsp + 64], ecx

    prepare_hold_process_char8 0, 1
    prepare_hold_process_char8 1, 2
    prepare_hold_process_char8 2, 4
    prepare_hold_process_char8 3, 8
    prepare_hold_process_char8 4, 16
    prepare_hold_process_char8 5, 32
    prepare_hold_process_char8 6, 64
    prepare_hold_process_char8 7, 128
    inc qword [rsp + 8]

.row_done:
    add rsi, 8
    jmp .skip_to_next_line

.measure_done:
    inc rsi
    jmp .line_loop

.skip_to_next_line:
    cmp rsi, r12
    jae .success
    mov al, [rsi]
    cmp al, ';'
    je .success
    inc rsi
    cmp al, 10
    je .line_loop
    cmp al, ','
    je .line_loop
    jmp .skip_to_next_line

.success:
    prepare_hold_flush_current8
    mov rax, [rsp]
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 160
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = minimized 4-panel note-data, rdx = byte length,
; r8 = input row seconds for emitted object rows,
; r9 = input row milliseconds for emitted object rows,
; stack arg 5 = input row time count,
; stack arg 6 = out note counts,
; stack arg 7 = out tech masks,
; stack arg 8 = out note masks,
; stack arg 9 = out hold masks,
; stack arg 10 = out mine masks,
; stack arg 11 = out prev-row-live-hold flags,
; stack arg 12 = out row seconds,
; stack arg 13 = out row milliseconds,
; stack arg 14 = output row capacity.
; rax = prepared row count, or ASSP_NOT_FOUND for unsupported rows/capacity.
assp_step_parity_prepare_tap_rows_4:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    push rbp
    sub rsp, 96

    mov rsi, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov r15, [rsp + 208]
    mov rbx, [rsp + 216]
    mov rdi, [rsp + 224]
    mov rbp, [rsp + 232]

    test r12, r12
    jz .init
    test rsi, rsi
    jz .fail

.init:
    test r12, r12
    jnz .check_outputs
    xor eax, eax
    jmp .done

.check_outputs:
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    test rbx, rbx
    jz .fail
    test rdi, rdi
    jz .fail
    test rbp, rbp
    jz .fail
    cmp qword [rsp + 240], 0
    je .fail
    cmp qword [rsp + 248], 0
    je .fail
    cmp qword [rsp + 256], 0
    je .fail
    cmp qword [rsp + 264], 0
    je .fail
    cmp qword [rsp + 272], 0
    je .fail

    lea r12, [rsi + r12]
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov dword [rsp + 32], 0
    mov dword [rsp + 36], 0
    mov dword [rsp + 40], 0
    mov dword [rsp + 44], 0
    mov dword [rsp + 48], 0

.line_loop:
    cmp rsi, r12
    jae .success

.trim_left:
    cmp rsi, r12
    jae .success
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
    je .skip_to_next_line
    cmp al, ','
    je .measure_done
    cmp al, ';'
    je .success

    lea rax, [rsi + 4]
    cmp rax, r12
    ja .success

    cmp dword [rsi], 30303030h
    je .row_done

    mov rax, [rsp + 8]
    cmp rax, [rsp + 200]
    jae .fail
    mov ecx, [r13 + rax * 4]
    mov [rsp + 56], ecx
    mov ecx, [r14 + rax * 4]
    mov [rsp + 60], ecx
    inc qword [rsp + 8]

    prepare_process_char4 0, 1
    prepare_process_char4 1, 2
    prepare_process_char4 2, 4
    prepare_process_char4 3, 8

.row_done:
    add rsi, 4
    jmp .skip_to_next_line

.measure_done:
    inc rsi
    jmp .line_loop

.skip_to_next_line:
    cmp rsi, r12
    jae .success
    mov al, [rsi]
    cmp al, ';'
    je .success
    inc rsi
    cmp al, 10
    je .line_loop
    cmp al, ','
    je .line_loop
    jmp .skip_to_next_line

.success:
    prepare_flush_current4
    mov rax, [rsp]
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    add rsp, 96
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

%ifdef ASSP_STANDALONE_EXE
section .bss
alignb 64
step_parity_fast_key_generation resd 1
alignb 64
step_parity_fast_key_entries resd 65536
%endif

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
step_parity_foot_masks db 0, 1, 2, 4, 8
const_four_f32 dd 4.0
const_thousand_f32 dd 1000.0
const_million_f32 dd 1000000.0
const_sixty_f32 dd 60.0
const_thousand_f64 dq 1000.0
const_million_f64 dq 1000000.0
rows_per_beat_f32 dd 48.0
hold_end_none dd -1.0
; 8-panel placements generated from the same foot order as the runtime API.
step_parity_perm8_counts:
    db 1, 2, 2, 6, 2, 6, 2, 8, 2, 2, 6, 8, 6, 8, 8, 16
    db 2, 2, 2, 4, 2, 4, 0, 0, 6, 4, 8, 8, 8, 8, 0, 0
    db 2, 2, 2, 4, 2, 4, 0, 0, 2, 0, 4, 0, 4, 0, 0, 0
    db 6, 4, 4, 8, 4, 8, 0, 0, 8, 0, 8, 0, 8, 0, 0, 0
    db 2, 2, 2, 4, 2, 4, 0, 0, 2, 0, 4, 0, 4, 0, 0, 0
    db 6, 4, 4, 8, 4, 8, 0, 0, 8, 0, 8, 0, 8, 0, 0, 0
    db 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 2, 2, 2, 4, 2, 4, 0, 0, 2, 0, 4, 0, 4, 0, 0, 0
    db 2, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0
    db 6, 4, 4, 8, 4, 8, 0, 0, 4, 0, 8, 0, 8, 0, 0, 0
    db 8, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0
    db 6, 4, 4, 8, 4, 8, 0, 0, 4, 0, 8, 0, 8, 0, 0, 0
    db 8, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0
    db 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
step_parity_perm8_offsets:
    dw 0, 1, 3, 5, 11, 13, 19, 21
    dw 29, 31, 33, 39, 47, 53, 61, 69
    dw 85, 87, 89, 91, 95, 97, 101, 101
    dw 101, 107, 111, 119, 127, 135, 143, 143
    dw 143, 145, 147, 149, 153, 155, 159, 159
    dw 159, 161, 161, 165, 165, 169, 169, 169
    dw 169, 175, 179, 183, 191, 195, 203, 203
    dw 203, 211, 211, 219, 219, 227, 227, 227
    dw 227, 229, 231, 233, 237, 239, 243, 243
    dw 243, 245, 245, 249, 249, 253, 253, 253
    dw 253, 259, 263, 267, 275, 279, 287, 287
    dw 287, 295, 295, 303, 303, 311, 311, 311
    dw 311, 313, 313, 313, 313, 313, 313, 313
    dw 313, 313, 313, 313, 313, 313, 313, 313
    dw 313, 321, 321, 321, 321, 321, 321, 321
    dw 321, 321, 321, 321, 321, 321, 321, 321
    dw 321, 323, 325, 327, 331, 333, 337, 337
    dw 337, 339, 339, 343, 343, 347, 347, 347
    dw 347, 349, 349, 349, 349, 349, 349, 349
    dw 349, 353, 353, 353, 353, 353, 353, 353
    dw 353, 359, 363, 367, 375, 379, 387, 387
    dw 387, 391, 391, 399, 399, 407, 407, 407
    dw 407, 415, 415, 415, 415, 415, 415, 415
    dw 415, 423, 423, 423, 423, 423, 423, 423
    dw 423, 429, 433, 437, 445, 449, 457, 457
    dw 457, 461, 461, 469, 469, 477, 477, 477
    dw 477, 485, 485, 485, 485, 485, 485, 485
    dw 485, 493, 493, 493, 493, 493, 493, 493
    dw 493, 501, 501, 501, 501, 501, 501, 501
    dw 501, 501, 501, 501, 501, 501, 501, 501
    dw 501, 517, 517, 517, 517, 517, 517, 517
    dw 517, 517, 517, 517, 517, 517, 517, 517
step_parity_perm8_values:
    dq 00000000000000000h
    dq 00000000000000001h
    dq 00000000000000003h
    dq 00000000000000100h
    dq 00000000000000300h
    dq 00000000000000201h
    dq 00000000000000301h
    dq 00000000000000102h
    dq 00000000000000103h
    dq 00000000000000403h
    dq 00000000000000304h
    dq 00000000000010000h
    dq 00000000000030000h
    dq 00000000000020001h
    dq 00000000000030001h
    dq 00000000000010002h
    dq 00000000000010003h
    dq 00000000000040003h
    dq 00000000000030004h
    dq 00000000000030100h
    dq 00000000000010300h
    dq 00000000000030201h
    dq 00000000000020301h
    dq 00000000000030102h
    dq 00000000000010302h
    dq 00000000000040103h
    dq 00000000000010403h
    dq 00000000000030104h
    dq 00000000000010304h
    dq 00000000001000000h
    dq 00000000003000000h
    dq 00000000003000001h
    dq 00000000001000003h
    dq 00000000002000100h
    dq 00000000003000100h
    dq 00000000001000200h
    dq 00000000001000300h
    dq 00000000004000300h
    dq 00000000003000400h
    dq 00000000003000201h
    dq 00000000004000301h
    dq 00000000003000401h
    dq 00000000003000102h
    dq 00000000002000103h
    dq 00000000001000203h
    dq 00000000001000403h
    dq 00000000001000304h
    dq 00000000002010000h
    dq 00000000003010000h
    dq 00000000001020000h
    dq 00000000001030000h
    dq 00000000004030000h
    dq 00000000003040000h
    dq 00000000003020001h
    dq 00000000004030001h
    dq 00000000003040001h
    dq 00000000003010002h
    dq 00000000002010003h
    dq 00000000001020003h
    dq 00000000001040003h
    dq 00000000001030004h
    dq 00000000002030100h
    dq 00000000004030100h
    dq 00000000003040100h
    dq 00000000001030200h
    dq 00000000002010300h
    dq 00000000004010300h
    dq 00000000001020300h
    dq 00000000003010400h
    dq 00000000004030201h
    dq 00000000003040201h
    dq 00000000004020301h
    dq 00000000003020401h
    dq 00000000004030102h
    dq 00000000003040102h
    dq 00000000004010302h
    dq 00000000003010402h
    dq 00000000002040103h
    dq 00000000001040203h
    dq 00000000002010403h
    dq 00000000001020403h
    dq 00000000002030104h
    dq 00000000001030204h
    dq 00000000002010304h
    dq 00000000001020304h
    dq 00000000100000000h
    dq 00000000300000000h
    dq 00000000300000001h
    dq 00000000100000003h
    dq 00000000300000100h
    dq 00000000100000300h
    dq 00000000300000201h
    dq 00000000300000102h
    dq 00000000100000403h
    dq 00000000100000304h
    dq 00000000300010000h
    dq 00000000100030000h
    dq 00000000300020001h
    dq 00000000300010002h
    dq 00000000100040003h
    dq 00000000100030004h
    dq 00000000201000000h
    dq 00000000301000000h
    dq 00000000102000000h
    dq 00000000103000000h
    dq 00000000403000000h
    dq 00000000304000000h
    dq 00000000403000001h
    dq 00000000304000001h
    dq 00000000201000003h
    dq 00000000102000003h
    dq 00000000302000100h
    dq 00000000403000100h
    dq 00000000304000100h
    dq 00000000301000200h
    dq 00000000201000300h
    dq 00000000102000300h
    dq 00000000104000300h
    dq 00000000103000400h
    dq 00000000403000201h
    dq 00000000304000201h
    dq 00000000403000102h
    dq 00000000304000102h
    dq 00000000201000403h
    dq 00000000102000403h
    dq 00000000201000304h
    dq 00000000102000304h
    dq 00000000302010000h
    dq 00000000403010000h
    dq 00000000304010000h
    dq 00000000301020000h
    dq 00000000201030000h
    dq 00000000102030000h
    dq 00000000104030000h
    dq 00000000103040000h
    dq 00000000403020001h
    dq 00000000304020001h
    dq 00000000403010002h
    dq 00000000304010002h
    dq 00000000201040003h
    dq 00000000102040003h
    dq 00000000201030004h
    dq 00000000102030004h
    dq 00000010000000000h
    dq 00000030000000000h
    dq 00000030000000001h
    dq 00000010000000003h
    dq 00000030000000100h
    dq 00000010000000300h
    dq 00000030000000201h
    dq 00000030000000102h
    dq 00000010000000403h
    dq 00000010000000304h
    dq 00000030000010000h
    dq 00000010000030000h
    dq 00000030000020001h
    dq 00000030000010002h
    dq 00000010000040003h
    dq 00000010000030004h
    dq 00000030001000000h
    dq 00000010003000000h
    dq 00000030002000100h
    dq 00000030001000200h
    dq 00000010004000300h
    dq 00000010003000400h
    dq 00000030002010000h
    dq 00000030001020000h
    dq 00000010004030000h
    dq 00000010003040000h
    dq 00000020100000000h
    dq 00000030100000000h
    dq 00000010200000000h
    dq 00000010300000000h
    dq 00000040300000000h
    dq 00000030400000000h
    dq 00000040300000001h
    dq 00000030400000001h
    dq 00000020100000003h
    dq 00000010200000003h
    dq 00000040300000100h
    dq 00000030400000100h
    dq 00000020100000300h
    dq 00000010200000300h
    dq 00000040300000201h
    dq 00000030400000201h
    dq 00000040300000102h
    dq 00000030400000102h
    dq 00000020100000403h
    dq 00000010200000403h
    dq 00000020100000304h
    dq 00000010200000304h
    dq 00000040300010000h
    dq 00000030400010000h
    dq 00000020100030000h
    dq 00000010200030000h
    dq 00000040300020001h
    dq 00000030400020001h
    dq 00000040300010002h
    dq 00000030400010002h
    dq 00000020100040003h
    dq 00000010200040003h
    dq 00000020100030004h
    dq 00000010200030004h
    dq 00000030201000000h
    dq 00000040301000000h
    dq 00000030401000000h
    dq 00000030102000000h
    dq 00000020103000000h
    dq 00000010203000000h
    dq 00000010403000000h
    dq 00000010304000000h
    dq 00000040302000100h
    dq 00000030402000100h
    dq 00000040301000200h
    dq 00000030401000200h
    dq 00000020104000300h
    dq 00000010204000300h
    dq 00000020103000400h
    dq 00000010203000400h
    dq 00000040302010000h
    dq 00000030402010000h
    dq 00000040301020000h
    dq 00000030401020000h
    dq 00000020104030000h
    dq 00000010204030000h
    dq 00000020103040000h
    dq 00000010203040000h
    dq 00001000000000000h
    dq 00003000000000000h
    dq 00003000000000001h
    dq 00001000000000003h
    dq 00003000000000100h
    dq 00001000000000300h
    dq 00003000000000201h
    dq 00003000000000102h
    dq 00001000000000403h
    dq 00001000000000304h
    dq 00003000000010000h
    dq 00001000000030000h
    dq 00003000000020001h
    dq 00003000000010002h
    dq 00001000000040003h
    dq 00001000000030004h
    dq 00003000001000000h
    dq 00001000003000000h
    dq 00003000002000100h
    dq 00003000001000200h
    dq 00001000004000300h
    dq 00001000003000400h
    dq 00003000002010000h
    dq 00003000001020000h
    dq 00001000004030000h
    dq 00001000003040000h
    dq 00002000100000000h
    dq 00003000100000000h
    dq 00001000200000000h
    dq 00001000300000000h
    dq 00004000300000000h
    dq 00003000400000000h
    dq 00004000300000001h
    dq 00003000400000001h
    dq 00002000100000003h
    dq 00001000200000003h
    dq 00004000300000100h
    dq 00003000400000100h
    dq 00002000100000300h
    dq 00001000200000300h
    dq 00004000300000201h
    dq 00003000400000201h
    dq 00004000300000102h
    dq 00003000400000102h
    dq 00002000100000403h
    dq 00001000200000403h
    dq 00002000100000304h
    dq 00001000200000304h
    dq 00004000300010000h
    dq 00003000400010000h
    dq 00002000100030000h
    dq 00001000200030000h
    dq 00004000300020001h
    dq 00003000400020001h
    dq 00004000300010002h
    dq 00003000400010002h
    dq 00002000100040003h
    dq 00001000200040003h
    dq 00002000100030004h
    dq 00001000200030004h
    dq 00003000201000000h
    dq 00004000301000000h
    dq 00003000401000000h
    dq 00003000102000000h
    dq 00002000103000000h
    dq 00001000203000000h
    dq 00001000403000000h
    dq 00001000304000000h
    dq 00004000302000100h
    dq 00003000402000100h
    dq 00004000301000200h
    dq 00003000401000200h
    dq 00002000104000300h
    dq 00001000204000300h
    dq 00002000103000400h
    dq 00001000203000400h
    dq 00004000302010000h
    dq 00003000402010000h
    dq 00004000301020000h
    dq 00003000401020000h
    dq 00002000104030000h
    dq 00001000204030000h
    dq 00002000103040000h
    dq 00001000203040000h
    dq 00003010000000000h
    dq 00001030000000000h
    dq 00003020100000000h
    dq 00002030100000000h
    dq 00003010200000000h
    dq 00001030200000000h
    dq 00004010300000000h
    dq 00001040300000000h
    dq 00003010400000000h
    dq 00001030400000000h
    dq 00100000000000000h
    dq 00300000000000000h
    dq 00300000000000001h
    dq 00100000000000003h
    dq 00300000000000100h
    dq 00100000000000300h
    dq 00300000000000201h
    dq 00300000000000102h
    dq 00100000000000403h
    dq 00100000000000304h
    dq 00300000000010000h
    dq 00100000000030000h
    dq 00300000000020001h
    dq 00300000000010002h
    dq 00100000000040003h
    dq 00100000000030004h
    dq 00300000001000000h
    dq 00100000003000000h
    dq 00300000002000100h
    dq 00300000001000200h
    dq 00100000004000300h
    dq 00100000003000400h
    dq 00300000002010000h
    dq 00300000001020000h
    dq 00100000004030000h
    dq 00100000003040000h
    dq 00300000100000000h
    dq 00100000300000000h
    dq 00300000201000000h
    dq 00300000102000000h
    dq 00100000403000000h
    dq 00100000304000000h
    dq 00200010000000000h
    dq 00300010000000000h
    dq 00100020000000000h
    dq 00100030000000000h
    dq 00400030000000000h
    dq 00300040000000000h
    dq 00400030000000001h
    dq 00300040000000001h
    dq 00200010000000003h
    dq 00100020000000003h
    dq 00400030000000100h
    dq 00300040000000100h
    dq 00200010000000300h
    dq 00100020000000300h
    dq 00400030000000201h
    dq 00300040000000201h
    dq 00400030000000102h
    dq 00300040000000102h
    dq 00200010000000403h
    dq 00100020000000403h
    dq 00200010000000304h
    dq 00100020000000304h
    dq 00400030000010000h
    dq 00300040000010000h
    dq 00200010000030000h
    dq 00100020000030000h
    dq 00400030000020001h
    dq 00300040000020001h
    dq 00400030000010002h
    dq 00300040000010002h
    dq 00200010000040003h
    dq 00100020000040003h
    dq 00200010000030004h
    dq 00100020000030004h
    dq 00400030001000000h
    dq 00300040001000000h
    dq 00200010003000000h
    dq 00100020003000000h
    dq 00400030002000100h
    dq 00300040002000100h
    dq 00400030001000200h
    dq 00300040001000200h
    dq 00200010004000300h
    dq 00100020004000300h
    dq 00200010003000400h
    dq 00100020003000400h
    dq 00400030002010000h
    dq 00300040002010000h
    dq 00400030001020000h
    dq 00300040001020000h
    dq 00200010004030000h
    dq 00100020004030000h
    dq 00200010003040000h
    dq 00100020003040000h
    dq 00300020100000000h
    dq 00400030100000000h
    dq 00300040100000000h
    dq 00300010200000000h
    dq 00200010300000000h
    dq 00100020300000000h
    dq 00100040300000000h
    dq 00100030400000000h
    dq 00400030201000000h
    dq 00300040201000000h
    dq 00400030102000000h
    dq 00300040102000000h
    dq 00200010403000000h
    dq 00100020403000000h
    dq 00200010304000000h
    dq 00100020304000000h
    dq 00201000000000000h
    dq 00301000000000000h
    dq 00102000000000000h
    dq 00103000000000000h
    dq 00403000000000000h
    dq 00304000000000000h
    dq 00403000000000001h
    dq 00304000000000001h
    dq 00201000000000003h
    dq 00102000000000003h
    dq 00403000000000100h
    dq 00304000000000100h
    dq 00201000000000300h
    dq 00102000000000300h
    dq 00403000000000201h
    dq 00304000000000201h
    dq 00403000000000102h
    dq 00304000000000102h
    dq 00201000000000403h
    dq 00102000000000403h
    dq 00201000000000304h
    dq 00102000000000304h
    dq 00403000000010000h
    dq 00304000000010000h
    dq 00201000000030000h
    dq 00102000000030000h
    dq 00403000000020001h
    dq 00304000000020001h
    dq 00403000000010002h
    dq 00304000000010002h
    dq 00201000000040003h
    dq 00102000000040003h
    dq 00201000000030004h
    dq 00102000000030004h
    dq 00403000001000000h
    dq 00304000001000000h
    dq 00201000003000000h
    dq 00102000003000000h
    dq 00403000002000100h
    dq 00304000002000100h
    dq 00403000001000200h
    dq 00304000001000200h
    dq 00201000004000300h
    dq 00102000004000300h
    dq 00201000003000400h
    dq 00102000003000400h
    dq 00403000002010000h
    dq 00304000002010000h
    dq 00403000001020000h
    dq 00304000001020000h
    dq 00201000004030000h
    dq 00102000004030000h
    dq 00201000003040000h
    dq 00102000003040000h
    dq 00302000100000000h
    dq 00403000100000000h
    dq 00304000100000000h
    dq 00301000200000000h
    dq 00201000300000000h
    dq 00102000300000000h
    dq 00104000300000000h
    dq 00103000400000000h
    dq 00403000201000000h
    dq 00304000201000000h
    dq 00403000102000000h
    dq 00304000102000000h
    dq 00201000403000000h
    dq 00102000403000000h
    dq 00201000304000000h
    dq 00102000304000000h
    dq 00203010000000000h
    dq 00403010000000000h
    dq 00304010000000000h
    dq 00103020000000000h
    dq 00201030000000000h
    dq 00401030000000000h
    dq 00102030000000000h
    dq 00301040000000000h
    dq 00403020100000000h
    dq 00304020100000000h
    dq 00402030100000000h
    dq 00302040100000000h
    dq 00403010200000000h
    dq 00304010200000000h
    dq 00401030200000000h
    dq 00301040200000000h
    dq 00204010300000000h
    dq 00104020300000000h
    dq 00201040300000000h
    dq 00102040300000000h
    dq 00203010400000000h
    dq 00103020400000000h
    dq 00201030400000000h
    dq 00102030400000000h
step_parity_perm4_counts:
    db 1, 2, 2, 6, 2, 6, 2, 8, 2, 2, 6, 8, 6, 8, 8, 16
step_parity_perm4_offsets:
    db 0, 1, 3, 5, 11, 13, 19, 21, 29, 31, 33, 39, 47, 53, 61, 69
step_parity_perm4_values:
    dd 000000000h
    dd 000000001h, 000000003h
    dd 000000100h, 000000300h
    dd 000000201h, 000000301h, 000000102h, 000000103h, 000000403h, 000000304h
    dd 000010000h, 000030000h
    dd 000020001h, 000030001h, 000010002h, 000010003h, 000040003h, 000030004h
    dd 000030100h, 000010300h
    dd 000030201h, 000020301h, 000030102h, 000010302h, 000040103h, 000010403h, 000030104h, 000010304h
    dd 001000000h, 003000000h
    dd 003000001h, 001000003h
    dd 002000100h, 003000100h, 001000200h, 001000300h, 004000300h, 003000400h
    dd 003000201h, 004000301h, 003000401h, 003000102h, 002000103h, 001000203h, 001000403h, 001000304h
    dd 002010000h, 003010000h, 001020000h, 001030000h, 004030000h, 003040000h
    dd 003020001h, 004030001h, 003040001h, 003010002h, 002010003h, 001020003h, 001040003h, 001030004h
    dd 002030100h, 004030100h, 003040100h, 001030200h, 002010300h, 004010300h, 001020300h, 003010400h
    dd 004030201h, 003040201h, 004020301h, 003020401h, 004030102h, 003040102h, 004010302h, 003010402h
    dd 002040103h, 001040203h, 002010403h, 001020403h, 002030104h, 001030204h, 002010304h, 001020304h
dance_single_distances4:
    dd 0.0, 1.4142135623730951, 1.4142135623730951, 2.0
    dd 1.4142135623730951, 0.0, 2.0, 1.4142135623730951
    dd 1.4142135623730951, 2.0, 0.0, 1.4142135623730951
    dd 2.0, 1.4142135623730951, 1.4142135623730951, 0.0
dance_double_distances8:
    dd 0.0, 1.4142135623731, 1.4142135623731, 2.0, 3.0, 4.12310562561766, 4.12310562561766, 5.0
    dd 1.4142135623731, 0.0, 2.0, 1.4142135623731, 2.23606797749979, 3.0, 3.60555127546399, 4.12310562561766
    dd 1.4142135623731, 2.0, 0.0, 1.4142135623731, 2.23606797749979, 3.60555127546399, 3.0, 4.12310562561766
    dd 2.0, 1.4142135623731, 1.4142135623731, 0.0, 1.0, 2.23606797749979, 2.23606797749979, 3.0
    dd 3.0, 2.23606797749979, 2.23606797749979, 1.0, 0.0, 1.4142135623731, 1.4142135623731, 2.0
    dd 4.12310562561766, 3.0, 3.60555127546399, 2.23606797749979, 1.4142135623731, 0.0, 2.0, 1.4142135623731
    dd 4.12310562561766, 3.60555127546399, 3.0, 2.23606797749979, 1.4142135623731, 2.0, 0.0, 1.4142135623731
    dd 5.0, 4.12310562561766, 4.12310562561766, 3.0, 2.0, 1.4142135623731, 1.4142135623731, 0.0
dance_single_col_y2 db 2, 0, 4, 2
dance_double_col_y2 db 2, 0, 4, 2, 2, 0, 4, 2
step_parity_col_norm:
    db 0, 1, 2, 3
    times 252 db 4
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
dance_double_pair_avg_x2:
    db 0, 1, 1, 2, 3, 4, 4, 5, 0
    db 1, 2, 2, 3, 4, 5, 5, 6, 2
    db 1, 2, 2, 3, 4, 5, 5, 6, 2
    db 2, 3, 3, 4, 5, 6, 6, 7, 4
    db 3, 4, 4, 5, 6, 7, 7, 8, 6
    db 4, 5, 5, 6, 7, 8, 8, 9, 8
    db 4, 5, 5, 6, 7, 8, 8, 9, 8
    db 5, 6, 6, 7, 8, 9, 9, 10, 10
    db 0, 2, 2, 4, 6, 8, 8, 10, 0
dance_double_pair_avg_y2:
    db 2, 1, 3, 2, 2, 1, 3, 2, 2
    db 1, 0, 2, 1, 1, 0, 2, 1, 0
    db 3, 2, 4, 3, 3, 2, 4, 3, 4
    db 2, 1, 3, 2, 2, 1, 3, 2, 2
    db 2, 1, 3, 2, 2, 1, 3, 2, 2
    db 1, 0, 2, 1, 1, 0, 2, 1, 0
    db 3, 2, 4, 3, 3, 2, 4, 3, 4
    db 2, 1, 3, 2, 2, 1, 3, 2, 2
    db 2, 0, 4, 2, 2, 0, 4, 2, 0
dance_double_facing_x4:
    dd 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 04103f366h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 04103f366h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 042c80000h, 04103f366h, 04103f366h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 042c80000h, 0423322edh, 0423322edh, 042c80000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 042a0c900h, 042c80000h, 041d4e552h, 0423322edh, 04103f366h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 042a0c900h, 041d4e552h, 042c80000h, 0423322edh, 04103f366h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 042c80000h, 042a0c900h, 042a0c900h, 042c80000h, 042c80000h, 04103f366h, 04103f366h, 000000000h, 000000000h
    dd 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
dance_double_facing_y4:
    dd 000000000h, 04103f366h, 000000000h, 000000000h, 000000000h, 03b73b469h, 000000000h, 000000000h, 000000000h
    dd 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 04103f366h, 042c80000h, 000000000h, 04103f366h, 03e9bf284h, 03fb7d5f1h, 000000000h, 03b73b469h, 000000000h
    dd 000000000h, 04103f366h, 000000000h, 000000000h, 000000000h, 03e9bf284h, 000000000h, 000000000h, 000000000h
    dd 000000000h, 03e9bf284h, 000000000h, 000000000h, 000000000h, 04103f366h, 000000000h, 000000000h, 000000000h
    dd 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
    dd 03b73b469h, 03fb7d5f1h, 000000000h, 03e9bf284h, 04103f366h, 042c80000h, 000000000h, 04103f366h, 000000000h
    dd 000000000h, 03b73b469h, 000000000h, 000000000h, 000000000h, 04103f366h, 000000000h, 000000000h, 000000000h
    dd 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h, 000000000h
