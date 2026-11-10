-- ============================================================
-- JEN FINDER - STANDALONE JOIN NOTIFICATION SCRIPT
-- ============================================================
local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local Http         = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local parent       = LocalPlayer:WaitForChild("PlayerGui", 15)

local DISCORD_WEBHOOK         = "https://discord.com/api/webhooks/1569779188087656550/C9KYAHFKm9vkSgd99lJftl0IS9NfNjRGUb3YgbOCEKNJ95rk9Zpm22C4mnN1ikEb4LuW"
local DISCORD_WEBHOOK_ENABLED = true

local rarityColorsHex = { divine=0xFFCD37, eternal=0xDACAEC, secret=0xFFFFFF, cosmic=0xBE55FF, mythic=0xFF4B55, legendary=0xFF9B2D, epic=0xFF6EC8, rare=0x41A5FF, uncommon=0x69DC78, common=0xDCE1EB }
local rarityEmojis = { divine='👑', eternal='♾️', secret='🔮', cosmic='🌌', mythic='🔥', legendary='💎', epic='💜', rare='💙', uncommon='💚', common='⚪' }
local accentColors = { divine=Color3.fromRGB(255,205,55), eternal=Color3.fromRGB(218,202,236), secret=Color3.fromRGB(255,255,255), cosmic=Color3.fromRGB(190,85,255), mythic=Color3.fromRGB(255,75,85), legendary=Color3.fromRGB(255,155,45), epic=Color3.fromRGB(255,110,200), rare=Color3.fromRGB(65,165,255), uncommon=Color3.fromRGB(105,220,120), common=Color3.fromRGB(220,225,235) }

local requestFn = request or http_request or (syn and syn.request) or (http and http.request)

-- Helpers
local function parseNum(v)
    if type(v) == "number" then return v end
    if type(v) == "string" then
        local num, suffix = v:match("([%d%.]+)([BMTK]?)")
        if num then
            num = tonumber(num) or 0
            if suffix == "K" then return num * 1e3 end
            if suffix == "M" then return num * 1e6 end
            if suffix == "B" then return num * 1e9 end
            if suffix == "T" then return num * 1e12 end
            return num
        end
    end
    return 0
end

local function fetchAvatarUrl(userId)
    local ok, res = pcall(function() return game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..tostring(userId).."&size=420x420&format=Png&isCircular=false") end)
    if ok and type(res) == "string" then
        local j, d = pcall(function() return Http:JSONDecode(res) end)
        if j and d and d.data and d.data[1] and d.data[1].imageUrl then return d.data[1].imageUrl end
    end
end

local function fetchAssetUrl(assetId)
    local ok, res = pcall(function() return game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds="..tostring(assetId).."&size=420x420&format=Png") end)
    if ok and type(res) == "string" then
        local j, d = pcall(function() return Http:JSONDecode(res) end)
        if j and d and d.data and d.data[1] and d.data[1].imageUrl then return d.data[1].imageUrl end
    end
end

local function fmtWeight(v)
    v = parseNum(v)
    if v <= 0 then return '—' end
    if v >= 1e12 then return string.format('%.2fT Kg', v/1e12) end
    if v >= 1e9 then return string.format('%.2fB Kg', v/1e9) end
    if v >= 1e6 then return string.format('%.2fM Kg', v/1e6) end
    if v >= 1000 then return string.format('%.2fK Kg', v/1000) end
    return string.format('%.2f Kg', v)
end

local function fmtMoney(v)
    v = parseNum(v)
    if v < 0 then return '—' end
    for _, e in ipairs({{1e18,'Qi'},{1e15,'Qa'},{1e12,'T'},{1e9,'B'},{1e6,'M'},{1e3,'K'}}) do
        if v >= e[1] then return string.format('$%.2f%s/s', v/e[1], e[2]) end
    end
    return string.format('$%.2f/s', v)
end

-- ============================================================
-- 1. TOAST UI
-- ============================================================
local Notif = {}
do
    local notifGui = Instance.new('ScreenGui')
    notifGui.Name = 'JenJoinNotifs'
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.DisplayOrder = 1250
    notifGui.Parent = parent

    local container = Instance.new('Frame')
    container.Name = 'NotifStack'
    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -10, 1, -10)
    container.Size = UDim2.new(0, 220, 1, -20)
    container.BackgroundTransparency = 1
    container.Parent = notifGui

    local layout = Instance.new('UIListLayout')
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 5)
    layout.Parent = container

    local order = 0
    function Notif.push(name, weightKg, incomePerSec, rarityName)
        order = order + 1
        local card = Instance.new('Frame')
        card.Size = UDim2.new(1, 0, 0, 46)
        card.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
        card.BackgroundTransparency = 0.06
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.Parent = container

        Instance.new('UICorner', card).CornerRadius = UDim.new(0, 6)
        local key = tostring(rarityName or ''):lower():gsub('%s+','')
        local accentColor = accentColors[key] or Color3.fromRGB(120, 200, 255)

        local stroke = Instance.new('UIStroke', card)
        stroke.Color = accentColor
        stroke.Thickness = 1.5
        stroke.Transparency = 0.4

        local stripe = Instance.new('Frame', card)
        stripe.Size = UDim2.new(0, 3, 1, 0)
        stripe.BackgroundColor3 = accentColor
        stripe.BorderSizePixel = 0
        Instance.new('UICorner', stripe).CornerRadius = UDim.new(0, 6)

        local title = Instance.new('TextLabel', card)
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 8, 0, 4)
        title.Size = UDim2.new(1, -90, 0, 18)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 13
        title.TextColor3 = accentColor
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.Text = tostring(name or 'Unknown')

        local moneyLabel = Instance.new('TextLabel', card)
        moneyLabel.BackgroundTransparency = 1
        moneyLabel.Position = UDim2.new(1, -82, 0, 4)
        moneyLabel.Size = UDim2.new(0, 74, 0, 18)
        moneyLabel.Font = Enum.Font.GothamBold
        moneyLabel.TextSize = 12
        moneyLabel.TextColor3 = Color3.fromRGB(120, 240, 140)
        moneyLabel.TextXAlignment = Enum.TextXAlignment.Right
        moneyLabel.TextTruncate = Enum.TextTruncate.AtEnd
        moneyLabel.Text = fmtMoney(incomePerSec)

        local weightLabel = Instance.new('TextLabel', card)
        weightLabel.BackgroundTransparency = 1
        weightLabel.Position = UDim2.new(0, 8, 0, 23)
        weightLabel.Size = UDim2.new(0.5, -10, 0, 18)
        weightLabel.Font = Enum.Font.Gotham
        weightLabel.TextSize = 12
        weightLabel.TextColor3 = Color3.fromRGB(185, 220, 255)
        weightLabel.TextXAlignment = Enum.TextXAlignment.Left
        weightLabel.TextTruncate = Enum.TextTruncate.AtEnd
        weightLabel.Text = fmtWeight(weightKg)

        local rarityLabel = Instance.new('TextLabel', card)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Position = UDim2.new(0.5, 0, 0, 23)
        rarityLabel.Size = UDim2.new(0.5, -8, 0, 18)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 11
        rarityLabel.TextColor3 = accentColor
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
        rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
        rarityLabel.Text = tostring(rarityName or 'Unknown')

        card.Position = UDim2.new(0, 40, 0, 0)
        TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()

        task.delay(4, function()
            if not card.Parent then return end
            local t = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 40, 0, 0), BackgroundTransparency = 1 })
            t:Play()
            t.Completed:Connect(function() if card.Parent then card:Destroy() end end)
        end)
    end
end

-- ============================================================
-- 2. DISCORD WEBHOOK
-- ============================================================
local webhookLastSent = 0
local function safeText(v, fallback)
    if v == nil then return fallback or 'None' end
    local t = type(v)
    if t == 'string' then return v ~= '' and v or (fallback or 'None') end
    if t == 'number' then return tostring(v) end
    if t == 'table' then
        local ok, joined = pcall(function() return table.concat(v, ', ') end)
        if ok and joined ~= '' then return joined end
        return fallback or 'None'
    end
    return fallback or tostring(v)
end

local function sendDiscordWebhook(entry, placeId, jobId)
    if not DISCORD_WEBHOOK_ENABLED or DISCORD_WEBHOOK == '' or type(requestFn) ~= 'function' or not entry then return end
    if os.clock() - webhookLastSent < 1.5 then return end
    webhookLastSent = os.clock()

    local rarityText = safeText(entry.rarity, 'Unknown')
    local rarityKey  = rarityText:lower():gsub('%s+','')
    local color      = rarityColorsHex[rarityKey] or 0x78C8FF
    local rarityEmoji = rarityEmojis[rarityKey] or '⭐'

    local resolvedPlace = tostring(placeId or entry.placeId or game.PlaceId)
    local resolvedJob   = tostring(jobId or entry.jobId or game.JobId or '')
    local link = string.format('https://www.roblox.com/games/%s?gameInstanceId=%s', resolvedPlace, resolvedJob)

    local rawMut = entry.mutations or entry.mutationText or ''
    local mutations = safeText(rawMut, 'None')
    mutations = mutations:gsub('%s*%[[^%]]*%]',''):match('^%s*(.-)%s*$') or 'None'

    local avatarUrl = fetchAvatarUrl(LocalPlayer.UserId)
    local petIconUrl
    local icon = tostring(entry.icon or '')
    local id = icon:match('rbxassetid://(%d+)') or icon:match('^%s*(%d+)%s*$')
    if id then petIconUrl = fetchAssetUrl(id) end

    local embed = {
        title = '✅ Joined Server',
        url = link,
        description = string.format('Teleported into a server with **%s**\n[🔗 Join Server »](%s)', safeText(entry.name, 'Unknown'), link),
        color = color,
        fields = {
            {name = '💰 Income',   value = '`'..fmtMoney(entry.rate)..'`',    inline = true},
            {name = '⚖️ Weight',   value = '`'..fmtWeight(entry.weight)..'`', inline = true},
            {name = rarityEmoji..' Rarity', value = '**'..rarityText..'**',  inline = true},
            {name = '🧬 Mutations', value = '`'..mutations..'`',              inline = false},
            {name = '🌐 Server',   value = '[**Click to Join »**]('..link..')', inline = true},
            {name = '👤 Player',   value = '`'..safeText(LocalPlayer.Name, '?')..'`', inline = true},
            {name = '🎯 Job ID',   value = '`'..resolvedJob..'`',             inline = false},
        },
        footer = { text = 'Jen Finder • '..os.date('%Y-%m-%d %H:%M:%S') },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
    if avatarUrl then embed.thumbnail = { url = avatarUrl } end
    if petIconUrl then embed.image    = { url = petIconUrl } end

    local body = Http:JSONEncode({ username = 'Jen Finder', embeds = {embed} })

    task.spawn(function()
        pcall(requestFn, { Url = DISCORD_WEBHOOK, Method = 'POST', Headers = {['Content-Type'] = 'application/json'}, Body = body, Timeout = 10 })
    end)
end

-- ============================================================
-- 3. COMBINED TRIGGER
-- ============================================================
getgenv().JenNotif = function(entry)
    if not entry then return end
    pcall(Notif.push, entry.name, entry.weight, entry.rate, entry.rarity)
    pcall(sendDiscordWebhook, entry, entry.placeId, entry.jobId)
    print(string.format('[Jen Notif] -> %s | %s | %s', tostring(entry.name), tostring(entry.rarity), tostring(entry.rate)))
end

-- ============================================================
-- 4. AUTO-HOOK (Detects when you click "Join" in the UI)
-- ============================================================
task.spawn(function()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local function hookButton(btn)
        -- Look for buttons that say "Join"
        if btn:IsA("TextButton") and btn.Text:lower():match("join") then
            if btn:GetAttribute("JenHooked") then return end
            btn:SetAttribute("JenHooked", true)

            btn.MouseButton1Click:Connect(function()
                local card = btn.Parent
                local nameStr = "Unknown"
                local rateStr = 0
                local rarityStr = "Unknown"
                
                -- Extract text from the UI card next to the button
                for _, child in ipairs(card:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local txt = child.Text
                        -- Matches strings like "15.94B/s • Secret"
                        local r, rar = txt:match("([%d%.]+[BMTK]?/s)%s*•%s*(.+)")
                        if r then
                            rateStr = r
                            rarityStr = rar
                        elseif not txt:match("players") and not txt:lower():match("join") and txt ~= "" and nameStr == "Unknown" then
                            nameStr = txt
                        end
                    end
                end
                
                -- Fire the notification!
                if getgenv().JenNotif then
                    getgenv().JenNotif({
                        name = nameStr,
                        rarity = rarityStr,
                        rate = rateStr,
                        placeId = game.PlaceId,
                        jobId = game.JobId
                    })
                end
            end)
        end
    end
    
    for _, v in ipairs(PlayerGui:GetDescendants()) do hookButton(v) end
    PlayerGui.DescendantAdded:Connect(hookButton)
end)
