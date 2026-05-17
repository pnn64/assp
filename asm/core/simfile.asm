default rel
%include "asmssp.inc"

global asmssp_count_note_charts
global asmssp_find_notes_by_index

section .text

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
    mov eax, ASMSSP_TRUE
    jmp %%done
%%no:
    xor eax, eax
%%done:
%endmacro

; rcx = simfile bytes, rdx = len.
; rax = number of #NOTES: tags.
asmssp_count_note_charts:
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

; rcx = simfile bytes, rdx = len, r8 = chart index, r9 = out asmssp_chart_ref.
; eax = 1 when found, 0 otherwise.
asmssp_find_notes_by_index:
    test rcx, rcx
    jz .fail
    test r9, r9
    jz .fail
    cmp rdx, 7
    jb .fail

    mov qword [r9 + ASMSSP_CHART_REF_NOTES_PTR], 0
    mov qword [r9 + ASMSSP_CHART_REF_NOTES_LEN], 0
    mov [r9 + ASMSSP_CHART_REF_INDEX], r8

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
    mov [r9 + ASMSSP_CHART_REF_NOTES_PTR], rax
    sub rdx, rax
    mov [r9 + ASMSSP_CHART_REF_NOTES_LEN], rdx
    mov eax, ASMSSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

