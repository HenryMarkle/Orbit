-- global vertRepeater, r, gEEprops, solidMtrx, gLEprops, colr, colrDetail, colrInd, gdLayer, gdDetailLayer, gdIndLayer, gLOProps, gLevel, gEffectProps, gRenderCameraTilePos, effectSeed, lrSup, chOp, fatOp, gradAf, effectIn3D, gAnyDecals, gRotOp, slimeFxt, DRDarkSlimeFix, DRWhite, DRPxl, DRPxlRect, effSide, gCustomEffects, gEffects, gLastImported, skyRootsFix, lampColr, lampLayer

local me = {}

local utils = require('comEditorUtils')
local spelrelaterat = require('spelrelaterat')
local fiffigt = require('fiffigt')

local bit = require('bit')

function me.ApplyCustomEffect(me, q, c, effectr, efname)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  local mtrx = effectr.mtrx
  
  -- Find the effect
  local cEff = nil
  if (getPos(gCustomEffects, efname) > 0) then
    for i = 1, #gEffects do
      local iefs = gEffects[i].efs
      for j = 1, #iefs do
        local jef = iefs[j]
        if (jef.nm == efname) then
          cEff = jef
          break
        end
      end
      if (cEff ~= nil) then break end
    end
  end
  
  -- Draw the effect
  if (cEff ~= nil) then
    local effGraf = member("previewImprt")
    if (gLastImported ~= cEff.nm) then
      member("previewImprt").importFileInto("Effects" .. dirSeparator .. cEff.nm .. ".png")
      effGraf.name = "previewImprt"
      gLastImported = cEff.nm
    end
    effGraf = effGraf.image
    
    local tpCase = cEff.tp

    if (tpCase == "standardPlant") or (tpCase == "standardHanger") or (tpCase == "standardClinger") then
        local lsL

        -- Get potential layers
        local switcher = {}
        switcher["All"] = { 1, 2, 3 }
        switcher["1"] = { 1 }
        switcher["2"] = { 2 }
        switcher["3"] = { 3 }
        switcher["1:st and 2:nd"] = { 1, 2 }
        switcher["2:nd and 3:rd"] = { 2, 3 }

        lsL = list(switcher[lrSup or "All"] or { 1, 2, 3 })
        
        -- Get amount
        local amount = 17
        if cEff["placeAmt"] then
          amount = cEff.placeAmt
        end

        -- Now we place the effect
        for _,layer in ipairs(lsL) do
          local solidCheck = spelrelaterat.solidAfaMv(point(q2,c2+1),layer) 
          
          if cEff.tp == "standardHanger" then
            solidCheck = spelrelaterat.solidAfaMv(point(q2,c2-1),layer)
          elseif cEff.tp == "standardClinger" then
            solidCheck = spelrelaterat.solidAfaMv(point(q2-1,c2),layer) + spelrelaterat.solidAfaMv(point(q2+1,c2),layer)
          end
          
          if (solidMtrx[q2][c2][layer] == 0) and (solidCheck >= 1) then
            
            for i = 1, mtrx[q2][c2] * 0.01 * amount do
              local pnt = me.giveGroundPosCustom(q,c,layer, cEff.tp)
              local clingerMult = (spelrelaterat.giveMiddleOfTile(point(q,c)).x>pnt.x)
              local d = random(9) + ((layer-1)*10)
              
              local var = random(cEff.vars)
              if cEff["strengthAffectVar"] then 
                var = random(restrict(toint(cEff.vars*(mtrx[q2][c2]-11+random(21))*0.01), 1, cEff.vars)) 
              end

              local grab = rect(cEff.pxlSz.x * (var-1), 1, cEff.pxlSz.x * var, 1+cEff.pxlSz.y)
              local rot = 0
              if cEff["randRot"] then rot = random(cEff.randRot * 2 + 1) - cEff.randRot end
              
              local sz = (random(41) + 79) / 100.0 -- default range: 0.8 to 1.2 (inclusive)
              if cEff["szVar"] then
                if cEff.szVar[1] == cEff.szVar[2] then
                  sz = cEff.szVar[1]
                elseif cEff["strengthAffectSize"] then
                  sz = cEff.szVar[1] * (1.0 - ((mtrx[q2][c2] / 100.0) ^ 0.85)) + cEff.szVar[2] * ((mtrx[q2][c2] / 100.0) ^ 0.85)
                else
                  sz = (random((cEff.szVar[2] * 1000.0 - cEff.szVar[1] * 1000.0)) / 1000.0) + cEff.szVar[1]
                end
              end
              
              rot = 0
              if cEff["rotVar"] then
                rot = random(cEff.rotVar * 2 + 1) - cEff.rotVar
              end

              do
                local tpCase = cEff.tp
  
                if (tpCase == "standardHanger") then
                  rot = rot + 180
                elseif (tpCase == "standardClinger") then
                  if clingerMult == 1 then
                    rot = rot + 90
                  else
                    rot = rot + 270
                  end
                end
              end
              
              local flp = 0
              if cEff["randomFlip"] then
                if cEff.randomFlip then flp = random(2)-1 end
              end
              local rootAmt = 5
              if cEff.findPos("rootAmt") then rootAmt = cEff.rootAmt end
              
              local qd = spelrelaterat.rotateRectAroundPoint(rect(-(cEff.pxlSz.x/2.0)*sz, -cEff.pxlSz.y*sz, (cEff.pxlSz.x/2.0)*sz, rootAmt), pnt, rot)
              if flp then qd = spelrelaterat.flipQuadH(qd) end
              
              local useEffCol = 0
              if cEff["pickColor"] then
                if cEff.pickColor then useEffCol = 1 end
              end
              
              if tobool(useEffCol) then
                member("layer"..string(d)).image:copyPixels(effGraf, qd, grab, {color=colr, ink=36})
                
                if colr ~= color(0,255,0) then
                  if cEff["hasGrad"] then
                    if cEff.hasGrad then grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y) end
                  end
                  spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "previewImprt", grab, 0.5, nil)
                end
              else
                member("layer"..string(d)).image:copyPixels(effGraf, qd, grab, {ink=36})
                if cEff["forceGrad"] then
                  if tobool(cEff.forceGrad) then
                    grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y)
                    spelrelaterat.copyPixelsToEffectColor("A", d, qd, "previewImprt", grab, 0.5, nil)
                    spelrelaterat.copyPixelsToEffectColor("B", d, qd, "previewImprt", grab, 0.5, nil)
                  end
                end
              end
            end
          end
        end
    elseif (tpCase == "grower") or (tpCase == "hanger") or (tpCase == "clinger") then -- grower effect and its extended family
        if (random(100) < mtrx[q2][c2]) and (random(3) > 1) then
          local switcher = {}
          switcher["All"] = function() return random(29) end
          switcher["1"] = function() return random(9) end
          switcher["2"] = function() return random(10) - 1 + 10 end
          switcher["3"] = function() return random(10) - 1 + 20 end
          switcher["1:st and 2:nd"] = function() return random(19) end
          switcher["2:nd and 3:rd"] = function() return random(20) - 1 + 10 end

          local d = (switcher[lrSup or "All"] or function() return random(29) end)()

          local lr = 1 + toint(d > 9) + toint(d > 19)
          
          local ctpCase = cEff.tp

          local growDir
          local side
          -- Figure out grow direction
          if (ctpCase == "grower") then -- the normal kind.
            growDir = 180
          elseif (ctpCase == "hanger") then -- growers but they grow upside down.
            growDir = 0
          elseif (ctpCase == "clinger") then -- growers but they grow from the sides. how fancy!
            side = random(2)-1
            if effSide == "L" then side = 0
            elseif effSide == "R" then side = 1 end
            if side == 1 then growDir = 90
            else growDir = 270
            end
          end
          
          -- Do we have a tip? If so, do setup
          local doingTip = 0
          if cEff["tipGraf"] then
            doingTip = 1
            local effGraf = member("previewImprt")
            if gLastImported ~= cEff.tipGraf then
              member("previewImprt").importFileInto("Effects" .. dirSeparator .. cEff.tipGraf .. ".png")
              effGraf.name = "previewImprt"
              gLastImported = cEff.tipGraf
            end
            effGraf = effGraf.image
          end
          
          -- Set up other variables
          local sz = 1.0
          local blnd = 1.0
          local blnd2 = 1.0
          local varBias = 0
          if cEff["heightAffectVar"] > 0 then
            if cEff.heightAffectVar < 0 then
              varBias = 1
            end
          end
          local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
          local pnt = mdPnt + point(random(21)-11, random(21)-11)
          local lastDir = growDir + random(cEff.initRotVar * 2 + 1) - cEff.initRotVar
          
          if cEff["szChange"] then
            sz = cEff.szChange[1]
          end
          
          local quadsToDraw = list()
          local drawQuad = 0
          
          -- Draw loop: as with every grower, draw from tip to ground (or void)
          while (pnt.y < gLOprops.size.y * 20 + 100) and (pnt.y > -100) and (pnt.x < gLOprops.size.x * 20 + 100) and (pnt.x > -100) do
            local vars
            local pxlSz
            local moveAmt

            if doingTip == 1 then
              vars = cEff.tipVars
              pxlSz = cEff.tipPxlSz
              moveAmt = cEff.tipMoveAmt
            else
              vars = cEff.vars
              pxlSz = cEff.pxlSz
              moveAmt = cEff.segmentMoveAmt
            end
            
            -- Figure out grow direction and take a step in that direction. The area between the step is the segment.
            local dir = growDir + random(cEff.segmentRotVar * 2 + 1) - cEff.segmentRotVar
            dir = fiffigt.lerp(lastDir, dir, cEff.segmentRotPull)
            local lastPnt = pnt
            pnt = pnt + fiffigt.degToVec(dir) * moveAmt
            lastDir = dir
            
            -- Set up the quad
            local qd = (lastPnt + pnt) / 2.0
            qd = rect(qd, qd) + rect(-pxlSz.x*sz/2.0,-pxlSz.y/2.0, pxlSz.x*sz/2.0, pxlSz.y/2.0)
            qd = spelrelaterat.rotateToQuadFix(qd, fiffigt.lookAtpoint(lastPnt, pnt))
            
            local flp = 0
            if cEff["randomFlip"] then
              if cEff.randomFlip then flp = random(2)-1 end
            end
            if flp then qd = spelrelaterat.flipQuadH(qd) end
            
            -- Figure out variation and effect color
            local var = random(vars)
            if cEff["heightAffectVar"] and (doingTip ~= 1) then
              local varBias = spelrelaterat.restrict(varBias + cEff.heightAffectVar, 0, 1)
              var = random(spelrelaterat.restrict(toint(cEff.vars*varBias), 1, cEff.vars))
            end
            local grab = rect(pxlSz.x*(var-1), 1, pxlSz.x*var, 1+pxlSz.y)
            
            local useEffCol = 0
            if cEff["pickColor"] then
              if cEff.pickColor then useEffCol = 1 end
            end
            
            -- Draw the damn thing
            if tobool(skyRootsFix) then
              local quadToAdd = {qd, effGraf, grab, -1, -1, blnd, blnd2, doingTip}
              
              if tobool(useEffCol) then
                if colr ~= color(0,255,0) then
                  if cEff["hasGrad"] then
                    if cEff.hasGrad then
                      grab = grab + rect(0, pxlSz.y, 0, pxlSz.y)
                      quadToAdd[4] = grab
                    end
                  end
                  
                  if cEff["effectFadeOut2"] and blnd2 > 0 and doingTip == 0 then
                    qd = (lastPnt + pnt) / 2.0
                    qd = rect(qd, qd) + rect(-pxlSz.x*sz/1.6,-pxlSz.y/1.6, pxlSz.x*sz/1.6, pxlSz.y/1.6)
                    qd = spelrelaterat.rotateToQuadFix(qd, fiffigt,fiffigt.lookAtpoint(lastPnt, pnt))
                    if flp then qd = spelrelaterat.flipQuadH(qd) end
                    quadToAdd[5] = qd
                  end
                end
              else
                if cEff["forceGrad"] then
                  if tobool(cEff.forceGrad) then
                    grab = grab + rect(0, pxlSz.y, 0, pxlSz.y)
                    quadToAdd[4] = grab
                  end
                end
              end
              
              quadsToDraw:add(quadToAdd)
            else
              if tobool(useEffCol) then
                member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {color=colr, ink=36})
                if colr ~= color(0,255,0) then
                  if cEff["hasGrad"] then
                    if tobool(cEff.hasGrad) then grab = grab + rect(0, pxlSz.y, 0, pxlSz.y) end
                  end
                  spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "previewImprt", grab, 0.5, blnd)
                  
                  if cEff["effectFadeOut2"] and blnd2 > 0 and doingTip == 0 then
                    qd = (lastPnt + pnt) / 2.0
                    qd = rect(qd, qd) + rect(-pxlSz.x*sz/1.6,-pxlSz.y/1.6, pxlSz.x*sz/1.6, pxlSz.y/1.6)
                    qd = spelrelaterat.rotateToQuadFix(qd, fiffigt.lookAtpoint(lastPnt, pnt))
                    if tobool(flp) then qd = spelrelaterat.flipQuadH(qd) end
                    spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "softBrush1", member("softBrush1").image.rect, 0.5, blnd2)
                  end
                end
              else
                member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {ink=36})
                if cEff["forceGrad"] then
                  if tobool(cEff.forceGrad) then
                    grab = grab + rect(0, pxlSz.y, 0, pxlSz.y)
                    spelrelaterat.copyPixelsToEffectColor("A", d, qd, "previewImprt", grab, 0.5, blnd)
                    spelrelaterat.copyPixelsToEffectColor("B", d, qd, "previewImprt", grab, 0.5, blnd)
                  end
                end
              end
            end
            
            -- Adjust per-segment variables
            if cEff["effectFadeOut"] then blnd = blnd * cEff.effectFadeOut
            else blnd = blnd * 0.85 end
            
            if cEff["effectFadeOut2"] then blnd2 = math.max(0.0, blnd2 - cEff.effectFadeOut2) end
            
            if cEff["szChange"] then
              sz = spelrelaterat.restrict(sz + random(1000)/1000.0 * cEff.szChange[3], math.min(cEff.szChange[1], cEff.szChange[2]), math.max(cEff.szChange[1], cEff.szChange[2]))
            end
            
            -- Switch graphic and reset after tip
            if doingTip == 1 then
              doingTip = 0
              local effGraf = member("previewImprt")
              if gLastImported ~= cEff.nm then
                member("previewImprt").importFileInto("Effects" .. dirSeparator .. cEff.nm .. ".png")
                effGraf.name = "previewImprt"
                gLastImported = cEff.nm
              end
              effGraf = effGraf.image
            end
            
            -- Stop once we hit solid ground
            tlPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
            
            if tobool(skyRootsFix) and spelrelaterat.withinBoundsOfLevel(tlPos) == 0 then
              drawQuad = 0
              break
            end
            
            if spelrelaterat.solidAfaMv(tlPos, lr) then
              drawQuad = 1
              break
            end
          end
          
          if tobool(drawQuad) then
            if tobool(skyRootsFix) then
              for _,qdd in ipairs(quadsToDraw) do
                if tobool(useEffCol) then
                  member("layer"..tostring(d)).image:copyPixels(qdd[2], qdd[1], qdd[3], {color=colr, ink=36})
                  if colr ~= color(0,255,0) then
                    local qddg = qdd[3]
                    if cEff["hasGrad"] then
                      if tobool(cEff.hasGrad) then qddg = qdd[4] end
                    end
                    spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qdd[1], "previewImprt", qddg, 0.5, qdd[6])
                    
                    if cEff["effectFadeOut2"] and (qdd[7] > 0) and (qdd[8] == 0) then
                      spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qdd[5], "softBrush1", member("softBrush1").image.rect, 0.5, qdd[7])
                    end
                  end
                else
                  member("layer"..tostring(d)).image:copyPixels(qdd[2], qdd[1], qdd[3], {ink=36})
                  if cEff["forceGrad"] then
                    if tobool(cEff.forceGrad) then
                      spelrelaterat.copyPixelsToEffectColor("A", d, qdd[1], "previewImprt", qdd[4], 0.5, qdd[6])
                      spelrelaterat.copyPixelsToEffectColor("B", d, qdd[1], "previewImprt", qdd[4], 0.5, qdd[6])
                    end
                  end
                end
              end
            end
          end
        end
    elseif (tpCase == "individual") or (tpCase == "individualHanger") or (tpCase == "individualClinger") then -- individual plant effect
        local switcher = {}
        switcher["All"] = function() return random(29) end
        switcher["1"] = function() return random(9) end
        switcher["2"] = function() return random(10) - 1 + 10 end
        switcher["3"] = function() return random(10) - 1 + 20 end
        switcher["1:st and 2:nd"] = function() return random(19) end
        switcher["2:nd and 3:rd"] = function() return random(20) - 1 + 10 end

        local d = switcher[lrSup or "All"]()

        lr = 1 + (d > 9) + (d > 19)

        local solidCheck = spelrelaterat.solidAfaMv(point(q2,c2+1),lr) 
        if cEff.tp == "individualHanger" then
          solidCheck = spelrelaterat.solidAfaMv(point(q2,c2-1),lr)
        elseif cEff.tp == "individualClinger" then
          solidCheck = spelrelaterat.solidAfaMv(point(q2-1,c2),lr) + spelrelaterat.solidAfaMv(point(q2+1,c2),lr)
        end
        
        if solidMtrx[q2][c2][lr]==0 and tobool(solidCheck) then
          -- Figure out variables
          local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
          local pnt = mdPnt + point(random(21)-11, 10)
          local clingerSide
          
          if cEff.tp == "individualHanger" then
            pnt = mdPnt + point(random(21)-11, -10)
          elseif cEff.tp == "individualClinger" then
            clingerSide = -spelrelaterat.solidAfaMv(point(q2-1,c2),lr) + spelrelaterat.solidAfaMv(point(q2+1,c2),lr)
            pnt = mdPnt + point(10*clingerSide, random(21)-11)
          end
          
          local var = random(cEff.vars)
          if cEff["strengthAffectVar"] then var = random(restrict((cEff.vars*(mtrx[q2][c2]-11+random(21))*0.01).integer, 1, cEff.vars)) end
          local grab = rect(cEff.pxlSz.x*(var-1), 1, cEff.pxlSz.x*var, 1+cEff.pxlSz.y)
          
          local sz = (random(41) + 79) / 100.0 -- default range: 0.8 to 1.2 (inclusive)
          if cEff["szVar"] then
            if cEff.szVar[1] == cEff.szVar[2] then
              sz = cEff.szVar[1]
            else 
              sz = (random((cEff.szVar[2] * 1000.0 - cEff.szVar[1] * 1000.0)) / 1000.0) + cEff.szVar[1]
            end
          end
          
          local rot = 0
          if cEff["rotVar"] then
            rot = random(cEff.rotVar * 2 + 1) - cEff.rotVar
          end
          if cEff.tp == "individualHanger" then
            rot = rot + 180
          elseif cEff.tp == "individualClinger" then
            rot = rot + 180 + 90 * clingerSide
          end
          
          local flp = 0
          if cEff["randomFlip"] then
            if cEff.randomFlip then flp = random(2)-1 end
          end
          local rootAmt = 5
          if cEff["rootAmt"] then rootAmt = cEff.rootAmt end
          
          local qd = spelrelaterat.rotateRectAroundPoint(rect(-(cEff.pxlSz.x/2.0)*sz, -cEff.pxlSz.y*sz, (cEff.pxlSz.x/2.0)*sz, rootAmt), pnt, rot)
          if tobool(flp) then qd = spelrelaterat.flipQuadH(qd) end
          
          -- Draw the thing
          local useEffCol = 0
          if cEff["pickColor"] then
            if tobool(cEff.pickColor) then useEffCol = 1 end
          end
          
          if tobool(useEffCol) then
            member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {color=colr, ink=36})
            if colr ~= color(0,255,0) then
              if cEff["hasGrad"] then
                if tobool(cEff.hasGrad) then grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y) end
              end
              spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "previewImprt", grab, 0.5, nil)
            end
          else
            member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {ink=36})
            if cEff["forceGrad"] then
              if tobool(cEff.forceGrad) then
                grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y)
                spelrelaterat.copyPixelsToEffectColor("A", d, qd, "previewImprt", grab, 0.5, nil)
                spelrelaterat.copyPixelsToEffectColor("B", d, qd, "previewImprt", grab, 0.5, nil)
              end
            end
          end
        end

    elseif (tpCase == "wall") then -- things that get placed on wall
      local dmin = 0
      local dmax = 29
    
      if lrSup == "All" then
        dmin = 0
        dmax = 29
      elseif lrSup == "1" then
        dmin = 0
        dmax = 9
      elseif lrSup == "2" then
        dmin = 10
        dmax = 19
      elseif lrSup == "3" then
        dmin = 20
        dmax = 29
      elseif lrSup == "1:st and 2:nd" then
        dmin = 0
        dmax = 19
      elseif lrSup == "2:nd and 3:rd" then
        dmin = 10
        dmax = 29
      end

      local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
      local amount = 20
      if cEff["placeAmt"] then
        amount = cEff.placeAmt
      end
      
      for k = 1, math.max(1, toint(amount * mtrx[q2][c2] / 100.0)) do
        -- Figure out where and how big (we need ow big to figure out depth believe it or not)
        local pnt = mdPnt + point(random(21)-11, random(21)-11)
        
        local sz = (random(41) + 79) / 100.0 -- default range: 0.8 to 1.2 (inclusive)
        local x
        if cEff["szVar"] then
          if cEff.szVar[1] == cEff.szVar[2] then
            sz = cEff.szVar[1]
          elseif cEff["strengthAffectSize"] then
            x = spelrelaterat.restrict(mtrx[q2][c2]-11+random(21),1,100)
            sz = cEff.szVar[1] * (1.0 - power(x / 100.0, 0.85)) + cEff.szVar[2] * power(x / 100.0, 0.85)
          else
            sz = (random((cEff.szVar[2] * 1000.0) - (cEff.szVar[1] * 1000.0)+1)-1) / 1000.0 + cEff.szVar[1]
          end
        end
        
        -- Figure out depth and if we can actually place it
        local canPlace = 0
        local d = -1
        local lr = 0
        local cl = color(255,255,255)
        for dp = dmin, dmax do
          local rad = sz/2.0
          for _,dr in ipairs({point(0,0), point(-1,0), point(0,-1), point(0,1), point(1,0)}) do
            local tempPt = point(toint(pnt.x + dr.x*rad), toint(pnt.y + dr.y*rad))
            if (member("layer"..tostring(dp)):getPixel(tempPt.x, tempPt.y) ~= color(255,255,255)) then
              canPlace = 1
              cl = member("layer"..tostring(dp)):getPixel(tempPt.x, tempPt.y)
              if (cEff["can3D"]) then
                if cEff.can3D == 1 or (cEff.can3D == 2 and toint(effectIn3D)) then
                  d = max(0, dp - 2)
                else
                  d = dp
                end
              else
                d = dp
              end
              lr = 1 + (d > 9) + (d > 19)
              break
            end
          end
          if canPlace == 1 then break end
        end
        
        if (canPlace==1) and cEff["requireSolid"] then
          if cEff.requireSolid == 1 then
            canPlace = spelrelaterat.solidAfaMv(point(q2,c2),lr)
          end
        end
        
        -- Now draw it if we can
        if canPlace == 1 and d > -1 then
          d = spelrelaterat.restrict(d - 1 + random(2), dmin, dmax)
          
          local var = random(cEff.vars)
          if cEff["strengthAffectVar"] then var = random(restrict(toint(cEff.vars*(mtrx[q2][c2]-11+random(21))*0.01), 1, cEff.vars)) end
          local grab = rect(cEff.pxlSz.x*(var-1), 1, cEff.pxlSz.x*var, 1+cEff.pxlSz.y)
          
          local rot = 0
          if cEff["randomRotat"] then
            if toint(cEff.randomRotat) then rot = random(361) - 1 end
          end
          
          local flp = 0
          if cEff["randomFlip"] then
            if tobool(cEff.randomFlip) then flp = random(2)-1 end
          end
          
          local qd = rect(pnt, pnt) + rect(-(cEff.pxlSz/2.0), cEff.pxlSz/2.0)
          qd = spelrelaterat.rotateToQuadFix(qd, rot)
          if tobool(flp) then qd = spelrelaterat.flipQuadH(qd) end
          
          local useEffCol = 0
          if cEff["pickColor"] then
            if tobool(cEff.pickColor) then useEffCol = 1 end
          end
          
          if cEff["outline"] then -- outline, if wanted
            if tobool(cEff.outline) then
              for _,j2 in ipairs({{point(-1,-1), color(0,0,255)}, {point(-0,-1), color(0,0,255)}, {point(-1,-0), color(0,0,255)}, {point(1,1), color(255,0,0)},{point(0,1), color(255,0,0)},{point(1,0), color(255,0,0)}}) do
                local oqd = {qd[1] + j2[1], qd[2] + j2[1], qd[3] + j2[1], qd[4] + j2[1]}
                member("layer"..tostring(d)).image:copyPixels(effGraf, oqd, grab, {color=j2[2], ink=36})
              end
            end
          end
          
          if tobool(useEffCol) then -- actually drawing
            member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {color=colr, ink=36})
            if colr ~= color(0,255,0) then
              if cEff["hasGrad"] then
                if tobool(cEff.hasGrad) then grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y) end
              end
              spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "previewImprt", grab, 0.5, nil)
            end
          else
            member("layer"..tostring(d)).image:copyPixels(effGraf, qd, grab, {ink=36})
            if cEff["forceGrad"] then
              if tobool(cEff.forceGrad) then
                grab = grab + rect(0, cEff.pxlSz.y, 0, cEff.pxlSz.y)
                spelrelaterat.copyPixelsToEffectColor("A", d, qd, "previewImprt", grab, 0.5, nil)
                spelrelaterat.copyPixelsToEffectColor("B", d, qd, "previewImprt", grab, 0.5, nil)
              end
            end
          end
        end
      end
    elseif (tpCase == "texture") then --things that add textures to the wall
        local layerImages = list()
        local layerImagesA = list()
        local layerImagesB = list()
        
        for dldld = 0, 29 do
          layerImages:add(member("layer"..tostring(dldld)).image)
          layerImagesA:add(member("gradientA"..tostring(dldld)).image)
          layerImagesB:add(member("gradientB"..tostring(dldld)).image)
        end

        local dmin = 0
        local dmax = 29
        
        if lrSup == "All" then
            dmin = 0
            dmax = 29
        elseif lrSup == "1" then
            dmin = 0
            dmax = 9
        elseif lrSup == "2" then
            dmin = 10
            dmax = 19
        elseif lrSup == "3" then
            dmin = 20
            dmax = 29
        elseif lrSup == "1:st and 2:nd" then
            dmin = 0
            dmax = 19
        elseif lrSup == "2:nd and 3:rd" then
            dmin = 10
            dmax = 29
        end

        local clrMask = 2
        if (cEff["clrMask"]) then -- masking to specific colours, ie 'only apply this to green pixels'
          clrMask = cEff.clrMask
        end
        
        local maskRed = bit.band(clrMask, 1) == 1
        local maskGreen = bit.band(clrMask, 2) == 2
        local maskBlue = bit.band(clrMask, 4) == 4
        local maskEffA = bit.band(clrMask, 8) == 8
        local maskEffB = bit.band(clrMask, 16) == 16

        local bleed = 0
        
        local useEffCol = 0
        if cEff["pickColor"] then
            if tobool(cEff.pickColor) then useEffCol = 1 end
        end
        
        if (cEff["bleed"]) then -- 'bleed' being if the texture can apply through layers
            bleed = cEff.bleed
        end
        
        local placeAmt = 20
        if (cEff["placeAmt"]) then
            placeAmt = cEff.placeAmt
        end
        
        local affop = 0.05
        if (cEff["affectOpenAreas"]) then
            affop = cEff.affectOpenAreas
        end
        
        local requireSolid = 0
        if (cEff["requireSolid"]) then
            requireSolid = cEff.requireSolid
        end

        local fc = affop + (1.0-affop)* (1-((1-spelrelaterat.solidAfaMv(point(q2,c2), 3)) * requireSolid))
    
        for dt = 1, 30 do
          local lr = 30-dt
          if (lr == 9) or (lr == 19) then
            local lraddc = 1+(dt>9)+(dt>19)
            local sld = (1-((1-solidMtrx[q2][c2][lraddc]) * requireSolid))
            fc = affop + (1.0 - affop) * (1-((1-spelrelaterat.solidAfaMv(point(q2,c2), lraddc)) * requireSolid))
          end
          
          local deepEffect = 0
          if (lr == 0) or (lr == 10) or (lr == 20) or (sld == 0) then
            deepEffect = 1
          end
          
          local effSt = mtrx[q2][c2]
          
          local placeCount = effSt * (0.2 + (0.8 * deepEffect)) * 0.01 * placeAmt * fc
          
          if (lr >= dmin) and (lr <= dmax) then
            for placed = 1, placeCount do
              local pnt = spelrelaterat.giveMiddleOfTile(point(q,c)) + point(random(21)-11, random(21)-11)
              
              if deepEffect then
                pnt = (point(q-1, c-1)*20)+point(random(20), random(20))
              else
                if random(2)==1 then
                  pnt = (point(q-1, c-1)*20)+point(1 + 19*(random(2)-1), random(20))
                else 
                  pnt = (point(q-1, c-1)*20)+point(random(20), 1 + 19*(random(2)-1))
                end
              end
              
              local var = random(cEff.vars)
              
              if (cEff["strengthAffectVar"]) then
                if tobool(cEff.strengthAffectVar) then
                  var = random(restrict(toint(cEff.vars*(effSt-11+random(21))*0.01), 1, cEff.vars))
                end
              end
              
              for lch = 0, (cEff.pxlSz.x - 1) do
                for lcv = 0, (cEff.pxlSz.y - 1) do
                  local gtCl = effGraf:getPixel(lch + (var - 1) * cEff.pxlSz.x, lcv + 1)
                  if (gtCl ~= DRWhite) then
                    for lr2 = lr, spelrelaterat.restrict(lr + bleed, dmin, 29) do
                      
                      layerlr = layerImages[lr2 + 1]
                      layerlrA = layerImagesA[lr2 + 1]
                      layerlrB = layerImagesB[lr2 + 1]
                      layerlrAB = {layerlrA, layerlrB}
                      
                      lrClr = layerlr:getPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv)
                      
                      if me.doesColorFitMask(lrClr, maskRed, maskGreen, maskBlue, maskEffA, maskEffB) then
                        if tobool(useEffCol) then
                          layerlr:setPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv, colr)
                          if (cEff["hasGrad"]) then
                            if tobool(cEff.hasGrad) then
                              gradClr = effGraf:getPixel(lch + (var - 1) * cEff.pxlSz.x, lcv + 1 + cEff.pxlSz.y)
                              if (gdLayer ~= "C") then
                                layerlrAB[toint(gdLayer == "A") + toint(gdLayer == "B") * 2]:setPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv, gradClr)
                              end
                            end
                          end
                        else
                          layerlr:setPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv, gtCl)
                          
                          if (cEff["forceGrad"]) then
                            if tobool(cEff.forceGrad) then
                              gradClr = effGraf:getPixel(lch + (var - 1) * cEff.pxlSz.x, lcv + 1 + cEff.pxlSz.y)
                              layerlrA:setPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv, gradClr)
                              layerlrB:setPixel(pnt.x - (cEff.pxlSz.x / 2) + lch, pnt.y - (cEff.pxlSz.y / 2) + lcv, gradClr)
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
    end
  end
end

function me.giveGroundPosCustom(q, c, l, t)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
  local pnt = mdPnt
  
    if t == "standardPlant" then
      pnt = mdPnt + point(-11+random(21), 10)
      if (gLEprops.matrix[q2][c2][l][1]==3) then
        pnt.y = pnt.y - (pnt.x-mdPnt.x) - 5
      elseif (gLEprops.matrix[q2][c2][l][1]==2) then
        pnt.y = pnt.y - (mdPnt.x-pnt.x) - 5
      end
      
    elseif t == "standardHanger" then
      pnt = mdPnt - point(-11+random(21), 10)
      if (gLEprops.matrix[q2][c2][l][1]==4) then
        pnt.y = pnt.y + (pnt.x-mdPnt.x) + 5
      elseif (gLEprops.matrix[q2][c2][l][1]==5) then
        pnt.y = pnt.y + (mdPnt.x-pnt.x) + 5
      end
      
    elseif "standardClinger" then
        local side
        if effSide == "L" then
            side = 1
            pnt = mdPnt - point(10, -11+random(21))
        elseif effSide == "R" then
            side = 2
            pnt = mdPnt + point(10, -11+random(21))
        else
            side = random(2)
            pnt = mdPnt + point(10 * ((side - 1) * 2 - 1), -11+random(21))
        end
      
      if (gLEprops.matrix[q2][c2][l][1]==(5-side)) then
        pnt.x = pnt.x + ((pnt.y-mdPnt.y) + 5) * ((side - 1) * 2 - 1)
      elseif (gLEprops.matrix[q2][c2][l][1]==(4+side)) then
        pnt.x = pnt.x + ((mdPnt.y-pnt.y) + 5) * ((side - 1) * 2 - 1)
      end
  end
  return pnt
end

function me.doesColorFitMask(clr, maskRed, maskGreen, maskBlue, maskEffA, maskEffB) -- if a color fits the mask specified
  if tobool(maskRed) and clr == color(255, 0, 0) then
    return true
  end
  
  if tobool(maskGreen) and clr == color(0, 255, 0) then
    return true
  end
  
  if tobool(maskBlue) and clr == color(0, 0, 255) then
    return true
  end
  
  if tobool(maskEffA) then
    if tobool(maskRed) and clr == color(150, 0, 150) then
      return true
    end
    if tobool(maskGreen) and clr == color(255, 0, 255) then
      return true
    end
    if tobool(maskBlue) and clr == color(255, 150, 255) then
      return true
    end
  end
  
  if tobool(maskEffB) then
    if tobool(maskRed) and clr == color(0, 150, 150) then
      return true
    end
    if tobool(maskGreen) and clr == color(0, 255, 255) then
      return true
    end
    if tobool(maskBlue) and clr == color(150, 255, 255) then
      return true
    end
  end
  
  return false
end

function me.applyStandardErosion(q, c, eftc, tp, effectr)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  local affop = effectr.affectOpenAreas
  local fc = affop + (1.0-toint(affop))* toint(     spelrelaterat.solidAfaMv(point(q2,c2), 3)   )

  for d = 1, 30 do
    local lr = 30-d

    local dmin = 0
    local dmax = 29

    if lrSup == "All" then
        dmin = 0
        dmax = 29
    elseif lrSup == "1" then
        dmin = 0
        dmax = 9
    elseif lrSup == "2" then
        dmin = 10
        dmax = 19
    elseif lrSup == "3" then
        dmin = 20
        dmax = 29
    elseif lrSup == "1:st and 2:nd" then
        dmin = 0
        dmax = 19
    elseif lrSup == "2:nd and 3:rd" then
        dmin = 10
        dmax = 29
    end

    local sld
    
    if (lr == 9)or(lr==19) then
      local lraddc = 1+toint(d>9)+toint(d>19)
      sld = solidMtrx[q2][c2][lraddc]
      fc = affop + (1.0-toint(affop))* toint( spelrelaterat.solidAfaMv(point(q2,c2), lraddc) )
    end
    local deepEffect = 0
    
    if (lr == 0)or(lr==10)or(lr==20)or(sld==0)then
      deepEffect = 1
    end

    local mtrxq2c2 = effectr.mtrx[q2][c2]

    local strlr = tostring(lr)
    local layerlr = member("layer" .. strlr).buf
    local galr = member("gradientA" .. strlr).buf
    local gblr = member("gradientB" .. strlr).buf
    local dclr = member("layer" .. strlr ..'dc').buf
    local endofloop = mtrxq2c2*(0.2 + (0.8*deepEffect))*0.01*effectr.repeats*fc

    local pnt
    for cntr = 1, endofloop do
      if tobool(deepEffect) then
        pnt = (point(q-1, c-1)*20)+point(random(20), random(20))
      else
        if random(2)==1 then
          pnt = (point(q-1, c-1)*20)+point(1 + 19*(random(2)-1), random(20))
        else 
          pnt = (point(q-1, c-1)*20)+point(random(20), 1 + 19*(random(2)-1))
        end
      end

      local cl
      local clA
      local clB
      local clDc

      if tp == "Rust" or tp == "Barnacles" or tp == "Colored Barnacles" or tp == "Clovers" then
        pnt = pnt+(fiffigt.degToVec(random(360))*4)
        
        if (lr > dmax) or (lr < dmin) then
          cl = DRWhite
          clA = DRWhite
          clB = DRWhite
          clDc = DRWhite
        else
          cl = layerlr:getPixel(pnt)
          clA = galr:getPixel(pnt)
          clB = gblr:getPixel(pnt)
          clDc = dclr:getPixel(pnt)
        end

      elseif tp == "Erode" or tp == "Ultra Erode" then
        pnt = pnt+fiffigt.degToVec(random(360))*2
        if (layerlr:getPixel(pnt) == DRWhite) or (random(108)==1) then
          cl = "G"
        else
          cl = DRWhite
        end
        if (layerlr:getPixel(pnt) == DRWhite) then
          cl = "N"
        end
      elseif tp == "Super Erode" then
        pnt = pnt+fiffigt.degToVec(random(360))*2
        if (layerlr.getPixel(pnt) == DRWhite) then
          cl = "G"
        else
          cl = DRWhite
        end
        if (layerlr.getPixel(pnt) == DRWhite) then
          cl = "N"
        end

      elseif tp == "Destructive Melt" or tp == "Impacts" then
        if (lr > dmax) or (lr < dmin) then
          cl = DRWhite
          clA = DRWhite
          clB = DRWhite
          clDc = DRWhite
        else
          cl = layerlr:getPixel(pnt)
          clA = galr:getPixel(pnt)
          clB = gblr:getPixel(pnt)
          clDc = dclr:getPixel(pnt)
        end
        if(cl == DRWhite)then
          cl = "W"
        end
        if(clA == DRWhite)then
          clA = "W"
        end
        if(clB == DRWhite)then
          clB = "W"
        end
        if(clDc == DRWhite)then
          clDc = "W"
        end
      else
        if (lr > dmax) or (lr < dmin) then
          cl = DRWhite
          clA = DRWhite
          clB = DRWhite
          clDc = DRWhite
        else
          cl = layerlr:getPixel(pnt)
          clA = galr:getPixel(pnt)
          clB = gblr:getPixel(pnt)
          clDc = dclr:getPixel(pnt)
        end
      end

      if tp == "Slime" or tp == "SlimeX3" then
        if (cl ~= DRWhite) then
          local ofst = random(2) - 1
          local lgt = 3 + random(random(random(6)))
          
          local nwLr
          
          if tobool(effectIn3D) then
            nwLr = me.get3DLr(lr)
          else

            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelateratrestrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end

          if (nwLr > 29) then
            nwLr = 29
          elseif (nwLr < 0) then
            nwLr = 0
          end
          
          local strnwlr = tostring(nwLr)
          local layernwlr = member("layer" .. strnwlr).buf
          local dcnwlr
          local ganwlr
          local gbnwlr
          
          if tobool(gradAf) then
            local ondc = (clDc ~= DRWhite)
            local ona = (clA ~= DRWhite)
            local onb = (clB ~= DRWhite)
            local slmRect = rect(pnt, pnt) + rect(0 + ofst, 0, 1 + ofst, lgt)
            
            layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
            
            if (ondc) then
              dcnwlr = member("layer" .. strnwlr .. "dc").buf
              dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
            end
            
            if (ona) then
              ganwlr = member("gradientA" .. strnwlr).buf
              ganwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clA})
            end

            if (onb) then
              gbnwlr = member("gradientB" .. strnwlr).buf
              gbnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clB})
            end

            if (random(2) == 1) then
              slmRect = rect(pnt, pnt) + rect(0 + ofst + 1, 1 ,1 + ofst + 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
              if (ondc) then
                dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
              end
              if (ona)then
                ganwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clA})
              end
              if (onb)then
                gbnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clB})
              end
            else
              slmRect = rect(pnt, pnt) + rect(0 + ofst - 1, 1, 1 + ofst - 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
              if (ondc) then
                dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
              end
              if (ona) then
                ganwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clA})
              end
              if (onb) then
                gbnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clB})
              end
            end
          elseif tobool(slimeFxt) then
            local slmRect = rect(pnt, pnt) + rect(0 + ofst, 0, 1 + ofst, lgt)
            layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
            local ondc = (clDc ~= DRWhite)
            
            if (ondc) then
              dcnwlr = member('layer' .. nwLr .. 'dc').buf
              dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
            end
            
            if (random(2) == 1) then
              slmRect = rect(pnt, pnt) + rect(0 + ofst + 1, 1 ,1 + ofst + 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
              if (ondc) then
                dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
              end
            else
              slmRect = rect(pnt, pnt) + rect(0 + ofst - 1, 1, 1 + ofst - 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
              if (ondc) then
                dcnwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=clDc})
              end
            end
          else
            local slmRect = rect(pnt, pnt) + rect(0 + ofst, 0, 1 + ofst, lgt)
            layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
            if (random(2) == 1) then
              slmRect = rect(pnt, pnt) + rect(0 + ofst + 1, 1 ,1 + ofst + 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
            else
              slmRect = rect(pnt, pnt) + rect(0 + ofst - 1, 1, 1 + ofst - 1, lgt - 1)
              layernwlr:copyPixels(DRPxl, slmRect, DRPxlRect, {color=cl})
            end
          end
        end
      elseif tp == "DecalsOnlySlime" then
        if (cl ~= DRWhite) and (lr >= dmin) and (lr <= dmax) then
          local ofst = random(2)-1
          local lgt = 3 + random(random(random(6)))
          local ondc = (clDc ~= DRWhite)
          local onga = (clA ~= DRWhite)
          local ongb = (clB ~= DRWhite)
          if (ondc)then
            dclr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,1+ofst,lgt), DRPxlRect, {color=clDc})
          end
          if (onga)then
            galr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,1+ofst,lgt), DRPxlRect, {color=clA})
          end
          if (ongb)then
            gblr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,1+ofst,lgt), DRPxlRect, {color=clB})
          end
          
          if random(2)==1 then
            if (ondc)then
              dclr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,1+ofst+1,lgt-1), DRPxlRect, {color=clDc})
            end
            if (onga)then
              galr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,1+ofst+1,lgt-1), DRPxlRect, {color=clA})
            end
            if (ongb)then
              gblr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,1+ofst+1,lgt-1), DRPxlRect, {color=clB})
            end
          else
            if (ondc)then
              dclr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,1+ofst-1,lgt-1), DRPxlRect, {color=clDc})
            end
            if (onga)then
              galr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,1+ofst-1,lgt-1), DRPxlRect, {color=clA})
            end
            if (ongb)then
              gblr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,1+ofst-1,lgt-1), DRPxlRect, {color=clB})
            end
          end
        end
    elseif tp == "Rust" then
        if (cl ~= DRWhite) then
          local ofst = random(2)-1
          local nwLr
          
          if  tobool(effectIn3D) then
            nwLr = me.get3DLr(lr)
          else

            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end
          
          local strnwlr = tostring(nwLr)
          local rustdot = member("rustDot").image
          member("layer"..strnwlr).buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=cl, ink=36})
          if(gradAf)then
            if (clDc ~= DRWhite)then
              member("layer"..strnwlr.."dc").buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clDc, ink=36})
            end
            if (clA ~= DRWhite)then
              member("gradientA"..strnwlr).buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clA, ink=36})--comment below
            end
            if (clB ~= DRWhite)then
              member("gradientB"..strnwlr).buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clB, ink=36})--not using 39-darker here because 36 makes things look better
            end
          end
        end
    elseif tp == "Barnacles" then
      if (cl ~= DRWhite) then
          local nwLr
            if  tobool(effectIn3D) then
            nwLr = me.get3DLr(lr)
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end
          
          local strnwlr = tostring(nwLr)
          local layernwlr = member("layer" .. strnwlr).buf
          if tobool(random(2)-1) then
            local b1 = member("barnacle1").image
            local b2 = member("barnacle2").image
            layernwlr:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=cl, ink=36})
            
            if tobool(gradAf)then
              if (clDc ~= DRWhite)then
                member("layer"..strnwlr.."dc").buf:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=clDc, ink=36})
              end
              if (clA ~= DRWhite)then
                member("gradientA"..strnwlr).buf:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=clA, ink=36})
              end
              if (clB ~= DRWhite)then
                member("gradientB"..strnwlr).buf:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=clB, ink=36})
              end
            end
            layernwlr:copyPixels(b2, rect(pnt, pnt)+rect(-2,-2,3,3), b2.rect, {color=color(255,0,0), ink=36})
          else
            local rustdot = member("rustDot").image
            local ofst = random(2)-1
            layernwlr:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=(list({color(255,0,0),cl})[random(2)]), ink=36})
            if tobool(gradAf)then
              if (clDc ~= DRWhite)then
                member("layer"..strnwlr.."dc").buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clDc, ink=36})
              end
              if (clA ~= DRWhite)then
                member("gradientA"..strnwlr).buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clA, ink=36})
              end
              if (clB ~= DRWhite)then
                member("gradientB"..strnwlr).buf:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=clB, ink=36})
              end --same use of 36 and not 39 as rust
            end
          end
        end
    elseif tp == "Colored Barnacles" then
        if (cl ~= DRWhite) then
          local nwLr
            if  effectIn3D then
            nwLr = me.get3DLr(lr)
          else

            if lrSup == "All" then
                nwLr = restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = restrict(lr -1 + random(2), 0, 29)
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end

          local strnwlr = string(nwLr)
          local layernwlr = member("layer" .. strnwlr).image
          
          local b1
          local b2

          if (gdIndLayer == "C") then
            if random(2)-1 then
              b1 = member("barnacle1").image
              b2 = member("barnacle2").image
              layernwlr:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=cl, ink=36})
              layernwlr:copyPixels(b2, rect(pnt, pnt)+rect(-2,-2,3,3), b2.rect, {color=color(255,0,0), ink=36})
            else
              ofst = random(2)-1
              rustdot = member("rustDot").image
              layernwlr:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=(list({color(255,0,0),cl})[random(2)]), ink=36})
            end
          else
            if random(2)-1 then
              b1 = member("barnacle1").image
              b2 = member("barnacle2").image
              layernwlr:copyPixels(b1, rect(pnt, pnt)+rect(-3,-3,4,4), b1.rect, {color=cl, ink=36})
              layernwlr:copyPixels(b2, rect(pnt, pnt)+rect(-2,-2,3,3), b2.rect, {color=colrInd, ink=36})
              member("gradient"..gdIndLayer..strnwlr).image:copyPixels(b2, rect(pnt, pnt)+rect(-2,-2,3,3), b2.rect, {ink=39})
            else
              ofst = random(2)-1
              rustdot = member("rustDot").image
              layernwlr:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=colrInd, ink=36})
              member("gradient"..gdIndLayer..strnwlr).image:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {ink=39})
            end
          end
        end

    elseif tp == "Clovers" then

        if (cl ~= color(255, 255, 255)) then
          local nwLr
        
          if  effectIn3D then
            nwLr = get3DLr(lr)
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end

          if nwLr <= 9 then
            str = 1
          else
            str = random(2)
          end
          
          if str == 1 then
            local strnwlr = tostring(nwLr)
            local layernwlr = member("layer"..strnwlr).image
            
            local n
            local h1
            local h2
            local nRect

            local LC3
            local LC4

            if (gdLayer == "C") then
              n = list({1,1,1,1,1,1,2,1.5})[random(8)]
              h1 = -5*n
              h2 = 6*n
              nRect = spelrelaterat.rotateToQuad(rect(pnt, pnt)+rect(h1,h1,h2,h2), random(360))
              if (random(60) == 1) then
                LC4 = member("4LCloverGraf").image
                layernwlr:copyPixels(LC4, nRect, LC4.rect, {color=list({color(255,0,0), color(0,255,0), color(0,0,255)})[random(3)], ink=36})
              else
                LC3 = member("3LCloverGraf").image
                layernwlr:copyPixels(LC3, nRect, LC3.rect, {color=list({color(255,0,0), color(0,255,0), color(0,0,255)})[random(3)], ink=36})
              end
            else
              n = list({1,1,1,1,1,1,2,1.5})[random(8)]
              h1 = -5*n
              h2 = 6*n
              nRect = rotateToQuad(rect(pnt, pnt)+rect(h1,h1,h2,h2), random(360))
              local gradnwlr = member("gradient"..gdLayer..strnwlr).image
              if (random(60) == 1) then
                LC4 = member("4LCloverGraf").image
                LCG4 = member("4LCloverGrad").image
                layernwlr:copyPixels(LC4, nRect, LC4.rect, {color=colr, ink=36})
                gradnwlr:copyPixels(LCG4, nRect, LCG4.rect, {ink=39})
              else
                LC3 = member("3LCloverGraf").image
                LCG3 = member("3LCloverGrad").image
                layernwlr:copyPixels(LC3, nRect, LC3.rect, {color=colr, ink=36})
                gradnwlr:copyPixels(LCG3, nRect, LCG3.rect, {ink=39})
              end
            end
          end
        end
    elseif tp == "Erode" then
        local nwLr
        if (cl ~= DRWhite) then
          if(random(6)>1)then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr + 1, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr + 1, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr + 1, 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr + 1, 0, 29)
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end

          local layernwlr = member("layer"..tostring(nwLr)).buf
          local rustdot = member("rustDot").image
          for a = 1, 6 do
            local pnt = pnt + point(-3+random(5), -3+random(5))
            local ofst = random(2)-1
            layernwlr:copyPixels(rustdot, rect(pnt, pnt)+rect(-2+ofst,-2,2+ofst,2), rustdot.rect, {color=DRWhite, ink=36})
          end
        end
    elseif tp == "Sand" then
        local nwLr

        if (cl ~= DRWhite) then
          if (random(6) > 1) then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr + 1, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr + 1, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr + 1, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr + 1, 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr + 1, 0, 29)
            end
          end

          if (nwLr > 29) then
            nwLr = 29
          elseif (nwLr < 0) then
            nwLr = 0
          end
          
          local strnwlr = string(nwLr)
          local layernwlr = member("layer" .. strnwlr).image
          
          local Cgrad
          local ganwlr
          local redC
          local greenC
          local blueC

          if (gdIndLayer == "A") then
            Cgrad = 1
            ganwlr = member("gradientA" .. strnwlr).image
          elseif (gdIndLayer == "B") then
            Cgrad = 2
            gbnwlr = member("gradientB" .. strnwlr).image
          else
            Cgrad = 0
            redC = (cl == color(255, 0, 0))
            greenC = (cl == color(0, 255, 0))
            blueC = (cl == color(0, 0, 255))
          end

          for a = 1, 6 do
            local pnt = pnt + point(random(5) - 3, random(5) - 3)
            local ofst = random(2) -- can't remove, would change rng
            local prectsn = rect(pnt, pnt) + rect(-0.5, -0.5, 0.5, 0.5)
            if (Cgrad == 0) then
              if (redC) then
                layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(0, 255, 0), color(0, 0, 255), color(0, 150, 0), color(0, 0, 150)})[random(4)], ink=36})
              elseif (greenC) then
                layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(255, 0, 0), color(0, 0, 255), color(150, 0, 0), color(0, 0, 150)})[random(4)], ink=36})
              elseif (blueC) then
                layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(255, 0, 0), color(0, 255, 0), color(150, 0, 0), color(0, 150, 0)})[random(4)], ink=36})
              else
                layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(150, 0, 0), color(0, 150, 0), color(0, 0, 150)})[random(6)], ink=36})
              end
            elseif (Cgrad == 1) then
              layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(255, 0, 255), color(150, 0, 150)})[random(2)], ink=36})
              ganwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {ink=39})
            else
              layernwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {color=list({color(0, 255, 255), color(0, 150, 150)})[random(2)], ink=36})
              gbnwlr:copyPixels(DRPxl, prectsn, DRPxlRect, {ink=39})
            end
          end
        end
    elseif tp == "Super Erode" then
        local nwLr

        if (cl ~= DRWhite) then
          if(random(40 + 4 * lr * (lr > 19))>1)then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
            end
          end
          
          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end
          
          local layernwlr = member("layer"..tostring(nwLr)).image
          local ermask = member("SuperErodeMask").image
          
          for a = 1, 6 do
            local pnt = pnt + point(-4+random(7), -4+random(7))
            layernwlr:copyPixels(ermask, rect(pnt, pnt)+rect(-4, -4, 4, 4), ermask.rect, {color=DRWhite, ink=36})
          end
        end
    elseif tp == "Ultra Super Erode" then
        local nwLr
        
        if(random(40 + 4 * lr * (lr > 19))>1)then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
        else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
            end
        end

        if nwLr > 29 then
          nwLr = 29
        elseif nwLr < 0 then
          nwLr = 0
        end
        
        local blob = member("Blob").image
        local layernwlr = member("layer"..tostring(nwLr)).image
        
        for a = 1, 6 do
          local pnt = pnt + point(-4+random(7), -4+random(7))
          local rctdel = rect(pnt, pnt)+rect(-8, -8, 8, 8)
          layernwlr:copyPixels(blob, rctdel, blob.rect, {color=DRWhite, ink=36})
          layernwlr:copyPixels(blob, rctdel, blob.rect, {color=DRWhite, ink=36})
        end
    elseif tp == "Melt" then
        if (cl ~= DRWhite) and (lr >= dmin) and (lr <= dmax) then
          local cp = imagebuf(4,4)
          local rct = rect(pnt,pnt)+rect(-2,-2,2,2)
          cp:copyPixels(layerlr, rect(0,0,4,4), rct)
          cp:setPixel(point(0,0), DRWhite)
          cp:setPixel(point(3,0), DRWhite)
          cp:setPixel(point(0,3), DRWhite)
          cp:setPixel(point(3,3), DRWhite)
          layerlr:copyPixels(cp, rct+rect(0,1,0,1), rect(0,0,4,4), {ink=36})
          member("tst").buf = cp
          if tobool(gradAf)then
            local cpA = imagebuf(4,4)
            cpA:copyPixels(galr, rect(0,0,4,4), rct)
            cpA:setPixel(point(0,0), DRWhite)
            cpA:setPixel(point(3,0), DRWhite)
            cpA:setPixel(point(0,3), DRWhite)
            cpA:setPixel(point(3,3), DRWhite)
            galr:copyPixels(cpA, rct+rect(0,1,0,1), rect(0,0,4,4), {ink=39})
            member("tstGradA").buf = cpA
            local cpB = imagebuf(4,4)
            cpB:copyPixels(gblr, rect(0,0,4,4), rct)
            cpB:setPixel(point(0,0), DRWhite)
            cpB:setPixel(point(3,0), DRWhite)
            cpB:setPixel(point(0,3), DRWhite)
            cpB:setPixel(point(3,3), DRWhite)
            gblr:copyPixels(cpB, rct+rect(0,1,0,1), rect(0,0,4,4), {ink=39})
            member("tstGradB").buf = cpB
            local cpDc = imagebuf(4,4)
            cpDc:copyPixels(dclr, rect(0,0,4,4), rct)
            cpDc:setPixel(point(0,0), DRWhite)
            cpDc:setPixel(point(3,0), DRWhite)
            cpDc:setPixel(point(0,3), DRWhite)
            cpDc:setPixel(point(3,3), DRWhite)
            dclr:copyPixels(cpDc, rct+rect(0,1,0,1), rect(0,0,4,4), {ink=36})
            member("tstDc").buf = cpDc
          end
        end
    elseif tp == "Fat Slime" then
        if (cl ~= DRWhite) then
          local ofst = random(2)-1
          local lgt = 3 + random(random(random(6)))
          local big = random(3)
          local fat = random(2)
          
          local nwLr
          
          if tobool(effectIn3D) then
            nwLr = me.get3DLr(lr)
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end
          
          local strnwlr = tostring(nwLr)
          local layernwlr = member("layer"..strnwlr).image
          layernwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,big+ofst,fat+lgt), DRPxl.rect, {color=list({cl, cl, cl, cl, cl, cl, cl, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)})[random(10)]})--cl
          
          local ondc
          local onga
          local ongb

          local dcnwlr
          
          if tobool(gradAf)then
            ondc = (clDc ~= DRWhite)
            onga = (clA ~= DRWhite)
            ongb = (clB ~= DRWhite)
            if (ondc)then
              dcnwlr = member("layer"..strnwlr.."dc").image
              dcnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,big+ofst,fat+lgt), DRPxlRect, {color=clDc})
            end
            if (onga)then
              ganwlr = member("gradientA"..strnwlr).image
              ganwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,big+ofst,fat+lgt), DRPxlRect, {color=clA})
            end
            if (ongb)then
              gbnwlr = member("gradientB"..strnwlr).image
              gbnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst,0,big+ofst,fat+lgt), DRPxlRect, {color=clB})
            end
          end
          if random(2)==1 then
            layernwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,big+ofst+1,fat+lgt-1), DRPxlRect, {color=list({cl, cl, cl, cl, cl, cl, cl, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)})[random(10)]})--cl
            if tobool(gradAf)then
              if (ondc)then
                dcnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,big+ofst+1,fat+lgt-1), DRPxlRect, {color=clDc})
              end
              if (onga)then
                ganwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,big+ofst+1,fat+lgt-1), DRPxlRect, {color=clA})
              end
              if (ongb)then
                gbnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst+1,1,big+ofst+1,fat+lgt-1), DRPxlRect, {color=clB})
              end
            end
          else
            layernwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,big+ofst-1,fat+lgt-1), DRPxlRect, {color=list({cl, cl, cl, cl, cl, cl, cl, color(255, 0, 0), color(0, 255, 0), color(0, 0, 255)})[random(10)]})--cl
            if tobool(gradAf)then
              if (ondc)then
                dcnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,big+ofst-1,fat+lgt-1), DRPxlRect, {color=clDc})
              end
              if (onga)then
                ganwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,big+ofst-1,fat+lgt-1), DRPxlRect, {color=clA})
              end
              if (ongb)then
                gbnwlr:copyPixels(DRPxl, rect(pnt, pnt)+rect(0+ofst-1,1,big+ofst-1,fat+lgt-1), DRPxlRect, {color=clB})
              end
            end
          end
        end
    elseif tp == "Roughen" then
        if (lr >= dmin) and (lr <= dmax) then
          if(cl == color(0, 255, 0))then
            local roughenImg = member("roughenTexture").image
            local var = random(20)
            for lch = 0, 6 do
              for lcv = 0, 6 do
                if(layerlr:getPixel(pnt.x-3+lch, pnt.y-3+lcv) == color(0, 255, 0))then
                  local gtCl = roughenImg:getPixel(lch+(var-1)*7, lcv)
                  if gtCl ~= DRWhite then
                    layerlr:setPixel(pnt.x-3+lch, pnt.y-3+lcv, gtCl)
                  end
                end
              end
            end
          end
        end
    elseif tp == "Super Melt" then
        local mvDown
        local cpAImg
        local cpBImg
        local cpDcImg
        local nwLr

        if (cl ~= DRWhite) and (lr >= dmin) and (lr <= dmax) then
          local maskImg = member("destructiveMeltMask").image
          local pntCal = point(maskImg.width,maskImg.height)/2.0
          local cpImg = image(maskImg.width,maskImg.height)
          local rct = rect(pnt-pntCal, pnt+pntCal)
          cpImg:copyPixels(layerlr, cpImg.rect, rct)
          cpImg:copyPixels(maskImg, cpImg.rect, maskImg.rect, {ink=36, color=DRWhite})
          mvDown = random(7)*(mtrxq2c2/100.0)
          
          if tobool(gradAf) then
            cpAImg = image(maskImg.width,maskImg.height)
            cpBImg = image(maskImg.width,maskImg.height)
            cpDcImg = image(maskImg.width,maskImg.height)
            cpAImg:copyPixels(galr, cpAImg.rect, rct)
            cpAImg:copyPixels(maskImg, cpAImg.rect, maskImg.rect, {ink=36, color=DRWhite})
            cpBImg:copyPixels(gblr, cpBImg.rect, rct)
            cpBImg:copyPixels(maskImg, cpBImg.rect, maskImg.rect, {ink=36, color=DRWhite})
            cpDcImg:copyPixels(dclr, cpDcImg.rect, rct)
            cpDcImg:copyPixels(maskImg, cpDcImg.rect, maskImg.rect, {ink=36, color=DRWhite})
          end

          if (effectIn3D) then
            nwLr = me.get3DLr(lr)
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end
          if((lr > 6)and(nwLr <= 6))or((nwLr > 6)and(lr <= 6))then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          end

          if (nwLr > 29) then
            nwLr = 29
          elseif (nwLr < 0) then
            nwLr = 0
          end
          
          local nwRect = rct + rect(0, 0, 0, mvDown)
          local strnwlr = tostring(nwLr)
          
          member("layer"..strnwlr).image:copyPixels(cpImg, nwRect, cpImg.rect, {ink=36})
          if (gradAf)then
            member("gradientA"..strnwlr).image:copyPixels(cpAImg, nwRect, cpAImg.rect, {ink=39})
            member("gradientB"..strnwlr).image:copyPixels(cpBImg, nwRect, cpBImg.rect, {ink=39})
            member("layer"..strnwlr.."dc").image:copyPixels(cpDcImg, nwRect, cpDcImg.rect, {ink=36})
          end
        end
    elseif tp == "Destructive Melt" then
        if (cl ~= DRWhite) and (lr >= dmin) and (lr <= dmax) then
          local maskImg = member("destructiveMeltMask").image
          local cpImg = image(maskImg.width,maskImg.height)
          local rct = rect(pnt-point(maskImg.width,maskImg.height)/2.0, pnt+point(maskImg.width,maskImg.height)/2.0)
          
          cpImg:copyPixels(layerlr, cpImg.rect, rct)

          local cpAImg
          local cpBImg
          local cpDcImg

          local nwLr

          if (gradAf) then
            cpAImg = image(maskImg.width,maskImg.height)
            cpAImg:copyPixels(galr, cpAImg.rect, rct)
            cpBImg = image(maskImg.width,maskImg.height)
            cpBImg:copyPixels(gblr, cpBImg.rect, rct)
            cpDcImg = image(maskImg.width,maskImg.height)
            cpDcImg:copyPixels(dclr, cpDcImg.rect, rct)
          end

          pnt = point(-2+random(3), -2+random(3))
          rct = rct + rect(pnt, pnt)
          local mvDown = random(7)*(mtrxq2c2/100.0)
          if tobool(effectIn3D) then
            nwLr = me.get3DLr(lr)
          else
            if lrSup == "All" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 10, 29)
            else
                nwLr = spelrelaterat.restrict(lr -1 + random(2), 0, 29)
            end
          end
          if((lr > 6)and(nwLr <= 6))or((nwLr > 6)and(lr <= 6))then
            if lrSup == "All" then
                nwLr = lr
            elseif lrSup == "1" then
                nwLr = spelrelaterat.restrict(lr, 0, 9)
            elseif lrSup == "2" then
                nwLr = spelrelaterat.restrict(lr, 10, 19)
            elseif lrSup == "3" then
                nwLr = spelrelaterat.restrict(lr, 20, 29)
            elseif lrSup == "1:st and 2:nd" then
                nwLr = spelrelaterat.restrict(lr, 0, 19)
            elseif lrSup == "2:nd and 3:rd" then
                nwLr = spelrelaterat.restrict(lr, 10, 29)
            else
                nwLr = lr
            end
          end

          if nwLr > 29 then
            nwLr = 29
          elseif nwLr < 0 then
            nwLr = 0
          end
          
          local strnwlr = tostring(nwLr)
          local destroyImg = member("destructiveMeltDestroy").image
          local destroyMask = destroyImg.createMask() -- UNDEFINED HERE
          layerlr:copyPixels(cpImg, rct + rect(0, 0, 0, mvDown), cpImg.rect, {mask=destroyMask})
          member("layer"..strnwlr).image:copyPixels(cpImg, rct + rect(0, 0, 0, mvDown*0.5), cpImg.rect, {mask=destroyMask, ink=36})
          if(cl == "W")then
            layerlr:copyPixels(destroyImg,  rect(rct.left, rct.top, rct.right, rct.bottom+mvDown), destroyImg.rect, {ink=36, color= DRWhite})
          end
          if tobool(gradAf) then
            galr:copyPixels(cpAImg, rct + rect(0, 0, 0, mvDown), cpAImg.rect, {mask=destroyMask})
            member("gradientA"..strnwlr).image:copyPixels(cpAImg, rct + rect(0, 0, 0, mvDown*0.5), cpAImg.rect, {mask=destroyMask, ink=39})
            if(clA == "W")then
              galr:copyPixels(destroyImg, rect(rct.left, rct.top, rct.right, rct.bottom+mvDown), destroyImg.rect, {ink=36, color= DRWhite})
            end
            gblr:copyPixels(cpBImg, rct + rect(0, 0, 0, mvDown), cpBImg.rect, {mask=destroyMask})
            member("gradientB"..strnwlr).image:copyPixels(cpBImg, rct + rect(0, 0, 0, mvDown*0.5), cpBImg.rect, {mask=destroyMask, ink=39})
            if(clB == "W")then
              gblr:copyPixels(destroyImg, rect(rct.left, rct.top, rct.right, rct.bottom+mvDown), destroyImg.rect, {ink=36, color= DRWhite})
            end
            dclr:copyPixels(cpDcImg, rct + rect(0, 0, 0, mvDown), cpDcImg.rect, {mask=destroyMask})
            member("layer"..strnwlr.."dc").image:copyPixels(cpDcImg, rct + rect(0, 0, 0, mvDown*0.5), cpDcImg.rect, {mask=destroyMask, ink=36})
            if(clDc == "W")then
              dclr:copyPixels(destroyImg, rect(rct.left, rct.top, rct.right, rct.bottom+mvDown), destroyImg.rect, {ink=36, color= DRWhite})
            end
          end
        end
    elseif tp == "Impacts" then
        local chance
        if (lr >= dmin) and (lr <= dmax) then
          chance = random(110)
          if lr <= 9 then
            chance = random(6)
          elseif lr <= 19 then
            chance = random(90)
          end
          if (chance==1) then
            if(cl ~= DRWhite)then
              local var = random(8)
              for lch = 0, 19 do
                for lcv = 1, 20 do
                  if(layerlr:getPixel((pnt.x-15+lch), (pnt.y-15+lcv)) ~= DRWhite)then
                    for iVar = 1, 3 do
                      gtCl = member("Impact"..tostring(iVar)).image:getPixel(lch+(var-1)*20, lcv)
                      if gtCl ~= DRWhite then
                        member("layer"..tostring(spelrelaterat.restrict(lr+iVar-1, dmin, dmax))).image:setPixel((pnt.x-15+lch), (pnt.y-15+lcv), DRWhite)
                      end
                    end
                  end
                end
              end
            end
          end
        end
    end
    end
  end
end

function me.get3DLr(lr)
    local nwLr
  if lrSup == "All" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
  elseif lrSup == "1" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 9)
  elseif lrSup == "2" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 19)
  elseif lrSup == "3" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 20, 29)
  elseif lrSup == "1:st and 2:nd" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 19)
  elseif lrSup == "2:nd and 3:rd" then
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 10, 29)
  else
    nwLr = spelrelaterat.restrict(lr -2 + random(3), 0, 29)
  end
    
  if (lr == 6) and (nwLr == 5) then
    nwLr = 6
  elseif (lr == 5) and (nwLr == 6) then
    nwLr = 5
  end
  if (nwLr > 29) then
    return 29
  elseif (nwLr < 0) then
    return 0
  end
  return nwLr
end 

function me.applyStandardPlant(q, c, eftc, tp)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local amount = 17

  if tp == "Root Grass" then
    amount = 12
  elseif tp == "Grass" then
    amount = 10
  elseif tp == "Dandelions" then
    amount = random(10)
  elseif tp == "Seed Pods" then
    amount = random(5)
  elseif tp == "Cacti" then
    amount = 3
  elseif tp == "Rain Moss" then
    amount = 9
  elseif tp == "rubble" then
    amount = 11
  elseif tp == "Colored Rubble" then
    amount = 11
  elseif tp == "Horse Tails" then
    amount = 1 + random(3)
  elseif tp == "Circuit Plants" then
    amount = 2
  elseif tp == "Feather Plants" then
    amount = 4
  elseif tp == "Reeds" then
    amount = 2
  elseif tp == "Lavenders" or tp == "Storm Plants" then
    amount = 5
  elseif tp == "Hyacinths" then
    amount = 5
  elseif tp == "Seed Grass" then
    amount = 5
  elseif tp == "Orb Plants" then
    amount = 5
  elseif tp == "Lollipop Mold" then
    amount = 5
  elseif tp == "Og Grass" then
    amount = 7
  end

  local switcher = {}
  switcher["All"] = {1,2,3}
  switcher["1"] = {1}
  switcher["2"] = {2}
  switcher["3"] = {3}
  switcher["1:st and 2:nd"] = {1,2}
  switcher["2:nd and 3:rd"] = {2,3}

  lsL = switcher[lrSup or "All"] or {1,2,3}

  -- gradImg = image(10,30,16)
  -- mskImg = image(10,30,16)
  
  for _,layer in ipairs(lsL) do
    if (spelrelaterat.solidMtrx[q2][c2][layer]~=1) and (spelrelaterat.solidAfaMv(point(q2,c2+1), layer)==1) then
      -- mdPnt = giveMiddleOfTile(point(q,c))
      for cntr = 1, gEEprops.effects[r].mtrx[q2][c2]*0.01*amount do
        local pnt = me.giveGroundPos(q, c, layer)
        local lr = random(9) + (layer-1)*10
        
        if tp == "Grass" then
          local freeSides = 0
          if (spelrelaterat.solidAfaMv(point(q2-1,c2+1), layer)==0)then--or(afaMvLvlEdit(point(q,c), layer)=3) then
            --freeSides = freeSides + 1
            amount = amount/2
          end
          if (spelrelaterat.solidAfaMv(point(q2+1,c2+1), layer)==0)then--or(afaMvLvlEdit(point(q,c), layer)=2) then
            -- freeSides = freeSides + 1
            
            amount = amount/2
          end
          
          local rct = rect(pnt, pnt) + rect(-10,-20,10, 10)
          
          local rnd = random(20)
          
          local flp = random(2)-1
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          
          local gtRect = rect((rnd-1)*20, 0, rnd*20, 30)+rect(1,0,1,0)
          member("layer"..tostring(lr)).buf:copyPixels(member("GrassGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            -- pnt = depthPnt(pnt, lr-5)
            rct = rect(pnt, pnt) + rect(-10,-20,10, 10)
            if tobool(flp) then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "GrassGrad", gtRect, 0.5)
          end
        elseif tp == "Root Grass" then
          local freeSides = 0
          if (spelrelaterat.solidAfaMv(point(q2-1,c2+1), layer)==0)then--or(afaMvLvlEdit(point(q,c), layer)=3) then
            freeSides = freeSides + 1
          end
          if (spelrelaterat.solidAfaMv(point(q2+1,c2+1), layer)==0)then--or(afaMvLvlEdit(point(q,c), layer)=2) then
            freeSides = freeSides + 1
          end

          local rnd
          
          local rct = rect(pnt, pnt) + rect(-5,-17,5, 3)
          if (freeSides > 0) or (amount<0.5) then
            rnd = 10+random(5)
          else
            rnd = random(10)
          end
          
          local flp = random(2)-1
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          
          local gtRect = rect((rnd-1)*10, 0, rnd*10, 30)+rect(1,0,1,0)
          member("layer"..tostring(lr)).buf:copyPixels(member("RootGrassGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            rct = rect(pnt, pnt) + rect(-5,-17,5, 3)
            if flp then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "RootGrassGrad", gtRect, 0.5)
          end
        elseif tp == "Seed Pods" then
          local rnd = random(7)
          local rct = rect(pnt, pnt) + rect(-10,-77,10, 3)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*20, 0, rnd*20, 80)+rect(1,0,1,0)
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          member("layer"..tostring(lr)).buf:copyPixels(member("SeedPodsGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            rct = rect(pnt, pnt) + rect(-10,-77,10, 3)
            if tobool(flp) then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "SeedPodsGrad", gtRect, 0.5)
          end
        elseif tp == "Dandelions" then
          local rnd = random(15)
          local rct = rect(pnt, pnt) + rect(-6,-28,6, 0)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*12, 0, rnd*12, 28)+rect(1,0,1,0)
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          member("layer"..tostring(lr)).buf:copyPixels(member("dandelionsGraf").image, rct, gtRect, {color=colr, ink=36})
          spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "dandelionsGrad", gtRect, 0.5)
        elseif tp == "Reeds" then
          local rnd = random(4)
          local rndSz = random(30)
          local rct = rect(pnt, pnt) + rect(-60, -190 - rndSz * 2, 60, 10)
          local flp = random(2) - 1
          local gtRect = rect((rnd - 1) * 120, 1, rnd * 120, 201)
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          member("layer" .. tostring(lr)).buf:copyPixels(member("reedsGraf2").image, rct, gtRect, {color=colr, ink=36})
          if (gdLayer ~= "C") then
            member("gradient" .. gdLayer .. tostring(lr)).image:copyPixels(member("reedsGrad2").image, rct, gtRect, {ink=39})
          end
        elseif tp == "Lavenders" then
          local rnd = random(3)
          local rndSz = random(20)
          local rct = rect(pnt, pnt) + rect(-4, -103 - rndSz * 2, 4, 3)
          local flp = random(2) - 1
          local gtRect = rect((rnd - 1) * 8, 1, rnd * 8, 107)
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          member("layer" .. tostring(lr)).buf:copyPixels(member("lavendersGraf").image, rct, gtRect, {color=colr, ink=36})
          if (colr ~= color(0, 255, 0)) then
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "lavendersGrad", gtRect, 0.5)
          end

          for cal = 0, 2 do
            for rep = -1, 1 do
              local caler = 0
              if (cal == 2) then
                caler = 1
              end
              local rand = random(5)
              local getRct = rect((rand - 1) * 10, 1 + 10 * caler, rand * 10, 11 + 10 * caler)
              local nRect = rect(pnt, pnt) + rect(-5, -105 + cal * 10 - rndSz * 2, 5, -95 + cal * 10 - rndSz * 2)
              local newLr = spelrelaterat.restrict(lr + rep, 0, 29)
              member("layer" .. tostring(newLr)).buf:copyPixels(member("lavendersFlowers").image, nRect, getRct, {color=colr, ink=36})
              if (colr ~= color(0, 255, 0)) then
                member("gradient" .. gdLayer .. tostring(newLr)).buf:copyPixels(member("lavendersFlowers").image, nRect, getRct, {ink=39})
              end
            end
          end
        elseif tp == "Hyacinths" then
          local rnd = random(15)
          local rct = rect(pnt, pnt) + rect(-10,-77,10, 3)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*20, 0, rnd*20, 80)+rect(1,0,1,0)
          local rct = rotate(rct, random(50) - 25)
          member("layer"..tostring(lr)).buf:copyPixels(member("hyacinthGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "hyacinthGrad", gtRect, 0.5)
          end
        elseif tp == "Seed Grass" then
          local rnd = random(15)
          local rct = rect(pnt, pnt) + rect(-10,-47,10, 3)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*20, 0, rnd*20, 50)+rect(0,1,0,1)
          local rct = rotate(rct, random(50) - 25)
          member("layer"..tostring(lr)).buf:copyPixels(member("seedGrassGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "seedGrassGrad", gtRect, 0.5)
          end
        elseif tp == "Orb Plants" then
          local rnd = random(15)
          local rct = rect(pnt, pnt) + rect(-20,-57,20, 3)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*40, 0, rnd*40, 60)+rect(1,0,1,0)
          local rct = rotate(rct, random(50) - 25)
          member("layer"..tostring(lr)).buf:copyPixels(member("orbPlantGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "orbPlantGrad", gtRect, 0.5)
          end  
        elseif tp == "Circuit Plants" then  
          if(random(300) > gEEprops.effects[r].mtrx[q2][c2])then
            local rnd = random(spelrelaterat.restrict(toint(20*(gEEprops.effects[r].mtrx[q2][c2]-11+random(21))*0.01), 1, 16))
            local sz = 0.15+0.85*(gEEprops.effects[r].mtrx[q2][c2]*0.01 ^ 0.85)
            local rct = rect(pnt, pnt) + rect(-20*sz,-95*sz,20*sz, 5)
            local flp = random(2)-1
            local gtRect = rect((rnd-1)*40, 0, rnd*40, 100)+rect(1,0,1,0)
            if tobool(flp) then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            member("layer"..tostring(lr)).buf:copyPixels(member("CircuitPlantGraf").image, rct, gtRect, {color=colr, ink=36})
            if(sz < 0.75)then
              member("layer"..tostring(lr)).buf:copyPixels(member("CircuitPlantGraf").image, rct+rect(1,0,1,0), gtRect, {color=colr, ink=36})
              member("layer"..tostring(lr)).buf:copyPixels(member("CircuitPlantGraf").image, rct+rect(0,1,0,1), gtRect, {color=colr, ink=36})
            end
            if colr ~= color(0,255,0) then
              rct = rect(pnt, pnt) + rect(-20*sz,-95*sz,20*sz, 5)
              if tobool(flp) then
                rct = spelrelaterat.vertFlipRect(rct)
              end
              spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "CircuitPlantGrad", gtRect, 0.5)
            end 
          end
        elseif tp == "Storm Plants" then
          if(random(300) > gEEprops.effects[r].mtrx[q2][c2])then
            local rnd = random(spelrelaterat.restrict(toint(20*(gEEprops.effects[r].mtrx[q2][c2]-11+random(21))*0.01), 1, 16))
            local sz = 0.15+0.85*(gEEprops.effects[r].mtrx[q2][c2]*0.01 ^ 0.85)
            local rct = rect(pnt, pnt) + rect(-20*sz,-95*sz,20*sz, 5)
            local flp = random(2)-1
            local gtRect = rect((rnd-1)*40, 0, rnd*40, 100)+rect(1,0,1,0)
            if tobool(flp) then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            member("layer"..tostring(lr)).buf:copyPixels(member("StormPlantGraf").image, rct, gtRect, {color=colr, ink=36})
            if(sz < 0.75)then
              member("layer"..tostring(lr)).buf:copyPixels(member("StormPlantGraf").image, rct+rect(1,0,1,0), gtRect, {color=colr, ink=36})
              member("layer"..tostring(lr)).buf:copyPixels(member("StormPlantGraf").image, rct+rect(0,1,0,1), gtRect, {color=colr, ink=36})
            end
            if colr ~= color(0,255,0) then
              rct = rect(pnt, pnt) + rect(-20*sz,-95*sz,20*sz, 5)
              if tobool(flp) then
                rct = spelrelaterat.vertFlipRect(rct)
              end
              spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "StormPlantGrad", gtRect, 0.5)
            end 
          end
        elseif tp == "Feather Plants" then
          if(random(300) > gEEprops.effects[r].mtrx[q2][c2])then
            local leanDir = 0
            if(q2 > 1)then
              if(spelrelaterat.afaMvLvlEdit(point(q2-1,c2), layer)==0)and(spelrelaterat.afaMvLvlEdit(point(q2-1,c2+1), layer)==1)then
                leanDir = leanDir + gEEprops.effects[r].mtrx[q2-1][c2]
              elseif (spelrelaterat.afaMvLvlEdit(point(q2-1,c2), layer)==1) then
                leanDir = leanDir - 90
              end
            end
            if(q2 < gLOprops.size.x-1)then
              if(spelrelaterat.afaMvLvlEdit(point(q2+1,c2), layer)==0)and(spelrelaterat.afaMvLvlEdit(point(q2+1,c2+1), layer)==1)then
                leanDir = leanDir - gEEprops.effects[r].mtrx[q2+1][c2]
              elseif (spelrelaterat.afaMvLvlEdit(point(q2+1,c2), layer)==1) then
                leanDir = leanDir + 90
              end
            end
            
            local rnd = random(spelrelaterat.restrict(toint(20*(gEEprops.effects[r].mtrx[q2][c2]-11+random(21))*0.01), 1, 16))
            local sz = 1--0.2+0.8*power(gEEprops.effects[r].mtrx[q2][c2]*0.01, 0.85)
            local rct = rect(pnt, pnt) + rect(-20*sz,-90*sz,20*sz, 100*sz)
            local gtRect = rect((rnd-1)*40, 0, rnd*40, 190)+rect(1,0,1,0)
            
            rct = rotate(rct, (65.0*((leanDir - 11 + random(21))/100.0))+0.1)
            
            local checkForSolid = (rct[1]+rct[2]+rct[3]+rct[4])/4.0
            if(   member("layer"..tostring(lr)).buf.getPixel(checkForSolid.x, checkForSolid.y) ~= color(255, 255, 255))then
              
              if(leanDir - 11 + random(21) > 0) then
                rct = spelrelaterat.flipQuadH(rct)
              end
              
              member("layer"..tostring(lr)).buf:copyPixels(member("FeatherPlantGraf").image, rct, gtRect, {color=colr, ink=36})
              if colr ~= color(0,255,0) then
                spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "FeatherPlantGrad", gtRect, 0.5)
              end 
            end
          end
        elseif tp == "Horse Tails" then
          local rnd = spelrelaterat.restrict(random(3+toint(20*gEEprops.effects[r].mtrx[q2][c2]*0.01)), 1, 14)
          local rct = rect(pnt, pnt) + rect(-10,-48,10, 2)
          local flp = random(2)-1
          local gtRect = rect((rnd-1)*20, 0, rnd*20, 50)+rect(1,0,1,0)
          if tobool(flp) then
            rct = spelrelaterat.vertFlipRect(rct)
          end
          member("layer"..tostring(lr)).buf:copyPixels(member("HorseTailGraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            rct = rect(pnt, pnt) + rect(-10,-48,10, 2)
            if tobool(flp) then
              rct = spelrelaterat.vertFlipRect(rct)
            end
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "HorseTailGrad", gtRect, 0.5)
          end
        elseif tp == "Cacti" then
          for rep = 1, random(random(3)) do
            local sz = 0.5+(random(gEEprops.effects[r].mtrx[q2][c2]*0.7)*0.01)
            local rotat = -45+random(90)
            if (spelrelaterat.solidAfaMv(point(q2-1,c2+1), layer)==0)or(spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==3) then
              rotat = rotat - 10-random(30)
            end
            if (spelrelaterat.solidAfaMv(point(q2+1,c2+1), layer)==0)or(spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==2) then
              rotat = rotat + 10+random(30)
            end
            local tpPnt = pnt + fiffigt.degToVec(rotat)*15*sz
            
            local rct = rotate( rect((pnt+tpPnt)*0.5,(pnt+tpPnt)*0.5)+rect(-4*sz,-7*sz,4*sz,8*sz) ,fiffigt.lookAtPoint(pnt, tpPnt))
            member("layer"..tostring(lr)).buf:copyPixels(member("bigCircle").image, rct, member("bigCircle").image.rect, {color=colr, ink=36})
            if colr ~= color(0,255,0) then
              rct = rect(tpPnt,tpPnt)+rect(-9*sz,-6*sz,9*sz,13*sz)+rect(-3,-3,3,3)
              spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "softBrush1", member("softBrush1").image.rect, 0.5)
            end
          end
        elseif tp == "Rubble" then
          local rct = rect(pnt,pnt)+rect(-3,-3,3,3)+rect(-random(3),-random(3), random(3), random(3))
          local rct = rotate(rct,random(360))
          local rubbl = random(4)
          for rep = 1, 4 do
            if lr+rep-1 > 29 then
              break
            else
              member("layer"..tostring(lr+rep-1)).buf:copyPixels(member("rubbleGraf"..tostring(rubbl)).image, rct, member("rubbleGraf"..tostring(rubbl)).image.rect, {color=color(0,255,0), ink=36})
            end                
          end
        elseif tp == "Colored Rubble" then
          local rct = rect(pnt,pnt)+rect(-3,-3,3,3)+rect(-random(3),-random(3), random(3), random(3))
          local rct = rotate(rct,random(360))
          local rubbl = random(4)
          for rep = 1, 4 do
            if lr+rep-1 > 29 then
              break
            else
              member("layer"..tostring(lr+rep-1)).buf:copyPixels(member("rubbleGraf"..tostring(rubbl)).image, rct, member("rubbleGraf"..tostring(rubbl)).image.rect, {color=colrInd, ink=36})
              if (gdIndLayer ~= "C") then
                member("gradient"..gdIndLayer..tostring(lr+rep-1)).image:copyPixels(member("rubbleGraf"..tostring(rubbl)).image, rct, member("rubbleGraf"..tostring(rubbl)).image.rect, {ink=39})
              end
            end                
          end
        elseif tp == "Rain Moss" then
          local pnt = pnt + fiffigt.degToVec(random(360)) * random(random(100)) * 0.04
          local rct = rect(pnt, pnt) + rect(-12, -12, 13, 13)
          local rct = rotateToQuad(rct, ((random(4) - 1) * 90) + 1)
          local gtRect = random(4)
          gtRect = rect((gtRect - 1) * 25, 0, gtRect * 25, 25)
          member("layer" .. tostring(lr)).buf:copyPixels(member("rainMossGraf").image, rct, gtRect, {color=colr, ink=36})
          if (colr ~= color(0,255,0)) then
            local tpPnt = spelrelaterat.depthPnt(pnt, lr - 5) + fiffigt.degToVec(random(360)) * random(6)
            rct = rect(tpPnt, tpPnt) + rect(-20, -20, 20, 20) + rect(0, 0, -15, -15)
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "softBrush1", member("softBrush1").image.rect, 0.5)
          end
        elseif tp == "Lollipop Mold" then
          if(random(300) > gEEprops.effects[r].mtrx[q2][c2])then
            local grafSz = point(20,20)
            local rnd = random(3)-1
            if (gEEprops.effects[r].mtrx[q2][c2] > 60) then
              rnd = random(5)-1
            end
            
            local sz = 0.5+(random(gEEprops.effects[r].mtrx[q2][c2]*0.5)*0.01)
            local ang = random(31)-16.0 -- range: -15 to 15 inclusive
            local len = (random(8)+12) / 2.0
            
            -- stem
            pnt = pnt - point(0, len)
            local rct = spelrelaterat.rotateToQuadFix(rect(pnt, pnt) + rect(-0.75, -len, 0.75, len), ang)
            member("layer"..tostring(lr)).buf:copyPixels(DRPxl, rct, rect(0,0,1,1), {color=color(150,0,0), ink=36}) -- stems forced as shaded color
            
            -- orb
            pnt = pnt - (point(math.cos((ang+90) * math.pi / 180.0), math.sin((ang+90) * math.pi / 180.0)) * (len + (10*sz) - 2))
            rct = spelrelaterat.rotateToQuadFix(rect(pnt, pnt) + (rect(-10,-10,10,10) * sz), ang)
            member("layer"..tostring(lr)).buf:copyPixels(member("lollipopMoldGraf").image, rct, rect(20*rnd, 1, 20*(rnd+1), 20), {color=colr, ink=36})
            if (colr ~= color(0,255,0)) then
              spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "lollipopMoldGraf", rect(20*rnd, 21, 20*(rnd+1), 39), 0.5, (random(20) + 80.0) / 100.0)
            end
          end
        elseif tp == "Og Grass" then
          local freeSides = 0
          if (spelrelaterat.solidAfaMv(point(q2-1,c2+1), layer)==0)then
            freeSides = freeSides + 1
          end
          if (spelrelaterat.solidAfaMv(point(q2+1,c2+1), layer)==0)then
            freeSides = freeSides + 1
          end
          local rand = random (3)
          local rct = rect(pnt, pnt) + rect(-5*rand,-17*rand,5*rand, 3*rand)
          local rnd
          if (freeSides > 0) or (amount<0.5) then
            rnd = 10+random(5)
          else
            rnd = random(15)
          end
          local flp = random(2)-1
          if tobool(flp) then
            rct = fiffigt.vertFlipRect(rct)
          end
          local gtRect = rect((rnd-1)*20, 0, rnd*19, 50)+rect(1,0,1,0)
          member("layer"..tostring(lr)).buf:copyPixels(member("grassoggraf").image, rct, gtRect, {color=colr, ink=36})
          if colr ~= color(0,255,0) then
            rct = rect(pnt, pnt) + rect(-5*rand,-17*rand,5*rand, 3*rand)
            if tobool(flp) then
              rct = fiffigt.vertFlipRect(rct)
            end
            spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, "RootGrassGrad", gtRect, 0.5)
          end 
        end
      end
    end
  end
end

function me.giveGroundPos(q, c,l)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
  local pnt = mdPnt + point(-11+random(21), 10)
  if (gLEprops.matrix[q2][c2][l][1]==3) then
    pnt.y = pnt.y - (pnt.x-mdPnt.x) - 5
  elseif (gLEprops.matrix[q2][c2][l][1]==2) then
    pnt.y = pnt.y - (mdPnt.x-pnt.x) - 5
  end
  return pnt
end


function me.apply3Dsprawler(q, c, effc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local big = 0
  if (c > 1) and ((c2 - 1) > 0) then
    big = (gEEprops.effects[r].mtrx[q2][c2-1] > 0)
  end
  
  local lr = 1
  local layer
  local lrRange
  if lrSup == "All" then
    layer = random(3)
    lrRange = {0, 29}
  elseif lrSup == "1" then
    layer = 1
  elseif lrSup == "2" then
    layer = 2
    lrRange = {6, 29}
  elseif lrSup == "3" then
    layer = 3
    lrRange = {6, 29}
  elseif lrSup == "1:st and 2:nd" then
    layer = random(2)
    lrRange = {0, 29}
  elseif lrSup == "2:nd and 3:rd" then
    layer = random(2) + 1
    lrRange = {6, 29}
  else
    layer = random(3)
    lrRange = {0, 29}
  end
  
  lr = ((layer-1)*10) + random(9) - 1
  
  if layer == 1 then
    if lr < 5 then
      lrRange = {0, 5} 
    else 
      lrRange = {6, 29} 
    end
  end

  local sts

  if effc == "Sprawlbush" then
    sts = {branches=10+random(10)+15*big, expectedBranchLife={small=20, big=35, smallRandom=30, bigRandom=70}, startTired=0, avoidWalls=1.0, generalDir=0.6, randomDir=1.2, step=6.0}
  elseif effc == "featherFern" then
    sts = {branches=3+random(3)+3*big, expectedBranchLife={small=130, big=200, smallRandom=50, bigRandom=100}, startTired=-77 - (77*big), avoidWalls=0.6, generalDir=1.2, randomDir=0.6, step=2.0, featherCounter=0, airRoots=0}
  elseif effc == "Fungus Tree" then
    sts = {branches=10+random(10)+15*big, expectedBranchLife={small=30, big=60, smallRandom=15, bigRandom=30}, startTired=0, avoidWalls=0.8, generalDir=0.8, randomDir=1.0, step=3.0, thickness=(6+random(3))*(1+big*0.4), branchPoints=list()}
  elseif effc == "Head Lamp" then
    sts = {branches=1, expectedBranchLife={small=80, big=160, smallRandom=5, bigRandom=20}, startTired=0, avoidWalls=0.8, generalDir=3, randomDir=10, step=3.0, thickness=(10+random(3))*(1+big*0.4), branchPoints={}}
  end
  
  if (spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==0)and(spelrelaterat.afaMvLvlEdit(point(q2,c2+1), layer)==1) then
    
    local pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10+random(20), 10)
    
    if effc == "Fungus Tree" or effc == "Head Lamp" then
      if big then
        expectedLife = sts.expectedBranchLife.big+random(sts.expectedBranchLife.bigRandom)
      else
        expectedLife = sts.expectedBranchLife.small+random(sts.expectedBranchLife.smallRandom)
      end
      sts.branchPoints = list({list({pos=pnt, dir=point(0,-1), thickness=sts.thickness, layer=lr, lifeLeft=expectedLife, tired=sts.startTired})})
    end
    
    
    for branches = 1, sts.branches do
      local pos = point(pnt.x, pnt.y)
      local lstPos = point(pnt.x, pnt.y)
      local generalDir = fiffigt.degToVec(-60+random(120))
      local lstAimPnt = generalDir
      local brLr = lr
      
      local brLrDir = 101 + random(201)
      local avoidWalls = 2.0
      
      local tiredNess = sts.startTired

      local expectedLife
      
      if tobool(big) then
        expectedLife = sts.expectedBranchLife.big+random(sts.expectedBranchLife.bigRandom)
      else
        expectedLife = sts.expectedBranchLife.small+random(sts.expectedBranchLife.smallRandom)
      end

      local baseThickness
      local startLifeTime

      if effc == "featherFern" then
        sts.airRoots = 25+15*big
      elseif effc == "Fungus Tree" or effc == "Head Lamp" then
        branch = sts.branchPoints[random(#sts.branchPoints)]
        sts.branchPoints:deleteOne(branch)
        
        baseThickness = branch.thickness
        pos = branch.pos
        lstPos = branch.pos
        brLr = branch.layer
        generalDir = branch.dir
        lstAimPnt = branch.dir
        tiredNess = branch.tired
        expectedLife = restrict(branch.lifeLeft - 11 + random(21), 5, 200)
        startLifeTime = expectedLife
      end
      
      for step = 1, expectedLife do
        lstPos = pos

        if effc == "featherFern" then
          tiredNess = tiredNess + 0.5 + math.abs(tiredNess*0.05) - 0.3*big
        elseif effc == "Fungus Tree" or effc == "Head Lamp" then
          tiredNess = -90*(1.0-((startLifeTime-step)/startLifeTime))
        end
        
        local aimPnt = generalDir*sts.generalDir+fiffigt.degToVec(random(360))*sts.randomDir + point(0, tiredNess*0.01)
        
        for _,dir in ipairs({point(-1,0), point(-1,-1), point(0,-1), point(1,-1), point(1,0), point(1,1), point(0,1), point(-1,1)}) do
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(lstPos)+dir+gRenderCameraTilePos, toint((brLr/10.0)-0.4999)+1)==1) then
            aimPnt = aimPnt - dir*avoidWalls
            avoidWalls = spelrelaterat.restrict(avoidWalls - 0.06, 0.2, 2)
            step = step + toint(effc ~= "Fungus Tree")
          else
            aimPnt = aimPnt + dir*0.1
          end
        end
        
        avoidWalls = spelrelaterat.restrict(avoidWalls + 0.03, 0.2, 2)
        
        local lstLayer = brLr
        
        
        brLr = brLr + brLrDir*0.01
        
        local smllst = lrRange[1]
        if toint((lstLayer/10.0)-0.4999)+1 > 1 then
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos)+gRenderCameraTilePos, toint((lstLayer/10.0)-0.4999)+1-1)==1) then
            local wall = toint((lstLayer/10.0)-0.4999)*10
            if wall > 0 then
              wall = wall - 1 
            end
            smllst = spelrelaterat.restrict(smllst, wall, 0)
          end
        end
        
        local bggst = lrRange[2]
        if toint((lstLayer/10.0)-0.4999)+1 < 3 then
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos)+gRenderCameraTilePos, toint((lstLayer/10.0)-0.4999)+1+1)==1) then
            local wall = toint((spelrelaterat.restrict(lstLayer, 1, 29)/10.0)+0.4999)*10 -1
            bggst = spelrelaterat.restrict(bggst, 0, wall)
          end
        end
        
        if brLr < smllst then
          brLr = smllst
          brLrDir = random(41)
        end
        if brLr > bggst then
          brLr = bggst
          brLrDir = -random(41)
        end
        
        -- aimPnt = aimPnt + point(0, tiredNess*0.01)
        
        aimPnt = (aimPnt + lstAimPnt + lstAimPnt)/3.0
        
        lstAimPnt = aimPnt
        
        pos = pos + fiffigt.moveToPoint(point(0,0), aimPnt, sts.step)
        
        local pstColor = 0

        local fc
        local lngth
        local ftness
        local rct
        local brLrDir
        local thickness
        local rnd

        if effc == "featherFern" then
          if sts.airRoots > 0 then
            sts.featherCounter = 20
            sts.airRoots = sts.airRoots - 1
          end
          
          
          sts.featherCounter = sts.featherCounter + fiffigt.diag(pos, lstPos)*0.5 + math.abs(pos.x - lstPos.x) + math.abs(lstLayer-brLr)
          if sts.featherCounter > 8 + ((expectedLife-step)/expectedLife)*12 then
            sts.featherCounter = sts.featherCounter - (8 + ((expectedLife-step)/expectedLife)*12)
            
            fc = ((expectedLife-step)/expectedLife)
            fc = 1.0-fc
            fc = fc*fc
            fc = 1.0-fc
            
            lngth = math.sin(fc*PI)*  (math.abs(pos.y-pnt.y) + 120)/3.0
            
            for cntr = 1, sts.airRoots do
              lngth = (lngth*6.0 + (math.abs(pos.y-pnt.y)+4))/7.0
            end
            -- put (expectedLife-step)/expectedLife.float .... lngth
            
            for _,rct in ipairs({rect(pos, pos) + rect(0, 0, 1, lngth), rect(pos, pos) + rect(1, 0, 2, lngth-random(random(random(toint(lngth)+1))))}) do
              member("layer"..tostring(toint(brLr))).image:copyPixels(member("pxl").image, rct, member("pxl").image.rect, {ink=36, color=colr})
            end
            
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rect(pos, pos) + rect(-6, 0, 6, lngth+2), "featherFernGradient", member("featherFernGradient").rect, 0.5)
            
            pstColor = 1
          end
          
          fc = ((expectedLife-step)/expectedLife)
          fc = fc*fc
          
          ftness = sin(fc*PI)*(4+1*big)
          rct = rect(pos, pos) + rect(-1, -3, 1, 3)+rect(-ftness, -ftness, ftness, ftness)
          
          
          rct = spelrelaterat.rotateToQuad( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          
          brLrDir = brLrDir -4 + random(7)
        elseif effc == "Sprawlbush" then          
          rct = rect(pos, pos) + rect(-2, -5, 2, 5)
          rct = spelrelaterat.rotateToQuad( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        elseif effc == "Fungus Tree" then
          thickness = ((startLifeTime-step)/startLifeTime)*baseThickness
          
          sts.branchPoints:add({pos=pos, dir=fiffigt.moveToPoint(point(0,0), aimPnt, 1.0), thickness=thickness, layer=brLr, lifeLeft=startLifeTime-step, tired=tiredNess})
          
          
          
          if step == expectedLife then
            rnd = random(5)
            rct = rect(pos, pos)+rect(-5, -19, 5, 1)
            if random(2)==1 then
              rct = fiffigt.vertFlipRect(rct)
            end
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("fungusTreeTops").image, rct, rect((rnd-1)*10, 1, rnd*10, 21), {ink=36, color=colr})
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rect(pos, pos)+rect(-7, -11, 7, 3), "softBrush1", member("softBrush1").rect, 0.5)
          end
          
          rct = rect(pos, pos) + rect(-1, -3, 1, 3)+rect(-thickness, -thickness, thickness, thickness)
          rct = spelrelaterat.rotateToQuad( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        elseif effc == "Head Lamp" then
          -- Made by April
          
          thickness = ((startLifeTime-step)/startLifeTime)*baseThickness
          
          sts.branchPoints:add({pos=pos, dir=fiffigt.moveToPoint(point(0,0), aimPnt, 1.0), thickness=thickness, layer=brLr, lifeLeft=startLifeTime-step, tired=tiredNess})
          if step <= 7 then            
            --for making the stump more lumpy .. strange, quite like your mother
            rct=thickness*7
            rct2= rect(-8, 0, 9, 17)
            for circleStep = 0, 3 do    
              rct=rct-(rct/10)
              --draws circle around stump then places random points along stump 
              local stumpRadius= (rct)/2
              rnd=stumpRadius
              for circlePnt = 0, rnd do
                local randAngle = random(180)
                randAngle = randAngle * (math.pi/180)
                local randAnglePos= point(math.sin(randAngle)*100, math.cos(randAngle)*100)
                randAnglePos=randAnglePos*random(stumpRadius)
                randAnglePos=randAnglePos/100
                --draw circle
                for insideStep = 0, 2 do 
                  if (brLr-(insideStep+circleStep)) < 29 and (brLr-(insideStep+circleStep)) > 0 then
                    member("layer"..tostring(brLr.integer-(insideStep+circleStep))).image:copyPixels(member("blob").image, rct2+rect(randAnglePos, randAnglePos)+rect(pos, pos), member("blob").rect, {ink=36, color=colr})
                  end
                end
              end
            end
            
          end 
          
          if step == expectedLife then
            rnd = random(4)
            local headSize= rect(-79, -9, 80, 10)+rect(pos,pos)
            --draw bounds for antennas and fruit
            local HeadLampSprite=rect(160*(rnd-1), 0,160*rnd, 19)
            rnd=random(15)+7
            local overallrnd=random(80)-40
            local rctL=spelrelaterat.rotateToQuadFix(headSize, rnd+overallrnd)
            local rctR=spelrelaterat.rotateToQuadFix(headSize, -1*rnd+overallrnd+random(5))
            --draw fruits
            local fruitRnd=random(6)
            local fruitRct=rect(-17, -10, 18, 10)
            local fruitRctR=spelrelaterat.rotateToQuadFix(fruitRct+rect(rctR[3], rctR[3]), (rnd+overallrnd)/2)
            local FruitRctL=spelrelaterat.rotateToQuadFix(fruitRct+rect(rctL[4], rctL[4]), (rnd+overallrnd)/2)
            local fruitSpriteRct=rect(35*(fruitRnd-1), 0, 35*fruitRnd, 20)
            
            --peak dogshit to prevent drawing outside valid layers
            if (toint(brLr)-1)<0 then
              brLr=brLr+1
            end
            
            --Right fruits
            member("layer"..tostring(toint(brLr)-1)).image:copyPixels(member("HeadLampFruitGraf").image, fruitRctR, fruitSpriteRct, {ink=36, color=lampColr})
            spelrelaterat.copyPixelsToRootEffectColor(lampLayer, brLr-1, fruitRctR, "HeadLampFruitGraf", fruitSpriteRct, 0.5, 1)
            --left fruit
            fruitRnd=random(6)
            fruitSpriteRct=rect(35*(fruitRnd-1), 0, 35*fruitRnd, 20)
            member("layer"..tostring(toint(brLr)-1)).image:copyPixels(member("HeadLampFruitGraf").image, FruitRctL-rect(0,0,0,3), fruitSpriteRct, {ink=36, color=lampColr})
            
            spelrelaterat.copyPixelsToRootEffectColor(lampLayer, brLr-1, FruitRctL-rect(0,0,0,3), "HeadLampFruitGraf", fruitSpriteRct, 0.5, 1)
            --draw antennas
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("HeadLampGrafR").image, rctR, HeadLampSprite, {ink=36, color=colr})
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("HeadLampGrafL").image, rctL, HeadLampSprite, {ink=36, color=colr})
            --erase any effectcolor below it
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctR, "HeadLampGrafR", HeadLampSprite, 0.5, -1)
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctL, "HeadLampGrafL", HeadLampSprite, 0.5, -1)
            
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctR, "HeadLampGrad", member("HeadLampGrad").rect, 0.5, 1)
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctL, "HeadLampGrad", member("HeadLampGrad").rect, 0.5, 1)
          end
          
          rct = rect(pos, pos) + rect(-1, -3, 1, 3)+rect(-thickness, -thickness, thickness, thickness)
          rct = spelrelaterat.rotateToQuad( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        end
        
        member("layer"..tostring(toint(brLr))).image:copyPixels(member("blob").image, rct, member("blob").image.rect, {ink=36, color=colr})
        member("layer"..tostring(toint(lstLayer))).image:copyPixels(member("blob").image, rct, member("blob").image.rect, {ink=36, color=colr})
        
        if tobool(pstColor) then
          local blnd = (1.0-((expectedLife - step)/expectedLife))*25 + random((1.0-((expectedLife - step)/expectedLife))*75)
          if effc == "Fungus Tree" then
            blnd = (1.0-((expectedLife - step)/expectedLife))*100
          end
          if effc == "Head Lamp" then
            blnd = (1.0-((expectedLife - step)/expectedLife))*50
          end
          member("softbrush2").image:copyPixels(member("pxl").image, member("softbrush2").image.rect, rect(0,0,1,1), {color=color(255,255,255)})
          member("softbrush2").image:copyPixels(member("softbrush1").image, member("softbrush2").image.rect, member("softbrush1").image.rect, {blend=blnd})
          spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, spelrelaterat.rotateToQuad(rect(pos, pos) + rect(-17, -25, 17, 25),fiffigt.lookAtPoint(pos, lstPos)), "softBrush2", member("softBrush1").rect, 0.5)
        end
      end
    end
  end
end


function me.applyInverse3Dsprawler(q, c, effc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local big = 0
  if (c > 1) and ((c2 - 1) > 0) then
    big = (gEEprops.effects[r].mtrx[q2][c2+1] > 0)
  end
  
  local lr = 1

  local layer
  local lrRange

  if lrSup == "All" then
    layer = random(3)
    lrRange = {0, 29}
  elseif lrSup == "1" then
    layer = 1
  elseif lrSup == "2" then
    layer = 2
    lrRange = {6, 29}
  elseif lrSup == "3" then
    layer = 3
    lrRange = {6, 29}
  elseif lrSup == "1:st and 2:nd" then
    layer = random(2)
    lrRange = {0, 29}
  elseif lrSup == "2:nd and 3:rd" then
    layer = random(2) + 1
    lrRange = {6, 29}
  else
    layer = random(3)
    lrRange = {0, 29}
  end
  
  lr = ((layer-1)*10) + random(9) - 1
  
  if layer == 1 then
    if lr < 5 then
      lrRange = {0, 5} 
    else 
      lrRange = {6, 29} 
    end
  end

  local sts

  if effc == "Sprawlbush" then
    sts = {branches=10+random(10)+15*big, expectedBranchLife={small=20, big=35, smallRandom=30, bigRandom=70}, startTired=0, avoidWalls=1.0, generalDir=0.6, randomDir=1.2, step=6.0}
  elseif effc == "Fungus Roots" then
    sts = {branches=10+random(10)+15*big, expectedBranchLife={small=30, big=60, smallRandom=15, bigRandom=30}, startTired=0, avoidWalls=0.8, generalDir=0.8, randomDir=1.0, step=3.0, thickness=(6+random(3))*(1+big*0.4), branchPoints=list()}
  elseif effc == "Ceiling Lamp" then
    sts = {branches=1, expectedBranchLife={small=80, big=160, smallRandom=5, bigRandom=20}, startTired=0, avoidWalls=0.8, generalDir=3, randomDir=10, step=3.0, thickness=(10+random(3))*(1+big*0.4), branchPoints=list()}
  end
  
  local pnt
  
  if (spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==0)and(spelrelaterat.afaMvLvlEdit(point(q2,c2-1), layer)==1) then
    
    pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10+random(20), -10)
    
    if effc == "Fungus Roots" or effc == "Ceiling Lamp" then
      if big then
        expectedLife = sts.expectedBranchLife.big+random(sts.expectedBranchLife.bigRandom)
      else
        expectedLife = sts.expectedBranchLife.small+random(sts.expectedBranchLife.smallRandom)
      end
      sts.branchPoints = list({{pos=pnt, dir=point(0,1), thickness=sts.thickness, layer=lr, lifeLeft=expectedLife, tired=sts.startTired}})
    end
    
    for branches = 1, sts.branches do
      local pos = point(pnt.x, pnt.y)
      local lstPos = point(pnt.x, pnt.y)
      local generalDir = fiffigt.degToVec(-60+random(120) + 180)
      local lstAimPnt = generalDir
      local brLr = lr
      
      local brLrDir = 101 + random(201)
      local avoidWalls = 2.0
      
      local tiredNess = sts.startTired
      local expectedLife

      if tobool(big) then
        expectedLife = sts.expectedBranchLife.big+random(sts.expectedBranchLife.bigRandom)
      else
        expectedLife = sts.expectedBranchLife.small+random(sts.expectedBranchLife.smallRandom)
      end

      local branch
      local baseThickness
      local startLifeTime

      if effc == "Fungus Roots" or effc == "Ceiling Lamp" then
        branch = sts.branchPoints[random(#sts.branchPoints)]
        sts.branchPoints:deleteOne(branch)
        
        baseThickness = branch.thickness
        pos = branch.pos
        lstPos = branch.pos
        brLr = branch.layer
        generalDir = branch.dir
        lstAimPnt = branch.dir
        tiredNess = branch.tired
        expectedLife = spelrelaterat.restrict(branch.lifeLeft - 11 + random(21), 5, 200)
        startLifeTime = expectedLife
      end
      
      for step = 1, expectedLife do
        lstPos = pos
        
        if effc == "Fungus Roots" or effc == "Ceiling Lamp" then
          tiredNess = -90*(1.0-((startLifeTime-step)/startLifeTime))
        end

        local aimPnt = generalDir*sts.generalDir+fiffigt.degToVec(random(360))*sts.randomDir - point(0, tiredNess*0.01)
        local avoidWalls
        for _,dir in ipairs({point(-1,0), point(-1,-1), point(0,-1), point(1,-1), point(1,0), point(1,1), point(0,1), point(-1,1)}) do
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(lstPos)+dir+gRenderCameraTilePos, toint((brLr/10.0)-0.4999)+1)==1) then
            aimPnt = aimPnt - dir*avoidWalls
            avoidWalls = spelrelaterat.restrict(avoidWalls - 0.06, 0.2, 2)
            step = step + (effc ~= "Fungus Roots")
          else
            aimPnt = aimPnt + dir*0.1
          end
        end
        
        avoidWalls = spelrelaterat.restrict(avoidWalls + 0.03, 0.2, 2)
        
        local lstLayer = brLr
        
        
        brLr = brLr + brLrDir*0.01
        
        local smllst = lrRange[1]
        if toint((lstLayer/10.0)-0.4999)+1 > 1 then
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos)+gRenderCameraTilePos, toint((lstLayer/10.0)-0.4999)+1-1)==1) then
            local wall = toint((lstLayer/10.0)-0.4999)*10
            if wall > 0 then
              wall = wall - 1 
            end
            smllst = spelrelaterat.restrict(smllst, wall, 0)
          end
        end
        
        local bggst = lrRange[2]
        if toint((lstLayer/10.0)-0.4999)+1 < 3 then
          if (spelrelaterat.afaMvLvlEdit(spelrelaterat.giveGridPos(pos)+gRenderCameraTilePos, toint((lstLayer/10.0)-0.4999)+1+1)==1) then
            local wall = toint((restrict(lstLayer, 1, 29)/10.0)+0.4999)*10 -1
            bggst = spelrelaterat.restrict(bggst, 0, wall)
          end
        end
        
        if brLr < smllst then
          brLr = smllst
          brLrDir = random(41)
        end
        if brLr > bggst then
          brLr = bggst
          brLrDir = -random(41)
        end
        
        -- aimPnt = aimPnt + point(0, tiredNess*0.01)
        
        aimPnt = (aimPnt + lstAimPnt + lstAimPnt)/3.0
        
        lstAimPnt = aimPnt
        
        pos = pos + fiffigt.moveToPoint(point(0,0), aimPnt, sts.step)
        
        local pstColor = 0
        local rct
        
        if effc == "Sprawlroots" then
          rct = rect(pos, pos) + rect(-2, -5, 2, 5)
          rct = rotate( rct, fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        elseif effc == "Fungus Roots" then
          local thickness = ((startLifeTime-step)/startLifeTime)*baseThickness
          
          sts.branchPoints:add({pos=pos, dir=fiffigt.moveToPoint(point(0,0), aimPnt, 1.0), thickness=thickness, layer=brLr, lifeLeft=startLifeTime-step, tired=tiredNess})
          
          if step == expectedLife then
            local rnd = random(5)
            rct = rect(pos, pos)+rect(-5, -19, 5, 1)
            if random(2)==1 then
              rct = fiffigt.vertFlipRect(rct)
            end
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("fungusTreeTops").image, rct, rect((rnd-1)*10, 1, rnd*10, 21), {ink=36, color=colr})
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rect(pos, pos)+rect(-7, -11, 7, 3), "softBrush1", member("softBrush1").image.rect, 0.5)
          end
          
          rct = rect(pos, pos) + rect(-1, -3, 1, 3)+rect(-thickness, -thickness, thickness, thickness)
          rct = rotate( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        elseif effc == "Ceiling Lamp" then
          -- Made by April, upside-down-ified by Alduris
          
          local thickness = ((startLifeTime-step)/startLifeTime)*baseThickness
          
          sts.branchPoints:add({pos=pos, dir=fiffigt.moveToPoint(point(0,0), aimPnt, 1.0), thickness=thickness, layer=brLr, lifeLeft=startLifeTime-step, tired=tiredNess})
          
          if step <= 7 then            
            --for making the stump more lumpy .. strange, quite like your mother
            rct=thickness*7
            local rct2= rect(-8, 0, 9, 17)
            
            for circleStep = 0, 3 do    
              rct=rct-(rct/10)
              --draws circle around stump then places random points along stump 
              local stumpRadius= (rct)/2
              local rnd=stumpRadius
              for circlePnt = 0, rnd do
                local randAngle = random(180)
                randAngle = randAngle * (math.pi/180)
                local randAnglePos= point(math.sin(randAngle)*100, math.cos(randAngle)*100)
                randAnglePos=randAnglePos*random(stumpRadius)
                randAnglePos=randAnglePos/100
                --draw circle
                for insideStep = 0, 2 do 
                  if (brLr-(insideStep+circleStep)) < 29 and (brLr-(insideStep+circleStep)) > 0 then
                    member("layer"..tostring(toint(brLr)-(insideStep+circleStep))).image:copyPixels(member("blob").image, rct2+rect(randAnglePos, randAnglePos)+rect(pos, pos), member("blob").image.rect, {ink=36, color=colr})
                  end
                end
              end
            end
          end 

          local rnd
          local headSize
          local HeadLampSprite
          
          if step == expectedLife then
            rnd = random(4)
            headSize= rect(-79, -9, 80, 10)+rect(pos,pos)
            --draw bounds for antennas and fruit
            HeadLampSprite=rect(160*(rnd-1), 0,160*rnd, 19)
            rnd=random(15)+7
            local overallrnd=random(80)-40
            local rctL=spelrelaterat.rotateToQuadFix(headSize, rnd+overallrnd)
            local rctR=spelrelaterat.rotateToQuadFix(headSize, -1*rnd+overallrnd+random(5))
            --draw fruits
            local fruitRnd=random(6)
            local fruitRct=rect(-17, -10, 18, 10)
            local fruitRctR=spelrelaterat.rotateToQuadFix(fruitRct+rect(rctR[3], rctR[3]), (rnd+overallrnd)/2)
            local FruitRctL=spelrelaterat.rotateToQuadFix(fruitRct+rect(rctL[4], rctL[4]), (rnd+overallrnd)/2)
            local fruitSpriteRct=rect(35*(fruitRnd-1), 0, 35*fruitRnd, 20)
            
            --peak dogshit to prevent drawing outside valid layers
            if (toint(brLr)-1)<0 then
              brLr=brLr+1
            end
            
            --Right fruits
            member("layer"..tostring(toint(brLr)-1)).image:copyPixels(member("HeadLampFruitGraf").image, fruitRctR, fruitSpriteRct, {ink=36, color=lampColr})
            spelrelaterat.copyPixelsToRootEffectColor(lampLayer, brLr-1, fruitRctR, "HeadLampFruitGraf", fruitSpriteRct, 0.5, 1)
            --left fruit
            fruitRnd=random(6)
            fruitSpriteRct=rect(35*(fruitRnd-1), 0, 35*fruitRnd, 20)
            member("layer"..tostring(toint(brLr)-1)).image:copyPixels(member("HeadLampFruitGraf").image, FruitRctL-rect(0,0,0,3), fruitSpriteRct, {ink=36, color=lampColr})
            
            spelrelaterat.copyPixelsToRootEffectColor(lampLayer, brLr-1, FruitRctL-rect(0,0,0,3), "HeadLampFruitGraf", fruitSpriteRct, 0.5, 1)
            --draw antennas
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("HeadLampGrafR").image, rctR, HeadLampSprite, {ink=36, color=colr})
            member("layer"..tostring(toint(brLr))).image:copyPixels(member("HeadLampGrafL").image, rctL, HeadLampSprite, {ink=36, color=colr})
            --erase any effectcolor below it
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctR, "HeadLampGrafR", HeadLampSprite, 0.5, -1)
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctL, "HeadLampGrafL", HeadLampSprite, 0.5, -1)
            
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctR, "HeadLampGrad", member("HeadLampGrad").rect, 0.5, 1)
            spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rctL, "HeadLampGrad", member("HeadLampGrad").rect, 0.5, 1)
          end
          
          rct = rect(pos, pos) + rect(-1, -3, 1, 3)+rect(-thickness, -thickness, thickness, thickness)
          rct = rotate( rct ,fiffigt.lookAtPoint(pos, lstPos))
          
          brLrDir = brLrDir -11 + random(21)
          
          pstColor = 1
        end
        
        member("layer"..tostring(toint(brLr))).image:copyPixels(member("blob").image, rct, member("blob").image.rect, {ink=36, color=colr})
        member("layer"..tostring(toint(lstLayer))).image:copyPixels(member("blob").image, rct, member("blob").image.rect, {ink=36, color=colr})
        
        if tobool(pstColor) then
          local blnd = (1.0-((expectedLife - step)/expectedLife))*25 + random((1.0-((expectedLife - step)/expectedLife))*75)
          if effc == "Fungus Roots" then
            blnd = (1.0-((expectedLife - step)/expectedLife))*100
          end
          member("softbrush2").image:copyPixels(member("pxl").image, member("softbrush2").image.rect, rect(0,0,1,1), {color=color(255,255,255)})
          member("softbrush2").image:copyPixels(member("softbrush1").image, member("softbrush2").image.rect, member("softbrush1").image.rect, {blend=blnd})
          spelrelaterat.copyPixelsToEffectColor(gdLayer, brLr, rotate(rect(pos, pos) + rect(-17, -25, 17, 25),fiffigt.lookAtPoint(pos, lstPos)), "softBrush2", member("softBrush1").image.rect, 0.5)
        end
      end
    end
  end
end


return me