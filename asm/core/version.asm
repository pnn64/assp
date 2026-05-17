default rel
%include "assp.inc"

global assp_version

section .text

assp_version:
    mov eax, ASSP_VERSION
    ret

