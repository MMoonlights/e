local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local ChestEvent = ReplicatedStorage:WaitForChild("Event").Backpack.ChestRemoteEvent
local BackpackFunction = ReplicatedStorage.Event.Backpack.BackpackRemoteFunction

local player = Players.LocalPlayer
local isProcessingChest = false
local lootedChests = {}
local isFarming = false

local settings = {
    minRarity = 0,
    coinMode = "Greater",
    coinValue = 0,
    capMode = "Greater",
    capValue = 0
}

local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ChestAutoFarmUI"
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 300, 0, 360)
    main.Position = UDim2.new(0.5, -150, 0.5, -180)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(137, 180, 250)
    stroke.Thickness = 1
    stroke.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Chest Auto Farm"
    title.TextColor3 = Color3.fromRGB(205, 214, 244)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = main

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -50)
    container.Position = UDim2.new(0, 10, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local function createRow(order, labelText)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.LayoutOrder = order
        row.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(205, 214, 244)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        return row
    end

    local function createInput(parent, placeholder, isNumber)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.6, -5, 1, 0)
        box.Position = UDim2.new(0.4, 5, 0, 0)
        box.BackgroundColor3 = Color3.fromRGB(49, 50, 68)
        box.TextColor3 = Color3.fromRGB(205, 214, 244)
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.PlaceholderText = placeholder
        box.Text = ""
        box.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = box

        if isNumber then
            box:GetPropertyChangedSignal("Text"):Connect(function()
                local num = string.match(box.Text, "%d+")
                if num ~= box.Text then
                    box.Text = num or ""
                end
            end)
        end

        return box
    end

    local function createToggle(parent, text)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.3, 0, 1, 0)
        btn.Position = UDim2.new(0.4, 5, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(49, 50, 68)
        btn.TextColor3 = Color3.fromRGB(205, 214, 244)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = text
        btn.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn

        return btn
    end

    local rarityRow = createRow(1, "Min Rarity (0-5)")
    local rarityInput = createInput(rarityRow, "0", true)
    rarityInput.Text = "0"
    rarityInput.FocusLost:Connect(function()
        local val = tonumber(rarityInput.Text) or 0
        settings.minRarity = math.clamp(val, 0, 5)
        rarityInput.Text = tostring(settings.minRarity)
    end)

    local coinRow = createRow(2, "Coins")
    local coinModeBtn = createToggle(coinRow, settings.coinMode)
    local coinInput = createInput(coinRow, "0=Any", true)
    coinInput.Size = UDim2.new(0.3, -10, 1, 0)
    coinInput.Position = UDim2.new(0.7, 5, 0, 0)
    coinInput.Text = "0"

    coinModeBtn.MouseButton1Click:Connect(function()
        if settings.coinMode == "Greater" then
            settings.coinMode = "Less"
        else
            settings.coinMode = "Greater"
        end
        coinModeBtn.Text = settings.coinMode
    end)

    coinInput.FocusLost:Connect(function()
        settings.coinValue = tonumber(coinInput.Text) or 0
        coinInput.Text = tostring(settings.coinValue)
    end)

    local capRow = createRow(3, "Capacity")
    local capModeBtn = createToggle(capRow, settings.capMode)
    local capInput = createInput(capRow, "0=Any", true)
    capInput.Size = UDim2.new(0.3, -10, 1, 0)
    capInput.Position = UDim2.new(0.7, 5, 0, 0)
    capInput.Text = "0"

    capModeBtn.MouseButton1Click:Connect(function()
        if settings.capMode == "Greater" then
            settings.capMode = "Less"
        else
            settings.capMode = "Greater"
        end
        capModeBtn.Text = settings.capMode
    end)

    capInput.FocusLost:Connect(function()
        settings.capValue = tonumber(capInput.Text) or 0
        capInput.Text = tostring(settings.capValue)
    end)

    local farmBtn = Instance.new("TextButton")
    farmBtn.Size = UDim2.new(1, 0, 0, 45)
    farmBtn.BackgroundColor3 = Color3.fromRGB(137, 180, 250)
    farmBtn.TextColor3 = Color3.fromRGB(30, 30, 46)
    farmBtn.Font = Enum.Font.GothamBold
    farmBtn.TextSize = 16
    farmBtn.Text = "Start Farming"
    farmBtn.LayoutOrder = 4
    farmBtn.Parent = container

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6)
    fc.Parent = farmBtn

    farmBtn.MouseButton1Click:Connect(function()
        isFarming = not isFarming
        if isFarming then
            farmBtn.Text = "Stop Farming"
            farmBtn.BackgroundColor3 = Color3.fromRGB(243, 139, 168)
            print("Auto farm started.")
        else
            farmBtn.Text = "Start Farming"
            farmBtn.BackgroundColor3 = Color3.fromRGB(137, 180, 250)
            print("Auto farm stopped.")
        end
    end)

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, 0, 0, 20)
    statusText.BackgroundTransparency = 1
    statusText.TextColor3 = Color3.fromRGB(166, 173, 200)
    statusText.Font = Enum.Font.Gotham
    statusText.TextSize = 12
    statusText.Text = "Status: Idle"
    statusText.LayoutOrder = 5
    statusText.Parent = container

    return statusText
end

local statusLabel = createUI()

local function updateStatus(msg)
    if statusLabel then
        statusLabel.Text = "Status: " .. msg
    end
end

local function shouldTakeItem(item)
    local rarity = item.rare or 0
    local coin = item.coin or 0
    local cap = item.useCapacity or 0

    if rarity < settings.minRarity then return false end

    if settings.coinValue > 0 then
        if settings.coinMode == "Greater" and coin < settings.coinValue then return false end
        if settings.coinMode == "Less" and coin > settings.coinValue then return false end
    end

    if settings.capValue > 0 then
        if settings.capMode == "Greater" and cap < settings.capValue then return false end
        if settings.capMode == "Less" and cap > settings.capValue then return false end
    end

    return true
end

ChestEvent.OnClientEvent:Connect(function(eventType, eventData)
    if eventType == "OpenChest" and eventData then
        isProcessingChest = true
        task.spawn(function()
            print("Chest opened. ID: " .. tostring(eventData.chestId))
            updateStatus("Looting chest...")
            
            if eventData.items and #eventData.items > 0 then
                print("Items found: " .. #eventData.items)
                for index, item in ipairs(eventData.items) do
                    if shouldTakeItem(item) then
                        print("Taking item: " .. tostring(item.name))
                        task.spawn(function()
                            pcall(function()
                                BackpackFunction:InvokeServer("TakeChestItem", eventData.chestId, item.id, "MyBackpackInventory")
                            end)
                        end)
                        task.wait(0.15)
                    else
                        print("Skipping item: " .. tostring(item.name) .. " (Filters)")
                    end
                end
            else
                print("Chest is empty.")
            end
            
            print("Closing chest...")
            task.wait(0.2)
            
            task.spawn(function()
                pcall(function()
                    BackpackFunction:InvokeServer("CloseChest")
                end)
            end)
            
            task.wait(0.5)
            isProcessingChest = false
            updateStatus("Idle")
            print("Ready for next chest")
        end)
    end
end)

local function isChestObject(object)
    local current = object
    while current and current ~= Workspace do
        local name = string.lower(current.Name)
        if string.find(name, "chest") or string.find(name, "crate") or string.find(name, "loot") or string.find(name, "box") then
            return true
        end
        current = current.Parent
    end
    return false
end

local function findChest()
    local closestPart = nil
    local closestDist = math.huge
    local closestPrompt = nil
    
    for _, object in ipairs(Workspace:GetDescendants()) do
        if (object:IsA("Model") or object:IsA("BasePart")) and isChestObject(object) then
            local targetPart = object:IsA("BasePart") and object or (object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart"))
            
            if targetPart and not lootedChests[targetPart] then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - targetPart.Position).Magnitude
                    if distance < closestDist then
                        closestDist = distance
                        closestPart = targetPart
                        closestPrompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    end
                end
            end
        end
    end
    
    return closestPart, closestPrompt, closestDist
end

task.spawn(function()
    print("UI Loaded. Waiting for user to start...")
    
    while true do
        pcall(function()
            if isFarming then
                if not isProcessingChest then
                    local chestPart, prompt, dist = findChest()
                    
                    if chestPart then
                        updateStatus("Moving to chest...")
                        local character = player.Character
                        
                        if character and character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.CFrame = chestPart.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.5)
                            
                            if prompt then
                                updateStatus("Opening chest...")
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
                            end
                            
                            local timeout = 0
                            while not isProcessingChest and timeout < 2 do
                                task.wait(0.1)
                                timeout += 0.1
                            end
                            
                            if not isProcessingChest then
                                print("Failed to open chest. Blacklisting it.")
                                lootedChests[chestPart] = true
                            else
                                print("Chest successfully opened. Blacklisting.")
                                lootedChests[chestPart] = true
                            end
                        end
                    else
                        updateStatus("Searching for chests...")
                    end
                end
            end
        end)
        
        task.wait(0.5)
    end
end)
