; ===========================================================
;  print.asm — Print a null-terminated string using BIOS
; ===========================================================
;
;  HOW IT WORKS:
;  The BIOS provides interrupt 0x10 for video services.
;  Function 0x0E (teletype output) prints one character at
;  the current cursor position and advances the cursor.
;
;  We loop through each byte of the string, send it to
;  int 0x10, and stop when we hit a 0x00 (null terminator).
;
;  USAGE:
;    mov bx, MY_STRING   ; put address of string in BX
;    call print           ; prints the string
;
;  REGISTERS USED:
;    BX = pointer to string (input, preserved)
;    AH = 0x0E (BIOS teletype function number)
;    AL = current character being printed
;    SI = internal pointer (used to walk through string)
; ===========================================================

print:
    pusha                   ; Save ALL registers to the stack.
                            ; We're being polite — whoever called us
                            ; expects their registers unchanged.

    mov si, bx              ; Copy string address from BX → SI.
                            ; We use SI as our "walking pointer"
                            ; because BX is our input — we don't
                            ; want to modify the caller's BX.

.loop:
    lodsb                   ; Load byte at [SI] into AL, then SI++.
                            ; This is a shortcut for:
                            ;   mov al, [si]
                            ;   inc si
                            ; LODSB = "Load String Byte"

    cmp al, 0              ; Is this the null terminator (0x00)?
    je .done               ; If yes, we've reached the end → stop.

    mov ah, 0x0E           ; BIOS function: Teletype Output
                            ; AH = function number
                            ; AL = character to print (already set by lodsb)

    int 0x10               ; Call BIOS video interrupt!
                            ; This prints the character in AL
                            ; at the current cursor position
                            ; and advances the cursor by one.

    jmp .loop              ; Go back and process the next character.

.done:
    popa                    ; Restore ALL registers from the stack.
                            ; The caller's registers are exactly as
                            ; they were before calling us.
    ret                     ; Return to whoever called us.


; ===========================================================
;  print_nl — Print a newline (CR + LF)
; ===========================================================
;
;  Newline on screen requires TWO characters:
;    0x0D = Carriage Return (move cursor to column 0)
;    0x0A = Line Feed (move cursor down one row)
;
;  We just point BX to a tiny 3-byte string and call print.
; ===========================================================

print_nl:
    pusha

    mov ah, 0x0E

    mov al, 0x0D           ; Carriage Return — move to start of line
    int 0x10

    mov al, 0x0A           ; Line Feed — move down one line
    int 0x10

    popa
    ret