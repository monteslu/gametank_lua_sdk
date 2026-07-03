; ---------------------------------------------------------------------------
; GameTank NMI handler. (The IRQ handler lives in gt_blitq.s now: blit
; completion chains the async blit queue.)
; Modeled on clydeshaffer/gametank_sdk src/gt/interrupt.s (MIT).
;
; NMI  = vblank: release the vsync spin (gt_frameflag) and bump the tick
;        counter. $1FFF is the boot guard the startup code zeroes.
; ---------------------------------------------------------------------------
.import   _gt_frameflag
.import   _gt_ticks
.export   _nmi_int

.PC02                             ; W65C02 assembly mode

.segment  "CODE"

_nmi_int:
        PHA
        LDA $1FFF
        BNE nmi_done
        STZ _gt_frameflag
        INC _gt_ticks
        BNE nmi_done
        INC _gt_ticks+1
nmi_done:
        PLA
        RTI
