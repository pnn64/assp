default rel
%include "assp.inc"

global assp_sha1_short_hex2
global assp_chart_hash_pair
global assp_md5_hex

%define SHA_BUF 0
%define SHA_W 64
%define SHA_H0 384
%define SHA_H1 388
%define SHA_H2 392
%define SHA_H3 396
%define SHA_H4 400
%define SHA_BUF_LEN 408
%define SHA_TOTAL_LEN 416
%define SHA_OUT_PTR 424
%define SHA_A 432
%define SHA_B 436
%define SHA_C 440
%define SHA_D 444
%define SHA_E 448
%define SHA_DIGEST 456
%define SHA_SECOND_PTR 464
%define SHA_SECOND_LEN 472
%define SHA_LOCAL_SIZE 512

%define SHA_PAIR_CTX1 32
%define SHA_PAIR_CTX2 (SHA_PAIR_CTX1 + SHA_LOCAL_SIZE)
%define SHA_PAIR_CHART_PTR (SHA_PAIR_CTX2 + SHA_LOCAL_SIZE)
%define SHA_PAIR_CHART_LEN (SHA_PAIR_CHART_PTR + 8)
%define SHA_PAIR_BPM_PTR (SHA_PAIR_CHART_LEN + 8)
%define SHA_PAIR_BPM_LEN (SHA_PAIR_BPM_PTR + 8)
%define SHA_PAIR_OUT_PTR (SHA_PAIR_BPM_LEN + 8)
%define SHA_PAIR_LOCAL_SIZE 1104

%define MD5_BUF 0
%define MD5_TOTAL_LEN 64
%define MD5_BUF_LEN 72
%define MD5_OUT_PTR 80
%define MD5_H0 88
%define MD5_H1 92
%define MD5_H2 96
%define MD5_H3 100
%define MD5_A 104
%define MD5_B 108
%define MD5_C 112
%define MD5_D 116
%define MD5_LOCAL_SIZE 192

section .text

; rcx = data ptr, rdx = len, r8 = out32 ascii buffer.
; Writes the full lowercase MD5 hex digest. eax = 1 on success.
assp_md5_hex:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    sub rsp, MD5_LOCAL_SIZE + 8
    mov rbx, rsp
    mov [rbx + MD5_OUT_PTR], r8

    test r8, r8
    jz .md5_fail
    test rdx, rdx
    jz .md5_init
    test rcx, rcx
    jz .md5_fail

.md5_init:
    mov dword [rbx + MD5_H0], 0x67452301
    mov dword [rbx + MD5_H1], 0xefcdab89
    mov dword [rbx + MD5_H2], 0x98badcfe
    mov dword [rbx + MD5_H3], 0x10325476
    mov qword [rbx + MD5_TOTAL_LEN], rdx
    mov qword [rbx + MD5_BUF_LEN], 0

    call md5_update
    call md5_finish
    call md5_write_hex

    mov eax, ASSP_TRUE
    jmp .md5_done

.md5_fail:
    xor eax, eax

.md5_done:
    add rsp, MD5_LOCAL_SIZE + 8
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = first bytes, rdx = first len, r8 = second bytes, r9 = second len,
; stack arg 5 = out16 ascii buffer. eax = 1 on success, 0 on invalid pointers.
assp_sha1_short_hex2:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r10, [rsp + 96]
    sub rsp, SHA_LOCAL_SIZE
    mov rbx, rsp
    mov [rbx + SHA_OUT_PTR], r10
    mov [rbx + SHA_SECOND_PTR], r8
    mov [rbx + SHA_SECOND_LEN], r9

    test r10, r10
    jz .fail
    test rdx, rdx
    jz .check_second
    test rcx, rcx
    jz .fail

.check_second:
    test r9, r9
    jz .init
    test r8, r8
    jz .fail

.init:
    mov dword [rbx + SHA_H0], 0x67452301
    mov dword [rbx + SHA_H1], 0xefcdab89
    mov dword [rbx + SHA_H2], 0x98badcfe
    mov dword [rbx + SHA_H3], 0x10325476
    mov dword [rbx + SHA_H4], 0xc3d2e1f0
    mov qword [rbx + SHA_BUF_LEN], 0
    mov rax, rdx
    add rax, r9
    mov [rbx + SHA_TOTAL_LEN], rax

    call sha1_update

    mov rcx, [rbx + SHA_SECOND_PTR]
    mov rdx, [rbx + SHA_SECOND_LEN]
    call sha1_update

    call sha1_finish
    call sha1_write_short_hex

    mov eax, ASSP_TRUE
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, SHA_LOCAL_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = chart bytes, rdx = chart len, r8 = normalized BPM bytes,
; r9 = normalized BPM len, stack arg 5 = out32 ascii buffer.
; Writes chart hash at out32[0..16] and BPM-neutral hash at out32[16..32].
; eax = 1 on success, 0 on invalid pointers.
assp_chart_hash_pair:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov rbx, [rsp + 96]
    test rbx, rbx
    jz .fail
    test rdx, rdx
    jz .check_bpms
    test rcx, rcx
    jz .fail

.check_bpms:
    test r9, r9
    jz .init
    test r8, r8
    jz .fail

.init:
    sub rsp, SHA_PAIR_LOCAL_SIZE
    mov [rsp + SHA_PAIR_CHART_PTR], rcx
    mov [rsp + SHA_PAIR_CHART_LEN], rdx
    mov [rsp + SHA_PAIR_BPM_PTR], r8
    mov [rsp + SHA_PAIR_BPM_LEN], r9
    mov [rsp + SHA_PAIR_OUT_PTR], rbx

    lea rbx, [rsp + SHA_PAIR_CTX1]
    mov dword [rbx + SHA_H0], 0x67452301
    mov dword [rbx + SHA_H1], 0xefcdab89
    mov dword [rbx + SHA_H2], 0x98badcfe
    mov dword [rbx + SHA_H3], 0x10325476
    mov dword [rbx + SHA_H4], 0xc3d2e1f0
    mov qword [rbx + SHA_BUF_LEN], 0

    mov rcx, [rsp + SHA_PAIR_CHART_PTR]
    mov rdx, [rsp + SHA_PAIR_CHART_LEN]
    call sha1_update

    lea rsi, [rsp + SHA_PAIR_CTX1]
    lea rdi, [rsp + SHA_PAIR_CTX2]
    mov rax, [rsi + SHA_BUF + 0]
    mov [rdi + SHA_BUF + 0], rax
    mov rax, [rsi + SHA_BUF + 8]
    mov [rdi + SHA_BUF + 8], rax
    mov rax, [rsi + SHA_BUF + 16]
    mov [rdi + SHA_BUF + 16], rax
    mov rax, [rsi + SHA_BUF + 24]
    mov [rdi + SHA_BUF + 24], rax
    mov rax, [rsi + SHA_BUF + 32]
    mov [rdi + SHA_BUF + 32], rax
    mov rax, [rsi + SHA_BUF + 40]
    mov [rdi + SHA_BUF + 40], rax
    mov rax, [rsi + SHA_BUF + 48]
    mov [rdi + SHA_BUF + 48], rax
    mov rax, [rsi + SHA_BUF + 56]
    mov [rdi + SHA_BUF + 56], rax
    mov rax, [rsi + SHA_H0]
    mov [rdi + SHA_H0], rax
    mov rax, [rsi + SHA_H2]
    mov [rdi + SHA_H2], rax
    mov eax, [rsi + SHA_H4]
    mov [rdi + SHA_H4], eax
    mov rax, [rsi + SHA_BUF_LEN]
    mov [rdi + SHA_BUF_LEN], rax

    lea rbx, [rsp + SHA_PAIR_CTX1]
    mov rax, [rsp + SHA_PAIR_CHART_LEN]
    add rax, [rsp + SHA_PAIR_BPM_LEN]
    mov [rbx + SHA_TOTAL_LEN], rax
    mov rax, [rsp + SHA_PAIR_OUT_PTR]
    mov [rbx + SHA_OUT_PTR], rax
    mov rcx, [rsp + SHA_PAIR_BPM_PTR]
    mov rdx, [rsp + SHA_PAIR_BPM_LEN]
    call sha1_update
    call sha1_finish
    call sha1_write_short_hex

    lea rbx, [rsp + SHA_PAIR_CTX2]
    mov rax, [rsp + SHA_PAIR_CHART_LEN]
    add rax, 11
    mov [rbx + SHA_TOTAL_LEN], rax
    mov rax, [rsp + SHA_PAIR_OUT_PTR]
    add rax, 16
    mov [rbx + SHA_OUT_PTR], rax
    lea rcx, [neutral_bpms]
    mov edx, 11
    call sha1_update
    call sha1_finish
    call sha1_write_short_hex

    add rsp, SHA_PAIR_LOCAL_SIZE
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

; rcx = data ptr, rdx = len. Uses rbx as local base.
md5_update:
    test rdx, rdx
    jz .done

    mov r12, rcx
    mov r13, rdx
    mov rax, [rbx + MD5_BUF_LEN]
    test rax, rax
    jz .full_chunks

    mov r8, 64
    sub r8, rax
    cmp r13, r8
    jae .fill_buffer

    lea rcx, [rbx + MD5_BUF + rax]
    mov rdx, r12
    mov r8, r13
    call copy_bytes
    add [rbx + MD5_BUF_LEN], r13
    jmp .done

.fill_buffer:
    lea rcx, [rbx + MD5_BUF + rax]
    mov rdx, r12
    mov r14, r8
    call copy_bytes
    lea rcx, [rbx + MD5_BUF]
    call md5_compress_block
    mov qword [rbx + MD5_BUF_LEN], 0
    add r12, r14
    sub r13, r14

.full_chunks:
    cmp r13, 64
    jb .remainder
    mov rcx, r12
    call md5_compress_block
    add r12, 64
    sub r13, 64
    jmp .full_chunks

.remainder:
    test r13, r13
    jz .done
    lea rcx, [rbx + MD5_BUF]
    mov rdx, r12
    mov r8, r13
    call copy_bytes
    mov [rbx + MD5_BUF_LEN], r13

.done:
    ret

md5_finish:
    mov rax, [rbx + MD5_BUF_LEN]
    mov byte [rbx + MD5_BUF + rax], 0x80
    inc rax

    cmp rax, 56
    jbe .zero_to_len
    lea rcx, [rbx + MD5_BUF + rax]
    mov r8, 64
    sub r8, rax
    call zero_bytes
    lea rcx, [rbx + MD5_BUF]
    call md5_compress_block
    xor eax, eax

.zero_to_len:
    lea rcx, [rbx + MD5_BUF + rax]
    mov r8, 56
    sub r8, rax
    call zero_bytes

    mov rax, [rbx + MD5_TOTAL_LEN]
    shl rax, 3
    mov [rbx + MD5_BUF + 56], rax

    lea rcx, [rbx + MD5_BUF]
    call md5_compress_block
    ret

; rcx = 64-byte little-endian block. Uses rbx as local base.
align 16
md5_compress_block:
    push r12
    push r13
    push r14
    push r15
    mov rsi, rcx
    lea rdi, [md5_k]
    lea r11, [md5_s]
    mov r12d, [rbx + MD5_H0]
    mov r13d, [rbx + MD5_H1]
    mov r14d, [rbx + MD5_H2]
    mov r15d, [rbx + MD5_H3]
    xor r8d, r8d

align 16
.round_loop:
    cmp r8d, 16
    jb .round_f
    cmp r8d, 32
    jb .round_g
    cmp r8d, 48
    jb .round_h
    jmp .round_i

.round_f:
    mov r9d, r13d
    mov r10d, r9d
    and r9d, r14d
    not r10d
    and r10d, r15d
    or r9d, r10d
    mov r10d, r8d
    jmp .round_apply

.round_g:
    mov r9d, r15d
    mov r10d, r9d
    and r9d, r13d
    not r10d
    and r10d, r14d
    or r9d, r10d
    lea r10d, [r8 + r8 * 4 + 1]
    and r10d, 15
    jmp .round_apply

.round_h:
    mov r9d, r13d
    xor r9d, r14d
    xor r9d, r15d
    lea r10d, [r8 + r8 * 2 + 5]
    and r10d, 15
    jmp .round_apply

.round_i:
    mov r9d, r15d
    not r9d
    or r9d, r13d
    xor r9d, r14d
    lea r10d, [r8 * 8]
    sub r10d, r8d
    and r10d, 15

.round_apply:
    mov eax, r12d
    add eax, r9d
    add eax, [rdi + r8 * 4]
    add eax, [rsi + r10 * 4]
    movzx ecx, byte [r11 + r8]
    rol eax, cl
    add eax, r13d

    mov r12d, r15d
    mov r15d, r14d
    mov r14d, r13d
    mov r13d, eax

    inc r8d
    cmp r8d, 64
    jb .round_loop

    add [rbx + MD5_H0], r12d
    add [rbx + MD5_H1], r13d
    add [rbx + MD5_H2], r14d
    add [rbx + MD5_H3], r15d
    pop r15
    pop r14
    pop r13
    pop r12
    ret

md5_write_hex:
    mov rdi, [rbx + MD5_OUT_PTR]
    xor r8d, r8d
.hex_loop:
    cmp r8d, 16
    jae .done
    mov dl, [rbx + MD5_H0 + r8]
    call write_hex_byte
    inc r8d
    jmp .hex_loop
.done:
    ret

; rcx = data ptr, rdx = len. Uses rbx as local base.
sha1_update:
    test rdx, rdx
    jz .done

    mov r12, rcx
    mov r13, rdx
    mov rax, [rbx + SHA_BUF_LEN]
    test rax, rax
    jz .full_chunks

    mov r8, 64
    sub r8, rax
    cmp r13, r8
    jae .fill_buffer

    lea rcx, [rbx + SHA_BUF + rax]
    mov rdx, r12
    mov r8, r13
    call copy_bytes
    add [rbx + SHA_BUF_LEN], r13
    jmp .done

.fill_buffer:
    lea rcx, [rbx + SHA_BUF + rax]
    mov rdx, r12
    mov r14, r8
    call copy_bytes
    lea rcx, [rbx + SHA_BUF]
    call sha1_compress_block
    mov qword [rbx + SHA_BUF_LEN], 0
    add r12, r14
    sub r13, r14

.full_chunks:
    cmp r13, 64
    jb .remainder
    mov rcx, r12
    call sha1_compress_block
    add r12, 64
    sub r13, 64
    jmp .full_chunks

.remainder:
    test r13, r13
    jz .done
    lea rcx, [rbx + SHA_BUF]
    mov rdx, r12
    mov r8, r13
    call copy_bytes
    mov [rbx + SHA_BUF_LEN], r13

.done:
    ret

sha1_finish:
    mov rax, [rbx + SHA_BUF_LEN]
    mov byte [rbx + SHA_BUF + rax], 0x80
    inc rax

    cmp rax, 56
    jbe .zero_to_len
    lea rcx, [rbx + SHA_BUF + rax]
    mov r8, 64
    sub r8, rax
    call zero_bytes
    lea rcx, [rbx + SHA_BUF]
    call sha1_compress_block
    xor eax, eax

.zero_to_len:
    lea rcx, [rbx + SHA_BUF + rax]
    mov r8, 56
    sub r8, rax
    call zero_bytes

    mov rax, [rbx + SHA_TOTAL_LEN]
    shl rax, 3
    bswap rax
    mov [rbx + SHA_BUF + 56], rax

    lea rcx, [rbx + SHA_BUF]
    call sha1_compress_block
    ret

; rcx = 64-byte block. Uses rbx as local base.
align 16
sha1_compress_block:
    push r12
    push r13
    push r14
    push r15
    xor r8d, r8d
.load_loop:
    cmp r8d, 16
    jae .schedule
    mov eax, [rcx + r8 * 4]
    bswap eax
    mov [rbx + SHA_W + r8 * 4], eax
    inc r8d
    jmp .load_loop

.schedule:
    mov r8d, 16
.schedule_loop:
    cmp r8d, 80
    jae .round_init
%rep 4
    mov eax, [rbx + SHA_W + r8 * 4 - 12]
    xor eax, [rbx + SHA_W + r8 * 4 - 32]
    xor eax, [rbx + SHA_W + r8 * 4 - 56]
    xor eax, [rbx + SHA_W + r8 * 4 - 64]
    rol eax, 1
    mov [rbx + SHA_W + r8 * 4], eax
    inc r8d
%endrep
    jmp .schedule_loop

.round_init:
    mov r12d, [rbx + SHA_H0]
    mov r13d, [rbx + SHA_H1]
    mov r14d, [rbx + SHA_H2]
    mov r15d, [rbx + SHA_H3]
    mov edx, [rbx + SHA_H4]
    xor r8d, r8d

align 16
.round_ch_loop:
    mov r11d, r14d
    xor r11d, r15d
    and r11d, r13d
    xor r11d, r15d
    mov eax, r12d
    rol eax, 5
    add eax, r11d
    add eax, edx
    add eax, 0x5a827999
    add eax, [rbx + SHA_W + r8 * 4]

    mov edx, r15d
    mov r15d, r14d
    mov r14d, r13d
    rol r14d, 30
    mov r13d, r12d
    mov r12d, eax

    inc r8d
    cmp r8d, 20
    jb .round_ch_loop

align 16
.round_parity1_loop:
    mov r11d, r13d
    xor r11d, r14d
    xor r11d, r15d
    mov eax, r12d
    rol eax, 5
    add eax, r11d
    add eax, edx
    add eax, 0x6ed9eba1
    add eax, [rbx + SHA_W + r8 * 4]

    mov edx, r15d
    mov r15d, r14d
    mov r14d, r13d
    rol r14d, 30
    mov r13d, r12d
    mov r12d, eax

    inc r8d
    cmp r8d, 40
    jb .round_parity1_loop

align 16
.round_maj_loop:
    mov r11d, r13d
    or r11d, r14d
    and r11d, r15d
    mov r9d, r13d
    and r9d, r14d
    or r11d, r9d
    mov eax, r12d
    rol eax, 5
    add eax, r11d
    add eax, edx
    add eax, 0x8f1bbcdc
    add eax, [rbx + SHA_W + r8 * 4]

    mov edx, r15d
    mov r15d, r14d
    mov r14d, r13d
    rol r14d, 30
    mov r13d, r12d
    mov r12d, eax

    inc r8d
    cmp r8d, 60
    jb .round_maj_loop

align 16
.round_parity2_loop:
    mov r11d, r13d
    xor r11d, r14d
    xor r11d, r15d
    mov eax, r12d
    rol eax, 5
    add eax, r11d
    add eax, edx
    add eax, 0xca62c1d6
    add eax, [rbx + SHA_W + r8 * 4]

    mov edx, r15d
    mov r15d, r14d
    mov r14d, r13d
    rol r14d, 30
    mov r13d, r12d
    mov r12d, eax

    inc r8d
    cmp r8d, 80
    jb .round_parity2_loop

    add [rbx + SHA_H0], r12d
    add [rbx + SHA_H1], r13d
    add [rbx + SHA_H2], r14d
    add [rbx + SHA_H3], r15d
    add [rbx + SHA_H4], edx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

sha1_write_short_hex:
    mov rdi, [rbx + SHA_OUT_PTR]
    mov r9d, [rbx + SHA_H0]
    bswap r9d
    mov r8d, 4
.hex_h0_loop:
    mov dl, r9b
    call write_hex_byte
    shr r9d, 8
    dec r8d
    jnz .hex_h0_loop

    mov r9d, [rbx + SHA_H1]
    bswap r9d
    mov r8d, 4
.hex_h1_loop:
    mov dl, r9b
    call write_hex_byte
    shr r9d, 8
    dec r8d
    jnz .hex_h1_loop
.done:
    ret

; dl = byte, rdi = output cursor. Advances rdi by 2.
write_hex_byte:
    lea r11, [hex_chars]
    movzx ecx, dl
    shr ecx, 4
    mov al, [r11 + rcx]
    mov [rdi], al
    movzx ecx, dl
    and ecx, 0x0f
    mov al, [r11 + rcx]
    mov [rdi + 1], al
    add rdi, 2
    ret

; rcx = dest, rdx = src, r8 = len.
copy_bytes:
    push rdi
    push rsi
    mov rdi, rcx
    mov rsi, rdx
    mov rcx, r8
    rep movsb
    pop rsi
    pop rdi
    ret

; rcx = dest, r8 = len.
zero_bytes:
    push rdi
    mov rdi, rcx
    mov rcx, r8
    xor eax, eax
    rep stosb
    pop rdi
    ret

section .rdata

neutral_bpms db "0.000=0.000"
hex_chars db "0123456789abcdef"
md5_s db 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22
      db 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20
      db 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23
      db 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
md5_k dd 0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee
      dd 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501
      dd 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be
      dd 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821
      dd 0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa
      dd 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8
      dd 0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed
      dd 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a
      dd 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c
      dd 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70
      dd 0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05
      dd 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665
      dd 0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039
      dd 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1
      dd 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1
      dd 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
