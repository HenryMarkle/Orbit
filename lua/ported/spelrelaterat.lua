local me = {}

local fiffigt = require('fiffigt')

---@param pos point
---@return point
function me.giveGridPos(pos)
    return point(toint((pos.x / 20.0) + 0.4999), toint((pos.y / 20.0) + 0.4999))
end

---@param pos point
---@return point
function me.giveMiddleOfTile(pos)
    return point(pos.x * 20 - 10, pos.y * 20 - 10)
end

---@param val number
---@param low number
---@param high number
---@return number
function me.restrict(val, low, high)
    if (val < low) then
        return low
    elseif (val > high) then
        return high
    else
        return val
    end
end

---@param val number
---@param low number
---@param high number
---@return number
function me.restrictWithFlip(val, low, high)
    if (val < low) then
        return val + (high - low) + 1
    elseif (val > high) then
        return val - (high - low) - 1
    else
        return val
    end
end

---Returns the type of geometry cell in a given matrix position.
---@param pos point
---@param layer number
---@return number
function me.afaMvLvlEdit(pos, layer)
    --global gLEProps, gLOprops
    if pos:inside(rect(1, 1, gLOprops.size.x + 1, gLOprops.size.y + 1)) then
        return gLEProps.matrix[pos.x][pos.y][layer][1]
    else
        return 1
    end
end

---Returns the geometry cell in a given matrix position.
---@param pos point
---@param layer number
---@return number
function me.solidAfaMv(pos, layer)
    --global solidMtrx, gLOprops
    if pos:inside(rect(1, 1, gLOprops.size.x + 1, gLOprops.size.y + 1)) then
        return solidMtrx[pos.x][pos.y][layer]
    else
        return 1
    end
end

---@param pos point
---@return integer
function me.withinBoundsOfLevel(pos)
    --global solidMtrx
    if pos:inside(rect(2, 2, #solidMtrx, #solidMtrx[1])) then
        return 1
    else
        return 0
    end
end

---@param pnt point
---@param dpt number
---@return unknown
function me.depthPnt(pnt, dpt)
    return (pnt - point(700, 800 / 3)) / ((10 + dpt * 0.025) * 0.1) + point(700, 800 / 3)
end

---@param tile point
---@param effectSeed number
---@return number
function me.seedForTile(tile, effectSeed)
    --global gLEProps
    return effectSeed + tile.x + tile.y * #gLEProps.matrix
end

---@param gdLayer string
---@param lr number
---@param rct rect|Quad
---@param getMember string
---@param gtRect rect
---@param zbleed number
---@param blnd number?
function me.copyPixelsToEffectColor(gdLayer, lr, rct, getMember, gtRect, zbleed, blnd)
    --global DRPxl
    if (blnd == nil) then
        blnd = 1.0
    end

    if (gdLayer ~= "C") and (blnd > 0) then
        lr = toint(lr)

        if (lr < 0) then
            lr = 0
        elseif (lr > 29) then
            lr = 29
        end
        local gtImg = member(getMember).image

        if (blnd ~= 0) and (blnd ~= nil) then
            local dmpImg = image(gtImg)
            dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                { blend = 100.0 * (1.0 - blnd), color = color(255, 255, 255) })
            gtImg = dmpImg
        end

        member("gradient" .. gdLayer .. tostring(lr)).image:copyPixels(gtImg, rct, gtRect, { ink = 39 })

        if (zbleed > 0) then
            if (zbleed < 1) then
                local dmpImg = image(gtImg)
                dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                    { blend = 100.0 * (1.0 - zbleed), color = color(255, 255, 255) })
                gtImg = dmpImg
            end
            local nxt = lr + 1
            if (nxt > 29) then nxt = 29 end
            member("gradient" .. gdLayer .. tostring(nxt)).image:copyPixels(gtImg, rct, gtRect, { ink = 39 })
            nxt = lr - 1
            if (nxt < 0) then nxt = 0 end
            member("gradient" .. gdLayer .. tostring(nxt)).image:copyPixels(gtImg, rct, gtRect, { ink = 39 })
        end
    end
end

---@param gdLayer string
---@param lr number
---@param rct rect|Quad
---@param getMember string
---@param gtRect rect
---@param zbleed number
---@param blnd number?
function me.copyPixelsToEffectColor2(gdLayer, lr, rct, getMember, gtRect, zbleed, blnd)
    --global DRPxl
    if (blnd == nil) then
        blnd = 1.0
    end

    if (gdLayer ~= "C") and (blnd > 0) then
        lr = toint(lr)

        if (lr < 0) then
            lr = 0
        elseif (lr > 29) then
            lr = 29
        end
        local gtImg = member(getMember).image

        if (blnd ~= 0) and (blnd ~= nil) then
            local dmpImg = image(gtImg)
            dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                { blend = 100.0 * (1.0 - blnd), color = color(255, 255, 255) })
            gtImg = dmpImg
        end

        member("gradient" .. gdLayer .. tostring(lr)).buf:copyPixels(gtImg, rct, gtRect, { ink = 39 })

        if (zbleed > 0) then
            if (zbleed < 1) then
                local dmpImg = image(gtImg)
                dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                    { blend = 100.0 * (1.0 - zbleed), color = color(255, 255, 255) })
                gtImg = dmpImg
            end
            local nxt = lr + 1
            if (nxt > 29) then nxt = 29 end
            member("gradient" .. gdLayer .. tostring(nxt)).buf:copyPixels(gtImg, rct, gtRect, { ink = 39 })
            nxt = lr - 1
            if (nxt < 0) then nxt = 0 end
            member("gradient" .. gdLayer .. tostring(nxt)).buf:copyPixels(gtImg, rct, gtRect, { ink = 39 })
        end
    end
end


---@param gdLayer string
---@param lr number
---@param rct rect
---@param getMember string
---@param gtRect rect
---@param zbleed number
---@param blnd number?
function me.copyPixelsToRootEffectColor(gdLayer, lr, rct, getMember, gtRect, zbleed, blnd)
    --global DRPxl
    --use: copyPixelsToRootEffectColor(effect color letter from "Color" option (A, B, C=none), depth layer (from 0 to 29), final rectangle, gradient image name, source rectangle, blend modifier(from 0 to 1))
    if (blnd == VOID) then
        blnd = 1.0
    end

    if (gdLayer ~= "C") and (blnd > 0) then
        lr = toint(lr)

        if (lr < 0) then
            lr = 0
        elseif (lr > 29) then
            lr = 29
        end

        local gtImg = member(getMember).image
        if (blnd ~= 0) and (blnd ~= VOID) then
            local dmpImg = image(gtImg)
            dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                { blend = 100.0 * (1.0 - blnd), color = color(255, 255, 255) })
            gtImg = dmpImg
        end

        member("gradient" .. gdLayer .. string(lr)).image.copyPixels(gtImg, rct, gtRect, { ink = 39 })
        if (zbleed > 0) then
            if (zbleed < 1) then
                local dmpImg = image(gtImg)
                dmpImg:copyPixels(DRPxl, dmpImg.rect, rect(0, 0, 1, 1),
                    { blend = 100.0 * (1.0 - zbleed), color = color(255, 255, 255) })
                gtImg = dmpImg
            end

            for nxtAdd = 1, 3 do
                local nxt = lr + nxtAdd
                if (nxt > 29) then nxt = 29 end
                member("gradient" .. gdLayer .. tostring(nxt)).image:copyPixels(gtImg, rct, gtRect, { ink = 39 })
                nxt = lr - nxtAdd
                if (nxt < 0) then nxt = 0 end
                member("gradient" .. gdLayer .. tostring(nxt)).image:copyPixels(gtImg, rct, gtRect, { ink = 39 })
            end
        end
    end
end

---@deprecated Use the builtin function silhoutte().
---@param img Image
---@param inverted number
---@return Image
function me.makeSilhoutteFromImg(img, inverted)
    --global DRPxl
    local inv = image(img.width, img.height)
    inv:copyPixels(DRPxl, img.rect, rect(0, 0, 1, 1), { color = color(255, 255, 255) })
    inv:copyPixels(img, img.rect, img.rect, { ink = 36, color = color(255, 255, 255) })

    if (inverted == 0) then
        inv = me.makeSilhoutteFromImg(inv, 1)
    end

    return inv
end

---@deprecated Use the builtin function rotate().
---@param rct rect
---@param deg number
---@return Quad
function me.rotateToQuad(rct, deg)
    local dir = fiffigt.degToVec(deg)
    local midPnt = point((rct.left + rct.right) * 0.5, (rct.top + rct.bottom) * 0.5)
    local tlr = dir * rct.height * 0.5
    local topPnt = midPnt + tlr
    local bottomPnt = midPnt - tlr
    tlr = fiffigt.giveDirFor90degrToLine(point(-dir.x, -dir.y), dir) * rct.width * 0.5
    return quad(topPnt + tlr, topPnt - tlr, bottomPnt - tlr, bottomPnt + tlr)
end

---@param pnt1 point
---@param pnt2 point
---@return point
function me.giveDirFor90degrToLineLB(pnt1, pnt2)
    local X1 = pnt1.x
    local Y1 = pnt1.y
    local X2 = pnt2.x
    local Y2 = pnt2.y
    local Ydiff = Y1 - Y2
    local Xdiff = X1 - X2
    if (Ydiff == 0) then
        return point(0, 1)
    elseif (Xdiff == 0) then
        return point(1, 0)
    else
        local newPnt = point(1, -1.0 / (Ydiff / Xdiff))
        return newPnt / math.sqrt(newPnt.x * newPnt.x + newPnt.y * newPnt.y)
    end
end

---@param pointA point
---@param pointB point
---@return point
function me.dirVecLB(pointA, pointB)
    pointB = pointB - pointA
    if (pointB == point(0, 0)) then
        return point(0, 1)
    else
        return pointB / math.sqrt(pointB.x * pointB.x + pointB.y * pointB.y)
    end
end

---@param rct rect
---@param dir point
---@return Quad
function me.rotateToQuadLB(rct, dir)
    local midPnt = point((rct.left + rct.right) * 0.5, (rct.top + rct.bottom) * 0.5)
    local tlr = dir * rct.height * 0.5
    local topPnt = midPnt + tlr
    local bottomPnt = midPnt - tlr
    tlr = me.giveDirFor90degrToLineLB(dir * -1, dir) * rct.width * 0.5
    return quad(topPnt + tlr, topPnt - tlr, bottomPnt - tlr, bottomPnt + tlr)
end

---@param rct rect
---@param deg number
---@return Quad
function me.rotateToQuadFix(rct, deg)
    local mdpt = point((rct.left + rct.right) * 0.5, (rct.top + rct.bottom) * 0.5)
    local halfWidth = (rct.right - rct.left) / 2.0
    local halfHeight = (rct.bottom - rct.top) / 2.0
    if deg % 360.0 == 0.0 then
        return quad(point(rct.left, rct.top), point(rct.right, rct.top), point(rct.right, rct.bottom),
            point(rct.left, rct.bottom))
    elseif deg % 360.0 == 180.0 then
        return quad(point(rct.right, rct.bottom), point(rct.left, rct.bottom), point(rct.left, rct.top),
            point(rct.right, rct.top))
    elseif deg % 360.0 == 90.0 then
        return quad(mdpt + point(-halfHeight, halfWidth), mdpt + point(-halfHeight, -halfWidth),
            mdpt + point(halfHeight, -halfWidth), mdpt + point(halfHeight, halfWidth))
    elseif deg % 360.0 == 270.0 then
        return quad(mdpt + point(halfHeight, -halfWidth), mdpt + point(halfHeight, halfWidth),
            mdpt + point(-halfHeight, halfWidth), mdpt + point(-halfHeight, -halfWidth))
    else
        return me.rotateToQuad(rct, deg)
    end
end

---@param pnt point
---@param ang number
---@return point
function me.rotatePnt(pnt, ang)
    local handy = require('fiffigt')

    ang = (ang + handy.lookAtpoint(point(0, 0), pnt) - 90) * math.pi / 180.0
    local dist = math.sqrt(pnt.x * pnt.x + pnt.y * pnt.y)
    return point(math.cos(ang) * dist, math.sin(ang) * dist)
end

---@deprecated Use the builtin function rotate()
---@param rct rect
---@param pt point
---@param ang number
---@return Quad
function me.rotateRectAroundPoint(rct, pt, ang)
    local tl = me.rotatePnt(point(rct.left, rct.top), ang)
    local tr = me.rotatePnt(point(rct.right, rct.top), ang)
    local br = me.rotatePnt(point(rct.right, rct.bottom), ang)
    local bl = me.rotatePnt(point(rct.left, rct.bottom), ang)
    return quad(pt + tl, pt + tr, pt + br, pt + bl)
end

---@param qd Quad
---@return Quad
function me.flipQuadH(qd)
    return quad(qd.topright, qd.topleft, qd.bottomleft, qd.bottomright)
end

---@param qd Quad
---@return Quad
function me.flipQuadV(qd)
    return quad(qd.bottomright, qd.bottomleft, qd.topleft, qd.topright)
end

---@param mem string
---@param pnt point
---@param dp number
---@param cl string
function me.pasteShortCutHole(mem, pnt, dp, cl)
    --global gLEProps, gLOprops, gCameraProps, gCurrentRenderCamera, gRenderCameraTilePos, gRenderCameraPixelPos
    local rct = me.giveMiddleOfTile(pnt) - (gRenderCameraTilePos * 20) - gRenderCameraPixelPos
    rct = me.depthPnt(rct, dp)
    rct = rect(rct, rct) + rect(-10, -10, 10, 10)
    local idString = ""
    for _, dr in ipairs({ point(-1, 0), point(0, -1), point(1, 0), point(0, 1) }) do
        if (pnt + dr):inside(rect(1, 1, gLOprops.size.x, gLOprops.size.y)) then
            matProp = gLEProps.matrix[pnt.x + dr.x][pnt.y + dr.y][1][2]
            if (matProp:getPos(5) > 0) or (matProp:getPos(4) > 0) then
                idString = idString .. "1"
            else
                idString = idString .. "0"
            end
        else
            idString = idString .. "0"
        end
    end
    local ps = list({ "0101", "1010", "1111", "1100", "0110", "0011", "1001", "1110", "0111", "1011", "1101", "0000" })
    :getPos(idString)
    local clL
    if (cl == "BORDER") then
        clL = { { color(255, 0, 0), point(-1, 0) }, { color(255, 0, 0), point(0, -1) }, { color(255, 0, 0), point(-1, -1) }, { color(255, 0, 0), point(-2, 0) }, { color(255, 0, 0), point(0, -2) }, { color(255, 0, 0), point(-2, -2) }, { color(0, 0, 255), point(1, 0) }, { color(0, 0, 255), point(0, 1) }, { color(0, 0, 255), point(1, 1) }, { color(0, 0, 255), point(2, 0) }, { color(0, 0, 255), point(0, 2) }, { color(0, 0, 255), point(2, 2) } }
    else
        clL = list(list({ cl, point(0, 0) }))
    end
    local shortCutsGraf = member("shortCutsGraf").image
    local memImage = member(mem).image
    local getShCtRect = rect(20 * (ps - 1), 1, 20 * ps, 21)
    for _, c in ipairs(clL) do
        memImage:copyPixels(shortCutsGraf, rct + rect(c[2], c[2]), getShCtRect, { ink = 36, color = c[1] })
    end
end

---@param sze point
---@param addTilesLeft number
---@param addTilesTop number
function me.resizeLevel(sze, addTilesLeft, addTilesTop) --nt
    --global gLEProps, gLOprops, gTEprops, gEEprops, gPEprops, gCameraProps
    local newMatrix = list()
    local newTEmatrix = list()

    for q = 1, sze.x + addTilesLeft do
        local ql = list()
        for c = 1, sze.y + addTilesTop do
            local adder
            if (q - addTilesLeft <= #gLEProps.matrix) and (c - addTilesTop <= #gLEProps.matrix[1]) and (q - addTilesLeft > 0) and (c - addTilesTop > 0) then
                adder = gLEProps.matrix[q - addTilesLeft][c - addTilesTop]
            else
                adder = list({ list({ 1, list() }), list({ 1, list() }), list({ 1, list() }) })
            end
            ql:add(adder)
        end
        newMatrix:add(ql)
    end

    for q = 1, sze.x + addTilesLeft do
        local ql = list()
        for c = 1, sze.y + addTilesTop do
            local adder
            if (q + addTilesLeft <= #gTEprops.tlMatrix) and (c + addTilesTop <= #gTEprops.tlMatrix[1]) and (q - addTilesLeft > 0) and (c - addTilesTop > 0) then
                adder = gTEprops.tlMatrix[q - addTilesLeft][c - addTilesTop]

                -- fix for tiles during resize
                for l = 1, 3 do
                    if adder[l].tp == "tileBody" then
                        local newPt = adder[l].data[1] + point(addTilesLeft, addTilesTop)
                        adder[l].data[1] = newPt
                        if newPt.x < 1 or newPt.x > sze.x + addTilesLeft or newPt.y < 1 or newPt.y > sze.y + addTilesTop then
                            adder[l] = { tp = "default", data = 0 }
                        end
                    end
                end
            else
                adder = list({ map({ tp = "default", data = 0 }), map({ tp = "default", data = 0 }), map({ tp = "default", data = 0 }) })
            end
            ql:add(adder)
        end
        newTEmatrix:add(ql)
    end


    for _, effect in ipairs(gEEprops.effects) do
        local newEffMtrx = list()

        for q = 1, sze.x + addTilesLeft do
            local ql = list()
            for c = 1, sze.y + addTilesTop do
                local adder
                if (q + addTilesLeft <= #effect.mtrx) and (c + addTilesTop <= #effect.mtrx[1]) and (q - addTilesLeft > 0) and (c - addTilesTop > 0) then
                    adder = effect.mtrx[q - addTilesLeft][c - addTilesTop]
                else
                    adder = 0
                end
                ql.add(adder)
            end
            newEffMtrx.add(ql)
        end

        effect.mtrx = newEffMtrx
    end

    for _, prop in ipairs(gPEprops.props) do
        for q = 1, 4 do
            prop[4][q] = prop[4][q] + 16 * point(addTilesLeft, addTilesTop)
        end

        if prop[5]["points"] ~= nil then
            for q = 1, #prop[5].points do
                prop[5].points[q] = prop[5].points[q] + 20 * point(addTilesLeft, addTilesTop)
            end
        end
    end

    for q = 1, #gCameraProps.cameras do
        gCameraProps.cameras[q] = gCameraProps.cameras[q] + point(20 * addTilesLeft, 20 * addTilesTop)
    end


    gLEProps.matrix = newMatrix
    gTEprops.tlMatrix = newTEmatrix
    gLOprops.size = sze + point(addTilesLeft, addTilesTop) --- (rmvTilesLeft, rmvTilesTop)

    --global gLASTDRAWWASFULLANDMINI
    gLASTDRAWWASFULLANDMINI = 0

    local oldimg = image(member("lightImage").image)
    member("lightImage").image = image((gLOprops.size.x * 20) + 300, (gLOprops.size.y * 20) + 300, 1)
    member("lightImage").image:copypixels(oldimg, oldimg.rect, oldimg.rect)
end

function me.ResetgEnvEditorProps()
    --global gEnvEditorProps
    gEnvEditorProps = map({ waterLevel = -1, waterInFront = 1, waveLength = 60, waveAmplitude = 5, waveSpeed = 10 })
end

function me.resetPropEditorProps()
    --global gPEprops
    gPEprops = map({ props = list(), lastKeys = list(), keys = list(), workLayer = 1, lstMsPs = point(0, 0), pmPos =
    point(1, 1), pmSavPosL=list(), propRotation = 0, propStretchX = 1, propStretchY = 1, propFlipX = 1, propFlipY = 1, depth = 0, color = 0 })
end

---@param vec point
---@return number
function me.vecToRadLB(vec)
    if (vec.x == 0) then
        if (vec.y < 0) then
            return -math.pi / 2.0
        else
            return math.pi / 2.0
        end
    elseif (vec.x < 0) then
        return math.atan(vec.y / vec.x) - math.pi
    else
        return math.atan(vec.y / vec.x)
    end
end

return me
