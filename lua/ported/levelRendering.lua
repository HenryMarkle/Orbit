-- global gLEProps, gTEProps, gLastImported, tileSetIndex, gTiles, gTinySignsDrawn, gLOprops
-- global gRenderCameraTilePos, gRenderCameraPixelPos, gRenderTrashProps, gMegaTrash, gDRMatFixes, gDRInvI, gRRSpreadsMore
-- global RandomMetals_allowed, RandomMetals_grabTiles, ChaoticStone2_needed, DRRandomMetal_needed, SmallMachines_forbidden, SmallMachines_grabTiles, RandomMachines_grabTiles, RandomMachines_forbidden, RandomMachines2_forbidden, RandomMachines2_grabTiles
local me = {}

local utils = require('comEditorUtils')
local spelrelaterat = require('spelrelaterat')
local fiffigt = require('fiffigt')

me.frntImg = image(1, 1)

function me.renderLevel()
  -- local utils = require('comEditorUtils')

  if utils.checkMinimize() then
    _player.appMinimize()
  end
  if utils.checkExit() then
    _player.quit()
  end

  tm = _system.milliseconds

  gTinySignsDrawn = 0

  gRenderTrashProps = list()

  RENDER = 0
  local cols = 100 --gLOprops.size.x
  local rows = 60  --gLOprops.size.y

  -- member("bkgBkgImage").image = image(cols*20, rows*20, 16)
  member("finalImage").image = image(cols * 20, rows * 20)

  randomSeed = gLOprops.tileSeed

  me.setUpLayer(3)
  me.setUpLayer(2)
  me.setUpLayer(1)

  gLastImported = ""

  --   global gLoadedName

  print(gLoadedName .. " rendered in " .. (_system.milliseconds - tm))
end

---@param layer number
function me.setUpLayer(layer)
  local start = os.clock()

  -- global gLOprops
  local cols = 100 --gLOprops.size.x
  local rows = 60  --gLOprops.size.y
  local tlset = image(member("tileSet1").image)
  local dpt
  if layer == 1 then
    dpt = 0
  elseif layer == 2 then
    dpt = 10
  else
    dpt = 20
  end

  --  repeat with q = dpt to dpt+9 then
  --    member("layer"..tostring(q)).image = image(cols*20, rows*20, 32)
  --  end

  --  member("concreteTexture").image = image(1040,800,32)
  --  repeat with q = 1 to 10 then
  --    repeat with c = 1 to 8 then
  --      member("concreteTexture").image:copyPixels( member("concreteTexture2").image, rect((q-1)*108, (c-1)*108,q*108,c*108), rect(0,0,108,108) )
  --    end
  --  end
  --   global gLOprops

  member("vertImg").image = image(cols * 20, rows * 20)
  member("horiImg").image = image(cols * 20, rows * 20)

  me.frntImg = image(cols * 20, rows * 20) -- 32
  local frntImg = me.frntImg
  local mdlFrntImg = image(cols * 20, rows * 20) -- 32
  local mdlBckImg = image(cols * 20, rows * 20) -- 32
  local poleCol = color(255, 0, 0)
  local drawLaterTiles = list()
  local drawLastTiles = list()
  local shortCutEntrences = list()
  local shortCuts = list()

  -- depthPnt(pnt, dpt)

  for q = 1, cols do
    for c = 1, rows do
      -- if((q >= gRenderCameraTilePos.x)and(q < gRenderCameraTilePos.x + cols)and(c >= gRenderCameraTilePos.y)and(c < gRenderCameraTilePos.y + rows))or(checkIfTileHasMaterialRenderTypeTiles(point(q,c), layer))then
      if (q + gRenderCameraTilePos.x > 0) and (q + gRenderCameraTilePos.x <= gLOprops.size.x) and (c + gRenderCameraTilePos.y > 0) and (c + gRenderCameraTilePos.y <= gLOprops.size.y) then
        local ps = point(q, c) + gRenderCameraTilePos

        local tp = gLEProps.matrix[ps.x][ps.y][layer][1]


        for _, t in ipairs(gLEProps.matrix[ps.x][ps.y][layer][2]) do
          local rct
          if t == 1 then
            rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) +
            rect(0, 8, 0, -8)                                            --rect(gRenderCameraTilePos,gRenderCameraTilePos)*20
            mdlFrntImg:copyPixels(member("pxl").image, rct, member("pxl").image.rect, { color = poleCol })
          elseif t == 2 then
            rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) +
            rect(8, 0, -8, 0)                                            --rect(gRenderCameraTilePos,gRenderCameraTilePos)*20
            mdlFrntImg:copyPixels(member("pxl").image, rct, member("pxl").image.rect, { color = poleCol })
          elseif t == 3 then
          elseif t == 4 then
            tp = 1
          end
          --     case t of
          --     1:
          --     2:
          --     3:
          --       -- rct = rect((q-1)*20, (c-1)*20, q*20, c*20)--+rect(0, 8, 0, -8)
          --       --   mdlFrntImg:copyPixels(member("hiveGrass").image, rct, member("hiveGrass").image.rect, {color:pltt[1]})
          --     4:
          --   end case
        end

        --drawATile(q, c, layer)
        --  put gLEProps.matrix[q][c][layer][1]
        if (gLEProps.matrix[ps.x][ps.y][1][1] == 7) and (layer == 1) then
          shortCutEntrences:add({ random(1000), ps.x, ps.y })
        else
          if getPos(gLEProps.matrix[ps.x][ps.y][1][2], 5) ~= 0 then --------------------
            if layer == 1 then
              if gLEProps.matrix[ps.x][ps.y][1][1] == 1 then
                if list({ "material", "default" }):getPos(gTEProps.tlMatrix[ps.x][ps.y][layer].tp) ~= 0 then --------------------
                  shortCuts:add(point(ps.x, ps.y))
                end
              end
            elseif layer == 2 then
              if gLEProps.matrix[ps.x][ps.y][2][1] == 1 then
                if gLEProps.matrix[ps.x][ps.y][1][1] ~= 1 then
                  if list({ "material", "default" }):getPos(gTEProps.tlMatrix[ps.x][ps.y][layer].tp) ~= 0 then --------------------
                    shortCuts:add(point(ps.x, ps.y))
                  end
                end
              end
            end
          end

          if gTEProps.tlMatrix[ps.x][ps.y][layer].tp == "tileHead" then
            local dt = gTEProps.tlMatrix[ps.x][ps.y][layer].data
            if (getPos(gTiles[dt[1].x].tls[dt[1].y].tags, "drawLast") ~= 0) then --------------------
              drawLastTiles:add({ random(999), ps.x, ps.y })
            else
              drawLaterTiles:add({ random(999), ps.x, ps.y })
            end
          elseif gTEProps.tlMatrix[ps.x][ps.y][layer].tp ~= "tileBody" then
            drawLaterTiles:add({ random(999), ps.x, ps.y })
          end
        end
      end
    end
  end -- loop

  --   drawLaterTiles.sort()
  table.sort(drawLaterTiles, function(a, b) return a[1] < b[1] end)

  local drawMaterials = list()
  local indxer = list()

  --CAT CHANGE
  for nc = 1, utils.getLastMatCat() do
    for q = 1, #gTiles[nc].tls do
      indxer:add(gTiles[nc].tls[q].nm)
      drawMaterials:add(list({ gTiles[nc].tls[q].nm, list(), gTiles[nc].tls[q].renderType }))
    end
  end

  for _, tl in ipairs(drawLaterTiles) do
    local savSeed = randomSeed
    -- global gLOprops
    randomSeed = spelrelaterat.seedForTile(point(tl[2], tl[3]), gLOprops.tileSeed + layer)

    local tpCase = gTEProps.tlMatrix[tl[2]][tl[3]][layer].tp

    if tpCase == "material" then
      if indxer:getPos(gTEProps.tlMatrix[tl[2]][tl[3]][layer].data) > 0 then                   --------------------
        drawMaterials[indxer:getPos(gTEProps.tlMatrix[tl[2]][tl[3]][layer].data)][2]:add(tl)   --------------------
      end
    elseif tpCase == "default" then
      drawMaterials[indxer:getPos(gTEProps.defaultMaterial)][2]:add(tl)   --------------------
    elseif tpCase == "tileHead" then
      if gTEProps.tlMatrix[(tl[2])][(tl[3])][layer].data then
        local dt = gTEProps.tlMatrix[(tl[2])][(tl[3])][layer].data
        frntImg = me.drawATileTile(tl[2], tl[3], layer, gTiles[dt[1].x].tls[dt[1].y], frntImg, dt)
      end
    end

    -- case gTEProps.tlMatrix[tl[2]][tl[3]][layer].tp of
    --   "material":
    --   "default":
    --   "tileHead":
    -- end case
    randomSeed = savSeed
  end

  for q = 1, #drawMaterials do
    local savSeed = randomSeed
    -- global gLOprops
    randomSeed = gLOprops.tileSeed + layer

    local matsToRender = drawMaterials[q][2]

    if (#matsToRender > 0) then
      
      local matName = drawMaterials[q][1]
      local rtCase = drawMaterials[q][3]

      if rtCase == "invisibleI" then
        if (gDRInvI == false) then
          for _, tl in ipairs(matsToRender) do
            frntImg = me.drawATileMaterial(tl[2], tl[3], layer, matName, frntImg)
          end
        end
      elseif rtCase == "unified" then
        for _, tl in ipairs(matsToRender) do
          frntImg = me.drawATileMaterial(tl[2], tl[3], layer, matName, frntImg)
        end

      elseif rtCase == "customUnified" then
        for _, tl in ipairs(matsToRender) do
          local afa = spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer)
          if (afa ~= 0) and (afa ~= 7) and (afa ~= 8) and (afa ~= 9) then
            me.LDrawATileMaterial(tl[2], tl[3], layer, matName)
          end
        end
      elseif rtCase == "tiles" then
        frntImg = me.renderTileMaterial(layer, matName, frntImg)
      elseif rtCase == "customAutofit" then
        frntImg = me.LRenderTileMaterial(layer, matName, frntImg)
      elseif rtCase == "pipeType" then
        for _, tl in ipairs(matsToRender) do
          -- frntImg = drawATileMaterial(tl[2], tl[3], layer, pltt, drawTiles[q][1], frntImg)
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 0 then
            me.drawPipeTypeTile(matName, point(tl[2], tl[3]), layer)
          end

        end
      elseif rtCase == "rockType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 0 then
            me.drawRockTypeTile(matName, point(tl[2], tl[3]), layer, FALSE)
          end
        end

      elseif rtCase == "largeTrashType" then
        for _, tl in ipairs(matsToRender) do
          if tobool(gDRMatFixes) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6) then
            me.drawPipeTypeTile(matName, point(tl[2], tl[3]), layer)
          end
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 or ((gDRMatFixes) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6)) then
            me.drawLargeTrashTypeTile(matName, point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "roughRock" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            if matName == "Rough Rock" then
              me.drawRockTypeTile("Rocks", point(tl[2], tl[3]), layer, TRUE)
            elseif matName == "Sandy Dirt" then
              me.drawPipeTypeTile("Sandy Dirt", point(tl[2], tl[3]), layer)
            end

            -- case matName of
            --   "Rough Rock":
            --   "Sandy Dirt":
            -- end case
          end
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 then
            me.drawRoughRockTile(matName, point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "megaTrashType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            me.drawPipeTypeTile(matName, point(tl[2], tl[3]), layer)
          end
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            me.drawMegaTrashTypeTile(matName, point(tl[2], tl[3]), layer, frntImg)
          end
        end

        print('rendered megaTrashType')
      elseif rtCase == "dirtType" then
        for _, tl in ipairs(matsToRender) do
          if (gDRMatFixes) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6) then
            me.drawPipeTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer)
          end
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 then
            me.drawDirtTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "sandy" then
        for _, tl in ipairs(matsToRender) do
          local block = spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer)
          if (block ~= 0) and (block ~= 7) and (block ~= 8) and (block ~= 9) then
            me.drawSandyTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg, 4, { 40, 28, 24, 16, 10 },
              { 0, 40, 68, 92, 108 }, 30)
          end
        end
      elseif rtCase == "wv" then
        for _, tl in ipairs(matsToRender) do
          if (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 0) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 7) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 8) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 9) then
            me.drawWVTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer)
          end
        end
      elseif rtCase == "ridgeType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 then
            me.drawRidgeTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "densePipeType" then
        for _, tl in pairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 0 then
            me.drawDPTTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end

      elseif rtCase == "randomPipesType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 0 then
            me.drawRandomPipesMat(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "ceramicType" then
        for _, tl in ipairs(matsToRender) do
          if (point(tl[2], tl[3]):inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) and (gDRMatFixes == FALSE) and (spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) ~= 1) then
            frntImg = me.drawATileMaterial(tl[2], tl[3], layer, "Standard", frntImg)
          elseif spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            me.drawCeramicTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "ceramicAType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            me.drawCeramicATypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      elseif rtCase == "ceramicBType" then
        for _, tl in ipairs(matsToRender) do
          if spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 1 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 2 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 3 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 4 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 5 or spelrelaterat.afaMvLvlEdit(point(tl[2], tl[3]), layer) == 6 then
            me.drawCeramicBTypeTile(drawMaterials[q][1], point(tl[2], tl[3]), layer, frntImg)
          end
        end
      end

      -- case drawMaterials[q][3] of
      --     "invisibleI":
      --     "unified":
      --     "customUnified":
      --     "tiles":
      --     "customAutofit":
      --     "pipeType":
      --     "rockType":
      --     "largeTrashType":
      --     "roughRock":
      --     "megaTrashType":
      --     "dirtType":
      --     "sandy":
      --     "wv":
      --     "ridgeType":
      --     "densePipeType":
      --     "randomPipesType":
      --     "ceramicType":
      --     "ceramicAType":
      --     "ceramicBType":
      --   end case
    end
    randomSeed = savSeed
  end

  --shortCuts.sort()
  for _, tl in ipairs(shortCuts) do
    if (shortCuts:getPos(tl + point(-1, 0)) > 0) and ((shortCuts:getPos(tl + point(1, 0)) > 0)) then --------------------
      me.drawATileTile(tl.x, tl.y, layer,
        { nm = "shortCutHorizontal", sz = point(1, 1), specs = list(), specs2 = nil, tp = "voxelStruct", repeatL = list({ 1, 9 }), bfTiles = 0, rnd = 1, ptPos = 0, tags =
        list() }, frntImg)
    elseif (shortCuts:getPos(tl + point(0, -1)) > 0) and ((shortCuts:getPos(tl + point(0, 1)) > 0)) then --------------------
      me.drawATileTile(tl.x, tl.y, layer,
        { nm = "shortCutVertical", sz = point(1, 1), specs = list(), specs2 = nil, tp = "voxelStruct", repeatL = list({ 1, 9 }), bfTiles = 0, rnd = 1, ptPos = 0, tags =
        list() }, frntImg)
    else
      me.drawATileTile(tl.x, tl.y, layer,
        { nm = "shortCutTile", sz = point(1, 1), specs = list(), specs2 = nil, tp = "voxelStruct", repeatL = list({ 1, 9 }), bfTiles = 0, rnd = 1, ptPos = 0, tags =
        list() }, frntImg)
    end
  end

  for _, tl in ipairs(drawLastTiles) do
    local dt = gTEProps.tlMatrix[(tl[2])][(tl[3])][layer].data
    frntImg = me.drawATileTile(tl[2], tl[3], layer, gTiles[dt[1].x].tls[dt[1].y], frntImg)
  end

  -- global gShortcuts
  -- shortCutEntrences.sort()
  table.sort(shortCutEntrences, function(a, b) return a[1] < b[1] end)

  for _, tl in ipairs(shortCutEntrences) do
    -- frntImg = drawAShortCut(tl[2], tl[3], layer, pltt, frntImg)
    -- put gShortcuts
    local tp = "shortCut"
    if getPos(gShortcuts.indexL, point(tl[2], tl[3]) - gRenderCameraTilePos) > 0 then          --------------------
      tp = gShortcuts.scs[getPos(gShortcuts.indexL, point(tl[2], tl[3]) - gRenderCameraTilePos)] --------------------
    end

    local mem = "shortCut"
    if tp == "shortCut" then
      mem = "shortCutArrows"
    elseif tp == "playerHole" then
      mem = "shortCutDots"
    end

    me.drawATileTile(tl[2], tl[3], 1,
      { nm = mem, sz = point(3, 3), specs = list(), specs2 = list(), tp = "voxelStruct", repeatL = list({ 1, 7, 12 }), bfTiles = 1, rnd = -1, ptPos = 0, tags =
      list() }, frntImg)
  end

  --  repeat with q = dpt to dpt+9 then
  --    member("layer"..tostring(q)).image:copyPixels(frntImg,rect(0,0,1040,800), rect(0,0,1040,800), {ink=36})
  --  end

  for q = 0, cols do
    me.drawVerticalSurface(q, dpt, tl)
  end
  for q = 0, rows do
    me.drawHorizontalSurface(q, dpt, tl)
  end

  member("layer" .. tostring(dpt + 5)).image:copyPixels(mdlBckImg, mdlBckImg.rect, mdlBckImg.rect, { ink = 36 })
  member("layer" .. tostring(dpt)).image:copyPixels(frntImg, frntImg.rect, frntImg.rect, { ink = 36 })

  --ADD CRACKS
  local d = 0
  if layer == 2 then
    d = 10
  elseif layer == 3 then
    d = 20
  end

  -- print('BEFORE LOOP')
  for q = 1, cols do
    for c = 1, rows do
      local q2 = q + gRenderCameraTilePos.x
      local c2 = c + gRenderCameraTilePos.y

      -- print('['..q..', '..c..']')
      if (q2 > 1) and (q2 < gLOprops.size.x) and (c2 > 1) and (c2 < gLOprops.size.y) then
        if (getPos(gLEProps.matrix[q2][c2][layer][2], 11) > 0) then --------------------
          local rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)

          if (gLEProps.matrix[q2 - 1][c2][layer][2]:getPos(11) > 0) or (gLEProps.matrix[q2 - 1][c2][layer][1] == 0) or (gLEProps.matrix[q2 + 1][c2][layer][2]:getPos(11) > 0) or (gLEProps.matrix[q2 + 1][c2][layer][1] == 0) then
            rct = rct + rect(-10, 0, 10, 0)
          else
            rct = rct + rect(5, 0, -5, 0)
          end
          if (gLEProps.matrix[q2][c2 - 1][layer][2]:getPos(11) > 0) or (gLEProps.matrix[q2][c2 - 1][layer][1] == 0) or (gLEProps.matrix[q2][c2 + 1][layer][2]:getPos(11) > 0) or (gLEProps.matrix[q2][c2 + 1][layer][1] == 0) then
            rct = rct + rect(0, -10, 0, 10)
          else
            rct = rct + rect(0, 5, 0, -5)
          end

          -- print('['..q..', '..c..']')

          for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
            if (gLEProps.matrix[q2 + dir.x][c2 + dir.y][layer][1] ~= 1) then
              for z = d, d + 8 do
                for r = 1, 3 do
                  local rnd = random(4)
                  member("layer" .. tostring(z)).image:copyPixels(member("rubbleGraf" .. tostring(rnd)).image,
                    rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) + rect(dir * 10, dir * 10) +
                    rect(random(3) - random(8) + (z - d), random(3) - random(8) + (z - d), random(8) - random(3) - (z - d),
                      random(8) - random(3) - (z - d)), member("rubbleGraf" .. tostring(rnd)).image.rect,
                    { color = color(255, 255, 255), ink = 36 })
                end
              end
            end
          end



          for z = d, d + 8 do
            for r = 1, 4 do
              if ((random(8) > (z - d)) and (random(3) > 1)) or (random(5) == 1) then
                local rnd = random(4)
                member("layer" .. tostring(z)).image:copyPixels(member("rubbleGraf" .. tostring(rnd)).image,
                  rct +
                  rect(random(8) - random(8) + (z - d), random(8) - random(8) + (z - d), random(8) - random(8) - (z - d),
                    random(8) - random(8) - (z - d)), member("rubbleGraf" .. tostring(rnd)).image.rect,
                  { color = color(255, 255, 255), ink = 36 })
              end
            end
          end
        end
      end
    end
  end

  -- POLES ADDED AFTER CRACKS
  member("layer" .. tostring(dpt + 4)).image:copyPixels(mdlFrntImg, mdlFrntImg.rect, mdlFrntImg.rect, { ink = 36 })
  --  --ADD POLES (AGAIN)
  --  repeat with q = 1 to 52 then
  --    repeat with c = 1 to 40 then
  --      repeat with t in gLEProps.matrix[q][c][layer][2] then
  --        case t of
  --          1:
  --            rct = rect((q-1)*20, (c-1)*20, q*20, c*20)+rect(0, 8, 0, -8)
  --            mdlFrntImg:copyPixels(member("pxl").image, rct, member("pxl").image.rect, {color:poleCol})
  --          2:
  --            rct = rect((q-1)*20, (c-1)*20, q*20, c*20)+rect(8, 0, -8, 0)
  --            mdlFrntImg:copyPixels(member("pxl").image, rct, member("pxl").image.rect, {color:poleCol})
  --            --   3:
  --            -- rct = rect((q-1)*20, (c-1)*20, q*20, c*20)--+rect(0, 8, 0, -8)
  --            --   mdlFrntImg:copyPixels(member("hiveGrass").image, rct, member("hiveGrass").image.rect, {color:pltt[1]})
  --            --  4:
  --            --    tp = 1
  --        end case
  --      end
  --    end
  --  end
  
  print('finished setting up layer '..layer..' in '..tostring(os.clock() - start)..'seconds')
end

function me.checkIfATileIsSolidAndSameMaterial(tl, lr, mat)
  -- local spelrelaterat = require('spelrelaterat')

  tl = point(spelrelaterat.restrict(tl.x, 1, gLOprops.size.x), spelrelaterat.restrict(tl.y, 1, gLOprops.size.y))
  local rtrn = 0
  if gLEProps.matrix[tl.x][tl.y][lr][1] == 1 then
    if (gTEProps.tlMatrix[tl.x][tl.y][lr].tp == "material") and (gTEProps.tlMatrix[tl.x][tl.y][lr].data == mat) then
      rtrn = 1
    elseif (gTEProps.tlMatrix[tl.x][tl.y][lr].tp == "default") and (gTEProps.defaultMaterial == mat) then
      rtrn = 1
    end
  end
  return rtrn
end

---@param q number
---@param c number
---@param l number
---@param mat string
---@param frntImg Image
function me.drawATileMaterial(q, c, l, mat, frntImg)
  ---@type number
  local dp

  -- global gLOprops, gEEprops, gAnyDecals

  if l == 1 then
    dp = 0
  elseif l == 2 then
    dp = 10
  else
    dp = 20
  end

  local rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
  local myTileSet = mat
  if (mat == "Scaffolding") and tobool(gDRMatFixes) then
    myTileSet = mat .. "DR"
  elseif (mat == "Invisible") then
    myTileSet = "SuperStructure"
  end

  local geoCase = gLEProps.matrix[q][c][l][1]

  local pstRect
  local gtRect

  if geoCase == 1 then
    -- local start = os.clock()

    ---@type table
    local profL
    ---@type number
    local gtAtV
    ---@type number
    local gtAtH
    ---@type rect
    -- local pstRect

    for f = 1, 4 do

      if f == 1 then
        profL = list({ point(-1, 0), point(0, -1) })
        gtAtV = 2
        pstRect = rct + rect(0, 0, -10, -10)
      elseif f == 2 then
        profL = list({ point(1, 0), point(0, -1) })
        gtAtV = 4
        pstRect = rct + rect(10, 0, 0, -10)
      elseif f == 3 then
        profL = list({ point(1, 0), point(0, 1) })
        gtAtV = 6
        pstRect = rct + rect(10, 10, 0, 0)
      else
        profL = list({ point(-1, 0), point(0, 1) })
        gtAtV = 8
        pstRect = rct + rect(0, 10, -10, 0)
      end
      -- case f of
      --   1:
      --   2:
      --   3:
      --   otherwise:
      -- end case
      local ID = ""
      for _, dr in ipairs(profL) do
        ID = ID .. tostring(toint(me.isMyTileSetOpenToThisTile(mat, point(q, c) + dr, l)))
      end

      if ID == "11" then
        if (getPos({ 1, 2, 3, 4, 5 }, toint(me.isMyTileSetOpenToThisTile(mat, point(q, c) + profL[1] + profL[2], l))) > 0) then
          gtAtH = 10
          gtAtV = 2
        else
          gtAtH = 8
        end
      else
        gtAtH = getPos({ 0, "00", 0, "01", 0, "10" }, ID)
      end
      if gtAtH == 4 then
        if gtAtV == 6 then
          gtAtV = 4
        elseif gtAtV == 8 then
          gtAtV = 2
        end
      elseif gtAtH == 6 then
        if (gtAtV == 4) or (gtAtV == 8) then
          gtAtV = gtAtV - 2
        end
      end

      gtRect = rect((gtAtH - 1) * 10, (gtAtV - 1) * 10, gtAtH * 10, gtAtV * 10) + rect(-5, -5, 5, 5)
      pstRect = pstRect - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20

      -- if q == 17 and c == 10 and f == 1 then
      --   print('HERE')
      --   draw(member("tileSet" .. tostring(myTileSet)).image, 0, 0)
      --   draw(point(gtRect.left, gtRect.top), point(gtRect.right, gtRect.top), color(0,0,0))
      --   draw(point(gtRect.right, gtRect.top), point(gtRect.right, gtRect.bottom), color(0,0,0))
      --   draw(point(gtRect.right, gtRect.bottom), point(gtRect.left, gtRect.bottom), color(0,0,0))
      --   draw(point(gtRect.left, gtRect.bottom), point(gtRect.left, gtRect.top), color(0,0,0))
      -- end


      --  member("layer"..tostring(dp)).image:copyPixels(member("tileSet"..tostring(myTileSet)).image, pstRect+rect(-5,-5, 5, 5), gtRect, {ink=36})
      if (mat ~= "Sand Block") then
        
        frntImg:copyPixels(member("tileSet" .. tostring(myTileSet)).image, pstRect + rect(-5, -5, 5, 5), gtRect, { ink = 36 })

        for d = dp + 1, dp + 9 do
          member("layer" .. tostring(d)).image:copyPixels(member("tileSet" .. tostring(myTileSet)).image,
            pstRect + rect(-5, -5, 5, 5), gtRect + rect(120, 0, 120, 0), { ink = 36 })
        end
      end
    end

    -- local finish = os.clock()
    -- print('branch 1: '..(finish - start))
  elseif geoCase >= 2 and geoCase <= 5 then
    local slp = gLEProps.matrix[q][c][l][1]
    local askDirs

    if tobool(gDRMatFixes) then
      askDirs = { 0, { point(-1, 0), point(0, 1) }, { point(0, 1), point(1, 0) }, { point(-1, 0), point(0, -1) }, { point(0, -1), point(1, 0) } }
    else
      askDirs = { 0, { point(-1, 0), point(0, 1) }, { point(1, 0), point(0, 1) }, { point(-1, 0), point(0, -1) }, { point(1, 0), point(0, -1) } }
    end

    local myAskDirs = askDirs[slp]
    -- type slp:       number
    -- type askDirs:   list
    -- type myAskDirs: list
    pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20

    for ad = 1, #myAskDirs do
      gtRect = rect(10, 90, 30, 110) + rect(60 * toint(ad == 2), 30 * (slp - 2), 60 * toint(ad == 2), 30 * (slp - 2))
      if me.isMyTileSetOpenToThisTile(mat, point(q, c) + myAskDirs[ad], l) then
        gtRect = gtRect + rect(30, 0, 30, 0)
      end
      --  member("layer"..tostring(dp)).image:copyPixels(member("tileSet"..tostring(myTileSet)).image, pstRect+rect(-5,-5, 5, 5), gtRect+rect(-5,-5, 5, 5), {ink=36})

      if (mat == "Scaffolding") and (tobool(gDRMatFixes) == false) then
        for d = dp + 5, dp + 6 do
          member("layer" .. tostring(d)).image:copyPixels(member("tileSet" .. tostring(myTileSet)).image,
            pstRect + rect(-5, -5, 5, 5), gtRect + rect(-5, -5, 5, 5) + rect(120, 0, 120, 0), { ink = 36 })
        end
        for d = dp + 8, dp + 9 do
          member("layer" .. tostring(d)).image:copyPixels(member("tileSet" .. tostring(myTileSet)).image,
            pstRect + rect(-5, -5, 5, 5), gtRect + rect(-5, -5, 5, 5) + rect(120, 0, 120, 0), { ink = 36 })
        end
      elseif (mat ~= "Sand Block") then
        frntImg:copyPixels(member("tileSet" .. tostring(myTileSet)).image, pstRect + rect(-5, -5, 5, 5),
          gtRect + rect(-5, -5, 5, 5), { ink = 36 })
        for d = dp + 1, dp + 9 do
          member("layer" .. tostring(d)).image:copyPixels(member("tileSet" .. tostring(myTileSet)).image,
            pstRect + rect(-5, -5, 5, 5), gtRect + rect(-5, -5, 5, 5) + rect(120, 0, 120, 0), { ink = 36 })
        end
      end
      --        end
    end
  elseif geoCase == 6 then
    if (mat ~= "Invisible") then
      pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20
      if (mat == "Stained Glass") then
        me.drawATileTile(q, c, l,
          { nm = "SGFL", sz = point(1, 1), specs = list(), specs2 = nil, tp = "voxelStruct", repeatL = list({ 10 }), bfTiles = 0, rnd = 1, ptPos = 0, tags =
          list() }, frntImg)
      elseif tobool(gDRMatFixes) or ((mat ~= "Sand Block") and (mat ~= "Scaffolding") and (mat ~= "Tiny Signs")) then
        me.drawATileTile(q, c, l,
          { nm = "tileSet" .. tostring(myTileSet) .. "Floor", sz = point(1, 1), specs = list(), specs2 = nil, tp =
          "voxelStruct", repeatL = list({ 6, 1, 1, 1, 1 }), bfTiles = 1, rnd = 1, ptPos = 0, tags = list({}) }, frntImg)
      else
        me.drawATileTile(q, c, l,
          { nm = "tileSetBigMetalFloor", sz = point(1, 1), specs = list(), specs2 = nil, tp = "voxelStruct", repeatL =
          list({ 6, 1, 1, 1, 1 }), bfTiles = 1, rnd = 1, ptPos = 0, tags = list() }, frntImg)
      end
    end
  end

  

  -- case gLEProps.matrix[q][c][l][1] of
  --   1:
  --   2,3,4,5:
  --   6:
  -- end case

  local matInt = getPos(
  { "Concrete", "RainStone", "Bricks", "Tiny Signs", "Cliff", "Non-Slip Metal", "BulkMetal", "MassiveBulkMetal",
    "Asphalt" }, mat)

    local modList = { 45, 6, 1, 10, 45, 5, 5, 10, 45 }
  if (matInt > 0) then
    local modder = modList[matInt]

    gtRect = rect((q % modder) * 20, (c % modder) * 20, ((q % modder) + 1) * 20, ((c % modder) + 1) * 20)

    if mat == "Bricks" then
      gtRect = rect(0, 0, 20, 20)
    end

    if (mat == "Tiny Signs") and (not gTinySignsDrawn) then
      me.drawTinySigns()
      gTinySignsDrawn = true
    end

    local geoCase = gLEProps.matrix[q][c][l][1]

    if geoCase == 1 then
      pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - (rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20)
      --put mat.."Texture"
      -- put member(mat.."Texture")
      member("layer" .. tostring(dp)).image:copyPixels(member(mat .. "Texture").image, pstRect, gtRect, { ink = 36 })

    elseif geoCase >= 2 and geoCase <= 5 then
      member("layer" .. tostring(dp)).image:copyPixels(member(mat .. "Texture").image, pstRect, gtRect, { ink = 36 })

      -- This part "shears off" the corners of the textures to fit the slope shape

      local qd
      if geoCase == 2 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.right, rct.bottom), point(rct.right, rct.bottom), point(rct.left, rct.top), point(rct.right, rct.top))
        -- qd = quad(point(rct.left, rct.top), point(rct.right, rct.top), point(rct.right, rct.bottom), point(rct.right, rct.bottom))
      elseif geoCase == 3 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.top), point(rct.left, rct.top), point(rct.right, rct.top), point(rct.left, rct.bottom))
      elseif geoCase == 4 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        -- qd = quad(point(rct.right, rct.top), point(rct.right, rct.top), point(rct.left, rct.bottom), point(rct.right, rct.bottom))
        qd = quad(point(rct.left, rct.bottom), point(rct.left, rct.bottom), point(rct.right, rct.top), point(rct.right, rct.bottom))
      elseif geoCase == 5 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.top), point(rct.left, rct.top), point(rct.right, rct.bottom), point(rct.left, rct.bottom))
      end
      qd = qd - (gRenderCameraTilePos * 20) --[gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos]*20
      member("layer" .. tostring(dp)).image:copyPixels(member("pxl").image, qd, rect(0, 0, 1, 1), { color = color(255, 255, 255) })
    end

    -- case gLEProps.matrix[q][c][l][1] of
    --   1:
    --   2,3,4,5:
    --     case gLEProps.matrix[q][c][l][1] of
    --       5:--2:
    --       4:--3:
    --       3:--4:
    --       2:--5:
    --     end case
    -- end case
  end

  if mat == "Stained Glass" then
    local matInt = 1
    local modder = 1
    local imgLoad = "SG"
    local gtRect = rect(0, 0, 20, 20)
    local var = "1"
    local clr1 = "A"
    local clr2 = "B"
    local q2 = q + gRenderCameraTilePos.x
    local c2 = c + gRenderCameraTilePos.y

    for nav = 1, #gEEprops.effects do
      if (gEEprops.effects[nav].nm == "Stained Glass Properties") then
        if (gEEprops.effects[nav].mtrx[q][c] >= 1) then
          local optCase = gEEprops.effects[nav].options[2][3]

          if optCase == "1" then
            var = "1"
          elseif optCase == "2" then
            var = "2"
          elseif optCase == "3" then
            var = "3"
          else
            var = "1"
          end

          -- case gEEprops.effects[nav].options[2][3] of
          --   "1":
          --     var = "1"
          --   "2":
          --     var = "2"
          --   "3":
          --     var = "3"
          --   otherwise:
          --     var = "1"
          -- end case

          optCase = gEEprops.effects[nav].options[3][3]

          if optCase == "EffectColor1" then
            clr1 = "A"
          elseif optCase == "EffectColor2" then
            clr1 = "B"
          elseif optCase == "None" then
            clr1 = "C"
          else
            clr1 = "A"
          end

          -- case gEEprops.effects[nav].options[3][3] of
          --   "EffectColor1":
          --     clr1 = "A"
          --   "EffectColor2":
          --     clr1 = "B"
          --   "None":
          --     clr1 = "C"
          --   otherwise:
          --     clr1 = "A"
          -- end case

          optCase = gEEprops.effects[nav].options[4][3]

          if optCase == "EffectColor1" then
            clr2 = "A"
          elseif optCase == "EffectColor2" then
            clr2 = "B"
          elseif optCase == "None" then
            clr2 = "C"
          else
            clr2 = "B"
          end

          -- case gEEprops.effects[nav].options[4][3] of
          --   "EffectColor1":
          --     clr2 = "A"
          --   "EffectColor2":
          --     clr2 = "B"
          --   "None":
          --     clr2 = "C"
          --   otherwise:
          --     clr2 = "B"
          -- end case
        end
      end
    end

    local geoCase = gLEProps.matrix[q][c][l][1]

    if geoCase == 1 then
      local pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20
      member("layer" .. tostring(dp)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      --repeat with den = 1 to 9 then
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. clr1 .. clr2).image, pstRect, gtRect,
        { ink = 36 })
      member("gradientA" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      member("gradientB" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      --den = den+1
      --end
    elseif geoCase >= 2 and geoCase <= 5 then
      member("layer" .. tostring(dp)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      --repeat with dep = 1 to 9 then
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. clr1 .. clr2).image, pstRect, gtRect,
        { ink = 36 })
      member("gradientA" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      member("gradientB" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      --dep = dep+1
      --end

      local rct
      local qd
      if geoCase == 2 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.right, rct.bottom), point(rct.right, rct.bottom), point(rct.left, rct.top),
          point(rct.right, rct.top))
      elseif geoCase == 3 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.bottom), point(rct.left, rct.bottom), point(rct.right, rct.top),
          point(rct.left, rct.top))
      elseif geoCase == 4 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.right, rct.top), point(rct.right, rct.top), point(rct.left, rct.bottom),
          point(rct.right, rct.bottom))
      elseif geoCase == 5 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.top), point(rct.left, rct.top), point(rct.right, rct.bottom),
          point(rct.left, rct.bottom))
      end

      qd = qd -
      gRenderCameraTilePos *
      20                                -- [gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos]*20
      for vj = 0, 1 do
        member("layer" .. tostring(dp + vj)).image:copyPixels(member("pxl").image, rct, rect(0, 0, 1, 1),
          { color = color(255, 255, 255) })
        --vj = vj + 1
      end
    elseif geoCase == 6 then
      local pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20
      member("layer" .. tostring(dp)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      --repeat with des = 1 to 9 then
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Socket").image, pstRect, gtRect,
        { color = color(0, 255, 0), ink = 36 })
      member("layer" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. clr1 .. clr2).image, pstRect, gtRect,
        { ink = 36 })
      member("gradientA" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      member("gradientB" .. tostring(dp + 1)).image:copyPixels(member(imgLoad .. var .. "Grad").image, pstRect, gtRect,
        { ink = 39 })
      --des = des+1
      --end

      local rct = rect((q - 1) * 20, (c - 1) * 20 + 10, q * 20, c * 20)
      local qd = quad(point(rct.right, rct.bottom), point(rct.left, rct.bottom), point(rct.left, rct.top),
        point(rct.right, rct.top))

      -- case gLEProps.matrix[q][c][l][1] of
      --   6:
      --     rct = rect((q-1)*20, (c-1)*20+10, q*20, c*20)
      --     rct = [point(rct.right, rct.bottom), point(rct.left, rct.bottom), point(rct.left, rct.top), point(rct.right, rct.top)]
      -- end case
      qd = qd -
      gRenderCameraTilePos *
      20                                -- [gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos]*20

      for v6 = 0, 1 do
        member("layer" .. tostring(dp + v6)).image:copyPixels(member("pxl").image, rct, rect(0, 0, 1, 1),
          { color = color(255, 255, 255) })
        --v6 = v6 + 1
      end
    end

    -- case gLEProps.matrix[q][c][l][1] of
    --   1:

    --   2,3,4,5:
    --     -- case gLEProps.matrix[q][c][l][1] of
    --     --   5:--2:
    --     --   4:--3:
    --     --   3:--4:
    --     --   2:--5:
    --     -- end case

    --   6:
    -- end case
  end

  if mat == "Sand Block" then
    local matInt = 1
    local modder = 28

    local gtRect = rect((q % modder) * 20, (c % modder) * 20, ((q % modder) + 1) * 20, ((c % modder) + 1) * 20)

    local geoCase = gLEProps.matrix[q][c][l][1]

    if geoCase == 1 then
      local pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20) - rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20
      local rnd = random(4)
      for dep = 0, 9 do
        member("layer" .. tostring(dp + dep)).image:copyPixels(member(mat .. "Texture" .. tostring(random(4))).image,
          pstRect, gtRect, { ink = 36 })
        --dep = dep+1
      end
    elseif geoCase >= 2 and geoCase <= 5 then
      local rnd = random(4)

      for dep = 0, 9 do
        member("layer" .. tostring(dp + dep)).image:copyPixels(member(mat .. "Texture" .. tostring(random(4))).image,
          pstRect, gtRect, { ink = 36 })
        --dep = dep+1
      end

      local rct
      local qd
      if geoCase == 2 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.right, rct.bottom), point(rct.right, rct.bottom), point(rct.left, rct.top),
          point(rct.right, rct.top))
      elseif geoCase == 3 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.bottom), point(rct.left, rct.bottom), point(rct.right, rct.top),
          point(rct.left, rct.top))
      elseif geoCase == 4 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.right, rct.top), point(rct.right, rct.top), point(rct.left, rct.bottom),
          point(rct.right, rct.bottom))
      elseif geoCase == 5 then
        rct = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20)
        qd = quad(point(rct.left, rct.top), point(rct.left, rct.top), point(rct.right, rct.bottom),
          point(rct.left, rct.bottom))
      end

      -- case gLEProps.matrix[q][c][l][1] of
      --   5:--2:
      --   4:--3:
      --   3:--4:
      --   2:--5:
      -- end case
      qd = qd -
      gRenderCameraTilePos *
      20                                -- [gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos, gRenderCameraTilePos]*20
      for dep = 0, 9 do
        member("layer" .. tostring(dp + dep)).image:copyPixels(member("pxl").image, rct, rect(0, 0, 1, 1),
          { color = color(255, 255, 255) })
        --dep = dep+1
      end
    elseif geoCase == 6 then
      local pstRect = rect((q - 1) * 20, (c - 1) * 20, q * 20, c * 20 - 10) -
      rect(gRenderCameraTilePos, gRenderCameraTilePos) * 20
      for dep = 0, 9 do
        member("layer" .. tostring(dp + dep)).image:copyPixels(member(mat .. "Texture" .. tostring(random(4))).image,
          pstRect, gtRect, { ink = 36 })
        --dep = dep+1
      end
    end

    -- case gLEProps.matrix[q][c][l][1] of
    --   1:

    --   2,3,4,5:
    --   6:
    -- end case
  end

  return frntImg
end

---@param mat string
---@param tl point
---@param l number
---@return boolean
function me.isMyTileSetOpenToThisTile(mat, tl, l)
  -- type return: number
  -- global gLOprops
  local rtrn = false
  if tl:inside(rect(1, 1, gLOprops.size.x + 1, gLOprops.size.y + 1)) then
    if getPos({ 1, 2, 3, 4, 5 }, gLEProps.matrix[tl.x][tl.y][l][1]) > 0 then
      if (gTEProps.tlMatrix[tl.x][tl.y][l].tp == "material") and (gTEProps.tlMatrix[tl.x][tl.y][l].data == mat) then
        rtrn = true
      elseif (gTEProps.tlMatrix[tl.x][tl.y][l].tp == "default") and (gTEProps.defaultMaterial == mat) then
        rtrn = true
      end
    end
  else
    if gTEProps.defaultMaterial == mat then
      rtrn = true
    end
  end
  return rtrn
end

function me.drawRidgeTypeTile(mat, tl, layer, frntImg)
  -- local fiffigt = require('fiffigt')
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)
  local distanceToAir = -1

  for dist = 1, 5 do
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
        distanceToAir = dist
        break
      end
    end
    if (distanceToAir ~= -1) then
      break
    end
  end
  if (distanceToAir == -1) then
    distanceToAir = 5
  end
  if (distanceToAir >= 1) then
    local layRB = (layer - 1) * 10
    local dp = layRB
    local dsct = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
    local pos = dsct

    if (distanceToAir == 1) then
      member("layer" .. string(layRB + 2)).image:copyPixels(member("ridgeBase").image,
        rect(pos.x - 10, pos.y - 10, pos.x + 10, pos.y + 10), rect(0, 0, 22, 22), { ink = 36 })
    end

    if (random(5) <= distanceToAir) then
      local var = random(30)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      frntImg:copyPixels(member("ridgeRocks").image, spelrelaterat.rotateToQuad(rct, random(15)),
        rect((var - 1) * 52, 1, var * 52, 53), { ink = 36 })
    end

    for q = 1, distanceToAir do
      local dp

      if (distanceToAir == 1) then
        dp = layRB + random(2) - 1
      else
        dp = layRB + random(10) - 1
      end

      local pos = dsct + point(-11 + random(21), -11 + random(21))
      local var = random(30)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      member("layer" .. string(dp)).image:copyPixels(member("ridgeRocks").image,
        spelrelaterat.rotateToQuad(rct, random(15)), rect((var - 1) * 52, 1, var * 52, 53), { ink = 36 })
    end
  end
  randomSeed = savSeed
end

---@param q number
---@param c number
---@param l number
---@param tl table
---@param frntImg Image
---@param dt table
function me.drawATileTile(q, c, l, tl, frntImg, dt)
  -- local utils = require('comEditorUtils')
  -- local fiffigt = require('fiffigt')
  -- local spelrelaterat = require('spelrelaterat')
  -- global gAnyDecals

  --INTERNAL
  local tileImage
  if (utils.checkDRInternal(tl.nm)) then
    tileImage = member(tl.nm).image
  else
    tileImage = image("Graphics" .. dirSeparator .. tl.nm .. ".png")
  end

  q = q - gRenderCameraTilePos.x
  c = c - gRenderCameraTilePos.y

  --clTile = member(("layer")..tostring(lr)).image.getPixel(pnt)

  local mdPnt = point(toint((tl.sz.x * 0.5) + 0.4999), toint((tl.sz.y * 0.5) + 0.4999))
  local strt = point(q, c) - mdPnt + point(1, 1)

  ---@type rect
  local rct
  ---@type rect
  local gtRect
  ---@type number
  local dp
  ---@type rect
  local getrect
  ---@type rect
  local getrct
  ---@type number
  local rnd
  ---@type number
  local d

  local colored = (getPos(tl.tags, "colored") > 0)
  if (colored) then
    gAnyDecals = 1
  end

  local effectColorA = (getPos(tl.tags, "effectColorA") > 0)
  --  if(effectColorA)then
  --    gAnyDecals = 1
  --  end

  local effectColorB = (getPos(tl.tags, "effectColorB") > 0)
  --  if(effectColorB)then
  --    gAnyDecals = 1
  --  end

  local tpCase = tl.tp

  if tpCase == "box" then
    local nmOfTiles = tl.sz.x * tl.sz.y
    local n = 1

    for g = strt.x, strt.x + tl.sz.x - 1 do
      for h = strt.y, strt.y + tl.sz.y - 1 do
        local rct = rect((g - 1) * 20, (h - 1) * 20, (g * 20), (h * 20))
        local getrct = rect(20, (n - 1) * 20, 40, n * 20)
        member("vertImg").image:copyPixels(tileImage, rct, getrct, { ink = 36 })
        getrct = rect(0, (n - 1) * 20, 20, n * 20)
        member("horiImg").image:copyPixels(tileImage, rct, getrct, { ink = 36 })
        --          if(colored)then
        --            if (tl.tags.GetPos("effectColorA") = 0) and (tl.tags.GetPos("effectColorB") = 0) then
        --              member("horiDc").image:copyPixels(tileImage, rct, getrct+rect(tl.sz.x*20+(40*tl.bfTiles),0,tl.sz.x*20+(40*tl.bfTiles), 0), {ink=36})
        --            end
        --          end
        --          if(effectColorA)then
        --            member("horiGradA").image:copyPixels(tileImage, rct, getrct+rect(tl.sz.x*20+(40*tl.bfTiles),0,tl.sz.x*20+(40*tl.bfTiles), 0), {ink=36})
        --          end
        --          if(effectColorB)then
        --            member("horiGradB").image:copyPixels(tileImage, rct, getrct+rect(tl.sz.x*20+(40*tl.bfTiles),0,tl.sz.x*20+(40*tl.bfTiles), 0), {ink=36})
        --          end
        n = n + 1
      end
    end

    local rct = rect(strt * 20, (strt + tl.sz) * 20) + rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles,
      20 * tl.bfTiles) + rect(-20, -20, -20, -20)
    local getRect = rect(0, 0, tl.sz.x * 20, tl.sz.y * 20) + rect(0, 0, 40 * tl.bfTiles, 40 * tl.bfTiles) +
    rect(0, nmOfTiles * 20, 0, nmOfTiles * 20)
    local rnd = random(tl.rnd)
    getRect = getRect + rect(getRect.width * (rnd - 1), 0, getRect.width * (rnd - 1), 0)
    frntImg:copyPixels(tileImage, rct, getRect, { ink = 36 })

    --    "wvStruct":
    --      drawWVTagTile(q, c, l, tl, frntImg, effectColorA, effectColorB, colored, tileImage)
  elseif tpCase == "voxelStruct" then
    local dp
    if l == 1 then
      dp = 0
    elseif l == 2 then
      dp = 10
    else
      dp = 20
    end

    local rct = rect(
      strt * 20, (strt + tl.sz) * 20
    ) + rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles,20 * tl.bfTiles) + rect(-20, -20, -20, -20)
    
    local gtRect = rect(0, 0, (tl.sz.x * 20) + (40 * tl.bfTiles), (tl.sz.y * 20) + (40 * tl.bfTiles))


    local rnd
    if tl.rnd == -1 then
      rnd = 1

      for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
        if getPos({ 0, 6 }, spelrelaterat.afaMvLvlEdit(point(q, c) + dir + gRenderCameraTilePos, 1)) ~= 0 then
          break
        else
          rnd = rnd + 1
        end
      end
    else
      rnd = random(tl.rnd)
    end

    if getPos(tl.tags, "ramp") ~= 0 then
      rnd = 2
      if (spelrelaterat.afaMvLvlEdit(point(q, c) + gRenderCameraTilePos, 1) == 3) then
        rnd = 1
      end
    end

    frntImg:copyPixels(tileImage, rct, gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) +
    rect(0, 1, 0, 1), { ink = 36 })


    local d = -1
    for ps = 1, #tl.repeatL do
      for ps2n = 1, tl.repeatL[ps] do
        d = d + 1

        if d + dp > 29 then
          break
        else
          member("layer" .. tostring(d + dp)).image:copyPixels(tileImage, rct,
            gtRect + rect(gtRect.width * (rnd - 1), gtRect.height * (ps - 1), gtRect.width * (rnd - 1),
              gtRect.height * (ps - 1)) + rect(0, 1, 0, 1), { ink = 36 })

          if (colored) then
            if (effectColorA == false) and (effectColorB == false) then
              member("layer" .. tostring(d + dp) .. "dc").image:copyPixels(tileImage, rct,
                gtRect + rect(gtRect.width * (rnd - 1), gtRect.height * (ps - 1), gtRect.width * (rnd - 1),
                  gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
                rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0),
                { ink = 36 })
            end
          end

          if (effectColorA) then
            member("gradientA" .. tostring(d + dp)).image:copyPixels(tileImage, rct,
              gtRect + rect(gtRect.width * (rnd - 1), gtRect.height * (ps - 1), gtRect.width * (rnd - 1),
                gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0),
              { ink = 39 })
          end

          if (effectColorB) then
            member("gradientB" .. tostring(d + dp)).image:copyPixels(tileImage, rct,
              gtRect + rect(gtRect.width * (rnd - 1), gtRect.height * (ps - 1), gtRect.width * (rnd - 1),
                gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0),
              { ink = 39 })
          end
        end
      end
    end
  elseif tpCase == "voxelStructRandomDisplaceHorizontal" or tpCase == "voxelStructRandomDisplaceVertical" then
    local dp

    if l == 1 then
      dp = 0
    elseif l == 2 then
      dp = 10
    else
      dp = 20
    end

    local rct = rect(strt * 20, (strt + tl.sz) * 20) + rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles,
      20 * tl.bfTiles) + rect(-20, -20, -20, -20)
    local gtRect = rect(0, 0, (tl.sz.x * 20) + (40 * tl.bfTiles), (tl.sz.y * 20) + (40 * tl.bfTiles))

    -- rnd = 1

    seed = randomSeed
    -- global gLOprops

    local gtRect1
    local gtRect2
    local rct1
    local rct2

    if tpCase == "voxelStructRandomDisplaceVertical" then
      randomSeed = gLOprops.tileSeed + q
      local dsplcPoint = random(gtRect.height)
      gtRect1 = rect(gtRect.left, gtRect.top, gtRect.right, gtRect.top + dsplcPoint)
      gtRect2 = rect(gtRect.left, gtRect.top + dsplcPoint, gtRect.right, gtRect.bottom)
      rct1 = rect(rct.left, rct.bottom - dsplcPoint, rct.right, rct.bottom)
      rct2 = rect(rct.left, rct.top, rct.right, rct.bottom - dsplcPoint)
    else
      randomSeed = gLOprops.tileSeed + c
      local dsplcPoint = random(gtRect.width)
      gtRect1 = rect(gtRect.left, gtRect.top, gtRect.left + dsplcPoint, gtRect.bottom)
      gtRect2 = rect(gtRect.left + dsplcPoint, gtRect.top, gtRect.right, gtRect.bottom)
      rct1 = rect(rct.right - dsplcPoint, rct.top, rct.right, rct.bottom)
      rct2 = rect(rct.left, rct.top, rct.right - dsplcPoint, rct.bottom)
    end
    randomSeed = seed

    frntImg:copyPixels(tileImage, rct1, gtRect1 + rect(0, 1, 0, 1), { ink = 36 })
    frntImg:copyPixels(tileImage, rct2, gtRect2 + rect(0, 1, 0, 1), { ink = 36 })


    local d = -1
    for ps = 1, #tl.repeatL do
      for ps2n = 1, tl.repeatL[ps] do
        d = d + 1
        if d + dp > 29 then
          break
        else
          member("layer" .. tostring(d + dp)).image:copyPixels(tileImage, rct1,
            gtRect1 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1), { ink = 36 })
          if (colored) then
            if (effectColorA == false) and (effectColorB == false) then
              member("layer" .. tostring(d + dp) .. "dc").image:copyPixels(tileImage, rct1,
                gtRect1 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
                rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 36 })
            end
          end

          if (effectColorA) then
            member("gradientA" .. tostring(d + dp)).image:copyPixels(tileImage, rct1,
              gtRect1 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 39 })
          end

          if (effectColorB) then
            member("gradientB" .. tostring(d + dp)).image:copyPixels(tileImage, rct1,
              gtRect1 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 39 })
          end

          member("layer" .. tostring(d + dp)).image:copyPixels(tileImage, rct2,
            gtRect2 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1), { ink = 36 })
          if (colored) then
            if (effectColorA == false) and (effectColorB == false) then
              member("layer" .. tostring(d + dp) .. "dc").image:copyPixels(tileImage, rct2,
                gtRect2 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
                rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 36 })
            end
          end

          if (effectColorA) then
            member("gradientA" .. tostring(d + dp)).image:copyPixels(tileImage, rct2,
              gtRect2 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 39 })
          end

          if (effectColorB) then
            member("gradientB" .. tostring(d + dp)).image:copyPixels(tileImage, rct2,
              gtRect2 + rect(0, gtRect.height * (ps - 1), 0, gtRect.height * (ps - 1)) + rect(0, 1, 0, 1) +
              rect(tl.sz.x * 20 + (40 * tl.bfTiles), 0, tl.sz.x * 20 + (40 * tl.bfTiles), 0), { ink = 39 })
          end
        end
      end
    end
  elseif tpCase == "voxelStructRockType" then
    local dp
    if l == 1 then
      dp = 0
    elseif l == 2 then
      dp = 10
    else
      dp = 20
    end

    local rct = rect(strt * 20, (strt + tl.sz) * 20) + rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles,
      20 * tl.bfTiles) + rect(-20, -20, -20, -20)
    local gtRect = rect(0, 0, (tl.sz.x * 20) + (40 * tl.bfTiles), (tl.sz.y * 20) + (40 * tl.bfTiles))


    local rnd = random(tl.rnd)

    for d = dp, spelrelaterat.restrict(dp + 9 + (10 * toint(tl.specs2 ~= nil)), 0, 29) do
      if getPos({ 12, 8, 4 }, d) then
        rnd = random(tl.rnd)
      end

      member("layer" .. tostring(d)).image:copyPixels(tileImage, rct,
        gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1), { ink = 36 })

      if (colored) then
        if (effectColorA == FALSE) and (effectColorB == FALSE) then
          member("layer" .. tostring(d) .. "dc").image:copyPixels(tileImage, rct,
            gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
            rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0),
            { ink = 36 })
        end
      end

      if (effectColorA) then
        member("gradientA" .. tostring(d)).image:copyPixels(tileImage, rct,
          gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
          rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0), { ink = 39 })
      end

      if (effectColorB) then
        member("gradientB" .. tostring(d)).image:copyPixels(tileImage, rct,
          gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
          rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0), { ink = 39 })
      end
    end
  elseif tpCase == "voxelStructSandType" then
    local dp
    if (l == 1) then
      dp = 1
    elseif (l == 2) then
      dp = 11
    else
      dp = 21
    end

    local rct = rect(strt * 20, (strt + tl.sz) * 20) +
    rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles, 20 * tl.bfTiles) + rect(-20, -20, -20, -20)
    local gtRect = rect(0, 0, (tl.sz.x * 20) + (40 * tl.bfTiles), (tl.sz.y * 20) + (40 * tl.bfTiles))
    for d = dp, spelrelaterat.restrict(dp + 9 + (10 * (tl.specs2 ~= nil)), 1, 29) do
      local rnd = random(tl.rnd)
      member("layer" .. string(d)).image:copyPixels(tileImage, rct,
        gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1), { ink = 36 })
      if (colored) then
        if (effectColorA == FALSE) and (effectColorB == FALSE) then
          member("layer" .. string(d) .. "dc").image:copyPixels(tileImage, rct,
            gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
            rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0),
            { ink = 36 })
        end
      end
      if (effectColorA) then
        member("gradientA" .. string(d)).image:copyPixels(tileImage, rct,
          gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
          rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0), { ink = 39 })
      end
      if (effectColorB) then
        member("gradientB" .. string(d)).image:copyPixels(tileImage, rct,
          gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1) +
          rect((tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0, (tl.sz.x * 20 + (40 * tl.bfTiles)) * tl.rnd, 0), { ink = 39 })
      end
    end
  elseif tpCase == "voxelStructSeamlessHorizontal" or tpCase == "voxelStructSeamlessVertical" then
    -- By LudoCrypt
    local dp
    if l == 1 then
      dp = 0
    elseif l == 2 then
      dp = 10
    else
      dp = 20
    end

    -- where it actually draws in the image, being the start -> start + sz. Expand by bfTiles. Offset by 20.
    local rct = rect(strt * 20, (strt + tl.sz) * 20) +
    rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles, 20 * tl.bfTiles) + rect(-20, -20, -20, -20)

    -- "get rect" aka source rect aka where it picks from the tile image, being the regular (sz + bfTiles * 2) * 20, used effectively as the unit size
    local gtRect = rect(0, 0, (tl.sz.x * 20) + (40 * tl.bfTiles), (tl.sz.y * 20) + (40 * tl.bfTiles))

    if tl.rnd == -1 then
      local rnd = 1

      for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
        if getPos({ 0, 6 }, spelrelaterat.afaMvLvlEdit(point(q, c) + dir + gRenderCameraTilePos, 1)) ~= 0 then
          break
        else
          rnd = rnd + 1
        end
      end
    else
      rnd = random(tl.rnd)
    end

    if getPos(tl.tags, "ramp") ~= 0 then
      rnd = 2
      if (spelrelaterat.afaMvLvlEdit(point(q, c) + gRenderCameraTilePos, 1) == 3) then
        rnd = 1
      end
    end

    seed = randomSeed

    -- offset within the "unit" for seamless tiles
    local seamOffsetX = 0
    local seamOffsetY = 0

    -- unit size for rnd vars
    local fullSz = rect(0, 0, gtRect.width, gtRect.height)

    local rnd

    if tl.tp == "voxelStructSeamlessHorizontal" then
      fullSz = rect(0, 0, gtRect.width * tl.seam, gtRect.height)

      -- seed based function y (c) coordinate when looping along x (q)
      randomSeed = gLOprops.tileSeed + c
      local tileOffset = q

      if getPos(tl.tags, "seamlessDisplace") ~= 0 then
        tileOffset = q + random(tl.seam)
      end

      seamOffsetX = (toint(tileOffset / tl.sz.x) % tl.seam)

      -- recalculate rnd to accomodate for seam size
      randomSeed = -gLOprops.tileSeed + toint(tileOffset / (tl.sz.x * tl.seam)) + c * gLOprops.tileSeed

      if tl.rnd ~= -1 then
        rnd = random(tl.rnd)
      end
    elseif tl.tp == "voxelStructSeamlessVertical" then
      fullSz = rect(0, 0, gtRect.width, gtRect.height * tl.seam)

      -- seed based function x (q) coordinate when looping along y (c)
      randomSeed = gLOprops.tileSeed + q
      local tileOffset = c

      if tl.tags.getPos("seamlessDisplace") ~= 0 then
        tileOffset = c + random(tl.seam)
      end

      seamOffsetY = (toint(tileOffset / tl.sz.y) % tl.seam)

      -- recalculate rnd to accomodate for seam size
      randomSeed = -gLOprops.tileSeed + toint(tileOffset / (tl.sz.y * tl.seam)) + q * gLOprops.tileSeed

      if tl.rnd ~= -1 then
        rnd = random(tl.rnd)
      end
    end

    randomSeed = seed

    frntImg:copyPixels(tileImage, rct,
      gtRect + rect(fullSz.width * (rnd - 1), 0, fullSz.width * (rnd - 1), 0) +
      rect(seamOffsetX * gtRect.width, seamOffsetY * gtRect.height, seamOffsetX * gtRect.width,
        seamOffsetY * gtRect.height) + rect(0, 1, 0, 1), { ink = 36 })

    local d = -1
    for ps = 1, #tl.repeatL do
      for ps2n = 1, tl.repeatL[ps] do
        d = d + 1
        if d + dp > 29 then
          break
        else
          local copyRect = gtRect +
          rect(fullSz.width * (rnd - 1), fullSz.height * (ps - 1), fullSz.width * (rnd - 1), fullSz.height * (ps - 1)) +
          rect(seamOffsetX * gtRect.width, seamOffsetY * gtRect.height, seamOffsetX * gtRect.width,
            seamOffsetY * gtRect.height) + rect(0, 1, 0, 1)
          member("layer" .. tostring(d + dp)).image:copyPixels(tileImage, rct, copyRect, { ink = 36 })

          if (colored) then
            if (effectColorA == false) and (effectColorB == false) then
              member("layer" .. tostring(d + dp) .. "dc").image:copyPixels(tileImage, rct,
                copyRect + rect(fullSz.width * tl.rnd, 0, fullSz.height * tl.rnd, 0), { ink = 36 })
            end
          end

          if (effectColorA) then
            member("gradientA" .. tostring(d + dp)).image:copyPixels(tileImage, rct,
              copyRect + rect(fullSz.width * tl.rnd, 0, fullSz.height * tl.rnd, 0), { ink = 39 })
          end

          if (effectColorB) then
            member("gradientB" .. tostring(d + dp)).image:copyPixels(tileImage, rct,
              copyRect + rect(fullSz.width * tl.rnd, 0, fullSz.height * tl.rnd, 0), { ink = 39 })
          end
        end
      end
    end
  end

  -- case tl.tp of
  --   "box":
  --   "voxelStruct":
  --   "voxelStructRandomDisplaceHorizontal", "voxelStructRandomDisplaceVertical":
  --   "voxelStructRockType":
  --   "voxelStructSandType":
  --   "voxelStructSeamlessHorizontal", "voxelStructSeamlessVertical":
  -- end case

  for _, tag in ipairs(tl.tags) do
    ---@type Image
    local img
    ---@type table
    local r

    local rnd
    local dp
    local mdPnt

    if tag == "Chain Holder" then
      if (#dt > 2) then
        if (dt[3] ~= "NONE") then
          local ps1 = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10.1, 10.1)
          local ps2 = spelrelaterat.giveMiddleOfTile(dt[3] - gRenderCameraTilePos) + point(10.1, 10.1)

          local dp
          if l == 1 then
            dp = 2
          elseif l == 2 then
            dp = 12
          else
            dp = 22
          end

          -- global gLOprops

          local steps = toint((fiffigt.diag(ps1, ps2) / 12.0) + 0.4999)
          local dr = fiffigt.moveToPoint(ps1, ps2, 1.0)
          local ornt = random(2) - 1
          local degDir = fiffigt.lookatpoint(ps1, ps2)
          local stp = random(100) * 0.01

          for q = 1, steps do
            local pos = ps1 + (dr * 12 * (q - stp))
            local rct
            local gtRect

            if toint(ornt) then
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
            member("layer" .. tostring(dp)).image:copyPixels(member("bigChainSegment").image,
              spelrelaterat.rotateToQuad(rct, degDir), gtRect, { color = gLOprops.pals[gLOprops.pal].detCol, ink = 36 })
            -- member("layer"..tostring(dp)).image:copyPixels(member("bigChainSegment").image, rct, member("bigChainSegment").image.rect, {color=color(255,0,0), ink=36})
          end
        end
      end
    elseif tag == "fanBlade" then
      local dp
      if l == 1 then
        dp = 10
      elseif l == 2 then
        dp = 20
      else
        dp = 25
      end

      local rct = rect(-23, -23, 23, 23) +
      rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c)))
      -- dp = 1
      member("layer" .. tostring(dp - 2)).image:copyPixels(member("fanBlade").image,
        spelrelaterat.rotateToQuad(rct, random(360)), member("fanBlade").image.rect, { ink = 36, color = color(0, 255, 0) })

      member("layer" .. tostring(dp)).image:copyPixels(member("fanBlade").image,
        spelrelaterat.rotateToQuad(rct, random(360)), member("fanBlade").image.rect, { ink = 36, color = color(0, 255, 0) })
    elseif tag == "Big Wheel" then
      ---@type table
      local dpsL

      if l == 1 then
        dpsL = { 0, 7 }
      elseif l == 2 then
        dpsL = { 9, 17 }
      else
        dpsL = { 19, 27 }
      end

      local rct = rect(-90, -90, 90, 90) +
      rect(spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10),
        spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10))
      -- dp = 1
      for _, dp1 in ipairs(dpsL) do
        local rnd = random(360)
        for _, dp in ipairs({ dp1, dp1 + 1, dp1 + 2 }) do
          member("layer" .. tostring(dp)).image:copyPixels(member("Big Wheel Graf").image,
            spelrelaterat.rotateToQuad(rct, rnd + 0.001), member("Big Wheel Graf").image.rect,
            { ink = 36, color = color(0, 255, 0) })
        end
      end
    elseif tag == "Sawblades" then
      local dpsL

      if l == 1 then
        dpsL = { 0, 7 }
      elseif l == 2 then
        dpsL = { 9, 17 }
      else
        dpsL = { 19, 27 }
      end

      local rct = rect(-90, -90, 90, 90) +
      rect(giveMiddleOfTile(point(q, c)) + point(10, 10), giveMiddleOfTile(point(q, c)) + point(10, 10))

      for _, dp1 in iapirs(dpsL) do
        local rnd = random(360)
        for _, dp in ipairs({ dp1 }) do
          member("layer" .. tostring(dp)).image:copyPixels(member("sawbladeGraf").image, rotateToQuad(rct, rnd + 0.001),
            member("sawbladeGraf").image.rect, { ink = 36, color = color(0, 0, 255) })
        end
      end
    elseif tag == "randomCords" then
      local dp
      if l == 1 then
        dp = random(9)
      elseif l == 2 then
        dp = 10 + random(9)
      else
        dp = 20 + random(9)
      end
      -- put tl
      local pnt = spelrelaterat.giveMiddleOfTile(point(q, c + (tl.sz.y / 2))) -- + point(-0.5*tl.sz.x+random(tl.sz.x), 0)
      local rct = rect(-50, -50, 50, 50) + rect(pnt, pnt)
      -- dp = 1
      --  member("layer"..tostring(dp-2)).image:copyPixels(member("fanBlade").image, rotateToQuad(rct, random(360)), member("fanBlade").image.rect, {ink=36, color=color(0,255,0)})
      local rnd = random(7)
      member("layer" .. tostring(dp)).image:copyPixels(member("randomCords").image,
        spelrelaterat.rotateToQuad(rct, -30 + random(60)), rect((rnd - 1) * 100, 0, rnd * 100, 100) + rect(1, 1, 1, 1),
        { ink = 36 })
    elseif tag == "Big Sign" then
      -- put "BIG SIGN"
      img = image(60, 60) -- 1

      local rnd = random(20)
      local rct = rect(3, 3, 29, 33)

      img:copyPixels(member("bigSigns1").image, rct, rect((rnd - 1) * 26, 0, rnd * 26, 30), { ink = 36, color = color(0,
        0, 0) })
      rnd = random(20)
      rct = rect(3 + 28, 3, 29 + 28, 33)
      img:copyPixels(member("bigSigns1").image, rct, rect((rnd - 1) * 26, 0, rnd * 26, 30), { ink = 36, color = color(0,
        0, 0) })
      rnd = random(14)
      rct = rect(3, 35, 3 + 55, 35 + 24)
      img:copyPixels(member("bigSigns2").image, rct, rect((rnd - 1) * 55, 0, rnd * 55, 24), { ink = 36, color = color(0,
        0, 0) })

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        frntImg:copyPixels(img,
          rect(-30, -30, 30, 30) +
          rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
          rect(r[1], r[1]), rect(0, 0, 60, 60), { ink = 36, color = r[2] })
      end


      local dp
      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      frntImg:copyPixels(img,
        rect(-30, -30, 30, 30) +
        rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))), rect(0, 0, 60, 60),
        { ink = 36, color = color(255, 0, 255) })
      --member("layer"..tostring(dp-1)).image:copyPixels(img, rect(-30,-30,30,30)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c))), rect(0,0,60,60), {ink=36, color=color(255,255,255)})
      --member("layer"..tostring(dp)).image:copyPixels(img, rect(-30,-30,30,30)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c))), rect(0,0,60,60), {ink=36, color=color(255,0,255)})

      local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) --depthPnt(giveMiddleOfTile(point(q,c)), -5+dp)

      spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-30, -30), mdPnt + point(30, 30)),
        "bigSignGradient", rect(0, 0, 60, 60), 1, 1.0)
    elseif tag == "Big Sign B" then
      -- put "BIG SIGN"
      img = image(60, 60) -- 1
      local rnd = random(20)
      local rct = rect(3, 3, 29, 33)
      img:copyPixels(member("bigSigns1").image, rct, rect((rnd - 1) * 26, 0, rnd * 26, 30), { ink = 36, color = color(0,
        0, 0) })
      rnd = random(20)
      rct = rect(3 + 28, 3, 29 + 28, 33)
      img:copyPixels(member("bigSigns1").image, rct, rect((rnd - 1) * 26, 0, rnd * 26, 30), { ink = 36, color = color(0,
        0, 0) })
      rnd = random(14)
      rct = rect(3, 35, 3 + 55, 35 + 24)
      img:copyPixels(member("bigSigns2").image, rct, rect((rnd - 1) * 55, 0, rnd * 55, 24), { ink = 36, color = color(0,
        0, 0) })

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        frntImg:copyPixels(img,
          rect(-30, -30, 30, 30) +
          rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
          rect(r[1], r[1]), rect(0, 0, 60, 60), { ink = 36, color = r[2] })
      end


      local dp
      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      frntImg:copyPixels(img,
        rect(-30, -30, 30, 30) +
        rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))), rect(0, 0, 60, 60),
        { ink = 36, color = color(0, 255, 255) })
      --member("layer"..tostring(dp-1)).image:copyPixels(img, rect(-30,-30,30,30)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c))), rect(0,0,60,60), {ink=36, color=color(255,255,255)})
      --member("layer"..tostring(dp)).image:copyPixels(img, rect(-30,-30,30,30)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c))), rect(0,0,60,60), {ink=36, color=color(255,0,255)})

      local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) --depthPnt(giveMiddleOfTile(point(q,c)), -5+dp)

      spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-30, -30), mdPnt + point(30, 30)),
        "bigSignGradient", rect(0, 0, 60, 60), 1, 1.0)
    elseif tag == "Big Western Sign" or tag == "Big Western Sign Tilted" then
      img = image(36, 48) -- 1
      local rnd = random(20)
      --  rct = rect(3,3,29,33)
      img:copyPixels(member("bigWesternSigns").image, img.rect, rect((rnd - 1) * 36, 0, rnd * 36, 48),
        { ink = 36, color = color(0, 0, 0) })


      local mdPoint = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)
      local lst = { { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(255, 0, 255) } }

      if tag == "Big Western Sign Tilted" then
        local tlt = -45.1 + random(90)
        for _, r in ipairs(lst) do
          frntImg:copyPixels(img,
            spelrelaterat.rotateToQuad(rect(mdPoint, mdPoint) + rect(-18, -24, 18, 24) + rect(r[1], r[1]), tlt),
            rect(0, 0, 36, 48), { ink = 36, color = r[2] })
        end
      else
        for _, r in ipairs(lst) do
          frntImg:copyPixels(img, rect(mdPoint, mdPoint) + rect(-18, -24, 18, 24) + rect(r[1], r[1]), rect(0, 0, 36, 48),
            { ink = 36, color = r[2] })
        end
      end

      local dp
      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end
      spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPoint + point(-25, -30), mdPoint + point(25, 30)),
        "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
    elseif tag == "Big Western Sign B" or tag == "Big Western Sign Tilted B" then
      img = image(36, 48)
      rnd = random(20)
      --  rct = rect(3,3,29,33)
      img:copyPixels(member("bigWesternSigns").image, img.rect, rect((rnd - 1) * 36, 0, rnd * 36, 48),
        { ink = 36, color = color(0, 0, 0) })


      local mdPoint = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)
      local lst = { { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(0, 255, 255) } }

      if tag == "Big Western Sign Tilted B" then
        local tlt = -45.1 + random(90)
        for _, r in ipairs(lst) do
          frntImg:copyPixels(img,
            spelrelaterat.rotateToQuad(rect(mdPoint, mdPoint) + rect(-18, -24, 18, 24) + rect(r[1], r[1]), tlt),
            rect(0, 0, 36, 48), { ink = 36, color = r[2] })
        end
      else
        for _, r in ipairs(lst) do
          frntImg:copyPixels(img, rect(mdPoint, mdPoint) + rect(-18, -24, 18, 24) + rect(r[1], r[1]), rect(0, 0, 36, 48),
            { ink = 36, color = r[2] })
        end
      end

      local dp
      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPoint + point(-25, -30), mdPoint + point(25, 30)),
        "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
    elseif tag == "Small Asian Sign" or tag == "small asian sign function wall" then
      img = image(20, 20)
      rnd = random(14)
      local rct = rect(0, 1, 20, 18)
      img:copyPixels(member("smallAsianSigns").image, rct, rect((rnd - 1) * 20, 0, rnd * 20, 17),
        { ink = 36, color = color(0, 0, 0) })

      if tag == "Small Asian Sign" then
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(255, 0, 255) } }) do
          frntImg:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end

        if l == 1 then
          dp = 0
        elseif l == 2 then
          dp = 10
        else
          dp = 20
        end

        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1)
      else
        if l == 1 then
          dp = 8
        elseif l == 2 then
          dp = 18
        else
          dp = 28
        end

        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(255, 0, 255) } }) do
          member("layer" .. tostring(dp)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          member("layer" .. tostring(dp + 1)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          -- member("layer"..tostring(dp+2)).image:copyPixels(img, rect(-10,-10,10,10)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c)))+rect(r[1],r[1]), rect(0,0,20,20), {ink=36, color=r[2]})
        end

        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
      end
    elseif tag == "Small Asian Sign B" or tag == "small asian sign function wall B" then
      img = image(20, 20)
      rnd = random(14)
      local rct = rect(0, 1, 20, 18)
      img:copyPixels(member("smallAsianSigns").image, rct, rect((rnd - 1) * 20, 0, rnd * 20, 17),
        { ink = 36, color = color(0, 0, 0) })

      if tag == "Small Asian Sign B" then
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(0, 255, 255) } }) do
          frntImg:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end

        if l == 1 then
          dp = 0
        elseif l == 2 then
          dp = 10
        else
          dp = 20
        end

        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1)
      else
        if l == 1 then
          dp = 8
        elseif l == 2 then
          dp = 18
        else
          dp = 28
        end
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(0, 255, 255) } }) do
          member("layer" .. tostring(dp)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          member("layer" .. tostring(dp + 1)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          -- member("layer"..tostring(dp+2)).image:copyPixels(img, rect(-10,-10,10,10)+rect(giveMiddleOfTile(point(q,c)), giveMiddleOfTile(point(q,c)))+rect(r[1],r[1]), rect(0,0,20,20), {ink=36, color=r[2]})
        end
        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
      end
    elseif tag == "Small Asian Sign Station" or tag == "small asian sign on wall Station" then
      img = image(20, 20)
      rnd = random(14)
      local rct = rect(0, 1, 20, 18)
      img:copyPixels(member("smallAsianSignsStation").image, rct, rect((rnd - 1) * 20, 0, rnd * 20, 17),
        { ink = 36, color = color(0, 0, 0) })

      if tag == "Small Asian Sign Station" then
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(255, 0, 255) } }) do
          frntImg:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end

        if l == 1 then
          dp = 0
        elseif l == 2 then
          dp = 10
        else
          dp = 20
        end

        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1)
      else
        if l == 1 then
          dp = 8
        elseif l == 2 then
          dp = 18
        else
          dp = 28
        end

        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(255, 0, 255) } }) do
          member("layer" .. tostring(dp)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          member("layer" .. tostring(dp + 1)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end
        local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
      end
    elseif tag == "Small Asian Sign Station B" or tag == "small asian sign on wall Station B" then
      img = image(20, 20)
      rnd = random(14)
      local rct = rect(0, 1, 20, 18)
      img:copyPixels(member("smallAsianSignsStation").image, rct, rect((rnd - 1) * 20, 0, rnd * 20, 17),
        { ink = 36, color = color(0, 0, 0) })

      if tag == "Small Asian Sign Station B" then
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(0, 255, 255) } }) do
          frntImg:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end

        if l == 1 then
          dp = 0
        elseif l == 2 then
          dp = 10
        else
          dp = 20
        end

        mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1)
      else
        if l == 1 then
          dp = 8
        elseif l == 2 then
          dp = 18
        else
          dp = 28
        end
        for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(0, 0), color(0, 255, 255) } }) do
          member("layer" .. tostring(dp)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
          member("layer" .. tostring(dp + 1)).image:copyPixels(img,
            rect(-10, -10, 10, 10) +
            rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c))) +
            rect(r[1], r[1]), rect(0, 0, 20, 20), { ink = 36, color = r[2] })
        end
        mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
        spelrelaterat.copyPixelsToEffectColor("B", dp, rect(mdPnt + point(-13, -13), mdPnt + point(13, 13)),
          "bigSignGradient", rect(0, 0, 60, 60), 1, 1)
      end
    elseif tag == "glass" then
      if l == 1 then
        rct = rect(-10 * tl.sz.x, -10 * tl.sz.y, 10 * tl.sz.x, 10 * tl.sz.y) +
        rect(spelrelaterat.giveMiddleOfTile(point(q, c)), spelrelaterat.giveMiddleOfTile(point(q, c)))
        member("glassImage").image:copyPixels(member("pxl").image, rct, rect(0, 0, 1, 1), { ink = 36 })
      end
    elseif tag == "harvester" then
      spelrelaterat.renderHarvesterDetails(q, c, l, tl, frntImg, dt)
    elseif tag == "Temple Floor" then
      local tileCat = 0
      for a = 1, #gTiles do
        if (gTiles[a].nm == "Temple Stone") then
          tileCat = a
          break
        end
      end

      local actualTlPs = point(q, c) + gRenderCameraTilePos

      local nextIsFloor = false
      if (actualTlPs.x + 8 <= #gTEProps.tlMatrix) then
        if (gTEProps.tlMatrix[actualTlPs.x + 8][actualTlPs.y][l].tp == "tileHead") then
          if (gTEProps.tlMatrix[actualTlPs.x + 8][actualTlPs.y][l].data[2] == "Temple Floor") then
            nextIsFloor = true
          end
        end
      end

      local prevIsFloor = false
      if (actualTlPs.x - 8 > 0) then
        if (gTEProps.tlMatrix[actualTlPs.x - 8][actualTlPs.y][l].tp == "tileHead") then
          if (gTEProps.tlMatrix[actualTlPs.x - 8][actualTlPs.y][l].data[2] == "Temple Floor") then
            prevIsFloor = true
          end
        end
      end

      if (prevIsFloor) then
        frntImg = me.drawATileTile(q + gRenderCameraTilePos.x - 4, c + gRenderCameraTilePos.y - 1, l,
          gTiles[tileCat].tls[13], frntImg)
      else
        frntImg = me.drawATileTile(q + gRenderCameraTilePos.x - 3, c + gRenderCameraTilePos.y - 1, l,
          gTiles[tileCat].tls[7], frntImg)
      end

      if (not nextIsFloor) then
        frntImg = me.drawATileTile(q + gRenderCameraTilePos.x + 4, c + gRenderCameraTilePos.y - 1, l,
          gTiles[tileCat].tls[8], frntImg)
      end

      --  drawATileTile(q-4, c-1, l, [#nm:"Temple Stone Wedge", #sz:point(2,1), #specs:[], #specs2:void, #tp:"voxelStruct", #repeatL:[1,1,1,1,6], #bfTiles:0, #rnd:1, #ptPos:0, #tags:[]], frntImg)
      --  drawATileTile(q+4, c-1, l, [#nm:"Temple Stone Wedge", #sz:point(2,1), #specs:[], #specs2:void, #tp:"voxelStruct", #repeatL:[1,1,1,1,6], #bfTiles:0, #rnd:1, #ptPos:0, #tags:[]], frntImg)
    elseif tag == "Larger Sign" then
      -- put "BIG SIGN"
      img = image(80 + 6, 100 + 6)
      rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSigns").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100),
        { ink = 36, color = color(0, 0, 0) })

      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. string(dp + d)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) +
          rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r[2] })
        end
      end


      member("layer" .. string(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106),
        { ink = 36, color = color(255, 255, 255) })
      member("layer" .. string(dp + 1)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt),
        rect(0, 0, 86, 106), { ink = 36, color = color(255, 0, 255) })

      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          local rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1) --+ rect(0,0,-1,-1)

          if (random(7) == 1) then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif (random(7) == 1) then
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

      spelrelaterat.copyPixelsToEffectColor("A", dp + 1, rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)),
        "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    elseif tag == "Larger Sign B" then
      -- put "BIG SIGN"
      img = image(80 + 6, 100 + 6)
      rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSigns").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100),
        { ink = 36, color = color(0, 0, 0) })

      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. string(dp + d)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) +
          rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r[2] })
        end
      end

      member("layer" .. string(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106),
        { ink = 36, color = color(255, 255, 255) })
      member("layer" .. string(dp + 1)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt),
        rect(0, 0, 86, 106), { ink = 36, color = color(0, 255, 255) })

      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          local rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1) --+ rect(0,0,-1,-1)
          if (random(7) == 1) then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif (random(7) == 1) then
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

      spelrelaterat.copyPixelsToEffectColor("B", dp + 1, rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)),
        "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    elseif tag == "Station Larger Sign" then
      img = image(80 + 6, 100 + 6)
      rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSignsStation").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100) + rect(0, 1, 0, 1),
        { ink = 36, color = color(0, 0, 0) })

      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. string(dp + d)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) +
          rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r[2] })
        end
      end

      member("layer" .. string(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106),
        { ink = 36, color = color(255, 255, 255) })
      member("layer" .. string(dp + 1)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt),
        rect(0, 0, 86, 106), { ink = 36, color = color(255, 0, 255) })
      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          local rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1)
          if (random(7) == 1) then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif (random(7) == 1) then
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

      spelrelaterat.copyPixelsToEffectColor("A", dp + 1, rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)),
        "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    elseif tag == "Station Larger Sign B" then
      img = image(80 + 6, 100 + 6)
      rnd = random(14)
      local rct = rect(3, 3, 83, 103)
      img:copyPixels(member("largerSignsStation").image, rct, rect((rnd - 1) * 80, 0, rnd * 80, 100) + rect(0, 1, 0, 1),
        { ink = 36, color = color(0, 0, 0) })

      if l == 1 then
        dp = 0
      elseif l == 2 then
        dp = 10
      else
        dp = 20
      end

      mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 0)

      for _, r in ipairs({ { point(-4, -4), color(0, 0, 255) }, { point(-3, -3), color(0, 0, 255) }, { point(3, 3), color(255, 0, 0) }, { point(4, 4), color(255, 0, 0) }, { point(-2, -2), color(0, 255, 0) }, { point(-1, -1), color(0, 255, 0) }, { point(0, 0), color(0, 255, 0) }, { point(1, 1), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) }, { point(2, 2), color(0, 255, 0) } }) do
        for d = 0, 1 do
          member("layer" .. string(dp + d)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt) +
          rect(r[1], r[1]), rect(0, 0, 86, 106), { ink = 36, color = r[2] })
        end
      end

      member("layer" .. string(dp)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt), rect(0, 0, 86, 106),
        { ink = 36, color = color(255, 255, 255) })
      member("layer" .. string(dp + 1)).image:copyPixels(img, rect(-43, -53, 43, 53) + rect(mdPnt, mdPnt),
        rect(0, 0, 86, 106), { ink = 36, color = color(0, 255, 255) })
      member("largeSignGrad2").image:copyPixels(member("largeSignGrad").image, rect(0, 0, 80, 100), rect(0, 0, 80, 100))

      for a = 0, 6 do
        for b = 0, 13 do
          local rct = rect((a * 16) - 6, (b * 8) - 1, ((a + 1) * 16) - 6, ((b + 1) * 8) - 1)
          if (random(7) == 1) then
            local blnd = random(random(100))
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(0, 0, 1, 1), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
            member("largeSignGrad2").image:copyPixels(member("pxl").image, rct + rect(1, 1, 0, 0), rect(0, 0, 1, 1),
              { color = color(255, 255, 255), blend = blnd / 2 })
          elseif (random(7) == 1) then
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
      spelrelaterat.copyPixelsToEffectColor("B", dp + 1, rect(mdPnt + point(-43, -53), mdPnt + point(43, 53)),
        "largeSignGrad2", rect(0, 0, 86, 106), 1, 1.0)
    elseif tag == "Station Lamp" then
      -- Magic stuff
      img = image(40, 20)                                                                                                   -- 1 --Single variation size (w(+buffer), h(+buffer), (???))
      rnd = random(1)                                                                                                       -- Variations
      local rct = rect(1, 1, 39, 19)                                                                                        -- I don't know what this does
      img:copyPixels(member("StationLamp").image, img.rect, rect((rnd - 1) * 40, 0, rnd * 40, 20),
        { ink = 36, color = color(0, 0, 0) })                                                                               -- Image thingy

      --lst = [[point(-4,-4), color(0,0,255)],[point(-3,-3), color(0,0,255)],[point(3,3), color(255,0,0)],[point(4,4), color(255,0,0)],[point(-2,-2), color(0,255,0)], [point(-1,-1), color(0,255,0)], [point(0,0), color(0,255,0)], [point(1,1), color(0,255,0)], [point(2,2), color(0,255,0)], [point(0,0), color(255,0,255)]]
      for _, r in ipairs({ { point(0, 0), color(255, 0, 255) } }) do --Creates the colour space
        frntImg:copyPixels(img,
          rect(-20, -10, 20, 10) +
          rect(spelrelaterat.giveMiddleOfTile(point(q, c)) + point(11, 1),
            spelrelaterat.giveMiddleOfTile(point(q, c)) + point(11, 1)) + rect(r[1], r[1]), rect(0, 0, 40, 20),
          { ink = 36, color = r[2] })
      end

      if l == 1 then
        dp = 1
      elseif l == 2 then
        dp = 11
      else
        dp = 21
      end

      mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c)) + point(11, 1)
      spelrelaterat.copyPixelsToEffectColor("A", dp, rect(mdPnt + point(-20, -10), mdPnt + point(20, 10)),
        "StationLampGradient", rect(0, 0, 40, 20), 1)
    elseif tag == "LumiaireH" then
      if l == 1 then
        dp = 7
      elseif l == 2 then
        dp = 17
      else
        dp = 27
      end

      local rct = rect(-29, -11, 29, 11) +
      rect(spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10),
        spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10))
      member("layer" .. tostring(dp)).image:copyPixels(member("LumiaireH").image, rct, member("LumiaireH").image.rect,
        { ink = 36, color = color(255, 0, 255) })
      member("gradientA" .. tostring(dp)).image:copyPixels(member("LumHGrad").image, rct, member("LumHGrad").image.rect,
        { ink = 39 })
    elseif tag == "LumiaireV" then
      if l == 1 then
        dp = 7
      elseif l == 2 then
        dp = 17
      else
        dp = 27
      end

      rct = rect(-11, -29, 11, 29) +
      rect(spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10),
        spelrelaterat.giveMiddleOfTile(point(q, c)) + point(10, 10))
      member("layer" .. tostring(dp)).image:copyPixels(member("LumiaireV").image, rct, member("LumiaireV").image.rect,
        { ink = 36, color = color(255, 0, 255) })
      member("gradientA" .. tostring(dp)).image:copyPixels(member("LumVGrad").image, rct, member("LumVGrad").image.rect,
        { ink = 39 })
    end

    -- case tag of
    --   "Chain Holder":
    --   "fanBlade":
    --   "Big Wheel":
    --   "Sawblades":
    --   "randomCords":
    --   "Big Sign":
    --   "Big Sign B":
    --   "Big Western Sign", "Big Western Sign Tilted":
    --   "Big Western Sign B", "Big Western Sign Tilted B":
    --   "Small Asian Sign", "small asian sign function wall":
    --   "Small Asian Sign B", "small asian sign function wall B":
    --   "Small Asian Sign Station", "Small Asian Sign On Wall Station":
    --   "Small Asian Sign Station B", "Small Asian Sign On Wall Station B":
    --   "glass":
    --   "harvester":
    --   "Temple Floor":
    --   "Larger Sign":
    --   "Larger Sign B":
    --   "Station Larger Sign":
    --   "Station Larger Sign B":
    --   "Station Lamp": -- Dry does documentation during a 24 hr session :( On the bright side, it's documentation.

    --   "LumiaireH":


    --   "LumiaireV":


    -- end case
  end

  return frntImg
end

--function drawAShortCut(q, c, l, pltt, frntImg)
--  --  if l = 1 then
--  dp = 0
--  --  else
--  --    dp = 10
--  --  end
--
--  rct = rect(strt*20, (strt+tl.sz)*20)+rect(-20*tl.bfTiles, -20*tl.bfTiles, 20*tl.bfTiles, 20*tl.bfTiles)+rect(-20, -20, -20, -20)
--  gtRect = rect(0,0,(tl.sz.x*20)+(40*tl.bfTiles), (tl.sz.y*20)+(40*tl.bfTiles))
--  d = 0
--  repeat with ps = 1 to tl.repeatL.count then
--    repeat with ps2 = 1 to tl.repeatL[ps] then
--      -- gtRect =  + rect(0, (((tl.sz.y*20)+(40*tl.bfTiles))-1)*d, 0, ((tl.sz.y*20)+(40*tl.bfTiles))*d)
--      member("layer"..tostring(d+dp)).image:copyPixels(tileImage, rct, gtRect + rect(0,gtRect.height*(ps-1), 0, gtRect.height*(ps-1))+rect(0,1,0,1), {ink=36})
--      d = d + 1
--    end
--  end
--end

---@param row number
---@param dpt number
---@param tl unknown
function me.drawHorizontalSurface(row, dpt, tl)
  -- if row < 10 then
  local pnt1 = point(0, row * 20)
  local pnt2 = point(gLOprops.size.x * 20, row * 20)

  for q = 1, 10 do
    local dp = dpt + 10 - q
    -- pt1 = depthPnt(pnt1, dp-5)
    --  pt2 = depthPnt(pnt2, dp-5)
    member("layer" .. tostring(dp)).image:copyPixels(member("horiImg").image, rect(pnt1 + point(0, 15), pnt2 +
    point(0, 20)), rect(pnt1, pnt2) + rect(0, 20 - q, 0, 21 - q), { ink = 36 })
    --member("layer"..tostring(dp).."dc").image:copyPixels(member("horiDc").image, rect(pnt1+point(0,15), pnt2+point(0,20)), rect(pnt1, pnt2)+rect(0,20-q,0,21-q), {ink=36})
    --member("gradientA"..tostring(dp)).image:copyPixels(member("horiGradA").image, rect(pnt1+point(0,15), pnt2+point(0,20)), rect(pnt1, pnt2)+rect(0,20-q,0,21-q), {ink=36})
    --member("gradientB"..tostring(dp)).image:copyPixels(member("horiGradB").image, rect(pnt1+point(0,15), pnt2+point(0,20)), rect(pnt1, pnt2)+rect(0,20-q,0,21-q), {ink=36})
  end
  -- else
  pnt1 = point(0, (row - 1) * 20)
  pnt2 = point(gLOprops.size.x * 20, (row - 1) * 20)
  for q = 1, 10 do
    local dp = dpt + 10 - q
    --   pt1 = depthPnt(pnt1, dp-5)
    -- pt2 = depthPnt(pnt2, dp-5)
    member("layer" .. tostring(dp)).image:copyPixels(member("horiImg").image, rect(pnt1 + point(0, 0), pnt2 + point(0, 5)),
      rect(pnt1, pnt2) + rect(0, q, 0, q + 1), { ink = 36 })
    --member("layer"..tostring(dp).."dc").image:copyPixels(member("horiDc").image, rect(pnt1+point(0,0), pnt2+point(0,5)), rect(pnt1, pnt2)+rect(0,q,0,q+1), {ink=36})
    --member("gradientA"..tostring(dp)).image:copyPixels(member("horiGradA").image, rect(pnt1+point(0,0), pnt2+point(0,5)), rect(pnt1, pnt2)+rect(0,q,0,q+1), {ink=36})
    --member("gradientB"..tostring(dp)).image:copyPixels(member("horiGradB").image, rect(pnt1+point(0,0), pnt2+point(0,5)), rect(pnt1, pnt2)+rect(0,q,0,q+1), {ink=36})
  end
  --end
end

---@param col number
---@param dpt number
---@param tl unknown
function me.drawVerticalSurface(col, dpt, tl)
  --if col < 26 then
  local pnt1 = point(col * 20, 0)
  local pnt2 = point(col * 20, gLOprops.size.y * 20)

  for q = 1, 10 do
    local dp = dpt + 10 - q
    --   pt1 = depthPnt(pnt1, dp-5)
    --  pt2 = depthPnt(pnt2, dp-5)
    member("layer" .. tostring(dp)).image:copyPixels(member("vertImg").image, rect(pnt1 + point(15, 0), pnt2 +
    point(20, 0)), rect(pnt1, pnt2) + rect(20 - q, 0, 21 - q, 0), { ink = 36 })
    --member("layer"..tostring(dp).."dc").image:copyPixels(member("vertDc").image, rect(pnt1+point(15,0), pnt2+point(20,0)), rect(pnt1, pnt2)+rect(20-q,0,21-q,0), {ink=36})
    --member("gradientA"..tostring(dp)).image:copyPixels(member("vertGradA").image, rect(pnt1+point(15,0), pnt2+point(20,0)), rect(pnt1, pnt2)+rect(20-q,0,21-q,0), {ink=36})
    --member("gradientB"..tostring(dp)).image:copyPixels(member("vertGradB").image, rect(pnt1+point(15,0), pnt2+point(20,0)), rect(pnt1, pnt2)+rect(20-q,0,21-q,0), {ink=36})
  end
  --else
  pnt1 = point((col - 1) * 20, 0)
  pnt2 = point((col - 1) * 20, gLOprops.size.y * 20)
  for q = 1, 10 do
    local dp = dpt + 10 - q
    --  pt1 = depthPnt(pnt1, dp-5)
    --  pt2 = depthPnt(pnt2, dp-5)
    member("layer" .. tostring(dp)).image:copyPixels(member("vertImg").image, rect(pnt1 + point(0, 0), pnt2 + point(5, 0)),
      rect(pnt1, pnt2) + rect(q, 0, q + 1, 0), { ink = 36 })
    --member("layer"..tostring(dp).."dc").image:copyPixels(member("vertDc").image, rect(pnt1+point(0,0), pnt2+point(5,0)), rect(pnt1, pnt2)+rect(q,0,q+1, 0), {ink=36})
    --member("gradientA"..tostring(dp)).image:copyPixels(member("vertGradA").image, rect(pnt1+point(0,0), pnt2+point(5,0)), rect(pnt1, pnt2)+rect(q,0,q+1, 0), {ink=36})
    --member("gradientB"..tostring(dp)).image:copyPixels(member("vertGradB").image, rect(pnt1+point(0,0), pnt2+point(5,0)), rect(pnt1, pnt2)+rect(q,0,q+1, 0), {ink=36})
  end
  --end
end

function me.giveDptFromCol(col)
  local val = 255
  for q = 0, 19 do
    print(val)
    val = toint(val * 0.9)
  end
end

function me.drawPipeTypeTile(mat, tl, layer)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local gtPos = point(0, 0)

  local geoCase = gLEProps.matrix[tl.x][tl.y][layer][1]

  if geoCase == 1 then
    local nbrs = ""
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      --if afaMvLvlEdit(tl+dir, layer)=1 then
      if (random(2) == 1) and (spelrelaterat.afaMvLvlEdit(tl + dir, layer) == 1) then
        nbrs = nbrs .. "1"
      else
        nbrs = nbrs .. tostring(toint(me.isMyTileSetOpenToThisTile(mat, tl + dir, layer)))
      end
      -- else
      --  nbrs = nbrs .. "0"
      --end
    end

    if nbrs == "0101" then
      gtPos = point(2, 2)
    elseif nbrs == "1010" then
      gtPos = point(4, 2)
    elseif nbrs == "1111" then
      gtPos = point(6, 2)
    elseif nbrs == "0111" then
      gtPos = point(8, 2)
    elseif nbrs == "1101" then
      gtPos = point(10, 2)
    elseif nbrs == "1110" then
      gtPos = point(12, 2)
    elseif nbrs == "1011" then
      gtPos = point(14, 2)
    elseif nbrs == "0011" then
      gtPos = point(16, 2)
    elseif nbrs == "1001" then
      gtPos = point(18, 2)
    elseif nbrs == "1100" then
      gtPos = point(20, 2)
    elseif nbrs == "0110" then
      gtPos = point(22, 2)
    elseif nbrs == "1000" then
      gtPos = point(24, 2)
    elseif nbrs == "0010" then
      gtPos = point(26, 2)
    elseif nbrs == "0100" then
      gtPos = point(28, 2)
    elseif nbrs == "0001" then
      gtPos = point(30, 2)
    elseif nbrs == "0000" then
      if tobool(gDRMatFixes) then
        gtPos = point(40, 2)
      end
    end

    if mat == "small Pipes" then
      member("layer" .. tostring(((layer - 1) * 10) + 5)).image:copyPixels(member("frameWork").image,
        rect((tl.x - 1 - gRenderCameraTilePos.x) * 20, (tl.y - 1 - gRenderCameraTilePos.y) * 20,
          (tl.x - gRenderCameraTilePos.x) * 20, (tl.y - gRenderCameraTilePos.y) * 20), rect(0, 0, 20, 20), { ink = 36 })
    end
  elseif geoCase == 2 then
    gtPos = point(34, 2)
  elseif geoCase == 3 then
    gtPos = point(32, 2)
  elseif geoCase == 4 then
    gtPos = point(36, 2)
  elseif geoCase == 5 then
    gtPos = point(38, 2)
  elseif geoCase == 6 then
    if tobool(gDRMatFixes) then
      gtPos = point(42, 2)
    end
  elseif geoCase == 9 then
    if tobool(gDRMatFixes) then
      gtPos = point(44, 2)
    end
  end

  -- case gLEProps.matrix[tl.x][tl.y][layer][1] of
  --   1:


  --     --  put nbrs
  --     -- case nbrs of
  --     --   "0101":
  --     --   "1010":
  --     --   "1111":
  --     --   "0111":
  --     --   "1101":
  --     --   "1110":
  --     --   "1011":
  --     --   "0011":
  --     --   "1001":
  --     --   "1100":

  --     --   "0110":

  --     --   "1000":

  --     --   "0010":

  --     --   "0100":

  --     --   "0001":

  --     --   "0000":


  --     -- end case


  --   3:

  --   2:

  --   4:

  --   5:

  --   6:

  --   9:

  -- end case

  local mem

  local lowerCaseMat = string.lower(mat)

  if lowerCaseMat == "small pipes" then
    mem = "pipeTiles2"
  elseif lowerCaseMat == "trash" then
    mem = "trashTiles3"
  elseif lowerCaseMat == "largetrash" then
    mem = "largeTrashTiles"
  elseif lowerCaseMat == "megatrash" then
    mem = "largeTrashTiles"
  elseif lowerCaseMat == "dirt" then
    mem = "dirtTiles"
  elseif lowerCaseMat == "sandy dirt" then
    mem = "sandyDirtTiles"
  end

  -- case mat of
  --   "small Pipes":
  --   "trash":
  --   "largeTrash":
  --   "megaTrash":
  --   "dirt":
  --   "Sandy Dirt":
  -- end case

  -- d = [2,11,21][layer]
  for _, startLayer in ipairs({ ((layer - 1) * 10) + 2, ((layer - 1) * 10) + 7 }) do
    local rndList = { 2, 4, 6, 8 }
    local genR = random(4)
    gtPos.y = rndList[genR]
    local rct = rect((gtPos.x - 1) * 20, (gtPos.y - 1) * 20, gtPos.x * 20, gtPos.y * 20)
    for d = startLayer, startLayer + 1 do
      member("layer" .. tostring(d)).image:copyPixels(member(mem).image,
        rect((tl.x - 1 - gRenderCameraTilePos.x) * 20, (tl.y - 1 - gRenderCameraTilePos.y) * 20,
          (tl.x - gRenderCameraTilePos.x) * 20, (tl.y - gRenderCameraTilePos.y) * 20) + rect(-10, -10, 10, 10),
        rct + rect(1, 1, 1, 1) + rect(-10, -10, 10, 10), { ink = 36 })
      --member("layer"..tostring(d)).image:copyPixels(member("pxl").image, rect((tl.x-1)*20, (tl.y-1)*20, tl.x*20, tl.y*20), rect(0,0,1,1))
    end
  end

  if mat == "trash" then
    if gLEProps.matrix[tl.x][tl.y][layer][1] ~= 9 or (not tobool(gDRMatFixes)) then
      for q = 1, 3 do
        local rndList = { 1, 11, 21 }
        local d = rndList[layer] + random(9) - 1
        local gt = random(48)
        gt = rect(50 * (gt - 1), 0, 50 * gt, 50) + rect(1, 1, 1, 1)
        local rct = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) - point(11, 11) +
        point(random(21), random(21))
        rct = rect(rct - point(25, 25), rct + point(25, 25))
        
        local colors = { color(255, 0, 0), color(0, 255, 0), color(0, 0, 255) }
        
        member("layer" .. tostring(d)).image:copyPixels(member("assortedTrash").image, rotate(rct, random(360)), gt, { color = colors[random(3)], ink = 36 })
      end
    end
  end

  -- case mat of
  --   "trash":
  -- end case


  randomSeed = savSeed
end

function me.drawWVTypeTile(mat, tl, layer)
  -- local spelrelaterat = require('spelrelaterat')
  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
  local img = mat .. "WVTile"
  local xPos = (spelrelaterat.afaMvLvlEdit(tl, layer) - 1) * 20
  local lr = (layer - 1) * 10
  for d = 0, 9 do
    rct = rect(xPos, d * 20, xPos + 20, (d + 1) * 20)
    member("layer" .. string(lr + d)).image:copyPixels(member(img).image,
      rect(pos.x - 10, pos.y - 10, pos.x + 10, pos.y + 10), rct + rect(0, 1, 0, 1), { ink = 36 })
  end
end

--function drawWVTagTile(q, c, l, tl, frntImg, effectColorA, effectColorB, colored, sav2)
--  strt = point(q, c)
--  tlt = 7
--  case afaMvLvlEdit(strt, l) of
--    1:
--      tlt = 1
--    2:
--      tlt = 3
--    3:
--      tlt = 2
--    4:
--      tlt = 4
--    5:
--      tlt = 5
--    6:
--      tlt = 6
--  end case
--  tsz = point(1, 1)
--  if (l = 1) then
--    dp = 0
--  elseif (l = 2) then
--    dp = 10
--  else
--    dp = 20
--  end
--  rct = rect(strt * 20, (strt + tsz) * 20) + rect(-20 * tl.bfTiles, -20 * tl.bfTiles, 20 * tl.bfTiles, 20 * tl.bfTiles) + rect(-20, -20, -20, -20)
--  gtRect = rect(0, 0, 20 + (40 * tl.bfTiles), 20 + (40 * tl.bfTiles))
--  rnd = tlt + 7 * (random(tl.rnd) - 1)
--  --frntImg:copyPixels(tileImage, rct, gtRect + rect(gtRect.width * (rnd - 1), 0, gtRect.width * (rnd - 1), 0) + rect(0, 1, 0, 1), {ink=36})
--  d = -1
--  timg = tileImage
--  repeat with ps = 1 to tl.repeatL.count
--    trct = gtRect + rect(gtRect.width * (rnd - 1), gtRect.height * (ps - 1), gtRect.width * (rnd - 1), gtRect.height * (ps - 1)) + rect(1, 1, 1, 1)
--    repeat with ps2 = 1 to tl.repeatL[ps]
--      d = d + 1
--      if (d + dp > 29) then
--        break
--      else
--        tlr = string(d + dp)
--        member("layer" .. tlr).image:copyPixels(timg, rct, trct, {ink=36})
--        if (colored) then
--          if (effectColorA = 0) and (effectColorB = 0) then
--            member("layer" .. tlr .. "dc").image:copyPixels(timg, rct, trct + rect((20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0, (20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0), {ink=36})
--          end
--        end
--        if (effectColorA) then
--          member("gradientA" .. tlr).image:copyPixels(timg, rct, trct + rect((20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0, (20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0), {#ink:39})
--        end
--        if (effectColorB) then
--          member("gradientB" .. tlr).image:copyPixels(timg, rct, trct + rect((20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0, (20 + (40 * tl.bfTiles)) * 7 * tl.rnd, 0), {#ink:39})
--        end
--      end
--    end
--  end
--end

function me.drawRockTypeTile(mat, tl, layer, trBool)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local gtPos = point(0, 0)

  local geoCase = gLEProps.matrix[tl.x][tl.y][layer][1]

  if geoCase == 1 then
    local nbrs = ""
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      --if afaMvLvlEdit(tl+dir, layer)=1 then
      if (random(2) == 1) and (spelrelaterat.afaMvLvlEdit(tl + dir, layer) == 1) then
        nbrs = nbrs .. "1"
      else
        nbrs = nbrs .. string(toint(me.isMyTileSetOpenToThisTile(mat, tl + dir, layer)))
      end
    end

    if nbrs == "0101" then
      gtPos = point(2, 2)
    elseif nbrs == "1010" then
      gtPos = point(4, 2)
    elseif nbrs == "1111" then
      gtPos = point(6, 2)
    elseif nbrs == "0111" then
      gtPos = point(8, 2)
    elseif nbrs == "1101" then
      gtPos = point(10, 2)
    elseif nbrs == "1110" then
      gtPos = point(12, 2)
    elseif nbrs == "1011" then
      gtPos = point(14, 2)
    elseif nbrs == "0011" then
      gtPos = point(16, 2)
    elseif nbrs == "1001" then
      gtPos = point(18, 2)
    elseif nbrs == "1100" then
      gtPos = point(20, 2)
    elseif nbrs == "0110" then
      gtPos = point(22, 2)
    elseif nbrs == "1000" then
      gtPos = point(24, 2)
    elseif nbrs == "0010" then
      gtPos = point(26, 2)
    elseif nbrs == "0100" then
      gtPos = point(28, 2)
    elseif nbrs == "0001" then
      gtPos = point(30, 2)
    elseif nbrs == "0000" then
      gtPos = point(40, 2)
    end
  elseif geoCase == 2 then
    gtPos = point(34, 2)
  elseif geoCase == 3 then
    gtPos = point(32, 2)
  elseif geoCase == 4 then
    gtPos = point(36, 2)
  elseif geoCase == 5 then
    gtPos = point(38, 2)
  elseif geoCase == 6 then
    gtPos = point(42, 2)
  elseif geoCase == 9 then
    gtPos = point(44, 2)
  end

  -- case gLEProps.matrix[tl.x][tl.y][layer][1] of
  --   1:


  --   3:

  --   2:

  --   4:

  --   5:

  --   6:

  --   9:

  -- end case

  local mem
  if mat == "Rocks" then
    mem = "rockTiles"
  end

  -- case mat of
  --   "Rocks":
  -- end case

  local d = (layer - 1) * 10
  local rndList = { 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32 }
  gtPos.y = rndList[random(16)]
  local rct = rect((gtPos.x - 1) * 20, (gtPos.y - 1) * 20, gtPos.x * 20, gtPos.y * 20)
  if tobool(trBool) then
    for rg = 1, 4 do
      member("layer" .. tostring(d + rg)).image:copyPixels(member(mem).image,
        rect((tl.x - 1 - gRenderCameraTilePos.x) * 20, (tl.y - 1 - gRenderCameraTilePos.y) * 20,
          (tl.x - gRenderCameraTilePos.x) * 20, (tl.y - gRenderCameraTilePos.y) * 20) + rect(-10, -10, 10, 10),
        rct + rect(1, 1, 1, 1) + rect(-10, -10, 10, 10), { ink = 36 })
    end
  else
    for rg = 0, 4 do
      member("layer" .. tostring(d + rg)).image:copyPixels(member(mem).image,
        rect((tl.x - 1 - gRenderCameraTilePos.x) * 20, (tl.y - 1 - gRenderCameraTilePos.y) * 20,
          (tl.x - gRenderCameraTilePos.x) * 20, (tl.y - gRenderCameraTilePos.y) * 20) + rect(-10, -10, 10, 10),
        rct + rect(1, 1, 1, 1) + rect(-10, -10, 10, 10), { ink = 36 })
    end
  end
  gtPos.y = rndList[random(16)]
  rct = rect((gtPos.x - 1) * 20, (gtPos.y - 1) * 20, gtPos.x * 20, gtPos.y * 20)
  for rd = 5, 9 do
    member("layer" .. tostring(d + rd)).image:copyPixels(member(mem).image,
      rect((tl.x - 1 - gRenderCameraTilePos.x) * 20, (tl.y - 1 - gRenderCameraTilePos.y) * 20,
        (tl.x - gRenderCameraTilePos.x) * 20, (tl.y - gRenderCameraTilePos.y) * 20) + rect(-10, -10, 10, 10),
      rct + rect(1, 1, 1, 1) + rect(-10, -10, 10, 10), { ink = 36 })
  end
  randomSeed = savSeed
end

function me.drawLargeTrashTypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local distanceToAir = -1
  for dist = 1, 5 do
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
        distanceToAir = dist
        break
      end
    end
    if (distanceToAir ~= -1) then
      break
    end
  end


  if (distanceToAir == -1) then
    distanceToAir = 5
  end

  if (distanceToAir < 5) then
    me.drawPipeTypeTile("trash", tl, layer)
  end


  --  pos =
  local pos

  if (distanceToAir < 3) then
    -- global gTrashPropOptions, gProps

    for q = 1, distanceToAir + random(2) - 1 do
      local dp = spelrelaterat.restrict(((layer - 1) * 10) + random(random(10)) - 1 + random(3), 0, 29)

      pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
      pos = pos + point(-11 + random(21), -11 + random(21))

      if (#gTrashPropOptions ~= 0) then
        local propAddress = gTrashPropOptions[random(#gTrashPropOptions)]
        local prop = gProps[propAddress.x].prps[propAddress.y]

        local rct = rect(pos, pos) + rect(-prop.sz.x * 10, -prop.sz.y * 10, prop.sz.x * 10, prop.sz.y * 10)
        local qd = rotate(rct, random(360))

        gRenderTrashProps:add({ -dp, prop.nm, propAddress, qd, { settings = { renderTime = 0, seed = random(1000) } } })
      end
    end
  end

  if (distanceToAir > 2) then
    local dp = ((layer - 1) * 10)
    pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

    if (random(5) <= distanceToAir) then
      member("layer" .. tostring(dp)).image:copyPixels(member("pxl").image, rect(pos.x - 10, pos.y - 10, pos.x + 10,
        pos.y + 10), rect(0, 0, 1, 1), { color = color(255, 0, 0) })
      local var = random(14)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      frntImg:copyPixels(member("bigJunk").image, rotate(rct, random(360)),
        rect((var - 1) * 60, 0, var * 60, 60) + rect(0, 1, 0, 1), { ink = 36 })
    end

    for q = 1, distanceToAir do
      local dp = ((layer - 1) * 10) + random(10) - 1
      pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
      local var = random(14)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      member("layer" .. tostring(dp)).image:copyPixels(member("bigJunk").image,
        rotate(rct, random(360)), rect((var - 1) * 60, 0, var * 60, 60) + rect(0, 1, 0, 1), { ink = 36 })
    end
  end

  randomSeed = savSeed
end

function me.drawRoughRockTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local imgR = "Not Found"
  local szR = 0
  local intOp = 1

  if mat == "Rough Rock" then
    imgR = "roughRock"
    szR = 60
    intOp = 6
  elseif mat == "Sandy Dirt" then
    szR = 20
    imgR = "sandRR"
    intOp = 2
  end

  -- case mat of
  --   "Rough Rock":
  --   "Sandy Dirt":
  -- end case

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local distanceToAir = -1
  for dist = 1, 5 do
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
        distanceToAir = dist
        break
      end
    end
    if (distanceToAir ~= -1) then
      break
    end
  end

  if (distanceToAir == -1) then
    distanceToAir = 5
  end

  if tobool(gRRSpreadsMore) then
    distanceToAir = distanceToAir + 1
  end

  if (distanceToAir < 5) then
    if mat == "Rough Rock" then
      me.drawRockTypeTile("Rocks", tl, layer, TRUE)
    elseif mat == "Sandy Dirt" then
      me.drawPipeTypeTile("Sandy Dirt", tl, layer)
      distanceToAir = distanceToAir + 1
    end

    -- case mat of
    --   "Rough Rock":
    --   "Sandy Dirt":
    -- end case
  end

  if (distanceToAir > 2) then
    local dp = ((layer - 1) * 10)
    local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

    local rndList = { 1, 1.05, 1.1 }

    if (random(5) <= distanceToAir) then
      member("layer" .. tostring(dp)).image:copyPixels(member("pxl").image, rect(pos.x - 10, pos.y - 10, pos.x + 10,
        pos.y + 10), rect(0, 0, 1, 1), { color = color(255, 0, 0) })
      local var = random(intOp)
      local fat = rndList[random(3)]
      local rct = rect(pos, pos) + rect(-szR * fat, -szR * fat, szR * fat, szR * fat)
      frntImg:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(360)),
        rect((var - 1) * szR * 2, 0, var * szR * 2, szR * 2) + rect(0, 1, 0, 1), { ink = 36 })
    end

    local dp = ((layer - 1) * 10)
    local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
    local var = random(intOp)
    local fat = rndList[random(3)]
    local rct = rect(pos, pos) + rect(-szR * fat, -szR * fat, szR * fat, szR * fat)

    member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(360)),
      rect((var - 1) * szR * 2, 0, var * szR * 2, szR * 2) + rect(0, 1, 0, 1), { ink = 36 })

    for q = 1, distanceToAir do
      local dp = ((layer - 1) * 10) + random(10) - 1
      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
      local var = random(intOp)
      local fat = rndList[random(3)]
      local rct = rect(pos, pos) + rect(-szR * fat, -szR * fat, szR * fat, szR * fat)
      member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(360)),
        rect((var - 1) * szR * 2, 0, var * szR * 2, szR * 2) + rect(0, 1, 0, 1), { ink = 36 })
    end

    if mat == "Sandy Dirt" and random(2) == 1 then
      local dp = ((layer - 1) * 10)
      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

      local rndList = { 1, 1.05, 1.1 }

      if (random(5) <= distanceToAir) then
        member("layer" .. tostring(dp)).image:copyPixels(member("pxl").image, rect(pos.x - 10, pos.y - 10, pos.x + 10,
          pos.y + 10), rect(0, 0, 1, 1), { color = color(255, 0, 0) })
        local var = random(intOp)
        local fat = rndList[random(3)]
        local rct = rect(pos, pos) + rect(-szR * fat, -szR * fat, szR * fat, szR * fat)
        frntImg:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(360)),
          rect((var - 1) * szR * 2, 0, var * szR * 2, szR * 2) + rect(0, 1, 0, 1), { ink = 36 })
      end

      for q = 1, distanceToAir do
        local dp = ((layer - 1) * 10) + random(10) - 1
        local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
        local var = random(intOp)
        local fat = rndList[random(3)]
        local rct = rect(pos, pos) + rect(-szR * fat, -szR * fat, szR * fat, szR * fat)
        member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(360)),
          rect((var - 1) * szR * 2, 0, var * szR * 2, szR * 2) + rect(0, 1, 0, 1), { ink = 36 })
      end
    end
  end

  randomSeed = savSeed
end

function me.drawSandyTypeTile(mat, tl, layer, frntImg, vars, szList, hAddList, slopeSz)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)
  local imgR = mat .. "STile"
  local block = spelrelaterat.afaMvLvlEdit(tl, layer)

  if (block == 1) then
    distanceToAir = -1

    for dist = 1, 5 do
      for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
        if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
          distanceToAir = dist
          break
        end
      end
      if (distanceToAir ~= -1) then
        break
      end
    end

    if (distanceToAir == -1) then
      distanceToAir = 5
    end

    local fatFac = 1
    if (distanceToAir < 5) then
      fatFac = 2
    elseif (distanceToAir < 4) then
      fatFac = 3
    elseif (distanceToAir < 3) then
      fatFac = 4
    elseif (distanceToAir < 2) then
      fatFac = 5
    end

    for rep = 1, fatFac + 4 do
      local dp = ((layer - 1) * 10)
      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

      if (random(5) <= distanceToAir) then
        local var = random(vars)
        local fatSide = szList[fatFac]
        local fatAdd = hAddList[fatFac]
        local halfSide = fatSide / 2
        local rct = rect(pos, pos) + rect(-halfSide, -halfSide, halfSide, halfSide)
        frntImg:copyPixels(member(imgR).image, spelrelaterat.rotateToQuad(rct, random(45) - random(45)),
          rect(fatSide * (var - 1), fatAdd, fatSide * var, fatAdd + fatSide) + rect(0, 1, 0, 1), { ink = 36 })
      end

      for q = 1, distanceToAir do
        local dp = ((layer - 1) * 10) + random(10) - 1
        local fatD = fatFac * 3
        local fatDD = fatD * 2 - 1
        local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) +
        point(-fatD + random(fatDD), -fatD + random(fatDD))
        local var = random(vars)
        local fatSide = szList[fatFac]
        local fatAdd = hAddList[fatFac]
        local halfSide = fatSide / 2
        local rct = rect(pos, pos) + rect(-halfSide, -halfSide, halfSide, halfSide)
        member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image,
          spelrelaterat.rotateToQuad(rct, random(45) - random(45)),
          rect(fatSide * (var - 1), fatAdd, fatSide * var, fatAdd + fatSide) + rect(0, 1, 0, 1), { ink = 36 })
      end
    end
  elseif (block == 6) then
    lr = (layer - 1) * 10
    for rep = 1, szList + 2 do
      for dp = lr + 5, lr + 9 do
        local ptAdd = point(random(8) - random(8), -10)
        local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-2 + random(3), -2 + random(3)) +
        ptAdd
        local var = random(vars)
        local rn = random(2)
        local rndList1 = { #szList, #szList - 1 }
        local rndList2 = { #hAddList, #hAddList - 1 }
        local fatSide = szList[rndList1[rn]]
        local fatAdd = hAddList[rndList2[rn]]
        local halfSide = fatSide / 2
        local rct = rect(pos, pos) + rect(-halfSide, -halfSide, halfSide, halfSide)
        member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image,
          spelrelaterat.rotateToQuad(rct, random(10) - random(10)),
          rect(fatSide * (var - 1), fatAdd, fatSide * var, fatAdd + fatSide) + rect(0, 1, 0, 1), { ink = 36 })
      end
    end
  elseif (block == 2 or 3 or 4 or 5) then
    local lr = (layer - 1) * 10

    for dp = lr, lr + 9 do
      local ptAdd = point(0, 0)

      if block == 2 then
        ptAdd = point(-4, 4)
      elseif block == 3 then
        ptAdd = point(4, 4)
      elseif block == 4 then
        ptAdd = point(-4, -4)
      elseif block == 5 then
        ptAdd = point(4, -4)
      end

      -- case block of
      --   2:
      --   3:
      --   4:
      --   5:
      -- end case

      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-2 + random(3), -2 + random(3)) +
      ptAdd
      local var = block - 1
      local fatAdd = hAddList[#hAddList] + szList[#szList]
      local halfSide = slopeSz / 2
      local rct = rect(pos, pos) + rect(-halfSide, -halfSide, halfSide, halfSide)
      member("layer" .. tostring(dp)).image:copyPixels(member(imgR).image,
        spelrelaterat.rotateToQuad(rct, random(10) - random(10)),
        rect(slopeSz * (var - 1), fatAdd, slopeSz * var, fatAdd + slopeSz) + rect(0, 1, 0, 1), { ink = 36 })
    end
  end
  randomSeed = savSeed
end

function me.drawMegaTrashTypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local distanceToAir = -1
  for dist = 1, 5 do
    for _, dir in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
      if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
        distanceToAir = dist
        break
      end
    end
    if (distanceToAir ~= -1) then
      break
    end
  end

  if (distanceToAir == -1) then
    distanceToAir = 5
  end

  if (distanceToAir < 5) then
    me.drawPipeTypeTile("trash", tl, layer)
  end

  if (distanceToAir < 3) then
    -- global gMegaTrash, gProps
    for q = 1, distanceToAir + random(2) - 1 do
      local dp = spelrelaterat.restrict(((layer - 1) * 10) + random(random(10)) - 1 + random(3), 0, 29)
      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
      local pos = pos + point(-11 + random(21), -11 + random(21))

      if (#gMegaTrash ~= 0) then
        local propAddress = gMegaTrash[random(#gMegaTrash)]
        local prop = gProps[propAddress.x].prps[propAddress.y]
        local rct = rect(pos, pos) + rect(-prop.sz.x * 10, -prop.sz.y * 10, prop.sz.x * 10, prop.sz.y * 10)
        gRenderTrashProps:add({ -dp, prop.nm, propAddress, rotateToQuad(rct, random(360)), { settings = { renderTime = 0, seed = random(1000) } } })
      end
    end
  end

  if (distanceToAir > 2) then
    local dp = ((layer - 1) * 10)
    local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

    if (random(5) <= distanceToAir) then
      member("layer" .. tostring(dp)).image:copyPixels(member("pxl").image, rect(pos.x - 10, pos.y - 10, pos.x + 10,
        pos.y + 10), rect(0, 0, 1, 1), { color = color(255, 0, 0) })
      local var = random(14)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      frntImg:copyPixels(member("bigJunk").image, spelrelaterat.rotateToQuad(rct, random(360)),
        rect((var - 1) * 60, 0, var * 60, 60) + rect(0, 1, 0, 1), { ink = 36 })
    end

    for q = 1, distanceToAir do
      local dp = ((layer - 1) * 10) + random(10) - 1
      local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
      local var = random(14)
      local rct = rect(pos, pos) + rect(-30, -30, 30, 30)
      member("layer" .. tostring(dp)).image:copyPixels(member("bigJunk").image,
        spelrelaterat.rotateToQuad(rct, random(360)), rect((var - 1) * 60, 0, var * 60, 60) + rect(0, 1, 0, 1), { ink = 36 })
    end
  end

  randomSeed = savSeed
end

function me.drawDirtTypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')
  -- local fiffigt = require('fiffigt')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local dp = ((layer - 1) * 10)
  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

  local optOut = false
  if (layer > 1) then
    optOut = (spelrelaterat.afaMvLvlEdit(tl, layer - 1) == 1)
  end

  if (optOut) then
    member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("pxl").image,
      rect(pos, pos) + rect(-14, -14, 14, 14), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
    local var = random(4)
    local rct = rect(pos, pos) + rect(-18, -18, 18, 18)
    member("layer" .. tostring(dp)).image:copyPixels(member("rubbleGraf" .. var).image,
      spelrelaterat.rotateToQuad(rct, random(360)), member("rubbleGraf" .. var).image.rect,
      { ink = 36, color = color(0, 255, 0) })
  else
    local distanceToAir = 6
    local ext = false
    for dist = 1, 5 do
      for _, dir in ipairs({ point(-1, 0), point(-1, -1), point(0, -1), point(1, -1), point(1, 0), point(1, 1), point(0, 1), point(-1, 1) }) do
        if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
          distanceToAir = dist
          ext = true
          break
        end
      end
      if (ext) then
        break
      end
    end

    distanceToAir = distanceToAir + -2 + random(3)

    if (distanceToAir >= 5) then
      member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("pxl").image,
        rect(pos, pos) + rect(-14, -14, 14, 14), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
      local var = random(4)
      local rct = rect(pos, pos) + rect(-18, -18, 18, 18)
      member("layer" .. tostring(dp)).image:copyPixels(member("rubbleGraf" .. var).image,
        spelrelaterat.rotateToQuad(rct, random(360)), member("rubbleGraf" .. var).image.rect,
        { ink = 36, color = color(0, 255, 0) })
    else
      local amnt = fiffigt.lerp(distanceToAir, 3, 0.5) * 15

      if (layer > 1) then
        amnt = distanceToAir * 10
      end

      for q = 1, amnt do
        local dp = ((layer - 1) * 10) + random(10) - 1
        local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) + point(-11 + random(21), -11 + random(21))
        local var = random(4)
        me.drawDirtClot(pos, dp, var, layer, distanceToAir)
      end

      if (layer < 3) then
        for dist = 1, 3 do
          for _, dir in ipairs({ point(-1, 0), point(-1, -1), point(0, -1), point(1, -1), point(1, 0), point(1, 1), point(0, 1), point(-1, 1) }) do
            if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer + 1) == 1) and (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) then
              for q = 1, 10 do
                local dpAdd
                if (layer == 1) then
                  dpAdd = 6 + random(4)
                else
                  dpAdd = 2 + random(8)
                end
                local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos) +
                point(-11 + random(21), -11 + random(21)) + dir * dist * dist * dpAdd * random(85) * 0.01
                local var = random(4)
                me.drawDirtClot(pos, ((layer - 1) * 10) + dpAdd, var, layer, distanceToAir)
              end
            end
          end
        end
      end
    end
  end

  randomSeed = savSeed
end

function me.drawDirtClot(pos, dp, var, layer, distanceToAir)
  -- local spelrelaterat = require('spelrelaterat')

  local szAdd = (random(distanceToAir + 1) - 1)

  for d = 0, 2 do
    local sz = 5 + szAdd + d * 2
    local pstDp = spelrelaterat.restrict(dp - 1 + d, 0, 29)
    local rct = rect(pos, pos) + rect(-sz, -sz, sz, sz)
    member("layer" .. tostring(pstDp)).image:copyPixels(member("rubbleGraf" .. var).image,
      spelrelaterat.rotateToQuad(rct, random(360)), member("rubbleGraf" .. var).image.rect,
      { ink = 36, color = color(0, 255, 0) })
  end

  -- pos2 = giveGridPos(pos + point(-10, -10))
  if ((random(6) > distanceToAir) and (random(3) == 1)) or ((spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos + point(-10, -10)) + gRenderCameraTilePos, layer) ~= 1) and ((spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos + point(10, 10)) + gRenderCameraTilePos, layer) == 1)) or (layer == 2)) then
    for d = 0, 2 do
      local sz = 2 + (szAdd * 0.5) + d * 2
      local pstDp = spelrelaterat.restrict(dp - 1 + d, 0, 29)
      local rct = rect(pos, pos) + rect(-sz, -sz, sz, sz) +
      rect(point(-4, -4) + point(-2 * d, -2 * d), point(-4, -4) + point(-2 * d, -2 * d))
      member("layer" .. tostring(pstDp)).image:copyPixels(member("rubbleGraf" .. var).image,
        spelrelaterat.rotateToQuad(rct, random(360)), member("rubbleGraf" .. var).image.rect,
        { ink = 36, color = color(0, 0, 255) })
    end
  end

  if ((random(6) > distanceToAir) and (random(3) == 1)) or ((spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos + point(10, 10)) + gRenderCameraTilePos, layer) ~= 1) and ((spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos + point(-10, -10)) + gRenderCameraTilePos, layer) == 1)) or (layer == 2)) then
    for d = 0, 2 do
      local sz = 2 + (szAdd * 0.5) + d * 2
      local pstDp = spelrelaterat.restrict(dp - 1 + d, 0, 29)
      local rct = rect(pos, pos) + rect(-sz, -sz, sz, sz) + rect(point(4, 4) + point(2 * d, 2 * d),
        point(4, 4) + point(2 * d, 2 * d))
      member("layer" .. tostring(pstDp)).image:copyPixels(member("rubbleGraf" .. var).image,
        spelrelaterat.rotateToQuad(rct, random(360)), member("rubbleGraf" .. var).image.rect,
        { ink = 36, color = color(255, 0, 0) })
    end
  end
end

function me.drawCeramicTypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops, gEEprops, gAnyDecals

  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local chaos = 0
  local doColor = false

  for q = 1, #gEEprops.effects do
    if (gEEprops.effects[q].nm == "Ceramic Chaos") then
      local optCase = gEEprops.effects[q].options[3][3]

      local dmin
      local dmax

      if optCase == "1" then
        dmin = 1
        dmax = 1
      elseif optCase == "2" then
        dmin = 2
        dmax = 2
      elseif optCase == "3" then
        dmin = 3
        dmax = 3
      elseif optCase == "1:st and 2:nd" then
        dmin = 1
        dmax = 2
      elseif optCase == "2:st and 3:nd" then
        dmin = 2
        dmax = 3
      else
        dmin = 1
        dmax = 3
      end

      -- case gEEprops.effects[q].options[3][3] of--["All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd"]
      --   "1":
      --   "2":
      --   "3":
      --   "1:st and 2:nd":
      --   "2:nd and 3:rd":
      --   otherwise:
      -- end case
      if (layer >= dmin) and (layer <= dmax) then
        if (gEEprops.effects[q].mtrx[tl.x][tl.y] > chaos) then
          chaos = gEEprops.effects[q].mtrx[tl.x][tl.y]
        end
      end
      if (gEEprops.effects[q].Options[2][3] == "Colored") then
        doColor = true
      end
    end
  end

  if (doColor) then
    gAnyDecals = true
  end

  chaos = chaos * 0.01

  local dp = ((layer - 1) * 10)
  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
  local clr = color(239, 234, 224)


  local lft = 0
  local rght = 0
  local tp = 0
  local bttm = 0

  if (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 1) and (not tobool(gDRMatFixes) or ((spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 6))) then
    lft = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 1) and (not tobool(gDRMatFixes) or ((spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 6))) then
    rght = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 1) and (not tobool(gDRMatFixes) or ((spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 6))) then
    tp = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 1) and (not tobool(gDRMatFixes) or ((spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 6))) then
    bttm = 1
  end

  local h = spelrelaterat.afaMvLvlEdit(tl, layer)

  local h2
  if h == 1 then
    h2 = ""
  elseif h == 2 then
    h2 = "NE"
  elseif h == 3 then
    h2 = "NW"
  elseif h == 4 then
    h2 = "SE"
  elseif h == 5 then
    h2 = "SW"
  end

  -- case h of
  --   1:
  --   2:
  --   3:
  --   4:
  --   5:
  -- end case

  if (h == 1) or (h == 2) or (h == 3) or (h == 4) or (h == 5) then
    if (h == 1) then
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), rect(0, 0, 1, 1),
          { ink = 36, color = color(255 * (1 - doColor), 255 * doColor, 0) })
      end
    else
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCP" .. h2).image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), member("ceramicTileSilh" .. h2).image.rect,
          { ink = 36, color = color(255 * (1 - doColor), 255 * doColor, 0) })
      end
    end
    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocket" .. h2).image,
      rect(pos, pos) + rect(-8, -8, 8, 8), member("ceramicTileSocket" .. h2).image.rect,
      { ink = 36, color = color(255 * doColor, 255 * (1 - doColor), 0) })

    if (h == 1) or (h == 2) or (h == 4) then
      if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })

          if (doColor) then
            member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
              rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 36, color = clr })
          end
        end
      end
    end

    if (h == 1) or (h == 3) or (h == 5) then
      if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
          if (doColor) then
            member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
              rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 36, color = clr })
          end
        end
      end
    end

    if (h == 1) or (h == 4) or (h == 5) then
      if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
          if (doColor) then
            member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
              rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = clr })
          end
        end
      end
    end

    if (h == 1) or (h == 2) or (h == 3) then
      if tobool(bttm) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, -8, 11), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
          if (doColor) then
            member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
              rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 36, color = clr })
          end
        end
      end
    end


    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      local f
      if (random(100) < chaos * 100) then
        f = toint(random(1000 + 4000 * chaos) * chaos)
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end

      if (abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTile" .. h2).image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
          member("ceramicTile" .. h2).image.rect, { ink = 36 })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10)) .. "dc").image:copyPixels(member("ceramicTileSilh" .. h2).image,
            spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
            member("ceramicTileSilh" .. h2).image.rect, { ink = 36, color = clr })
        end
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTile" .. h2).image,
          rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTile" .. h2).image.rect, { ink = 36 })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10)) .. "dc").image:copyPixels(member("ceramicTileSilh" .. h2).image,
            rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTileSilh" .. h2).image.rect, { ink = 36, color = clr })
        end
      end
    end

    randomSeed = savSeed
  elseif (h == 6) then
    for q = 1, 9 do
      member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCPFL").image,
        rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, (10 - bttm) / 2), member("ceramicTileSilhFL").image.rect,
        { ink = 36, color = color(255 * (1 - doColor), 255 * doColor, 0) })
    end
    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocketFL").image,
      rect(pos, pos) + rect(-8, -8, 8, 8 / 2), member("ceramicTileSocketFL").image.rect,
      { ink = 36, color = color(255 * doColor, 255 * (1 - doColor), 0) })


    if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = clr })
        end
      end
    end

    if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = clr })
        end
      end
    end

    if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 0) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 0, 255) })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10) + q) .. "dc").image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = clr })
        end
      end
    end



    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      local f
      if (random(100) < chaos * 100) then
        f = toint(random(1000 + 4000 * chaos) * chaos)
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end

      if (abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileFL").image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
          member("ceramicTileFL").image.rect, { ink = 36 })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10)) .. "dc").image:copyPixels(member("ceramicTileSilhFL").image,
            spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
            member("ceramicTileSilhFL").image.rect, { ink = 36, color = clr })
        end
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileFL").image,
          rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileFL").image.rect, { ink = 36 })
        if (doColor) then
          member("layer" .. tostring(((layer - 1) * 10)) .. "dc").image:copyPixels(member("ceramicTileSilhFL").image,
            rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileSilhFL").image.rect, { ink = 36, color = clr })
        end
      end
    end

    randomSeed = savSeed
  end
end

function me.drawCeramicATypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops, gEEprops, gAnyDecals

  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local chaos = 0

  for q = 1, #gEEprops.effects do
    if (gEEprops.effects[q].nm == "Ceramic Chaos") then
      local optCase = gEEprops.effects[q].options[3][3]

      local dmin
      local dmax
      if optCase == "1" then
        dmin = 1
        dmax = 1
      elseif optCase == "2" then
        dmin = 2
        dmax = 2
      elseif optCase == "3" then
        dmin = 3
        dmax = 3
      elseif optCase == "1:st and 2:nd" then
        dmin = 1
        dmax = 2
      elseif optCase == "2:nd and 3:rd" then
        dmin = 2
        dmax = 3
      else
        dmin = 1
        dmax = 3
      end

      -- case gEEprops.effects[q].options[3][3] of--["All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd"]
      --   "1":
      --   "2":
      --   "3":
      --   "1:st and 2:nd":
      --   "2:nd and 3:rd":
      --   otherwise:
      -- end case
      if (layer >= dmin) and (layer <= dmax) then
        if (gEEprops.effects[q].mtrx[tl.x][tl.y] > chaos) then
          chaos = gEEprops.effects[q].mtrx[tl.x][tl.y]
        end
      end
    end
  end

  --gAnyDecals = true

  chaos = chaos * 0.01

  local dp = ((layer - 1) * 10)
  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
  local clr = color(239, 234, 224)


  local lft = 0
  local rght = 0
  local tp = 0
  local bttm = 0

  if (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 6) then
    lft = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 6) then
    rght = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 6) then
    tp = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 6) then
    bttm = 1
  end

  local h = spelrelaterat.afaMvLvlEdit(tl, layer)
  local h2

  if h == 1 then
    h2 = ''
  elseif h == 2 then
    h2 = "NE"
  elseif h == 3 then
    h2 = "NW"
  elseif h == 4 then
    h2 = "SE"
  elseif h == 5 then
    h2 = "SW"
  end

  -- case h of
  --   1:
  --   2:
  --   3:
  --   4:
  --   5:
  -- end case

  if (h == 1) or (h == 2) or (h == 3) or (h == 4) or (h == 5) then
    if (h == 1) then
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), rect(0, 0, 1, 1),
          { ink = 36, color = color(0, 255, 0) })
      end
    else
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCP" .. h2).image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), member("ceramicTileSilh" .. h2).image.rect,
          { ink = 36, color = color(0, 255, 0) })
      end
    end

    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocket" .. h2).image,
      rect(pos, pos) + rect(-8, -8, 8, 8), member("ceramicTileSocket" .. h2).image.rect, { ink = 36, color = color(255, 0,
      0) })

    if (h == 1) or (h == 2) or (h == 4) then
      if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 3) or (h == 5) then
      if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 4) or (h == 5) then
      if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 2) or (h == 3) then
      if tobool(bttm) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, -8, 11), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
          member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end


    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    local f
    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      if (random(100) < chaos * 100) then
        f = toint(random(1000 + 4000 * chaos) * chaos)
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end
      if (math.abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh" .. h2).image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
          member("ceramicTileSilh" .. h2).image.rect, { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2" .. h2).image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
          member("ceramicTileSilh2" .. h2).image.rect, { ink = 39 })
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh" .. h2).image,
          rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTileSilh" .. h2).image.rect,
          { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2" .. h2).image,
          rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTileSilh2" .. h2).image.rect, { ink = 39 })
      end
    end

    randomSeed = savSeed
  elseif (h == 6) then
    for q = 1, 9 do
      member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCPFL").image,
        rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, (10 - bttm) / 2), member("ceramicTileSilhFL").image.rect,
        { ink = 36, color = color(0, 255, 0) })
    end
    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocketFL").image,
      rect(pos, pos) + rect(-8, -8, 8, 8 / 2), member("ceramicTileSocketFL").image.rect, { ink = 36, color = color(255, 0,
      0) })


    if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 39 })
      end
    end

    if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 39 })
      end
    end

    if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 39 })
      end
    end

    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    local f
    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      if (random(100) < chaos * 100) then
        f = toint(random(1000 + 4000 * chaos) * chaos)
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end
      if (math.abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilhFL").image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
          member("ceramicTileSilhFL").image.rect, { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2FL").image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
          member("ceramicTileSilh2FL").image.rect, { ink = 39 })
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilhFL").image,
          rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileSilhFL").image.rect,
          { ink = 36, color = color(255, 0, 255) })
        member("gradientA" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2FL").image,
          rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileSilh2FL").image.rect, { ink = 39 })
      end
    end

    randomSeed = savSeed
  end
end

function me.drawCeramicBTypeTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops, gEEprops, gAnyDecals

  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local chaos = 0

  for q = 1, #gEEprops.effects do
    if (gEEprops.effects[q].nm == "Ceramic Chaos") then
      local optCase = gEEprops.effects[q].options[3][3]

      local dmin
      local dmax

      if optCase == "1" then
        dmin = 1
        dmax = 1
      elseif optCase == "2" then
        dmin = 2
        dmax = 2
      elseif optCase == "3" then
        dmin = 3
        dmax = 3
      elseif optCase == "1:st and 2:nd" then
        dmin = 1
        dmax = 2
      elseif optCase == "2:nd and 3:rd" then
        dmin = 2
        dmax = 3
      else
        dmin = 1
        dmax = 3
      end

      -- case gEEprops.effects[q].options[3][3] of--["All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd"]
      --   "1":
      --   "2":
      --   "3":
      --   "1:st and 2:nd":
      --   "2:nd and 3:rd":
      --   otherwise:
      -- end case
      if (layer >= dmin) and (layer <= dmax) then
        if (gEEprops.effects[q].mtrx[tl.x][tl.y] > chaos) then
          chaos = gEEprops.effects[q].mtrx[tl.x][tl.y]
        end
      end
    end
  end

  --gAnyDecals = true

  chaos = chaos * 0.01

  local dp = ((layer - 1) * 10)
  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
  local clr = color(239, 234, 224)


  local lft = 0
  local rght = 0
  local tp = 0
  local bttm = 0
  if (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 6) then
    lft = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 6) then
    rght = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 6) then
    tp = 1
  end
  if (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 2) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 3) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 4) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 5) and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 6) then
    bttm = 1
  end

  local h = spelrelaterat.afaMvLvlEdit(tl, layer)
  local h2

  if h == 1 then
    h2 = ""
  elseif h == 2 then
    h2 = "NE"
  elseif h == 3 then
    h2 = "NW"
  elseif h == 4 then
    h2 = "SE"
  elseif h == 5 then
    h2 = "SW"
  end

  -- case h of
  --   1:
  --   2:
  --   3:
  --   4:
  --   5:
  -- end case

  if (h == 1) or (h == 2) or (h == 3) or (h == 4) or (h == 5) then
    if (h == 1) then
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), rect(0, 0, 1, 1),
          { ink = 36, color = color(0, 255, 0) })
      end
    else
      for q = 1, 9 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCP" .. h2).image,
          rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, 10 - bttm), member("ceramicTileSilh" .. h2).image.rect,
          { ink = 36, color = color(0, 255, 0) })
      end
    end
    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocket" .. h2).image,
      rect(pos, pos) + rect(-8, -8, 8, 8), member("ceramicTileSocket" .. h2).image.rect, { ink = 36, color = color(255, 0,
      0) })

    if (h == 1) or (h == 2) or (h == 4) then
      if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-11, -9, -9, 9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 3) or (h == 5) then
      if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(9, -9, 11, 9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 4) or (h == 5) then
      if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end

    if (h == 1) or (h == 2) or (h == 3) then
      if tobool(bttm) and (random(120) > chaos * chaos * chaos * 100) then
        for q = 2, 8 do
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, -8, 11), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
          member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
            rect(pos, pos) + rect(-9, 9, 9, 11), rect(0, 0, 1, 1), { ink = 39 })
        end
      end
    end


    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    local f
    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      if (random(100) < chaos * 100) then
        f = (random(1000 + 4000 * chaos) * chaos).integer
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end

      if (abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh" .. h2).image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
          member("ceramicTileSilh" .. h2).image.rect, { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2" .. h2).image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9), -90.05122 + f * 0.01),
          member("ceramicTileSilh2" .. h2).image.rect, { ink = 39 })
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh" .. h2).image,
          rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTileSilh" .. h2).image.rect,
          { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2" .. h2).image,
          rect(pos, pos) + rect(-9, -9, 9, 9), member("ceramicTileSilh2" .. h2).image.rect, { ink = 39 })
      end
    end

    randomSeed = savSeed
  elseif (h == 6) then
    for q = 1, 9 do
      member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("ceramicTileSilhCPFL").image,
        rect(pos, pos) + rect(-10 + lft, -10 + tp, 10 - rght, (10 - bttm) / 2), member("ceramicTileSilhFL").image.rect,
        { ink = 36, color = color(0, 255, 0) })
    end
    member("layer" .. tostring(((layer - 1) * 10) + 1)).image:copyPixels(member("ceramicTileSocketFL").image,
      rect(pos, pos) + rect(-8, -8, 8, 8 / 2), member("ceramicTileSocketFL").image.rect, { ink = 36, color = color(255, 0,
      0) })


    if tobool(lft) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-11, -9, -9, 9 / 2), rect(0, 0, 1, 1), { ink = 39 })
      end
    end

    if tobool(rght) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, -8), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(9, -9, 11, 9 / 2), rect(0, 0, 1, 1), { ink = 39 })
      end
    end

    if tobool(tp) and (random(120) > chaos * chaos * chaos * 100) then
      for q = 2, 8 do
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("layer" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, -8, -9), rect(0, 0, 1, 1), { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10) + q)).image:copyPixels(member("pxl").image,
          rect(pos, pos) + rect(-9, -11, 9, -9), rect(0, 0, 1, 1), { ink = 39 })
      end
    end



    pos = pos + point(-7 + random(13), -7 + random(13)) * chaos * chaos * chaos * random(100) * 0.01

    local f
    if (chaos == 0) or (random(300 - 298 * chaos * chaos * chaos) > 1) then
      if (random(100) < chaos * 100) then
        f = toint(random(1000 + 4000 * chaos) * chaos)
        for a = 1, (1.0 - chaos) * 4 do
          f = random(f)
          if (f == 1) then
            break
          end
        end
      else
        f = 1
      end
      if (abs(f) > 1) then
        f = f - 1
        if (random(2) == 1) then
          f = f * -1
        end
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilhFL").image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
          member("ceramicTileSilhFL").image.rect, { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2FL").image,
          spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-9, -9, 9, 9 / 2), -90.05122 + f * 0.01),
          member("ceramicTileSilh2FL").image.rect, { ink = 39 })
      else
        member("layer" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilhFL").image,
          rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileSilhFL").image.rect,
          { ink = 36, color = color(0, 255, 255) })
        member("gradientB" .. tostring(((layer - 1) * 10))).image:copyPixels(member("ceramicTileSilh2FL").image,
          rect(pos, pos) + rect(-9, -9, 9, 9 / 2), member("ceramicTileSilh2FL").image.rect, { ink = 39 })
      end
    end

    randomSeed = savSeed
  end
end

function me.drawDPTTile(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)
  local pstLr = me.DPStartLayerOfTile(tl, layer)
  --For Dry's mat
  if (mat == "Shallow Circuits") or (mat == "Shallow Dense Pipes") then
    pstLr = layer * 10 - 10
  end

  if (spelrelaterat.afaMvLvlEdit(tl, layer) > 1) then
    local a = spelrelaterat.afaMvLvlEdit(tl, layer)
    local var = 16

    if a == 2 then
      var = 20
    elseif a == 3 then
      var = 19
    elseif a == 4 then
      var = 17
    elseif a == 5 then
      var = 18
    elseif a == 6 then
      if tobool(gDRMatFixes) then
        var = 21
      end
    elseif a == 9 then
      if tobool(gDRMatFixes) then
        var = 22
      end
    end

    -- case a of
    --   2: var = 20
    --   3: var = 19
    --   4: var = 17
    --   5: var = 18
    --   6:
    --   9:
    -- end case

    for q = pstLr, (layer * 10) - 1 do
      if (mat == "Shallow Circuits") then
        member("layer" .. q).image:copyPixels(member("circuitsImage").image, rect(pos - point(20, 20), pos + point(20, 20)),
          rect((var - 1) * 40, 1, var * 40, 41), { ink = 36 })
      elseif (mat == "Shallow Dense Pipes") then
        member("layer" .. q).image:copyPixels(member("dense PipesImage").image, rect(pos - point(20, 20),
          pos + point(20, 20)), rect((var - 1) * 40, 1, var * 40, 41), { ink = 36 })
      else
        member("layer" .. q).image:copyPixels(member(mat .. "image").image, rect(pos - point(20, 20), pos + point(20, 20)),
          rect((var - 1) * 40, 1, var * 40, 41), { ink = 36 })
      end
    end
  else
    lst = { "0000", "1111", "0101", "1010", "0001", "1000", "0100", "0010", "1001", "1100", "0110", "0011", "1011",
      "1101", "1110", "0111" }

    local lftDp = me.DPStartLayerOfTile(tl + point(-1, 0), layer)
    local rghtDp = me.DPStartLayerOfTile(tl + point(1, 0), layer)
    local tpDp = me.DPStartLayerOfTile(tl + point(0, -1), layer)
    local bttmDp = me.DPStartLayerOfTile(tl + point(0, 1), layer)

    for q = pstLr, (layer * 10) - 1 do
      local lft = spelrelaterat.solidAfaMv(tl + point(-1, 0), layer) * me.DPCircuitConnection(tl + point(-1, 0), q).x *
      (lftDp <= q)
      local rght = spelrelaterat.solidAfaMv(tl + point(1, 0), layer) * me.DPCircuitConnection(tl, q).x * (rghtDp <= q)
      local tp = spelrelaterat.solidAfaMv(tl + point(0, -1), layer) * me.DPCircuitConnection(tl + point(0, -1), q).y *
      (tpDp <= q)
      local bttm = spelrelaterat.solidAfaMv(tl + point(0, 1), layer) * me.DPCircuitConnection(tl, q).y * (bttmDp <= q)
      -- For Dry's mat
      if (mat == "Shallow Circuits") or (mat == "Shallow Dense Pipes") then
        lft = spelrelaterat.solidAfaMv(tl + point(-1, 0), layer) * me.DPCircuitConnection(tl + point(-1, 0), q).x
        rght = spelrelaterat.solidAfaMv(tl + point(1, 0), layer) * me.DPCircuitConnection(tl, q).x
        tp = spelrelaterat.solidAfaMv(tl + point(0, -1), layer) * me.DPCircuitConnection(tl + point(0, -1), q).y
        bttm = spelrelaterat.solidAfaMv(tl + point(0, 1), layer) * me.DPCircuitConnection(tl, q).y
      end

      if (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) > 1 and (not tobool(gDRMatFixes) or (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 9))) then
        lft = 1
      end
      if (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) > 1 and (not tobool(gDRMatFixes) or (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 9))) then
        rght = 1
      end
      if (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) > 1 and (not tobool(gDRMatFixes) or (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 9))) then
        tp = 1
      end
      if (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) > 1 and (not tobool(gDRMatFixes) or (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 9))) then
        bttm = 1
      end


      local var = getPos(lst, (tostring(lft) .. tostring(tp) .. tostring(rght) .. tostring(bttm)))
      local rand = 1
      if (mat == "Circuits") or (mat == "Shallow Circuits") then
        rand = random(5)
      end

      if (mat == "Shallow Circuits") then
        member("layer" .. q).image:copyPixels(member("circuitsImage").image, rect(pos - point(20, 20), pos + point(20, 20)),
          rect((var - 1) * 40, 1 + (rand - 1) * 40, var * 40, 1 + rand * 40), { ink = 36 })
      elseif (mat == "Shallow Dense Pipes") then
        member("layer" .. q).image:copyPixels(member("dense PipesImage").image, rect(pos - point(20, 20),
          pos + point(20, 20)), rect((var - 1) * 40, 1 + (rand - 1) * 40, var * 40, 1 + rand * 40), { ink = 36 })
      else
        member("layer" .. q).image:copyPixels(member(mat .. "image").image, rect(pos - point(20, 20), pos + point(20, 20)),
          rect((var - 1) * 40, 1 + (rand - 1) * 40, var * 40, 1 + rand * 40), { ink = 36 })
      end
    end
  end

  randomSeed = savSeed
end

function me.drawRandomPipesMat(mat, tl, layer, frntImg)
  -- local spelrelaterat = require('spelrelaterat')

  local savSeed = randomSeed
  -- global gLOprops
  randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

  local pos = spelrelaterat.giveMiddleOfTile(tl - gRenderCameraTilePos)

  if (spelrelaterat.afaMvLvlEdit(tl, layer) > 1) then
    local a = spelrelaterat.afaMvLvlEdit(tl, layer)
    local var = 16

    if a == 2 then
      var = 20
    elseif a == 3 then
      var = 19
    elseif a == 4 then
      var = 17
    elseif a == 5 then
      var = 18
    elseif a == 6 then
      local rndList = { 21, 25 }
      var = rndList[random(2)]
    elseif a == 9 then
      var = 22
    end

    -- case a of
    --   2: var = 20
    --   3: var = 19
    --   4: var = 17
    --   5: var = 18
    --   6: var = [21, 25][random(2)]
    --   9: var = 22
    -- end case

    local q = (layer * 10) - 10

    if a == 6 then
      for ld = 0, 9 do
        member("layer" .. string(q + ld)).image:copyPixels(member(mat .. "Image2").image,
          rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * ld, var * 20, 20 * (ld + 1)),
          { ink = 36 })
      end
    else
      for ld = 0, 2 do
        member("layer" .. string(q + ld)).image:copyPixels(member(mat .. "Image2").image,
          rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * ld, var * 20, 20 * (ld + 1)),
          { ink = 36 })
      end
      for tf = 3, 6 do
        member("layer" .. string(q + tf)).image:copyPixels(member(mat .. "Image2").image,
          rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * 3, var * 20, 20 * 4), { ink = 36 })
      end
      tf = 7
      for ld = 4, 6 do
        member("layer" .. string(q + tf)).image:copyPixels(member(mat .. "Image2").image,
          rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * ld, var * 20, 20 * (ld + 1)),
          { ink = 36 })
        tf = tf + 1
      end
    end
  else
    local lst = { "0000", "1111", "0101", "1010", "0001", "1000", "0100", "0010", "1001", "1100", "0110", "0011", "1011",
      "1101", "1110", "0111" }

    local q = (layer * 10) - 10

    local lft = spelrelaterat.solidAfaMv(tl + point(-1, 0), layer) * me.DPCircuitConnection(tl + point(-1, 0), q).x
    local rght = sspelrelaterat.olidAfaMv(tl + point(1, 0), layer) * me.DPCircuitConnection(tl, q).x
    local tp = spelrelaterat.solidAfaMv(tl + point(0, -1), layer) * me.DPCircuitConnection(tl + point(0, -1), q).y
    local bttm = sspelrelaterat.olidAfaMv(tl + point(0, 1), layer) * me.DPCircuitConnection(tl, q).y

    if (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) > 1 and (spelrelaterat.afaMvLvlEdit(tl + point(-1, 0), layer) ~= 9)) then
      lft = 1
    end
    if (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) > 1 and (spelrelaterat.afaMvLvlEdit(tl + point(1, 0), layer) ~= 9)) then
      rght = 1
    end
    if (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) > 1 and (spelrelaterat.afaMvLvlEdit(tl + point(0, -1), layer) ~= 9)) then
      tp = 1
    end
    if (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) > 1 and (spelrelaterat.afaMvLvlEdit(tl + point(0, 1), layer) ~= 9)) then
      bttm = 1
    end


    local var = getPos(lst, (tostring(lft) .. tostring(tp) .. tostring(rght) .. tostring(bttm)))

    if var == 3 then
      local rndList = { 3, 23 }
      var = rndList[random(2)]
    elseif var == 4 then
      local rndList = { 4, 24 }
      var = rndList[random(2)]
    elseif var == 1 then
      local rndList = { 1, 26, 27 }
      var = rndList[random(3)]
    end

    for ld = 0, 2 do
      member("layer" .. string(q + ld)).image:copyPixels(member(mat .. "Image2").image,
        rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * ld, var * 20, 20 * (ld + 1)), { ink = 36 })
    end
    for tf = 3, 6 do
      member("layer" .. string(q + tf)).image:copyPixels(member(mat .. "Image2").image,
        rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * 3, var * 20, 20 * 4), { ink = 36 })
    end
    tf = 7
    for ld = 4, 6 do
      member("layer" .. string(q + tf)).image:copyPixels(member(mat .. "Image2").image,
        rect(pos - point(10, 10), pos + point(10, 10)), rect((var - 1) * 20, 20 * ld, var * 20, 20 * (ld + 1)), { ink = 36 })
      tf = tf + 1
    end
  end

  randomSeed = savSeed
end

function me.DPCircuitConnection(tl, dpAdd)
  -- local spelrelaterat = require('spelrelaterat')
  local savSeed = randomSeed
  randomSeed = spelrelaterat.seedForTile(tl, 0) + (dpAdd / 2).integer * (tl.x / 3).integer - (tl.y / 2).integer

  local pnt

  if (random(2) == 1) then
    pnt = point(random(2) - 1, random(2) - 1)
  else
    if (random(2) == 1) then
      pnt = point(1, 0)
    else
      pnt = point(0, 1)
    end
  end


  randomSeed = savSeed

  return pnt
end

function me.DPStartLayerOfTile(tl, layer)
  if (layer > 1) then
    if (spelrelaterat.afaMvLvlEdit(tl, layer - 1) == 1) then
      --  return 0
    end
  end

  local distanceToAir = me.DistanceToAir(tl, layer)

  --  if(random(300)=1)then
  --  put distanceToAir
  -- end

  if (distanceToAir >= 7) and (layer == 1) then
    --   return 0
  end

  local pushIn = 6 - distanceToAir
  pushIn = pushIn - toint(layer == 1) - 3 * toint(layer == 3)
  pushIn = spelrelaterat.restrict(pushIn, -4 * (layer > 1) - 5 * toint(layer == 3), 9 - 5 * toint(layer == 1))


  return (layer - 1) * 10 + pushIn
end

function me.DistanceToAir(tl, layer)
  -- local spelrelaterat = require('spelrelaterat')
  local distanceToAir = 8
  local ext = false
  for dist = 1, 7 do
    for _, dir in ipairs({ point(-1, 0), point(-1, -1), point(0, -1), point(1, -1), point(1, 0), point(1, 1), point(0, 1), point(-1, 1) }) do
      if (spelrelaterat.afaMvLvlEdit(tl + dir * dist, layer) ~= 1) and (spelrelaterat.afaMvLvlEdit(tl + dir * dist, spelrelaterat.restrict(layer - 1, 1, 3)) ~= 1) then
        distanceToAir = dist
        ext = true
        break
      end
    end
    if (ext) then
      break
    end
  end
  return distanceToAir
end

function me.drawTinySigns()
  -- local spelrelaterat

  member("Tiny SignsTexture").image:copyPixels(member("pxl").image, rect(0, 0, 1080, 800), rect(0, 0, 1, 1),
    { color = color(0, 255, 0) })

  local language = 2

  local blueList = { point(1, 1), point(1, 0), point(0, 1) }
  local redList = { point(-1, -1), point(-1, 0), point(0, -1) }

  local tlSize = 8
  local rndList = { 20, 14, 1 }
  for c = 0, 100 do
    for q = 0, 135 do
      --putRct = rect((q-1)*8, )
      local mdPnt = point((q + 0.5) * tlSize, (c + 0.5) * tlSize)
      
      local gtPos = point(random(rndList[language]), language)

      if random(50) == 1 then
        language = 2
      elseif random(80) == 1 then
        language = 1
      end

      if random(7) == 1 then
        if random(3) == 1 then
          gtPos = point(1, 3)
        else
          gtPos = point(random(random(7)), 3)
          if random(5) == 1 then
            language = 2
          elseif random(10) == 1 then
            language = 1
          end
        end
      end

      for _, p in ipairs(redList) do
        member("Tiny SignsTexture").image:copyPixels(member("tinySigns").image,
          rect(mdPnt, mdPnt) + rect(-3, -3, 3, 3) + rect(p, p), rect((gtPos.x - 1) * 6, (gtPos.y - 1) * 6, gtPos.x * 6,
          gtPos.y * 6), { ink = 36, color = color(255, 0, 0) })
      end
      for _, p in ipairs(blueList) do
        member("Tiny SignsTexture").image:copyPixels(member("tinySigns").image,
          rect(mdPnt, mdPnt) + rect(-3, -3, 3, 3) + rect(p, p), rect((gtPos.x - 1) * 6, (gtPos.y - 1) * 6, gtPos.x * 6,
          gtPos.y * 6), { ink = 36, color = color(0, 0, 255) })
      end

      member("Tiny SignsTexture").image:copyPixels(member("tinySigns").image, rect(mdPnt, mdPnt) + rect(-3, -3, 3, 3),
        rect((gtPos.x - 1) * 6, (gtPos.y - 1) * 6, gtPos.x * 6, gtPos.y * 6), { ink = 36, color = color(0, 255, 0) })
    end
  end
end

function me.renderTileMaterial(layer, material, frntImg)
  -- local utils = require('comEditorUtils')
  -- local spelrelaterat = require('spelrelaterat')

  local tlsOrdered = list()
  for q = 1, gLOprops.size.x do
    for c = 1, gLOprops.size.y do
      local LEPropqc = gLEProps.matrix[q][c][layer][1]
      if (LEPropqc ~= 0) then
        local addMe = false
        local TEPropqc = gTEProps.tlMatrix[q][c][layer]
        if (TEPropqc.tp == "material") then
          if (TEPropqc.data == material) then
            addMe = true
          end
        elseif (gTEProps.defaultMaterial == material) then
          if (TEPropqc.tp == "default") then
            addMe = true
          end
        end

        if (addMe) then
          if (LEPropqc == 1) then
            tlsOrdered:add({ random(gLOprops.size.x + gLOprops.size.y), point(q, c) })
          elseif tobool(gDRMatFixes) or ((material ~= "Tiled Stone") and (material ~= "Chaotic Stone") and (material ~= "Random Machines") and (material ~= "3DBricks")) then
            tlsOrdered:add({ random(gLOprops.size.x + gLOprops.size.y), point(q, c) })
          elseif (point(q, c):inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
            frntImg = me.drawATileMaterial(q, c, layer, "Standard", frntImg)
          end
        end
      end
    end
  end

  -- tlsOrdered.sort()
  table.sort(tlsOrdered, function(a, b) return a[1] < b[1] end)
  local tls = list()

  for q = 1, #tlsOrdered do
    tls:add(tlsOrdered[q][2])
  end

  if material == "Chaotic Stone" then
    if tobool(gDRMatFixes) then
      local tileCat
      for tc = utils.getFirstTileCat(), #gTiles do
        if (gTiles[tc].nm == "LB Missing Stone") then
          tileCat = tc
          break
        end
      end

      local cnt = #tls

      for q = 1, cnt do
        local tl = tls[cnt + 1 - q]

        local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

        if geoCase == 2 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 3 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 4 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 5 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 6 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
          tls:deleteAt(cnt + 1 - q)
        end

        -- case (spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)) of
        --   2:
        --   3:
        --   4:
        --   5:
        --   6:
        --   0, 7, 8, 9:
        -- end case
      end
    end

    local stCat = 0
    for st = 1, #gTiles do
      if (gTiles[st].nm == "Stone") then
        stCat = st
        break
      end
    end

    local delL = list()

    for _, tl in ipairs(tls) do
      if getPos(delL, tl) == 0 then
        local hts = 0

        for _, dir in ipairs({ point(1, 0), point(0, 1), point(1, 1) }) do
          hts = hts + (tls:getPos(tl + dir) > 0) * (delL:getPos(tl + dir) == 0)
        end

        if hts == 3 then
          if (tl:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
            frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[stCat].tls[2], frntImg)
          end

          for _, dir in ipairs({ point(1, 0), point(0, 1), point(1, 1) }) do
            delL:add(tl + dir)
          end
          delL:add(tl)
        end
      end
    end

    for _, del in ipairs(delL) do
      tls:deleteOne(del)
    end

    local savSeed = randomSeed

    while #tls > 0 do
      randomSeed = gLOprops.tileSeed + #tls
      local tl   = tls[random(#tls)]

      if (tl:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[stCat].tls[1], frntImg)
      end
      tls:deleteOne(tl)
    end
    randomSeed = savSeed
  elseif material == "Tiled Stone" then
    if tobool(gDRMatFixes) then
      local tileCat
      for tc = utils.getFirstTileCat(), #gTiles do
        if (gTiles[tc].nm == "LB Missing Stone") then
          tileCat = tc
          break
        end
      end

      local cnt = #tls

      for q = 1, cnt do
        local tl = tls[cnt + 1 - q]

        local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

        if geoCase == 2 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 3 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 4 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 5 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 6 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
          tls:deleteAt(cnt + 1 - q)
        end

        -- case () of
        --   2:
        --   3:
        --   4:
        --   5:
        --   6:
        --   0, 7, 8, 9:
        -- end case
      end
    end

    local stCat = 0
    for st = 1, #gTiles do
      if (gTiles[st].nm == "Stone") then
        stCat = st
        break
      end
    end

    local delL = list()

    for _, tl in ipairs(tls) do
      if delL:getPos(tl) == 0 then
        if tobool(tl.y % 2) and tobool((tl.x + ((tl.y % 4) == 1)) % 2) then
          local hts = 0

          for _, dir in ipairs({ point(1, 0), point(0, 1), point(1, 1) }) do
            hts = hts + (tls:getPos(tl + dir) > 0) * (delL:getPos(tl + dir) == 0)
          end

          if hts == 3 then
            frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[stCat].tls[2], frntImg)

            for _, dir in ipairs({ point(1, 0), point(0, 1), point(1, 1) }) do
              delL:add(tl + dir)
            end
            delL:add(tl)
          end
        end
      end
    end

    for _, toDel in ipairs(delL) do
      tls:deleteOne(toDel)
    end

    while #tls > 0 do
      local tl = tls[random(#tls)]
      frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[stCat].tls[1], frntImg)
      tls:deleteOne(tl)
    end

    --    "3DBricks":
    --      repeat while tls.count > 0 then
    --        tl = tls[random(tls.count)]
    --        frntImg = drawATileTile(tl.x,tl.y,layer, gTiles[5].tls[8], frntImg)
    --        tls.deleteOne(tl)
    --      end
  elseif material == "Random Machines" then
    if tobool(gDRMatFixes) then
      local tileCat
      for tc = utils.getFirstTileCat(), #gTiles do
        if (gTiles[tc].nm == "LB Missing Machine") then
          tileCat = tc
          break
        end
      end

      local cnt = #tls

      for q = 1, cnt do
        local tl = tls[cnt + 1 - q]

        local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

        if geoCase == 2 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 3 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 4 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 5 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 6 then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
          tls:deleteAt(cnt + 1 - q)
        elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
          tls:deleteAt(cnt + 1 - q)
        end

        -- case () of
        --   2:
        --   3:
        --   4:
        --   5:
        --   6:
        --   0,7,8,9:
        -- end case
      end
    end

    local savSeed = randomSeed

    randomSeed = gLOprops.tileSeed + layer

    local randomMachines = list()
    for w = 1, 8 do
      local lst = list()

      for h = 1, 8 do
        lst:add(list())
      end

      randomMachines:add(lst)
    end

    for a = 1, #RandomMachines_grabTiles do
      for q = 1, #gTiles do
        if (gTiles[q].nm == RandomMachines_grabTiles[a]) then
          for t = 1, #gTiles[q].tls do
            local theTile = gTiles[q].tls[t]
            if (theTile.sz.x <= 8) and (theTile.sz.y <= 8) and (theTile.specs2 == 0) and (getPos(RandomMachines_forbidden, theTile.nm) == 0) then
              randomMachines[theTile.sz.x][theTile.sz.y]:add(point(q, t))
            end
          end
        end
      end
    end

    local delL = map()
    local tlsBlock = map()

    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for _, tl in ipairs(tls) do
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)
      if not delL[tl] then
        local randomOrderList = list()

        for w = 1, #randomMachines do
          for h = 1, #randomMachines[w] do
            for t = 1, #randomMachines[w][h] do
              randomOrderList:add({ random(1000), randomMachines[w][h][t] })
            end
          end
        end

        -- randomOrderList.sort()
        table.sort(randomOrderList, function(a, b) return a[1] < b[1] end)

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]

          local legalToPlace = true

          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

              if (not tlsBlock[tostring(testPoint)]) or ((spec > -1) and (delL[testPoint] or (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec))) then
                legalToPlace = false
                break
              end
            end

            if (legalToPlace == false) then
              break
            end
          end

          if legalToPlace then
            local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) - 1)

            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = true
                end
              end
            end
            break
          end
        end
      end
    end

    randomSeed = savSeed
  elseif material == "Random Machines 2" then
    local tileCat
    for tc = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tc].nm == "LB Missing Machine") then
        tileCat = tc
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case (spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)) of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   0,7,8,9:
      -- end case
    end

    local savSeed = randomSeed

    randomSeed = gLOprops.tileSeed + layer

    local randomMachines = list()

    for w = 1, 8 do
      local lst = list()
      for h = 1, 8 do
        lst:add(list())
      end
      randomMachines:add(lst)
    end

    for a = 1, #RandomMachines2_grabTiles do
      for q = 1, #gTiles do
        if (gTiles[q].nm == RandomMachines2_grabTiles[a]) then
          for t = 1, #gTiles[q].tls do
            local theTile = gTiles[q].tls[t]

            if (theTile.sz.x <= 8) and (theTile.sz.y <= 8) and (theTile.specs2 == 0) and (getPos(RandomMachines2_forbidden, theTile.nm) == 0) then
              randomMachines[theTile.sz.x][theTile.sz.y]:add(point(q, t))
            end
          end
        end
      end
    end

    local delL = map()
    local tlsBlock = map()

    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for _, tl in ipairs(tls) do
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

      if not delL[tl] then
        local randomOrderList = list()

        for w = 1, #randomMachines do
          for h = 1, #randomMachines[w] do
            for t = 1, #randomMachines[w][h] do
              randomOrderList:add({ random(1000), randomMachines[w][h][t] })
            end
          end
        end

        randomOrderList:sort()

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]

          local legalToPlace = true

          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

              if not (tlsBlock[tostring(testPoint)]) then
                legalToPlace = false
                break
              end

              if (spec > -1) then
                if (delL[testPoint]) then
                  legalToPlace = false
                  break
                end
                if (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec) then
                  legalToPlace = false
                  break
                end
              end
            end
            if (legalToPlace == false) then
              break
            end
          end

          if (legalToPlace) then
            local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) -
            1)
            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = true
                end
              end
            end
            break
          end
        end
      end
    end

    randomSeed = savSeed
  elseif material == "Small Machines" then
    local tileCat
    for tc = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tc].nm == "LB Missing Machine") then
        tileCat = tc
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   0,7,8,9:
      -- end case
    end

    local savSeed = randomSeed

    randomSeed = gLOprops.tileSeed + layer

    local randomMachines = list()

    for w = 1, 8 do
      lst = list()
      for h = 1, 8 do
        lst:add(list())
      end
      randomMachines:add(lst)
    end

    for a = 1, #SmallMachines_grabTiles do
      for q = 1, #gTiles do
        if (gTiles[q].nm == SmallMachines_grabTiles[a]) then
          for t = 1, #gTiles[q].tls do
            local theTile = gTiles[q].tls[t]
            if (theTile.sz.x <= 8) and (theTile.sz.y <= 8) and (theTile.specs2 == 0) and (getPos(SmallMachines_forbidden, theTile.nm) == 0) then
              randomMachines[theTile.sz.x][theTile.sz.y]:add(point(q, t))
            end
          end
        end
      end
    end

    local delL = map()
    local tlsBlock = map()
    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for _, tl in ipairs(tls) do
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)
      if not delL[tl] then
        local randomOrderList = list()

        for w = 1, #randomMachines do
          for h = 1, #randomMachines[w] do
            for t = 1, randomMachines[w][h] do
              randomOrderList:add({ random(1000), randomMachines[w][h][t] })
            end
          end
        end

        -- randomOrderList.sort()
        table.sort(randomOrderList, function(a, b) return a[1] < b[1] end)

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]

          local legalToPlace = true

          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

              if not (tlsBlock[tostring(testPoint)]) then
                legalToPlace = false
                break
              end

              if (spec > -1) then
                if (delL[testPoint]) then
                  legalToPlace = false
                  break
                end
                if (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec) then
                  legalToPlace = false
                  break
                end
              end
            end
            if (legalToPlace == false) then
              break
            end
          end

          if (legalToPlace) then
            local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) -
            1)
            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = true
                end
              end
            end
            break
          end
        end
      end
    end

    randomSeed = savSeed
  elseif material == "Random Metal" then
    local tileCat
    for tc = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tc].nm == "LB Missing Metal") then --> this is the category for slopes, shortcut geometry and glass, added to prevent the material from crashing if applied function these geometries and to add custom ones
        tileCat = tc
      break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg) --> tileCat is the category mentioned above, 1 is the tile order number
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2: --> 2 is the geometry number (it can be 0, 1, 2, 3, 4, 5, 5, 7, 8(unused), 9)
      --   3:
      --   4:
      --   5:
      --   6:
      --   0,7,8,9:
      -- end case
    end

    local savSeed = randomSeed

    randomSeed = gLOprops.tileSeed + layer

    local randomMetal = list()
    for w = 1, 8 do
      local lst = list()
      for h = 1, 8 do
        lst:add(list())
      end
      randomMetal:add(lst)
    end

    -- remove the "--" to uncomment
    for q = utils.getFirstTileCat(), #gTiles do --cat change
      for t = 1, #gTiles[q].tls do
        local theTile = gTiles[q].tls[t]

        if (getPos(theTile.tags, "randomMetal") ~= 0) or (getPos(DRRandomMetal_needed, theTile.nm) >= 1) then --> you can add things before "then" here, just be sure to add "and" between conditions
          -- (gTiles[q].tls[t].tags.getPos("randomMetal") ~= 0) --> checks a tag; you can change the tag, just be sure to add the reight function to the tiles you want in the material mix
          -- (gTiles[q].tls[t].sz.x <= 8) --> checks the height of the tile (value of x in #sz:point(x, y))
          -- (gTiles[q].tls[t].sz.y <= 8) --> checks the width of the tile (value of y in #sz:point(x, y))
          -- (forbidden.getPos(gTiles[q].tls[t].nm) = 0) --> checks if the tile is forbidden (list above)
          -- (gTiles[q].tls[t].specs2 = 0) --> checks if the tile has no specs function layer 2
          randomMetal[theTile.sz.x][theTile.sz.y]:add(point(q, t))
        end
      end
    end

    local delL = map()
    local tlsBlock = map()
    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for _, tl in ipairs(tls) do
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

      if not delL[tl] then
        local randomOrderList = list()

        for w = 1, #randomMetal do
          for h = 1, #randomMetal[w] do
            for t = 1, #randomMetal[w][h] do
              randomOrderList:add({ random(1000), randomMetal[w][h][t] })
            end
          end
        end

        -- randomOrderList.sort()
        table.sort(randomOrderList, function(a, b) return a[1] < b[1] end)

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]

          local legalToPlace = true

          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

              if not (tlsBlock[tostring(testPoint)]) then
                legalToPlace = false
                break
              end

              if (spec > -1) then
                if (delL[testPoint]) then
                  legalToPlace = false
                  break
                end

                if (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec) then
                  legalToPlace = false
                  break
                end
              end
            end
            if (legalToPlace == false) then
              break
            end
          end

          if (legalToPlace) then
            local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) -
            1)
            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = true
                end
              end
            end
            break
          end
        end
      end
    end

    randomSeed = savSeed
  elseif material == "Chaotic Stone 2" then
    local tileCat
    for tc = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tc].nm == "LB Missing Stone") then
        tileCat = tc
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   0,7,8,9:
      -- end case
    end

    local savSeed = randomSeed
    randomSeed = gLOprops.tileSeed + layer

    local stones = list()
    local smSto = list()

    for w = 1, 8 do
      local lst = list()
      for h = 1, 8 do
        lst:add(list())
      end
      stones:add(lst)
    end

    for q = utils.getFirstTileCat(), #gTiles do ---cat change
      for t = 1, #gTiles[q].tls do
        local tsto = gTiles[q].tls[t]

        if (((getPos(tsto.tags, "chaoticStone2") ~= 0) or (getPos(tsto.tags, "chaoticStone2 : rare") ~= 0) or (getPos(tsto.tags, "chaoticStone2 : very rare") ~= 0))) or (getPos(ChaoticStone2_needed, tsto.nm) >= 1) then
          if (tsto.sz.x > 1) and (tsto.sz.y > 1) then
            stones[tsto.sz.x][tsto.sz.y]:add(point(q, t))
          else
            smSto:add(tsto)
          end
        end
      end
    end

    local delL = map()
    local tlsBlock = map()

    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for tlC = 1, #tls do
      local tl = tls[tlC]
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

      if not (delL[tl]) then
        local randomOrderList = list()
        for w = 1, #stones do
          for h = 1, #stones[w] do
            for t = 1, #stones[w][h] do
              randomOrderList:add({ random(500), stones[w][h][t] })
            end
          end
        end

        -- randomOrderList.sort()
        table.sort(randomOrderList, function(a, b) return a[1] < b[1] end)

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]
          local legalToPlace = true

          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
              if (not tlsBlock[testPoint]) then
                legalToPlace = false
                break
              end

              if (spec > -1) then
                if (delL[testPoint]) then
                  legalToPlace = false
                  break
                end
                if (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec) then
                  legalToPlace = false
                  break
                end
              end
            end
            if (legalToPlace == false) then
              break
            end
          end

          local tags2 = testTile.tags

          if ((getPos(tags2, "chaoticStone2 : rare") ~= 0) and (random(2) ~= 1)) or ((getPos(tags2, "chaoticStone2 : very rare") ~= 0) and (random(4) ~= 1)) or ((testTile.nm == "Big Stone Marked") and (random(2) ~= 1)) then
            legalToPlace = false
          end

          if (legalToPlace) then
            local rootPos = tl +
            point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) - 1)
            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = 1
                  tls:deleteOne(tl + point(a, b))
                  --writeMessage(tl + point(a, b))
                end
              end
            end
            break
          end
        end
      end
    end

    while #tls > 0 do
      local tl = tls[random(#tls)]
      local ptt = smSto[random(#smSto)]

      if ((getPos(ptt.tags, "chaoticStone2 : rare") ~= 0) and (random(8) ~= 1)) or ((getPos(ptt.tags, "chaoticStone2 : very rare") ~= 0) and (random(16) ~= 1)) then
        ptt = smSto[random(#smSto)]
      end

      frntImg = me.drawATileTile(tl.x, tl.y, layer, ptt, frntImg)
      tls:deleteOne(tl)
    end
    randomSeed = savSeed
  elseif material == "Random Metals" then
    --Dry's random metals
    local tileCat
    for tc = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tc].nm == "LB Missing Metal") then
        tileCat = tc
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   0, 7, 8, 9:
      -- end case
    end

    local savSeed = randomSeed

    randomSeed = gLOprops.tileSeed + layer

    local randomMetals = list()

    for w = 1, 8 do
      local lst = list()
      for h = 1, 8 do
        lst:add(list())
      end
      randomMetals:add(lst)
    end

    for a = 1, #RandomMetals_grabTiles do
      for q = 1, #gTiles do
        if (gTiles[q].nm == RandomMetals_grabTiles[a]) then
          for t = 1, #gTiles[q].tls do
            local theTile = gTiles[q].tls[t]
            if (theTile.sz.x <= 8) and (theTile.sz.y <= 8) and (theTile.specs2 == 0) and (getPos(RandomMetals_allowed, theTile.nm) >= 1) then
              randomMetals[theTile.sz.x][theTile.sz.y]:add(point(q, t))
            end
          end
        end
      end
    end

    local delL = map()
    local tlsBlock = map()

    for _, tl in ipairs(tls) do
      tlsBlock[tostring(tl)] = true
    end

    for _, tl in ipairs(tls) do
      randomSeed = spelrelaterat.seedForTile(tl, gLOprops.tileSeed + layer)

      if not delL[tl] then
        local randomOrderList = list()

        for w = 1, #randomMetals do
          for h = 1, #randomMetals[w] do
            for t = 1, #randomMetals[w][h] do
              randomOrderList:add({ random(1000), randomMetals[w][h][t] })
            end
          end
        end

        -- randomOrderList.sort()
        table.sort(randomOrderList, function(a, b) return a[1] < b[1] end)

        for q = 1, #randomOrderList do
          local testTile = gTiles[randomOrderList[q][2].x].tls[randomOrderList[q][2].y]

          local legalToPlace = true
          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

              if (not tlsBlock[testPoint]) then
                legalToPlace = false
                break
              end

              if (spec > -1) then
                if (delL[testPoint]) then
                  legalToPlace = false
                  break
                end
                if (spelrelaterat.afaMvLvlEdit(testPoint, layer) ~= spec) then
                  legalToPlace = false
                  break
                end
              end
            end
            if (legalToPlace == false) then
              break
            end
          end

          if (legalToPlace) then
            local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) -
            1)
            if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
              frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg)
            end

            for a = 0, testTile.sz.x - 1 do
              for b = 0, testTile.sz.y - 1 do
                local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
                if (spec > -1) then
                  delL[tl + point(a, b)] = true
                end
              end
            end
            break
          end
        end
      end
    end

    randomSeed = savSeed
  elseif material == "Dune Sand" then
    --Dry's mat, improved by LB
    
    local savSeed = randomSeed
    randomSeed = gLOprops.tileSeed + layer
    local duneSand = list()

    for a = utils.getFirstTileCat(), #gTiles do -- cat change
      for b = 1, #gTiles[a].tls do
        local theTile = gTiles[a].tls[b]
        if (theTile.tp == "voxelStructSandType") and (theTile.sz.x == 1) and (theTile.sz.y == 1) then
          duneSand:add(theTile)
        end
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]
      if (spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer) ~= 1) then
        tls:deleteAt(cnt + 1 - q)
      else
        frntImg = me.drawATileTile(tl.x, tl.y, layer, duneSand[random(#duneSand)], frntImg)
        tls:deleteAt(cnt + 1 - q)
      end
    end

    randomSeed = savSeed
  elseif material == "Temple Stone" then
    for tileCat = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tileCat].nm == "Temple Stone") then
        break
      end
    end

    -- global templeStoneCorners
    templeStoneCorners = list({ list(), list(), list(), list() })

    local tls2 = clone(tls)

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[6], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[7], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[8], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 then
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 9 then
        if tobool(gDRMatFixes) then
          tls:deleteAt(cnt + 1 - q)
        end
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   0, 7, 8:
      --   9:
      -- end case
    end

    for q = 1, #tls2 do
      local tl = tls2[q]
      if ((tl.y % 4) == 0) then
        if ((tl.x % 6) == 0) then
          me.attemptDrawTempleStone(tl, tls, 2, layer, frntImg, tileCat)
          --elseif((tl.x % 6) = 3)then
          --  attemptDrawTempleStone(tl, tls, 3, layer, frntImg, tileCat)
        end
      end

      if ((tl.y % 4) == 2) then
        if ((tl.x % 6) == 3) then
          me.attemptDrawTempleStone(tl, tls, 2, layer, frntImg, tileCat)
          --  elseif((tl.x % 6) = 0)then
          --   attemptDrawTempleStone(tl, tls, 3, layer, frntImg, tileCat)
        end
      end
    end

    for q = 1, #templeStoneCorners[1] do
      local ind = #templeStoneCorners[1] + 1 - q
      if (templeStoneCorners[3]:getPos(templeStoneCorners[1][ind]) > 0) then
        --  templeStoneCorners[3].deleteOne(templeStoneCorners[1][ind])
        tls:deleteOne(templeStoneCorners[1][ind])
        --  templeStoneCorners[1].deleteAt(ind)
      end
    end

    for q = 1, #templeStoneCorners[2] do
      local ind = #templeStoneCorners[2] + 1 - q
      if (templeStoneCorners[4]:getPos(templeStoneCorners[2][ind]) > 0) then
        --  templeStoneCorners[4].deleteOne(templeStoneCorners[2][ind])
        tls:deleteOne(templeStoneCorners[2][ind])
        --  templeStoneCorners[2].deleteAt(ind)
      end
    end

    while #tls > 0 do
      local tl = tls[random(#tls)]
      local drawn = false

      if (templeStoneCorners[1]:getPos(tl) > 0) then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[7], frntImg)
        drawn = true
      elseif (templeStoneCorners[2]:getPos(tl) > 0) then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[8], frntImg)
        drawn = true
      elseif (templeStoneCorners[3]:getPos(tl) > 0) then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        drawn = true
      elseif (templeStoneCorners[4]:getPos(tl) > 0) then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[6], frntImg)
        drawn = true
      end

      if (drawn == false) then
        local occupy = list({ point(-1, 0), point(-1, 1), point(0, 0), point(0, 1), point(1, 0), point(1, 1) })
        local drawn = true

        for q = 1, #occupy do
          if (me.checkIfATileIsSolidAndSameMaterial(tl + occupy[q], layer, "Temple Stone") == false) then
            drawn = false
            break
          end

          for a = 1, 4 do
            if (templeStoneCorners[a]:getPos(tl + occupy[q]) > 0) then
              drawn = false
              break
            end
          end

          if (drawn == false) then
            break
          end

          if (tls:getPos(tl + occupy[q]) == 0) then
            drawn = false
            break
          end
        end

        if (drawn) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[9], frntImg)
          for q = 1, #occupy do
            tls:deleteOne(tl + occupy[q])
          end
        end
      end

      if (drawn == false) then
        if (me.checkIfATileIsSolidAndSameMaterial(tl + point(-1, 0), layer, "Temple Stone") and tls:getPos(tl + point(-1, 0)) > 0) and (templeStoneCorners[1]:getPos(tl + point(-1, 0)) == 0) and (templeStoneCorners[2]:getPos(tl + point(-1, 0)) == 0) and (templeStoneCorners[3]:getPos(tl + point(-1, 0)) == 0) and (templeStoneCorners[4]:getPos(tl + point(-1, 0)) == 0) then
          frntImg = me.drawATileTile(tl.x - 1, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteOne(tl + point(-1, 0))
        elseif (me.checkIfATileIsSolidAndSameMaterial(tl + point(1, 0), layer, "Temple Stone") and tls:getPos(tl + point(1, 0)) > 0) and (templeStoneCorners[1]:getPos(tl + point(1, 0)) == 0) and (templeStoneCorners[2]:getPos(tl + point(1, 0)) == 0) and (templeStoneCorners[3]:getPos(tl + point(1, 0)) == 0) and (templeStoneCorners[4]:getPos(tl + point(1, 0)) == 0) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteOne(tl + point(1, 0))
        else
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        end
      end

      tls:deleteOne(tl)
    end

    templeStoneCorners = list()
  elseif material == "4Mosaic" then
    for tileCat = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tileCat].nm == "LB 4Mosaic") then
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 3 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 4 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 5 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 6 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[6], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 1 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   1:
      --   0, 7, 8, 9:
      -- end case
    end
  elseif material == "3DBricks" then
    for tileCat = utils.getFirstTileCat(), #gTiles do
      if (gTiles[tileCat].nm == "LB Missing 3DBricks") then
        break
      end
    end

    local cnt = #tls

    for q = 1, cnt do
      local tl = tls[cnt + 1 - q]

      local geoCase = spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)

      if geoCase == 2 then
        if tobool(gDRMatFixes) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[2], frntImg)
          tls:deleteAt(cnt + 1 - q)
        end
      elseif geoCase == 3 then
        if tobool(gDRMatFixes) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[3], frntImg)
          tls:deleteAt(cnt + 1 - q)
        end
      elseif geoCase == 4 then
        if tobool(gDRMatFixes) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[5], frntImg)
          tls:deleteAt(cnt + 1 - q)
        end
      elseif geoCase == 5 then
        if tobool(gDRMatFixes) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[4], frntImg)
          tls:deleteAt(cnt + 1 - q)
        end
      elseif geoCase == 6 then
        if tobool(gDRMatFixes) then
          frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[6], frntImg)
          tls:deleteAt(cnt + 1 - q)
        end
      elseif geoCase == 1 then
        frntImg = me.drawATileTile(tl.x, tl.y, layer, gTiles[tileCat].tls[1], frntImg)
        tls:deleteAt(cnt + 1 - q)
      elseif geoCase == 0 or geoCase == 7 or geoCase == 8 or geoCase == 9 then
        tls:deleteAt(cnt + 1 - q)
      end

      -- case () of
      --   2:
      --   3:
      --   4:
      --   5:
      --   6:
      --   1:
      --   0, 7, 8, 9:
      -- end case
    end
  elseif material == "Chaotic Greeble" then
    -- Cursed material by Alduris
    local savSeed = randomSeed
    randomSeed = gLOprops.tileSeed + layer

    -- Collect tiles that aren't completely air
    local allTiles = list()

    for _, tlGrp in ipairs(gTiles) do
      for _, tlCG in ipairs(tlGrp.tls) do
        if tlCG.tags then
          if getPos(tlCG.tags, "notChaos") > 0 then
            goto continueCG
          end
        end

        for _, spec in ipairs(tlCG.specs) do
          if spec > 0 then
            allTiles:add(tlCG)
            break
          end
        end

        ::continueCG::
      end
    end

    -- Do things!!
    local cnt = #tls

    for q = 1, cnt do
      if (#tls == 0) then break end

      local tl = tls[random(#tls)]

      -- Shuffle tiles
      local randomTiles = list()

      for _, thisTl in ipairs(allTiles) do
        randomTiles:append({ random(10000), thisTl })
      end

      -- randomTiles.sort()
      table.sort(randomTiles, function(a, b) return a[1] < b[1] end)

      -- Find a tile to place
      for t = 1, #randomTiles do
        local testTile = randomTiles[t][2]

        -- Determine legality of placement
        local legalToPlace = true
        for a = 0, testTile.sz.x - 1 do
          for b = 0, testTile.sz.y - 1 do
            local testPoint = tl + point(a, b)
            local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]

            if spec <= 0 then goto continueCG2 end -- ignore air and buffer

            if (getPos(tls, testPoint) == 0) then  -- areas where material is not placed
              legalToPlace = false
              break
            end

            local geoSpec = spelrelaterat.afaMvLvlEdit(testPoint, layer)
            if (geoSpec ~= spec) and (geoSpec ~= 1) and (geoSpec ~= 7) then
              -- spec does not match function non-solid tile
              legalToPlace = false
              break
            end

            ::continueCG2::
          end
          if (not legalToPlace) then break end
        end

        if legalToPlace then
          -- Place tile
          local rootPos = tl + point(toint((testTile.sz.x / 2.0) + 0.4999) - 1, toint((testTile.sz.y / 2.0) + 0.4999) - 1)
          if (rootPos:inside(rect(gRenderCameraTilePos, gRenderCameraTilePos + point(100, 60)))) then
            frntImg = me.drawATileTile(rootPos.x, rootPos.y, layer, testTile, frntImg, list())
          end

          -- Remove tile ref
          for a = 0, testTile.sz.x - 1 do
            for b = 0, testTile.sz.y - 1 do
              local testPoint = tl + point(a, b)
              local spec = testTile.specs[(b + 1) + (a * testTile.sz.y)]
              if spec > 0 then
                tls:deleteAt(getPos(tls, testPoint))
              end
            end
          end
          break
        end
      end
    end

    randomSeed = savSeed
  end

  -- case material of
  --   "Chaotic Stone":
  --   "Tiled Stone":
  --   "Random Machines":
  --   "Random Machines 2":
  --   "Small Machines":
  --   "Random Metal":
  --   "Chaotic Stone 2":
  --   "Random Metals":
  --   "Dune Sand":
  --   "Temple Stone":
  --   "4Mosaic":
  --   "3DBricks":

  --   "Chaotic Greeble":
  -- end case

  return frntImg
end

function me.attemptDrawTempleStone(tlPos, tilesList, templeStoneType, layer, frntImg, tileCat)
  -- global templeStoneCorners
  local occupy = list()

  if templeStoneType == 2 then
    occupy = list({ point(-1, 0), point(0, -1), point(0, 0), point(0, 1), point(1, -1), point(1, 0), point(1, 1), point(
    2, 0) })
  elseif templeStoneType == 3 then
    occupy = list({ point(0, 0), point(1, 0) })
  end

  -- case templeStoneType of
  --   2:
  --   3:
  -- end case

  for q = 1, #occupy do
    if tobool(me.checkIfATileIsSolidAndSameMaterial(tlPos + occupy[q], layer, "Temple Stone")) then
      return tilesList
    end
  end

  frntImg = me.drawATileTile(tlPos.x, tlPos.y, layer, gTiles[tileCat].tls[templeStoneType], frntImg)

  if (templeStoneType == 2) then
    templeStoneCorners[1]:add(tlPos + point(-1, -1))
    templeStoneCorners[2]:add(tlPos + point(2, -1))
    templeStoneCorners[3]:add(tlPos + point(2, 1))
    templeStoneCorners[4]:add(tlPos + point(-1, 1))
  end

  for q = 1, #occupy do
    tilesList:deleteOne(tlPos + occupy[q])
  end
  return tilesList
end

--function IsTileADoubleInChaoticStone(tl, lr)
--  if(tl.x < 0)or(tl.y < 0) then
--    return false
--  end
--
--  if (checkIfATileIsSolidAndSameMaterial(tl, lr, "Chaotic Stone")) then
--
--    savseed = the randomSeed
--    the randomSeed = SeedOfTile(tl)
--    rtrn = false
--
--    if (random(3)>1) then
--      rtrn = true
--      repeat with dir in [point(1,0), point(0,1), point(1,1)] then
--     --   if(IsTileADoubleInChaoticStone(tl-dir, lr)) then return false
--        if (checkIfATileIsSolidAndSameMaterial(tl+dir, lr, "Chaotic Stone") = 0) then
--          rtrn = false
--          break
--        end
--      end
--    end
--
--    the randomSeed = savseed
--    return rtrn
--
--
--  else
--    return false
--  end
--end


function me.checkIfTileHasMaterialRenderTypeTiles(tl, lr)
  local retrn = 0

  if tobool(me.checkIfATileIsSolidAndSameMaterial(tl, lr, "Chaotic Stone")) or tobool(me.checkIfATileIsSolidAndSameMaterial(tl, lr, "Tiled Stone")) then
    retrn = 1
  end

  return retrn
end

function me.renderHarvesterDetails(q, c, l, tl, frntImg, dt)
  -- local spelrelaterat = require('spelrelaterat')
  -- local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))

  local big = (dt[2] == "Harvester B")
  -- put dt[2] .... big
  print(dt[2] .. ' ' .. big)

  local letter
  local eyePoint
  local armPoint

  local lowerPartPos

  if (big) then
    letter = "B"
    mdPnt.x = mdPnt.x + 10
    eyePoint = point(75, -126)
    armPoint = point(105, 108)
  else
    letter = "A"
    eyePoint = point(37, -85)
    armPoint = point(58, 60)
  end

  local actualQ = q + gRenderCameraTilePos.x
  local actualC = c + gRenderCameraTilePos.y
  local lowerPart = point(0, 0)

  for h = actualC, #gTEProps.tlMatrix[actualQ] do
    if (gTEProps.tlMatrix[actualQ][h][l].tp == "tileHead") then
      if (gTEProps.tlMatrix[actualQ][h][l].data[2] == "Harvester Arm " .. letter) then
        lowerPart = point(q, h - gRenderCameraTilePos.y)
      end
    end
  end

  if (lowerPart ~= point(0, 0)) then
    lowerPartPos = spelrelaterat.giveMiddleOfTile(lowerPart)
    if big then
      lowerPartPos.x = lowerPartPos.x + 10
    end
  end

  for side = 1, 2 do
    local sideList = { -1, 1 }
    local dr = sideList[side]
    local eyePastePos = mdPnt + point(eyePoint.x * dr, eyePoint.y)
    local mem = member("Harvester" .. letter .. "Eye")
    local qd = spelrelaterat.rotateToQuad(
    rect(eyePastePos, eyePastePos) + rect(-mem.width / 2, -mem.height / 2, mem.width / 2, mem.height / 2), random(360))

    for dpth = ((l - 1) * 10) + 3, ((l - 1) * 10) + 6 do
      member("layer" .. dpth).image:copyPixels(mem.image, qd, mem.image.rect, { ink = 36, color = color(0, 255, 0) })
    end
  end
end

function me.renderBeveledImage(img, dp, qd, bevel)
  local boundrect = rect(10000, 10000, -10000, -10000)
  local mrgn = 10

  for _, pnt in ipairs(qd) do
    if (pnt.x - mrgn < boundrect.left) then
      boundrect.left = pnt.x - mrgn
    end
    if (pnt.x + mrgn > boundrect.right) then
      boundrect.right = pnt.x + mrgn
    end
    if (pnt.y - mrgn < boundrect.top) then
      boundrect.top = pnt.y - mrgn
    end
    if (pnt.y + mrgn > boundrect.bottom) then
      boundrect.bottom = pnt.y + mrgn
    end
  end

  -- local qdOffset = {point(boundrect.left, boundrect.top),point(boundrect.left, boundrect.top),point(boundrect.left, boundrect.top),point(boundrect.left, boundrect.top)}

  local dumpImg = image(boundrect.width, boundrect.height)  -- 1
  dumpImg:copyPixels(img, quad(qd) - point(boundrect.left, boundrect.top), img.rect)
  local inverseImg = spelrelaterat.makeSilhoutteFromImg(dumpImg, 1)


  dumpImg = image(boundrect.width, boundrect.width)  -- 32
  dumpImg:copyPixels(member("pxl").image, dumpImg.rect, rect(0, 0, 1, 1), { color = color(0, 255, 0) })

  --  member("HEJHEJ").image = inverseImg
  for b = 1, bevel do
    for _, a in ipairs({ { color(255, 0, 0), point(-1, -1) }, { color(255, 0, 0), point(0, -1) }, { color(255, 0, 0), point(-1, 0) }, { color(0, 0, 255), point(1, 1) }, { color(0, 0, 255), point(0, 1) }, { color(0, 0, 255), point(1, 0) } }) do
      dumpImg:copyPixels(inverseImg, dumpImg.rect + rect(a[2] * b, a[2] * b), inverseImg.rect, { color = a[1], ink = 36 })
    end
  end

  dumpImg:copyPixels(inverseImg, dumpImg.rect, inverseImg.rect, { color = color(255, 255, 255), ink = 36 })

  -- inverseImg = image( dumpImg.width,  dumpImg.height, 1)
  -- inverseImg:copyPixels(member("pxl").image, inverseImg.rect, rect(0,0,1,1))
  -- inverseImg:copyPixels(member("pxl").image, inverseImg.rect, rect(0,0,1,1), {color=color(255, 255, 255)})

  -- dumpImg:copyPixels(inverseImg, dumpImg.rect, inverseImg.rect, {color=color(255, 255, 255), ink=36})

  member("layer" .. tostring(dp)).image:copyPixels(dumpImg, boundrect, dumpImg.rect, { ink = 36 })
end

return me
