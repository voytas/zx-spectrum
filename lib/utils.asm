    module Utils
;
; Simple delay routine. Runs a loop until DE reaches zero.
;
; Input:
;   DE - the delay
; Modifies:
;   A & DE (both will be zero on return)
@delay:
        dec de              ; decrement counter
        ld a,d
        or e                ; A = D | E
        jr nz,delay         ; if A is not zero, continue
        ret

        endmodule