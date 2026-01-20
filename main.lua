local lk, lg, lm, lw = love.keyboard, love.graphics, love.mouse, love.window
local lt, le = love.timer, love.event
local next = next
local table_clear = require("table.clear")
local wWd, wHg, gWd, gHg = lg.getWidth(), lg.getHeight(), 640, 480
local isDebug = true

local sc = 1.5

-- TODO: Replace with monogram
-- fonts
local fonts = {
    tooltip = lg.newFont("/assets/fonts/monogram-extended.TTF", 22),
    dialName = lg.newFont("/assets/fonts/monogram-extended.TTF", 28),
    ui = lg.newFont("/assets/fonts/PixeloidSans.ttf", 14),
}

fonts.ui:setLineHeight(1.2)

for _, f in pairs(fonts) do
    f:setFilter("nearest", "nearest", 4)
end

if arg[2] == "debug" then
    isDebug = true
else
    isDebug = false
end

local settings = {
    showTooltip = true
}

local keys = {
    up = "w",
    down = "s",
    left = "a",
    right = "d",
    menu = "j",
    confirm = "k",
    cancel = "l",
}

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
    dial = {
        e_10 = false,
        e_8_base = false,
        e_8_b1 = false
    }
}

local pL, pR, pT, pB = ply.x, ply.x + ply.w, ply.y, ply.y + ply.h

local plyOArea = {
    x = ply.x - ply.w,
    y = ply.y - ply.w,
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
-- dialog page
local dialPg = 1

--TODO: Set to true if dialogue finishes instead of relying on a timer (typewriter effect)
local isDialogProg = false
-- delay after dialog
local isDialogTimeout = false

--TODO: Add dialogue choices
local isDialogChoice = false
local isDialogChSelected = false
-- current dialog choices if available
local dialCh = 1

-- TODO: Implement multiple choices in one dialogue
local dialChPage = 1

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

local fieldLeft, fieldRight = -350, 5000

local objNpc = {}
-- field obj
local fW, fH, oW, oH = 100, 100, 20, 20
for y = 1, fH, 1 do
    for x = 1, fW, 1 do
        table.insert(objField, { x = 20 + oW * (x - 1), y = 20 + oH * (y - 1), w = oW, h = oH, a = 1 })
    end
end

-- creates a new npc object (use on table)
local function newNpc(x, y, w, h, colLine, colFill, txt, name, arg, choices)
    table.insert(objNpc,
        {
            x = x,
            y = y,
            w = w,
            h = h,
            colLine = colLine,
            colFill = colFill,
            txt = txt,
            -- optional
            name = name,
            arg = arg,
            choices = choices,
            tAlp = 0
        })
end

newNpc(0, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "This is a text, Hello world!" },
    "Entity 1")

newNpc(60, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "I'm a block." }, "Entity 2")

newNpc(120, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "Does it feel weird that we're just in a simulation?" },
    "Entity 3")

newNpc(240, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "I should probably rest now.." },
    "Entity 4")

newNpc(20, 3000, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "You really went this far huh." },
    "Entity 5")

newNpc(1760, 1760, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "This place is huge." },
    "Entity 6")

newNpc(800, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 }, { "I can talk now!", "I can even continue what i want to say!" },
    "Entity 7")

newNpc(2000, 2300, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
    { "It's so empty here..", "What should we do instead of standing here?", { { 1, 1, 1 }, "Only if i could ", { 1, 1, 0 }, "ask", { 1, 1, 1 }, " you somethiing.." } },
    "Entity 8",
    function()
        ply.dial.e_8_base = true
    end
)

newNpc(1600, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
    {
        {
            { 1, 1, 1 },
            "This block has no name."
        },
        {
            { 1, 1, 1 },
            "Or is it?"
        },
        {
            { 1, 1, 1 },
            "Maybe you could find it out yourself.."
        }
    },
    "", nil
)

newNpc(-100, -20, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
    {
        {
            { 1, 1, 1 },
            "I can control your game!"
        },
        {
            { 1, 1, 1 },
            "I can even open the menu!"
        }
    },
    "Entity 9",
    function()
        isMenu = true
    end
)

newNpc(-200, -20, 20, 20, { 1, .0, .7 }, { .8, .2, .5 },
    {
        {
            { 1, 1, 1 },
            "This place is huge."
        }
    }, "Entity 10",
    function()
        ply.dial.e_10 = true
    end
)

newNpc(-20, -200, 20, 20, { 1, 0.5, 0.7 }, { .8, .2, .5 },
    {
        {
            { 1, 1, 1 }, "This is a ",
            { 1, 1, 0 }, "really",
            { 1, 1, 1 },
            " long line of text that might probably wrap around to the next line. Or maybe not since the message is still too short to show, depending on the resolution of your screen."
        },
        {
            { 1, 1, 1 },
            "Now with this information.. i can actually write an entire movie script in this box!\nOh nevermind.. it doesn't fit the whole screen."
        }
    },
    "Entity 11")

function love.load()
    lg.setDefaultFilter("nearest", "nearest")
    lm.setVisible(false)

    arr = lg.newImage("/assets/img/arr.png")
end

-- use on npc table loop
local function newDialog(tabDial, npcObj)
    if not isDialog and not isDialogTimeout then
        if not isDialogProg then
            table.insert(tabDial, { txt = npcObj.txt, name = npcObj.name, arg = npcObj.arg, choices = npcObj.choices })
        end
        isDialog = true
        isDialogProg = true
        print("triggered dialogue" .. " (isDialog: " .. tostring(isDialog) .. ")")
    end
end

-- trigger when player is on npc dialogue hitbox (objRetElse is optional)
local function npcHitbox(npc, objRet, objRetElse)
    if ply.face == "up" then
        if pR > npc.x - 10 and
            pL < npc.x + npc.w + 10 and
            pT < npc.y + npc.h + 10 and
            pB > npc.y + npc.h then
            objRet()
        else
            if objRetElse ~= nil then
                objRetElse()
            end
        end
    elseif ply.face == "down" then
        if pR > npc.x - 10 and
            pL < npc.x + npc.w + 10 and
            pT < npc.y and
            pB > npc.y - 10 then
            objRet()
        else
            if objRetElse ~= nil then
                objRetElse()
            end
        end
    elseif ply.face == "left" then
        if pR > npc.x + npc.w and
            pL < npc.x + npc.w + 10 and
            pT < npc.y + npc.h + 10 and
            pB > npc.y - 10 then
            objRet()
        else
            if objRetElse ~= nil then
                objRetElse()
            end
        end
    elseif ply.face == "right" then
        if pR > npc.x - 10 and
            pL < npc.x and
            pT < npc.y + npc.h + 10 and
            pB > npc.y - 10 then
            objRet()
        else
            if objRetElse ~= nil then
                objRetElse()
            end
        end
    end
end

-- iterates table on reverse (add index (i) value as function argument in func var)
local function reverseItr(tab, func)
    for i = #tab, 1, -1 do
        func(i)
    end
end

local function dialEndFunc()
    for _, npc in ipairs(objNpc) do
        -- entity 10
        if npc.name == "Entity 10" and ply.dial.e_10 then
            reverseItr(objNpc, function(i)
                if objNpc[i].name == "Entity 10" then
                    table.remove(objNpc, i)
                end
            end)
            newNpc(-200, -20, 20, 20, { 1, 0.5, 0.7 }, { 0.8, 0.2, 0.5 },
                { { { 1, 1, 1 }, "This could fit a lot of people." } }, "Entity 10", nil)
            print(npc.name .. " replaced")
        end

        -- entity 8
        if ply.dial.e_8_base then
            reverseItr(objNpc, function(i)
                if objNpc[i].name == "Entity 8" then
                    table.remove(objNpc, i)
                end
            end)
            newNpc(2000, 2300, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
                {
                    {
                        { 1, 1, 1 },
                        "Now that you're still here, i'll ask you something.."
                    },
                    {
                        { 1, 1, 1 },
                        "How do you feel being here?"
                    }
                }, "Entity 8",
                function()
                    -- since this is a function, it could be programmable to work from what the player's chose
                    ply.dial.e_8_b1 = true
                end,
                -- if dialPg == #dialObj.txt after dialog prog then trigger choice event
                {
                    txt = {
                        -- decision pg 1 (if available)
                        {
                            -- decision 1
                            -- after decision, reset dialPg value to 1 for this to work
                            -- use on dialCh
                            {
                                -- use on dialPg
                                {
                                    { 1, 1, 1 },
                                    "I mean, you we're talking with the other people you met earlier, so that makes sense i think."
                                },
                                {
                                    { 1, 1, 1 },
                                    "I still feel bored even after this though."
                                },
                                --TODO: Trigger event depending on choices
                                arg = function()
                                    print("[INFO] doesnt work yet.. (ch:" .. dialCh .. " pg:" .. dialChPage .. ")")
                                end
                            },
                            -- decision 2
                            -- ditto
                            {
                                -- ditto
                                {
                                    { 1, 1, 1 },
                                    "Well, at least there's something to do in this place."
                                },
                                arg = function()
                                    print("[INFO] doesnt work yet.. (ch:" .. dialCh .. " pg:" .. dialChPage .. ")")
                                end
                            }
                        }
                    },
                    chTxt = {
                        -- order is important in decisions
                        "Not too bad.",
                        "I feel tired either."
                    }
                    -- might improve how this feature works though, so complex
                })
            print(npc.name .. " replaced")
        end
        if npc.name == "Entity 8" and ply.dial.e_8_b1 then
            reverseItr(objNpc, function(i)
                if objNpc[i].name == "Entity 8" then
                    table.remove(objNpc, i)
                end
            end)
            newNpc(2000, 2300, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
                {
                    {
                        { 1, 1, 1 },
                        "Only if there's something interesting to do here.."
                    }
                }, "Entity 8"
            )
            print(npc.name .. " replaced")
        end
    end
end

function love.keypressed(k)
    if k == "escape" then
        if not isDialog then
            le.quit(0)
        end
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
    if k == keys.confirm then
        if not isMenu then
            for _, npc in ipairs(objNpc) do
                --TODO: Consider diagonals?
                npcHitbox(npc, function()
                    newDialog(dialObj, npc)
                end)
            end
        end
        -- dialog confirm & next page functionality
        if not isDialogProg and isDialog then
            for _, dial in ipairs(dialObj) do
                if #dial.txt > dialPg then
                    dialPg = dialPg + 1
                    dProgTime = 0
                    dArrAlp = 0
                    isDialogProg = true
                    print("next page (page: " .. dialPg .. ")")
                else
                    if isDialogChoice then
                        isDialogChoice = false
                        isDialogChSelected = false
                        dialPg = 1
                    else
                        if dial.arg ~= nil then
                            dial.arg()
                            print("finshed dialog arg")
                        end
                        -- run dialogue-triggered events
                        dialEndFunc()
                        isDialog = false
                        isDialogTimeout = true
                        dialPg = 1
                        table_clear(dialObj)
                        print("end of dialogue" .. " (isDialog: " .. tostring(isDialog) .. ")")
                    end
                end
            end
        end
    end
    if k == keys.menu then
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
    if k == keys.cancel then
        if isMenu then
            isMenu = false
        end
        if isDialogProg and isDialog then
            isDialogProg = false
            dProgTime = 0
        end
    end
    if k == keys.up then
        if isDialogChoice then
            if dialCh > 1 then
                dialCh = dialCh - 1
            else
                dialCh = 1
            end
        end
    end
    if k == keys.down then
        if isDialogChoice then
            for _, ch in ipairs(dialObj) do
                if dialCh < #ch.choices.txt.chTxt then
                    dialCh = dialCh + 1
                else
                    dialCh = #ch.choices.txt.chTxt
                end
            end
        end
    end
end

function love.resize(w, h)
    wWd, wHg = w, h
end

local function plyInput(dt)
    if not isDialog and not isMenu then
        if lk.isDown(keys.up) then
            ply.y = ply.y - dt * ply.vy
            ply.face = "up"
        end
        if lk.isDown(keys.down) then
            ply.y = ply.y + dt * ply.vy
            ply.face = "down"
        end
        if lk.isDown(keys.left) then
            ply.x = ply.x - dt * ply.vx
            ply.face = "left"
        end
        if lk.isDown(keys.right) then
            ply.x = ply.x + dt * ply.vx
            ply.face = "right"
        end

        if lk.isDown(keys.cancel) then
            ply.vx, ply.vy = 350, 350
            ply.isAfter = true
        else
            ply.vx, ply.vy = 200, 200
            ply.isAfter = false
        end

        if lk.isDown(keys.up) or lk.isDown(keys.left) or lk.isDown(keys.down) or lk.isDown(keys.right) then
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
end

local function gameLoop(dt)
    -- game field loop
    if ply.isAfter then
        table.insert(plyAImg, { x = ply.x, y = ply.y, w = ply.w, h = ply.h, a = 0.2 })
    end

    for i, pImg in ipairs(plyAImg) do
        pImg.a = pImg.a - dt * 0.35
        -- ply after img boundaries
        if pImg.x < fieldLeft then
            pImg.x = fieldLeft
        end
        if pImg.y < fieldLeft then
            pImg.y = fieldLeft
        end
        if pImg.x > fieldRight then
            pImg.x = fieldRight
        end
        if pImg.y > fieldRight then
            pImg.y = fieldRight
        end
        plyAimgCount = i

        if pImg.a < 0 then
            table.remove(plyAImg, i)
        end
    end

    -- debug counters
    if next(plyAImg) == nil then
        plyAimgCount = 0
    end
    if next(objField) == nil then
        objCount = 0
    end

    for _, obj in ipairs(objField) do
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

    for _, npc in ipairs(objNpc) do
        if settings.showTooltip then
            npcHitbox(npc,
                function()
                    if not isDialog then
                        if npc.tAlp < 1 then
                            npc.tAlp = npc.tAlp + dt * 8
                        end
                    end
                end,
                function()
                    if npc.tAlp > 0 then
                        npc.tAlp = npc.tAlp - dt * 5
                    end
                end)
            if isDialog then
                if npc.tAlp > 0 then
                    npc.tAlp = npc.tAlp - dt * 5
                end
            end
        end
    end
end

function love.update(dt)
    pL, pR, pT, pB = ply.x, ply.x + ply.w, ply.y, ply.y + ply.h
    plyOArea.x, plyOArea.y = ply.x - 20, ply.y - 20

    plyInput(dt)
    if not isMenu then
        gameLoop(dt)
    end

    if not isMenu and not isDialog then
        if lk.isDown("=") then
            if sc < 2.5 then
                if lk.isDown("lctrl") or lk.isDown("rctrl") then
                    sc = sc + dt
                else
                    sc = sc + dt * 0.5
                end
            else
                sc = 2.5
            end
        end
        if lk.isDown("-") then
            if sc > 0.85 then
                if lk.isDown("lctrl") or lk.isDown("rctrl") then
                    sc = sc - dt
                else
                    sc = sc - dt * 0.5
                end
            else
                sc = 0.85
            end
        end
    end

    -- ply boundaries
    if ply.x < -350 then
        ply.x = -350
    end
    if ply.y < -350 then
        ply.y = -350
    end
    if ply.x + ply.w > 5000 then
        ply.x = 5000
    end
    if ply.y + ply.w > 5000 then
        ply.y = 5000
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
        if dFrmBGAlp < 0.93 then
            dFrmBGAlp = dFrmBGAlp + dt * 4.65
        else
            dFrmBGAlp = 0.93
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
    lg.scale(sc, sc)
    -- any better way though
    lg.translate(-ply.x + (wWd / (2 * sc)) - (ply.w / 2), -ply.y + (wHg / (2 * sc)) - (ply.h / 2))
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
    lg.print("it feels cold here.....", fonts.ui, 20, 0)

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
        lg.rectangle("fill", ply.x, ply.y, ply.w, ply.h - 19)
    end
    if ply.face == "down" then
        lg.rectangle("line", ply.x, ply.y + 18, ply.w, ply.h - 19)
        lg.rectangle("fill", ply.x, ply.y + 18, ply.w, ply.h - 19)
    end
    if ply.face == "left" then
        lg.rectangle("line", ply.x, ply.y, ply.w - 19, ply.h)
        lg.rectangle("fill", ply.x, ply.y, ply.w - 19, ply.h)
    end
    if ply.face == "right" then
        lg.rectangle("line", ply.x + 18, ply.y, ply.w - 19, ply.h)
        lg.rectangle("fill", ply.x + 18, ply.y, ply.w - 19, ply.h)
    end

    lg.setColor(1, 1, 1, ply.arrAlp)
    lg.draw(arr, ply.x - 20, ply.y + 20, -math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 20, ply.y + 40, -math.pi, 3.5, 3.5)
    lg.draw(arr, ply.x + 39, ply.y + 2, math.pi / 2, 3.5, 3.5)
    lg.draw(arr, ply.x + 1, ply.y - 19, 0, 3.5, 3.5)

    for _, npc in ipairs(objNpc) do
        lg.setColor(.7, .5, .3, npc.tAlp)
        lg.circle("fill", npc.x + npc.w / 2, npc.y - 12, 4)
        lg.circle("line", npc.x + npc.w / 2, npc.y - 12, 6)
    end

    lg.setColor(1, 1, 1, 0.35)
    lg.rectangle("line", fieldLeft, fieldLeft, -fieldLeft + fieldRight, -fieldLeft + fieldRight)

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
    for i, dial in ipairs(dialObj) do
        if dial.name ~= "" then
            lg.setColor(1, 1, 1, dFrmAlp)
            lg.rectangle("line", 20 + (260 * (i - 1)), wHg - 160, 240, 40)
            lg.setColor(0, 0, 0, dFrmBGAlp)
            lg.rectangle("fill", 20 + (260 * (i - 1)), wHg - 160, 240, 40)
            lg.setColor(1, 1, 1)
            lg.printf(dial.name, fonts.dialName, 20 + (260 * (i - 1)), wHg - 153, 240, "center")
        end
    end

    lg.setColor(1, 1, 1, dFrmAlp)
    lg.rectangle("line", 0, wHg - 120, wWd, 120)
    lg.setColor(0, 0, 0, dFrmBGAlp)
    lg.rectangle("fill", 0, wHg - 120, wWd, 120)
    lg.setColor(1, 1, 1, 1)
    for _, dial in ipairs(dialObj) do
        if not isDialogChSelected then
            lg.printf(dial.txt[dialPg], fonts.ui, 20, wHg - 100, wWd - 40, "left")
        else
            lg.printf(dial.choices.txt[dialChPage][dialCh][dialPg], fonts.ui, 20, wHg - 100, wWd - 40, "left")
        end
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
            plyOArea.y ..
            "\n" ..
            dProgTime ..
            "\n" ..
            dTimeout ..
            "\n" .. dArrAlp .. "\n" .. ply.face .. "\n" .. dialPg .. "\n" .. dialCh .. " " .. dialChPage .. "\n" .. sc,
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
