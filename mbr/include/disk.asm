
load_disk:
	pusha

check_for_extension:
	mov ah, 0x41
	mov bx, 0x55aa
	mov dl, [disk]
	int 0x13
	jc lba_not_supported
	call .extension_available
	jmp prepare_for_dap
	
	.extension_available:
		push si
		mov si, extension_avai
		call print
		pop si
		ret


prepare_for_dap:
	mov ax, (boot_info_gathering_start-mbr_start)/512		; start sector
	mov bx, boot_info_gathering_start				; Offset
	xor dx, dx							; Segment
	mov cx, (kernel_load_end-boot_info_gathering_start)/512		; number of sectors	
	jmp real_read_disk



;#######################################################################################;
;#  Offset	Size		Description						;
;#######################################################################################;
;#  0		1		size of packet (16 bytes)				;
;#  1		1		always 0						;
;#  2		2		number of sectors to transfer (max 127 on some BIOSes)	;
;#  4		2		transfer buffer (16 bit offset)				;
;#  6		2		transfer buffer (16 bit segment)			;
;#  8		4		lower 32-bits of 48-bit starting LBA			;
;# 12		4		upper 16-bits of 48-bit starting LBA			;
;#######################################################################################;

DAP:
				db 0x10
				db 0
	.sectors_to_transfer	dw 127
	.buffer_offset		dw 0
	.buffer_segment		dw 0
	.lower_lba		dd 0
	.upper_lba		dd 0

;########################################
;#		Read Disk		#
;########################################
;# AH: 42 = function number		#
;# DL: drive index			#
;# DS:SI = pointer to DAP		#
;########################################

real_read_disk:
	.check:
		cmp cx, 127
		jbe .start_read
		pusha
		mov cx, 127
		call real_read_disk
		popa
		add eax, 127
		add dx, 172*512/16
		sub cx, 127
		jmp .check

	.start_read:
		mov [DAP.lower_lba], ax
		mov [DAP.buffer_offset], bx
		mov [DAP.buffer_segment], dx
		mov [DAP.sectors_to_transfer], cx

		mov ah, 0x42
		mov dx, 0x0000
		mov dl, [disk]

		mov si, DAP
		int 0x13
		jc .disk_read_error_hlt
		jmp exit_disk_read


	.disk_read_error_hlt:
		mov si, disk_error
		call print
		mov ah, 0x01
		int 0x13
		mov word [reg_16], ax
		call print_reg_16
		.halt:
			hlt
			jmp .halt

lba_not_supported:	
	mov si, lba_error
	call print
	cli
	hlt

exit_disk_read:
	popa
	ret

lba_error	db 'LBA is not supported', ENDL, 0
disk_error	db 'Disk error', ENDL, 0
disk		db 0x80
extension_avai  db 'INT 13 Extension is available', ENDL, 0
