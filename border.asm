            sldopt COMMENT WPMEM, LOGPOINT, ASSERTION
            device zxspectrum48


IM2_TABLE   equ $fe00               // location of the IM2 table (257 bytes)
IM2_JP      equ $fd                 // jump location high and low byte

            org $8000
start:
            di                      // disable interrupts
            ld sp,0
            ld a,high IM2_TABLE
            ld i,a                  // load high address of the jump table location
            im 2                    // set interrupt to mode 2
            ei                      // enable interrupts
main:
            jr main                 // and do nothing, wait for interrupts
handler:
            di
            push af
            push bc
            push de
            push hl

            ld hl,counter
            ld a,(hl)
            inc a
            out (254),a
            ld (hl),a

            pop hl
            pop de
            pop bc
            pop af
            ei
            ret
counter:
            db 0

// interrupt callback
            org IM2_JP | IM2_JP << 8
            jp handler

// interrupt jump table of 257 bytes of the same value
            org IM2_TABLE
    .257    db IM2_JP

// generate snapshot file
            savesna "./output/border.sna", start