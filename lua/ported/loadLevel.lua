-- --global projects, ldPrps, gTEProps, gTiles, gLEProps, gEEprops, gLightEProps, gLEVEL, gLOprops, gLoadedName, gCameraProps, gEnvEditorProps, gPEprops, gLOADPATH, showControls, gEffects, gCustomEffects, gFSLastTm, gFSFlag

local me = {}

function me.exitFrame()
    --   if (showControls) then
    --     sprite(32).blend = 100
    --   else
    --     sprite(32).blend = 0
    --   end

    local utils = require('comEditorUtils')

    if utils.dontRunStuff() then
        gFSLastTm = _system.milliseconds
        -- go the frame
        return
    end

    if utils.checkMinimize() then
        _player.appMinimize()
    end
    if utils.checkExit() then
        _player.quit()
    end

    utils.checkDebugKeybinds()

    gFSFlag = false
    if _system.milliseconds - gFSLastTm > 10 then
        gFSFlag = true
        gFSLastTm = _system.milliseconds
    end

    local txt = "Use the up and down keys to select a project. Use enter to open it."
    txt = txt .. RETURN
    --   put RETURN after txt
    for _, f in ipairs(gLOADPATH) do
        -- put f & "/" after txt
        txt = txt .. "/"
    end
    txt = txt .. RETURN
    txt = txt .. RETURN
    --   put RETURN after txt
    --   put RETURN after txt
    for q = ldPrps.listScrollPos, ldPrps.listScrollPos + ldPrps.listShowTotal do
        if q > #projects then
            break
        else
            if q ~= ldPrps.currProject then
                -- put projects[q] after txt
                txt = txt .. projects[q]
            else
                -- put "<"&&projects[q]&&">" after txt
                txt = txt .. "< " .. projects[q] .. " >"
            end
            --   put RETURN after txt
            txt = txt .. RETURN
        end
    end

    member("ProjectsL").text = txt

    --lstKeys
    -- ldPrps
    local up = utils.checkCustomKeybind("LevelBrowseUp", 126)    --_key.keyPressed(126)
    local dwn = utils.checkCustomKeybind("LevelBrowseDown", 125) --_key.keyPressed(125)
    local lft = utils.checkCustomKeybind("LevelBrowseLeft", 123) --_key.keyPressed(123)
    local rgth = utils.checkCustomKeybind("LevelBrowseRight", 124) --_key.keyPressed(124)
    if utils.dontRunStuff() then
        up = false
        dwn = false
        lft = false
        rgth = false
    end

    if (up) then
        if gFSFlag then
            if (ldPrps.lstUp == 0) or (ldPrps.lstUp > 20 and (ldPrps.lstUp % 4) == 0) then
                ldPrps.currProject = ldPrps.currProject - 1
                if ldPrps.currProject < 1 then
                    ldPrps.currProject = #projects
                end
            end
            ldPrps.lstUp = ldPrps.lstUp + 1
        end
    else
        ldPrps.lstUp = 0
    end
    if (dwn) then
        if gFSFlag then
            if (ldPrps.lstdwn == 0) or (ldPrps.lstdwn > 20 and (ldPrps.lstdwn % 4) == 0) then
                ldPrps.currProject = ldPrps.currProject + 1
                if ldPrps.currProject > #projects then
                    ldPrps.currProject = 1
                end
            end
            ldPrps.lstdwn = ldPrps.lstdwn + 1
        end
    else
        ldPrps.lstdwn = 0
    end

    if ldPrps.currProject < ldPrps.listScrollPos then
        ldPrps.listScrollPos = ldPrps.currProject
    elseif ldPrps.currProject > ldPrps.listScrollPos + ldPrps.listShowTotal then
        ldPrps.listScrollPos = ldPrps.currProject - ldPrps.listShowTotal
    end

    if (rgth) and (ldPrps.rgth == 0) and (#projects > 0) then
        if (atChar(projects[ldPrps.currProject], 1) == "#") then
            me.loadSubFolder(projects[ldPrps.currProject])
        end
    elseif (lft) and (ldPrps.lft == 0) then
        if (gLOADPATH.count > 0) then
            gLOADPATH:deleteAt(gLOADPATH.count)
            _movie.go(2)
        end
    end

    ldPrps.lft = lft
    ldPrps.rgth = rgth

    if not utils.dontRunStuff() then
        if utils.checkCustomKeybind("LevelBrowseNew", "N") and _movie.window.sizeState ~= "minimized" then
            gLoadedName = "New Project"
            member("level Name").text = "New Project"
            _movie.go(7)
        elseif (utils.checkCustomKeybind("LevelBrowseSelect", 36)) and (projects.count > 0) and _movie.window.sizeState ~= "minimized" then
            if (atChar(projects[ldPrps.currProject], 1) ~= "#") then
                me.loadLevel(projects[ldPrps.currProject])
                _movie.go(7)
            end
        end
    end
    --   go the frame
end

---@param fldrName string
function me.loadSubFolder(fldrName)
    -- gLOADPATH:add(fldrName:sub(2))
    table.insert(gLOADPATH, fldrName:sub(2))
    _movie.go(2)
end

---@param lvlName string
---@param fullPath number?
function me.loadLevel(lvlName, fullPath)
    local utils = require('comEditorUtils')
    local utils2 = require('spelrelaterat')

    local pth = ''

    if tobool(fullPath) then
        pth = ""
    else
        pth = moviePath .. "LevelEditorProjects" .. dirSeparator
        for _, f in pairs(gLOADPATH) do
            pth = pth .. f .. dirSeparator
        end
    end

    -- local objFileio = xtra("fileio")
    --createFile (objFileio, the moviePath&the dirSeparator&"LevelEditorProjects"&the dirSeparator&levelName&".txt")
    -- objFileio.openFile(pth .. lvlName .. ".txt", 0)

    if (fullPath == 1) then
        gLoadedName = ""
        local lastBackSlash = 0
        for q = 1, #lvlName do
            if (atChar(lvlName, q) == dirSeparator) then
                lastBackSlash = q
            end
        end
        gLoadedName = lvlName:sub(lastBackSlash + 1, #lvlName)
        print(gLoadedName)
    else
        gLoadedName = lvlName
    end
    member("level Name").text = lvlName
    --objFileio.writeString(string(l))

    local f = io.open(pth .. lvlName .. ".txt", "r")

    local l2
    if not f then
        print("[loadLevel] NO FILE")
    else
        l2 = f:read("a")
        f:close()

        -- unnecesarry
        -- string.gsub(l2, "\r\n", "\n")
        -- string.gsub(l2, "\r", "\n")
    end

    -- local l2 = objFileio.readFile()
    -- objFileio.closeFile()

    --sv2 = gLOprops.duplicate()

    -- TODO: Replace this shit with optimized method calls.
    local l1 = fromLingo(atLine(l2, 1))
    gLEProps.matrix = l1
    l1 = fromLingo(atLine(l2, 2))
    gTEProps = l1
    l1 = fromLingo(atLine(l2, 3))
    gEEprops = l1
    -- print("HERE2")
    l1 = fromLingo(atLine(l2, 4))
    -- print("HERE")
    gLightEProps = l1
    l1 = fromLingo(atLine(l2, 5))
    gLEVEL = l1
    l1 = fromLingo(atLine(l2, 6))

    gLOprops = l1

    --    if gLOprops = 0 then
    --       sv1 = [1, 1, 1]
    --    else
    if not gLOprops["light"] then
        gLOprops["light"] = 1
    end

    if not gTEProps["specialEdit"] then
        gTEProps["specialEdit"] = 0
    end

    if not gLOprops["size"] then
        gLOprops["size"] = point(52, 40)
    end

    if not gLOprops["extraTiles"] then
        gLOprops["extraTiles"] = list({ 1, 1, 1, 3 })
    end

    gLOprops.pals = list({ list({ detCol = color(255, 0, 0) }) })

    if fromLingo(atLine(l2, 7)) == nil then
        gCameraProps.cameras = list({ point(gLOprops.size.x * 10, gLOprops.size.y * 10) - point(35 * 20, 20 * 20) })
    else
        gCameraProps = fromLingo(atLine(l2, 7))
    end


    -- Extracted for efficiency
    local line8 = atLine(l2, 8)
    local parsedLine8 = fromLingo(line8)

    if (parsedLine8 == nil) or (not parsedLine8["waterLevel"]) then
        utils2.resetgEnvEditorProps()
    else
        gEnvEditorProps = parsedLine8
    end


    local line9 = atLine(l2, 9)
    local parsedLine9 = fromLingo(line9)

    if (parsedLine9 == nil) or (line9:sub(1, 6) ~= "[#prop") then -- = " color") then
        --  if (value(l2.line[9]) = void)or(chars(l2.line[9], 1, 6) = " color") then
        utils2.resetPropEditorProps()
    else
        gPEprops = parsedLine9
    end

    if not gPEprops["color"] then
        gPEprops["color"] = 0
    end

    if not gPEprops["props"] then
        gPEprops["props"] = list()
    end

    gTEProps.tmPos = point(2, 1)

    me.versionFix()

    member("lightImage").image = image((gLOprops.size.x * 20) + 300, (gLOprops.size.y * 20) + 300)
    local sav = member("lightImage")

    member("lightImage"):importFileInto(pth .. lvlName .. ".png")
    sav.name = "lightImage"

    if (member("lightImage").image.rect ~= rect(0, 0, (gLOprops.size.x * 20) + 300, (gLOprops.size.y * 20) + 300)) then
        local wantedRect = rect(0, 0, (gLOprops.size.x * 20) + 300, (gLOprops.size.y * 20) + 300)
        local img = image(wantedRect.width, wantedRect.height)

        -- Extracted for efficiency
        local lightImageMember = member("lightImage")
        local lightImageMemberRect = lightImageMember.image.rect

        img:copyPixels(
            -- source image
            lightImageMember.image,
            
            -- destination rectangle
            rect(wantedRect.width / 2, wantedRect.height / 2, wantedRect.width / 2, wantedRect.height / 2)
                + rect(-lightImageMemberRect.width / 2, -lightImageMemberRect.height / 2, lightImageMemberRect.width / 2, lightImageMemberRect.height / 2), 

            -- source rectangle
            lightImageMemberRect
        )
        member("lightImage").image = img
        print("Adapted light rect")
    end

    --global gLASTDRAWWASFULLANDMINI
    gLASTDRAWWASFULLANDMINI = 0


    print(pth .. lvlName .. ".png")
end

function me.versionFix()
    --  gTEProps.tlMatrix[(tl[2])][(tl[3])][layer].data
    --global gNotFoundTiles
    local utils = require('comEditorUtils')

    gNotFoundTiles = list()
    for q = 1, gLOprops.size.x do
        for c = 1, gLOprops.size.y do
            for d = 1, 3 do
                gTEProps.tlMatrix[q][c][d].data = gTEProps.tlMatrix[q][c][d].data or gTEProps.tlMatrix[q][c][d].Data

                if gTEProps.tlMatrix[q][c][d].tp == "tileHead" then
                    local huntNew = ""
                    local tlData = gTEProps.tlMatrix[q][c][d].data
                    if #tlData < 2 then
                        huntNew = tlData.nm
                    else
                        local pnt = tlData[1]
                        if #gTiles >= pnt.x then
                            if #gTiles[pnt.x].tls >= pnt.y then
                                if gTiles[pnt.x].tls[pnt.y].nm ~= tlData[2] then
                                    huntNew = tlData[2]
                                    --  put huntNew
                                end
                            else
                                huntNew = tlData[2]
                            end
                        else
                            huntNew = tlData[2]
                        end
                    end

                    -->changed fix to PJB's one
                    local found = false
                    if huntNew ~= "" then
                        gTEProps.tlMatrix[q][c][d].data = list({ point(2, 1), "NOT FOUND" })
                        for cat = 1, #gTiles do
                            -- Skip material categories
                            if not gTiles[cat]["clr"] then
                                goto continue1
                            end
                            -- Check tiles
                            for tl = 1, #gTiles[cat].tls do
                                if gTiles[cat].tls[tl].nm == huntNew then
                                    gTEProps.tlMatrix[q][c][d].data = list({ point(cat, tl), huntNew })
                                    found = true
                                    break
                                end
                            end
                            if found then
                                break
                            end

                            ::continue1::
                        end

                        if not found then
                            utils.writeException("Tile Not Found",
                                "the tile \"" ..
                                huntNew .. "\" is missing in the Init.txt file from your Graphics folder.")
                            print("Warning: unknown tile '" .. huntNew .. "' in map file. Replacing with default material.")
                            if gNotFoundTiles:getPos(huntNew) == 0 then
                                gNotFoundTiles:add(huntNew)
                                _player.alert("Warning: unknown tile '" ..
                                huntNew .. "' in map file. Replacing with default material.")
                            end
                            gTEProps.tlMatrix[q][c][d] = map({ tp = "default", data = 0 })
                        end
                    else
                        gTEProps.tlMatrix[q][c][d].Data = nil
                        gTEProps.tlMatrix[q][c][d].data = tlData
                    end
                    --          if gTEProps.tlMatrix[q][c][d].data = [point(2, 1), "NOT FOUND"] then
                    --            writeException("Tile Not Found", "the tile "&QUOTE& huntNew &QUOTE&" is missing in the Init.txt file from your Graphics folder.")
                    --            gTEProps.tlMatrix[q][c][d].data = [point(3, 1), "Small Stone"]
                    --          end
                end
            end
        end
    end

    for q = 1, #gLEProps.toolMatrix do
        for c = 1, #gLEProps.toolMatrix[1] do
            if gLEProps.toolMatrix[q][c] == "save" then
                gLEProps.toolMatrix[q][c] = ""
            end
        end
    end

    --global gProps
    for q = 1, #gPEprops.props do
        local correctReference = true
        if (gPEprops.props[q][3].x > #gProps) then
            correctReference = false
        elseif (gPEprops.props[q][3].y > #gProps[gPEprops.props[q][3].x].prps) then
            correctReference = false
        elseif (gProps[gPEprops.props[q][3].x].prps[gPEprops.props[q][3].y].nm ~= gPEprops.props[q][2]) then
            correctReference = false
        end

        if (correctReference == false) then
            for a = 1, #gProps do
                for b = 1, #gProps[a].prps do
                    if (gProps[a].prps[b].nm == gPEprops.props[q][2]) then
                        correctReference = true
                        gPEprops.props[q][3] = point(a, b)
                        break
                    end
                end
                if correctReference == true then
                    break
                end
            end
        end

        if #gPEprops.props[q] == 4 then
            gPEprops.props[q]:add(map({ settings = clone(gProps[gPEprops.props[q][3].x].prps[gPEprops.props[q][3].y]
            .settings) }))
        end

        if (correctReference == false) then
            utils.writeException("Prop Not Found",
                "the prop \"" ..
                tostring(gPEprops.props[q][2]) .. "\" is missing in the Init.txt file from your Props folder.")
            gPEprops.props[q][3] = point(1, 1)
        end
    end

    if not gLEVEL["waterDrips"] then
        gLEVEL["waterDrips"] = 1
    end
    if not gLEVEL["tags"] then
        gLEVEL["tags"] = list()
    end
    if gLEVEL["lightDynamic"] then
        gLEVEL["lightDynamic"] = nil
        gLEVEL["lightType"] = "Static"
        -- gLEVEL:deleteProp("lightDynamic")
        -- gLEVEL:addProp("lightType", "Static")

    end
    if gLEVEL["lightBlend"] then
        gLEVEL["lightBlend"] = nil
    end

    if not gLOprops["tileSeed"] then
        gLOprops["tileSeed"] = random(400)
    end

    if not gLOprops["colGlows"] then
        gLOprops["colGlows"] = list({0, 0})
    end

    if not gLEProps["camPos"] then
        gLEProps["camPos"] = point(0, 0)
    end

    if not gCameraProps["quads"] then
        gCameraProps["quads"] = list()
        for q = 1, #gCameraProps.cameras do
            --   gCameraProps.quads:add([[0,0],[0,0],[0,0],[0,0]])
            table.insert(gCameraProps.quads, list({ { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }))
        end
    end

    if not gLEVEL["music"] then
        gLEVEL["music"] = "NONE"
    end

    for _, ef in ipairs(gEEprops.effects) do
        ef.Options = list(ef.Options or ef.options)

        ----Effect update
        local cEff = nil
        if gCustomEffects:getPos(ef.nm) > 0 then
            for i = 1, #gEffects do
                local iefs = gEffects[i].efs
                for j = 1, #iefs do
                    local ijef = iefs[j]
                    if ijef.nm == ef.nm then
                        cEff = ijef
                        break
                    end
                end
                if cEff ~= nil then
                    break
                end
            end
        end
        local sd = 0
        local rotOp = 0
        local clr = 0
        local gaf = 0
        local lay = 0
        local _3dOp = 0
        local sideOp = 0
        local srfOp = 0
        for _, op3 in ipairs(ef.Options) do
            if (op3[1] == "Seed") then
                sd = 1
            elseif (op3[1] == "3D") then
                _3dOp = 1
            elseif (op3[1] == "Rotate") then
                rotOp = 1
            elseif (op3[1] == "Side") then
                sideOp = 1
            elseif (op3[1] == "Color") then
                clr = 1
                if (op3[2] ~= list({ "Color1", "Color2", "Dead" })) then
                    op3[2] = list({ "Color1", "Color2", "Dead" })
                end
            elseif (op3[1] == "Affect Gradients and Decals") then
                gaf = 1
            elseif (op3[1] == "Layers") then
                lay = 1
                if ef.nm == "Mosaic Plants" then
                    if op3[2] ~= list({ "1", "2", "1:st and 2:nd" }) then
                        op3[2] = list({ "1", "2", "1:st and 2:nd" })
                    end
                elseif (op3[2] ~= list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" })) then
                    op3[2] = list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" })
                end
            elseif (op3[1] == "Require In-Bounds") then
                srfOp = 1
            end
        end

        -- Custom effects
        if (cEff ~= nil) then
            if (sideOp == 0) then
                if list({ "clinger", "standardClinger" }).findPos(cEff.tp) > 0 then
                    ef.Options:add(list({ "Side", list({ "Left", "Right", "Random" }), "Random" }))
                end
            end
            if (cEff.tp == "grower" or cEff.tp == "hanger" or cEff.tp == "clinger") and (srfOp == 0) then
                ef.Options:add({ "Require In-Bounds", list({ "Yes", "No" }), ({ "No", "Yes" })
                    [toint(utils.getBoolConfig("Sky roots fix")) + 1] })
            end
            if (_3dOp == 0) then
                if cEff.tp == "wall" and cEff:findPos("can3D") > 0 then
                    if cEff.can3D == 2 then
                        ef.Options:add(list({ "3D", list({ "On", "Off" }), "Off" }))
                    end
                end
            end
            if (clr == 0) then
                if cEff:findPos("pickColor") > 0 then
                    if cEff.pickColor == 1 then
                        ef.Options:add(list({ "Color", list({ "Color1", "Color2", "Dead" }), "Color2" }))
                    end
                end
            end
        end

        -- Seed
        if (sd == 0) then
            ef.Options:add(list({ "Seed", list(), random(500) }))
        end

        -- Fix layers
        if (lay == 0) and (list({ "BlackGoo", "Super BlackGoo", "Stained Glass Properties" }):getPos(ef.nm) == 0) then
            if (cEff ~= nil) then
                if cEff.tp == "individual" then
                    ef.Options:add(list({ "Layers", list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" }), "1" }))
                else
                    ef.Options:add(list({ "Layers", list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" }), "1" }))
                end
            elseif (list({ "Fungi Flowers", "Lighthouse Flowers", "Colored Fungi Flowers", "Colored Lighthouse Flowers", "Fern", "Giant Mushroom", "Sprawlbush", "featherFern", "Fungus Tree", "Head Lamp" }):getPos(ef.nm) > 0) then
                ef.Options:add(list({ "Layers", list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" }), "1" }))
            else
                ef.Options.add(list({ "Layers", list({ "All", "1", "2", "3", "1:st and 2:nd", "2:nd and 3:rd" }), "1" }))
            end
        end

        -- Some other missing Options
        if (rotOp == 0) and (ef.nm == "Little Flowers") then
            ef.Options:add(list({ "Rotate", list({ "On", "Off" }), "Off" }))
        end
        if (clr == 0) and (ef.nm == "DaddyCorruption") then
            ef.Options:add(list({ "Color", list({ "Color1", "Color2", "Dead" }), "Color2" }))
        end
        if (gaf == 0) and (list({ "Melt", "Super Melt", "Destructive Melt", "Rust", "Barnacles" }):getPos(ef.nm) > 0) then
            ef.Options:add(list({ "Affect Gradients and Decals", list({ "Yes", "No" }), "No" }))
        end
        if (gaf == 0) and (list({ "Slime", "SlimeX3", "Fat Slime" }):getPos(ef.nm) > 0) then
            ef.Options:add(list({ "Affect Gradients and Decals", list({ "Yes", "No" }), "Yes" }))
        end

        -- Sky roots fix
        if (srfOp == 0) and list({ "Arm Growers", "Growers", "Mini Growers", "Rollers", "Thorn Growers", "Garbage Spirals", "Fuzzy Growers", "Spinets", "Small Springs", "Hang Roots", "Thick Roots", "Shadow Plants", "Colored Hang Roots", "Colored Thick Roots", "Colored Shadow Plants", "Root Plants", "Coral Growers", "Leaf Growers", "Meat Growers", "Horror Growers", "Thunder Growers", "Ice Growers", "Grass Growers", "Fancy Growers", "Mosaic Plants", "Grape Roots", "Hand Growers" }):getPos(ef.nm) > 0 then
            ef.Options:add(list({ "Require In-Bounds", list({ "Yes", "No" }), ({ "Yes", "No" })
                [toint(utils.getBoolConfig("Sky roots fix")) + 1] }))
        end

        -- Cross screen
        if not ef["crossScreen"] then
            ef["crossScreen"] = 0
        end
        if (list({ "Arm Growers", "Growers", "Mini Growers", "Rollers", "Thorn Growers", "Garbage Spirals", "Fuzzy Growers", "Spinets", "Small Springs", "Wires", "Chains", "Colored Wires", "Colored Chains", "Hang Roots", "Thick Roots", "Shadow Plants", "Colored Hang Roots", "Colored Thick Roots", "Colored Shadow Plants", "Root Plants", "Coral Growers", "Leaf Growers", "Meat Growers", "Horror Growers", "Thunder Growers", "Ice Growers", "Grass Growers", "Fancy Growers", "Mosaic Plants", "Grape Roots", "Hand Growers" }):getPos(ef.nm) > 0) then
            ef.crossScreen = 1
        end

        -- Joar you're silly
        if (list({ "Slime", "Fat Slime", "Scales", "SlimeX3", "DecalsOnlySlime", "Melt", "Rust", "Barnacles", "Colored Barnacles", "Clovers", "Erode", "Sand", "Super Erode", "Ultra Super Erode", "Roughen", "Impacts", "Super Melt", "Destructive Melt" }):getPos(ef.nm) > 0) then
            ef.tp = "standardErosion"
        else
            ef.tp = "nn"
        end

        -- Erosion settings
        if (ef.nm == "Roughen") then
            ef.repeats = 30
            ef.affectOpenAreas = 0.05
        elseif (ef.nm == "Impacts") then
            ef.repeats = 75
            ef.affectOpenAreas = 0.05
        elseif (ef.nm == "Rust") then
            ef.repeats = 60
            ef.affectOpenAreas = 0.2
        elseif (ef.nm == "Clovers") then
            ef.repeats = 20
            ef.affectOpenAreas = 0.2
        elseif (ef.nm == "SlimeX3") then
            ef.repeats = 390
            ef.affectOpenAreas = 0.5
        elseif (ef.nm == "Fat Slime") then
            ef.repeats = 200
            ef.affectOpenAreas = 0.5
        elseif (list({ "Slime", "DecalsOnlySlime" }):getPos(ef.nm) > 0) then
            ef.repeats = 130
            ef.affectOpenAreas = 0.5
        elseif (list({ "Erode", "Sand" }):getPos(ef.nm) > 0) then
            ef.repeats = 80
            ef.affectOpenAreas = 0.5
        elseif (list({ "Super Melt", "Destructive Melt" }):getPos(ef.nm) > 0) then
            ef.repeats = 50
            ef.affectOpenAreas = 0.5
        elseif (list({ "Barnacles", "Colored Barnacles" }):getPos(ef.nm) > 0) then
            ef.repeats = 60
            ef.affectOpenAreas = 0.3
        elseif (list({ "Melt", "Super Erode", "Ultra Super Erode" }):getPos(ef.nm) > 0) then
            ef.repeats = 60
            ef.affectOpenAreas = 0.5
        end
    end
end

return me
