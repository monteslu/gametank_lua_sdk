; ---------------------------------------------------------------------------
; gt_sspr_z - integer PIXEL EXPANSION scaler, direct to the framebuffer.
;
; This is NOT general nearest-neighbor (no per-pixel divide): at an integer
; scale S the map degenerates to "blow each source pixel up into an SxS square".
; So the kernel writes each source byte into an SxS block of VRAM - one `lda`
; per source pixel, S*S unrolled stores, no addressing math in the loop. A
; transparent source pixel (color 0, the colorkey) is simply skipped, so the
; background shows through on all S rows for free.
;
; The caller (gt_sspr) has already entered CPU mode (poke-VRAM), clamped the
; sprite fully on-screen, and set the zp contract. VRAM is $4000, rows 128
; apart: pixel (x,y) = $4000 | (y<<7) | x.
;
; zp contract:
;   sp_src (16) = source top-left  = gt_gsheet_ptr + sy*128 + sx
;   sp_dst (16) = dest VRAM top-left = $4000 + dy*128 + dx
;   sp_sw  (u8) = source width  (1..64)
;   sp_sh  (u8) = source height (1..64)
;   sp_s   (u8) = scale 2..4   (scale 1 goes through the blitter, not here)
; Clobbers A/X/Y.
; ---------------------------------------------------------------------------
.export _gt_sspr_z
.exportzp _sp_src, _sp_dst, _sp_sw, _sp_sh, _sp_s
.PC02

.segment "ZEROPAGE" : zeropage
_sp_src:  .res 2
_sp_dst:  .res 2
_sp_sw:   .res 1
_sp_sh:   .res 1
_sp_s:    .res 1
sp_sp:    .res 2               ; running source row pointer
sp_r0:    .res 2               ; dest VRAM row 0 of the current S-row band
sp_r1:    .res 2               ; row 1 (+128)
sp_r2:    .res 2               ; row 2 (+256)   (used for S>=3)
sp_r3:    .res 2               ; row 3 (+384)   (used for S==4)
sp_rem:   .res 1               ; source rows remaining
sp_x:     .res 1               ; dest x within the band (col*S), advanced per src px

; MUST live in the FIXED (always-mapped) CODE segment, not a banked one: the C
; caller maps bank 2 (the sheet) at $8000 before calling this so the source read
; works, and a banked kernel body would be unmapped by that switch.
.segment "CODE"

_gt_sspr_z:
        lda     _sp_src
        sta     sp_sp
        lda     _sp_src+1
        sta     sp_sp+1
        ; r0 = sp_dst
        lda     _sp_dst
        sta     sp_r0
        lda     _sp_dst+1
        sta     sp_r0+1
        lda     _sp_sh
        sta     sp_rem
        lda     _sp_s
        cmp     #2
        beq     band2
        cmp     #3
        beq     band3
        jmp     band4

; ===========================================================================
; SCALE 2 : each source pixel -> a 2x2 block over rows r0,r1
; ===========================================================================
band2:
        ; r1 = r0 + 128
        clc
        lda     sp_r0
        adc     #128
        sta     sp_r1
        lda     sp_r0+1
        adc     #0
        sta     sp_r1+1
        lda     #0
        sta     sp_x                 ; dest x = 0
        ldy     #0                   ; source x
        ldx     _sp_sw
@px2:
        lda     (sp_sp),y
        beq     @skip2               ; transparent
        phy                          ; save source index
        ldy     sp_x                 ; dest x = col*2
        sta     (sp_r0),y            ; r0[x]
        sta     (sp_r1),y            ; r1[x]
        iny
        sta     (sp_r0),y            ; r0[x+1]
        sta     (sp_r1),y            ; r1[x+1]
        ply                          ; restore source index
@skip2:
        clc                          ; dest x += 2
        lda     sp_x
        adc     #2
        sta     sp_x
        iny                          ; source x += 1
        dex
        bne     @px2
        ; next source row: sp += 128 ; r0 += 256 (2 rows)
        jsr     next_src
        clc
        lda     sp_r0+1
        adc     #1                   ; +256
        sta     sp_r0+1
        dec     sp_rem
        bne     band2
        rts

; ===========================================================================
; SCALE 3
; ===========================================================================
band3:
        clc
        lda     sp_r0
        adc     #128
        sta     sp_r1
        lda     sp_r0+1
        adc     #0
        sta     sp_r1+1
        lda     sp_r0                ; r2 = r0 + 256
        sta     sp_r2
        lda     sp_r0+1
        clc
        adc     #1
        sta     sp_r2+1
        lda     #0
        sta     sp_x
        ldy     #0
        ldx     _sp_sw
@px3:
        lda     (sp_sp),y
        beq     @skip3
        phy
        ldy     sp_x
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        iny
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        iny
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        ply
@skip3:
        clc
        lda     sp_x
        adc     #3
        sta     sp_x
        iny
        dex
        bne     @px3
        jsr     next_src
        clc                          ; r0 += 384
        lda     sp_r0
        adc     #128
        sta     sp_r0
        lda     sp_r0+1
        adc     #1
        sta     sp_r0+1
        dec     sp_rem
        bne     band3
        rts

; ===========================================================================
; SCALE 4
; ===========================================================================
band4:
        clc
        lda     sp_r0
        adc     #128
        sta     sp_r1
        lda     sp_r0+1
        adc     #0
        sta     sp_r1+1
        lda     sp_r0                ; r2 = r0+256
        sta     sp_r2
        lda     sp_r0+1
        clc
        adc     #1
        sta     sp_r2+1
        lda     sp_r0                ; r3 = r0+384
        clc
        adc     #128
        sta     sp_r3
        lda     sp_r0+1
        adc     #1
        sta     sp_r3+1
        lda     #0
        sta     sp_x
        ldy     #0
        ldx     _sp_sw
@px4:
        lda     (sp_sp),y
        beq     @skip4
        phy
        ldy     sp_x
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        sta     (sp_r3),y
        iny
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        sta     (sp_r3),y
        iny
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        sta     (sp_r3),y
        iny
        sta     (sp_r0),y
        sta     (sp_r1),y
        sta     (sp_r2),y
        sta     (sp_r3),y
        ply
@skip4:
        clc
        lda     sp_x
        adc     #4
        sta     sp_x
        iny
        dex
        bne     @px4
        jsr     next_src
        clc                          ; r0 += 512
        lda     sp_r0+1
        adc     #2
        sta     sp_r0+1
        dec     sp_rem
        bne     band4
        rts

; advance source row pointer by one source row (+128)
next_src:
        clc
        lda     sp_sp
        adc     #128
        sta     sp_sp
        lda     sp_sp+1
        adc     #0
        sta     sp_sp+1
        rts
