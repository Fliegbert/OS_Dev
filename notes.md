Helpful:
	https://wiki.osdev.org/My_Bootloader_Does_Not_Work
	https://wiki.osdev.org/Rolling_Your_Own_Bootloader#Loading..._Please_wait...
	https://alamot.github.io/os_stage1/
	http://www.uruk.org/orig-grub/mem64mb.html


mapping:
	- bootsector is loaded at 0x00007c00
	- there is bios area at 0x00000000 to 0x000004FF
	- there's an EBDA somewhere between 0x00080000 and 0x0009FFFF
	- lot of memory again after 0x00100000

	- We should map non preallocated pieces like second stage and so on..

	map: ###################################################################################
	     #       Bios Area			Stack Pointer		    Boot Sector        #
	     #  0x00000000-0x000004FF  ..  0x00006c00-0x00007bff  ..  0x00007c00-0x00007e00  ..#
	     #		Sector 2		Memory Map				       #
	     #	0x00007e00-0x00008000  ..  0x00008000-0x00008094			       #
	     #		EDBA								       #
             #  0x00080000-0x0009FFFF  ..						       #
	     ###################################################################################


Next Steps:
	Begin Sector 2
	Memory detection:
	
	alamot
	- check if long is supported
	- activate A20 gate / address line
	- prepare paging
	- remap PIC
	- enter long mode and pass control to kernel
	
	osdev
	- Check presence of PCI, CPUID, MSRs
	- Enable and confirm enabled A20 line
	- Load GDTR
	- Inform BIOS of target processor mode
	- Get memory map from BIOS
	- Locate kernel in filesystem
	- Allocate memory to load kernel image
	- Load kernel image into buffer
	- Enable graphics mode
	- Check kernel image ELF headers
	- Enable long mode, if 64-bit
	- Allocate and map memory for kernel segments
	- Setup stack
	- Setup COM serial output port
	- Setup IDT
	- Disable PIC
	- Check presence of CPU features (NX, SMEP, x87, PCID, global pages, TCE, WP, MMX, SSE, SYSCALL), and enable them
	- Assign a PAT to write combining
	- Setup FS/GS base
	- Load IDTR
	- Enable APIC and setup using information in ACPI tables
	- Setup GDT and TSS 
