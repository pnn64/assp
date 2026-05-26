default rel
%include "assp.inc"

global assp_find_byte
global assp_count_timing_segments
global assp_count_gimmick_speed_segments
global assp_count_gimmick_scroll_segments

section .text

; rcx = data, rdx = len, r8d = byte.
; rax = byte index, or ASSP_NOT_FOUND.
assp_find_byte:
    test rdx, rdx
    jz .not_found
    test rcx, rcx
    jz .not_found

    movd xmm1, r8d
    punpcklbw xmm1, xmm1
    punpcklwd xmm1, xmm1
    pshufd xmm1, xmm1, 0
    xor rax, rax

.wide_loop:
    cmp rdx, 16
    jb .tail
    movdqu xmm0, [rcx + rax]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit
    add rax, 16
    sub rdx, 16
    cmp rdx, 64
    jb .tail_or_32
    jmp .wide64_loop

.wide64_loop:
    movdqu xmm0, [rcx + rax]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit
    movdqu xmm0, [rcx + rax + 16]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit_hi
    movdqu xmm0, [rcx + rax + 32]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit_32
    movdqu xmm0, [rcx + rax + 48]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit_48
    add rax, 64
    sub rdx, 64
    cmp rdx, 64
    jae .wide64_loop

.tail_or_32:
    cmp rdx, 32
    jb .tail_or_16
    jmp .wide32_loop

.wide32_loop:
    movdqu xmm0, [rcx + rax]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit
    movdqu xmm0, [rcx + rax + 16]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit_hi
    add rax, 32
    sub rdx, 32
    cmp rdx, 32
    jae .wide32_loop
    jmp .tail_or_16

.wide_hit:
    bsf r10d, r10d
    add rax, r10
    ret

.wide_hit_hi:
    bsf r10d, r10d
    lea rax, [rax + r10 + 16]
    ret

.wide_hit_32:
    bsf r10d, r10d
    lea rax, [rax + r10 + 32]
    ret

.wide_hit_48:
    bsf r10d, r10d
    lea rax, [rax + r10 + 48]
    ret

.tail_or_16:
    cmp rdx, 16
    jb .tail
    movdqu xmm0, [rcx + rax]
    pcmpeqb xmm0, xmm1
    pmovmskb r10d, xmm0
    test r10d, r10d
    jnz .wide_hit
    add rax, 16
    sub rdx, 16
    jmp .tail

.tail:
    test rdx, rdx
    jz .not_found

.tail_loop:
    cmp byte [rcx + rax], r8b
    je .done
    inc rax
    dec rdx
    jnz .tail_loop

.not_found:
    mov rax, ASSP_NOT_FOUND

.done:
    ret

; rcx = comma-separated #SPEEDS bytes, rdx = len.
; rax = count of non-default speed-factor segments, or ASSP_NOT_FOUND.
assp_count_gimmick_speed_segments:
; rcx = comma-separated #SCROLLS bytes, rdx = len.
; rax = count of non-default scroll-value segments, or ASSP_NOT_FOUND.
assp_count_gimmick_scroll_segments:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rdx, rdx
    jz .zero
    test rcx, rcx
    jz .not_found

    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d

.segment_loop:
    cmp rsi, rdi
    jae .done_count

    mov r13, rsi
.find_comma:
    cmp r13, rdi
    jae .segment_bounds
    cmp byte [r13], ','
    je .segment_bounds
    inc r13
    jmp .find_comma

.segment_bounds:
    mov r14, rsi
    mov r15, r13

.trim_left:
    cmp r14, r15
    jae .next_segment
    cmp byte [r14], ' '
    ja .trim_right
    inc r14
    jmp .trim_left

.trim_right:
    cmp r15, r14
    jbe .next_segment
    cmp byte [r15 - 1], ' '
    ja .find_equal
    dec r15
    jmp .trim_right

.find_equal:
    mov rbx, r14
.equal_loop:
    cmp rbx, r15
    jae .next_segment
    cmp byte [rbx], '='
    je .value_bounds
    inc rbx
    jmp .equal_loop

.value_bounds:
    inc rbx
    mov rcx, rbx
.find_value_end:
    cmp rcx, r15
    jae .parse_value
    cmp byte [rcx], '='
    je .parse_value
    inc rcx
    jmp .find_value_end

.parse_value:
    mov rdx, rcx
    mov rcx, rbx
    call parse_dec6_signed
    jc .next_segment

    cmp rax, 999999
    jl .count_segment
    cmp rax, 1000001
    jg .count_segment
    cmp rax, 1000001
    jne .next_segment
    test edx, edx
    jz .next_segment

.count_segment:
    inc r12

.next_segment:
    cmp r13, rdi
    jae .done_count
    lea rsi, [r13 + 1]
    jmp .segment_loop

.done_count:
    mov rax, r12
    jmp .pop_done

.zero:
    xor eax, eax
    jmp .pop_done

.not_found:
    mov rax, ASSP_NOT_FOUND

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = number start, rdx = number end.
; rax = signed millionths, edx = has nonzero digits past 6 decimals.
; CF = parse failure.
parse_dec6_signed:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    mov rsi, rcx
    mov rdi, rdx

.trim_left:
    cmp rsi, rdi
    jae .fail
    cmp byte [rsi], ' '
    ja .trim_right
    inc rsi
    jmp .trim_left

.trim_right:
    cmp rdi, rsi
    jbe .fail
    cmp byte [rdi - 1], ' '
    ja .sign
    dec rdi
    jmp .trim_right

.sign:
    xor ebx, ebx
    cmp byte [rsi], '+'
    je .plus
    cmp byte [rsi], '-'
    jne .int_init
    mov ebx, 1
.plus:
    inc rsi
    cmp rsi, rdi
    jae .fail

.int_init:
    xor r8d, r8d
    xor r9d, r9d

.int_loop:
    cmp rsi, rdi
    jae .finish_number
    movzx eax, byte [rsi]
    cmp al, '0'
    jb .check_dot
    cmp al, '9'
    ja .finish_number
    sub eax, '0'
    imul r8, r8, 10
    add r8, rax
    inc r9
    inc rsi
    jmp .int_loop

.check_dot:
    cmp al, '.'
    jne .finish_number
    inc rsi
    xor r10d, r10d
    xor r11d, r11d
    xor r13d, r13d
    xor r14d, r14d
    jmp .frac_loop

.frac_loop:
    cmp rsi, rdi
    jae .finish_frac
    movzx eax, byte [rsi]
    cmp al, '0'
    jb .finish_frac
    cmp al, '9'
    ja .finish_frac
    sub eax, '0'
    inc r9
    cmp r10d, 6
    jae .extra_digit
    imul r11, r11, 10
    add r11, rax
    inc r10d
    inc rsi
    jmp .frac_loop

.extra_digit:
    test eax, eax
    jz .extra_next
    mov r14d, 1
.extra_next:
    inc r10d
    inc rsi
    jmp .frac_loop

.finish_frac:
    mov ecx, r10d
    mov eax, 6
    cmp ecx, eax
    cmova ecx, eax
    lea rdx, [rel scan_dec6_frac_scale]
    imul r11, qword [rdx + rcx * 8]
    jmp .trailing

.finish_number:
    xor r11d, r11d
    xor r14d, r14d

.trailing:
    cmp rsi, rdi
    jae .finish_scaled
    cmp byte [rsi], ' '
    ja .fail
    inc rsi
    jmp .trailing

.finish_scaled:
    test r9, r9
    jz .fail

    imul r8, r8, 1000000
    add r8, r11
    mov rax, r8
    test ebx, ebx
    jz .success
    neg rax

.success:
    mov edx, r14d
    clc
    jmp .done

.fail:
    stc

.done:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
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

section .rdata
align 8
scan_dec6_frac_scale dq 1000000, 100000, 10000, 1000, 100, 10, 1
