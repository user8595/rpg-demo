local lk, lg = love.keyboard, love.graphics
local next = next
local json = require("libs.json")
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

--TODO: Implement dialogue function
-- dalogue
local dialObj = {}
local dialTxt = json.decode(love.filesystem.read("dialogue.json"))
local isDialog = false

--TODO: Implement dialogue progress confirm (or not instantly close dialogue box)
local isDIalogProg = false

local objNpc = {}

-- field obj
local fW, fH, oW, oH = 100, 100, 20, 20
for y = 1, fH, 1 do
    for x = 1, fW, 1 do
        table.insert(objField, { x = 20 + oW * (x - 1), y = 20 + oH * (y - 1), w = oW, h = oH, a = 1 })
    end
end

table.insert(objNpc,
    { x = 0, y = -60, w = 20, h = 20, colLine = { 1, 0.5, 0.7 }, colFill = { 0.8, 0.2, 0.5 }, txt = dialTxt.ent_1 })

function love.load()
    lg.setDefaultFilter("nearest", "nearest")
    arr = lg.newImage("/arr.png")
end

function love.keypressed(k)
    if k == "escape" then
        love.event.quit(0)
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
        for _, npc in ipairs(objNpc) do
            if pR > npc.x - 10 and
                pL < npc.x + npc.w + 10 and
                pT < npc.y + npc.h + 10 and
                pB > npc.y - 10 then
                if not isDialog then
                    isDialog = true
                else
                    isDialog = false
                end
            end
        end
    end
end

function love.resize(w, h)
    wWd, wHg = w, h
end

function love.update(dt)
    pL, pR, pT, pB = ply.x, ply.x + ply.w, ply.y, ply.y + ply.h
    plyOArea.x, plyOArea.y = ply.x - 20, ply.y - 20

    if not isDialog then
        if lk.isDown("w") then
            ply.y = ply.y - dt * ply.vy
        end
        if lk.isDown("s") then
            ply.y = ply.y + dt * ply.vy
        end
        if lk.isDown("a") then
            ply.x = ply.x - dt * ply.vx
        end
        if lk.isDown("d") then
            ply.x = ply.x + dt * ply.vx
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
                obj.a = obj.a + dt * 5
            end
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
    end
    
    lg.setColor(1, 0.5, 0.5)
    lg.rectangle("fill", ply.x, ply.y, ply.w, ply.h)
    lg.setColor(1, 0.75, 0.7)
    lg.rectangle("line", ply.x, ply.y, ply.w, ply.h)
    
    lg.setColor(1, 1, 1, ply.arrAlp)
    lg.draw(arr, ply.x - 20, ply.y + 20, -math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 20, ply.y + 40, -math.pi, 3.5, 3.5)
    lg.draw(arr, ply.x + 39, ply.y + 2, math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 1, ply.y - 19, 0, 3.5, 3.5)
    
    -- debug
    lg.setColor(1, 1, 1, 1)
    if isDebug then
        lg.setColor(1, 1, 1, 1)
        lg.rectangle("line", plyOArea.x, plyOArea.y, plyOArea.w, plyOArea.h)
        for _, npc in ipairs(objNpc) do
            lg.setColor(npc.colLine)
            lg.rectangle("line", npc.x - 10, npc.y - 10, npc.w + 20, npc.h + 20)
        end
    end
    lg.pop()
    
    if isDialog then
        lg.setColor(1, 1, 1, 1)
        lg.rectangle("line", 0, wHg - 120, wWd, 120)
        lg.setColor(0, 0, 0, 0.75)
        lg.rectangle("fill", 0, wHg - 120, wWd, 120)
        lg.setColor(1, 1, 1, 1)
        for _, dial in ipairs(dialObj) do
            lg.print(dial.txt, 20, wHg - 100)
        end
    end

    if isDebug then
        lg.setColor(1, 1, 1, 1)
        lg.printf(
            ply.x ..
            "\n" .. ply.y .. "\n" .. ply.arrTimeout .. "\n" .. ply.arrAlp .. "\n" .. plyOArea.x .. "\n" .. plyOArea.y, 0,
            10,
            wWd - 10, "right")
        lg.printf(
            love.timer.getFPS() ..
            " FPS\n" ..
            string.format("%.2f", lg.getStats().texturememory / 1024) ..
            " MB" .. "/" .. lg.getStats().images .. " imgs" .. "/" .. lg.getStats().drawcalls .. " drw\n" ..
            objCount .. " objs\n" .. plyAimgCount .. " objs", 10, 10, wWd, "left")
    end
end
