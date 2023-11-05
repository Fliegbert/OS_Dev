BITS 16

; creating a struct for info
; http://www.petesqbsite.com/sections/tutorials/tuts/vbe3.pdf


vesa_info_block:
	.vbe_signature		db "VBE2"
	.vbe_version		resw 1
	.oem_str_ptr		resd 1
	.capabilities		resd 1		; indicates support of spec. features graphical env.
	.video_mode_ptr		resd 1		; vbe_far_ptr to video mode number list
	.total_memory		resw 1		; maximum amount of memory available to frame buffer
	.oem_software_rev	resw 1
	.oem_vendor_name_ptr	resd 1
	.oem_product_name_ptr	resd 1
	.oem_product_rev_ptr	resd 1
	.reserved		resb 222
	.oem_data		resb 256

vbe_mode_info:
	.mode_attributes	resw 1
	.win_a_attributes	resb 1	;?
	.win_b_attributes	resb 1	;?
	.win_granularity	resw 1
	.win_size		resw 1
	.win_a_segment		resw 1
	.win_b_segment		resw 1
	.win_func_ptr		resd 1
	.bytes_per_scanline	resw 1
	.x_resolution		resw 1
	.y_resolution		resw 1
	.x_char_size		resb 1
	.y_char_size		resb 1
	.number_of_planes	resb 1
	.bpp			resb 1		; bits per pixel in graphic modes/ chars in text mode
	.number_of_banks	resb 1
	.memory_model		resb 1
	.bank_size		resb 1
	.number_of_image_pages	resb 1
	.reserved_1		resb 1

	; direct color fields (required for direct/6 and YUV/7 memory models)
	.red_mask_size		resb 1
	.red_field_position	resb 1
	.green_mask_size	resb 1
	.green_field_position	resb 1
	.blue_mask_size		resb 1
	.blue_field_position	resb 1
	.rsvd_mask_size		resb 1
	.rsvd_field_position	resb 1
	.direct_color_mode_info	resb 1
	.phys_base_ptr		resd 1
	.reserved_2		resd 1
	.reserved_3		resw 1
	.link_bytes_per_scanln	resw 1
	.bnk_num_of_img_pages	resb 1
	.lin_num_of_img_pages	resb 1
	.lin_red_mask_size	resb 1
	.lin_red_field_position	resb 1
	.lin_green_mask_size	resb 1
	.lin_green_field_pos	resb 1
	.lin_blue_mask_size	resb 1
	.lin_blue_field_pos	resb 1
	.lin_rsvd_mask_size	resb 1
	.lin_rsvd_field_pos	resb 1
	.max_pixel_clock	resd 1
	.reserved_4		resb 189

vesa_start:
	push ax
	push di
	push bx
	push cx
	push dx
	
	xor ax, ax
	mov es, ax
	mov ax, vesa_info_block.vbe_signature
	mov si, ax
	call print

	mov ax, 800
	mov word [x_width], ax
	mov ax, 600
	mov [y_height], ax
	mov al, 32
	mov [bpp], al


	.get_vbe_controller_information:
		mov ax, 4f00h
		mov di, vesa_info_block
		int 10h
	
		cmp ax, 004fh
		jne .vesa_function_fail

	.start_set_mode:
		mov ax, word [vesa_info_block.video_mode_ptr]
		mov [v_offset], ax
		mov ax, word [vesa_info_block.video_mode_ptr+2]
		mov [v_segment], ax

		mov fs, ax
		mov si, [v_offset]

	.query_modes:
		mov dx, [fs:si]			; getting mode location now prepare for case of next
		mov [mode], dx
		add si, 2
		mov [v_offset], si

		cmp dx, word 0ffffh
		je .vesa_function_fail

		push es				; check next mode
		mov ax, 4f01h
		mov cx, [mode]
		mov di, vbe_mode_info
		int 10h
		pop es

		cmp ax, 004fh
		jne .vesa_function_fail

		mov ax, [x_width]
		cmp ax, [vbe_mode_info.x_resolution]
		jne .next_mode

		mov ax, [y_height]
		cmp ax, [vbe_mode_info.y_resolution]
		jne .next_mode

		mov al, [bpp]
		cmp al, [vbe_mode_info.bpp]
		jne .next_mode

		push es		
		mov ax,	4f02h			; set proper mode
		mov bx, [mode]
		or bx, 4000h			; set byte d14 to turn on linear frame buffer
		xor di, di			; 0000 0000 0000 0000
		int 10h
		pop es

		cmp ax, 004fh
                jne .vesa_function_fail

		jmp return_on_success
				
	.next_mode:
		mov si, [v_offset]
		mov ax, [v_segment]
		mov fs, ax
		jmp .query_modes

	.no_mode:
		jmp halt

	.vesa_function_fail:
		cmp al, 4fh
		jne .vesa_function_not_supported
		cmp ah, 00h
		jne .vesa_status_error
	
	.vesa_function_not_supported:
		mov si, function_not_supported_lbl
		call print
		mov word [reg_16], ax
		call print_reg_16
		jmp halt

	.vesa_status_error:
		mov si, vesa_status_error_code
		call print
		mov word [reg_16], ax
		call print_reg_16
		jmp halt

return_on_success:	
	pop ax
	pop di
	pop bx
	pop cx
	pop dx
	ret


function_not_supported_lbl	db "This function is not supported", ENDL, 0
vesa_status_error_code		db "Vesa status error: "
x_width				dw 0
y_height			dw 0
bpp				db 0
v_offset			dw 0
v_segment			dw 0
mode				dw 0
width_string			db "width:", ENDL, 0
height_string                   db "height:", ENDL, 0
bpp_string			db "bpp:"









;####################################################################################################
;https://wiki.osdev.org/Getting_VBE_Mode_Info

; Common Errors:

; Dont use old standard mode numbers, dont rely on them e.g. from older VBE specifications 
; (VBE 1.0, VBE 1.1 VBE 1.2) one standard was mode 0x0113 = 800 * 600 * 15-bpp

; Pixel data is not contiguous, e.g. (line 1 then line 2. ..)
; there can be padding between lines e.g. (line 1, padding, line 2, padding...)
; Get Mode Information returns number of bytes between lines which should be used
; For example, for a 640 * 480 * 16-bpp video mode, the offset of a line is found by 
; "offset = line * bytes_per_line" and not by "offset = line * (640 * 2)".
; each line should be filled seperately

; in VBE 3.0 there may be 2 bytes between lines returned by get mode information function
; first one used when video mode is setup for bank switching, second one used if linear frame buffer
; is used. in older versions there isnt bytes between lines for linear frame buffer, the one for 
; bankswitching is used

; check memory_model field and (for 15-bpp and higher video modes) all of the component mask and 
;field position fields (e.g. red_mask_size, red_field_position, etc) in structure returned by 
;get_mode_information, dont aasume pixel formats

;Dont assume unused bits are unused, those bits could be used by video cards

; use vbe functions to change the palette, if using vga i/o check if they are compatible first

; If the VBE says video mode is supported by the video card, it doesnt mean its also supported by 
; monitor. There are  2 video mode timings, that are supposed to be supported by all monitors
; 640*480 and 720*480 standard vga timing
; for other modes test with EDID

; Dont read from video memory, use double buffering
;####################################################################################################
