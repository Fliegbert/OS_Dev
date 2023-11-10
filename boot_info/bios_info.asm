BITS 16

xor ax, ax
mov es, ax

call vesa_start
mov si, vesa_call_success
call print

call prepare_a20_status
mov si, a20_success
call print

call detect_memory
mov si, mem_call_success
call print

;mov si, vbe_mode_info
;mov di, 9000h
;mov cx, 64
;rep movsd

halt_2:
        cli
        hlt
        jmp halt

%include "boot_info/include/a20.asm"
%include "boot_info/include/memory_detection.asm"
%include "boot_info/include/vesa.asm"

a20_success		db "A20 Success", ENDL, 0
mem_call_success	db "Detect Memory success", ENDL, 0
vesa_call_success	db "Vesa success", ENDL, 0
times 512		db 0
