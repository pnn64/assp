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
%define FREEBSD_CMDLINE_CAP 65536
%define FREEBSD_PATH_CAP 4096

section .text

_start:
    mov [freebsd_initial_rsp], rsp
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

    mov rsi, [freebsd_initial_rsp]
    test rsi, rsi
    jz .finish
    mov r12, [rsi]
    lea r13, [rsi + 8]
    lea rdi, [freebsd_cmdline]
    mov r15d, FREEBSD_CMDLINE_CAP - 1
    xor r14d, r14d

.arg_loop:
    cmp r14, r12
    jae .finish
    mov rsi, [r13 + r14 * 8]
    test rsi, rsi
    jz .finish

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

section .bss

freebsd_initial_rsp resq 1
freebsd_cmdline_ready resb 1
freebsd_cmdline resb FREEBSD_CMDLINE_CAP
freebsd_path_buffer resb FREEBSD_PATH_CAP

%endif
