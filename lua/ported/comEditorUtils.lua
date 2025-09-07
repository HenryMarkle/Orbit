-- global gLoadedName, INT_EXIT, INT_EXRD, DRInternalList, DRFirstTileCat, DRLastMatCat, RandomMetals_allowed, RandomMetals_grabTiles, ChaoticStone2_needed, DRRandomMetal_needed, SmallMachines_grabTiles, SmallMachines_forbidden, RandomMachines_forbidden, RandomMachines_grabTiles, RandomMachines2_forbidden, RandomMachines2_grabTiles, DRBevelColors, CommsDrizzle, gTiles, GL_ptPos, GL_drPos, GL_keyDict, gCustomKeybinds, gVersion

local Module = {}


-- print('[utils] color() is', color)

function Module.clearLogs()
  --type fl: dynamic
  --type return: void
  member("logText").text = "Rain World Community Editor; " .. gVersion .. "; Editor exception log"
  member("DEBUGTR").text = "Rain World Community Editor; " .. gVersion .. "; Large trash log"
  -- local fl = xtra("fileio")
  -- fl.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fl.delete()
  -- fl.createFile( moviePath .. "editorExceptionLog.txt")
  -- fl.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fl.writeString(member("logText").text)
  -- fl.closeFile()
  -- fl.openFile( moviePath .. "largeTrashLog.txt", 0)
  -- fl.delete()
  -- fl.createFile( moviePath .. "largeTrashLog.txt")
  -- fl.openFile( moviePath .. "largeTrashLog.txt", 0)
  -- fl.writeString(member("DEBUGTR").text)
  -- fl.closeFile()

  local f = io.open(moviePath .. "editorExceptionLog.txt", "w")

  if f then
    f:write(member("logText").text)
    f:close()
  end

  f = io.open(moviePath .. "largeTrashLog.txt", "w")

  if f then
    f:write(member("DEBUGTR").text)
    f:close()
  end

end

function Module.prepareRelease()
  member("logText").text = ""
  member("editorConfig").text = ""
  member("DEBUGTR").text = ""
  member("editorKeybinds").text = ""
  member("effectsInit").text = ""
  member("matInit").text = ""
  member("initImport").text = ""
  member("effectsL").text = "<EFFECTS>"
  member("editEffectName").text = ""
  member("effectOptions").text = "[ Layers ]: All"..RETURN.."All     1     - 2 -   3     1:st and 2:nd     2:nd and 3:rd     "
  member("level Name").text = "New Project"
  member("ProjectsL").text = ""
  member("previewTiles").image = image(1, 1)
  member("previewTilesDR").image = image(1, 1)
  member("previewImprt").image = image(1, 1)
  
--   for q = 1, 1000 do
--     (member q of castLib 2).erase() -- customMems
--   end
  castLib(2):eraseMembers()
  
--   go  frame
  _movie.halt()
end

function Module.checkDebugKeybinds()
  if Module.checkCustomKeybind("ExportAssets", {"E","A",48}) then -- tab+e+a
    Module.exportAll()
  elseif Module.checkCustomKeybind("OutputInternalLog", {"I","L",48}) then -- tab+i+l
    Module.outputInternalLog()
  elseif Module.checkCustomKeybind("PrepareInternalsForRelease", {"P","I",48}) then -- tab+P+I
    Module.prepareRelease()
--   elseif checkCustomKeybind(#RestartComputer, {48,"X","C","P",36}) then -- thanks drycrycrystal for suggesting this
    -- _system.restart() -- restart computer lmao
    -- hell NAH
--   elseif checkCustomKeybind("ShutdownComputer", nil) then
    -- _system.shutDown()
  end
end

---@param tp string
---@param msg any
function Module.writeException(tp, msg)
  -- local fileOpener

  member("logText").text = member("logText").text..RETURN..tostring(gLoadedName).." ! "..tostring(tp).." Exception : "..tostring(msg)
  -- fileOpener = xtra("fileio")
  -- fileOpener.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fileOpener.writeString(member("logText").text)
  -- fileOpener.writeReturn("windows")

  local excepFile = io.open(moviePath .. "editorExceptionLog.txt", "a")

  if excepFile then
    excepFile:write(member("logText").text .. "\r\n")
    excepFile:close()
  end
end

function Module.writeMessage(msg)
  -- local fileOpener
  member("logText").text = member("logText").text..RETURN..string(gLoadedName).." : "..string(msg)
  -- fileOpener = xtra("fileio")
  -- fileOpener.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fileOpener.writeString(member("logText").text)
  -- fileOpener.writeReturn("windows")

  local excepFile = io.open(moviePath .. "editorExceptionLog.txt", "a")

  if excepFile then
    excepFile:write(member("logText").text .. "\r\n")
    excepFile:close()
  end
end

function Module.writeInfoMessage(msg)
  -- local fileOpener
  member("logText").text = member("logText").text..RETURN.."Info : "..string(msg)
  -- fileOpener = xtra("fileio")
  -- fileOpener.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fileOpener.writeString(member("logText").text)
  -- fileOpener.writeReturn("windows")

  local excepFile = io.open(moviePath .. "editorExceptionLog.txt", "a")

  if excepFile then
    excepFile:write(member("logText").text .. "\r\n")
    excepFile:close()
  end
end

function Module.writeInternalMessage(msg)
  member("logText").text = member("logText").text..RETURN..string(gLoadedName).." : "..string(msg)
end

function Module.outputInternalLog()
  -- local fileOpener = xtra("fileio")
  -- fileOpener.openFile( moviePath .. "editorExceptionLog.txt", 0)
  -- fileOpener.writeString(member("logText").text)
  -- fileOpener.writeReturn("windows")

  local excepFile = io.open(moviePath .. "editorExceptionLog.txt", "a")

  if excepFile then
    excepFile:write(member("logText").text .. "\r\n")
    excepFile:close()
  end
end

function Module.popupWarning(ttl, msg)
  if not Module.checkIsDrizzleRendering() then
    _player.alert(ttl .. ": " .. msg)
  end
  --if not checkIsDrizzleRendering() then
  --  alertObj = new xtra("MUI")
  --  alertArgs = [#buttons:#Ok, #icon:#caution, #title:ttl, #message:msg..RETURN..RETURN.."Press 'Ok' to dismiss.", #movable:TRUE]
  --  if objectp(alertObj) then
  --    Alert(alertObj, alertArgs)
  --  end
  --end
end

function Module.exportAll()
  local pth = ''
  local objFileio
  local objImg

  pth =  moviePath .. "Export" ..  dirSeparator
  objFileio = xtra("fileio")
  objImg = xtra("ImgXtra")

  local i = 1
  repeat -- I hope there's not more than 100 cast libs in  future lol
    local cname
    local c = castLib(i)
    i = i + 1
    if c == nil then break end
    cname = c.name .. "_"
    for _, m in pairs(c.member) do
      local fname
      if (m.name == nil) then
        fname = pth .. c.name .. "_" .. tostring(m.number)
      else
        fname = pth .. c.name .. "_" .. tostring(m.number) .. "_" .. m.name
      end
      if (m.type == "bitmap") then
        -- objImg.ix_saveImage({image = m.image, filename = fname .. ".png", format = "PNG"})
        exportImage(m.image, fname)
      elseif (m.type == "script") then
        -- objFileio.createFile(objFileio, pth .. m.name .. ".ls")
        -- objFileio.openFile(pth .. m.name .. ".ls", 0)
        -- objFileio.writeString(m.scriptText)
        -- objFileio.closeFile()

        local f = io.open(pth .. m.name .. ".ls", "w")

        if f then
          f:write(m.scriptText)
          f:close()
        end
      elseif (m.type == "text") then
        -- objFileio.createFile(objFileio, fname .. ".txt")
        -- objFileio.openFile(fname .. ".txt", 0)
        -- objFileio.writeString(m.text)
        -- objFileio.closeFile()

        local f = io.open(fname .. ".txt", "w")

        if f then
          f:write(m.text)
          f:close()
        end
      end
    end
until i == 100
--   go  frame
  _movie.halt()
end

---@param str string
---@return boolean
function Module.getBoolConfig(str)
  local txt = member("editorConfig").text
  for q = 1, numberOfLines(txt) do
    if (atLine(txt, q) == str .. " : TRUE") then
      return true
    end
  end
  return false
end

---@param str string
---@param def number
---@return number
function Module.getBoolConfigOrDefault(str, def)
  local txt = member("editorConfig").text
  for q = 1, numberOfLines(txt) do
    if (string.sub(atLine(txt, q), 1, #str) == str) then
      if atLine(txt, q) == str .. " : TRUE" then
        return 1
      end
    end
  end
  return def
end

---@param str string
---@return string
function Module.getStringConfig(str)
  local txt = member("editorConfig").text
  for q = 1, numberOfLines(txt) do
    if (atLine(txt, q) == str .. " : DROUGHT") then
      return "DROUGHT"
    elseif (atLine(txt, q) == str .. " : DRY") then
      return "DRY"
    end
  end
  return "VANILLA"
end

---@param str string
---@return string|nil
function Module.getStringConfigOrVoid(str)
  local txt = member("editorConfig").text
  for q = 1, numberOfLines(txt) do
    if (string.sub(atLine(txt, q), 1, #str) == str) then
      return string.sub(str, #str+3, #atLine(txt, q))
    end
  end
  return nil
end

---@return boolean
function Module.dontRunStuff()
  return _movie.window.sizeState == "minimized"
end

---@return boolean
function Module.checkMinimize()
  if gCustomKeybinds then 
    return Module.checkCustomKeybind("Minimize", {56, 48})
  end
  
  if not(_movie.window.sizeState == "minimized") then
    if _key.keyPressed(56) then
      return _key.keyPressed(48)
    end
  end
  return FALSE
end

---@return boolean
function Module.checkExitRender()
  if gCustomKeybinds then 
    return (Module.checkCustomKeybind("ExitRender", {48, "Z", "R"}))
  end
  
  if not(_movie.window.sizeState == "minimized") then
    if (_key.keyPressed(48)) then
      if (INT_EXRD == "DROUGHT") then
        if (_key.keyPressed("Z")) then
          return (_key.keyPressed("R"))
        end
      elseif (INT_EXRD == "DRY") then
        if (_key.keyPressed("X")) then
          return (_key.keyPressed("C"))
        end
      else
        return true
      end
    end
  end
  return false
end

---@return boolean
function Module.checkExit()
  if gCustomKeybinds then 
    return Module.checkCustomKeybind("Close", {53, 56})
  end

  if (_movie.window.sizeState ~= "minimized") then
    if (INT_EXIT == "DROUGHT") then
      if (_key.keyPressed(56)) then
        return (_key.keyPressed(53))
      end
    elseif (INT_EXIT == "DRY") then
      if (_key.keyPressed(48)) then
        if (_key.keypressed(36)) then
          return (_key.keyPressed("X"))
        end
      end
    else
      return (_key.keyPressed(53))
    end
  end
  return false
end

---@param nm string
---@return boolean
function Module.checkDRInternal(nm)
  return DRInternalList:getPos(nm) > 0
end

---@param num number
function Module.setFirstTileCat(num)
  DRFirstTileCat = num
end

---@return number
function Module.getFirstTileCat()
  return DRFirstTileCat
end

---@param num number
function Module.setLastMatCat(num)
  DRLastMatCat = num
end

---@return table
function Module.getLastMatCat()
  return DRLastMatCat
end

function Module.initDRInternal()
  DRInternalList = list({"SGFL", "tileSetAsphaltFloor", "tileSetStandardFloor", "tileSetBigMetalFloor", "tileSetBricksFloor", "tileSetCliffFloor", "tileSetConcreteFloor", "tileSetNon-Slip MetalFloor", "tileSetRainstoneFloor", "tileSetRough RockFloor", "tileSetScaffoldingDRFloor", "tileSetSteelFloor", "tileSetSuperStructure2Floor", "tileSetSuperStructureFloor", "tileSetTiny SignsFloor", "tileSetElectricMetalFloor", "tileSetCageGrateFloor", "tileSetGrateFloor", "tileSetBulkMetalFloor", "tileSetMassiveBulkMetalFloor", "4Mosaic Square", "4Mosaic Slope NE", "4Mosaic Slope SE", "4Mosaic Slope NW", "4Mosaic Slope SW", "4Mosaic Floor", "3DBrick Square", "3DBrick Slope NE", "3DBrick Slope SE", "3DBrick Slope NW", "3DBrick Slope SW", "3DBrick Floor", "Small Stone Slope NE", "Small Stone Slope SE", "Small Stone Slope NW", "Small Stone Slope SW", "Small Stone Floor", "Small Machine Slope NE", "Small Machine Slope SE", "Small Machine Slope NW", "Small Machine Slope SW", "Small Machine Floor", "Missing Metal Slope NE", "Missing Metal Slope SE", "Missing Metal Slope NW", "Missing Metal Slope SW", "Missing Metal Floor", "Small Stone Marked", "Square Stone Marked", "Small Metal Alt", "Small Metal Marked", "Small Metal X", "Metal Floor Alt", "Metal Wall", "Metal Wall Alt", "Square Metal Marked", "Square Metal X", "Wide Metal", "Tall Metal", "Big Metal X", "Large Big Metal", "Large Big Metal Marked", "Large Big Metal X", "AltGrateA", "AltGrateB1", "AltGrateB2", "AltGrateB3", "AltGrateB4", "AltGrateC1", "AltGrateC2", "AltGrateE1", "AltGrateE2", "AltGrateF1", "AltGrateF2", "AltGrateF3", "AltGrateF4", "AltGrateG1", "AltGrateG2", "AltGrateH", "AltGrateI", "AltGrateF2", "AltGrateJ1", "AltGrateJ2", "AltGrateJ3", "AltGrateJ4", "AltGrateK1", "AltGrateK2", "AltGrateK3", "AltGrateK4", "AltGrateL", "AltGrateM", "AltGrateN", "AltGrateO", "Big Big Pipe", "Ring Chain", "Stretched Pipe", "Stretched Wire", "Twisted Thread", "Christmas Wire", "Ornate Wire", "Dune Sand", "Big Chain", "Chunky Chain", "Big Bike Chain", "Huge Bike Chain", "Long Barbed Wire", "Small Chain", "Fat Chain"})
  RandomMetals_grabTiles = list({"Metal", "Metal construction", "Plate"})
  RandomMetals_allowed = list({"Small Metal", "Metal Floor", "Square Metal", "Big Metal", "Big Metal Marked", "C Beam Horizontal AA", "C Beam Horizontal AB", "C Beam Vertical AA", "C Beam Vertical BA", "Plate 2"})
  ChaoticStone2_needed = list({"Small Stone", "Square Stone", "Tall Stone", "Wide Stone", "Big Stone", "Big Stone Marked"})
  DRRandomMetal_needed = list({"Small Metal", "Metal Floor", "Square Metal", "Big Metal", "Big Metal Marked", "Four Holes", "Cross Beam Intersection"})
  SmallMachines_grabTiles = list({"Machinery", "Machinery2", "Small machine"})
  SmallMachines_forbidden = list({"Feather Box - W", "Feather Box - E", "Piston Arm", "Vertical Conveyor Belt A", "Ventilation Box Empty", "Ventilation Box", "Big Fan", "Giant Screw", "Compressor Segment", "Compressor R", "Compressor L", "Hub Machine", "Pole Holder", "Sky Box", "Conveyor Belt Wheel", "Piston Top", "Piston Segment Empty", "Piston Head", "Piston Segment Filled", "Piston Bottom", "Piston Segment Horizontal A", "Piston Segment Horizontal B", "machine box C_E", "machine box C_W", "machine box C_Sym", "Machine Box D", "machine box B", "Big Drill", "Elevator Track", "Conveyor Belt Covered", "Conveyor Belt L", "Conveyor Belt R", "Conveyor Belt Segment", "Dyson Fan", "Metal Holes", "valve", "Tank Holder", "Drill Rim", "Door Holder R", "Door Holder L", "Drill B", "machine box A", "Machine Box E L", "Machine Box E R", "Drill Shell A", "Drill Shell B", "Drill Shell Top", "Drill Shell Bottom", "Pipe Box R", "Pipe Box L"})
  RandomMachines_grabTiles = list({"Machinery", "Machinery2", "Small machine", "LB Machinery", "Custom Random Machines"})
  RandomMachines_forbidden = list({"Feather Box - W", "Feather Box - E", "Piston Arm", "Vertical Conveyor Belt A", "Piston Head No Cage", "Conveyor Belt Holder Only", "Conveyor Belt Wheel Only", "Drill Valve"})
  RandomMachines2_grabTiles = list({"Machinery", "Machinery2", "Small machine"})
  RandomMachines2_forbidden = list({"Feather Box - W", "Feather Box - E", "Piston Arm", "Vertical Conveyor Belt A", "Ventilation Box Empty", "Ventilation Box", "Big Fan", "Giant Screw", "Compressor Segment", "Compressor R", "Compressor L", "Hub Machine", "Pole Holder", "Sky Box", "Conveyor Belt Wheel", "Piston Top", "Piston Segment Empty", "Piston Head", "Piston Segment Filled", "Piston Bottom", "Piston Segment Horizontal A", "Piston Segment Horizontal B", "machine box C_E", "machine box C_W", "machine box C_Sym", "Machine Box D", "machine box B", "Big Drill", "Elevator Track", "Conveyor Belt Covered", "Conveyor Belt L", "Conveyor Belt R", "Conveyor Belt Segment", "Dyson Fan"})
  DRBevelColors = list({{color(255, 0, 0), point(-1, -1)}, {color(255, 0, 0), point(0, -1)}, {color(255, 0, 0), point(-1, 0)}, {color(0, 0, 255), point(1, 1)}, {color(0, 0, 255), point(0, 1)}, {color(0, 0, 255), point(1, 0)}})
end

---For Drizzle to override to skip some initialization code that it shouldn't need to care about.
function Module.checkIsDrizzleRendering()
  return true
end

--function freeImageNotFoundEx me
--  if ( moviePath .. "FreeImage.dll" = void) then
--    member("logText").text = member("logText").text..RETURN.."File Not Found Exception : FreeImage.dll is missing. You must place it in  same folder as your editor executable."
--    fileOpener = new xtra("fileio")
--    fileOpener.openFile( moviePath .. "editorExceptionLog.txt", 0)
--    fileOpener.writeString(member("logText").text)
--    fileOpener.writeReturn(#windows)
--  end
--end

---@param ad any
function Module.tryAddToPreview(ad)
  ---@type number
  local moreTilePreviews
  
  ---@type Image
  local prevw

  ---@type Image
  local drprevw
  
  ---@type number
  local calculatedHeight
  
  ---@type number
  local vertSZ
  
  ---@type number
  local horiSZ
  
  ---@type rect
  local rct

  if ad["ptPos"] ~= 0 then return end
  
  moreTilePreviews = Module.getBoolConfig("More tile previews")
  prevw = member("previewTiles").image
  drprevw = member("previewTilesDR").image
  
  -- Import tile preview
  -- Henry: this may be nil.
  local sav2 = member("previewImprt")
  member("previewImprt").importFileInto("Graphics" ..  dirSeparator .. ad.nm .. ".png")
  sav2.name = "previewImprt"
  --INTERNAL
  if (Module.checkDRInternal(ad.nm)) then
    sav2.image = member(ad.nm).image
  end
  calculatedHeight = sav2.image.rect.height
  vertSZ = 16 * ad.sz.locV
  horiSZ = 16 * ad.sz.locH
  if (ad.tp == "voxelStruct") then
    calculatedHeight = 1 + vertSZ + (20 * (ad.sz.locV + (ad.bfTiles * 2)) * #ad.repeatL)
    if ad.tags.getPos("ramp") > 0 then
      calculatedHeight = 1 + vertSZ + (20 * (ad.sz.locV * 2 + (ad.bfTiles * 2)) * #ad.repeatL)
    end
  end
  rct = rect(0, calculatedHeight - vertSZ, horiSZ, calculatedHeight)
  if ((GL_ptPos + horiSZ + 1) > prevw.width) and (moreTilePreviews) then
    drprevw:copyPixels(sav2.image, rect(GL_drPos, 0, GL_drPos + horiSZ, vertSZ), rct)
    ad.ptPos = GL_drPos + 60000
    ad:addProp("category", "gTiles")
    if (ad.tags:getPos("notTile") == 0) then
      gTiles[#gTiles].tls:add(ad)
    end
    GL_drPos = GL_drPos + horiSZ + 1
  else
    prevw:copyPixels(sav2.image, rect(GL_ptPos, 0, GL_ptPos + horiSZ, vertSZ), rct)
    ad.ptPos = GL_ptPos
    ad:addProp("category", "gTiles")
    if (ad.tags:getPos("notTile") == 0) then
      gTiles[#gTiles].tls:add(ad)
    end
    GL_ptPos = GL_ptPos + horiSZ + 1  
  end
end

---Weird ass function
function Module.getKeybindStr(k, d)
  if k == nil then
    return d
  end
  
  local v = GL_keyDict[k]
  if v == nil then return d end
  
  -- global GL_keyCodeList
  local s = ""
  local inv = false
  local addPlus = false
  
  local customStrCases = {
    {"+", "plus"}, 
    {"-", "minus"}, 
    {",", "comma"}, 
    {".", "dot"}, 
    {"/", "slash"}, 
    {"\\", "backslash"}, 
    {" ", "space"}, 
    {"`", "backtick"}, 
    {"~", "tilde"}, 
    {"!", "exclamation mark"}, 
    {"@", "at"}, 
    {"#", "pound"}, 
    {"$", "dollar sign"}, 
    {"%", "percent"}, 
    {"^", "caret"}, 
    {"&", "ampersand"}, 
    {"*", "asterisk"}, 
    {"(", "left parenthesis"}, 
    {")", "right parenthesis"}, 
    {"_", "underscore"}, 
    {"=", "equals"}, 
    {"|", "pipe"}, 
    {"'", "apostrophe"}, 
    {"\"", "quote"}, 
    {":", "colon"}, 
    {";", "semicolon"}, 
    {"?", "question mark"}
  }
  
  for checkk, check in pairs(v) do
    if inv then
      inv = false
      goto continue
    elseif v == "NOT" then
      inv = true
      goto continue
    end
    
    if addPlus then s = s .. "+" end
    addPlus = true
    
    if type(v) == "string" then
      local p = {v, v}
      for _, pair in ipairs(customStrCases) do
        if pair[1] == v then
          p = pair
          break
        end
      end
      s = s .. p[2]
    else
      local str = "???"
      for _, tuple in ipairs(GL_keyCodeList) do
        if tuple[2] == v then
          str = tuple[3]
          break
        end
      end
      s = s .. str
    end

    ::continue::
  end
  if s == "" then return d end
  return s
end

function Module.initCustomKeybindThings()
  -- global GL_keyCodeList, GL_allKeybinds
  gCustomKeybinds = 1
  
  GL_keyDict = {}

  local case = Module.getStringConfigOrVoid("Exit button")
  
  if (case == "VANILLA") then
    GL_keyDict["close"] = {53} -- Escape
  elseif (case == "DRY") then
    GL_keyDict["close"] = {48, 36, "X"} -- Tab Shift X
  else
    GL_keyDict["close"] = {"Shift", 53} -- Shift Escape
  end
  
  -- Exit button (close editor button)
  -- case getStringConfigOrVoid("Exit button") of
  --   "VANILLA":
  --     GL_keyDict[#close] = [53] -- Escape
  --   "DRY":
  --     GL_keyDict[#close] = [48, 36, "X"] -- Tab Shift X
  --   otherwise:
  --     -- DROUGHT or default
  --     GL_keyDict[#close] = ["Shift", 53] -- Shift Escape
  -- end case
  
  -- Minimize button
  GL_keyDict["minimize"] = {"Shift", 48} -- Shift Tab
  

  local case2 = Module.getStringConfigOrVoid("Exit render button")
  
  if (case2 == "VANILLA") then
    GL_keyDict["exitrender"] = {48} -- Tab
  elseif (case2 == "DRY") then
    GL_keyDict["exitrender"] = {48, "X", "C"} -- Tab X C
  else
    GL_keyDict["exitrender"] = {48, "Z", "R"} -- Tab Z R
  end

  -- Exit render button
  -- case getStringConfigOrVoid("Exit render button") of
  --   "VANILLA":
  --     GL_keyDict[#exitrender] = [48] -- Tab
  --   "DRY":
  --     GL_keyDict[#exitrender] = [48, "X", "C"] -- Tab X C
  --   otherwise:
  --     -- DROUGHT or default
  --     GL_keyDict[#exitrender] = [48, "Z", "R"] -- Tab Z R
  -- end case
  
  GL_keyCodeList = {
    {"ArrowLeft", 123, "Left"}, 
    {"ArrowRight", 124, "Right"}, 
    {"ArrowDown", 125, "Down"}, 
    {"ArrowUp", 126, "Up"}, 
    {"Numpad0", 82, "Numpad 0"}, 
    {"Numpad1", 83, "Numpad 1"}, 
    {"Numpad2", 84, "Numpad 2"}, 
    {"Numpad3", 85, "Numpad 3"}, 
    {"Numpad4", 86, "Numpad 4"}, 
    {"Numpad5", 87, "Numpad 5"}, 
    {"Numpad6", 88, "Numpad 6"}, 
    {"Numpad7", 89, "Numpad 7"}, 
    {"Numpad8", 91, "Numpad 8"}, 
    {"Numpad9", 92, "Numpad 9"}, 
    {"NumpadPlus", 78, "Numpad Plus"}, 
    {"NumpadMinus", 70, "Numpad Minus"}, 
    {"NumpadTimes", 66, "Numpad Times"}, 
    {"NumpadDivide", 77, "Numpad Divide"}, 
    {"NumpadDot", 65, "Numpad Dot"}, 
    {"NumpadEnter", 76, "Numpad Enter"}, 
    {"Enter", 36, "Enter"}, 
    {"ContextMenu", 127, "Context Menu"}, 
    {"Escape", 53, "Escape"}, 
    {"Tab", 48, "Tab"}, 
    {"Space", " ", "Space"}, 
    {"Backspace", 51, "Backspace"}, 
    {"Insert", 114, "Insert"}, 
    {"Delete", 117, "Delete"}, 
    {"Home", 115, "Home"}, 
    {"End", 119, "End"}, 
    {"PageUp", 116, "Page Up"}, 
    {"PageDown", 121, "Page Down"}, 
    {"Pause", 113, "Pause"}, 
    {"F1", 122, "F1"}, 
    {"F2", 120, "F2"}, 
    {"F3", 99, "F3"}, 
    {"F4", 118, "F4"}, 
    {"F5", 96, "F5"},
    {"F6", 97, "F6"}, 
    {"F7", 98, "F7"}, 
    {"F8", 100, "F8"}, 
    {"F9", 101, "F9"}, 
    {"F10", 109, "F10"}, 
    {"F11", 103, "F11"}, 
    {"F12", 111, "F12"}, 
    {"F13", 105, "F13"}, 
    {"F14", 107, "F14"}, 
    {"F15", 113, "F15"}
}
end

---@param nm string
---@return number|string
function Module.keyToKeyCode(nm)
  -- global GL_keyCodeList
  for _, tuple in ipairs(GL_keyCodeList) do
    if tuple[1] == nm then
      return tuple[2]
    end
  end
  
  if #nm ~= 1 and (nm ~= "Control") and (nm ~= "Shift") and (nm ~= "Alt") and (nm ~= "NOT") then
    Module.writeException("Custom Keybinds", "Key code '" .. nm .. "' not recognized!")
    return nm
  end
  
  return nm
end

---Converts a string to a symbol.
---@param s string
---@return string
function Module.str2symbol(s)
  ---@type number
  local i

  while s:find(" ") > 0 do
    i = offset(" ", s)
    s = string.sub(s, 1, i - 1) .. string.sub(s, i + 1)
  end
  return s
end


---@param k string
---@param v string
function Module.registerCustomKeybind(k, v)
  if (k == "") or (v == "") then
    return
  end
  
  -- Ignore that this method is empty, it used to have more stuff
  
  -- Actually register (why symbols? they're *a lot* faster than strings lol)
  local i = Module.str2symbol(k)
  
  if (v == "NONE") then
    GL_keyDict[i] = list({nil})
    return
  end
  
  local a = list()
  while v:find(" ") do
    local offst = offset(" ", v)
    if offst == 1 then
      v = string.sub(v, 2)
      --delete v[1]
    elseif offset("--", v) == 1 then
      break
    else
      a:append(Module.keyToKeyCode(v:sub(1, offst-1)))
      v = v:sub(offst+1)
      --delete v.char[1..offst]
    end
  end
  if (v ~= "") and offset("--", v) ~= 1 then a.append(Module.keyToKeyCode(v)) --  rest of everything else 
  end
  
  if #a == 0 then
    GL_keyDict[i] = list({nil})
  else
    GL_keyDict[i] = a
  end
end

-- function bool_xor(a, b)
--     return (a and not b) or (not a and b)
-- end

---@param k string
---@param d any
---@return boolean
function Module.checkCustomKeybind(k, d)
  if Module.dontRunStuff() then
    return false
  end

  local inv = 0
  
  if gCustomKeybinds and k ~= nil then
    -- Try to retrieve  actual keybind
    local v = GL_keyDict[k]  --[k]
    
    if v ~= nil then
      local control = 0
      local shift = 0
      local alt = 0
      inv = 0
    
      for _, check in ipairs(v) do
        if check == nil then
          return false
        elseif check == "NOT" then
          inv = 1
          goto continue1
        elseif check == "Control" then
          control = 1
        elseif check == "Shift" then
          shift = 1
        elseif check == "Alt" then
          alt = 1
        elseif inv==1 and _key.keyPressed(check) then
          return false
        elseif inv==0 and not _key.keyPressed(check) then
          return false
        end
        inv = 0
        ::continue1::

      end
      
      if tobool(ixor(_key.controlDown, control)) then
        return false
      end
      if tobool(ixor(_key.shiftDown, shift)) then
        return false
      end
      if tobool(ixor(_key.optionDown, alt)) then
        return false
      end
      return true
    end
    
  end
  
  -- Default case
  if type(d) == "table" then
    inv = 0
    for _, check in ipairs(d) do
      if check == nil then
        return false
      elseif check == "NOT" then
        inv = 1
        goto continue2
      elseif not _key.keyPressed(check) and inv==0 then
        return false
      elseif _key.keyPressed(check) and inv==1 then
        return false
      end
      ::continue2::
    end
    return true
  elseif d ~= nil then
    return _key.keyPressed(d)
  else
    return false
  end
  return true
end

return Module

