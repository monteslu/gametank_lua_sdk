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
.export   _gt_nmi_hook

.PC02                             ; W65C02 assembly mode

.segment  "BSS"
_gt_nmi_hook: .res 2              ; 0 = none; else called once per vblank
                                  ; (the audio sequencer's wall clock - the
                                  ; installee must save every zp/reg it uses)

.segment  "CODE"

_nmi_int:
        PHA
        LDA $1FFF
        BNE nmi_done
        STZ _gt_frameflag
        INC _gt_ticks
        BNE :+
        INC _gt_ticks+1
:       LDA _gt_nmi_hook+1
        BEQ nmi_done
        PHX
        PHY
        JSR hook_call
        PLY
        PLX
nmi_done:
        PLA
        RTI
hook_call:
        JMP (_gt_nmi_hook)
