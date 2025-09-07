local me = {}

---@param images table
function me.sendPreview(images)
    
end

function me.shouldSendPreview() return true end

function me.drawPreview()
    clear()

    local preview = image(1400, 800)

    clear(preview)

    for i = 29, 0, -1 do
        local offset = point(29 - i - 5, 29 - i - 5)

        preview:copyPixels(member('layer'..i).image, rect(-29, -29, 1400, 800)+offset, rect(300, 200, 1700, 1000), {ink=36})
        preview:copyPixels(member("pxl").image, rect(0, 0, 1402, 802), rect(0, 0, 1, 1), { color=color(255,255,255), blend=0.03 })
    end

    draw(preview, 0, 0)
end

function me.drawPreview2()
    clear()

    local preview = image(1400, 800)

    clear(preview)

    for i = 29, 0, -1 do
        local offset = point(29 - i - 5, 29 - i - 5)

        preview:copyPixels(member('layer'..i).buf, rect(-29, -29, 1400, 800)+offset, rect(300, 200, 1700, 1000), {ink=36})
        preview:copyPixels(member("pxl").image, rect(0, 0, 1402, 802), rect(0, 0, 1, 1), { color=color(255,255,255), blend=0.03 })
    end

    draw(preview, 0, 0)
end

local doneSetup = false
local currentMaterialLayer = 1
local doneSetupMaterials = false
local doneMaterials = false
local donePropsStart = false
local doneProps = false

local doneEffectsStart = false
local doneEffects = false

local doneRendering = false

clear()

function me.exitFrame()
    if doneRendering then
        return
    end

    if not doneSetup then
        require('startUp').exitFrame()
        require('loadLevel').loadLevel('World' .. dirSeparator .. 'CC' .. dirSeparator .. 'CC_A02')
        -- require('loadLevel').loadLevel('ropes')
        require('renderStart').exitFrame()
        
        afterEffects = 0
        doneSetup = true
    end


    -- for ix,x in ipairs(gLEProps.matrix) do
    --     for iy,y in ipairs(x) do
    --         if y[1][1] ~= 0 then print('['..ix..', '..iy..'] = '..y[1][1]) end
    --     end
    -- end

    do -- setting up camera
    
        ---@type point
        local camera = gCameraProps.cameras[1]

        gCurrentRenderCamera = 0
        
        gRenderCameraTilePos = point(
            toint((camera.x/20) - 0.49999),
            toint((camera.y/20) - 0.49999)
        )

        gRenderCameraPixelPos = camera - (gRenderCameraTilePos * 20)
        gRenderCameraPixelPos.x = toint(gRenderCameraPixelPos.x)
        gRenderCameraPixelPos.y = toint(gRenderCameraPixelPos.y)

        gRenderCameraTilePos = gRenderCameraTilePos + point(-15, -10)
    end

    if not doneSetupMaterials then -- render layers
        local cols = 100
        local rows = 60

        for i = 0, 29 do
            member('layer'..i).image = image(cols*20, rows*20)
            member('gradientA'..i).image = image(cols*20, rows*20)
            member('gradientB'..i).image = image(cols*20, rows*20)
            member('layer'..i..'dc').image = image(cols*20, rows*20)
        end

        member('rainBowMask').image = image(cols*20, rows*20)

        gTinySignsDrawn = false
        gRenderTrashProps = list()

        member('finalImage').image = image(cols*20, rows*20)

        randomSeed = gLOprops.tileSeed
        
    end

    if not doneMaterials then
        doneSetupMaterials = true

        local levelRendering = require('levelRendering')
    
        if currentMaterialLayer < 4 then
            levelRendering.setUpLayer(currentMaterialLayer)
            currentMaterialLayer = currentMaterialLayer + 1
        else
            doneMaterials = true
        end


        gLastImported = ''

        c = 1

        me.drawPreview()
        return
    end

    if not donePropsStart then
        require('renderPropsStart').exitFrame()
        c = 1
        donePropsStart = true
    end

    if not doneProps then -- props pre-effects
        if keepLooping then require('renderProps').newFrame()
        else doneProps = true end

        me.drawPreview()
        return
    end

    if not doneEffectsStart then
        require('renderEffectsStart').exitFrame()

        for i = 0, 29 do
            member("layer" .. i).buf = imagebuf(member("layer" .. i).image)
            member("gradientA" .. i).buf = imagebuf(member("gradientA" .. i).image)
            member("gradientB" .. i).buf = imagebuf(member("gradientB" .. i).image)
            member("layer" .. i .. "dc").buf = imagebuf(member("layer" .. i .. "dc").image)
        end

        doneEffectsStart = true
        return
    end

    if not doneEffects then
        local script = require('renderEffects')
        
        -- local start = os.clock()
        if keepLooping then script.newFrame()
        else doneEffects = true end
        -- print('Loop took ' .. (os.clock() - start) .. ' seconds')

        me.drawPreview2()
        
        return
    end
    
    for i = 0, 29 do
        member("layer" .. i).image:copyPixels(member("layer" .. i).buf, member("layer" .. i).buf.rect, member("layer" .. i).buf.rect)
        member("gradientA" .. i).image:copyPixels(member("gradientA" .. i).buf, member("gradientA" .. i).buf.rect, member("gradientA" .. i).buf.rect)
        member("gradientB" .. i).image:copyPixels(member("gradientB" .. i).buf, member("gradientB" .. i).buf.rect, member("gradientB" .. i).buf.rect)
        member("layer" .. i .. "dc").image:copyPixels(member("layer" .. i .. "dc").buf, member("layer" .. i .. "dc").buf.rect, member("layer" .. i .. "dc").buf.rect)
    end
    
    me.drawPreview()

    doneRendering = true

    print('finished rendering')
    -- _player.quit()
end

return me