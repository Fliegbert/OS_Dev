BITS 16

mov si, welcome_lbl
call print

call detect_memory
mov si, mem_call_success
call print

call vesa_start
mov si, vesa_call_success
call print

jmp halt

%include "boot_info/include/memory_detection.inc"
%include "boot_info/include/vesa.inc"

welcome_lbl		db 'Welcome to Sector 2', ENDL, 0
mem_call_success	db "detect Memory success", ENDL, 0
vesa_call_success	db "vesa success", ENDL, 0
times 512		db 0
