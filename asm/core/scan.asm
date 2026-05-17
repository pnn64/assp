default rel
%include "asmssp.inc"

global asmssp_find_byte

section .text

; rcx = data, rdx = len, r8d = byte.
; rax = byte index, or ASMSSP_NOT_FOUND.
asmssp_find_byte:
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
    mov rax, ASMSSP_NOT_FOUND

.done:
    ret

