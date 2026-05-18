default rel
%include "assp.inc"

global assp_find_byte
global assp_count_timing_segments

section .text

; rcx = data, rdx = len, r8d = byte.
; rax = byte index, or ASSP_NOT_FOUND.
assp_find_byte:
    test rdx, rdx
    jz .not_found
    test rcx, rcx
    jz .not_found

    xor rax, rax

.loop:
    cmp byte [rcx + rax], r8b
    je .done
    inc rax
    cmp rax, rdx
    jb .loop

.not_found:
    mov rax, ASSP_NOT_FOUND

.done:
    ret

; rcx = comma-separated timing map bytes, rdx = len.
; rax = count of non-empty trimmed segments, or ASSP_NOT_FOUND on invalid ptr.
assp_count_timing_segments:
    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .not_found

    xor eax, eax
    xor r8d, r8d
    xor r9d, r9d

.loop:
    cmp r8, rdx
    jae .end_segment
    mov r10b, [rcx + r8]
    cmp r10b, ','
    je .comma
    cmp r10b, ' '
    jbe .next
    mov r9d, 1
.next:
    inc r8
    jmp .loop

.comma:
    test r9d, r9d
    jz .comma_done
    inc rax
.comma_done:
    xor r9d, r9d
    inc r8
    jmp .loop

.end_segment:
    test r9d, r9d
    jz .done
    inc rax
    jmp .done

.zero:
    xor eax, eax
    jmp .done

.not_found:
    mov rax, ASSP_NOT_FOUND

.done:
    ret
