default rel
%include "win64.inc"

%ifdef ASSP_WINDOWS

global assp_os_close
global assp_os_command_line
global assp_os_counter
global assp_os_counter_frequency
global assp_os_exit
global assp_os_file_size
global assp_os_open_readonly
global assp_os_read
global assp_os_stdout
global assp_os_trace
global assp_os_write

extern CloseHandle
extern CreateFileA
extern ExitProcess
extern GetCommandLineA
extern GetFileSizeEx
extern GetStdHandle
extern QueryPerformanceCounter
extern QueryPerformanceFrequency
extern ReadFile
extern WriteFile

section .text

; rcx = exit code.
assp_os_exit:
    jmp ExitProcess

; Returns stdout handle.
assp_os_stdout:
    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    add rsp, 40
    ret

; Returns Windows command line for the Windows-only parser path.
assp_os_command_line:
    sub rsp, 40
    call GetCommandLineA
    add rsp, 40
    ret

; rcx = bytes, rdx = len. Startup tracing is Unix-focused for now.
assp_os_trace:
    ret

; rcx = path. Returns handle or INVALID_HANDLE_VALUE.
assp_os_open_readonly:
    sub rsp, 72
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword [rsp + 32], OPEN_EXISTING
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call CreateFileA
    add rsp, 72
    ret

; rcx = handle. eax = nonzero on success.
assp_os_close:
    sub rsp, 40
    call CloseHandle
    add rsp, 40
    ret

; rcx = handle, rdx = out i64 size. eax = nonzero on success.
assp_os_file_size:
    sub rsp, 40
    call GetFileSizeEx
    add rsp, 40
    ret

; rcx = handle, rdx = buffer, r8 = len, r9 = out u32 bytes read.
assp_os_read:
    sub rsp, 40
    mov qword [rsp + 32], 0
    call ReadFile
    add rsp, 40
    ret

; rcx = handle, rdx = buffer, r8 = len, r9 = out u32 bytes written.
assp_os_write:
    sub rsp, 40
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 40
    ret

; rcx = out frequency. eax = nonzero on success.
assp_os_counter_frequency:
    sub rsp, 40
    call QueryPerformanceFrequency
    add rsp, 40
    ret

; rcx = out counter. eax = nonzero on success.
assp_os_counter:
    sub rsp, 40
    call QueryPerformanceCounter
    add rsp, 40
    ret

%endif
