; gt_fixed_asm.s — hand-tuned 65C02 implementations of the 16.16 hot ops.
;
; Drop-in replacements for the cc65-compiled gt_fmul / gt_fdiv in gt_fixed.c
; (those C definitions are #ifdef'd out when GT_FIXED_ASM is set). Same
; symbols, same cc65 cdecl ABI, so every existing call site links unchanged.
; PICO-8 semantics are preserved bit-for-bit (mathcheck's RAM-verified cases
; plus a ~1300-vector on-emulator brute test are the gate; the reference model
; those vectors come from is locked by test/fixed_asm.test.js).
;
; cc65 cdecl ABI for `long f(long a, long b)`:
;   entry:  b is in EAX  (A=b.0 lo, X=b.1, sreg=b.2, sreg+1=b.3 hi)
;           a is on the C stack: (c_sp),0..3 = a.0..a.3
;   exit:   return long in EAX (A=lo .. sreg+1=hi); the callee pops a (incsp4)
;
; Both routines are TABLELESS (no lookup tables) so they add no RODATA to the
; already-tight fixed bank — the six real ports keep fitting.
;
; gt_fmul:  res = neg( ( |a| * |b| ) >> 16 ), truncated to 32 bits.
;           (Proven bit-equal to gt_fixed.c's four-partial-product form.)
;           Unsigned 32x32 -> 64 shift-add long multiply (shift-right variant:
;           the 4-byte multiplier and 4-byte running product share one 8-byte
;           register, shifted right 32 times; the multiplicand is added to the
;           top on each 1 bit). Result = bytes 2..5 of the 64-bit product.
;
; gt_fdiv:  q = neg( floor( (|a| << 16) / |b| ) ), truncated to 32 bits.
;           /0 saturates: a<0 -> $80000001, else $7FFFFFFF (P8 manual).
;           Restoring long division: 48 shift-subtract steps over a 48-bit
;           dividend (|a| in the top 32 bits, 16 zero bits below) / 32-bit |b|.

        .setcpu "65C02"
        .export _gt_fmul
        .export _gt_fdiv
        .importzp c_sp, sreg
        .import   incsp4

; ---------------------------------------------------------------------------
; zero-page scratch (leaf routines; linker allocates after the cc65 runtime zp)
; ---------------------------------------------------------------------------
        .segment "ZEROPAGE" : zeropage
aa:     .res 4          ; |a| magnitude (aa+0 = lo)  — fmul multiplicand / div dividend
bb:     .res 4          ; |b| magnitude              — fmul multiplier   / div divisor
pr:     .res 8          ; 64-bit product (fmul): pr[0..3]=multiplier, pr[4..7]=accum
mneg:   .res 1          ; result sign (1 = negate result)
rem:    .res 4          ; division remainder
qq:     .res 4          ; division quotient
dtmp:   .res 4          ; trial-subtract scratch (division)

        .segment "CODE"

; ===========================================================================
; long gt_fmul (long a, long b)
; ===========================================================================
.proc _gt_fmul
        jsr     load_args_sign  ; aa=|a|, bb=|b|, mneg set; a popped

        ; --- 64-bit shift-add multiply: pr = aa * bb ---
        ; pr[0..3] = multiplier (bb); pr[4..7] = 0 (running high product)
        lda     bb+0
        sta     pr+0
        lda     bb+1
        sta     pr+1
        lda     bb+2
        sta     pr+2
        lda     bb+3
        sta     pr+3
        stz     pr+4
        stz     pr+5
        stz     pr+6
        stz     pr+7

        ldx     #32
@mloop:
        ; test the current multiplier bit (pr bit0); if 1, add the multiplicand
        ; into the top 32 bits BEFORE shifting. C ends up = the carry-out of the
        ; add, which the following ror chain folds into bit63 (correct: the add
        ; is at weight 2^32 and a carry out is weight 2^64, i.e. bit63 after the
        ; >>1). When bit0 is 0 we clear C so the top shifts in a 0.
        lda     pr+0
        lsr     a               ; C = pr bit0 (the multiplier bit)
        bcc     @noadd
        clc
        lda     pr+4
        adc     aa+0
        sta     pr+4
        lda     pr+5
        adc     aa+1
        sta     pr+5
        lda     pr+6
        adc     aa+2
        sta     pr+6
        lda     pr+7
        adc     aa+3
        sta     pr+7            ; C = carry-out of the high add
        bra     @shift
@noadd:
        clc                     ; no add: shift a 0 into the top
@shift:
        ; 64-bit logical shift right, bringing C into bit63
        ror     pr+7
        ror     pr+6
        ror     pr+5
        ror     pr+4
        ror     pr+3
        ror     pr+2
        ror     pr+1
        ror     pr+0
        dex
        bne     @mloop

        ; pr+0..7 now holds the full 64-bit product; result = product >> 16.
        lda     pr+2            ; lo
        ldx     pr+3
        ldy     pr+4
        sty     sreg
        ldy     pr+5
        sty     sreg+1

        ldy     mneg
        beq     @done
        jmp     negeax
@done:
        rts
.endproc

; ===========================================================================
; long gt_fdiv (long a, long b)
; ===========================================================================
.proc _gt_fdiv
        ; stash b into bb and a into aa WITHOUT sign-normalizing yet (need the
        ; raw divisor to test for zero, and dividend sign for the saturation).
        sta     bb+0
        stx     bb+1
        lda     sreg
        sta     bb+2
        lda     sreg+1
        sta     bb+3
        ldy     #0
        lda     (c_sp),y
        sta     aa+0
        iny
        lda     (c_sp),y
        sta     aa+1
        iny
        lda     (c_sp),y
        sta     aa+2
        iny
        lda     (c_sp),y
        sta     aa+3
        jsr     incsp4

        ; --- divide by zero? (bb == 0) -> saturate by sign of a ---
        lda     bb+0
        ora     bb+1
        ora     bb+2
        ora     bb+3
        bne     @nonzero
        bit     aa+3            ; a<0 -> $80000001, else $7FFFFFFF
        bpl     @sat_pos
        lda     #$00
        sta     sreg
        lda     #$80
        sta     sreg+1
        ldx     #$00
        lda     #$01
        rts
@sat_pos:
        lda     #$FF
        sta     sreg
        lda     #$7F
        sta     sreg+1
        ldx     #$FF
        lda     #$FF
        rts

@nonzero:
        ; --- sign + magnitudes ---
        stz     mneg
        bit     aa+3
        bpl     @a_pos
        inc     mneg
        jsr     neg_aa
@a_pos:
        bit     bb+3
        bpl     @b_pos
        lda     mneg
        eor     #1
        sta     mneg
        jsr     neg_bb
@b_pos:
        ; --- restoring division: dividend = |a| << 16 (48-bit), divisor |b|.
        ; Feed 48 dividend bits MSB-first: the top 32 are |a| (shifted out of aa
        ; left), the low 16 are 0. Remainder rem (32-bit) accumulates; quotient
        ; qq (32-bit) collects; low 32 quotient bits are the result.
        stz     rem+0
        stz     rem+1
        stz     rem+2
        stz     rem+3
        stz     qq+0
        stz     qq+1
        stz     qq+2
        stz     qq+3

        ldx     #48
@dloop:
        ; next dividend bit = MSB of aa (0 once aa is exhausted after 32 shifts)
        asl     aa+0
        rol     aa+1
        rol     aa+2
        rol     aa+3            ; C = old bit31 of aa = the dividend bit
        ; rem = (rem << 1) | C
        rol     rem+0
        rol     rem+1
        rol     rem+2
        rol     rem+3
        ; qq <<= 1
        asl     qq+0
        rol     qq+1
        rol     qq+2
        rol     qq+3
        ; trial rem - bb
        lda     rem+0
        sec
        sbc     bb+0
        sta     dtmp+0
        lda     rem+1
        sbc     bb+1
        sta     dtmp+1
        lda     rem+2
        sbc     bb+2
        sta     dtmp+2
        lda     rem+3
        sbc     bb+3
        bcc     @norestore      ; rem < bb -> keep remainder, q bit stays 0
        ; commit difference back to rem, set quotient bit 0
        sta     rem+3
        lda     dtmp+2
        sta     rem+2
        lda     dtmp+1
        sta     rem+1
        lda     dtmp+0
        sta     rem+0
        inc     qq+0            ; bit0 is 0 after the asl above
@norestore:
        dex
        bne     @dloop

        lda     qq+2
        sta     sreg
        lda     qq+3
        sta     sreg+1
        lda     qq+0
        ldx     qq+1

        ldy     mneg
        beq     @dived
        jmp     negeax
@dived:
        rts
.endproc

; ===========================================================================
; helpers
; ===========================================================================

; load_args_sign: stash b (EAX) into bb, pull a off the C stack into aa, pop a,
; then normalize both to magnitudes and set mneg = (a<0) ^ (b<0).
.proc load_args_sign
        sta     bb+0
        stx     bb+1
        lda     sreg
        sta     bb+2
        lda     sreg+1
        sta     bb+3
        ldy     #0
        lda     (c_sp),y
        sta     aa+0
        iny
        lda     (c_sp),y
        sta     aa+1
        iny
        lda     (c_sp),y
        sta     aa+2
        iny
        lda     (c_sp),y
        sta     aa+3
        jsr     incsp4

        stz     mneg
        bit     aa+3
        bpl     @a_pos
        inc     mneg
        jsr     neg_aa
@a_pos:
        bit     bb+3
        bpl     @b_pos
        lda     mneg
        eor     #1
        sta     mneg
        jsr     neg_bb
@b_pos:
        rts
.endproc

; neg_aa / neg_bb: 32-bit two's-complement negate in place.
.proc neg_aa
        sec
        lda     #0
        sbc     aa+0
        sta     aa+0
        lda     #0
        sbc     aa+1
        sta     aa+1
        lda     #0
        sbc     aa+2
        sta     aa+2
        lda     #0
        sbc     aa+3
        sta     aa+3
        rts
.endproc

.proc neg_bb
        sec
        lda     #0
        sbc     bb+0
        sta     bb+0
        lda     #0
        sbc     bb+1
        sta     bb+1
        lda     #0
        sbc     bb+2
        sta     bb+2
        lda     #0
        sbc     bb+3
        sta     bb+3
        rts
.endproc

; negeax: negate the 32-bit value in EAX (A/X/sreg/sreg+1), return in EAX.
.proc negeax
        clc
        eor     #$FF
        adc     #1
        pha                     ; new A (lo)
        txa
        eor     #$FF
        adc     #0
        tax                     ; new X
        lda     sreg
        eor     #$FF
        adc     #0
        sta     sreg
        lda     sreg+1
        eor     #$FF
        adc     #0
        sta     sreg+1
        pla                     ; restore A (lo)
        rts
.endproc
