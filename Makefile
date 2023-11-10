AUXFILES:=Makefile notes.md
ASM=nasm

SRC_DIR=Bios_Bootloader_C
MBR_DIR=Bios_Bootloader_C/mbr
BIOS_INFO_DIR=Bios_Bootloader_C/boot_info

SRCFILES := $(shell find $(PROJDIRS) -type f -name "\*.asm")
INCFILES := $(shell find $(PROJDIRS) -type f -name "\*.inc")
DEPFILES:=$(patsubst %.asm,%.inc,$(SRCFILES))

.Phony: clean, .force-rebuild

all: bootloader.bin

bootloader.bin: os.asm
	@nasm -fbin os.asm -o os.bin
	@sudo dd if=os.bin of=/dev/sda
	@qemu-system-i386 -hda os.bin

clean:
	@rm *.bin

#debug:
	#@nasm os_debug.asm -f elf -g -o os_debug.elf
	#@objcopy -O binary os_debug.elf os_debug.img
	#@qemu -s -S -hda os_debug.img -boot a
	#@gdb
