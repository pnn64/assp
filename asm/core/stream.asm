default rel
%include "assp.inc"

global assp_stream_counts_from_densities
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

; rcx = u32 densities, rdx = density count, r8 = optional output segments,
; r9 = output cap. rax = total segment count.
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
    mov [rbx + r8 + ASSP_STREAM_TOKEN_KIND], eax
    mov dword [rbx + r8 + 4], 0
    mov [rbx + r8 + ASSP_STREAM_TOKEN_LEN], rdx
.count:
    inc r13
    ret

; rcx = assp_stream_token tokens, rdx = token count, r8d = breakdown mode,
; r9 = optional output bytes, stack arg 5 = output cap.
; rax = total bytes required/written, not including a nul terminator.
assp_format_stream_tokens:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, [rsp + 96]

    test rcx, rcx
    jz .maybe_empty
    jmp .validate

.maybe_empty:
    test rdx, rdx
    jnz .zero

.validate:
    cmp r8d, ASSP_BREAKDOWN_SIMPLIFIED
    ja .zero

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

    xor edx, edx
    cmp r15d, ASSP_BREAKDOWN_PARTIAL
    jne .not_partial
    mov edx, 1
    jmp .check_threshold

.not_partial:
    cmp r15d, ASSP_BREAKDOWN_SIMPLIFIED
    jne .check_threshold
    mov edx, 4

.check_threshold:
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
    cmp r15d, ASSP_BREAKDOWN_SIMPLIFIED
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
    cmp r8d, ASSP_STREAM_TOKEN_RUN20
    jne .prefix24
    mov al, '~'
    call append_byte
    jmp .number

.prefix24:
    cmp r8d, ASSP_STREAM_TOKEN_RUN24
    jne .prefix32
    mov al, '\'
    call append_byte
    jmp .number

.prefix32:
    cmp r8d, ASSP_STREAM_TOKEN_RUN32
    jne .number
    mov al, '='
    call append_byte

.number:
    push r8
    push r11
    mov rax, r10
    call append_u64
    pop r11
    pop r8

    cmp r8d, ASSP_STREAM_TOKEN_RUN20
    jne .suffix24
    mov al, '~'
    call append_byte
    jmp .star

.suffix24:
    cmp r8d, ASSP_STREAM_TOKEN_RUN24
    jne .suffix32
    mov al, '\'
    call append_byte
    jmp .star

.suffix32:
    cmp r8d, ASSP_STREAM_TOKEN_RUN32
    jne .star
    mov al, '='
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
    mov qword [rsp], 0
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov qword [rsp + 24], 0

    test rdi, rdi
    jz .no_streams

.segment_loop:
    cmp r14, rdi
    jae .finish

    lea r10, [r14 + r14 * 2]
    shl r10, 3
    mov rax, [rsi + r10 + ASSP_STREAM_SEGMENT_END]
    sub rax, [rsi + r10 + ASSP_STREAM_SEGMENT_START]
    mov [rsp + 24], rax

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
    mov rax, [rsp + 24]
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
    mov qword [rsp + 16], ASSP_TRUE
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .stream_add_size
    inc qword [rsp]

.stream_add_size:
    mov rax, [rsp + 24]
    add [rsp], rax
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
    mov rax, [rsp + 24]
    call append_u64
    mov al, ')'
    call append_byte
    mov al, ' '
    call append_byte
    jmp .break_done

.break_not_detailed:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .break_symbol
    mov rax, [rsp]
    add [rsp + 8], rax
    jmp .break_clear

.break_symbol:
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .break_emit_symbol
    cmp qword [rsp], 0
    je .break_emit_symbol
    mov rax, [rsp]
    call append_u64
    cmp qword [rsp + 16], 0
    je .break_emit_symbol
    mov al, '*'
    call append_byte

.break_emit_symbol:
    mov rax, [rsp + 24]
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
    mov qword [rsp], 0
    mov qword [rsp + 16], 0

.break_done:
    inc r14
    jmp .segment_loop

.finish:
    cmp qword [rsp], 0
    je .finish_level
    cmp r15d, ASSP_STREAM_BREAKDOWN_SIMPLE
    jne .finish_total
    mov rax, [rsp]
    call append_u64
    cmp qword [rsp + 16], 0
    je .finish_level
    mov al, '*'
    call append_byte
    jmp .finish_level

.finish_total:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .finish_level
    mov rax, [rsp]
    add [rsp + 8], rax

.finish_level:
    cmp r15d, ASSP_STREAM_BREAKDOWN_TOTAL
    jne .finish_non_total
    mov rax, [rsp + 8]
    call append_u64
    call append_total_suffix
    jmp .done

.finish_non_total:
    test r13, r13
    jnz .done

.no_streams:
    call append_no_streams
    jmp .done

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
    mov al, 'N'
    call append_byte
    mov al, 'o'
    call append_byte
    mov al, ' '
    call append_byte
    mov al, 'S'
    call append_byte
    mov al, 't'
    call append_byte
    mov al, 'r'
    call append_byte
    mov al, 'e'
    call append_byte
    mov al, 'a'
    call append_byte
    mov al, 'm'
    call append_byte
    mov al, 's'
    call append_byte
    mov al, '!'
    call append_byte
    ret

append_total_suffix:
    mov al, ' '
    call append_byte
    mov al, 'T'
    call append_byte
    mov al, 'o'
    call append_byte
    mov al, 't'
    call append_byte
    mov al, 'a'
    call append_byte
    mov al, 'l'
    call append_byte
    ret
