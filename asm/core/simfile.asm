default rel
%include "assp.inc"

global assp_count_note_charts
global assp_find_notes_by_index
global assp_find_chart_by_index
global assp_find_global_bpms
global assp_find_chart_bpms_by_index
global assp_find_global_tag
global assp_find_chart_tag_by_index
global assp_find_global_timing_tags
global assp_find_chart_timing_tags_by_index

section .text

%macro find_timing_tag 3
    mov r10, rsi
    mov r11, rdi
    lea r12, [%1]
    mov r13, %2
    lea rbx, [r15 + %3]
    call find_tag_in_range
%endmacro

%macro is_notes_tag 1
    cmp byte [%1 + 0], '#'
    jne %%no
    cmp byte [%1 + 1], 'N'
    jne %%no
    cmp byte [%1 + 2], 'O'
    jne %%no
    cmp byte [%1 + 3], 'T'
    jne %%no
    cmp byte [%1 + 4], 'E'
    jne %%no
    cmp byte [%1 + 5], 'S'
    jne %%no
    cmp byte [%1 + 6], ':'
    jne %%no
    mov eax, ASSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro is_notedata_tag 1
    cmp byte [%1 + 0], '#'
    jne %%no
    cmp byte [%1 + 1], 'N'
    jne %%no
    cmp byte [%1 + 2], 'O'
    jne %%no
    cmp byte [%1 + 3], 'T'
    jne %%no
    cmp byte [%1 + 4], 'E'
    jne %%no
    cmp byte [%1 + 5], 'D'
    jne %%no
    cmp byte [%1 + 6], 'A'
    jne %%no
    cmp byte [%1 + 7], 'T'
    jne %%no
    cmp byte [%1 + 8], 'A'
    jne %%no
    cmp byte [%1 + 9], ':'
    jne %%no
    mov eax, ASSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro is_bpms_tag 1
    cmp byte [%1 + 0], '#'
    jne %%no
    cmp byte [%1 + 1], 'B'
    jne %%no
    cmp byte [%1 + 2], 'P'
    jne %%no
    cmp byte [%1 + 3], 'M'
    jne %%no
    cmp byte [%1 + 4], 'S'
    jne %%no
    cmp byte [%1 + 5], ':'
    jne %%no
    mov eax, ASSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro store_tag 3
    lea rax, [r10 + %1]
    mov rdx, rax
%%find_end:
    cmp rdx, r11
    jae .meta_next
    cmp byte [rdx], ';'
    je %%found_end
    inc rdx
    jmp %%find_end
%%found_end:
    mov [rbx + %2], rax
    sub rdx, rax
    mov [rbx + %3], rdx
    jmp .meta_next
%endmacro

%macro store_trim_field 2
    mov rax, r8
    mov rdx, r12
%%trim_left:
    cmp rax, rdx
    jae %%empty
    cmp byte [rax], ' '
    ja %%trim_right
    inc rax
    jmp %%trim_left
%%trim_right:
    cmp rdx, rax
    jbe %%empty
    cmp byte [rdx - 1], ' '
    ja %%store
    dec rdx
    jmp %%trim_right
%%empty:
    mov [rbx + %1], rax
    mov qword [rbx + %2], 0
    jmp %%done
%%store:
    mov [rbx + %1], rax
    sub rdx, rax
    mov [rbx + %2], rdx
%%done:
%endmacro

; rcx = simfile bytes, rdx = len.
; rax = number of #NOTES: tags.
assp_count_note_charts:
    test rcx, rcx
    jz .zero
    cmp rdx, 7
    jb .zero

    mov r10, rcx
    lea r11, [rcx + rdx]
    xor r8d, r8d

.scan:
    lea rax, [r10 + 7]
    cmp rax, r11
    ja .done

    is_notes_tag r10
    test eax, eax
    jz .next
    inc r8
    add r10, 7
    jmp .scan

.next:
    inc r10
    jmp .scan

.done:
    mov rax, r8
    ret

.zero:
    xor eax, eax
    ret

; rcx = simfile bytes, rdx = len, r8 = out assp_byte_slice.
; eax = 1 when a #BPMS: tag is found, 0 otherwise.
assp_find_global_bpms:
    test rcx, rcx
    jz .fail
    test r8, r8
    jz .fail
    cmp rdx, 6
    jb .fail

    mov qword [r8 + ASSP_BYTE_SLICE_PTR], 0
    mov qword [r8 + ASSP_BYTE_SLICE_LEN], 0

    mov r10, rcx
    lea r11, [rcx + rdx]

.scan:
    lea rax, [r10 + 6]
    cmp rax, r11
    ja .fail

    is_bpms_tag r10
    test eax, eax
    jnz .found
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + 6]
    mov rdx, rax
.find_end:
    cmp rdx, r11
    jae .fail
    cmp byte [rdx], ';'
    je .store
    inc rdx
    jmp .find_end

.store:
    mov [r8 + ASSP_BYTE_SLICE_PTR], rax
    sub rdx, rax
    mov [r8 + ASSP_BYTE_SLICE_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = out assp_byte_slice.
; Finds a chart-local SSC #BPMS: tag in the selected #NOTEDATA block.
; eax = 1 when found, 0 otherwise.
assp_find_chart_bpms_by_index:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    cmp rdx, 7
    jb .fail

    mov qword [r9 + ASSP_BYTE_SLICE_PTR], 0
    mov qword [r9 + ASSP_BYTE_SLICE_LEN], 0

    mov rbx, r9
    mov rdi, rcx
    lea r12, [rcx + rdx]
    mov r13, r8
    xor r14d, r14d
    xor r15d, r15d

.scan:
    lea rax, [rdi + 10]
    cmp rax, r12
    ja .fail

    is_notedata_tag rdi
    test eax, eax
    jz .check_notes
    mov r15, rdi
    add rdi, 10
    jmp .scan

.check_notes:
    lea rax, [rdi + 7]
    cmp rax, r12
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, 7
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found_chart:
    test r15, r15
    jz .fail
    mov r10, r15
    mov r11, rdi
    call find_bpms_in_range
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = simfile bytes, rdx = len, r8 = tag bytes, r9 = tag len,
; stack arg 5 = out assp_byte_slice.
; The tag must include the leading '#' and trailing ':'.
; eax = 1 when found, 0 otherwise.
assp_find_global_tag:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rbx, [rsp + 96]
    test rcx, rcx
    jz .fail
    test r8, r8
    jz .fail
    test r9, r9
    jz .fail
    test rbx, rbx
    jz .fail
    cmp rdx, r9
    jb .fail

    mov qword [rbx + ASSP_BYTE_SLICE_PTR], 0
    mov qword [rbx + ASSP_BYTE_SLICE_LEN], 0

    mov r10, rcx
    lea r11, [rcx + rdx]
    mov r12, r8
    mov r13, r9
    call find_tag_in_range
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = tag bytes,
; stack arg 5 = tag len, stack arg 6 = out assp_byte_slice.
; Finds a chart-local SSC tag in the selected #NOTEDATA block.
; eax = 1 when found, 0 otherwise.
assp_find_chart_tag_by_index:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, [rsp + 96]
    mov rbx, [rsp + 104]
    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    test r12, r12
    jz .fail
    test rbx, rbx
    jz .fail
    cmp rdx, 7
    jb .fail

    mov qword [rbx + ASSP_BYTE_SLICE_PTR], 0
    mov qword [rbx + ASSP_BYTE_SLICE_LEN], 0

    mov rdi, rcx
    lea rsi, [rcx + rdx]
    mov r13, r8
    xor r14d, r14d
    xor r15d, r15d

.scan:
    lea rax, [rdi + 10]
    cmp rax, rsi
    ja .fail

    is_notedata_tag rdi
    test eax, eax
    jz .check_notes
    mov r15, rdi
    add rdi, 10
    jmp .scan

.check_notes:
    lea rax, [rdi + 7]
    cmp rax, rsi
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, 7
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found_chart:
    test r15, r15
    jz .fail
    mov r10, r15
    mov r11, rdi
    mov r12, r9
    mov r13, [rsp + 96]
    call find_tag_in_range
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = simfile bytes, rdx = len, r8 = out assp_timing_tags.
; eax = 1 on valid input. Missing tags remain empty slices.
assp_find_global_timing_tags:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail
    test r8, r8
    jz .fail

    mov r10, rcx
    lea r11, [rcx + rdx]
    mov rbx, r8
    call find_timing_tags_in_range
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = out assp_timing_tags.
; Collects chart-local SSC timing tags from the selected #NOTEDATA block.
; eax = 1 when the chart is found, 0 otherwise.
assp_find_chart_timing_tags_by_index:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    cmp rdx, 7
    jb .fail

    mov r13, r8
    mov rbx, r9
    call zero_timing_tags

    mov rdi, rcx
    lea rsi, [rcx + rdx]
    xor r14d, r14d
    xor r15d, r15d

.scan:
    lea rax, [rdi + 10]
    cmp rax, rsi
    ja .fail

    is_notedata_tag rdi
    test eax, eax
    jz .check_notes
    mov r15, rdi
    add rdi, 10
    jmp .scan

.check_notes:
    lea rax, [rdi + 7]
    cmp rax, rsi
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, 7
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found_chart:
    test r15, r15
    jz .fail
    mov r10, r15
    mov r11, rdi
    mov rbx, r9
    call find_timing_tags_in_range
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = out assp_chart_ref.
; eax = 1 when found, 0 otherwise.
assp_find_notes_by_index:
    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    cmp rdx, 7
    jb .fail

    mov qword [r9 + ASSP_CHART_REF_NOTES_PTR], 0
    mov qword [r9 + ASSP_CHART_REF_NOTES_LEN], 0
    mov [r9 + ASSP_CHART_REF_INDEX], r8

    mov r10, rcx
    lea r11, [rcx + rdx]
    xor ecx, ecx

.scan:
    lea rax, [r10 + 7]
    cmp rax, r11
    ja .fail

    is_notes_tag r10
    test eax, eax
    jz .next

    cmp rcx, r8
    je .found
    inc rcx
    add r10, 7
    jmp .scan

.next:
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + 7]
    mov rdx, rax

.find_end:
    cmp rdx, r11
    jae .fail
    cmp byte [rdx], ';'
    je .store
    inc rdx
    jmp .find_end

.store:
    inc rdx
    mov [r9 + ASSP_CHART_REF_NOTES_PTR], rax
    sub rdx, rax
    mov [r9 + ASSP_CHART_REF_NOTES_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = out assp_chart_info.
; eax = 1 when found, 0 otherwise.
assp_find_chart_by_index:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    cmp rdx, 7
    jb .fail

    mov rbx, r9
    xor eax, eax
    mov r10d, ASSP_CHART_INFO_SIZE / 8
    mov r11, rbx

.zero:
    mov [r11], rax
    add r11, 8
    dec r10d
    jnz .zero

    mov [rbx + ASSP_CHART_INFO_INDEX], r8
    mov rsi, rcx
    mov rdi, rcx
    lea r12, [rcx + rdx]
    mov r13, r8
    xor r14d, r14d
    mov r15, rcx

.scan:
    lea rax, [rdi + 10]
    cmp rax, r12
    ja .fail

    is_notedata_tag rdi
    test eax, eax
    jz .check_notes
    mov r15, rdi
    add rdi, 10
    jmp .scan

.check_notes:
    lea rax, [rdi + 7]
    cmp rax, r12
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found
    inc r14
    add rdi, 7
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found:
    lea rsi, [rdi + 7]
    mov rdx, rsi

.find_notes_end:
    cmp rdx, r12
    jae .fail
    cmp byte [rdx], ';'
    je .store_notes
    inc rdx
    jmp .find_notes_end

.store_notes:
    inc rdx
    mov r14, rdx
    mov r10, rsi
    mov r11, r14
    call parse_sm_notes_block
    test eax, eax
    jnz .success

    mov [rbx + ASSP_CHART_INFO_NOTES_PTR], rsi
    mov rdx, r14
    sub rdx, rsi
    mov [rbx + ASSP_CHART_INFO_NOTES_LEN], rdx

    mov r10, r15
    mov r11, rdi
    call parse_chart_meta

.success:
    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; r10 = scan start, r11 = scan end, rbx = out assp_byte_slice.
; eax = 1 when a #BPMS: tag is found, 0 otherwise.
find_bpms_in_range:
.scan:
    lea rax, [r10 + 6]
    cmp rax, r11
    ja .fail

    is_bpms_tag r10
    test eax, eax
    jnz .found
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + 6]
    mov rdx, rax
.find_end:
    cmp rdx, r11
    jae .fail
    cmp byte [rdx], ';'
    je .store
    inc rdx
    jmp .find_end

.store:
    mov [rbx + ASSP_BYTE_SLICE_PTR], rax
    sub rdx, rax
    mov [rbx + ASSP_BYTE_SLICE_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; r10 = scan start, r11 = scan end, r12 = tag ptr, r13 = tag len,
; rbx = out assp_byte_slice.
; eax = 1 when the exact tag is found, 0 otherwise.
find_tag_in_range:
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail

.scan:
    lea rax, [r10 + r13]
    cmp rax, r11
    ja .fail

    call match_tag_at
    test eax, eax
    jnz .found
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + r13]
    mov rdx, rax
.find_end:
    cmp rdx, r11
    jae .fail
    cmp byte [rdx], ';'
    je .store
    inc rdx
    jmp .find_end

.store:
    mov [rbx + ASSP_BYTE_SLICE_PTR], rax
    sub rdx, rax
    mov [rbx + ASSP_BYTE_SLICE_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; r10 = candidate ptr, r12 = tag ptr, r13 = tag len.
; eax = 1 on exact byte match, 0 otherwise.
match_tag_at:
    xor r8d, r8d
.loop:
    cmp r8, r13
    jae .yes
    mov al, [r10 + r8]
    cmp al, [r12 + r8]
    jne .no
    inc r8
    jmp .loop
.yes:
    mov eax, ASSP_TRUE
    ret
.no:
    xor eax, eax
    ret

; rbx = assp_timing_tags.
zero_timing_tags:
    xor eax, eax
    xor r8d, r8d
.loop:
    cmp r8, ASSP_TIMING_TAGS_SIZE
    jae .done
    mov [rbx + r8], rax
    add r8, 8
    jmp .loop
.done:
    ret

; r10 = scan start, r11 = scan end, rbx = assp_timing_tags.
find_timing_tags_in_range:
    mov rsi, r10
    mov rdi, r11
    mov r15, rbx
    call zero_timing_tags

    find_timing_tag tag_bpms, tag_bpms_end - tag_bpms, ASSP_TIMING_TAGS_BPMS
    find_timing_tag tag_stops, tag_stops_end - tag_stops, ASSP_TIMING_TAGS_STOPS
    cmp qword [r15 + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR], 0
    jne .stops_done
    find_timing_tag tag_freezes, tag_freezes_end - tag_freezes, ASSP_TIMING_TAGS_STOPS
.stops_done:
    find_timing_tag tag_delays, tag_delays_end - tag_delays, ASSP_TIMING_TAGS_DELAYS
    find_timing_tag tag_warps, tag_warps_end - tag_warps, ASSP_TIMING_TAGS_WARPS
    find_timing_tag tag_speeds, tag_speeds_end - tag_speeds, ASSP_TIMING_TAGS_SPEEDS
    find_timing_tag tag_scrolls, tag_scrolls_end - tag_scrolls, ASSP_TIMING_TAGS_SCROLLS
    find_timing_tag tag_fakes, tag_fakes_end - tag_fakes, ASSP_TIMING_TAGS_FAKES
    ret

; r10 = metadata scan start, r11 = metadata end, rbx = assp_chart_info.
parse_chart_meta:
.meta_loop:
    cmp r10, r11
    jae .done
    cmp byte [r10], '#'
    jne .meta_next

    lea rax, [r10 + 13]
    cmp rax, r11
    ja .check_difficulty
    cmp byte [r10 + 1], 'D'
    jne .check_difficulty
    cmp byte [r10 + 2], 'E'
    jne .check_difficulty
    cmp byte [r10 + 3], 'S'
    jne .check_difficulty
    cmp byte [r10 + 4], 'C'
    jne .check_difficulty
    cmp byte [r10 + 5], 'R'
    jne .check_difficulty
    cmp byte [r10 + 6], 'I'
    jne .check_difficulty
    cmp byte [r10 + 7], 'P'
    jne .check_difficulty
    cmp byte [r10 + 8], 'T'
    jne .check_difficulty
    cmp byte [r10 + 9], 'I'
    jne .check_difficulty
    cmp byte [r10 + 10], 'O'
    jne .check_difficulty
    cmp byte [r10 + 11], 'N'
    jne .check_difficulty
    cmp byte [r10 + 12], ':'
    jne .check_difficulty
    store_tag 13, ASSP_CHART_INFO_DESC_PTR, ASSP_CHART_INFO_DESC_LEN

.check_difficulty:
    lea rax, [r10 + 12]
    cmp rax, r11
    ja .check_step_type
    cmp byte [r10 + 1], 'D'
    jne .check_step_type
    cmp byte [r10 + 2], 'I'
    jne .check_step_type
    cmp byte [r10 + 3], 'F'
    jne .check_step_type
    cmp byte [r10 + 4], 'F'
    jne .check_step_type
    cmp byte [r10 + 5], 'I'
    jne .check_step_type
    cmp byte [r10 + 6], 'C'
    jne .check_step_type
    cmp byte [r10 + 7], 'U'
    jne .check_step_type
    cmp byte [r10 + 8], 'L'
    jne .check_step_type
    cmp byte [r10 + 9], 'T'
    jne .check_step_type
    cmp byte [r10 + 10], 'Y'
    jne .check_step_type
    cmp byte [r10 + 11], ':'
    jne .check_step_type
    store_tag 12, ASSP_CHART_INFO_DIFFICULTY_PTR, ASSP_CHART_INFO_DIFFICULTY_LEN

.check_step_type:
    lea rax, [r10 + 11]
    cmp rax, r11
    ja .check_meter
    cmp byte [r10 + 1], 'S'
    jne .check_meter
    cmp byte [r10 + 2], 'T'
    jne .check_meter
    cmp byte [r10 + 3], 'E'
    jne .check_meter
    cmp byte [r10 + 4], 'P'
    jne .check_meter
    cmp byte [r10 + 5], 'S'
    jne .check_meter
    cmp byte [r10 + 6], 'T'
    jne .check_meter
    cmp byte [r10 + 7], 'Y'
    jne .check_meter
    cmp byte [r10 + 8], 'P'
    jne .check_meter
    cmp byte [r10 + 9], 'E'
    jne .check_meter
    cmp byte [r10 + 10], ':'
    jne .check_meter
    store_tag 11, ASSP_CHART_INFO_STEP_TYPE_PTR, ASSP_CHART_INFO_STEP_TYPE_LEN

.check_meter:
    lea rax, [r10 + 7]
    cmp rax, r11
    ja .meta_next
    cmp byte [r10 + 1], 'M'
    jne .meta_next
    cmp byte [r10 + 2], 'E'
    jne .meta_next
    cmp byte [r10 + 3], 'T'
    jne .meta_next
    cmp byte [r10 + 4], 'E'
    jne .meta_next
    cmp byte [r10 + 5], 'R'
    jne .meta_next
    cmp byte [r10 + 6], ':'
    jne .meta_next
    store_tag 7, ASSP_CHART_INFO_METER_PTR, ASSP_CHART_INFO_METER_LEN

.meta_next:
    inc r10
    jmp .meta_loop

.done:
    ret

; r10 = #NOTES value start, r11 = after terminating ';', rbx = assp_chart_info.
; eax = 1 when the value is an SM-style colon-field chart block.
parse_sm_notes_block:
    mov r8, r10
    mov r12, r10
    xor r13d, r13d

.scan:
    cmp r12, r11
    jae .fail
    cmp byte [r12], ';'
    je .fail
    cmp byte [r12], ':'
    jne .next

    mov rax, r12
    xor ecx, ecx
.slash_loop:
    cmp rax, r8
    jbe .slash_done
    dec rax
    cmp byte [rax], '\'
    jne .slash_done
    inc ecx
    jmp .slash_loop
.slash_done:
    test ecx, 1
    jnz .next

    cmp r13d, 0
    je .field_step_type
    cmp r13d, 1
    je .field_desc
    cmp r13d, 2
    je .field_difficulty
    cmp r13d, 3
    je .field_meter
    cmp r13d, 4
    je .field_done
    jmp .fail

.field_step_type:
    store_trim_field ASSP_CHART_INFO_STEP_TYPE_PTR, ASSP_CHART_INFO_STEP_TYPE_LEN
    jmp .advance_field

.field_desc:
    store_trim_field ASSP_CHART_INFO_DESC_PTR, ASSP_CHART_INFO_DESC_LEN
    jmp .advance_field

.field_difficulty:
    store_trim_field ASSP_CHART_INFO_DIFFICULTY_PTR, ASSP_CHART_INFO_DIFFICULTY_LEN
    jmp .advance_field

.field_meter:
    store_trim_field ASSP_CHART_INFO_METER_PTR, ASSP_CHART_INFO_METER_LEN
    jmp .advance_field

.field_done:
    lea rax, [r12 + 1]
    mov [rbx + ASSP_CHART_INFO_NOTES_PTR], rax
    mov rdx, r11
    sub rdx, rax
    mov [rbx + ASSP_CHART_INFO_NOTES_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.advance_field:
    inc r13d
    lea r8, [r12 + 1]

.next:
    inc r12
    jmp .scan

.fail:
    xor eax, eax
    ret

section .rdata

tag_bpms db "#BPMS:"
tag_bpms_end:
tag_stops db "#STOPS:"
tag_stops_end:
tag_freezes db "#FREEZES:"
tag_freezes_end:
tag_delays db "#DELAYS:"
tag_delays_end:
tag_warps db "#WARPS:"
tag_warps_end:
tag_speeds db "#SPEEDS:"
tag_speeds_end:
tag_scrolls db "#SCROLLS:"
tag_scrolls_end:
tag_fakes db "#FAKES:"
tag_fakes_end:
