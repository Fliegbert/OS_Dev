[BITS 16]
gdt:
.gdt_null:
	dq 0		;; Null Segment

.gdt_code:
	dw 0FFFFh	;; Limit
	dw 0		;; Base address
	db 0		;; Second DW, Base address bits 16-23
	db 10011010b	;; type at the end because of big endian, at front privilege and present
	db 11001111b
	db 0

.gdt_data:
	dw 0FFFFh
	dw 0
	db 0
	db 10010010b
	db 11001111b
	db 0
.gdt_end:

.gdt_pointer:
	dw gdt.gdt_end - gdt - 1
	dd gdt.gdt_null

CODE_SEG equ gdt.gdt_code - gdt.gdt_null
DATA_SEG equ gdt.gdt_data - gdt.gdt_null

;; Pitfalls:

;; One wrong bit will make things fail, Protected mode errors often triple-fault the CPU

;; Most library routines probably won't work. printf(), for example

;; Before clearing the PE bit, the segment registers must point to descriptors that are appropriate 
;; to real mode. This means a limit of exactly 0xFFFF

;; You can not use the '286 LMSW instruction to clear the PE bit. Use MOV CR0, nnn.

;; Load all segment registers with valid selectors after entering protected mode. If a protected 
;; routine pushes an segment register and pops the old invalid real-mode reg, it crashes

;; The IDTR must also be reset to a value that is appropriate to real-mode before re-enabling 
;; interrupts

;; Not all instructions are legal in real mode.

;; The GDT (as well as LDTs) should reside in RAM

;; https://files.osdev.org/mirrors/geezer/os/pm.htm
;; https://wiki.osdev.org/Global_Descriptor_Table
;; https://wiki.osdev.org/GDT_Tutorial
