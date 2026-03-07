# ================================================================
#  Makefile — MyOS Build System (Milestone 1)
# ================================================================
#
#  USAGE:
#    make          Build the bootloader
#    make run      Build + run in QEMU
#    make debug    Build + run in QEMU with GDB support
#    make bochs    Build + run in Bochs
#    make clean    Remove all build artifacts
#    make hexdump  Show raw bytes of the boot image
#
# ================================================================

# -- Tools --
ASM      = nasm
QEMU     = qemu-system-i386
BOCHS    = bochs

# -- Flags --
ASMFLAGS = -f bin

# -- Directories --
BOOT_DIR = boot
BUILD_DIR = build

# -- Files --
BOOT_SRC = $(BOOT_DIR)/boot.asm
BOOT_BIN = $(BUILD_DIR)/boot.bin

# ================================================================
#  TARGETS
# ================================================================

# Default target: build everything
all: $(BOOT_BIN)
	@echo ""
	@echo "Build successful!"
	@echo "   Output: $(BOOT_BIN) ($$(wc -c < $(BOOT_BIN)) bytes)"
	@echo "   Run with: make run"
	@echo ""

# Assemble the bootloader
#
# -f bin  = Output raw binary (no ELF headers, no linking)
#           This is critical! The BIOS expects raw machine code,
#           not an ELF executable. The output must be EXACTLY
#           512 bytes with the 0xAA55 signature at the end.
#
# -I ./   = Include path (so %include "boot/print.asm" works)
#
$(BOOT_BIN): $(BOOT_SRC) $(BOOT_DIR)/print.asm $(BOOT_DIR)/print_hex.asm
	@mkdir -p $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -I ./ $(BOOT_SRC) -o $(BOOT_BIN)

# Run in QEMU
#
# -fda    = Load as floppy disk drive A
#           BIOS will try to boot from floppy first
#
run: $(BOOT_BIN)
	@echo "Launching QEMU..."
	$(QEMU) -fda $(BOOT_BIN)

# Run in QEMU with GDB debug support
#
# -s = Start GDB server on localhost:1234
# -S = Freeze CPU at startup (wait for GDB to connect)
#
# In another terminal:
#   gdb -ex "target remote :1234" -ex "set architecture i8086"
#
debug: $(BOOT_BIN)
	@echo "Launching QEMU in debug mode (GDB on :1234)..."
	@echo "   Connect with: gdb -ex 'target remote :1234' -ex 'set arch i8086'"
	$(QEMU) -fda $(BOOT_BIN) -s -S

# Run in Bochs
bochs: $(BOOT_BIN)
	@echo "Launching Bochs..."
	$(BOCHS) -f bochsrc.txt -q

# Show a hexdump of the boot image
# Useful for verifying:
#   - Total size is 512 bytes
#   - Last 2 bytes are 55 AA
#   - Code starts at the beginning
hexdump: $(BOOT_BIN)
	@echo "Hexdump of $(BOOT_BIN):"
	@echo ""
	xxd $(BOOT_BIN) | head -5
	@echo "   ..."
	xxd $(BOOT_BIN) | tail -3
	@echo ""
	@echo "Last 2 bytes (should be 55 AA):"
	xxd -s 510 -l 2 $(BOOT_BIN)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm bochsout.log
	@echo "Cleaned."

# Mark targets that don't produce files
.PHONY: all run debug bochs hexdump clean