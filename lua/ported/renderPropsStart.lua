-- global c, keepLooping, afterEffects, gLastImported, gRenderTrashProps, gCurrentlyRenderingTrash, softProp, propsToRender, gPEprops

local me = {}

function me.exitFrame()
  local utils = require('comEditorUtils')

  if (utils.checkMinimize()) then
    _player.appMinimize()
  end
  if (utils.checkExit()) then
    _player.quit()
  end
  if (utils.checkExitRender()) then
    _movie.go(9)
  end

  c = 1

  ---@type boolean
  keepLooping = true
  --Set by LevelRenderer.cs now.
  --afterEffects = (_movie.frame > 51)
  gLastImported = ""
  gCurrentlyRenderingTrash = false

  if (#gRenderTrashProps > 0) then
    if (afterEffects == 0) then
      gCurrentlyRenderingTrash = true
    end
  end

  -- for q = 0, 29 do
    -- local sprq = sprite(50 - q) -- TODO: maybe implement this
    -- sprq.loc = point(683 - q, 384 - q)
    -- local val = (q + 1.0) / 30.0 * 255
    -- sprq.color = color(val, val, val)
  -- end

  -- Sort props by their render order.
 
  propsToRender = list()
  local peprps = gPEprops.props
  for a = 1, #peprps do
    propsToRender:add(list(peprps[a]))
  end
  table.sort(
    propsToRender,
    function(a, b)
      return (a[5].settings.renderorder or a[5].settings.renderOrder) < (b[5].settings.renderorder or b[5].settings.renderOrder)
    end
  )

  ---This is used to signal to the renderer that it's now rendering a soft props;
  ---It contains additional information such as the target quad and if it's 'colored' or not.
  ---@class softProp
  ---@field c integer
  ---@field pasteRect rect
  ---@field prop table
  ---@field propData table
  ---@field dp integer
  ---@field clr color?
  softProp = nil
end

return me
