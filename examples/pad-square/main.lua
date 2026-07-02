-- pad-square: the gtlua hello-world, PICO-8 style.
-- d-pad moves, 🅾️ cycles color, ❎ grows, button 6 (GameTank C) shrinks.

local x = 60
local y = 60
local size = 8
local col = 8      -- p8 red
local speed = 2

function _update60()
  if (btn(0)) x -= speed
  if (btn(1)) x += speed
  if (btn(2)) y -= speed
  if (btn(3)) y += speed

  if (btnp(4)) col += 1
  if (btnp(5)) size = mid(4, size + 4, 32)
  if (btnp(6)) size = mid(4, size - 4, 32)

  x = mid(0, x, 127 - size)
  y = mid(0, y, 127 - size)
end

function _draw()
  cls(1)
  rectfill(x, y, x + size - 1, y + size - 1, col % 16)
  rect(x - 2, y - 2, x + size + 1, y + size + 1, 7)
end
