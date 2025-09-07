-- The name of this abject matters not.
-- The modules are named after their respective files.

local Module = {}

function Module.exitFrame()
  local utils = require('comEditorUtils')

  DRPxl = member("pxl").image
  DRPxlRect = DRPxl.rect
  DRWhite = color(255, 255, 255)
  slimeFxt = utils.getBoolConfig("Slime always affects editor decals")
  DRDarkSlimeFix = utils.getBoolConfig("Dark Slime fix")
  gRRSpreadsMore = utils.getBoolConfig("Rough Rock spreads more")
  grimeActive = utils.getBoolConfig("Grime")
  grimeOnGradients = utils.getBoolConfig("Grime on gradients")
  bkgFix = utils.getBoolConfig("Gradients with BackgroundScenes fix")
  gDRMatFixes = utils.getBoolConfig("Material fixes")
  gDRInvI = utils.getBoolConfig("Invisible material fix")
  member("blackOutImg1").image = image(1, 1)
  member("blackOutImg2").image = image(1, 1)
  member("GradientOutput").image = image(1, 1)

  if utils.checkMinimize() then
    _player.appMinimize()
  end

  if utils.checkExit() then
    _player.quit()
  end

  if utils.checkExitRender() then
    _movie.go(9)
  end

  print("Start render")

  gLOprops.pal = 1

  firstCamRepeat = true
  gCurrentRenderCamera = 0
  gAnyDecals = 0
  Module.createShortCuts()
  tileSetIndex = list()
  solidMtrx = list()

  ---@type table
  local nonSolidTileSets

  if (utils.getBoolConfig("Trash and Small pipes non solid")) then
    nonSolidTileSets = list({ "Small Pipes", "Trash" }) --"Invisible"
  else
    nonSolidTileSets = list()
  end
  if (gDRInvI == false) then
    nonSolidTileSets:add("Invisible")
  end

  for q = 1, gLOprops.size.x do
    local l = list()

    for c = 1, gLOprops.size.y do
      local cell = list()

      for d = 1, 3 do
        local ad = false
        if (gLEProps.matrix[q][c][d][1] == 1) and (getPos(gLEProps.matrix[q][c][d][2], 11) == 0) then
          local tl = gTEprops.tlMatrix[q][c][d]
          if (tl.tp == "default") or (tl.tp == "material") then
            local testMat = tl.data
            if tl.tp == "default" then
              testMat = gTEprops.defaultMaterial
            end
            --            if testMat = "small pipes" then
            --              put (nonSolidTileSets.getPos(testMat)=0)
            --              put (nonSolidTileSets.getPos(testMat)=0)
            --            end if
            ad = (nonSolidTileSets:getPos(testMat) == 0)
          elseif (tl.tp == "tileHead") or (tl.tp == "tileBody") then
            local tlPs = tl.data[1]
            if tl.tp == "tileBody" then
              tlPs = nil
              if (tl.data[1].y > 0) and (tl.data[1].x > 0) and (tl.data[1].y < gLOprops.size.y) and (tl.data[1].x < gLOprops.size.x) then
                if type(gTEprops.tlMatrix[tl.data[1].x][tl.data[1].y][tl.data[2]].data) == "table" then
                  tlPs = gTEprops.tlMatrix[tl.data[1].x][tl.data[1].y][tl.data[2]].data[1]
                end
              end
            end
            ad = true

            if (tlPs ~= nil) then
              if (tlPs.x > 2) and (tlPs.x <= #gTiles) then
                if tlPs.y <= #gTiles[tlPs.x].tls then
                  if gTiles[tlPs.x].tls[tlPs.y].tags ~= nil then
                    ad = (gTiles[tlPs.x].tls[tlPs.y].tags:getPos("nonSolid") == 0)
                  end
                end
              end
            end

            -- put "added" && (gTiles[tlPs.x].tls[tlPs.y].tags.getPos("nonSolid")=0) && "to solidmatrix from tile" && gTiles[tlPs.x].tls[tlPs.y].nm
          end
        end

        cell:add(ad)
      end
      -- l.add([(gLEProps.matrix[q][c][1][1] = 1), (gLEProps.matrix[q][c][2][1] = 1), (gLEProps.matrix[q][c][3][1] = 1)])
      l:add(cell)
    end
    solidMtrx:add(l)
  end
end

function Module.createShortCuts()
  ---@class gShortcuts
  ---@field scs string[]
  ---@field indexL point[]
  gShortcuts = { scs = list(), indexL = list() }

  for q = 2, #gLEProps.matrix - 1 do
    for c = 2, #gLEProps.matrix[1] - 1 do
      if getPos(gLEProps.matrix[q][c][1][2], 4) > 0 then
        local didItWork = true
        local tp = "shortCut"

        local holeDir = point(0, 0)

        local stps = 0
        local pos = point(q, c)
        local stp = false
        local lastDir = point(0, 0)
        local rpt = 0

        local dirsL
        repeat
          rpt = rpt + 1
          
          if rpt > 1000 then
            didItWork = false
            stp = true
          end

          dirsL = list({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) })
          dirsL:deleteOne(lastDir)
          dirsL:addAt(1, lastDir)
          dirsL:deleteOne(-lastDir)

          for _, dir in ipairs(dirsL) do
            if (pos + dir):inside(rect(1, 1, gLOprops.size.x + 1, gLOprops.size.y + 1)) then
              if getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 6) > 0 then
                stp = true
                tp = "playerHole"
                pos = point(q, c)

                -- put point(q,c) && "dsgfsd"
                lastDir = dir
                break
              elseif getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 7) > 0 then
                stp = true
                tp = "lizardHole"
                pos = point(q, c)
                lastDir = dir
                break
              elseif getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 19) > 0 then
                stp = true
                tp = "WHAMH"
                pos = point(q, c)
                lastDir = dir
                break
              elseif getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 21) > 0 then
                stp = true
                tp = "scavengerHole"
                pos = point(q, c)
                lastDir = dir
                break
              elseif getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 4) > 0 then
                stp = true
                pos = pos + dir
                lastDir = dir

                break
              elseif getPos(gLEProps.matrix[pos.x + dir.x][pos.y + dir.y][1][2], 5) > 0 then
                stps = stps + 1
                pos = pos + dir
                lastDir = dir
                break
              end
            end
          end

          if holeDir == point(0, 0) then
            holeDir = lastDir
          end
        until stp

        if didItWork then
          gShortcuts.indexL:add(point(q, c))
          gShortcuts.scs:add(tp)
        end
      end
    end
  end
end

return Module
