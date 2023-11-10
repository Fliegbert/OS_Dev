BITS 16

mmap_ent equ 0x8600

detect_memory:
	push si
	push ax

	.detect_low_memory:
		clc
		int 0x12
		jc .detect_low_failed
		mov word [low_memory], ax
		
		mov word [reg_16], ax			; 0x027f = 639
		call print_reg_16

		mov si, low_success
		call print
		
		jmp .detect_high_memory

		.detect_low_failed:
			mov si, low_error
			call print
			jmp halt

	
	.detect_high_memory:
	;########################################################################################
	;#				Query System Address Map				#
	;#		Input:									#
	;#			Using int 0x15							#
	;#											#
	;#			Function Code:  EAX = 0xE820					#
	;#										        #
	;#			Continuation:   EBX = contains continuation value needs to be 0 #
	;#					in first call nust be used to keep calls	#
	;#					contiguos					#
	;#											#
	;#			Buff Pointer:	ES:DI = Pointer to address Range Descriptor	#
	;#											#
	;#			Buff Size:	ECX = Length in Bytes of the structure passed	#
	;#					to the BIOS. Minimum size which must be sup-	#
	;#					ported is 20 by bios and caller. might be ex-	#
	;#					ded in the future, is 24 and so on..		#
	;#											#
	;#			Signature:	EDX = 'SMAP' used by bios to verify the caller	#
	;#					is requesting the system map information to be	#
	;#					returned in ES:DI				#
	;#											#
	;#		Output:									#
	;#			Carry Flag	No error if 0					#
	;#											#
	;#			Signature	EAX = 'SMAP' Signature to verify correct BIOS   #
	;#					revision					#
	;#											#
	;#			Buff Pointer	ES:DI = Returned Address Range (same as input)  #
	;#											#
	;#			Buff Size	ECX = Number of bytes returned by BIOS in ad-	#
	;#					dress range descriptor, minimum is 20		#
	;#											#
	;#			Continuation	EBX = Continuation value for next call. If 0	#
	;#					it means the last valid descriptor has been re	#
	;#					turned or if carry is set (subsequent)		#
	;#											#
	;#		Structure:								#
	;#											#
	;#		#########################################################################
	;#		#	Offset Bytes	Name		Description			#
	;#		#########################################################################
	;#		#	 0		BaseAddrLow	Low 32 Bits of Base Address	#
	;#		#	 4		BaseAddreHigh	High 32 Bits of Base Address	#
	;#		#	 8		LengthLow	Low 32 Bits of Length in Bytes	#
	;#		#	12		LengthHigh	High 32 Bits of Length in Bytes #
	;#		#	16		Type		Address type of this range	#
	;#		#	20		ACPI 3.0 ext	Gives more information if there #
	;#		#########################################################################
	;#		#	if cx returns 24 instead of 20	ACPI 3.0 ext			#
	;#		#########################################################################
	;#		#	ACPI 3.0 Extended Attributes bitfield				#
	;#		#	20		Indicates if the entire entry should be ignored #
	;#		#			(if cleared)					#
	;#		#	21		Indicates if the entry is non-volatile		#
	;#		#			(if the bit is set)				#
	;#		#	22		Remaining 30 bits are currently undefined	#
	;#		#########################################################################
	;#											#
	;#		BaseAddrLow + BaseAddrHigh = 64 bit BaseAddress = physical address of	#
	;#		of the start of the range being specified				#
	;#											#
	;#		LengthLow + LengthHigh = 64 bit Length of this range = physical conti-	#
	;#		guous length in bytes of a range being specified			#
	;#											#
	;#		Type describes usage of address range specified				#
	;#			1 = AddressRangeMemory = address is available RAM usable by OS	#
	;#			2 = AddressRangeReserved = This address is in use or reserved	#
	;#			by the system and must not be used by the OS			#
	;#			3 = ACPI reclaimable memory					#
	;#			4 = ACPI NVS memory						#
	;#			5 = Area containing bad memory					#
	;#											#
	;######################################################################################## 
	;# Returns unsorted list (SHOULD not be overlapping areas)				#
	;# Each list entry is stored in memory at ES:DI, DI is not incremented			#
	;#											#
	;# Format of Entry:									#
	;#	uint64_t = Base address								#
	;#	uint64_t = Length of "region", if 0 ignore whole entry				#
	;#	uint32_t = Region "type"							#
	;#		Type 1: = Usable (normal) RAM						#
	;#		Type 2: = Reserved - unusable						#
	;#		Type 3: = ACPI reclaimable memory					#
	;#		Type 4: = ACPI NVS memory						#
	;#		Type 5: = Area containing bad memory					#
	;#	uint32_t = ACPI 3.0 Extended Attributes bitfield (if 24 bytes are returned,	#
	;#		   instead of 20)							#
	;#		Bit 0 indicates if the entire entry should be ignored (if the bit	#
	;#		is clear)								#
	;#											#
	;#		Bit 1 indicates if the entry is non-volatile (if the bit is set)	#
	;#		or not. The standard states that "Memory reported as non-volatil	#
	;#		e may require characterization to determine its suitability for		#
	;#		use as conventional RAM.						#
	;#											#
	;#	Remaining 30 bits are currently undefined					#
	;#											#
	;#	Basic Usage:									#
	;#		- For the first call to the function, point ES:DI at the destina	#
	;#		  tion buffer for the list						#
	;#		- Clear ebx, set edx 0x534D4150, set eax 0xE820, set ecx 24 do		#
	;#		  int 0x15								#
	;#		- if first call successful:						#
	;#			EAX will be set to 0x534D4150					#
	;#			carry flag clear						#
	;#			ebx non zero, must be preserved for next call			#
	;#			cl will contain number of bytes actually stored at ES:DI	#
	;#											#
	;#		- Subsequent calls:							#
	;#			Increment di by entry size					#
	;#			Reset eax to 0xe820 and ecx to 24				#
	;#			If reaching end of list, ebx may reset to 0 and function	#
	;#				will start over again					#
	;#			If not reset to 0 function will return with carry set if	#
	;#				if trying to access entry after last valid entry	#
	;#											#
	;########################################################################################
		
		.first_e820_call:
			
			mov di, 0x8604			;# edx gives the position of SMAP to bios
			xor ebx, ebx			;# bp will be used to store the entry count
			xor bp, bp			;# carry set = error
			mov edx, 0x534D4150		;# requesting 24 bytes with ecx	
			mov eax, 0xe820			;# eax != smap = error
			mov [es:di+20], dword 1		;# ebx = 0 = error
			mov ecx, 24
			int 0x15
			
			mov si, memory_map_lbl
			call print
			call check_values

			jc short .e820_fail
			mov edx, 0x534D4150		;cmp eax, 0x534D4150
			cmp eax, edx
			jne short .e820_fail
			test ebx, ebx ;cmp ebx, 0
			je short .e820_fail
			jmp short .check_e820_entry

		.e820_loop:				;# loop for subsequent entries
			mov [es:di+20], dword 1		;# if carry set here = finished
			mov eax, 0xe820			;# need to restore edx, can be trashed->bios
			mov ecx, 24
			;mov es:[di], ebx
			int 0x15

			call check_values
			jc short .e820_finished ;.e820_finished
			mov edx, 0x534D4150

		.check_e820_entry:			;# check amount cx amount if empty skip
			jcxz .skip			;# if cx > 20 check acpi attribute
			cmp cl, 20			;# if cx =< 20 check normal range immediatley
			jbe short .normal_20 ;.normal_20;# if ext attribute bit 1 set skip
			test byte [es:di+20], 1
			je short .skip ;.skip

		.normal_20:				;# if length not 0 inc entry count else skip
			mov ecx, [es:di+8]		;#
			or ecx, [es:di+12]
			jz .skip
			inc bp
			add di, 24

		.skip:
			cmp ebx, 0
			jne short .e820_loop ;.e820_loop		
			
		.e820_finished:
			mov [mmap_ent], bp		;# mmap_ent = 0x8000
			clc				;# bp = 2 bytes = infront of memory entries
			jmp exit_detection

		.e820_fail:
			mov si, high_mem_error
			call print
			jmp halt

check_values:
	push ax
	
	mov si, memory_map_location
	call print	
	mov ax, di
        mov word [reg_16], ax   
        call print_reg_16
        
	pop ax

	push cx

        xor cx, cx
        mov cx, 24
        call print_bytes_start
	mov si, endl
        call print

        pop cx

	ret

exit_detection:
	pop si
	pop ax
	ret	

low_memory	dw 0, ENDL, 0
low_success	db "low was successfully found", ENDL, 0
low_error	db "low not found", ENDL, 0
high_mem_error	db "error managing high memory", ENDL, 0
endl            db ENDL, 0
memory_map_lbl	db ENDL, "Memory Map:", ENDL, "Base Address 8 Bytes x Length 8 Bytes x Type 4 Bytes x ACPI 3.0 ext 4 Bytes", ENDL, 0
memory_map_location db "Memory Location: ", 0
