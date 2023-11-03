BITS 16

mov si, welcome_lbl
call print

call detect_memory
mov si, mem_call_success
call print


jmp halt

%include "boot_info/include/memory_detection.inc"

welcome_lbl		db 'Welcome to Sector 2', ENDL, 0
mem_call_success	db "detect Memory success", ENDL, 0
times 512		db 0
