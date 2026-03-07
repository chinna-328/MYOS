; ===========================================================
;  print_hex.asm — Print a 16-bit value as hexadecimal
; ===========================================================
;
;  HOW IT WORKS:
;  We need to convert a binary number into ASCII hex characters.
;
;  Example: DX = 0x1FB6
;  We want to print: "0x1FB6"
;
;  The trick: Extract each nibble (4 bits) from DX, convert
;  it to its ASCII hex character, and store it in a template
;  string. Then print the string.
;
;  A nibble can be 0x0–0xF:
;    0x0–0x9 → ASCII '0'–'9' (add 0x30)
;    0xA–0xF → ASCII 'A'–'F' (add 0x37)
;                              because 0xA + 0x37 = 0x41 = 'A'
;
;  USAGE:
;    mov dx, 0x1FB6      ; put the value in DX
;    call print_hex       ; prints "0x1FB6"
;
;  REGISTERS USED:
;    DX = 16-bit value to print (input)
;    CX = loop counter (4 nibbles)
;    AX = scratch register for conversion
; ===========================================================

print_hex:
    pusha                   ; Save all registers

    mov cx, 4              ; We have 4 hex digits to process
                            ; (16 bits / 4 bits per digit = 4 digits)

.loop:
    dec cx                  ; CX goes 3, 2, 1, 0 (we use it as index)

    ; -- Step 1: Extract the lowest nibble from DX --
    mov ax, dx              ; Copy DX into AX (we'll work with AX)
    and ax, 0x000F          ; Mask: keep only the lowest 4 bits
                            ; Example: 0x1FB6 AND 0x000F = 0x0006

    ; -- Step 2: Convert nibble to ASCII character --
    cmp al, 9              ; Is this nibble 0-9 or A-F?
    jle .is_digit

.is_alpha:                  ; Nibble is 0xA-0xF
    add al, 0x37           ; 0xA + 0x37 = 0x41 = 'A'
                            ; 0xB + 0x37 = 0x42 = 'B'  ...etc
    jmp .store

.is_digit:                  ; Nibble is 0x0-0x9
    add al, 0x30           ; 0x0 + 0x30 = 0x30 = '0'
                            ; 0x1 + 0x30 = 0x31 = '1'  ...etc

.store:
    ; -- Step 3: Store the ASCII character in our template --
    ; HEX_OUT is "0x0000". The digits start at HEX_OUT+2.
    ; CX tells us which position (3=leftmost, 0=rightmost):
    ;
    ;   HEX_OUT: '0' 'x' '?' '?' '?' '?'  0x00
    ;   Index:    0   1    2   3   4   5    6
    ;   CX=3 -> index 2 (leftmost hex digit)
    ;   CX=2 -> index 3
    ;   CX=1 -> index 4
    ;   CX=0 -> index 5 (rightmost hex digit)

    mov bx, HEX_OUT        ; BX = base address of template string
    add bx, 2              ; Skip past "0x" prefix
    add bx, cx             ; Add offset for this digit's position

    mov [bx], al           ; Store the ASCII character

    ; -- Step 4: Shift DX right by 4 bits for the next nibble --
    shr dx, 4              ; 0x1FB6 -> 0x01FB -> 0x001F -> 0x0001
                            ; Each shift exposes the next nibble

    ; -- Step 5: Loop or finish --
    cmp cx, 0              ; Have we processed all 4 digits?
    je .done
    jmp .loop

.done:
    mov bx, HEX_OUT        ; Point BX to our completed hex string
    call print              ; Print it!

    popa                    ; Restore all registers
    ret

; -- Template string --
; We fill in the '0' placeholders with actual hex digits.
; The final null byte (0) tells our print function where to stop.
HEX_OUT:
    db '0x0000', 0          ; 7 bytes: '0','x','0','0','0','0', 0x00