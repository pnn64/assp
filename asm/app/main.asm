default rel
%include "asmssp.inc"
%include "win64.inc"

extern CloseHandle
extern CreateFileA
extern ExitProcess
extern GetCommandLineA
extern GetFileSizeEx
extern GetStdHandle
extern ReadFile
extern WriteFile

extern asmssp_count_note_stats_4

global start

%define FILE_BUFFER_CAP 8388608

section .text

start:
    sub rsp, 40

    call init_stdout
    call parse_args

    call read_file
    test eax, eax
    jz fail_read

    call find_selected_notes
    test eax, eax
    jz fail_notes

    mov rcx, [note_ptr]
    mov rdx, [note_len]
    lea r8, [note_stats]
    call asmssp_count_note_stats_4
    test eax, eax
    jz fail_stats

    call print_report
    xor ecx, ecx
    call ExitProcess

fail_read:
    lea rcx, [msg_read_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_notes:
    lea rcx, [msg_notes_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

fail_stats:
    lea rcx, [msg_stats_fail]
    call print_z
    mov ecx, 1
    call ExitProcess

init_stdout:
    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    add rsp, 40
    ret

parse_args:
    push rsi
    sub rsp, 32

    lea rax, [default_fixture]
    mov [input_path], rax
    mov qword [chart_index], 0

    call GetCommandLineA
    mov rsi, rax
    test rsi, rsi
    jz .done

    cmp byte [rsi], '"'
    jne .skip_exe_plain
    inc rsi
.skip_exe_quote:
    mov al, [rsi]
    test al, al
    jz .done
    inc rsi
    cmp al, '"'
    jne .skip_exe_quote
    jmp .skip_spaces

.skip_exe_plain:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    jbe .skip_spaces
    inc rsi
    jmp .skip_exe_plain

.skip_spaces:
    mov al, [rsi]
    cmp al, ' '
    ja .path_start
    test al, al
    jz .done
    inc rsi
    jmp .skip_spaces

.path_start:
    cmp al, '"'
    jne .path_plain
    inc rsi
    mov [input_path], rsi
.path_quote_loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, '"'
    je .path_quote_end
    inc rsi
    jmp .path_quote_loop

.path_quote_end:
    mov byte [rsi], 0
    inc rsi
    jmp .skip_arg_spaces

.path_plain:
    mov [input_path], rsi
.path_plain_loop:
    mov al, [rsi]
    test al, al
    jz .done
    cmp al, ' '
    jbe .path_plain_end
    inc rsi
    jmp .path_plain_loop

.path_plain_end:
    mov byte [rsi], 0
    inc rsi

.skip_arg_spaces:
    mov al, [rsi]
    cmp al, ' '
    ja .parse_chart
    test al, al
    jz .done
    inc rsi
    jmp .skip_arg_spaces

.parse_chart:
    xor rax, rax
.chart_loop:
    movzx rdx, byte [rsi]
    cmp dl, '0'
    jb .store_chart
    cmp dl, '9'
    ja .store_chart
    imul rax, rax, 10
    sub edx, '0'
    add rax, rdx
    inc rsi
    jmp .chart_loop

.store_chart:
    mov [chart_index], rax

.done:
    add rsp, 32
    pop rsi
    ret

read_file:
    sub rsp, 72

    mov qword [file_handle], 0
    mov qword [file_size], 0
    mov dword [file_bytes_read], 0

    mov rcx, [input_path]
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword [rsp + 32], OPEN_EXISTING
    mov qword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp + 48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je .fail
    mov [file_handle], rax

    mov rcx, rax
    lea rdx, [file_size]
    call GetFileSizeEx
    test eax, eax
    jz .close_fail

    mov rax, [file_size]
    test rax, rax
    jz .close_fail
    cmp rax, FILE_BUFFER_CAP
    ja .close_fail

    mov rcx, [file_handle]
    lea rdx, [file_buffer]
    mov r8d, eax
    lea r9, [file_bytes_read]
    mov qword [rsp + 32], 0
    call ReadFile
    test eax, eax
    jz .close_fail

    mov rcx, [file_handle]
    call CloseHandle
    mov qword [file_handle], 0

    mov eax, [file_bytes_read]
    cmp rax, [file_size]
    jne .fail

    mov [file_len], rax
    mov eax, ASMSSP_TRUE
    jmp .done

.close_fail:
    mov rcx, [file_handle]
    test rcx, rcx
    jz .fail
    call CloseHandle
    mov qword [file_handle], 0

.fail:
    xor eax, eax

.done:
    add rsp, 72
    ret

find_selected_notes:
    lea r10, [file_buffer]
    mov r11, [file_len]
    lea r11, [r10 + r11]
    mov r8, [chart_index]
    xor r9d, r9d

.scan:
    lea rax, [r10 + 7]
    cmp rax, r11
    ja .fail

    cmp byte [r10 + 0], '#'
    jne .next
    cmp byte [r10 + 1], 'N'
    jne .next
    cmp byte [r10 + 2], 'O'
    jne .next
    cmp byte [r10 + 3], 'T'
    jne .next
    cmp byte [r10 + 4], 'E'
    jne .next
    cmp byte [r10 + 5], 'S'
    jne .next
    cmp byte [r10 + 6], ':'
    jne .next

    cmp r9, r8
    je .found_tag
    inc r9
    add r10, 7
    jmp .scan

.next:
    inc r10
    jmp .scan

.found_tag:
    lea rax, [r10 + 7]
    mov rdx, rax

.find_end:
    cmp rdx, r11
    jae .fail
    cmp byte [rdx], ';'
    je .found_end
    inc rdx
    jmp .find_end

.found_end:
    inc rdx
    mov [note_ptr], rax
    sub rdx, rax
    mov [note_len], rdx
    mov eax, ASMSSP_TRUE
    ret

.fail:
    xor eax, eax
    ret

print_report:
    sub rsp, 40

    lea rcx, [msg_header]
    call print_z
    lea rcx, [label_file]
    call print_z
    mov rcx, [input_path]
    call print_z
    lea rcx, [newline]
    call print_z

    lea rcx, [label_chart]
    mov rdx, [chart_index]
    call print_field
    lea rcx, [label_rows]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_ROWS]
    call print_field
    lea rcx, [label_steps]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_STEPS]
    call print_field
    lea rcx, [label_arrows]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_ARROWS]
    call print_field
    lea rcx, [label_jumps]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_JUMPS]
    call print_field
    lea rcx, [label_hands]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_HANDS]
    call print_field
    lea rcx, [label_holds]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_HOLDS]
    call print_field
    lea rcx, [label_rolls]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_ROLLS]
    call print_field
    lea rcx, [label_mines]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_MINES]
    call print_field
    lea rcx, [label_lifts]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_LIFTS]
    call print_field
    lea rcx, [label_fakes]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_FAKES]
    call print_field
    lea rcx, [label_left]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_LEFT]
    call print_field
    lea rcx, [label_down]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_DOWN]
    call print_field
    lea rcx, [label_up]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_UP]
    call print_field
    lea rcx, [label_right]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_RIGHT]
    call print_field
    lea rcx, [label_bad_rows]
    mov rdx, [note_stats + ASMSSP_NOTE_STATS_MALFORMED_ROWS]
    call print_field

    add rsp, 40
    ret

print_field:
    sub rsp, 56
    mov [rsp + 32], rdx
    call print_z
    mov rcx, [rsp + 32]
    call print_u64
    lea rcx, [newline]
    call print_z
    add rsp, 56
    ret

print_u64:
    mov rax, rcx
    lea r10, [num_buffer + 32]
    xor r8d, r8d
    mov r9d, 10

    test rax, rax
    jnz .loop
    dec r10
    mov byte [r10], '0'
    mov r8d, 1
    jmp .emit

.loop:
    xor edx, edx
    div r9
    add dl, '0'
    dec r10
    mov [r10], dl
    inc r8
    test rax, rax
    jnz .loop

.emit:
    mov rcx, r10
    mov rdx, r8
    sub rsp, 40
    call print_raw
    add rsp, 40
    ret

print_z:
    mov r10, rcx
    xor edx, edx
.len:
    cmp byte [r10 + rdx], 0
    je .emit
    inc rdx
    jmp .len
.emit:
    sub rsp, 40
    call print_raw
    add rsp, 40
    ret

print_raw:
    sub rsp, 56
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [stdout_handle]
    lea r9, [stdout_written]
    mov qword [rsp + 32], 0
    call WriteFile
    add rsp, 56
    ret

section .data

default_fixture db "fixtures\camellia_mix.ssc", 0
msg_header db "asmssp standalone", 13, 10, 0
msg_read_fail db "failed to read input file", 13, 10, 0
msg_notes_fail db "failed to find selected #NOTES chart", 13, 10, 0
msg_stats_fail db "assembly note stat counter failed", 13, 10, 0
label_file db "file: ", 0
label_chart db "chart: ", 0
label_rows db "rows: ", 0
label_steps db "steps: ", 0
label_arrows db "arrows: ", 0
label_jumps db "jumps: ", 0
label_hands db "hands: ", 0
label_holds db "holds: ", 0
label_rolls db "rolls: ", 0
label_mines db "mines: ", 0
label_lifts db "lifts: ", 0
label_fakes db "fakes: ", 0
label_left db "left: ", 0
label_down db "down: ", 0
label_up db "up: ", 0
label_right db "right: ", 0
label_bad_rows db "malformed_rows: ", 0
newline db 13, 10, 0

section .bss

stdout_handle resq 1
stdout_written resd 1
input_path resq 1
chart_index resq 1
file_handle resq 1
file_size resq 1
file_len resq 1
file_bytes_read resd 1
note_ptr resq 1
note_len resq 1
note_stats resb ASMSSP_NOTE_STATS_SIZE
num_buffer resb 32
file_buffer resb FILE_BUFFER_CAP

