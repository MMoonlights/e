local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local localPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

local afkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end)

local guiInset = GuiService:GetGuiInset()
local INSET_Y = guiInset.Y

local FixCar   = ReplicatedStorage.Remotes.Repair.FixCar
local CollectJunk = ReplicatedStorage.Remotes.Base.CollectJunk
local SellCar  = ReplicatedStorage.Remotes.Garage.SellCar
local BuyCar   = ReplicatedStorage.Remotes.Merchant.BuyCar
local SpawnCar = ReplicatedStorage.Remotes.SpawnCar

local currentCarName = "Set Car Name"
local isToggled = false
local running = true

local flipSelectedRarities = { [0] = false, [1] = false, [2] = true, [3] = false, [4] = false }
local flipRunning = false

local farmSelectedRarities = { [0] = false, [1] = false, [2] = true, [3] = false, [4] = false }
local farmRunning = false

local areaRotateRunning = false
local currentAreaIndex = 1

local farmAreaRotateRunning = false
local farmAreaIndex = 1

local playerBaseId = "base_" .. tostring(localPlayer.UserId)

local collectRunning = false
local isCollecting = false
local collectInterval = 300
local collectNextTime = 0

local deliveryRunning = false
local isDelivering = false
local DELIVERY_COOLDOWN = 30

local isProcessing = false
local RARITY_INFO = {
    [0] = { name = "Common" },
    [1] = { name = "Uncommon" },
    [2] = { name = "Rare" },
    [3] = { name = "Epic" },
    [4] = { name = "Legendary" },
}

local carRarityCache = {
    ["Acadi RVS Sedan"] = 0, ["Artho F9 RT"] = 4, ["Artho F9 ST"] = 3, ["Artho G1000"] = 0,
    ["Artho G451"] = 1, ["Artho G623"] = 2, ["Artho G672"] = 1, ["Artho G770"] = 3,
    ["Artho VS600"] = 3, ["Artho X723"] = 1, ["Bantt Rental"] = 0, ["Beressa Char"] = 4,
    ["Beressa Verona"] = 4, ["Bogdan 2099"] = 0, ["Chiverleta Cerano"] = 1, ["Chiverleta Cerano XZ2"] = 3,
    ["Chiverleta Ceretta X05"] = 2, ["Chiverleta Ceretta X07"] = 3, ["Chiverleta Golde"] = 0,
    ["Chiverleta Imalo 67"] = 3, ["Chiverleta Outskirts BT"] = 0, ["Chiverleta Taohra BT"] = 0,
    ["Chiverleta Taohra SVV"] = 2, ["Cryele 222B"] = 2, ["DAW 0909"] = 0, ["Dawson Competition"] = 3,
    ["Dawson Hammer"] = 3, ["Dawson Hammer 70"] = 3, ["Dawson Hammer JHT8"] = 1, ["Dawson Hammer SCV"] = 2,
    ["Dawson Rhino SCT"] = 3, ["Deserter Grand Prince"] = 3, ["Deutschotoren C2"] = 3, ["Deutschotoren C297x"] = 2,
    ["Deutschotoren C3"] = 3, ["Deutschotoren C3 B63"] = 0, ["Deutschotoren C393"] = 2, ["Deutschotoren C3E5"] = 1,
    ["Deutschotoren C4 DSG"] = 3, ["Deutschotoren C483"] = 3, ["Deutschotoren C5 600"] = 3, ["Deutschotoren C5 B21"] = 0,
    ["Deutschotoren C543"] = 0, ["Deutschotoren C560"] = 1, ["Deutschotoren C783"] = 1, ["Deutschotoren C873"] = 3,
    ["Deutschotoren S5"] = 3, ["Deutschotoren U8"] = 3, ["Fedsel Coronet"] = 0, ["Fedsel E-Line Cargo"] = 0,
    ["Fedsel Expedition"] = 1, ["Fedsel Expedition Hybrid"] = 2, ["Fedsel ST"] = 4, ["Fedsel Stallion G3"] = 1,
    ["Fedsel Stallion G5"] = 2, ["Hakusho Ciri"] = 0, ["Hakusho Concord"] = 1, ["Hakusho MRB Sport"] = 3,
    ["Ivar Manguster"] = 0, ["Konsegga Artero"] = 4, ["Ladammi Devil"] = 4, ["Ladammi Valor"] = 4,
    ["Land Ranger V500"] = 2, ["Lilia Exima"] = 3, ["Luxius BG600"] = 3, ["Luxius FFA"] = 4,
    ["Luxius OJ100"] = 1, ["Luxius VQ"] = 2, ["Marcalen-Denz  A500"] = 4, ["Marcalen-Denz  K413"] = 2,
    ["Marcalen-Denz  OS92 DBZ"] = 4, ["Marcalen-Denz  VT"] = 3, ["Marcalen-Denz B660"] = 1, ["Marcalen-Denz LPS"] = 3,
    ["Marcalen-Denz LPS94"] = 3, ["Marcalen-Denz M24"] = 4, ["Marcalen-Denz T600"] = 1, ["Mazuta 29"] = 1,
    ["Mazuta JO4"] = 2, ["Mazuta Mint"] = 1, ["Medallia 84F"] = 4, ["Medallia B44"] = 4, ["Mitta Aydens REO"] = 2,
    ["MoLesennen 270N"] = 4, ["Nikken 290S"] = 2, ["Nikken Altimata"] = 0, ["Nikken Sinata B21"] = 2,
    ["Nikken Starline S340"] = 3, ["Nikken Starline S350"] = 3, ["Preischel 311 SR3 GTK"] = 4, ["Preischel 313n"] = 3,
    ["Preischel Crayele"] = 1, ["Quantum H26"] = 1, ["Quantum N500"] = 2, ["Suiba Presse RST"] = 2,
    ["Susuri Vitality"] = 0, ["Tokina Absoluta SR 2.0"] = 3, ["Tokina Absoluta SR 3.0"] = 2, ["Tokina Karma"] = 1,
    ["Tokina RP60"] = 1, ["Volfsen Passo"] = 0, ["Volfsen Rolf"] = 0,
}

local AREAS = {
    { name = "East Suburbs", getPath = function() return workspace.FastTravel.Folder["East Suburbs"].Part end },
    { name = "North Suburbs", getPath = function() return workspace.FastTravel.Folder["North Suburbs"].Part end },
    { name = "West Suburbs", getPath = function() return workspace.FastTravel.Folder["West Suburbs"].Part end },
    { name = "Auction", getPath = function() return workspace.FastTravel.Locations.Auction.Part end },
    { name = "Junkyard", getPath = function() return workspace.FastTravel.Locations.Junkyard.Part end },
    { name = "Port", getPath = function() return workspace.FastTravel.Locations.Port.Part end },
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "🚗 Car Flipper 🚗",
    LoadingTitle = "🚗 Car Flipper 🚗",
    LoadingSubtitle = "by BinaryDevelopment",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local QuickTab = Window:CreateTab("⚡ Quick")
local CarsTab = Window:CreateTab("🚘 Active Cars")
local BuyTab = Window:CreateTab("💰 Auto Buy")
local FarmTab = Window:CreateTab("🏭 Auto Farm")
local SettingsTab = Window:CreateTab("🔧 Settings")

local quickStatus = QuickTab:CreateParagraph({Title = "Status Panel", Content = "Idle"})
local buyStatus = BuyTab:CreateParagraph({Title = "Scanner Status", Content = "Scanning inactive."})
local farmStatus = FarmTab:CreateParagraph({Title = "Automation Engine", Content = "Status: Idle"})

local function isValidCar(name)
    local cars = ReplicatedStorage:FindFirstChild("Cars")
    return cars and cars:FindFirstChild(name) ~= nil
end

local function getCarRarity(name)
    if carRarityCache[name] ~= nil then return carRarityCache[name] end
    return 0
end

local function teleportToArea(area)
    local ok, part = pcall(area.getPath)
    if not ok or not part then return false end
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.05)
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
        task.wait(0.1)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    return false
end

local function safeTeleport(hrp, position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.05)
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
    task.wait(0.1)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.6)
end

local function forceOpenGarage()
    local garageBtn = localPlayer.PlayerGui:FindFirstChild("RuntimeGui")
    if not garageBtn then return end
    local sidebar = garageBtn:FindFirstChild("SideBar")
    if not sidebar then return end
    local btn = sidebar:FindFirstChild("Garage")
    if not btn then return end

    local pos  = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local cx = pos.X + size.X / 2
    local cy = pos.Y + size.Y / 2 + INSET_Y

    mousemoveabs(cx, cy - 20)
    task.wait(0.08)
    mousemoveabs(cx, cy + 6)
    task.wait(0.08)
    mouse1click()
    task.wait(1.2)
end

local function forceCloseGarage()
    local garageBtn = localPlayer.PlayerGui:FindFirstChild("RuntimeGui")
    if not garageBtn then return end
    local sidebar = garageBtn:FindFirstChild("SideBar")
    if not sidebar then return end
    local btn = sidebar:FindFirstChild("Garage")
    if not btn then return end

    local pos  = btn.AbsolutePosition
    local size = btn.AbsoluteSize
    local cx = pos.X + size.X / 2
    local cy = pos.Y + size.Y / 2 + INSET_Y

    mousemoveabs(cx, cy - 20)
    task.wait(0.08)
    mousemoveabs(cx, cy + 6)
    task.wait(0.08)
    mouse1click()
    task.wait(1.2)
end

local function findNewestCarIndex()
    local rg = localPlayer.PlayerGui:FindFirstChild("RuntimeGui")
    if not rg then return nil end
    local garageGui = rg:FindFirstChild("Guis") and rg.Guis:FindFirstChild("Garage")
    if not garageGui then return nil end
    local carList = garageGui:FindFirstChild("MainFrame")
        and garageGui.MainFrame:FindFirstChild("GridFrame")
        and garageGui.MainFrame.GridFrame:FindFirstChild("GridFrame")
        and garageGui.MainFrame.GridFrame.GridFrame:FindFirstChild("CarList")
    if not carList then return nil end

    local highestIndex = nil
    for _, child in pairs(carList:GetChildren()) do
        if child:IsA("Frame") and child.Visible then
            local num = tonumber(child.Name)
            if num then
                if not highestIndex or num > highestIndex then
                    highestIndex = num
                end
            end
        end
    end
    return highestIndex and tostring(highestIndex) or nil
end

local function collectResources()
    isCollecting = true
    local character = localPlayer.Character
    if not (character and character:FindFirstChild("HumanoidRootPart")) then
        isCollecting = false
        return
    end

    local hrp = character.HumanoidRootPart

    local ok1, cashBox = pcall(function() return workspace.PlayerBases[playerBaseId].CashBox.Box end)
    if ok1 and cashBox then
        farmStatus:Set({Title = "Automation Engine", Content = "Status: Teleporting to Cash Collection..."})
        safeTeleport(hrp, cashBox.Position)
        local ok2, cashPrompt = pcall(function() return workspace.PlayerBases[playerBaseId].CashBox.Box.CollectPrompt end)
        if ok2 and cashPrompt and cashPrompt:IsA("ProximityPrompt") then
            fireproximityprompt(cashPrompt)
            task.wait(0.8)
        end
    end

    local ok3, partsBox = pcall(function() return workspace.PlayerBases[playerBaseId].ResourceBox.Box end)
    if ok3 and partsBox then
        farmStatus:Set({Title = "Automation Engine", Content = "Status: Teleporting to Resource Collection..."})
        safeTeleport(hrp, partsBox.Position)
        local ok4, partsPrompt = pcall(function() return workspace.PlayerBases[playerBaseId].ResourceBox.Box.CollectPrompt end)
        if ok4 and partsPrompt and partsPrompt:IsA("ProximityPrompt") then
            fireproximityprompt(partsPrompt)
            task.wait(0.8)
        end
    end

    collectNextTime = os.clock() + collectInterval
    isCollecting = false
end

local function doDeliveries()
    isDelivering = true
    local character = localPlayer.Character
    if not (character and character:FindFirstChild("HumanoidRootPart")) then
        isDelivering = false
        return
    end

    local hrp = character.HumanoidRootPart
    local activeInteractables = workspace:FindFirstChild("ActiveInteractables")
    if not activeInteractables then
        isDelivering = false
        return
    end

    local items = activeInteractables:GetChildren()
    if #items == 0 then
        isDelivering = false
        return
    end

    local ok, base = pcall(function() return workspace.PlayerBases[playerBaseId] end)
    local basePos = (ok and base and base.PrimaryPart) and base.PrimaryPart.Position or nil
    local itemsDelivered = 0

    for _, item in ipairs(items) do
        if not deliveryRunning or not running then break end
        if isProcessing or isCollecting then break end
        
        local targetPart = (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart", true)
        if not targetPart then continue end

        farmStatus:Set({Title = "Automation Engine", Content = "Status: Picking up delivery piece: " .. item.Name})
        safeTeleport(hrp, targetPart.Position)
        task.wait(0.3)

        local prompt = item:FindFirstChild("JunkPrompt", true)
        task.wait(0.25)

        if prompt and prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
            task.wait(1.0)
        end

        itemsDelivered = itemsDelivered + 1

        if basePos then
            farmStatus:Set({Title = "Automation Engine", Content = "Status: Dropping off delivery at Base Zone..."})
            safeTeleport(hrp, basePos)
            task.wait(0.8)
        end
    end
    isDelivering = false
end

task.spawn(function()
    while running do
        if deliveryRunning then
            while (isProcessing or isCollecting) and deliveryRunning do task.wait(0.5) end
            if not deliveryRunning then break end
            doDeliveries()
            local cooldownEnd = os.clock() + DELIVERY_COOLDOWN
            while deliveryRunning and os.clock() < cooldownEnd do task.wait(1) end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while running do
        if collectRunning then
            local now = os.clock()
            if collectNextTime <= now then
                while isProcessing and collectRunning do task.wait(0.5) end
                if not collectRunning then break end
                collectResources()
            end
        end
        task.wait(1)
    end
end)

local function doBuySequence(obj, statusObject)
    local prompt = obj:FindFirstChild("MerchantPrompt", true)
    if not prompt then return false end

    local merchantZone = prompt:GetAttribute("MerchantZone")
    local merchantId   = prompt:GetAttribute("MerchantId")
    if not merchantZone or not merchantId then return false end

    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local part = (obj:IsA("Model") and obj.PrimaryPart) or obj:FindFirstChildWhichIsA("BasePart", true)
        if part then safeTeleport(character.HumanoidRootPart, part.Position) end
    end

    statusObject:Set({Title = "Processing", Content = "Buying: " .. obj.Name .. " [" .. merchantZone .. "]"})
    BuyCar:FireServer(merchantZone, merchantId)
    task.wait(2)

    statusObject:Set({Title = "Processing", Content = "Opening Garage Client..."})
    forceOpenGarage()
    return true
end

local function processFarmCar(obj)
    local rarity = getCarRarity(obj.Name)
    if not farmSelectedRarities[rarity] then return false end
    if isProcessing or isCollecting or isDelivering then return false end

    isProcessing = true
    local success = doBuySequence(obj, farmStatus)
    if not success then
        isProcessing = false
        return false
    end

    local carIndex = nil
    for attempt = 1, 10 do
        carIndex = findNewestCarIndex()
        if carIndex then break end
        task.wait(0.5)
    end
    carIndex = carIndex or "16"

    farmStatus:Set({Title = "Processing", Content = "Closing Garage Client Asset..."})
    forceCloseGarage()
    task.wait(0.5)

    farmStatus:Set({Title = "Processing", Content = "Repairing Core Car Index [" .. carIndex .. "]"})
    local attempt = 0
    while farmRunning and attempt < 15 do
        attempt = attempt + 1
        FixCar:FireServer(carIndex)
        task.wait(0.6)
    end
    task.wait(0.5)

    farmStatus:Set({Title = "Processing", Content = "Selling Finalized Car Module..."})
    SellCar:FireServer(carIndex)
    task.wait(1)

    isProcessing = false
    return true
end

QuickTab:CreateInput({
    Name = "Target Car Configuration",
    PlaceholderText = "Enter Vehicle Identity Name",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text) currentCarName = Text end
})

QuickTab:CreateToggle({
    Name = "Toggle Target Interaction Execution",
    CurrentValue = false,
    Callback = function(Value)
        isToggled = Value
        quickStatus:Set({Title = "Status Panel", Content = isToggled and "Active target run starting..." or "Idle"})
        if isToggled then
            task.spawn(function()
                while isToggled and running do
                    local activeMerchants = workspace:FindFirstChild("ActiveMerchants")
                    if activeMerchants then
                        for _, merchant in ipairs(activeMerchants:GetChildren()) do
                            if merchant:IsA("Folder") then
                                local target = merchant:FindFirstChild(currentCarName)
                                if target and target:IsA("Model") then
                                    doBuySequence(target, quickStatus)
                                    isToggled = false
                                    break
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

local currentCarMap = {}
local CarDropdown = CarsTab:CreateDropdown({
    Name = "Nearby Active Merchant Vehicles",
    Options = {"Click Refresh Below"},
    CurrentOption = {"Click Refresh Below"},
    MultipleOptions = false,
    Callback = function(Option)
        local chosenObj = currentCarMap[Option[1]]
        if chosenObj and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPart = chosenObj.PrimaryPart or chosenObj:FindFirstChildWhichIsA("BasePart", true)
            if targetPart then
                safeTeleport(localPlayer.Character.HumanoidRootPart, targetPart.Position)
            end
        end
    end
})

CarsTab:CreateButton({
    Name = "Scan & Refresh Network Vehicles",
    Callback = function()
        local activeMerchants = workspace:FindFirstChild("ActiveMerchants")
        local newOptions = {}
        table.clear(currentCarMap)
        if activeMerchants then
            for _, folder in ipairs(activeMerchants:GetChildren()) do
                if folder:IsA("Folder") then
                    for _, obj in ipairs(folder:GetChildren()) do
                        if obj:IsA("Model") and isValidCar(obj.Name) then
                            local keyName = obj.Name .. " (Rarity: " .. getCarRarity(obj.Name) .. ")"
                            table.insert(newOptions, keyName)
                            currentCarMap[keyName] = obj
                        end
                    end
                end
            end
        end
        if #newOptions == 0 then table.insert(newOptions, "No Vehicles Currently Open") end
        CarDropdown:Refresh(newOptions, true)
    end
})

BuyTab:CreateToggle({
    Name = "Enable Auto Buy Processing Loop",
    CurrentValue = false,
    Callback = function(Value)
        flipRunning = Value
        if flipRunning then
            task.spawn(function()
                while flipRunning and running do
                    if not isProcessing and not isCollecting and not isDelivering then
                        buyStatus:Set({Title = "Scanner Status", Content = "Scanning Active Merchant Inventories..."})
                        local activeMerchants = workspace:FindFirstChild("ActiveMerchants")
                        if activeMerchants then
                            for _, folder in ipairs(activeMerchants:GetChildren()) do
                                for _, obj in ipairs(folder:GetChildren()) do
                                    if obj:IsA("Model") and isValidCar(obj.Name) and flipSelectedRarities[getCarRarity(obj.Name)] then
                                        local prompt = obj:FindFirstChild("MerchantPrompt", true)
                                        local zone = prompt and prompt:GetAttribute("MerchantZone")
                                        local id = prompt and prompt:GetAttribute("MerchantId")
                                        if zone and id then
                                            isProcessing = true
                                            if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                                                if part then safeTeleport(localPlayer.Character.HumanoidRootPart, part.Position) end
                                            end
                                            BuyCar:FireServer(zone, id)
                                            task.wait(1.5)
                                            isProcessing = false
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(2)
                end
                buyStatus:Set({Title = "Scanner Status", Content = "Scanning inactive."})
            end)
        end
    end
})

BuyTab:CreateToggle({
    Name = "Enable Area Rotation Network",
    CurrentValue = false,
    Callback = function(Value)
        areaRotateRunning = Value
        if areaRotateRunning then
            task.spawn(function()
                currentAreaIndex = 1
                while areaRotateRunning and running do
                    local area = AREAS[currentAreaIndex]
                    buyStatus:Set({Title = "Scanner Status", Content = "Rotating Zone to: " .. area.name})
                    teleportToArea(area)
                    task.wait(3.5)
                    currentAreaIndex = (currentAreaIndex % #AREAS) + 1
                end
            end)
        end
    end
})

BuyTab:CreateSection("Auto Buy Target Filters")
for i = 0, 4 do
    BuyTab:CreateToggle({
        Name = RARITY_INFO[i].name .. " Rarity Tier",
        CurrentValue = flipSelectedRarities[i],
        Callback = function(Value) flipSelectedRarities[i] = Value end
    })
end

FarmTab:CreateToggle({
    Name = "Activate Full Cycle Auto Farm Loop",
    CurrentValue = false,
    Callback = function(Value)
        farmRunning = Value
        if farmRunning then
            task.spawn(function()
                while farmRunning and running do
                    local activeMerchants = workspace:FindFirstChild("ActiveMerchants")
                    local located = false
                    if activeMerchants then
                        for _, folder in ipairs(activeMerchants:GetChildren()) do
                            for _, obj in ipairs(folder:GetChildren()) do
                                if obj:IsA("Model") and isValidCar(obj.Name) then
                                    if processFarmCar(obj) then located = true end
                                end
                            end
                        end
                    end
                    if not located then
                        farmStatus:Set({Title = "Automation Engine", Content = "Scanning active instances for matching rarity targets..."})
                    end
                    task.wait(2)
                end
                farmStatus:Set({Title = "Automation Engine", Content = "Status: Idle"})
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Enable Farm Area Rotation Grid",
    CurrentValue = false,
    Callback = function(Value)
        farmAreaRotateRunning = Value
        if farmAreaRotateRunning then
            task.spawn(function()
                farmAreaIndex = 1
                while farmAreaRotateRunning and running do
                    local area = AREAS[farmAreaIndex]
                    farmStatus:Set({Title = "Automation Engine", Content = "Farming Teleporting Node: " .. area.name})
                    teleportToArea(area)
                    task.wait(4)
                    farmAreaIndex = (farmAreaIndex % #AREAS) + 1
                end
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Auto Collect Base Vault Containers",
    CurrentValue = false,
    Callback = function(Value)
        collectRunning = Value
        if collectRunning then collectNextTime = os.clock() end
    end
})

FarmTab:CreateToggle({
    Name = "Auto Collect Junk Delivery Nodes",
    CurrentValue = false,
    Callback = function(Value) deliveryRunning = Value end
})

FarmTab:CreateSection("Auto Farm Target Filters")
for i = 0, 4 do
    FarmTab:CreateToggle({
        Name = RARITY_INFO[i].name .. " Rarity Tier",
        CurrentValue = farmSelectedRarities[i],
        Callback = function(Value) farmSelectedRarities[i] = Value end
    })
end

SettingsTab:CreateButton({
    Name = "Completely Unload Execution Pipeline",
    Callback = function()
        running = false
        flipRunning = false
        areaRotateRunning = false
        farmRunning = false
        farmAreaRotateRunning = false
        collectRunning = false
        deliveryRunning = false
        afkConnection:Disconnect()
        Rayfield:Destroy()
    end
end)
