-- =====================================================================
-- JEN FINDER — Auto-Save Button Position, All-Pink, Instant Auto Join
-- + Loading Screen (fills 1s to 100%, THEN teleports)
-- + Name Tags ([Owner] Jen Finder / Jen Finder User) — script-users only
-- =====================================================================

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")
local LocalPlayer  = Players.LocalPlayer
local CoreGui      = game:GetService("CoreGui")

local GENV = (getgenv and getgenv()) or _G
GENV.__FinderGen = (GENV.__FinderGen or 0) + 1
local MY_GEN = GENV.__FinderGen
local function alive() return GENV.__FinderGen == MY_GEN end

-- =====================================================================
-- RESET TIMER (5-Minute Cycle)
-- =====================================================================
local function getResetInfo()
    local now = workspace:GetServerTimeNow()
    local interval = 300
    local nextResetUnix = (math.floor(now / interval) + 1) * interval
    local remaining = nextResetUnix - now
    return { resetAt = nextResetUnix * 1000, remaining = remaining, running = true }
end

-- =====================================================================
-- COLOR PALETTE
-- =====================================================================
local PINK       = Color3.fromRGB(236, 72, 153)
local PINK_LT    = Color3.fromRGB(255, 105, 180)
local PINK_HOT   = Color3.fromRGB(255, 60, 150)
local PINK_DK    = Color3.fromRGB(190, 24, 93)
local PINK_MID   = Color3.fromRGB(210, 50, 130)
local PINK_PALE  = Color3.fromRGB(255, 200, 225)
local PANEL_BG   = Color3.fromRGB(34, 16, 26)
local ROW_BG     = Color3.fromRGB(52, 24, 40)
local CHIP_BG    = Color3.fromRGB(85, 40, 65)
local INPUT_BG   = Color3.fromRGB(60, 26, 46)
local JOIN_BG    = PINK
local REFRESH_BG = PINK_DK
local CLOSE_BG   = Color3.fromRGB(230, 50, 130)
local AUTO_BG    = Color3.fromRGB(110, 30, 80)
local HERE_BG    = Color3.fromRGB(80, 220, 140)

-- =====================================================================
-- TOGGLE IMAGE
-- =====================================================================
local TOGGLE_IMAGE_URL = "https://raw.githubusercontent.com/mallu837/sae/main/Jen.png"
local TOGGLE_IMAGE_LOCAL = "JenFinderToggle.png"

local toggleImage = nil
pcall(function()
    if isfile and isfile(TOGGLE_IMAGE_LOCAL) then
        local loader = getcustomasset or getsynasset
        if loader then
            toggleImage = loader(TOGGLE_IMAGE_LOCAL)
            return
        end
    end
    if writefile then
        local ok, res = pcall(function()
            return game:HttpGet(TOGGLE_IMAGE_URL, true)
        end)
        if ok and type(res) == "string" and #res > 200 then
            pcall(writefile, TOGGLE_IMAGE_LOCAL, res)
            local loader = getcustomasset or getsynasset
            if loader then
                toggleImage = loader(TOGGLE_IMAGE_LOCAL)
            end
        end
    end
end)

-- =====================================================================
-- TELEPORT ERROR HELPER
-- =====================================================================
GENV.__ChilliTpWhy = function(result)
    local rs = tostring(result or "")
    if rs:find("GameFull") then return "full"
    elseif rs:find("GameEnded") or rs:find("GameNotFound") then return "gone"
    elseif rs:find("Flooded") then return "flood"
    elseif rs:find("Unauthorized") then return "denied" end
    return "fail"
end

-- =====================================================================
-- CONSTANTS
-- =====================================================================
local EGG_KEY        = "k109"
local EGG_SHARE_URL  = "https://my.tomroblox.com/egg"
local GV_LEVELS      = {50e6, 100e6, 300e6, 500e6, 1e9, 5e9, 10e9}
local GV_LABELS      = {"50M/s", "100M/s", "300M/s", "500M/s", "1B/s", "5B/s", "10B/s"}
local GV_FILE        = "JenFinder_GV.txt"
local GV_SORT_FILE   = "JenFinder_Sort.txt"
local GV_AUTO_FILE   = "JenFinder_AutoJoin.txt"
local GV_AUTOON_FILE = "JenFinder_AutoOn.txt"
local GV_BTN_POS     = "JenFinder_BtnPos.txt"
local GV_LASTHOP_FILE = "JenFinder_LastHop.txt"
local GV_RAND_POWER  = 0.6

local currentLanguage = "EN"
local GV_IDX = 5
local GV_SORT = 1
local AUTO_JOIN_V = 1e9
local AUTO_JOIN_ON_SAVED = false
local LAST_HOP_AT = 0
local GV_TRIED = {}

pcall(function()
    if isfile and readfile and isfile(GV_FILE) then
        local n = tonumber(readfile(GV_FILE):match("%d+"))
        if n and n >= 1 and n <= #GV_LEVELS then GV_IDX = n end
    end
end)
pcall(function()
    if isfile and readfile and isfile(GV_SORT_FILE) then
        local n = tonumber(readfile(GV_SORT_FILE):match("%d+"))
        if n and n >= 1 and n <= 4 then GV_SORT = n end
    end
end)
pcall(function()
    if isfile and readfile and isfile(GV_AUTO_FILE) then
        local txt = readfile(GV_AUTO_FILE)
        local n = tonumber(txt and txt:match("[%d%.]+") or "")
        if n and n > 0 then AUTO_JOIN_V = n end
    end
end)
pcall(function()
    if isfile and readfile and isfile(GV_AUTOON_FILE) then
        local txt = readfile(GV_AUTOON_FILE) or ""
        AUTO_JOIN_ON_SAVED = txt:match("1") ~= nil
    end
end)
pcall(function()
    if isfile and readfile and isfile(GV_LASTHOP_FILE) then
        LAST_HOP_AT = tonumber(readfile(GV_LASTHOP_FILE)) or 0
    end
end)

-- =====================================================================
-- /s INPUT HELPERS
-- =====================================================================
local function parseSInput(txt)
    if not txt or txt == "" then return nil end
    txt = tostring(txt):lower():gsub("%s", ""):gsub(",", "")
    txt = txt:gsub("/s$", ""):gsub("/s", "")
    local num, suf = txt:match("^([%d%.]+)([a-z]?)$")
    if not num then return nil end
    num = tonumber(num)
    if not num or num <= 0 then return nil end
    local SUF = {k=1e3, m=1e6, b=1e9, t=1e12, q=1e15, a=1e18, s=1e21, x=1e24}
    return num * (SUF[suf] or 1)
end

local function formatSInput(v)
    v = tonumber(v) or 0
    if v <= 0 then return "" end
    local units = {
        {1e24,"X"},{1e21,"S"},{1e18,"A"},{1e15,"Q"},
        {1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}
    }
    for _, u in ipairs(units) do
        if v >= u[1] then
            local t = string.format("%.2f", v / u[1]):gsub("0+$", ""):gsub("%.$", "")
            return t .. u[2] .. "/s"
        end
    end
    return string.format("%d/s", v)
end

-- =====================================================================
-- DATA HELPERS
-- =====================================================================
local GV_U, GV_UN = {}, 0
local function gvU(jobId)
    local u = GV_U[jobId]
    if not u then
        if GV_UN >= 1500 then GV_U = {}; GV_UN = 0 end
        u = math.min(0.9999, math.max(0.0001, math.random()))
        GV_U[jobId] = u; GV_UN = GV_UN + 1
    end
    return u
end

local function gvFmt(v)
    v = tonumber(v) or 0
    local units = {{1e33,"Dc"},{1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qi"},
                   {1e15,"Qa"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
    for _, u in ipairs(units) do
        if v >= u[1] then
            local t = string.format("%.2f", v / u[1]):gsub("0+$", ""):gsub("%.$", "")
            return t .. u[2] .. "/s"
        end
    end
    return string.format("%d/s", v)
end

local function gvFetch(url, key)
    GENV.__ChilliGVErr = nil
    local raw, status, got = nil, nil, false
    local req = (syn and syn.request) or (http and http.request) or http_request or request
        or (fluxus and fluxus.request)
    if key and req then
        local ok2, r2 = pcall(req, {Url = url, Method = "GET",
            Headers = {["Accept"] = "application/json", ["X-K"] = key}})
        if ok2 and type(r2) == "table" then
            got = true
            status = tonumber(r2.StatusCode)
            if type(r2.Body) == "string" and #r2.Body > 10 and (not status or status < 400) then
                raw = r2.Body
            end
        end
    end
    if not raw then
        local u = key and (url .. "?k=" .. key) or url
        local ok, res = pcall(function() return game:HttpGet(u) end)
        if ok and type(res) == "string" and #res > 10 then raw = res; got = true end
    end
    if not raw then
        if status and (status >= 500 or status == 429) then GENV.__ChilliGVErr = "busy"
        elseif status and status >= 400 then GENV.__ChilliGVErr = "denied"
        elseif got then GENV.__ChilliGVErr = "bad"
        else GENV.__ChilliGVErr = "net" end
        return nil
    end
    local dOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if dOk and type(data) == "table" then return data end
    GENV.__ChilliGVErr = "bad"
    return nil
end

local function gvLoad()
    local urls = {{EGG_SHARE_URL .. "/q7", own = true}}
    local results, pending = {}, #urls
    for i, u in ipairs(urls) do
        task.spawn(function()
            local ok, d = pcall(gvFetch, u[1], u.own and EGG_KEY or nil)
            results[i] = (ok and d) or false
            pending = pending - 1
        end)
    end
    local t0 = os.clock()
    while pending > 0 and os.clock() - t0 < 4 do task.wait(0.1) end
    local srcs = {}
    local nowL = os.time() * 1000
    for i, u in ipairs(urls) do
        local d = results[i]
        if d then
            if u.own then
                for _, e in ipairs(d) do
                    if type(e) == "table" and tonumber(e.ageMs) then
                        e.timestamp = nowL - tonumber(e.ageMs)
                    end
                end
            end
            srcs[#srcs+1] = d
        end
    end
    if #srcs == 0 then return nil end
    if #srcs == 1 then return srcs[1] end
    local byJob, out = {}, {}
    local function add(e)
        if type(e) ~= "table" or type(e.jobId) ~= "string" then return end
        local cur = byJob[e.jobId]
        if not cur then
            local c = {}; for k, v in pairs(e) do c[k] = v end
            byJob[e.jobId] = c; out[#out+1] = c
        else
            if type(e.value) == "number" and (type(cur.value) ~= "number" or e.value > cur.value) then
                cur.value = e.value; cur.petName = e.petName or cur.petName
                if e.iconId then cur.iconId = e.iconId end
            end
            for _, k in ipairs({"players","maxPlayers","rarityName","iconId","timestamp"}) do
                if cur[k] == nil and e[k] ~= nil then cur[k] = e[k] end
            end
        end
    end
    for _, d in ipairs(srcs) do for _, e in ipairs(d) do add(e) end end
    return out
end

local function gvFilter(list, minV, useTried, includeCurrent)
    local best = {}
    for _, e in ipairs(list) do
        if type(e) == "table" and type(e.jobId) == "string" and type(e.value) == "number"
            and e.value >= minV and (includeCurrent or e.jobId ~= game.JobId)
            and not (useTried and GV_TRIED[e.jobId]) then
            local pl, mx = tonumber(e.players), tonumber(e.maxPlayers)
            local full = pl and mx and mx > 0 and pl >= mx
            if not full or e.jobId == game.JobId then
                local cur = best[e.jobId]
                if not cur or e.value > cur.value then
                    best[e.jobId] = {
                        jobId = e.jobId, value = e.value,
                        pet = (tostring(e.petName or "Rare Pet"):gsub("%s+"," ")),
                        players = pl, maxPlayers = mx, ts = tonumber(e.timestamp),
                        icon = tostring(e.iconId or ""),
                        rarity = tostring(e.rarityName or "")
                    }
                end
            end
        end
    end
    local out = {}
    for _, v in pairs(best) do out[#out+1] = v end
    table.sort(out, function(a, b) return a.value > b.value end)
    return out
end

local function gvShuffle(items)
    local keyOf = {}
    for _, it in ipairs(items) do
        local w = (math.max(it.value or 1, 1) ^ GV_RAND_POWER)
        local pl, mx = tonumber(it.players), tonumber(it.maxPlayers)
        local free = (pl and mx and mx > 0) and math.max(0, (mx - pl) / mx) or 0.5
        w = w * (0.4 + 0.6 * free)
        keyOf[it] = math.log(gvU(it.jobId or "")) / w
    end
    local out = {}
    for i, it in ipairs(items) do out[i] = it end
    table.sort(out, function(a, b) return keyOf[a] > keyOf[b] end)
    return out
end

local function gvErrText()
    local e = GENV.__ChilliGVErr
    if e == "net" then return "No connection"
    elseif e == "denied" or e == "bad" then return "No data from server" end
    return "Server overloaded"
end

-- =====================================================================
-- LOADING SCREEN — 1s fill to 100%, THEN teleport fires
-- =====================================================================
local function showJoinLoader()
    local okGui, playerGui = pcall(function()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
            or LocalPlayer:WaitForChild("PlayerGui", 3)
    end)
    if not okGui or not playerGui then return nil end

    local prev = playerGui:FindFirstChild("JenFinderFloatingLoader")
    if prev then prev:Destroy() end

    local DURATION    = 1  -- 1.0 second flat
    local GAME_NAME   = "JEN FINDER"
    local STATUS_TEXT = "Joining Server"
    local DISCORD_LINK = "https://discord.gg/GFZYsspybS"

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "JenFinderFloatingLoader"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 2147483647
    screenGui.Parent = playerGui

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(320, 135)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.ZIndex = 1
    card.Parent = screenGui

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = Color3.fromRGB(255, 105, 180)
    cardStroke.Thickness = 2.5
    cardStroke.Transparency = 0.15

    local cardGradient = Instance.new("UIGradient", card)
    cardGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 225)),
    }
    cardGradient.Rotation = 90

    local title = Instance.new("TextLabel", card)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0, 15)
    title.Size = UDim2.new(1, -80, 0, 24)
    title.BackgroundTransparency = 1
    title.Text = GAME_NAME
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(255, 20, 147)
    title.ZIndex = 2

    local percent = Instance.new("TextLabel", card)
    percent.AnchorPoint = Vector2.new(1, 0)
    percent.Position = UDim2.new(1, -20, 0, 18)
    percent.Size = UDim2.fromOffset(50, 20)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.Font = Enum.Font.GothamBlack
    percent.TextSize = 18
    percent.TextColor3 = Color3.fromRGB(255, 20, 147)
    percent.ZIndex = 2

    local status = Instance.new("TextLabel", card)
    status.AnchorPoint = Vector2.new(0.5, 1)
    status.Position = UDim2.new(0.5, 0, 1, -55)
    status.Size = UDim2.new(1, -40, 0, 16)
    status.BackgroundTransparency = 1
    status.Text = STATUS_TEXT
    status.Font = Enum.Font.GothamBold
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(180, 80, 130)
    status.ZIndex = 2

    task.spawn(function()
        local dots = 0
        while status.Parent do
            status.Text = STATUS_TEXT .. string.rep(".", dots)
            dots = (dots + 1) % 4
            task.wait(0.3)
        end
    end)

    local barBg = Instance.new("Frame", card)
    barBg.AnchorPoint = Vector2.new(0.5, 1)
    barBg.Position = UDim2.new(0.5, 0, 1, -40)
    barBg.Size = UDim2.new(0.85, 0, 0, 8)
    barBg.BackgroundColor3 = Color3.fromRGB(255, 210, 228)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 2
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame", barBg)
    barFill.Size = UDim2.fromScale(0, 1)
    barFill.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 3
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    local barGradient = Instance.new("UIGradient", barFill)
    barGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 147)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 190)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 20, 147)),
    }

    local discordBtn = Instance.new("TextButton", card)
    discordBtn.AnchorPoint = Vector2.new(0.5, 1)
    discordBtn.Position = UDim2.new(0.5, 0, 1, -12)
    discordBtn.Size = UDim2.new(1, -40, 0, 20)
    discordBtn.BackgroundTransparency = 1
    discordBtn.Text = "Discord Server"
    discordBtn.Font = Enum.Font.GothamMedium
    discordBtn.TextSize = 11
    discordBtn.TextColor3 = Color3.fromRGB(255, 20, 147)
    discordBtn.ZIndex = 2

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
            discordBtn.Text = "Copied! 💖"
            discordBtn.TextColor3 = Color3.fromRGB(255, 105, 180)
            task.wait(2)
            discordBtn.Text = "Discord Server"
            discordBtn.TextColor3 = Color3.fromRGB(255, 20, 147)
        else
            discordBtn.Text = DISCORD_LINK
        end
    end)

    local baseY = card.Position.Y.Scale
    local bob = 0
    local bobConn = RunService.RenderStepped:Connect(function(dt)
        if not card.Parent then
            if bobConn then bobConn:Disconnect() end
            return
        end
        bob = bob + dt * 2
        card.Position = UDim2.new(card.Position.X.Scale, 0, baseY + math.sin(bob) * 0.01, 0)
    end)

    local startTime = tick()
    local destroyed = false
    local currentPct = 0
    local fillConn = RunService.RenderStepped:Connect(function()
        if destroyed then return end
        local t = math.clamp((tick() - startTime) / DURATION, 0, 1)
        local eased = 1 - (1 - t) * (1 - t)
        currentPct = eased * 100
        percent.Text = string.format("%d%%", math.floor(currentPct))
        barFill.Size = UDim2.fromScale(eased, 1)
    end)

    local function fadeOutAndDestroy()
        if destroyed then return end
        destroyed = true
        pcall(function() if fillConn then fillConn:Disconnect() end end)
        pcall(function() if bobConn then bobConn:Disconnect() end end)
        local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        for _, obj in ipairs(screenGui:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                TweenService:Create(obj, fadeInfo, { TextTransparency = 1 }):Play()
            elseif obj:IsA("Frame") then
                TweenService:Create(obj, fadeInfo, { BackgroundTransparency = 1 }):Play()
            elseif obj:IsA("UIStroke") then
                TweenService:Create(obj, fadeInfo, { Transparency = 1 }):Play()
            end
        end
        task.wait(0.25)
        if screenGui.Parent then screenGui:Destroy() end
    end

    task.delay(20, function()
        if not destroyed then fadeOutAndDestroy() end
    end)

    return {
        waitFill = function()
            local t0 = tick()
            while not destroyed and tick() - t0 < DURATION + 0.1 do
                task.wait(0.05)
            end
            if not destroyed then
                percent.Text = "100%"
                barFill.Size = UDim2.fromScale(1, 1)
                if fillConn then fillConn:Disconnect() end
            end
        end,
        fail = function()
            fadeOutAndDestroy()
        end,
        destroy = function()
            fadeOutAndDestroy()
        end,
    }
end

-- =====================================================================
-- HOP — instant teleport (with 1s loading screen, THEN teleport)
-- =====================================================================
local function hopHighValue(minV, only, cachedCands)
    if GENV.__ChilliHopBusy and os.clock() - (GENV.__ChilliHopAt or 0) < 60 then return end
    GENV.__ChilliHopBusy = true
    GENV.__ChilliHopAt = os.clock()

    task.spawn(function()
        local TeleportSvc = game:GetService("TeleportService")
        local placeId     = game.PlaceId

        local list, cand
        if cachedCands and #cachedCands > 0 then
            list, cand = true, cachedCands
        elseif only then
            list, cand = true, {only}
        else
            list = gvLoad()
            cand = list and gvFilter(list, minV, true) or {}
        end
        if not cachedCands and not only and list and #cand == 0 and next(GV_TRIED) then
            table.clear(GV_TRIED)
            cand = gvFilter(list, minV, false)
        end

        if list and #cand > 0 then
            for i = 1, math.min(#cand, 8) do
                if not alive() then break end
                local sv = cand[i]
                GV_TRIED[sv.jobId] = true

                local loader = nil
                pcall(function() loader = showJoinLoader() end)

                if loader then
                    pcall(function() loader.waitFill() end)  -- yields 1s
                else
                    task.wait(1)  -- fallback if UI failed
                end

                if not alive() then
                    if loader then pcall(loader.destroy) end
                    break
                end

                local failed, conn, why = false, nil, "fail"
                pcall(function()
                    conn = TeleportSvc.TeleportInitFailed:Connect(function(plr, result)
                        if plr == LocalPlayer then
                            failed = true
                            why = GENV.__ChilliTpWhy(result)
                            pcall(function() game:GetService("GuiService"):ClearError() end)
                        end
                    end)
                end)

                local ok = pcall(function()
                    TeleportSvc:TeleportToPlaceInstance(placeId, sv.jobId, LocalPlayer)
                end)

                if not ok then
                    failed = true
                else
                    local t0 = os.clock()
                    while os.clock() - t0 < 1.5 and not failed do
                        task.wait(0.1)
                    end
                end

                if conn then pcall(function() conn:Disconnect() end) end

                if failed then
                    if loader then pcall(loader.fail) end
                    task.wait(why == "flood" and 3.5 or 0.3)
                else
                    pcall(function()
                        if writefile then
                            writefile(GV_LASTHOP_FILE, tostring(os.time()))
                        end
                    end)
                    LAST_HOP_AT = os.time()
                    break
                end
            end
        end

        GENV.__ChilliHopBusy = false
    end)
end

-- =====================================================================
-- JEN FINDER PANEL
-- =====================================================================
local function createGVBar()
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("JenFinderList")
    if old then old:Destroy() end

    local lsg, lpn, lrows, ltitle, lstatus, lscale, resetLbl
    local bSort, bRar, bLvl, bAuto, bAutoJoin, bRef, autoInput
    local GV_RARITY = nil
    local SORT_NAMES = {"Random", "Value", "Newest", "Fewest"}
    local CACHE = {list = nil, at = 0}
    local PANEL_AUTO = false
    local AUTO_JOIN_ON = AUTO_JOIN_ON_SAVED
    local autoLoopActive = false
    local lastAutoClearAt = 0
    local LAST_RESET_AT = 0

    local function saveAutoState()
        pcall(function()
            if writefile then
                writefile(GV_AUTOON_FILE, AUTO_JOIN_ON and "1" or "0")
            end
        end)
        AUTO_JOIN_ON_SAVED = AUTO_JOIN_ON
    end

    local function tierColor(v)
        if v >= 1e10 then return Color3.fromRGB(255, 96, 80) end
        if v >= 5e9  then return Color3.fromRGB(255, 200, 70) end
        if v >= 1e9  then return Color3.fromRGB(200, 120, 255) end
        if v >= 1e8  then return Color3.fromRGB(80, 220, 140) end
        return Color3.fromRGB(120, 170, 230)
    end

    local function updateAutoBtn()
        if not bAutoJoin then return end
        if AUTO_JOIN_ON then
            bAutoJoin.Text = "● Auto Join: ON"
            bAutoJoin.BackgroundColor3 = PINK
        else
            bAutoJoin.Text = "Auto Join: OFF"
            bAutoJoin.BackgroundColor3 = AUTO_BG
        end
    end

    local function updateStatusLine()
        if not lstatus then return end
        if AUTO_JOIN_ON then
            lstatus.Text = "🔍 Auto Join ≥ " .. formatSInput(AUTO_JOIN_V)
            lstatus.TextColor3 = PINK_LT
            lstatus.Visible = true
        else
            lstatus.Visible = false
        end
    end

    local function closeList()
        if lsg then lsg.Enabled = false end
    end

    local function clearRows()
        for _, c in ipairs(lrows:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
    end

    local function refreshChips()
        bLvl.Text = "From " .. GV_LABELS[GV_IDX]
        bSort.Text = "Sort: " .. SORT_NAMES[GV_SORT]
        bRar.Text = "Rarity: " .. (GV_RARITY or "All")
        if bAuto then bAuto.Text = "Join " .. formatSInput(AUTO_JOIN_V) end
    end

    local function render()
        if not (lsg and lsg.Parent and lsg.Enabled) then return end
        clearRows()
        local minV = GV_LEVELS[GV_IDX]
        local list = CACHE.list
        if not list then
            ltitle.Text = "High eggs: 0"
            refreshChips()
            return
        end

        local items = gvFilter(list, minV, false, true)
        local seen, rars = {}, {}
        for _, it in ipairs(items) do
            if it.rarity ~= "" and not seen[it.rarity] then
                seen[it.rarity] = true; rars[#rars+1] = it.rarity
            end
        end
        table.sort(rars)
        if GV_RARITY and not seen[GV_RARITY] then GV_RARITY = nil end
        refreshChips()

        local currentServer = nil
        local otherItems = {}
        for _, it in ipairs(items) do
            if it.jobId == game.JobId then
                currentServer = it
            else
                if not GV_RARITY or it.rarity == GV_RARITY then
                    table.insert(otherItems, it)
                end
            end
        end

        if GV_SORT == 1 then otherItems = gvShuffle(otherItems)
        elseif GV_SORT == 3 then table.sort(otherItems, function(a,b) return (a.ts or 0) > (b.ts or 0) end)
        elseif GV_SORT == 4 then
            table.sort(otherItems, function(a,b)
                local pa, pb = a.players or 99, b.players or 99
                if pa ~= pb then return pa < pb end
                return a.value > b.value
            end)
        end

        local shown = {}
        if currentServer then table.insert(shown, currentServer) end
        for _, it in ipairs(otherItems) do table.insert(shown, it) end

        ltitle.Text = "High eggs: " .. #shown
        local nowMs = os.time() * 1000

        for i = 1, math.min(#shown, 50) do
            local it = shown[i]
            local isHere = (it.jobId == game.JobId)
            local col = tierColor(it.value)

            local row = Instance.new("Frame")
            row.LayoutOrder = i
            row.Size = UDim2.new(1,-6,0,46)
            row.BackgroundColor3 = ROW_BG
            row.BorderSizePixel = 0
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,9); rc.Parent = row
            local rs = Instance.new("UIStroke")
            rs.Thickness = isHere and 2.5 or 1.3
            rs.Color = isHere and HERE_BG or PINK_LT
            rs.Transparency = isHere and 0 or 0.35
            rs.Parent = row

            local bar2 = Instance.new("Frame")
            bar2.Size = UDim2.new(0,3,0.6,0)
            bar2.Position = UDim2.new(0,3,0.2,0)
            bar2.BackgroundColor3 = col
            bar2.BorderSizePixel = 0
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1,0); bc.Parent = bar2
            bar2.Parent = row

            local img = Instance.new("ImageLabel")
            img.Position = UDim2.new(0,10,0.5,-17)
            img.Size = UDim2.fromOffset(34,34)
            img.BackgroundColor3 = Color3.fromRGB(24,10,20)
            img.BorderSizePixel = 0
            img.ScaleType = Enum.ScaleType.Fit
            if it.icon ~= "" then img.Image = "rbxassetid://" .. it.icon end
            local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,8); ic.Parent = img
            img.Parent = row

            local nm = Instance.new("TextLabel")
            nm.BackgroundTransparency = 1
            nm.Position = UDim2.new(0,50,0,3)
            nm.Size = UDim2.new(1,-108,0,18)
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.TextColor3 = Color3.new(1,1,1)
            nm.Text = it.pet
            nm.Parent = row

            local vl = Instance.new("TextLabel")
            vl.BackgroundTransparency = 1
            vl.Position = UDim2.new(0,50,0,20)
            vl.Size = UDim2.new(1,-108,0,13)
            vl.Font = Enum.Font.GothamBlack
            vl.TextSize = 11
            vl.TextXAlignment = Enum.TextXAlignment.Left
            vl.TextColor3 = col
            vl.Text = gvFmt(it.value) .. (it.rarity ~= "" and (" • " .. it.rarity) or "")
            vl.Parent = row

            local ageTxt, stale = "", false
            if it.ts and it.ts > 1e11 then
                local ageSecs = math.max(0, (nowMs - it.ts) / 1000)
                local remaining = math.clamp(math.ceil(300 - ageSecs), 0, 300)
                ageTxt = tostring(math.floor((300 - remaining) / 60)) .. 'm ago'
                stale = ageSecs >= 60
            end

            local pc = (it.players and it.maxPlayers)
                and (it.players .. "/" .. it.maxPlayers .. " players")
                or "players unknown"
            local sb = Instance.new("TextLabel")
            sb.BackgroundTransparency = 1
            sb.Position = UDim2.new(0,50,0,32)
            sb.Size = UDim2.new(1,-108,0,12)
            sb.Font = Enum.Font.Gotham
            sb.TextSize = 10
            sb.TextXAlignment = Enum.TextXAlignment.Left
            sb.TextColor3 = stale and Color3.fromRGB(255,170,90) or PINK_PALE
            sb.Text = pc .. ((pc ~= "" and ageTxt ~= "") and " • " or "") .. ageTxt
            sb.Parent = row

            local jb = Instance.new("TextButton")
            jb.AnchorPoint = Vector2.new(1,0.5)
            jb.Position = UDim2.new(1,-6,0.5,0)
            jb.Size = UDim2.fromOffset(52,30)
            jb.BorderSizePixel = 0
            jb.AutoButtonColor = false
            jb.Font = Enum.Font.GothamBold
            jb.TextSize = 13
            jb.TextColor3 = Color3.new(1,1,1)
            jb.TextStrokeTransparency = 0.55

            if isHere then
                jb.Text = "HERE"
                jb.BackgroundColor3 = HERE_BG
                jb.Activated:Connect(function() closeList() end)
            else
                jb.Text = "Join"
                jb.BackgroundColor3 = JOIN_BG
                jb.Activated:Connect(function()
                    if not alive() then return end
                    closeList()
                    hopHighValue(minV, it)
                end)
            end

            local jc = Instance.new("UICorner"); jc.CornerRadius = UDim.new(0,8); jc.Parent = jb
            jb.Parent = row

            row.Parent = lrows
        end
    end

    local function loadList(force)
        if not lsg then return end
        if not force and CACHE.list and os.clock() - CACHE.at < 15 then render(); return end
        clearRows()
        ltitle.Text = "Loading..."
        refreshChips()
        task.spawn(function()
            local list = gvLoad()
            CACHE.list = list
            CACHE.at = os.clock()
            render()
        end)
    end

    local function startAutoLoop()
        if autoLoopActive then return end
        autoLoopActive = true
        task.spawn(function()
            while AUTO_JOIN_ON and alive() do
                local list = CACHE.list
                local cand
                if list then
                    cand = gvFilter(list, AUTO_JOIN_V, true)
                    if #cand == 0 and next(GV_TRIED) and os.clock() - lastAutoClearAt > 30 then
                        table.clear(GV_TRIED)
                        lastAutoClearAt = os.clock()
                        cand = gvFilter(list, AUTO_JOIN_V, false)
                    end
                    if #cand > 0 then
                        AUTO_JOIN_ON = false
                        if lstatus and lstatus.Parent then
                            lstatus.Text = "✔ Joining " .. gvFmt(cand[1].value)
                            lstatus.Visible = true
                        end
                        hopHighValue(AUTO_JOIN_V, nil, cand)
                        break
                    end
                end

                if not AUTO_JOIN_ON then break end
                list = gvLoad()
                if list then
                    CACHE.list = list
                    CACHE.at = os.clock()
                    render()
                end
                if not AUTO_JOIN_ON then break end

                if list then
                    cand = gvFilter(list, AUTO_JOIN_V, true)
                    if #cand == 0 and next(GV_TRIED) and os.clock() - lastAutoClearAt > 30 then
                        table.clear(GV_TRIED)
                        lastAutoClearAt = os.clock()
                        cand = gvFilter(list, AUTO_JOIN_V, false)
                    end
                    if #cand > 0 then
                        AUTO_JOIN_ON = false
                        if lstatus and lstatus.Parent then
                            lstatus.Text = "✔ Joining " .. gvFmt(cand[1].value)
                            lstatus.Visible = true
                        end
                        hopHighValue(AUTO_JOIN_V, nil, cand)
                        break
                    end
                    if lstatus and lstatus.Parent then
                        lstatus.Text = "🔍 Auto Join ≥ " .. formatSInput(AUTO_JOIN_V)
                        lstatus.Visible = true
                    end
                else
                    if lstatus and lstatus.Parent then
                        lstatus.Text = "⚠ " .. gvErrText()
                        lstatus.Visible = true
                    end
                end

                task.wait(1)
            end
            autoLoopActive = false
        end)
    end

    local function build()
        lsg = Instance.new("ScreenGui")
        lsg.Name = "JenFinderList"
        lsg.ResetOnSpawn = false
        lsg.IgnoreGuiInset = true
        lsg.DisplayOrder = 1001
        lsg.Enabled = false
        lsg.Parent = parent

        lpn = Instance.new("Frame")
        lpn.AnchorPoint = Vector2.new(1,0.5)
        lpn.Position = UDim2.new(1,-6,0.5,0)
        lpn.Size = UDim2.fromOffset(250, 415)
        lpn.BackgroundColor3 = PANEL_BG
        lpn.BorderSizePixel = 0
        local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,12); pc.Parent = lpn
        local ps = Instance.new("UIStroke")
        ps.Thickness = 1.6; ps.Color = PINK; ps.Transparency = 0.15
        ps.Parent = lpn
        lscale = Instance.new("UIScale"); lscale.Parent = lpn
        lpn.Parent = lsg

        local hdr = Instance.new("Frame")
        hdr.Size = UDim2.new(1,0,0,36)
        hdr.BackgroundColor3 = PINK
        hdr.BorderSizePixel = 0
        local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0,12); hc.Parent = hdr
        local hg = Instance.new("UIGradient")
        hg.Color = ColorSequence.new(PINK_LT, PINK_DK)
        hg.Rotation = 90; hg.Parent = hdr
        hdr.Parent = lpn

        local fill = Instance.new("Frame")
        fill.Position = UDim2.new(0,0,0,22)
        fill.Size = UDim2.new(1,0,0,14)
        fill.BackgroundColor3 = PINK_MID
        fill.BorderSizePixel = 0
        fill.ZIndex = 1
        fill.Parent = hdr

        local ht = Instance.new("TextLabel")
        ht.BackgroundTransparency = 1
        ht.Position = UDim2.new(0,10,0,0)
        ht.Size = UDim2.new(1,-46,1,0)
        ht.Font = Enum.Font.GothamBlack
        ht.TextSize = 15
        ht.TextXAlignment = Enum.TextXAlignment.Left
        ht.TextTruncate = Enum.TextTruncate.AtEnd
        ht.TextColor3 = Color3.new(1,1,1)
        ht.TextStrokeTransparency = 0.5
        ht.ZIndex = 3
        ht.Text = "Jen Finder"
        ht.Parent = hdr

        ltitle = Instance.new("TextLabel")
        ltitle.BackgroundTransparency = 1
        ltitle.Position = UDim2.new(0,12,0,38)
        ltitle.Size = UDim2.new(0.5,-12,0,14)
        ltitle.Font = Enum.Font.GothamBold
        ltitle.TextSize = 10
        ltitle.TextXAlignment = Enum.TextXAlignment.Left
        ltitle.TextColor3 = PINK_LT
        ltitle.ZIndex = 2
        ltitle.Parent = lpn

        resetLbl = Instance.new("TextLabel")
        resetLbl.BackgroundTransparency = 1
        resetLbl.Position = UDim2.new(0.5, 0, 0, 38)
        resetLbl.Size = UDim2.new(0.5, -12, 0, 14)
        resetLbl.Font = Enum.Font.GothamBold
        resetLbl.TextSize = 10
        resetLbl.TextXAlignment = Enum.TextXAlignment.Right
        resetLbl.TextColor3 = Color3.fromRGB(230, 245, 255)
        resetLbl.Text = 'RESET --:--'
        resetLbl.ZIndex = 5
        resetLbl.Parent = lpn

        task.spawn(function()
            local lastSec = -1
            while lpn and lpn.Parent do
                local info = getResetInfo()
                if info and info.running and type(info.remaining) == 'number' then
                    local s = math.max(0, math.ceil(info.remaining))
                    resetLbl.Text = string.format('RESET %02d:%02d', math.floor(s/60), s%60)
                    resetLbl.TextColor3 = (s <= 30  and Color3.fromRGB(255, 85, 85))
                                         or (s <= 60 and Color3.fromRGB(255, 215, 65))
                                         or  Color3.fromRGB(230, 245, 255)
                    if s <= 0 or (lastSec > 0 and s > lastSec + 60) then
                        LAST_RESET_AT = os.time()
                        clearRows()
                        CACHE.list = nil
                        if ltitle then ltitle.Text = "High eggs: 0" end
                    end
                    lastSec = s
                else
                    resetLbl.Text = 'RESET --:--'
                end
                task.wait(1)
            end
        end)

        lstatus = Instance.new("TextLabel")
        lstatus.Name = "AutoStatus"
        lstatus.BackgroundTransparency = 1
        lstatus.Position = UDim2.new(0,12,0,54)
        lstatus.Size = UDim2.new(1,-24,0,11)
        lstatus.Font = Enum.Font.GothamMedium
        lstatus.TextSize = 9
        lstatus.TextXAlignment = Enum.TextXAlignment.Left
        lstatus.TextTruncate = Enum.TextTruncate.AtEnd
        lstatus.TextWrapped = false
        lstatus.TextColor3 = PINK_LT
        lstatus.Visible = false
        lstatus.Parent = lpn

        local function btn(txt, col, ts)
            local b = Instance.new("TextButton")
            b.BackgroundColor3 = col
            b.BorderSizePixel = 0
            b.AutoButtonColor = false
            b.Font = Enum.Font.GothamBold
            b.TextSize = ts or 12
            b.TextColor3 = Color3.new(1,1,1)
            b.TextStrokeTransparency = 0.55
            b.TextTruncate = Enum.TextTruncate.AtEnd
            b.Text = txt
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
            b.Parent = lpn
            return b
        end

        local bClose = btn("X", CLOSE_BG, 13)
        bClose.AnchorPoint = Vector2.new(1,0.5)
        bClose.Position = UDim2.new(1,-7,0,18)
        bClose.Size = UDim2.fromOffset(26,24)
        bClose.ZIndex = 5
        bClose.Activated:Connect(closeList)

        local function chip(xs)
            local b = btn("", CHIP_BG, 11)
            b.Position = UDim2.new(xs, xs == 0 and 8 or 3, 0, 68)
            b.Size = UDim2.new(1/3, xs == 0 and -11 or -6, 0, 26)
            return b
        end
        bLvl = chip(0)
        bSort = chip(1/3)
        bRar = chip(2/3)

        bLvl.Activated:Connect(function()
            GV_IDX = GV_IDX % #GV_LEVELS + 1
            GV_RARITY = nil
            pcall(function() if writefile then writefile(GV_FILE, tostring(GV_IDX)) end end)
            loadList(false)
        end)
        bSort.Activated:Connect(function()
            GV_SORT = GV_SORT % 4 + 1
            pcall(function() if writefile then writefile(GV_SORT_FILE, tostring(GV_SORT)) end end)
            render()
        end)
        bRar.Activated:Connect(function()
            local list = CACHE.list
            if not list then return end
            local items = gvFilter(list, GV_LEVELS[GV_IDX], false, true)
            local seen, rars = {}, {}
            for _, it in ipairs(items) do
                if it.rarity ~= "" and not seen[it.rarity] then
                    seen[it.rarity] = true; rars[#rars+1] = it.rarity
                end
            end
            table.sort(rars)
            local nxt = nil
            if GV_RARITY == nil then nxt = rars[1]
            else
                for i, r in ipairs(rars) do
                    if r == GV_RARITY then nxt = rars[i+1]; break end
                end
            end
            GV_RARITY = nxt
            render()
        end)

        autoInput = Instance.new("TextBox")
        autoInput.Name = "AutoInput"
        autoInput.Position = UDim2.new(0, 8, 0, 100)
        autoInput.Size = UDim2.new(0.5, -10, 0, 28)
        autoInput.BackgroundColor3 = INPUT_BG
        autoInput.BorderSizePixel = 0
        autoInput.Font = Enum.Font.GothamBold
        autoInput.TextSize = 12
        autoInput.TextColor3 = Color3.new(1,1,1)
        autoInput.PlaceholderColor3 = PINK_PALE
        autoInput.PlaceholderText = "e.g. 1B, 500M"
        autoInput.ClearTextOnFocus = false
        autoInput.Text = formatSInput(AUTO_JOIN_V)
        local aic = Instance.new("UICorner"); aic.CornerRadius = UDim.new(0,8); aic.Parent = autoInput
        local ais = Instance.new("UIStroke"); ais.Color = PINK_DK; ais.Thickness = 1; ais.Transparency = 0.4; ais.Parent = autoInput
        autoInput.Parent = lpn

        bAuto = btn("Join " .. formatSInput(AUTO_JOIN_V), JOIN_BG, 12)
        bAuto.Position = UDim2.new(0.5, 2, 0, 100)
        bAuto.Size = UDim2.new(0.5, -10, 0, 28)

        autoInput:GetPropertyChangedSignal("Text"):Connect(function()
            local v = parseSInput(autoInput.Text)
            if v then
                bAuto.Text = "Join " .. formatSInput(v)
            else
                bAuto.Text = "Auto Join"
            end
        end)

        bAuto.Activated:Connect(function()
            if not alive() then return end
            local txt = autoInput.Text or ""
            local v = parseSInput(txt)
            if not v and txt == "" then v = AUTO_JOIN_V end
            if not v then
                autoInput.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
                task.delay(1, function()
                    if autoInput and autoInput.Parent then
                        autoInput.BackgroundColor3 = INPUT_BG
                    end
                end)
                return
            end

            AUTO_JOIN_V = v
            autoInput.Text = formatSInput(v)
            bAuto.Text = "Join " .. formatSInput(v)
            pcall(function()
                if writefile then writefile(GV_AUTO_FILE, string.format("%.0f", v)) end
            end)

            local cached
            if CACHE.list then
                cached = gvFilter(CACHE.list, v, false)
                if #cached == 0 then
                    if lstatus then
                        lstatus.Text = "⚠ No eggs ≥ " .. formatSInput(v)
                        lstatus.TextColor3 = Color3.fromRGB(255, 170, 90)
                        lstatus.Visible = true
                        task.delay(4, function()
                            if lstatus and lstatus.Parent then
                                updateStatusLine()
                                lstatus.TextColor3 = PINK_LT
                            end
                        end)
                    end
                    return
                end
            end

            closeList()
            hopHighValue(v, nil, cached)
        end)

        bAutoJoin = btn("Auto Join: OFF", AUTO_BG, 11)
        bAutoJoin.Position = UDim2.new(0, 8, 0, 134)
        bAutoJoin.Size = UDim2.new(0.65, -10, 0, 24)

        bRef = btn("Refresh", REFRESH_BG, 11)
        bRef.Position = UDim2.new(0.65, 2, 0, 134)
        bRef.Size = UDim2.new(0.35, -10, 0, 24)
        bRef.Activated:Connect(function()
            loadList(not (CACHE.list and os.clock() - (CACHE.at or 0) < 2))
        end)

        bAutoJoin.Activated:Connect(function()
            if not alive() then return end
            local v = parseSInput(autoInput.Text or "") or AUTO_JOIN_V
            AUTO_JOIN_V = v
            autoInput.Text = formatSInput(v)
            pcall(function()
                if writefile then writefile(GV_AUTO_FILE, string.format("%.0f", v)) end
            end)

            AUTO_JOIN_ON = not AUTO_JOIN_ON
            saveAutoState()
            updateAutoBtn()
            updateStatusLine()

            if AUTO_JOIN_ON then
                startAutoLoop()
            end
        end)

        lrows = Instance.new("ScrollingFrame")
        lrows.BackgroundTransparency = 1
        lrows.BorderSizePixel = 0
        lrows.Position = UDim2.new(0, 6, 0, 164)
        lrows.Size = UDim2.new(1, -12, 1, -170)
        lrows.ScrollBarThickness = 3
        lrows.ScrollBarImageColor3 = PINK
        lrows.CanvasSize = UDim2.new(0, 0, 0, 0)
        lrows.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 5); ll.SortOrder = Enum.SortOrder.LayoutOrder
        ll.Parent = lrows
        lrows.Parent = lpn

        updateAutoBtn()
        updateStatusLine()
    end

    local function openList()
        if not lsg then build() end
        AUTO_JOIN_ON = AUTO_JOIN_ON_SAVED
        updateAutoBtn()
        updateStatusLine()

        local target = 1
        pcall(function()
            target = math.clamp(workspace.CurrentCamera.ViewportSize.Y / 480, 0.8, 1.7)
        end)
        lscale.Scale = target * 0.9
        lsg.Enabled = true
        pcall(function()
            TweenService:Create(lscale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target}):Play()
        end)
        loadList(false)

        if AUTO_JOIN_ON then
            startAutoLoop()
        end

        if not PANEL_AUTO then
            PANEL_AUTO = true
            local lastSig, skips = nil, 0
            task.spawn(function()
                while alive() and lsg and lsg.Parent and lsg.Enabled do
                    task.wait(12)
                    if not (alive() and lsg and lsg.Parent and lsg.Enabled) then break end
                    if AUTO_JOIN_ON then
                        task.wait(2)
                    else
                        if os.time() - LAST_RESET_AT < 5 then
                            task.wait(1)
                        else
                            local list = gvLoad()
                            if list and lsg and lsg.Enabled then
                                CACHE.list = list; CACHE.at = os.clock()
                                local parts = {}
                                for i = 1, math.min(#list, 60) do
                                    local e = list[i]
                                    if type(e) == "table" then
                                        parts[#parts+1] = tostring(e.jobId) .. ":" .. tostring(e.value)
                                    end
                                end
                                local sig = #list .. "|" .. table.concat(parts, ",")
                                skips = skips + 1
                                if sig ~= lastSig or skips >= 3 then
                                    lastSig, skips = sig, 0
                                    local cp = lrows and lrows.CanvasPosition
                                    render()
                                    if cp then
                                        task.defer(function() pcall(function() lrows.CanvasPosition = cp end) end)
                                    end
                                end
                            end
                        end
                    end
                end
                PANEL_AUTO = false
            end)
        end
    end

    local function startAutoJoin()
        if not lsg then build() end
        AUTO_JOIN_ON = true
        updateAutoBtn()
        updateStatusLine()
        startAutoLoop()
    end

    return {
        open = openList,
        close = closeList,
        isOpen = function() return lsg and lsg.Enabled end,
        toggle = function()
            if lsg and lsg.Enabled then closeList() else openList() end
        end,
        startAutoJoin = startAutoJoin
    }
end

-- =====================================================================
-- FLOATING TOGGLE BUTTON
-- =====================================================================
local function createFloatingButton(panel)
    local parent = (gethui and gethui()) or CoreGui
    local old = parent:FindFirstChild("JenFinderFloat")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "JenFinderFloat"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 1000

    local btn
    if toggleImage then
        btn = Instance.new("ImageButton")
        btn.Image = toggleImage
        btn.ImageColor3 = Color3.new(1, 1, 1)
        btn.ScaleType = Enum.ScaleType.Fit
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.fromOffset(64, 64)
        btn.AutoButtonColor = false
        btn.Parent = sg
    else
        btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(112, 38)
        btn.BackgroundColor3 = PINK
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextStrokeTransparency = 0.5
        btn.Text = "Jen Finder"
        btn.Parent = sg

        local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 8); uc.Parent = btn
        local us = Instance.new("UIStroke"); us.Color = PINK_DK; us.Thickness = 1.5; us.Parent = btn
        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, PINK_LT),
            ColorSequenceKeypoint.new(1, PINK_HOT),
        })
        grad.Rotation = 90; grad.Parent = btn
    end

    btn.AnchorPoint = Vector2.new(0, 0.5)

    local savedX, savedY = 6, 200
    pcall(function()
        if isfile and readfile and isfile(GV_BTN_POS) then
            local txt = readfile(GV_BTN_POS)
            local sx, sy = txt:match("(-?%d+),(-?%d+)")
            if sx and sy then
                savedX = tonumber(sx)
                savedY = tonumber(sy)
            end
        end
    end)
    btn.Position = UDim2.new(0, savedX, 0, savedY)

    btn.Activated:Connect(function()
        if not alive() then return end
        panel.toggle()
    end)

    local dragging, dragStart, startPos = false, nil, nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    pcall(function()
                        if writefile then
                            local px = btn.Position.X.Offset
                            local py = btn.Position.Y.Offset
                            writefile(GV_BTN_POS, string.format("%d,%d", px, py))
                        end
                    end)
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                     startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    sg.Parent = parent
end

-- =====================================================================
-- JEN FINDER NAME TAGS  (visible ONLY to other script users)
-- Owner : "[Owner] Jen Finder" (gold) — detected by username
-- User  : "Jen Finder User"    (pink) — detected by attr + BoolValue
-- =====================================================================
local OWNER_NAME  = "salmarando"
local TAG_ATTR    = "JenFinderUser"
local SIGNAL_NAME = "JenFinderUserSignal"

local function isScriptUser(player)
    local char = player.Character
    if not char then return false end
    if char:GetAttribute(TAG_ATTR) == true then return true end
    if char:FindFirstChild(SIGNAL_NAME) then return true end
    return false
end

local function drawTag(player)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    local isOwner  = (player.Name == OWNER_NAME)
    local isUser   = isScriptUser(player)
    local existing = head:FindFirstChild("JenFinderNameTag")

    if not (isOwner or isUser) then
        if existing then existing:Destroy() end
        return
    end
    if existing then return end

    local bg = Instance.new("BillboardGui")
    bg.Name = "JenFinderNameTag"
    bg.Size = UDim2.fromOffset(240, 32)
    bg.StudsOffset = Vector3.new(0, 2.5, 0)
    bg.AlwaysOnTop = true
    bg.LightInfluence = 0
    bg.MaxDistance = 200
    bg.ResetOnSpawn = false
    bg.Parent = head

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 14
    lbl.Text = isOwner and "[Owner] Jen Finder" or "Jen Finder User"
    lbl.TextColor3 = isOwner
        and Color3.fromRGB(255, 215, 0)
        or  Color3.fromRGB(255, 105, 180)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = bg

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = isOwner
        and Color3.fromRGB(200, 140, 0)
        or  Color3.fromRGB(180, 20, 90)
    stroke.Parent = lbl
end

local function broadcastSelf()
    if LocalPlayer.Name == OWNER_NAME then return end
    local char = LocalPlayer.Character
    if not char then return end
    pcall(function() char:SetAttribute(TAG_ATTR, true) end)
    if not char:FindFirstChild(SIGNAL_NAME) then
        local bv = Instance.new("BoolValue")
        bv.Name = SIGNAL_NAME
        bv.Parent = char
    end
end

local function watchPlayer(player)
    local function hook(char)
        if player == LocalPlayer then broadcastSelf() end
        drawTag(player)
        char:GetAttributeChangedSignal(TAG_ATTR):Connect(function()
            drawTag(player)
        end)
        char.ChildAdded:Connect(function(c)
            if c.Name == SIGNAL_NAME then drawTag(player) end
        end)
    end

    if player.Character then task.spawn(hook, player.Character) end
    player.CharacterAdded:Connect(function(c)
        task.wait(0.3)
        hook(c)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
Players.PlayerAdded:Connect(watchPlayer)

-- safety net — catches late replication / missed signals
task.spawn(function()
    while alive() do
        task.wait(5)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then drawTag(p) end
        end
    end
end)

-- =====================================================================
-- BOOT
-- =====================================================================
local panel = createGVBar()
createFloatingButton(panel)

if AUTO_JOIN_ON_SAVED and (os.time() - LAST_HOP_AT > 10) then
    task.spawn(function()
        task.wait(3)
        panel.startAutoJoin()
    end)
end

print("[🌸 Jen Finder] Loaded — Auto-Save Pos: ON · Toggle: " ..
      (toggleImage and "Jen.png" or "Text") ..
      " · Auto Join Saved: " .. (AUTO_JOIN_ON_SAVED and "ON" or "OFF") ..
      " · Name Tags: ON (Owner: " .. OWNER_NAME .. ")" ..
      " · Loading Screen: ON (1s → 100% → join)")
