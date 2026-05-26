default rel
%include "assp.inc"

global assp_stream_counts_from_densities
global assp_stream_percentages_centi
global assp_stream_segments_from_densities
global assp_stream_tokens_from_densities
global assp_format_stream_tokens
global assp_format_stream_segments

%macro ASSP_DENSITY_KIND 0
    cmp eax, 16
    jb %%break
    cmp eax, 20
    jb %%run16
    cmp eax, 24
    jb %%run20
    cmp eax, 32
    jb %%run24
    mov eax, ASSP_STREAM_TOKEN_RUN32
    jmp %%done
%%run24:
    mov eax, ASSP_STREAM_TOKEN_RUN24
    jmp %%done
%%run20:
    mov eax, ASSP_STREAM_TOKEN_RUN20
    jmp %%done
%%run16:
    mov eax, ASSP_STREAM_TOKEN_RUN16
    jmp %%done
%%break:
    mov eax, ASSP_STREAM_TOKEN_BREAK
%%done:
%endmacro

%define FMT_SEG_RUN_SUM 0
%define FMT_SEG_TOTAL_SUM 8
%define FMT_SEG_MERGED_FLAG 16
%define FMT_SEG_CUR_SIZE 24
%define FMT_TOKEN_BREAK_THRESHOLD 8

section .text

; rcx = u32 densities, rdx = density count, r8 = out assp_stream_counts.
; eax = 1 on success, 0 on invalid pointers.
assp_stream_counts_from_densities:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test r8, r8
    jz .fail
    test rcx, rcx
    jz .maybe_empty
    jmp .init

.maybe_empty:
    test rdx, rdx
    jnz .fail

.init:
    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8

    xor eax, eax
    mov r9d, ASSP_STREAM_COUNTS_SIZE / 8
    mov r10, rbx
.zero:
    mov [r10], rax
    add r10, 8
    dec r9d
    jnz .zero

    test rdi, rdi
    jz .success

    xor r9d, r9d
.find_first:
    cmp r9, rdi
    jae .success
    cmp dword [rsi + r9 * 4], 16
    jae .first_found
    inc r9
    jmp .find_first

.first_found:
    mov r10, rdi
    dec r10
.find_last:
    cmp dword [rsi + r10 * 4], 16
    jae .last_found
    dec r10
    jmp .find_last

.last_found:
    mov r11, r9
.category_loop:
    cmp r11, r10
    ja .break_counts

    mov eax, [rsi + r11 * 4]
    cmp eax, 16
    jb .sn_break
    cmp eax, 20
    jb .run16
    cmp eax, 24
    jb .run20
    cmp eax, 32
    jb .run24
    inc qword [rbx + ASSP_STREAM_COUNTS_RUN32]
    jmp .category_next

.run16:
    inc qword [rbx + ASSP_STREAM_COUNTS_RUN16]
    jmp .category_next

.run20:
    inc qword [rbx + ASSP_STREAM_COUNTS_RUN20]
    jmp .category_next

.run24:
    inc qword [rbx + ASSP_STREAM_COUNTS_RUN24]
    jmp .category_next

.sn_break:
    inc qword [rbx + ASSP_STREAM_COUNTS_SN_BREAKS]

.category_next:
    inc r11
    jmp .category_loop

.break_counts:
    xor r12d, r12d
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d

.break_scan:
    cmp r12, rdi
    jae .tail_break

    cmp dword [rsi + r12 * 4], 16
    jae .stream_start
    inc r12
    jmp .break_scan

.stream_start:
    mov r8, r12

.extend_stream:
    lea rax, [r12 + 1]
    cmp rax, rdi
    jae .stream_end
    cmp dword [rsi + rax * 4], 16
    jb .stream_end
    inc r12
    jmp .extend_stream

.stream_end:
    lea r9, [r12 + 1]
    test r15d, r15d
    jz .leading_gap

    mov rax, r8
    sub rax, r14
    cmp rax, 2
    jb .set_prev
    add r13, rax
    jmp .set_prev

.leading_gap:
    cmp r8, 2
    jb .set_prev
    add r13, r8

.set_prev:
    mov r14, r9
    mov r15d, 1
    inc r12
    jmp .break_scan

.tail_break:
    test r15d, r15d
    jz .store_total_breaks
    mov rax, rdi
    sub rax, r14
    cmp rax, 2
    jb .store_total_breaks
    add r13, rax

.store_total_breaks:
    mov [rbx + ASSP_STREAM_COUNTS_TOTAL_BREAKS], r13

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

; rcx = assp_stream_counts, rdx = total measures, r8 = out stream percent,
; r9 = out adjusted stream percent, stack arg 5 = out break percent.
; Outputs are percentages rounded to cents. eax = 1 on success.
assp_stream_percentages_centi:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12

    mov r10, [rbp + 48]
    test rcx, rcx
    jz .fail
    test r8, r8
    jz .fail
    test r9, r9
    jz .fail
    test r10, r10
    jz .fail

    mov rsi, [rcx + ASSP_STREAM_COUNTS_RUN16]
    add rsi, [rcx + ASSP_STREAM_COUNTS_RUN20]
    add rsi, [rcx + ASSP_STREAM_COUNTS_RUN24]
    add rsi, [rcx + ASSP_STREAM_COUNTS_RUN32]
    mov rdi, [rcx + ASSP_STREAM_COUNTS_TOTAL_BREAKS]

    xor eax, eax
    test rdx, rdx
    jz .store_stream_percent
    mov rax, rsi
    imul rax, rax, 10000
    mov rbx, rdx
    call stream_round_unsigned_div_ties_even
.store_stream_percent:
    mov [r8], rax

    lea r12, [rsi + rdi]
    xor eax, eax
    test r12, r12
    jz .store_adjusted_percent
    mov rax, rsi
    imul rax, rax, 10000
    mov rbx, r12
    call stream_round_unsigned_div_ties_even
.store_adjusted_percent:
    mov [r9], rax

    mov r11, 10000
    sub r11, rax
    mov r10, [rbp + 48]
    mov [r10], r11

    mov eax, 1
    jmp .done

.fail:
    xor eax, eax

.done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

; rax = numerator, rbx = positive denominator. rax = ties-even rounded quotient.
stream_round_unsigned_div_ties_even:
    xor edx, edx
    div rbx
    mov r10, rdx
    shl r10, 1
    cmp r10, rbx
    jb .done
    ja .round_up
    test al, 1
    jz .done
.round_up:
    inc rax
.done:
    ret

; rcx = u32 densities, rdx = density count, r8 = optional output segments,
; r9 = output cap. rax = total segment count.
align 16
assp_stream_segments_from_densities:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .zero

    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d
    xor r14d, r14d
    xor r15d, r15d
    xor r11d, r11d

.scan:
    cmp r14, rdi
    jae .tail

    cmp dword [rsi + r14 * 4], 16
    jae .stream_start
    inc r14
    jmp .scan

.stream_start:
    mov r8, r14

.extend:
    lea r9, [r14 + 1]
    cmp r9, rdi
    jae .stream_end
    cmp dword [rsi + r9 * 4], 16
    jb .stream_end
    inc r14
    jmp .extend

.stream_end:
    lea r9, [r14 + 1]
    test r11d, r11d
    jz .leading_gap

    mov rax, r8
    sub rax, r15
    cmp rax, 2
    jb .push_stream
    mov rax, r15
    mov rdx, r8
    mov ecx, ASSP_TRUE
    call store_segment
    jmp .push_stream

.leading_gap:
    cmp r8, 2
    jb .push_stream
    xor eax, eax
    mov rdx, r8
    mov ecx, ASSP_TRUE
    call store_segment

.push_stream:
    mov rax, r8
    mov rdx, r9
    xor ecx, ecx
    call store_segment

    mov r15, r9
    mov r11d, ASSP_TRUE
    inc r14
    jmp .scan

.tail:
    test r11d, r11d
    jz .done
    mov rax, rdi
    sub rax, r15
    cmp rax, 2
    jb .done
    mov rax, r15
    mov rdx, rdi
    mov ecx, ASSP_TRUE
    call store_segment

.done:
    mov rax, r13
    jmp .pop_done

.zero:
    xor eax, eax

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

store_segment:
    test rbx, rbx
    jz .count
    cmp r13, r12
    jae .count
    lea r10, [r13 + r13 * 2]
    shl r10, 3
    mov [rbx + r10 + ASSP_STREAM_SEGMENT_START], rax
    mov [rbx + r10 + ASSP_STREAM_SEGMENT_END], rdx
    mov [rbx + r10 + ASSP_STREAM_SEGMENT_IS_BREAK], rcx
.count:
    inc r13
    ret

; rcx = u32 densities, rdx = density count, r8 = optional output tokens,
; r9 = output cap. rax = total token count in RSSP's active stream range.
align 16
assp_stream_tokens_from_densities:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    test rcx, rcx
    jz .zero

    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    mov r12, r9
    xor r13d, r13d

    test rdi, rdi
    jz .done

    xor r14d, r14d
.find_first:
    cmp r14, rdi
    jae .done
    cmp dword [rsi + r14 * 4], 16
    jae .first_found
    inc r14
    jmp .find_first

.first_found:
    mov r15, rdi
    dec r15
.find_last:
    cmp dword [rsi + r15 * 4], 16
    jae .load_token
    dec r15
    jmp .find_last

.load_token:
    mov eax, [rsi + r14 * 4]
    ASSP_DENSITY_KIND
    mov r11d, eax
    mov r9, 1

.extend_token:
    cmp r14, r15
    jae .emit_token
    lea r10, [r14 + 1]
    mov eax, [rsi + r10 * 4]
    ASSP_DENSITY_KIND
    cmp eax, r11d
    jne .emit_token
    inc r14
    inc r9
    jmp .extend_token

.emit_token:
    mov eax, r11d
    mov rdx, r9
    call store_token
    inc r14
    cmp r14, r15
    jbe .load_token

.done:
    mov rax, r13
    jmp .pop_done

.zero:
    xor eax, eax

.pop_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

store_token:
    test rbx, rbx
    jz .count
    cmp r13, r12
    jae .count
    mov r8, r13
    shl r8, 4
    mov [rbx + r8 + ASSP_STREAM_TOKEN_KIND], rax
    mov [rbx + r8 + ASSP_STREAM_TOKEN_LEN], rdx
.count:
    inc r13
    ret

; rcx = assp_stream_token tokens, rdx = token count, r8d = breakdown mode,
; r9 = optional output bytes, stack arg 5 = output cap.
; rax = total bytes required/written, not including a nul terminator.
align 16
assp_format_stream_tokens:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, [rsp + 96]
    sub rsp, 32

    test rcx, rcx
    jz .maybe_empty
    jmp .validate

.maybe_empty:
    test rdx, rdx
    jnz .zero

.validate:
    cmp r8d, ASSP_BREAKDOWN_SIMPLIFIED
    ja .zero

    xor eax, eax
    cmp r8d, ASSP_BREAKDOWN_PARTIAL
    jne .threshold_simplified
    mov eax, 1
    jmp .threshold_done

.threshold_simplified:
    cmp r8d, ASSP_BREAKDOWN_SIMPLIFIED
    jne .threshold_done
    mov eax, 4

.threshold_done:
    mov [rsp], rax

    mov rsi, rcx
    mov rdi, rdx
    mov r15d, r8d
    mov rbx, r9
    xor r13d, r13d
    xor r14d, r14d

.token_loop:
    cmp r14, rdi
    jae .done

    mov r10, r14
    shl r10, 4
    mov eax, [rsi + r10 + ASSP_STREAM_TOKEN_KIND]
    test eax, eax
    jz .break_token

    mov r8d, eax
    call merge_run_tokens
    mov r14, rdx
    mov r10, rax
    mov r11d, ecx

    test r13, r13
    jz .write_run
    mov al, ' '
    call append_byte

.write_run:
    call write_run_token
    jmp .token_loop

.break_token:
    mov r8, [rsi + r10 + ASSP_STREAM_TOKEN_LEN]
    call format_break_token
    inc r14
    jmp .token_loop

.done:
    mov rax, r13
    jmp .pop_done

.zero:
    xor eax, eax

.pop_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; input: r14 = start index, r8d = run kind.
; output: rax = merged length, ecx = star flag, rdx = next token index.
merge_run_tokens:
    mov r10, r14
    shl r10, 4
    mov rax, [rsi + r10 + ASSP_STREAM_TOKEN_LEN]
    xor ecx, ecx
    lea r9, [r14 + 1]

.loop:
    lea r10, [r9 + 1]
    cmp r10, rdi
    jae .done

    mov r10, r9
    shl r10, 4
    cmp dword [rsi + r10 + ASSP_STREAM_TOKEN_KIND], ASSP_STREAM_TOKEN_BREAK
    jne .done
    mov r11, [rsi + r10 + ASSP_STREAM_TOKEN_LEN]

    mov rdx, [rsp + FMT_TOKEN_BREAK_THRESHOLD]
    cmp r11, rdx
    ja .done

    lea r10, [r9 + 1]
    shl r10, 4
    mov edx, [rsi + r10 + ASSP_STREAM_TOKEN_KIND]
    test edx, edx
    jz .done
    cmp edx, r8d
    jne .different_run

    add rax, r11
    add rax, [rsi + r10 + ASSP_STREAM_TOKEN_LEN]
    mov ecx, ASSP_TRUE
    add r9, 2
    jmp .loop

.different_run:
    cmp qword [rsp + FMT_TOKEN_BREAK_THRESHOLD], 4
    jne .skip_break
    cmp r11, 1
    jbe .skip_break
    cmp r11, 4
    ja .skip_break
    add rax, r11
    mov ecx, ASSP_TRUE

.skip_break:
    inc r9

.done:
    mov rdx, r9
    ret

; input: r8d = run kind, r10 = length, r11d = star flag.
write_run_token:
    xor r9d, r9d
    cmp r8d, ASSP_STREAM_TOKEN_RUN20
    je .set_tilde
    cmp r8d, ASSP_STREAM_TOKEN_RUN24
    je .set_backslash
    cmp r8d, ASSP_STREAM_TOKEN_RUN32
    jne .maybe_prefix
    mov r9b, '='
    jmp .maybe_prefix

.set_tilde:
    mov r9b, '~'
    jmp .maybe_prefix

.set_backslash:
    mov r9b, '\'

.maybe_prefix:
    test r9b, r9b
    jz .number
    mov al, r9b
    call append_byte

.number:
    push r11
    mov rax, r10
    call append_u64
    pop r11

    test r9b, r9b
    jz .star
    mov al, r9b
    call append_byte

.star:
    test r11d, r11d
    jz .done
    mov al, '*'
    call append_byte

.done:
    ret

; input: r8 = break length.
format_break_token:
    cmp r15d, ASSP_BREAKDOWN_DETAILED
    jne .partial
    cmp r8, 1
    jbe .done
    test r13, r13
    jz .detail_open
    mov al, ' '
    call append_byte

.detail_open:
    mov al, '('
    call append_byte
    mov rax, r8
    call append_u64
    mov al, ')'
    call append_byte
    jmp .done

.partial:
    cmp r15d, ASSP_BREAKDOWN_PARTIAL
    jne .simplified
    cmp r8, 1
    jbe .done
    cmp r8, 4
    jbe .dash
    cmp r8, 32
    jbe .slash
    jmp .bar

.simplified:
    cmp r8, 4
    jbe .done
    cmp r8, 32
    jbe .slash

.bar:
    mov al, '|'
    jmp .symbol

.slash:
    mov al, '/'
    jmp .symbol

.dash:
    mov al, '-'

.symbol:
    test r13, r13
    jz .emit_symbol
    push rax
    mov al, ' '
    call append_byte
    pop rax

.emit_symbol:
    call append_byte

.done:
    ret

; input: rax = unsigned integer.
append_u64:
    cmp rax, 10000
    jae .slow
    cmp rax, 1000
    jae .small4
    cmp rax, 100
    jae .small3
    cmp rax, 10
    jae .small2
    add al, '0'
    call append_byte
    ret

.small2:
    lea r10, [rel stream_int4_emit]
    lea r10, [r10 + rax * 4 + 2]
    mov r8d, 2
    call append_bytes
    ret

.small3:
    lea r10, [rel stream_int4_emit]
    lea r10, [r10 + rax * 4 + 1]
    mov r8d, 3
    call append_bytes
    ret

.small4:
    lea r10, [rel stream_int4_emit]
    lea r10, [r10 + rax * 4]
    mov r8d, 4
    call append_bytes
    ret

.slow:
    sub rsp, 32
    lea r10, [rsp + 32]
    xor r8d, r8d
    mov r11d, 10

    test rax, rax
    jnz .loop
    dec r10
    mov byte [r10], '0'
    mov r8d, 1
    jmp .emit

.loop:
    xor edx, edx
    div r11
    add dl, '0'
    dec r10
    mov [r10], dl
    inc r8
    test rax, rax
    jnz .loop

.emit:
    test r8, r8
    jz .done
    mov al, [r10]
    call append_byte
    inc r10
    dec r8
    jmp .emit

.done:
    add rsp, 32
    ret

; input: r10 = bytes, r8 = byte count.
append_bytes:
    test r8, r8
    jz .done
    test rbx, rbx
    jz .count_only
    mov rax, r13
    add rax, r8
    jc .slow
    cmp rax, r12
    ja .slow

    push rsi
    push rdi
    mov rsi, r10
    lea rdi, [rbx + r13]
    mov rcx, r8
    rep movsb
    pop rdi
    pop rsi
    add r13, r8
    jmp .done

.slow:
    mov al, [r10]
    call append_byte
    inc r10
    dec r8
    jnz .slow
    jmp .done

.count_only:
    add r13, r8

.done:
    ret

; input: al = byte.
append_byte:
    test rbx, rbx
    jz .count
    cmp r13, r12
    jae .count
    mov [rbx + r13], al
.count:
    inc r13
    ret

; rcx = assp_stream_segment segments, rdx = segment count,
; r8d = stream breakdown level, r9 = optional output bytes,
; stack arg 5 = output cap. rax = total bytes required/written.
assp_format_stream_segments:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, [rsp + 96]
    sub rsp, 32

    test rcx, rcx
    jz .maybe_empty
    jmp .validate

.maybe_empty:
    test rdx, rdx
    jnz .zero

.validate:
    cmp r8d, ASSP_STREAM_BREAKDOWN_TOTAL
    ja .zero

    mov rsi, rcx
    mov rdi, rdx
    mov r15d, r8d
    mov rbx, r9
    xor r13d, r13d
    xor r14d, r14d
    mov qword [rsp + FMT_SEG_RUN_SUM], 0
    mov qword [rsp + FMT_SEG_TOTAL_SUM], 0
    mov qword [rsp + FMT_SEG_MERGED_FLAG], 0
    mov qword [rsp + FMT_SEG_CUR_SIZE], 0

    test rdi, rdi
    jz .no_streams
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    je .total_loop_init

.segment_loop:
    cmp r14, rdi
    jae .finish

    lea r10, [r14 + r14 * 2]
    shl r10, 3
    mov rax, [rsi + r10 + ASSP_STREAM_SEGMENT_END]
    sub rax, [rsi + r10 + ASSP_STREAM_SEGMENT_START]
    mov [rsp + FMT_SEG_CUR_SIZE], rax

    cmp qword [rsi + r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    jne .break_segment

    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    je .stream_sum
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    je .stream_sum

    test r14, r14
    jz .stream_write_size
    lea r10, [r14 - 1]
    lea r10, [r10 + r10 * 2]
    shl r10, 3
    cmp qword [rsi + r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    jne .stream_write_size
    mov al, '-'
    call append_byte

.stream_write_size:
    mov rax, [rsp + FMT_SEG_CUR_SIZE]
    call append_u64
    inc r14
    jmp .segment_loop

.stream_sum:
    test r14, r14
    jz .stream_add_size
    lea r10, [r14 - 1]
    lea r10, [r10 + r10 * 2]
    shl r10, 3
    cmp qword [rsi + r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    jne .stream_add_size
    mov qword [rsp + FMT_SEG_MERGED_FLAG], ASSP_TRUE
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .stream_add_size
    inc qword [rsp + FMT_SEG_RUN_SUM]

.stream_add_size:
    mov rax, [rsp + FMT_SEG_CUR_SIZE]
    add [rsp + FMT_SEG_RUN_SUM], rax
    inc r14
    jmp .segment_loop

.break_segment:
    test r14, r14
    jz .break_done
    lea rax, [r14 + 1]
    cmp rax, rdi
    jae .break_done

    cmp r15d, ASSP_STREAM_BREAKDOWN_DETAILED
    jne .break_not_detailed
    mov al, ' '
    call append_byte
    mov al, '('
    call append_byte
    mov rax, [rsp + FMT_SEG_CUR_SIZE]
    call append_u64
    mov al, ')'
    call append_byte
    mov al, ' '
    call append_byte
    jmp .break_done

.break_not_detailed:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .break_symbol
    mov rax, [rsp + FMT_SEG_RUN_SUM]
    add [rsp + FMT_SEG_TOTAL_SUM], rax
    jmp .break_clear

.break_symbol:
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .break_emit_symbol
    cmp qword [rsp + FMT_SEG_RUN_SUM], 0
    je .break_emit_symbol
    mov rax, [rsp + FMT_SEG_RUN_SUM]
    call append_u64
    cmp qword [rsp + FMT_SEG_MERGED_FLAG], 0
    je .break_emit_symbol
    mov al, '*'
    call append_byte

.break_emit_symbol:
    mov rax, [rsp + FMT_SEG_CUR_SIZE]
    cmp rax, 4
    jbe .break_dash
    cmp rax, 31
    jbe .break_slash

    mov al, ' '
    call append_byte
    mov al, '|'
    call append_byte
    mov al, ' '
    call append_byte
    jmp .break_clear

.break_slash:
    mov al, '/'
    call append_byte
    jmp .break_clear

.break_dash:
    mov al, '-'
    call append_byte

.break_clear:
    mov qword [rsp + FMT_SEG_RUN_SUM], 0
    mov qword [rsp + FMT_SEG_MERGED_FLAG], 0

.break_done:
    inc r14
    jmp .segment_loop

.finish:
    cmp qword [rsp + FMT_SEG_RUN_SUM], 0
    je .finish_level
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .finish_total
    mov rax, [rsp + FMT_SEG_RUN_SUM]
    call append_u64
    cmp qword [rsp + FMT_SEG_MERGED_FLAG], 0
    je .finish_level
    mov al, '*'
    call append_byte
    jmp .finish_level

.finish_total:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .finish_level
    mov rax, [rsp + FMT_SEG_RUN_SUM]
    add [rsp + FMT_SEG_TOTAL_SUM], rax

.finish_level:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .finish_non_total
    mov rax, [rsp + FMT_SEG_TOTAL_SUM]
    call append_u64
    call append_total_suffix
    jmp .done

.finish_non_total:
    test r13, r13
    jnz .done

.no_streams:
    call append_no_streams
    jmp .done

.total_loop_init:
    xor r11d, r11d

.total_loop:
    cmp r14, rdi
    jae .total_done
    lea r10, [r14 + r14 * 2]
    shl r10, 3
    cmp qword [rsi + r10 + ASSP_STREAM_SEGMENT_IS_BREAK], 0
    jne .total_next
    mov rax, [rsi + r10 + ASSP_STREAM_SEGMENT_END]
    sub rax, [rsi + r10 + ASSP_STREAM_SEGMENT_START]
    add r11, rax

.total_next:
    inc r14
    jmp .total_loop

.total_done:
    mov rax, r11
    call append_u64
    call append_total_suffix

.done:
    mov rax, r13
    jmp .pop_done

.zero:
    xor eax, eax

.pop_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

append_no_streams:
    lea r10, [rel no_streams_text]
    mov r8d, no_streams_text_end - no_streams_text
    call append_bytes
    ret

append_total_suffix:
    lea r10, [rel total_suffix_text]
    mov r8d, total_suffix_text_end - total_suffix_text
    call append_bytes
    ret

section .rdata
align 16
stream_int4_emit:
%assign i 0
%rep 10000
    db '0' + (i / 1000), '0' + ((i / 100) % 10), '0' + ((i / 10) % 10), '0' + (i % 10)
%assign i i+1
%endrep

no_streams_text db "No Streams!"
no_streams_text_end:
total_suffix_text db " Total"
total_suffix_text_end:
