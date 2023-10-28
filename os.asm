mbr_start:
	times 90 db 0 ;fat32 filesystem
	%include "mbr/mbr.asm"
mbr_end:

boot_info_gathering_start:
	%include "boot_info/bios_info.asm"
	align 512, db 0
boot_info_gathering_end:

kernel_load_start:
	%include "kernel/kernel.asm"
	align 512, db 0
kernel_load_end:
