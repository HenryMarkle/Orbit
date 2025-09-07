-- global projects, ldPrps, gLOADPATH, showControls, INT_EXIT, INT_EXRD, gFSLastTm, gFSFlag

local me = {}

function exitFrame()
    local utils = require('comEditorUtils')

    INT_EXIT = utils.getStringConfig("Exit button")
    INT_EXRD = utils.getStringConfig("Exit render button")
    showControls = utils.getBoolConfig("Show controls")
    gFSLastTm = _system.milliseconds
    gFSFlag = false
    if utils.checkMinimize() then
        _player.appMinimize()
    end
    if utils.checkExit() then
        _player.quit()
    end

    projects = list()

    local pth = moviePath .. "LevelEditorProjects" .. dirSeparator
    for _, f in ipairs(gLOADPATH) do
        pth = pth .. dirSeparator .. f
    end

    local fileList = list()
    local i = 1
    repeat
        local n = getNthFileNameInFolder(pth, i)
        if n == "" then
            break
        end

        if atChar(n, #n - 3) ~= "." then
            projects:add("#" .. n)
        else
            --   fileList:add(n)
            table.insert(fileList, n)
        end
        i = i + 1
    until false




    for _, l in ipairs(fileList) do
        if string.sub(l, #l - 3) == ".txt" then
            projects:add(string.sub(l, 1, #l - 4))
        end
    end

    local txt = "Use the arrow keys to select a project. Use enter to open it."
    --   put RETURN after txt
    txt = txt .. RETURN
    for _, f in ipairs(gLOADPATH) do
        -- put f .. "/" after txt
        txt = txt .. "/"
    end
    -- put RETURN after txt
    -- put RETURN after txt
    txt = txt .. RETURN
    txt = txt .. RETURN

    for _, q in ipairs(projects) do
        -- put q after txt
        -- put RETURN after txt

        txt = txt .. q .. RETURN
    end

    ldPrps = map({ lstUp = 1, lstDwn = 1, lft = 1, rgth = 1, currProject = 1, listScrollPos = 1, listShowTotal = 30 })

    member("ProjectsL").text = txt

    member("PalName").text =
    "Press 'N' to create a new level. Use left and right arrows to step in and out of subfolders"
end

return me
