; ---------------------------------------------------------------------------
; gt_blitq.s — the async blit queue + the zero-page fastcall ABI.
;
; WHY (measured, SPEED_PLAN.md): the old runtime spin-waited on the blitter
; and re-programmed modes inside EVERY primitive call — spr() cost 932
; cycles, rectfill() 1,864, before drawing a pixel. Here a primitive just
; appends an 8-byte descriptor and returns; the blit-complete IRQ programs
; the next descriptor the moment the previous blit finishes. Drawing
; overlaps game logic completely; the CPU cost of a blit is the enqueue.
;
; Queue entry (8 bytes, X-indexed so the 8-bit index wraps the 256-byte
; ring for free):
;   +0 dma_flags byte for this blit (RECT: colorfill+opaque; SPR: gcarry)
;   +1 VX  +2 VY  +3 GX  +4 GY  +5 WIDTH  +6 HEIGHT
;   +7 COLOR (pre-inverted by the producer; ignored by SPR blits)
;
; EMULATOR RULE (the flicker fix, now load-bearing): the emulator
; materializes a finished blit's pixels lazily using the LIVE registers, so
; gt_q_kick touches $4000 with a dummy read BEFORE writing new flags/regs —
; that forces the catch-up under the state the blit actually ran with.
; Harmless on hardware.
;
; The zero-page ABI: the compiler stores builtin args into _gt_a0.._gt_a5
; (sta zp) instead of pushing cc65 stack words, and the runtime reads them
; the same way. Camera and pad state live here too so btn()/camera() emit
; as inline zp ops.
; ---------------------------------------------------------------------------
.import   _gt_draw_busy
.export   _gt_a0, _gt_a1, _gt_a2, _gt_a3, _gt_a4, _gt_a5
.export   _gt_cam_x, _gt_cam_y
.export   _gt_pad0, _gt_pad1, _gt_rpt0, _gt_rpt1
.export   _gt_qhead, _gt_qtail, _gt_qbank
.export   _gt_q
.export   _gt_ent
.export   _gt_q_kick, _gt_q_push, _gt_q_pump
.export   _irq_int

DMA_Flags = $2007
Bank_Reg  = $2005
VDMA_Base = $4000               ; VX $4000 VY $4001 GX $4002 GY $4003
VDMA_W    = $4004
VDMA_H    = $4005
DMA_Start = $4006
VDMA_Col  = $4007

.PC02

.segment "ZEROPAGE" : zeropage

_gt_a0:    .res 2               ; fastcall arg slots (ints)
_gt_a1:    .res 2
_gt_a2:    .res 2
_gt_a3:    .res 2
_gt_a4:    .res 2
_gt_a5:    .res 2
_gt_cam_x: .res 2               ; camera offset (P8 camera())
_gt_cam_y: .res 2
_gt_pad0:  .res 2               ; held-button word, player 0 (btn masks)
_gt_pad1:  .res 2
_gt_rpt0:  .res 2               ; newpress+repeat word (btnp masks)
_gt_rpt1:  .res 2
_gt_qhead: .res 1               ; producer index (multiples of 8)
_gt_qtail: .res 1               ; consumer index (advanced by the pump)
_gt_qbank: .res 1               ; this frame's $2005 byte for blits
_gt_ent:   .res 8               ; entry staging: C fills, gt_q_push commits

.segment "BSS"

_gt_q:     .res 256             ; 32 entries x 8 bytes

.segment "CODE"

; ---------------------------------------------------------------------------
; gt_q_kick: if the queue has an entry, program + start it (does NOT ack).
; Called ONLY from the main thread, under SEI, when the blitter is idle
; (the "pump": every enqueue and the drain loop advance the chain). The IRQ
; handler deliberately does NOT touch the queue or the blitter registers —
; chaining blits from interrupt context while the emulator materializes the
; finished blit lazily proved to be a timing-sensitive crash (runaway after
; a variable number of frames); the pump keeps every VDMA access on the
; main thread, the pattern the runtime always used. Clobbers A,X. When the
; queue is empty, the blitter is done working: clear _gt_draw_busy.
; ---------------------------------------------------------------------------
_gt_q_kick:
        LDA VDMA_Base           ; dummy read: force emulator catch-up FIRST
        LDX _gt_qtail
        CPX _gt_qhead
        BEQ @empty
        LDA _gt_q+0,x           ; per-blit dma flags
        STA DMA_Flags
        LDA _gt_qbank
        STA Bank_Reg
        LDA _gt_q+1,x
        STA VDMA_Base
        LDA _gt_q+2,x
        STA VDMA_Base+1
        LDA _gt_q+3,x
        STA VDMA_Base+2
        LDA _gt_q+4,x
        STA VDMA_Base+3
        LDA _gt_q+5,x
        STA VDMA_W
        LDA _gt_q+6,x
        STA VDMA_H
        LDA _gt_q+7,x
        STA VDMA_Col
        LDA #1
        STA DMA_Start           ; kick
        TXA
        CLC
        ADC #8
        STA _gt_qtail
        RTS
@empty:
        STZ _gt_draw_busy
        RTS

; ---------------------------------------------------------------------------
; gt_q_push: commit the staged entry (_gt_ent) into the ring and pump.
; The producer fast path: callers do 8 zp stores + JSR — no C-stack args.
; If the ring is full, pump until the blitter frees a slot (never a blind
; spin). Clobbers A,X.
; ---------------------------------------------------------------------------
_gt_q_push:
@full:  LDA _gt_qhead
        CLC
        ADC #8
        CMP _gt_qtail
        BNE @room
        JSR _gt_q_pump          ; ring full: advance the chain, retry
        BRA @full
@room:  LDX _gt_qhead
        LDA _gt_ent+0
        STA _gt_q+0,x
        LDA _gt_ent+1
        STA _gt_q+1,x
        LDA _gt_ent+2
        STA _gt_q+2,x
        LDA _gt_ent+3
        STA _gt_q+3,x
        LDA _gt_ent+4
        STA _gt_q+4,x
        LDA _gt_ent+5
        STA _gt_q+5,x
        LDA _gt_ent+6
        STA _gt_q+6,x
        LDA _gt_ent+7
        STA _gt_q+7,x
        TXA
        CLC
        ADC #8
        STA _gt_qhead
        ; FALLS THROUGH into the pump

; ---------------------------------------------------------------------------
; gt_q_pump: if the blitter is idle and work is queued, start the next blit.
; The ONLY place blits start. Interrupt-state preserved (php/sei/plp) so it
; is safe from any context; the completion IRQ only clears _gt_draw_busy.
; Clobbers A,X.
; ---------------------------------------------------------------------------
_gt_q_pump:
        PHP
        SEI
        LDA _gt_draw_busy
        BNE @out
        LDA _gt_qtail
        CMP _gt_qhead
        BEQ @out
        INC _gt_draw_busy       ; 0 -> 1
        JSR _gt_q_kick
@out:   PLP
        RTS

; ---------------------------------------------------------------------------
; IRQ = blit complete: acknowledge and mark the blitter idle. Nothing else —
; the main-thread pump advances the queue. STZ touches no registers, so
; nothing needs saving (the proven pre-queue handler shape).
; ---------------------------------------------------------------------------
_irq_int:
        STZ DMA_Start           ; acknowledge the DMA interrupt
        STZ _gt_draw_busy
        RTI
