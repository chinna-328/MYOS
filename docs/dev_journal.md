# Dev Journal — MyOS

## Day 1 — Milestone 1: Bootloader

### What I did
- Set up project structure
- Wrote print.asm (BIOS teletype string printing)
- Wrote print_hex.asm (16-bit hex value printing)
- Wrote boot.asm (main bootloader)
- Created Makefile with run/debug/hexdump targets

### What I learned
- BIOS loads the first 512 bytes of a disk to 0x7C00
- The magic number 0xAA55 marks a sector as bootable
- Real Mode uses 16-bit registers and segment:offset addressing
- BIOS int 0x10 function 0x0E prints a character at the cursor
- pusha and popa save/restore all general-purpose registers
- lodsb loads a byte from [SI] into AL and increments SI
- Hex conversion: nibble 0-9 add 0x30, nibble A-F add 0x37
