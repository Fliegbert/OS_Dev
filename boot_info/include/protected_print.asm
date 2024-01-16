[BITS 32]

fill_screen:
        mov edi, [vbe_mode_info.phys_base_ptr]
        mov ecx, 800*600
        mov eax, 0xFFFFFFFF
        rep stosd
        ret
;;; print_p: Print a string to video memory
;;; Parameters:
;;;     input 1: address of string
;;;     input 2: row to print to        (address, not value)
;;;     input 3: column to print to     (address, not value)
;;;     output 1: return code in AX
print_p:
        push ebp
        mov ebp, esp
        sub esp, 4              ; error/return code

        push edi
        push esi
        push ebx
        push ecx
        push edx

        ;; Set up EDI with row/col to print to
        mov edi, [vbe_mode_info.phys_base_ptr]
        xor eax, eax
        mov ax, [vbe_mode_info.bytes_per_scanline]

        mov ebx, [ebp+12]       ; Cursor Y address                              ; Pushed middle
        mov bx, [ebx]           ; Cursor Y value
        and ebx, 0x0000FFFF     ; blank out upper 16 bits
        shl ebx, 4              ; multiply by 16 - # of lines per char
        imul ebx, eax           ; multiply by bytes per line
        mov esi, ebx            ; row to print to, in bytes

        mov ebx, [ebp+8]        ; Cursor X address                              ; Was pushed last
        mov bx, [ebx]           ; Cursor X value
        and ebx, 0x0000FFFF     ; blank out upper 16 bits
        ; Kernel Cursor for where to start
        ; Width of a text character equals:
        ; text size 8x16 = 8 Pixels * 4 Bytes per Pixel = 32 Bytes
        shl ebx, 5              ; Col to print to, in bytes
        add esi, ebx            ; screen position in bytes to write text to     ; Ab Hier erstmal
        add edi, esi            ; EDI = Offset into screen framebuffer
        mov esi, [ebp+16]       ; Start of string to print (in ESI)             ; Pushed first, string i want to print, Parameter String

        .loop:
                lodsb                   ; Load byte from ESI to AL
                cmp al, 0
                je .end_print
                cmp al, 0xA             ; Line feed?
                je .LF
                cmp al, 0xD             ; Carriage return?
                je .CR
                
                ; Print Character
                shl eax, 4              ; Multiply by 16 - length of stored char in bytes       ; I think shift left because value gets more when shifted left, bit and stuff
                sub eax, 16             ; Go to start of char                                   ; substract 16 bytes to get start
                add eax, 5000h          ; Bitmap font memory address - offset by ascii value    ; add font memory to get start
                push dword 16           ; Height of character in lines                          ; for later inside loop
                .char_loop:
                        mov ecx, 8              ; # of bits to check                            ; bit amount to check before next line
                        mov bl, [eax]           ; Get next byte of character                    ; move byte to check with bt instruction
                        inc eax                 ; move to next byte                             ; prepare next byte for subsequent loop
                        .bit_loop:
                                mov edx, ecx
                                dec edx
                                bt bx, dx
                                jc .write_text_color
                                mov [edi], dword 0x000000FF                     ; ARGB text bg color - blue
                                jmp .next_bit

                                .write_text_color:
                                mov [edi], dword 0x00FFFFFF                     ; ARGB text fg color - white

                                .next_bit:
                                add edi, 4              ; Next pixel position in frame buffer                   ; 1 Pixel = 4 Bytes = 32 bpp (Bits per pixel)
                                dec ecx,                                                                        ; Next Bit to check in bx
                                jnz .bit_loop

                                pop ecx                 ; # of lines left to write
                                dec ecx
                                jz .inc_cursor
                                xor edx, edx
                                mov dx, [vbe_mode_info.bytes_per_scanline]      ; Bytes per scanline
                                add edi, edx            ; Go down 1 line on screen
                                sub edi, 32             ; move back 1 char width to line up
                                push ecx
                                jmp .char_loop

                .inc_cursor:
                xor edx, edx
                mov dx, [vbe_mode_info.bytes_per_scanline]
                imul edx, 15
                sub edi, edx

                mov ebx,[ebp+8]

                inc word [ebx]
                cmp word [ebx], 80
                jne .loop

                xor edx, edx
                mov dx, word [ebx]
                shl dx, 5
                sub edi, edx
                mov word [ebx], 0

                .LF:
                        mov ebx, [ebp+12]       ; Cursor Y address
                        inc word [ebx]          ; Go down 1 row
                        cmp word [ebx], 30      ; At bottom? (30 * 16 = 480)
                        jge .scroll_down

                        xor eax, eax
                        mov ax, [vbe_mode_info.bytes_per_scanline]      ; Bytes per scanline
                        shl eax, 4              ; multiply by 16 - char height in lines
                        add edi, eax            ; go down 1 char row
                        mov ebx, [ebp+8]        ; Cursor X address
                        jmp .loop

                .CR:
                        mov ebx, [ebp+8]        ; Cursor X address
                        xor edx, edx
                        mov dx, word [ebx]
                        shl dx, 5               ; multiply by 32 - 8px char width * 4 bytes
                        sub edi, edx
                        mov word [ebx], 0
                        jmp .loop

                .scroll_down:
                        ;; copy screen lines 1-24 into lines 0-23 (0-based),
                        ;; then clear out last line, line 24
                        ;; and continue printing
                        push edi
                        push esi

                        mov edi, [vbe_mode_info.phys_base_ptr]
                        mov esi, edi
                        xor eax, eax
                        mov ax, [vbe_mode_info.bytes_per_scanline]
                        shl eax, 4
                        add esi, eax            ; Byte location of screen line 1
                        
                        ; 600 lines - 16 lines character height = 584 lines
                        ; 584 * bytes per scanline (800 pixels * 4 bytes per pixel = 3200 bytes)
                        ; 584 * 3200 = 1868800 or 1C8400h bytes
                        ; 1868800 / 4 = 467200 or 72100h dbl words
                        mov ecx, 0x72100
                        rep movsd               ; Copy char height lines offset by 1 from esi to edi

                        ; EDI pointing at last character line (last 16 lines)
                        ; 800px per line * 16 lines = 12800px * 4 bytes per px = 51200 bytes
                        ; 51200 / 4 = 12800 or 3200h dbl words
                        mov eax, 0x000000FF     ; Pixel color - blue
                        mov ecx, 0x3200
                        rep stosd               ; clear last line

                        pop esi
                        pop edi

                        dec word [ebx]          ; set Y = line 24
                        mov ebx, [ebp+8]        ; Cursor X address
        jmp .loop

        .end_print:
        mov dword [ebp-4], 0            ; Return code 0 = success
        mov eax, [ebp-4]

        pop edx
        pop ecx
        pop ebx
        pop esi
        pop edi

        mov esp, ebp
        pop ebp

        ret



; source: https://www.youtube.com/watch?v=yimDZ1Nxg28 1:13:00
