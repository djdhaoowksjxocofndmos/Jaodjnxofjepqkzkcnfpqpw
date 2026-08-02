script_name("Sion Detek Ore CPRP Siap Ga Siap Harus Siap")
script_author("Sion")

require "lib.moonloader"
require "lib.sampfuncs"
local imgui = require "mimgui"

local font = renderCreateFont("Arial", 12, 5)
local window = imgui.new.bool(false)

local ore = {}
local selectedTree = nil

function scanOre()
    ore = {}
    for id = 0,2048 do
    
        if sampIs3dTextDefined(id) then

            local ok,text,color,x,y,z =
                pcall(sampGet3dTextInfoById,id)

            if ok and text then

                local clean = tostring(text)
                    :gsub("{......}","")
                    :gsub("\n"," ")

                if clean:lower():find("ore",1,true) then

local timer = clean:match("%d%d:%d%d") or clean:match("%d%d%.%d%d")
local oreType = clean:match("%-%s*([^%)]+)")
local seconds = nil

if timer then
    local m, s = timer:match("(%d+)[%:%.]([%d]+)")
    if m and s then
        seconds = tonumber(m) * 60 + tonumber(s)
    end
end

table.insert(ore,{
    id = id,
    text = clean,
    x = tonumber(x),
    y = tonumber(y),
    z = tonumber(z),
    timer = seconds,
    oreType = oreType or "Unknown",
    lastUpdate = os.time()
})
              end
           end
        end
     end
  end

local function isInFrontOfCamera(x, y, z)

    local cx, cy, cz = getActiveCameraCoordinates()
    local tx, ty, tz = getActiveCameraPointAt()

    if not cx or not cy or not cz or not tx or not ty or not tz then
        return true
    end

    local fx = tx - cx
    local fy = ty - cy
    local fz = tz - cz

    local vx = x - cx
    local vy = y - cy
    local vz = z - cz

    local dot = (fx * vx) + (fy * vy) + (fz * vz)

    return dot > 0
end

function Draw3DLine(x1, y1, z1, x2, y2, z2, steps, color)

    if not isInFrontOfCamera(x2, y2, z2) then
        return
    end

    steps = steps or 25

    local last_sx, last_sy

    for i = 0, steps do

        local t = i / steps

        local x = x1 + (x2 - x1) * t
        local y = y1 + (y2 - y1) * t
        local z = z1 + (z2 - z1) * t

        local sx, sy = convert3DCoordsToScreen(x, y, z)

        if sx and sy then

            if last_sx then
                renderDrawLine(last_sx, last_sy, sx, sy, 6, 0x5500BFFF)
                renderDrawLine(last_sx, last_sy, sx, sy, 2, color)
            end

            last_sx = sx
            last_sy = sy

        else
            last_sx = nil
            last_sy = nil
        end
    end

    local px, py, pz = getCharCoordinates(PLAYER_PED)

    local dx = x2 - px
    local dy = y2 - py
    local dz = z2 - pz

    local distance = math.sqrt(
        dx * dx +
        dy * dy +
        dz * dz
    )


    local tx, ty = convert3DCoordsToScreen(
        x2,
        y2,
        z2 + 1.0
    )

    if tx and ty then

local line1 = "TUJUAN LU DISINI"
local line2 = string.format("%.1fm", distance)

local w1 = renderGetFontDrawTextLength(font, line1)
local w2 = renderGetFontDrawTextLength(font, line2)

renderFontDrawText(font, line1, tx - w1/2, ty, 0xFF00BFFF)
renderFontDrawText(font, line2, tx - w2/2, ty + 15, 0xFF00BFFF)
    end
end

function drawOreLine()
    if not selectedTree then
        return
    end

    local px, py, pz = getCharCoordinates(PLAYER_PED)

    Draw3DLine(
        px,
        py,
        pz,
        selectedTree.x,
        selectedTree.y,
        selectedTree.z,
        25,
        0xFF00BFFF
    )
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

imgui.OnFrame(function() return window[0] end, function()
local title = " SION DETEK ORE CPRP SIAP GA SIAP HARUS SIAP"
imgui.SetNextWindowSizeConstraints(imgui.ImVec2(440, 0), imgui.ImVec2(math.huge, math.huge))
imgui.Begin(title, window, imgui.WindowFlags.AlwaysAutoResize+ imgui.WindowFlags.NoScrollbar)

    if imgui.Button("SCAN ORE", imgui.ImVec2(-1,40)) then
        scanOre()
    end

 imgui.Separator()

local buttonWidth=200
local buttonHeight=70
local columnCount = math.ceil(#ore/5)

for col=0,columnCount-1 do

    if col>0 then
        imgui.SameLine()
    end

    imgui.BeginGroup()

    for row=1,5 do

        local index=row+(col*5)

        if ore[index] then

            local v=ore[index]

            if v.timer then
                local now=os.time()
                local diff=now-v.lastUpdate
                if diff>0 then
                    v.timer=v.timer-diff
                    v.lastUpdate=now
                end
            end

            local line1
            local line2=""
            local line3=v.oreType

            if v.timer and v.timer>0 then
                local menit=math.floor(v.timer/60)
                local detik=v.timer%60
                line1="Ore Ga Siap"
                line2=string.format("%02d:%02d",menit,detik)
            else
                line1="Ore Siap"
            end

            local size1=imgui.CalcTextSize(line1)
            local size2=imgui.CalcTextSize(line2)
            local size3=imgui.CalcTextSize(line3)

if imgui.Button("##"..index,imgui.ImVec2(buttonWidth,buttonHeight)) then
    selectedTree = v
end

            local pos=imgui.GetItemRectMin()
            local bw=imgui.GetItemRectSize().x

            local function drawCenter(text,y)
                if text=="" then return end
                local size=imgui.CalcTextSize(text)
                imgui.SetCursorScreenPos(imgui.ImVec2(pos.x+(bw-size.x)/2,y))
                imgui.Text(text)
            end

if line2 ~= "" then
    drawCenter(line1,pos.y+5)
    drawCenter(line2,pos.y+25)
    drawCenter(line3,pos.y+45)
else
    drawCenter(line1,pos.y+15)
    drawCenter(line3,pos.y+35)
end

imgui.SetCursorScreenPos(
    imgui.ImVec2(
        pos.x,
        pos.y + buttonHeight + 8
    )
)
        end
    end

    imgui.EndGroup()
end
    imgui.End()
end)

function main()
 repeat wait(100) until isSampAvailable()
imgui.OnInitialize(function() applyTheme() end)
sampRegisterChatCommand("sdo", function() window[0] = not window[0] end)

lua_thread.create(function()
    wait(5000)
    sampAddChatMessage("{39C0FF}[Sion Detek Ore CPRP Siap Ga Siap Harus Siap] {FFFFFF}Loaded, ketik {39C0FF}/sdo {FFFFFF}buat buka UI.", -1)
end)

    while true do
        wait(0)
        drawOreLine()
    end
end