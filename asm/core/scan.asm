default rel
%include "assp.inc"

global assp_find_byte

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

