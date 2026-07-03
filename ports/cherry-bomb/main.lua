-- cherry-bomb (adapted port)
-- A wave survival shmup inspired by "Cherry Bomb" by Krystman / Lazy Devs
-- (lexaloffle.com/bbs/?tid=48986, CC4-BY-NC-SA). From-scratch gtlua
-- implementation of the design, drawn with primitives.
-- This port: CC-BY-NC-SA 4.0.
--
-- d-pad move, 🅾️ (GT A) shoot. Survive the waves. Runs locked 30fps:
-- enemy motion is all-integer (quarter-pixel y, table-driven sway), and
-- cls() is kicked at update start so its DMA overlaps the game logic.

local px = 60
local py = 108
local pflash = 0
local lives = 3
local score = 0
local wave = 0
local wavetimer = 30
local gameover = 0
local ph = 0                -- frame counter (drives sway + starfield)

-- player bullets
local bx = array(6)
local by = array(6)
local blive = array(6)
local cooldown = 0

-- enemies: integer math only. y in quarter-pixels; sway from a table.
local ex = array(8)
local ey4 = array(8)        -- y * 4
local ebase = array(8)
local espd4 = array(8)      -- quarter-pixels per frame
local elive = array(8)
local left = 0

local swaytab = array(32)   -- flr(sin(k/32) * 24), filled once in _init

function spawn_wave()
  wave += 1
  left = 0
  for i = 1, #ex do
    if i <= 3 + wave then
      elive[i] = 1
      ebase[i] = 28 + (i * 23) % 80
      ex[i] = ebase[i]
      ey4[i] = (-8 - (i % 4) * 14) * 4
      local s = 3 + wave + (i % 3) * 2
      if (s > 12) s = 12
      espd4[i] = s
      left += 1
    else
      elive[i] = 0
    end
  end
end

function fire()
  for i = 1, #bx do
    if blive[i] == 0 and cooldown == 0 then
      blive[i] = 1
      bx[i] = px
      by[i] = py - 6
      cooldown = 4
      return
    end
  end
end

-- 8x8 cherry-pair sprite in cell 0: stems (dark green), two round
-- berries (red) with pink highlights. Drawn once into the sheet.
function make_art()
  -- clear cell 0 to transparent (GRAM boots as noise)
  for y = 0, 7 do
    for x = 0, 7 do
      sset(x, y, 0)
    end
  end
  -- stems
  sset(3, 0, 3) sset(4, 0, 3)
  sset(2, 1, 3) sset(5, 1, 3)
  sset(2, 2, 3) sset(5, 2, 3)
  -- left berry
  sset(1, 3, 8) sset(2, 3, 8)
  sset(0, 4, 8) sset(1, 4, 8) sset(2, 4, 8) sset(3, 4, 8)
  sset(0, 5, 8) sset(1, 5, 14) sset(2, 5, 8) sset(3, 5, 8)
  sset(1, 6, 8) sset(2, 6, 8)
  -- right berry
  sset(5, 4, 8) sset(6, 4, 8)
  sset(4, 5, 8) sset(5, 5, 8) sset(6, 5, 8) sset(7, 5, 8)
  sset(4, 6, 8) sset(5, 6, 14) sset(6, 6, 8) sset(7, 6, 8)
  sset(5, 7, 8) sset(6, 7, 8)
end

function _init()
  for k = 1, 32 do
    swaytab[k] = flr(sin(k * 0.03125) * 24)
  end
  make_art()
  spawn_wave()
end

function _update()
  cls(0)   -- kick the big clear first: its DMA runs under the logic below

  if gameover == 1 then
    if (btnp(4)) gameover = 0 lives = 3 score = 0 wave = 0 px = 60 spawn_wave()
    return
  end

  ph += 1

  -- player
  if (btn(0)) px -= 4
  if (btn(1)) px += 4
  if (btn(2)) py -= 2
  if (btn(3)) py += 2
  px = mid(6, px, 121)
  py = mid(70, py, 120)
  if (btn(4)) fire()
  if (cooldown > 0) cooldown -= 1
  if (pflash > 0) pflash -= 1

  -- bullets
  for i = 1, #bx do
    if blive[i] == 1 then
      by[i] -= 8
      if (by[i] < -4) blive[i] = 0
    end
  end

  -- enemies (integer math throughout)
  for i = 1, #ex do
    if elive[i] == 1 then
      ex[i] = ebase[i] + swaytab[1 + (ph \ 2 + i * 4) % 32]
      ey4[i] += espd4[i]
      if (ey4[i] > 520) ey4[i] = -40
      local eyi = ey4[i] \ 4

      for j = 1, #bx do
        if blive[j] == 1 then
          if abs(bx[j] - ex[i]) < 6 and abs(by[j] - eyi) < 6 then
            blive[j] = 0
            elive[i] = 0
            left -= 1
            score += 10
          end
        end
      end

      if elive[i] == 1 and pflash == 0 then
        if abs(px - ex[i]) < 7 and abs(py - eyi) < 7 then
          lives -= 1
          pflash = 45
          if (lives <= 0) gameover = 1
        end
      end
    end
  end

  if left <= 0 then
    wavetimer -= 1
    if wavetimer <= 0 then
      wavetimer = 30
      spawn_wave()
    end
  end
end

function _draw()
  -- background was cleared in _update; just the stars
  local sy = (ph * 2) % 128
  pset(20, sy, 5)
  pset(90, (sy + 64) % 128, 6)

  if gameover == 1 then
    rectfill(24, 50, 103, 70, 8)
    rect(24, 50, 103, 70, 7)
    rectfill(30, 58, 30 + mid(0, score \ 10, 60), 62, 10)
    return
  end

  -- player ship (flash while invulnerable)
  if pflash % 8 < 4 then
    rectfill(px - 1, py - 5, px + 1, py + 4, 12)
    rectfill(px - 5, py, px + 5, py + 3, 12)
  end

  -- bullets
  for i = 1, #bx do
    if (blive[i] == 1) rectfill(bx[i] - 1, by[i] - 2, bx[i], by[i] + 2, 10)
  end

  -- enemies: real cherry sprites, one blit each
  for i = 1, #ex do
    if elive[i] == 1 then
      spr(0, ex[i] - 4, ey4[i] \ 4 - 3)
    end
  end

  -- hud: lives bar, score bar, wave bar
  rectfill(2, 2, 2 + lives * 6, 4, 12)
  rectfill(0, 0, mid(0, score \ 8, 127), 1, 10)
  rectfill(127 - mid(1, wave, 8) * 4, 5, 127, 8, 14)
end
