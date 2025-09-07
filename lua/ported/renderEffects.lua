-- global vertRepeater, r, gEEprops, solidMtrx, gLEprops, colr, colrDetail, colrInd, gdLayer, gdDetailLayer, gdIndLayer, gLOProps, gLevel, gEffectProps, gViewRender, keepLooping, gRenderCameraTilePos, effectSeed, lrSup, chOp, fatOp, gradAf, effectIn3D, gAnyDecals, gRotOp, slimeFxt, DRDarkSlimeFix, DRWhite, DRPxl, DRPxlRect, colrIntensity, fruitDensity, leafDensity, mshrSzW, mshrSz, hasFlowers, effSide, fingerLen, fingerSz, gCustomEffects, gEffects, gLastImported, skyRootsFix, lampColr, lampLayer

local me = {}

local utils = require('comEditorUtils')
local fiffigt = require('fiffigt')
local spelrelaterat = require('spelrelaterat')

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
    --   go the frame
    end
  else
    while keepLooping do
      me.newFrame()
    end
  end
end

function me.newFrame()
    vertRepeater = vertRepeater + 1
    local efcnt = #gEEprops.effects
    
  if (efcnt == 0) then
    keepLooping = false
    return
  elseif (r == 0) then
    vertRepeater = 1
    r = 1
    me.initEffect()
  end

  local efcsc = gEEprops.effects[r].crossScreen
  if ((vertRepeater > 60) and (efcsc == 0)) or ((vertRepeater > gLOprops.size.y) and (efcsc == 1)) then
    me.exitEffect()
    r = r + 1
    if (r > efcnt) then
      keepLooping = false
      return
    else
      me.initEffect()
      vertRepeater = 1
    end
  end
  local effectr = gEEprops.effects[r]
  if (effectr.crossScreen == 0) then
    -- sprite(59).y = vertRepeater * 20
    for q = 1, 100 do
      local q2 = q + gRenderCameraTilePos.x
      local c2 = vertRepeater + gRenderCameraTilePos.y

      if (q2 > 0) then
        if (q2 <= gLOprops.size.x) then
            if (c2 > 0) then
                if (c2 <= gLOprops.size.y) then
              me.effectOnTile(q, vertRepeater, q2, c2, effectr)
            end
          end
        end
      end
    end
  else
    local repmcam = vertRepeater - gRenderCameraTilePos.y
    -- sprite(59).y = repmcam * 20
    for q2 = 1, gLOprops.size.x do
      me.effectOnTile(q2 - gRenderCameraTilePos.x, repmcam, q2, vertRepeater, effectr)
    end
  end
end

function me.effectOnTile(q, c, q2, c2, effectr)
    if effectr.mtrx[q2][c2] > 0 then
    local efname = effectr.nm
    local savSeed = randomSeed
    randomSeed = spelrelaterat.seedForTile(point(q2, c2), effectSeed)
    
    local nameCase = efname
    
    if (nameCase == "Slime") or (nameCase == "Rust") or (nameCase == "Barnacles") or
        (nameCase == "Erode") or (nameCase == "Melt") or (nameCase ==  "Roughen") or
        (nameCase == "SlimeX3") or (nameCase == "Destructive Melt") or (nameCase == "Super Melt") or
        (nameCase == "Super Erode") or (nameCase == "DecalsOnlySlime") or (nameCase == "Ultra Super Erode") or
        (nameCase == "Colored Barnacles") or (nameCase == "Sand") or (nameCase == "Impacts") or (nameCase == "Fat Slime") then
            require("StandardEffects").applyStandardErosion(q,c,0, efname, effectr)
    
    elseif (nameCase == "Root Grass") or (nameCase == "Cacti") or (nameCase == "Rubble") or (nameCase == "Rain Moss") or
        (nameCase == "Dandelions") or (nameCase == "Seed Pods") or (nameCase == "Grass") or (nameCase == "Horse Tails") or
        (nameCase == "Circuit Plants") or (nameCase == "Feather Plants") or (nameCase == "Storm Plants") or (nameCase == "Colored Rubble") or
        (nameCase == "Reeds") or (nameCase == "Layenders") or (nameCase == "Seed Grass") or (nameCase == "Hyacinths") or (nameCase == "Orb Plants") or 
        (nameCase == "Lollipop Mold") or (nameCase == "Og Grass") then

        require("StandardEffects").applyStandardPlant(q,c,0, efname)
    
    elseif (nameCase == "Sprawlbush") or (nameCase == "featherFern") or (nameCase == "Fungus Tree") or
        (nameCase == "Head Lamp") then
        if effectr.mtrx[q2][c2] > 0 then
            require("StandardEffects").apply3Dsprawler(q,c, efname)
        end
    
    elseif (nameCase == "Sprawlroots") or (nameCase == "Fungus Roots") or (nameCase == "Ceiling Lamp") then
        if effectr.mtrx[q2][c2] > 0 then
          require("StandardEffects").applyInverse3Dsprawler(q,c,efname)
        end
    
    elseif (nameCase == "Growers") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
          require("JoarEffects").applyHugeFlower(q,c,0)
        end

    elseif (nameCase == "Arm Growers") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
          require("JoarEffects").ApplyArmGrower(q,c,0)
        end

    elseif (nameCase == "Thorn Growers") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
          require("JoarEffects").ApplyThornGrower(q,c,0)
        end

    elseif (nameCase == "hang roots") then
        for r2 = 1, 3 do
          if (random(100)<effectr.mtrx[q2][c2]) then
            require("JoarEffects").applyHangRoots(q,c,0)
          end
        end

    elseif (nameCase == "Thick Roots") then
        if (random(100)<effectr.mtrx[q2][c2]) then
          require("JoarEffects").applyThickRoots(q,c,0)
        end

    elseif (nameCase == "Rollers") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(5)==1) then
          require("JoarEffects").ApplyRoller(q,c,0)
        end

    elseif (nameCase == "Garbage Spirals") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(6)==1) then
          require("JoarEffects").ApplyGarbageSpiral(q,c,0)
        end

    elseif (nameCase == "Shadow Plants") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)==1) then
          require("JoarEffects").applyShadowPlants(q,c,0)
        end

    elseif (nameCase == "Wires") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
          require("JoarEffects").applyWire(q,c,0)
        end

    elseif (nameCase == "Chains") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
          require("JoarEffects").applyChain(q,c,0)
        end

    elseif (nameCase == "Fungi Flowers") then
        if effectr.mtrx[q2][c2] > 0 then
          require("JoarEffects").applyFungiFlower(q,c)
        end
    
    elseif (nameCase == "Lighthouse Flowers") then
        if effectr.mtrx[q2][c2] > 0 then
          require("JoarEffects").applyLHFlower(q,c)
        end

    elseif (nameCase == "Fern") or (nameCase == "Giant Mushroom") then
        if effectr.mtrx[q2][c2] > 0 then
          require("JoarEffects").applyBigPlant(q,c)
        end

    elseif nameCase == "BlackGoo" then
        require("JoarEffects").applyBlackGoo(q,c,0)
    
    elseif nameCase == "DarkSlime" then
        require("JoarEffects").applyDarkSlime(q,c, effectr)
    
    elseif (nameCase == "Restore As Scaffolding") or (nameCase == "Restore As Pipes") then
        require("JoarEffects").applyRestoreEffect(q,c, q2, c2, efname)
    
    elseif nameCase == "DaddyCorruption" then
        require("JoarEffects").applyDaddyCorruption(q,c,effectr.mtrx[q2][c2])
    
    elseif nameCase == "Corruption No Eye" then
        require("JoarEffects").applyCorruptionNoEye(q,c,effectr.mtrx[q2][c2])
    
    elseif nameCase == "Slag" then-->to support older projects
        require("JoarEffects").applyCorruptionNoEye(q,c,effectr.mtrx[q2][c2])
      
    -- LB effects
    elseif nameCase == "LSlime" then
        require('LSlime').DRFSlimeApply(q, c, effectr)
    
    elseif nameCase == "Dense Mold" then
        require("LBEffects").applyWLPlant(q, c)

    elseif nameCase == "Mini Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1)then
          require("LBEffects").applyMiniGrowers(q,c,0)
        end

    elseif nameCase == "Colored Fungi Flowers" then
        if (gdLayer == "C") then
          if effectr.mtrx[q2][c2] > 0 then
            require("JoarEffects").applyFungiFlower(q,c)
          end
        else
          if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyColoredFungiFlower(q,c)
          end
        end

    elseif nameCase == "Colored Lighthouse Flowers" then
        if (gdLayer == "C") then
          if effectr.mtrx[q2][c2] > 0 then
            require("JoarEffects").applyLHFlower(q,c)
          end
        else
          if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyColoredLHFlower(q,c)
          end
        end

    elseif nameCase == "Foliage" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyFoliage(q,c)
        end
    elseif nameCase == "Assorted Trash" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyAssortedTrash(q,c)
        end
    elseif nameCase == "High Grass" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyHighGrass(q,c)
        end
    elseif nameCase == "Small Springs" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applySmallSprings(q,c)
        end
    elseif nameCase == "High Fern" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyHighFern(q,c)
        end
    elseif nameCase == "Mistletoe" then
        if effectr.mtrx[q2][c2] > 0 then
            require("LBEffects").applyMistletoe(q,c)
        end
    elseif nameCase == "Colored Hang Roots" then
        if (gdLayer == "C") then
            for r2 = 1, 3 do
                if (random(100)<effectr.mtrx[q2][c2]) then
                    require("JoarEffects").applyHangRoots(q,c,0)
                end
            end
        else
            for r2 = 1, 3 do
                if (random(100)<effectr.mtrx[q2][c2]) then
                    require("LBEffects").applyColoredHangRoots(q,c,0)
                end
            end
        end
    elseif nameCase == "Clovers" then
        require("LBEffects").applyResRoots(q,c)
        require("StandardEffects").applyStandardErosion(q,c,0, efname, effectr)
        
    elseif nameCase == "Colored Wires" then
        if (gdIndLayer == "C") then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("JoarEffects").applyWire(q,c,0)
        end
        else
            if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
                require("LBEffects").applyColoredWires(q,c,0)
            end
        end
    elseif nameCase == "Colored Chains" then
        if (gdIndLayer == "C") then
            if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
                require("JoarEffects").applyChain(q,c,0)
            end
        else
            if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
                require("LBEffects").applyColoredChains(q,c,0)
            end
        end
    elseif nameCase == "Ring Chains" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("LBEffects").applyRingChains(q,c,0)
        end
        
    elseif nameCase == "Spinets" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("LBEffects").ApplySpinets(q,c,0)
        end
        
    elseif nameCase == "Colored Thick Roots" then
        if (gdLayer == "C") then
            if (random(100)<effectr.mtrx[q2][c2]) then
                require("JoarEffects").applyThickRoots(q,c,0)
            end
        else
            if (random(100)<effectr.mtrx[q2][c2]) then
                require("LBEffects").applyColoredThickRoots(q,c,0)
            end
        end
    elseif nameCase == "Colored Shadow Plants" then
        if (gdLayer == "C") then
            if (random(100)<effectr.mtrx[q2][c2]) and (random(3)==1) then
                require("JoarEffects").applyShadowPlants(q,c,0)
            end
        else
            if (random(100)<effectr.mtrx[q2][c2]) and (random(3)==1) then
                require("LBEffects").applyColoredShadowPlants(q,c,0)
            end
        end
    elseif nameCase == "Root Plants" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)==1) then
            require("LBEffects").applyRootPlants(q,c,0)
        end
        
    elseif nameCase == "Wastewater Mold" then
        if (gdLayer == "C") then
            require("JoarEffects").applyCorruptionNoEye(q,c,effectr.mtrx[q2][c2])
        else
            require("LBEffects").applyWastewaterMold(q,c,effectr.mtrx[q2][c2])
        end
    elseif nameCase == "Little Flowers" then
        require("LBEffects").applyFlowers(q,c,effectr.mtrx[q2][c2])
        
        -- Leo
    elseif nameCase == "Ivy" then
        for r2 = 1,3 do
            if (random(100)<effectr.mtrx[q2][c2]) then
                require("MiscEffects").applyIvy(q,c,0)
            end
        end

    -- Dakras
    elseif nameCase == "Left Facing Kelp" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("DakrasEffects").ApplySideKelp(q,c)
        end
    elseif nameCase == "Right Facing Kelp" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("DakrasEffects").ApplyFlipSideKelp(q,c)
        end
    elseif nameCase == "Mixed Facing Kelp" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("DakrasEffects").ApplyMixKelp(q,c)
        end
    
    elseif nameCase == "Bubble Grower" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(2)==1) then
            require("DakrasEffects").ApplyBubbleGrower(q,c)
        end
    
    elseif nameCase == "Moss Wall" then
        require("DakrasEffects").applyMossWall(q,c,effectr.mtrx[q2][c2])
    
    elseif nameCase == "Club Moss" then
        require("DakrasEffects").applyClubMoss(q,c,effectr.mtrx[q2][c2])
    
    -- Nautillo
    elseif nameCase == "Horror Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("NautilloEffects").ApplyHorrorGrower(q,c,0)
        end

    elseif nameCase == "Fuzzy Growers" then
        if (random(100) < effectr.mtrx[q2][c2]) and (random(3) > 1) then
            require("NautilloEffects").ApplyFuzzyGrower(q, c)
        end
    elseif nameCase == "Coral Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("NautilloEffects").ApplyCoralGrower(q,c,0)
        end
    elseif nameCase == "Leaf Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("NautilloEffects").ApplyLeafGrower(q,c,0)
        end
    elseif nameCase == "Meat Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("NautilloEffects").ApplyMeatGrower(q,c,0)
        end
    
    -- Tronsx
    elseif nameCase == "Thunder Growers" then
        if (random(100) < effectr.mtrx[q2][c2]) and (random(3) > 1) then
            require("MiscEffects").ApplyThunderGrower(q,c,0)
        end
    
    -- Intrepid
    elseif nameCase == "Fancy Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("IntrepidEffects").ApplyFancyGrower(q,c,0)
        end
    elseif nameCase == "Ice Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("IntrepidEffects").ApplyIceGrower(q,c,0)
        end
    elseif nameCase == "Grass Growers" then
        if (random(100)<effectr.mtrx[q2][c2]) and (random(3)>1) then
            require("IntrepidEffects").ApplyGrassGrower(q,c,0)
        end
        
    -- Ludocrypt
    elseif nameCase == "Mushroom Stubs" then
        require("MiscEffects").applyMushroomStubs(q,c,effectr.mtrx[q2][c2])
    
    -- Alduris
    elseif nameCase == "Mosaic Plants" then
        require("AldurisEffects").ApplyMosaicPlant(q, c)
    elseif nameCase == "Cobwebs" then
        require("AldurisEffects").ApplyCobweb(q, c)
    elseif nameCase == "Fingers" then
        require("AldurisEffects").ApplyFingers(q, c)
    
    -- April
    elseif nameCase == "Grape Roots" then
        for r2 = 1, 3 do
            if (random(100) < effectr.mtrx[q2][c2]) then
                require("AprilEffects").applyGrapeRoots(q, c, 0)
            end
        end

    elseif nameCase == "Hand Growers" then
        require("AprilEffects").applyHandGrowers(q, c, 0)
    elseif nameCase == "Spindles" then
        require("AprilEffects").applySpindle(q,c,0)
    elseif nameCase == "Wire Bunches" then
        require("AprilEffects").applyWireBunch(q,c,0)
    elseif nameCase == "Box Grubs" then
        require("AprilEffects").applyJoarFW(q,c,0)
    
    else
        -- Custom effects system
        if (getPos(gCustomEffects, efname) > 0) then
            require("StandardEffects").ApplyCustomEffect(q, c, effectr, efname)
        end
    end
  

      
    randomSeed = savSeed
  end
end

function me.initEffect()
  local effectr = gEEprops.effects[r]
  local efopts =  effectr.options or effectr.Options
  effectSeed = 0
  
    for a = 1, #efopts do
        local curop = efopts[a]
        
        if(curop[1] == "Seed")then
            effectSeed = curop[3]
            break
        end
  
    end
  
  effectIn3D = false
  gRotOp = false
  skyRootsFix = false
  
  for _,op in ipairs(efopts) do
    local opt = op[1]

    -- local lrSup
    -- local colr
    -- local gdLayer
    -- local colrDetail
    -- local gdDetailLayer
    -- local colrInd
    -- local gdIndLayer
    -- local effectIn3D
    -- local gRotOp
    -- local fatOp
    -- local chOp
    -- local gradAf
    -- local colrIntensity
    -- local fruitDensity
    -- local leafDensity
    -- local mshrSz
    -- local mshrSzW
    -- local hasFlowers
    -- local effSide
    -- local fingerSz
    -- local fingerLen
    -- local lampColr
    -- local LampLayer

    if (opt == "Layers") then
        local selector = {}
        selector["All"] = "All"
        selector["1"] = "1"
        selector["2"] = "2"
        selector["3"] = "3"
        selector["1:st and 2:nd"] = "1:st and 2:nd"
        selector["1:st and 2:nd"] = "1:st and 2:nd"
        selector["2:nd and 3:rd"] = "2:nd and 3:rd"

        lrSup = selector[op[3]]
    
    elseif (opt == "Color") then
        local selector = {}
        selector["Color1"] = color(255, 0, 255)
        selector["Color2"] = color(0, 255, 255)
        selector["Dead"] = color(0, 255, 0)

        ---@type color?
        colr = selector[op[3] or "Dead"] or color(0, 255, 0)

        selector["Color1"] = "A"
        selector["Color2"] = "B"
        selector["Dead"] = "C"

        ---@type string?
        gdLayer = selector[op[3]]

    elseif (opt == "Detail Color") then
        local selector = {}
        selector["Color1"] = color(255, 0, 255)
        selector["Color2"] = color(0, 255, 255)
        selector["Dead"] = color(0, 255, 0)

        colrDetail = selector[op[3]]

        selector["Color1"] = "A"
        selector["Color2"] = "B"
        selector["Dead"] = "C"

        gdDetailLayer = selector[op[3]]

    elseif (opt == "Effect Color") then
        local selector = {}
        selector["EffectColor1"] = color(255, 0, 255)
        selector["EffectColor2"] = color(0, 255, 255)
        selector["None"] = color(0, 255, 0)

        colrInd = selector[op[3]]

        selector["EffectColor1"] = "A"
        selector["EffectColor2"] = "B"
        selector["None"] = "C"

        gdIndLayer = selector[op[3]]

    elseif (opt == "Seed") then
        randomSeed = op[3]

    elseif (opt == "3D") then
        effectIn3D = (op[3] == "On")

    elseif (opt == "Rotate") then
        gRotOp = (op[3] == "On")

    elseif (opt == "Fatness") then
        local selector = {}
        selector["1px"] = "1px"
        selector["2px"] = "2px"
        selector["3px"] = "3px"
        selector["random"] = "random"
        
        fatOp = selector[op[3]]

    elseif (opt == "Size") then
        local selector = {}
        selector["Small"] = "Small"
        selector["FAT"] = "FAT"

        chOp = selector[op[3]]

    elseif (opt == "Affect Gradients and Decals") then
        gradAf = (op[3] == "Yes")

    elseif (opt == "Color Intensity") then
        local selector = {}
        selector["High"] = "H"
        selector["Medium"] = "M"
        selector["Low"] = "L"
        selector["None"] = "N"
        selector["Random"] = "R"

        colrIntensity = selector[op[3]]

    elseif (opt == "Fruit Density") then
        local selector = {}
        selector["High"] = "H"
        selector["Medium"] = "M"
        selector["Low"] = "L"
        selector["None"] = "N"

        fruitDensity = selector[op[3]]

    elseif (opt == "Leaf Density") then
        leafDensity = op[3]
    elseif (opt == "Mushroom Size") then
        local selector = {}
        selector["Small"] = "S"
        selector["Medium"] = "M"
        selector["Random"] = "R"

        mshrSz = selector[op[3]]
    
    elseif (opt == "Mushroom Width") then
        local selector = {}
        selector["Small"] = "S"
        selector["Medium"] = "M"
        selector["W"] = "L"
        selector["Random"] = "R"

        mshrSzW = selector[op[3]]

    elseif (opt == "Flowers") then
        hasFlowers = (op[3] == "On")

    elseif (opt == "Side") then
        local selector = {}
        selector["Left"] = "L"
        selector["Right"] = "R"
        selector["Top"] = "T"
        selector["Bottom"] = "B"

        effSide = selector[op[3]] or "?"

    elseif (opt == "Finger Thickness") then
        local selector = {}
        selector["Small"] = "S"
        selector["Medium"] = "M"
        selector["FAT"] = "L"

        fingerSz = selector[op[3]] or "?"

    elseif (opt == "Finger Length") then
        local selector = {}
        selector["Short"] = "S"
        selector["Medium"] = "M"
        selector["Tall"] = "L"

        fingerLen = selector[op[3]] or "?"

    elseif (opt == "Lamp Color") then
        local selector = {}
        selector["Color1"] = color(255, 0, 255)
        selector["Color2"] = color(0, 255, 255)
        selector["Dead"] = color(0, 255, 0)

        lampColr = selector[op[3]]

        selector["Color1"] = "A"
        selector["Color2"] = "B"
        selector["Dead"] = "C"

        LampLayer = selector[op[3]]

    elseif (opt == "Require In-Bounds") then
        if (op[3] == "Yes") then
            skyRootsFix = true
        end

    end
  end

  local nameCase = effectr.nm

  if (nameCase == "BlackGoo") then
    local cols = 100
    local rows = 60
    
    member("blackOutImg1").image = image(cols*20, rows*20) -- 32
    local blk1 = member("blackOutImg1").image
    blk1:copyPixels(DRPxl, rect(0,0,cols*20, rows*20), rect(0,0,1,1), {color = color(0, 0, 0)})
    member("blackOutImg2").image = image(cols*20, rows*20) -- 32
    local blk2 = member("blackOutImg2").image
    blk2:copyPixels(DRPxl, rect(0,0,cols*20, rows*20), rect(0,0,1,1), {color = color(0, 0, 0)})
  --   sprite(57).visibility = 1
  --   sprite(58).visibility = 1
    
    for q = 1, 100 do
      for c = 1, 60 do
        local q2 = q + gRenderCameraTilePos.x
        local c2 = c + gRenderCameraTilePos.y
        if(q2 < 1)or(q2 > gLOprops.size.x)or(c2 < 1)or(c2 > gLOprops.size.y)then
          blk1:copyPixels(DRPxl, rect((q-1)*20, (c-1)*20, q*20, c*20), rect(0,0,1,1), {color=color(255, 255, 255)})
          blk2:copyPixels(DRPxl, rect((q-1)*20, (c-1)*20, q*20, c*20), rect(0,0,1,1), {color=color(255, 255, 255)})
        end
      end
    end
    
    local blobImg = member("blob").image
    local rct = blobImg.rect
    for q2 = 1, cols do
      for c2 = 1, rows do
        if(q2+gRenderCameraTilePos.x > 0)and(q2+gRenderCameraTilePos.x <= gLOprops.size.x)and(c2+gRenderCameraTilePos.y > 0)and(c2+gRenderCameraTilePos.y <= gLOprops.size.y)then
          local tile = point(q2,c2)+gRenderCameraTilePos
          
          if (effectr.mtrx[tile.x][tile.y] == 0) then
            local sPnt = spelrelaterat.giveMiddleOfTile(point(q2,c2))+point(-10,-10)--+gRenderCameraPixelPos--gRenderCameraTilePos-gRenderCameraPixelPos
            
            for d = 1, 10 do
              for e = 1, 10 do
                local ps = point(sPnt.x + d*2, sPnt.y + e*2)
                blk1:copyPixels(blobImg, rect(ps.x-6-random(random(11)),ps.y-6-random(random(11)),ps.x+6+random(random(11)),ps.y+6+random(random(11))), rct, {color = color(255, 255, 255), ink=36})
                blk2:copyPixels(blobImg, rect(ps.x-7-random(random(14)),ps.y-7-random(random(14)),ps.x+7+random(random(14)),ps.y+7+random(random(14))), rct, {color = color(255, 255, 255), ink=36})
                -- end 
              end
            end
          elseif ((getPos(gLEProps.matrix[tile.x][tile.y][1][2], 5) > 0)or(getPos(gLEProps.matrix[tile.x][tile.y][1][2], 4) > 0))and(gLEProps.matrix[tile.x][tile.y][2][1]==1) then
            local ps = spelrelaterat.giveMiddleOfTile(point(q2,c2))--+gRenderCameraPixelPos--gRenderCameraTilePos-gRenderCameraPixelPos
            blk1:copyPixels(blobImg, rect(ps.x-4-random(random(9)),ps.y-4-random(random(9)),ps.x+4+random(random(9)),ps.y+4+random(random(9))), rct, {color=color(255, 255, 255), ink=36})
            blk2:copyPixels(blobImg, rect(ps.x-7-random(random(9)),ps.y-7-random(random(9)),ps.x+7+random(random(9)),ps.y+7+random(random(9))), rct, {color=color(255, 255, 255), ink=36})
            blk1:copyPixels(blobImg, rect(ps.x-4-random(random(9)),ps.y-4-random(random(9)),ps.x+4+random(random(9)),ps.y+4+random(random(9))), rct, {color=color(255, 255, 255), ink=36})
            blk2:copyPixels(blobImg, rect(ps.x-7-random(random(9)),ps.y-7-random(random(9)),ps.x+7+random(random(9)),ps.y+7+random(random(9))), rct, {color=color(255, 255, 255), ink=36})
          end
        end
      end
    end
  elseif (nameCase == "Super BlackGoo") then
    local cols = 100
    local rows = 60
    
    member("blackOutImg1").image = image(cols*20, rows*20)
    local blk1 = member("blackOutImg1").image
    member("blackOutImg1").image:copyPixels(DRPxl, rect(0,0,cols*20, rows*20), rect(0,0,1,1), {color=color(255, 255, 255)})
    member("blackOutImg2").image = image(cols*20, rows*20)
    local blk2 = member("blackOutImg2").image
    member("blackOutImg2").image:copyPixels(DRPxl, rect(0,0,cols*20, rows*20), rect(0,0,1,1), {color=color(255, 255, 255)})
    -- sprite(57).visibility = 1
    -- sprite(58).visibility = 1
    
    for q = 1, 100 do
      for c = 1, 60 do
        local q2 = q + gRenderCameraTilePos.x
        local c2 = c + gRenderCameraTilePos.y
        if(q2 < 1)or(q2 > gLOprops.size.x)or(c2 < 1)or(c2 > gLOprops.size.y)then
          blk1:copyPixels(DRPxl, rect((q-1)*20, (c-1)*20, q*20, c*20), rect(0,0,1,1), {color=color(255, 255, 255)})
          blk2:copyPixels(DRPxl, rect((q-1)*20, (c-1)*20, q*20, c*20), rect(0,0,1,1), {color=color(255, 255, 255)})
        end
      end
    end
    
    local blobImg = member("blob").image
    local rct = blobImg.rect
    for q2 = 1, cols do
      for c2 = 1, rows do
        if(q2+gRenderCameraTilePos.x > 0)and(q2+gRenderCameraTilePos.x <= gLOprops.size.x)and(c2+gRenderCameraTilePos.y > 0)and(c2+gRenderCameraTilePos.y <= gLOprops.size.y)then
          local tile = point(q2,c2)+gRenderCameraTilePos
          
          if (gEEprops.effects[r].mtrx[tile.x][tile.y] == 0) then
            local sPnt = spelrelaterat.giveMiddleOfTile(point(q2,c2))+point(-10,-10)--+gRenderCameraPixelPos--gRenderCameraTilePos-gRenderCameraPixelPos
            
            for d = 1, 10 do
              for e = 1, 10 do
                local ps = point(sPnt.x + d*2, sPnt.y + e*2)
                -- if member("layer0").image.getPixel(ps) = color(255, 255, 255) then
                blk1:copyPixels(blobImg, rect(ps.x-6-random(random(11)),ps.y-6-random(random(11)),ps.x+6+random(random(11)),ps.y+6+random(random(11))), rct, {color=color(0, 0, 0), ink=36})
                blk2:copyPixels(blobImg, rect(ps.x-7-random(random(14)),ps.y-7-random(random(14)),ps.x+7+random(random(14)),ps.y+7+random(random(14))), rct, {color=color(0, 0, 0), ink=36})
                -- end 
              end
            end
          elseif ((gLEProps.matrix[tile.x][tile.y][1][2].getPos(5) > 0)or(gLEProps.matrix[tile.x][tile.y][1][2].getPos(4) > 0))and(gLEProps.matrix[tile.x][tile.y][2][1]==1) then
            local ps = spelrelaterat.giveMiddleOfTile(point(q2,c2))--+gRenderCameraPixelPos--gRenderCameraTilePos-gRenderCameraPixelPos
            blk1:copyPixels(blobImg, rect(ps.x-4-random(random(9)),ps.y-4-random(random(9)),ps.x+4+random(random(9)),ps.y+4+random(random(9))), rct, {color=color(0, 0, 0), ink=36})
            blk2:copyPixels(blobImg, rect(ps.x-7-random(random(9)),ps.y-7-random(random(9)),ps.x+7+random(random(9)),ps.y+7+random(random(9))), rct, {color=color(0, 0, 0), ink=36})
            blk1:copyPixels(blobImg, rect(ps.x-4-random(random(9)),ps.y-4-random(random(9)),ps.x+4+random(random(9)),ps.y+4+random(random(9))), rct, {color=color(0, 0, 0), ink=36})
            blk2:copyPixels(blobImg, rect(ps.x-7-random(random(9)),ps.y-7-random(random(9)),ps.x+7+random(random(9)),ps.y+7+random(random(9))), rct, {color=color(0, 0, 0), ink=36})
          end
        end
      end
    end
  elseif (nameCase == "Fungi Flowers") then
    local l = list({2,3,4,5})
    local l2 = list()
    for a = 1, 4 do
      local val = l[random(#l)]
      l2:add(val)
      l:deleteOne(val)
    end
    gEffectProps = {list=l2, listPos=1}
  elseif (nameCase == "Colored Fungi Flowers") then
    local l = list({2,3,4,5})
      local l2 = list()
      for a = 1, 4 do
        local val = l[random(#l)]
        l2:add(val)
        l:deleteOne(val)
      end
      gEffectProps = {list=l2, listPos=1}
  elseif (nameCase == "Lighthouse Flowers") then
    local l = list({1,2,3,4,5,6,7,8})
      local l2 = list()
      for a = 1, 8 do
        local val = l[random(#l)]
        l2:add(val)
        l:deleteOne(val)
      end
      gEffectProps = {list=l2, listPos=1}
    elseif (nameCase == "Colored Lighthouse Flowers") then
        local l = list({1,2,3,4,5,6,7,8})
        local l2 = list()
        for a = 1, 8 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "Foliage") then
        local l = list({1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28})
        local l2 = list()
        for a = 1, 28 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}
    elseif (nameCase == "Assorted Trash") then
        local l = list({
            1,2,3,4,5,6,7,8,9,10,11,12,
            13,14,15,16,17,18,19,20,21,
            22,23,24,25,26,27,28,29,30,
            31,32,33,34,35,36,37,38,39,
            40,41,42,43,44,45,46,47,48
        })
        local l2 = list()
        for a = 1, 48 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "High Grass") then
        local l = list({1,2,3,4})
        local l2 = list()
        for a = 1, 4 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "Small Springs") then
        local l = list({1,2,3,4,5,6,7})
        local l2 = list()
        for a = 1, 7 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "High Fern") then
        local l = list({1,2})
        local l2 = list()
        for a = 1, 2 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "Mistletoe") then
        local l = list({1,2,3,4,5,6})
        local l2 = list()
        for a = 1, 6 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "Fern") or (nameCase == "Giant Mushroom") or (nameCase == "Springs") then
        local l = list({1,2,3,4,5,6,7})
        local l2 = list()
        for a = 1, 7 do
            local val = l[random(#l)]
            l2:add(val)
            l:deleteOne(val)
        end
        gEffectProps = {list=l2, listPos=1}

    elseif (nameCase == "DaddyCorruption") then
        daddyCorruptionHoles = list()
    
    elseif (nameCase == "Mosaic Plants") then
        mosaicPlantStarts = list()
        require("AldurisEffects").InitMosaicPlants()
    end
  
--   txt = ""
--   put "<APPLYING EFFECTS>" after txt
--   put RETURN after txt
  
  for ef = 1, #gEEprops.effects do
    
    if ef == r then
    --   put string(ef)..". ->"..gEEprops.effects[ef].nm after txt
    else
    --   put string(ef)..". "..gEEprops.effects[ef].nm after txt
    end
    -- put RETURN after txt
  end
  
--   member("effectsL").text = txt
end

function me.exitEffect()
    local nameCase = gEEprops.effects[r].nm

    if nameCase == "BlackGoo" then
        local lr0 = member("layer0").buf
        lr0:copyPixels(member("blackOutImg1").image, rect(0,0,100*20, 60*20), rect(0,0,100*20, 60*20), {ink=36, color=color(0, 255, 0)})
        lr0:copyPixels(member("blackOutImg2").image, rect(0,0,100*20, 60*20), rect(0,0,100*20, 60*20), {ink=36, color=color(255, 0, 0)})


        member("blackOutImg1").image = image(1, 1) -- 1
        -- member("blackOutImg2").image = image(1, 1, 1)
        -- sprite(58).visibility = 0
        -- sprite(57).visibility = 0
        
    elseif nameCase == "Super BlackGoo" then
        local lr0 = member("layer0").buf
        lr0:copyPixels(member("blackOutImg1").image, rect(0,0,100*20, 60*20), rect(0,0,100*20, 60*20), {ink=36, color=color(0, 255, 0)})
        lr0:copyPixels(member("blackOutImg2").image, rect(0,0,100*20, 60*20), rect(0,0,100*20, 60*20), {ink=36, color=color(255, 0, 0)})
        
        
        member("blackOutImg1").image = image(1, 1) -- 1
        -- member("blackOutImg2").image = image(1, 1, 1)
        -- sprite(58).visibility = 0
        -- sprite(57).visibility = 0

    elseif nameCase == "DaddyCorruption" then
        for i = 1, #daddyCorruptionHoles do
          local qd = rotate(rect(daddyCorruptionHoles[i][1], daddyCorruptionHoles[i][1])+rect(-daddyCorruptionHoles[i][2],-daddyCorruptionHoles[i][2],daddyCorruptionHoles[i][2],daddyCorruptionHoles[i][2]), daddyCorruptionHoles[i][3])
          for d = 0, 1 do
            member("layer"..string(daddyCorruptionHoles[i][4]+d)).image:copyPixels(member("DaddyBulb").image, qd, rect(60, 1, 134, 74), {color=color(255, 255, 255), ink=36})
          end
          if(random(2)==1)and(random(100)>daddyCorruptionHoles[i][5])then
            member("layer"..string(daddyCorruptionHoles[i][4]+2)).image:copyPixels(member("DaddyBulb").image, qd, rect(60, 1, 134, 74), {color=color(255, 0, 0), ink=36})
          else
            if gdLayer == "A" then
                member("layer"..string(daddyCorruptionHoles[i][4]+2)).image:copyPixels(member("DaddyBulb").image, qd, rect(60, 1, 134, 74), {color=color(255, 0, 255), ink=36})
                spelrelaterat.copyPixelsToEffectColor("A", daddyCorruptionHoles[i][4]+2, rect(daddyCorruptionHoles[i][1], daddyCorruptionHoles[i][1])+rect(-daddyCorruptionHoles[i][2]*1.5,-daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5), "softBrush1", member("softBrush1").image.rect, 0.5, fiffigt.lerp(random(50)*0.01, 1.0, random(daddyCorruptionHoles[i][5])*0.01))
            elseif gdLayer == "B" then
                member("layer"..string(daddyCorruptionHoles[i][4]+2)).image:copyPixels(member("DaddyBulb").image, qd, rect(60, 1, 134, 74), {color=color(0, 255, 255), ink=36})
                spelrelaterat.copyPixelsToEffectColor("B", daddyCorruptionHoles[i][4]+2, rect(daddyCorruptionHoles[i][1], daddyCorruptionHoles[i][1])+rect(-daddyCorruptionHoles[i][2]*1.5,-daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5), "softBrush1", member("softBrush1").image.rect, 0.5, fiffigt.lerp(random(50)*0.01, 1.0, random(daddyCorruptionHoles[i][5])*0.01))
            else
                member("layer"..string(daddyCorruptionHoles[i][4]+2)).image:copyPixels(member("DaddyBulb").image, qd, rect(60, 1, 134, 74), {color=color(0, 255, 255), ink=36})
                spelrelaterat.copyPixelsToEffectColor("B", daddyCorruptionHoles[i][4]+2, rect(daddyCorruptionHoles[i][1], daddyCorruptionHoles[i][1])+rect(-daddyCorruptionHoles[i][2]*1.5,-daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5,daddyCorruptionHoles[i][2]*1.5), "softBrush1", member("softBrush1").image.rect, 0.5, fiffigt.lerp(random(50)*0.01, 1.0, random(daddyCorruptionHoles[i][5])*0.01))       
            end
          end
        end
        daddyCorruptionHoles = list()

    end
end



return me