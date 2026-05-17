default rel
%include "asmssp.inc"

global asmssp_version

section .text

asmssp_version:
    mov eax, ASMSSP_VERSION
    ret

