-- global vertRepeater, r, gEEprops, keepLooping

local me = {}

local utils = require('comEditorUtils')

function me.exitFrame()
  if (utils.checkMinimize()) then
    _player.appMinimize()
  end
  if (utils.checkExit()) then
    _player.quit()
  end
  if (utils.checkExitRender()) then
    _movie.go(9)
  end
  for q = 0, 29 do
    -- sprq = sprite(50 - q)
    -- sprq.loc = point(683 - q, 384 - q)
    -- val = (q.float + 1.0) / 30.0 * 255
    -- sprq.color = color(val, val, val)
  end

--   sprite(57).visibility = 0
--   sprite(58).visibility = 0
  vertRepeater = 100000
  if (#gEEprops.effects > 0) then
    r = 0
    keepLooping = true
  else
    -- go(56)
  end
end

return me