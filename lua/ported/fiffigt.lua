--detta skript räknar ut distansen mellan två punkter

local M = {}

function M.restrict(val, low, high)
    if (val < low) then
        return low
    elseif (val > high) then
        return high
    else
        return val
    end
end

---@param point1 point
---@param point2 point
---@return number
function M.diag(point1, point2)
  local rectHeight = math.abs(point1.y - point2.y)
  local rectWidth = math.abs(point1.x - point2.x)
  return math.sqrt((rectHeight * rectHeight) + (rectWidth * rectWidth))
end

---
---@param point1 point
---@param point2 point
---@param dig number
---@return boolean
function M.diagWI(point1, point2, dig)
  local RectHeight = math.abs(point1.y - point2.y)
  local RectWidth = math.abs(point1.x - point2.x)
  return ((RectHeight * RectHeight) + (RectWidth * RectWidth) < dig*dig )
end 

---
---@param point1 point
---@param point2 point
---@return number
function M.diagNoSqrt(point1, point2)
  local RectHeight = math.abs(point1.y - point2.y)
  local RectWidth = math.abs(point1.x - point2.x)
  
  local diagonal = (RectHeight * RectHeight) + (RectWidth * RectWidth)
  
  return diagonal
end

---comment
---@param rct rect
---@return table
function M.vertFlipRect(rct)
  return {
    point(rct.right, rct.top),
    point(rct.left, rct.top),
    point(rct.left, rct.bottom),
    point(rct.right, rct.bottom)
}
end

--tar fram en förflyttning mellan två punkter, bergänsad till theMovement
---comment
---@param pointA point
---@param pointB point
---@param theMovement number
---@return point
function M.moveToPoint(pointA, pointB, theMovement)
  pointB = pointB-pointA
  local diagonal = M.diag(point(0,0), pointB)
  
  local dirVec
  
  if diagonal>0 then
    dirVec = pointB/diagonal
  else
    dirVec = point(0, 1)
  end
  return dirVec*theMovement
end

---
---@param p1 point
---@param p2 point
---@return point
function M.returnRelativePoint(p1, p2)
  -- p1 är den relativa nollpunktens absoluta position
  -- p2 är den absoluta positionen hos punkten vars relativa position ska beräknas
  local newX = -1 * (p1.x - p2.x)
  local newY = p1.y - p2.y
  return point(newX, newY)
end

---
---@param p1 point
---@param p2 point
---@return point
function M.returnAbsolutePoint(p1, p2)
  -- p1 är den relativa nollpunktens absoluta position
  -- p2 är den relativa positionen hos den punkt vars absoluta position ska beräknas
  local realX = p1.x + p2.x
  local realY = p1.y - p2.y
  return point(realX, realY)
end

---comment
---@param A number
---@param B number
---@param val number
---@return number
function M.lerp(A, B, val)
  val = M.restrict(val, 0, 1)
  
  local sv

  if(B < A)then
    sv = A
    A = B
    B = sv
    val = 1.0-val
  end
  return M.restrict(A + (B-A)*val, A, B)
end

---comment
---@param A point
---@param B point
---@param val number
---@return point
function M.lerpPnt(A, B, val)
  return point(M.lerp(A.x, B.x, val), M.lerp(A.y, B.y, val))
end


--lämnar tillbaks punkten där två linjer korsar varandra
--(lämna in linjerna som rektanglar)
function M.giveCrossPoint(line1PntA, line1PntB, line2PntA, line2PntB)

  local X1 =line1PntA.x.float
  local Y1 =line1PntA.y.float
  local X2 =line1PntB.x.float
  local Y2 =line1PntB.y.float

  local X3 =line2PntA.x.float
  local Y3 =line2PntA.y.float
  local X4 =line2PntB.x.float
  local Y4 =line2PntB.y.float

  local crossPointX
  local crossPointY

  if not(X2==X1) and not(X4==X3) then
    if not ((((Y4-Y3)/(X4-X3))-((Y2-Y1)/(X2-X1))) == 0) then
      crossPointX = (Y1-((Y2-Y1)/(X2-X1))*X1+((Y4-Y3)/(X4-X3))*X3-Y3)/(((Y4-Y3)/(X4-X3))-((Y2-Y1)/(X2-X1)))
      crossPointY = ((Y2-Y1)/(X2-X1))*crossPointX+(Y1-((Y2-Y1)/(X2-X1))*X1)
    end
  elseif not (X4==X3) then
    crossPointX = X1
    crossPointY = ((Y4-Y3)/(X4-X3))*crossPointX+Y3-((Y4-Y3)/(X4-X3))*X3
  else
    crossPointX = X3
    crossPointY = Y1 
  end
  
  return point(crossPointX, crossPointY)
end




-- --lämnar tillbaks yta och punkt för var en linje träffar en rect
-- --(lämna in linjen som en rektangel, punkten innuti recten som andrapunkt)

-- function M.giveHitSurf(obstRect, movLine)
--   local lastPoint = point(movLine.left, movLine.top)
--   local insidePoint = point(movLine.right, movLine.bottom)
  
--   local leftHitPoint = M.giveCrossPoint(rect(obstRect.left, 0, obstRect.left, 1), movLine)
--   local rightHitPoint = M.giveCrossPoint(rect(obstRect.right, 0, obstRect.right, 1), movLine)
--   local topHitPoint = M.giveCrossPoint(rect(0, obstRect.top, 1, obstRect.top), movLine)
--   local bottomHitPoint = M.giveCrossPoint(rect(0, obstRect.bottom, 1, obstRect.bottom), movLine)
  
--   local insidePointsL = list()
  
--   obstRect = obstRect + rect(-1, -1, 1, 1)

--   local pointData
  
--   if leftHitPoint:inside(obstRect) then
--     pointData = map({dist=the_Diagonal(leftHitPoint, point(movLine.left, movLine.top)), pos = leftHitPoint, LTRB = "left"})
--     insidePointsL:add(pointData)
--   end
  
--   if rightHitPoint:inside(obstRect) then
--     pointData = map({dist=the_Diagonal(rightHitPoint, point(movLine.left, movLine.top)), pos=rightHitPoint, LTRB="right"})
--     insidePointsL:add(pointData)
--   end
  
--   if topHitPoint:inside(obstRect) then
--     pointData = map({dist=the_Diagonal(topHitPoint, point(movLine.left, movLine.top)), pos=topHitPoint, LTRB="top"})
--     insidePointsL:add(pointData)
--   end
  
--   if bottomHitPoint:inside(obstRect) then
--     pointData = map({dist=the_Diagonal(bottomHitPoint, point(movLine.left, movLine.top)), pos=bottomHitPoint, LTRB="bottom"})
--     insidePointsL:add(pointData)
--   end
  
--   insidePointsL:sort()
  
--   local hitsurf = insidePointsL[1].LTRB
--   local hitPoint = insidePointsL[1].pos
  
  
--   return list({hitSurf, hitPoint})
-- end



---comment
---@param pos point
---@param lookAtpoint point
---@return number
function M.lookAtPoint(pos, lookAtpoint)
  local y_diff = lookAtpoint.y - pos.y
  local x_diff = pos.x - lookAtpoint.x
  
  local rotationAngleRad = 0

  if not (x_diff == 0) then
    rotationAngleRad = math.atan(y_diff / x_diff)
  else
    rotationAngleRad = 1.5 * math.pi
  end
  
  local fuckedupanglefix_parameter = 0

  if lookAtpoint.x > pos.x then
    fuckedupanglefix_parameter = 0  -- 2 * PI
  else
    fuckedupanglefix_parameter = math.pi
  end
  rotationAngleRad = fuckedupanglefix_parameter - rotationAngleRad
  
  return ((rotationAngleRad * 180 / math.pi) + 90)
end

---@param deg number
---@return point
function M.degToVec(deg)
  local rad = -2 * math.pi * ((deg + 90) / 360.0)
  return point(-math.cos(rad), math.sin(rad))
end

---comment
---@param deg number
---@param facH number
---@param facV number
---@return point
function M.degToVecFac2(deg, facH, facV)
  deg = deg + 90
  deg = -deg
  local rad = ((deg/360.0))*math.pi*2
  
  return point(-math.cos(rad)*facH, math.sin(rad)*facV)
end

---comment
---@param pnt point
---@param A point
---@param B point
---@return point
function M.closestPointOnLine(pnt, A, B)
  return M.giveCrossPoint(pnt, pnt + M.giveDirFor90degrToLine(A, B), A, B)
end

---comment
---@param pnt1 point
---@param pnt2 point
---@return point
function M.giveDirFor90degrToLine(pnt1, pnt2)
  local X1 = pnt1.x
  local Y1 = pnt1.y
  
  local X2 = pnt2.x
  local Y2 = pnt2.y
  
  local Ydiff = Y1-Y2
  local Xdiff = X1-X2
  
  local dir = 0

  if Xdiff ~= 0 then
    dir = Ydiff/Xdiff
  else
    dir = 1
  end
  
  local newDir = 0
  
  if dir ~= 0 then
    newDir = -1.0/dir
  else
    newDir = 1
  end
  
  local newPnt = point(1, newDir)
  
  
  local fac = 1
  
  if X2 < X1 then 
    if Y2 < Y1 then
      fac = 1
    else
      fac = -1
    end
  else
    if Y2 < Y1 then
      fac = 1
    else
      fac = -1
    end
  end
  
  newPnt = newPnt * fac
  
  newPnt = newPnt/M.diag(point(0,0), newPnt)--(ABS(newPnt.x)-ABS(newPnt.y))
  return newPnt
end

function M.lnPntDist(pnt, lineA, lineB)
  --  dir = giveDirFor90degrToLine(lineA, lineB)
  --  newLinePnt = pnt + dir
  --  crossPnt = giveCrossPoint(pnt, newLinePnt, lineA, lineB)
  --  return diag(pnt, crossPnt)
  
  return diag(pnt, giveCrossPoint(pnt, pnt + giveDirFor90degrToLine(lineA, lineB), lineA, lineB))
end

function M.giveCircleCollTime(pos1, r1, vel1, pos2, r2, vel2)
  -- h = _system.milliseconds
  local x1 = pos1.x
  local y1 = pos1.y
  
  local x2 = pos2.x
  local y2 = pos2.y
  
  local vx1 = vel1.x
  local vy1 = vel1.y
  
  local vx2 = vel2.x
  local vy2 = vel2.y
  
  
  local A = -x1*vx1-y1*vy1+vx1*x2+vy1*y2+x1*vx2-x2*vx2+y1*vy2-y2*vy2
  local B = -x1*vx1-y1*vy1+vx1*x2+vy1*y2+x1*vx2-x2*vx2+y1*vy2-y2*vy2
  local C = (vx1 ^ 2)+(vy1 ^ 2)-2*vx1*vx2+(vx2 ^ 2)-2*vy1*vy2+(vy2 ^ 2)
  local D = (x1 ^ 2)+(y1 ^ 2)-(r1 ^ 2)-2*x1*x2+(x2 ^ 2)-2*y1*y2+(y2 ^ 2)-2*r1*r2-(r2 ^ 2)
  local E = (vx1 ^ 2)+(vy1 ^ 2)-2*vx1*vx2+(vx2 ^ 2)-2*vy1*vy2+(vy2 ^ 2)
  
  local T = (2.0*A-math.sqrt((-2.0*B ^ 2)-4.0*C*D))/(2.0*E)
  
  return T
end

function M.lnPntDistNonAbs(pnt, lnPnt1, lnPnt2)
    local k
    if not (lnPnt1.x-lnPnt2.x == 0) then
        k = (lnPnt1.y-lnPnt2.y)/(lnPnt1.x-lnPnt2.x)
    else
        k = 0
    end
  local m = lnPnt1.y-(k*lnPnt1.x)
  
  local Y1 = pnt.y
  local X1 = pnt.x --+ 0.0001
  
  
  if not (X1 == 0) then
    local k2 = (Y1-m)/X1
    local D = math.sqrt((math.abs(Y1-m) ^ 2)+ (X1 ^ 2))
    local E = math.sin(math.atan(   (k2-k)/(1+k2*k)  ))
    
    local F = 1
    if k<0 then
      F = -1
    end
    
    
    return (D*E*F)
  else 
    --  put "lnPntDistNonAbs ALERT"
    return point(0, 0)
  end
end 

---@param rct rect
---@param pnt point
---@return point
function M.closestPntInRect(rct, pnt)
  local resPnt = point(0,0)
  if pnt.x < rct.left then
    
    
    if pnt.y < rct.top then
      resPnt = point(rct.left, rct.top)
    elseif pnt.y > rct.bottom then
      resPnt = point(rct.left, rct.bottom)
    else
      resPnt = point(rct.left, pnt.y)
    end
    
    
    
  elseif pnt.x > rct.right then
    
    
    if pnt.y < rct.top then
      resPnt = point(rct.right, rct.top)
    elseif pnt.y > rct.bottom then
      resPnt = point(rct.right, rct.bottom)
    else
      resPnt = point(rct.right, pnt.y)
    end
    
    
    
  else
    
    if pnt.y < rct.top then
      resPnt = point(pnt.x, rct.top)
    elseif pnt.y > rct.bottom then
      resPnt = point(pnt.x, rct.bottom)
    else
      resPnt = pnt
    end
    
  end
  
  return resPnt
end

---@param pnt1 point
---@param pnt2 point
---@param pnt3 point
---@param pnt4 point
function M.angleBetweenLines(pnt1, pnt2, pnt3, pnt4)
  --  k = (pnt2.y-pnt1.y)/(pnt2.x-pnt1.x)
  --  k2 = (pnt4.y-pnt3.y)/(pnt4.x-pnt3.x)
  --  k = k.float
  --  k2 = k2.float
  --  if (1+k2*k)<>0 then
  --    return (atan((k2-k)/(1+k2*k))/(PI*2))*360.0
  --  else
  --    return 0
  --  end
  -- return ((atan(k)-atan(k2))/PI)*180.0
  return M.lookAtPoint(pnt1, pnt2)-M.lookAtPoint(pnt3, pnt4)
end

function M.compareAngles(origo, pnt1, pnt2)
  --tm = _system.milliseconds
  
  -- repeat with q = 1 to 10000 then
  
  pnt1 = pnt1 - origo
  pnt2 = pnt2 - origo
  
  pnt2 = M.rotatePntFromOrigo(pnt2, point(0,0), M.lookAtPoint(point(0,0), pnt1))
  local ang = M.lookAtPoint(point(0,0), pnt2)
  if ang > 180 then
    ang = math.abs(ang-360)
  end
  
  
  
  --end repeat
  --put  _system.milliseconds - tm
  return ang
end

function M.rotatePntFromOrigo(pnt, org, rotat)
  local realDir = M.lookAtPoint(org, pnt)
  local diagonal = M.diag(org, pnt)
  local newDir = realDir-rotat
  local vec = M.degToVec(newDir)
  local rotatedPnt = org+(vec*diagonal)
  return rotatedPnt
end

function M.customAdd(L, val)
  L:add(val)
  return L
end

function M.customSort(L)
  L:sort()
  return L
end

function M.insideLine(pnt, A, B, rad)
  local retrn = FALSE
  if M.diag(pnt, A)<rad then 
    retrn = TRUE
  elseif M.diag(pnt, B)<rad then 
    retrn = TRUE
  end
  
  if retrn == FALSE then
    local dist
    local shitCode = M.lnPntDistNonAbs(pnt, A, B)
    
    if type(shitCode) == "number" then
        dist = math.abs(shitCode)
    elseif type(shitCode) == "userdata" then
        dist = 0
    end

    if dist < rad then
      local hyp1 = M.diag(A, B)
      local hyp2 = M.diag(A, A+(M.giveDirFor90degrToLine(A, B)*rad))
      
      local maxDiag = math.sqrt((hyp1 ^ 2)+(hyp2 ^ 2))
      
      if (M.diag(pnt, A)<maxDiag)and(M.diag(pnt, B)<maxDiag) then
        retrn = TRUE
      end
      
    end
  end
  
  return retrn
  
end

---Generates the text file of the newly rendered level.
---@param lvlName string
function M.newMakeLevel(lvlName)
  --put "saving:" && lvlName && "..."
  
  --global gLOprops, gCameraProps
  
  local sz  = gLOprops.size*20
  local pos = point(0,0)
  
--   global gLOprops, gLightEProps, gLEProps, gEnvEditorProps, gLevel
  
  local lightangle = M.degToVec(gLightEProps.lightAngle) * gLightEProps.flatness
  
  local txt = ""
  txt = txt .. lvlName
--   put RETURN after txt
    txt = txt .. RETURN
  txt = txt .. (gLOprops.size.x - gLOprops.extratiles[1] - gLOprops.extratiles[3]) .. "*" .. (gLOprops.size.y - gLOprops.extratiles[2] - gLOprops.extratiles[4])
  if gEnvEditorProps.waterLevel > -1 then
    txt = txt .. "|" .. gEnvEditorProps.waterLevel .. "|" .. gEnvEditorProps.waterInFront
  end
--   put RETURN after txt
  txt =  txt .. RETURN
  txt = txt .. lightangle.x .. "*" .. lightangle.y .. "|0|0"
  --   put RETURN after txt
  txt =  txt .. RETURN
  
  for q = 1, #gCameraProps.cameras do
    -- put (gCameraProps.cameras[q].x.integer - gLOprops.extratiles[1]*20) & "," & (gCameraProps.cameras[q].y.integer - gLOprops.extratiles[2]*20) after txt
    txt = txt .. (gCameraProps.cameras[q].x.integer - gLOprops.extratiles[1]*20) .. "," .. (gCameraProps.cameras[q].y.integer - gLOprops.extratiles[2]*20)
    if (q < #gCameraProps.cameras)then
    --   put "|" after txt
    txt = txt .. '|'
    end
  end
  
  
  local mtrx = require("saveFile").changeToPlayMatrix()
  
--   put RETURN after txt
  if (gLevel.defaultTerrain == 1) then
    txt = txt .. "Border: Solid"
  else
    txt = txt .. "Border: Passable"
  end
--   put RETURN after txt
  txt = txt .. RETURN
  --ITEMS
  for q = 1 + gLOprops.extratiles[1], gLOprops.size.x - gLOprops.extratiles[3] do
    for c = 1 + gLOprops.extratiles[2], gLOprops.size.y - gLOprops.extratiles[4] do
      if(mtrx[q][c][1][2].getPos(9) > 0) then
        txt = txt .. "0," .. (q-gLOprops.extratiles[1]) .. "," .. (c-gLOprops.extratiles[2]) .. "|"
      end
      if(mtrx[q][c][1][2].getPos(10) > 0) then
        txt = txt .. "1," .. (q-gLOprops.extratiles[1]) .. "," .. (c-gLOprops.extratiles[2]) .. "|"
      end
    end
  end
  
--   put RETURN after txt
--   put RETURN after txt
--   put RETURN after txt
--   put RETURN after txt
  txt = txt .. RETURN
  txt = txt .. RETURN
  txt = txt .. RETURN
  txt = txt .. RETURN
  txt = txt .. '0'
  --   put "0" after txt--connmap
--   put RETURN after txt--connmap
--   put RETURN after txt--line for baked AI info
  txt = txt .. RETURN
  txt = txt .. RETURN
  for q = 1 + gLOprops.extratiles[1], gLOprops.size.x - gLOprops.extratiles[3] do
    for c = 1 + gLOprops.extratiles[2], gLOprops.size.y - gLOprops.extratiles[4] do
      local case1 = mtrx[q][c][1][1]

        if case1 == 1 then
            txt = txt .. "1"
        elseif case1 == 2 or case1 == 3 or case1 == 4 or case1 == 5 then
            txt = txt .. "2"
        elseif case1 == 6 then
            txt = txt .. "3"
        elseif case1 == 7 then
            txt = txt .. "4,3"
        else
            txt = txt .. "0"
        end

    --   case mtrx[q][c][1][1] of
    --     1: --wall
    --       txt = txt & "1"
    --     2, 3, 4, 5:--slopes
    --       txt = txt & "2"
    --     6: --floor
    --       txt = txt & "3"
    --     7: --shortcut entrance
    --       txt = txt & "4,3"
    --     otherwise: --air
    --       txt = txt & "0"
    --   end
      
      for e = 1, mtrx[q][c][1][2].count do
        local case2 = mtrx[q][c][1][2][e]

        local spelr = require('spelrelaterat')

        if case2 == 2 then
            if not(mtrx[q][c][1][1] == 1)then
              txt = txt .. ",1"
            end
        elseif case2 == 1 then
            if not(mtrx[q][c][1][1] == 1)then
              txt = txt .. ",2"
            end
        elseif case2 == 5 then
            txt = txt .. ",3"
        elseif case2 == 6 then
            txt = txt .. ",4"
        elseif case2 == 7 then
            txt = txt .. ",5"
        elseif case2 == 19 then
            txt = txt .. ",9"
        elseif case2 == 21 then
            txt = txt .. ",12"
        elseif case2 == 3 then
            if(spelr.afaMvLvlEdit(point(q,c), 1) == 0)and(spelr.afaMvLvlEdit(point(q,c+1), 1) == 1) then
              txt = txt .. ",7"
            end
        elseif case2 == 18 then
            txt = txt .. ",8"
        elseif case2 == 13 then
            txt = txt .. ",10"
        elseif case2 == 20 then
            txt = txt .. ",11"
        end

        -- case mtrx[q][c][1][2][e] of
        --   2: --vertical beam
        --     if(mtrx[q][c][1][1] <> 1)then
        --       txt = txt & ",1"
        --     end
        --   1: -- horizontal beam
        --     if(mtrx[q][c][1][1] <> 1)then
        --       txt = txt & ",2"
        --     end
        --   5: --shortcut
        --     txt = txt & ",3"
        --   6: --room exit
        --     txt = txt & ",4"
        --   7: --hiding hole
        --     txt = txt & ",5"
        --   19: -- WHAM
        --     txt = txt & ",9"
        --   21: -- scavenger hole
        --     txt = txt & ",12"
        --   3: -- hive!
        --     if(afaMvLvlEdit(point(q,c), 1) = 0)and(afaMvLvlEdit(point(q,c+1), 1) = 1)then
        --       txt = txt & ",7"
        --     end
        --   18: -- waterfall!
        --     txt = txt & ",8"
        --   13: --garbage hole
        --     txt = txt & ",10"
        --   20: --worm grass
        --     txt = txt & ",11"
            
        -- end case
      end
      
      if not(mtrx[q][c][1][1] == 1) and not(mtrx[q][c][2][1] == 1)then -- wall behind
        txt = txt .. ",6"
      end
      
      txt = txt .. "|"
    end
  end
  
--   put RETURN after txt
  txt = txt .. RETURN
  -- Put the cangles into the txt
--   put "camera angles:" after txt
  txt = txt .. "camera angles:"
  for q = 1, #gCameraProps.cameras do
    for i = 1, 4 do
    --   put gCameraProps.quads[q][i][1] & "," & gCameraProps.quads[q][i][2] after txt
      txt = txt .. gCameraProps.quads[q][i][1] .. "," .. gCameraProps.quads[q][i][2]
        if i < 4 then 
            -- put ";" after txt 
            txt = txt .. ';'
        end
    end
    if (q < #gCameraProps.cameras)then
    --   put "|" after txt
      txt = txt .. '|'
    end
  end
  
  local foundFile = 0
  
  for i = 1, 1000 do
    local n = getNthFileNameInFolder("Levels", i)
    if n == "" then 
        break
    end
    if n == lvlName .. ".txt" then
      foundFile = 1
      break
    end
  end
  
--   put "Found file: " + foundFile
  if foundFile == 1 then
    local fileDeleter = xtra("fileio")
    fileDeleter.openFile(moviePath .. "Levels/" .. lvlName .. ".txt", 0)
    fileDeleter.delete()
    -- put "FILE DELETED!"
  end
  
  
  local objFileio = xtra("fileio")
  objFileio.createFile(moviePath .. "Levels/" .. lvlName .. ".txt")
  objFileio.closeFile()
  
  
  
  local fileOpener = xtra("fileio")
  fileOpener.openFile(moviePath .. "Levels/" .. lvlName .. ".txt", 0)
  for q = 1, numberOfLines(txt) do
    fileOpener.writeString(atLine(txt, q))
    fileOpener.writeReturn("windows")
  end
  -- txt2 = ""
  --- --repeat with q = 1 to 1040*800 then
  --  txt2 = txt2 & string(random(10)-1)
  -- end repeat
  --  fileOpener.writeString(txt2)
  -- fileOpener.writeReturn(#windows)
  fileOpener.closeFile()
  
  
  
  
  
  -- repeat with q = 0 to 29 then
  --     props = ["image": member("layer"&q).image, "filename":_movie.path&"Levels/"&lvlName & "_" & q & ".png"]
  -- ok = gImgXtra.ix_saveImage(props)
  -- end repeat
  
  
  
  
--   put "saved22:" && lvlName --&& ok
end

function M.LerpVector(A, B, l)
  return point(M.lerp(A.x, B.x, l), M.lerp(A.y, B.y, l))
end

function M.SeedOfTile(tile)
--   global gLOprops
  return gLOprops.tileSeed + (tile.y * gLOprops.size.x) + tile.x
end

function M.Bezier(A, cA, B, cB, f)
  
  local middleControl = M.LerpVector(cA, cB, f)
  cA = M.LerpVector(A, cA, f)
  cB = M.LerpVector(cB, B, f)
  cA = M.LerpVector(cA, middleControl, f)
  cB = M.LerpVector(middleControl, cB, f)
  
  return M.LerpVector(cA, cB, f)
end

---@deprecated
---@param fileName string
function M.CacheLoadImage(fileName)
  -- implemented in C#
end


return M


























