BITS 16

print:
;#########################;
; Write in Teletype Mode  ;
;#########################;
; AH: 0e		  ;
; AL: ASCII character	  ;
; BH: page number	  ;
; BL: Foreground Px Color ;
;##########################

	pusha
	mov ah, 0x0e
	mov bl, 0x02

.s_print:
	lodsb
        cmp al, 0
        je goback
        int 0x10
        jmp .s_print

;
; '0'-'9' = hex 0x30-0x39
; 'A'-'F' = hex 0x41-0x46
; 'a'-'f' = hex 0x61-0x66
;

print_reg_16:
	pusha
	mov di, output_16
	mov ax, [reg_16]
	mov si, hexstr
	mov cx, 4
	jmp hex_loop

hex_loop:

	; 0x8080 -> 0808
	rol ax, 4
	mov bx, ax
	and bx, 0x0f
	mov bl, [si + bx]
	mov [di], bl
	inc di
	dec cx
	jnz hex_loop
	mov si, output_16
	call print
	
	popa
	ret

; Hx 30-39 = Chr 0-9
; Hx 41-46 = Chr A-F

print_bytes_start:
	pusha
	xor bx, bx

print_bytes:
	push bx

	xor ax, ax
	mov ax, [di+bx]
	push ax

	shr ax, 12
	and al, 0x0f

	add al, 0x30			; conversion to ascii character, if 30-39h its now ascii
	cmp al, 0x39
	jle print_high_byte
	add al, 0x7			; Upper case A-F chr = 41-46

print_high_byte:	
	mov ah, 0x0e
	mov bl, 0x02
	int 0x10
	pop ax
	pop bx

	xor ax, ax
	mov ax, [di+bx]
	
	shr ax, 8
	and al, 0x0f
	add al, 0x30
	cmp al, 0x39
	jle print_low_byte
	add al, 7

print_low_byte:
	push bx
	mov ah, 0x0e
	mov bl, 0x02
	int 0x10
	dec cx
	pop bx
	add bx, 1

	cmp cx, 0
	jne print_bytes

goback:
	popa
        ret

output_16	db '0000', ENDL, 0
hexstr		db '0123456789ABCDEF'
reg_16          dw 0
