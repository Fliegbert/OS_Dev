[BITS 16]

xor ax, ax
mov es, ax

call prepare_a20_status
mov si, a20_success
call print

call detect_memory
mov si, mem_call_success
call print

call check_cpuid
call long_availability

call vesa_start
call load_vga_fonts

cli
lgdt [gdt.gdt_pointer]
mov eax, cr0
or eax, 1
mov cr0, eax
jmp CODE_SEG:protected_init

[BITS 32]
protected_init:
	mov ax, DATA_SEG
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov gs, ax
	mov fs, ax
	mov esp, 090000h
        
        push dword print_success
        call print_string
        push dword num
        call print_string
        jmp hang2

hang2:
	jmp hang2

%include "boot_info/include/a20.asm"
%include "boot_info/include/memory_detection.asm"
%include "boot_info/include/vesa.asm"
%include "boot_info/include/long_mode.asm"
%include "boot_info/include/gdt.asm"
%include "boot_info/include/vga_handling.asm"

char_test               db "ABCD", 0
num                     db "1234", 0
a20_success		db "A20 Success", ENDL, 0
mem_call_success	db "Detect Memory success", ENDL, 0
vesa_call_success	db "Vesa success", ENDL, 0
print_success           db "Welcome to 32-bit Mode!", 0
times 512		db 0
