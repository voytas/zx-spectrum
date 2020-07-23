        module Screen

MAX_X_POS   equ     31
MAX_Y_POS   equ     23
ATTRIBUTES  equ     #5800

;-----------------------------------------------------------
; scroll_text_up - Scroll text one line up
; Input:
;   None
; Modifies:
;  AF, BC, DE, HL, IX
;-----------------------------------------------------------
; print_char - Print a character provided in the accumulator
;
; Input:
;   B - x position (0-31)
;   C - y position (0-23)
;   A - character to print
; Modifies:
;   BC, DE, HL, AF
;-----------------------------------------------------------
; print_string - Print a string provided as an address in DE
;
; Input:
;   B  - x position (0-31)
;   C  - y position (0-23)
;   DE - string to print (zero terminated)
; Modifies:
;   BC, DE, HL, AF
;-----------------------------------------------------------

@print_string:
        ld a,(de)                       ; char to print
        or a                            ; check if end of string (zero)
        ret z                           ; if zero, no more to print
        push de
        push bc
        call print_char
        pop bc
        pop de
        inc de
        ld a,(de)                       ; next char to print
        or a                            ; check if end of string (zero)
        ret z                           ; if zero, no more to print
        ld a,b
        cp MAX_X_POS                    ; check if need to move down
        jr z,new_line
        inc b
        jr print_string
new_line:
        ld b,0                          ; reset x_pos
        ld a,c
        cp MAX_Y_POS                    ; check if last screen line
        jr z,scroll_up
        inc c                           ; if not increment y_pos
        jr print_string
scroll_up:
        push bc
        push de
        call scroll_text_up             ; scroll 1 line up
        pop de
        pop bc
        jr print_string

@print_char:
; screen address calculation
        ex af,af'                       ; preserve char code
        ld a,b
        ld b,0
        sla c                           ; x2 (max 46)
        sla c                           ; x4 (max 92)
        sla c                           ; x8 (max 184)
        sla c                           ; x16 (may overflow)
        rl b                            ; handle overflow
        ld hl,screen_map
        add hl,bc                       ; HL = screen_map + x_pos + y_pos * 16
        ld de,(hl)                      ; screen address
        add e                           ; add x_pos
        ld e,a
        ex af,af'                       ; restore char code

; char bitmap address calculation
        sub #20                         ; zero based ASCII index
        ld b,0
        ld c,a                          ; each char is 8 bytes, skip 8x bytes
        sla c                           ; x2 (max 222)
        sla c                           ; x4 (may overflow)
        rl b                            ; shift b, too
        sla c                           ; x8 (may overflow)
        rl b                            ; shift b, too
        ld hl,char_map_c64
        add hl,bc                       ; now have correct char template address
        ld b,8                          ; 8 lines to print per char
print_char_lines:
        ld a,(hl)                       ; char line
        ld (de),a                       ; output to screen
        inc hl                          ; next char line
        inc d                           ; next screen line
        djnz print_char_lines           ; and continue
        ret

@scroll_text_up
        ld ix,screen_map
        ld a,23                         ; number of text lines
repeat_row:
        ex af,af'
        ld a,8                          ; number of lines per char
        ld de,(ix)                      ; current line address
        ld hl,(ix + 16)                 ; next line address
repeat_line:
        ld bc,32                        ; 32 bytes per line
        push de
        push hl
        ldir                            ; copy line (32 bytes)
        pop hl
        pop de
        inc d                           ; next destination line
        inc h                           ; next source line
        dec a
        jr nz,repeat_line               ; repeat 8 times
        ld bc,16
        add ix,bc                       ; next line address
        ex af,af'
        dec a
        jr nz,repeat_row                ; repeat 23 times
; clear the last line after scroll
        ld b,8                          ; number of lines in pixels
        ld h,#50                        ; address of the last text line (#50E0)
clear_line1:
        ld l,#E0
clear_line2:
        ld (hl),0                       ; clear it
        inc l                           ; next column (E0-FF)
        jr nz,clear_line2               ; repeat 32 times
        inc h                           ; next line
        djnz clear_line1                ; repeat 8 times
        ret

@paper:
        ld hl,ATTRIBUTES
        ld (hl),255
        ret

; addresses of each screen line
screen_map:
        dw #4000, #4100, #4200, #4300, #4400, #4500, #4600, #4700       // Line 0-7
        dw #4020, #4120, #4220, #4320, #4420, #4520, #4620, #4720       // Line 8-15
        dw #4040, #4140, #4240, #4340, #4440, #4540, #4640, #4740       // Line 16-23
        dw #4060, #4160, #4260, #4360, #4460, #4560, #4660, #4760       // Line 24-31
        dw #4080, #4180, #4280, #4380, #4480, #4580, #4680, #4780       // Line 32-39
        dw #40A0, #41A0, #42A0, #43A0, #44A0, #45A0, #46A0, #47A0       // Line 40-47
        dw #40C0, #41C0, #42C0, #43C0, #44C0, #45C0, #46C0, #47C0       // Line 48-55
        dw #40E0, #41E0, #42E0, #43E0, #44E0, #45E0, #46E0, #47E0       // Line 56-63
        dw #4800, #4900, #4A00, #4B00, #4C00, #4D00, #4E00, #4F00       // Line 64-71
        dw #4820, #4920, #4A20, #4B20, #4C20, #4D20, #4E20, #4F20       // Line 72-79
        dw #4840, #4940, #4A40, #4B40, #4C40, #4D40, #4E40, #4F40       // Line 80-87
        dw #4860, #4960, #4A60, #4B60, #4C60, #4D60, #4E60, #4F60       // Line 88-95
        dw #4880, #4980, #4A80, #4B80, #4C80, #4D80, #4E80, #4F80       // Line 96-103
        dw #48A0, #49A0, #4AA0, #4BA0, #4CA0, #4DA0, #4EA0, #4FA0       // Line 104-111
        dw #48C0, #49C0, #4AC0, #4BC0, #4CC0, #4DC0, #4EC0, #4FC0       // Line 112-119
        dw #48E0, #49E0, #4AE0, #4BE0, #4CE0, #4DE0, #4EE0, #4FE0       // Line 120-127
        dw #5000, #5100, #5200, #5300, #5400, #5500, #5600, #5700       // Line 128-135
        dw #5020, #5120, #5220, #5320, #5420, #5520, #5620, #5720       // Line 136-143
        dw #5040, #5140, #5240, #5340, #5440, #5540, #5640, #5740       // Line 144-151
        dw #5060, #5160, #5260, #5360, #5460, #5560, #5660, #5760       // Line 152-159
        dw #5080, #5180, #5280, #5380, #5480, #5580, #5680, #5780       // Line 160-167
        dw #50A0, #51A0, #52A0, #53A0, #54A0, #55A0, #56A0, #57A0       // Line 168-175
        dw #50C0, #51C0, #52C0, #53C0, #54C0, #55C0, #56C0, #57C0       // Line 176-183
        dw #50E0, #51E0, #52E0, #53E0, #54E0, #55E0, #56E0, #57E0       // Line 184-191

        include "./lib/charmap.asm"

        endmodule