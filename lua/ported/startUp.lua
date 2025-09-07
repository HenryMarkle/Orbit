local m = {}

function m.exitFrame()
  local utils = require("comEditorUtils")
  local utils2 = require("spelrelaterat")

  gVersion = "V.0.4.63"

  local hadException = 0

  --  clearAsObjects()
  --  clearCache
  --  _global.clearGlobals()
  --  _movie.halt()

  -- Load config
  member("editorConfig").text = ""
  member("editorConfig"):importFileInto("editorConfig.txt")
  if (not utils.checkIsDrizzleRendering()) and ((member("editorConfig").text == nil) or (member("editorConfig").text == "") or not (atLine(member("editorConfig").text, 1) == atLine(member("baseConfig").text, 1))) then
    -- local fileCo = xtra("fileio")
    -- fileCo.createFile(moviePath .. "editorConfig.txt")
    -- fileCo.openFile(moviePath .. "editorConfig.txt", 0)
    -- fileCo.writeString(member("baseConfig").text)
    -- fileCo.writeReturn("windows")

    local f = io.open(moviePath .. "editorConfig.txt", "w")
    if f then
      f:write(member("baseConfig").text .. "\r\n")
      f:close()
    else
      print('Warning: fileCo at editorConfig failed to open')
    end

    member("editorConfig").text = member("baseConfig").text
    _movie.go(1)
    return
  end

  
  -- Global var init
  utils.clearLogs()
  if utils.checkMinimize() then
    _player.appMinimize()
  end
  _global.clearGlobals()

  _movie.exitLock = TRUE
  local lvlPropOutput = FALSE
  utils.initDRInternal()
  gFullRender = 1
  gViewRender = 1 - toint(utils.getBoolConfig("Fast render"))
  local DRLastTL = 1
  gMassRenderL = list()
  gLOADPATH = list()
  gLEVEL = map({
    timeLimit = 4800,
    defaultTerrain = 1,
    maxFlies = 10,
    flySpawnRate = 50,
    lizards = list(),
    ambientSounds =
        list(),
    music = "NONE",
    tags = list(),
    lightType = "Static",
    waterDrips = 1,
    lightRect = rect(0, 0, 1040, 800),
    matrix =
        list()
  })


  _movie.window.appearanceOptions.border = "none"
  _movie.window.resizable = FALSE

  gLoadedName = "New Project"
  member("level Name").text = "New Project"

  gImgXtra = xtra("ImgXtra")

  local g = 21

  -- Dead branch
  if (g == 2) then
    -- gSaveProps = list({ baScreenInfo("width"), baScreenInfo("height"), baScreenInfo("depth") })

    -- local fac = gSaveProps[1] / gSaveProps[2]

    -- local screenResolutionPoint = _system.deskTopRectList

    -- -- not implemented apparently
    -- -- baSetDisplay(screenResolutionPoint.locH, screenResolutionPoint.locV, 32, "temp", false)

    -- local screenSize = _system.deskTopRectList / 2

    -- local midPos = screenResolutionPoint / 2
    -- local windowRect = rect(midPos - screenSize, midPos + screenSize)
    -- _movie.window.rect = windowRect
    -- _movie.stage.drawRect = windowRect
  else
    gSaveProps = list({ 1, 1, 1 })
  end

  local solidMtrx = list()

  -- Load keybinds
  --global gCustomKeybinds, GL_keyDict
  gCustomKeybinds = 0
  GL_keyDict = nil

  if utils.getBoolConfig("Custom keybinds") and utils.checkIsDrizzleRendering() then
    member("editorKeybinds").text = ""
    member("editorKeybinds"):importFileInto("editorKeybinds.txt")
    if member("editorKeybinds").text and not (member("editorKeybinds").text == "") then
      utils.initCustomKeybindThings()
      local keyFL = member("editorKeybinds")
      for ln = 1, numberOfLines(keyFL.text) do
        local lin = atLine(keyFL.text, ln)
        local offst = offset(" = ", lin)
        if (offst > 0) then
          utils.registerCustomKeybind(string.sub(lin, 1, offst - 1), string.sub(lin, offst + 3))
        end
      end
      table.sort(GL_keyDict)
    end
  end



  -- LEVELEDITOR!!!!!
  local cols = 72 --gLOprops.size.loch
  local rows = 43 --gLOprops.size.locv

  ---@class gLEProps
  ---@field matrix {[1]: number, [2]: number[]}[][]
  ---@field levelEditors table
  ---@field toolMatrix string[]
  ---@field camPos point
  
  ---Geometry matrix
  ---@type gLEProps
  gLEProps = map({ matrix = list(), levelEditors = list(), toolMatrix = list(), camPos = point(0, 0) })

  table.insert(gLEProps.toolMatrix, list({ "inverse", "paintWall", "paintAir", "slope" }))
  table.insert(gLEProps.toolMatrix, list({ "floor", "squareWall", "squareAir", "move" }))
  table.insert(gLEProps.toolMatrix, list({ "rock", "spear", "crack", "" }))
  table.insert(gLEProps.toolMatrix, list({ "horBeam", "verBeam", "glass", "copyBack" }))
  table.insert(gLEProps.toolMatrix, list({ "shortCutEntrance", "shortCut", "lizardHole", "playerSpawn" }))
  table.insert(gLEProps.toolMatrix, list({ "forbidbats", "", "hive", "waterFall" }))
  table.insert(gLEProps.toolMatrix, list({ "scavengerHole", "WHAMH", "garbageHole", "wormGrass" }))
  table.insert(gLEProps.toolMatrix, list({ "workLayer", "flip", "mirrorToggle", "setMirrorPoint" }))

  utils2.ResetgEnvEditorProps()
  for q = 1, cols do
    local ql = list()
    for c = 1, rows do
      ql:add(list({ { 1, list() }, { 1, list() }, { 0, list() } }))
    end
    gLEProps.matrix:add(ql)
  end

  --TILEEDITOR!!!

  gTEProps = map({
    lastKeys = list(),
    keys = list(),
    workLayer = 1,
    lstMsPs = point(0, 0),
    tlMatrix = list(),
    defaultMaterial =
    "Concrete",
    toolType = "material",
    toolData = "Big Metal",
    tmPos = point(1, 1),
    tmSavPosL = list(),
    specialEdit = 0
  })

  for q = 1, cols do
    local l = list()
    for c = 1, rows do
      l:add(map({ map({ tp = "default", data = 0 }), map({ tp = "default", data = 0 }), map({ tp = "default", data = 0 }) }))
    end
    gTEProps.tlMatrix:add(l)
  end
  member("layerText").text = "Layer=1"

  gTiles = list()

  --CAT CHANGE
  gTiles:add(map({ nm = "Materials", tls = list() }))
  local tilesInCat = gTiles[1].tls
  tilesInCat:add({
    nm = "Standard",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(150, 150,
      150)
  })
  tilesInCat:add({
    nm = "Concrete",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(150, 255,
      255)
  })
  tilesInCat:add({
    nm = "RainStone",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(0, 0,
      255)
  })
  tilesInCat:add({
    nm = "Bricks",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(200, 150,
      100)
  })
  tilesInCat:add({
    nm = "BigMetal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(255, 0,
      0)
  })
  tilesInCat:add({
    nm = "Tiny Signs",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(255,
      200, 255)
  })
  tilesInCat:add({
    nm = "Scaffolding",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(60,
      60, 40)
  })
  tilesInCat:add({
    nm = "Dense Pipes",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "densePipeType",
    color = color(
      0, 0, 150)
  })
  tilesInCat:add({
    nm = "SuperStructure",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      160, 180, 255)
  })
  tilesInCat:add({
    nm = "SuperStructure2",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      190, 160, 0)
  })
  tilesInCat:add({
    nm = "Tiled Stone",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(100, 0,
      255)
  })
  tilesInCat:add({
    nm = "Chaotic Stone",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(255,
      0, 255)
  })
  tilesInCat:add({
    nm = "Small Pipes",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "pipeType",
    color = color(255,
      255, 0)
  })
  tilesInCat:add({ nm = "Trash", sz = point(1, 1), specs = list({ 0 }), renderType = "pipeType", color = color(90, 255, 0) })
  tilesInCat:add({
    nm = "Invisible",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "invisibleI",
    color = color(200,
      200, 200)
  })
  tilesInCat:add({
    nm = "LargeTrash",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "largeTrashType",
    color = color(
      175, 30, 255)
  })
  tilesInCat:add({
    nm = "3DBricks",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(255, 150,
      0)
  })
  tilesInCat:add({
    nm = "Random Machines",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(72,
      116, 80)
  })
  tilesInCat:add({ nm = "Dirt", sz = point(1, 1), specs = list({ 0 }), renderType = "dirtType", color = color(124, 72, 52) })
  tilesInCat:add({
    nm = "Ceramic Tile",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "ceramicType",
    color = color(
      60, 60, 100)
  })
  tilesInCat:add({
    nm = "Temple Stone",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(0, 120,
      180)
  })
  tilesInCat:add({
    nm = "Circuits",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "densePipeType",
    color = color(0,
      150, 0)
  })
  tilesInCat:add({
    nm = "Ridge",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "ridgeType",
    color = color(200, 15,
      60)
  })

  gTiles:add(map({ nm = "LB Materials", tls = list() }))
  tilesInCat = gTiles[2].tls
  tilesInCat:add({
    nm = "Steel",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(220, 170,
      195)
  })
  tilesInCat:add({ nm = "4Mosaic", sz = point(1, 1), specs = list({ 0 }), renderType = "tiles", color = color(227, 76, 13) })
  tilesInCat:add({
    nm = "Color A Ceramic",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "ceramicAType",
    color =
        color(120, 0, 90)
  })
  tilesInCat:add({
    nm = "Color B Ceramic",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "ceramicBType",
    color =
        color(0, 175, 175)
  })
  tilesInCat:add({
    nm = "Random Pipes",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "randomPipesType",
    color =
        color(80, 0, 140)
  })
  tilesInCat:add({
    nm = "Rocks",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "rockType",
    color = color(185, 200,
      0)
  })
  tilesInCat:add({
    nm = "Rough Rock",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "roughRock",
    color = color(155,
      170, 0)
  })
  tilesInCat:add({
    nm = "Random Metal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(180,
      10, 10)
  })
  tilesInCat:add({ nm = "Cliff", sz = point(1, 1), specs = list({ 0 }), renderType = "unified", color = color(75, 75, 75) })
  tilesInCat:add({
    nm = "Non-Slip Metal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      180, 80, 80)
  })
  tilesInCat:add({
    nm = "Stained Glass",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      180, 80, 180)
  })
  tilesInCat:add({
    nm = "Sandy Dirt",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "sandy",
    color = color(180, 180,
      80)
  })
  tilesInCat:add({
    nm = "MegaTrash",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "megaTrashType",
    color = color(
      135, 10, 255)
  })
  tilesInCat:add({
    nm = "Shallow Dense Pipes",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "densePipeType",
    color =
        color(13, 23, 110)
  })
  tilesInCat:add({
    nm = "Sheet Metal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "wv",
    color = color(145, 135,
      125)
  })
  tilesInCat:add({
    nm = "Chaotic Stone 2",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(90,
      90, 90)
  })
  tilesInCat:add({
    nm = "Asphalt",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(115, 115,
      115)
  })

  gTiles:add(map({ nm = "Community Materials", tls = list() }))
  tilesInCat = gTiles[3].tls
  tilesInCat:add({
    nm = "Shallow Circuits",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "densePipeType",
    color =
        color(15, 200, 155)
  })
  tilesInCat:add({
    nm = "Random Machines 2",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(
      116, 116, 80)
  })
  tilesInCat:add({
    nm = "Small Machines",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(80,
      116, 116)
  })
  tilesInCat:add({
    nm = "Random Metals",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(255,
      0, 80)
  })
  tilesInCat:add({
    nm = "ElectricMetal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      255, 0, 100)
  })
  tilesInCat:add({
    nm = "Grate",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(190, 50,
      190)
  })
  tilesInCat:add({
    nm = "CageGrate",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(50, 190,
      190)
  })
  tilesInCat:add({
    nm = "BulkMetal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(50, 19,
      190)
  })
  tilesInCat:add({
    nm = "MassiveBulkMetal",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "unified",
    color = color(
      255, 19, 19)
  })
  tilesInCat:add({
    nm = "Dune Sand",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(255, 255,
      100)
  })
  tilesInCat:add({
    nm = "Chaotic Greeble",
    sz = point(1, 1),
    specs = list({ 0 }),
    renderType = "tiles",
    color = color(
      100, 100, 100)
  })

  local savLM = member("matInit")
  member("matInit"):importFileInto("Materials" .. dirSeparator .. "Init.txt")
  savLM.name = "matInit"
  DRCustomMatList = list()
  if savLM and savLM.text and not (savLM.text == "") then
    for ln = 1, numberOfLines(savLM.text) do
      local lin = atLine(savLM.text, ln)
      if not (lin == "") then
        if (atChar(lin, 1) == "-") then
          gTiles:add(map({ nm = string.sub(lin, 2), tls = list() }))
          local efLn = ln + 1

          while efLn <= numberOfLines(savLM.text) do
            local efLin = atLine(savLM.text, efLn)
            if (atChar(efLin, 1) == "-") then
              break
            elseif not (efLin == "") then
              local gtlCnt = gTiles[#gTiles]
              gtlCnt.tls:add(fromLingo(efLin))
              local matTl = gtlCnt.tls[#gtlCnt.tls]
              matTl["sz"] = point(1, 1)
              matTl["specs"] = list({ 0 })
              if matTl["autofit"] then
                matTl["renderType"] = "customAutofit"
              else
                matTl["renderType"] = "customUnified"
              end

              DRCustomMatList:add(matTl)

              -- Deal with autofit material
              if (matTl["renderType"] == "customAutofit") then
                local afMat = member("initImport")
                afMat.text = ""
                member("initImport"):importFileInto("Materials" .. dirSeparator .. matTl.nm .. ".txt")
                afMat.name = "initImport"

                -- Make sure parts are correct
                if (type(matTl.autofit) ~= "table") then
                  matTl.autofit = map()
                end
                if (not matTl.autofit:findPos("categories")) then
                  matTl.autofit["categories"] = list()
                end
                if (not matTl.autofit:findPos("tiles")) then
                  matTl.autofit["tiles"] = list()
                end
                if (not matTl.autofit:findPos("ignoreTiles")) then
                  matTl.autofit["ignoreTiles"] = list()
                end

                -- Import information
                local importPart = 2 -- tiles by default
                for matLnNo = 1, numberOfLines(afMat.text) do
                  local matLn = atLine(afMat.text, matLnNo)
                  if (matLn == "-Categories") then
                    importPart = 1
                  elseif (matLn == "-Tiles") then
                    importPart = 2
                  elseif (matLn == "-Ignore Tiles") then
                    importPart = 3
                  elseif not (matLn == "") then
                    if (importPart == 1) then
                      table.insert(matTl.autofit.categories, matLn)
                    elseif (importPart == 2) then
                      table.insert(matTl.autofit.tiles, matLn)
                    elseif (importPart == 3) then
                      table.insert(matTl.autofit.ignoreTiles, matLn)
                    end
                  end
                end
              end
            end
            efLn = efLn + 1
          end
          ln = efLn - 1
        end
      end
    end

    if (#gTiles >= 1) then
      for del = 1, #gTiles do
        if (#gTiles[del].tls < 1) then
          gTiles:deleteAt(del)
        end
      end
    end
  end


  utils.setLastMatCat(#gTiles)

  gTiles:add(map({ nm = "Special", tls = list() }))
  tilesInCat = gTiles[#gTiles].tls
  tilesInCat:add({
    nm = "Rect Clear",
    sz = point(1, 1),
    specs = list({ 0 }),
    placeMethod = "rect",
    color = color(255, 0,
      0)
  })
  tilesInCat:add({
    nm = "SH pattern box",
    sz = point(1, 1),
    specs = list({ 0 }),
    placeMethod = "rect",
    color = color(210,
      0, 255)
  })
  tilesInCat:add({
    nm = "SH grate box",
    sz = point(1, 1),
    specs = list({ 0 }),
    placeMethod = "rect",
    color = color(160, 0,
      255)
  })
  -- LB
  tilesInCat:add({
    nm = "Alt Grate Box",
    sz = point(1, 1),
    specs = list({ 0 }),
    placeMethod = "rect",
    color = color(75,
      75, 240)
  })
  -- Alduris
  tilesInCat:add({
    nm = "Ventbox Rect",
    sz = point(1, 1),
    specs = list({ 0 }),
    placeMethod = "rect",
    color = color(0, 0,
      255)
  })
  utils.setFirstTileCat(#gTiles + 1)


  local sav = member("initImport")
  sav.text = ""
  member("initImport"):importFileInto("Graphics" .. dirSeparator .. "Init.txt")
  sav.text = sav.text .. RETURN .. RETURN .. member("Drought Needed Init").text
  sav.name = "initImport"

  member("previewTiles").image = image(60000, 500)
  GL_ptPos = 1
  member("previewTilesDR").image = image(1, 1)
  GL_drPos = 1

  if (utils.getBoolConfig("More tile previews")) then
    member("previewTilesDR").image = image(60000, 500)
  end

  for q = 1, numberOfLines(sav.text) do
    local savTextLine = atLine(sav.text, q)
    if (savTextLine ~= "") then
      if (atChar(savTextLine, 1) == "-") then
        local vl = fromLingo(string.sub(savTextLine, 2))
        if (vl == nil) then
          utils.writeException("Tile Init Error",
            "Line " ..
            ' ' .. q .. ' ' .. " is malformed in the Init.txt file from your Graphics folder. (" .. savTextLine .. ")")
          hadException = 1
        else
          gTiles:add(map({ nm = vl[1], clr = vl[2], tls = list() }))
        end
      elseif (fromLingo(savTextLine) == nil) then
        utils.writeException("Tile Init Error",
          "Line " ..
          ' ' .. q .. ' ' .. " is malformed in the Init.txt file from your Graphics folder. (" .. savTextLine .. ")")
        hadException = 1
      else
        -- Here is where it normally would have added the tile to the preview. That is extremely slow so we just straight up don't do that =3
        local ad = map(fromLingo(savTextLine))
        

        ad.tags = list(ad.tags)
        ad["ptPos"] = 0
        if (ad.tags:getPos("notTile") == 0) then
          gTiles[#gTiles].tls:add(ad)
        end
      end
    end
  end

  altGrafLG = "1"
  
  ---@type {nm:string, clr:color, prps:table}[]
  gProps = list()

  utils2.resetPropEditorProps()

  gPEcolors = list()
  sav = member("initImport")
  member("initImport"):importFileInto("Props" .. dirSeparator .. "propColors.txt")
  sav.name = "initImport"
  for q = 1, numberOfLines(sav.text) do
    if not (atLine(sav.text, q) == "") then
      gPEcolors:add(fromLingo(atLine(sav.text, q)))
    end
  end

  sav = member("initImport")
  member("initImport"):importFileInto("Props" .. dirSeparator .. "Init.txt")
  sav.name = "initImport"

  for q = 1, 1000 do ---- PJB fix 2000 --> 1000
    castLib(2):eraseMembers()
  end

  for q = 1, numberOfLines(sav.text) do
    local savTextLine = atLine(sav.text, q)
    if not (savTextLine == "") then
      -- print(savTextLine)
      if (atChar(savTextLine, 1) == "-") then
        local vl = fromLingo(string.sub(savTextLine, 2))
        
        if (vl == nil) then
          utils.writeException("Prop Init Error",
            "Line " ..
            ' ' .. q .. ' ' .. " is malformed in the Init.txt file from your Props folder. (" .. savTextLine .. ")")
          hadException = 1
        else
          gProps:add(map({ nm = vl[1], clr = vl[2], prps = list() }))
        end
      elseif (fromLingo(savTextLine) == nil) then
        utils.writeException("Prop Init Error",
          "Line " .. ' ' ..
          q .. ' ' .. " is malformed in the Init.txt file from your Props folder. (" .. savTextLine .. ")")
        hadException = 1
      else
        local ad = map(fromLingo(savTextLine))
        ad:addProp("category", #gProps)
        if (ad.tp == "standard") or (ad.tp == "variedStandard") then
          local dp = 0

          for i = 1, #ad.repeatL do
            dp = dp + ad.repeatL[i]
          end
          ad:addProp("depth", dp)
        end
        
        table.insert(gProps[#gProps].prps, ad)
      end
    end
  end

  gPageCount = 0
  gPageTick = 0

  --CAT CHANGE
  local rndDisF = utils.getBoolConfig("voxelStructRandomDisplace for tiles as props")
  local tAsPFixes = utils.getBoolConfig("Tiles as props fixes")
  for q = utils.getFirstTileCat(), #gTiles do
    gPageTick = 0
    for c = 1, #gTiles[q].tls do
      --if gPageTick = 0 then
      --  gPageTick = 21
      --  gPageCount = gPageCount + 1
      --  gProps:add([nm="Tiles as props " .. gPageCount, clr=color(255, 0,0), prps=[]])
      --end
      local tl = gTiles[q].tls[c]
      if ((tl.tp == "voxelStruct") or (tl.tp == "voxelStructRockType") or (tl.tp == "voxelStructRandomDisplaceVertical" and tobool(rndDisF)) or (tl.tp == "voxelStructRandomDisplaceHorizontal" and tobool(rndDisF))) and (list(tl.tags):getPos("notProp") == 0) then
        --Ugly part Ik (I made it less ugly -Alduris)
        local tlTags = list({ "Tile" })
        local noFixTags = list({ "Tile" })

        if (tl.tp == "voxelStructRockType") then
          table.insert(tlTags, "rockType")
          table.insert(noFixTags, "rockType")
        end
        if (list(tl.tags):getPos("notMegaTrashProp") > 0) then
          table.insert(tlTags, "notMegaTrashProp")
          table.insert(noFixTags, "notMegaTrashProp")
        end

        if (tl.tags:getPos("effectColorA") > 0) then
          table.insert(tlTags, "effectColorA")
        end

        if (tl.tags:getPos("effectColorB") > 0) then
          table.insert(tlTags, "effectColorB")
        end
        if (tl.tags:getPos("colored") > 0) then
          table.insert(tlTags, "colored")
        end
        if (tl.tags:getPos("customColor") > 0) then
          table.insert(tlTags, "customColor")
        end
        if (tl.tags:getPos("customColorRainbow") > 0) then tlTags:append("customColorRainbow") end
        if (tl.tags:getPos("randomRotat") > 0) then tlTags:append("randomRotat") end
        if (tl.tags:getPos("randomFlipX") > 0) then tlTags:append("randomFlipX") end
        if (tl.tags:getPos("randomFlipY") > 0) then tlTags:append("randomFlipY") end
        if (tl.tags:getPos("Circular Sign") > 0) then tlTags:append("Circular Sign") end
        if (tl.tags:getPos("Circular Sign B") > 0) then tlTags:append("Circular Sign B") end
        if (tl.tags:getPos("Larger Sign") > 0) then tlTags:append("Larger Sign") end
        if (tl.tags:getPos("Larger Sign B") > 0) then tlTags:append("Larger Sign B") end
        if (tl.tags:getPos("notTrashProp") > 0) then
          tlTags:append("notTrashProp")
          noFixTags:append("notTrashProp")
        end
        if (tl.tags:getPos("INTERNAL") > 0) then
          -- tlTags:append("INTERNAL")
          -- noFixTags:append("INTERNAL")
          table.insert(tlTags, "INTERNAL")
          table.insert(noFixTags, "INTERNAL")
        end
        --End ugly part
        local repeatL
        if (tl.tp == "voxelStructRockType") then
          local repLen = 0
          if type(tl.specs2) == "table" then repLen = #tl.specs2 end

          -- repeatL = list({ 10 + toint(not (#tl.specs2 == 0)) * 10 })
          repeatL = list({ 10 + repLen * 10 })
        else
          repeatL = tl.repeatL
        end

        local ad

        local repLen = 0
        if type(tl.specs2) == "table" then repLen = #tl.specs2 end

        if (tAsPFixes) then
          if (tl.rnd > 1) then
            ad = map({
              nm = tl.nm,
              tp = "variedStandard",
              colorTreatment = "standard",
              sz = tl.sz +
                  point(tl.bfTiles * 2, tl.bfTiles * 2),
              -- depth = 10 + toint(not (#tl.specs2 == 0)) * 10,
              depth = 10 + repLen * 10,
              repeatL = repeatL,
              vars =
                  tl.rnd,
              random = 1,
              tags = tlTags,
              layerExceptions = list({}),
              notes = list({ "Tile as prop" })
            })
          else
            ad = map({
              nm = tl.nm,
              tp = "standard",
              colorTreatment = "standard",
              sz = tl.sz +
                  point(tl.bfTiles * 2, tl.bfTiles * 2),
              -- depth = 10 + toint(not (#tl.specs2 == 0)) * 10,
              depth = 10 + repLen * 10,
              repeatL = repeatL,
              tags =
                  tlTags,
              layerExceptions = list(),
              notes = list({ "Tile as prop" })
            })
          end
        else
          ad = map({
            nm = tl.nm,
            tp = "standard",
            colorTreatment = "standard",
            sz = tl.sz +
                point(tl.bfTiles * 2, tl.bfTiles * 2),
            -- depth = 10 + toint(not ((#tl.specs2 == 0))) * 10,
            depth = 10 + repLen * 10,
            repeatL = repeatL,
            tags =
                noFixTags,
            layerExceptions = list(),
            notes = list({ "Tile as prop" })
          })
        end

        if gPageTick == 0 then
          gProps:add(map({ nm = gTiles[q].nm, clr = color(255, 0, 0), prps = list() }))
        end

        ad:addProp("category", #gProps)
        gProps[#gProps].prps:add(ad)
        gPageTick = gPageTick - 1
      end
    end
  end

  for prq = 1, #gProps do
    if (#gProps[prq].prps <= 0) then
      gProps:deleteAt(prq)
    end
  end

  gProps:add(map({ nm = "Rope type props", clr = color(0, 255, 0), prps = list() }))
  local propsInCat = gProps[#gProps].prps
  propsInCat:add(map({
    nm = "Wire",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 3,
    collisionDepth = 0,
    segRad = 1,
    grav = 0.5,
    friction = 0.5,
    airFric = 0.9,
    stiff = 0,
    previewColor =
        color(255, 0, 0),
    previewEvery = 4,
    edgeDirection = 0,
    rigid = 0,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Tube",
    tp = "rope",
    depth = 4,
    tags = list(),
    notes = list(),
    segmentLength = 10,
    collisionDepth = 2,
    segRad = 4.5,
    grav = 0.5,
    friction = 0.5,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(0, 0, 255),
    previewEvery = 2,
    edgeDirection = 5,
    rigid = 1.6,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "ThickWire",
    tp = "rope",
    depth = 3,
    tags = list(),
    notes = list(),
    segmentLength = 4,
    collisionDepth = 1,
    segRad = 2,
    grav = 0.5,
    friction = 0.8,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(255, 255, 0),
    previewEvery = 2,
    edgeDirection = 0,
    rigid = 0.2,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "RidgedTube",
    tp = "rope",
    depth = 4,
    tags = list(),
    notes = list(),
    segmentLength = 5,
    collisionDepth = 2,
    segRad = 5,
    grav = 0.5,
    friction = 0.3,
    airFric = 0.7,
    stiff = 1,
    previewColor =
        color(255, 0, 255),
    previewEvery = 2,
    edgeDirection = 0,
    rigid = 0.1,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Fuel Hose",
    tp = "rope",
    depth = 5,
    tags = list(),
    notes = list(),
    segmentLength = 16,
    collisionDepth = 1,
    segRad = 7,
    grav = 0.5,
    friction = 0.8,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(255, 150, 0),
    previewEvery = 1,
    edgeDirection = 1.4,
    rigid = 0.2,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Broken Fuel Hose",
    tp = "rope",
    depth = 6,
    tags = list(),
    notes = list(),
    segmentLength = 16,
    collisionDepth = 1,
    segRad = 7,
    grav = 0.5,
    friction = 0.8,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(255, 150, 0),
    previewEvery = 1,
    edgeDirection = 1.4,
    rigid = 0.2,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Large Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 28,
    collisionDepth = 3,
    segRad = 9.5,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(0, 255, 0),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Large Chain 2",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 28,
    collisionDepth = 3,
    segRad = 9.5,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(20, 205, 0),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Bike Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 38,
    collisionDepth = 3,
    segRad = 16.5,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(100, 100, 100),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 16.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Zero-G Tube",
    tp = "rope",
    depth = 4,
    tags = list(),
    notes = list(),
    segmentLength = 10,
    collisionDepth = 2,
    segRad = 4.5,
    grav = 0,
    friction = 0.5,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(0, 255, 0),
    previewEvery = 2,
    edgeDirection = 0,
    rigid = 0.6,
    selfPush = 2,
    sourcePush = 0.5
  }))
  propsInCat:add(map({
    nm = "Zero-G Wire",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 8,
    collisionDepth = 0,
    segRad = 1,
    grav = 0,
    friction = 0.5,
    airFric = 0.9,
    stiff = 1,
    previewColor =
        color(255, 0, 0),
    previewEvery = 2,
    edgeDirection = 0.3,
    rigid = 0.5,
    selfPush = 1.2,
    sourcePush = 0.5
  }))
  propsInCat:add(map({
    nm = "Fat Hose",
    tp = "rope",
    depth = 6,
    tags = list(),
    notes = list(),
    segmentLength = 40,
    collisionDepth = 3,
    segRad = 20,
    grav = 0.9,
    friction = 0.6,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(0, 100, 150),
    previewEvery = 1,
    edgeDirection = 0.1,
    rigid = 0.2,
    selfPush = 10,
    sourcePush = 0.1
  }))
  propsInCat:add(map({
    nm = "Wire Bunch",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 50,
    collisionDepth = 3,
    segRad = 20,
    grav = 0.9,
    friction = 0.6,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(255, 100, 150),
    previewEvery = 1,
    edgeDirection = 0.1,
    rigid = 0.2,
    selfPush = 10,
    sourcePush = 0.1
  }))
  propsInCat:add(map({
    nm = "Wire Bunch 2",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 50,
    collisionDepth = 3,
    segRad = 20,
    grav = 0.9,
    friction = 0.6,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(255, 100, 150),
    previewEvery = 1,
    edgeDirection = 0.1,
    rigid = 0.2,
    selfPush = 10,
    sourcePush = 0.1
  }))

  gProps:add(map({ nm = "LB Rope Props", clr = color(0, 255, 0), prps = list() }))
  propsInCat = gProps[#gProps].prps
  propsInCat:add(map({
    nm = "Big Big Pipe",
    tp = "rope",
    depth = 6,
    tags = list(),
    notes = list(),
    segmentLength = 40,
    collisionDepth = 3,
    segRad = 20,
    grav = 0.9,
    friction = 0.6,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(50, 150, 210),
    previewEvery = 1,
    edgeDirection = 0.1,
    rigid = 0.2,
    selfPush = 10,
    sourcePush = 0.1
  }))
  propsInCat:add(map({
    nm = "Ring Chain",
    tp = "rope",
    depth = 6,
    tags = list(),
    notes = list(),
    segmentLength = 40,
    collisionDepth = 3,
    segRad = 20,
    grav = 0.9,
    friction = 0.6,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(100, 200, 0),
    previewEvery = 1,
    edgeDirection = 0.1,
    rigid = 0.2,
    selfPush = 10,
    sourcePush = 0.1
  }))
  propsInCat:add(map({
    nm = "Christmas Wire",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 17,
    collisionDepth = 0,
    segRad = 8.5,
    grav = 0.5,
    friction = 0.5,
    airFric = 0.9,
    stiff = 0,
    previewColor =
        color(200, 0, 200),
    previewEvery = 1,
    edgeDirection = 0,
    rigid = 0,
    selfPush = 0,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Ornate Wire",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 17,
    collisionDepth = 0,
    segRad = 8.5,
    grav = 0.5,
    friction = 0.5,
    airFric = 0.9,
    stiff = 0,
    previewColor =
        color(0, 200, 200),
    previewEvery = 1,
    edgeDirection = 0,
    rigid = 0,
    selfPush = 0,
    sourcePush = 0
  }))

  gProps:add(map({ nm = "Alduris Rope Props", clr = color(0, 255, 0), prps = list() }))
  propsInCat = gProps[#gProps].prps
  propsInCat:add(map({
    nm = "Small Chain",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 22,
    collisionDepth = 0,
    segRad = 3,
    grav = 0.5,
    friction = 0.65,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(255, 0, 150),
    previewEvery = 2,
    edgeDirection = 0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Fat Chain",
    tp = "rope",
    depth = 0,
    tags = list(),
    notes = list(),
    segmentLength = 44,
    collisionDepth = 0,
    segRad = 8,
    grav = 0.5,
    friction = 0.65,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(255, 0, 150),
    previewEvery = 2,
    edgeDirection = 0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))

  gProps:add(map({ nm = "Dakras Rope Props", clr = color(0, 255, 0), prps = list() }))
  propsInCat = gProps[#gProps].prps
  propsInCat:add(map({
    nm = "Big Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 56,
    collisionDepth = 3,
    segRad = 19,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(0, 255, 40),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Chunky Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 28,
    collisionDepth = 3,
    segRad = 19,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(0, 255, 40),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 6.5,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Big Bike Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 76,
    collisionDepth = 3,
    segRad = 33,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(100, 150, 100),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 33,
    sourcePush = 0
  }))
  propsInCat:add(map({
    nm = "Huge Bike Chain",
    tp = "rope",
    depth = 9,
    tags = list(),
    notes = list(),
    segmentLength = 152,
    collisionDepth = 3,
    segRad = 66,
    grav = 0.9,
    friction = 0.8,
    airFric = 0.95,
    stiff = 1,
    previewColor =
        color(100, 200, 100),
    previewEvery = 1,
    edgeDirection = 0.0,
    rigid = 0.0,
    selfPush = 66,
    sourcePush = 0
  }))

  gProps:add(map({ nm = "Long props", clr = color(0, 255, 0), prps = list() }))
  propsInCat = gProps[#gProps].prps
  propsInCat:add(map({ nm = "Cabinet Clamp", tp = "long", depth = 0, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Drill Suspender", tp = "long", depth = 5, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Thick Chain", tp = "long", depth = 0, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Drill", tp = "long", depth = 10, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Piston", tp = "long", depth = 4, tags = list(), notes = list() }))

  gProps:add(map({ nm = "LB Long Props", clr = color(0, 255, 0), prps = list() }))
  propsInCat = gProps[#gProps].prps
  propsInCat:add(map({ nm = "Stretched Pipe", tp = "long", depth = 0, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Twisted Thread", tp = "long", depth = 0, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Stretched Wire", tp = "long", depth = 0, tags = list(), notes = list() }))
  propsInCat:add(map({ nm = "Long Barbed Wire", tp = "long", depth = 0, tags = list(), notes = list() }))

  gTrashPropOptions = list()
  gMegaTrash = list()
  ntrashPFix = utils.getBoolConfig("notTrashProp fix")
  for q = 1, #gProps do
    for c = 1, #gProps[q].prps do
      gProps[q].prps[c]:addProp("settings", map())
      gProps[q].prps[c].settings:addProp("renderOrder", 0)
      gProps[q].prps[c].settings:addProp("seed", 500)
      gProps[q].prps[c].settings:addProp("renderTime", 0)

      local caseTp = gProps[q].prps[c].tp
      if (caseTp == "standard") or (caseTp == "variedStandard") then
        if (gProps[q].prps[c].colorTreatment == "bevel") then
          table.insert(gProps[q].prps[c].notes, "The highlights and shadows on this prop are generated by code, so it can be rotated to any degree and they will remain correct.")
        else
          table.insert(gProps[q].prps[c].notes, "Be aware that shadows and highlights will not rotate with the prop, so extreme rotations may cause incorrect shading.")
        end

        if caseTp == "variedStandard" then
          gProps[q].prps[c].settings:addProp("variation", (gProps[q].prps[c].random == 0))

          if toint(gProps[q].prps[c].random) then
            table.insert(gProps[q].prps[c].notes, "Will put down a random variation. A specific variation can be selected from settings ('N' key).")
          else
            table.insert(gProps[q].prps[c].notes, "This prop comes with many variations. Which variation can be selected from settings ('N' key).")
          end
        else
          gProps[q].prps[c].tags = list(gProps[q].prps[c].tags)

          if (gProps[q].prps[c].sz.locH < 5) and (gProps[q].prps[c].sz.locV < 5) and (gProps[q].prps[c].tags:getPos("INTERNAL") == 0) and (gProps[q].prps[c].tags:getPos("notTrashProp") == 0 or (not tobool(ntrashPFix))) then
            gTrashPropOptions:add(point(q, c))
            if (gProps[q].prps[c].sz.locH < 3) or (gProps[q].prps[c].sz.locV < 3) then
              gTrashPropOptions:add(point(q, c))
            end
          end
          if (gProps[q].prps[c].sz.locH >= 4) and (gProps[q].prps[c].sz.locV >= 4) and (gProps[q].prps[c].sz.locH <= 20) and (gProps[q].prps[c].sz.locV <= 20) and (gProps[q].prps[c].tags:getPos("colored") == 0) and (gProps[q].prps[c].tags:getPos("effectColorB") == 0) and (gProps[q].prps[c].tags:getPos("effectColorA") == 0) and (gProps[q].prps[c].tags:getPos("notMegaTrashProp") == 0) then
            gMegaTrash:add(point(q, c))
          end
        end
      elseif (caseTp == "rope") then
        gProps[q].prps[c].settings["release"] = 0
      elseif (caseTp == "customRope") then
        gProps[q].prps[c].settings["release"] = 0
        if (gProps[q].prps[c].colorTreatment == "bevel") then
          table.insert(gProps[q].prps[c].notes, "The highlights and shadows on this prop are generated by code, so it can be rotated to any degree and they will remain correct.")
        else
          table.insert(gProps[q].prps[c].notes, "Be aware that shadows and highlights will not rotate with the prop, so extreme rotations may cause incorrect shading.")
        end
      else
        if (caseTp == "variedDecal") or (caseTp == "variedSoft") then
          gProps[q].prps[c].settings:addProp("variation", (gProps[q].prps[c].random == 0))
          gProps[q].prps[c].settings:addProp("customDepth", gProps[q].prps[c].depth)

          if tobool(gProps[q].prps[c].random) then
            table.insert(gProps[q].prps[c].notes, "Will put down a random variation. A specific variation can be selected from settings ('N' key).")
          else
            table.insert(gProps[q].prps[c].notes, "This prop comes with many variations. Which variation can be selected from settings ('N' key).")
          end

          if (caseTp == "variedSoft") or (caseTp == "coloredSoft") then
            if tobool(gProps[q].prps[c].colorize) then
              gProps[q].prps[c].settings["applyColor"] = 1
              table.insert(gProps[q].prps[c].notes, "It's recommended to render this prop after the effects if the color is activated, as the effects won't affect the color layers.")
            end
          end
        elseif (caseTp == "simpleDecal") or (caseTp == "soft") or (caseTp == "softEffect") or (caseTp == "antimatter") or (caseTp == "coloredSoft") then
          gProps[q].prps[c].settings["customDepth"] =  gProps[q].prps[c].depth
        end

        if (caseTp == "soft") or (caseTp == "softEffect") or (caseTp == "variedSoft") or (caseTp == "coloredSoft") then
          if (gProps[q].prps[c].selfShade == 1) then
            table.insert(gProps[q].prps[c].notes, 
              "The highlights and shadows on this prop are generated by code, so it can be rotated to any degree and they will remain correct.")
          else
            table.insert(gProps[q].prps[c].notes, 
              "Be aware that shadows and highlights will not rotate with the prop, so extreme rotations may cause incorrect shading.")
          end
        end

        local caseName = gProps[q].prps[c].nm

        if (caseName == "wire") or (caseName == "Zero-G Wire") or (caseName == "Straight wire") or (caseName == "Straight Zero-G Wire") then
          gProps[q].prps[c].settings["thickness"] = 2
          table.insert(gProps[q].prps[c].notes, "The thickness of the wire can be set in settings.")
        elseif (caseName == "Zero-G Tube") or (caseName == "Straight Zero-G Tube") then
          gProps[q].prps[c].settings["applyColor"] = 0
          table.insert(gProps[q].prps[c].notes, "The tube can be colored white through the settings.")
        end

        for _, t in ipairs(gProps[q].prps[c].tags) do
          if (t == "customColor") then
            gProps[q].prps[c].settings["color"] = 0
            table.insert(gProps[q].prps[c].notes, "Custom color available")
          elseif t == "customColorRainBow" then
            gProps[q].prps[c].settings["color"] = 1
            table.insert(gProps[q].prps[c].notes, "Custom color available")
          end
        end
      end
    end

    --EFFECTS EDITOR!
    gEffects = list()
    local savEf = member("effectsInit")
    member("effectsInit"):importFileInto("effectsInit.txt")
    savEf.name = "effectsInit"
    if not (savEf.text == nil) and not (savEf.text == "") and not (atLine(savEf.text, 1) == atLine(member("baseEffectsInit").text, 1)) and not utils.checkIsDrizzleRendering() then
      -- fileEf = xtra("fileio")
      -- fileEf.createFile(moviePath .. "effectsInit.txt")
      -- fileEf.openFile(moviePath .. "effectsInit.txt", 0)
      -- fileEf.writeString(member("baseEffectsInit").text)
      -- fileEf.writeReturn("windows")

      local f = io.open(moviePath .. "effectsInit.txt", "w")

      if f then
        f:write(member("baseEffectsInit").text .. "\r\n")
        f:close()
      else
        print('Warning: fileEf failed to open')
      end

      savEf.text = member("baseEffectsInit").text
    end
    for ln = 1, numberOfLines(savEf.text) do
      local lin = atLine(savEf.text, ln)
      if not (lin == "") then
        if (atChar(lin, 1) == "-") then
          gEffects:add(map({ nm = string.sub(lin, 2), efs = list() }))
          
          local efLn = ln + 1
          while efLn <= numberOfLines(savEf.text) do
            local efLin = atLine(savEf.text, efLn)
            if (atChar(efLin, 1) == "-") then
              break
            elseif not (efLin == "") then
              gEffects[#gEffects].efs:add(map({ nm = efLin }))
            end

            efLn = efLn + 1
          end
          ln = efLn - 1
        end
      end
    end
    if (#gEffects >= 1) then
      for del = #gEffects, 1, -1 do
        if (#gEffects[del].efs < 1) then
          gEffects:deleteAt(del)
        end
      end
    end
    if (#gEffects < 1) then
      gEffects:add(map({ nm = "Natural", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Slime" }))
      gEffects[#gEffects].efs:add(map({ nm = "Melt" }))
      gEffects[#gEffects].efs:add(map({ nm = "Rust" }))
      gEffects[#gEffects].efs:add(map({ nm = "Barnacles" }))
      gEffects[#gEffects].efs:add(map({ nm = "Rubble" }))
      gEffects[#gEffects].efs:add(map({ nm = "DecalsOnlySlime" }))

      gEffects:add(map({ nm = "Erosion", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Roughen" }))
      gEffects[#gEffects].efs:add(map({ nm = "SlimeX3" }))
      gEffects[#gEffects].efs:add(map({ nm = "Super Melt" }))
      gEffects[#gEffects].efs:add(map({ nm = "Destructive Melt" }))
      gEffects[#gEffects].efs:add(map({ nm = "Erode" }))
      gEffects[#gEffects].efs:add(map({ nm = "Super Erode" }))
      gEffects[#gEffects].efs:add(map({ nm = "DaddyCorruption" }))

      gEffects:add(map({ nm = "Artificial", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Wires" }))
      gEffects[#gEffects].efs:add(map({ nm = "Chains" }))

      gEffects:add(map({ nm = "Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Root Grass" }))
      gEffects[#gEffects].efs:add(map({ nm = "Seed Pods" }))
      gEffects[#gEffects].efs:add(map({ nm = "Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Cacti" }))
      gEffects[#gEffects].efs:add(map({ nm = "Rain Moss" }))
      gEffects[#gEffects].efs:add(map({ nm = "Hang Roots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Grass" }))

      gEffects:add(map({ nm = "Plants2", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Arm Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Horse Tails" }))
      gEffects[#gEffects].efs:add(map({ nm = "Circuit Plants" }))
      gEffects[#gEffects].efs:add(map({ nm = "Feather Plants" }))
      gEffects[#gEffects].efs:add(map({ nm = "Thorn Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Rollers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Garbage Spirals" }))

      gEffects:add(map({ nm = "Plants3", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Thick Roots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Shadow Plants" }))

      gEffects:add(map({ nm = "Plants (Individual)", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Fungi Flowers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Lighthouse Flowers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fern" }))
      gEffects[#gEffects].efs:add(map({ nm = "Giant Mushroom" }))
      gEffects[#gEffects].efs:add(map({ nm = "Sprawlbush" }))
      gEffects[#gEffects].efs:add(map({ nm = "featherFern" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fungus Tree" }))

      gEffects:add(map({ nm = "Paint Effects", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "BlackGoo" }))
      gEffects[#gEffects].efs:add(map({ nm = "DarkSlime" }))

      gEffects:add(map({ nm = "Restoration", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Restore As Scaffolding" }))
      gEffects[#gEffects].efs:add(map({ nm = "Ceramic Chaos" }))

      gEffects:add(map({ nm = "LB Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Hang Roots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Thick Roots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Shadow Plants" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Lighthouse Flowers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Fungi Flowers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Root Plants" }))

      gEffects:add(map({ nm = "LB Plants 2", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Foliage" }))
      gEffects[#gEffects].efs:add(map({ nm = "Mistletoe" }))
      gEffects[#gEffects].efs:add(map({ nm = "High Fern" }))
      gEffects[#gEffects].efs:add(map({ nm = "High Grass" }))
      gEffects[#gEffects].efs:add(map({ nm = "Little Flowers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Wastewater Mold" }))

      gEffects:add(map({ nm = "LB Plants 3", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Spinets" }))
      gEffects[#gEffects].efs:add(map({ nm = "Small Springs" }))
      gEffects[#gEffects].efs:add(map({ nm = "Mini Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Clovers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Reeds" }))
      gEffects[#gEffects].efs:add(map({ nm = "Lavenders" }))
      gEffects[#gEffects].efs:add(map({ nm = "Dense Mold" }))

      gEffects:add(map({ nm = "LB Erosion", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Ultra Super Erode" }))
      gEffects[#gEffects].efs:add(map({ nm = "Impacts" }))

      gEffects:add(map({ nm = "LB Paint Effects", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Super BlackGoo" }))
      gEffects[#gEffects].efs:add(map({ nm = "Stained Glass Properties" }))

      gEffects:add(map({ nm = "LB Natural", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Barnacles" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Rubble" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fat Slime" }))
      gEffects[#gEffects].efs:add(map({ nm = "Sand" }))

      gEffects:add(map({ nm = "LB Artificial", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Assorted Trash" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Wires" }))
      gEffects[#gEffects].efs:add(map({ nm = "Colored Chains" }))
      gEffects[#gEffects].efs:add(map({ nm = "Ring Chains" }))

      gEffects:add(map({ nm = "Dakras Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Left Facing Kelp" }))
      gEffects[#gEffects].efs:add(map({ nm = "Right Facing Kelp" }))
      gEffects[#gEffects].efs:add(map({ nm = "Mixed Facing Kelp" }))
      gEffects[#gEffects].efs:add(map({ nm = "Bubble Grower" }))
      gEffects[#gEffects].efs:add(map({ nm = "Moss Wall" }))
      gEffects[#gEffects].efs:add(map({ nm = "Club Moss" }))
      gEffects[#gEffects].efs:add(map({ nm = "Dandelions" }))

      gEffects:add(map({ nm = "Leo Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Ivy" }))

      gEffects:add(map({ nm = "Nautillo Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Fuzzy Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Leaf Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Meat Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Hyacinths" }))
      gEffects[#gEffects].efs:add(map({ nm = "Seed Grass" }))
      gEffects[#gEffects].efs:add(map({ nm = "Orb Plants" }))
      gEffects[#gEffects].efs:add(map({ nm = "Storm Plants" }))

      gEffects:add(map({ nm = "Nautillo Plants 2", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Coral Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Horror Growers" }))

      gEffects:add(map({ nm = "Tronsx Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Thunder Growers" }))

      gEffects:add(map({ nm = "Intrepid Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Ice Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Grass Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fancy Growers" }))

      gEffects:add(map({ nm = "LudoCrypt Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Mushroom Stubs" }))

      gEffects:add(map({ nm = "Alduris Effects", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Mosaic Plants" }))
      gEffects[#gEffects].efs:add(map({ nm = "Lollipop Mold" }))
      gEffects[#gEffects].efs:add(map({ nm = "Cobwebs" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fingers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Sprawlroots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Fungus Roots" }))

      gEffects:add(map({ nm = "April Plants", efs = list() }))
      gEffects[#gEffects].efs:add(map({ nm = "Grape Roots" }))
      gEffects[#gEffects].efs:add(map({ nm = "Og Grass" }))
      gEffects[#gEffects].efs:add(map({ nm = "Hand Growers" }))
      gEffects[#gEffects].efs:add(map({ nm = "Head Lamp" }))
      gEffects[#gEffects].efs:add(map({ nm = "Ceiling Lamp" }))
      gEffects[#gEffects].efs:add(map({ nm = "Spindles" }))

      -- THE FOLLOWING EFFECTS ARE NOT FOR PUBLIC USE. DO NOT USE WITHOUT PERMISSION.
      if getBoolConfig("HB special") then
        --gEffects[#gEffects].efs:add(map({nm="Wire Bunches"})) -- contact @aprilistheworstmonthever before use
      end
      if getBoolConfig("Hog special") then
        --gEffects[#gEffects].efs:add(map({nm="Box Grubs"})) -- contact @slithersss before use
      end
    end

    -- Custom effects
    local sav = member("initImport")
    sav.text = ""
    member("initImport"):importFileInto("Effects" .. dirSeparator .. "Init.txt")
    sav.name = "initImport"

    local didNewHeading = 0
    gCustomEffects = list()
    for q = 1, numberOfLines(sav.text) do
      local savTextLine = atLine(sav.text, q)
      if not (savTextLine == "") then
        if (atChar(savTextLine, 1) == "-") then
          didNewHeading = 1
          local vl = string.sub(savTextLine, 2)
          gEffects:add(map({ nm = vl, efs = list() }))
        elseif (value(savTextLine) == nil) then
          writeException("Effects Init Error",
            "Line " ..
            ' ' .. q .. ' ' .. " is malformed in the Init.txt file from your Effects folder. (" .. savTextLine .. ")")
          hadException = 1
        else
          local ad = fromLingo(savTextLine)
          if ad:findPos("nm") > 0 and (ad:findPos("tp") > 0) then
            -- New heading if needed
            if didNewHeading == 0 then
              gEffects:add(map({ nm = "Custom Effects", efs = list() }))
              writeException("Effects Init Error",
                "Effects/Init.txt does not begin with a category. Creating temporary category, but please create one yourself.")
              hadException = 1
              didNewHeading = 1
            end

            -- Ok add the effect
            if #gEffects[#gEffects].efs >= 7 then
              -- wrap to a new space if will overflow. mostly because too lazy to figure out scrolling lol
              gEffects:add(map({ nm = gEffects[#gEffects].nm, efs = list() }))
            end
            gEffects[#gEffects].efs:add(ad)
            gCustomEffects:append(ad.nm)
          else
            writeException("Effects Init Error",
              "Line " ..
              ' ' ..
              q .. ' ' .. " is missing nm or tp in the Init.txt file from your Effects folder. (" .. savTextLine .. ")")
            hadException = 1
          end
        end
      end
    end
    -- Remove empty categories
    for q = #gEffects, 1, -1 do
      if #gEffects[q].efs == 0 then
        writeException("Effects Init Error", "Category '" .. gEffects[q].nm .. "' was empty! Removing.")
        hadException = 1
        gEffects:deleteAt(q)
      end
    end

    gEEprops = map({
      lastKeys = list(),
      keys = list(),
      lstMsPs = point(0, 0),
      effects = list(),
      emPos = point(1, 1),
      editEffect = 0,
      selectEditEffect = 0,
      mode =
      "createNew",
      brushSize = 5
    })


    --Light editor
    gLightEProps = map({
      pos = point(1040 / 2, 800 / 2),
      rot = 0,
      sz = point(50, 70),
      col = 1,
      keys = 0,
      lastKeys = 0,
      lastTm = 0,
      lightAngle = 180,
      flatness = 1,
      lightRect =
          rect(1000, 1000, -1000, -1000),
      paintShape = "pxl"
    })
    gLOprops = map({
      mouse = 0,
      lastMouse = 0,
      mouseClick = 0,
      pal = 1,
      pals = list({ map({ detCol = color(255, 0, 0) }) }),
      eCol1 = 1,
      eCol2 = 2,
      totEcols = 5,
      tileSeed =
          random(400),
      colGlows = list({ 0, 0 }),
      size = point(cols, rows),
      extraTiles = list({ 12, 3, 12, 5 }),
      light = 1
    })

    gCustomLights = list()
    if not utils.checkIsDrizzleRendering() then
      local pth = moviePath .. "Lights" .. dirSeparator
      local i = 1
      while true do
        local n = getNthFileNameInFolder(pth, i)
        if n == "" then
          break
        end
        if (string.sub(n, #n - 3) == ".png") then
          gCustomLights:append(n)
        end
        i = i + 1
      end
    end

    -- new(script "levelEdit_parentscript", 1) -- Don't know what to do here
    --new(script"levelEdit_parentscript", 2)

    gCameraProps = map({
      cameras = list({ point(gLOprops.size.locH * 10, gLOprops.size.locV * 10) - point(35 * 20, 20 *
        20) }),
      selectedCamera = 0,
      quads = list({ list({ list({ 0, 0 }), list({ 0, 0 }), list({ 0, 0 }), list({ 0, 0 }) }) }),
      keys =
          map({ n = 0, d = 0, e = 0, p = 0 }),
      lastKeys = map({ n = 0, d = 0, e = 0, p = 0 })
    })

    --Reset internals
    for _, mem in ipairs({ "rainBowMask", "blackOutImg1", "blackOutImg2" }) do
      member(mem).image = image(1, 1)
    end

    member("lightImage").image = image((gLOprops.size.x * 20) + 300, (gLOprops.size.y * 20) + 300)

    for i = 0, 29 do
      member("layer" .. i).image         = image(1, 1)
      member("layer" .. i .. "sh").image = image(1, 1)
      member("gradientA" .. i).image     = image(1, 1)
      member("gradientB" .. i).image     = image(1, 1)
      member("layer" .. i .. "dc").image = image(1, 1)
      member("dumpImage").image          = image(1, 1)
      member("finalDecalImage").image    = image(1, 1)
      member("GradientOutput").image     = image(1, 1)
    end

    if utils.getBoolConfig("Large trash debug log") then
      for tr = 1, #gTrashPropOptions do
        member("DEBUGTR").text = member("DEBUGTR").text ..
            RETURN .. gProps[gTrashPropOptions[tr].x].prps[gTrashPropOptions[tr].y].nm
      end
      -- local fileOpener = xtra("fileio")
      -- fileOpener.openFile(moviePath .. "largeTrashLog.txt", 0)
      -- fileOpener.writeString(member("DEBUGTR").text)
      -- fileOpener.writeReturn("windows")

      local f = io.open(moviePath .. "largeTrashLog.txt", "r")

      if f then
        f:write(member("DEBUGTR").text .. "\r\n")
        f:close()
      else
        print("Warning: fileOpener at Large trash failed to open")
      end
    end
    --exportAll() -- use keybind instead (tab+e+a default)

    -- Warn the user if an exception was encountered
    if hadException == 1 then
      utils.popupWarning("Init Issues", "Encountered issues while reading inits! See editorExceptionLog.txt for more info.")
    end
  end
end

return m
