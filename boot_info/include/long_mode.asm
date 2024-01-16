BITS 16
check_cpuid:
	; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
	; in the FLAGS register. If we can flip it, CPUID is available.

	; Copy FLAGS in to EAX via stack
	pushfd
	pop eax

	; Copy to ECX as well for comparing later on
	mov ecx, eax

	; Flip the ID bit
	xor eax, 1 << 21

	; Copy EAX to FLAGS via the stack
	push eax
	popfd

	; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
	pushfd
	pop eax

	; Restore FLAGS from the old version stored in ECX (i.e. flipping the
	; ID bit back if it was ever flipped).
	push ecx
	popfd

	; Compare EAX and ECX. If they are equal then that means the bit
	; wasn't flipped, and CPUID isn't supported.
	cmp eax, ecx
	je .cpuid_not_available
	mov si, cpuid_suc
	call print
	jmp long_availability

	.cpuid_not_available:
                mov si, cpuid_err
                call print
                mov al, 1
                ret

long_availability:
	mov eax, 0x80000000 ; Test if extended processor info in available.  
	cpuid                
	cmp eax, 0x80000001 
	jb .extended_err
	mov si, extended_cpuid
	call print

	mov eax, 0x80000001 ; After calling CPUID with EAX = 0x80000001, 
	cpuid
	test edx, 1 << 29
	jz .long_mode_err
	mov al, 0
	ret

	.extended_err:
                mov si, extended_error
                call print
                mov al, 1
                ret

	.long_mode_err:
		mov si, long_mode_err
                call print
                mov al, 1
                ret
	
cpuid_err		db "cpuid not available.", ENDL, 0
cpuid_suc		db "cpuid available", ENDL, 0
long_mode_err		db "long mode not available.", ENDL, 0
long_mode_supported	db "long mode supported.", ENDL, 0
extended_cpuid		db "Extended cpuid supported", ENDL, 0
extended_error		db "Extended error", ENDL, 0
test_lbl_2		db "test", ENDL, 0



; https://wiki.osdev.org/Setting_Up_Long_Mode
; https://wiki.osdev.org/CPUID
