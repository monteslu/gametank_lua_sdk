-- orbit: PICO-8-style demo — a ship orbits with sin/cos turn math,
-- d-pad nudges the orbit, 🅾️ reverses, ❎ changes colors.
-- Exercises: fixed point, trig, one-line ifs, btnp, circfill, camera.

local angle = 0
local speed = 0.008
local radius = 40
local ship_col = 8   -- p8 red
local trail = 0.0
local shake = 0

function _init()
  srand(7)
end

function _update60()
  angle += speed
  if (btn(0)) radius -= 1
  if (btn(1)) radius += 1
  if (btnp(4)) speed = -speed
  if (btnp(5)) ship_col += 1
  radius = mid(8, radius, 58)
  if (btnp(2)) shake = 6
  if (shake > 0) shake -= 1
end

function _draw()
  cls(1)                          -- p8 dark blue

  local cx = 64
  local cy = 64
  if shake > 0 then
    cx += flr(rnd(shake)) - shake \ 2
    cy += flr(rnd(shake)) - shake \ 2
  end

  -- orbit ring
  circ(cx, cy, radius, 13)

  -- sun
  circfill(cx, cy, 10, 9)
  circfill(cx, cy, 7, 10)

  -- planet on the orbit
  local px = cx + flr(cos(angle) * radius)
  local py = cy + flr(sin(angle) * radius)
  circfill(px, py, 5, ship_col % 16)
  pset(px, py - 6, 7)

  -- moon, twice the angular speed, quarter turn ahead
  local mx = px + flr(cos(angle * 2 + 0.25) * 10)
  local my = py + flr(sin(angle * 2 + 0.25) * 10)
  circfill(mx, my, 2, 6)

  -- starfield corners + hud line
  pset(10, 10, 7)
  pset(120, 14, 6)
  pset(24, 110, 7)
  pset(100, 100, 6)
  line(0, 127, flr(t() * 8) % 128, 127, 11)
end
