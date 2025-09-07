-- global gViewRender, c, gPEprops, keepLooping, gRenderCameraTilePos, gLastImported, gLastImportedImage, gProps, afterEffects, gAnyDecals, gRenderTrashProps, gCurrentlyRenderingTrash, gESoftProp, softProp, propsToRender, altGrafLG, DRPxl, DRRopeVari, DRBevelColors

-- Lord have mercy on my soul

local fiffigt = require('fiffigt')
local utils = require('comEditorUtils')
local spelrelaterat = require('spelrelaterat')
local levelRendering = require('levelRendering')

local me = {}

function me.exitFrame()
  if (utils.checkMinimize()) then
    _player.appMinimize()
  end
  if (utils.checkExit()) then
    _player.quit()
  end
  if (gViewRender) then
    if (utils.checkExitRender()) then
      _movie.go(9)
    end
    me.newFrame()
    if (keepLooping) then
      -- go the frame
    end
  else
    while keepLooping do
      me.newFrame()
    end
  end
end

function me.newFrame()
  ---@type table
  local qd
  ---@type table
  local propData


  if (softProp ~= nil) then
    if (gESoftProp < 1) then
      me.renderSoftProp2()
    else
      me.renderESoftProp()
    end
  else
    if (gCurrentlyRenderingTrash) then
      if (c > #gRenderTrashProps) then
        gCurrentlyRenderingTrash = false
        if (#propsToRender > 0) then
          c = 1
          propData = propsToRender[c]
        else
          keepLooping = false
          return
        end
      else
        propData = gRenderTrashProps[c]
      end
    else
      print('Props: ' .. (c-1) .. '/' .. (#propsToRender) .. ': ' .. propsToRender[c][2])
      if (c > #propsToRender) then
        keepLooping = false
        return
      end
      propData = propsToRender[c]
    end

    local dt3 = propData[3]
    local prop = gProps[dt3.x].prps[dt3.y]
    local prpSets = propData[5].settings

    if (me.ShouldThisPropRender(prop, quad(propData[4]), prpSets)) then
      me.updateText()
      qd = quad(propData[4])
      local dp = math.abs(-propData[1])
      if (gCurrentlyRenderingTrash == false) then
        qd = qd * (20.0 / 16.0)
      end
      local mdPoint = center(qd)
      local savSeed = randomSeed
      --   global gLOprops
      randomSeed = spelrelaterat.seedForTile(spelrelaterat.giveGridPos(mdPoint), prpSets.seed)
      if (gCurrentlyRenderingTrash == false) then
        local camPos20 = gRenderCameraTilePos * 20
        qd = qd - camPos20
      end

      local data
      if (gCurrentlyRenderingTrash) then
        data = list()
      else
        data = propsToRender[c][5]
      end
      me.renderProp(prop, dp, qd, mdPoint, data)
      randomSeed = savSeed
    end

    c = c + 1
  end
end

---@param prop table
---@param qd Quad
---@param settings table
---@return boolean
function me.ShouldThisPropRender(prop, qd, settings)
  if (settings.renderTime ~= afterEffects) then
    return false
  end

  if (gCurrentlyRenderingTrash == false) then
    qd = qd * (20.0 / 16.0)
    local camPos20 = gRenderCameraTilePos * 20
    qd = qd - camPos20 -- {camPos20, camPos20, camPos20, camPos20}
  end

  local mdPoint = center(qd)
  local dig = 0

  -- for q = 1, 4 do
  --   if (fiffigt.diagWI(mdPoint, qd[q], dig) == FALSE) then
  --     dig = fiffigt.diag(mdPoint, qd[q])
  --   end
  -- end

  -- unrolled

  if not fiffigt.diagWI(mdPoint, qd.topleft, dig) then
    dig = fiffigt.diag(mdPoint, qd.topleft)
  end
  if not fiffigt.diagWI(mdPoint, qd.topright, dig) then
    dig = fiffigt.diag(mdPoint, qd.topright)
  end
  if not fiffigt.diagWI(mdPoint, qd.bottomright, dig) then
    dig = fiffigt.diag(mdPoint, qd.bottomright)
  end
  if not fiffigt.diagWI(mdPoint, qd.bottomleft, dig) then
    dig = fiffigt.diag(mdPoint, qd.bottomleft)
  end

  return fiffigt.diag(mdPoint, fiffigt.closestPntInRect(rect(-50, -100, 2050, 1100), mdPoint)) <= dig
end

function me.updateText()
  local txt = "<RENDERING PROPS>" .. RETURN
  local viewProp = c

  if (softProp ~= VOID) then
    viewProp = c - 1
  end

  if (gCurrentlyRenderingTrash) then
    txt = txt .. "Trash props -   " .. tostring(c) .. " / " .. tostring(#gRenderTrashProps) .. RETURN
  else
    for prp = 1, #propsToRender do
      local renderPrp = propsToRender[prp]

      ---@type point
      local propAddress = renderPrp[3]

      if (me.ShouldThisPropRender(gProps[propAddress.x].prps[propAddress.y], quad(renderPrp[4]), renderPrp[5].settings)) then
        if (prp == viewProp) then
          txt = txt .. tostring(prp) .. ". ->" .. renderPrp[2]
        else
          txt = txt .. tostring(prp) .. ". " .. renderPrp[2]
        end
        -- put RETURN after txt
        txt = txt .. RETURN
      end
    end
  end
  member("effectsL").text = txt
end

---@param prop table
---@param dp number
---@param qd Quad
---@param mdPoint point
---@param data table
function me.renderProp(prop, dp, qd, mdPoint, data)
  ---@type Image
  local propImage

  ---@type boolean
  local tileAsProp = false

  if (gLastImported ~= prop.nm) then
    tileAsProp = (getPos(prop.tags, "Tile") > 0)
    local path
    if (tileAsProp) then
      path = "Graphics" .. dirSeparator .. prop.nm .. ".png"
    elseif (prop.tp == "customRope") then
      path = "Props" .. dirSeparator .. prop.nm .. "Segment.png"
    elseif (prop.tp == "customLong") then
      path = "Props" .. dirSeparator .. prop.nm .. "Segment.png"
    else
      path = "Props" .. dirSeparator .. prop.nm .. ".png"
    end
    propImage = image(path)
    gLastImported = prop.nm
    gLastImportedImage = propImage
  else
    propImage = gLastImportedImage
  end
  --INTERNAL
  if tobool(utils.checkDRInternal(prop.nm)) then
    propImage = member(prop.nm).image
  end

  ---@type string
  local tpCase = prop.tp

  if (tpCase == "standard") or (tpCase == "variedStandard") then
    me.renderVoxelProp(prop, dp, qd, mdPoint, data, propImage)
  elseif (tpCase == "simpleDecal") or (tpCase == "variedDecal") then
    gAnyDecals = 1
    me.renderDecal(prop, dp, qd, mdPoint, data, propImage)
  elseif (tpCase == "rope") or (tpCase == "customRope") then
    me.renderRope(prop, propsToRender[c][5], dp)
  elseif (tpCase == "soft") or (tpCase == "variedSoft") or (tpCase == "antimatter") or (tpCase == "coloredSoft") then
    gESoftProp = 0
    me.initRenderSoftProp(prop, qd, data, dp, propImage)
  elseif (tpCase == "softEffect") then
    gESoftProp = 1
    me.initRenderSoftProp(prop, qd, data, dp, propImage)
  elseif (tpCase == "long") or (tpCase == "customLong") then
    me.renderLongProp(qd, prop, propsToRender[c][5], dp)
  end

  --   case (prop.tp) of
  --     "standard", "variedStandard":
  --     "simpleDecal", "variedDecal":
  --     "rope", "customRope":
  --     "soft", "variedSoft", "antimatter", "coloredSoft":
  --     "softEffect":
  --     "long", "customLong":
  --   end case
  me.DoPropTags(prop, dp, qd)
end

---@param prop table
---@param dp number
---@param qd Quad
---@param mdPoint point
---@param propImage Image
function me.renderVoxelProp(prop, dp, qd, mdPoint, propData, propImage)
  ---@type number
  local var
  ---@type number
  local ps
  ---@type boolean
  local colored
  ---@type rect
  local gtRect
  ---@type Image
  local dumpImg
  ---@type Image
  local inverseImg
  ---@type Image
  local layerDpImg
  ---@type table
  local a
  ---@type boolean
  local variedStandard

  var = 0
  variedStandard = (prop.tp == "variedStandard")

  if (variedStandard) then
    var = propData.settings.variations - 1
  end

  ps = 0

  --INTERNAL
  if (utils.checkDRInternal(prop.nm)) then
    propImage = member(prop.nm).image
  end

  colored = (getPos(prop.tags, "colored") > 0)

  if (colored) then
    gAnyDecals = 1
  end

  local effectColorA = (getPos(prop.tags, "effectColorA") > 0)
  local effectColorB = (getPos(prop.tags, "effectColorB") > 0)

  for q = 1, #prop.repeatL do
    gtRect = rect(0, 1, prop.sz.x * 20, prop.sz.y * 20 + 1)
    gtRect = gtRect + rect(gtRect.width * var, gtRect.height * ps, gtRect.width * var, gtRect.height * ps)

    for q2 = 1, prop.repeatL[q] do
      layerDpImg = member("layer" .. tostring(math.abs(dp))).image

      ---@type string
      local ctCase = prop.colorTreatment

      if ctCase == "standard" then
        layerDpImg:copyPixels(propImage, qd, gtRect, { ink = 36 })
        if (effectColorA) then
          if (variedStandard) then
            member("gradientA" .. tostring(dp)).image:copyPixels(propImage, qd,
              gtRect + rect(prop.sz.x * 20 * prop.vars, 0, prop.sz.x * 20 * prop.vars, 0), { ink = 39 })
          else
            member("gradientA" .. tostring(dp)).image:copyPixels(propImage, qd,
              gtRect + rect(prop.sz.x * 20, 0, prop.sz.x * 20, 0), { ink = 39 })
          end
        end
        if (effectColorB) then
          if (variedStandard) then
            member("gradientB" .. tostring(dp)).image:copyPixels(propImage, qd,
              gtRect + rect(prop.sz.x * 20 * prop.vars, 0, prop.sz.x * 20 * prop.vars, 0), { ink = 39 })
          else
            member("gradientB" .. string(dp)).image:copyPixels(propImage, qd,
              gtRect + rect(prop.sz.x * 20, 0, prop.sz.x * 20, 0), { ink = 39 })
          end
        end
      elseif ctCase == "bevel" then
        copyPixelsBevel(layerDpImg, propImage, qd, gtRect, prop.bevel)

        -- old code

        -- dumpImg = image(gtRect.width, gtRect.height)
        -- dumpImg:copyPixels(propImage, dumpImg.rect, gtRect)
        -- -- inverseImg = require('spelrelaterat').makeSilhoutteFromImg(dumpImg, 1)
        -- inverseImg = silhouette(dumpImg, true)
        -- dumpImg = image(layerDpImg.width, layerDpImg.height)
        -- dumpImg:copyPixels(DRPxl, qd, rect(0, 0, 1, 1), { color = color(0, 255, 0) })
        
        -- for b = 1, prop.bevel do
        --   for _, a in ipairs(DRBevelColors) do
        --     local a2mb = a[2] * b
        --     dumpImg:copyPixels(inverseImg, qd + a2mb, inverseImg.rect, { color = a[1], ink = 36 })
        --   end
        -- end
        
        -- dumpImg:copyPixels(inverseImg, qd, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
        -- inverseImg = image(dumpImg.width, dumpImg.height)
        -- inverseImg:copyPixels(DRPxl, inverseImg.rect, rect(0, 0, 1, 1))
        -- inverseImg:copyPixels(DRPxl, qd, rect(0, 0, 1, 1), { color = color(255, 255, 255) })
        -- dumpImg:copyPixels(inverseImg, dumpImg.rect, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
        -- layerDpImg:copyPixels(dumpImg, dumpImg.rect, dumpImg.rect, { ink = 36 })
      end

      --   case (prop.colorTreatment) of
      --     "standard":
      --     "bevel":
      --   end case

      if (colored) then
        if (effectColorA == false) then
          if (effectColorB == false) then
            if (variedStandard) then
              member("layer" .. tostring(dp) .. "dc").image:copyPixels(propImage, qd,
                gtRect + rect(prop.sz.x * 20 * prop.vars, 0, prop.sz.x * 20 * prop.vars, 0), { ink = 36 })
            else
              member("layer" .. tostring(dp) .. "dc").image:copyPixels(propImage, qd,
                gtRect + rect(prop.sz.x * 20, 0, prop.sz.x * 20, 0), { ink = 36 })
            end
          end
        end
      end
      dp = dp + 1
      if (dp > 29) then
        break
      end
    end
    if (dp > 29) then
      break
    end
    ps = ps + 1
  end
end

---@param prop table
---@param dp number
---@param qd Quad
---@param mdPoint point
---@param data table
---@param propImage Image
function me.renderDecal(prop, dp, qd, mdPoint, data, propImage)
  ---@type number
  local rnd
  ---@type number
  local ps
  ---@types number
  local depthzero
  ---@types table
  local dirq
  ---@types number
  local actualDepth
  ---@types number
  local averagesz
  ---@types rect
  local getrect
  ---@types color
  local clr

  rnd = 1
  ps = 1


  --INTERNAL
  if (utils.checkDRInternal(prop.nm)) then
    propImage = member(prop.nm).image
  end
  -- put "render decal"
  local depthZero = dp
  for _, testDp in ipairs({ 0, 10, 20 }) do
    if (dp <= testDp) and (dp + prop.depth > testDp) then
      depthZero = testDp
      break
    end
  end

  dirq = me.directifunctionsQuad()

  actualDepth = prop.depth
  if (dp + prop.depth > 29) then
    actualDepth = 29 - dp
  end

  local averageSz = (fiffigt.diag(qd.topleft, qd.topright) + fiffigt.diag(qd.topright, qd.bottomright) + fiffigt.diag(qd.bottomright, qd.bottomleft) + fiffigt.diag(qd.bottomleft, qd.topright)) /
  4.0
  averageSz = (averageSz + 80.0) / 2.0
  averageSz = averageSz / 12.0
  averageSz = averageSz / ((4.0 + actualDepth) / 5.0)
  dirq = dirq * averageSz

  local getRect = propImage.rect
  if (prop.tp == "variedDecal") then
    getRect = rect(prop.pxlSize.x * (data.settings.variation - 1), 0, prop.pxlSize.x * data.settings.variation,
      prop.pxlSize.y) + rect(0, 1, 0, 1)
  end

  clr = color(0, 0, 0)
  if (data.settings["color"]) then
    if (data.settings.color > 0) then
      --   global gPEcolors
      clr = gPEcolors[data.settings.color][2]
    end
  end

  for q = 1, data.settings.customDepth do
    member("layer" .. tostring(dp) .. "dc").image:copyPixels(propImage, qd + (dirq * (dp - depthZero)), getRect,
      { ink = 36, color = clr })
    dp = dp + 1
    if (dp > 29) then
      break
    end
  end
end

--used by renderDecal
---@return table
function me.directifunctionsQuad()
  ---@type table
  local qDirs
  ---@type point
  local frst
  ---@type table
  local l1
  --  seed =  the randomSeed
  --  the randomSeed = gLOprops.tileSeed
  qDirs = list()
  frst = require('fiffigt').degToVec(random(360))
  l1 = list({ { random(100), frst }, { random(100), -frst }, { random(100), fiffigt.degToVec(random(360)) }, { random(100), fiffigt.degToVec(random(360)) } })
  --   l1.sort()
  table.sort(l1, function(a, b) return a[1] < b[1] end)

  for q = 1, 4 do
    qDirs:add(l1[q][2])
  end

  return qDirs
  --
  --  newImg = member(mem).image.duplicate()
  --  qd = [point(0,0), point(newImg.width, 0), point(newImg.width, newImg.height), point(0,newImg.height)]
  --  qd = qd + qDirs*fac
  --  member(mem).image.copypixels(newImg, qd, newImg.rect)
  --
  --  the randomSeed = seed
end

---@param prop table
---@param data table
---@param dp number
function me.renderRope(prop, data, dp)
  ---@type point
  local lastPos
  ---@type point
  local lastDir
  ---@type point
  local lastPerp
  ---@type point
  local pos
  ---@type point
  local dir
  ---@type point
  local perp

  lastPos = data.points[1]
  lastDir = fiffigt.moveToPoint(lastPos, data.points[2], 1.0)
  lastPerp = me.CorrectPerp(lastDir)
  if (prop.tp == "customRope") then
    local diffSeg = (prop.pixelSize.y - prop.segmentLength) * 0.5
    if tobool(prop.random) then
      DRRopeVari = random(prop.vars) - 1
    else
      DRRopeVari = 0
    end

    for q = 1, #data.points do
      pos = data.points[q]

      if (q < #data.points) then
        dir = spelrelaterat.dirVecLB(pos, data.points[q + 1])
      else
        dir = lastDir
      end

      perp = me.CorrectPerp(dir)
      me.renderCustomRopeSegment(q, prop, data, dp, pos, dir, perp, lastPos, lastDir, lastPerp, diffSeg)
      lastPos = pos
      lastDir = dir
      lastPerp = perp
    end
  elseif (prop.nm == "Small Chain") or (prop.nm == "Fat Chain") then
    me.renderChainEffectProp(prop, data, dp)
  else
    for q = 1, #data.points do
      pos = data.points[q]
      if (q < #data.points) then
        dir = fiffigt.moveToPoint(pos, data.points[q + 1], 1.0)
      else
        dir = lastDir
      end
      perp = me.CorrectPerp(dir)

      me.renderRopeSegment(q, prop, data, dp, pos, dir, perp, lastPos, lastDir, lastPerp)
      lastPos = pos
      lastDir = dir
      lastPerp = perp
    end
  end
end

function me.renderChainEffectProp(prop, data, dp)
  local fat = (prop.nm == "Fat Chain")

  ---@type string
  local graf
  ---@type integer
  local spacing

  if fat then
    spacing = 16
    graf = "bigChainSegment"
  else
    spacing = 8
    graf = "chainSegment"
  end

  -- Calculate length
  local len = 0
  for q = 1, #data.points - 1 do
    len = len + fiffigt.diag(data.points[q], data.points[q + 1])
  end

  local numSegs = toint(len / spacing + 0.4999)
  if numSegs < 2 then numSegs = 2 end

  -- Draw segments
  for q = 1, numSegs do
    -- Sizes

    ---@type rect
    local grab
    ---@type rect
    local place

    if (q % 2) == 1 then
      grab = rect(0, 0, 6, 10)
      place = rect(-3, -5, 3, 5)
      if fat then
        grab = grab * 2
        place = place * 2
      end
    else
      grab = rect(7, 0, 8, 10)
      place = rect(-1, -5, 1, 5)
      if fat then
        grab = rect(13, 0, 16, 20)
        place = place * 2
      end
    end

    local p = 1
    local dst = q * spacing

    for i = 1, #data.points - 1 do
      dst = dst - fiffigt.diag(data.points[i], data.points[i + 1])
      if dst <= 0 then
        p = i + 1 + (dst / fiffigt.diag(data.points[i], data.points[i + 1]))
        break
      end
    end

    local pl = toint(p - 0.4999)
    local pn = toint(p + 0.4999)
    local lrp = p - pl

    if pl == pn then goto continue end

    -- Draw
    local lastPos = data.points[pl]
    local nextPos = data.points[pn]
    local pt = point(fiffigt.lerp(lastPos.x, nextPos.x, lrp), fiffigt.lerp(lastPos.y, nextPos.y, lrp)) -
    gRenderCameraTilePos * 20
    local dir = fiffigt.lookAtPoint(lastPos, nextPos)

    member("layer" .. tostring(dp)).image:copyPixels(member(graf).image,
      spelrelaterat.rotateToQuadFix(rect(pt, pt) + place, dir), grab, { color = color(255, 0, 0) })

    ::continue::
  end
end

function me.CorrectPerp(dir)
  --  if(dir = point(0, -1))then
  --    return point(1, 0)
  --  elseif (dir = point(1, 0))then
  --    return point(1, 0)
  --  elseif (dir = point(0, 1))then
  --    return point(0, 1)
  --  elseif (dir = point(-1, 0))then
  --    return point(-1, 0)
  --  else
  return fiffigt.giveDirFor90degrToLine(-dir + point(0.001, -0.001), dir)
  -- end
end

function me.renderBigChainSegment(ropePointIndex, ropeDepth, segmentStartPos, segmentEndPos)

  local segmentDirection = fiffigt.moveToPoint(segmentEndPos, segmentStartPos, 1.0)
  local segmentPerpendicularDirection = point(segmentDirection.y, -segmentDirection.x)

  -- chains alternate between thick and thin segments.
  local isThickChainSegment = ((ropePointIndex % 2) == 0)
  local isThinChainSegment = not isThickChainSegment

  local wdth

  if (isThickChainSegment) then
    wdth = 20
  else
    wdth = 7
  end

  -- calculating the start and end pos for the chain sprite
  -- different from the segmentStartPos / segmentEndPos, for some reasfunction.
  local pntA = segmentStartPos + segmentDirection * 11
  local pntB = segmentEndPos - segmentDirection * 11

  -- box defining where the chain is drawn function the screen
  local drawBox = { pntA - segmentPerpendicularDirection * wdth, pntA + segmentPerpendicularDirection * wdth,
    pntB + segmentPerpendicularDirection * wdth, pntB - segmentPerpendicularDirection * wdth }
  -- get it into camera space
  drawBox = { drawBox[1] - gRenderCameraTilePos * 20, drawBox[2] - gRenderCameraTilePos * 20, drawBox[3] -
  gRenderCameraTilePos * 20, drawBox[4] - gRenderCameraTilePos * 20 }

  local highlightOffset = { point(-2, -2), point(-2, -2), point(-2, -2), point(-2, -2) }

  -- had to be horizontally flipped

  local drawQd = quad(
    pntA + segmentPerpendicularDirection * wdth,
    pntA - segmentPerpendicularDirection * wdth,
    pntB - segmentPerpendicularDirection * wdth,
    pntB + segmentPerpendicularDirection * wdth
  ) - gRenderCameraTilePos * 20

  local spriteHeight = 100
  local thickSpriteWidth = 40
  local thinSpriteWidth = 14

  for graphicLayer = 0, 5 do
    local layerDepth = spelrelaterat.restrict(ropeDepth + graphicLayer, 0, 29)

    local spriteRect = rect(0, 1 + (graphicLayer * spriteHeight), thickSpriteWidth, 1 + ((graphicLayer + 1) * spriteHeight))
    if (isThinChainSegment) then
      spriteRect = spriteRect + rect(thickSpriteWidth, 0, thinSpriteWidth, 0)
    end

    member("layer" .. layerDepth).image:copyPixels(member("bigChainGraf").image, drawQd, spriteRect, { ink = 36 })
    member("layer" .. layerDepth).image:copyPixels(member("bigChainGrafHighLight").image, drawQd - point(2, 2),
      spriteRect, { ink = 36 })

    -- draws the back side of the chain
    layerDepth = spelrelaterat.restrict(ropeDepth + 4 + graphicLayer, 0, 29)
    local reverseGraphicLayer = 5 - graphicLayer

    spriteRect = rect(0, 1 + (reverseGraphicLayer * spriteHeight), thickSpriteWidth,
      1 + ((reverseGraphicLayer + 1) * spriteHeight))
    if (isThinChainSegment) then
      spriteRect = spriteRect + rect(thickSpriteWidth, 0, thinSpriteWidth, 0)
    end

    member("layer" .. layerDepth).image:copyPixels(member("bigChainGraf").image, drawQd, spriteRect, { ink = 36 })
    member("layer" .. layerDepth).image:copyPixels(member("bigChainGrafHighLight").image, drawQd - point(2, 2),
      spriteRect, { ink = 36 })
  end
end

function me.renderCustomRopeSegment(num, prop, data, dp, pos, dir, perp, lastPos, lastDir, lastPerp, diffSeg)
  local dr = spelrelaterat.dirVecLB(pos, lastPos) * diffSeg
  local wdth = prop.pixelSize.x * 0.5

  ---@type point
  local pntA
  ---@type point
  local pntB

  if (num == 1) then
    pntA = lastPos + (dr + lastDir * wdth) * 0.5
    pntB = pos - 1.5 * dr - lastDir * wdth
  else
    pntA = lastPos + dr
    pntB = pos - dr
  end

  local pastQd = { pntA - lastPerp * wdth, pntA + lastPerp * wdth, pntB + lastPerp * wdth, pntB - lastPerp * wdth }
  local renderCamMul = gRenderCameraTilePos * 20

  pastQd = { pastQd[1] - renderCamMul, pastQd[2] - renderCamMul, pastQd[3] - renderCamMul, pastQd[4] - renderCamMul }
  local sav2 = member("previewImprt")
  local colored = (prop.tags:getPos("colored") > 0)

  if (colored) then
    gAnyDecals = 1
  end

  local effectColorA = (prop.tags:getPos("effectColorA") > 0)
  local effectColorB = (prop.tags:getPos("effectColorB") > 0)
  local ps = 0

  for q = 1, #prop.repeatL do
    local gtRect = rect(0, 1, prop.pixelSize.x, prop.pixelSize.y + 1)
    gtRect = gtRect + rect(gtRect.width * DRRopeVari, gtRect.height * ps, gtRect.width * DRRopeVari, gtRect.height * ps)
    for q2 = 1, prop.repeatL[q] do
      local layerImg = member("layer" .. tostring(dp)).image

      ---@type string
      local ctCase = prop.colorTreatment

      if ctCase == "standard" then
        layerImg:copyPixels(sav2.image, quad(pastQd), gtRect, { ink = 36 })
        if (effectColorA) then
          member("gradientA" .. tostring(dp)).image:copyPixels(sav2.image, quad(pastQd),
            gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 39 })
        end

        if (effectColorB) then
          member("gradientB" .. tostring(dp)).image:copyPixels(sav2.image, quad(pastQd),
            gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 39 })
        end
      elseif ctCase == "bevel" then
        local dumpImg = image(gtRect.width, gtRect.height)
        dumpImg:copyPixels(sav2.image, dumpImg.rect, gtRect)
        local inverseImg = spelrelaterat.makeSilhoutteFromImg(dumpImg, 1)
        dumpImg = image(layerImg.width, layerImg.height)
        dumpImg:copyPixels(DRPxl, quad(pastQd), rect(0, 0, 1, 1), { color = color(0, 255, 0) })

        for bbvl = 1, prop.bevel do
          for _, abvl in ipairs(DRBevelColors) do
            local a2mb = abvl[2] * bbvl
            dumpImg:copyPixels(inverseImg, quad(pastQd) + a2mb, inverseImg.rect, { color = abvl[1], ink = 36 })
          end
        end

        dumpImg:copyPixels(inverseImg, quad(pastQd), inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
        inverseImg = image(dumpImg.width, dumpImg.height)
        inverseImg:copyPixels(DRPxl, inverseImg.rect, rect(0, 0, 1, 1))
        inverseImg:copyPixels(DRPxl, quad(pastQd), rect(0, 0, 1, 1), { color = color(255, 255, 255) })
        dumpImg:copyPixels(inverseImg, dumpImg.rect, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
        layerImg:copyPixels(dumpImg, dumpImg.rect, dumpImg.rect, { ink = 36 })
      end

      --   case (prop.colorTreatment) of
      --     "standard":
      --     "bevel":
      --   end case

      if (colored) then
        if (effectColorA == FALSE) then
          if (effectColorB == FALSE) then
            member("layer" .. tostring(dp) .. "dc").image:copyPixels(sav2.image, quad(pastQd),
              gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 36 })
          end
        end
      end
      dp = dp + 1
      if (dp > 29) then
        break
      end
    end
    if (dp > 29) then
      break
    end
    ps = ps + 1
  end
  if tobool(prop.random) then
    DRRopeVari = random(prop.vars) - 1
  else
    DRRopeVari = DRRopeVari + 1
    if (DRRopeVari >= prop.vars) then
      DRRopeVari = 0
    end
  end
end

---@param num number
---@param prop table
---@param data table
---@param dp number
---@param pos point
---@param dir point
---@param perp point
---@param lastPos point
---@param lastDir point
---@param lastPerp point
function me.renderRopeSegment(num, prop, data, dp, pos, dir, perp, lastPos, lastDir, lastPerp)
  ---@type string
  local nmCase = prop.nm

  local wdth

  ---@type Quad
  local pastQd

  if (nmCase == "Wire") or (nmCase == "Zero-G Wire") then
    wdth = data.settings.thickness / 2.0


    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {
    --   pastQd[1] - gRenderCameraTilePos*20,
    --   pastQd[2] - gRenderCameraTilePos*20,
    --   pastQd[3] - gRenderCameraTilePos*20,
    --   pastQd[4] - gRenderCameraTilePos*20
    -- }

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      lastPos + lastPerp * wdth,
      lastPos - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    member("layer" .. tostring(math.abs(dp))).image:copyPixels(member("pxl").image, pastQd, rect(0, 0, 1, 1),
      { color = color(255, 0, 0) })
  elseif (nmCase == "Christmas Wire") then
    wdth = 8.5
    -- pastQd = {pos + perp*wdth, pos - perp*wdth, lastPos - lastPerp*wdth, lastPos + lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos + perp * wdth,
      pos - perp * wdth,
      lastPos - lastPerp * wdth,
      lastPos + lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    member("layer" .. tostring(dp)).image:copyPixels(member("christmasWireGraf" .. altGrafLG).image, pastQd,
      rect(0, 1, 17, 25), { ink = 36 })
    member("gradientA" .. tostring(dp)).image:copyPixels(member("christmasWireGrad").image, pastQd, rect(0, 1, 17, 25),
      { ink = 39 })
    member("gradientB" .. tostring(dp)).image:copyPixels(member("christmasWireGrad").image, pastQd, rect(0, 1, 17, 25),
      { ink = 39 })
    if altGrafLG == "1" then
      altGrafLG = "2"
    else
      altGrafLG = "1"
    end
  elseif (nmCase == "Ornate Wire") then
    wdth = 8.5
    -- pastQd = {pos + perp*wdth, pos - perp*wdth, lastPos - lastPerp*wdth, lastPos + lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos + perp * wdth,
      pos - perp * wdth,
      lastPos - lastPerp * wdth,
      lastPos + lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    local rcTc = rect(0, 1, 17, 25)
    member("layer" .. tostring(dp)).image:copyPixels(member("tangledWireGraf").image, pastQd, rcTc, { ink = 36 })
    member("gradientA" .. tostring(dp)).image:copyPixels(member("tangledWireGrad").image, pastQd, rcTc, { ink = 39 })
    member("gradientB" .. tostring(dp)).image:copyPixels(member("tangledWireGrad").image, pastQd, rcTc, { ink = 39 })
  elseif nmCase == "Tube" then
    wdth = 5.0

    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp* wdth,
      pos + perp* wdth,
      lastPos + lastPerp* wdth,
      lastPos - lastPerp* wdth
    ) - gRenderCameraTilePos * 20

    for a = 1, 4 do
      if (dp + a <= 30) then
        member("layer" .. tostring(dp + a - 1)).image:copyPixels(member("tubeGraf").image, pastQd,
          rect(0, (a - 1) * 10, 10, a * 10), { ink = 36 })
      else
        break
      end
    end
  elseif nmCase == "ThickWire" then
    wdth = 2
    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      lastPos + lastPerp * wdth,
      lastPos - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 1, 3 do
      if (dp + a <= 30) then
        member("layer" .. tostring(dp + a - 1)).image:copyPixels(member("thickWireGraf").image, pastQd,
          rect(0, (a - 1) * 4, 4, a * 4), { ink = 36 })
      else
        break
      end
    end
  elseif nmCase == "RidgedTube" then
    wdth = 5
    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      lastPos + lastPerp * wdth,
      lastPos - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 1, 4 do
      if (dp + a <= 30) then
        member("layer" .. tostring(dp + a - 1)).image:copyPixels(member("ridgedTubeGraf").image, pastQd,
          rect(0, (a - 1) * 10, 5, a * 10), { ink = 36 })
      else
        break
      end
    end
  elseif nmCase == "Fuel Hose" or nmCase == "Zero-G Tube" then
    wdth = 7
    local jointSize = 6
    local col = 0

    if (prop.nm == "Zero-G Tube") then
      wdth = 6
      jointSize = 4
      if (data.settings.applyColor == 1) then
        col = 1
        gAnyDecals = 1
      end
    end

    local myPerp = lastPerp
    -- pastQd = {pos - myPerp*wdth, pos + myPerp*wdth, lastPos + myPerp*wdth, lastPos - myPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - myPerp * wdth,
      pos + myPerp * wdth,
      pos + myPerp * wdth,
      pos - myPerp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 1, 5 do
      if (dp + a <= 30) then
        member("layer" .. tostring(dp + a - 1)).image:copyPixels(member("fuelHoseGraf").image, pastQd,
          rect(0, 1 + (a - 1) * 16, 14, 1 + a * 16), { ink = 36 })
        if (col == 1) then
          member("layer" .. tostring(dp + a - 1) .. "dc").image:copyPixels(member("fuelHoseCol").image, pastQd,
            rect(0, 1 + (a - 1) * 16, 14, 1 + a * 16), { ink = 36 })
        end
      else
        break
      end
    end

    for a = 1, 4 do
      if (dp + a <= 29) then
        member("layer" .. tostring(dp + a)).image:copyPixels(member("fuelHoseJoint").image,
          rect(pos, pos) + rect(-jointSize, -jointSize, jointSize, jointSize) -
          rect(gRenderCameraTilePos * 20, gRenderCameraTilePos * 20), rect(0, 1 + (a - 1) * 12, 12, 1 + a * 12), { ink = 36 })
      else
        break
      end
    end
  elseif nmCase == "Broken Fuel Hose" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
    local dst = fiffigt.diag(pos, lastPos)

    for b = 0, 2 do
      wdth = 5

      local pntA = pos + dr * (dst / 3.0) * b
      local pntB = pos + dr * (dst / 3.0) * (b + 1)

      local Aprp = fiffigt.moveToPoint(point(0, 0),
        point(fiffigt.lerp(lastPerp.x, perp.x, b / 3.0), fiffigt.lerp(lastPerp.y, perp.y, b / 3.0)), 1.0)
      local Bprp = fiffigt.moveToPoint(point(0, 0),
        point(fiffigt.lerp(lastPerp.x, perp.x, (b + 1) / 3.0), fiffigt.lerp(lastPerp.y, perp.y, (b + 1) / 3.0)), 1.0)

      -- pastQd = {pntA - Aprp*wdth, pntA + Aprp*wdth, pntB + Bprp*wdth, pntB - Bprp*wdth}
      -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

      pastQd = quad(
        pntA - Aprp * wdth,
        pntA + Aprp * wdth,
        pntB + Bprp * wdth,
        pntB - Bprp * wdth
      ) - gRenderCameraTilePos * 20

      for a = 2, 5 do
        if (dp + a <= 29) then
          member("layer" .. tostring(dp + a)).image:copyPixels(member("ridgedTubeGraf").image, pastQd,
            rect(0, (a - 1) * 10, 5, a * 10), { ink = 36 })
        else
          break
        end
      end
    end


    if (random(5) < 4) then
      wdth = 7
      local myPerp = lastPerp
      -- pastQd = {pos - myPerp*wdth, pos + myPerp*wdth, lastPos + myPerp*wdth, lastPos - myPerp*wdth}
      -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

      pastQd = quad(
        pos - myPerp * wdth,
        pos + myPerp * wdth,
        lastPos + myPerp * wdth,
        lastPos - myPerp * wdth
      ) - gRenderCameraTilePos * 20

      for a = 1, 5 do
        if (dp + a <= 30) then
          member("layer" .. tostring(dp + a - 1)).image:copyPixels(member("fuelHoseGraf").image, pastQd,
            rect(0, 1 + (a - 1) * 16, 14, 1 + a * 16), { ink = 36 })
        else
          break
        end
      end

      for a = 1, 4 do
        if (dp + a <= 29) then
          member("layer" .. tostring(dp + a)).image:copyPixels(member("fuelHoseJoint").image,
            rect(pos, pos) + rect(-6, -6, 6, 6) - rect(gRenderCameraTilePos * 20, gRenderCameraTilePos * 20),
            rect(0, 1 + (a - 1) * 12, 12, 1 + a * 12), { ink = 36 })
        else
          break
        end
      end
    end
  elseif nmCase == "Large Chain" or nmCase == "Large Chain 2" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
    local dst = fiffigt.diag(pos, lastPos)
    
    local isEvent = (num % 2) == 0
    
    if isEvent then
      wdth = 10
    else
      wdth = 3.5
    end

    local pntA = lastPos + dr * 11
    local pntB = pos - dr * 11

    -- pastQd = {pntA - lastPerp*wdth, pntA + lastPerp*wdth, pntB + lastPerp*wdth, pntB - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    -- lastPerp had to be negated and I don't know what messed with it.

    pastQd = quad(
      pntA + lastPerp * wdth,
      pntA - lastPerp * wdth,
      pntB - lastPerp * wdth,
      pntB + lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    if prop.nm == "Large Chain" then
      local graph = member("largeChainGraf").image
      local hgraph = member("largeChainGrafHighLight").image
      
      for a = 0, 5 do
        local pstDp = spelrelaterat.restrict(dp + a, 0, 29)
        member("layer" .. tostring(pstDp)).image:copyPixels(graph, pastQd, rect(toint(not isEvent) * 20, 1 + a * 50, 20 + toint(not isEvent) * 7, 1 + (a + 1) * 50), { ink = 36 })
        member("layer" .. tostring(pstDp)).image:copyPixels(hgraph, pastQd - point(2, 2), rect(toint(not isEvent) * 20, 1 + a * 50, 20 + toint(not isEvent) * 7, 1 + (a + 1) * 50), { ink = 36 })

        pstDp = spelrelaterat.restrict(dp + 4 + a, 0, 29)
        local b = 5 - a
        member("layer" .. tostring(pstDp)).image:copyPixels(graph, pastQd, rect(toint(not isEvent) * 20, 1 + b * 50, 20 + toint(not isEvent) * 7, 1 + (b + 1) * 50), { ink = 36 })
        member("layer" .. tostring(pstDp)).image:copyPixels(hgraph, pastQd - point(2, 2), rect(toint(not isEvent) * 20, 1 + b * 50, 20 + toint(not isEvent) * 7, 1 + (b + 1) * 50), { ink = 36 })
      end
    else
      local graph = member("largeChainGraf2").image
      local hgraph = member("largeChainGraf2HighLight").image

      for a = 0, 5 do
        local pstDp = spelrelaterat.restrict(dp + a, 0, 29)
        member("layer" .. tostring(pstDp)).image:copyPixels(graph, pastQd,
          rect(toint(not isEvent) * 20, 1 + a * 50, 20 + toint(not isEvent) * 7, 1 + (a + 1) * 50), { ink = 36 })
        member("layer" .. tostring(pstDp)).image:copyPixels(hgraph,
          pastQd - point(2, 2), rect(toint(not isEvent) * 20, 1 + a * 50, 20 + toint(not isEvent) * 7, 1 + (a + 1) *
        50), { ink = 36 })

        pstDp = spelrelaterat.restrict(dp + 4 + a, 0, 29)
        local b = 5 - a
        member("layer" .. tostring(pstDp)).image:copyPixels(graph, pastQd,
          rect(toint(not isEvent) * 20, 1 + b * 50, 20 + toint(not isEvent) * 7, 1 + (b + 1) * 50), { ink = 36 })
        member("layer" .. tostring(pstDp)).image:copyPixels(hgraph,
          pastQd - point(2, 2), rect(toint(not isEvent) * 20, 1 + b * 50, 20 + toint(not isEvent) * 7, 1 + (b + 1) *
        50), { ink = 36 })
      end
    end
  elseif nmCase == "Big Chain" or nmCase == "Chunky Chain" then
    me.renderBigChainSegment(num, dp, lastPos, pos)
  elseif nmCase == "Bike Chain" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
    local dst = fiffigt.diag(pos, lastPos)
    wdth = 17

    local pntA = lastPos + dr * 17
    local pntB = pos - dr * 17

    -- pastQd = {pntA - lastPerp*wdth, pntA + lastPerp*wdth, pntB + lastPerp*wdth, pntB - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pntA - lastPerp * wdth,
      pntA + lastPerp * wdth,
      pntB + lastPerp * wdth,
      pntB - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    require('levelRendering').renderBeveledImage(member("BikeChainBolt").image, dp,
      { lastPos + point(-8, -8) - gRenderCameraTilePos * 20, lastPos + point(8, -8) - gRenderCameraTilePos * 20, lastPos +
      point(8, 8) - gRenderCameraTilePos * 20, lastPos + point(-8, 8) - gRenderCameraTilePos * 20 }, 2)

    local pstDp
    for a = 1, 9 do
      pstDp = spelrelaterat.restrict(dp + a, 0, 29)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BikeChainBolt").image,
        rect(lastPos, lastPos) + rect(-8, -8, 8, 8) - rect(gRenderCameraTilePos * 20, gRenderCameraTilePos * 20),
        member("BikeChainBolt").image.rect, { ink = 36, color = color(0, 255, 0) })
    end

    if ((num % 2) == 0) then
      pstDp = spelrelaterat.restrict(dp + 1, 0, 29)
      levelRendering.renderBeveledImage(member("BikeChainSegment").image, pstDp, pastQd, 1)
      pstDp = spelrelaterat.restrict(dp + 2, 0, 29)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BikeChainSegment").image, pastQd,
        member("BikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 8, 0, 29)
      levelRendering.renderBeveledImage(member("BikeChainSegment").image, pstDp, pastQd, 1)
      pstDp = spelrelaterat.restrict(dp + 9, 0, 29)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BikeChainSegment").image, pastQd,
        member("BikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    else
      pstDp = spelrelaterat.restrict(dp + 3, 0, 29)
      levelRendering.renderBeveledImage(member("BikeChainSegment").image, pstDp, pastQd, 1)
      pstDp = spelrelaterat.restrict(dp + 4, 0, 29)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BikeChainSegment").image, pastQd,
        member("BikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 6, 0, 29)
      levelRendering.renderBeveledImage(member("BikeChainSegment").image, pstDp, pastQd, 1)
      pstDp = spelrelaterat.restrict(dp + 7, 0, 29)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BikeChainSegment").image, pastQd,
        member("BikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    end
  elseif nmCase == "Big Bike Chain" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
    local dst = fiffigt.diag(pos, lastPos)
    wdth = 34

    local pntA = lastPos + dr * 34
    local pntB = pos - dr * 34

    -- pastQd = {pntA - lastPerp*wdth, pntA + lastPerp*wdth, pntB + lastPerp*wdth, pntB - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pntA - lastPerp * wdth,
      pntA + lastPerp * wdth,
      pntB + lastPerp * wdth,
      pntB - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    -- levelRendering.renderBeveledImage(member("BigBikeChainBolt").image, dp,
    --   { lastPos + point(-16, -16) - gRenderCameraTilePos * 20, lastPos + point(16, -16) - gRenderCameraTilePos * 20,
    --     lastPos + point(16, 16) - gRenderCameraTilePos * 20, lastPos + point(-16, 16) - gRenderCameraTilePos * 20 }, 2)

    copyPixelsBevel(
      member('layer'..dp).image, 
      member("BigBikeChainBolt").image, 
      quad(
        lastPos + point(-16, -16),
        lastPos + point(16, -16),
        lastPos + point(16, 16),
        lastPos + point(-16, 16)
      ) - gRenderCameraTilePos * 20, 
      member("BigBikeChainBolt").image.rect, 
      2
    )
    if (num == 1) then
      return
    end

    local pstDp

    for a = 1, 9 do
      pstDp = spelrelaterat.restrict(dp + a, 0, 58)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BigBikeChainBolt").image,
        rect(lastPos, lastPos) + rect(-16, -16, 16, 16) - rect(gRenderCameraTilePos * 20, gRenderCameraTilePos * 20),
        member("BigBikeChainBolt").image.rect, { ink = 36, color = color(0, 255, 0) })
    end

    if ((num % 2) == 0) then
      pstDp = spelrelaterat.restrict(dp + 1, 0, 58)
      -- levelRendering.renderBeveledImage(member("BigBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("BigBikeChainSegment").image, pastQd, member("BigBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 2, 0, 58)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BigBikeChainSegment").image, pastQd,
        member("BigBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 8, 0, 58)
      -- levelRendering.renderBeveledImage(member("BigBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("BigBikeChainSegment").image, pastQd, member("BigBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 9, 0, 58)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BigBikeChainSegment").image, pastQd,
        member("BigBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    else
      pstDp = spelrelaterat.restrict(dp + 3, 0, 58)
      -- levelRendering.renderBeveledImage(member("BigBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("BigBikeChainSegment").image, pastQd, member("BigBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 4, 0, 58)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BigBikeChainSegment").image, pastQd,
        member("BigBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 6, 0, 58)
      -- levelRendering.renderBeveledImage(member("BigBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("BigBikeChainSegment").image, pastQd, member("BigBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 7, 0, 58)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("BigBikeChainSegment").image, pastQd,
        member("BigBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    end
  elseif nmCase == "Huge Bike Chain" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
    local dst = fiffigt.diag(pos, lastPos)
    wdth = 68

    local pntA = lastPos + dr * 68
    local pntB = pos - dr * 68

    -- pastQd = {pntA - lastPerp*wdth, pntA + lastPerp*wdth, pntB + lastPerp*wdth, pntB - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pntA - lastPerp * wdth,
      pntA + lastPerp * wdth,
      pntB + lastPerp * wdth,
      pntB - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    -- levelRendering.renderBeveledImage(member("HugeBikeChainBolt").image, dp,
    --   { lastPos + point(-32, -32) - gRenderCameraTilePos * 20, lastPos + point(32, -32) - gRenderCameraTilePos * 20,
    --     lastPos + point(32, 32) - gRenderCameraTilePos * 20, lastPos + point(-32, 32) - gRenderCameraTilePos * 20 }, 2)

    copyPixelsBevel(
      member('layer'..dp).image, 
      member("HugeBikeChainBolt").image, 
      quad(
        lastPos + point(-32, -32),
        lastPos + point(32, -32),
        lastPos + point(32, 32),
        lastPos + point(-32, 32)
      ) - gRenderCameraTilePos * 20, 
      member("HugeBikeChainBolt").image.rect, 
      2
    )

    if (num == 1) then
      return
    end

    local pstDp

    for a = 1, 9 do
      pstDp = spelrelaterat.restrict(dp + a, 0, 116)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("HugeBikeChainBolt").image,
        rect(lastPos, lastPos) + rect(-32, -32, 32, 32) - rect(gRenderCameraTilePos * 20, gRenderCameraTilePos * 20),
        member("HugeBikeChainBolt").image.rect, { ink = 36, color = color(0, 255, 0) })
    end

    if ((num % 2) == 0) then
      pstDp = spelrelaterat.restrict(dp + 1, 0, 116)
      -- levelRendering.renderBeveledImage(member("HugeBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("HugeBikeChainSegment").image, pastQd, member("HugeBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 2, 0, 116)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("HugeBikeChainSegment").image, pastQd,
        member("HugeBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 8, 0, 116)
      -- levelRendering.renderBeveledImage(member("HugeBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("HugeBikeChainSegment").image, pastQd, member("HugeBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 9, 0, 116)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("HugeBikeChainSegment").image, pastQd,
        member("HugeBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    else
      pstDp = spelrelaterat.restrict(dp + 3, 0, 116)
      -- levelRendering.renderBeveledImage(member("HugeBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("HugeBikeChainSegment").image, pastQd, member("HugeBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 4, 0, 116)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("HugeBikeChainSegment").image, pastQd,
        member("HugeBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })

      pstDp = spelrelaterat.restrict(dp + 6, 0, 116)
      -- levelRendering.renderBeveledImage(member("HugeBikeChainSegment").image, pstDp, pastQd, 1)
      copyPixelsBevel(member('layer'..pstDp).image, member("HugeBikeChainSegment").image, pastQd, member("HugeBikeChainSegment").image.rect, 1)
      pstDp = spelrelaterat.restrict(dp + 7, 0, 116)
      member("layer" .. tostring(pstDp)).image:copyPixels(member("HugeBikeChainSegment").image, pastQd,
        member("HugeBikeChainSegment").image.rect, { ink = 36, color = color(0, 255, 0) })
    end
  elseif nmCase == "Fat Hose" then
    wdth = 20
    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      lastPos + lastPerp * wdth,
      lastPos - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 0, 4 do
      if (dp + a + 1 <= 29) then
        member("layer" .. tostring(dp + a + 1)).image:copyPixels(member("fatHoseGraf").image, pastQd,
          rect(40, a * 40, 80, (a + 1) * 40), { ink = 36 })
      else
        break
      end
    end

    -- pastQd = {pos - perp*wdth - dir*5, pos + perp*wdth - dir*5, pos + perp*wdth + dir*5, pos - perp*wdth + dir*5}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth - dir * 5,
      pos + perp * wdth - dir * 5,
      pos + perp * wdth + dir * 5,
      pos - perp * wdth + dir * 5
    ) - gRenderCameraTilePos * 20

    for a = 0, 5 do
      if (dp + a <= 29) then
        member("layer" .. tostring(dp + a)).image:copyPixels(member("fatHoseGraf").image, pastQd,
          rect(0, a * 10, 40, (a + 1) * 10), { ink = 36 })
      else
        break
      end
    end

    local mdPnt = (pos + lastPos) / 2
    mdPnt = mdPnt - gRenderCameraTilePos * 20
    member("layer" .. tostring(math.abs(dp))).image:copyPixels(member("fatHoseGraf").image,
      rect(mdPnt, mdPnt) + rect(-5, -5, 5, 5), rect(80, 0, 90, 10), { ink = 36 })
  elseif nmCase == "Wire Bunch" or nmCase == "Wire Bunch 2" then
    local dr = fiffigt.moveToPoint(pos, lastPos, 1.0)     -- previously undefined
    if ((num % 2) == 0) or (num == #data.points) then
      dr = fiffigt.moveToPoint(pos, lastPos, 1.0)
      -- global wireBunchSav

      if wireBunchSav == nil then
        wireBunchSav = list()
        wireBunchSav:add(list({ lastPos, lastDir }))
        for i = 1, 19 do
          wireBunchSav:add(fiffigt.degToVec(random(360)))
        end
      end

      local possiblePositions = list()
      for i = 1, 10 do
        possiblePositions:add(fiffigt.degToVec((i / 10.0) * 360))
      end
      for i = 1, 6 do
        possiblePositions:add(fiffigt.degToVec((i / 6.0) * 360) * 0.75)
      end
      for i = 1, 3 do
        possiblePositions:add(fiffigt.degToVec((i / 3.0) * 360) * 0.5)
      end

      local useLastPos = wireBunchSav[1][1]
      local useLastDir = wireBunchSav[1][2]
      local useLastPerp = fiffigt.giveDirFor90degrToLine(-useLastDir, useLastDir)

      for i = 1, 19 do
        local aPoint = wireBunchSav[i + 1]
        local indx = random(#possiblePositions)
        local bPoint = possiblePositions[indx]
        possiblePositions:deleteAt(indx)

        local aPos = useLastPos + useLastPerp * aPoint.x * 18

        local aDp = toint(dp + 2.5 + aPoint.y * 2.5) + 1

        local bPos = pos + perp * bPoint.x * 18
        local bDp = toint(dp + 2.5 + bPoint.y * 2.5) + 1

        local aHandle = aPos + useLastDir * fiffigt.lerp(fiffigt.diag(aPos, bPos) / 2.0, (40 + random(40)), 0.5)
        local bHandle = bPos - dir * fiffigt.lerp(fiffigt.diag(aPos, bPos) / 2.0, (40 + random(40)), 0.5)

        local c2 = fiffigt.LerpVector(aPoint, bPoint, 0.5)
        local cPos = lastPos + lastPerp * c2.x * 18

        aHandle = fiffigt.LerpVector(aHandle, cPos, 0.5)
        bHandle = fiffigt.LerpVector(bHandle, cPos, 0.5)

        if (random(35) == 1) then
          bPos = aPos + useLastDir * 60.0 + fiffigt.degToVec(random(360)) * random(60)
          bHandle = fiffigt.LerpVector(bHandle, bPos + fiffigt.degToVec(random(360)) * random(30), 0.5)
        elseif (random(35) == 1) then
          aPos = bPos - dir * 60.0 + fiffigt.degToVec(random(360)) * random(60)
          aHandle = fiffigt.LerpVector(aHandle, aPos + fiffigt.degToVec(random(360)) * random(30), 0.5)
        end

        me.DrawBezierWire(lastDir, aPos, aHandle, bPos, bHandle, aDp, bDp)



        wireBunchSav[i + 1] = bPoint
      end
      wireBunchSav[1][1] = pos
      wireBunchSav[1][2] = dir
    end

    wdth = 20
    -- pastQd = {pos -dr*3.5 - perp*wdth, pos -dr*3.5 + perp*wdth, pos + dr*3.5 + perp*wdth, pos +dr*3.5 - perp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - dr * 3.5 - perp * wdth,
      pos - dr * 3.5 + perp * wdth,
      pos + dr * 3.5 + perp * wdth,
      pos + dr * 3.5 - perp * wdth
    ) - gRenderCameraTilePos * 20

    local mnClamp = 0
    if (dp >= 6) then
      mnClamp = 6
    end

    for a2 = 0, 10 do
      local a = 10 - a2
      if (prop.nm == "Wire Bunch") then
        member("layer" .. tostring(spelrelaterat.restrict(dp + a - 1, mnClamp, 29))).image:copyPixels(
          member("wireBunchGraf").image,
          pastQd,
          rect(0, 1 + a * 7, 42, 1 + (a + 1) * 7),
          { ink = 36 }
        )
      else
        member("layer" .. tostring(spelrelaterat.restrict(dp + a - 1, mnClamp, 29))).image:copyPixels(
          member("wireBunchGraf2").image,
          pastQd,
          rect(0, a * 7, 42, (a + 1) * 7),
          { ink = 36 }
        )
      end
    end

    if (num == #data.points) then
      wireBunchSav = nil
    end
  elseif nmCase == "Big Big Pipe" then
    wdth = 20
    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      lastPos + lastPerp * wdth,
      lastPos - lastPerp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 0, 4 do
      if (dp + a + 1 <= 29) then
        member("layer" .. tostring(dp + a + 1)).image:copyPixels(member("bigBigPipeGraf").image, pastQd,
          rect(40, a * 40, 80, (a + 1) * 40), { ink = 36 })
      else
        break
      end
    end

    -- pastQd = {pos - perp*wdth - dir*5, pos + perp*wdth - dir*5, pos + perp*wdth + dir*5, pos - perp*wdth + dir*5}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth - dir * 5,
      pos + perp * wdth - dir * 5,
      pos + perp * wdth + dir * 5,
      pos - perp * wdth + dir * 5
    ) - gRenderCameraTilePos * 20

    for a = 0, 5 do
      if (dp + a <= 29) then
        member("layer" .. tostring(dp + a)).image:copyPixels(member("bigBigPipeGraf").image, pastQd,
          rect(0, a * 10, 40, (a + 1) * 10), { ink = 36 })
      else
        break
      end
    end

    local mdPnt = (pos + lastPos) / 2
    mdPnt = mdPnt - gRenderCameraTilePos * 20
    member("layer" .. tostring(dp)).image:copyPixels(member("bigBigPipeGraf").image, rect(mdPnt, mdPnt) + rect(-5, -5, 5,
      5), rect(80, 0, 90, 10), { ink = 36 })
  elseif nmCase == "Ring Chain" then
    wdth = 20
    -- pastQd = {pos - perp*wdth, pos + perp*wdth, lastPos + lastPerp*wdth, lastPos - lastPerp*wdth}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth,
      pos + perp * wdth,
      pos + perp * wdth,
      pos - perp * wdth
    ) - gRenderCameraTilePos * 20

    for a = 0, 4 do
      if (dp + a <= 29) then
        member("layer" .. tostring(dp + a)).image:copyPixels(member("ringChainGraf").image, pastQd,
          rect(40, a * 40, 80, (a + 1) * 40), { ink = 36 })
      else
        break
      end
    end

    -- pastQd = {pos - perp*wdth - dir*5, pos + perp*wdth - dir*5, pos + perp*wdth + dir*5, pos - perp*wdth + dir*5}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth - dir * 5,
      pos + perp * wdth - dir * 5,
      pos + perp * wdth + dir * 5,
      pos - perp * wdth + dir * 5
    ) - gRenderCameraTilePos * 20

    for a = 0, 4 do
      if (dp + a <= 29) then
        member("layer" .. tostring(dp + a)).image:copyPixels(member("ringChainGraf").image, pastQd,
          rect(0 - 19, a * 10, 40 - 19, (a + 1) * 10), { ink = 36 })
      else
        break
      end
    end

    local mdPnt = (pos + lastPos) / 2
    mdPnt = mdPnt - gRenderCameraTilePos * 20
    member("layer" .. tostring(dp)).image:copyPixels(member("ringChainGraf").image, rect(mdPnt, mdPnt) + rect(-5, -5, 5,
      5), rect(80, 0, 90, 10), { ink = 36 })
  end

  --     case prop.nm of
  --     "wire", "Zero-G Wire":
  --     "Christmas Wire":
  --     "Ornate Wire":
  --     "tube":
  --     "ThickWire":
  --     "RidgedTube":
  --     "Fuel Hose", "Zero-G Tube":
  --     "Broken Fuel Hose":
  --     "Large Chain", "Large Chain 2":
  --     "Big Chain", "Chunky Chain":
  --     "Bike Chain":
  --     "Big Bike Chain":
  --     "Huge Bike Chain":
  --     "Fat Hose":
  --     "Wire Bunch", "Wire Bunch 2":
  --     "Big Big Pipe":
  --     "Ring Chain":
  --   end case
end

-- global wireBunchSav

---comment
---@param startDir point
---@param A point
---@param aHandle point
---@param B point
---@param bHandle point
---@param aDp number
---@param bDp number
function me.DrawBezierWire(startDir, A, aHandle, B, bHandle, aDp, bDp)
  ---@type number
  local repeats
  ---@type point
  local lastdir
  ---@type point
  local lastpos
  ---@type point
  local lastperp
  ---@type point
  local pos
  ---@type point
  local dir
  ---@type point
  local perp
  ---@type number
  local wdth
  ---@type Quad
  local pastQd
  ---@type number
  local myDp

  repeats = toint(fiffigt.diag(A, B) / 5.0)
  local lastDir = startDir
  local lastPos = A - startDir
  local lastPerp = fiffigt.giveDirFor90degrToLine(lastPos, A)

  for i = 1, repeats do
    pos = fiffigt.Bezier(A, aHandle, B, bHandle, i / repeats)
    dir = fiffigt.moveToPoint(lastPos, pos, 1.0)
    perp = fiffigt.giveDirFor90degrToLine(lastPos, pos)

    wdth = 2
    -- pastQd = {pos - perp*wdth + dir, pos + perp*wdth + dir, lastPos + lastPerp*wdth - lastDir, lastPos - lastPerp*wdth - lastDir}
    -- pastQd = {pastQd[1] - gRenderCameraTilePos*20, pastQd[2] - gRenderCameraTilePos*20, pastQd[3] - gRenderCameraTilePos*20, pastQd[4] - gRenderCameraTilePos*20}

    pastQd = quad(
      pos - perp * wdth + dir,
      pos + perp * wdth + dir,
      lastPos + lastPerp * wdth - lastDir,
      lastPos - lastPerp * wdth - lastDir
    ) - gRenderCameraTilePos * 20

    myDp = toint(fiffigt.lerp(aDp, bDp, i / repeats))

    for i2 = 1, 3 do
      if (myDp + i2 <= 30) then
        member("layer" .. tostring(myDp + i2 - 1)).image:copyPixels(member("thickWireGraf").image, pastQd,
          rect(0, (i2 - 1) * 4, 4, i2 * 4), { ink = 36 })
      else
        break
      end
    end

    lastPos = pos
    lastDir = dir
    lastPerp = perp
  end
end

---comment
---@param prop table
---@param qd Quad
---@param propData table
---@param dp number
---@param propImage Image
function me.initRenderSoftProp(prop, qd, propData, dp, propImage)
  ---@type number
  local lft
  ---@type number
  local tp
  ---@type number
  local rght
  ---@type number
  local bttm
  ---@type point
  local p
  ---@type rect
  local pasteRect
  ---@type point
  local offsetPnt
  ---@type rect
  local getRect

  lft = qd.topleft.x
  tp = qd.topleft.y
  rght = qd.topleft.x
  bttm = qd.topleft.y

  local enclosed = enclose(qd)

  lft = enclosed.left
  tp = enclosed.top
  rght = enclosed.right
  bttm = enclosed.bottom

  -- for _,p in ipairs(qd) do
  --   if(p.x < lft) then
  --     lft = p.x
  --   end
  --   if(p.x > rght) then
  --     rght = p.x
  --   end
  --   if(p.y < tp) then
  --     tp = p.y
  --   end
  --   if(p.y > bttm) then
  --     bttm = p.y
  --   end
  -- end

  pasteRect = rect(lft, tp, rght, bttm)
  offsetPnt = point(lft, tp)
  member("softPropRender").image = image(pasteRect.width, pasteRect.height)

  getRect = propImage.rect
  if (prop.tp == "variedSoft") then
    getRect = rect((propData.settings.variation - 1) * prop.pxlSize.x, 0, propData.settings.variation * prop.pxlSize.x,
      prop.pxlSize.y) + rect(0, 1, 0, 1)
  end

  if (prop.tp == "coloredSoft") then
    getRect = rect(0, 0, prop.pxlSize.x, prop.pxlSize.y) + rect(0, 1, 0, 1)
  end

  member("softPropRender").image:copyPixels(propImage, qd - offsetPnt, getRect)

  if ((prop.tp == "variedSoft") or (prop.tp == "coloredSoft")) and (prop.colorize == 1) and tobool(propData.settings.applyColor) then
    gAnyDecals = true
    member("softPropColor").image = image(pasteRect.width, pasteRect.height)
    member("softPropColor").image:copyPixels(propImage, qd - offsetPnt,
      getRect + rect(0, getRect.height, 0, getRect.height))
  end

  if (getPos(prop.tags, "effectColorA") > 0 or getPos(prop.tags, "effectColorB") > 0) then
    member("softPropGrad").image = image(pasteRect.width, pasteRect.height)
    member("softPropGrad").image:copyPixels(propImage, qd - offsetPnt, getRect +
    rect(0, getRect.height, 0, getRect.height))
  end

  ---@type color
  local clr = color(0, 0, 0)
  if (propData.settings["color"] or 0) > 0 then
    --   global gPEcolors
    clr = gPEcolors[propData.settings.color][2]
    gAnyDecals = 1
  end

  softProp = map({ c = 0, pasteRect = pasteRect, prop = prop, propData = propData, dp = dp, clr = clr })

  --   for q = 0, 29 do
  --     sprite(50-q).color = color(0,0,0)
  --   end
end

---TODO: reimplement
function me.renderSoftProp()
  ---@type color
  local clr
  ---@type number
  local dpth
  ---@type number
  local renderFrom
  ---@type number
  local renderTo
  ---@type boolean
  local painted
  ---@type number
  local dp
  ---@type table
  local colornumstruct
  ---@type point
  local dir
  ---@type color
  local palCol
  ---@type number
  local ang
  ---@type number
  local dpthRemove
  ---@type color
  local clrzClr
  ---@type number
  local val

  local effectColorA = (getPos(softProp.prop.tags, "effectColorA") > 0)
  local effectColorB = (getPos(softProp.prop.tags, "effectColorB") > 0)

  for q2 = 0, softProp.pasteRect.width - 1 do
    clr = member("softPropRender").image:getPixel(q2, softProp.c)

    if (clr ~= color(255, 255, 255)) and ((clr.g > 0) or (softProp.prop.tp == "antimatter")) then
      dpth = clr.g / 255.0

      if (softProp.prop.tp == "antimatter") then
        renderFrom = softProp.dp
        renderTo = spelrelaterat.restrict(toint(softProp.dp + softProp.propData.settings.customDepth * (1.0 - dpth)), 0,
          29)
        painted = false
        for d = renderFrom, renderTo do
          dp = spelrelaterat.restrict(renderTo - d + renderFrom, 0, 29)

          if member("layer" .. dp).image:getPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top) ~= color(255, 255, 255) then
            member("layer" .. dp).image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top,
              color(255, 255, 255))

            if (painted == false) then
              for _, clrList in ipairs({ { color(255, 0, 0), -1 }, { color(0, 0, 255), 1 } }) do
                for _, dir in ipairs({ point(1, 0), point(1, -1), point(0, 1), point(2, 0), point(2, -2), point(0, 2) }) do
                  if member("layer" .. dp).image:getPixel(q2 + softProp.pasteRect.left + dir.x * clrList[2], softProp.c + softProp.pasteRect.top + dir.y * clrList[2]) ~= color(255, 255, 255) then
                    member("layer" .. dp).image:setPixel(q2 + softProp.pasteRect.left + dir.x * clrList[2],
                      softProp.c + softProp.pasteRect.top + dir.y * clrList[2], clrList[1])
                  end
                end
              end
              painted = true
            end
          end
        end
      else
        if (effectColorA) then
          palCol = color(255, 0, 255)
        elseif (effectColorB) then
          palCol = color(0, 255, 255)
        else
          palCol = color(0, 255, 0)
        end

        if not tobool(softProp.prop.selfShade) then
          if (effectColorA) then
            if (clr.b > (255.0 / 3.0) * 2.0) then
              palCol = color(255, 150, 255)
            elseif (clr.b < 255.0 / 3.0) then
              palCol = color(150, 0, 150)
            end
          elseif (effectColorB) then
            if (clr.b > (255.0 / 3.0) * 2.0) then
              palCol = color(150, 255, 255)
            elseif (clr.b < 255.0 / 3.0) then
              palCol = color(0, 150, 150)
            end
          else
            if (clr.b > (255.0 / 3.0) * 2.0) then
              palCol = color(0, 0, 255)
            elseif (clr.b < 255.0 / 3.0) then
              palCol = color(255, 0, 0)
            end
          end
        else
          ang = 0.0
          for a = 1, softProp.prop.smoothShading do
            for _, pnt in ipairs({ point(1, 0), point(1, 1), point(0, 1) }) do
              --  put dpth .. " " .. ang .. " " .. softPropDepth(point(q2, softProp.c)-pnt*a) .. " " .. softPropDepth(point(q2, softProp.c)+pnt*a)
              ang = ang + (dpth - me.softPropDepth(point(q2, softProp.c) - pnt * a)) +
              (me.softPropDepth(point(q2, softProp.c) + pnt * a) - dpth)
            end
          end
          ang = ang / (softProp.prop.smoothShading * 3.0)

          ang = ang * (1.0 - clr.r / 255.0)

          if (ang * 10.0 * (dpth ^ softProp.prop.depthAffectHilites) > softProp.prop.highLightBorder) then
            if (effectColorA) then
              palCol = color(255, 150, 255)
            elseif (effectColorB) then
              palCol = color(150, 255, 255)
            else
              palCol = color(0, 0, 255)
            end
          elseif (-ang * 10.0 > softProp.prop.shadowBorder) then
            if (effectColorA) then
              palCol = color(150, 0, 150)
            elseif (effectColorB) then
              palCol = color(0, 150, 150)
            else
              palCol = color(255, 0, 0)
            end
          end
        end

        dpth = 1.0 - dpth
        dpth = (dpth ^ softProp.prop.contourExp)

        dpthRemove = (dpth * softProp.propData.settings.customDepth)

        renderFrom = 0
        renderTo = 0

        if (softProp.prop.round) then
          renderFrom = softProp.dp + (dpthRemove / 2.0)
          renderTo = softProp.dp + softProp.propData.settings.customDepth - (dpthRemove / 2.0)
        else
          renderFrom = softProp.dp + dpthRemove
          renderTo = softProp.dp + softProp.propData.settings.customDepth
        end

        renderFrom = fiffigt.lerp(renderFrom, softProp.dp + dpthRemove, clr.r / 255.0)
        renderTo = fiffigt.lerp(renderTo, softProp.dp + dpthRemove, clr.r / 255.0)

        for dp = fiffigt.restrict(toint(renderFrom), 0, 29), fiffigt.restrict(toint(renderTo), 0, 29) do
          member("layer" .. dp).image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top, palCol)
        end

        clrzClr = color(255, 255, 255)

        if (softProp.clr ~= 0) then
          clrzClr = softProp.clr
        elseif (softProp.prop.tp == "variedSoft") then
          if (softProp.prop.colorize == 1) then
            if (softProp.propData.settings.applyColor) then
              clrzClr = member("softPropColor").image:getPixel(q2, softProp.c)
            end
          end
        elseif (softProp.prop.tp == "coloredSoft") then
          if (softProp.prop.colorize == 1) then
            if (softProp.propData.settings.applyColor) then
              clrzClr = member("softPropColor").image:getPixel(q2, softProp.c)
            end
          end
        end

        if (clrzClr ~= color(255, 255, 255)) then
          for dp = fiffigt.restrict(toint(renderFrom), 0, 29), fiffigt.restrict(toint(renderTo), 0, 29) do
            member("layer" .. dp .. "dc").image:setPixel(q2 + softProp.pasteRect.left, softProp.c +
            softProp.pasteRect.top, clrzClr)
          end
        end


        local gradOp = color(255, 255, 255)

        if (effectColorA or effectColorB) then
          gradOp = member("softPropGrad").image:getPixel(q2, softProp.c)
        end

        if (effectColorA and gradOp ~= color(255, 255, 255)) then
          for dp = fiffigt.restrict(toint(renderFrom), 0, 29), fiffigt.restrict(toint(renderTo), 0, 29) do
            member("gradientA" .. dp).image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top,
              gradOp)
          end
        elseif (effectColorB and gradOp ~= color(255, 255, 255)) then
          for dp = fiffigt.restrict(toint(renderFrom), 0, 29), fiffigt.restrict(toint(renderTo), 0, 29) do
            member("gradientB" .. dp).image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top,
              gradOp)
          end
        end
      end
    end
  end

  softProp.c = softProp.c + 1
  if (softProp.c >= softProp.pasteRect.height) then
    for q = 0, 29 do
      val = (q + 1.0) / 30.0
      --   sprite(50-q).color = color(val*255, val*255, val*255)
    end
    softProp = nil
  end
end

function me.renderSoftProp2()
  local effectColorA = (getPos(softProp.prop.tags, "effectColorA") > 0)
  local effectColorB = (getPos(softProp.prop.tags, "effectColorB") > 0)

  local effectColor = 0

  if effectColorA then
    effectColor = 1
  elseif effectColorB then
    effectColor = 2
  end

  for d = 0, softProp.propData.settings.customDepth do
    local normalizedDepth = d / softProp.propData.settings.customDepth

    copyPixelsSoftProp(
      member("layer" .. d + softProp.dp).image,
      member("softPropRender").image,
      softProp.pasteRect,
      normalizedDepth,
      effectColor,
      softProp.prop.selfShade,
      softProp.prop.smoothShading,
      softProp.prop.depthAffectHilites,
      softProp.prop.highLightBorder,
      softProp.prop.shadowBorder
    )
  end

  softProp = nil
end

---@param pxl point
---@return number
function me.softPropDepth(pxl)
  ---@type color
  local clr

  clr = member("softPropRender").image:getPixel(pxl.x, pxl.y)
  if (clr == color(255, 255, 255)) or (clr == color(0, 0, 0)) then
    return 0.0
  end

  return clr.g / 255.0
end

function me.renderESoftProp()
  for q2 = 0, softProp.pasteRect.width - 1 do
    local clr = member("softPropRender").image:getPixel(q2, softProp.c)
    local dpth

    if (clr ~= color(255, 255, 255)) then
      if (clr.g > 0) then
        dpth = clr.g / 255.0
      elseif (clr.b > 0) then
        dpth = clr.b / 255.0
      else
        dpth = clr.r / 255.0
      end

      local palCol = color(0, 255, 0)

      local ang = 0.0
      for a = 1, softProp.prop.smoothShading do
        for _, pnt in ipairs({ point(1, 0), point(1, 1), point(0, 1) }) do
          --  put dpth .. " " .. ang .. " " .. softPropDepth(point(q2, softProp.c)-pnt*a) .. " " .. softPropDepth(point(q2, softProp.c)+pnt*a)
          ang = ang + (dpth - me.EsoftPropDepth(point(q2, softProp.c) - pnt * a)) +
          (me.EsoftPropDepth(point(q2, softProp.c) + pnt * a) - dpth)
        end
      end
      ang = ang / (softProp.prop.smoothShading.float * 3.0)

      ang = ang * (1.0 / 255.0)

      if (ang * 10.0 * (dpth ^ softProp.prop.depthAffectHilites) > softProp.prop.highLightBorder) then
        palCol = color(0, 0, 255)
      elseif (-ang * 10.0 > softProp.prop.shadowBorder) then
        palCol = color(255, 0, 0)
      end

      dpth = 1.0 - dpth
      dpth = (dpth ^ softProp.prop.contourExp)

      local dpthRemove = (dpth * softProp.propData.settings.customDepth)

      local renderFrom = 0
      local renderTo = 0

      if (softProp.prop.round) then
        renderFrom = softProp.dp + (dpthRemove / 2.0)
        renderTo = softProp.dp + softProp.propData.settings.customDepth - (dpthRemove / 2.0)
      else
        renderFrom = softProp.dp + dpthRemove
        renderTo = softProp.dp + softProp.propData.settings.customDepth
      end

      renderFrom = fiffigt.lerp(renderFrom, softProp.dp + dpthRemove, clr.r / 255.0)
      renderTo = fiffigt.lerp(renderTo, softProp.dp + dpthRemove, clr.r / 255.0)

      for dp = spelrelaterat.restrict(toint(renderFrom), 0, 29), spelrelaterat.restrict(toint(renderTo), 0, 29) do
        member("layer" .. dp).image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top, palCol)
      end

      local clrzClr = color(255, 255, 255)

      if (softProp.clr ~= 0) then
        clrzClr = softProp.clr
      elseif (softProp.prop.tp == "variedSoft") then
        if (softProp.prop.colorize == 1) then
          if (softProp.propData.settings.applyColor) then
            clrzClr = member("softPropColor").image:getPixel(q2, softProp.c)
          end
        end
      elseif (softProp.prop.tp == "coloredSoft") then
        if (softProp.prop.colorize == 1) then
          if (softProp.propData.settings.applyColor) then
            clrzClr = member("softPropColor").image:getPixel(q2, softProp.c)
          end
        end
      end

      if (clrzClr ~= color(255, 255, 255)) then
        if (clr.b > 0) then
          clrzClr.g = 1
        elseif (clr.r > 0) then
          clrzClr.g = 2
        end

        for dp = spelrelaterat.restrict(toint(renderFrom), 0, 29), spelrelaterat.restrict(toint(renderTo), 0, 29) do
          member("layer" .. dp .. "dc").image:setPixel(q2 + softProp.pasteRect.left, softProp.c + softProp.pasteRect.top,
            clrzClr)
        end
      end
    end
  end

  softProp.c = softProp.c + 1
  if (softProp.c >= softProp.pasteRect.height) then
    for q = 0, 29 do
      -- val = (q+1.0)/30.0
      --   sprite(50-q).color = color(val*255, val*255, val*255)
    end
    softProp = nil
  end
end

---@param pxl point
---@return number
function me.EsoftPropDepth(pxl)
  local clr = member("softPropRender").image:getPixel(pxl.x, pxl.y)
  if (clr == color(255, 255, 255)) or (clr == color(0, 0, 0)) then
    return 0.0
  end
  if (clr.g > 0) then
    return clr.g / 255.0
  elseif (clr.b > 0) then
    return clr.b / 255.0
  else
    return clr.r / 255.0
  end
end

---@param qd Quad
function me.renderLongProp(qd, prop, data, dp)
  local A = (qd.topleft + qd.bottomleft) / 2.0
  local B = (qd.topright + qd.bottomright) / 2.0

  local dir = fiffigt.moveToPoint(A, B, 1.0)
  local perp = me.CorrectPerp(dir)
  local dist = fiffigt.diag(A, B)


  if (prop.tp == "customLong") then
    local lgt = prop.segmentLength
    local steps = ((dist / lgt) + 0.4999).integer
    local diffSeg = ((prop.pixelSize.y - lgt) + prop.pixelSize.x) * 0.5
    local sav2 = member("previewImprt")
    local colored = (prop.tags:getPos("colored") > 0)

    if (colored) then
      gAnyDecals = 1
    end

    local effectColorA = (prop.tags:getPos("effectColorA") > 0)
    local effectColorB = (prop.tags:getPos("effectColorB") > 0)
    local baseDp = dp
    local vari

    if tobool(prop.random) then
      vari = random(prop.vars) - 1
    else
      vari = 0
    end

    local prlAng = spelrelaterat.vecToRadLB(dir)
    local cosAng = diffSeg * math.cos(prlAng)
    local sinAng = diffSeg * math.sin(prlAng)
    for n = 1, steps do
      local ps = 0
      local dp = baseDp
      local posProp = A + (dir * lgt * n)
      local pastQd = spelrelaterat.rotateToQuadLB(
      rect(posProp, posProp) +
      rect(-prop.pixelSize.x * 0.5 - cosAng, -prop.pixelSize.y * 0.5 - sinAng, prop.pixelSize.x * 0.5 - cosAng,
        prop.pixelSize.y * 0.5 - sinAng), dir)

      for q = 1, #prop.repeatL do
        local gtRect = rect(0, 1, prop.pixelSize.x, prop.pixelSize.y + 1)
        gtRect = gtRect + rect(gtRect.width * vari, gtRect.height * ps, gtRect.width * vari, gtRect.height * ps)

        for q2 = 1, prop.repeatL[q] do
          local layerImg = member("layer" .. tostring(dp)).image

          local ctCase = prop.colorTreatment

          if ctCase == "standard" then
            layerImg:copyPixels(sav2.image, pastQd, gtRect, { ink = 36 })
            if (effectColorA) then
              member("gradientA" .. tostring(dp)).image:copyPixels(sav2.image, pastQd,
                gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 39 })
            end
            if (effectColorB) then
              member("gradientB" .. tostring(dp)).image:copyPixels(sav2.image, pastQd,
                gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 39 })
            end
          elseif ctCase == "bevel" then
            local dumpImg = image(gtRect.width, gtRect.height)
            dumpImg:copyPixels(sav2.image, dumpImg.rect, gtRect)
            local inverseImg = spelrelaterat.makeSilhoutteFromImg(dumpImg, 1)
            dumpImg = image(layerImg.width, layerImg.height)
            dumpImg:copyPixels(DRPxl, pastQd, rect(0, 0, 1, 1), { color = color(0, 255, 0) })

            for bbvl = 1, prop.bevel do
              for _, abvl in ipairs(DRBevelColors) do
                local a2mb = abvl[2] * bbvl
                dumpImg:copyPixels(inverseImg, pastQd + a2mb, inverseImg.rect, { color = abvl[1], ink = 36 })
              end
            end

            dumpImg:copyPixels(inverseImg, pastQd, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
            inverseImg = image(dumpImg.width, dumpImg.height)
            inverseImg:copyPixels(DRPxl, inverseImg.rect, rect(0, 0, 1, 1))
            inverseImg:copyPixels(DRPxl, pastQd, rect(0, 0, 1, 1), { color = color(255, 255, 255) })
            dumpImg:copyPixels(inverseImg, dumpImg.rect, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })
            layerImg:copyPixels(dumpImg, dumpImg.rect, dumpImg.rect, { ink = 36 })
          end

          --   case (prop.colorTreatment) of
          --     "standard":
          --     "bevel":
          --   end case
          if (colored) then
            if (effectColorA == false) then
              if (effectColorB == false) then
                member("layer" .. string(dp) .. "dc").image.copyPixels(sav2.image, pastQd,
                  gtRect + rect(prop.pixelSize.x * prop.vars, 0, prop.pixelSize.x * prop.vars, 0), { ink = 36 })
              end
            end
          end
          dp = dp + 1
          if (dp > 29) then
            break
          end
        end
        if (dp > 29) then
          break
        end
        ps = ps + 1
      end
      if tobool(prop.random) then
        vari = random(prop.vars) - 1
      else
        vari = vari + 1
        if (vari >= prop.vars) then
          vari = 0
        end
      end
    end
  else
    local nmCase = prop.nm

    if nmCase == "Cabinet Clamp" then
      local mem = member("clampSegmentGraf")
      local totalSegments = toint((dist / mem.image.height) - 0.5)
      local buffer = dist - (totalSegments * mem.image.height)

      local qd2 = { A - (perp * mem.image.width * 0.5) + (dir * buffer * 0.5), A + (perp * mem.image.width * 0.5) +
      (dir * buffer * 0.5), A + (perp * mem.image.width * 0.5), (A - perp * mem.image.width * 0.5) }
      member("layer" .. dp).image:copyPixels(member("pxl").image, qd2, rect(0, 0, 1, 1), { color = color(0, 255, 0) })
      qd2 = { B - (perp * mem.image.width * 0.5) - (dir * buffer * 0.5), B + (perp * mem.image.width * 0.5) -
      (dir * buffer * 0.5), B + (perp * mem.image.width * 0.5), (B - perp * mem.image.width * 0.5) }
      member("layer" .. dp).image:copyPixels(member("pxl").image, qd2, rect(0, 0, 1, 1), { color = color(0, 255, 0) })

      local d = buffer / 2.0

      for q = 1, totalSegments do
        local pnt = A + d * dir
        qd2 = { pnt - (perp * mem.image.width * 0.5) + (dir * mem.image.height), pnt + (perp * mem.image.width * 0.5) +
        (dir * mem.image.height), pnt + (perp * mem.image.width * 0.5), (pnt - perp * mem.image.width * 0.5) }
        member("layer" .. dp).image:copyPixels(mem.image, qd2, mem.image.rect, { color = color(0, 255, 0), ink = 36 })

        d = d + mem.image.height
      end

      mem = member("clampBoltGraf")
      member("layer" .. dp).image:copyPixels(mem.image,
        rect(A, A) + rect(-mem.image.width / 2, -mem.image.height / 2, mem.image.width / 2, mem.image.height / 2),
        mem.image.rect, { ink = 36 })
      member("layer" .. dp).image:copyPixels(mem.image,
        rect(B, B) + rect(-mem.image.width / 2, -mem.image.height / 2, mem.image.width / 2, mem.image.height / 2),
        mem.image.rect, { ink = 36 })
    elseif nmCase == "Stretched Pipe" then
      local steps = toint((fiffigt.diag(A, B) / 20.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 20.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-10, -11, 10, 11)
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:coPypixels(
        member("stretchedPipeGraf").image, rotate(rct, degDir), rect(0, 0, 20, 22), { ink = 36 })
      end
    elseif nmCase == "Stretched Wire" then
      local steps = toint((fiffigt.diag(A, B) / 2.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 2.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-1, -2, 1, 2)
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(
        member("stretchedWireGraf").image, rotate(rct, degDir), rect(0, 0, 2, 4), { ink = 36 })
      end
    elseif nmCase == "Twisted Thread" then
      local steps = toint((fiffigt.diag(A, B) / 20.0) + 0.4999)
      local ps = toint((fiffigt.diag(A, B) / 20.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 20.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-2.5, -10.0, 2.5, 10.0)
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(member("barbedWireGraf").image,
          rotate(rct, degDir), rect(0, 0, 5, 20), { ink = 36 })
      end
    elseif nmCase == "Long Barbed Wire" then
      local steps = toint((fiffigt.diag(A, B) / 20.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 20.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-2.5, -10.0, 2.5, 10.0)
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(member("barbedWireGraf").image,
          rotate(rct, degDir), rect(0, 0, 5, 20), { ink = 36 })
      end
    elseif nmCase == "Twisted Thread" then
      local steps = toint((fiffigt.diag(A, B) / 8.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 8.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-4, -4, 4, 4)
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(
        member("twistedThreadGraf").image, rotate(rct, degDir), rect(0, 0, 8, 8), { ink = 36 })
      end
    elseif nmCase == "Thick Chain" then
      local steps = toint((fiffigt.diag(A, B) / 12.0) + 0.4999)
      local ornt = random(2) - 1
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01
      for q = 1, steps do
        local pos = A + (dir * 12 * (q - stp))
        local rct
        local gtRect
        if tobool(ornt) then
          --   pos = (pnt+lastPnt)*0.5
          rct = rect(pos, pos) + rect(-6, -10, 6, 10)
          gtRect = rect(0, 0, 12, 20)
          ornt = 0
        else
          -- pos = (pnt+lastPnt)*0.5
          rct = rect(pos, pos) + rect(-2, -10, 2, 10)
          gtRect = rect(13, 0, 16, 20)
          ornt = 1
        end
        -- put rct
        member("layer" .. tostring(dp)).image:copyPixels(member("bigChainSegment").image, rotate(rct, degDir), gtRect,
          { color = color(255, 0, 5), ink = 36 })
        -- member("layer"..string(dp)).image.copypixels(member("bigChainSegment").image, rct, member("bigChainSegment").image.rect, {#color:color(255,0,0), #ink:36})
      end
    elseif nmCase == "Drill Suspender" then
      local thirdDist = dist / 4.0

      for q = 1, 2 do
        local ps = A
        local dr = dir

        if (q == 2) then
          ps = B
          dr = point(-dir.x, -dir.y)
        end

        local QD = quad(ps - perp, ps + perp, ps + dr * thirdDist + perp, ps + dr * thirdDist - perp)
        member("layer" .. spelrelaterat.restrict(dp + 3, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(0, 255, 0) })

        QD = quad(ps - perp * 2, ps + perp * 2, ps + dr * 10.0 + perp * 2, ps + dr * 10.0 - perp * 2)
        member("layer" .. spelrelaterat.restrict(dp + 3, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(0, 255, 0) })

        local rodWidth = 18.0
        QD = quad(ps + dr * thirdDist - perp * rodWidth, ps + dr * thirdDist + perp * rodWidth,
          ps + dr * (thirdDist - 2.5) + perp * rodWidth, ps + dr * (thirdDist - 2.5) - perp * rodWidth)
        member("layer" .. spelrelaterat.restrict(dp + 3, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(0, 255, 0) })

        QD = quad(ps + dr * thirdDist - perp * 3, ps + dr * thirdDist + perp * 3, ps + dr * thirdDist - perp * 3 - dr *
        28, ps + dr * thirdDist + perp * 3 - dr * 28)
        QD = QD + dr * 2 --[dr*2, dr*2, dr*2, dr*2]
        for e = 0, 2 do
          member("layer" .. spelrelaterat.restrict(dp + 2 + e, 0, 29)).image:copyPixels(
          member("DrillSuspenderClamp").image, QD,
            rect(0, spelrelaterat.restrict(e, 0, 1) * 28, 6, (spelrelaterat.restrict(e, 0, 1) + 1) * 28), { ink = 36 })
        end

        member("layer" .. spelrelaterat.restrict(dp + 2, 0, 29)).image:copyPixels(member("DrillSuspenderBolt").image,
          rect(ps, ps) + rect(-3, -3, 3, 3), rect(0, 0, 6, 6), { ink = 36 })
        for e = 3, 4 do
          member("layer" .. spelrelaterat.restrict(dp + e, 0, 29)).image:copyPixels(member("DrillSuspenderBolt").image,
            rect(ps, ps) + rect(-4, -4, 4, 4), rect(0, 6, 8, 14), { ink = 36 })
        end
      end

      for q = 1, 2 do
        local perpOffset = -10.0

        if (q == 2) then
          perpOffset = 10.0
        end

        local rodWidth = 0.65

        local QD = quad(A + dir * thirdDist - perp * (-rodWidth + perpOffset),
          A + dir * thirdDist - perp * (rodWidth + perpOffset), B - dir * thirdDist - perp * (rodWidth + perpOffset),
          B - dir * thirdDist - perp * (-rodWidth + perpOffset))
        member("layer" .. spelrelaterat.restrict(dp + 3, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(0, 255, 0) })

        for e = 1, 2 do
          local pos = A + dir * thirdDist - perp * perpOffset

          if (e == 2) then
            pos = B - dir * thirdDist - perp * perpOffset
          end

          for d = 0, 5 do
            local sz = 3.0 + 7.0 * math.sin((d / 5.0) * math.pi)
            QD = quad(pos + dir * sz - perp, pos + dir * sz + perp, pos - dir * sz + perp, pos - dir * sz - perp)
            member("layer" .. spelrelaterat.restrict(dp + d, 0, 29)).image:copyPixels(member("pxl").image, QD,
              rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
          end
        end
      end
    elseif nmCase == "Drill" then
      local steps = toint((fiffigt.diag(A, B) / 20.0) + 0.4999)
      local degDir = fiffigt.lookAtPoint(A, B)
      local stp = random(100) * 0.01

      for q = 1, steps do
        local pos = A + (dir * 20.0 * (q - stp))
        local rct = rect(pos, pos) + rect(-10, -10, 10, 10)

        for e = 0, 9 do
          member("layer" .. tostring(spelrelaterat.restrict(dp + e, 0, 29))).image:copyPixels(member("DrillGraf").image,
            rotate(rct, degDir), rect(0, e * 20, 20, (e + 1) * 20), { ink = 36 })
        end
      end
    elseif nmCase == "Piston" then
      local dr = dir

      for d = 0, 2 do
        local wdth = 3 + d
        local QD = quad(A - perp * wdth, A + perp * wdth, B + perp * wdth, B - perp * wdth)
        member("layer" .. spelrelaterat.restrict(dp + d + 1, 0, 29)).image:copyPixels(member("pxl").image, QD,
          rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })

        member("layer" .. spelrelaterat.restrict(dp + d + 1, 0, 29)).image:copyPixels(member("pistonHead").image,
          rect(A.x - 5, A.y - 5, A.x + 5, A.y + 5), member("pistonHead").image.rect, { ink = 36 })
      end
      local wdth = 1
      local QD = quad(A + dir - perp * wdth, A + dir + perp * wdth, B - dir + perp * wdth, B - dir - perp * wdth) +
      point(-1, -1)                                                                                                                -- [point(-1,-1), point(-1,-1), point(-1,-1), point(-1,-1)]
      member("layer" .. spelrelaterat.restrict(dp + 1, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1, 1),
        { ink = 36, color = color(0, 0, 255) })

      local A2 = A
      if (fiffigt.diag(A, B) > 200) then
        A2 = B + fiffigt.moveToPoint(A, B, 200.0)
      end

      for d = 0, 4 do
        wdth = 5 + d + toint(d > 0)
        QD = quad(A2 - perp * wdth, A2 + perp * wdth, B + perp * wdth, B - perp * wdth)
        member("layer" .. spelrelaterat.restrict(dp + d, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(0, 255, 0) })

        if (d == 0) then
          wdth = 3
          QD = quad(A2 + dir * 2 - perp * wdth, A2 + dir * 2 + perp * wdth, B - dir * 2 + perp * wdth,
            B - dir * 2 - perp * wdth) + point(-2, -2)                                                                                     -- [point(-2,-2), point(-2,-2), point(-2,-2), point(-2,-2)]
          member("layer" .. spelrelaterat.restrict(dp, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1, 1),
            { ink = 36, color = color(0, 0, 255) })
        end

        QD = quad(A2 - perp * wdth, A2 + perp * wdth, A2 + dir * 2 + perp * wdth, A2 + dir * 2 - perp * wdth)
        member("layer" .. spelrelaterat.restrict(dp + d, 0, 29)).image:copyPixels(member("pxl").image, QD, rect(0, 0, 1,
          1), { ink = 36, color = color(255, 0, 0) })
      end
    end

    -- case (prop.nm) of
    --   "Cabinet Clamp":
    --   "Stretched Pipe":
    --   "Stretched Wire":
    --   "Long Barbed Wire":
    --   "Twisted Thread":
    --   "Thick Chain":
    --   "Drill Suspender":
    --   "Drill":
    --   "Piston":
    -- end case
  end
end

---@param prop table
---@param dp number
---@param qd table|Quad
function me.DoPropTags(prop, dp, qd)
  for i = 1, #prop.tags do
    local tagCase = prop.tags[i]

    if tagCase == "Circular Sign" then
      local img = image(120, 120)
      local rnd = random(14)
      img:copyPixels(member("circularSigns").image, rect(0, 0, 120, 120),
        rect((rnd - 1) * 120, 1 + 240, rnd * 120, 1 + 240 + 120), { ink = 36, color = color(0, 0, 0) })


      local mdPnt = (qd[1] + qd[2] + qd[3] + qd[4]) / 4.0

      for _, r in ipairs({ { point(-1, -1), color(0, 0, 255) }, { point(-0, -1), color(0, 0, 255) }, { point(-1, -0), color(0, 0, 255) }, { point(-2, -2), color(0, 0, 255) }, { point(1, 1), color(255, 0, 0) }, { point(0, 1), color(255, 0, 0) }, { point(1, 0), color(255, 0, 0) }, { point(2, 2), color(255, 0, 0) }, { point(0, 0), color(0, 255, 0) } }) do
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(img,
          rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt) + rect(r[1], r[1]), rect(0, 0, 120, 120), { ink = 36, color = r[2] })
      end

      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1 + 120, rnd * 120, 1 + 240),
        { ink = 36, color = color(0, 255, 0) })
      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1, rnd * 120, 1 + 120),
        { ink = 36, color = color(255, 0, 255) })

      spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-60, -60), mdPnt + point(60, 60)),
        "circleSignGrad", rect(0, 1, 120, 121), 0.5, 1)
    elseif tagCase == "Circular Sign B" then
      local img = image(120, 120)
      local rnd = random(14)
      img:copyPixels(member("circularSigns").image, rect(0, 0, 120, 120),
        rect((rnd - 1) * 120, 1 + 240, rnd * 120, 1 + 240 + 120), { ink = 36, color = color(0, 0, 0) })


      local mdPnt = (qd[1] + qd[2] + qd[3] + qd[4]) / 4.0

      for _, r in ipairs({ { point(-1, -1), color(0, 0, 255) }, { point(-0, -1), color(0, 0, 255) }, { point(-1, -0), color(0, 0, 255) }, { point(-2, -2), color(0, 0, 255) }, { point(1, 1), color(255, 0, 0) }, { point(0, 1), color(255, 0, 0) }, { point(1, 0), color(255, 0, 0) }, { point(2, 2), color(255, 0, 0) }, { point(0, 0), color(0, 255, 0) } }) do
        member("layer" .. string(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(img,
          rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt) + rect(r[1], r[1]), rect(0, 0, 120, 120), { ink = 36, color = r[2] })
      end

      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1 + 120, rnd * 120, 1 + 240),
        { ink = 36, color = color(0, 255, 0) })
      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1, rnd * 120, 1 + 120),
        { ink = 36, color = color(0, 255, 255) })

      spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-60, -60), mdPnt + point(60, 60)),
        "circleSignGrad", rect(0, 1, 120, 121), 0.5, 1)
    elseif tagCase == "Circular Sign Off" then
      local img = image(120, 120)
      local rnd = random(14)
      img:copyPixels(member("circularSigns").image, rect(0, 0, 120, 120),
        rect((rnd - 1) * 120, 1 + 240, rnd * 120, 1 + 240 + 120), { ink = 36, color = color(0, 0, 0) })

      local mdPnt = (qd[1] + qd[2] + qd[3] + qd[4]) / 4.0

      for _, r in ipairs({ { point(-1, -1), color(0, 0, 255) }, { point(-0, -1), color(0, 0, 255) }, { point(-1, -0), color(0, 0, 255) }, { point(-2, -2), color(0, 0, 255) }, { point(1, 1), color(255, 0, 0) }, { point(0, 1), color(255, 0, 0) }, { point(1, 0), color(255, 0, 0) }, { point(2, 2), color(255, 0, 0) }, { point(0, 0), color(0, 255, 0) } }) do
        member("layer" .. tostring(spelrelaterat.restrict(dp, 0, 29))).image:copyPixels(img,
          rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt) + rect(r[1], r[1]), rect(0, 0, 120, 120), { ink = 36, color = r[2] })
      end

      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1 + 120, rnd * 120, 1 + 240),
        { ink = 36, color = color(0, 255, 0) })
      member("layer" .. tostring(dp)).image:copyPixels(member("circularSigns").image,
        rect(-60, -60, 60, 60) + rect(mdPnt, mdPnt), rect((rnd - 1) * 120, 1, rnd * 120, 1 + 120),
        { ink = 36, color = color(255, 0, 0) })
    elseif tagCase == "Larger Sign" then
      local img = image(80 + 6, 100 + 6)
      local rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSigns").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100),
        { ink = 36, color = color(0, 0, 0) })

      local mdPnt = (qd[1] + qd[2] + qd[3] + qd[4]) / 4.0

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. tostring(spelrelaterat.restrict(dp + d, 0, 29))).image:copyPixels(img,
            rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) + rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r
          [2] })
        end
      end


      member("layer" .. tostring(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86,
        106), { ink = 36, color = color(255, 255, 255) })
      member("layer" .. tostring(spelrelaterat.restrict(dp + 1, 0, 29))).image:copyPixels(img,
        rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106), { ink = 36, color = color(255, 0, 255) })

      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1) --+ rect(0,0,-1,-1)
          if (random(7) == 1) then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif random(7) == 1 then
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(0, 0, 0), blend = random(random(60)) })
          end
          member("largeSignGrad2").image:copyPixels(member("pxl").image, rect(rct.left, rct.top, rct.right, rct.top + 1),
            rect(0, 0, 1, 1), { color = color(255, 255, 255), blend = 20 })
          member("largeSignGrad2").image:copyPixels(member("pxl").image,
            rect(rct.left, rct.top + 1, rct.left + 1, rct.bottom), rect(0, 0, 1, 1),
            { color = color(255, 255, 255), blend = 20 })
        end
      end

      spelrelaterat.copyPixelsToEffectColor("A", spelrelaterat.restrict(dp + 1, 0, 29),
        rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)), "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    elseif tagCase == "Larger Sign B" then
      local img = image(80 + 6, 100 + 6)
      local rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSigns").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100),
        { ink = 36, color = color(0, 0, 0) })

      local mdPnt = (qd[1] + qd[2] + qd[3] + qd[4]) / 4.0

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. tostring(spelrelaterat.restrict(dp + d, 0, 29))).image:copyPixels(img,
            rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) + rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r
          [2] })
        end
      end


      member("layer" .. tostring(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86,
        106), { ink = 36, color = color(255, 255, 255) })
      member("layer" .. tostring(spelrelaterat.restrict(dp + 1, 0, 29))).image:copyPixels(img,
        rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106), { ink = 36, color = color(0, 255, 255) })

      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1) --+ rect(0,0,-1,-1)
          if random(7) == 1 then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif random(7) == 1 then
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(0, 0, 0), blend = random(random(60)) })
          end
          member("largeSignGrad2").image:copyPixels(member("pxl").image, rect(rct.left, rct.top, rct.right, rct.top + 1),
            rect(0, 0, 1, 1), { color = color(255, 255, 255), blend = 20 })
          member("largeSignGrad2").image:copyPixels(member("pxl").image,
            rect(rct.left, rct.top + 1, rct.left + 1, rct.bottom), rect(0, 0, 1, 1),
            { color = color(255, 255, 255), blend = 20 })
        end
      end

      spelrelaterat.copyPixelsToEffectColor("B", spelrelaterat.restrict(dp + 1, 0, 29),
        rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)), "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    end

    --     case prop.tags[i] of
    --       "Circular Sign":
    --         -- put "CIRCLE SIGN"
    --       "Circular Sign B":
    --         -- put "CIRCLE SIGN"
    --       "Circular Sign Off":
    --       "Larger Sign":
    --         -- put "BIG SIGN"

    --       "Larger Sign B":
    --         -- put "BIG SIGN"
    --     end case
    --   type img: image
    --   type rnd: number
    --   type mdpnt: point
    --   type r: list
    --   type qd: list
  end
end

return me
