# Milestone 1 — Bare Metal Bootloader

## What We Built

A 512-byte boot sector that:
1. BIOS loads from disk into memory at 0x7C00
2. Sets up segment registers (DS, ES, SS) and stack pointer
3. Prints a welcome banner using BIOS int 0x10
4. Prints hex values (0x1FB6, 0x0000, 0xFFFF) for debugging
5. Halts the CPU in an infinite HLT loop

## Key Concepts Learned

### The Boot Process
- CPU starts in 16-bit Real Mode
- BIOS reads first 512 bytes of disk (the boot sector)
- Checks for magic number 0xAA55 at bytes 510-511
- Loads sector to 0x7C00 and jumps to it

### Real Mode
- 16-bit registers (AX, BX, CX, DX, SI, DI, SP, BP)
- 1 MB addressable memory (0x00000 - 0xFFFFF)
- Segment:Offset addressing (Physical = Segment x 16 + Offset)
- Direct access to BIOS interrupts

### BIOS Interrupts Used
- int 0x10, AH=0x0E — Teletype output (print one character)

### Memory Layout
- 0x7C00-0x7DFF: Our bootloader (512 bytes)
- 0x9000: Stack top (grows downward)
- 0xB8000: VGA text buffer (not used yet — we use BIOS instead)

## Files

| File               | Purpose                         |
|--------------------|---------------------------------|
| boot/boot.asm      | Main bootloader, entry point    |
| boot/print.asm     | print() and print_nl() functions|
| boot/print_hex.asm | print_hex() for debugging       |

## Expected Output

    =============================
      MyOS Bootloader v0.1
      Running on bare metal!
    =============================
    Test hex 0x1FB6: 0x1FB6
    Test hex 0x0000: 0x0000
    Test hex 0xFFFF: 0xFFFF
    Boot complete. CPU halted.

## What's Next

- Read sectors from disk (BIOS int 0x13)
- Set up the Global Descriptor Table (GDT)
- Switch from Real Mode (16-bit) to Protected Mode (32-bit)