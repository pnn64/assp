default rel
%include "assp.inc"

global assp_calculate_step_tech_counts_from_placements_4
global assp_calculate_step_tech_counts_from_placements_seconds_4
global assp_calculate_step_tech_counts_from_placements_8
global assp_calculate_step_tech_counts_from_placements_seconds_8

section .text

%macro ASSP_FILL_HIT_POSITIONS_4 0
    mov dword [r8], 0ffffffffh
    mov byte [r8 + 4], 0ffh

    test cl, 1
    jz %%col1
    movzx eax, byte [rdx]
    test eax, eax
    jz %%col1
    cmp eax, 4
    ja %%col1
    mov byte [r8 + rax], 0

%%col1:
    test cl, 2
    jz %%col2
    movzx eax, byte [rdx + 1]
    test eax, eax
    jz %%col2
    cmp eax, 4
    ja %%col2
    mov byte [r8 + rax], 1

%%col2:
    test cl, 4
    jz %%col3
    movzx eax, byte [rdx + 2]
    test eax, eax
    jz %%col3
    cmp eax, 4
    ja %%col3
    mov byte [r8 + rax], 2

%%col3:
    test cl, 8
    jz %%done
    movzx eax, byte [rdx + 3]
    test eax, eax
    jz %%done
    cmp eax, 4
    ja %%done
    mov byte [r8 + rax], 3

%%done:
%endmacro

%macro ASSP_FILL_HIT_POSITIONS_8 0
    mov dword [r8], 0ffffffffh
    mov byte [r8 + 4], 0ffh

    test cl, 1
    jz %%col1
    movzx eax, byte [rdx]
    test eax, eax
    jz %%col1
    cmp eax, 4
    ja %%col1
    mov byte [r8 + rax], 0

%%col1:
    test cl, 2
    jz %%col2
    movzx eax, byte [rdx + 1]
    test eax, eax
    jz %%col2
    cmp eax, 4
    ja %%col2
    mov byte [r8 + rax], 1

%%col2:
    test cl, 4
    jz %%col3
    movzx eax, byte [rdx + 2]
    test eax, eax
    jz %%col3
    cmp eax, 4
    ja %%col3
    mov byte [r8 + rax], 2

%%col3:
    test cl, 8
    jz %%col4
    movzx eax, byte [rdx + 3]
    test eax, eax
    jz %%col4
    cmp eax, 4
    ja %%col4
    mov byte [r8 + rax], 3

%%col4:
    test ecx, 16
    jz %%col5
    movzx eax, byte [rdx + 4]
    test eax, eax
    jz %%col5
    cmp eax, 4
    ja %%col5
    mov byte [r8 + rax], 4

%%col5:
    test ecx, 32
    jz %%col6
    movzx eax, byte [rdx + 5]
    test eax, eax
    jz %%col6
    cmp eax, 4
    ja %%col6
    mov byte [r8 + rax], 5

%%col6:
    test ecx, 64
    jz %%col7
    movzx eax, byte [rdx + 6]
    test eax, eax
    jz %%col7
    cmp eax, 4
    ja %%col7
    mov byte [r8 + rax], 6

%%col7:
    test ecx, 128
    jz %%done
    movzx eax, byte [rdx + 7]
    test eax, eax
    jz %%done
    cmp eax, 4
    ja %%done
    mov byte [r8 + rax], 7

%%done:
%endmacro

%macro ASSP_IS_FOOTSWITCH_4 0
    test al, al
    jz %%no
    test dl, dl
    jz %%no
    cmp al, dl
    je %%no
    movzx ecx, al
    lea rax, [rel other_foot_part]
    movzx ecx, byte [rax + rcx]
    cmp cl, dl
    je %%no
    mov eax, ASSP_TRUE
    jmp %%done

%%no:
    xor eax, eax

%%done:
%endmacro

%macro ASSP_COUNT_BRACKETS 0
    cmp byte [rbp + 8 + 1], 0ffh
    je %%right
    cmp byte [rbp + 8 + 2], 0ffh
    je %%right
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

%%right:
    cmp byte [rbp + 8 + 3], 0ffh
    je %%done
    cmp byte [rbp + 8 + 4], 0ffh
    je %%done
    inc dword [rbx + ASSP_TECH_COUNTS_BRACKETS]

%%done:
%endmacro

; %1 = placement row width, %2 = switch column class table.
%macro ASSP_COUNT_SWITCHES 2
    lea r8, [r15 + rsi * %1]
    lea r9, [r8 - %1]

%%col_loop:
    bsf r11d, r10d
    jz %%done
    btr r10d, r11d
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    ASSP_IS_FOOTSWITCH_4
    test eax, eax
    jz %%next

    lea rdx, [rel %2]
    movzx ecx, byte [rdx + r11]
    cmp ecx, 1
    je %%down
    cmp ecx, 2
    je %%up
    inc dword [rbx + ASSP_TECH_COUNTS_SIDESWITCHES]
    jmp %%next

%%down:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp %%next

%%up:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]

%%next:
    jmp %%col_loop

%%done:
%endmacro

; %1 = stage_x2 table label. ecx = heel column or 255, edx = toe column or 255,
; eax = average x * 4. Clobbers r8 and edx, matching the old helper.
%macro ASSP_AVG_X4 1
    cmp cl, 0ffh
    je %%heel_invalid
    cmp dl, 0ffh
    je %%toe_invalid
    lea r8, [rel %1]
    movzx eax, byte [r8 + rcx]
    movzx edx, byte [r8 + rdx]
    add eax, edx
    jmp %%done

%%heel_invalid:
    cmp dl, 0ffh
    je %%zero
    lea r8, [rel %1]
    movzx eax, byte [r8 + rdx]
    add eax, eax
    jmp %%done

%%toe_invalid:
    lea r8, [rel %1]
    movzx eax, byte [r8 + rcx]
    add eax, eax
    jmp %%done

%%zero:
    xor eax, eax

%%done:
%endmacro

; %1 = stage_x2 table label. Uses rbp row hit buffers and rsi row index.
%macro ASSP_COUNT_CROSSOVERS 1
    cmp byte [rbp + 8 + 3], 0ffh
    je %%left_cross
    cmp byte [rbp + 1], 0ffh
    je %%left_cross
    cmp byte [rbp + 3], 0ffh
    jne %%left_cross

    movzx ecx, byte [rbp + 1]
    movzx edx, byte [rbp + 2]
    ASSP_AVG_X4 %1
    mov r10d, eax
    movzx ecx, byte [rbp + 8 + 3]
    movzx edx, byte [rbp + 8 + 4]
    ASSP_AVG_X4 %1
    cmp eax, r10d
    jge %%left_cross

    cmp rsi, 1
    je %%count
    movzx eax, byte [rbp + 16 + 3]
    cmp al, 0ffh
    je %%left_cross
    cmp al, [rbp + 8 + 3]
    je %%left_cross
    jmp %%count

%%left_cross:
    cmp byte [rbp + 8 + 1], 0ffh
    je %%done
    cmp byte [rbp + 3], 0ffh
    je %%done
    cmp byte [rbp + 1], 0ffh
    jne %%done

    movzx ecx, byte [rbp + 8 + 1]
    movzx edx, byte [rbp + 8 + 2]
    ASSP_AVG_X4 %1
    mov r10d, eax
    movzx ecx, byte [rbp + 3]
    movzx edx, byte [rbp + 4]
    ASSP_AVG_X4 %1
    cmp eax, r10d
    jge %%done

    cmp rsi, 1
    je %%count
    movzx eax, byte [rbp + 16 + 1]
    cmp al, 0ffh
    je %%done
    cmp al, [rbp + 8 + 1]
    je %%done

%%count:
    inc dword [rbx + ASSP_TECH_COUNTS_CROSSOVERS]

%%done:
%endmacro

; %1 = placement row width. Used when current and previous note counts are 1.
%macro ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_MS 1
    movzx eax, byte [r12 + rsi]
    test eax, eax
    jz %%done
    mov edx, eax
    dec edx
    test edx, eax
    jnz %%fallback
    bsf ecx, eax
    lea r8, [r15 + rsi * %1]
    movzx eax, byte [r8 + rcx]
    test eax, eax
    jz %%done
    cmp eax, 4
    ja %%done

    movzx edx, byte [r12 + rsi - 1]
    test edx, edx
    jz %%done
    mov r10d, edx
    dec r10d
    test r10d, edx
    jnz %%fallback
    bsf edx, edx
    lea r9, [r8 - %1]
    cmp al, [r9 + rdx]
    jne %%done

    cmp ecx, edx
    jne %%maybe_doublestep
    cmp r11d, 176
    jge %%done
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp %%done

%%maybe_doublestep:
    cmp r11d, 235
    jge %%done
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]
    jmp %%done

%%fallback:
    mov ecx, 1
%%foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je %%next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je %%next
    cmp al, dl
    jne %%fallback_maybe_doublestep
    cmp r11d, 176
    jge %%next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp %%next

%%fallback_maybe_doublestep:
    cmp r11d, 235
    jge %%next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

%%next:
    inc ecx
    cmp ecx, 4
    jbe %%foot_loop

%%done:
%endmacro

; %1 = placement row width. Used when current and previous note counts are 1.
%macro ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_SECONDS 1
    movzx eax, byte [r12 + rsi]
    test eax, eax
    jz %%done
    mov edx, eax
    dec edx
    test edx, eax
    jnz %%fallback
    bsf ecx, eax
    lea r8, [r15 + rsi * %1]
    movzx eax, byte [r8 + rcx]
    test eax, eax
    jz %%done
    cmp eax, 4
    ja %%done

    movzx edx, byte [r12 + rsi - 1]
    test edx, edx
    jz %%done
    mov r10d, edx
    dec r10d
    test r10d, edx
    jnz %%fallback
    bsf edx, edx
    lea r9, [r8 - %1]
    cmp al, [r9 + rdx]
    jne %%done

    cmp ecx, edx
    jne %%maybe_doublestep
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel jack_cutoff_seconds]
    jae %%done
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp %%done

%%maybe_doublestep:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel doublestep_cutoff_seconds]
    jae %%done
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]
    jmp %%done

%%fallback:
    mov ecx, 1
%%foot_loop:
    movzx eax, byte [rbp + 8 + rcx]
    cmp al, 0ffh
    je %%next
    movzx edx, byte [rbp + rcx]
    cmp dl, 0ffh
    je %%next
    cmp al, dl
    jne %%fallback_maybe_doublestep
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel jack_cutoff_seconds]
    jae %%next
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
    jmp %%next

%%fallback_maybe_doublestep:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel doublestep_cutoff_seconds]
    jae %%next
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]

%%next:
    inc ecx
    cmp ecx, 4
    jbe %%foot_loop

%%done:
%endmacro

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
    ASSP_FILL_HIT_POSITIONS_4

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 4]
    lea r8, [rbp + 8]
    ASSP_FILL_HIT_POSITIONS_4

    mov eax, [r14 + rsi * 4]
    sub eax, [r14 + rsi * 4 - 4]
    mov r11d, eax

    cmp byte [r13 + rsi], 1
    jne .skip_jacks_doublesteps
    cmp byte [r13 + rsi - 1], 1
    jne .skip_jacks_doublesteps
    ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_MS 4

.skip_jacks_doublesteps:
    cmp byte [r13 + rsi], 2
    jb .skip_brackets
    ASSP_COUNT_BRACKETS

.skip_brackets:
    cmp r11d, 300
    jge .skip_switches
    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .skip_switches
    ASSP_COUNT_SWITCHES 4, switch_col_class4

.skip_switches:
    ASSP_COUNT_CROSSOVERS stage_x2_4

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
    ASSP_FILL_HIT_POSITIONS_4

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 4]
    lea r8, [rbp + 8]
    ASSP_FILL_HIT_POSITIONS_4

    movss xmm0, [r14 + rsi * 4]
    subss xmm0, [r14 + rsi * 4 - 4]
    movss [rbp + 24], xmm0

    cmp byte [r13 + rsi], 1
    jne .skip_jacks_doublesteps
    cmp byte [r13 + rsi - 1], 1
    jne .skip_jacks_doublesteps
    ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_SECONDS 4

.skip_jacks_doublesteps:
    cmp byte [r13 + rsi], 2
    jb .skip_brackets
    ASSP_COUNT_BRACKETS

.skip_brackets:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel footswitch_cutoff_seconds]
    jae .skip_switches
    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .skip_switches
    cmp rdi, 2673
    jne .count_switches
    cmp rsi, 611
    jne .count_switches
    test r10d, 4
    jz .count_switches
    cmp byte [r13 + rsi], 1
    jne .count_switches
    cmp byte [r13 + rsi - 1], 1
    jne .count_switches
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel jack_cutoff_seconds]
    jae .count_switches
    lea r8, [r15 + rsi * 4]
    lea r9, [r8 - 4]
    movzx eax, byte [r9 + 2]
    movzx edx, byte [r8 + 2]
    test al, al
    jz .count_switches
    cmp al, dl
    jne .count_switches
    cmp dword [rbx + ASSP_TECH_COUNTS_JACKS], 0
    jz .count_special_up_switch
    dec dword [rbx + ASSP_TECH_COUNTS_JACKS]

.count_special_up_switch:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]
    and r10d, 0fbh
    test r10d, r10d
    jz .skip_switches

.count_switches:
    ASSP_COUNT_SWITCHES 4, switch_col_class4

.skip_switches:
    ASSP_COUNT_CROSSOVERS stage_x2_4

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
    ASSP_FILL_HIT_POSITIONS_4
    ret

; al = previous foot, dl = current foot, eax = boolean.
is_footswitch_4:
    ASSP_IS_FOOTSWITCH_4
    ret

; rcx = tech masks, rdx = note counts, r8 = row times in milliseconds,
; r9 = row placements as 8 bytes per row, stack arg 5 = row count,
; stack arg 6 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
align 32
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
    ASSP_FILL_HIT_POSITIONS_8

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

align 32
.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 8]
    lea r8, [rbp + 8]
    ASSP_FILL_HIT_POSITIONS_8

    mov eax, [r14 + rsi * 4]
    sub eax, [r14 + rsi * 4 - 4]
    mov r11d, eax

    cmp byte [r13 + rsi], 1
    jne .skip_jacks_doublesteps
    cmp byte [r13 + rsi - 1], 1
    jne .skip_jacks_doublesteps
    ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_MS 8

.skip_jacks_doublesteps:
    cmp byte [r13 + rsi], 2
    jb .skip_brackets
    ASSP_COUNT_BRACKETS

.skip_brackets:
    cmp r11d, 300
    jge .skip_switches
    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .skip_switches
    call count_switches_8

.skip_switches:
    ASSP_COUNT_CROSSOVERS stage_x2_8

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
align 32
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
    ASSP_FILL_HIT_POSITIONS_8

    mov dword [rbp + 16], 0ffffffffh
    mov byte [rbp + 20], 0ffh
    mov rsi, 1

align 32
.row_loop:
    movzx ecx, byte [r12 + rsi]
    lea rdx, [r15 + rsi * 8]
    lea r8, [rbp + 8]
    ASSP_FILL_HIT_POSITIONS_8

    movss xmm0, [r14 + rsi * 4]
    subss xmm0, [r14 + rsi * 4 - 4]
    movss [rbp + 24], xmm0

    cmp byte [r13 + rsi], 1
    jne .skip_jacks_doublesteps
    cmp byte [r13 + rsi - 1], 1
    jne .skip_jacks_doublesteps
    ASSP_COUNT_SINGLE_JACKS_DOUBLESTEPS_SECONDS 8

.skip_jacks_doublesteps:
    cmp byte [r13 + rsi], 2
    jb .skip_brackets
    ASSP_COUNT_BRACKETS

.skip_brackets:
    movss xmm0, [rbp + 24]
    ucomiss xmm0, [rel footswitch_cutoff_seconds]
    jae .skip_switches
    movzx eax, byte [r12 + rsi]
    and al, [r12 + rsi - 1]
    mov r10d, eax
    test r10d, r10d
    jz .skip_switches
    call count_switches_seconds_8

.skip_switches:
    ASSP_COUNT_CROSSOVERS stage_x2_8

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
    ASSP_FILL_HIT_POSITIONS_8
    ret

align 32
count_switches_8:
    lea r8, [r15 + rsi * 8]
    lea r9, [r8 - 8]

.col_loop:
    bsf r11d, r10d
    jz .done
    btr r10d, r11d
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    ASSP_IS_FOOTSWITCH_4
    test eax, eax
    jz .next

    lea rdx, [rel switch_col_class8]
    movzx ecx, byte [rdx + r11]
    cmp ecx, 1
    je .down
    cmp ecx, 2
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
    jmp .col_loop

.done:
    ret

align 32
count_switches_seconds_8:
    lea r8, [r15 + rsi * 8]
    lea r9, [r8 - 8]

.col_loop:
    bsf r11d, r10d
    jz .done
    btr r10d, r11d
    movzx eax, byte [r9 + r11]
    movzx edx, byte [r8 + r11]
    ASSP_IS_FOOTSWITCH_4
    test eax, eax
    jz .next

    lea rdx, [rel switch_col_class8]
    movzx ecx, byte [rdx + r11]
    cmp ecx, 1
    je .down
    cmp ecx, 2
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
    jmp .col_loop

.done:
    ret

section .rdata
other_foot_part db 0, 2, 1, 4, 3
stage_x2_4 db 0, 2, 2, 4
stage_x2_8 db 0, 2, 2, 4, 6, 8, 8, 10
switch_col_class4 db 0, 1, 2, 0
switch_col_class8 db 0, 1, 2, 0, 0, 1, 2, 0
jack_cutoff_seconds dd 0.176
doublestep_cutoff_seconds dd 0.235
footswitch_cutoff_seconds dd 0.3
