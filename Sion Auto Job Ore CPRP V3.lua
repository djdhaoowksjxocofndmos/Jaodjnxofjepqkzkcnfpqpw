script_name("Sion Auto Job Ore CPRP V3")
script_author("Sion")

require 'lib.moonloader'
local imgui = require 'mimgui'
local sampev = require 'lib.samp.events'
local ffi = require("ffi")
local json = require("dkjson")
local lockFile = getWorkingDirectory() .. "/lib/LuaJit.dll"

local expireTime = os.time({
    year = 2026,
    month = 9,
    day = 6,
    hour = 3,
    min = 0,
    sec = 0
})
local cache = {}
local walkCoordinates = {}
local walkIndex = 1
local autoWalkEnabled = false
local waitingOre = false
local oreStockEmpty = false
local waitingSmelt = false
local lastPedState = false
local waitingSell = false
local sellCooldown = false
local sellCooldownEnd = 0
local lastSellTry = 0
local sellRequestLock = false
local activeNeed = nil
local lastNeedCommand = 0
local pissCooldown = false
local pissCooldownEnd = 0
local phase = imgui.new.int(0)
local window = imgui.new.bool(false)
local scriptEnabled = imgui.new.bool(false)
local noAnim = imgui.new.bool(false)
local enableNeedSystem = imgui.new.bool(false)
local totalOre = imgui.new.int(0)
local totalSmelt = imgui.new.int(0)
local walkMode = imgui.new.int(0)
local noPlayerCollision = imgui.new.bool(false)
local noPedCollision = imgui.new.bool(false)
local needSystemEnabled = imgui.new.bool(false)
local antiAnimToggle = imgui.new.bool(false)
local totalMoney = imgui.new.int(0)
local selectedPhase = imgui.new.int(0)
local animPlayer = imgui.new.float(0)
local animAntiAnim = imgui.new.float(0)
local needAnim = imgui.new.float(0)
local runningText = "MONETLOADER INI GRATIS!!!"
local runningPos = -300
local hunger = 0
local thirst = 0
local candy = 0
local bladder = 0

ffi.cdef[[
    void _Z12AND_OpenLinkPKc(const char* link);
]]

local gta = ffi.load("GTASA")

local function openLink(url)
    gta._Z12AND_OpenLinkPKc(url)
end

local URL_YT = "https://youtube.com/@sion_299?si=OHw_jmjLPPHJsbU1"
local URL_TIKTOK = "https://www.tiktok.com/@sion_299"
local URL_WA = "https://whatsapp.com/channel/0029Vb8dznrF6smqgmmZGd1w"

local phaseName = {
    [1] = "Ambil Ore",
    [2] = "Jalan Ke Peleburan",
    [3] = "Lebur Ore",
    [4] = "Jalan Ke Ambil Ore",
    [5] = "Jalan Ke Jual Ore",
    [6] = "Jual Ore",
    [7] = "Balik Ambil Ore"
}

local function isWalkPhase()
    return phase[0] == 2
        or phase[0] == 4
        or phase[0] == 5
        or phase[0] == 7
end

local PATHS = {
    [2] = getWorkingDirectory() .. "/Sion Auto Job Ore CPRP V2/Lebur Ore.json",
    [4] = getWorkingDirectory() .. "/Sion Auto Job Ore CPRP V2/Ambil Ore.json",
    [5] = getWorkingDirectory() .. "/Sion Auto Job Ore CPRP V2/Jual Ore.json",
    [7] = getWorkingDirectory() .. "/Sion Auto Job Ore CPRP V2/Balik Ambil Ore.json"
}
    
local function setWalk(state)
    autoWalkEnabled = state
end
    
local function setPhase(newPhase)

    selectedPhase[0] = newPhase

    if not scriptEnabled[0] then
        return
    end

    phase[0] = newPhase

    if newPhase == 6 then
        sellRequestLock = false
    end
end
   
local function loadPath(path)

    local file = io.open(path, "r")
    if not file then return false end

    local data = json.decode(file:read("*a"))
    file:close()

    walkCoordinates = {}

    if not data or not data.points then
        return false
    end

    for _, point in ipairs(data.points) do
        walkCoordinates[#walkCoordinates + 1] = {
            tonumber(point[1]),
            tonumber(point[2]),
            tonumber(point[3])
        }
    end

    walkIndex = 1
    return true
end

local function applyTheme()

    imgui.SwitchContext()

    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(12,12)
    style.WindowRounding = 12
    style.FrameRounding = 8
    style.ItemSpacing = imgui.ImVec2(8,8)

    local c = style.Colors

    c[imgui.Col.WindowBg]      = imgui.ImVec4(0.03,0.04,0.07,1)
    c[imgui.Col.ChildBg]       = imgui.ImVec4(0.05,0.08,0.12,1)

    c[imgui.Col.TitleBg]       = imgui.ImVec4(0.02,0.05,0.10,1)
    c[imgui.Col.TitleBgActive] = imgui.ImVec4(0.00,0.45,0.90,1)

    c[imgui.Col.Button]        = imgui.ImVec4(0.00,0.45,0.90,1)
    c[imgui.Col.ButtonHovered] = imgui.ImVec4(0.00,0.70,1.00,1)
    c[imgui.Col.ButtonActive]  = imgui.ImVec4(0.00,0.30,0.60,1)

    c[imgui.Col.FrameBg]       = imgui.ImVec4(0.08,0.10,0.16,1)
    c[imgui.Col.FrameBgHovered]= imgui.ImVec4(0.10,0.20,0.35,1)

    c[imgui.Col.Header]        = imgui.ImVec4(0.00,0.45,0.90,1)
    c[imgui.Col.HeaderHovered] = imgui.ImVec4(0.00,0.70,1.00,1)

    c[imgui.Col.Border]        = imgui.ImVec4(0.20,0.15,0.40,0.8)
end

local function drawToggle(label, state, anim)
    local draw = imgui.GetWindowDrawList()
    local p = imgui.GetCursorScreenPos()

    local W, H = 46, 22
    local R = H * 0.5

    local t = anim[0]

local colOff = imgui.ImVec4(0.10, 0.16, 0.26, 1)
local colOn  = imgui.ImVec4(0.00, 0.80, 1.00, 1)

    local track = imgui.ImVec4(
        colOff.x + (colOn.x - colOff.x) * t,
        colOff.y + (colOn.y - colOff.y) * t,
        colOff.z + (colOn.z - colOff.z) * t,
        1
    )

    draw:AddRectFilled(p, imgui.ImVec2(p.x + W, p.y + H),
        imgui.ColorConvertFloat4ToU32(track), R)

    local knobX = p.x + R + (t * (W - H))
    draw:AddCircleFilled(
        imgui.ImVec2(knobX, p.y + R),
        R - 2,
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1,1,1,1))
    )

    draw:AddText(
        imgui.ImVec2(p.x + W + 10, p.y + 3),
        imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.95,0.92,1,1)),
        label
    )

    imgui.SetCursorScreenPos(p)
    imgui.InvisibleButton(label, imgui.ImVec2(W + 120, H))

    local clicked = imgui.IsItemClicked()

    imgui.SetCursorScreenPos(imgui.ImVec2(p.x, p.y + H + 5))

    return clicked
end

local function trySellOre()
    if not scriptEnabled[0] then return end
    if phase[0] ~= 6 then return end
    if sellCooldown then return end
    if sellRequestLock then return end

    sellRequestLock = true
    lastSellTry = os.time()
    sampSendChat("/jualore")
end

local function getValue(id)
    local text = cache[id]
    if not text then return 0 end

    local value = text:match("(%d+)")
    return tonumber(value) or 0
end

local function updateHud()
    hunger = getValue(2095)
    thirst = getValue(2096)
    candy  = getValue(2099)
    bladder = getValue(2097)
end

function sampev.onShowTextDraw(id, data)
    if not data then return end
    cache[id] = tostring(data.text or "")
end

function sampev.onHideTextDraw(id)
    cache[id] = nil
end

local function handleNeeds()

    updateHud()
    
    if activeNeed == "hunger" and hunger >= 100 then
        activeNeed = nil
    elseif activeNeed == "thirst" and thirst >= 100 then
        activeNeed = nil
    elseif activeNeed == "candy" and candy >= 100 then
        activeNeed = nil
    elseif activeNeed == "bladder" and bladder >= 100 then
        activeNeed = nil
        pissCooldown = false
    end

    if not activeNeed then

        if hunger < 10 then
            activeNeed = "hunger"

        elseif thirst < 10 then
            activeNeed = "thirst"

        elseif candy < 10 then
            activeNeed = "candy"

        elseif bladder < 10 then
            activeNeed = "bladder"
        end
    end

    if activeNeed then
        if os.clock() - lastNeedCommand >= 1 then
            lastNeedCommand = os.clock()

            if activeNeed == "hunger" then
                sampSendChat("/use snack")

            elseif activeNeed == "thirst" then

                sampSendChat("/use sprunk")

            elseif activeNeed == "candy" then
                sampSendChat("/use permen")

            elseif activeNeed == "bladder" then
                if not pissCooldown then
                    pissCooldown = true
                    pissCooldownEnd = os.time() + 10

                    sampSendChat("/piss")

                    lua_thread.create(function()
                        wait(300)
                        sendOtotH()
                   end)
                end
            end
        end
    end
end

local function resetNeedSystem()
    activeNeed = nil
    lastNeedCommand = 0
    pissCooldown = false
end

function sendOtotH()
    if ototHBusy then return end
    ototHBusy = true

    lua_thread.create(function()
        local success, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)

        if success then
            local data = allocateMemory(68)

            sampStorePlayerOnfootData(playerId, data)
            setStructElement(data, 36, 1, 192, false)
            sampSendOnfootData(data)

            freeMemory(data)
        end

        wait(500)
        ototHBusy = false
    end)
end

function sampev.onSetPlayerPos(x, y, z)
    if scriptEnabled[0] and antiAnimToggle[0] then
        return false
    end
end

function sampev.onApplyPlayerAnimation(...)
    if scriptEnabled[0] and antiAnimToggle[0] then
        return false
    end
end

function sampev.onTogglePlayerControllable(toggle)
    if scriptEnabled[0] and antiAnimToggle[0] then
        return false
    end
end

function sampev.onSetPlayerFacingAngle(angle)
    if scriptEnabled[0] and antiAnimToggle[0] then
        return false
    end
end

function handlePlayers()

    if not noPlayerCollision[0] then return end

    local px, py, pz = getCharCoordinates(PLAYER_PED)

    for i = 0, sampGetMaxPlayerId(false) do
        local ok, ped = sampGetCharHandleBySampPlayerId(i)

        if ok and ped ~= PLAYER_PED then

            local x, y, z = getCharCoordinates(ped)

            local dist = getDistanceBetweenCoords3d(
                px, py, pz,
                x, y, z
            )

            if dist <= 1.0 then
                setCharCollision(ped, false)
            end
        end
    end
end

function restorePlayersCollision()

    for i = 0, sampGetMaxPlayerId(false) do
        local ok, ped = sampGetCharHandleBySampPlayerId(i)

        if ok and ped ~= PLAYER_PED then
            setCharCollision(ped, true)
        end
    end
end

local walkIndex = 1
local walkTick = 0
local turning = false
local turnDir = 0
local turnTimer = 0
local TURN_TIME = 350
local TURN_ANGLE = 25


function getAngleDiff(a, b)
    local diff = a - b

    while diff > 180 do
        diff = diff - 360
    end

    while diff < -180 do
        diff = diff + 360
    end

    return diff
end

local function RadioButton(label, value, selected)
    local radius = 6

    local pos = imgui.GetCursorScreenPos()
    local draw = imgui.GetWindowDrawList()

    imgui.InvisibleButton("##"..label, imgui.ImVec2(18, 18))
    local clicked = imgui.IsItemClicked()

    local center = imgui.ImVec2(pos.x + 9, pos.y + 9)

    draw:AddCircle(center, radius, 0xFFFFFFFF, 24, 2)

    if selected == value then
        draw:AddCircleFilled(center, radius - 3, 0xFFFFFFFF, 24)
    end

    imgui.SameLine()
    imgui.Text(label)

    return clicked
end

function startTurn(prev, current, next)

    local dir1 = getHeadingFromVector2d(
        current[1] - prev[1],
        current[2] - prev[2]
    )

    local dir2 = getHeadingFromVector2d(
        next[1] - current[1],
        next[2] - current[2]
    )

    local diff = getAngleDiff(dir2, dir1)

    if math.abs(diff) > TURN_ANGLE then

        turning = true
        turnTimer = os.clock() * 1000 + TURN_TIME

        if diff > 0 then
            turnDir = -255
        else
            turnDir = 255
        end

    end
end

function updateAutoWalk()

    if not autoWalkEnabled or not isWalkPhase() then
        autoWalkEnabled = false
        setGameKeyState(1, 0)
        return
    end

    local point = walkCoordinates[walkIndex]
    if not point then
        autoWalkEnabled = false
        setGameKeyState(1, 0)
        walkIndex = 1
        return
    end

    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local tx, ty, tz = point[1], point[2], point[3]

    local dist = getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz)

    setCharHeading(PLAYER_PED, getHeadingFromVector2d(tx - px, ty - py))
    setGameKeyState(1, 255)

if dist <= 1.0 then

    local oldIndex = walkIndex

    walkIndex = walkIndex + 1

    if walkIndex > #walkCoordinates then

        autoWalkEnabled = false

        setGameKeyState(1,0)
        setGameKeyState(16,0)
        setGameKeyState(0,0)

        walkIndex = 1

        if phase[0] == 2 then
            setPhase(3)

        elseif phase[0] == 4 then
            setPhase(1)

        elseif phase[0] == 5 then
            setPhase(6)

        elseif phase[0] == 7 then
            setPhase(1)
        end

        return
    end

    local prev = walkCoordinates[oldIndex]
    local current = walkCoordinates[walkIndex]
    local nextPoint = walkCoordinates[walkIndex + 1]

    if prev and current and nextPoint then
        startTurn(prev, current, nextPoint)
      end
   end
end

local function getColor(v)
    v = tonumber(v) or 0

    if v < 20 then
        return imgui.ImVec4(1.0, 0.2, 0.2, 1.0)
    elseif v < 50 then
        return imgui.ImVec4(1.0, 0.7, 0.2, 1.0)
    else
        return imgui.ImVec4(0.2, 1.0, 0.5, 1.0)
    end
end

local function updateAnim(anim, state)
    local speed = 0.15
    if state then
        anim[0] = anim[0] + speed
        if anim[0] > 1 then anim[0] = 1 end
    else
        anim[0] = anim[0] - speed
        if anim[0] < 0 then anim[0] = 0 end
    end
end

local function drawNeedBars()
    local h = tonumber(hunger) or 0
    local t = tonumber(thirst) or 0
    local s = tonumber(candy) or 0
    local b = tonumber(bladder) or 0

    imgui.TextColored(getColor(h), "Lapar: " .. h .. "%")
    imgui.ProgressBar(h / 100, imgui.ImVec2(-1, 10), "")

    imgui.TextColored(getColor(t), "Haus: " .. t .. "%")
    imgui.ProgressBar(t / 100, imgui.ImVec2(-1, 10), "")

    imgui.TextColored(getColor(s), "Stres: " .. s .. "%")
    imgui.ProgressBar(s / 100, imgui.ImVec2(-1, 10), "")

    imgui.TextColored(getColor(b), "Kencing: " .. b .. "%")
    imgui.ProgressBar(b / 100, imgui.ImVec2(-1, 10), "")
end

imgui.OnFrame(
function()
    return window[0]
end,
function()

    imgui.SetNextWindowSize(imgui.ImVec2(500, 775))
    imgui.Begin( "  SION AUTO JOB ORE CPRP V3",
    window, imgui.WindowFlags.NoResize)
    
updateAnim(needAnim, enableNeedSystem[0])
updateAnim(animAntiAnim, antiAnimToggle[0])
updateAnim(animPlayer, noPlayerCollision[0])

    imgui.Text("Total Ambil Ore : " .. totalOre[0])
    imgui.SameLine(300)
    imgui.Text("Total Lebur Ore : " .. totalSmelt[0])
    imgui.Text("Total Penghasilan : ")
    imgui.SameLine(0, 0)
    imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), "$" .. totalMoney[0])

    imgui.SameLine(300)
    local cooldownText = "Tidak Ada"
    if sellCooldown then
        local remain = sellCooldownEnd - os.time()
        if remain < 0 then remain = 0 end
        cooldownText = tostring(remain) .. " Detik"
    end
    
    imgui.Text("Delay Job : " .. cooldownText)
    
    imgui.Dummy(imgui.ImVec2(0, 10))
    drawNeedBars()
imgui.Dummy(imgui.ImVec2(0, 10))

imgui.SetNextItemWidth(-1)
local preview = "Pilih Fase"
if phase[0] ~= 0 then preview = phaseName[phase[0]]
end

if imgui.BeginCombo("##phasecombo", preview) then
    for i = 1, 7 do
        if phaseName[i] then
            if imgui.Selectable(phaseName[i], selectedPhase[0] == i) then
                setPhase(i)
            end
        end
    end
    imgui.EndCombo()
end

    local phaseText = "Tidak Aktif"
    if scriptEnabled[0] then
        if phase[0] == 2 then phaseText = "Jalan Ke Peleburan"
        elseif phase[0] == 3 then phaseText = "Lebur Ore"
        elseif phase[0] == 4 then phaseText = "Jalan Ke Ambil Ore"
        elseif phase[0] == 5 then phaseText = "Jalan Ke Jual Ore"
        elseif phase[0] == 6 then phaseText = "Jual Ore"
        elseif phase[0] == 7 then phaseText = "Balik Ambil Ore"
        elseif phase[0] == 1 then phaseText = "Ambil Ore"
        end
    end
    
    imgui.Text("FASE : " .. phaseText)

imgui.Dummy(imgui.ImVec2(0, 5))
    if scriptEnabled[0] then
        imgui.TextColored(imgui.ImVec4(0,1,0,1), "STATUS : RUNNING")
    else
        imgui.TextColored(imgui.ImVec4(1,0,0,1), "STATUS : STOPPED")
    end

    if not scriptEnabled[0] then
        if imgui.Button("START", imgui.ImVec2(-1, 40)) then
            scriptEnabled[0] = true
            
        if walkMode[0] == 1 then
           sampProcessChatInput("/djwosineakejsnakdknznsndjskskdjajsdjjsksjdjsjejxjsjfnnxakskzpakwnsnakqkskskkapqosjsndjsjsj")
          end

            local startPhase = selectedPhase[0]
            if startPhase == 0 then startPhase = 1 end

            walkIndex = 1
            autoWalkEnabled = false

            setPhase(startPhase)

 if startPhase == 2
or startPhase == 4
or startPhase == 5
or startPhase == 7 then
    loadPath(PATHS[startPhase])
    setWalk(true)
   end
end
    else
        if imgui.Button("STOP", imgui.ImVec2(-1, 40)) then
            scriptEnabled[0] = false
            if walkMode[0] == 1 then
                walkMode[0] = 0
                sampProcessChatInput("/djwosineakejsnakdknznsndjskskdjajsdjjsksjdjsjejxjsjfnnxakskzpakwnsnakqkskskkapqosjsndjsjsj")
            end
            sellRequestLock = false
            sellCooldown = false
            waitingOre = false
            waitingSmelt = false
            waitingSell = false
            pissCooldown = false
            pissBusy = false
            autoWalkEnabled = false
            walkIndex = 1
            enableNeedSystem[0] = false
            antiAnimToggle[0] = false
            setPhase(0)
            totalOre[0] = 0
            totalSmelt[0] = 0
            noPlayerCollision[0] = false
            noPedCollision[0] = false
            sellCooldownEnd = 0
            hunger = 0
            thirst = 0
            candy = 0
            bladder = 0
            cache = {}
            setGameKeyState(1,0)
        end
    end
    
imgui.Text("Pilih Mode Jalan:")
if RadioButton("Jalan Biasa", 0, walkMode[0]) then
    walkMode[0] = 0
    if scriptEnabled[0] then
    sampProcessChatInput("/djwosineakejsnakdknznsndjskskdjajsdjjsksjdjsjejxjsjfnnxakskzpakwnsnakqkskskkapqosjsndjsjsj")
    end
end

imgui.SameLine()

if RadioButton("Lari", 1, walkMode[0]) then
    walkMode[0] = 1
    if scriptEnabled[0] then
    sampProcessChatInput("/djwosineakejsnakdknznsndjskskdjajsdjjsksjdjsjejxjsjfnnxakskzpakwnsnakqkskskkapqosjsndjsjsj")
    end
end

imgui.Separator()
imgui.TextColored(imgui.ImVec4(0.0, 0.75, 1.0, 1), "BYPASS MENU")
imgui.Separator()

local startX = imgui.GetCursorPosX()
local startY = imgui.GetCursorPosY()

imgui.SetCursorPos(imgui.ImVec2(startX, startY))

if drawToggle("Auto Makan Minum DLL", enableNeedSystem[0], needAnim) then
    enableNeedSystem[0] = not enableNeedSystem[0]
end

imgui.SetCursorPos(imgui.ImVec2(startX + 250, startY))
if drawToggle("Anti Anim (From Yasid)", antiAnimToggle[0], animAntiAnim) then
    antiAnimToggle[0] = not antiAnimToggle[0]
end

imgui.SetCursorPos(imgui.ImVec2(startX, startY + 35))
if drawToggle("Tembus Player", noPlayerCollision[0], animPlayer) then
    noPlayerCollision[0] = not noPlayerCollision[0]
    
        if not noPlayerCollision[0] then
        restorePlayersCollision()
    end
end

imgui.Dummy(imgui.ImVec2(0, 20))

local avail = imgui.GetContentRegionAvail().x
local textSize = imgui.CalcTextSize(runningText)

runningPos = runningPos + (imgui.GetIO().DeltaTime * 100)

if runningPos > avail then
    runningPos = -textSize.x
end

local t = os.clock()
local glow = (math.sin(t * 3) + 1) * 0.5

imgui.SetCursorPosX(runningPos)

imgui.TextColored(
    imgui.ImVec4(
        0.0 + glow * 0.2,
        0.7 + glow * 0.3,
        1.0,
        1.0
    ),
    runningText
)

imgui.Dummy(imgui.ImVec2(0, 20))

local fullW = imgui.GetContentRegionAvail().x

local btnW = (fullW - 8) * 0.5
local btnH = 32

imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.8,0.1,0.1,1))
imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1,0.2,0.2,1))
imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.6,0.05,0.05,1))

if imgui.Button(" YouTube", imgui.ImVec2(btnW, btnH)) then
    openLink(URL_YT)
end

imgui.PopStyleColor(3)

imgui.SameLine()

imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.05,0.05,0.05,1))
imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12,0.12,0.12,1))
imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.01,0.01,0.01,1))

if imgui.Button(" TikTok", imgui.ImVec2(btnW, btnH)) then
    openLink(URL_TIKTOK)
end

imgui.PopStyleColor(3)

local centerPos = (fullW - btnW) * 0.5
imgui.SetCursorPosX(centerPos)

imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.145, 0.827, 0.400, 1.0))
imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.90, 0.48, 1.0))
imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.10, 0.70, 0.32, 1.0))

if imgui.Button(" Saluran WA", imgui.ImVec2(btnW, btnH)) then
    openLink(URL_WA)
end

imgui.PopStyleColor(3)

    imgui.End()
end)

function sampev.onServerMessage(color, text)

    if not scriptEnabled[0] then return end
    if not text then return end

    if text:find("You have taken the ore") then
        phase[0] = 2
        totalOre[0] = totalOre[0] + 1
        waitingOre = false
        oreStockEmpty = false

if loadPath(PATHS[2]) then
    setWalk(true)
end

    elseif text:find("Stock is less than 1") then
        oreStockEmpty = true
        waitingOre = false

    elseif text:find("finished smelting ore") then
        totalSmelt[0] = totalSmelt[0] + 1
        waitingSmelt = false
        phase[0] = 4

if loadPath(PATHS[4]) then
    setWalk(true)
end

    elseif text:find("cannot carry more than 30 smelted ores") then
        waitingSmelt = false
        phase[0] = 5

if loadPath(PATHS[5]) then
    setWalk(true)
end

    elseif text:find("You have sold 1 ore item for") then
        sellRequestLock = false

        local money = tonumber(text:match("%$(%d+)")) or 0
        totalMoney[0] = totalMoney[0] + money
        waitingSell = false

    elseif text:find("You don't have any smelted ore") then
        setPhase(7)

if loadPath(PATHS[7]) then
    setWalk(true)
end

elseif text:find("You are currently holding ore, please smelt it first", 1, true) then
    phase[0] = 2
    waitingOre = false

    sampAddChatMessage("{39C0FF}[Auto Ore]{FFFFFF} Ore Belum Di Lebur, Auto Pindah Fase", -1)

if loadPath(PATHS[2]) then
    setWalk(true)
end

    elseif text:find("You must be at the ore collection point")
        or text:find("You must be at the ore collection/selling point")
        or text:find("You are not a miner") then

sampAddChatMessage("{39C0FF}[Auto Ore] " .. text, -1)
return
    end

    if text:find("You must wait", 1, true) then

        local function parseCooldown(t)
            local clean = t
                :gsub("{%x%x%x%x%x%x}", "")
                :gsub("~%a~", "")
            return tonumber(clean:match("(%d+)%s*second"))
        end

        local sec = parseCooldown(text)
        if sec and sec > 0 and sec < 300 then
            sellCooldown = true
            sellCooldownEnd = os.time() + sec
            sellRequestLock = false
        end
    end
end

function main()
    repeat wait(0) until isSampAvailable()
 
    imgui.OnInitialize(function()
    applyTheme()
end)

    sampRegisterChatCommand("sionaore", function()
        window[0] = not window[0]
    end)
    lua_thread.create(function()
    wait(5000)
    sampAddChatMessage("{39C0FF}[Sion Auto Job Ore CPRP V3] {FFFFFF}Loaded, ketik {39C0FF}/sionaore {FFFFFF}buat buka UI.", -1)
    end)

    lua_thread.create(function()
        while true do
            wait(1000)

            if scriptEnabled[0] and enableNeedSystem[0] then
                updateHud()
                handleNeeds()
            end
        end
    end)
    
    lua_thread.create(function()
    while true do
        wait(100)

        if scriptEnabled[0] and noPlayerCollision[0]  then
                handlePlayers()
        end
    end
end)

    lua_thread.create(function()
        while true do
            wait(0)

            if scriptEnabled[0] then
                handlePlayers()
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(500)

            if sellCooldown and os.time() >= sellCooldownEnd then
                sellCooldown = false
                sellRequestLock = false
                sampAddChatMessage("{39C0FF}[Auto Ore]{FFFFFF} Cooldown Beres", -1)
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(1000)

            if scriptEnabled[0] then

                if phase[0] == 1 and not waitingOre then
                    waitingOre = true
                    sampSendChat("/ambilore")
                end

                if phase[0] == 3 and not waitingSmelt then
                    waitingSmelt = true
                    sampSendChat("/leburore")
                end

                if phase[0] == 6 then
                    if not sellCooldown and not sellRequestLock then
                        sellRequestLock = true
                        lastSellTry = os.time()
                        sampSendChat("/jualore")
                    end
                end

            end
        end
    end)

    while true do
        wait(0)

        if scriptEnabled[0] then
            updateAutoWalk()
        end
    end
end