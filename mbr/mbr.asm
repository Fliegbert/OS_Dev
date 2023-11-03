; Set execution mode, dont let assembler guess one
BITS 16
[ORG 0x7c00]

%define ENDL 0x0D, 0x0A

; Set CS:IP with far jump and dont assume CS:IP
start: jmp 0:entry

entry:

	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov sp, 0x7c00 ; Stack grows down
	cld
			
	mov [disk], dl

	; Set up video mode
	mov ah, 0x00
	mov al, 0x0E
	int 0x10
	
	call load_disk
	
;	mov si, disk_success
	call print
	
	jmp boot_info_gathering_start
halt:
	cli
	hlt
	jmp halt

%include "mbr/include/print.inc"
%include "mbr/include/disk.inc"

;disk_success		db "disk successful loaded", ENDL, 0
times 510-($-$$)	db 0
dw 0xAA55
