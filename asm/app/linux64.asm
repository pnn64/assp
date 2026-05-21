default rel

%ifdef ASSP_LINUX

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

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_CLOSE 3
%define SYS_LSEEK 8
%define SYS_EXIT 60
%define SYS_OPENAT 257
%define SYS_CLOCK_GETTIME 228

%define AT_FDCWD -100
%define CLOCK_MONOTONIC 1
%define SEEK_SET 0
%define SEEK_END 2
%define LINUX_PATH_CAP 4096

section .text

_start:
    mov rax, [rsp]
    mov [assp_os_argc], rax
    lea rax, [rsp + 8]
    mov [assp_os_argv], rax
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

; rcx = path. Returns Linux fd or -1.
assp_os_open_readonly:
    push rsi
    push rdi

    mov rsi, rcx
    lea rdi, [linux_path_buffer]
    mov r8d, LINUX_PATH_CAP - 1
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
    lea rsi, [linux_path_buffer]
    xor edx, edx
    xor r10d, r10d
    syscall
    test rax, rax
    js .fail
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
    test rax, rax
    setns al
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
    test rax, rax
    js .fail
    mov [r8], rax

    mov eax, SYS_LSEEK
    mov rdi, r9
    xor esi, esi
    mov edx, SEEK_SET
    syscall
    test rax, rax
    js .fail

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
    cmp rax, -4
    je .read_loop
    test rax, rax
    js .fail
    jz .success
    add r13, rax
    sub r14, rax
    add rbx, rax
    jmp .read_loop

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
    cmp rax, -4
    je .write_loop
    test rax, rax
    jle .fail
    add r13, rax
    sub r14, rax
    add rbx, rax
    jmp .write_loop

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
    test rax, rax
    js .fail

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

assp_os_argc resq 1
assp_os_argv resq 1
linux_path_buffer resb LINUX_PATH_CAP

%endif
