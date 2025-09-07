-- global vertRepeater, r, gEEprops, solidMtrx, gLEProps, colr, colrDetail, colrInd, gdLayer, gdDetailLayer, gdIndLayer, gLOProps, gLevel, gEffectProps, gRenderCameraTilePos, effectSeed, lrSup, chOp, fatOp, gradAf, effectIn3D, gAnyDecals, gRotOp, slimeFxt, DRDarkSlimeFix, DRWhite, DRPxl, DRPxlRect, colrIntensity, skyRootsFix

local me = {}

local utils = require('comEditorUtils')
local spelrelaterat = require('spelrelaterat')
local fiffigt = require('fiffigt')

function me.applyDarkSlime (q, c, effectR)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  cls = {color(255, 0,0), color(0,255, 0), color(0,0,255)}
  
  local fc = spelrelaterat.solidAfaMv(point(q2,c2), 1)
  
--   if lrSup == "All" then
--   elseif lrSup == "1" then
--   elseif lrSup == "2" then
--   elseif lrSup == "3" then
--   elseif lrSup == "1:st and 2:nd" then
--   elseif lrSup == "2:nd and 3:rd" then
--   else
--   end
  
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
  else
  end
  
  for d = 0, 29 do
    local lr

    if lrSup == "All" then
        lr = d
    elseif lrSup == "1" then
        lr = spelrelaterat.restrict(d, 0, 9)
    elseif lrSup == "2" then
        lr = spelrelaterat.restrict(d, 10, 19)
    elseif lrSup == "3" then
        lr = spelrelaterat.restrict(d, 20, 29)
    elseif lrSup == "1:st and 2:nd" then
        lr = spelrelaterat.restrict(d, 0, 19)
    elseif lrSup == "2:nd and 3:rd" then
        lr = spelrelaterat.restrict(d, 10, 29)
    else
        lr = d
    end
    
    local sld

    if (lr==0)or(lr == 10)or(lr==20) then
      local lraddc = 1+(lr>9)+(lr>19)
      sld = (solidMtrx[q2][c2][ lraddc ])
      if tobool(DRDarkSlimeFix) then
        fc = spelrelaterat.solidAfaMv(point(q2,c2), lraddc)
      else
        fc = spelrelaterat.solidAfaMv(point(q2,c2)+gRenderCameraTilePos, lraddc)
      end
    end

    local deepEffect = 0
    
    if (lr == 0)or(lr==10)or(lr==20)or(sld==0)then
      deepEffect = 1
    end

    local endofloop = effectR.mtrx[q2][c2]*(0.2 + (0.8*deepEffect))*0.01*80*fc
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

      local layerd = member("layer"..tostring(d)).image
      
      if (layerd:getPixel(pnt) ~= DRWhite) and (d >= dmin) and (d <= dmax) then
        lgt = random(40)
        if (layerd:getPixel(pnt+point(0,lgt)) ~= DRWhite)  and (d >= dmin) and (d <= dmax) then
          clr = cls[random(3)]
          layerlr = member("layer"..tostring(lr)).image
          layerlr:copyPixels(DRPxl, rect(pnt, pnt+point(1, lgt)), DRPxlRect, {color=clr})
          if random(2)==1 then
            layerlr:copyPixels(DRPxl, rect(pnt, pnt+point(1, lgt))+rect(-1, 1, -1, -1), DRPxlRect, {color=clr})
          else
            layerlr:copyPixels(DRPxl, rect(pnt, pnt+point(1, lgt))+rect(1, 1, 1, -1), DRPxlRect, {color=clr})
          end
        end
      end
    end
  end
end

function me.applyHugeFlower (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y

    local d

  if lrSup == "All" then
    d = random(30)-1
  elseif lrSup == "1" then
    d = random(10)-1
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20)-1
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(30)-1
  end
  
  local lr = 1+toint(d>9)+toint(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local startQuadToDraw = list()
    local quadsToDraw = list()
    
    startQuadToDraw:add(rect(pnt.x-3, pnt.y-3, pnt.x+3, mdPnt.y+3))
    
    if not tobool(skyRootsFix) then
      member("layer"..tostring(d)).buf:copyPixels(member("flowerhead").image, rect(pnt.x-3, pnt.y-3, pnt.x+3, mdPnt.y+3), member("flowerhead").image.rect, {color=colr, ink=36})
    end
    
    local h = pnt.y
    
    while h < 30000 do
      h = h + 1
      pnt.x = pnt.x -2 + random(3)
      
      if tobool(skyRootsFix) then
        quadsToDraw:add(rect(pnt.x-1, h, pnt.x+2, h+2))
      else
        member("layer"..tostring(d)).buf:copyPixels(member("pxl").image, rect(pnt.x-1, h, pnt.x+2, h+2), member("pxl").image.rect, {color=colr})
      end
      
      local tlPos = spelrelaterat.giveGridPos(point(pnt.x, h)) + gRenderCameraTilePos
      
      if tobool(skyRootsFix) and (not tobool(spelrelaterat.withinBoundsOfLevel(tlPos))) then
        return
      end
      
      if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
        break
      elseif spelrelaterat.solidAfaMv(tlPos, lr) == 1 then
        break
      end
      
    end
    
    if tobool(skyRootsFix) then
      for _,qdd in ipairs(quadsToDraw) do
        member("layer"..tostring(d)).buf:copyPixels(member("pxl").image, qdd, member("pxl").image.rect, {color=colr})
      end
      member("layer"..tostring(d)).buf:copyPixels(member("flowerhead").image, startQuadToDraw[1], member("flowerhead").image.rect, {color=colr, ink=36})
    end
    
    spelrelaterat.copyPixelsToEffectColor(gdLayer, d, rect(headPos.x-37, headPos.y-37, headPos.x+37, h+10), "hugeFlowerMaskMask", member("hugeFlowerMask").image.rect, 0.8)
    
  end
end

function me.ApplyArmGrower (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y

  local d

  if lrSup == "All" then
    d = random(29)
  elseif lrSup == "1" then
    d = random(9)
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(19)
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(29)
  end

  local lr = 1+toint(d>9)+toint(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local lastDir = 180 - 101 + random(201)
    
    local points = list({pnt})
    
    local quadsToDraw = list()

    local lastPnt
    
    
    while pnt.y < 30000 do
      local dir = 180 - 31 + random(61)
      dir = fiffigt.lerp(lastDir, dir, 0.75)
      lastPnt = pnt
      pnt = pnt + fiffigt.degToVec(dir)*30.0
      lastDir = dir
      
      local rct = (lastPnt + pnt)/2.0
      rct = rect(rct, rct)
      rct = rct + rect(-10, -25, 10, 25)
      local qd = rotate(rct, fiffigt.lookAtPoint(lastPnt, pnt))
      if(random(2)==1)then
        qd = spelrelaterat.flipQuadH(qd)
      end
      
      points:add(pnt)
      
      local var = random(13)

      if tobool(skyRootsFix) then
        quadsToDraw:add(list({qd, rect((var-1)*20, 1, var*20, 50+1)}))
      else
        member("layer"..tostring(d)).buf:copyPixels(member("ArmGrowerGraf").image, qd, rect((var-1)*20, 1, var*20, 50+1), {color=colr, ink=36})
      end
      
      local tlPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      if tobool(skyRootsFix) and (not tobool(spelrelaterat.withinBoundsOfLevel(tlPos))) then
        return
      end
      
      if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
        break
      elseif spelrelaterat.solidAfaMv(tlPos, lr) == 1 then
        break
      end
      
    end
    
    if tobool(skyRootsFix) then
      for _,qdd in ipairs(quadsToDraw) do
        member("layer"..tostring(d)).buf:copyPixels(member("ArmGrowerGraf").image, qdd[1], qdd[2], {color=colr, ink=36} )
      end
    end
    
    if(#points > 2)then
      for p = 1, #points -1 do
        local rct = (points[p] + points[p+1])/2.0
        rct = rect(rct, rct)
        rct = rct + rect(-12, -36, 12, 36)
        local qd = rotate(rct, fiffigt.lookAtPoint(points[p], points[p+1]))
        
        spelrelaterat.copyPixelsToEffectColor2(gdLayer, d, qd, "softBrush1", member("softBrush1").image.rect, 0.5, (((#points-p+1)/#points) ^ 1.5))
      end
    end
    
    -- copyPixelsToEffectColor(gdLayer, d, rect(headPos.x-37, headPos.y-37, headPos.x+37, h+10), "hugeFlowerMaskMask", member("hugeFlowerMask").image.rect, 0.8)
    
  end
end

function me.ApplyThornGrower (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y

  local d

    if lrSup == "All" then
        d = random(29)
  elseif lrSup == "1" then
    d = random(9)
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(19)
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(29)
  end
  
  local lr = 1+(d>9)+(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local lastDir = 180 - 61 + random(121)
    local blnd = 1
    local blnd2 = 1
    
    local wdth = 0.5
    
    local searchBase = 50
    
    local quadsToDraw = list()
    
    local lastPnt

    while pnt.y < 30000 do
      local dir = 180 - 61 + random(121)
      dir = fiffigt.lerp(lastDir, dir, 0.35)
      lastPnt = pnt
      pnt = pnt + fiffigt.degToVec(dir)*30.0
      
      if(searchBase > 0)then
        local moveDir = point(0,0)
        for _,tst in ipairs({point(-1,0), point(1,0), point(1,1), point(0,1), point(-1, 1)}) do
          local tstPnt = spelrelaterat.giveGridPos(lastPnt) + gRenderCameraTilePos + tst
          if(tstPnt.x > 0)and(tstPnt.x < gLOprops.size.x-1)and(tstPnt.y > 0)and(tstPnt.y < gLOprops.size.y-1)then
            moveDir = moveDir + tst*gEEprops.effects[r].mtrx[tstPnt.x][tstPnt.y]
          end
        end
        pnt = pnt + (moveDir/100.0)*searchBase
        searchBase = searchBase - 1.5
        pnt = lastPnt + fiffigt.moveToPoint(lastPnt, pnt, 30.0)
      end
      
      lastDir = dir
      
      local rct = (lastPnt + pnt)/2.0
      rct = rect(rct, rct)
      rct = rct + rect(-10*wdth, -25, 10*wdth, 25)
      local qd = rotate(rct, fiffigt.lookAtPoint(lastPnt, pnt))
      if(random(2)==1)then
        qd = spelrelaterat.flipQuadH(qd)
      end
      
      wdth = wdth + (random(1000)/1000.0)/5.0
      if(wdth > 1)then
        wdth = 1
      end
      
      local var = random(13)
      
      
      if tobool(skyRootsFix) then
        quadsToDraw:add(list({qd, rect((var-1)*20, 1, var*20, 50+1), blnd}))
      else
        member("layer"..tostring(d)).image:copyPixels(member("thornBushGraf").image, qd, rect((var-1)*20, 1, var*20, 50+1), {color=colr, ink=36} )
        spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "thornBushGrad", rect((var-1)*20, 1, var*20, 50+1), 0.5, blnd)
      end
      
      
      blnd = blnd * 0.85
      
      if(blnd2 > 0)then
        local rct = (lastPnt + pnt)/2.0
        rct = rect(rct, rct)
        rct = rct + rect(-12, -36, 12, 36)
        local qd = rotate(rct, fiffigt.lookAtPoint(lastPnt, pnt))
        
        spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qd, "softBrush1", member("softBrush1").image.rect, 0.5, blnd2)
        
        blnd2 = blnd2 - 0.15
      end
      
      local tlPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      if tobool(skyRootsFix) and (not tobool(spelrelaterat.withinBoundsOfLevel(tlPos))) then
        return
      end
      
      if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
        break
      elseif spelrelaterat.solidAfaMv(tlPos, lr) == 1 then
        break
      end
      
    end
    
    if tobool(skyRootsFix) then
      for _,qdd in ipairs(quadsToDraw) do
        member("layer"..tostring(d)).image:copyPixels(member("thornBushGraf").image, qdd[1], qdd[2], {color=colr, ink=36} )
        spelrelaterat.copyPixelsToEffectColor(gdLayer, d, qdd[1], "thornBushGrad", qdd[2], 0.5, qdd[3])
      end
    end
    
    -- copyPixelsToEffectColor(gdLayer, d, rect(headPos.x-37, headPos.y-37, headPos.x+37, h+10), "hugeFlowerMaskMask", member("hugeFlowerMask").image.rect, 0.8)
    
  end
end

function me.ApplyGarbageSpiral (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local frontWall = 1
  local backWall = 29
  
  local d

  if lrSup == "All" then
    d = random(29)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "1" then
    d = random(9)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(19)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(29)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  end

  local lr = 1+(d>9)+(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local dir = random(360)
    local dirAdd = 40+random(20)
    
    if(random(2)==1)then
      dirAdd = -dirAdd
    end
    
    local grav = -0.7
    
    local spiralWait = 15 + random(15)
    local spiral = 1.0
    local searchBase = -8--12
    
    local loseSpiralTime = 60 + random(300)
    
    local spiralFac = fiffigt.lerp(0.95, 0.91, (gEEprops.effects[r].mtrx[q2][c2]/100.0) * (random(1000)/1000.0))
    
    local dpthSpeed = fiffigt.lerp(-1.0, 1.0, random(1000)/1000.0)/20.0
    
    local conPoints = {{pnt, d, 0}}
    local points = {{pnt, d, 1}}
    
    local cntr = 0

    while pnt.y < 30000 do
      cntr = cntr + 1
      dir = dir + dirAdd
      
      dirAdd = dirAdd * spiralFac
      spiralFac = spiralFac + 0.0013
      
      if(spiralFac > 0.993)then
        spiralFac = 0.993
      end
      
      local lastPnt = pnt
      pnt = pnt + fiffigt.degToVec(dir)*3.0*(spiral ^ 0.5)
      
      spiralWait = spiralWait - 1
      if(spiralWait < 0)then
        local moveDir = point(0,0)
        for dst = 1, 7 do
          for _,tst in ipairs({point(-1,0), point(1,0), point(1,1), point(0,1), point(-1, 1)}) do
            local tstPnt = spelrelaterat.giveGridPos(lastPnt) + gRenderCameraTilePos + tst*dst
            if(tstPnt.x > 0)and(tstPnt.x < gLOprops.size.x-1)and(tstPnt.y > 0)and(tstPnt.y < gLOprops.size.y-1)then
              moveDir = moveDir + (tst*gEEprops.effects[r].mtrx[tstPnt.x][tstPnt.y])
            end
          end
        end
        pnt = pnt + (moveDir/4600.0)*searchBase*(1.0-(spiral ^ 0.5))
        searchBase = searchBase + 0.15
        if(searchBase > 12)then
          searchBase = 12
        end
        
        
        pnt.y = pnt.y + grav * (1.0-(spiral ^ 0.5))
        grav = grav + 0.2 * (1.0-(spiral ^ 0.5))--(abs(grav) + 0.8) * 0.009 * (1.0-power(spiral, 0.5))
        
        
        spiral = spiral - (1.0/loseSpiralTime)
        if(spiral < 0)then
          spiral = 0
          d = d + dpthSpeed
          if(d < frontWall)then
            d = frontWall
          elseif (d > backWall) then
            d = backWall
          end
          
        end
      end
      
      if(random(1000) < (spiral ^ 4.0)*1000)then
        conPoints:add({pnt, d, cntr})
      end
      
      pnt = lastPnt + fiffigt.moveToPoint(lastPnt, pnt, 3.0)
      
      points:add({pnt, d, spiral})
      
      local tlPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      if tobool(skyRootsFix) and (not tobool(spelrelaterat.withinBoundsOfLevel(tlPos))) then
        return
      end
      
      if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
        break
      elseif spelrelaterat.solidAfaMv(tlPos, lr) == 1 then
        break
      end
      
    end
    
    for cntr = 1, #conPoints do
      local a = conPoints[random(#conPoints)][1]
      local blnd = (1.0-(spelrelaterat.restrict(conPoints[cntr][3] / #points, 0, 1) ^ 1.3))
      local useD = spelrelaterat.restrict(toint(conPoints[cntr][2]), frontWall, backWall)
      if(random(10)==1)then
        local qd = rect(a.x, a.y, a.x+1, a.y+random(random(100)))
        member("layer"..tostring(points[1][2])).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr, ink=36} )
        spelrelaterat.copyPixelsToEffectColor(gdLayer, useD, qd, "pxl", rect(0,0,1,1), 0.5, blnd)
      else
        local b = conPoints[random(#conPoints)][1]
        local dir = fiffigt.moveToPoint(a, b, 1.0)
        local perp = spelrelaterat.giveDirFor90degrToLine(-dir, dir)*0.5
        local qd = quad(a - perp, a + perp, b + perp, b-perp)
        member("layer"..tostring(points[1][2])).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr, ink=36} )
        spelrelaterat.copyPixelsToEffectColor(gdLayer, useD, qd, "pxl", rect(0,0,1,1), 0.5, blnd)
      end
    end
    
    local lastPnt = points[1][1]
    local lastUseD = points[1][2]
    for q = 1, #points do
      local pnt = points[q][1]
      local rct = (lastPnt + pnt)/2.0
      rct = rect(rct, rct)
      rct = rct + rect(-1, -2, 1, 2)
      local qd = rotate(rct, fiffigt.lookAtPoint(lastPnt, pnt))
      
      local useD = spelrelaterat.restrict(toint(points[q][2]), frontWall, backWall)
      local blnd = 1.0-(spelrelaterat.restrict(q / #points, 0, 1) ^ 1.3)
      local blnd = fiffigt.lerp(blnd, 0.5, points[q][3])
      member("layer"..tostring(useD)).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr, ink=36} )
      spelrelaterat.copyPixelsToEffectColor(gdLayer, useD, qd, "pxl", rect(0,0,1,1), 0.5, blnd)
      
      if(lastUseD ~= useD)then
        member("layer"..tostring(lastUseD)).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr, ink=36} )
        spelrelaterat.copyPixelsToEffectColor(gdLayer, lastUseD, qd, "pxl", rect(0,0,1,1), 0.5, blnd)
      end
      
      lastUseD = useD
      lastPnt = pnt
    end
    
    -- copyPixelsToEffectColor(gdLayer, d, rect(headPos.x-37, headPos.y-37, headPos.x+37, h+10), "hugeFlowerMaskMask", member("hugeFlowerMask").image.rect, 0.8)
    
  end
end

function me.ApplyRoller (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local frontWall = 1
  local backWall = 29

  local d

  if lrSup == "All" then
    d = random(29)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "1" then
    d = random(9)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(19)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(29)
    if(d <= 5)then
      backWall = 5
    elseif (d >= 6)then
      frontWall = 6
    end
  end
  
  local lr = 1+(d>9)+(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local dir = random(360)
    local dirAdd = (10+random(30))*0.3
    if(random(2)==1)then
      dirAdd = -dirAdd
    end
    
    local dspeed = (-11+random(21))/100.0
    
    local lastUseD = d
    
    local grav = 0.7
    
    local points = list({{pnt, d}})
    
    local seedChance = 1.0
    
    local quadsToDraw = list()
    
    while pnt.y < 30000 do
      dir = dir - 11 + random(21) + dirAdd
      
      dspeed = spelrelaterat.restrict(dspeed + (-11+random(21))/1000.0, -0.1, 0.1)
      
      d = d + dspeed
      
      if(d < frontWall)then
        d = frontWall
        dspeed = random(10)/100.0
      elseif (d > backWall)then
        d = backWall
        dspeed = -random(10)/100.0
      end
      
      local lastPnt = pnt
      pnt = pnt + fiffigt.degToVec(dir)*5.0
      pnt.y = pnt.y + grav
      
      grav = grav + 0.001
      
      
      
      local rct = (lastPnt + pnt)/2.0
      rct = rect(rct, rct)
      rct = rct + rect(-1.5, -3.5, 1.5, 3.5)
      local qd = rotate(rct, fiffigt.lookAtPoint(lastPnt, pnt))
      --      if(random(2)=1)then
      --        qd = flipQuadH(qd)
      --      end
      
      
      --  var = random(13)
      
      local useD = spelrelaterat.restrict(toint(d), frontWall, backWall)
      
      if(seedChance > 0)then
        for a = 1, 8 do
          if (random(1000) < (seedChance ^ 1.5)*1000)then
            local seedPos = pnt + fiffigt.moveToPoint(pnt, lastPnt, (fiffigt.diag(pnt, lastPnt)*random(1000))/1000.0) + fiffigt.degToVec(random(360))*random(3)
            local seedLr = spelrelaterat.restrict(useD - 2 + random(3), frontWall, backWall)
            
            if tobool(skyRootsFix) then
              local quadTryAdd = {0, seedLr, rect(seedPos,seedPos), -1}
              
              if (random(3) > 1) then
                seedLr = spelrelaterat.restrict(seedLr - 1, frontWall, backWall)
                quadTryAdd[4] = seedLr
              end
              
              quadsToDraw:add(quadTryAdd)
            else
              member("layer"..tostring(seedLr)).image:copyPixels(member("rustDot").image, rect(seedPos,seedPos)+rect(-2, -2, 2, 2), member("rustDot").image.rect, {color=colr, ink=36} )
              spelrelaterat.copyPixelsToEffectColor(gdLayer, seedLr, rect(seedPos,seedPos)+rect(-2, -2, 2, 2), "rustDot", member("rustDot").image.rect, 0.8, 1)
              
              if(random(3) > 1)then
                seedLr = spelrelaterat.restrict(seedLr - 1, frontWall, backWall)
                member("layer"..tostring(seedLr)).image:copyPixels(member("pxl").image, rect(seedPos,seedPos)+rect(-1, -1, 1, 1), member("pxl").image.rect, {color=colr} )
                spelrelaterat.copyPixelsToEffectColor(gdLayer, seedLr, rect(seedPos,seedPos)+rect(-1, -1, 1, 1), "pxl", member("pxl").image.rect, 0.8, 1)
              else
                member("layer"..tostring(seedLr)).image:copyPixels(member("pxl").image, rect(seedPos,seedPos)+rect(-1, -1, 1, 1), member("pxl").image.rect, {color=color(255, 0, 0)} )
              end
            end
          end
        end
      end
      
      seedChance = seedChance - (random(100)/2200.0)
      
      points:add({pnt, useD})
      
      
      
      if tobool(skyRootsFix) then
        quadsToDraw:add({1, useD, qd})
      else
        member("layer"..tostring(useD)).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr} )
      end
      
      if(lastUseD ~= useD)then
        if tobool(skyRootsFix) then
          quadsToDraw:add({1, lastUseD, qd})
        else
          member("layer"..tostring(lastUseD)).image:copyPixels(member("pxl").image, qd, rect(0,0,1,1), {color=colr} )
        end
      end
      
      lastUseD = useD
      
      local tlPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      if tobool(skyRootsFix) and (not tobool(spelrelaterat.withinBoundsOfLevel(tlPos))) then
        return
      end
      
      if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
        break
      elseif spelrelaterat.solidAfaMv(tlPos, 1 + (useD > 9) + (useD > 19)) == 1 then
        break
      end
      
    end
    
    if tobool(skyRootsFix) then
      for _,qdd in ipairs(quadsToDraw) do
        if tobool(qdd[1]) then
          member("layer"..tostring(qdd[2])).image:copyPixels(member("pxl").image, qdd[3], rect(0,0,1,1), {color=colr} )
        else
          member("layer"..tostring(qdd[2])).image:copyPixels(member("rustDot").image, qdd[3]+rect(-2, -2, 2, 2), member("rustDot").image.rect, {color=colr, ink=36} )
          spelrelaterat.copyPixelsToEffectColor(gdLayer, qdd[2], qdd[3]+rect(-2, -2, 2, 2), "rustDot", member("rustDot").image.rect, 0.8, 1)
          
          if(qdd[4] >= 0)then
            member("layer"..tostring(qdd[4])).image:copyPixels(member("pxl").image, qdd[3]+rect(-1, -1, 1, 1), member("pxl").image.rect, {color=colr} )
            spelrelaterat.copyPixelsToEffectColor(gdLayer, qdd[4], qdd[3]+rect(-1, -1, 1, 1), "pxl", member("pxl").image.rect, 0.8, 1)
          else
            member("layer"..tostring(qdd[2])).image:copyPixels(member("pxl").image, qdd[3]+rect(-1, -1, 1, 1), member("pxl").image.rect, {color=color(255, 0, 0)} )
          end
        end
      end
    end
    
    if(#points > 2)then
      for p = 1, #points -1 do
        local rct = (points[p][1] + points[p+1][1])/2.0
        rct = rect(rct, rct)
        rct = rct + rect(-1.5, -3.5, 1.5, 3.5)
        local qd = rotate(rct, fiffigt.lookAtPoint(points[p][1], points[p+1][1]))
        --  copyPixelsToEffectColor(gdLayer, useD, qd, "pxl", rect(0,0,1,1), 0.8)
        spelrelaterat.copyPixelsToEffectColor(gdLayer, points[p][2], qd, "pxl", rect(0,0,1,1), 0.8, (((#points-p+1)/#points) ^ 1.5))
      end
    end
  end
end

function me.applyHangRoots (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local d

  if lrSup == "All" then
    d = random(30)-1
  elseif lrSup == "1" then
    d = random(10)-1
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20)-1
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(30)-1
  end

  local lr = 1+(d>9)+(d>19)
  
  if (gLEProps.matrix[q2][c2][lr][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    -- member("layer"..tostring(d)).image:copyPixels(member("flowerhead").image, rect(pnt.x-3, pnt.y-3, pnt.x+3, mdPnt.y+3), member("flowerhead").image.rect, {color=colr, ink=36})
    local lftBorder = mdPnt.x-10
    local rgthBorder =  mdPnt.x+10
    
    local quadsToDraw = list()
    
    while pnt.y+gRenderCameraTilePos.y*20 > -100 do
      
      -- member("layer"..tostring(d)).image:copyPixels(member("pxl").image, rect(pnt.x-1, h, pnt.x+2, h+2), member("pxl").image.rect, {color=colr})
      local lstPos = pnt
      pnt = pnt + fiffigt.degToVec(-45+random(90))*(2+random(6))
      pnt.x = spelrelaterat.restrict(pnt.x, lftBorder, rgthBorder)
      local dir = fiffigt.moveToPoint(pnt, lstPos, 1.0)
      local crossDir = spelrelaterat.giveDirFor90degrToLine(-dir, dir)
      local qd = quad(pnt-crossDir, pnt+crossDir, lstPos+crossDir, lstPos-crossDir)
      
      if tobool(skyRootsFix) then
        quadsToDraw.add(qd)
      else
        member("layer"..tostring(d)).image:copyPixels(member("pxl").image, qd, member("pxl").image.rect, {color=color(255, 0, 0)})
      end
      
      if spelrelaterat.solidAfaMv(spelrelaterat.giveGridPos(lstPos) + gRenderCameraTilePos, lr) == 1 then
        break
      end
      
      if tobool(skyRootsFix) and (spelrelaterat.withinBoundsOfLevel(spelrelaterat.giveGridPos(lstPos) + gRenderCameraTilePos) == 0) then
        return
      end
      
    end
    
    if tobool(skyRootsFix) then
      for _,qdd in ipairs(quadsToDraw) do
        member("layer"..tostring(d)).image:copyPixels(member("pxl").image, qdd, member("pxl").image.rect, {color=color(255, 0, 0)})
      end
    end
  end
end

function me.applyThickRoots (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local frontWall = 0
  local backWall = 29
  
  local d

  if lrSup == "All" then
    d = random(30)-1
  elseif lrSup == "1" then
    d = random(10)-1
    backWall = 9
  elseif lrSup == "2" then
    d = random(10)-1 + 10
    frontWall = 10
    backWall = 19
  elseif lrSup == "3" then
    d = random(10)-1 + 20
    frontWall = 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20)-1
    backWall = 19
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
    frontWall = 10
  else
    d = random(30)-1
  end

  if(d > 5)then
    frontWall = 5+3
    d = spelrelaterat.restrict(d, frontWall, 29)
  else
    backWall = 5
  end
  
  if (gLEProps.matrix[q2][c2][(1+(d>9)+(d>19))][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local health = 6
    local points = list({{pnt, d, health}})
    
    local dir = 0
    
    local floatDpth = d
    
    local thickness = (gEEprops.effects[r].mtrx[q2][c2]/100.0)*((random(10000)/10000.0) ^ 0.3)
    
    while pnt.y+gRenderCameraTilePos.y*20 > -100 do
      
      floatDpth = floatDpth + fiffigt.lerp(-0.3, 0.3, random(1000)/1000.0)
      if(floatDpth < frontWall)then
        floatDpth = frontWall
      elseif(floatDpth > backWall)then
        floatDpth = backWall
      end
      d = spelrelaterat.restrict(toint(floatDpth), frontWall, backWall)
      
      local lstPos = pnt
      dir = fiffigt.lerp(dir, -45+random(90), 0.5)
      pnt = pnt + fiffigt.degToVec(dir)*(2+random(6))
      
      local lstGridPos = spelrelaterat.giveGridPos(lstPos) + gRenderCameraTilePos
      local gridPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      
      local tlt = 0
      for q = -1, 1 do
        if (q~=0)and (gridPos.x + q > 0)and(gridPos.x + q < #gEEprops.effects[r].mtrx)and(gridPos.y-1 > 0)and(gridPos.y-1 < #gEEprops.effects[r].mtrx[1]) and (lstGridPos.x + q > 0)and(lstGridPos.x + q < #gEEprops.effects[r].mtrx)and(lstGridPos.y-1 > 0)and(lstGridPos.y-1 < #gEEprops.effects[r].mtrx[1])then
          tlt = tlt + gEEprops.effects[r].mtrx[lstGridPos.x+q][lstGridPos.y-1]*q
        end
      end
      pnt.x = pnt.x + (tlt/100.0)*2.0
      gridPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      
      if(lstGridPos.x ~= gridPos.x) then
        if (gridPos.x > 0)and(gridPos.x < #gEEprops.effects[r].mtrx)and(gridPos.y > 0)and(gridPos.y < #gEEprops.effects[r].mtrx[1]) and (lstGridPos.x > 0)and(lstGridPos.x < #gEEprops.effects[r].mtrx)and(lstGridPos.y > 0)and(lstGridPos.y < #gEEprops.effects[r].mtrx[1]) then
          if (gEEprops.effects[r].mtrx[gridPos.x][gridPos.y] == 0)and(gEEprops.effects[r].mtrx[lstGridPos.x][lstGridPos.y] > 0) then
            pnt.x = spelrelaterat.restrict(pnt.x, spelrelaterat.giveMiddleOfTile(spelrelaterat.giveGridPos(lstPos)).x-9, spelrelaterat.giveMiddleOfTile(spelrelaterat.giveGridPos(lstPos)).x+9)
          end
        end
      end
      
      
      points:add({pnt, d, health})
      
      if spelrelaterat.solidAfaMv(lstGridPos, (1+(d>9)+(d>19))) == 1 then
        health = health - 1
        if(health < 1) then
          break
        end
      else
        health = spelrelaterat.restrict(health+1, 0, 6)
      end
      
      if tobool(skyRootsFix) and (spelrelaterat.withinBoundsOfLevel(lstGridPos) == 0) then
        return
      end
    end
    
    local lstPos = points[1][1] + point(0,1)
    local lastRad = 0
    local lastPerp = point(0,0)
    
    for q = 1, #points do
      local f = q / #points
      local pnt = points[q][1]
      local d = points[q][2]
      local dir = fiffigt.moveToPoint(pnt, lstPos, 1.0)
      local perp = spelrelaterat.giveDirFor90degrToLine(-dir, dir)
      local rad = 0.6 + f*8.0*(points[q][3]/6.0)*fiffigt.lerp(0.8, 1.2, random(1000)/1000.0)*fiffigt.lerp(thickness, 0.5, 0.2)
      
      for _,c in ipairs({{0, 1.0}, {1, 0.7}, {2, 0.3}}) do
        if(d - c[1] >= 0)and((rad*c[2] > 0.8)or(c[1]==0))then
          local qd = quad(pnt-perp*rad*c[2], pnt+perp*rad*c[2], lstPos+dir+lastPerp*lastRad*c[2], lstPos+dir-lastPerp*lastRad*c[2])
          member("layer"..tostring(d - c[1])).image:copyPixels(member("pxl").image, qd, member("pxl").image.rect, {color=color(0,255,0)})
        end
      end
      
      lstPos = pnt
      lastPerp = perp
      lastRad = rad
    end
  end
end

function me.applyShadowPlants (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local frontWall = 0
  local backWall = 29
  
  local d

  if lrSup == "All" then
    d = random(30)-1
  elseif lrSup == "1" then
    d = random(10)-1
    backWall = 9
  elseif lrSup == "2" then
    d = random(10)-1 + 10
    frontWall = 10
    backWall = 19
  elseif lrSup == "3" then
    d = random(10)-1 + 20
    frontWall = 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20)-1
    backWall = 19
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
    frontWall = 10
  else
    d = random(30)-1
  end

  if(d > 5)then
    frontWall = 5+3
    d = spelrelaterat.restrict(d, frontWall, 29)
  else
    backWall = 5
  end
  
  if (gLEProps.matrix[q2][c2][(1+(d>9)+(d>19))][1]==0)then--and(afaMvLvlEdit(point(q,c+1), 1)=1) then
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local headPos = mdPnt+point(-11+random(21), -11+random(21))
    local pnt = point(headPos.x, headPos.y)
    
    local health = 6
    local points = list({{pnt, d, health}})
    
    local dir = 180
    
    -- floatDpth = d
    
    local cycle = fiffigt.lerp(6.0, 12.0, random(10000)/10000.0)
    local cntr = random(50)
    
    local tltFac = 0.0
    
    while pnt.y+gRenderCameraTilePos.y*20 > -100 do
      cntr = cntr + 1
      --      floatDpth = floatDpth + lerp(-0.3, 0.3, random(1000)/1000.0)
      --      if(floatDpth < frontWall)then
      --        floatDpth = frontWall
      --      elseif(floatDpth > backWall)then
      --        floatDpth = backWall
      --      end
      --      d = restrict(floatDpth.integer, frontWall, backWall)
      
      local lstPos = pnt
      dir = fiffigt.lerp(dir, 180-45+random(90), 0.1)
      dir = dir + math.sin((cntr/cycle)*math.pi*2.0)*8
      cycle = cycle + 0.1
      if(cycle > 35) then cycle = 35 end
      pnt = pnt + fiffigt.degToVec(dir)*3
      
      local lstGridPos = spelrelaterat.giveGridPos(lstPos) + gRenderCameraTilePos
      local gridPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      
      local tlt = 0
      for q = -1, 1 do
        if (q~=0)and (lstGridPos.x + q > 0)and(lstGridPos.x + q < #gEEprops.effects[r].mtrx)and(lstGridPos.y+1 > 0)and(lstGridPos.y+1 < #gEEprops.effects[r].mtrx[1]) then
          tlt = tlt + gEEprops.effects[r].mtrx[lstGridPos.x+q][lstGridPos.y+1]*q
        end
      end
      
      pnt.x = pnt.x + (tlt/100.0)*fiffigt.lerp(-2.0, 1.0, (tltFac ^ 0.85))
      gridPos = spelrelaterat.giveGridPos(pnt) + gRenderCameraTilePos
      
      tltFac = tltFac + 0.002
      if(tltFac > 1.0)then tltFac = 1.0 end
      --      
      --      
      --      if(lstGridPos.x ~= gridPos.x) then
      --        if (gridPos.x > 0)and(gridPos.x < gEEprops.effects[r].mtrx.count)and(gridPos.y > 0)and(gridPos.y < gEEprops.effects[r].mtrx[1].count) then
      --          if (lstGridPos.x  > 0)and(lstGridPos.x < gEEprops.effects[r].mtrx.count)and(lstGridPos.y > 0)and(lstGridPos.y < gEEprops.effects[r].mtrx[1].count) then
      --            if (gEEprops.effects[r].mtrx[gridPos.x][gridPos.y] = 0)and(gEEprops.effects[r].mtrx[lstGridPos.x][lstGridPos.y] > 0) then
      --              pnt.x = restrict(pnt.x, spelrelaterat.giveMiddleOfTile(spelrelaterat.giveGridPos(lstPos)).x-9, spelrelaterat.giveMiddleOfTile(spelrelaterat.giveGridPos(lstPos)).x+9)
      --            end
      --          end
      --        end
      --      end
      
      
      points:add({pnt, d, health})
      
      if spelrelaterat.solidAfaMv(lstGridPos, (1+(d>9)+(d>19))) == 1 then
        health = health - 1
        if(health < 1) then
          break
        end
      else
        health = spelrelaterat.restrict(health+1, 0, 6)
      end
      
      if tobool(skyRootsFix) and (spelrelaterat.withinBoundsOfLevel(lstGridPos) == 0) then
        return
      end
    end
    
    local fuzzLength = 20+random(50)
    
    local thickness = (gEEprops.effects[r].mtrx[q2][c2]/100.0)*((random(10000)/10000.0) ^ 0.3)
    thickness = fiffigt.lerp(thickness, spelrelaterat.restrict(#points, 20.0, 180.0)/180.0, 0.5)
    
    local lstPos = points[1][1] + point(0,1)
    local lastRad = 0
    local lastPerp = point(0,0)
    
    for q = 1, #points do
      local f = q / #points
      local pnt = points[q][1]
      local d = points[q][2]
      local dir = fiffigt.moveToPoint(pnt, lstPos, 1.0)
      local perp = spelrelaterat.giveDirFor90degrToLine(-dir, dir)
      --rad = 0.6 + f*8.0*(points[q][3].float/6.0)*lerp(0.8, 1.2, random(1000)/1000.0)*lerp(thickness, 0.5, 0.2)
      f =  math.sin(f*math.pi*0.5)
      local rad = 1.1 + f*7.0*(points[q][3]/6.0)*fiffigt.lerp(thickness, 0.5, 0.2)
      
      for _,c in ipairs({{0, 1.0}, {1, 0.7}, {2, 0.3}}) do
        if(d - c[1] >= 0)and((rad*c[2] > 0.8)or(c[1]==0))then
          local qd = quad(pnt-perp*rad*c[2], pnt+perp*rad*c[2], lstPos+dir+lastPerp*lastRad*c[2], lstPos+dir-lastPerp*lastRad*c[2])
          member("layer"..tostring(d - c[1])).image:copyPixels(member("pxl").image, qd, member("pxl").image.rect, {color=color(0,0,255)})
          
          if(random(30) == 1)then
            me.sporeGrower(pnt + fiffigt.moveToPoint(pnt, lstPos, fiffigt.diag(pnt, lstPos)*random(10000)/10000.0), 15 + random(50) * (1.0-f), d - c[1], color(0,0,255))
          end
          
          if(q < fuzzLength) and(random(fuzzLength) > q)and(random(6)==1) then
            local f2 = q / fuzzLength
            me.sporeGrower(pnt + fiffigt.moveToPoint(pnt, lstPos, fiffigt.diag(pnt, lstPos)*random(10000)/10000.0), 65 + random(50) * (1.0-f2), d - c[1], color(0,0,255))
          end
        end
      end
      
      lstPos = pnt
      lastPerp = perp
      lastRad = rad
    end
  end
end

function me.sporeGrower (pos, lngth, layer, col)
  local dir = point(0, -1)
  
  for q = 1, lngth do
    local otherCol = member("layer"..layer).image:getPixel(pos.x-1, pos.y-1)
    if(otherCol ~= col)and(otherCol ~= color(255, 255, 255))then
      break
    else
      member("layer"..layer).image:setPixel(pos.x-1, pos.y-1, col)
      pos = pos + dir
      
      if(dir.y == -1)and(random(2)==1)then
        if(random(2)==1)then
          dir = point(-1, 0)
        else
          dir = point(1, 0)
        end
      else 
        dir = point(0, -1)
      end
    end
  end
end

function me.applyDaddyCorruption (q, c, amount)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
  -- global daddyCorruptionHoles
  
  local extraHoleChance = 1

  local dmin
  local dmax
  local dmax2
  
  if lrSup == "All" then
    dmin = 0
    dmax = 29
    dmax2 = 26
  elseif lrSup == "1" then
    dmin = 0
    dmax = 6
    dmax2 = 6
  elseif lrSup == "2" then
    dmin = 10
    dmax = 16
    dmax2 = 16
  elseif lrSup == "3" then
    dmin = 20
    dmax = 29
    dmax2 = 26
  elseif lrSup == "1:st and 2:nd" then
    dmin = 0
    dmax = 16
    dmax2 = 16
  elseif lrSup == "2:nd and 3:rd" then
    dmin = 10
    dmax = 29
    dmax2 = 26
  else
    dmin = 0
    dmax = 29
    dmax2 = 26
  end

  for a = 1, amount/2 do
    local dp = random(28)-1
    
    if(dp > 3)then
      dp = dp + 2
    end
    
    local lr = 3
    local rad = random(100)*0.2*fiffigt.lerp(0.2, 1.0, amount/100)
    
    if(dp < 10)then
      lr = 1
    elseif (dp < 20) then
      lr = 2
    end
    
    local startPos = mdPnt+point(-11+random(21), -11+random(21))
    
    local solid = 0
    
    if(spelrelaterat.solidAfaMv(point(q2,c2), lr) == 1)then
      solid = 1
    end
    
    if(solid == 0)and(lr < 3)and(dp - (lr-1)*10 > 6)then
      if(spelrelaterat.solidAfaMv(point(q2,c2), lr+1) == 1)then
        solid = 1
      end
    end
    
    if(solid == 0)then
      for _,dr in ipairs({point(-1,0), point(0,-1), point(0,1), point(1,0)}) do
        if(spelrelaterat.solidAfaMv(spelrelaterat.giveGridPos(startPos + dr*rad)+gRenderCameraTilePos, lr) == 1)then
          solid = 1
          break
        end
      end
    end
    
    if(solid == 0)and(dp < 27)and(rad > 1.2)then
      for _,dr in ipairs({point(0,0), point(-1,0), point(0,-1), point(0,1), point(1,0)}) do
        if( member("layer"..tostring(dp+2)).image:getPixel(startPos.x + dr.x*rad*0.5, startPos.y + dr.y*rad*0.5) ~= color(255, 255, 255))then --compare it to -1 here, not to white
          rad = rad / 2
          solid = 1
          break
        end
      end
    end
    
    if(solid == 1)then
      for d = 0, 2 do
        if(dp+d <= dmax) and (dp+d >= dmin) then
          if(rad <= 10)then
            member("layer"..tostring(dp+d)).image:copyPixels(member("DaddyBulb").image, rect(startPos, startPos)+rect(-rad,-rad,rad,rad), rect(0, 1+d*20, 20, 1+(d+1)*20), {ink=36})
          else
            member("layer"..tostring(dp+d)).image:copyPixels(member("DaddyBulb").image, rect(startPos, startPos)+rect(-rad,-rad,rad,rad), rect(20, 1+d*40, 60, 1+(d+1)*40), {ink=36})
          end
        else
          break
        end
      end
      
      if((random(3) == 1)or(extraHoleChance==1))and(dp <= dmax2) and (dp >= dmin)then
        daddyCorruptionHoles:add({startPos, rad * (50+random(50))*0.01, random(360), dp, amount})
        extraHoleChance = 0
      end
    end
  end  
end

function me.applyCorruptionNoEye (q, c, amount)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
  
  local dmin
  local dmax

  if lrSup == "All" then
    dmin = 0
    dmax = 29
  elseif lrSup == "1" then
    dmin = 0
    dmax = 6
  elseif lrSup == "2" then
    dmin = 10
    dmax = 16
  elseif lrSup == "3" then
    dmin = 20
    dmax = 29
  elseif lrSup == "1:st and 2:nd" then
    dmin = 0
    dmax = 16
  elseif lrSup == "2:nd and 3:rd" then
    dmin = 10
    dmax = 29
  else
    dmin = 0
    dmax = 29
  end

  for a = 1, amount/2 do
    local dp = random(28)-1
    
    if(dp > 3)then
      dp = dp + 2
    end
    
    local lr = 3
    local rad = random(100)*0.2*fiffigt.lerp(0.2, 1.0, amount/100)
    
    if(dp < 10)then
      lr = 1
    elseif (dp < 20) then
      lr = 2
    end
    
    local startPos = mdPnt+point(-11+random(21), -11+random(21))
    
    local solid = 0
    
    if(spelrelaterat.solidAfaMv(point(q2,c2), lr) == 1)then
      solid = 1
    end
    
    if(solid == 0)and(lr < 3)and(dp - (lr-1)*10 > 6)then
      if(spelrelaterat.solidAfaMv(point(q2,c2), lr+1) == 1)then
        solid = 1
      end
    end
    
    if(solid == 0)then
      for _,dr in ipairs({point(-1,0), point(0,-1), point(0,1), point(1,0)}) do
        if(spelrelaterat.solidAfaMv(spelrelaterat.giveGridPos(startPos + dr*rad)+gRenderCameraTilePos, lr) == 1)then
          solid = 1
          break
        end
      end
    end
    
    if(solid == 0)and(dp < 27)and(rad > 1.2)then
      for _,dr in ipairs({point(0,0), point(-1,0), point(0,-1), point(0,1), point(1,0)}) do
        if( member("layer"..tostring(dp+2)).image:getPixel(startPos.x + dr.x*rad*0.5, startPos.y + dr.y*rad*0.5) ~= -1)then --compare it to -1 here, not to white
          rad = rad / 2
          solid = 1
          break
        end
      end
    end
    
    if(solid == 1)then
      for d = 0, 2 do
        if(dp+d <= dmax) and (dp+d >= dmin) then
          if(rad <= 10)then
            member("layer"..tostring(dp+d)).image:copyPixels(member("CNEBulb").image, rect(startPos, startPos)+rect(-rad,-rad,rad,rad), rect(0, 1+d*20, 20, 1+(d+1)*20), {ink=36})
          else
            member("layer"..tostring(dp+d)).image:copyPixels(member("CNEBulb").image, rect(startPos, startPos)+rect(-rad,-rad,rad,rad), rect(20, 1+d*40, 60, 1+(d+1)*40), {ink=36})
          end
        else
          break
        end
      end
    end
  end
end

function me.applyWire(q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y

  -- global gCurrentRenderCamera
  
  local d
  
  if lrSup == "All" then
    d = random(30) - 1
  elseif lrSup == "1" then
    d = random(10) - 1
  elseif lrSup == "2" then
    d = random(10) - 1 + 10
  elseif lrSup == "3" then
    d = random(10) - 1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20) - 1
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20) - 1 + 10
  else
    d = random(30) - 1
  end

  local lr = 1 + toint(d > 9) + toint(d > 19)
  
  if (gLEProps.matrix[q2][c2][lr][1] == 0) then
    local layerd = member("layer" .. tostring(d)).buf
    member("wireImage").buf = imagebuf(layerd.width, layerd.height)
    local wireImg = member("wireImage").image
    
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q, c))
    local startPos = mdPnt+point(-11 + random(21), -11 + random(21))
    local myCamera = me.closestCamera(startPos + gRenderCameraTilePos * 20)
    
    if (myCamera == 0) then
      return
    end
    
    local fatness = 1

    if fatOp == "2px" then
      fatness = 2
    elseif fatOp == "3px" then
      fatness = 3
    elseif fatOp == "random" then
      fatness = random(3)
    end
    
    local a = 1.0 + random(100) + random(random(random(900)))
    local keepItFromToForty = random(30)
    a = ((a * keepItFromToForty) + 40.0) / (keepItFromToForty + 1.0)
    local addNRct = rect(-toint(fatness > 1), -toint(fatness > 1), toint(fatness == 3), toint(fatness == 3))
    wireImg:copyPixels(DRPxl, rect(startPos.x, startPos.y - 1, startPos.x + 1, startPos.y + 1) + addNRct, rect(0, 0, 1, 1), {color=color(0, 0, 0)})
    local goodStops = 0
    
    for dir = 0, 1 do
      local pnt = point(startPos.x, startPos.y)
      local lastPnt = point(startPos.x, startPos.y)
      for rep = 1, 1000 do
        pnt.x = startPos.x + (-1 + 2 * dir) * rep
        pnt.y = startPos.y + a - ((2.71828183 ^ (rep / a)) + (2.71828183 ^ (-rep / a))) * (a / 2.0)
        
        local dr = fiffigt.moveToPoint(lastPnt, pnt, fatness)
        
        wireImg:copyPixels(DRPxl, rect(pnt.x, pnt.y, pnt.x + 1, lastPnt.y + 1) + addNRct, rect(0, 0, 1, 1), {color=color(0, 0, 0)})
        lastPnt = point(pnt.x, pnt.y)
        
        local tlPos = spelrelaterat.giveGridPos(point(pnt.x, pnt.y)) + gRenderCameraTilePos
        
        if (not tlPos:inside(rect(1, 1, gLOprops.size.x + 1, gLOprops.size.y + 1))) then
          break
        else 
          if(myCamera == gCurrentRenderCamera)and(me.seenByCamera(myCamera, pnt + gRenderCameraTilePos)==1) then
            if (gLEProps.matrix[tlPos.x][tlPos.y][lr][1] == 1) then
              if (layerd:getPixel(pnt) ~= DRWhite) then
                goodStops = goodStops + 1
                break
              end
            end
          else
            if (spelrelaterat.solidAfaMv(tlPos, lr)) then
              goodStops = goodStops + 1
              break
            end
          end
        end
      end
    end

    if (goodStops == 2) then
      layerd:copyPixels(wireImg, wireImg.rect, wireImg.rect, {color=color(255, 0, 0), ink=36})
    end
  end
end

function me.applyChain (q, c, eftc)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  -- global gCurrentRenderCamera
  
  local d

  if lrSup == "All" then
    d = random(30)-1
  elseif lrSup == "1" then
    d = random(10)-1
  elseif lrSup == "2" then
    d = random(10)-1 + 10
  elseif lrSup == "3" then
    d = random(10)-1 + 20
  elseif lrSup == "1:st and 2:nd" then
    d = random(20)-1
  elseif lrSup == "2:nd and 3:rd" then
    d = random(20)-1 + 10
  else
    d = random(30)-1
  end
  
  local lr = 1+(d>9)+(d>19)
  
  local big = 0
  
  if chOp == "FAT" then
    big = 1
  end
  
  --repeat with lmao = 0 to 100 then
  if (gLEProps.matrix[q2][c2][lr][1]==0)then
    member("wireImage").image = image(member("layer"..tostring(d)).image.width, member("layer"..tostring(d)).image.height)
    local mdPnt = spelrelaterat.giveMiddleOfTile(point(q,c))
    local startPos = mdPnt+point(-11+random(21), -11+random(21))
    
    local myCamera = me.closestCamera(startPos+gRenderCameraTilePos*20)
    if(myCamera == 0)then
      return
    end

    local a = 1.0+random(100)+random(random(random(900)))
    local keepItFromToForty = random(30)
    a = ((a*keepItFromToForty)+40.0)/(keepItFromToForty+1.0)
    
    if big then
      a = a + 10
    end
    
    local origOrnt = random(2)-1
    
    local goodStops = 0

    local ornt
    
    for dir = 0, 1 do
      local pnt = point(startPos.x, startPos.y)
      local lastPnt = point(startPos.x, startPos.y)
      
      if dir == 0 then
        ornt = origOrnt
      else
        ornt = 1-origOrnt
      end
      
      for rep = 1, 4000 do
        local checkterrain = 0
        
        pnt.x = startPos.x +(-1 + 2*dir)*rep*0.25
        pnt.y = startPos.y + a - ((2.71828183 ^ ((rep*0.25)/a))+(2.71828183 ^ (-(rep*0.25)/a)))*(a/2.0)
        
        local pos
        local rct
        local gtRect

        if big == 0 then
          if fiffigt.diag(pnt, lastPnt)>=7 then
            if ornt then
              pos = (pnt+lastPnt)*0.5
              rct = rect(pos,pos)+rect(-3,-5,3,5)
              gtRect = rect(0,0,6,10)
              ornt = 0
            else
              pos = (pnt+lastPnt)*0.5
              rct = rect(pos,pos)+rect(-1,-5,1,5)
              gtRect = rect(7,0,8,10)
              ornt = 1
            end
            member("wireImage").image:copyPixels(member("chainSegment").image, rotate(rct, fiffigt.lookAtPoint(lastPnt,pnt)), gtRect, {color=color(0,0,0), ink=36})
            lastPnt = point(pnt.x, pnt.y)
            checkterrain = 1
          end
        else
          if fiffigt.diag(pnt, lastPnt)>=12 then
            if ornt then
              pos = (pnt+lastPnt)*0.5
              rct = rect(pos,pos)+rect(-6,-10,6,10)
              gtRect = rect(0,0,12,20)
              ornt = 0
            else
              pos = (pnt+lastPnt)*0.5
              rct = rect(pos,pos)+rect(-2,-10,2,10)
              gtRect = rect(13,0,16,20)
              ornt = 1
            end
            member("wireImage").image:copyPixels(member("bigChainSegment").image, rotate(rct, fiffigt.lookAtPoint(lastPnt,pnt)), gtRect, {color=color(0,0,0), ink=36})
            lastPnt = point(pnt.x, pnt.y)
            checkterrain = 1
          end
        end
        
        if tobool(checkterrain) then
          local tlPos = spelrelaterat.giveGridPos(point(pnt.x, pnt.y)) + gRenderCameraTilePos
          if not tlPos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
            break
          else 
            if(myCamera == gCurrentRenderCamera)and(me.seenByCamera(myCamera, pnt + gRenderCameraTilePos)==1) then
              if gLEProps.matrix[tlPos.x][tlPos.y][lr][1] == 1 then
                if member("layer"..tostring(d)).buf:getPixel(pnt) ~= color(255,255,255) then
                  goodStops = goodStops + 1
                  break
                end
              end
            else
              if spelrelaterat.solidAfaMv(tlPos, lr) then
                goodStops = goodStops + 1
                break
              end
            end
          end
        end
      end
    end
    
    if goodStops == 2 then
      member("layer"..tostring(d)).buf:copyPixels(member("wireImage").image, member("wireImage").image.rect, member("wireImage").image.rect, {color=color(255, 0, 0), ink=36})
    end
  end
  --end
end

function me.applyFungiFlower (q, c)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local lr = 1
  local layer

  if lrSup == "All" then
    layer = random(3)
  elseif lrSup == "1" then
    layer = 1
  elseif lrSup == "2" then
    layer = 2
  elseif lrSup == "3" then
    layer = 3
  elseif lrSup == "1:st and 2:nd" then
    layer = random(2)
  elseif lrSup == "2:nd and 3:rd" then
    layer = random(2) + 1
  else
    layer = random(3)
  end
  
  lr = ((layer-1)*10) + random(9) - 1

  local pnt
  
  if (spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==0) then
    local rnd = 0
    local flp
    if (spelrelaterat.afaMvLvlEdit(point(q2,c2+1), layer)==1) then
      rnd = gEffectProps.list[gEffectProps.listPos]
      flp = random(2)-1
      local closestEdge = 1000
      
      for a = - 5, 5 do
        if (spelrelaterat.afaMvLvlEdit(point(q2+a,c2+1), layer)~=1) then
          if math.abs(a) <= math.abs(closestEdge) then
            flp = (a>0)
            closestEdge = a
            if a == 0 then
              flp = random(2)-1
            end
          end
        end
      end
      
      pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10+random(20), 10)
    elseif (spelrelaterat.afaMvLvlEdit(point(q2+1,c2), layer)==1) then
      rnd = 1
      flp = 0
      pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(10, -random(10))
    elseif (spelrelaterat.afaMvLvlEdit(point(q2-1,c2), layer)==1) then
      rnd = 1
      flp = 1
      pnt = spelrelaterat.giveMiddleOfTile(point(q2,c2))+point(-10, -random(10))
    end
    
    if rnd ~= 0 then
      local rct = rect(pnt, pnt) + rect(-80, -80, 80, 80)
      local gtRect = rect((rnd-1)*160, 0, rnd*160, 160)+rect(1,0,1,0)
      if tobool(flp) then
        rct = fiffigt.vertFlipRect(rct)
      end
      member("layer"..tostring(lr)).image:copyPixels(member("fungiFlowersGraf").image, rct, gtRect, {ink=36})
    end
  end
  
  gEffectProps.listPos = gEffectProps.listPos + 1
  
  if gEffectProps.listPos > #gEffectProps.list then
    local l = list({2,3,4,5})
    local l2 = list()

    for a = 1, 4 do
      local val = l[random(#l)]
      l2:add(val)
      l:deleteOne(val)
    end
    gEffectProps = {list=l2, listPos=1}
  end
end

function me.applyLHFlower (q, c)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local lr = 1
  local layer

  if lrSup == "All" then
    layer = random(3)
  elseif lrSup == "1" then
    layer = 1
  elseif lrSup == "2" then
    layer = 2
  elseif lrSup == "3" then
    layer = 3
  elseif lrSup == "1:st and 2:nd" then
    layer = random(2)
  elseif lrSup == "2:nd and 3:rd" then
    layer = random(2) + 1
  else
    layer = random(3)
  end

  lr = ((layer-1)*10) + random(9) - 1

  if (spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==0) then
    
    local rnd = gEffectProps.list[gEffectProps.listPos]
    local flp = random(2)-1
    local pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10+random(20), 10)
    
    local rct = rect(pnt, pnt) + rect(-40, -160, 40, 20)
    local gtRect = rect((rnd-1)*80, 0, rnd*80, 180)+rect(1,0,1,0)
    if tobool(flp) then
      rct = fiffigt.vertFlipRect(rct)
    end
    member("layer"..tostring(lr)).image:copyPixels(member("lightHouseFlowersGraf").image, rct, gtRect, {ink=36})
  end
  
  gEffectProps.listPos = gEffectProps.listPos + 1

  if gEffectProps.listPos > #gEffectProps.list then
    local l = list({1,2,3,4,5,6,7,8})
    local l2 = list()
    for a = 1, 8 do
      local val = l[random(#l)]
      l2:add(val)
      l:deleteOne(val)
    end
    gEffectProps = {list=l2, listPos=1}
  end
end

function me.applyBlackGoo (q, c, eftc)
  local sPnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10,-10)
  local rct = member("blob").image.rect
  for d = 1, 10 do
    for e = 1, 10 do
      local ps = point(sPnt.x + d*2, sPnt.y + e*2)
      if member("layer0").buf:getPixel(ps) == color(255, 255, 255) then
        member("blackOutImg1").image:copyPixels(member("blob").image, rect(ps.x-6-random(random(11)),ps.y-6-random(random(11)),ps.x+6+random(random(11)),ps.y+6+random(random(11))), rct, {color=color(255, 255, 255, 0), ink=36})
        member("blackOutImg2").image:copyPixels(member("blob").image, rect(ps.x-7-random(random(14)),ps.y-7-random(random(14)),ps.x+7+random(random(14)),ps.y+7+random(random(14))), rct, {color=color(255, 255, 255, 0), ink=36})
      end
    end
  end
end

function me.applyRestoreEffect (q, c, q2, c2, eftc)
  local layers

  if lrSup == "All" then
    layers = {1,2,3}
  elseif lrSup == "1" then
    layers = {1}
  elseif lrSup == "2" then
    layers = {2}
  elseif lrSup == "3" then
    layers = {3}
  elseif lrSup == "1:st and 2:nd" then
    layers = {1,2}
  elseif lrSup == "2:nd and 3:rd" then
    layers = {2,3}
  else
    layers = {1,2,3}
  end

  for _,layer in ipairs(layers) do
    if(spelrelaterat.afaMvLvlEdit(point(q2, c2), layer)==1)then
      local mdPoint = spelrelaterat.giveMiddleOfTile(point(q,c))
      local tlRct = rect(mdPoint+point(-10, -10), mdPoint+point(10,10))
      
      --        member("layer" .. lr).image:copyPixels(member("pxl").image, rect(mdPoint-point(10, 10), mdPoint+point(10,10)), rect(0,0,1,1), {color=color(255, 0, 0)})
      --    
      
      local A = 2
      local B = 1
      
      local U = A
      
      if tobool(me.isTileSolidAndAffected(point(q2-1, c2), layer)) then
        U = B
      end

      for lr = ((layer-1)*10) + 4, ((layer-1)*10) + 6 do
        member("layer" .. lr).image:copyPixels(member("pxl").image, rect(mdPoint+point(-10, -10), mdPoint+point(-10+U,10)), rect(0,0,1,1), {color=color(255, 0, 0)})
      end

      me.draw3DBeams(q2, c2, layer, tlRct, {1,4}, U)
      
      U = A

      if tobool(me.isTileSolidAndAffected(point(q2+1, c2), layer))then
        U = B
      end

      for lr = ((layer-1)*10) + 4, ((layer-1)*10) + 6 do
        member("layer" .. lr).image:copyPixels(member("pxl").image, rect(mdPoint+point(10-U, -10), mdPoint+point(10,10)), rect(0,0,1,1), {color=color(255, 0, 0)})
      end

      me.draw3DBeams(q2, c2, layer, tlRct, {2,3}, U)
      
      U = A
      if tobool(me.isTileSolidAndAffected(point(q2, c2-1), layer))then
        U = B
      end

      for lr = ((layer-1)*10) + 4, ((layer-1)*10) + 6 do
        member("layer" .. lr).image:copyPixels(member("pxl").image, rect(mdPoint+point(-10, -10), mdPoint+point(10,-10+U)), rect(0,0,1,1), {color=color(255, 0, 0)})
      end

      me.draw3DBeams(q2, c2, layer, tlRct, {1,2}, U)
      
      U = A
      if tobool(me.isTileSolidAndAffected(point(q2, c2+1), layer))then
        U = B
      end

      for lr = ((layer-1)*10) + 4, ((layer-1)*10) + 6 do
        member("layer" .. lr).image:copyPixels(member("pxl").image, rect(mdPoint+point(-10, 10-U), mdPoint+point(10,10)), rect(0,0,1,1), {color=color(255, 0, 0)})
      end

      me.draw3DBeams(q2, c2, layer, tlRct, {3,4}, U)
      
    end
    me.reDrawPoles(point(q2,c2), layer, q, c, ((layer-1)*10) + 4)
  end
end

function me.draw3DBeams (q2, c2, layer, tlRct, crnrs, U)
  if(layer > 1) then
    if tobool(me.isTileSolidAndAffected(point(q2, c2), layer-1))then
      for _,crnr in ipairs(crnrs) do
        local rct = me.CornerRect(tlRct, crnr, U)
        for lr = ((layer-1)*10) - 5, ((layer-1)*10) + 5 do
          member("layer" .. lr).image:copyPixels(member("pxl").image, rct, rect(0,0,1,1), {color=color(255, 0, 0)})
        end
      end
    end
  end
  if(layer < 3) then
    if tobool(me.isTileSolidAndAffected(point(q2, c2), layer+1)) then
      local rct = me.CornerRect(tlRct, crnr, U)
      for _,crnr in ipairs(crnrs) do
        for lr = ((layer-1)*10) + 5, ((layer-1)*10) + 15 do
          member("layer" .. lr).image:copyPixels(member("pxl").image, rct, rect(0,0,1,1), {color=color(255, 0, 0)})
        end
      end
    end
  end
end


function me.CornerRect(tlRct, crnr, U)
  -- tlRct = tlRct+rect(1,1,-1,-1)
  
  if crnr == 1 then
    return rect(tlRct.left, tlRct.top, tlRct.left+U, tlRct.top+U)
  elseif crnr == 2 then
    return rect(tlRct.right-U, tlRct.top, tlRct.right, tlRct.top+U)
  elseif crnr == 3 then
    return rect(tlRct.right-U, tlRct.bottom-U, tlRct.right, tlRct.bottom)
  elseif crnr == 4 then
    return rect(tlRct.left, tlRct.bottom-U, tlRct.left+U, tlRct.bottom)
  end

  return nil
end

function me.isTileSolidAndAffected (tl, layer)
  if(spelrelaterat.afaMvLvlEdit(point(tl.x, tl.y), layer)~=1)or(tl.x<1)or(tl.y<1)or(tl.x > gLOprops.size.x)or(tl.y > gLOprops.size.y)then
    return 0
  elseif (gEEprops.effects[r].mtrx[tl.x][tl.y] > 0)then
    return 1
  else
    return 0
  end
end

function me.reDrawPoles(pos, layer, q, c, drawLayer)
  -- global gLEProps, gLOprops
  if pos:inside(rect(1,1,gLOprops.size.x+1,gLOprops.size.y+1)) then
    for _, t in ipairs(gLEProps.matrix[pos.x][pos.y][layer][2]) do
      local rct
      
      if t == 1 then
        rct = rect((q-1)*20, (c-1)*20, q*20, c*20)+rect(0, 8, 0, -8)--rect(gRenderCameraTilePos,gRenderCameraTilePos)*20
        member("layer" .. drawLayer).image:copyPixels(member("pxl").image, rct, member("pxl").image.rect, {color:color(255, 0, 0)})
      elseif t == 2 then  
        rct = rect((q-1)*20, (c-1)*20, q*20, c*20)+rect(8, 0, -8, 0)--rect(gRenderCameraTilePos,gRenderCameraTilePos)*20
        member("layer" .. drawLayer).image:copyPixels(member("pxl").image, rct, member("pxl").image.rect, {color:color(255, 0, 0)})
      end
    end
  end
end

function me.closestCamera (pos)
  -- global gCameraProps
  local closest = 1000
  local bestCam = 0
  
  for camNum = 1, #gCameraProps.cameras do
    if tobool(me.seenByCamera(camNum, pos))and(fiffigt.diag(pos, gCameraProps.cameras[camNum]+point(1400/2, 800/2)) < closest )then
      closest = fiffigt.diag(pos, gCameraProps.cameras[camNum]+point(1400/2, 800/2))
      bestCam = camNum
    end
  end
  
  return bestCam
end

function me.seenByCamera (camNum, pos)
  -- global gCameraProps
  
  local cameraPos = gCameraProps.cameras[camNum]
  
  if pos:inside(rect(cameraPos.x, cameraPos.y, cameraPos.x+1400, cameraPos.y+800)+(rect(-15, -10, 15, 10)*20))then
    return 1
  else
    return 0
  end
end

function me.applyBigPlant (q, c)
  local q2 = q + gRenderCameraTilePos.x
  local c2 = c + gRenderCameraTilePos.y
  
  local lr = 1
  local layer

  if lrSup == "All" then
    layer = random(3)
  elseif lrSup == "1" then
    layer = 1
  elseif lrSup == "2" then
    layer = 2
  elseif lrSup == "3" then
    layer = 3
  elseif lrSup == "1:st and 2:nd" then
    layer = random(2)
  elseif lrSup == "2:nd and 3:rd" then
    layer = random(2) + 1
  else
    layer = random(3)
  end
  
  local mem = "fern"

  if gEEprops.effects[r].nm == "Giant Mushroom" then
    mem = "giantMushroom"
  end
  
  lr = ((layer-1)*10) + random(9) - 1
  if (spelrelaterat.afaMvLvlEdit(point(q2,c2), layer)==0) then
    
    local rnd = gEffectProps.list[gEffectProps.listPos]
    local flp = random(2)-1
    local pnt = spelrelaterat.giveMiddleOfTile(point(q,c))+point(-10+random(20), 10)
    
    local rct = rect(pnt, pnt) + rect(-50, -80, 50, 20)
    local gtRect = rect((rnd-1)*100, 0, rnd*100, 100)+rect(1,1,1,1)
    if tobool(flp) then
      rct = fiffigt.vertFlipRect(rct)
    end
    member("layer"..tostring(lr)).image:copyPixels(member(mem.."Graf").image, rct, gtRect, {ink=36, color=colr})
    
    pnt = spelrelaterat.depthPnt(pnt, lr-5)
    rct = rect(pnt, pnt) + rect(-50, -80, 50, 20)
    if tobool(flp) then
      rct = fiffigt.vertFlipRect(rct)
    end
    spelrelaterat.copyPixelsToEffectColor(gdLayer, lr, rct, mem.."Grad",rect((rnd-1)*100, 0, rnd*100, 100)+rect(1,1,1,1), 0.5)
  end
  
  gEffectProps.listPos = gEffectProps.listPos + 1

  if gEffectProps.listPos > #gEffectProps.list then
    local l = list({1,2,3,4,5,6,7,8})
    local l2 = list()
    for a = 1, 8 do
      local val = l[random(#l)]
      l2:add(val)
      l:deleteOne(val)
    end
    gEffectProps = {list=l2, listPos=1}
  end
end











return me