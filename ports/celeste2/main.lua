-- celeste classic 2: lani's trek — gametank port
-- A hand-translation to gtlua of "Celeste Classic 2: Lani's Trek" by
-- ExOK Games — Maddy Thorson, Noel Berry, Lena Raine (music), Kevin
-- Regamey (sfx) — released CC-BY-NC-SA 4.0 at lexaloffle.com/bbs/?tid=41282.
-- This port (real logic, real levels, real sprite sheet) is released under
-- the same license: CC-BY-NC-SA 4.0. See LICENSE and PORT_NOTES.md for
-- every divergence from the original cart.
--
-- Controls: d-pad move, GT A (O) jump, GT B (X) grapple. Hold DOWN while
-- releasing GT B to set a carried object down gently.
--
-- Build:
--   node ports/celeste2/tools/gen.mjs        (regenerates data + sheet.bin)
--   node bin/gtlua.js build ports/celeste2/main.lua --sheet ports/celeste2/sheet.bin
--
-- The level maps are the cart's own px9-compressed data, re-encoded by
-- tools/gen.mjs as an LZSS stream that decodes in place inside the map
-- buffer (the GameTank has 7.4 KB of work RAM — see PORT_NOTES.md).

-- ---------------------------------------------------------------------------
-- game state
-- ---------------------------------------------------------------------------

local level_index = 0
local level_intro = 0
local outro = 0                 -- "to be continued" card (slice builds)
local frames = 0
local seconds = 0
local minutes = 0
local freeze_time = 0
local shake = 0
local sfx_timer = 0
local berry_count = 0
local death_count = 0
local show_score = 0
local infade = 0
local have_grapple = 0
local level_checkpoint = -1
local tflash = -1000            -- titlescreen_flash (nil -> -1000)
local l1_cue = 0                -- level 1 bridge music sting fired
local next_id = 1

-- level meta (set by load_meta)
local lvl_w = 16
local lvl_h = 16
local cam_mode = 1
local lvl_bg = 0
local lvl_cloudcol = 13
local lvl_title = 0             -- 0 none, 1 trailhead, 2 glacial, 3 golden, 4 destination
local lvl_right = 0
local cam_barx = -1
local cam_bary = -1

-- camera
local camera_x = 0
local camera_y = 0
local camera_target_x = 0
local camera_target_y = 0
local c_offset = 0
local c_flag = 0
local cam_draw_x = 0            -- camera actually used this frame (incl. shake)
local cam_draw_y = 0

-- input
local input_x = 0
local input_jump = 0
local input_jump_pressed = 0
local input_grapple = 0
local input_grapple_pressed = 0
local axis_x_value = 0
local axis_x_turned = 0

-- player
local p_x = 0
local p_y = 0
local p_spd_x = 0.0
local p_spd_y = 0.0
local p_rem_x = 0.0
local p_rem_y = 0.0
local p_facing = 1
local p_state = 0
local p_freeze = 0
local p_spr = 2.0
local p_on_ground = 0
local p_t_jump_grace = 0
local p_jump_grace_y = 0
local p_t_var_jump = 0
local p_var_jump_speed = 0.0
local p_auto_var_jump = 0
local p_grapple_x = 0
local p_grapple_y = 0
local p_grapple_dir = 0
local p_grapple_wave = 0.0
local p_grapple_boost = 0
local p_grapple_retract = 0
local p_t_grapple_cooldown = 0
local p_t_grapple_jump_grace = 0
local p_grapple_jump_grace_y = 0
local p_t_grapple_pickup = 0
local p_wipe_timer = 0
local p_holding = 0             -- id of carried object, 0 = none
local p_sb_id = 0               -- springboard ridden in state 2
local p_berry_id = -1           -- last berry grabbed
local p_ghit_kind = 0           -- 0 solid tile, 2 grappler, 3 crumble, 4 holdable
local p_ghit_id = 0
local p_ghit_tx = 0
local p_ghit_ty = 0
local p_ghit_sx = 0             -- grappler snap point
local p_ghit_sy = 0

-- grapple pickup (one per game, level 2)
local gp_x = 0
local gp_y = 0
local gp_live = 0

-- map: 2 tiles per int, row-major; tail doubles as LZ staging at load
local map = array(2048)
local fl = array(128)           -- sprite flags, tiles 0-127
local fl_pos = 1
local ld_pos = 1
local lz_len = 0

-- collected berries (persist across deaths/levels)
local collected = array(12)
local n_collected = 0

-- pools (capacities asserted against the level census by gen.mjs)
local holds = pool(10)          -- kn 1 = snowball, kn 2 = springboard
local crumbs = pool(20)
local berries = pool(6)
local bridges = pool(2)
local spawners = pool(5)

-- snow + clouds
local snow_x = array(26)
local snow_y = array(26, 0.5)
local cloud_x = array(12, 0.5)
local cloud_y = array(12)
local cloud_s = array(12)

-- player scarf (5 segments)
local scarf_x = array(5, 0.5)
local scarf_y = array(5, 0.5)

-- sfx: 4 channels, note-off timers + one queued follow-up note each
local sfx_t = array(4)
local sfxq_n = array(4)
local sfxq_d = array(4)
local sfxq_w = array(4)

-- object slide scratch (o_slide/o_cc results)
local st_x = 0
local st_y = 0
local st_hit = 0

-- ---------------------------------------------------------------------------
-- generated level + flag data (tools/gen.mjs splices between the markers)
-- ---------------------------------------------------------------------------

function fr(n, v)
  local k = 0
  while k < n do
    fl[fl_pos] = v
    fl_pos += 1
    k += 1
  end
end

function d16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)
  map[ld_pos] = a
  map[ld_pos + 1] = b
  map[ld_pos + 2] = c
  map[ld_pos + 3] = d
  map[ld_pos + 4] = e
  map[ld_pos + 5] = f
  map[ld_pos + 6] = g
  map[ld_pos + 7] = h
  map[ld_pos + 8] = i
  map[ld_pos + 9] = j
  map[ld_pos + 10] = k
  map[ld_pos + 11] = l
  map[ld_pos + 12] = m
  map[ld_pos + 13] = n
  map[ld_pos + 14] = o
  map[ld_pos + 15] = p
  ld_pos += 16
end

function d1(a)
  map[ld_pos] = a
  ld_pos += 1
end

-- ===== GENERATED DATA (tools/gen.mjs) =====
-- ===== END GENERATED DATA =====

-- ---------------------------------------------------------------------------
-- map access: bytes inside the packed int buffer
-- ---------------------------------------------------------------------------

function bget(i)
  local v = map[i \ 2 + 1]
  if i % 2 == 1 then
    return (v >> 8) & 255
  end
  return v & 255
end

function bset(i, b)
  local w = i \ 2 + 1
  local v = map[w]
  if i % 2 == 1 then
    map[w] = (v & 255) | (b << 8)
  else
    map[w] = (v & -256) | b
  end
end

function mget(tx, ty)
  if tx < 0 or ty < 0 or tx >= lvl_w or ty >= lvl_h then
    return 0
  end
  return bget(ty * lvl_w + tx)
end

function mset(tx, ty, v)
  if tx < 0 or ty < 0 or tx >= lvl_w or ty >= lvl_h then
    return
  end
  bset(ty * lvl_w + tx, v)
end

-- LZSS decode, in place: stream staged in the buffer tail by ld_dat(n)
function lz_unpack()
  local rp = (2048 - (lz_len + 1) \ 2) * 2
  local wp = 0
  local total = lvl_w * lvl_h
  while wp < total do
    local tk = bget(rp)
    rp += 1
    if tk >= 128 then
      local d = bget(rp) + ((tk >> 5) & 3) * 256 + 1
      rp += 1
      local len = (tk & 31) + 3
      local k = 0
      while k < len do
        bset(wp, bget(wp - d))
        wp += 1
        k += 1
      end
    else
      bset(wp, tk)
      wp += 1
    end
  end
end

-- flag helpers. tile 19 (crumble) is solid while present; 128 marks a
-- broken crumble (invisible, not solid, but "was solid" for spike facing).
function tile_solid(t)
  if t == 19 then return 1 end
  if t > 127 then return 0 end
  if (fl[t + 1] & 2) ~= 0 then return 1 end
  return 0
end

function tile_osolid(t)
  if t == 128 then return 1 end
  return tile_solid(t)
end

-- solid test for an inclusive pixel box. Rows clamp to the level (the
-- cart's tile_y behavior); columns fall off to empty.
function box_solid(x0, y0, x1, y1)
  local i = x0 \ 8
  local i1 = x1 \ 8
  local j0 = mid(0, y0 \ 8, lvl_h - 1)
  local j1 = mid(0, y1 \ 8, lvl_h - 1)
  while i <= i1 do
    local j = j0
    while j <= j1 do
      if tile_solid(mget(i, j)) == 1 then return 1 end
      j += 1
    end
    i += 1
  end
  return 0
end

function o_solid(x, y)
  return box_solid(x, y, x + 7, y + 7)
end

function id2(tx, ty)
  return level_index * 100 + tx + ty * 128
end

function is_collected(v)
  local k = 1
  while k <= n_collected do
    if collected[k] == v then return 1 end
    k += 1
  end
  return 0
end

-- ---------------------------------------------------------------------------
-- sfx approximation (the cart's tracker sfx/music are not portable; these
-- are single-osc blips on the audio coprocessor — see PORT_NOTES.md)
-- ---------------------------------------------------------------------------

function sfx_go(ch, note, dur)
  gt.note(ch, note, 100)
  sfx_t[ch + 1] = dur
end

-- gated by the cart's sfx_timer lock
function psfx(ch, note, dur)
  if sfx_timer <= 0 then
    sfx_go(ch, note, dur)
  end
end

function sfx_q(ch, note, dur, wait)
  sfxq_n[ch + 1] = note
  sfxq_d[ch + 1] = dur
  sfxq_w[ch + 1] = wait
end

function sfx_tick()
  local c = 1
  while c <= 4 do
    if sfx_t[c] > 0 then
      sfx_t[c] -= 1
      if sfx_t[c] == 0 then gt.noteoff(c - 1) end
    end
    if sfxq_w[c] > 0 then
      sfxq_w[c] -= 1
      if sfxq_w[c] == 0 then
        gt.note(c - 1, sfxq_n[c], 100)
        sfx_t[c] = sfxq_d[c]
      end
    end
    c += 1
  end
  if sfx_timer > 0 then sfx_timer -= 1 end
end

-- ---------------------------------------------------------------------------
-- pools: canonical add sites (one per pool keeps the frozen field set)
-- ---------------------------------------------------------------------------

function hold_add(kn2, x2, y2, vx, vy)
  add(holds, {kn = kn2, x = x2, y = y2, rx = 0, ry = 0, sx = vx, sy = vy,
              hp = 6, thr = 0, stp = 0, hld = 0, frz = 0, sp = 11, pl = 0,
              idv = next_id})
  next_id += 1
end

function crumb_add(tx2, ty2)
  add(crumbs, {tx = tx2, ty = ty2, tm = 0, brk = 0})
end

function berry_add(tx2, ty2)
  add(berries, {x = tx2 * 8, y = ty2 * 8, st = 0, tmr = 0, gnd = 0,
                fls = 0, idv = id2(tx2, ty2)})
end

function bridge_add(x2, y2)
  add(bridges, {x = x2, y = y2, fall = 0})
end

function spawn_add(x2, y2, dir)
  add(spawners, {x = x2, y = y2, tm = (x2 \ 8) % 32, dr = dir})
end

function clear_pools()
  for o in all(holds) do del(holds, o) end
  for o in all(crumbs) do del(crumbs, o) end
  for o in all(berries) do del(berries, o) end
  for o in all(bridges) do del(bridges, o) end
  for o in all(spawners) do del(spawners, o) end
end

-- ---------------------------------------------------------------------------
-- math + movement helpers
-- ---------------------------------------------------------------------------

function approach(x, target, d)
  if x < target then
    return min(x + d, target)
  end
  return max(x - d, target)
end

function iapproach(x, target, d)
  if x < target then
    return min(x + d, target)
  end
  return max(x - d, target)
end

-- slide an 8x8 object m pixels along one axis (dx,dy is the unit axis);
-- results in st_x/st_y, st_hit=1 if a solid stopped it
function o_slide(x, y, m, dx, dy)
  st_x = x
  st_y = y
  st_hit = 0
  if m == 0 then return end
  local s = sgn(m)
  while m ~= 0 do
    if o_solid(st_x + s * dx, st_y + s * dy) == 1 then
      st_hit = 1
      return
    end
    st_x += s * dx
    st_y += s * dy
    m -= s
  end
end

-- corner-correct an 8x8 object moving horizontally toward dir: try shifting
-- down (and up when only==0) 1..side pixels. Results in st_x/st_y.
function o_cc(x, y, dir, side, only)
  local i = 1
  while i <= side do
    if o_solid(x + dir, y + i) == 0 then
      st_x = x + dir
      st_y = y + i
      return 1
    end
    if only == 0 then
      if o_solid(x + dir, y - i) == 0 then
        st_x = x + dir
        st_y = y - i
        return 1
      end
    end
    i += 1
  end
  return 0
end

-- ---------------------------------------------------------------------------
-- input (the cart's update_input, verbatim semantics)
-- ---------------------------------------------------------------------------

function update_input()
  local prev_x = axis_x_value
  if btn(0) then
    if btn(1) then
      if axis_x_turned == 1 then
        axis_x_value = prev_x
        input_x = prev_x
      else
        axis_x_turned = 1
        axis_x_value = -prev_x
        input_x = -prev_x
      end
    else
      axis_x_turned = 0
      axis_x_value = -1
      input_x = -1
    end
  elseif btn(1) then
    axis_x_turned = 0
    axis_x_value = 1
    input_x = 1
  else
    axis_x_turned = 0
    axis_x_value = 0
    input_x = 0
  end

  local jump = 0
  if btn(4) then jump = 1 end
  if jump == 1 and input_jump == 0 then
    input_jump_pressed = 4
  elseif jump == 1 then
    input_jump_pressed = max(0, input_jump_pressed - 1)
  else
    input_jump_pressed = 0
  end
  input_jump = jump

  local grap = 0
  if btn(5) then grap = 1 end
  if grap == 1 and input_grapple == 0 then
    input_grapple_pressed = 4
  elseif grap == 1 then
    input_grapple_pressed = max(0, input_grapple_pressed - 1)
  else
    input_grapple_pressed = 0
  end
  input_grapple = grap
end

function consume_jump_press()
  local val = 0
  if input_jump_pressed > 0 then val = 1 end
  input_jump_pressed = 0
  return val
end

function consume_grapple_press()
  local val = 0
  if input_grapple_pressed > 0 then val = 1 end
  input_grapple_pressed = 0
  return val
end

-- ---------------------------------------------------------------------------
-- camera
-- ---------------------------------------------------------------------------

function cam_barrier(bx8, px2)
  if bx8 < 0 then return end
  local bx = bx8 * 8
  if px2 < bx - 8 then
    camera_target_x = min(camera_target_x, bx - 128)
  elseif px2 > bx + 8 then
    camera_target_x = max(camera_target_x, bx)
  end
end

function cam_update(px2, py2)
  if cam_mode == 1 then
    if px2 < 42 then
      camera_target_x = 0
    else
      camera_target_x = max(40, min(lvl_w * 8 - 128, px2 - 48))
    end
  elseif cam_mode == 2 then
    if px2 < 120 then
      camera_target_x = 0
    elseif px2 > 136 then
      camera_target_x = 128
    else
      camera_target_x = px2 - 64
    end
    camera_target_y = max(min(lvl_h * 8 - 128, py2 - 64))
  elseif cam_mode == 3 then
    camera_target_x = max(min(lvl_w * 8 - 128, px2 - 56))
    cam_barrier(cam_barx, px2)
    if py2 < cam_bary * 8 + 3 then
      camera_target_y = 0
    else
      camera_target_y = cam_bary * 8
    end
  elseif cam_mode == 4 then
    local ax = px2
    local ay = py2
    if ax % 128 > 8 and ax % 128 < 120 then ax = (ax \ 128) * 128 + 64 end
    if ay % 128 > 4 and ay % 128 < 124 then ay = (ay \ 128) * 128 + 64 end
    camera_target_x = max(min(lvl_w * 8 - 128, ax - 64))
    camera_target_y = max(min(lvl_h * 8 - 128, ay - 64))
  elseif cam_mode == 5 then
    camera_target_x = max(min(lvl_w * 8 - 128, px2 - 32))
  elseif cam_mode == 6 then
    if px2 > 848 then
      c_offset = 48
    elseif px2 < 704 then
      c_flag = 0
      c_offset = 32
    elseif px2 > 808 then
      c_flag = 1
      c_offset = 96
    end
    camera_target_x = max(min(lvl_w * 8 - 128, px2 - c_offset))
    cam_barrier(cam_barx, px2)
    if c_flag == 1 then camera_target_x = max(camera_target_x, 672) end
  elseif cam_mode == 7 then
    if px2 > 420 then
      if px2 < 436 then
        c_offset = 32 + px2 - 420
      elseif px2 > 808 then
        c_offset = 48 - min(16, px2 - 808)
      else
        c_offset = 48
      end
    else
      c_offset = 32
    end
    camera_target_x = max(0, min(lvl_w * 8 - 128, px2 - c_offset))
  elseif cam_mode == 8 then
    camera_target_y = max(0, min(lvl_h * 8 - 128, py2 - 32))
  end
end

-- ---------------------------------------------------------------------------
-- levels
-- ---------------------------------------------------------------------------

function load_meta(n)
  cam_mode = 1
  lvl_bg = 0
  lvl_cloudcol = 13
  lvl_title = 0
  lvl_right = 0
  cam_barx = -1
  cam_bary = -1
  if n == 2 then
    cam_mode = 2
    lvl_cloudcol = 0
  elseif n == 3 then
    cam_mode = 3
    cam_barx = 38
    cam_bary = 6
    lvl_title = 1
  elseif n == 4 then
    cam_mode = 4
    lvl_title = 2
  elseif n == 5 then
    cam_mode = 5
    lvl_title = 3
    lvl_bg = 13
    lvl_cloudcol = 15
  elseif n == 6 then
    cam_mode = 6
    cam_barx = 105
    lvl_bg = 13
    lvl_cloudcol = 15
  elseif n == 7 then
    cam_mode = 7
    lvl_bg = 13
    lvl_cloudcol = 7
  elseif n == 8 then
    cam_mode = 8
    lvl_title = 4
    lvl_bg = 15
    lvl_cloudcol = 7
    lvl_right = 1
  end
end

function load_level(n)
  level_index = n
  level_checkpoint = -1
  ld_dat(n)
  lz_unpack()
  load_meta(n)
  if lvl_title > 0 then
    level_intro = 60
  end
  if n == 2 then
    sfx_go(3, 72, 3)
    sfx_q(3, 79, 4, 4)
  end
  restart_level()
end

function next_level()
  if level_index + 1 > ship_levels then
    outro = 150
    level_index = -1
    return
  end
  load_level(level_index + 1)
end

function restart_level()
  camera_x = 0
  camera_y = 0
  camera_target_x = 0
  camera_target_y = 0
  c_offset = 0
  c_flag = 0
  clear_pools()
  gp_live = 0
  infade = 0
  if level_index > 2 then
    have_grapple = 1
  else
    have_grapple = 0
  end
  sfx_timer = 0
  local sx2 = 12
  local sy2 = 100
  local i = 0
  while i < lvl_w do
    local j = 0
    while j < lvl_h do
      local t = mget(i, j)
      if t == 128 then
        mset(i, j, 19)
        t = 19
      end
      if t == 2 then
        if level_checkpoint < 0 then
          sx2 = i * 8 + 4
          sy2 = j * 8 + 8
        end
      elseif t == 13 then
        if id2(i, j) == level_checkpoint then
          sx2 = i * 8 + 4
          sy2 = j * 8 + 8
        end
      elseif t == 11 then
        hold_add(2, i * 8, j * 8, 0, 0)
      elseif t == 14 then
        spawn_add(i * 8, j * 8, 1)
      elseif t == 15 then
        spawn_add(i * 8, j * 8, -1)
      elseif t == 19 then
        crumb_add(i, j)
      elseif t == 20 then
        gp_x = i * 8
        gp_y = j * 8
        gp_live = 1
      elseif t == 21 then
        if is_collected(id2(i, j)) == 0 then
          berry_add(i, j)
        end
      elseif t == 62 then
        hold_add(1, i * 8, j * 8, 0, 0)
      elseif t == 63 then
        bridge_add(i * 8, j * 8)
      end
      j += 1
    end
    i += 1
  end
  p_spawn(sx2, sy2)
end

function p_spawn(x2, y2)
  p_x = x2
  p_y = y2
  p_spd_x = 0
  p_spd_y = 0
  p_rem_x = 0
  p_rem_y = 0
  p_facing = 1
  p_state = 0
  p_freeze = 0
  p_spr = 2
  p_t_jump_grace = 0
  p_jump_grace_y = y2
  p_t_var_jump = 0
  p_auto_var_jump = 0
  p_grapple_retract = 0
  p_grapple_wave = 0
  p_grapple_boost = 0
  p_t_grapple_cooldown = 0
  p_t_grapple_jump_grace = 0
  p_t_grapple_pickup = 0
  p_wipe_timer = 0
  p_holding = 0
  p_sb_id = 0
  p_berry_id = -1
  p_ghit_kind = 0
  local k = 1
  while k <= 5 do
    scarf_x[k] = p_x
    scarf_y[k] = p_y
    k += 1
  end
  cam_update(p_x, p_y)
  camera_x = camera_target_x
  camera_y = camera_target_y
end

-- ---------------------------------------------------------------------------
-- player physics
-- ---------------------------------------------------------------------------

function p_check_solid(ox, oy)
  return box_solid(p_x + ox - 3, p_y + oy - 6, p_x + ox + 2, p_y + oy - 1)
end

-- spike hazard test for the player box at offset (ox, oy)
function p_hazard(ox, oy)
  local x0 = p_x + ox - 3
  local y0 = p_y + oy - 6
  local x1 = p_x + ox + 2
  local y1 = p_y + oy - 1
  local i = x0 \ 8
  local i1 = x1 \ 8
  while i <= i1 do
    local j = y0 \ 8
    local j1 = y1 \ 8
    while j <= j1 do
      local t = mget(i, j)
      if t == 36 then
        if tile_osolid(mget(i, j + 1)) == 1 then
          -- up spike: hurts falling players
          if p_spd_y >= 0 and y1 >= j * 8 + 5 and y0 <= j * 8 + 7 then return 1 end
        else
          -- down spike
          if p_spd_y <= 0 and y1 >= j * 8 and y0 <= j * 8 + 2 then return 1 end
        end
      elseif t == 37 then
        if tile_osolid(mget(i - 1, j)) == 1 then
          -- points right: hurts leftward movement
          if p_spd_x <= 0 and x1 >= i * 8 and x0 <= i * 8 + 2 then return 1 end
        else
          -- points left
          if p_spd_x >= 0 and x1 >= i * 8 + 5 and x0 <= i * 8 + 7 then return 1 end
        end
      end
      j += 1
    end
    i += 1
  end
  return 0
end

-- corner correction; refuses corrections into spikes (the cart's
-- correction_func). only_sign skips one probe direction.
function p_corner_correct(dir_x, dir_y, side_dist, only_sign)
  if dir_x ~= 0 then
    local i = 1
    while i <= side_dist do
      local s = 1
      while s >= -1 do
        if s ~= -only_sign then
          if p_check_solid(dir_x, i * s) == 0 and p_hazard(dir_x, i * s) == 0 then
            p_x += dir_x
            p_y += i * s
            return 1
          end
        end
        s -= 2
      end
      i += 1
    end
  elseif dir_y ~= 0 then
    local i = 1
    while i <= side_dist do
      local s = 1
      while s >= -1 do
        if s ~= -only_sign then
          if p_check_solid(i * s, dir_y) == 0 and p_hazard(i * s, dir_y) == 0 then
            p_x += i * s
            p_y += dir_y
            return 1
          end
        end
        s -= 2
      end
      i += 1
    end
  end
  return 0
end

-- move with the player's on_collide handlers; returns 1 on hard collision
function p_move_x(amount)
  p_rem_x += amount
  local mx = flr(p_rem_x + 0.5)
  p_rem_x -= mx
  local total = mx
  local mxs = sgn(mx)
  while mx ~= 0 do
    if p_check_solid(mxs, 0) == 1 then
      if p_state == 0 then
        if sgn(total) == input_x and p_corner_correct(input_x, 0, 2, -1) == 1 then
          return 0
        end
      elseif p_state == 11 then
        if p_corner_correct(p_grapple_dir, 0, 4, 0) == 1 then
          return 0
        end
      end
      p_rem_x = 0
      p_spd_x = 0
      return 1
    else
      p_x += mxs
      mx -= mxs
    end
  end
  return 0
end

function p_move_y(amount)
  p_rem_y += amount
  local my = flr(p_rem_y + 0.5)
  p_rem_y -= my
  local total = my
  local mys = sgn(my)
  while my ~= 0 do
    if p_check_solid(0, mys) == 1 then
      if total < 0 and p_corner_correct(0, -1, 2, input_x) == 1 then
        return 0
      end
      p_t_var_jump = 0
      p_rem_y = 0
      p_spd_y = 0
      return 1
    else
      p_y += mys
      my -= mys
    end
  end
  return 0
end

-- move without collide side effects (the cart's callback-less move calls)
function p_move_x_nc(amount)
  p_rem_x += amount
  local mx = flr(p_rem_x + 0.5)
  p_rem_x -= mx
  local mxs = sgn(mx)
  while mx ~= 0 do
    if p_check_solid(mxs, 0) == 1 then return end
    p_x += mxs
    mx -= mxs
  end
end

function p_move_y_nc(amount)
  p_rem_y += amount
  local my = flr(p_rem_y + 0.5)
  p_rem_y -= my
  local mys = sgn(my)
  while my ~= 0 do
    if p_check_solid(0, mys) == 1 then return end
    p_y += mys
    my -= mys
  end
end

-- ---------------------------------------------------------------------------
-- player actions
-- ---------------------------------------------------------------------------

function p_jump()
  consume_jump_press()
  p_state = 0
  p_spd_y = -4
  p_var_jump_speed = -4
  p_spd_x += input_x * 0.2
  p_t_var_jump = 4
  p_t_jump_grace = 0
  p_auto_var_jump = 0
  p_move_y_nc(p_jump_grace_y - p_y)
  psfx(0, 72, 2)
end

function p_bounce(bx, by)
  p_state = 0
  p_spd_y = -4
  p_var_jump_speed = -4
  p_t_var_jump = 4
  p_t_jump_grace = 0
  p_auto_var_jump = 1
  p_spd_x += sgn(p_x - bx) * 0.5
  p_move_y_nc(by - p_y)
end

function p_wall_jump(dir)
  consume_jump_press()
  p_state = 0
  p_spd_y = -3
  p_var_jump_speed = -3
  p_spd_x = 3 * dir
  p_t_var_jump = 4
  p_auto_var_jump = 0
  p_facing = dir
  p_move_x_nc(-dir * 3)
  psfx(0, 74, 2)
end

function p_grapple_jump()
  consume_jump_press()
  psfx(0, 76, 2)
  p_state = 0
  p_t_grapple_jump_grace = 0
  p_spd_y = -3
  p_var_jump_speed = -3
  p_t_var_jump = 4
  p_auto_var_jump = 0
  p_grapple_retract = 1
  if abs(p_spd_x) > 4 then
    p_spd_x = sgn(p_spd_x) * 4
  end
  p_move_y_nc(p_grapple_jump_grace_y - p_y)
end

function p_die()
  p_state = 99
  p_wipe_timer = 0
  freeze_time = 2
  shake = 5
  death_count += 1
  sfx_go(0, 45, 4)
  sfx_q(0, 38, 8, 5)
  sfx_timer = 40
end

-- grapple probe. returns 0 none, 1 hit, 2 fail; sets p_ghit_* on hit.
function p_grapple_check(gx, gy)
  local tyc = mid(0, gy \ 8, lvl_h - 1)
  local t = mget(gx \ 8, tyc)
  if tile_solid(t) == 1 then
    if t < 128 and (fl[t + 1] & 4) ~= 0 then return 2 end
    if t == 19 then
      p_ghit_kind = 3
      p_ghit_tx = gx \ 8
      p_ghit_ty = tyc
    else
      p_ghit_kind = 0
    end
    return 1
  end
  -- grapplers (tile 46): 10x10 box centered on the tile
  local i = (gx - 8) \ 8
  while i <= (gx + 1) \ 8 do
    local j = (gy - 8) \ 8
    while j <= (gy + 1) \ 8 do
      if mget(i, j) == 46 then
        if gx >= i * 8 - 1 and gx < i * 8 + 9 and gy >= j * 8 - 1 and gy < j * 8 + 9 then
          p_ghit_kind = 2
          p_ghit_sx = i * 8 + 4
          p_ghit_sy = j * 8 + 4
          return 1
        end
      end
      j += 1
    end
    i += 1
  end
  local hit = 0
  for o in all(holds) do
    if hit == 0 and gx >= o.x and gx < o.x + 8 then
      local ok = 0
      if o.kn == 1 then
        -- snowball contains: y-1 .. y+9
        if gy >= o.y - 1 and gy < o.y + 10 then ok = 1 end
      else
        if gy >= o.y and gy < o.y + 8 then ok = 1 end
      end
      if ok == 1 then
        p_ghit_kind = 4
        p_ghit_id = o.idv
        hit = 1
      end
    end
  end
  if hit == 1 then return 1 end
  return 0
end

function p_start_grapple()
  p_state = 10
  p_spd_x = 0
  p_spd_y = 0
  p_rem_x = 0
  p_rem_y = 0
  p_grapple_x = p_x
  p_grapple_y = p_y - 3
  p_grapple_wave = 0
  p_grapple_retract = 0
  p_t_grapple_cooldown = 6
  p_t_var_jump = 0
  if input_x ~= 0 then
    p_grapple_dir = input_x
  else
    p_grapple_dir = p_facing
  end
  p_facing = p_grapple_dir
  psfx(0, 64, 2)
end

function ghit_destroyed()
  if p_ghit_kind == 3 then
    if mget(p_ghit_tx, p_ghit_ty) ~= 19 then return 1 end
  end
  return 0
end

-- release a held/pulled object with the given throw velocity
function hold_release(idv, vx, vy, gentle)
  for o in all(holds) do
    if o.idv == idv then
      o.hld = 0
      o.sx = vx
      o.sy = vy
      if o.kn == 1 then
        if gentle == 1 then o.stp = 1 end
        o.thr = 8
      else
        if gentle == 0 then o.thr = 5 end
      end
    end
  end
  psfx(0, 62, 2)
end

-- state 1: lifting a grabbed holdable up to carry position
function p_state1()
  local found = 0
  for o in all(holds) do
    if o.idv == p_ghit_id then
      found = 1
      o.x = iapproach(o.x, p_x - 4, 4)
      o.y = iapproach(o.y, p_y - 14, 4)
      if o.x == p_x - 4 and o.y == p_y - 14 then
        p_state = 0
        p_holding = o.idv
      end
    end
  end
  if found == 0 then
    p_state = 0
    p_grapple_retract = 1
  end
end

-- state 2: riding a springboard down to the launch point
function p_state2()
  local found = 0
  for o in all(holds) do
    if o.idv == p_sb_id then
      found = 1
      local at_x = approach(p_x, o.x + 4, 0.5)
      p_move_x(at_x - p_x)
      local at_y = approach(p_y, o.y + 4, 0.2)
      p_move_y(at_y - p_y)
      if o.sp == 11 and p_y >= o.y + 2 then
        o.sp = 12
      elseif p_y == o.y + 4 then
        -- spring launch
        consume_jump_press()
        if input_jump == 1 then
          psfx(0, 81, 3)
        else
          psfx(0, 79, 2)
        end
        p_state = 0
        p_spd_y = -5
        p_var_jump_speed = -5
        p_t_var_jump = 6
        p_t_jump_grace = 0
        p_rem_y = 0
        p_auto_var_jump = 0
        o.pl = 0
        o.sp = 11
        for c in all(crumbs) do
          if c.brk == 0 then
            if o.x <= c.tx * 8 + 7 and o.x + 7 >= c.tx * 8 and
               o.y + 4 <= c.ty * 8 + 7 and o.y + 11 >= c.ty * 8 then
              c.brk = 1
              c.tm = 0
              psfx(2, 45, 2)
            end
          end
        end
      end
    end
  end
  if found == 0 then
    p_state = 0
  end
end

-- state 12: pulling a holdable in with the grapple
function p_state12()
  local found = 0
  for o in all(holds) do
    if o.idv == p_ghit_id then
      found = 1
      local done = 0
      local amt = -p_grapple_dir * 6
      o.rx += amt
      local mx = flr(o.rx + 0.5)
      o.rx -= mx
      o_slide(o.x, o.y, mx, 1, 0)
      o.x = st_x
      o.y = st_y
      if st_hit == 1 then
        if o_cc(o.x, o.y, sgn(amt), 4, 0) == 1 then
          o.x = st_x
          o.y = st_y
        else
          o.rx = 0
          p_state = 0
          p_grapple_retract = 1
          hold_release(o.idv, -p_grapple_dir, 0, 0)
          done = 1
        end
      end
      if done == 0 then
        p_grapple_x = iapproach(p_grapple_x, p_x, 6)
        if o.y ~= p_y - 7 then
          o.ry += sgn(p_y - o.y - 7) * 0.5
          local my = flr(o.ry + 0.5)
          o.ry -= my
          o_slide(o.x, o.y, my, 0, 1)
          o.x = st_x
          o.y = st_y
        end
        p_grapple_wave = approach(p_grapple_wave, 0, 0.6)
        if o.x + 7 >= p_x - 3 and o.x <= p_x + 2 and
           o.y + 7 >= p_y - 6 and o.y <= p_y - 1 then
          p_state = 1
          psfx(0, 70, 2)
        elseif input_grapple == 0 or abs(o.y - p_y + 7) > 8 or
               sgn(o.x + 4 - p_x) == -p_grapple_dir then
          p_state = 0
          p_grapple_retract = 1
          hold_release(o.idv, -p_grapple_dir * 5, 0, 0)
        end
      end
    end
  end
  if found == 0 then
    p_state = 0
    p_grapple_retract = 1
  end
end

-- throw / set down the held object (state 0, grapple button released)
function p_throw_hold()
  for o in all(holds) do
    if o.idv == p_holding then
      if o_solid(o.x, o.y - 2) == 0 then
        o.y -= 2
        p_holding = 0
        if btn(3) then
          hold_release(o.idv, 2 * p_facing, 0, 1)
        else
          hold_release(o.idv, 4 * p_facing, -1, 0)
        end
      end
    end
  end
end

-- keep the held object at the carry position (after movement applies)
function p_hold_apply()
  for o in all(holds) do
    if o.idv == p_holding then
      o.x = p_x - 4
      o.y = p_y - 14
    end
  end
end

-- ---------------------------------------------------------------------------
-- player interactions with objects; returns 1 if the update aborts
-- ---------------------------------------------------------------------------

-- player box vs an 8x8 object box at (bx, by), player offset (ox, oy)
function p_overlaps(bx, by, ox, oy)
  if p_x + ox - 3 > bx + 7 then return 0 end
  if bx > p_x + ox + 2 then return 0 end
  if p_y + oy - 6 > by + 7 then return 0 end
  if by > p_y + oy - 1 then return 0 end
  return 1
end

function p_interactions()
  -- grapple pickup
  if gp_live == 1 then
    if p_overlaps(gp_x, gp_y, 0, 0) == 1 then
      gp_live = 0
      have_grapple = 1
      p_state = 50
      p_t_grapple_pickup = 0
      sfx_go(1, 80, 3)
      sfx_q(1, 87, 5, 4)
    end
  end

  -- falling bridge tiles
  for o in all(bridges) do
    if o.fall == 0 and p_overlaps(o.x, o.y, 0, 0) == 1 then
      o.fall = 1
      p_freeze = 1
      shake = 2
      psfx(2, 41, 4)
    end
  end

  -- holdables: snowball bounce / kill, springboard mount
  local died = 0
  for o in all(holds) do
    if o.hld == 0 and died == 0 then
      if o.kn == 1 then
        local hit = 0
        if p_spd_y >= 0 and p_y - p_spd_y < o.y + o.sy + 4 then
          -- moving snowballs get a widened bounce box
          local bx0 = o.x
          local bx1 = o.x + 7
          if o.sx ~= 0 then
            bx0 = o.x - 2
            bx1 = o.x + 9
          end
          if p_x - 3 <= bx1 and bx0 <= p_x + 2 and
             p_y - 6 <= o.y + 7 and o.y <= p_y - 1 then
            hit = 1
          end
        end
        if hit == 1 then
          p_bounce(o.x + 4, o.y)
          psfx(0, 76, 2)
          o.frz = 1
          o.sy = -1
          o.hp -= 1
          if o.hp <= 0 then
            psfx(2, 50, 2)
            del(holds, o)
          end
        elseif o.sx ~= 0 and o.thr <= 0 and p_overlaps(o.x, o.y, 0, 0) == 1 then
          p_die()
          died = 1
        end
      else
        if p_state ~= 2 and p_overlaps(o.x, o.y, 0, 0) == 1 and
           p_spd_y >= 0 and p_y - p_spd_y < o.y + o.sy + 4 then
          p_state = 2
          p_spd_x = 0
          p_spd_y = 0
          p_t_jump_grace = 0
          p_sb_id = o.idv
          p_rem_y = 0
          o.pl = 1
          p_move_y(o.y + 4 - p_y)
        end
      end
    end
  end
  if died == 1 then return 1 end

  -- berries
  for o in all(berries) do
    if o.st == 0 and p_overlaps(o.x, o.y, 0, 0) == 1 then
      o.st = 1
      o.fls = 5
      o.gnd = 0
      p_berry_id = o.idv
      sfx_go(1, 81, 2)
    end
  end

  -- crumbles: break on stand / on grapple contact
  for o in all(crumbs) do
    if o.brk == 0 then
      local cx0 = o.tx * 8
      local cy0 = o.ty * 8
      local hitit = 0
      if p_state == 0 then
        if p_overlaps(cx0, cy0, 0, 1) == 1 then hitit = 1 end
      elseif p_state == 11 then
        if p_overlaps(cx0, cy0, p_grapple_dir, 0) == 1 then hitit = 1 end
        if p_overlaps(cx0, cy0, p_grapple_dir, 3) == 1 then hitit = 1 end
        if p_overlaps(cx0, cy0, p_grapple_dir, -2) == 1 then hitit = 1 end
      end
      if hitit == 1 then
        o.brk = 1
        o.tm = 0
        psfx(2, 45, 2)
      end
    end
  end

  -- checkpoints (from the map)
  local i = (p_x - 3) \ 8
  while i <= (p_x + 2) \ 8 do
    local j = (p_y - 6) \ 8
    while j <= (p_y - 1) \ 8 do
      if mget(i, j) == 13 then
        if id2(i, j) ~= level_checkpoint then
          level_checkpoint = id2(i, j)
          sfx_go(1, 77, 2)
          sfx_q(1, 84, 3, 3)
          sfx_timer = 20
        end
      end
      j += 1
    end
    i += 1
  end
  return 0
end

-- ---------------------------------------------------------------------------
-- player update
-- ---------------------------------------------------------------------------

function p_update()
  p_on_ground = p_check_solid(0, 1)
  if p_on_ground == 1 then
    p_t_jump_grace = 4
    p_jump_grace_y = p_y
  else
    p_t_jump_grace = max(0, p_t_jump_grace - 1)
  end

  p_t_grapple_jump_grace = max(0, p_t_grapple_jump_grace - 1)

  if p_t_grapple_cooldown > 0 and p_state < 1 then
    p_t_grapple_cooldown -= 1
  end

  if p_grapple_retract == 1 then
    p_grapple_x = iapproach(p_grapple_x, p_x, 12)
    p_grapple_y = iapproach(p_grapple_y, p_y - 3, 6)
    if p_grapple_x == p_x and p_grapple_y == p_y - 3 then
      p_grapple_retract = 0
    end
  end

  if p_state == 0 then
    -- normal
    if input_x ~= 0 then
      p_facing = input_x
    end

    local target = 0
    local accel = 0.2
    if abs(p_spd_x) > 2 and input_x == sgn(p_spd_x) then
      target = 2
      accel = 0.1
    elseif p_on_ground == 1 then
      target = 2
      accel = 0.8
    elseif input_x ~= 0 then
      target = 2
      accel = 0.4
    end
    p_spd_x = approach(p_spd_x, input_x * target, accel)

    if p_on_ground == 0 then
      local mx2 = 4.4
      if btn(3) then mx2 = 5.2 end
      if abs(p_spd_y) < 0.2 and input_jump == 1 then
        p_spd_y = min(p_spd_y + 0.4, mx2)
      else
        p_spd_y = min(p_spd_y + 0.8, mx2)
      end
    end

    if p_t_var_jump > 0 then
      if input_jump == 1 or p_auto_var_jump == 1 then
        p_spd_y = p_var_jump_speed
        p_t_var_jump -= 1
      else
        p_t_var_jump = 0
      end
    end

    if input_jump_pressed > 0 then
      if p_t_jump_grace > 0 then
        p_jump()
      elseif p_check_solid(2, 0) == 1 then
        p_wall_jump(-1)
      elseif p_check_solid(-2, 0) == 1 then
        p_wall_jump(1)
      elseif p_t_grapple_jump_grace > 0 then
        p_grapple_jump()
      end
    end

    if p_holding ~= 0 and input_grapple == 0 then
      p_throw_hold()
    end

    if have_grapple == 1 and p_holding == 0 and p_t_grapple_cooldown <= 0 then
      if consume_grapple_press() == 1 then
        p_start_grapple()
      end
    end

  elseif p_state == 1 then
    p_state1()

  elseif p_state == 2 then
    p_state2()

  elseif p_state == 10 then
    -- grapple flying out
    local amount = min(64 - abs(p_grapple_x - p_x), 6)
    local grabbed = 0
    local i = 1
    while i <= amount do
      local hit = p_grapple_check(p_grapple_x + p_grapple_dir, p_grapple_y)
      if hit == 0 then
        hit = p_grapple_check(p_grapple_x + p_grapple_dir, p_grapple_y - 1)
      end
      if hit == 0 then
        hit = p_grapple_check(p_grapple_x + p_grapple_dir, p_grapple_y + 1)
      end

      if hit == 0 then
        p_grapple_x += p_grapple_dir * 2
      elseif hit == 1 then
        if p_ghit_kind == 2 then
          p_grapple_x = p_ghit_sx
          p_grapple_y = p_ghit_sy
        end
        if p_ghit_kind == 4 then
          for o in all(holds) do
            if o.idv == p_ghit_id then o.hld = 1 end
          end
          grabbed = 1
          p_state = 12
        else
          p_state = 11
        end
        p_grapple_wave = 2
        p_grapple_boost = 0
        p_freeze = 2
        psfx(0, 68, 3)
        break
      end

      if hit == 2 or (hit == 0 and abs(p_grapple_x - p_x) >= 64) then
        psfx(0, 58, 3)
        p_grapple_retract = 1
        p_freeze = 2
        p_state = 0
        break
      end
      i += 1
    end

    p_grapple_wave = approach(p_grapple_wave, 1, 0.2)
    p_spr = 3

    if grabbed == 0 and p_state == 10 then
      if input_grapple == 0 or abs(p_y - p_grapple_y) > 8 then
        p_state = 0
        p_grapple_retract = 1
      end
    end

  elseif p_state == 11 then
    -- grapple attached to solid
    if p_grapple_boost == 0 then
      p_grapple_boost = 1
      p_spd_x = p_grapple_dir * 8
    end

    p_spd_x = approach(p_spd_x, p_grapple_dir * 5, 0.25)
    p_spd_y = approach(p_spd_y, 0, 0.4)

    if p_spd_y == 0 then
      if p_y - 3 > p_grapple_y then
        p_move_y_nc(-0.5)
      elseif p_y - 3 < p_grapple_y then
        p_move_y_nc(0.5)
      end
    end

    if p_spr ~= 4 and p_check_solid(p_grapple_dir, 0) == 1 then
      p_spr = 4
      psfx(0, 66, 2)
    end

    if consume_jump_press() == 1 then
      if p_check_solid(p_grapple_dir * 2, 0) == 1 then
        p_wall_jump(-p_grapple_dir)
      else
        p_grapple_jump_grace_y = p_y
        p_grapple_jump()
      end
    end

    p_grapple_wave = approach(p_grapple_wave, 0, 0.6)

    if input_grapple == 0 or ghit_destroyed() == 1 then
      p_state = 0
      p_t_grapple_jump_grace = 4
      p_grapple_jump_grace_y = p_y
      p_grapple_retract = 1
      p_facing = -p_facing
      if abs(p_spd_x) > 5 then
        p_spd_x = sgn(p_spd_x) * 5
      elseif abs(p_spd_x) <= 0.5 then
        p_spd_x = 0
      end
    end

    if p_state == 11 and sgn(p_x - p_grapple_x) == p_grapple_dir then
      p_state = 0
      if p_ghit_kind == 2 then
        p_t_grapple_jump_grace = 4
        p_grapple_jump_grace_y = p_y
      end
      if abs(p_spd_x) > 5 then
        p_spd_x = sgn(p_spd_x) * 5
      end
    end

  elseif p_state == 12 then
    p_state12()

  elseif p_state == 50 then
    -- grapple pickup celebration
    p_spd_y = min(p_spd_y + 0.8, 4.5)
    p_spd_x = approach(p_spd_x, 0, 0.2)
    if p_on_ground == 1 then
      if p_t_grapple_pickup > 80 then p_state = 0 end
      p_t_grapple_pickup += 1
    end

  elseif p_state == 99 or p_state == 100 then
    if p_state == 100 then
      p_x += 1
      if p_wipe_timer == 5 and level_index > 1 then
        sfx_go(3, 84, 4)
        sfx_q(3, 88, 5, 5)
      end
    end
    p_wipe_timer += 1
    if p_wipe_timer > 20 then
      if p_state == 99 then
        restart_level()
      else
        next_level()
      end
    end
    return
  end

  -- apply movement
  p_move_x(p_spd_x)
  p_move_y(p_spd_y)

  p_hold_apply()

  -- sprite selection
  if p_state == 50 and p_t_grapple_pickup > 0 then
    p_spr = 5
  elseif p_state ~= 11 then
    if p_on_ground == 0 then
      p_spr = 3
    elseif input_x ~= 0 then
      p_spr += 0.25
      p_spr = 2 + p_spr % 2
    else
      p_spr = 2
    end
  end

  if p_interactions() == 1 then return end

  -- death
  if p_state < 99 and (p_y > lvl_h * 8 + 16 or p_hazard(0, 0) == 1) then
    if level_index == 1 and p_x > lvl_w * 8 - 64 then
      p_state = 100
      p_wipe_timer = -15
    else
      p_die()
    end
    return
  end

  -- bounds
  if p_y < -16 then
    p_y = -16
    p_spd_y = 0
  end
  if p_x < 3 then
    p_x = 3
    p_spd_x = 0
  elseif p_x > lvl_w * 8 - 3 then
    if lvl_right == 1 then
      p_x = lvl_w * 8 - 3
      p_spd_x = 0
    else
      p_state = 100
    end
  end

  -- level 1 bridge sting (stands in for the music change)
  if level_index == 1 and l1_cue == 0 and p_x > 488 then
    l1_cue = 1
    sfx_go(3, 74, 4)
    sfx_q(3, 81, 6, 5)
  end

  -- ending
  if level_index == 8 then
    if p_y > 376 then show_score += 1 end
  end

  -- camera
  cam_update(p_x, p_y)
  camera_x = iapproach(camera_x, camera_target_x, 5)
  camera_y = iapproach(camera_y, camera_target_y, 5)
end

-- ---------------------------------------------------------------------------
-- object updates
-- ---------------------------------------------------------------------------

function holds_update()
  for o in all(holds) do
    if o.frz > 0 then
      o.frz -= 1
    elseif o.hld == 0 then
      o.thr -= 1

      -- speeds
      if o.kn == 1 then
        if o.stp == 1 then
          o.sx = approach(o.sx, 0, 0.25)
          if o.sx == 0 then o.stp = 0 end
        elseif o.sx ~= 0 then
          o.sx = approach(o.sx, sgn(o.sx) * 2, 0.1)
        end
        if o_solid(o.x, o.y + 1) == 0 then
          o.sy = approach(o.sy, 4, 0.4)
        end
      else
        if o_solid(o.x, o.y + 1) == 1 then
          o.sx = approach(o.sx, 0, 1)
        else
          o.sx = approach(o.sx, 0, 0.2)
          o.sy = approach(o.sy, 4, 0.4)
        end
      end

      -- x axis
      local dead = 0
      o.rx += o.sx
      local mx = flr(o.rx + 0.5)
      o.rx -= mx
      o_slide(o.x, o.y, mx, 1, 0)
      o.x = st_x
      o.y = st_y
      if st_hit == 1 then
        if o.kn == 1 then
          if o_cc(o.x, o.y, sgn(mx), 2, 1) == 1 then
            o.x = st_x
            o.y = st_y
          else
            o.hp -= 1
            if o.hp <= 0 then
              psfx(2, 50, 2)
              dead = 1
            else
              o.sx = -o.sx
              o.rx = 0
              o.frz = 1
              psfx(2, 55, 2)
            end
          end
        else
          o.sx *= -0.2
          o.rx = 0
          o.frz = 1
        end
      end

      if dead == 0 then
        -- y axis
        o.ry += o.sy
        local my = flr(o.ry + 0.5)
        o.ry -= my
        o_slide(o.x, o.y, my, 0, 1)
        o.x = st_x
        o.y = st_y
        if st_hit == 1 then
          if o.sy < 0 then
            o.sy = 0
          elseif o.kn == 1 then
            if o.sy >= 4 then
              o.sy = -2
              psfx(2, 55, 2)
            elseif o.sy >= 1 then
              o.sy = -1
              psfx(2, 55, 2)
            else
              o.sy = 0
            end
          else
            if o.sy >= 2 then
              o.sy *= -0.4
            else
              o.sy = 0
            end
            o.sx *= 0.5
          end
          o.ry = 0
        end

        if o.kn == 2 and o.pl == 1 then
          p_move_y_nc(o.sy)
        end

        if o.y > lvl_h * 8 + 24 then
          dead = 1
        end
      end

      if dead == 1 then
        del(holds, o)
      end
    end
  end
end

function bridges_update()
  for o in all(bridges) do
    if o.fall == 1 and o.y < lvl_h * 8 + 32 then
      o.y += 3
    end
  end
end

function crumbs_update()
  for o in all(crumbs) do
    if o.brk == 1 then
      o.tm += 1
      if o.tm == 11 then
        mset(o.tx, o.ty, 128)
      end
      if o.tm > 90 then
        -- respawn only when nothing overlaps the tile
        local blocked = 0
        local cx0 = o.tx * 8
        local cy0 = o.ty * 8
        if p_state < 99 and p_overlaps(cx0, cy0, 0, 0) == 1 then
          blocked = 1
        end
        for s in all(holds) do
          if s.x <= cx0 + 7 and s.x + 7 >= cx0 and s.y <= cy0 + 7 and s.y + 7 >= cy0 then
            blocked = 1
          end
        end
        for s in all(berries) do
          if s.x <= cx0 + 7 and s.x + 7 >= cx0 and s.y <= cy0 + 7 and s.y + 7 >= cy0 then
            blocked = 1
          end
        end
        if blocked == 0 then
          o.brk = 0
          o.tm = 0
          mset(o.tx, o.ty, 19)
          psfx(2, 57, 2)
        end
      end
    end
  end
end

function spawners_update()
  for o in all(spawners) do
    o.tm += 1
    if o.tm >= 32 and abs(o.x - 64 - camera_x) < 128 then
      o.tm = 0
      hold_add(1, o.x, o.y - 8, o.dr * 2, 4)
      psfx(2, 57, 2)
    end
  end
end

function berries_update()
  for o in all(berries) do
    if o.st == 2 then
      o.tmr += 1
      if o.tmr > 5 then
        o.y -= 0.2
      end
      if o.tmr > 30 then
        del(berries, o)
      end
    elseif o.st == 1 then
      o.x += (p_x - o.x) / 8
      o.y += (p_y - 4 - o.y) / 8
      o.fls -= 1

      if p_on_ground == 1 and p_state ~= 99 then
        o.gnd += 1
      else
        o.gnd = 0
      end

      if o.gnd > 3 or p_x > lvl_w * 8 - 7 or p_berry_id ~= o.idv then
        if n_collected < 12 then
          n_collected += 1
          collected[n_collected] = o.idv
        end
        berry_count += 1
        o.st = 2
        o.tmr = 0
        sfx_go(1, 84, 3)
        sfx_q(1, 89, 4, 3)
        sfx_timer = 20
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- drawing
-- ---------------------------------------------------------------------------

function draw_checkpoint(i, j)
  spr(13, i * 8, j * 8)
  if id2(i, j) == level_checkpoint then
    -- active: waving green flag (the cart re-colors + sine-waves the pole)
    local w = flr(sin(time() * 2) * 1.5)
    rectfill(i * 8 + 2, j * 8 + 1 + w, i * 8 + 6, j * 8 + 3 + w, 11)
  end
end

function draw_tiles()
  local i0 = mid(0, camera_x \ 8, lvl_w - 1)
  local i1 = mid(0, (camera_x + 128) \ 8, lvl_w - 1)
  local j0 = mid(0, camera_y \ 8, lvl_h - 1)
  local j1 = mid(0, (camera_y + 128) \ 8, lvl_h - 1)
  local j = j0
  while j <= j1 do
    local rowb = j * lvl_w
    local i = i0
    while i <= i1 do
      local t = bget(rowb + i)
      if t ~= 0 and t < 128 then
        local f = fl[t + 1]
        if (f & 1) ~= 0 then
          spr(t, i * 8, j * 8)
        elseif t == 36 then
          if tile_osolid(mget(i, j + 1)) == 1 then
            spr(36, i * 8, j * 8)
          else
            spr(164, i * 8, j * 8)
          end
        elseif t == 37 then
          if tile_osolid(mget(i - 1, j)) == 1 then
            spr(165, i * 8, j * 8)
          else
            spr(37, i * 8, j * 8)
          end
        elseif t == 46 then
          spr(46, i * 8, j * 8)
        elseif t == 13 then
          draw_checkpoint(i, j)
        end
      end
      i += 1
    end
    j += 1
  end
end

function draw_snow()
  local i = 1
  while i <= 26 do
    circfill(cam_draw_x + (snow_x[i] - cam_draw_x * 0.5) % 132 - 2,
             cam_draw_y + (snow_y[i] - cam_draw_y * 0.5) % 132,
             i % 2, 7)
    snow_x[i] += 4 - i % 4
    snow_y[i] += sin(time() * 0.25 + i * 0.1)
    i += 1
  end
end

function draw_clouds()
  if lvl_cloudcol == lvl_bg then return end
  local i = 1
  while i <= 12 do
    local s = cloud_s[i]
    local x = cam_draw_x + (cloud_x[i] - cam_draw_x * 0.9) % (128 + s) - s \ 2
    local y = cam_draw_y + cloud_y[i] % (128 + s \ 2)
    rectfill(x - s \ 2, y - s \ 8, x + s \ 2, y + s \ 8, lvl_cloudcol)
    rectfill(x - s \ 4, y - s \ 4, x + s \ 4, y, lvl_cloudcol)
    cloud_x[i] += (4 - i % 4) * 0.25
    i += 1
  end
end

function print2(v, x, y)
  print(v \ 10, x, y, 7)
  print(v % 10, x + 4, y, 7)
end

function draw_time(x, y)
  rectfill(x, y, x + 32, y + 6, 0)
  print2(minutes \ 60, x + 1, y + 1)
  print(":", x + 9, y + 1, 7)
  print2(minutes % 60, x + 13, y + 1)
  print(":", x + 21, y + 1, 7)
  print2(seconds, x + 25, y + 1)
end

-- grapple rope: 8px segments of the cart's per-pixel sine wave
function draw_rope()
  local x0 = p_x
  local y = p_y - 3
  local amp = 2 * p_grapple_wave
  local dir = sgn(p_grapple_x - x0)
  local lastx = x0
  local lasty = y + 0.0
  local i = 8
  local n = abs(p_grapple_x - x0)
  while i <= n do
    local ax = x0 + i * dir
    local ay = y + sin(time() * 6 + i * 0.08) * amp
    line(lastx, lasty, ax, ay, 7)
    lastx = ax
    lasty = ay
    i += 8
  end
  line(lastx, lasty, p_grapple_x, y, 7)
end

function p_draw()
  -- death poof
  if p_state == 99 then
    local e = p_wipe_timer / 10
    local dx = mid(cam_draw_x, p_x, cam_draw_x + 128)
    local dy = mid(cam_draw_y, p_y - 4, cam_draw_y + 128)
    if e <= 1 then
      local i = 0
      while i <= 7 do
        circfill(dx + cos(i / 8) * 32 * e, dy + sin(i / 8) * 32 * e, (1 - e) * 8, 10)
        i += 1
      end
    end
    return
  end

  -- scarf (axis-clamped instead of the cart's sqrt normalize)
  local lx = p_x - p_facing + 0.0
  local ly = p_y - 3 + 0.0
  local i = 1
  while i <= 5 do
    scarf_x[i] += (lx - scarf_x[i] - p_facing) / 1.5
    scarf_y[i] += ((ly - scarf_y[i]) + sin(i * 0.25 + time()) * i * 0.25) / 2
    scarf_x[i] = lx + mid(-1.5, scarf_x[i] - lx, 1.5)
    scarf_y[i] = ly + mid(-1.5, scarf_y[i] - ly, 1.5)
    rectfill(scarf_x[i], scarf_y[i], scarf_x[i], scarf_y[i], 10)
    rectfill((scarf_x[i] + lx) / 2, (scarf_y[i] + ly) / 2,
             (scarf_x[i] + lx) / 2, (scarf_y[i] + ly) / 2, 10)
    lx = scarf_x[i]
    ly = scarf_y[i]
    i += 1
  end

  -- grapple
  if p_state >= 10 and p_state <= 12 then
    draw_rope()
  end
  if p_grapple_retract == 1 then
    line(p_x, p_y - 2, p_grapple_x, p_grapple_y + 1, 1)
    line(p_x, p_y - 3, p_grapple_x, p_grapple_y, 7)
  end

  -- sprite (flipped variants live at n+128 on the sheet)
  local n = flr(p_spr)
  if p_facing == 1 then
    spr(n, p_x - 4, p_y - 8)
  else
    spr(n + 128, p_x - 4, p_y - 8)
  end

  -- grapple pickup celebration
  if p_state == 50 and p_t_grapple_pickup > 0 then
    spr(20, p_x - 4, p_y - 18)
    local k = 0
    while k <= 7 do
      local s = sin(time() * 4 + k / 8)
      local c = cos(time() * 4 + k / 8)
      local ty = p_y - 14
      line(p_x + s * 16, ty + c * 16, p_x + s * 40, ty + c * 40, 7)
      k += 1
    end
  end
end

function draw_objects()
  for o in all(bridges) do
    spr(63, o.x, o.y)
  end

  for o in all(crumbs) do
    if o.brk == 0 or o.tm <= 10 then
      spr(19, o.tx * 8, o.ty * 8)
      if o.brk == 1 and o.tm > 2 then
        rect(o.tx * 8, o.ty * 8, o.tx * 8 + 7, o.ty * 8 + 7, 1)
      end
    end
  end

  for o in all(holds) do
    if o.kn == 1 then
      spr(62, o.x, o.y)
    else
      spr(o.sp, o.x, o.y)
    end
  end

  for o in all(berries) do
    if o.st == 2 and o.tmr >= 5 then
      print("1000", o.x - 4, o.y + 1, 8)
      if o.tmr % 4 < 2 then
        print("1000", o.x - 4, o.y, 7)
      else
        print("1000", o.x - 4, o.y, 14)
      end
    else
      spr(21, o.x, o.y + sin(time()) * 2)
      if o.fls > 0 then
        circ(o.x + 4, o.y + 4, o.fls * 3, 7)
        circfill(o.x + 4, o.y + 4, 5, 7)
      end
    end
  end

  if gp_live == 1 then
    spr(20, gp_x, gp_y + sin(time()) * 2)
  end
end

-- screen wipes in 4px bands (the cart does per-scanline sine wipes)
function draw_wipe(leftside)
  local e = infade / 12
  if leftside == 1 then
    e = (p_wipe_timer - 5) / 12
  end
  local i = 0
  while i <= 124 do
    local s = 191 * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
    if leftside == 1 then
      rectfill(cam_draw_x, cam_draw_y + i, cam_draw_x + s, cam_draw_y + i + 3, 0)
    else
      rectfill(cam_draw_x + s, cam_draw_y + i, cam_draw_x + 128, cam_draw_y + i + 3, 0)
    end
    i += 4
  end
end

function draw_score_panel()
  rectfill(34, 392, 98, 434, 1)
  rectfill(32, 390, 96, 432, 0)
  rect(32, 390, 96, 432, 7)
  spr(21, 44, 396)
  print("X", 56, 398, 7)
  print(berry_count, 62, 398, 7)
  spr(87, 44, 408)
  draw_time(56, 408)
  spr(71, 44, 420)
  print("X", 56, 421, 7)
  print(death_count, 62, 421, 7)
end

-- ---------------------------------------------------------------------------
-- callbacks
-- ---------------------------------------------------------------------------

function _init()
  fl_pos = 1
  fl_data()
  local i = 1
  while i <= 26 do
    snow_x[i] = flr(rnd(132))
    snow_y[i] = rnd(132)
    i += 1
  end
  i = 1
  while i <= 12 do
    cloud_x[i] = rnd(132)
    cloud_y[i] = flr(rnd(132))
    cloud_s[i] = 16 + flr(rnd(32))
    i += 1
  end
end

function _update()
  if level_index == 0 then
    -- title screen
    cls(0)
    if tflash > -999 then
      tflash -= 1
      if tflash < -30 then
        tflash = -1000
        load_level(1)
      end
    elseif btn(4) or btn(5) then
      tflash = 50
      sfx_go(3, 76, 4)
      sfx_q(3, 83, 6, 5)
    end

  elseif level_index == -1 then
    -- to-be-continued card (slice builds)
    cls(0)
    outro -= 1
    if outro <= 0 then
      level_index = 0
      frames = 0
      seconds = 0
      minutes = 0
      berry_count = 0
      death_count = 0
      n_collected = 0
      l1_cue = 0
    end

  elseif level_intro > 0 then
    cls(0)
    level_intro -= 1
    if level_intro == 0 then
      sfx_go(3, 84, 4)
      sfx_q(3, 88, 5, 5)
    end

  else
    cls(lvl_bg)

    shake = max(0, shake - 1)
    infade = min(infade + 1, 60)
    if level_index ~= 8 then frames += 1 end
    if frames == 30 then
      seconds += 1
      frames = 0
    end
    if seconds == 60 then
      minutes += 1
      seconds = 0
    end

    update_input()

    if freeze_time > 0 then
      freeze_time -= 1
    else
      holds_update()
      bridges_update()
      crumbs_update()
      spawners_update()
      berries_update()
      if p_freeze > 0 then
        p_freeze -= 1
      else
        p_update()
      end
    end
  end
  sfx_tick()
end

function _draw()
  if level_index == 0 then
    -- title (the cart palette-flashes the logo; we fade by skipping it)
    local show = 1
    if tflash > -999 and tflash <= 10 then show = 0 end
    camera(0, 0)
    cam_draw_x = 0
    cam_draw_y = 0
    if show == 1 then
      spr(72, 36, 32, 8, 4)
      print("LANI'S TREK", 43, 68, 14)
      print("A GAME BY", 47, 80, 1)
      print("MADDY THORSON", 39, 87, 5)
      print("NOEL BERRY", 44, 94, 5)
      print("LENA RAINE", 44, 101, 5)
      print("GAMETANK PORT OF THE PICO-8 GAME", 1, 116, 1)
    end
    rect(0, 0, 127, 127, 7)
    draw_snow()
    return
  end

  if level_index == -1 then
    camera(0, 0)
    cam_draw_x = 0
    cam_draw_y = 0
    print("TO BE CONTINUED...", 29, 56, 7)
    draw_time(48, 70)
    return
  end

  if level_intro > 0 then
    camera(0, 0)
    cam_draw_x = 0
    cam_draw_y = 0
    draw_time(4, 4)
    if level_index ~= 8 then
      print("LEVEL", 51, 56, 7)
      print(level_index - 2, 76, 56, 7)
    end
    if lvl_title == 1 then print("TRAILHEAD", 47, 64, 7) end
    if lvl_title == 2 then print("GLACIAL CAVES", 39, 64, 7) end
    if lvl_title == 3 then print("GOLDEN VALLEY", 39, 64, 7) end
    if lvl_title == 4 then print("DESTINATION", 43, 64, 7) end
    return
  end

  cam_draw_x = camera_x
  cam_draw_y = camera_y
  if shake > 0 then
    cam_draw_x = camera_x - 2 + flr(rnd(5))
    cam_draw_y = camera_y - 2 + flr(rnd(5))
  end
  camera(cam_draw_x, cam_draw_y)

  draw_clouds()
  draw_tiles()

  if show_score > 105 then
    draw_score_panel()
  end

  draw_objects()
  p_draw()
  draw_snow()

  if p_wipe_timer > 5 then
    draw_wipe(1)
  end
  if infade < 15 then
    draw_wipe(0)
  end

  if infade < 45 then
    draw_time(cam_draw_x + 4, cam_draw_y + 4)
  end
end
