BITS 16

; creating a struct for info
; http://www.petesqbsite.com/sections/tutorials/tuts/vbe3.pdf

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

;section .data

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


vesa_info_block:
        .vbe_signature          db "VBE2"
        .vbe_version            resw 1
        .oem_str_ptr            resd 1
        .capabilities           resd 1          ; indicates support of spec. features graphical env.
        .video_mode_ptr         resd 1          ; vbe_far_ptr to video mode number list
        .total_memory           resw 1          ; maximum amount of memory available to frame buffer
        .oem_software_rev       resw 1
        .oem_vendor_name_ptr    resd 1
        .oem_product_name_ptr   resd 1
        .oem_product_rev_ptr    resd 1
        .reserved               resb 222
        .oem_data               resb 256


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

