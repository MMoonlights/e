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

local settings = {
    coinsMode = "Greater",
    coinsValue = 0,
    capacityMode = "Greater",
    capacityValue = 0,
    selectedRarities = {
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true
    },
    openDelay = 0.45,
    takeDelay = 0.22,
    closeDelay = 0.35,
    openTimeout = 3
}

local rarities = {
    {id = 0, name = "Common"},
    {id = 1, name = "Uncommon"},
    {id = 2, name = "Rare"},
    {id = 3, name = "Epic"},
    {id = 4, name = "Legendary"},
    {id = 5, name = "Mythic"}
}

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

local oldGui = getGuiParent():FindFirstChild("SmartChestFarmV2")
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

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = object
    return corner
end

local function addStroke(object, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(70, 70, 90)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = object
    return stroke
end

local function addGradient(object, color1, color2)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = 25
    gradient.Parent = object
    return gradient
end

local function tween(object, props, time)
    TweenService:Create(object, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local gui = create("ScreenGui", {
    Name = "SmartChestFarmV2",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, getGuiParent())

local main = create("Frame", {
    Size = UDim2.fromOffset(340, 500),
    Position = UDim2.new(0, 22, 0.5, -250),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0,
    Active = true
}, gui)
addCorner(main, 14)
addStroke(main, Color3.fromRGB(90, 90, 120), 1, 0.25)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Color3.fromRGB(35, 35, 55),
    BorderSizePixel = 0,
    ZIndex = 2
}, main)
addCorner(header, 14)
addGradient(header, Color3.fromRGB(44, 44, 72), Color3.fromRGB(24, 24, 38))

local headerFix = create("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = Color3.fromRGB(24, 24, 38),
    BorderSizePixel = 0,
    ZIndex = 2
}, header)

local title = create("TextLabel", {
    Size = UDim2.new(1, -95, 0, 24),
    Position = UDim2.fromOffset(16, 6),
    BackgroundTransparency = 1,
    Text = "Chest Auto Farm",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
}, header)

local subtitle = create("TextLabel", {
    Size = UDim2.new(1, -95, 0, 16),
    Position = UDim2.fromOffset(16, 28),
    BackgroundTransparency = 1,
    Text = "Smart loot filter",
    TextColor3 = Color3.fromRGB(165, 165, 190),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
}, header)

local minimizeButton = create("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -72, 0, 9),
    BackgroundColor3 = Color3.fromRGB(45, 45, 62),
    BorderSizePixel = 0,
    Text = "–",
    TextColor3 = Color3.fromRGB(230, 230, 240),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    ZIndex = 4
}, header)
addCorner(minimizeButton, 8)

local closeButton = create("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -36, 0, 9),
    BackgroundColor3 = Color3.fromRGB(75, 35, 45),
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = Color3.fromRGB(255, 210, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    ZIndex = 4
}, header)
addCorner(closeButton, 8)

local content = create("Frame", {
    Size = UDim2.new(1, -28, 1, -96),
    Position = UDim2.fromOffset(14, 60),
    BackgroundTransparency = 1,
    ZIndex = 2
}, main)

local statusBar = create("Frame", {
    Size = UDim2.new(1, -28, 0, 28),
    Position = UDim2.new(0, 14, 1, -38),
    BackgroundColor3 = Color3.fromRGB(28, 28, 40),
    BorderSizePixel = 0,
    ZIndex = 3
}, main)
addCorner(statusBar, 8)
addStroke(statusBar, Color3.fromRGB(60, 60, 80), 1, 0.45)

local statusDot = create("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.fromOffset(12, 10),
    BackgroundColor3 = Color3.fromRGB(130, 130, 145),
    BorderSizePixel = 0,
    ZIndex = 4
}, statusBar)
addCorner(statusDot, 99)

local statusLabel = create("TextLabel", {
    Size = UDim2.new(1, -32, 1, 0),
    Position = UDim2.fromOffset(28, 0),
    BackgroundTransparency = 1,
    Text = "Idle",
    TextColor3 = Color3.fromRGB(180, 180, 195),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statusBar)

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color or Color3.fromRGB(180, 180, 195)
    statusDot.BackgroundColor3 = color or Color3.fromRGB(130, 130, 145)
end

local function createLabel(parent, text, y)
    return create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.fromOffset(0, y),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(205, 205, 220),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, parent)
end

local function createCard(parent, y, height)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = Color3.fromRGB(24, 24, 34),
        BorderSizePixel = 0,
        ZIndex = 3
    }, parent)
    addCorner(card, 10)
    addStroke(card, Color3.fromRGB(55, 55, 75), 1, 0.4)
    return card
end

local rarityLabel = createLabel(content, "Rarity Filter", 0)

local rarityButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.fromOffset(0, 24),
    BackgroundColor3 = Color3.fromRGB(30, 30, 44),
    BorderSizePixel = 0,
    Text = "All Rarities",
    TextColor3 = Color3.fromRGB(240, 240, 245),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 20
}, content)
addCorner(rarityButton, 9)
addStroke(rarityButton, Color3.fromRGB(65, 65, 90), 1, 0.3)

local rarityPadding = Instance.new("UIPadding")
rarityPadding.PaddingLeft = UDim.new(0, 12)
rarityPadding.PaddingRight = UDim.new(0, 34)
rarityPadding.Parent = rarityButton

local rarityArrow = create("TextLabel", {
    Size = UDim2.fromOffset(28, 34),
    Position = UDim2.new(1, -30, 0, 24),
    BackgroundTransparency = 1,
    Text = "▼",
    TextColor3 = Color3.fromRGB(180, 180, 200),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 21
}, content)

local rarityList = create("Frame", {
    Size = UDim2.new(1, 0, 0, 198),
    Position = UDim2.fromOffset(0, 62),
    BackgroundColor3 = Color3.fromRGB(22, 22, 32),
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 30
}, content)
addCorner(rarityList, 10)
addStroke(rarityList, Color3.fromRGB(80, 80, 110), 1, 0.15)

local rarityListLayout = create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, rarityList)

local rarityListPadding = Instance.new("UIPadding")
rarityListPadding.PaddingTop = UDim.new(0, 8)
rarityListPadding.PaddingLeft = UDim.new(0, 8)
rarityListPadding.PaddingRight = UDim.new(0, 8)
rarityListPadding.PaddingBottom = UDim.new(0, 8)
rarityListPadding.Parent = rarityList

local quickRarityRow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
    ZIndex = 31
}, rarityList)

local selectAllButton = create("TextButton", {
    Size = UDim2.new(0.5, -4, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Color3.fromRGB(45, 70, 50),
    BorderSizePixel = 0,
    Text = "Select All",
    TextColor3 = Color3.fromRGB(210, 255, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 32
}, quickRarityRow)
addCorner(selectAllButton, 7)

local clearAllButton = create("TextButton", {
    Size = UDim2.new(0.5, -4, 1, 0),
    Position = UDim2.new(0.5, 4, 0, 0),
    BackgroundColor3 = Color3.fromRGB(70, 45, 50),
    BorderSizePixel = 0,
    Text = "Clear",
    TextColor3 = Color3.fromRGB(255, 215, 220),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 32
}, quickRarityRow)
addCorner(clearAllButton, 7)

local rarityButtons = {}

local function refreshRarityText()
    local selectedCount = 0
    local names = {}

    for _, rarity in ipairs(rarities) do
        if settings.selectedRarities[rarity.id] then
            selectedCount += 1
            table.insert(names, rarity.name)
        end
    end

    if selectedCount == #rarities then
        rarityButton.Text = "All Rarities"
    elseif selectedCount == 0 then
        rarityButton.Text = "No Rarities"
    else
        rarityButton.Text = table.concat(names, ", ")
    end

    for _, rarity in ipairs(rarities) do
        local button = rarityButtons[rarity.id]
        if button then
            local selected = settings.selectedRarities[rarity.id] == true
            button.Text = selected and "✓  " .. rarity.name or "    " .. rarity.name
            button.TextColor3 = selected and Color3.fromRGB(190, 255, 205) or Color3.fromRGB(170, 170, 185)
            button.BackgroundColor3 = selected and Color3.fromRGB(38, 75, 50) or Color3.fromRGB(32, 32, 45)
        end
    end
end

for index, rarity in ipairs(rarities) do
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(32, 32, 45),
        BorderSizePixel = 0,
        Text = rarity.name,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = index + 1,
        ZIndex = 31
    }, rarityList)
    addCorner(button, 6)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = button

    rarityButtons[rarity.id] = button

    button.MouseButton1Click:Connect(function()
        settings.selectedRarities[rarity.id] = not settings.selectedRarities[rarity.id]
        refreshRarityText()
    end)
end

local filterCard = createCard(content, 82, 126)

local filterTitle = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.fromOffset(12, 10),
    BackgroundTransparency = 1,
    Text = "Loot Filters",
    TextColor3 = Color3.fromRGB(225, 225, 240),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, filterCard)

local function createFilterRow(parent, labelText, y, modeKey, valueKey)
    local label = create("TextLabel", {
        Size = UDim2.fromOffset(88, 28),
        Position = UDim2.fromOffset(12, y),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = Color3.fromRGB(190, 190, 205),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, parent)

    local modeButton = create("TextButton", {
        Size = UDim2.fromOffset(88, 28),
        Position = UDim2.fromOffset(100, y),
        BackgroundColor3 = Color3.fromRGB(34, 34, 48),
        BorderSizePixel = 0,
        Text = "Greater",
        TextColor3 = Color3.fromRGB(235, 235, 245),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 4
    }, parent)
    addCorner(modeButton, 7)
    addStroke(modeButton, Color3.fromRGB(60, 60, 82), 1, 0.45)

    local box = create("TextBox", {
        Size = UDim2.new(1, -210, 0, 28),
        Position = UDim2.fromOffset(198, y),
        BackgroundColor3 = Color3.fromRGB(34, 34, 48),
        BorderSizePixel = 0,
        Text = "0",
        PlaceholderText = "Any",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 135),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 4
    }, parent)
    addCorner(box, 7)
    addStroke(box, Color3.fromRGB(60, 60, 82), 1, 0.45)

    local function refreshMode()
        modeButton.Text = settings[modeKey] == "Greater" and "Greater" or "Less"
    end

    modeButton.MouseButton1Click:Connect(function()
        settings[modeKey] = settings[modeKey] == "Greater" and "Less" or "Greater"
        refreshMode()
    end)

    box.FocusLost:Connect(function()
        local number = tonumber(box.Text)
        if not number or number < 0 then
            number = 0
        end
        settings[valueKey] = number
        box.Text = tostring(number)
    end)

    refreshMode()

    return modeButton, box
end

createFilterRow(filterCard, "Coins", 42, "coinsMode", "coinsValue")
createFilterRow(filterCard, "Weight", 82, "capacityMode", "capacityValue")

local statsCard = createCard(content, 222, 78)

local statsTitle = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.fromOffset(12, 8),
    BackgroundTransparency = 1,
    Text = "Session Stats",
    TextColor3 = Color3.fromRGB(225, 225, 240),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statsCard)

local statsLine1 = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 18),
    Position = UDim2.fromOffset(12, 34),
    BackgroundTransparency = 1,
    Text = "Chests: 0  |  Taken: 0",
    TextColor3 = Color3.fromRGB(185, 185, 200),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statsCard)

local statsLine2 = create("TextLabel", {
    Size = UDim2.new(1, -24, 0, 18),
    Position = UDim2.fromOffset(12, 53),
    BackgroundTransparency = 1,
    Text = "Skipped: 0  |  Failed: 0",
    TextColor3 = Color3.fromRGB(185, 185, 200),
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4
}, statsCard)

local function updateStats()
    statsLine1.Text = "Chests: " .. stats.chests .. "  |  Taken: " .. stats.taken
    statsLine2.Text = "Skipped: " .. stats.skipped .. "  |  Failed: " .. stats.failed
end

local startButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 42),
    Position = UDim2.fromOffset(0, 316),
    BackgroundColor3 = Color3.fromRGB(75, 190, 115),
    BorderSizePixel = 0,
    Text = "Start Farming",
    TextColor3 = Color3.fromRGB(10, 20, 14),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 4
}, content)
addCorner(startButton, 10)

local specialButton = create("TextButton", {
    Size = UDim2.new(0.5, -5, 0, 36),
    Position = UDim2.fromOffset(0, 370),
    BackgroundColor3 = Color3.fromRGB(130, 85, 200),
    BorderSizePixel = 0,
    Text = "Special TP",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 4
}, content)
addCorner(specialButton, 9)

local extractButton = create("TextButton", {
    Size = UDim2.new(0.5, -5, 0, 36),
    Position = UDim2.new(0.5, 5, 0, 370),
    BackgroundColor3 = Color3.fromRGB(65, 125, 210),
    BorderSizePixel = 0,
    Text = "Extract TP",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 4
}, content)
addCorner(extractButton, 9)

local resetButton = create("TextButton", {
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.fromOffset(0, 418),
    BackgroundColor3 = Color3.fromRGB(42, 42, 58),
    BorderSizePixel = 0,
    Text = "Reset Cache",
    TextColor3 = Color3.fromRGB(220, 220, 235),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 4
}, content)
addCorner(resetButton, 8)
addStroke(resetButton, Color3.fromRGB(65, 65, 88), 1, 0.45)

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
        startButton.TextColor3 = Color3.fromRGB(10, 20, 14)
        tween(startButton, {BackgroundColor3 = Color3.fromRGB(75, 190, 115)}, 0.16)
        if isInventoryFull then
            setStatus("Inventory full", Color3.fromRGB(255, 70, 80))
        else
            setStatus("Stopped", Color3.fromRGB(220, 220, 235))
        end
    end
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

local function shouldTakeItem(item)
    if type(item) ~= "table" then
        return false
    end

    local rarity = tonumber(item.rare) or 0
    local coins = tonumber(item.coin) or 0
    local capacity = tonumber(item.useCapacity) or 0

    if not settings.selectedRarities[rarity] then
        return false
    end

    if settings.coinsValue > 0 then
        if settings.coinsMode == "Greater" and coins < settings.coinsValue then
            return false
        end

        if settings.coinsMode == "Less" and coins > settings.coinsValue then
            return false
        end
    end

    if settings.capacityValue > 0 then
        if settings.capacityMode == "Greater" and capacity < settings.capacityValue then
            return false
        end

        if settings.capacityMode == "Less" and capacity > settings.capacityValue then
            return false
        end
    end

    return true
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

local rarityOpen = false

local function setRarityOpen(state)
    rarityOpen = state
    rarityList.Visible = state
    rarityArrow.Text = state and "▲" or "▼"

    if state then
        tween(rarityButton, {BackgroundColor3 = Color3.fromRGB(38, 38, 56)}, 0.12)
    else
        tween(rarityButton, {BackgroundColor3 = Color3.fromRGB(30, 30, 44)}, 0.12)
    end
end

rarityButton.MouseButton1Click:Connect(function()
    setRarityOpen(not rarityOpen)
end)

rarityArrow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        setRarityOpen(not rarityOpen)
    end
end)

selectAllButton.MouseButton1Click:Connect(function()
    for _, rarity in ipairs(rarities) do
        settings.selectedRarities[rarity.id] = true
    end
    refreshRarityText()
end)

clearAllButton.MouseButton1Click:Connect(function()
    for _, rarity in ipairs(rarities) do
        settings.selectedRarities[rarity.id] = false
    end
    refreshRarityText()
end)

startButton.MouseButton1Click:Connect(function()
    setFarmingState(not isFarming)
end)

resetButton.MouseButton1Click:Connect(function()
    resetCache()
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
        content.Visible = false
        statusBar.Visible = false
        minimizeButton.Text = "+"
        tween(main, {Size = UDim2.fromOffset(340, 48)}, 0.18)
    else
        tween(main, {Size = UDim2.fromOffset(340, 500)}, 0.18)
        task.wait(0.18)
        if gui.Parent then
            content.Visible = true
            statusBar.Visible = true
        end
        minimizeButton.Text = "–"
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

                if shouldTakeItem(item) then
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

refreshRarityText()
updateStats()
setStatus("Idle", Color3.fromRGB(180, 180, 195))

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
