AUXFILES:=Makefile notes.md
ASM=nasm

SRC_DIR=Bios_Bootloader_C
MBR_DIR=Bios_Bootloader_C/mbr

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
