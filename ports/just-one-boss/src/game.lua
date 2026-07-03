-- just one boss — gametank port
-- Hand-translated from "Just One Boss" by bridgs (ayla nonsense)
-- (lexaloffle.com/bbs/?tid=30767), original licensed CC-BY-NC-SA 4.0.
-- This adaptation (real game logic, real sprite sheet, transcribed
-- tracker music) is released under the same license: CC-BY-NC-SA 4.0 —
-- see LICENSE in this directory. Every divergence from the original
-- cart is listed in PORT_NOTES.md.
--
-- d-pad: hop tile to tile. Step on the sparkling tiles to fill the
-- boss bar; dodge cards, coins, lasers and flowers. ➡️ advances menus
-- (🅾️/GT A works too).
--
-- Build:  node ports/just-one-boss/tools/mkgfx.mjs
--         node ports/just-one-boss/tools/mkmusic.mjs
--         node ports/just-one-boss/tools/assemble.mjs
--         node bin/gtlua.js build ports/just-one-boss/main.lua \
--           --sheet ports/just-one-boss/sheet.bin
--
-- Architecture note: the original is built on closures, per-entity
-- method tables and a promise/timeline library. gtlua has none of
-- those (by design), so this port re-expresses every promise chain as
-- flat (action, step, wait) state machines: one rotation machine per
-- mirror, one sub-action machine per mirror, one machine per hand,
-- plus standalone machines for the intro/victory/death cinematics.
-- Frame counts and easings are copied from the cart, so the fight's
-- timing matches the original at 30 fps.

-- ======================================================================
-- constants
-- ======================================================================

local E_LIN = 0
local E_IN = 1
local E_OUT = 2
local E_OUTIN = 3

-- actor indices (parallel arrays)
local BB = 1   -- boss (magic mirror)
local LH = 2
local RH = 3
local GB = 4   -- boss reflection (green mirror)
local GLH = 5
local GRH = 6

-- rotation-machine actions (index 1 = boss, 2 = green mirror)
local R_NONE = 0
local R_P1 = 1
local R_P23 = 2
local R_P4 = 3
local R_REEL = 4
local R_INTRO = 5
local R_CHG1 = 6
local R_CHG2 = 7
local R_CHG3 = 8
-- green-mirror schedule actions
local R_GCONJ = 20
local R_GCARDS = 21
local R_GLASERS = 22
local R_GCOINS = 23

-- sub-action machine
local S_NONE = 0
local S_READY = 1
local S_CONJ = 2
local S_LASERS = 3
local S_COINS = 4
local S_CARDS = 5
local S_CARDS_L = 6
local S_CARDS_R = 7
local S_DESPAWN = 8
local S_REEL = 9
local S_POUND = 10
local S_CAST = 11

-- hand machine
local H_NONE = 0
local H_CARDS = 1
local H_POUND = 2
local H_TEMPLE = 3
local H_FLOURISH = 4
local H_CASTR = 5

-- ======================================================================
-- global state
-- ======================================================================

local scene_frame = 0
local freeze_frames = 0
local shake_frames = 0
local is_paused = 0
local timer_seconds = 0
local rainbow_color = 8    -- p8 colour
local rainbow_idx = 0      -- 0..5 (for baked tile shimmer)

local score = 0
local score_mult = 0
local boss_phase = 0
local best_score = 0
local best_time = 0
local new_best_score = 0
local new_best_time = 0

local conjure_counter = 1
local game_on = 0          -- gameplay entities exist

-- player -------------------------------------------------------------
local palive = 0
local px = 45
local py = 20
local pvx = 0
local pvy = 0
local pfacing = 0
local pstep_dir = 4        -- 4 = none
local pnext_dir = 4
local pstep_frames = 0
local pteeter = 0
local pbump = 0            -- original default_counter (bump anim)
local pstun = 0
local pinvinc = 0
local pprev_col = 0
local pprev_row = 0
local pfa = 0              -- frames alive (teeter flash)

-- player reflection --------------------------------------------------
local ref_on = 0
local rprev_col = 0
local rprev_row = 0

-- player health UI (a sliding entity in the original) -----------------
local ph_hearts = 4
local ph_x = 63.0
local ph_y = 122
local ph_anim = 0          -- 0 none, 1 lose, 2 gain
local ph_dc = 0
local ph_vis = 0
local ph_slide = 0         -- -1/1 sliding off, 0 none
local ph_sf = 0            -- slide frame
local ph_sx = 0.0          -- slide origin
local ph_move = 0          -- death drift to centre
local ph_mf = 0

-- boss health bar ------------------------------------------------------
local bh_health = 0
local bh_vis = 0
local bh_dc = 0            -- drain counter after a phase fills the bar
local bh_rainbow = 0

-- boss actors ----------------------------------------------------------
local ax = array(6, 0.0)
local ay = array(6, 0.0)
local adox = array(6, 0.0)  -- idle bob draw offsets
local adoy = array(6, 0.0)
local aim = array(6, 0.0)   -- idle mult
local aidle = array(6)
local avis = array(6)
local apose = array(6)
-- movement (cubic bezier + easing)
local mvon = array(6)
local mvf = array(6)
local mvdur = array(6)
local mvez = array(6)
local mx0 = array(6, 0.0)
local my0 = array(6, 0.0)
local mx1 = array(6, 0.0)
local my1 = array(6, 0.0)
local mx2 = array(6, 0.0)
local my2 = array(6, 0.0)
local mx3 = array(6, 0.0)
local my3 = array(6, 0.0)

local boss_on = 0          -- boss entity exists
local green_on = 0         -- boss reflection exists
local bfa = 0              -- boss frames alive (idle bob phase)
local bexpr = 4
local gexpr = 1
local bhat = 0
local ghat = 1
local bdc = 0              -- laser-charge flicker counter
local gdc = 0
local bcracked = 0
local bwand_l = 0
local bwand_r = 0
local bbouq = 0
local bhome_x = 40
local bhome_y = -28
local ghome_x = 20

-- script machines: index 1 = boss, 2 = green mirror
local rA = array(2)
local rS = array(2)
local rW = array(2)
local rN = array(2)
local sA = array(2)
local sS = array(2)
local sW = array(2)
local sN = array(2)
local sCol = array(2)
local sSweep = array(2)
local sCount = array(2)
local sTgt = array(2)
local sXtra = array(2)
local sUpg = array(2)
-- hands (indexed by actor)
local hA = array(6)
local hS = array(6)
local hW = array(6)
local hRow = array(6)
local hFirst = array(6)

-- cinematic machines
local vA = 0               -- victory step (0 = off)
local vW = 0
local dA = 0               -- death step
local dW = 0
local trans_lock = 0       -- a phase transition/cinematic is running

-- start_game staging
local sg_step = 0
local sg_wait = 0
local sg_phase = 0

-- figment (game-over ghost)
local fg_on = 0
local fg_x = 0.0
local fg_y = 0.0
local fg_sx = 0.0
local fg_sy = 0.0
local fg_f = 0
local fg_mf = 0            -- move frames (to screen centre)
local fg_slide = 0
local fg_ssx = 0.0
local fg_fa = 0

-- curtains
local cur_anim = 0         -- 1 = open
local cur_dc = 0
local cur_amount = 62.0

-- screens: 1 title, 2 credit, 3 victory, 4 gameover
local scr_on = array(4)
local scr_x = array(4, 0.0)
local scr_fa = array(4)
local scr_fua = array(4)
local scr_act = array(4)
local scr_slide = array(4)  -- sliding dir (0 none)
local scr_sf = array(4)
local scr_ssx = array(4, 0.0)

-- audio ----------------------------------------------------------------
local mrow = -1            -- music row (-1 = off)
local macc = 0
local mlen = 512
local mc_sfx = array(4)
local mc_step = array(4)
local mc_acc = array(4)
local gs_sfx = array(4)    -- one-shot sfx overlay per channel
local gs_step = array(4)
local gs_acc = array(4)
local ch_note = array(4)   -- last note value sent (0 = off)
local ch_cut = array(4)    -- frames until forced noteoff (drum thump)

-- pools ------------------------------------------------------------------
local cards = pool(12)
local coins = pool(10)
local flowers = pool(64)
local parts = pool(24)
local streaks = pool(12)
local tiles = pool(12)
local poofs = pool(8)
local bunnies = pool(6)
local points = pool(6)
local hearts = pool(2)
local lasers = pool(4)

-- misc scratch
local flowseq = array(40)
local hat_on = 0
local hat_x = 0
local hat_y = 0
local hat_f = 0

-- ======================================================================
-- small helpers
-- ======================================================================

function rnd_int(lo, hi)
  return flr(lo + rnd(1 + hi - lo))
end

function rnd_dir()
  return 2 * rnd_int(0, 1) - 1
end

function freeze_shake(f, s)
  freeze_frames = max(f, freeze_frames)
  shake_frames = max(s, shake_frames)
end

function ease(kind, p)
  if (kind == E_IN) return 1 - (1 - p) * (1 - p)
  if (kind == E_OUT) return p * p
  if kind == E_OUTIN then
    if (p < 0.5) return p * p * 2
    local q = 2 * p - 1
    return (1 + 1 - (1 - q) * (1 - q)) / 2
  end
  return p
end

-- cubic bezier component
function bez(p0, p1, p2, p3, t)
  local u = 1 - t
  return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3
end

-- ======================================================================
-- audio: 4-channel sequencer over gt.note (see PORT_NOTES.md)
-- ======================================================================

function ch_off(ch)
  if ch_note[ch + 1] ~= 0 then
    gt.noteoff(ch)
    ch_note[ch + 1] = 0
  end
end

function ch_play(v, ch)
  if v <= 0 then
    ch_off(ch)
    return
  end
  local midi = v % 128
  local vol = (v \ 128) % 8
  if v >= 1024 then
    -- noise drum -> low sine thump, cut fast
    gt.note(ch, 21 + midi % 12, vol * 10)
    ch_cut[ch + 1] = 2
  else
    gt.note(ch, midi, vol * 16)
    ch_cut[ch + 1] = 0
  end
  ch_note[ch + 1] = v
end

function jb_sfx(id, ch)
  gs_sfx[ch + 1] = id
  gs_step[ch + 1] = -1
  gs_acc[ch + 1] = 0
end

function music_play(row)
  mrow = row
  macc = 0
  mlen = g_rowlen(row)
  local c = 0
  while c < 4 do
    mc_sfx[c + 1] = g_songrow(row, c)
    mc_step[c + 1] = -1
    mc_acc[c + 1] = 0
    c += 1
  end
end

function music_stop()
  mrow = -1
  local c = 0
  while c < 4 do
    mc_sfx[c + 1] = 64
    if (gs_sfx[c + 1] < 0) ch_off(c)
    c += 1
  end
end

function music_next_row()
  local fl = g_rowflag(mrow)
  if fl >= 4 then
    music_stop()
    return
  end
  if fl == 2 or (fl == 3 and mrow > 37) then
    -- loop end: scan back for the loop start
    local r = mrow
    while r > 0 do
      r -= 1
      local f2 = g_rowflag(r)
      if f2 == 1 or f2 == 3 or f2 == 5 then
        music_play(r)
        return
      end
    end
    music_play(0)
    return
  end
  music_play(mrow + 1)
end

function update_audio()
  local c = 0
  -- row master
  if mrow >= 0 then
    macc += 4
    if macc >= mlen then
      music_next_row()
    end
  end
  while c < 4 do
    local i = c + 1
    if ch_cut[i] > 0 then
      ch_cut[i] -= 1
      if (ch_cut[i] == 0) ch_off(c)
    end
    if gs_sfx[i] >= 0 then
      -- one-shot game sfx owns the channel
      local id = gs_sfx[i]
      local spd = g_sfxspeed(id)
      if gs_step[i] < 0 or gs_acc[i] >= spd then
        if (gs_acc[i] >= spd) gs_acc[i] -= spd
        gs_step[i] += 1
        if gs_step[i] >= g_sfxlen(id) then
          gs_sfx[i] = -1
          ch_off(c)
        else
          ch_play(g_sfxnote(id, gs_step[i]), c)
        end
      end
      gs_acc[i] += 4
    elseif mrow >= 0 and mc_sfx[i] < 64 then
      local id = mc_sfx[i]
      local spd = g_sfxspeed(id)
      if mc_step[i] < 0 or mc_acc[i] >= spd then
        if (mc_acc[i] >= spd) mc_acc[i] -= spd
        mc_step[i] += 1
        if mc_step[i] >= 32 then
          local w = g_sfxwrap(id)
          if w > 0 then
            mc_step[i] = w % 256
            ch_play(g_sfxnote(id, mc_step[i]), c)
          else
            mc_sfx[i] = 64
            ch_off(c)
          end
        else
          local ln = g_sfxlen(id)
          if mc_step[i] < ln then
            ch_play(g_sfxnote(id, mc_step[i]), c)
          else
            ch_off(c)
          end
        end
      end
      mc_acc[i] += 4
    end
    c += 1
  end
end

-- ======================================================================
-- actor movement (the original's move()/apply_velocity bezier system)
-- ======================================================================

function mv_to(i, tx, ty, dur, ez, a1x, a1y, a2x, a2y)
  local sx = ax[i]
  local sy = ay[i]
  mx0[i] = sx
  my0[i] = sy
  mx1[i] = sx + a1x
  my1[i] = sy + a1y
  mx2[i] = tx + a2x
  my2[i] = ty + a2y
  mx3[i] = tx
  my3[i] = ty
  mvf[i] = 0
  mvdur[i] = dur
  mvez[i] = ez
  mvon[i] = 1
end

-- default anchors = {dx/4, dy/4, -dx/4, -dy/4}
function mv_to_d(i, tx, ty, dur, ez)
  local dx = tx - ax[i]
  local dy = ty - ay[i]
  mv_to(i, tx, ty, dur, ez, dx / 4, dy / 4, -dx / 4, -dy / 4)
end

function mv_rel(i, dx, dy, dur, ez, a1x, a1y, a2x, a2y)
  mv_to(i, ax[i] + dx, ay[i] + dy, dur, ez, a1x, a1y, a2x, a2y)
end

function mv_rel_d(i, dx, dy, dur, ez)
  mv_to_d(i, ax[i] + dx, ay[i] + dy, dur, ez)
end

function mv_step(i)
  if (mvon[i] == 0) return
  mvf[i] += 1
  if mvf[i] >= mvdur[i] then
    ax[i] = mx3[i]
    ay[i] = my3[i]
    mvon[i] = 0
    return
  end
  local t = ease(mvez[i], mvf[i] / mvdur[i])
  ax[i] = bez(mx0[i], mx1[i], mx2[i], mx3[i], t)
  ay[i] = bez(my0[i], my1[i], my2[i], my3[i], t)
end

function mv_cancel(i)
  mvon[i] = 0
end

-- calc_idle_mult: idle bobbing (n = 2 for mirrors, 4 for hands)
function idle_step(i, f, n)
  local m = aim[i]
  if aidle[i] == 1 then
    m += 0.05
  else
    m -= 0.05
  end
  aim[i] = mid(0, m, 1)
  adox[i] = aim[i] * 3 * sin(f / 64)
  adoy[i] = aim[i] * n * sin(f / 32)
end

-- ======================================================================
-- effects
-- ======================================================================

function spawn_poof(x, y)
  add(poofs, { x = x, y = y, f = 0 })
end

-- poof with sound (the original's entity poof() helper)
function poof_at(x, y, forceful)
  if forceful == 1 then
    jb_sfx(12, 2)
  else
    jb_sfx(11, 2)
  end
  spawn_poof(x, y)
end

function spawn_burst(x, y, dy, num, col, speed)
  local i = 1
  while i <= num do
    local angle = (i + rnd(0.7)) / num
    local ps = speed * (0.5 + rnd(0.7))
    add(parts, {
      x = x, y = y - dy, px = x, py = y - dy,
      vx = ps * cos(angle), vy = ps * sin(angle) - speed / 2,
      fric = 0.75, grav = 0.1, col = col, ftd = rnd_int(13, 19),
    })
    i += 1
  end
end

function spawn_petals(x, y, col)
  local i = 1
  while i <= 2 do
    add(parts, {
      x = x, y = y - 2, px = x, py = y - 2,
      vx = i - 1.5, vy = -1 - rnd(1),
      fric = 0.9, grav = 0.06, col = col, ftd = 10 + flr(rnd(7)),
    })
    i += 1
  end
end

function spawn_pain(x, y)
  -- original entity 28 (baked art cut for sheet space): prim starburst
  add(parts, {
    x = x, y = y - 8, px = x, py = y - 16,
    vx = 0, vy = 0, fric = 1, grav = 0, col = 7, ftd = 3,
  })
end

function update_parts()
  for p in all(parts) do
    p.vy += p.grav
    p.vx *= p.fric
    p.vy *= p.fric
    p.px = p.x
    p.py = p.y
    p.x += p.vx
    p.y += p.vy
    p.ftd -= 1
    if (p.ftd <= 0) del(parts, p)
  end
  for s in all(streaks) do
    if s.dl > 0 then
      s.dl -= 1
      -- keep drifting like a burst particle while waiting
      s.py = s.y
      s.px = s.x
      s.y += s.vy
      s.x += s.vx
      s.vx *= 0.75
      s.vy *= 0.75
      if s.dl == 0 then
        s.sx = s.x
        s.sy = s.y
        s.f = 0
      end
    else
      s.f += 1
      local t = ease(E_OUT, s.f / 8)
      local dx = s.tx - s.sx
      local dy = -58 - s.sy
      s.px = s.x
      s.py = s.y
      s.x = bez(s.sx, s.sx + dx / 4, s.tx - dx / 4, s.tx, t)
      s.y = bez(s.sy, s.sy + dy / 4, -58 - dy / 4, -58, t)
      if s.f >= 8 then
        del(streaks, s)
        health_arrive()
      end
    end
  end
end

-- ======================================================================
-- player
-- ======================================================================

function pcol()
  return 1 + px \ 10
end

function prow()
  return 1 + py \ 8
end

function rcol()
  return 1 + (80 - px) \ 10
end

-- reflection mirrors the player's facing left<->right
function rfacing()
  if (pfacing == 0) return 1
  if (pfacing == 1) return 0
  return pfacing
end

-- returns coin index-ish occupancy check: is any landed coin on (c, r)?
function tile_occupied(c, r)
  local hit = 0
  for co in all(coins) do
    if co.ph == 3 and 1 + flr(co.x) \ 10 == c and 1 + flr(co.y) \ 8 == r then
      hit = 1
    end
  end
  return hit
end

function bump_coin_at(c, r)
  for co in all(coins) do
    if co.ph == 3 and 1 + flr(co.x) \ 10 == c and 1 + flr(co.y) \ 8 == r then
      co.hp -= 1
      if co.hp <= 0 then
        coin_die(co)
        del(coins, co)
      end
    end
  end
end

function coin_die(co)
  spawn_burst(flr(co.x), flr(co.y), 0, 6, 6, 4)
  jb_sfx(21, 1)
end

function undo_step()
  px = 10 * pprev_col - 5
  py = 8 * pprev_row - 4
  pstep_frames = 0
  pstep_dir = 4
  pnext_dir = 4
end

function player_bump()
  jb_sfx(20, 2)
  undo_step()
  pbump = 11
  freeze_shake(0, 5)
end

function try_step(dir)
  if pstep_dir == 4 and pteeter <= 0 and pbump <= 0 and pstun <= 0 then
    if bh_health <= 0 and boss_phase <= 0 and boss_on == 0 then
      jb_sfx(29, 1)
    end
    pfacing = dir
    pstep_dir = dir
    pstep_frames = 4
    pnext_dir = 4
    return true
  end
  return false
end

function queue_step(dir)
  if not try_step(dir) then
    pnext_dir = dir
  end
end

function check_inputs()
  if (btnp(0)) queue_step(0)
  if (btnp(1)) queue_step(1)
  if (btnp(2)) queue_step(2)
  if (btnp(3)) queue_step(3)
end

function apply_step()
  local dir = pstep_dir
  local dist = pstep_frames
  if dir ~= 4 then
    if dir > 1 then
      local d2 = dist
      if (dist > 2) d2 = dist - 1
      pvy += (2 * dir - 5) * d2
    else
      pvx += 2 * dir * dist - dist
    end
    pstep_frames -= 1
    if pstep_frames <= 0 then
      pstep_dir = 4
      if pnext_dir ~= 4 then
        try_step(pnext_dir)
        apply_step()
      end
    end
  end
end

function update_player()
  if (pstun > 0) pstun -= 1
  if (pteeter > 0) pteeter -= 1
  if (pbump > 0) pbump -= 1
  check_inputs()
  if pnext_dir ~= 4 and pstep_dir == 4 then
    try_step(pnext_dir)
  end
  pprev_col = pcol()
  pprev_row = prow()
  if ref_on == 1 then
    rprev_col = rcol()
    rprev_row = prow()
  end
  if pstun <= 0 then
    pvx = 0
    pvy = 0
    apply_step()
    px += pvx
    py += pvy
    local c = pcol()
    local r = prow()
    if pprev_col ~= c or pprev_row ~= r then
      if c ~= mid(1, c, 8) or r ~= mid(1, r, 5) then
        jb_sfx(19, 3)
        undo_step()
        pteeter = 11
      end
      local occ = tile_occupied(pcol(), prow())
      local crossed = 0
      if ref_on == 1 then
        local a = 0
        local b = 0
        if (pprev_col < 5) a = 1
        if (pcol() < 5) b = 1
        if (a ~= b) crossed = 1
      end
      if occ == 1 or crossed == 1 then
        if ref_on == 1 then
          if tile_occupied(rcol(), prow()) == 1 then
            bump_coin_at(rcol(), prow())
          end
        end
        player_bump()
        if occ == 1 then
          bump_coin_at(pcol(), prow())
        end
      end
    end
  end
  if (pinvinc > 0) pinvinc -= 1
  pfa += 1
end

-- reflection: mirrors the player; bumps coins on its own half
function update_reflection()
  if (ref_on == 0 or palive == 0) return
  local c = rcol()
  local r = prow()
  if (rprev_col ~= c or rprev_row ~= r) and tile_occupied(c, r) == 1 then
    bump_coin_at(c, r)
    if tile_occupied(pcol(), prow()) == 1 then
      bump_coin_at(pcol(), prow())
    end
    player_bump()
  end
end

function player_hurt(hx, hy)
  if (pinvinc > 0 or palive == 0) return
  jb_sfx(17, 0)
  spawn_pain(hx, hy)
  freeze_shake(6, 10)
  ph_anim = 1
  ph_dc = 20
  pinvinc = 60
  pstun = 19
  score_mult = 0
  ph_hearts -= 1
  if ph_hearts <= 0 then
    start_death()
  end
end

-- ======================================================================
-- magic tiles + score/health economy
-- ======================================================================

function spawn_magic_tile(delay)
  if bh_health >= 60 then
    bh_dc = 61
  end
  local d = delay
  if (d < 1) d = 1
  add(tiles, {
    x = 10 * rnd_int(1, 8) - 5,
    y = 8 * rnd_int(1, 5) - 4,
    st = 0, t = d, f = 0,
  })
end

function update_tiles()
  for tl in all(tiles) do
    tl.f += 1
    if tl.st == 0 then
      tl.t -= 1
      if tl.t == 10 then
        jb_sfx(8, 3)
      end
      if tl.t <= 0 then
        tl.st = 1
        tl.f = 0
        freeze_shake(0, 1)
        spawn_burst(tl.x, tl.y, 0, 4, 16, 4)
      end
    elseif tl.st == 2 then
      tl.t -= 1
      if (tl.t <= 0) del(tiles, tl)
    else
      -- active: collected by the player or the reflection
      local c = 1 + tl.x \ 10
      local r = 1 + tl.y \ 8
      local got = 0
      if (palive == 1 and pcol() == c and prow() == r) got = 1
      if (ref_on == 1 and palive == 1 and rcol() == c and prow() == r) got = 1
      if got == 1 then
        tl.st = 2
        tl.t = 6
        collect_tile(tl.x, tl.y, tl.f)
      end
    end
  end
end

function collect_tile(x, y, fa)
  freeze_shake(2, 2)
  score_mult = min(score_mult + 1, 8)
  jb_sfx(9, 3)
  score += score_mult
  add(points, { x = x, y = y - 7, v = score_mult, f = 32 })
  local health_change = 6
  if (boss_phase == 0) health_change = 12
  local n = 25
  if (boss_phase >= 5) n = 15
  spawn_burst(x, y, 0, n, 16, 10)
  local i = 1
  while i <= health_change do
    add(streaks, {
      x = x + 0.0, y = y + 0.0, px = x + 0.0, py = y + 0.0,
      vx = 3 * cos(i / health_change), vy = 3 * sin(i / health_change) - 1,
      sx = 0.0, sy = 0.0, tx = 8 + min(bh_health + i, 60),
      dl = 7 + 2 * i, f = 0,
    })
    i += 1
  end
  if health_change + bh_health < 60 and boss_phase < 5 then
    local base = 120
    if (boss_phase < 1) base = 100
    spawn_magic_tile(base - min(fa, 20))
  end
end

-- a health streak reached the bar (the original's per-particle promise)
function health_arrive()
  jb_sfx(10, 3)
  if bh_health < 60 then
    bh_health = mid(0, bh_health + 1, 60)
    bh_vis = 1
    bh_rainbow = 15
    local h = bh_health
    if boss_phase == 0 then
      if h == 25 then
        spawn_boss()
      elseif h == 37 then
        avis[BB] = 1
      elseif h == 60 then
        boss_intro()
      end
    elseif h >= 60 then
      if boss_phase >= 5 then
        bh_health = 0
      elseif boss_phase == 4 then
        start_victory()
      else
        start_phase_transition()
      end
    end
  end
end

function update_points()
  for pt in all(points) do
    pt.y -= 0.5
    pt.f -= 1
    if (pt.f <= 0) del(points, pt)
  end
end

-- ======================================================================
-- hazards
-- ======================================================================

function spawn_card(x, y, vx)
  local red = 0
  if (rnd(1) < 0.5) red = 1
  add(cards, { x = x + 0.0, y = y, vx = vx, red = red, f = 0 })
end

function update_cards()
  for cd in all(cards) do
    cd.x += cd.vx
    cd.f += 1
    if palive == 1 and pinvinc <= 0 then
      local c = 1 + flr(cd.x) \ 10
      local r = 1 + cd.y \ 8
      if c == pcol() and r == prow() then
        player_hurt(px, py)
      elseif ref_on == 1 and c == rcol() and r == prow() then
        player_hurt(80 - px, py)
      end
    end
    if (cd.f >= 100 or cd.x < -20 or cd.x > 100) del(cards, cd)
  end
end

function throw_coin_at(bx, by, tc, tr)
  local tx = 10 * tc - 5
  local ty = 8 * tr - 4
  jb_sfx(21, 1)
  add(coins, {
    x = bx + 0.0, y = by + 0.0, sx = bx, sy = by,
    tx = tx, ty = ty, ph = 0, f = 0, hp = 3,
  })
end

function update_coins()
  for co in all(coins) do
    co.f += 1
    if co.ph == 0 then
      -- arc to the target: 25 frames ease_out, anchors {20,-30,10,-60}
      local t = ease(E_OUT, co.f / 25)
      co.x = bez(co.sx, co.sx + 20, co.tx + 2 + 10, co.tx + 2, t)
      co.y = bez(co.sy, co.sy - 30, co.ty - 60, co.ty, t)
      if co.f >= 25 then
        co.ph = 1
        co.f = 0
      end
    elseif co.ph == 1 then
      if co.f >= 2 then
        -- landing frame: damaging + crushes a coin already there
        jb_sfx(22, 1)
        freeze_shake(2, 2)
        local c = 1 + flr(co.x) \ 10
        local r = 1 + flr(co.y) \ 8
        for other in all(coins) do
          if other.ph == 3 and 1 + flr(other.x) \ 10 == c and 1 + flr(other.y) \ 8 == r then
            coin_die(other)
            del(coins, other)
          end
        end
        if palive == 1 and pinvinc <= 0 then
          if (c == pcol() and r == prow()) player_hurt(px, py)
          if (ref_on == 1 and c == rcol() and r == prow()) player_hurt(80 - px, py)
        end
        co.ph = 2
        co.f = 0
        co.sx = flr(co.x)
        co.sy = flr(co.y)
      end
    elseif co.ph == 2 then
      -- settle bounce: rel (-2,0) over 8, anchors {0,-4,0,-4}
      local t = co.f / 8
      co.x = bez(co.sx, co.sx, co.sx - 2, co.sx - 2, t)
      co.y = bez(co.sy, co.sy - 4, co.sy - 4, co.sy, t)
      if co.f >= 8 then
        co.ph = 3
        co.f = 0
      end
    else
      -- sitting on the stage: still hurts on contact
      if palive == 1 and pinvinc <= 0 and pstun <= 0 then
        local c = 1 + flr(co.x) \ 10
        local r = 1 + flr(co.y) \ 8
        if (c == pcol() and r == prow()) player_hurt(px, py)
      end
    end
  end
end

function despawn_coins_of()
  for co in all(coins) do
    coin_die(co)
    del(coins, co)
  end
end

-- conjure pattern: the original's do_a_math hole sequence
function conj_hole_step(n, k)
  local total = 0
  if ((n + k) % 2 > 0) total += 1
  if ((n + k) % 3 > 0) total += 1
  if ((n + k) % 5 > 0) total += 1
  return mid(1, total, 3)
end

function conj_k()
  local c = conjure_counter
  if (c == 1) return 1
  if (c == 2) return 2
  if (c == 3) return 3
  if (c == 4) return 5
  if (c == 5) return 7
  if (c == 6) return 9
  if (c == 7) return 10
  return 11
end

-- spawn the flower field for boss b (1 = holes pattern, 2 = complement)
function conjure_spawn(b, extra)
  local k = conj_k()
  local n = 0
  local count = 0
  local i = 0
  while i < 40 do
    local at_n = 0
    if (i == n) at_n = 1
    if at_n == 1 then
      n += conj_hole_step(n, k)
    end
    local want = 0
    if (b == 1 and at_n == 1) want = 1
    if (b == 2 and at_n == 0) want = 1
    if want == 1 then
      count += 1
      flowseq[count] = i
    end
    i += 1
  end
  -- shuffle spawn order (original shuffles its locations list)
  i = count
  while i > 1 do
    local j = rnd_int(1, i)
    local tmp = flowseq[i]
    flowseq[i] = flowseq[j]
    flowseq[j] = tmp
    i -= 1
  end
  i = 1
  while i <= count do
    local cell = flowseq[i]
    add(flowers, {
      x = cell % 8 * 10 + 5, y = 8 * (cell \ 8) + 4,
      dl = i, bt = extra + 65 - i, dc = 0, ftd = 0, own = b,
    })
    i += 1
  end
end

function bloom_flowers(b)
  jb_sfx(16, 1)
  for fl in all(flowers) do
    if fl.own == b and fl.dl <= 0 and fl.ftd == 0 then
      fl.ftd = 15
      fl.dc = 4
      local col = 8
      spawn_petals(fl.x, fl.y, col)
    end
  end
end

function update_flowers()
  for fl in all(flowers) do
    if fl.dl > 0 then
      fl.dl -= 1
      if (fl.dl == 0) jb_sfx(15, 1)
    else
      if fl.bt > 0 then
        fl.bt -= 1
      end
      if fl.dc > 0 then
        fl.dc -= 1
        -- blooming: 4 damaging frames
        if palive == 1 and pinvinc <= 0 then
          local c = 1 + fl.x \ 10
          local r = 1 + fl.y \ 8
          if (c == pcol() and r == prow()) player_hurt(px, py)
          if (ref_on == 1 and c == rcol() and r == prow()) player_hurt(80 - px, py)
        end
      end
      if fl.ftd > 0 then
        fl.ftd -= 1
        if (fl.ftd <= 0) del(flowers, fl)
      end
    end
  end
end

function spawn_laser(own, long)
  local ftd = 16
  if (long == 1) ftd = 150
  freeze_shake(0, 4)
  add(lasers, { own = own, f = 0, ftd = ftd })
end

function update_lasers()
  for lz in all(lasers) do
    lz.f += 1
    lz.ftd -= 1
    if palive == 1 and pinvinc <= 0 then
      local base = BB
      if (lz.own == 2) base = GB
      local c = 1 + flr(ax[base]) \ 10
      if (c == pcol()) player_hurt(px, py)
      if (ref_on == 1 and c == rcol()) player_hurt(80 - px, py)
    end
    if (lz.ftd <= 0) del(lasers, lz)
  end
end

function update_hearts_pool()
  for h in all(hearts) do
    h.ftd -= 1
    if h.ftd <= 0 then
      del(hearts, h)
    else
      local c = 1 + h.x \ 10
      local r = 1 + h.y \ 8
      local got = 0
      if (palive == 1 and pcol() == c and prow() == r) got = 1
      if (ref_on == 1 and palive == 1 and rcol() == c and prow() == r) got = 1
      if got == 1 then
        jb_sfx(18, 0)
        if ph_hearts < 4 then
          ph_hearts += 1
          ph_anim = 2
          ph_dc = 10
        end
        spawn_burst(h.x, h.y, 0, 6, 8, 4)
        del(hearts, h)
      end
    end
  end
end

function update_bunnies()
  if hat_on == 1 then
    hat_f += 1
    if hat_f % 15 == 0 then
      local d = rnd_dir()
      add(bunnies, {
        x = hat_x + 0.0, y = hat_y + 0.0,
        vx = d * (1 + rnd(2)), vy = -1 - rnd(2), f = 100,
      })
      poof_at(hat_x, hat_y, 0)
      jb_sfx(25, 2)
    end
  end
  for b in all(bunnies) do
    b.vy += 0.1
    b.x += b.vx
    b.y += b.vy
    b.f -= 1
    if (b.f <= 0) del(bunnies, b)
  end
end

function update_poofs()
  for p in all(poofs) do
    p.f += 1
    if (p.f >= 12) del(poofs, p)
  end
end

-- cancel_everything: clears boss-generated entities on phase changes
function clear_boss_spawns()
  for cd in all(cards) do
    del(cards, cd)
  end
  for co in all(coins) do
    del(coins, co)
  end
  for fl in all(flowers) do
    del(flowers, fl)
  end
  for lz in all(lasers) do
    del(lasers, lz)
  end
  for tl in all(tiles) do
    if (tl.st > 0) del(tiles, tl)
  end
end

-- ======================================================================
-- boss: spawn / helpers
-- ======================================================================

function hand_dir(i)
  if (i == LH or i == GLH) return -1
  return 1
end

function boss_base(b)
  if (b == 2) return GB
  return BB
end

function set_idle(b, on)
  local i = boss_base(b)
  aidle[i] = on
  aidle[i + 1] = on
  aidle[i + 2] = on
end

function set_expr(b, e)
  if b == 1 then
    bexpr = e
  else
    gexpr = e
  end
end

function home_x_of(b)
  if (b == 2) return ghome_x
  return bhome_x
end

function spawn_boss()
  boss_on = 1
  bfa = 0
  bexpr = 4
  bhat = 0
  bcracked = 0
  ax[BB] = 40
  ay[BB] = -28
  avis[BB] = 0
  ax[LH] = 40 - 18
  ay[LH] = -23
  avis[LH] = 0
  apose[LH] = 3
  ax[RH] = 40 + 18
  ay[RH] = -23
  avis[RH] = 0
  apose[RH] = 3
end

function spawn_green()
  green_on = 1
  gexpr = bexpr
  ghat = 1
  ax[GB] = ax[BB]
  ay[GB] = ay[BB]
  avis[GB] = 1
  ax[GLH] = ax[LH]
  ay[GLH] = ay[LH]
  avis[GLH] = avis[LH]
  apose[GLH] = apose[LH]
  ax[GRH] = ax[RH]
  ay[GRH] = ay[RH]
  avis[GRH] = avis[RH]
  apose[GRH] = apose[RH]
end

function hand_appear(i)
  if avis[i] == 0 then
    avis[i] = 1
    poof_at(flr(ax[i]), flr(ay[i]), 0)
  end
end

function hand_disappear(i)
  if avis[i] == 1 then
    avis[i] = 0
    poof_at(flr(ax[i]), flr(ay[i]), 0)
  end
end

-- return_to_ready_position (instant part; the 25-frame wait is scripted)
function start_ready(b, expr)
  local i = boss_base(b)
  local hx = home_x_of(b)
  bwand_l = 0
  bwand_r = 0
  apose[i + 1] = 3
  apose[i + 2] = 3
  set_idle(b, 1)
  set_expr(b, expr)
  mv_to_d(i, hx, bhome_y, 15, E_IN)
  mv_to(i + 1, hx - 18, bhome_y + 5, 15, E_IN, -10, -10, -20, 0)
  hand_appear(i + 1)
  mv_to(i + 2, hx + 18, bhome_y + 5, 15, E_IN, 10, -10, 20, 0)
  hand_appear(i + 2)
end

-- ======================================================================
-- hand machine
-- ======================================================================

function hand_start_cards(i, first, delay)
  hA[i] = H_CARDS
  hS[i] = 0
  hFirst[i] = first
  if first == 1 then
    hRow[i] = 0
    hW[i] = delay
  else
    hRow[i] = 1
    hW[i] = delay + 19
  end
  aidle[i] = 0
end

function hand_start_pound(i, b)
  hA[i] = H_POUND
  hS[i] = 0
  hW[i] = 0
end

function hand_start_temple(i, b)
  hA[i] = H_TEMPLE
  hS[i] = 0
  hW[i] = 0
end

function hand_step(i)
  if (hA[i] == H_NONE) return
  if hW[i] > 0 then
    hW[i] -= 1
    return
  end
  local d = hand_dir(i)
  local b = 1
  local base = BB
  if i >= GB then
    b = 2
    base = GB
  end
  if hA[i] == H_CARDS then
    if hS[i] == 0 then
      apose[i] = 3
      mv_to(i, 40 + 52 * d, 8 * (hRow[i] % 5) + 4, 18, E_OUTIN, 10 * d, -10, 10 * d, 10)
      hS[i] = 1
      hW[i] = 18
    elseif hS[i] == 1 then
      apose[i] = 2
      hS[i] = 2
      hW[i] = 12
    else
      apose[i] = 1
      jb_sfx(13, 2)
      spawn_card(flr(ax[i]) - 7 * d, flr(ay[i]), -1.5 * d)
      hRow[i] += 2
      hW[i] = 10
      if hRow[i] > 4 then
        hA[i] = H_NONE
      else
        hS[i] = 0
      end
    end
  elseif hA[i] == H_POUND then
    if hS[i] == 0 then
      apose[i] = 2
      mv_to(i, ax[base] + 4 * d, ay[base] + 20, 15, E_OUT, 20 * d, 0, 20 * d, 0)
      hS[i] = 1
      hW[i] = 15
    else
      jb_sfx(12, 2)
      freeze_shake(0, 2)
      hA[i] = H_NONE
    end
  elseif hA[i] == H_TEMPLE then
    if hS[i] == 0 then
      apose[i] = 1
      mv_to_d(i, ax[base] + 13 * d, ay[base], 20, E_LIN)
      hS[i] = 1
      hW[i] = 20
    else
      hA[i] = H_NONE
    end
  elseif hA[i] == H_FLOURISH then
    if hS[i] == 0 then
      mv_to(i, 40 + 20 * d, -30, 12, E_OUT, -20, 20, 0, 20)
      hS[i] = 1
      hW[i] = 12
    else
      apose[i] = 6
      jb_sfx(23, 1)
      spawn_burst(flr(ax[i]), flr(ay[i]), 20, 20, 3, 10)
      freeze_shake(0, 20)
      hA[i] = H_NONE
    end
  elseif hA[i] == H_CASTR then
    -- upgraded cast: right hand takes a wand too
    if hS[i] == 0 then
      apose[i] = 1
      bwand_r = 1
      poof_at(flr(ax[i]) - 10, flr(ay[i]), 0)
      hS[i] = 1
      hW[i] = 30
    elseif hS[i] == 1 then
      mv_to(i, 40 + 20 * d, -30, 12, E_OUT, -20, 20, 0, 20)
      hS[i] = 2
      hW[i] = 12
    else
      apose[i] = 6
      jb_sfx(23, 1)
      spawn_burst(flr(ax[i]), flr(ay[i]), 20, 20, 3, 10)
      freeze_shake(0, 20)
      hA[i] = H_NONE
    end
  end
end

function hands_busy(b)
  local i = boss_base(b)
  if (hA[i + 1] ~= H_NONE) return true
  if (hA[i + 2] ~= H_NONE) return true
  return false
end

-- ======================================================================
-- sub-action machine (conjure / lasers / coins / cards / ready / ...)
-- ======================================================================

function sub_start(b, act)
  sA[b] = act
  sS[b] = 0
  sW[b] = 0
end

function sub_step(b)
  if (sA[b] == S_NONE) return
  if sW[b] > 0 then
    sW[b] -= 1
    return
  end
  local base = boss_base(b)
  local lh = base + 1
  local rh = base + 2
  if sA[b] == S_READY then
    if sS[b] == 0 then
      start_ready(b, sN[b])
      sS[b] = 1
      sW[b] = 25
    else
      sA[b] = S_NONE
    end
  elseif sA[b] == S_CONJ then
    if sS[b] == 0 then
      if (b == 1) conjure_counter = 1 + (conjure_counter + rnd_int(0, 2)) % 8
      set_idle(b, 0)
      hand_start_temple(lh, b)
      hand_start_temple(rh, b)
      sS[b] = 1
      sW[b] = 20
    elseif sS[b] == 1 then
      set_expr(b, 2)
      conjure_spawn(b, sXtra[b])
      sS[b] = 2
      sW[b] = sXtra[b] + 65
    elseif sS[b] == 2 then
      bloom_flowers(b)
      apose[lh] = 5
      apose[rh] = 5
      set_expr(b, 3)
      sS[b] = 3
      sW[b] = 31
    else
      sA[b] = S_NONE
    end
  elseif sA[b] == S_LASERS then
    if sS[b] == 0 then
      hand_disappear(lh)
      hand_disappear(rh)
      sCol[b] = rnd_int(0, 7)
      set_expr(b, 5)
      set_idle(b, 0)
      sN[b] = 3
      sS[b] = 1
    elseif sS[b] == 1 then
      sCol[b] = (sCol[b] + rnd_int(2, 6)) % 8
      mv_to(base, 10 * sCol[b] + 5, -20, 15, E_IN, 0, -10, 0, -10)
      sS[b] = 2
      sW[b] = 16
    elseif sS[b] == 2 then
      if sSweep[b] == 1 then
        local dir = 2
        if sCol[b] > 5 or (rnd(1) < 0.5 and sCol[b] > 1) then
          dir = -2
        end
        sCol[b] += dir
        mv_rel_d(base, 10 * dir, 0, 40, E_LIN)
      end
      sS[b] = 3
      sW[b] = 12
    elseif sS[b] == 3 then
      jb_sfx(14, 1)
      if b == 1 then
        bdc = 31
      else
        gdc = 31
      end
      sS[b] = 4
      sW[b] = 12
    elseif sS[b] == 4 then
      set_expr(b, 0)
      spawn_laser(b, 0)
      sS[b] = 5
      sW[b] = 16
    else
      set_expr(b, 5)
      sN[b] -= 1
      sW[b] = 5
      if sN[b] > 0 then
        sS[b] = 1
      else
        sA[b] = S_NONE
      end
    end
  elseif sA[b] == S_COINS then
    if sS[b] == 0 then
      set_idle(b, 0)
      hand_start_temple(rh, b)
      sS[b] = 1
      sW[b] = 20
    elseif sS[b] == 1 then
      set_expr(b, 7)
      apose[rh] = 1
      sS[b] = 2
      sW[b] = 15
    elseif sS[b] == 2 then
      local tc = pcol()
      local tr = prow()
      if sTgt[b] == 1 then
        tc = rcol()
      end
      throw_coin_at(flr(ax[base]) + 13, flr(ay[base]) - 6, tc, tr)
      apose[rh] = 4
      set_expr(b, 3)
      sCount[b] -= 1
      sW[b] = 20
      if sCount[b] > 0 then
        sS[b] = 1
      else
        sS[b] = 3
      end
    else
      sA[b] = S_NONE
    end
  elseif sA[b] == S_CARDS then
    if sS[b] == 0 then
      -- both hands, staggered: right first (or left for the reflection)
      if b == 1 then
        hand_start_cards(rh, 1, 0)
        hand_start_cards(lh, 0, 0)
      else
        hand_start_cards(lh, 1, 0)
        hand_start_cards(rh, 0, 0)
      end
      sS[b] = 1
    elseif not hands_busy(b) then
      sA[b] = S_NONE
    end
  elseif sA[b] == S_CARDS_L then
    if sS[b] == 0 then
      hand_start_cards(lh, 0, 0)
      sS[b] = 1
    elseif hA[lh] == H_NONE then
      sA[b] = S_NONE
    end
  elseif sA[b] == S_CARDS_R then
    if sS[b] == 0 then
      hand_start_cards(rh, 1, 0)
      sS[b] = 1
    elseif hA[rh] == H_NONE then
      sA[b] = S_NONE
    end
  elseif sA[b] == S_DESPAWN then
    despawn_coins_of()
    sW[b] = 10
    sA[b] = S_NONE
  elseif sA[b] == S_POUND then
    if sS[b] == 0 then
      hand_start_pound(lh, b)
      hand_start_pound(rh, b)
      sS[b] = 1
    elseif not hands_busy(b) then
      sA[b] = S_NONE
    end
  elseif sA[b] == S_REEL then
    if sS[b] == 0 then
      hand_appear(lh)
      apose[lh] = 3
      hand_appear(rh)
      apose[rh] = 3
      add(hearts, { x = 10 * rnd_int(3, 6) - 5, y = 4, ftd = 150 })
      if (boss_phase >= 3) bcracked = 1
      set_expr(b, 8)
      set_idle(b, 0)
      sS[b] = 1
    elseif sN[b] > 0 then
      -- shake all three actors
      local k = base
      while k <= rh do
        freeze_shake(0, 2)
        ax[k] = mid(10, ax[k], 70)
        ay[k] = mid(-40, ay[k], -20)
        poof_at(flr(ax[k]) + rnd_int(-10, 10), flr(ay[k]) + rnd_int(-10, 10), 1)
        mv_rel_d(k, rnd_int(-7, 7), rnd_int(-7, 7), 6, E_OUT)
        k += 1
      end
      sN[b] -= 1
      sW[b] = 5
    else
      sA[b] = S_NONE
    end
  elseif sA[b] == S_CAST then
    if sS[b] == 0 then
      set_idle(b, 0)
      mv_rel_d(lh, 23, 14, 20, E_IN)
      sS[b] = 1
      sW[b] = 20
    elseif sS[b] == 1 then
      apose[lh] = 1
      mv_rel(rh, 0, 0, 40, E_LIN, 18, 6, -18, 6)
      sS[b] = 2
      sW[b] = 40
    elseif sS[b] == 2 then
      mv_rel(rh, 0, 0, 40, E_LIN, 18, 6, -18, 6)
      sS[b] = 3
      sW[b] = 40
    elseif sS[b] == 3 then
      if sUpg[b] == 1 then
        hA[rh] = H_CASTR
        hS[rh] = 0
        hW[rh] = 0
      end
      set_expr(b, 1)
      bwand_l = 1
      poof_at(flr(ax[lh]) + 10, flr(ay[lh]), 0)
      sS[b] = 4
      sW[b] = 30
    elseif sS[b] == 4 then
      hA[lh] = H_FLOURISH
      hS[lh] = 0
      hW[lh] = 0
      sS[b] = 5
      sW[b] = 13
    elseif sS[b] == 5 then
      set_expr(b, 3)
      sS[b] = 6
      sW[b] = 5
    elseif sS[b] == 6 then
      if sUpg[b] == 1 then
        spawn_green()
        bhome_x += 20
        jb_sfx(30, 2)
      else
        ref_on = 1
        rprev_col = rcol()
        rprev_row = prow()
        poof_at(80 - px, py, 0)
      end
      sS[b] = 7
      sW[b] = 55
    else
      sA[b] = S_NONE
    end
  end
end

function sub_busy(b)
  if (sA[b] ~= S_NONE) return true
  return false
end

-- ======================================================================
-- rotation machine (per-phase attack loops + phase-change cinematics)
-- ======================================================================

function rot_start(b, act)
  rA[b] = act
  rS[b] = 0
  rW[b] = 0
end

-- advance helper: start sub and move to the given step
function rot_sub(b, act, stp)
  sub_start(b, act)
  rS[b] = stp
end

function decide_next_action()
  trans_lock = 0
  if boss_phase == 1 then
    rot_start(1, R_P1)
  elseif boss_phase <= 3 then
    rot_start(1, R_P23)
  elseif boss_phase == 4 then
    rot_start(1, R_P4)
  else
    rA[1] = R_NONE
  end
end

function rot_step_main()
  local b = 1
  if (rA[b] == R_NONE) return
  if rW[b] > 0 then
    rW[b] -= 1
    return
  end
  if (sub_busy(b)) return
  if rA[b] == R_P1 then
    local s = rS[b]
    if s == 0 then
      rot_sub(b, S_READY, 1)
      sN[b] = 1
    elseif s == 1 then
      rW[b] = 15
      rS[b] = 2
    elseif s == 2 then
      rot_sub(b, S_CARDS_L, 3)
    elseif s == 3 then
      rot_sub(b, S_READY, 4)
      sN[b] = 1
    elseif s == 4 then
      rW[b] = 10
      rS[b] = 5
    elseif s == 5 then
      rot_sub(b, S_CARDS_R, 6)
    elseif s == 6 then
      rot_sub(b, S_READY, 7)
      sN[b] = 1
    elseif s == 7 then
      rW[b] = 25
      rS[b] = 8
    elseif s == 8 then
      sSweep[b] = 0
      rot_sub(b, S_LASERS, 9)
    else
      rS[b] = 0
    end
  elseif rA[b] == R_P23 then
    local s = rS[b]
    if s == 0 then
      rW[b] = 15
      rS[b] = 1
    elseif s == 1 then
      sXtra[b] = 10
      rot_sub(b, S_CONJ, 2)
    elseif s == 2 then
      rW[b] = 30
      rS[b] = 3
    elseif s == 3 then
      rot_sub(b, S_READY, 4)
      sN[b] = 1
    elseif s == 4 then
      rot_sub(b, S_CARDS, 5)
    elseif s == 5 then
      rot_sub(b, S_READY, 6)
      sN[b] = 1
    elseif s == 6 then
      sSweep[b] = 1
      rot_sub(b, S_LASERS, 7)
    elseif s == 7 then
      rot_sub(b, S_READY, 8)
      sN[b] = 1
    elseif s == 8 then
      rot_sub(b, S_DESPAWN, 9)
    elseif s == 9 then
      sCount[b] = 4
      sTgt[b] = 0
      rot_sub(b, S_COINS, 10)
    elseif s == 10 then
      rot_sub(b, S_READY, 11)
      sN[b] = 1
    else
      rS[b] = 0
    end
  elseif rA[b] == R_P4 then
    local s = rS[b]
    if s == 0 then
      -- green: wait 75, conjure, ready
      rot_start(2, R_GCONJ)
      rW[2] = 75
      sXtra[b] = 0
      rot_sub(b, S_CONJ, 1)
    elseif s == 1 then
      rot_sub(b, S_READY, 2)
      sN[b] = 1
    elseif s == 2 then
      rW[b] = 20
      rS[b] = 3
    elseif s == 3 then
      sXtra[b] = 0
      rot_sub(b, S_CONJ, 4)
    elseif s == 4 then
      rot_sub(b, S_READY, 5)
      sN[b] = 1
    elseif s == 5 then
      rot_start(2, R_GCARDS)
      rW[2] = 84
      rot_sub(b, S_CARDS, 6)
    elseif s == 6 then
      rot_sub(b, S_READY, 7)
      sN[b] = 1
    elseif s == 7 then
      rW[b] = 100
      rS[b] = 8
    elseif s == 8 then
      rot_start(2, R_GLASERS)
      rW[2] = 30
      sSweep[b] = 0
      rot_sub(b, S_LASERS, 9)
    elseif s == 9 then
      rot_sub(b, S_READY, 10)
      sN[b] = 1
    elseif s == 10 then
      rW[b] = 50
      rS[b] = 11
    elseif s == 11 then
      rot_start(2, R_GCOINS)
      rot_sub(b, S_DESPAWN, 12)
    elseif s == 12 then
      sCount[b] = 3
      sTgt[b] = 0
      rot_sub(b, S_COINS, 13)
    elseif s == 13 then
      rot_sub(b, S_READY, 14)
      sN[b] = 1
    elseif s == 14 then
      rW[b] = 100
      rS[b] = 15
    else
      rS[b] = 0
    end
  elseif rA[b] == R_REEL then
    local s = rS[b]
    if s == 0 then
      -- cancel everything, appear, reel 10
      cancel_boss(1)
      avis[BB] = 1
      hand_appear(LH)
      hand_appear(RH)
      sN[b] = 10
      rot_sub(b, S_REEL, 1)
    elseif s == 1 then
      rW[b] = 10
      rS[b] = 2
    elseif s == 2 then
      set_expr(b, 5)
      rW[b] = 20
      rS[b] = 3
    elseif s == 3 then
      -- dispatch the per-phase change cinematic
      if boss_phase == 1 then
        rot_start(b, R_CHG1)
      elseif boss_phase == 2 then
        rot_start(b, R_CHG2)
      else
        rot_start(b, R_CHG3)
      end
    end
  elseif rA[b] == R_CHG1 then
    local s = rS[b]
    if s == 0 then
      rot_sub(b, S_READY, 1)
      sN[b] = 2
    elseif s == 1 then
      rW[b] = 30
      rS[b] = 2
    elseif s == 2 then
      set_idle(b, 0)
      rW[b] = 10
      rS[b] = 3
    elseif s == 3 then
      rot_sub(b, S_POUND, 4)
    elseif s == 4 then
      rot_sub(b, S_POUND, 5)
    elseif s == 5 then
      rot_sub(b, S_POUND, 6)
    elseif s == 6 then
      set_expr(b, 1)
      jb_sfx(16, 3)
      bbouq = 1
      apose[RH] = 3
      mv_rel(BB, 20, -10, 15, E_IN, -20, -10, -5, 0)
      rW[b] = 15 + 35
      rS[b] = 7
    elseif s == 7 then
      mv_rel_d(LH, 2, -9, 20, E_IN)
      rW[b] = 19
      rS[b] = 8
    elseif s == 8 then
      set_expr(b, 3)
      rW[b] = 30
      rS[b] = 9
    elseif s == 9 then
      set_expr(b, 1)
      rW[b] = 15
      rS[b] = 10
    elseif s == 10 then
      -- lh: 10, pose, hide bouquet, drift back; rh returns
      mv_rel(RH, 0, 7, 20, E_OUTIN, -35, -20, -25, 0)
      rW[b] = 10
      rS[b] = 11
    elseif s == 11 then
      apose[LH] = 3
      jb_sfx(28, 3)
      bbouq = 0
      mv_rel_d(LH, -22, 6, 20, E_IN)
      rW[b] = 9 + 15
      rS[b] = 12
    else
      finish_phase_change()
    end
  elseif rA[b] == R_CHG2 or rA[b] == R_CHG3 then
    local s = rS[b]
    if s == 0 then
      sN[b] = 2
      rot_sub(b, S_READY, 1)
    elseif s == 1 then
      if (rA[b] == R_CHG3) sUpg[b] = 1
      if (rA[b] == R_CHG2) sUpg[b] = 0
      rot_sub(b, S_CAST, 2)
    elseif s == 2 then
      if rA[b] == R_CHG3 and green_on == 1 then
        start_ready(2, 1)
      end
      rot_sub(b, S_READY, 3)
      sN[b] = 1
    elseif s == 3 then
      rW[b] = 60
      rS[b] = 4
    else
      finish_phase_change()
    end
  elseif rA[b] == R_INTRO then
    local s = rS[b]
    if s == 0 then
      rW[b] = 66
      rS[b] = 1
    elseif s == 1 then
      hand_appear(LH)
      rW[b] = 20
      rS[b] = 2
    elseif s == 2 then
      apose[LH] = 5
      rW[b] = 3
      rS[b] = 3
    elseif s == 3 then
      apose[LH] = 3
      rW[b] = 3
      rS[b] = 4
    elseif s == 4 then
      apose[LH] = 5
      rW[b] = 3
      rS[b] = 5
    elseif s == 5 then
      apose[LH] = 3
      rW[b] = 3 + 20
      rS[b] = 6
    elseif s == 6 then
      hand_appear(RH)
      rW[b] = 10
      rS[b] = 7
    elseif s == 7 then
      mv_rel(RH, -16, 8, 10, E_OUT, 10, 0, 10, 5)
      rW[b] = 10
      rS[b] = 8
    elseif s == 8 then
      apose[RH] = 2
      set_expr(b, 5)
      rW[b] = 33
      rS[b] = 9
    elseif s == 9 then
      set_expr(b, 6)
      rW[b] = 28
      rS[b] = 10
    elseif s == 10 then
      set_expr(b, 5)
      rW[b] = 34
      rS[b] = 11
    elseif s == 11 then
      set_expr(b, 1)
      rW[b] = 5
      rS[b] = 12
    elseif s == 12 then
      -- lh reaches toward the head (art: pose wiggle + out-and-back)
      apose[LH] = 5
      mv_to(LH, ax[BB] - 5, ay[BB] - 3, 10, E_OUT, 0, -10, -10, -2)
      rW[b] = 12
      rS[b] = 13
    elseif s == 13 then
      apose[LH] = 3
      mv_to(LH, bhome_x - 18, bhome_y + 5, 10, E_IN, -10, -2, 0, -10)
      rW[b] = 10
      rS[b] = 14
    elseif s == 14 then
      bhat = 1
      poof_at(flr(ax[BB]), flr(ay[BB]) - 10, 0)
      rW[b] = 35
      rS[b] = 15
    else
      finish_phase_change()
    end
  end
end

-- green mirror's phase-4 schedule
function rot_step_green()
  local b = 2
  if (rA[b] == R_NONE or green_on == 0) return
  if rW[b] > 0 then
    rW[b] -= 1
    return
  end
  if (sub_busy(b)) return
  if rA[b] == R_GCONJ then
    local s = rS[b]
    if s == 0 then
      sXtra[b] = 0
      rot_sub(b, S_CONJ, 1)
    elseif s == 1 then
      rot_sub(b, S_READY, 2)
      sN[b] = 1
    else
      rA[b] = R_NONE
    end
  elseif rA[b] == R_GCARDS then
    local s = rS[b]
    if s == 0 then
      rot_sub(b, S_CARDS, 1)
    elseif s == 1 then
      rW[b] = 20
      rS[b] = 2
    elseif s == 2 then
      rot_sub(b, S_READY, 3)
      sN[b] = 1
    else
      rA[b] = R_NONE
    end
  elseif rA[b] == R_GLASERS then
    local s = rS[b]
    if s == 0 then
      sSweep[b] = 0
      rot_sub(b, S_LASERS, 1)
    elseif s == 1 then
      rot_sub(b, S_READY, 2)
      sN[b] = 1
    else
      rA[b] = R_NONE
    end
  elseif rA[b] == R_GCOINS then
    local s = rS[b]
    if s == 0 then
      rot_sub(b, S_DESPAWN, 1)
    elseif s == 1 then
      rW[b] = 17
      rS[b] = 2
    elseif s == 2 then
      sCount[b] = 3
      sTgt[b] = 1
      rot_sub(b, S_COINS, 3)
    elseif s == 3 then
      rot_sub(b, S_READY, 4)
      sN[b] = 1
    else
      rA[b] = R_NONE
    end
  end
end

-- cancel_everything for boss b (+ boss-generated entities when main)
function cancel_boss(b)
  local base = boss_base(b)
  sA[b] = S_NONE
  hA[base + 1] = H_NONE
  hA[base + 2] = H_NONE
  mv_cancel(base)
  mv_cancel(base + 1)
  mv_cancel(base + 2)
  if b == 1 then
    bwand_l = 0
    bwand_r = 0
    bbouq = 0
    bdc = 0
    clear_boss_spawns()
    if green_on == 1 then
      green_on = 0
      rA[2] = R_NONE
      sA[2] = S_NONE
      hA[GLH] = H_NONE
      hA[GRH] = H_NONE
    end
  end
end

-- ======================================================================
-- phase transitions / cinematics
-- ======================================================================

function boss_intro()
  if (boss_phase >= 1) then
    music_play(25)
  else
    music_play(8)
  end
  trans_lock = 1
  rot_start(1, R_INTRO)
end

function start_phase_transition()
  trans_lock = 1
  rot_start(1, R_REEL)
end

function finish_phase_change()
  spawn_magic_tile(100)
  if boss_phase == 0 then
    scene_frame = 0
    ph_vis = 1
  end
  boss_phase += 1
  decide_next_action()
end

function start_victory()
  trans_lock = 1
  rA[1] = R_NONE
  cancel_boss(1)
  avis[BB] = 1
  hand_appear(LH)
  hand_appear(RH)
  music_stop()
  -- ten bonus tiles
  local i = 1
  while i <= 10 do
    spawn_magic_tile(20 + 13 * i)
    i += 1
  end
  sN[1] = 40
  sub_start(1, S_REEL)
  vA = 1
  vW = 0
end

function victory_step()
  if (vA == 0) return
  if vW > 0 then
    vW -= 1
    return
  end
  if vA == 1 then
    if not sub_busy(1) then
      cancel_boss(1)
      mv_to_d(BB, 40, -20, 15, E_IN)
      mv_to_d(LH, 22, -15, 15, E_IN)
      mv_to_d(RH, 58, -15, 15, E_IN)
      vA = 2
      vW = 15 + 20
    end
  elseif vA == 2 then
    if ref_on == 1 then
      poof_at(80 - px, py, 0)
      ref_on = 0
    end
    hat_on = 1
    hat_x = 40
    hat_y = -20
    hat_f = 0
    poof_at(40, -20, 0)
    -- the mirror vanishes
    boss_on = 0
    avis[BB] = 0
    avis[LH] = 0
    avis[RH] = 0
    vA = 3
    vW = 120
  elseif vA == 3 then
    cur_anim = 0
    cur_dc = 100
    vA = 4
    vW = 90
  elseif vA == 4 then
    music_play(47)
    is_paused = 1
    vA = 5
    vW = 75
  elseif vA == 5 then
    score += max(0, 380 - timer_seconds)
    new_best_score = 0
    new_best_time = 0
    if score >= best_score then
      best_score = score
      new_best_score = 1
    end
    if timer_seconds <= best_time or best_time == 0 then
      best_time = timer_seconds
      new_best_time = 1
    end
    scr_spawn(3, 63, 215)
    vA = 6
    vW = 135
  elseif vA == 6 then
    jb_sfx(24, 3)
    vA = 7
    vW = 35
  elseif vA == 7 then
    jb_sfx(24, 3)
    vA = 8
    vW = 45
  elseif vA == 8 then
    if new_best_score == 1 or new_best_time == 1 then
      jb_sfx(9, 3)
    end
    vA = 0
  end
end

function start_death()
  is_paused = 1
  trans_lock = 1
  fg_on = 1
  fg_x = px + 23.0
  fg_y = py + 65.0
  fg_f = 0
  fg_mf = -1
  fg_fa = 0
  fg_slide = 0
  music_stop()
  scr_spawn(4, 63, 220)
  palive = 0
  dA = 1
  dW = 35
end

function death_step()
  if (dA == 0) return
  if dW > 0 then
    dW -= 1
    return
  end
  if dA == 1 then
    -- figment starts drifting to centre; curtains close; sting cues
    fg_sx = fg_x
    fg_sy = fg_y
    fg_mf = 0
    cur_anim = 0
    cur_dc = 100
    music_play(35)
    dA = 2
    dW = 30
  elseif dA == 2 then
    ph_move = 1
    ph_mf = 0
    ph_sx = ph_x
    dA = 0
  end
end

-- ======================================================================
-- screens (title / credit / victory / game over)
-- ======================================================================

function scr_spawn(i, x, fua)
  scr_on[i] = 1
  scr_x[i] = x
  scr_fa[i] = 0
  scr_fua[i] = fua
  scr_act[i] = 0
  scr_slide[i] = 0
end

function scr_slide_off(i, dir)
  scr_slide[i] = dir
  scr_sf[i] = 0
  scr_ssx[i] = scr_x[i]
end

function show_title_screen(dir)
  if dir == -1 then
    scr_spawn(1, -66, 115)
  else
    scr_spawn(1, 192, 115)
  end
  scr_slide[1] = dir
  scr_sf[1] = 0
  scr_ssx[1] = scr_x[1]
  scr_act[1] = 2   -- sliding INTO place (slide targets centre)
end

-- slide movement: the original's slide() bezier, 100 frames
function slide_x(x0, dir, f)
  local t = f / 100
  return bez(x0, x0 + dir * 70, x0 - 129 * dir, x0 - 129 * dir, t)
end

function update_screens()
  local i = 1
  while i <= 4 do
    if scr_on[i] == 1 then
      scr_fa[i] += 1
      if scr_slide[i] ~= 0 then
        scr_sf[i] += 1
        scr_x[i] = slide_x(scr_ssx[i], scr_slide[i], scr_sf[i])
        if scr_sf[i] >= 100 then
          if scr_act[i] == 2 then
            scr_slide[i] = 0
            scr_act[i] = 0
          else
            scr_on[i] = 0
            scr_slide[i] = 0
          end
        end
      end
      if scr_slide[i] == 0 or scr_act[i] == 2 then
        if scr_fua[i] > 0 then
          scr_fua[i] -= 1
          if (scr_fua[i] == 0) scr_act[i] = 1
        end
      end
    end
    i += 1
  end
  -- title screen activation
  if scr_on[1] == 1 and scr_act[1] == 1 and (btnp(1) or btnp(4)) then
    jb_sfx(24, 3)
    scr_act[1] = 0
    scr_slide_off(1, 1)
    title_activated()
  end
  -- victory screen -> credits
  if scr_on[3] == 1 and scr_act[3] == 1 and (btnp(1) or btnp(4)) then
    jb_sfx(24, 3)
    scr_act[3] = 0
    scr_slide_off(3, 1)
    scr_spawn(2, 192, 130)
    scr_slide[2] = 1
    scr_sf[2] = 0
    scr_ssx[2] = 192
    scr_act[2] = 2
  end
  -- credits -> title
  if scr_on[2] == 1 and scr_act[2] == 1 and (btnp(1) or btnp(4)) then
    jb_sfx(24, 3)
    scr_act[2] = 0
    scr_slide_off(2, 1)
    show_title_screen(1)
  end
  -- game over: retry or back to menu
  if scr_on[4] == 1 and scr_act[4] == 1 then
    if btnp(1) or btnp(4) then
      jb_sfx(9, 3)
      scr_act[4] = 0
      scr_slide_off(4, 1)
      ph_slide = 1
      ph_sf = 0
      ph_sx = ph_x
      fg_slide = 1
      fg_f = 0
      fg_ssx = fg_x
      retry_game()
    elseif btnp(0) then
      music_play(37)
      scr_act[4] = 0
      scr_slide_off(4, -1)
      ph_slide = -1
      ph_sf = 0
      ph_sx = ph_x
      fg_slide = -1
      fg_f = 0
      fg_ssx = fg_x
      wipe_gameplay()
      show_title_screen(-1)
    end
  end
end

function title_activated()
  music_play(0)
  jb_sfx(9, 3)
  score = 0
  timer_seconds = 0
  wipe_gameplay()
  start_game(0)
end

function retry_game()
  local ph = boss_phase
  score = 0
  if (ph <= 1) score = 40
  if (ph <= 1) timer_seconds = 0
  wipe_gameplay()
  start_game(ph)
end

-- remove every gameplay entity (the original resets its entities list)
function wipe_gameplay()
  palive = 0
  ref_on = 0
  boss_on = 0
  green_on = 0
  hat_on = 0
  is_paused = 0
  trans_lock = 0
  rA[1] = R_NONE
  rA[2] = R_NONE
  sA[1] = S_NONE
  sA[2] = S_NONE
  vA = 0
  dA = 0
  local i = 1
  while i <= 6 do
    hA[i] = H_NONE
    mvon[i] = 0
    i += 1
  end
  clear_boss_spawns()
  for tl in all(tiles) do
    del(tiles, tl)
  end
  for p in all(parts) do
    del(parts, p)
  end
  for s in all(streaks) do
    del(streaks, s)
  end
  for p in all(poofs) do
    del(poofs, p)
  end
  for b in all(bunnies) do
    del(bunnies, b)
  end
  for pt in all(points) do
    del(points, pt)
  end
  for h in all(hearts) do
    del(hearts, h)
  end
  bh_health = 0
  bh_vis = 0
  bh_dc = 0
  bh_rainbow = 0
  bdc = 0
  gdc = 0
  bhome_x = 40
  bcracked = 0
end

-- start_game(phase): curtain opening + spawn staging
function start_game(phase)
  sg_phase = phase
  sg_step = 1
  sg_wait = 35
  game_on = 0
end

function start_game_step()
  if (sg_step == 0) return
  if sg_wait > 0 then
    sg_wait -= 1
    return
  end
  if sg_step == 1 then
    cur_anim = 1
    cur_dc = 100
    sg_step = 2
    sg_wait = 0
  elseif sg_step == 2 then
    score_mult = 0
    boss_phase = max(0, sg_phase - 1)
    is_paused = 0
    -- spawn player + UI
    palive = 1
    px = 45
    py = 20
    pvx = 0
    pvy = 0
    pfacing = 0
    pstep_dir = 4
    pnext_dir = 4
    pstep_frames = 0
    pteeter = 0
    pbump = 0
    pstun = 0
    pinvinc = 0
    pfa = 0
    ph_hearts = 4
    ph_x = 63
    ph_y = 122
    ph_anim = 0
    ph_dc = 0
    ph_vis = 0
    ph_slide = 0
    ph_move = 0
    bh_health = 0
    bh_vis = 0
    if sg_phase > 0 then
      spawn_boss()
      avis[BB] = 1
      bh_vis = 1
      ph_vis = 1
      bhat = 0
      if (sg_phase > 1) bhat = 1
      if sg_phase > 3 then
        ref_on = 1
        rprev_col = rcol()
        rprev_row = prow()
      end
      sg_step = 3
      sg_wait = 30
    else
      spawn_magic_tile(150 + 30)
      sg_step = 0
      game_on = 1
    end
  elseif sg_step == 3 then
    boss_intro()
    sg_step = 0
    game_on = 1
  end
end
