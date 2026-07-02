/* gt_math.c — PICO-8 math library on 16.16 fixed point:
 * turns-based trig (256-step ROM table, screen-space-inverted sin),
 * xorshift rnd/srand, and t()/time() as an exact 1/60s accumulator. */
#include "gt_fixed.h"
#include "gt_sintab.h"

long gt_fsin(long turns) {
    /* index = top 8 bits of the turn fraction */
    return gt_sintab[(unsigned char)(((unsigned long)turns >> 8) & 0xFF)];
}

long gt_fcos(long turns) {
    /* cos(x) = -p8sin(x + 0.25) */
    return -gt_sintab[(unsigned char)((((unsigned long)turns + 0x4000UL) >> 8) & 0xFF)];
}

long gt_fatan2(long dx, long dy) {
    /* PICO-8 convention: angle in turns [0,1), consistent with the inverted
     * sin — anchors: atan2(1,0)=0, atan2(0,-1)=0.25, atan2(-1,0)=0.5,
     * atan2(0,1)=0.75, atan2(1,1)=0.875, atan2(0,0)=0.75.
     * Equivalent to math-space atan2(-dy, dx)/2pi normalized to [0,1).
     * First-octant arctan via the classic approximation
     *   atan(r) ~ r*(pi/4 + 0.273*(1-r))  ->  turns: r*(0.125+0.04345*(1-r))
     * (max error ~0.0006 turns), quadrant-folded. */
    unsigned char swap = 0, mirror = 0, negate = 0;
    long mx = dx, my = -dy;          /* screen space -> math space */
    long ax, ay, r, a;
    if (dx == 0 && dy == 0) return 0xC000L;
    if (mx < 0) { mirror = 1; ax = -mx; } else ax = mx;
    if (my < 0) { negate = 1; ay = -my; } else ay = my;
    if (ay > ax) { swap = 1; r = gt_fdiv(ax, ay); }
    else         {           r = gt_fdiv(ay, ax); }
    a = gt_fmul(r, 0x2000L + gt_fmul(0x0B20L, 0x10000L - r));
    if (swap) a = 0x4000L - a;
    if (mirror) a = 0x8000L - a;
    if (negate) a = -a;
    return a & 0xFFFFL;
}

/* ---- rnd / srand: 32-bit xorshift ---- */
static unsigned long gt_rng = 0x1234ABCDUL;

long gt_p8_rnd(long x) {
    unsigned long s = gt_rng;
    long frac;
    s ^= s << 13;
    s ^= s >> 17;
    s ^= s << 5;
    gt_rng = s;
    if (x <= 0) return 0;
    /* fraction in [0,1) from 16 random bits, scaled: rnd(x) = frac * x */
    frac = (long)(s & 0xFFFFUL);
    return gt_fmul(frac, x);
}

void gt_p8_srand(long seed) {
    gt_rng = (unsigned long)seed;
    if (gt_rng == 0) gt_rng = 0x1234ABCDUL;
}

/* ---- t()/time(): seconds since boot, advanced by gt_endframe ---- */
long gt_time_acc = 0;
static unsigned char gt_time_rem = 0;

void gt_time_tick(void) {
    /* 1/60 s in 16.16 = 1092 + 16/60 exactly */
    gt_time_acc += 1092L;
    gt_time_rem += 16;
    if (gt_time_rem >= 60) { gt_time_rem -= 60; gt_time_acc += 1; }
}

long gt_p8_time(void) { return gt_time_acc; }
