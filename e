-- СЕРВИСЫ И ПЕРЕМЕННЫЕ
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChestEvent = ReplicatedStorage:WaitForChild("Event").Backpack.ChestRemoteEvent
local BackpackFunction = ReplicatedStorage.Event.Backpack.BackpackRemoteFunction

local ChestFolder = workspace["\229\174\157\231\174\177"] -- Папка 宝物
local SafeName = "\228\191\157\233\153\169\231\174\177"    -- Сейф 密码箱

local player = Players.LocalPlayer
local isProcessingChest = false
local isInventoryFull = false
local lootedChests = {}

-- НАСТРОЙКИ ФИЛЬТРОВ
local settings = {
    coinsMode = "Greater",
    coinsValue = 0,
    capMode = "Greater",
    capValue = 0,
    rarityToggles = {true, true, true, true, true, true} -- Common, Uncommon, Rare, Epic, Legendary, Mythic
}

local rarityNames = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
local rarityColors = {
    Color3.fromRGB(180, 180, 180), -- Common
    Color3.fromRGB(30, 255, 0),    -- Uncommon
    Color3.fromRGB(0, 100, 255),   -- Rare
    Color3.fromRGB(180, 0, 255),   -- Epic
    Color3.fromRGB(255, 170, 0),   -- Legendary
    Color3.fromRGB(255, 0, 0)      -- Mythic
}

-- ФУНКЦИЯ ПРОВЕРКИ ПРЕДМЕТА
local function shouldTakeItem(item)
    local rarity = item.rare or 0
    local coin = item.coin or 0
    local cap = item.useCapacity or 0

    -- Проверка рарити
    if not settings.rarityToggles[rarity + 1] then return false end

    -- Проверка монет
    if settings.coinsValue > 0 then
        if settings.coinsMode == "Greater" and coin < settings.coinsValue then return false end
        if settings.coinsMode == "Less" and coin > settings.coinsValue then return false end
    end

    -- Проверка места
    if settings.capValue > 0 then
        if settings.capMode == "Greater" and cap < settings.capValue then return false end
        if settings.capMode == "Less" and cap > settings.capValue then return false end
    end

    return true
end

-- УНИВЕРСАЛЬНОЕ НАЖАТИЕ КНОПКИ
local function firePrompt(prompt)
    if not prompt then return false end
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    elseif fire_proximityprompt then
        pcall(fire_proximityprompt, prompt)
    else
        pcall(function()
            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end)
    end
    return true
end

-- СОЗДАНИЕ МЕНЮ
local gui = Instance.new("ScreenGui")
gui.Name = "SmartChestFarm"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 420)
main.Position = UDim2.new(0, 20, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", main).Color = Color3.fromRGB(100, 100, 120)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "Chest Auto Farm"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -85)
scroll.Position = UDim2.new(0, 10, 0, 40)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.Parent = main
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)

-- Секция Рарити
local rarLabel = Instance.new("TextLabel")
rarLabel.Size = UDim2.new(1, 0, 0, 20)
rarLabel.BackgroundTransparency = 1
rarLabel.Text = "Rarity Filter:"
rarLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rarLabel.Font = Enum.Font.GothamBold
rarLabel.TextSize = 13
rarLabel.TextXAlignment = Enum.TextXAlignment.Left
rarLabel.Parent = scroll

local rarityFrame = Instance.new("Frame")
rarityFrame.Size = UDim2.new(1, 0, 0, 30)
rarityFrame.BackgroundTransparency = 1
rarityFrame.Parent = scroll
local rarLayout = Instance.new("UIListLayout")
rarLayout.FillDirection = Enum.FillDirection.Horizontal
rarLayout.Padding = UDim.new(0, 4)
rarLayout.Parent = rarityFrame

for i = 1, 6 do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 42, 0, 25)
    btn.BackgroundColor3 = rarityColors[i]
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Text = rarityNames[i]
    btn.AutoButtonColor = false
    btn.Parent = rarityFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        settings.rarityToggles[i] = not settings.rarityToggles[i]
        btn.TextTransparency = settings.rarityToggles[i] and 0 or 0.7
    end)
end

-- Функция для создания строки фильтра (Монеты/Место)
local function createFilterRow(labelText, defaultMode)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 50, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(0, 60, 0, 25)
    modeBtn.Position = UDim2.new(0, 55, 0, 2)
    modeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeBtn.Font = Enum.Font.Gotham
    modeBtn.TextSize = 11
    modeBtn.Text = defaultMode == "Greater" and "> Больше" or "< Меньше"
    modeBtn.Parent = row
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 4)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 60, 0, 25)
    box.Position = UDim2.new(0, 120, 0, 2)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.PlaceholderText = "0 = Any"
    box.Text = "0"
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    return modeBtn, box
end

local coinModeBtn, coinBox = createFilterRow("Coins:", "Greater")
local capModeBtn, capBox = createFilterRow("Cap:", "Greater")

coinModeBtn.MouseButton1Click:Connect(function()
    settings.coinsMode = settings.coinsMode == "Greater" and "Less" or "Greater"
    coinModeBtn.Text = settings.coinsMode == "Greater" and "> Больше" or "< Меньше"
end)
coinBox.FocusLost:Connect(function() settings.coinsValue = tonumber(coinBox.Text) or 0 end)

capModeBtn.MouseButton1Click:Connect(function()
    settings.capMode = settings.capMode == "Greater" and "Less" or "Greater"
    capModeBtn.Text = settings.capMode == "Greater" and "> Больше" or "< Меньше"
end)
capBox.FocusLost:Connect(function() settings.capValue = tonumber(capBox.Text) or 0 end)

-- Статус
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 1, -40)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Text = "Status: Idle"
statusLabel.Parent = main

-- Кнопка Старт/Стоп
local farmBtn = Instance.new("TextButton")
farmBtn.Size = UDim2.new(1, -20, 0, 30)
farmBtn.Position = UDim2.new(0, 10, 1, -65)
farmBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
farmBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
farmBtn.Font = Enum.Font.GothamBold
farmBtn.TextSize = 14
farmBtn.Text = "Start Farming"
farmBtn.Parent = main
Instance.new("UICorner", farmBtn).CornerRadius = UDim.new(0, 6)

local isFarming = false

local function updateStatus(msg, color)
    statusLabel.Text = "Status: " .. msg
    statusLabel.TextColor3 = color or Color3.fromRGB(150, 150, 150)
end

farmBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    if isFarming then
        isInventoryFull = false
        farmBtn.Text = "Stop Farming"
        farmBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        updateStatus("Farming...", Color3.fromRGB(80, 255, 80))
    else
        farmBtn.Text = "Start Farming"
        farmBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        updateStatus("Stopped", Color3.fromRGB(255, 255, 255))
    end
end)

-- ЛОГИКА ОТКРЫТИЯ И СБОРА
ChestEvent.OnClientEvent:Connect(function(action, data)
    if not data or not data.chestId then return end
    if action == "RequestSafePassword" then
        pcall(function() BackpackFunction:InvokeServer("CloseChest") end)
        return
    end

    if action == "OpenChest" then
        isProcessingChest = true
        updateStatus("Looting chest...", Color3.fromRGB(255, 255, 0))
        
        task.spawn(function()
            if data.items and #data.items > 0 then
                for _, item in ipairs(data.items) do
                    if isInventoryFull then break end
                    
                    if shouldTakeItem(item) then
                        -- ВНИМАНИЕ: pcall возвращает (успех, результат1, результат2...)
                        local ok, res1, res2 = pcall(function()
                            return BackpackFunction:InvokeServer("TakeChestItem", data.chestId, item.id, "MyBackpackInventory")
                        end)
                        
                        -- ПРОВЕРКА НА ПОЛНЫЙ ИНВЕНТАРЬ
                        if ok and res1 == false and res2 == "Capacity exceeded" then
                            isInventoryFull = true
                            isFarming = false
                            farmBtn.Text = "Start Farming"
                            farmBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                            updateStatus("INVENTORY FULL! Stopped.", Color3.fromRGB(255, 50, 50))
                            print("ИНВЕНТАРЬ ПОЛОН. ФЕРМ ОСТАНОВЛЕН.")
                            break
                        end
                    end
                    task.wait(0.1)
                end
            end
            
            task.wait(0.2)
            pcall(function() BackpackFunction:InvokeServer("CloseChest") end)
            task.wait(0.5)
            isProcessingChest = false
            if isFarming then updateStatus("Farming...", Color3.fromRGB(80, 255, 80)) end
        end)
    end
end)

-- ГЛАВНЫЙ ЦИКЛ ФАРМА
while task.wait(0.5) do
    pcall(function()
        if isFarming and not isInventoryFull and not isProcessingChest then
            local character = player.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end
            local hrp = character.HumanoidRootPart

            for _, obj in ipairs(ChestFolder:GetChildren()) do
                if obj:IsA("Model") and obj.Name ~= SafeName then 
                    local chestId = obj:GetAttribute("ChestId")
                    
                    if chestId and not lootedChests[chestId] then
                        hrp.CFrame = obj:GetPivot() * CFrame.new(0, 3, 0)
                        task.wait(0.5)
                        
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            firePrompt(prompt)
                            
                            local timeout = 0
                            while not isProcessingChest and timeout < 2.5 do
                                task.wait(0.1)
                                timeout += 0.1
                            end
                        end
                        
                        lootedChests[chestId] = true
                        break -- Идем к следующему сундуку
                    end
                end
            end
        end
    end)
end
