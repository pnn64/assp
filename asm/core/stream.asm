default rel
%include "assp.inc"

global assp_stream_counts_from_densities
global assp_stream_segments_from_densities

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
