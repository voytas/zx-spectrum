;    ZX Spectrum keyboard port mapping
;   +----+-----+-----+-----+-----+-----+
;   |    |             Bit             |
;   |Port|-----------------------------|
;   |    |  4     3     2     1     0  |
;   +----+-----+-----+-----+-----+-----+
;   |FEFE|  V  |  C  |  X  |  Z  | SHF |
;   |FDFE|  G  |  F  |  D  |  S  |  A  |
;   |FBFE|  T  |  R  |  E  |  W  |  Q  |
;   |F7FE|  5  |  4  |  3  |  2  |  1  |
;   |EFFE|  6  |  7  |  8  |  9  |  0  |
;   |DFFE|  Y  |  U  |  I  |  O  |  P  |
;   |BFFE|  H  |  J  |  K  |  L  | ENT |
;   |7FFE|  B  |  N  |  M  | SSH | SPC |
;   +----+-----+-----+-----+-----+-----+
;
;   SHF = Shift, ENT = Enter, SSH = Symbol Shift, SPC = Space
;   Note: bit is set to 0 if key is pressed, otherwise it is 1

KEY_NONE    equ     #FF
KEY_0       equ     #00
KEY_1       equ     #01
KEY_2       equ     #02
KEY_3       equ     #03
KEY_4       equ     #04
KEY_5       equ     #05
KEY_6       equ     #06
KEY_7       equ     #07
KEY_8       equ     #08
KEY_9       equ     #09
KEY_A       equ     #0A
KEY_B       equ     #0B
KEY_C       equ     #0C
KEY_D       equ     #0D
KEY_E       equ     #0E
KEY_F       equ     #0F
KEY_G       equ     #10
KEY_H       equ     #11
KEY_I       equ     #12
KEY_J       equ     #13
KEY_K       equ     #14
KEY_L       equ     #15
KEY_M       equ     #16
KEY_N       equ     #17
KEY_O       equ     #18
KEY_P       equ     #19
KEY_Q       equ     #1A
KEY_R       equ     #1B
KEY_S       equ     #1C
KEY_T       equ     #1D
KEY_U       equ     #1E
KEY_V       equ     #1F
KEY_W       equ     #20
KEY_X       equ     #21
KEY_Y       equ     #22
KEY_Z       equ     #23
KEY_ENTER   equ     #24
KEY_SPACE   equ     #25
KEY_SHIFT   equ     #80    ; mask 10000000
KEY_SSHIFT  equ     #40    ; mask 01000000

        module Keyboard
;
; Reads the keyboard and returns a result in A register with the code (see above).
; If multiple keys are pressed (excluding Shift and Symbol Shift) it returns KEY_NONE.
; Shift and Symbol Shift state is returned as b7 and b6 respectively.
;
; Input:
;   None
; Modifies:
;   BC, DE, HL and A
; Returns:
;   A = pressed key
;
@read_key:
        ld hl,key_map                   ; load the key mapping address
        ld e,KEY_NONE                   ; default to no key
read_port:
        ld a,(hl)                       ; read the port number
        or a                            ; is it zero?
        jr z,done                       ; if yes, we can exit
        ld b,a
        ld c,#FE                        ; now we have port number in BC
        in a,(c)                        ; read the value from that port
        cpl                             ; invert result, so pressed key value is 1
        and #1F                         ; first five bits contain key states
        ld b,5                          ; number of keys to process
process_key:
        inc hl                          ; char code address
        srl a                           ; check if key is pressed
        ld c,a                          ; preserve A value
        jr nc,next_key                  ; if key is not pressed, move to the next key
        ld a,(hl)                       ; load the key code
        inc e                           ; check if E equals KEY_NONE
        jr nz,not_first_key             ; if key state is not empty, check for multiple keys pressed
        ld e,a                          ; store pressed key code
        jr next_key                     ; and move to the next key
not_first_key:
        dec e                           ; restore stored key code value
set_key_value:
        cp KEY_SHIFT                    ; is it Shift?
        jr nz,not_shift
        set 7,e                         ; KEY_SHIFT
        jr next_key
not_shift:
        cp KEY_SSHIFT                   ; or is it Symbol Shift?
        jr nz,other_key                 ; or some other key
        set 6,e                         ; KEY_SSHIFT
        jr next_key
other_key:
        ld d,a
        ld a,e
        and #3F                         ; check if we have non-shift key already stored
        jr nz,duplicate_key             ; and handle multiple key scenario
        ld a,d
        or e                            ; now A = A | E
        ld e,a                          ; store new key code
        jr next_key                     ; and move to the next key
duplicate_key:
        ld e,KEY_NONE
        ret
next_key:
        ld a,c                          ; restore A value
        djnz process_key                ; continue if not five keys processed
        inc hl                          ; next port location
        jr read_port
done:
        ld a,e                          ; return result
        ret

key_map:
        db #FE, KEY_SHIFT, KEY_Z,      KEY_X, KEY_C, KEY_V   ; port 1111 1110
        db #FD, KEY_A,     KEY_S,      KEY_D, KEY_F, KEY_G   ; port 1111 1101
        db #FB, KEY_Q,     KEY_W,      KEY_E, KEY_R, KEY_T   ; port 1111 1011
        db #F7, KEY_1,     KEY_2,      KEY_3, KEY_4, KEY_5   ; port 1111 0111
        db #EF, KEY_0,     KEY_9,      KEY_8, KEY_7, KEY_6   ; port 1110 1111
        db #DF, KEY_P,     KEY_O,      KEY_I, KEY_U, KEY_Y   ; port 1101 1111
        db #BF, KEY_ENTER, KEY_L,      KEY_K, KEY_J, KEY_H   ; port 1011 1111
        db #7F, KEY_SPACE, KEY_SSHIFT, KEY_M, KEY_N, KEY_B   ; port 0111 1111
        db #00

        endmodule
