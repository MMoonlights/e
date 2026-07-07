local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

local backpackFolder = ReplicatedStorage:WaitForChild("Event"):WaitForChild("Backpack")
local ChestEvent = backpackFolder:WaitForChild("ChestRemoteEvent")
local BackpackFunction = backpackFolder:WaitForChild("BackpackRemoteFunction")

local ChestFolderName = "\229\174\157\231\174\177"
local SafeName = "\228\191\157\233\153\169\231\174\177"

local ChestFolder = workspace:FindFirstChild(ChestFolderName)

local rarities = {
    {id = 1, name = "Common"},
    {id = 2, name = "Uncommon"},
    {id = 3, name = "Rare"},
    {id = 4, name = "Epic"},
    {id = 5, name = "Legendary"},
    {id = 6, name = "Mythic"}
}

local settings = {
    rarityMode = "Greater",
    rarityValue = 0,
    coinsMode = "Greater",
    coinsValue = 0,
    weightMode = "Less",
    weightValue = 0,
    openDelay = 0.45,
    takeDelay = 0.22,
    closeDelay = 0.35,
    openTimeout = 3
}

local rarityRules = {}

for _, rarity in ipairs(rarities) do
    rarityRules[rarity.id] = {
        enabled = true,
        coinsMode = "Greater",
        coinsValue = 0,
        weightMode = "Less",
        weightValue = 0
    }
end

local isFarming = false
local isProcessingChest = false
local isInventoryFull = false
local lootedChests = {}
local failedChests = {}

local stats = {
    chests = 0,
    taken = 0,
    skipped = 0,
    failed = 0
}

local function getGuiParent()
    local ok, result = pcall(function()
        if gethui then
            return gethui()
        end

        return CoreGui
    end)

    if ok and result then
        return result
    end

    return CoreGui
end

local guiParent = getGuiParent()
local oldGui = guiParent:FindFirstChild("SmartChestFarmV3")

if oldGui then
    oldGui:Destroy()
end

local function create(className, props, parent)
    local object = Instance.new(className)

    for key, value in pairs(props or {}) do
        object[key] = value
    end

    if parent then
        object.Parent = parent
    end

    return object
end

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(75, 75, 100)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = object
    return s
end

local function gradient(object, color1, color2)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    g.Rotation = 25
    g.Parent = object
    return g
end

local function tween(object, props, time)
    TweenService:Create(object, TweenInfo.new(time or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local gui = create("ScreenGui", {
    Name = "SmartChestFarmV3",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, guiParent)

local main = create("Frame", {
    Size = UDim2.fromOffset(430, 560),
    Position = UDim2.new(0, 24, 0.5, -280),
    BackgroundColor3 = Color3.fromRGB(16, 16, 24),
    BorderSizePixel = 0,
    Active = true
}, gui)
corner(main, 14)
stroke(main, Color3.fromRGB(85, 85, 115), 1, 0.25)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = Color3.fromRGB(34, 34, 54),
    BorderSizePixel = 0,
    ZIndex = 5
}, main)
corner(header, 14)
gradient(header, Color3.fromRGB(45, 45, 74), Color3.fromRGB(24, 24, 38))

local headerFix = create("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = Color3.fromRGB(24, 24, 38),
    BorderSizePixel = 0,
    ZIndex = 5
}, header)

local title = create("TextLabel", {
    Size = UDim2.new(1, -110, 0, 24),
    Position = UDim2.fromOffset(16, 7),
    BackgroundTransparency = 1,
    Text = "Chest Auto Farm",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
}, header)

local subtitle = create("TextLabel", {
    Size = UDim2.new(1, -110, 0, 18),
    Position = UDim2.fromOffset(16, 29),
    BackgroundTransparency = 1,
    Text = "Rarity rules, filters and teleport tools",
    TextColor3 = Color3.fromRGB(170, 170, 195),
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6
}, header)

local minimizeButton = create("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -78, 0, 11),
    BackgroundColor3 = Color3.fromRGB(45, 45, 62),
    BorderSizePixel = 0,
    Text = "–",
    TextColor3 = Color3.fromRGB(235, 235, 245),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    ZIndex = 7
}, header)
corner(minimizeButton, 8)

local closeButton = create("TextButton", {
    Size = UDim2.fromOffset(32, 32),
    Position = UDim2.new(1, -40, 0, 11),
    BackgroundColor3 = Color3.fromRGB(80, 38, 48),
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 215, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    ZIndex = 7
}, header)
corner(closeButton, 8)

local tabBar = create("Frame", {
    Size = UDim2.new(1, -28, 0, 38),
    Position = UDim2.fromOffset(14, 66),
    BackgroundColor3 = Color3.fromRGB(22, 22, 32),
    BorderSizePixel = 0,
    ZIndex = 3
}, main)
corner(tabBar, 10)
stroke(tabBar, Color3.fromRGB(55, 55, 78), 1, 0.45)

local pages = create("Frame", {
    Size = UDim2.new(1, -28, 1, -154),
    Position = UDim2.fromOffset(14, 116),
    BackgroundTransparency = 1,
    ZIndex = 2
}, main)

local statusBar = create("Frame", {
    Size = UDim2.new(1, -28, 0, 30),
    Position = UDim2.new(0, 14, 1, -42),
    BackgroundColor3 = Color3.fromRGB(25, 25, 37),
    BorderSizePixel = 0,
    ZIndex = 4
}, main)
corner(statusBar, 9)
stroke(statusBar, Color3.fromRGB(60, 60, 82), 1, 0.45)

local statusDot = create("Frame", {
    Size = UDim2.fromOffset(9, 9),
    Position = UDim2.fromOffset(13, 11),
    BackgroundColor3 = Color3.fromRGB(150, 150, 165),
    BorderSizePixel = 0,
    ZIndex = 5
}, statusBar)
corner(statusDot, 99)

local statusLabel = create("TextLabel", {
    Size = UDim2.new(1, -38, 1, 0),
    Position = UDim2.fromOffset(32, 0),
    BackgroundTransparency = 1,
    Text = "Idle",
    TextColor3 = Color3.fromRGB(190, 190, 205),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5
}, statusBar)

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Color3.fromRGB(190, 190, 205)
    statusDot.BackgroundColor3 = color or Color3.fromRGB(150, 150, 165)
end

local pageMain = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = true,
    ZIndex = 2
}, pages)

local pageFilters = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 2
}, pages)

local pageRarities = create("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 2
}, pages)

local tabs = {}

local function makeTab(text, index, page)
    local btn = create("TextButton", {
        Size = UDim2.new(1 / 3, -8, 1, -10),
        Position = UDim2.new((index - 1) / 3, 6 + ((index - 1) * 4), 0, 5),
        BackgroundColor3 = index == 1 and Color3.fromRGB(70, 110, 190) or Color3.fromRGB(32, 32, 46),
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Color3.fromRGB(245, 245, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 4
    }, tabBar)
    corner(btn, 8)

    tabs[text] = {
        button = btn,
        page = page
    }

    btn.MouseButton1Click:Connect(function()
        for name, data in pairs(tabs) do
            data.page.Visible = name == text
            tween(data.button, {
                BackgroundColor3 = name == text and Color3.fromRGB(70, 110, 190) or Color3.fromRGB(32, 32, 46)
            }, 0.12)
        end
    end)

    return btn
end

makeTab("Main", 1, pageMain)
makeTab("Filters", 2, pageFilters)
makeTab("Rarities", 3, pageRarities)

local function makeCard(parent, y, height)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = Color3.fromRGB(24, 24, 35),
        BorderSizePixel = 0,
        ZIndex = 3
    }, parent)
    corner(card, 11)
    stroke(card, Color3.fromRGB(55, 55, 78), 1, 0.45)
    return card
end

local function makeTitle(parent, text, y)
    return create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 22),
        Position = UDim2.fromOffset(12, y),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(230, 230, 245),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, parent)
end

local function makeButton(parent, text, x, y, w, h, color, textColor)
    local btn = create("TextButton", {
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = textColor or Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 4
    }, parent)
    corner(btn, 9)
    return btn
end

local function makeModeValueRow(parent, labelText, y, modeGetter, modeSetter, valueGetter, valueSetter)
    local label = create("TextLabel", {
        Size = UDim2.fromOffset(92, 30),
        Position = UDim2.fromOffset(12, y),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = Color3.fromRGB(195, 195, 210),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    }, parent)

    local modeBtn = create("TextButton", {
        Size = UDim2.fromOffset(90, 30),
        Position = UDim2.fromOffset(112, y),
        BackgroundColor3 = Color3.fromRGB(34, 34, 49),
        BorderSizePixel = 0,
        Text = modeGetter(),
        TextColor3 = Color3.fromRGB(240, 240, 250),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 5
    }, parent)
    corner(modeBtn, 8)
    stroke(modeBtn, Color3.fromRGB(65, 65, 88), 1, 0.5)

    local box = create("TextBox", {
        Size = UDim2.new(1, -226, 0, 30),
        Position = UDim2.fromOffset(214, y),
        BackgroundColor3 = Color3.fromRGB(34, 34, 49),
        BorderSizePixel = 0,
        Text = tostring(valueGetter()),
        PlaceholderText = "0 = Any",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        PlaceholderColor3 = Color3.fromRGB(125, 125, 145),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 5
    }, parent)
    corner(box, 8)
    stroke(box, Color3.fromRGB(65, 65, 88), 1, 0.5)

    modeBtn.MouseButton1Click:Connect(function()
        local nextMode = modeGetter() == "Greater" and "Less" or "Greater"
        modeSetter(nextMode)
        modeBtn.Text = nextMode
    end)

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)

        if not n or n < 0 then
            n = 0
        end

        valueSetter(n)
        box.Text = tostring(n)
    end)

    return modeBtn, box
end

local statsCard = makeCard(pageMain, 0, 110)
makeTitle(statsCard, "Session Stats", 10)

local statsLine1 = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 42),
    BackgroundTransparency = 1,
    Text = "Chests: 0  |  Taken: 0",
    TextColor3 = Color3.fromRGB(195, 195, 210),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statsCard)

local statsLine2 = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 22),
    Position = UDim2.fromOffset(12, 68),
    BackgroundTransparency = 1,
    Text = "Skipped: 0  |  Failed: 0",
    TextColor3 = Color3.fromRGB(195, 195, 210),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statsCard)

local function updateStats()
    statsLine1.Text = "Chests: " .. stats.chests .. "  |  Taken: " .. stats.taken
    statsLine2.Text = "Skipped: " .. stats.skipped .. "  |  Failed: " .. stats.failed
end

local startButton = makeButton(pageMain, "Start Farming", 0, 126, 402, 44, Color3.fromRGB(75, 190, 115), Color3.fromRGB(10, 22, 14))
local specialButton = makeButton(pageMain, "Special TP", 0, 184, 196, 38, Color3.fromRGB(130, 85, 205))
local extractButton = makeButton(pageMain, "Extract TP", 206, 184, 196, 38, Color3.fromRGB(65, 125, 210))
local resetButton = makeButton(pageMain, "Reset Cache", 0, 236, 402, 36, Color3.fromRGB(44, 44, 62))
local closeChestButton = makeButton(pageMain, "Close Chest", 0, 286, 402, 36, Color3.fromRGB(54, 54, 72))

local infoCard = makeCard(pageMain, 340, 64)
makeTitle(infoCard, "Rarity IDs", 9)

local rarityIdText = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.fromOffset(12, 32),
    BackgroundTransparency = 1,
    Text = "1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary, 6 Mythic",
    TextColor3 = Color3.fromRGB(185, 185, 205),
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, infoCard)

local filterCard = makeCard(pageFilters, 0, 204)
makeTitle(filterCard, "Global Filters", 10)

makeModeValueRow(
    filterCard,
    "Rarity",
    46,
    function()
        return settings.rarityMode
    end,
    function(v)
        settings.rarityMode = v
    end,
    function()
        return settings.rarityValue
    end,
    function(v)
        settings.rarityValue = v
    end
)

makeModeValueRow(
    filterCard,
    "Coins",
    88,
    function()
        return settings.coinsMode
    end,
    function(v)
        settings.coinsMode = v
    end,
    function()
        return settings.coinsValue
    end,
    function(v)
        settings.coinsValue = v
    end
)

makeModeValueRow(
    filterCard,
    "Weight",
    130,
    function()
        return settings.weightMode
    end,
    function(v)
        settings.weightMode = v
    end,
    function()
        return settings.weightValue
    end,
    function(v)
        settings.weightValue = v
    end
)

local filterNote = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.fromOffset(12, 168),
    BackgroundTransparency = 1,
    Text = "0 disables the filter. Greater means > value. Less means < value.",
    TextColor3 = Color3.fromRGB(155, 155, 175),
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, filterCard)

local delayCard = makeCard(pageFilters, 220, 164)
makeTitle(delayCard, "Delays", 10)

makeModeValueRow(
    delayCard,
    "Open",
    46,
    function()
        return "Greater"
    end,
    function()
    end,
    function()
        return settings.openDelay
    end,
    function(v)
        settings.openDelay = math.max(v, 0.05)
    end
)

makeModeValueRow(
    delayCard,
    "Take",
    88,
    function()
        return "Greater"
    end,
    function()
    end,
    function()
        return settings.takeDelay
    end,
    function(v)
        settings.takeDelay = math.max(v, 0.05)
    end
)

makeModeValueRow(
    delayCard,
    "Close",
    130,
    function()
        return "Greater"
    end,
    function()
    end,
    function(v)
        return settings.closeDelay
    end,
    function(v)
        settings.closeDelay = math.max(v, 0.05)
    end
)

local rarityTop = create("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(24, 24, 35),
    BorderSizePixel = 0,
    ZIndex = 3
}, pageRarities)
corner(rarityTop, 10)
stroke(rarityTop, Color3.fromRGB(55, 55, 78), 1, 0.45)

local enableAllButton = makeButton(rarityTop, "Enable All", 10, 7, 122, 28, Color3.fromRGB(45, 85, 55))
local disableAllButton = makeButton(rarityTop, "Disable All", 142, 7, 122, 28, Color3.fromRGB(88, 48, 56))
local resetRulesButton = makeButton(rarityTop, "Reset Rules", 274, 7, 118, 28, Color3.fromRGB(52, 52, 72))

local rarityScroll = create("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.fromOffset(0, 56),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.fromOffset(0, #rarities * 96),
    ZIndex = 2
}, pageRarities)

local rarityLayout = create("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
}, rarityScroll)

local rarityButtons = {}

local function refreshRarityRows()
    for _, rarity in ipairs(rarities) do
        local row = rarityButtons[rarity.id]

        if row then
            local rule = rarityRules[rarity.id]

            row.toggle.Text = rule.enabled and "Enabled" or "Disabled"
            row.toggle.BackgroundColor3 = rule.enabled and Color3.fromRGB(45, 95, 60) or Color3.fromRGB(82, 48, 56)
            row.title.TextColor3 = rule.enabled and Color3.fromRGB(235, 235, 250) or Color3.fromRGB(145, 145, 160)
            row.coinsMode.Text = rule.coinsMode
            row.weightMode.Text = rule.weightMode
            row.coinsBox.Text = tostring(rule.coinsValue)
            row.weightBox.Text = tostring(rule.weightValue)
        end
    end
end

local function makeRarityRow(rarity, order)
    local row = create("Frame", {
        Size = UDim2.new(1, -6, 0, 86),
        BackgroundColor3 = Color3.fromRGB(24, 24, 35),
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 3
    }, rarityScroll)
    corner(row, 10)
    stroke(row, Color3.fromRGB(55, 55, 78), 1, 0.45)

    local title = create("TextLabel", {
        Size = UDim2.new(1, -138, 0, 22),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1,
        Text = rarity.name .. "  [" .. rarity.id .. "]",
        TextColor3 = Color3.fromRGB(235, 235, 250),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, row)

    local toggle = makeButton(row, "Enabled", 286, 7, 96, 24, Color3.fromRGB(45, 95, 60))

    local coinsLabel = create("TextLabel", {
        Size = UDim2.fromOffset(52, 24),
        Position = UDim2.fromOffset(12, 38),
        BackgroundTransparency = 1,
        Text = "Coins",
        TextColor3 = Color3.fromRGB(190, 190, 210),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, row)

    local coinsMode = makeButton(row, "Greater", 66, 36, 78, 26, Color3.fromRGB(34, 34, 49))
    local coinsBox = create("TextBox", {
        Size = UDim2.fromOffset(56, 26),
        Position = UDim2.fromOffset(150, 36),
        BackgroundColor3 = Color3.fromRGB(34, 34, 49),
        BorderSizePixel = 0,
        Text = "0",
        PlaceholderText = "0",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        PlaceholderColor3 = Color3.fromRGB(125, 125, 145),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 4
    }, row)
    corner(coinsBox, 7)
    stroke(coinsBox, Color3.fromRGB(65, 65, 88), 1, 0.5)

    local weightLabel = create("TextLabel", {
        Size = UDim2.fromOffset(54, 24),
        Position = UDim2.fromOffset(218, 38),
        BackgroundTransparency = 1,
        Text = "Weight",
        TextColor3 = Color3.fromRGB(190, 190, 210),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, row)

    local weightMode = makeButton(row, "Less", 274, 36, 68, 26, Color3.fromRGB(34, 34, 49))
    local weightBox = create("TextBox", {
        Size = UDim2.fromOffset(42, 26),
        Position = UDim2.fromOffset(348, 36),
        BackgroundColor3 = Color3.fromRGB(34, 34, 49),
        BorderSizePixel = 0,
        Text = "0",
        PlaceholderText = "0",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        PlaceholderColor3 = Color3.fromRGB(125, 125, 145),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 4
    }, row)
    corner(weightBox, 7)
    stroke(weightBox, Color3.fromRGB(65, 65, 88), 1, 0.5)

    rarityButtons[rarity.id] = {
        title = title,
        toggle = toggle,
        coinsMode = coinsMode,
        coinsBox = coinsBox,
        weightMode = weightMode,
        weightBox = weightBox
    }

    toggle.MouseButton1Click:Connect(function()
        rarityRules[rarity.id].enabled = not rarityRules[rarity.id].enabled
        refreshRarityRows()
    end)

    coinsMode.MouseButton1Click:Connect(function()
        local rule = rarityRules[rarity.id]
        rule.coinsMode = rule.coinsMode == "Greater" and "Less" or "Greater"
        refreshRarityRows()
    end)

    weightMode.MouseButton1Click:Connect(function()
        local rule = rarityRules[rarity.id]
        rule.weightMode = rule.weightMode == "Greater" and "Less" or "Greater"
        refreshRarityRows()
    end)

    coinsBox.FocusLost:Connect(function()
        local n = tonumber(coinsBox.Text)

        if not n or n < 0 then
            n = 0
        end

        rarityRules[rarity.id].coinsValue = n
        coinsBox.Text = tostring(n)
    end)

    weightBox.FocusLost:Connect(function()
        local n = tonumber(weightBox.Text)

        if not n or n < 0 then
            n = 0
        end

        rarityRules[rarity.id].weightValue = n
        weightBox.Text = tostring(n)
    end)
end

for i, rarity in ipairs(rarities) do
    makeRarityRow(rarity, i)
end

local function resetRarityRules()
    for _, rarity in ipairs(rarities) do
        rarityRules[rarity.id].enabled = true
        rarityRules[rarity.id].coinsMode = "Greater"
        rarityRules[rarity.id].coinsValue = 0
        rarityRules[rarity.id].weightMode = "Less"
        rarityRules[rarity.id].weightValue = 0
    end

    refreshRarityRows()
end

enableAllButton.MouseButton1Click:Connect(function()
    for _, rarity in ipairs(rarities) do
        rarityRules[rarity.id].enabled = true
    end

    refreshRarityRows()
end)

disableAllButton.MouseButton1Click:Connect(function()
    for _, rarity in ipairs(rarities) do
        rarityRules[rarity.id].enabled = false
    end

    refreshRarityRows()
end)

resetRulesButton.MouseButton1Click:Connect(function()
    resetRarityRules()
    setStatus("Rarity rules reset", Color3.fromRGB(120, 200, 255))
end)

local function passesFilter(value, mode, filterValue)
    value = tonumber(value) or 0
    filterValue = tonumber(filterValue) or 0

    if filterValue <= 0 then
        return true
    end

    if mode == "Greater" then
        return value > filterValue
    end

    if mode == "Less" then
        return value < filterValue
    end

    return true
end

local function shouldTakeItem(item)
    if type(item) ~= "table" then
        return false
    end

    local rarity = tonumber(item.rare) or 0
    local coins = tonumber(item.coin) or 0
    local weight = tonumber(item.useCapacity) or 0
    local rule = rarityRules[rarity]

    if not rule then
        return false
    end

    if not rule.enabled then
        return false
    end

    if not passesFilter(rarity, settings.rarityMode, settings.rarityValue) then
        return false
    end

    if not passesFilter(coins, settings.coinsMode, settings.coinsValue) then
        return false
    end

    if not passesFilter(weight, settings.weightMode, settings.weightValue) then
        return false
    end

    if not passesFilter(coins, rule.coinsMode, rule.coinsValue) then
        return false
    end

    if not passesFilter(weight, rule.weightMode, rule.weightValue) then
        return false
    end

    return true
end

local function getRoot()
    local character = player.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function safeCloseChest()
    pcall(function()
        BackpackFunction:InvokeServer("CloseChest")
    end)
end

local function firePrompt(prompt)
    if not prompt then
        return false
    end

    if fireproximityprompt then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)

        return ok
    end

    if fire_proximityprompt then
        local ok = pcall(function()
            fire_proximityprompt(prompt)
        end)

        return ok
    end

    local ok = pcall(function()
        prompt.HoldDuration = 0
        prompt:InputHoldBegin()
        task.wait(0.12)
        prompt:InputHoldEnd()
    end)

    return ok
end

local function setFarmingState(state)
    isFarming = state

    if isFarming then
        isInventoryFull = false
        startButton.Text = "Stop Farming"
        startButton.TextColor3 = Color3.fromRGB(255, 235, 235)
        tween(startButton, {BackgroundColor3 = Color3.fromRGB(215, 65, 75)}, 0.16)
        setStatus("Farming...", Color3.fromRGB(80, 255, 130))
    else
        startButton.Text = "Start Farming"
        startButton.TextColor3 = Color3.fromRGB(10, 22, 14)
        tween(startButton, {BackgroundColor3 = Color3.fromRGB(75, 190, 115)}, 0.16)

        if isInventoryFull then
            setStatus("Inventory full", Color3.fromRGB(255, 70, 80))
        else
            setStatus("Stopped", Color3.fromRGB(220, 220, 235))
        end
    end
end

local function resetCache()
    lootedChests = {}
    failedChests = {}

    stats.chests = 0
    stats.taken = 0
    stats.skipped = 0
    stats.failed = 0

    updateStats()
    setStatus("Cache reset", Color3.fromRGB(120, 200, 255))
end

local function findExtractionPart()
    local folder = workspace:FindFirstChild("ExtractionPointFolder")

    if not folder then
        return nil
    end

    for _, object in ipairs(folder:GetChildren()) do
        if object:IsA("BasePart") then
            return object
        end

        local part = object:FindFirstChildWhichIsA("BasePart", true)

        if part then
            return part
        end
    end

    return nil
end

local function teleportTo(cframe)
    local root = getRoot()

    if not root then
        setStatus("Character not found", Color3.fromRGB(255, 90, 90))
        return false
    end

    root.CFrame = cframe
    return true
end

local dragging = false
local dragStart = nil
local startPosition = nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

startButton.MouseButton1Click:Connect(function()
    setFarmingState(not isFarming)
end)

resetButton.MouseButton1Click:Connect(function()
    resetCache()
end)

closeChestButton.MouseButton1Click:Connect(function()
    safeCloseChest()
    setStatus("Chest closed", Color3.fromRGB(120, 200, 255))
end)

extractButton.MouseButton1Click:Connect(function()
    local part = findExtractionPart()

    if not part then
        setStatus("Extract point not found", Color3.fromRGB(255, 90, 90))
        return
    end

    if teleportTo(part.CFrame * CFrame.new(0, 3, 0)) then
        setStatus("Extract teleport done", Color3.fromRGB(100, 190, 255))
    end
end)

specialButton.MouseButton1Click:Connect(function()
    local target = CFrame.new(
        120.066177,
        42.1455879,
        210.65741,
        0.891437769,
        0,
        0.453143209,
        0,
        1,
        0,
        -0.453143209,
        0,
        0.891437769
    )

    if teleportTo(target) then
        setStatus("Special teleport done", Color3.fromRGB(205, 145, 255))
    end
end)

local minimized = false

minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized

    if minimized then
        tabBar.Visible = false
        pages.Visible = false
        statusBar.Visible = false
        minimizeButton.Text = "+"
        tween(main, {Size = UDim2.fromOffset(430, 54)}, 0.18)
    else
        tween(main, {Size = UDim2.fromOffset(430, 560)}, 0.18)
        task.wait(0.18)

        if gui.Parent then
            tabBar.Visible = true
            pages.Visible = true
            statusBar.Visible = true
            minimizeButton.Text = "–"
        end
    end
end)

closeButton.MouseButton1Click:Connect(function()
    isFarming = false
    gui:Destroy()
end)

ChestEvent.OnClientEvent:Connect(function(action, data)
    if not isFarming then
        return
    end

    if type(data) ~= "table" or not data.chestId then
        return
    end

    if action == "RequestSafePassword" then
        safeCloseChest()
        return
    end

    if action ~= "OpenChest" then
        return
    end

    isProcessingChest = true
    setStatus("Looting chest...", Color3.fromRGB(255, 230, 90))

    task.spawn(function()
        local items = data.items

        if type(items) == "table" then
            for _, item in ipairs(items) do
                if not isFarming or isInventoryFull then
                    break
                end

                if shouldTakeItem(item) and item.id ~= nil then
                    local result = table.pack(pcall(function()
                        return BackpackFunction:InvokeServer("TakeChestItem", data.chestId, item.id, "MyBackpackInventory")
                    end))

                    if result[1] and result[2] == false and result[3] == "Capacity exceeded" then
                        isInventoryFull = true
                        setFarmingState(false)
                        setStatus("Inventory full", Color3.fromRGB(255, 70, 80))
                        break
                    end

                    if result[1] then
                        stats.taken += 1
                    else
                        stats.failed += 1
                    end

                    updateStats()
                    task.wait(settings.takeDelay)
                else
                    stats.skipped += 1
                    updateStats()
                end
            end
        end

        task.wait(settings.closeDelay)
        safeCloseChest()
        task.wait(0.25)

        stats.chests += 1
        updateStats()

        isProcessingChest = false

        if isFarming and not isInventoryFull then
            setStatus("Farming...", Color3.fromRGB(80, 255, 130))
        end
    end)
end)

local function getChestId(object)
    local attribute = object:GetAttribute("ChestId")

    if attribute ~= nil then
        return tostring(attribute)
    end

    local pivot = object:GetPivot()
    local position = pivot.Position

    return object.Name .. "_" .. math.floor(position.X) .. "_" .. math.floor(position.Y) .. "_" .. math.floor(position.Z)
end

local function processNextChest()
    if not ChestFolder or not ChestFolder.Parent then
        ChestFolder = workspace:FindFirstChild(ChestFolderName)
    end

    if not ChestFolder then
        setStatus("Chest folder not found", Color3.fromRGB(255, 90, 90))
        return
    end

    local root = getRoot()

    if not root then
        setStatus("Waiting for character", Color3.fromRGB(255, 200, 90))
        return
    end

    local foundChest = false

    for _, object in ipairs(ChestFolder:GetChildren()) do
        if object:IsA("Model") and object.Name ~= SafeName then
            local chestId = getChestId(object)

            if chestId and not lootedChests[chestId] then
                foundChest = true
                setStatus("Opening chest...", Color3.fromRGB(255, 220, 90))

                local okPivot, pivot = pcall(function()
                    return object:GetPivot()
                end)

                if not okPivot then
                    failedChests[chestId] = (failedChests[chestId] or 0) + 1
                    stats.failed += 1
                    updateStats()

                    if failedChests[chestId] >= 2 then
                        lootedChests[chestId] = true
                    end

                    break
                end

                root.CFrame = pivot * CFrame.new(0, 3, 0)
                task.wait(settings.openDelay)

                local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)

                if not prompt then
                    failedChests[chestId] = (failedChests[chestId] or 0) + 1
                    stats.failed += 1
                    updateStats()

                    if failedChests[chestId] >= 2 then
                        lootedChests[chestId] = true
                    end

                    setStatus("Prompt not found", Color3.fromRGB(255, 110, 90))
                    break
                end

                local fired = firePrompt(prompt)

                if not fired then
                    failedChests[chestId] = (failedChests[chestId] or 0) + 1
                    stats.failed += 1
                    updateStats()

                    if failedChests[chestId] >= 2 then
                        lootedChests[chestId] = true
                    end

                    setStatus("Prompt failed", Color3.fromRGB(255, 110, 90))
                    break
                end

                local startedAt = os.clock()

                while isFarming and not isProcessingChest and os.clock() - startedAt < settings.openTimeout do
                    task.wait(0.05)
                end

                if isProcessingChest then
                    while isFarming and isProcessingChest do
                        task.wait(0.05)
                    end

                    lootedChests[chestId] = true
                else
                    failedChests[chestId] = (failedChests[chestId] or 0) + 1
                    stats.failed += 1
                    updateStats()

                    if failedChests[chestId] >= 2 then
                        lootedChests[chestId] = true
                    end

                    safeCloseChest()
                    setStatus("Open timeout", Color3.fromRGB(255, 160, 80))
                end

                break
            end
        end
    end

    if not foundChest and isFarming then
        setStatus("No new chests", Color3.fromRGB(170, 170, 190))
        task.wait(0.8)
    end
end

refreshRarityRows()
updateStats()
setStatus("Idle", Color3.fromRGB(190, 190, 205))

task.spawn(function()
    while gui.Parent do
        task.wait(0.35)

        local ok = pcall(function()
            if isFarming and not isInventoryFull and not isProcessingChest then
                processNextChest()
            end
        end)

        if not ok then
            stats.failed += 1
            updateStats()
            setStatus("Loop error", Color3.fromRGB(255, 90, 90))
            task.wait(0.8)
        end
    end
end)
