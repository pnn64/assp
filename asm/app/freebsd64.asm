default rel

%ifdef ASSP_FREEBSD

global _start
global assp_os_argc
global assp_os_argv
global assp_os_close
global assp_os_counter
global assp_os_counter_frequency
global assp_os_exit
global assp_os_file_size
global assp_os_open_readonly
global assp_os_read
global assp_os_stdout
global assp_os_trace
global assp_os_write

extern start

%define SYS_EXIT 1
%define SYS_READ 3
%define SYS_WRITE 4
%define SYS_CLOSE 6
%define SYS_CLOCK_GETTIME 232
%define SYS_LSEEK 478
%define SYS_OPENAT 499

%define AT_FDCWD -100
%define CLOCK_MONOTONIC 4
%define SEEK_SET 0
%define SEEK_END 2
%define FREEBSD_ARGV_SCAN_CAP 64
%define FREEBSD_PATH_CAP 4096

%macro FREEBSD_TRACE 2
%ifdef ASSP_STARTUP_TRACE
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r10
    push r11
    mov eax, SYS_WRITE
    mov edi, 2
    lea rsi, [%1]
    mov edx, %2
    syscall
    pop r11
    pop r10
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
%endif
%endmacro

section .text

_start:
    FREEBSD_TRACE freebsd_trace_start, freebsd_trace_start_end - freebsd_trace_start

    ; FreeBSD usually passes the initial argc block pointer in rdi. Some
    ; loaders call the entrypoint with rdi=argc and rsi=argv, so accept both.
    cmp rdi, 4096
    ja .stack_block
    test rsi, rsi
    jz .stack_block
    mov [assp_os_argc], rdi
    mov [assp_os_argv], rsi
    FREEBSD_TRACE freebsd_trace_abi_args, freebsd_trace_abi_args_end - freebsd_trace_abi_args
    jmp .call_start

.stack_block:
    mov r10, rdi
    test r10, r10
    jnz .load_stack_args
    mov r10, rsp

.load_stack_args:
    mov rax, [r10]
    cmp rax, FREEBSD_ARGV_SCAN_CAP
    ja .load_argv_vector
    mov [assp_os_argc], rax
    lea rax, [r10 + 8]
    mov [assp_os_argv], rax
    mov rsp, r10
    FREEBSD_TRACE freebsd_trace_argc_block, freebsd_trace_argc_block_end - freebsd_trace_argc_block
    jmp .call_start

.load_argv_vector:
    mov [assp_os_argv], r10
    xor eax, eax
.count_argv_loop:
    cmp rax, FREEBSD_ARGV_SCAN_CAP
    jae .count_argv_done
    mov r11, [r10 + rax * 8]
    test r11, r11
    jz .count_argv_done
    inc rax
    jmp .count_argv_loop
.count_argv_done:
    mov [assp_os_argc], rax
    lea rsp, [r10 - 8]
    FREEBSD_TRACE freebsd_trace_argv_vector, freebsd_trace_argv_vector_end - freebsd_trace_argv_vector

.call_start:
    FREEBSD_TRACE freebsd_trace_call_start, freebsd_trace_call_start_end - freebsd_trace_call_start
    and rsp, -16
    call start
    mov edi, eax
    mov eax, SYS_EXIT
    syscall

; rcx = exit code.
assp_os_exit:
    mov rdi, rcx
    mov eax, SYS_EXIT
    syscall

; Returns stdout fd.
assp_os_stdout:
    mov eax, 1
    ret

; rcx = bytes, rdx = len. Writes to stderr.
assp_os_trace:
    push rsi
    push rdi
    mov rsi, rcx
    mov eax, SYS_WRITE
    mov edi, 2
    syscall
    pop rdi
    pop rsi
    ret

; rcx = path. Returns FreeBSD fd or -1.
assp_os_open_readonly:
    push rsi
    push rdi

    mov rsi, rcx
    lea rdi, [freebsd_path_buffer]
    mov r8d, FREEBSD_PATH_CAP - 1
.path_loop:
    test r8d, r8d
    jz .fail
    lodsb
    test al, al
    jz .path_done
    cmp al, '\'
    jne .store_path
    mov al, '/'
.store_path:
    stosb
    dec r8d
    jmp .path_loop

.path_done:
    stosb
    mov eax, SYS_OPENAT
    mov edi, AT_FDCWD
    lea rsi, [freebsd_path_buffer]
    xor edx, edx
    xor r10d, r10d
    syscall
    jc .fail
    jmp .done

.fail:
    mov rax, -1

.done:
    pop rdi
    pop rsi
    ret

; rcx = fd. eax = nonzero on success.
assp_os_close:
    push rdi
    mov rdi, rcx
    mov eax, SYS_CLOSE
    syscall
    setnc al
    movzx eax, al
    pop rdi
    ret

; rcx = fd, rdx = out i64 size. eax = nonzero on success.
assp_os_file_size:
    push rsi
    push rdi

    mov r8, rdx
    mov r9, rcx

    mov eax, SYS_LSEEK
    mov rdi, rcx
    xor esi, esi
    mov edx, SEEK_END
    syscall
    jc .fail
    mov [r8], rax

    mov eax, SYS_LSEEK
    mov rdi, r9
    xor esi, esi
    mov edx, SEEK_SET
    syscall
    jc .fail

    mov eax, 1
    jmp .done

.fail:
    xor eax, eax

.done:
    pop rdi
    pop rsi
    ret

; rcx = fd, rdx = buffer, r8 = len, r9 = out u32 bytes read.
assp_os_read:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9
    xor ebx, ebx

.read_loop:
    test r14, r14
    jz .success
    mov eax, SYS_READ
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    syscall
    jc .check_intr
    test rax, rax
    jz .success
    add r13, rax
    sub r14, rax
    add rbx, rax
    jmp .read_loop

.check_intr:
    cmp eax, 4
    je .read_loop
    jmp .fail

.success:
    test r15, r15
    jz .no_read_store
    mov [r15], ebx
.no_read_store:
    mov eax, 1
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

; rcx = fd, rdx = buffer, r8 = len, r9 = out u32 bytes written.
assp_os_write:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    mov r12, rcx
    mov r13, rdx
    mov r14, r8
    mov r15, r9
    xor ebx, ebx

.write_loop:
    test r14, r14
    jz .success
    mov eax, SYS_WRITE
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    syscall
    jc .check_intr
    test rax, rax
    jle .fail
    add r13, rax
    sub r14, rax
    add rbx, rax
    jmp .write_loop

.check_intr:
    cmp eax, 4
    je .write_loop
    jmp .fail

.success:
    test r15, r15
    jz .no_write_store
    mov [r15], ebx
.no_write_store:
    mov eax, 1
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

; rcx = out frequency. eax = nonzero on success.
assp_os_counter_frequency:
    mov rax, 1000000000
    mov [rcx], rax
    mov eax, 1
    ret

; rcx = out counter. eax = nonzero on success.
assp_os_counter:
    push rsi
    push rdi
    sub rsp, 16

    mov r8, rcx
    mov eax, SYS_CLOCK_GETTIME
    mov edi, CLOCK_MONOTONIC
    mov rsi, rsp
    syscall
    jc .fail

    mov rax, [rsp]
    imul rax, rax, 1000000000
    add rax, [rsp + 8]
    mov [r8], rax
    mov eax, 1
    jmp .done

.fail:
    xor eax, eax

.done:
    add rsp, 16
    pop rdi
    pop rsi
    ret

section .rdata

freebsd_trace_start db "assp freebsd: _start", 10
freebsd_trace_start_end:
freebsd_trace_abi_args db "assp freebsd: argv from abi", 10
freebsd_trace_abi_args_end:
freebsd_trace_argc_block db "assp freebsd: argv from argc block", 10
freebsd_trace_argc_block_end:
freebsd_trace_argv_vector db "assp freebsd: argv from vector", 10
freebsd_trace_argv_vector_end:
freebsd_trace_call_start db "assp freebsd: call start", 10
freebsd_trace_call_start_end:

section .bss

assp_os_argc resq 1
assp_os_argv resq 1
freebsd_path_buffer resb FREEBSD_PATH_CAP

%endif
