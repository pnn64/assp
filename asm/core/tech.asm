default rel
%include "assp.inc"

global assp_count_step_tech_brackets_minimized_4
global assp_count_step_tech_brackets_minimized_8
global assp_parse_tech_notation

section .text

%macro count_tech_lane 2
    mov al, [rsi + %1]
    cmp al, '1'
    je %%active
    cmp al, '2'
    je %%active
    cmp al, '4'
    je %%active
    jmp %%done

%%active:
    or r13d, %2
    inc r14d

%%done:
%endmacro

%macro update_hold_lane 2
    mov al, [rsi + %1]
    cmp al, '2'
    je %%start
    cmp al, '4'
    je %%start
    cmp al, '3'
    je %%end
    jmp %%done

%%start:
    or r15d, %2
    jmp %%done

%%end:
    and r15d, ~%2

%%done:
%endmacro

%macro count_bracket_pair 2
    mov r10d, (1 << %1) | (1 << %2)
    mov r11d, ecx
    and r11d, r10d
    cmp r11d, r10d
    jne %%done
    test edx, r10d
    jnz %%done
    or edx, r10d
    inc eax

%%done:
%endmacro

%macro ASSP_COUNT_STEP_TECH_BRACKETS_MINIMIZED 3
; rcx = minimized note-data bytes, rdx = byte length, r8 = out assp_tech_counts.
; eax = 1 on success, 0 on invalid pointers.
%1:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 96

    test r8, r8
    jz %%fail
    test rdx, rdx
    jz %%zero_only
    test rcx, rcx
    jz %%fail

%%zero_only:
    mov rbx, r8
    xor eax, eax
    mov [rbx], rax
    mov [rbx + 8], rax
    mov [rbx + 16], rax
    mov [rbx + 24], rax

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
    xor r15d, r15d
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], 0
    mov qword [rsp + 88], 0

%%line_loop:
    cmp rsi, rdi
    jae %%success

%%skip_separators:
    cmp rsi, rdi
    jae %%success
    mov al, [rsi]
    cmp al, ';'
    je %%success
    cmp al, ','
    je %%skip_comma_one
    cmp al, 10
    je %%skip_one
    cmp al, 13
    je %%skip_one
    cmp al, ' '
    je %%skip_one
    cmp al, 9
    je %%skip_one
    jmp %%row_start

%%skip_one:
    inc rsi
    jmp %%skip_separators

%%skip_comma_one:
    mov dword [rsp + 64], ASSP_TRUE
    inc rsi
    jmp %%skip_separators

%%row_start:
    lea rax, [rsi + %2]
    cmp rax, rdi
    ja %%success
    inc dword [rsp + 40]

    xor r13d, r13d
    xor r14d, r14d
    count_tech_lane 0, 1
    count_tech_lane 1, 2
    count_tech_lane 2, 4
    count_tech_lane 3, 8
%if %2 == 8
    count_tech_lane 4, 16
    count_tech_lane 5, 32
    count_tech_lane 6, 64
    count_tech_lane 7, 128
%endif

    test r13d, r13d
    jz %%update_holds
    mov eax, [rsp]
    inc eax
    mov [rsp], eax
    cmp eax, 1
    je %%simple_store_first
    cmp eax, 2
    je %%simple_store_second
    cmp eax, 3
    je %%simple_store_third
    cmp eax, 4
    je %%simple_store_fourth
    mov dword [rsp + 8], ASSP_TRUE
    jmp %%simple_check_row

%%simple_store_first:
    mov [rsp + 16], r13d
    mov eax, [rsp + 40]
    mov [rsp + 48], eax
    jmp %%simple_check_row

%%simple_store_second:
    mov [rsp + 24], r13d
    mov eax, [rsp + 40]
    mov [rsp + 56], eax
    jmp %%simple_check_row

%%simple_store_third:
    mov [rsp + 32], r13d
    mov eax, [rsp + 40]
    mov [rsp + 72], eax
    jmp %%simple_check_row

%%simple_store_fourth:
    mov [rsp + 80], r13d
    mov eax, [rsp + 40]
    mov [rsp + 88], eax

%%simple_check_row:
    cmp r14d, 1
    je %%simple_check_hold
    mov dword [rsp + 8], ASSP_TRUE

%%simple_check_hold:
    test r15d, r15d
    jz %%seen_check
    mov dword [rsp + 8], ASSP_TRUE

%%seen_check:
    test r12d, r12d
    jnz %%count_row
    mov r12d, ASSP_TRUE
    jmp %%update_holds

%%count_row:
    test r15d, r15d
    jz %%update_holds
    cmp r14d, 2
    jb %%update_holds
    mov ecx, r13d
    call %3
    add [rbx + ASSP_TECH_COUNTS_BRACKETS], eax

%%update_holds:
    update_hold_lane 0, 1
    update_hold_lane 1, 2
    update_hold_lane 2, 4
    update_hold_lane 3, 8
%if %2 == 8
    update_hold_lane 4, 16
    update_hold_lane 5, 32
    update_hold_lane 6, 64
    update_hold_lane 7, 128
%endif
    test r15d, r15d
    jz %%row_done
    mov dword [rsp + 8], ASSP_TRUE

%%row_done:
    add rsi, %2

%%skip_to_next_line:
    cmp rsi, rdi
    jae %%success
    mov al, [rsi]
    cmp al, ';'
    je %%success
    inc rsi
    cmp al, 10
    je %%line_loop
    cmp al, ','
    je %%line_comma
    jmp %%skip_to_next_line

%%line_comma:
    mov dword [rsp + 64], ASSP_TRUE
    jmp %%line_loop

%%success:
%if %2 == 4
    cmp dword [rsp], 3
    jne %%check_simple_doublestep
    cmp dword [rsp + 8], 0
    jne %%check_simple_doublestep
    mov ecx, [rsp + 16]
    mov edx, [rsp + 24]
    mov r8d, [rsp + 32]
    call count_simple_crossovers_4
    add [rbx + ASSP_TECH_COUNTS_CROSSOVERS], eax

%%check_simple_footswitch:
    cmp dword [rsp], 3
    jne %%check_simple_jack
    cmp dword [rsp + 8], 0
    jne %%check_simple_jack
    cmp dword [rsp + 64], 0
    jne %%check_simple_jack
    cmp dword [rsp + 40], 16
    jne %%check_simple_jack
    mov eax, [rsp + 56]
    sub eax, [rsp + 48]
    cmp eax, 1
    jne %%check_simple_jack
    mov eax, [rsp + 72]
    sub eax, [rsp + 56]
    cmp eax, 1
    jne %%check_simple_jack
    cmp dword [rsp + 32], 1
    jne %%check_three_row_jacks
    mov eax, [rsp + 16]
    cmp eax, [rsp + 24]
    jne %%check_three_row_jacks
    cmp eax, 2
    je %%count_down_footswitch
    cmp eax, 4
    je %%count_up_footswitch
    jmp %%check_three_row_jacks

%%count_down_footswitch:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_DOWN_FOOTSWITCHES]
    jmp %%return_true

%%count_up_footswitch:
    inc dword [rbx + ASSP_TECH_COUNTS_FOOTSWITCHES]
    inc dword [rbx + ASSP_TECH_COUNTS_UP_FOOTSWITCHES]
    jmp %%return_true

%%check_three_row_jacks:
    xor eax, eax
    mov ecx, [rsp + 16]
    cmp ecx, [rsp + 24]
    jne %%check_second_jack_pair
    inc eax

%%check_second_jack_pair:
    mov ecx, [rsp + 24]
    cmp ecx, [rsp + 32]
    jne %%add_three_row_jacks
    inc eax

%%add_three_row_jacks:
    add [rbx + ASSP_TECH_COUNTS_JACKS], eax
    jmp %%return_true

%%check_simple_doublestep:
    cmp dword [rsp], 4
    jne %%check_simple_jack
    cmp dword [rsp + 8], 0
    jne %%check_simple_jack
    cmp dword [rsp + 64], 0
    jne %%check_simple_jack
    cmp dword [rsp + 40], 16
    jne %%check_simple_jack
    mov eax, [rsp + 56]
    sub eax, [rsp + 48]
    cmp eax, 1
    jne %%check_simple_jack
    mov eax, [rsp + 72]
    sub eax, [rsp + 56]
    cmp eax, 1
    jne %%check_simple_jack
    mov eax, [rsp + 88]
    sub eax, [rsp + 72]
    cmp eax, 1
    jne %%check_simple_jack
    cmp dword [rsp + 16], 8
    jne %%check_simple_jack
    cmp dword [rsp + 24], 4
    jne %%check_simple_jack
    cmp dword [rsp + 32], 1
    jne %%check_simple_jack
    cmp dword [rsp + 80], 2
    jne %%check_simple_jack
    inc dword [rbx + ASSP_TECH_COUNTS_DOUBLESTEPS]
    jmp %%return_true

%%check_simple_jack:
    cmp dword [rsp], 2
    jne %%return_true
    cmp dword [rsp + 8], 0
    jne %%return_true
    cmp dword [rsp + 64], 0
    jne %%return_true
    cmp dword [rsp + 40], 16
    jb %%return_true
    mov eax, [rsp + 56]
    sub eax, [rsp + 48]
    cmp eax, 1
    jne %%return_true
    mov eax, [rsp + 16]
    cmp eax, [rsp + 24]
    jne %%return_true
    inc dword [rbx + ASSP_TECH_COUNTS_JACKS]
%endif

%%return_true:
    mov eax, ASSP_TRUE
    jmp %%done

%%fail:
    xor eax, eax

%%done:
    add rsp, 96
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
%endmacro

ASSP_COUNT_STEP_TECH_BRACKETS_MINIMIZED assp_count_step_tech_brackets_minimized_4, 4, count_brackets_4
ASSP_COUNT_STEP_TECH_BRACKETS_MINIMIZED assp_count_step_tech_brackets_minimized_8, 8, count_brackets_8

; ecx = first single-note mask, edx = second mask, r8d = third mask.
; eax = 1 when the exact three-row tap sequence is a basic single-panel crossover.
count_simple_crossovers_4:
    xor eax, eax
    cmp ecx, 1
    je .left_to_right
    cmp ecx, 8
    je .right_to_left
    ret

.left_to_right:
    cmp r8d, 8
    jne .done
    cmp edx, 2
    je .found
    cmp edx, 4
    je .found
    ret

.right_to_left:
    cmp r8d, 1
    jne .done
    cmp edx, 2
    je .found
    cmp edx, 4
    je .found
    ret

.found:
    mov eax, 1

.done:
    ret

; ecx = active note mask, eax = disjoint bracketable pair count.
count_brackets_4:
    xor eax, eax
    xor edx, edx
    count_bracket_pair 0, 1
    count_bracket_pair 0, 2
    count_bracket_pair 1, 3
    count_bracket_pair 2, 3
    ret

; ecx = active note mask, eax = disjoint bracketable pair count.
count_brackets_8:
    xor eax, eax
    xor edx, edx
    count_bracket_pair 0, 1
    count_bracket_pair 0, 2
    count_bracket_pair 1, 3
    count_bracket_pair 2, 3
    count_bracket_pair 3, 4
    count_bracket_pair 4, 5
    count_bracket_pair 4, 6
    count_bracket_pair 5, 7
    count_bracket_pair 6, 7
    ret

; rcx = credit bytes, rdx = credit len, r8 = description bytes, r9 = description len,
; stack arg 5 = optional output bytes, stack arg 6 = output cap.
; rax = total bytes required/written, not including a nul terminator, or ASSP_NOT_FOUND.
assp_parse_tech_notation:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r15, [rsp + 96]
    mov r14, [rsp + 104]
    xor r13d, r13d

    test rdx, rdx
    jz .check_description
    test rcx, rcx
    jz .fail

.check_description:
    test r9, r9
    jz .parse_credit
    test r8, r8
    jz .fail

.parse_credit:
    sub rsp, 16
    mov [rsp], r8
    mov [rsp + 8], r9

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    call parse_single_tech

    mov rsi, [rsp]
    mov rax, [rsp + 8]
    lea rdi, [rsi + rax]
    call parse_single_tech

    mov rax, r13
    add rsp, 16
    jmp .done

.fail:
    mov rax, ASSP_NOT_FOUND

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rsi = input start, rdi = input end. Appends valid tech chunks to output.
parse_single_tech:
.skip_separators:
    cmp rsi, rdi
    jae .done
    mov al, [rsi]
    cmp al, ','
    je .skip_one
    cmp al, ' '
    ja .chunk_start
.skip_one:
    inc rsi
    jmp .skip_separators

.chunk_start:
    mov rbx, rsi
    mov r12, rsi

.find_chunk_end:
    cmp r12, rdi
    jae .chunk_bounds
    mov al, [r12]
    cmp al, ','
    je .chunk_bounds
    cmp al, ' '
    jbe .chunk_bounds
    inc r12
    jmp .find_chunk_end

.chunk_bounds:
    call chunk_is_no_tech
    test eax, eax
    jnz .skip_no_tech

    mov rcx, rbx
    mov rdx, r12
    call is_measure_data
    test eax, eax
    jnz .advance

    push r13
    mov rcx, rbx
    mov rdx, r12
    call parse_chunk_as_tech
    pop r11
    test eax, eax
    jnz .advance
    mov r13, r11

.advance:
    mov rsi, r12
    jmp .skip_separators

.skip_no_tech:
    mov rsi, rax
    jmp .skip_separators

.done:
    ret

; rbx = current chunk start, r12 = current chunk end, rdi = input end.
; eax = 1 and rax = end of "Tech" chunk when current and next chunks are "No Tech".
; eax = 0 otherwise.
chunk_is_no_tech:
    mov rax, r12
    sub rax, rbx
    cmp rax, 2
    jne .false
    cmp byte [rbx], 'N'
    jne .false
    cmp byte [rbx + 1], 'o'
    jne .false

    mov r8, r12
.skip_separators:
    cmp r8, rdi
    jae .false
    mov al, [r8]
    cmp al, ','
    je .skip_one
    cmp al, ' '
    ja .next_start
.skip_one:
    inc r8
    jmp .skip_separators

.next_start:
    mov r9, r8
.find_next_end:
    cmp r9, rdi
    jae .next_bounds
    mov al, [r9]
    cmp al, ','
    je .next_bounds
    cmp al, ' '
    jbe .next_bounds
    inc r9
    jmp .find_next_end

.next_bounds:
    mov rax, r9
    sub rax, r8
    cmp rax, 4
    jne .false
    cmp byte [r8], 'T'
    jne .false
    cmp byte [r8 + 1], 'e'
    jne .false
    cmp byte [r8 + 2], 'c'
    jne .false
    cmp byte [r8 + 3], 'h'
    jne .false
    mov rax, r9
    ret

.false:
    xor eax, eax
    ret

; rcx = chunk start, rdx = chunk end. eax = 1 if it is measure data.
is_measure_data:
    xor r8d, r8d

.loop:
    cmp rcx, rdx
    jae .done
    mov al, [rcx]
    cmp al, '0'
    jb .symbol
    cmp al, '9'
    jbe .next

.symbol:
    cmp al, '/'
    je .mark_symbol
    cmp al, '-'
    je .mark_symbol
    cmp al, '*'
    je .mark_symbol
    cmp al, '|'
    je .mark_symbol
    cmp al, '~'
    je .mark_symbol
    cmp al, '.'
    je .mark_symbol
    cmp al, "'"
    jne .false

.mark_symbol:
    mov r8d, 1

.next:
    inc rcx
    jmp .loop

.done:
    mov eax, r8d
    ret

.false:
    xor eax, eax
    ret

; rcx = chunk start, rdx = chunk end. eax = 1 when the full chunk parses.
parse_chunk_as_tech:
    push rsi
    push rdi
    mov r8, rcx
    mov r9, rdx

.loop:
    cmp r8, r9
    jae .success

    push r8
    push r9
    mov rsi, r8
    mov rdi, r9
    call best_prefix
    pop r9
    pop r8
    test rax, rax
    jz .fail

    push rax
    call append_token
    pop rax
    add r8, rax
    jmp .loop

.success:
    mov eax, 1
    jmp .done

.fail:
    xor eax, eax

.done:
    pop rdi
    pop rsi
    ret

; rsi = remainder start, rdi = chunk end.
; rax = longest matching pattern len, rdx = pattern ptr. rax = 0 when not found.
best_prefix:
    push rbx
    xor eax, eax
    xor edx, edx
    mov r9, rdi
    sub r9, rsi
    lea r8, [tech_patterns]

.pattern_loop:
    lea rcx, [tech_patterns_end]
    cmp r8, rcx
    jae .done
    movzx r11d, byte [r8]
    lea r10, [r8 + 1]
    cmp r11, r9
    ja .advance
    cmp r11, rax
    jbe .advance

    xor ecx, ecx
.compare:
    cmp rcx, r11
    jae .match
    mov bl, [rsi + rcx]
    cmp bl, [r10 + rcx]
    jne .advance
    inc rcx
    jmp .compare

.match:
    mov rax, r11
    mov rdx, r10

.advance:
    lea r8, [r10 + r11]
    jmp .pattern_loop

.done:
    pop rbx
    ret

; rdx = token ptr, rax = token len.
append_token:
    mov r10, rdx
    mov r11, rax
    test r13, r13
    jz .token_bytes
    mov al, ' '
    call append_byte

.token_bytes:
    test r11, r11
    jz .done
    mov al, [r10]
    call append_byte
    inc r10
    dec r11
    jmp .token_bytes

.done:
    ret

; al = byte.
append_byte:
    test r15, r15
    jz .count
    cmp r13, r14
    jae .count
    mov [r15 + r13], al
.count:
    inc r13
    ret

section .rdata

%macro tech_pattern 1
    db %%end - %%start
%%start:
    db %1
%%end:
%endmacro

tech_patterns:
    tech_pattern "24ths"
    tech_pattern "32nds"
    tech_pattern "br"
    tech_pattern "BR"
    tech_pattern "BR+"
    tech_pattern "BR-"
    tech_pattern "BT"
    tech_pattern "BT+"
    tech_pattern "BT-"
    tech_pattern "bu"
    tech_pattern "BU"
    tech_pattern "BU+"
    tech_pattern "BU-"
    tech_pattern "BXF"
    tech_pattern "BXF+"
    tech_pattern "BXF-"
    tech_pattern "bXF"
    tech_pattern "bXF+"
    tech_pattern "bXF-"
    tech_pattern "BxF"
    tech_pattern "BXf"
    tech_pattern "BxF+"
    tech_pattern "BxF-"
    tech_pattern "bXf"
    tech_pattern "bXf+"
    tech_pattern "bXf-"
    tech_pattern "bxF"
    tech_pattern "bxF+"
    tech_pattern "bxF-"
    tech_pattern "B+XF"
    tech_pattern "BX-F"
    tech_pattern "BX-F+"
    tech_pattern "BX+F+"
    tech_pattern "B+X-F"
    tech_pattern "B-X-F-"
    tech_pattern "B-XF+"
    tech_pattern "ds"
    tech_pattern "DS"
    tech_pattern "DS++"
    tech_pattern "DS+"
    tech_pattern "DS-"
    tech_pattern "dr"
    tech_pattern "DR"
    tech_pattern "DR+"
    tech_pattern "DR-"
    tech_pattern "dt"
    tech_pattern "dt-"
    tech_pattern "DT"
    tech_pattern "DT+"
    tech_pattern "DT-"
    tech_pattern "FL"
    tech_pattern "FL+"
    tech_pattern "FL-"
    tech_pattern "fs"
    tech_pattern "FS"
    tech_pattern "FS+"
    tech_pattern "FS-"
    tech_pattern "FX"
    tech_pattern "FX+"
    tech_pattern "FX-"
    tech_pattern "GH"
    tech_pattern "GH+"
    tech_pattern "GH-"
    tech_pattern "HA"
    tech_pattern "HA+"
    tech_pattern "HA-"
    tech_pattern "HS"
    tech_pattern "HS+"
    tech_pattern "HS-"
    tech_pattern "ITL+"
    tech_pattern "ja"
    tech_pattern "ja-"
    tech_pattern "JA"
    tech_pattern "JA+"
    tech_pattern "JA-"
    tech_pattern "ju"
    tech_pattern "ju-"
    tech_pattern "JU"
    tech_pattern "JU+"
    tech_pattern "JU-"
    tech_pattern "JUMPS"
    tech_pattern "JUMPS+"
    tech_pattern "JUMPS-"
    tech_pattern "KS"
    tech_pattern "KS+"
    tech_pattern "KS-"
    tech_pattern "KT"
    tech_pattern "KT+"
    tech_pattern "KT-"
    tech_pattern "LOL"
    tech_pattern "ma"
    tech_pattern "ma-"
    tech_pattern "MA"
    tech_pattern "MA+"
    tech_pattern "MA-"
    tech_pattern "MD"
    tech_pattern "MD+"
    tech_pattern "MD-"
    tech_pattern "rh"
    tech_pattern "rh-"
    tech_pattern "RH"
    tech_pattern "RH+"
    tech_pattern "RH-"
    tech_pattern "Rolls-"
    tech_pattern "RS"
    tech_pattern "RS+"
    tech_pattern "RS-"
    tech_pattern "SC"
    tech_pattern "SC+"
    tech_pattern "SC-"
    tech_pattern "SDS"
    tech_pattern "SDS+"
    tech_pattern "SDS-"
    tech_pattern "SJ"
    tech_pattern "SJ+"
    tech_pattern "SJ-"
    tech_pattern "SK"
    tech_pattern "SK+"
    tech_pattern "SK-"
    tech_pattern "SS"
    tech_pattern "SS+"
    tech_pattern "SS-"
    tech_pattern "SKT"
    tech_pattern "SKT+"
    tech_pattern "SKT-"
    tech_pattern "SPD"
    tech_pattern "SPD+"
    tech_pattern "SPD-"
    tech_pattern "STR"
    tech_pattern "STR+"
    tech_pattern "STR-"
    tech_pattern "TR"
    tech_pattern "TR+"
    tech_pattern "TR-"
    tech_pattern "WA"
    tech_pattern "WA+"
    tech_pattern "WA-"
    tech_pattern "XMOD"
    tech_pattern "XMOD+"
    tech_pattern "XMOD-"
    tech_pattern "xo"
    tech_pattern "XO"
    tech_pattern "XO+"
    tech_pattern "XO-"
tech_patterns_end:
