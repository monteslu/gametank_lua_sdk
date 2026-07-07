; ---------------------------------------------------------------------------
; gt_print_z — the blit-font glyph loop in 65C02.
;
; The C loop cost ~550 cycles per glyph (staging + push + cc65 body); this
; is ~160: glyph lookup via a 128-byte table, ring entries staged in place,
; one drain-check per glyph. HUD text is 15-25 glyphs on every cart, every
; frame.
;
; Contract (zp arg slots, no marshalling):
;   gt_a0        = str pointer (current position)
;   gt_a1        = x (int, updated on return)
;   gt_a2 lo     = y (already validated 0..123 by the C caller)
;   gt_a3 lo     = rowbase (font_slot * 10)
;   gt_a4 lo     = entry+7 byte (bankflip | FONT_GROUP | clips)
; Processes glyphs while *str != 0 AND 0 <= x <= 125. Returns with gt_a0/
; gt_a1 advanced; the C caller handles the leading x<0 part, the clipped
; tail, and the no-blitfont path.
; ---------------------------------------------------------------------------
.export _gt_print_z
.importzp _gt_a0, _gt_a1, _gt_a2, _gt_a3, _gt_a4
.import _gt_q, _gt_qhead, _gt_qtail, _gt_q_pump
.PC02

QF_SPR = $55

.segment "RODATA"
; ASCII 0-127 -> glyph number (matches gt_glyph(): digits 0-9, letters
; 10-35, space 36, ! 37, - 38, : 39, . 40, / 41; everything else space)
glyphmap:
        .repeat 33
        .byte 36
        .endrepeat               ; 0-32 control+space -> 36
        .byte 37                 ; 33 '!'
        .repeat 11
        .byte 36
        .endrepeat               ; 34-44
        .byte 38                 ; 45 '-'
        .byte 40                 ; 46 '.'
        .byte 41                 ; 47 '/'
        .byte 0,1,2,3,4,5,6,7,8,9 ; 48-57 digits
        .byte 39                 ; 58 ':'
        .repeat 6
        .byte 36
        .endrepeat               ; 59-64
        .byte 10,11,12,13,14,15,16,17,18,19,20,21,22
        .byte 23,24,25,26,27,28,29,30,31,32,33,34,35   ; 65-90 A-Z
        .repeat 6
        .byte 36
        .endrepeat               ; 91-96
        .byte 10,11,12,13,14,15,16,17,18,19,20,21,22
        .byte 23,24,25,26,27,28,29,30,31,32,33,34,35   ; 97-122 a-z
        .repeat 5
        .byte 36
        .endrepeat               ; 123-127

; rowoff[gn >> 5] = (gn / 32) * 5
rowoff: .byte 0, 5, 10

.segment "CODE"

.proc _gt_print_z
loop:   lda     _gt_a1+1        ; x high: any nonzero means x < 0 or > 255
        bne     done
        lda     _gt_a1
        cmp     #126
        bcs     done            ; x > 125
        lda     (_gt_a0)        ; next char (65C02 (zp) mode)
        beq     done
        bpl     ok
        lda     #' '            ; bytes >= 128 print as space
ok:     tay
        lda     glyphmap,y
        tay                     ; Y = glyph number
        ; ---- claim a ring slot ----
slot:   lda     _gt_qhead
        clc
        adc     #8
        cmp     _gt_qtail
        bne     free
        jsr     _gt_q_pump
        bra     slot
free:   ldx     _gt_qhead
        lda     #QF_SPR
        sta     _gt_q+0,x
        lda     _gt_a1
        sta     _gt_q+1,x       ; VX
        lda     _gt_a2
        sta     _gt_q+2,x       ; VY
        tya
        and     #31
        asl     a
        asl     a
        sta     _gt_q+3,x       ; GX = (gn & 31) * 4
        tya
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        phy
        tay
        lda     rowoff,y
        ply
        clc
        adc     _gt_a3
        sta     _gt_q+4,x       ; GY = rowbase + (gn>>5)*5
        lda     #3
        sta     _gt_q+5,x       ; W
        lda     #5
        sta     _gt_q+6,x       ; H
        lda     _gt_a4
        sta     _gt_q+7,x       ; flags byte (bank | FONT_GROUP | clips)
        txa
        clc
        adc     #8
        sta     _gt_qhead
        jsr     _gt_q_pump
        ; ---- advance: str++, x += 4 ----
        inc     _gt_a0
        bne     :+
        inc     _gt_a0+1
:       lda     _gt_a1
        clc
        adc     #4
        sta     _gt_a1
        bcc     loop
        inc     _gt_a1+1
        bra     loop
done:   rts
.endproc
