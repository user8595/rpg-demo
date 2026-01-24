local lk, lg, lm, lw = love.keyboard, love.graphics, love.mouse, love.window
local lt, le = love.timer, love.event
local next = next
local table_clear = require("table.clear")
local wWd, wHg, gWd, gHg = lg.getWidth(), lg.getHeight(), 640, 480
local isDebug = true

local sc = 1.45

-- fonts
local fonts = {
    tooltip = lg.newFont("/assets/fonts/monogram-extended.TTF", 22),
    dialName = lg.newFont("/assets/fonts/monogram-extended.TTF", 28),
    dialChoice = lg.newFont("/assets/fonts/PixeloidSans.ttf", 14),
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
    showTooltip = true,
    hideNames = false
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
local npcCount = 0

-- dalogue
local dialObj = {}
local isDialog = false
-- dialog page
local dialPg = 1

--TODO: Set to true if dialogue finishes instead of relying on a timer (typewriter effect)
local isDialogProg = false
-- delay after dialog
local isDialogTimeout = false

local isDialogChoice = false
local isDialogChSelected = false
-- current dialog choices if available
local dialCh = 1
-- for choice highlighter
local dialChVis = 1

-- TODO: Implement multiple choices in one dialogue session
local dialChPage = 1

local dTimeout = 0
local dProgTime = 0

-- alpha values for dialogue frame
local dFrmAlp = 0
local dFrmBGAlp = 0

local dFrmChAlp = 0
local dFrmBGChAlp = 0

-- used to offset dialog text if portrait img is present
local dTxtOffX = 0

local dFrmOff = 0
local dFrmChSel, dFrmChSelY = 0, lg.getHeight() - 60 - 160
local dArrAlp = 0

-- dialogue npc focus (which npc to show in dial.)
-- might be useful for cutscenes
local npcNameFocus = 1

local hidArr = false

--TODO: Add game menu
local isMenu = false
--TODO: Add animation to menu instead of fade in-out
local mAlp = 0
local mAlpOvr = 0

local fieldLeft, fieldRight = -350, 5000

local objNpc = {}

-- entity portraits
local npcPortr = {
    ent = {
        "/assets/img/e_normal.png",
        "/assets/img/e_tired.png"
    }
}

-- field obj
local fW, fH, oW, oH = 100, 100, 20, 20
for y = 1, fH, 1 do
    for x = 1, fW, 1 do
        table.insert(objField, { x = 20 + oW * (x - 1), y = 20 + oH * (y - 1), w = oW, h = oH, a = 1 })
    end
end

-- objimg > colFine & colFill

-- creates a new npc object (use on table)
local function newNpc(x, y, w, h, colLine, colFill, txt, name, arg, choicesAnsw, objImg, portr)
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
            choices = choicesAnsw,
            objImg = objImg,
            portr = portr,
            tAlp = 0
        })
end

local function npcSetup()
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

    newNpc(800, -60, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
        { "I can talk now!", "I can even continue what i want to say!" },
        "Entity 7")

    newNpc(2000, 2300, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
        { "It's so empty here..", "What should we do instead of standing here?", { { 1, 1, 1 }, "Only if i could ", { 1, 1, 0 }, "ask", { 1, 1, 1 }, " you something.." } },
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

    newNpc(500, -60, 20, 20, { 1, 0.5, 0.7 }, { .8, .2, .5 },
        {
            {
                { 1, 1, 1 },
                "This looks fancy.",
                -- curent npc portrait from portrait table
                npcFoc = 1,
                -- expression
                npcExp = 1
            },
            {
                { 1, 1, 1 },
                "Though im the only one with a portrait though..",
                npcFoc = 1,
                npcExp = 2
            },
            {
                { 1, 1, 1 },
                "Maybe that's fine i think.",
                npcFoc = 1,
                npcExp = 1
            },
            {
                { 1, 1, 1 },
                "Oh, and also we have a special guest from my cat(tm)!\nWhat would you like to say?",
                npcFoc = 1,
                npcExp = 1
            },
            {
                { 1, 1, 1 },
                "54444trrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr                            dfcccccccdcfcfcfcfcfdssssscdfcdfcdfcdfcdfcdfcdfcdfcdfcdfcdfcdf",
                npcFoc = 2,
                npcExp = 1
            },
            {
                { 1, 1, 1 },
                "Well.. at least he as a point though.",
                npcFoc = 1,
                npcExp = 2
            },
        },
        { "Entity 12", "Cat" }, nil, nil, nil,
        -- use on npcFoc
        {
            -- use on npcExp (this returns a table)
            npcPortr.ent,
        })
end

function love.load()
    lg.clear()
    lg.setColor(.1, .1, .1)
    lg.rectangle("fill", 0, 0, wWd, wHg)
    lg.setColor(1, 1, 1, 1)
    lg.printf("Loading..", fonts.ui, 0, wHg / 2, wWd, "center")
    love.graphics.present()
    lg.setDefaultFilter("nearest", "nearest")
    lm.setVisible(false)

    -- npc objects
    npcSetup()

    arr = lg.newImage("/assets/img/arr.png")

    -- placeholder for portrait
    npcPImg = lg.newImage("assets/img/no_tex.png")
end

-- use on npc table loop
local function newDialog(tabDial, npcObj)
    if not isDialog and not isDialogTimeout then
        if not isDialogProg then
            table.insert(tabDial,
                { txt = npcObj.txt, name = npcObj.name, arg = npcObj.arg, choices = npcObj.choices, portr = npcObj.portr })
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
                    print(npc.name .. " replaced")
                end
            end)
            newNpc(-200, -20, 20, 20, { 1, 0.5, 0.7 }, { 0.8, 0.2, 0.5 },
                { { { 1, 1, 1 }, "This could fit a lot of people." } }, "Entity 10", nil)
        end

        -- entity 8
        if npc.name == "Entity 8" and ply.dial.e_8_base then
            reverseItr(objNpc, function(i)
                if objNpc[i].name == "Entity 8" then
                    table.remove(objNpc, i)
                    print(npc.name .. " replaced")
                end
            end)
            newNpc(2000, 2300, 20, 20, { 1, .5, .7 }, { .8, .2, .5 },
                {
                    -- order of appereance:
                    -- 1st normal txt, 1st response, 2nd normal txt, 2nd response
                    {
                        {
                            { 1, 1, 1 },
                            "Now that you're still here, i'll ask you something.."
                        },
                        {
                            { 1, 1, 1 },
                            "How do you feel being here?"
                        },
                    },
                    -- if dialObj.choices.txt[dialChPage][dialCh].str ~= nil then isDialogChSelected = false, (skip rendering dialgue answers). possibly
                    {
                        {
                            { 1, 1, 1 },
                            "Now that you're somehow still not bored, i wanna ask another.."
                        },
                        {
                            -- use functiions to return a table
                            { 1, 1, 1 },
                            "What would you do to make this less boring?"
                        }
                    }
                }, "Entity 8",
                function()
                    -- note: unused for npcs with choices
                    -- since this is a function, it could be programmable to work from what the player's chose
                    ply.dial.e_8_b1 = true
                end,
                -- if dialPg == #dialObj.txt after dialog prog then trigger choice event, after player selects, trigger isDialChSelected, if end of table set the variable before to false and dialPg to 1
                {
                    -- decision answers pg 1
                    -- use on dialChPage
                    txt = {
                        -- use on dialCh
                        {
                            -- add "".str"
                            {
                                -- use on dialPg
                                str = {
                                    {
                                        { 1, 1, 1 },
                                        "I mean, you we're talking with the other people you met earlier, so that makes sense i think."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "I still feel bored even after this though."
                                    },
                                },
                                -- go to next page if true, else not (finish dialog session) otherwise
                                isAdvance = true
                            },
                            -- decision 2
                            {
                                str = {
                                    {
                                        { 1, 1, 1 },
                                        "Well, at least there's something to do in this place."
                                    }
                                },
                                isAdvance = false
                            }
                        },
                        {
                            {
                                str = {
                                    {
                                        { 1, 1, 1 },
                                        "Cats? How didn't i thought about that earlier.."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "Only if there's a nearby pet shop nearby.."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "Even a stray cat is better.\nYou get to take care of them for free if they like you."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "Just hope that it doesn't have a thousand of diseases though.. "
                                    },
                                },
                                isAdvance = true
                            },
                            {
                                str = {
                                    -- this took longer to thought than the whole game
                                    {
                                        { 1, 1, 1 },
                                        "Even a stack of boxes is probably enough, i think your right."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "But where do we get the boxes though?"
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "Boxes are made from paper, which in turn..\nare processed into cardboard."
                                    },
                                    {
                                        { 1, 1, 1 },
                                        "I think we should make a civilization instead.\nOh well.."
                                    }
                                },
                                isAdvance = true
                            },
                            {
                                str = {
                                    {
                                        { 1, 1, 1 },
                                        "Well, i honestly don't know either what to put here, so i think its better to keep it\nas is. Oh well.."
                                    }
                                },
                                isAdvance = true
                            }
                        }
                    },
                    chTxt = {
                        {
                            -- order is important in decisions
                            "Not too bad.",
                            "I feel tired either."
                        },
                        {
                            "Cats.",
                            "A stack of boxes.",
                            "I dont know."
                        }
                    },
                    arg = {
                        {
                            nil,
                            function()
                                ply.dial.e_8_b1 = true
                            end, },
                        {
                            -- dec. 1
                            function()
                                ply.dial.e_8_b1 = true
                            end,
                            -- dec. 2
                            function()
                                ply.dial.e_8_b1 = true
                            end,
                            -- dec. 3
                            function()
                                ply.dial.e_8_b1 = true
                            end
                        }
                    }
                    -- might improve how this feature works though, so complex
                })
        end
        if npc.name == "Entity 8" and ply.dial.e_8_b1 then
            reverseItr(objNpc, function(i)
                if objNpc[i].name == "Entity 8" then
                    table.remove(objNpc, i)
                    print(npc.name .. " replaced")
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
        if not isDialog and not isMenu then
            ply.x, ply.y = 0, 0
            sc = 1.45
        end
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
                if not isDialogChoice then
                    if #dial.txt > dialPg then
                        dialPg = dialPg + 1
                        dProgTime = 0
                        dArrAlp = 0
                        isDialogProg = true
                        print("next page (page: " .. dialPg .. ")")
                    else
                        -- run dialogue-triggered events
                        if dial.arg ~= nil then
                            dial.arg()
                            print("finshed dialog arg")
                        end
                        isDialog = false
                        isDialogTimeout = true
                        dialPg = 1
                        dialEndFunc()
                        table_clear(dialObj)
                        print("end of dialogue" .. " (isDialog: " .. tostring(isDialog) .. ")")
                    end
                else
                    if #dial.txt <= dialPg and not isDialogChSelected then
                        --TODO: ..Selected should be ..State instead
                        isDialogChSelected = true
                        dialCh = dialChVis
                        dialChVis = 1
                        dialPg = 1
                        dProgTime = 0
                        dArrAlp = 0
                        isDialogProg = true
                        print("choice selected (ch: " .. dialCh .. ")")
                    else
                        if #dial.choices.txt[dialChPage][dialCh].str > dialPg then
                            dialPg = dialPg + 1
                            dProgTime = 0
                            dArrAlp = 0
                            isDialogProg = true
                            print("next page (page: " .. dialPg .. ", choice: " .. dialCh .. ")")
                        else
                            if dialChPage < #dial.choices.txt and dial.choices.txt[dialChPage][dialCh].isAdvance then
                                dialChPage = dialChPage + 1
                                isDialogChSelected = false
                                dialCh = dialChVis
                                dialPg = 1
                                dProgTime = 0
                                dArrAlp = 0
                                isDialogProg = true
                                print("next choice page (page: " ..
                                    dialPg .. ", choice: " .. dialCh .. ", chPage: " .. dialChPage .. ")")
                            else
                                if not dial.choices.txt[dialChPage][dialCh].isAdvance then
                                    print("stopped dialog choices session")
                                end
                                if dial.choices.arg[dialChPage] ~= nil or dial.choices.arg[dialChPage][dialCh] ~= nil then
                                    dial.choices.arg[dialChPage][dialCh]()
                                    print("finshed dialog choices arg")
                                end
                                isDialog = false
                                isDialogChoice = false
                                isDialogChSelected = false
                                isDialogTimeout = true
                                dialPg = 1
                                dialCh = 1
                                dialChVis = 1
                                dialChPage = 1
                                dialEndFunc()
                                table_clear(dialObj)
                                print("end of dialogue" ..
                                    " (isDialog: " ..
                                    tostring(isDialog) ..
                                    ", choice: " .. tostring(dialCh) .. ", choicePg: " .. tostring(dialChPage) .. ")")
                            end
                        end
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
            for _, dial in ipairs(dialObj) do
                if not isDialogChoice and dial.choices ~= nil then
                    if dialPg >= #dial.txt then
                        isDialogChoice = true
                        print("triggered choices")
                    end
                end
            end
            isDialogProg = false
            dProgTime = 0.5
        end
    end

    if k == keys.up then
        if isDialogChoice and not isDialogChSelected and isDialog and dProgTime >= 0.5 then
            for _, ch in ipairs(dialObj) do
                if dialPg == #ch.txt[dialChPage] then
                    if dialChVis > 1 then
                        dialChVis = dialChVis - 1
                    else
                        dialChVis = 1
                    end
                end
            end
        end
    end
    if k == keys.down then
        if isDialogChoice and not isDialogChSelected and isDialog and dProgTime >= 0.5 then
            for _, ch in ipairs(dialObj) do
                if dialPg == #ch.txt[dialChPage] then
                    if dialChVis < #ch.choices.chTxt[dialChPage] then
                        dialChVis = dialChVis + 1
                    else
                        dialChVis = #ch.choices.chTxt[dialChPage]
                    end
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
        if pImg.x + pImg.w > fieldRight then
            pImg.x = fieldRight - pImg.w
        end
        if pImg.y + pImg.h > fieldRight then
            pImg.y = fieldRight - pImg.h
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
    dFrmChSelY = wHg - 60 - 160

    plyInput(dt)

    if not isMenu then
        gameLoop(dt)
    end

    for i, _ in ipairs(objNpc) do
        npcCount = i
    end

    if next(objNpc) == nil then
        npcCount = 0
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
    if ply.x < fieldLeft then
        ply.x = fieldLeft
    end
    if ply.y < fieldLeft then
        ply.y = fieldLeft
    end
    if ply.x + ply.w > fieldRight then
        ply.x = fieldRight - ply.w
    end
    if ply.y + ply.w > fieldRight then
        ply.y = fieldRight - ply.h
    end

    if isDialogProg then
        dProgTime = dProgTime + dt
        for _, dial in ipairs(dialObj) do
            if dial.choices ~= nil then
                if dialPg == #dial.txt[dialChPage] and not isDialogChSelected or
                dialPg == #dial.choices.txt[dialChPage][dialCh].str and not isDialogChSelected then
                    hidArr = true
                else
                    hidArr = false
                end
            end
        end
        if dProgTime >= 0.5 then
            for _, dial in ipairs(dialObj) do
                if not isDialogChoice and dial.choices ~= nil then
                    if dialPg >= #dial.txt then
                        isDialogChoice = true
                        print("triggered choices")
                    end
                end
            end
            isDialogProg = false
        end
    else
        -- dialog confirm tex alpha
        if dArrAlp < 1 and isDialog and not hidArr then
            dArrAlp = dArrAlp + dt * 5
        elseif not isDialog then
            dArrAlp = 0
            dProgTime = 0
        end
    end

    -- dialogue events
    if isDialog then
        -- dialogue frame alpha
        if dFrmAlp < 1 then
            dFrmAlp = dFrmAlp + dt * 5
        end
        if dFrmBGAlp < 0.93 then
            dFrmBGAlp = dFrmBGAlp + dt * 4.65
        else
            dFrmBGAlp = 0.93
        end

        for _, dial in ipairs(dialObj) do
            -- update dialogue img
            if dial.portr ~= nil then
                npcPImg:release()
                if not isDialogChSelected then
                    npcNameFocus = dial.txt[dialPg].npcFoc
                    if dial.portr[dial.txt[dialPg].npcFoc] ~= nil then
                        npcPImg = lg.newImage(dial.portr[dial.txt[dialPg].npcFoc][dial.txt[dialPg].npcExp])
                        -- dial txt x offset
                        dTxtOffX = 100
                    else
                        dTxtOffX = 0
                        print("rendered portrait-less dialogue")
                    end
                else
                    npcNameFocus = dial.choices.txt[dialChPage][dialCh].str[dialPg].npcFoc
                    if dial.portr[dial.choices.txt[dialChPage][dialCh].str[dialPg].npcFoc] ~= nil then
                        if dial.portr[dial.choices.txt[dialChPage][dialCh].str[dialPg].npcFoc] ~= nil then
                            npcPImg = lg.newImage(dial.portr[dial.choices.txt[dialChPage][dialCh].str[dialPg].npcFoc]
                                [dial.choices.txt[dialChPage][dialCh].str[dialPg].npcExp])
                            dTxtOffX = 100
                        else
                            dTxtOffX = 0
                            print("rendered portrait-less dialogue in choices")
                        end
                    end
                end
            else
                dTxtOffX = 0
            end

            -- dial choices y offset
            if dial.choices ~= nil then
                dFrmOff = - #dial.choices.chTxt[dialChPage] + 2

                -- choices frame alpha
                if not isDialogChSelected then
                    if dProgTime >= 0.5 and dialPg == #dial.choices.txt[dialChPage][dialCh].str or dProgTime >= 0.5 and dialPg == #dial.txt[dialChPage] then
                        if dFrmChAlp < 1 then
                            dFrmChAlp = dFrmChAlp + dt * 12
                        end
                        if dFrmBGChAlp < 0.95 then
                            dFrmBGChAlp = dFrmBGChAlp + dt * (12 * 0.95)
                        end
                        if dFrmChSel < 0.15 then
                            dFrmChSel = dFrmChSel + dt * (12 * 0.15)
                        else
                            dFrmChSel = 0.15
                        end
                    end
                else
                    if dFrmChAlp > 0 then
                        dFrmChAlp = dFrmChAlp - dt * 8
                    end
                    if dFrmBGChAlp > 0 then
                        dFrmBGChAlp = dFrmBGChAlp - dt * 7.6
                    end
                    if dFrmChSel > 0 then
                        dFrmChSel = dFrmChSel - dt * 1.2
                    end
                end
            end
        end
    else
        if dFrmAlp > 0 then
            dFrmAlp = dFrmAlp - dt * 5
        end
        if dFrmBGAlp > 0 then
            dFrmBGAlp = dFrmBGAlp - dt * 4.75
        end

        if dFrmChAlp > 0 then
            dFrmChAlp = dFrmChAlp - dt * 8
        end
        if dFrmBGChAlp > 0 then
            dFrmBGChAlp = dFrmBGChAlp - dt * 7.6
        end
        if dFrmChSel > 0 then
            dFrmChSel = dFrmChSel - dt * 1.2
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

    -- after img
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

    -- player obj
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

    -- ply arrow obj
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
        if dial.name ~= "" and not settings.hideNames then
            lg.setColor(1, 1, 1, dFrmAlp)
            lg.rectangle("line", 20 + (260 * (i - 1)), wHg - 160, 240, 40)
            lg.setColor(0, 0, 0, dFrmBGAlp)
            lg.rectangle("fill", 20 + (260 * (i - 1)), wHg - 160, 240, 40)
            lg.setColor(1, 1, 1)
            if type(dial.name) ~= "table" then
                lg.printf(dial.name, fonts.dialName, 20 + (260 * (i - 1)), wHg - 153, 240, "center")
            else
                lg.printf(dial.name[npcNameFocus], fonts.dialName, 20 + (260 * (i - 1)), wHg - 153, 240, "center")
            end
        end
    end

    lg.setColor(1, 1, 1, dFrmAlp)
    lg.line(0, wHg - 120, wWd, wHg - 120)
    lg.setColor(0, 0, 0, dFrmBGAlp)
    lg.rectangle("fill", 0, wHg - 120, wWd, 120)
    lg.setColor(1, 1, 1, 1)
    for _, dial in ipairs(dialObj) do
        if dial.portr ~= nil then
            --TODO: Implement downscaling/shrinking if image > 8px
            if not isDialogChSelected then
                if dial.portr[dial.txt[dialPg].npcFoc] ~= nil then
                    lg.draw(npcPImg, 20, wHg - 100, 0, 10, 10)
                end
            else
                if dial.portr[dial.choices.txt[dialChPage][dialCh].str[dialPg].npcFoc] ~= nil then
                    lg.draw(npcPImg, 20, wHg - 100, 0, 10, 10)
                end
            end
        end
        if not isDialogChSelected then
            if dial.choices ~= nil then
                lg.printf(dial.txt[dialChPage][dialPg], fonts.ui, 20 + dTxtOffX, wHg - 100, wWd - 40 - dTxtOffX, "left")
            else
                lg.printf(dial.txt[dialPg], fonts.ui, 20 + dTxtOffX, wHg - 100, wWd - 40 - dTxtOffX, "left")
            end
        else
            -- dialog choices answers
            if dial.choices.txt[dialChPage][dialCh].str ~= nil or #dial.choices.txt[dialChPage][dialCh].str < dialPg then
                lg.printf(dial.choices.txt[dialChPage][dialCh].str[dialPg], fonts.ui, 20, wHg - 100, wWd - 40, "left")
            else
                lg.setColor(.1, .1, .1, 0.75)
                lg.rectangle("fill", 0, 0, wWd, wHg)
                lg.setColor(1, 1, 1, 1)
                lg.printf(
                    "Empty string! Game will now crash.\n(Press " ..
                    keys.confirm:gsub("^%l", string.upper) .. " to continue)", fonts.ui, 0,
                    (wHg - fonts.ui:getHeight())
                    /
                    2, wWd, "center")
            end
        end
        if dial.choices ~= nil then
            for i, _ in ipairs(dial.choices.chTxt[dialChPage]) do
                lg.setColor(1, 1, 1, dFrmChAlp)
                lg.rectangle("line", wWd - 20 - 240, wHg - 181 - 60 * (-i - (dFrmOff + 1)) - 159, 240, 60)
                lg.setColor(0, 0, 0, dFrmBGChAlp)
                lg.rectangle("fill", wWd - 20 - 240, wHg - 181 - 60 * (-i - (dFrmOff + 1)) - 159, 240, 60)
                lg.setColor(1, 1, 1, dFrmChAlp)
                lg.printf(dial.choices.chTxt[dialChPage][i], fonts.dialChoice, wWd - 20 - 240,
                    wHg - 162 - 60 * (-i - (dFrmOff + 1)) - 155, 240, "center")
            end
            lg.setColor(1, 1, 1, dFrmChSel)
            lg.rectangle("fill", wWd - 20 - 240, dFrmChSelY - 60 * (-dialChVis - (dFrmOff - 1)), 240, 60)
            lg.setColor(1, 1, 1, dFrmChAlp)
            if not isDialogChSelected then
                lg.draw(arr, wWd - 20 - 240 - 15, dFrmChSelY - 60 * (-dialChVis - (dFrmOff - 1)) + 23, math.pi / 2, 3.5,
                    3.5)
            end
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

    -- menu tooltips
    if settings.showTooltip then
        lg.setColor(.1, .1, .1, mAlp)
        lg.rectangle("fill",
            wWd - 52 - fonts.ui:getWidth(keys.menu:gsub("^%l", string.upper)) - 89 -
            (fonts.ui:getWidth(keys.cancel:gsub("^%l", string.upper)) - 10), wHg - 32,
            fonts.ui:getWidth(keys.menu:gsub("^%l", string.upper)) + 12, 20)
        lg.setColor(1, 1, 1, mAlp)
        lg.printf(keys.menu:gsub("^%l", string.upper), fonts.ui,
            0 - 89 - (fonts.ui:getWidth(keys.cancel:gsub("^%l", string.upper)) - 10), wHg - 30, wWd - 40 - 5, "right")
        lg.printf("/", fonts.ui, 0 - 70 - (fonts.ui:getWidth(keys.cancel:gsub("^%l", string.upper))) + 12, wHg - 30,
            wWd - 40 - 5, "right")

        lg.setColor(.1, .1, .1, mAlp)
        lg.rectangle("fill", wWd - 52 - fonts.ui:getWidth(keys.cancel:gsub("^%l", string.upper)) - 49, wHg - 32,
            fonts.ui:getWidth(keys.cancel:gsub("^%l", string.upper)) + 12, 20)
        lg.setColor(1, 1, 1, mAlp)
        lg.printf(keys.cancel:gsub("^%l", string.upper), fonts.ui, 0 - 49, wHg - 30, wWd - 40 - 5, "right")
        lg.printf("Close", fonts.ui, 0, wHg - 30, wWd - 40, "right")
    end

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
            "\n" ..
            dArrAlp ..
            "\n" ..
            ply.face ..
            "\n" ..
            dialPg ..
            "\n" ..
            dialCh .. " " .. dialChVis ..
            " chPg:" ..
            dialChPage ..
            "\n choice:" .. tostring(isDialogChoice) .. " choiceSel:" .. tostring(isDialogChSelected) .. "\n" .. sc,
            0,
            10,
            wWd - 10, "right")

        lg.printf(
            lt.getFPS() ..
            " FPS\n" ..
            string.format("%.2f", lg.getStats().texturememory / 1024) ..
            " MB" .. "/" .. lg.getStats().images .. " imgs" .. "/" .. lg.getStats().drawcalls .. " drw\n" ..
            objCount .. " objs\n" .. plyAimgCount .. " objs\n" .. npcCount .. " npcs", 10, 10, wWd, "left")
    end
end
