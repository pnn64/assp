default rel

%ifdef ASSP_FREEBSD

global _start
global CloseHandle
global CreateFileA
global ExitProcess
global GetCommandLineA
global GetFileSizeEx
global GetStdHandle
global QueryPerformanceCounter
global QueryPerformanceFrequency
global ReadFile
global WriteFile

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
%define FREEBSD_CMDLINE_CAP 65536
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
    mov [freebsd_entry_rsp], rsp
    mov [freebsd_entry_rdi], rdi
    mov [freebsd_entry_rsi], rsi
    FREEBSD_TRACE freebsd_trace_start, freebsd_trace_start_end - freebsd_trace_start

    ; FreeBSD kernel entry passes the argc/argv stack pointer in rdi. If a
    ; loader calls us instead, rdi/rsi may already be argc/argv.
    cmp rdi, 4096
    ja .check_stack_ptr
    test rsi, rsi
    jz .check_stack_ptr
    mov [freebsd_argc], rdi
    mov [freebsd_argv], rsi
    FREEBSD_TRACE freebsd_trace_abi_args, freebsd_trace_abi_args_end - freebsd_trace_abi_args
    jmp .call_start

.check_stack_ptr:
    mov r10, rdi
    test r10, r10
    jnz .load_stack_args

.use_rsp:
    mov r10, rsp

.load_stack_args:
    mov rax, [r10]
    cmp rax, FREEBSD_ARGV_SCAN_CAP
    ja .load_argv_vector
    mov [freebsd_argc], rax
    lea rax, [r10 + 8]
    mov [freebsd_argv], rax
    mov rsp, r10
    FREEBSD_TRACE freebsd_trace_argc_block, freebsd_trace_argc_block_end - freebsd_trace_argc_block
    jmp .call_start

.load_argv_vector:
    mov [freebsd_argv], r10
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
    mov [freebsd_argc], rax
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
ExitProcess:
    mov rdi, rcx
    mov eax, SYS_EXIT
    syscall

; rcx = STD_OUTPUT_HANDLE. Returns stdout fd.
GetStdHandle:
    mov eax, 1
    ret

; Returns a writable Windows-style command line built from FreeBSD argv.
GetCommandLineA:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    cmp byte [freebsd_cmdline_ready], 0
    jne .return_buffer
    FREEBSD_TRACE freebsd_trace_cmdline, freebsd_trace_cmdline_end - freebsd_trace_cmdline

    lea rdi, [freebsd_cmdline]
    mov r15d, FREEBSD_CMDLINE_CAP - 1
    mov byte [rdi], 'a'
    inc rdi
    dec r15
    mov byte [rdi], 's'
    inc rdi
    dec r15
    mov byte [rdi], 's'
    inc rdi
    dec r15
    mov byte [rdi], 'p'
    inc rdi
    dec r15
    FREEBSD_TRACE freebsd_trace_cmdline_synthetic, freebsd_trace_cmdline_synthetic_end - freebsd_trace_cmdline_synthetic

    mov r12, [freebsd_argc]
    mov r13, [freebsd_argv]
    test r13, r13
    jz .finish
    cmp r12, 1
    jbe .finish
    mov r14d, 1

.arg_loop:
    cmp r14, r12
    jae .finish
    cmp r14, FREEBSD_ARGV_SCAN_CAP
    jae .finish
    mov rsi, [r13 + r14 * 8]
    test rsi, rsi
    jz .finish
    cmp rsi, 4096
    jb .finish
    FREEBSD_TRACE freebsd_trace_cmdline_arg, freebsd_trace_cmdline_arg_end - freebsd_trace_cmdline_arg

    test r14, r14
    jz .scan_quote
    test r15, r15
    jz .finish
    mov byte [rdi], ' '
    inc rdi
    dec r15

.scan_quote:
    mov rbx, rsi
    xor eax, eax
.scan_loop:
    mov dl, [rbx]
    test dl, dl
    jz .copy_arg
    cmp dl, ' '
    ja .scan_next
    mov eax, 1
.scan_next:
    inc rbx
    jmp .scan_loop

.copy_arg:
    test eax, eax
    jnz .quote_arg
    xor ebx, ebx
    jmp .copy_loop

.quote_arg:
    test r15, r15
    jz .finish
    mov byte [rdi], '"'
    inc rdi
    dec r15
    mov ebx, 1

.copy_loop:
    mov al, [rsi]
    test al, al
    jz .copy_done
    test r15, r15
    jz .finish
    mov [rdi], al
    inc rsi
    inc rdi
    dec r15
    jmp .copy_loop

.copy_done:
    cmp ebx, 1
    jne .next_arg
    test r15, r15
    jz .finish
    mov byte [rdi], '"'
    inc rdi
    dec r15

.next_arg:
    inc r14
    jmp .arg_loop

.finish:
    lea rax, [freebsd_cmdline]
    mov byte [rdi], 0
    mov byte [freebsd_cmdline_ready], 1
    FREEBSD_TRACE freebsd_trace_cmdline_done, freebsd_trace_cmdline_done_end - freebsd_trace_cmdline_done
    jmp .done

.return_buffer:
    lea rax, [freebsd_cmdline]

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

; rcx = path. Returns FreeBSD fd or INVALID_HANDLE_VALUE.
CreateFileA:
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
CloseHandle:
    push rdi
    mov rdi, rcx
    mov eax, SYS_CLOSE
    syscall
    setnc al
    movzx eax, al
    pop rdi
    ret

; rcx = fd, rdx = out i64 size. eax = nonzero on success.
GetFileSizeEx:
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
ReadFile:
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
WriteFile:
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
QueryPerformanceFrequency:
    mov rax, 1000000000
    mov [rcx], rax
    mov eax, 1
    ret

; rcx = out counter. eax = nonzero on success.
QueryPerformanceCounter:
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
freebsd_trace_cmdline db "assp freebsd: GetCommandLineA", 10
freebsd_trace_cmdline_end:
freebsd_trace_cmdline_synthetic db "assp freebsd: cmdline synthetic exe", 10
freebsd_trace_cmdline_synthetic_end:
freebsd_trace_cmdline_arg db "assp freebsd: cmdline arg", 10
freebsd_trace_cmdline_arg_end:
freebsd_trace_cmdline_done db "assp freebsd: cmdline done", 10
freebsd_trace_cmdline_done_end:

section .bss

freebsd_entry_rsp resq 1
freebsd_entry_rdi resq 1
freebsd_entry_rsi resq 1
freebsd_argc resq 1
freebsd_argv resq 1
freebsd_cmdline_ready resb 1
freebsd_cmdline resb FREEBSD_CMDLINE_CAP
freebsd_path_buffer resb FREEBSD_PATH_CAP

%endif
