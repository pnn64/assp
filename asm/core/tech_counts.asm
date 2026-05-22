default rel
%include "assp.inc"

global assp_calculate_step_tech_counts_from_placements_4
global assp_calculate_step_tech_counts_from_placements_seconds_4
global assp_calculate_step_tech_counts_from_placements_8
global assp_calculate_step_tech_counts_from_placements_seconds_8

section .text

; rcx = tech masks, rdx = note counts, r8 = row times in milliseconds,
; r9 = row placements as 4 bytes per row, stack arg 5 = row count,
; stack arg 6 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
assp_calculate_step_tech_counts_from_placements_4:
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
    mov rdi, [rsp + 104]
    mov rbx, [rsp + 112]
    sub rsp, 40
    mov rbp, rsp

    test rbx, rbx
    jz .fail

    xor eax, eax
    mov [rbx], rax
    mov [rbx + 8], rax
    mov [rbx + 16], rax
    mov [rbx + 24], rax

    test rdi, rdi
    jz .success
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp rdi, 2
    jb .success

    movzx ecx, byte [r12]
    mov rdx, r15
    lea r8, [rbp]
    call fill_hit_positions_4

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 4]
    lea r8, [rbp + 8]
    call fill_hit_positions_4

    mov eax, [r14 + rsi * 4]
    sub eax, [r14 + rsi * 4 - 4]
    mov r11d, eax

    call count_jacks_doublesteps_4
    call count_brackets_placements_4
    call count_switches_4
    call count_crossovers_4

    mov rax, [rbp]
    mov [rbp + 16], rax
    mov rax, [rbp + 8]
    mov [rbp], rax

    inc rsi
    cmp rsi, rdi
    jb .row_loop

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
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

; rcx = tech masks, rdx = note counts, r8 = row times in seconds f32,
; r9 = row placements as 4 bytes per row, stack arg 5 = row count,
; stack arg 6 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
assp_calculate_step_tech_counts_from_placements_seconds_4:
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
    mov rdi, [rsp + 104]
    mov rbx, [rsp + 112]
    sub rsp, 40
    mov rbp, rsp

    test rbx, rbx
    jz .fail

    xor eax, eax
    mov [rbx], rax
    mov [rbx + 8], rax
    mov [rbx + 16], rax
    mov [rbx + 24], rax

    test rdi, rdi
    jz .success
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp rdi, 2
    jb .success

    movzx ecx, byte [r12]
    mov rdx, r15
    lea r8, [rbp]
    call fill_hit_positions_4

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 4]
    lea r8, [rbp + 8]
    call fill_hit_positions_4

    movss xmm0, [r14 + rsi * 4]
    subss xmm0, [r14 + rsi * 4 - 4]
    movss [rbp + 24], xmm0

    call count_jacks_doublesteps_seconds_4
    call count_brackets_placements_4
    call count_switches_seconds_4
    call count_crossovers_4

    mov rax, [rbp]
    mov [rbp + 16], rax
    mov rax, [rbp + 8]
    mov [rbp], rax

    inc rsi
    cmp rsi, rdi
    jb .row_loop

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
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

; ecx = row mask, rdx = placement row, r8 = output positions[5].
fill_hit_positions_4:
    mov dword [r8], 0ffffffffh
    mov byte [r8 + 4], 0ffh

    test cl, 1
    jz .col1
    movzx eax, byte [rdx]
    test eax, eax
    jz .col1
    cmp eax, 4
    ja .col1
    mov byte [r8 + rax], 0

.col1:
    test cl, 2
    jz .col2
    movzx eax, byte [rdx + 1]
    test eax, eax
    jz .col2
    cmp eax, 4
    ja .col2
    mov byte [r8 + rax], 1

.col2:
    test cl, 4
    jz .col3
    movzx eax, byte [rdx + 2]
    test eax, eax
    jz .col3
    cmp eax, 4
    ja .col3
    mov byte [r8 + rax], 2

.col3:
    test cl, 8
    jz .done
    movzx eax, byte [rdx + 3]
    test eax, eax
    jz .done
    cmp eax, 4
    ja .done
    mov byte [r8 + rax], 3

.done:
    ret

count_jacks_doublesteps_4:
    cmp byte [r13 + rsi], 1
    jne .done
    cmp byte [r13 + rsi - 1], 1
    jne .done

    mov ecx, 1
.foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je .next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je .next
    cmp al, dl
    jne .maybe_doublestep
    cmp r11d, 176
    jge .next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp .next

.maybe_doublestep:
    cmp r11d, 235
    jge .next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

.next:
    inc ecx
    cmp ecx, 4
    jbe .foot_loop

.done:
    ret

count_jacks_doublesteps_seconds_4:
    cmp byte [r13 + rsi], 1
    jne .done
    cmp byte [r13 + rsi - 1], 1
    jne .done

    mov ecx, 1
.foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je .next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je .next
    cmp al, dl
    jne .maybe_doublestep
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel jack_cutoff_seconds]
    jae .next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp .next

.maybe_doublestep:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel doublestep_cutoff_seconds]
    jae .next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

.next:
    inc ecx
    cmp ecx, 4
    jbe .foot_loop

.done:
    ret

count_brackets_placements_4:
    cmp byte [r13 + rsi], 2
    jb .done
    cmp byte [rbp + 8 + 1], 0ffh
    je .right
    cmp byte [rbp + 8 + 2], 0ffh
    je .right
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

.right:
    cmp byte [rbp + 8 + 3], 0ffh
    je .done
    cmp byte [rbp + 8 + 4], 0ffh
    je .done
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

.done:
    ret

count_switches_4:
    cmp r11d, 300
    jge .done

    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .done

    xor r11d, r11d
    lea r8, [r15 + rsi * 4]
    lea r9, [r8 - 4]

.col_loop:
    bt r10d, r11d
    jnc .next
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    call is_footswitch_4
    test eax, eax
    jz .next

    cmp r11d, 1
    je .down
    cmp r11d, 2
    je .up
    inc dword [rbx + ASSP_TECH_COUNTS_SIDESWITCHES]
    jmp .next

.down:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp .next

.up:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]

.next:
    inc r11d
    cmp r11d, 4
    jb .col_loop

.done:
    ret

count_switches_seconds_4:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel footswitch_cutoff_seconds]
    jae .done

    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .done

    xor r11d, r11d
    lea r8, [r15 + rsi * 4]
    lea r9, [r8 - 4]

.col_loop:
    bt r10d, r11d
    jnc .next
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    call is_footswitch_4
    test eax, eax
    jz .next

    cmp r11d, 1
    je .down
    cmp r11d, 2
    je .up
    inc dword [rbx + ASSP_TECH_COUNTS_SIDESWITCHES]
    jmp .next

.down:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp .next

.up:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]

.next:
    inc r11d
    cmp r11d, 4
    jb .col_loop

.done:
    ret

; al = previous foot, dl = current foot, eax = boolean.
is_footswitch_4:
    test al, al
    jz .no
    test dl, dl
    jz .no
    cmp al, dl
    je .no
    movzx ecx, al
    lea rax, [rel other_foot_part]
    movzx ecx, byte [rax + rcx]
    cmp cl, dl
    je .no
    mov eax, ASSP_TRUE
    ret

.no:
    xor eax, eax
    ret

count_crossovers_4:
    cmp byte [rbp + 8 + 3], 0ffh
    je .left_cross
    cmp byte [rbp + 1], 0ffh
    je .left_cross
    cmp byte [rbp + 3], 0ffh
    jne .left_cross

    movzx ecx, byte [rbp + 1]
    movzx edx, byte [rbp + 2]
    call avg_x4_4
    mov r10d, eax
    movzx ecx, byte [rbp + 8 + 3]
    movzx edx, byte [rbp + 8 + 4]
    call avg_x4_4
    cmp eax, r10d
    jge .left_cross

    cmp rsi, 1
    je .count
    movzx eax, byte [rbp + 16 + 3]
    cmp al, 0ffh
    je .left_cross
    cmp al, [rbp + 8 + 3]
    je .left_cross
    jmp .count

.left_cross:
    cmp byte [rbp + 8 + 1], 0ffh
    je .done
    cmp byte [rbp + 3], 0ffh
    je .done
    cmp byte [rbp + 1], 0ffh
    jne .done

    movzx ecx, byte [rbp + 8 + 1]
    movzx edx, byte [rbp + 8 + 2]
    call avg_x4_4
    mov r10d, eax
    movzx ecx, byte [rbp + 3]
    movzx edx, byte [rbp + 4]
    call avg_x4_4
    cmp eax, r10d
    jge .done

    cmp rsi, 1
    je .count
    movzx eax, byte [rbp + 16 + 1]
    cmp al, 0ffh
    je .done
    cmp al, [rbp + 8 + 1]
    je .done

.count:
    inc dword [rbx + ASSP_TECH_COUNTS_CROSSOVERS]

.done:
    ret

; ecx = heel column or 255, edx = toe column or 255, eax = average x * 4.
avg_x4_4:
    cmp cl, 0ffh
    je .heel_invalid
    cmp dl, 0ffh
    je .toe_invalid
    lea r8, [rel stage_x2_4]
    movzx eax, byte [r8 + rcx]
    movzx edx, byte [r8 + rdx]
    add eax, edx
    ret

.heel_invalid:
    cmp dl, 0ffh
    je .zero
    lea r8, [rel stage_x2_4]
    movzx eax, byte [r8 + rdx]
    add eax, eax
    ret

.toe_invalid:
    lea r8, [rel stage_x2_4]
    movzx eax, byte [r8 + rcx]
    add eax, eax
    ret

.zero:
    xor eax, eax
    ret

; rcx = tech masks, rdx = note counts, r8 = row times in milliseconds,
; r9 = row placements as 8 bytes per row, stack arg 5 = row count,
; stack arg 6 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
assp_calculate_step_tech_counts_from_placements_8:
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
    mov rdi, [rsp + 104]
    mov rbx, [rsp + 112]
    sub rsp, 40
    mov rbp, rsp

    test rbx, rbx
    jz .fail

    xor eax, eax
    mov [rbx], rax
    mov [rbx + 8], rax
    mov [rbx + 16], rax
    mov [rbx + 24], rax

    test rdi, rdi
    jz .success
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp rdi, 2
    jb .success

    movzx ecx, byte [r12]
    mov rdx, r15
    lea r8, [rbp]
    call fill_hit_positions_8

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 8]
    lea r8, [rbp + 8]
    call fill_hit_positions_8

    mov eax, [r14 + rsi * 4]
    sub eax, [r14 + rsi * 4 - 4]
    mov r11d, eax

    call count_jacks_doublesteps_8
    call count_brackets_placements_8
    call count_switches_8
    call count_crossovers_8

    mov rax, [rbp]
    mov [rbp + 16], rax
    mov rax, [rbp + 8]
    mov [rbp], rax

    inc rsi
    cmp rsi, rdi
    jb .row_loop

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
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

; rcx = tech masks, rdx = note counts, r8 = row times in seconds f32,
; r9 = row placements as 8 bytes per row, stack arg 5 = row count,
; stack arg 6 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
assp_calculate_step_tech_counts_from_placements_seconds_8:
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
    mov rdi, [rsp + 104]
    mov rbx, [rsp + 112]
    sub rsp, 40
    mov rbp, rsp

    test rbx, rbx
    jz .fail

    xor eax, eax
    mov [rbx], rax
    mov [rbx + 8], rax
    mov [rbx + 16], rax
    mov [rbx + 24], rax

    test rdi, rdi
    jz .success
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    test r14, r14
    jz .fail
    test r15, r15
    jz .fail
    cmp rdi, 2
    jb .success

    movzx ecx, byte [r12]
    mov rdx, r15
    lea r8, [rbp]
    call fill_hit_positions_8

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 8]
    lea r8, [rbp + 8]
    call fill_hit_positions_8

    movss xmm0, [r14 + rsi * 4]
    subss xmm0, [r14 + rsi * 4 - 4]
    movss [rbp + 24], xmm0

    call count_jacks_doublesteps_seconds_8
    call count_brackets_placements_8
    call count_switches_seconds_8
    call count_crossovers_8

    mov rax, [rbp]
    mov [rbp + 16], rax
    mov rax, [rbp + 8]
    mov [rbp], rax

    inc rsi
    cmp rsi, rdi
    jb .row_loop

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
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

; ecx = row mask, rdx = placement row, r8 = output positions[5].
fill_hit_positions_8:
    mov dword [r8], 0ffffffffh
    mov byte [r8 + 4], 0ffh

    xor r9d, r9d
.col_loop:
    bt ecx, r9d
    jnc .next
    movzx eax, byte [rdx + r9]
    test eax, eax
    jz .next
    cmp eax, 4
    ja .next
    mov byte [r8 + rax], r9b

.next:
    inc r9d
    cmp r9d, 8
    jb .col_loop
    ret

count_jacks_doublesteps_8:
    cmp byte [r13 + rsi], 1
    jne .done
    cmp byte [r13 + rsi - 1], 1
    jne .done

    mov ecx, 1
.foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je .next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je .next
    cmp al, dl
    jne .maybe_doublestep
    cmp r11d, 176
    jge .next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp .next

.maybe_doublestep:
    cmp r11d, 235
    jge .next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

.next:
    inc ecx
    cmp ecx, 4
    jbe .foot_loop

.done:
    ret

count_jacks_doublesteps_seconds_8:
    cmp byte [r13 + rsi], 1
    jne .done
    cmp byte [r13 + rsi - 1], 1
    jne .done

    mov ecx, 1
.foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je .next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je .next
    cmp al, dl
    jne .maybe_doublestep
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel jack_cutoff_seconds]
    jae .next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp .next

.maybe_doublestep:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel doublestep_cutoff_seconds]
    jae .next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

.next:
    inc ecx
    cmp ecx, 4
    jbe .foot_loop

.done:
    ret

count_brackets_placements_8:
    cmp byte [r13 + rsi], 2
    jb .done
    cmp byte [rbp + 8 + 1], 0ffh
    je .right
    cmp byte [rbp + 8 + 2], 0ffh
    je .right
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

.right:
    cmp byte [rbp + 8 + 3], 0ffh
    je .done
    cmp byte [rbp + 8 + 4], 0ffh
    je .done
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

.done:
    ret

count_switches_8:
    cmp r11d, 300
    jge .done

    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .done

    xor r11d, r11d
    lea r8, [r15 + rsi * 8]
    lea r9, [r8 - 8]

.col_loop:
    bt r10d, r11d
    jnc .next
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    call is_footswitch_4
    test eax, eax
    jz .next

    cmp r11d, 1
    je .down
    cmp r11d, 5
    je .down
    cmp r11d, 2
    je .up
    cmp r11d, 6
    je .up
    inc dword [rbx + ASSP_TECH_COUNTS_SIDESWITCHES]
    jmp .next

.down:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp .next

.up:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]

.next:
    inc r11d
    cmp r11d, 8
    jb .col_loop

.done:
    ret

count_switches_seconds_8:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel footswitch_cutoff_seconds]
    jae .done

    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .done

    xor r11d, r11d
    lea r8, [r15 + rsi * 8]
    lea r9, [r8 - 8]

.col_loop:
    bt r10d, r11d
    jnc .next
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    call is_footswitch_4
    test eax, eax
    jz .next

    cmp r11d, 1
    je .down
    cmp r11d, 5
    je .down
    cmp r11d, 2
    je .up
    cmp r11d, 6
    je .up
    inc dword [rbx + ASSP_TECH_COUNTS_SIDESWITCHES]
    jmp .next

.down:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp .next

.up:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]

.next:
    inc r11d
    cmp r11d, 8
    jb .col_loop

.done:
    ret

count_crossovers_8:
    cmp byte [rbp + 8 + 3], 0ffh
    je .left_cross
    cmp byte [rbp + 1], 0ffh
    je .left_cross
    cmp byte [rbp + 3], 0ffh
    jne .left_cross

    movzx ecx, byte [rbp + 1]
    movzx edx, byte [rbp + 2]
    call avg_x4_8
    mov r10d, eax
    movzx ecx, byte [rbp + 8 + 3]
    movzx edx, byte [rbp + 8 + 4]
    call avg_x4_8
    cmp eax, r10d
    jge .left_cross

    cmp rsi, 1
    je .count
    movzx eax, byte [rbp + 16 + 3]
    cmp al, 0ffh
    je .left_cross
    cmp al, [rbp + 8 + 3]
    je .left_cross
    jmp .count

.left_cross:
    cmp byte [rbp + 8 + 1], 0ffh
    je .done
    cmp byte [rbp + 3], 0ffh
    je .done
    cmp byte [rbp + 1], 0ffh
    jne .done

    movzx ecx, byte [rbp + 8 + 1]
    movzx edx, byte [rbp + 8 + 2]
    call avg_x4_8
    mov r10d, eax
    movzx ecx, byte [rbp + 3]
    movzx edx, byte [rbp + 4]
    call avg_x4_8
    cmp eax, r10d
    jge .done

    cmp rsi, 1
    je .count
    movzx eax, byte [rbp + 16 + 1]
    cmp al, 0ffh
    je .done
    cmp al, [rbp + 8 + 1]
    je .done

.count:
    inc dword [rbx + ASSP_TECH_COUNTS_CROSSOVERS]

.done:
    ret

; ecx = heel column or 255, edx = toe column or 255, eax = average x * 4.
avg_x4_8:
    cmp cl, 0ffh
    je .heel_invalid
    cmp dl, 0ffh
    je .toe_invalid
    lea r8, [rel stage_x2_8]
    movzx eax, byte [r8 + rcx]
    movzx edx, byte [r8 + rdx]
    add eax, edx
    ret

.heel_invalid:
    cmp dl, 0ffh
    je .zero
    lea r8, [rel stage_x2_8]
    movzx eax, byte [r8 + rdx]
    add eax, eax
    ret

.toe_invalid:
    lea r8, [rel stage_x2_8]
    movzx eax, byte [r8 + rcx]
    add eax, eax
    ret

.zero:
    xor eax, eax
    ret

section .rdata
other_foot_part db 0, 2, 1, 4, 3
stage_x2_4 db 0, 2, 2, 4
stage_x2_8 db 0, 2, 2, 4, 6, 8, 8, 10
jack_cutoff_seconds dd 0.176
doublestep_cutoff_seconds dd 0.235
footswitch_cutoff_seconds dd 0.3
