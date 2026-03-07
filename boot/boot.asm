; ===========================================================
;  boot.asm — Stage 1 Bootloader (MBR — Master Boot Record)
; ===========================================================
;
;  This is where everything begins.
;
;  When you press the power button:
;    1. CPU starts -> runs BIOS
;    2. BIOS reads the first 512 bytes of the disk
;    3. BIOS checks: do the last 2 bytes equal 0xAA55?
;    4. If yes -> BIOS loads those 512 bytes to address 0x7C00
;    5. BIOS jumps to 0x7C00 -> YOUR CODE RUNS!
;
;  This file IS those 512 bytes. Every byte counts.
;
;  WHAT THIS BOOTLOADER DOES:
;    1. Sets up segment registers and stack
;    2. Prints a welcome message
;    3. Prints a hex value (to prove print_hex works)
;    4. Halts the CPU
;
; ===========================================================

[org 0x7C00]                ; Tell NASM: "This code will be loaded at
                            ; memory address 0x7C00 by the BIOS."
                            ;
                            ; WHY THIS MATTERS:
                            ; When you write `mov bx, MY_STRING`, NASM
                            ; needs to calculate the ACTUAL memory address
                            ; of MY_STRING. Without [org 0x7C00], NASM
                            ; thinks the code starts at 0x0000, so all
                            ; addresses would be WRONG.
                            ;
                            ; With [org 0x7C00], NASM adds 0x7C00 to all
                            ; labels, giving correct addresses.

[bits 16]                   ; Tell NASM: "Generate 16-bit Real Mode code."
                            ; The CPU starts in Real Mode after power-on.
                            ; Real Mode = 16-bit registers, 1 MB address space.


; ===========================================================
;  SECTION: Setup
; ===========================================================

    ; -- Initialize Segment Registers --
    ;
    ; In Real Mode, memory addresses are calculated as:
    ;   Physical Address = (Segment x 16) + Offset
    ;
    ; Example: DS=0x0000, Offset=0x7C00
    ;   Physical = 0x0000 x 16 + 0x7C00 = 0x7C00
    ;
    ; The BIOS doesn't guarantee what DS, ES, SS contain
    ; when it jumps to our code. They could be ANYTHING.
    ; We MUST set them ourselves to avoid weird bugs.

    xor ax, ax              ; AX = 0 (faster than `mov ax, 0`)
    mov ds, ax              ; Data Segment = 0
    mov es, ax              ; Extra Segment = 0

    ; -- Set Up the Stack --
    ;
    ; The stack grows DOWNWARD in memory.
    ; We put the stack at 0x9000 — safely above our bootloader
    ; (which is at 0x7C00-0x7E00) and below the BIOS area.
    ;
    ;   0x7C00  +-------------------+  Our bootloader (512 bytes)
    ;   0x7E00  +-------------------+
    ;           |  Free space        |
    ;   0x9000  +-------------------+  <-- Stack starts here (SS:SP)
    ;           |  Stack grows down  |      and grows downward
    ;           +-------------------+

    mov ss, ax              ; Stack Segment = 0
    mov sp, 0x9000          ; Stack Pointer = 0x9000
                            ; Stack will grow downward from here.

    ; -- Clear Direction Flag --
    cld                     ; Ensure string operations (lodsb) go FORWARD.
                            ; DF=0 means SI increments (forward).
                            ; DF=1 would mean SI decrements (backward).


; ===========================================================
;  SECTION: Main — Print Messages
; ===========================================================

    ; -- Print Welcome Message --
    mov bx, MSG_HELLO       ; BX = address of our hello string
    call print              ; Call our print function (from print.asm)
    call print_nl           ; Print a newline after it

    ; -- Print a Hex Value (Debugging Demo) --
    ;
    ; This proves our print_hex function works.
    ; In real OS dev, you'll use this constantly to inspect
    ; register values, memory addresses, and return codes.

    mov bx, MSG_HEX        ; Print a label first
    call print

    mov dx, 0x1FB6          ; Load a test value into DX
    call print_hex          ; Should print "0x1FB6"
    call print_nl

    ; -- Print Another Hex Value --
    mov bx, MSG_HEX2
    call print

    mov dx, 0x0000          ; Edge case: all zeros
    call print_hex          ; Should print "0x0000"
    call print_nl

    ; -- Print Another Hex Value --
    mov bx, MSG_HEX3
    call print

    mov dx, 0xFFFF          ; Edge case: max value
    call print_hex          ; Should print "0xFFFF"
    call print_nl

    ; -- Print Boot Complete --
    mov bx, MSG_DONE
    call print
    call print_nl


; ===========================================================
;  SECTION: Halt — Infinite Loop
; ===========================================================
;
;  We're done. But we can't just "return" — there's nothing
;  to return TO. The BIOS jumped to us and expects us to
;  either load an OS or hang forever.
;
;  HLT pauses the CPU until the next interrupt.
;  The JMP loop catches us if an interrupt wakes us up.

hang:
    hlt                    ; Halt the CPU (low power, waits for interrupt)
    jmp hang               ; If an interrupt wakes us, halt again.
                            ; This is an infinite loop — the CPU stays here forever.


; ===========================================================
;  SECTION: Data — Strings
; ===========================================================
;
;  db = "define byte" — places raw bytes into the binary.
;  Each string ends with 0 (null terminator) so our print
;  function knows where the string ends.
;
;  0x0D = Carriage Return, 0x0A = Line Feed (newline)

MSG_HELLO:
    db '=============================', 0x0D, 0x0A
    db '  MyOS Bootloader v0.1', 0x0D, 0x0A
    db '  Running on bare metal!', 0x0D, 0x0A
    db '=============================', 0

MSG_HEX:
    db 'Test hex 0x1FB6: ', 0

MSG_HEX2:
    db 'Test hex 0x0000: ', 0

MSG_HEX3:
    db 'Test hex 0xFFFF: ', 0

MSG_DONE:
    db 'Boot complete. CPU halted.', 0


; ===========================================================
;  SECTION: Includes
; ===========================================================
;
;  %include literally pastes the contents of these files
;  right here. It's like #include in C.
;
;  ORDER MATTERS: These must come AFTER the data section
;  but BEFORE the boot signature padding, because they
;  contain code that adds to our binary size. The boot
;  signature must be the LAST 2 bytes of the 512-byte sector.

%include "boot/print.asm"
%include "boot/print_hex.asm"


; ===========================================================
;  SECTION: Boot Signature — CRITICAL!
; ===========================================================
;
;  The BIOS checks the LAST 2 BYTES of the first 512-byte
;  sector. If they are 0x55 and 0xAA (little-endian: 0xAA55),
;  the BIOS considers this sector "bootable."
;
;  Without this magic number, the BIOS will say
;  "No bootable device found" and skip your disk.
;
;  $ = current position in the binary
;  $$ = start of the current section (0x7C00 for us)
;  $ - $$ = how many bytes we've used so far
;  510 - ($ - $$) = how many bytes are LEFT before byte 510
;
;  times N db 0 = fill N bytes with zeros (padding)
;
;  This padding + signature ensures the binary is EXACTLY
;  512 bytes — no more, no less.

times 510 - ($ - $$) db 0   ; Pad with zeros up to byte 510
dw 0xAA55                    ; Boot signature at bytes 510-511
                             ; dw = "define word" (2 bytes)
                             ; NASM stores this as 0x55 0xAA in memory
                             ; (little-endian), which is what BIOS expects.