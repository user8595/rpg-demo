local lk, lg, lm, lw = love.keyboard, love.graphics, love.mouse, love.window
local lt, le = love.timer, love.event
local next = next
local json = require("libs.json")
local table_clear = require("table.clear")
local wWd, wHg, gWd, gHg = lg.getWidth(), lg.getHeight(), 640, 480
local isDebug = true

if arg[2] == "debug" then
    isDebug = true
else
    isDebug = false
end

local ply = {
    x = 0,
    y = 0,
    w = 20,
    h = 20,
    vx = 200,
    vy = 200,
    face = "down",
    arrTimeout = 3,
    arrAlp = 1,
    isAfter = false,
}

local pL, pR, pT, pB = ply.x, ply.x + ply.w, ply.y, ply.y + ply.h

local plyOArea = {
    x = ply.x - 20,
    y = ply.y - 20,
    w = ply.w * 3,
    h = ply.h * 3,
}

local plyAImg = {}
local objField = {}
local objCount = 0
local plyAimgCount = 0

-- dalogue
local dialObj = {}
local isDialog = false
--TODO: Add dialogue choices
local dialPg = 1

--TODO: Set to true if dialogue finishes instead of relying on a timer (typewriter effect)
local isDialogProg = false
local isDialogTimeout = false
local dTimeout = 0
local dProgTime = 0
-- alpha values for dialogue frame
local dFrmAlp = 0
local dFrmBGAlp = 0
local dArrAlp = 0

--TODO: Add game menu
local isMenu = false
--TODO: Add animation to menu instead of fade in-out
local mAlp = 0
local mAlpOvr = 0

local objNpc = {}
-- field obj
local fW, fH, oW, oH = 100, 100, 20, 20
for y = 1, fH, 1 do
    for x = 1, fW, 1 do
        table.insert(objField, { x = 20 + oW * (x - 1), y = 20 + oH * (y - 1), w = oW, h = oH, a = 1 })
    end
end

-- npcs
table.insert(objNpc,
    {
        x = 0,
        y = -60,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt =
        { "This is a text. Hello world!" },
        name = "Entity 1"
    })

table.insert(objNpc,
    {
        x = 60,
        y = -60,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt = { "I'm a block." },
        name =
        "Entity 2"
    })

table.insert(objNpc,
    {
        x = 120,
        y = -60,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt =
        { "Does it feel weird that we're just in a simulation?" },
        name = "Entity 3"
    })

table.insert(objNpc,
    {
        x = 240,
        y = -60,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt =
        { "I should probably rest now.." },
        name = "Entity 4"
    })

table.insert(objNpc,
    {
        x = 20,
        y = 3000,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt =
        { "You really went this far huh." },
        name = "Entity 5"
    })

table.insert(objNpc,
    {
        x = 1760,
        y = 1760,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt =
        { "This place is huge." },
        name = "Entity 6"
    })
table.insert(objNpc,
    {
        x = 800,
        y = -60,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt = { "I can talk now!", "I can even continue what i want to say!" },
        name = "Entity 7"
    })
table.insert(objNpc,
    {
        x = 2400,
        y = 3000,
        w = 20,
        h = 20,
        colLine = { 1, 0.5, 0.7 },
        colFill = { 0.8, 0.2, 0.5 },
        txt = { "It's so empty here..", "What should we do instead of standing here?", "Only if i could ask you something.." },
        name = "Entity 8"
    })

function love.load()
    lg.setDefaultFilter("nearest", "nearest")
    lm.setVisible(false)

    arr = lg.newImage("/arr.png")
end

-- use on npc table loop
function newDialog(tabDial, npcObj)
    if not isDialog and not isDialogTimeout then
        if not isDialogProg then
            table.insert(tabDial, { txt = npcObj.txt, name = npcObj.name })
        end
        isDialog = true
        isDialogProg = true
        print("triggered dialogue" .. " (isDialog: " .. tostring(isDialog) .. ")")
    end
end

function love.keypressed(k)
    if k == "escape" then
        le.quit(0)
        print("exit game")
    end
    if k == "f11" then
        if not lw.getFullscreen() then
            lw.setFullscreen(true)
        else
            lw.setFullscreen(false)
        end
    end
    if k == "r" then
        ply.x, ply.y = 0, 0
    end
    if k == "f4" then
        if not isDebug then
            isDebug = true
        else
            isDebug = false
        end
    end
    if k == "k" then
        if not isMenu then
            for _, npc in ipairs(objNpc) do
                --TODO: Consider diagonals?
                if ply.face == "up" then
                    if pR > npc.x - 10 and
                        pL < npc.x + npc.w + 10 and
                        pT < npc.y + npc.h + 10 and
                        pB > npc.y + npc.h then
                        newDialog(dialObj, npc)
                    end
                elseif ply.face == "down" then
                    if pR > npc.x - 10 and
                        pL < npc.x + npc.w + 10 and
                        pT < npc.y and
                        pB > npc.y - 10 then
                        newDialog(dialObj, npc)
                    end
                elseif ply.face == "left" then
                    if pR > npc.x + npc.w and
                        pL < npc.x + npc.w + 10 and
                        pT < npc.y + npc.h + 10 and
                        pB > npc.y - 10 then
                        newDialog(dialObj, npc)
                    end
                elseif ply.face == "right" then
                    if pR > npc.x - 10 and
                        pL < npc.x and
                        pT < npc.y + npc.h + 10 and
                        pB > npc.y - 10 then
                        newDialog(dialObj, npc)
                    end
                end
            end
        end
        if not isDialogProg and isDialog then
            for _, dial in ipairs(dialObj) do
                if #dial.txt > dialPg then
                    dialPg = dialPg + 1
                    dProgTime = 0
                    dArrAlp = 0
                    isDialogProg = true
                    print("did it work?")
                else
                    isDialog = false
                    isDialogTimeout = true
                    dialPg = 1
                    table_clear(dialObj)
                    print("end of dialogue" .. " (isDialog: " .. tostring(isDialog) .. ")")
                end
            end
        end
    end
    if k == "j" then
        if not isDialog then
            if not isMenu then
                isMenu = true
                print("opened menu" .. " (isMenu: " .. tostring(isMenu) .. ")")
            else
                isMenu = false
                print("closed menu" .. " (isMenu: " .. tostring(isMenu) .. ")")
            end
        end
    end
    if k == "l" then
        if isMenu then
            isMenu = false
        end
    end
end

function love.resize(w, h)
    wWd, wHg = w, h
end

function love.update(dt)
    pL, pR, pT, pB = ply.x, ply.x + ply.w, ply.y, ply.y + ply.h
    plyOArea.x, plyOArea.y = ply.x - 20, ply.y - 20

    if not isDialog and not isMenu then
        if lk.isDown("w") then
            ply.y = ply.y - dt * ply.vy
            ply.face = "up"
        end
        if lk.isDown("s") then
            ply.y = ply.y + dt * ply.vy
            ply.face = "down"
        end
        if lk.isDown("a") then
            ply.x = ply.x - dt * ply.vx
            ply.face = "left"
        end
        if lk.isDown("d") then
            ply.x = ply.x + dt * ply.vx
            ply.face = "right"
        end

        if lk.isDown("l") then
            ply.vx, ply.vy = 350, 350
            ply.isAfter = true
        else
            ply.vx, ply.vy = 200, 200
            ply.isAfter = false
        end

        if lk.isDown("w") or lk.isDown("a") or lk.isDown("s") or lk.isDown("d") then
            ply.arrTimeout = 0
        else
            if ply.arrTimeout < 3 then
                ply.arrTimeout = ply.arrTimeout + dt
            end
        end

        if ply.arrTimeout >= 3 then
            if ply.arrAlp < 1 then
                ply.arrAlp = ply.arrAlp + dt * 3
            end
        else
            if ply.arrAlp > 0 then
                ply.arrAlp = ply.arrAlp - dt * 7
            end
        end
    else
        ply.arrTimeout = 0
        if ply.arrAlp > 0 then
            ply.arrAlp = ply.arrAlp - dt * 7
        end
    end

    -- game field loop
    if not isMenu then
        if ply.isAfter then
            table.insert(plyAImg, { x = ply.x, y = ply.y, w = ply.w, h = ply.h, a = 0.2 })
        end

        for i, pImg in ipairs(plyAImg) do
            pImg.a = pImg.a - dt * 0.35

            plyAimgCount = i

            if pImg.a < 0 then
                table.remove(plyAImg, i)
            end
        end

        if next(plyAImg) == nil then
            plyAimgCount = 0
        end
        if next(objField) == nil then
            objCount = 0
        end

        for i, obj in ipairs(objField) do
            if plyOArea.x < obj.x + obj.w and
                plyOArea.x + plyOArea.w > obj.x and
                plyOArea.y + plyOArea.h > obj.y and
                plyOArea.y < obj.y + obj.h then
                if obj.a > 0 then
                    obj.a = obj.a - dt * 20
                end
            else
                if obj.a < 1 then
                    obj.a = obj.a + dt * 2
                end
            end
        end
    end

    if isDialogProg then
        dProgTime = dProgTime + dt
        if dProgTime > 0.5 then
            isDialogProg = false
            dProgTime = 0
        end
    else
        if dArrAlp < 1 and isDialog then
            dArrAlp = dArrAlp + dt * 5
        else
            if dArrAlp > 0 then
                dArrAlp = dArrAlp - dt * 5
            end
        end
    end

    if isDialog then
        if dFrmAlp < 1 then
            dFrmAlp = dFrmAlp + dt * 5
        end
        if dFrmBGAlp < 0.95 then
            dFrmBGAlp = dFrmBGAlp + dt * 4.75
        end
    else
        if dFrmAlp > 0 then
            dFrmAlp = dFrmAlp - dt * 5
        end
        if dFrmBGAlp > 0 then
            dFrmBGAlp = dFrmBGAlp - dt * 4.75
        end
    end

    if isDialogTimeout then
        dTimeout = dTimeout + dt
        print("dialogue timeout" .. " (dTimeout: " .. dTimeout .. ")")
        if dTimeout > 0.2 then
            isDialogTimeout = false
            dTimeout = 0
            print("end dialogue timeout")
        end
    end

    if isMenu then
        if mAlp < 1 then
            mAlp = mAlp + dt * 10
        end
        if mAlpOvr < 0.5 then
            mAlpOvr = mAlpOvr + dt * 5
        end
    else
        if mAlp > 0 then
            mAlp = mAlp - dt * 5
        end
        if mAlpOvr > 0 then
            mAlpOvr = mAlpOvr - dt * 2.5
        end
    end
end

function love.draw()
    -- fields of hopes and dreams
    lg.push()
    lg.translate(-ply.x + wWd / 2 - ply.w, -ply.y + wHg / 2 - ply.h)
    for i, fld in ipairs(objField) do
        if i % 2 == 1 then
            lg.setColor(1, 0, 0, fld.a)
        else
            lg.setColor(1, 1, 1, fld.a)
        end
        lg.rectangle("fill", fld.x, fld.y, fld.w, fld.h)
        objCount = i
    end
    for _, npc in ipairs(objNpc) do
        lg.setColor(npc.colFill)
        lg.rectangle("fill", npc.x, npc.y, npc.w, npc.h)
    end
    lg.setColor(1, 1, 1)
    lg.print("it feels cold here.....", 20, 0)

    for _, pImg in ipairs(plyAImg) do
        lg.setColor(1, 0.5, 0.5, pImg.a)
        lg.rectangle("fill", pImg.x, pImg.y, pImg.w, pImg.h)
        lg.setColor(1, 0.75, 0.7, pImg.a)
        lg.rectangle("line", pImg.x, pImg.y, pImg.w, pImg.h)
        lg.setColor(1, 1, 1, pImg.a)
        if ply.face == "up" then
            lg.rectangle("line", pImg.x, pImg.y, pImg.w, pImg.h - 19)
        end
        if ply.face == "down" then
            lg.rectangle("line", pImg.x, pImg.y + 18, pImg.w, pImg.h - 19)
        end
        if ply.face == "left" then
            lg.rectangle("line", pImg.x, pImg.y, pImg.w - 19, pImg.h)
        end
        if ply.face == "right" then
            lg.rectangle("line", pImg.x + 18, pImg.y, pImg.w - 19, pImg.h)
        end
    end

    lg.setColor(1, 0.5, 0.5)
    lg.rectangle("fill", ply.x, ply.y, ply.w, ply.h)
    lg.setColor(1, 0.75, 0.7)
    lg.rectangle("line", ply.x, ply.y, ply.w, ply.h)
    lg.setColor(1, 1, 1, 1)
    if ply.face == "up" then
        lg.rectangle("line", ply.x, ply.y, ply.w, ply.h - 19)
    end
    if ply.face == "down" then
        lg.rectangle("line", ply.x, ply.y + 18, ply.w, ply.h - 19)
    end
    if ply.face == "left" then
        lg.rectangle("line", ply.x, ply.y, ply.w - 19, ply.h)
    end
    if ply.face == "right" then
        lg.rectangle("line", ply.x + 18, ply.y, ply.w - 19, ply.h)
    end
    lg.setColor(1, 1, 1, ply.arrAlp)
    lg.draw(arr, ply.x - 20, ply.y + 20, -math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 20, ply.y + 40, -math.pi, 3.5, 3.5)
    lg.draw(arr, ply.x + 39, ply.y + 2, math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 1, ply.y - 19, 0, 3.5, 3.5)

    -- field of debug and bytes
    lg.setColor(1, 1, 1, 1)
    if isDebug then
        lg.setColor(1, 1, 1, 1)

        lg.rectangle("line", plyOArea.x, plyOArea.y, plyOArea.w, plyOArea.h)
        for _, npc in ipairs(objNpc) do
            if ply.face == "up" then
                lg.setColor(npc.colLine)
                lg.rectangle("line", npc.x - 10, npc.y + npc.h, npc.w + 20, npc.h - 10)
            end
            if ply.face == "down" then
                lg.setColor(npc.colLine)
                lg.rectangle("line", npc.x - 10, npc.y - 10, npc.w + 20, npc.h - 10)
            end
            if ply.face == "left" then
                lg.setColor(npc.colLine)
                lg.rectangle("line", npc.x + 20, npc.y - 10, npc.w - 10, npc.h + 20)
            end
            if ply.face == "right" then
                lg.setColor(npc.colLine)
                lg.rectangle("line", npc.x - 10, npc.y - 10, npc.w - 10, npc.h + 20)
            end
        end
    end
    lg.pop()

    -- game ui
    -- dialog
    lg.setColor(1, 1, 1, dFrmAlp)
    lg.rectangle("line", 20, wHg - 160, 240, 40)
    lg.setColor(0, 0, 0, dFrmBGAlp)
    lg.rectangle("fill", 20, wHg - 160, 240, 40)
    lg.setColor(1, 1, 1)
    for _, dial in ipairs(dialObj) do
        lg.printf(dial.name, 20, wHg - 148, 240, "center")
    end

    lg.setColor(1, 1, 1, dFrmAlp)
    lg.rectangle("line", 0, wHg - 120, wWd, 120)
    lg.setColor(0, 0, 0, dFrmBGAlp)
    lg.rectangle("fill", 0, wHg - 120, wWd, 120)
    lg.setColor(1, 1, 1, 1)
    for _, dial in ipairs(dialObj) do
        lg.print(dial.txt[dialPg], 20, wHg - 100)
    end
    lg.setColor(1, 1, 1, dArrAlp)
    lg.draw(arr, wWd - 20, wHg - 15, -math.pi, 3.5, 3.5)

    -- menu
    lg.setColor(0, 0, 0, mAlpOvr)
    lg.rectangle("fill", 0, 0, wWd, wHg)

    -- ply info
    lg.setColor(0, 0, 0, mAlp)
    lg.rectangle("fill", 40, wHg - 180, 240, 140)
    lg.setColor(1, 1, 1, mAlp)
    lg.rectangle("line", 40, wHg - 180, 240, 140)

    -- main menu
    lg.setColor(0, 0, 0, mAlp)
    lg.rectangle("fill", wWd - 240, 40, 200, wHg - 80)
    lg.setColor(1, 1, 1, mAlp)
    lg.rectangle("line", wWd - 240, 40, 200, wHg - 80)

    if isDebug then
        lg.setColor(1, 1, 1, 1)
        lg.printf(
            ply.x ..
            "\n" ..
            ply.y ..
            "\n" ..
            ply.arrTimeout ..
            "\n" ..
            ply.arrAlp ..
            "\n" ..
            plyOArea.x ..
            "\n" ..
            plyOArea.y .. "\n" .. dProgTime .. "\n" .. dTimeout .. "\n" .. dArrAlp .. "\n" .. ply.face .. "\n" .. dialPg,
            0,
            10,
            wWd - 10, "right")
        lg.printf(
            lt.getFPS() ..
            " FPS\n" ..
            string.format("%.2f", lg.getStats().texturememory / 1024) ..
            " MB" .. "/" .. lg.getStats().images .. " imgs" .. "/" .. lg.getStats().drawcalls .. " drw\n" ..
            objCount .. " objs\n" .. plyAimgCount .. " objs", 10, 10, wWd, "left")
    end
end
