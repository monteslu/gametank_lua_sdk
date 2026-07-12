-- hello: the smallest real GameTank game - no assets, just code.
-- The screen is 128x128. cls clears it; print and the shape calls draw on top.
-- Colors are PICO-8-style indices 0-15 (0 black, 1 dark-blue, 10 yellow, 14 pink).

function _draw()
  cls(1)                          -- dark blue background

  print("hello gametank", 38, 14, 14)   -- title text, pink, near the top

  -- a smiley face, drawn entirely with shapes (no sprite sheet needed)
  circfill(64, 72, 26, 10)        -- head: a big yellow circle
  rectfill(53, 62, 58, 68, 0)     -- left eye: a black square
  rectfill(70, 62, 75, 68, 0)     -- right eye
  circfill(64, 82, 9, 0)          -- mouth: a black circle
end
