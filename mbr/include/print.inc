print:
;#########################;
; Write in Teletype Mode  ;
;#########################;
; AH: 0e		  ;
; AL: ASCII character	  ;
; BH: page number	  ;
; BL: Foreground Px Color ;
;##########################

	push ax
	push bx

	mov ah, 0x0e
	mov bl, 0x02

.s_print:
	lodsb
        cmp al, 0
        je .goback
        int 0x10
        jmp .s_print

.goback:
	pop ax
	pop bx
        ret

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

.hex_loop:

	; 0x8080 -> 0808
	rol ax, 4
	mov bx, ax
	and bx, 0x0f
	mov bl, [si + bx]
	mov [di], bl
	inc di
	dec cx
	jnz .hex_loop
	mov si, output_16
	call print
	
	popa
	ret

output_16	db '0000', ENDL, 0
hexstr		db '0123456789ABCDEF'
reg_16          dw 0
