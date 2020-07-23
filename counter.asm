
        device zxspectrum48
        org $8000

start:
        ld b,0
        ld c,0
        ld de,counter
        call @print_string
        ld hl,counter + 8
loop:
        ld a,(hl)
        cp "9"
        jr nz,increment
        ld (hl),"0"
        dec hl
        jr loop
increment:
        inc a
        ld (hl),a
        jr start

counter:
        db "000000000",0

        include "./lib/screen.asm"

        savesna "./output/counter.sna",start
        savetap "./output/counter.tap",start

        end
