default rel
%include "assp.inc"

global assp_sha1_short_hex2
global assp_chart_hash_pair

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

section .text

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
    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9

    sub rsp, 48
    mov [rsp + 32], rbx
    mov rcx, r12
    mov rdx, r13
    mov r8, r14
    mov r9, r15
    call assp_sha1_short_hex2
    test eax, eax
    jz .call_fail

    lea rax, [rbx + 16]
    mov [rsp + 32], rax
    mov rcx, r12
    mov rdx, r13
    lea r8, [neutral_bpms]
    mov r9d, 11
    call assp_sha1_short_hex2
    test eax, eax
    jz .call_fail

    add rsp, 48
    mov eax, ASSP_TRUE
    jmp .done

.call_fail:
    add rsp, 48

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
sha1_compress_block:
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
    mov eax, [rbx + SHA_W + r8 * 4 - 12]
    xor eax, [rbx + SHA_W + r8 * 4 - 32]
    xor eax, [rbx + SHA_W + r8 * 4 - 56]
    xor eax, [rbx + SHA_W + r8 * 4 - 64]
    rol eax, 1
    mov [rbx + SHA_W + r8 * 4], eax
    inc r8d
    jmp .schedule_loop

.round_init:
    mov eax, [rbx + SHA_H0]
    mov [rbx + SHA_A], eax
    mov eax, [rbx + SHA_H1]
    mov [rbx + SHA_B], eax
    mov eax, [rbx + SHA_H2]
    mov [rbx + SHA_C], eax
    mov eax, [rbx + SHA_H3]
    mov [rbx + SHA_D], eax
    mov eax, [rbx + SHA_H4]
    mov [rbx + SHA_E], eax
    xor r8d, r8d

.round_loop:
    cmp r8d, 20
    jb .round_ch
    cmp r8d, 40
    jb .round_parity1
    cmp r8d, 60
    jb .round_maj
    jmp .round_parity2

.round_ch:
    mov r11d, [rbx + SHA_B]
    mov r10d, r11d
    and r11d, [rbx + SHA_C]
    not r10d
    and r10d, [rbx + SHA_D]
    or r11d, r10d
    mov r10d, 0x5a827999
    jmp .round_apply

.round_parity1:
    mov r11d, [rbx + SHA_B]
    xor r11d, [rbx + SHA_C]
    xor r11d, [rbx + SHA_D]
    mov r10d, 0x6ed9eba1
    jmp .round_apply

.round_maj:
    mov r11d, [rbx + SHA_B]
    and r11d, [rbx + SHA_C]
    mov r10d, [rbx + SHA_B]
    and r10d, [rbx + SHA_D]
    or r11d, r10d
    mov r10d, [rbx + SHA_C]
    and r10d, [rbx + SHA_D]
    or r11d, r10d
    mov r10d, 0x8f1bbcdc
    jmp .round_apply

.round_parity2:
    mov r11d, [rbx + SHA_B]
    xor r11d, [rbx + SHA_C]
    xor r11d, [rbx + SHA_D]
    mov r10d, 0xca62c1d6

.round_apply:
    mov eax, [rbx + SHA_A]
    rol eax, 5
    add eax, r11d
    add eax, [rbx + SHA_E]
    add eax, r10d
    add eax, [rbx + SHA_W + r8 * 4]

    mov r9d, [rbx + SHA_D]
    mov [rbx + SHA_E], r9d
    mov r9d, [rbx + SHA_C]
    mov [rbx + SHA_D], r9d
    mov r9d, [rbx + SHA_B]
    rol r9d, 30
    mov [rbx + SHA_C], r9d
    mov r9d, [rbx + SHA_A]
    mov [rbx + SHA_B], r9d
    mov [rbx + SHA_A], eax

    inc r8d
    cmp r8d, 80
    jb .round_loop

    mov eax, [rbx + SHA_A]
    add [rbx + SHA_H0], eax
    mov eax, [rbx + SHA_B]
    add [rbx + SHA_H1], eax
    mov eax, [rbx + SHA_C]
    add [rbx + SHA_H2], eax
    mov eax, [rbx + SHA_D]
    add [rbx + SHA_H3], eax
    mov eax, [rbx + SHA_E]
    add [rbx + SHA_H4], eax
    ret

sha1_write_short_hex:
    mov eax, [rbx + SHA_H0]
    bswap eax
    mov [rbx + SHA_DIGEST], eax
    mov eax, [rbx + SHA_H1]
    bswap eax
    mov [rbx + SHA_DIGEST + 4], eax

    mov rdi, [rbx + SHA_OUT_PTR]
    xor r8d, r8d
.hex_loop:
    cmp r8d, 8
    jae .done
    mov dl, [rbx + SHA_DIGEST + r8]
    call write_hex_byte
    inc r8d
    jmp .hex_loop
.done:
    ret

; dl = byte, rdi = output cursor. Advances rdi by 2.
write_hex_byte:
    mov al, dl
    shr al, 4
    call write_hex_nibble
    mov al, dl
    and al, 0x0f
    call write_hex_nibble
    ret

write_hex_nibble:
    cmp al, 9
    jbe .digit
    add al, 'a' - 10
    jmp .store
.digit:
    add al, '0'
.store:
    mov [rdi], al
    inc rdi
    ret

; rcx = dest, rdx = src, r8 = len.
copy_bytes:
    xor r9d, r9d
.loop:
    cmp r9, r8
    jae .done
    mov al, [rdx + r9]
    mov [rcx + r9], al
    inc r9
    jmp .loop
.done:
    ret

; rcx = dest, r8 = len.
zero_bytes:
    xor r9d, r9d
    xor eax, eax
.loop:
    cmp r9, r8
    jae .done
    mov [rcx + r9], al
    inc r9
    jmp .loop
.done:
    ret

section .rdata

neutral_bpms db "0.000=0.000"
