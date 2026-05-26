default rel
%include "assp.inc"

global assp_count_note_charts
global assp_find_notes_by_index
global assp_find_chart_by_index
global assp_find_next_chart
global assp_find_global_bpms
global assp_find_chart_bpms_by_index
global assp_find_global_tag
global assp_find_global_tag_last
global assp_find_tag_in_range
global assp_find_chart_tag_by_index
global assp_find_global_timing_tags
global assp_find_timing_tags_in_range
global assp_find_chart_timing_tags_by_index
global assp_range_owns_timing
global assp_chart_owns_timing_by_index
global assp_supported_step_type_lanes

section .text

%macro find_range_byte 2
    cmp %1, r11
    jae %%not_found

%%wide:
    lea rax, [%1 + 16]
    cmp rax, r11
    ja %%tail
    movdqu xmm0, [%1]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask
    add %1, 16
    lea rax, [%1 + 64]
    cmp rax, r11
    ja %%tail_or_32
    jmp %%wide64

%%wide64:
    movdqu xmm0, [%1]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask
    movdqu xmm0, [%1 + 16]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask_hi
    movdqu xmm0, [%1 + 32]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask_32
    movdqu xmm0, [%1 + 48]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask_48
    add %1, 64
    lea rax, [%1 + 64]
    cmp rax, r11
    jbe %%wide64

%%tail_or_32:
    lea rax, [%1 + 32]
    cmp rax, r11
    ja %%tail_or_16

%%wide32:
    movdqu xmm0, [%1]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask
    movdqu xmm0, [%1 + 16]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask_hi
    add %1, 32
    lea rax, [%1 + 32]
    cmp rax, r11
    jbe %%wide32

%%tail_or_16:
    lea rax, [%1 + 16]
    cmp rax, r11
    ja %%tail
    movdqu xmm0, [%1]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    test eax, eax
    jnz %%mask
    add %1, 16
    jmp %%tail

%%mask:
    bsf eax, eax
    add %1, rax
    mov eax, ASSP_TRUE
    ret

%%mask_hi:
    bsf eax, eax
    lea %1, [%1 + rax + 16]
    mov eax, ASSP_TRUE
    ret

%%mask_32:
    bsf eax, eax
    lea %1, [%1 + rax + 32]
    mov eax, ASSP_TRUE
    ret

%%mask_48:
    bsf eax, eax
    lea %1, [%1 + rax + 48]
    mov eax, ASSP_TRUE
    ret

%%tail:
    cmp %1, r11
    jae %%not_found
    cmp byte [%1], %2
    je %%found
    inc %1
    jmp %%tail

%%found:
    mov eax, ASSP_TRUE
    ret

%%not_found:
    xor eax, eax
    ret
%endmacro

%macro check_timing_tag_at 2
    lea rax, [r10 + %2]
    cmp rax, r11
    ja %%done
    lea r12, [%1]
    mov r13, %2
    call match_tag_at
    test eax, eax
    jnz .yes
%%done:
%endmacro

%macro collect_timing_tag_at 3
    cmp qword [r15 + %3 + ASSP_BYTE_SLICE_PTR], 0
    jne %%done
    lea rax, [r10 + %2]
    cmp rax, r11
    ja %%done
    lea r12, [%1]
    mov r13, %2
    call match_tag_at
    test eax, eax
    jz %%done
    lea rbx, [r15 + %3]
    call store_tag_value_at
%%done:
%endmacro

%macro expect_alpha_ci 4
    cmp byte [%1 + %2], %3
    je %%ok
    cmp byte [%1 + %2], %3 + 32
    jne %4
%%ok:
%endmacro

%macro expect_exact 4
    cmp byte [%1 + %2], %3
    jne %4
%endmacro

%macro is_notes_tag 1
    expect_exact %1, 0, '#', %%no
    expect_alpha_ci %1, 1, 'N', %%no
    expect_alpha_ci %1, 2, 'O', %%no
    expect_alpha_ci %1, 3, 'T', %%no
    expect_alpha_ci %1, 4, 'E', %%no
    expect_alpha_ci %1, 5, 'S', %%no
    cmp byte [%1 + 6], ':'
    je %%notes
    cmp byte [%1 + 6], '2'
    jne %%no
    cmp byte [%1 + 7], ':'
    jne %%no
    mov eax, 8
    jmp %%done
%%notes:
    mov eax, 7
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro is_notedata_tag 1
    expect_exact %1, 0, '#', %%no
    expect_alpha_ci %1, 1, 'N', %%no
    expect_alpha_ci %1, 2, 'O', %%no
    expect_alpha_ci %1, 3, 'T', %%no
    expect_alpha_ci %1, 4, 'E', %%no
    expect_alpha_ci %1, 5, 'D', %%no
    expect_alpha_ci %1, 6, 'A', %%no
    expect_alpha_ci %1, 7, 'T', %%no
    expect_alpha_ci %1, 8, 'A', %%no
    expect_exact %1, 9, ':', %%no
    mov eax, ASSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro is_bpms_tag 1
    expect_exact %1, 0, '#', %%no
    expect_alpha_ci %1, 1, 'B', %%no
    expect_alpha_ci %1, 2, 'P', %%no
    expect_alpha_ci %1, 3, 'M', %%no
    expect_alpha_ci %1, 4, 'S', %%no
    expect_exact %1, 5, ':', %%no
    mov eax, ASSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

%macro store_tag 3
    lea rax, [r10 + %1]
    mov rdx, rax
    call find_semicolon
    test eax, eax
    jz .meta_next
    lea rax, [r10 + %1]
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
; rax = number of #NOTES:/#NOTES2: tags.
assp_count_note_charts:
    test rcx, rcx
    jz .zero
    cmp rdx, 8
    jb .zero

    mov r10, rcx
    lea r11, [rcx + rdx]
    xor r8d, r8d

.scan:
    call find_hash
    test eax, eax
    jz .done

    lea rax, [r10 + 8]
    cmp rax, r11
    ja .done

    is_notes_tag r10
    test eax, eax
    jz .next
    inc r8
    add r10, rax
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

; rcx = step type bytes, rdx = len.
; rax = supported lane count: 4 for dance-single, 8 for dance-double, 0 otherwise.
assp_supported_step_type_lanes:
    test rcx, rcx
    jz .zero

    mov r10, rcx
    lea r11, [rcx + rdx]

.trim_left:
    cmp r10, r11
    jae .zero
    cmp byte [r10], ' '
    ja .trim_right
    inc r10
    jmp .trim_left

.trim_right:
    cmp r11, r10
    jbe .zero
    cmp byte [r11 - 1], ' '
    ja .match
    dec r11
    jmp .trim_right

.match:
    mov rax, r11
    sub rax, r10
    cmp rax, tag_dance_single_dash_end - tag_dance_single_dash
    jne .zero

    lea r12, [tag_dance_single_dash]
    mov r13, tag_dance_single_dash_end - tag_dance_single_dash
    call match_tag_at
    test eax, eax
    jnz .single

    lea r12, [tag_dance_single_under]
    mov r13, tag_dance_single_under_end - tag_dance_single_under
    call match_tag_at
    test eax, eax
    jnz .single

    lea r12, [tag_dance_double_dash]
    mov r13, tag_dance_double_dash_end - tag_dance_double_dash
    call match_tag_at
    test eax, eax
    jnz .double

    lea r12, [tag_dance_double_under]
    mov r13, tag_dance_double_under_end - tag_dance_double_under
    call match_tag_at
    test eax, eax
    jnz .double

.zero:
    xor eax, eax
    ret

.single:
    mov eax, 4
    ret

.double:
    mov eax, 8
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
    call find_global_scan_end

.scan:
    call find_hash
    test eax, eax
    jz .fail

    lea rax, [r10 + 6]
    cmp rax, r11
    ja .fail

    is_bpms_tag r10
    test eax, eax
    jnz .found

.next:
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + 6]
    mov rdx, rax
    call find_semicolon
    test eax, eax
    jz .fail
    lea rax, [r10 + 6]

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
    cmp rdx, 8
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
    mov r10, rdi
    mov r11, r12
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, r12
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, rax
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
    call find_global_scan_end
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

; rcx = simfile bytes, rdx = len, r8 = tag bytes, r9 = tag len,
; stack arg 5 = out assp_byte_slice.
; The tag must include the leading '#' and trailing ':'.
; eax = 1 when found, 0 otherwise. Stores the last global match.
assp_find_global_tag_last:
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
    call find_global_scan_end
    mov r12, r8
    mov r13, r9
    xor r15d, r15d

.scan:
    call find_hash
    test eax, eax
    jz .done_scan

    lea rax, [r10 + r13]
    cmp rax, r11
    ja .done_scan

    call match_tag_at
    test eax, eax
    jz .next
    call store_tag_value_at
    test eax, eax
    jz .next
    mov r15d, ASSP_TRUE

.next:
    inc r10
    jmp .scan

.done_scan:
    mov eax, r15d
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

; rcx = range bytes, rdx = len, r8 = tag bytes, r9 = tag len,
; stack arg 5 = out assp_byte_slice.
; The tag must include the leading '#' and trailing ':'.
; eax = 1 when found, 0 otherwise.
assp_find_tag_in_range:
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
    cmp rdx, 8
    jb .fail

    mov qword [rbx + ASSP_BYTE_SLICE_PTR], 0
    mov qword [rbx + ASSP_BYTE_SLICE_LEN], 0

    mov rdi, rcx
    lea rsi, [rcx + rdx]
    mov r13, r8
    xor r14d, r14d
    xor r15d, r15d

.scan:
    mov r10, rdi
    mov r11, rsi
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, rsi
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, rax
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
    call find_global_scan_end
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

; rcx = range bytes, rdx = len, r8 = out assp_timing_tags.
; eax = 1 on valid input. Missing tags remain empty slices.
assp_find_timing_tags_in_range:
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
    cmp rdx, 8
    jb .fail

    mov r13, r8
    mov rbx, r9
    call zero_timing_tags

    mov rdi, rcx
    lea rsi, [rcx + rdx]
    xor r14d, r14d
    xor r15d, r15d

.scan:
    mov r10, rdi
    mov r11, rsi
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, rsi
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, rax
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

; rcx = range bytes, rdx = len.
; eax = 1 when the range has chart-owned timing, 0 otherwise.
assp_range_owns_timing:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail

    mov r10, rcx
    lea r11, [rcx + rdx]
    call range_owns_timing
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

; rcx = simfile bytes, rdx = len, r8 = chart index.
; eax = 1 when the selected SSC chart has chart-owned timing, 0 otherwise.
assp_chart_owns_timing_by_index:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .fail
    cmp rdx, 8
    jb .fail

    mov rdi, rcx
    lea rsi, [rcx + rdx]
    mov r13, r8
    xor r14d, r14d
    xor r15d, r15d

.scan:
    mov r10, rdi
    mov r11, rsi
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, rsi
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found_chart
    inc r14
    add rdi, rax
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found_chart:
    test r15, r15
    jz .fail
    mov r10, r15
    mov r11, rdi
    call range_owns_timing
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
    cmp rdx, 8
    jb .fail

    mov qword [r9 + ASSP_CHART_REF_NOTES_PTR], 0
    mov qword [r9 + ASSP_CHART_REF_NOTES_LEN], 0
    mov [r9 + ASSP_CHART_REF_INDEX], r8

    mov r10, rcx
    lea r11, [rcx + rdx]
    xor ecx, ecx

.scan:
    call find_hash
    test eax, eax
    jz .fail

    lea rax, [r10 + 8]
    cmp rax, r11
    ja .fail

    is_notes_tag r10
    test eax, eax
    jz .next

    cmp rcx, r8
    je .found
    inc rcx
    add r10, rax
    jmp .scan

.next:
    inc r10
    jmp .scan

.found:
    add rax, r10
    mov r8, rax
    mov rdx, rax

    call find_semicolon
    test eax, eax
    jz .fail
    mov rax, r8

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
    cmp rdx, 8
    jb .fail

    mov rbx, r9
    mov rsi, rcx
    xor eax, eax
    mov rdi, rbx
    mov ecx, ASSP_CHART_INFO_SIZE / 8
    rep stosq

    mov [rbx + ASSP_CHART_INFO_INDEX], r8
    mov rdi, rsi
    lea r12, [rsi + rdx]
    mov r13, r8
    xor r14d, r14d
    mov r15, rsi

.scan:
    mov r10, rdi
    mov r11, r12
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, r12
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jz .next

    cmp r14, r13
    je .found
    inc r14
    add rdi, rax
    jmp .scan

.next:
    inc rdi
    jmp .scan

.found:
    mov [rbx + ASSP_CHART_INFO_META_PTR], r15
    mov rdx, rdi
    sub rdx, r15
    mov [rbx + ASSP_CHART_INFO_META_LEN], rdx

    lea rsi, [rdi + rax]
    mov rdx, rsi

    mov r11, r12
    call find_semicolon
    test eax, eax
    jz .fail

.store_notes:
    inc rdx
    mov r14, rdx
    mov r10, r15
    lea rax, [r10 + 10]
    cmp rax, r12
    ja .try_sm_notes
    is_notedata_tag r10
    test eax, eax
    jnz .store_ssc_notes

.try_sm_notes:
    mov r10, rsi
    mov r11, r14
    call parse_sm_notes_block
    test eax, eax
    jnz .success

.store_ssc_notes:
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

; rcx = simfile bytes, rdx = len, r8 = byte offset to start scanning,
; r9 = out assp_chart_info.
; eax = 1 when the next chart at or after the offset is found, 0 otherwise.
assp_find_next_chart:
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
    cmp rdx, 8
    jb .fail
    cmp r8, rdx
    jae .fail

    mov rbx, r9
    mov rsi, rcx
    xor eax, eax
    mov rdi, rbx
    mov ecx, ASSP_CHART_INFO_SIZE / 8
    rep stosq

    lea r12, [rsi + rdx]
    lea rdi, [rsi + r8]
    mov r15, rsi
    test r8, r8
    jz .scan
    mov r15, rdi

.scan:
    mov r10, rdi
    mov r11, r12
    call find_hash
    test eax, eax
    jz .fail
    mov rdi, r10

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
    lea rax, [rdi + 8]
    cmp rax, r12
    ja .fail
    is_notes_tag rdi
    test eax, eax
    jnz .found

.next:
    inc rdi
    jmp .scan

.found:
    mov [rbx + ASSP_CHART_INFO_META_PTR], r15
    mov rdx, rdi
    sub rdx, r15
    mov [rbx + ASSP_CHART_INFO_META_LEN], rdx

    lea rsi, [rdi + rax]
    mov rdx, rsi

    mov r11, r12
    call find_semicolon
    test eax, eax
    jz .fail

.store_notes:
    inc rdx
    mov r14, rdx
    mov r10, r15
    lea rax, [r10 + 10]
    cmp rax, r12
    ja .try_sm_notes
    is_notedata_tag r10
    test eax, eax
    jnz .store_ssc_notes

.try_sm_notes:
    mov r10, rsi
    mov r11, r14
    call parse_sm_notes_block
    test eax, eax
    jnz .success

.store_ssc_notes:
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
    call find_hash
    test eax, eax
    jz .fail

    lea rax, [r10 + 6]
    cmp rax, r11
    ja .fail

    is_bpms_tag r10
    test eax, eax
    jnz .found

.next:
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + 6]
    mov rdx, rax
    call find_semicolon
    test eax, eax
    jz .fail
    lea rax, [r10 + 6]

.store:
    mov [rbx + ASSP_BYTE_SLICE_PTR], rax
    sub rdx, rax
    mov [rbx + ASSP_BYTE_SLICE_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; r10 = simfile start, r11 = simfile end.
; Narrows r11 to the first chart section so global scans do not consume
; chart-local SSC tags.
find_global_scan_end:
    push r10
    mov rdx, r10

.scan:
    mov r10, rdx
    call find_hash
    test eax, eax
    jz .done
    mov rdx, r10

    lea rax, [rdx + 10]
    cmp rax, r11
    ja .check_notes
    is_notedata_tag rdx
    test eax, eax
    jnz .found

.check_notes:
    lea rax, [rdx + 8]
    cmp rax, r11
    ja .next
    is_notes_tag rdx
    test eax, eax
    jnz .found

.next:
    inc rdx
    jmp .scan

.found:
    mov r11, rdx

.done:
    pop r10
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
    call find_hash
    test eax, eax
    jz .fail

    lea rax, [r10 + r13]
    cmp rax, r11
    ja .fail

    call match_tag_at
    test eax, eax
    jnz .found

.next:
    inc r10
    jmp .scan

.found:
    lea rax, [r10 + r13]
    mov rdx, rax
    call find_semicolon
    test eax, eax
    jz .line_terminator_only
    mov r8, rdx
    lea rdx, [r10 + r13]
    call find_line_tag_terminator
    test eax, eax
    jz .use_semicolon
    cmp rdx, r8
    jb .terminator_ready
.use_semicolon:
    mov rdx, r8
    jmp .terminator_ready

.line_terminator_only:
    lea rdx, [r10 + r13]
    call find_line_tag_terminator
    test eax, eax
    jz .fail
.terminator_ready:
    lea rax, [r10 + r13]

.store:
    mov [rbx + ASSP_BYTE_SLICE_PTR], rax
    sub rdx, rax
    mov [rbx + ASSP_BYTE_SLICE_LEN], rdx
    mov eax, ASSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

; r10 = matched tag ptr, r11 = scan end, r13 = tag len,
; rbx = out assp_byte_slice. eax = 1 when stored.
store_tag_value_at:
    lea rax, [r10 + r13]
    mov rdx, rax
    call find_semicolon
    test eax, eax
    jz .line_terminator_only
    mov r8, rdx
    lea rdx, [r10 + r13]
    call find_line_tag_terminator
    test eax, eax
    jz .use_semicolon
    cmp rdx, r8
    jb .terminator_ready
.use_semicolon:
    mov rdx, r8
    jmp .terminator_ready

.line_terminator_only:
    lea rdx, [r10 + r13]
    call find_line_tag_terminator
    test eax, eax
    jz .fail
.terminator_ready:
    lea rax, [r10 + r13]

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
    mov dl, [r12 + r8]
    cmp al, dl
    je .next
    cmp dl, 'A'
    jb .no
    cmp dl, 'Z'
    jbe .tag_upper
    cmp dl, 'a'
    jb .no
    cmp dl, 'z'
    ja .no
    sub dl, 32
    cmp al, dl
    jne .no
    jmp .next
.tag_upper:
    add dl, 32
    cmp al, dl
    jne .no
.next:
    inc r8
    jmp .loop
.yes:
    mov eax, ASSP_TRUE
    ret
.no:
    xor eax, eax
    ret

; r10 = scan start, r11 = scan end. r10 is advanced to the next '#'.
; eax = 1 when found, 0 otherwise.
find_hash:
    movdqa xmm1, [hash_bytes]
    find_range_byte r10, '#'

; rdx = scan start, r11 = scan end. rdx is advanced to the next ';'.
; eax = 1 when found, 0 otherwise.
find_semicolon:
    movdqa xmm1, [semicolon_bytes]
    find_range_byte rdx, ';'

; rdx = scan start, r11 = scan end. rdx is advanced to a line break
; that is followed by optional whitespace and another tag. This accepts
; broken one-line metadata tags without truncating multiline timing tags.
; eax = 1 when found, 0 otherwise.
find_line_tag_terminator:
    movdqa xmm1, [lf_bytes]
    movdqa xmm3, [cr_bytes]

.scan:
    cmp rdx, r11
    jae .not_found
    lea rax, [rdx + 16]
    cmp rax, r11
    ja .tail
    movdqu xmm0, [rdx]
    movdqa xmm2, xmm0
    pcmpeqb xmm0, xmm1
    pcmpeqb xmm2, xmm3
    por xmm0, xmm2
    pmovmskb eax, xmm0
    test eax, eax
    jnz .mask
    add rdx, 16
    jmp .scan

.mask:
    bsf eax, eax
    add rdx, rax
    jmp .check_next_tag

.tail:
    cmp rdx, r11
    jae .not_found
    mov al, [rdx]
    cmp al, 10
    je .check_next_tag
    cmp al, 13
    je .check_next_tag
    inc rdx
    jmp .tail

.check_next_tag:
    mov r9, rdx
    inc r9

.skip_ws:
    cmp r9, r11
    jae .continue_after_line
    mov al, [r9]
    cmp al, '#'
    je .found
    cmp al, 10
    je .next_ws
    cmp al, 13
    je .next_ws
    cmp al, ' '
    je .next_ws
    cmp al, 9
    jne .continue_after_line
.next_ws:
    inc r9
    jmp .skip_ws

.continue_after_line:
    inc rdx
    jmp .scan

.found:
    mov eax, ASSP_TRUE
    ret

.not_found:
    xor eax, eax
    ret

; r10 = metadata scan start, r11 = metadata end.
; eax = 1 when the chart has any RSSP chart-owned timing tag.
range_owns_timing:
.scan:
    call find_hash
    test eax, eax
    jz .no

    lea rax, [r10 + 1]
    cmp rax, r11
    jae .next
    mov al, [r10 + 1]
    or al, 32
    cmp al, 'b'
    je .check_b
    cmp al, 'c'
    je .check_c
    cmp al, 'd'
    je .check_d
    cmp al, 'f'
    je .check_f
    cmp al, 'l'
    je .check_l
    cmp al, 'o'
    je .check_o
    cmp al, 's'
    je .check_s
    cmp al, 't'
    je .check_t
    cmp al, 'w'
    je .check_w
    jmp .next

.check_b:
    check_timing_tag_at tag_bpms, tag_bpms_end - tag_bpms
    jmp .next

.check_c:
    check_timing_tag_at tag_combos, tag_combos_end - tag_combos
    jmp .next

.check_d:
    check_timing_tag_at tag_delays, tag_delays_end - tag_delays
    jmp .next

.check_f:
    check_timing_tag_at tag_freezes, tag_freezes_end - tag_freezes
    check_timing_tag_at tag_fakes, tag_fakes_end - tag_fakes
    jmp .next

.check_l:
    check_timing_tag_at tag_labels, tag_labels_end - tag_labels
    jmp .next

.check_o:
    check_timing_tag_at tag_offset, tag_offset_end - tag_offset
    jmp .next

.check_s:
    check_timing_tag_at tag_stops, tag_stops_end - tag_stops
    check_timing_tag_at tag_speeds, tag_speeds_end - tag_speeds
    check_timing_tag_at tag_scrolls, tag_scrolls_end - tag_scrolls
    jmp .next

.check_t:
    check_timing_tag_at tag_time_signatures, tag_time_signatures_end - tag_time_signatures
    check_timing_tag_at tag_tickcounts, tag_tickcounts_end - tag_tickcounts
    jmp .next

.check_w:
    check_timing_tag_at tag_warps, tag_warps_end - tag_warps
    jmp .next

.next:
    inc r10
    jmp .scan

.no:
    xor eax, eax
    ret

.yes:
    mov eax, ASSP_TRUE
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
    mov r15, rbx
    call zero_timing_tags
    xor r14d, r14d

.scan:
    call find_hash
    test eax, eax
    jz .done

    lea rax, [r10 + 1]
    cmp rax, r11
    jae .next
    mov al, [r10 + 1]
    or al, 32
    cmp al, 'b'
    je .check_b
    cmp al, 'd'
    je .check_d
    cmp al, 'f'
    je .check_f
    cmp al, 's'
    je .check_s
    cmp al, 'w'
    je .check_w
    jmp .next

.check_b:
    collect_timing_tag_at tag_bpms, tag_bpms_end - tag_bpms, ASSP_TIMING_TAGS_BPMS
    jmp .next

.check_d:
    collect_timing_tag_at tag_delays, tag_delays_end - tag_delays, ASSP_TIMING_TAGS_DELAYS
    jmp .next

.check_f:
    cmp r14d, 0
    jne .check_fakes
    cmp qword [r15 + ASSP_TIMING_TAGS_STOPS + ASSP_BYTE_SLICE_PTR], 0
    jne .check_fakes
    lea rax, [r10 + tag_freezes_end - tag_freezes]
    cmp rax, r11
    ja .check_fakes
    lea r12, [tag_freezes]
    mov r13, tag_freezes_end - tag_freezes
    call match_tag_at
    test eax, eax
    jz .check_fakes
    lea rbx, [r15 + ASSP_TIMING_TAGS_STOPS]
    call store_tag_value_at
    test eax, eax
    jnz .next

.check_fakes:
    collect_timing_tag_at tag_fakes, tag_fakes_end - tag_fakes, ASSP_TIMING_TAGS_FAKES
    jmp .next

.check_s:
    cmp r14d, 0
    jne .check_s_other
    lea rax, [r10 + tag_stops_end - tag_stops]
    cmp rax, r11
    ja .check_s_other
    lea r12, [tag_stops]
    mov r13, tag_stops_end - tag_stops
    call match_tag_at
    test eax, eax
    jz .check_s_other
    lea rbx, [r15 + ASSP_TIMING_TAGS_STOPS]
    call store_tag_value_at
    test eax, eax
    jz .check_s_other
    mov r14d, ASSP_TRUE
    jmp .next

.check_s_other:
    collect_timing_tag_at tag_speeds, tag_speeds_end - tag_speeds, ASSP_TIMING_TAGS_SPEEDS
    collect_timing_tag_at tag_scrolls, tag_scrolls_end - tag_scrolls, ASSP_TIMING_TAGS_SCROLLS
    jmp .next

.check_w:
    collect_timing_tag_at tag_warps, tag_warps_end - tag_warps, ASSP_TIMING_TAGS_WARPS
    jmp .next

.next:
    inc r10
    jmp .scan

.done:
    ret

; r10 = metadata scan start, r11 = metadata end, rbx = assp_chart_info.
parse_chart_meta:
.meta_loop:
    call find_hash
    test eax, eax
    jz .done

    lea rax, [r10 + 3]
    cmp rax, r11
    ja .meta_next
    movzx eax, word [r10 + 1]
    or ax, 2020h
    cmp ax, 6564h
    je .check_description
    cmp ax, 6964h
    je .check_difficulty
    cmp ax, 7473h
    je .check_step_type
    cmp ax, 656dh
    je .check_meter
    jmp .meta_next

.check_description:
    lea rax, [r10 + tag_description_end - tag_description]
    cmp rax, r11
    ja .meta_next
    mov rax, [r10]
    mov rdx, 2020202020202000h
    or rax, rdx
    mov rdx, 7069726373656423h
    cmp rax, rdx
    jne .meta_next
    mov eax, [r10 + 8]
    or eax, 20202020h
    cmp eax, 6e6f6974h
    jne .meta_next
    cmp byte [r10 + 12], ':'
    jne .meta_next
    store_tag tag_description_end - tag_description, ASSP_CHART_INFO_DESC_PTR, ASSP_CHART_INFO_DESC_LEN

.check_difficulty:
    lea rax, [r10 + tag_difficulty_end - tag_difficulty]
    cmp rax, r11
    ja .meta_next
    mov rax, [r10]
    mov rdx, 2020202020202000h
    or rax, rdx
    mov rdx, 7563696666696423h
    cmp rax, rdx
    jne .meta_next
    mov eax, [r10 + 8]
    or eax, 00202020h
    cmp eax, 3a79746ch
    jne .meta_next
    store_tag tag_difficulty_end - tag_difficulty, ASSP_CHART_INFO_DIFFICULTY_PTR, ASSP_CHART_INFO_DIFFICULTY_LEN

.check_step_type:
    lea rax, [r10 + tag_step_type_end - tag_step_type]
    cmp rax, r11
    ja .meta_next
    mov rax, [r10]
    mov rdx, 2020202020202000h
    or rax, rdx
    mov rdx, 7974737065747323h
    cmp rax, rdx
    jne .meta_next
    movzx eax, word [r10 + 8]
    or ax, 2020h
    cmp ax, 6570h
    jne .meta_next
    cmp byte [r10 + 10], ':'
    jne .meta_next
    store_tag tag_step_type_end - tag_step_type, ASSP_CHART_INFO_STEP_TYPE_PTR, ASSP_CHART_INFO_STEP_TYPE_LEN

.check_meter:
    lea rax, [r10 + tag_meter_end - tag_meter]
    cmp rax, r11
    ja .meta_next
    mov eax, [r10]
    or eax, 20202000h
    cmp eax, 74656d23h
    jne .meta_next
    movzx eax, word [r10 + 4]
    or ax, 2020h
    cmp ax, 7265h
    jne .meta_next
    cmp byte [r10 + 6], ':'
    jne .meta_next
    store_tag tag_meter_end - tag_meter, ASSP_CHART_INFO_METER_PTR, ASSP_CHART_INFO_METER_LEN

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
    mov r8, rax
    mov rdx, rax

.note_data_scan:
    cmp rdx, r11
    jae .store_note_data
    cmp byte [rdx], ';'
    je .store_note_data_with_semicolon
    cmp byte [rdx], ':'
    jne .note_data_next

    mov rax, rdx
    xor ecx, ecx
.note_slash_loop:
    cmp rax, r8
    jbe .note_slash_done
    dec rax
    cmp byte [rax], '\'
    jne .note_slash_done
    inc ecx
    jmp .note_slash_loop
.note_slash_done:
    test ecx, 1
    jz .store_note_data

.note_data_next:
    inc rdx
    jmp .note_data_scan

.store_note_data_with_semicolon:
    inc rdx

.store_note_data:
    mov rax, r8
    mov [rbx + ASSP_CHART_INFO_NOTES_PTR], rax
    sub rdx, r8
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

align 16
hash_bytes times 16 db '#'
semicolon_bytes times 16 db ';'
lf_bytes times 16 db 10
cr_bytes times 16 db 13

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
tag_offset db "#OFFSET:"
tag_offset_end:
tag_time_signatures db "#TIMESIGNATURES:"
tag_time_signatures_end:
tag_labels db "#LABELS:"
tag_labels_end:
tag_tickcounts db "#TICKCOUNTS:"
tag_tickcounts_end:
tag_combos db "#COMBOS:"
tag_combos_end:
tag_description db "#DESCRIPTION:"
tag_description_end:
tag_difficulty db "#DIFFICULTY:"
tag_difficulty_end:
tag_step_type db "#STEPSTYPE:"
tag_step_type_end:
tag_meter db "#METER:"
tag_meter_end:
tag_dance_single_dash db "dance-single"
tag_dance_single_dash_end:
tag_dance_single_under db "dance_single"
tag_dance_single_under_end:
tag_dance_double_dash db "dance-double"
tag_dance_double_dash_end:
tag_dance_double_under db "dance_double"
tag_dance_double_under_end:
