BITS 16

prepare_a20_status:
	push si
        push ax
        xor ax, ax

check_a20_status:
	clc
	cmp ax, 1
	je status_a20_done

	.check_a20:                      ;; compare values at 0000:0500 and FFFF:0510 whether they
                                        ;; are the same or not reason = if same a20 is disabled
                                        ;; since memory wraps because a20 = disabled
                pushf                   ;; push lower 16 bit of flags, free to encapsulate
                push es
                push ds
                push di
                push si
                cli                     ;; clearing interrupts

                xor ax, ax              ;; set test region
                mov es, ax
                not ax                  ;; complete complement of current value 0x0000 -> 0xFFFF
                mov ds, ax
                mov di, 500h
                mov si, 510h            ;; apparently 500 and 510 are guaranteed to be free

                ;; save original values
                mov dl, byte [es:di]
                push dx
                mov dl, byte [ds:si]
                push dx

                ;; test for values written in
                mov byte [es:di], 00h
                mov byte [ds:si], 0ffh
                cmp byte [es:di], 0ffh  ;; if it contains ffh, a20 is disabled since it means it
                                        ;; wraps around
                mov ax, 0
                je disabled_a20
                mov ax, 1
                jmp a20_enabled

a20_enabled:
                pop dx
                mov byte [ds:si], dl
                pop dx
                mov byte [es:di], dl

                pop si
                pop di
                pop es
                pop ds
                popf

		pop ax
		pop si

                mov si, enabled_lbl
                call print

                ret
disabled_a20:
                ; restore original values
                pop dx
                mov byte [ds:si], dl
                pop dx
                mov byte [es:di], dl

                pop si
                pop di
                pop es
                pop ds
                popf

		mov si, disabled_lbl
		call print
                sti ; Enable interrupts.

enable_a20:
	.bios_a20:
		mov ax, 2401h
		int 15h
		jc .bios_a20_error
		jmp status_a20_done

               .bios_a20_error:
			clc
			mov si, bios_error_lbl
			call print
			
			mov ax, 2403h
			int 15h
			jc exit_on_error
			mov word [reg_16], bx
			call print_reg_16
			test bl, 1		;; 3 = fast_gate & keyboard, 2 = fast_gate, 1 = Keyb
			je .keyboard


	.fast_gate:			;; test whether the second bit (a20 bit) is set, if so jmp
					;; first bit (zero bit) if set to 1 causes reset so check
					;; before sending out
		in al, 0x92		;; read from port
		test al, 2		;; testing whether second bit is set, 2 = 010b
		jnz status_a20_done
		or al, 2		;; if second bit not set yet, is set now
		and al, 0FEh		;; if first bit = 1 now set to 0 | must be 0 to avoid reset
		out 0x92, al		;; write to port
		jmp status_a20_done
					;; 0x92 can be unsecure, since there are reports of spontan-
					;; ous kernel reboot (Sony PCG-Z600NE) after A20 was enabled
					;; using 0x92 but not via keyboard controller

;; .keyboard not tested yet
	.keyboard:
		cli
		
		call .delay
		mov al, 0adh		;; Disable Keyboard
		out 64h, al

		call .delay
		mov al, 0d0h		;; Read from input
		out 64h, al

		call .delay
		in al, 60h
		push eax

		call .delay
		mov al, 0d1h		;; Write to output
		out 64h, al

		call .delay
		pop eax
		or al, 2
		out 60h,al

		call .delay
		mov al, 0aeh		;; enable keyboard
		out 64h, al

		call .delay
		sti			;; Enables interrupts
		ret

		.delay:
			in al, 064h
			test al, 2
			jnz .delay
			ret

		.delay2:
			in      al, 0x64
			test    al, 1
			jz      .delay2
			ret

disable_a20:
	clc
	mov ax, 2400h
	int 15h
	jc .disable_fail
	mov si, disable_lbl
	call print
	mov ax, 0
	ret

	.disable_fail:
		mov si, disable_err
		call print
		mov ax, 0
		ret

status_a20_done:
	mov si, exit_a20_lbl
	call print
	pop si
	pop ax
	mov ax, 1
	ret

exit_on_error:
	mov si, exit_a20_err
        call print
	pop si
	pop ax
	mov ax, 0
	ret

test_lbl	db "test", ENDL, 0
enabled_lbl	db "A20 is enabled.", ENDL, 0
disabled_lbl    db "A20 is disabled.", ENDL, 0
disable_lbl     db "A20 has been disabled.", ENDL, 0
exit_a20_lbl	db "Exiting A20.", ENDL, 0
exit_a20_err    db "Exiting A20 with Error.", ENDL, 0
bios_error_lbl  db "A20 bios Error, checking support...", ENDL, 0
disable_err	db "Couldn't Disable A20", ENDL, 0

;; sources:
;; https://www.win.tue.nl/~aeb/linux/kbd/A20.html
;; https://wiki.osdev.org/A20_Line#Keyboard_Controller_2
;; https://fd.lod.bz/rbil/interrup/bios_vendor/152403.html
