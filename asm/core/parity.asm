default rel
%include "assp.inc"

global assp_step_parity_permutations_4
global assp_step_parity_result_state_no_holds_4
global assp_step_parity_result_state_holds_4

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
