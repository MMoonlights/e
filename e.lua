-- Anti-AFK
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Anti Staff
spawn(function()
    while wait(5) do
        for i, v in pairs(game.Players:GetPlayers()) do
            if v:GetRankInGroup(11987919) > 149 then
                game.Players.LocalPlayer:Kick("Staff detected: " .. v.Name)
            end
        end
    end
end)

-- Simple UI Library
local Library = {}
local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = title
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 35)
    MainFrame.Position = UDim2.new(0.5, -125, 0, 100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 6)
    UICorner.Parent = MainFrame
    
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local UICorner2 = Instance.new("UICorner")
    UICorner2.CornerRadius = UDim.new(0, 6)
    UICorner2.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0.05, 0, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = title
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 14
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Position = UDim2.new(0.85, 0, 0, 2)
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.TextSize = 20
    MinimizeButton.Parent = TitleBar
    
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 0, 300)
    ContentFrame.Position = UDim2.new(0, 0, 0, 35)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    
    local UICorner3 = Instance.new("UICorner")
    UICorner3.CornerRadius = UDim.new(0, 6)
    UICorner3.Parent = ContentFrame
    
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(0.95, 0, 0.9, 0)
    ScrollingFrame.Position = UDim2.new(0.025, 0, 0.05, 0)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.ScrollBarThickness = 4
    ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.Parent = ContentFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = ScrollingFrame
    
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local minimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            ContentFrame.Visible = false
            MainFrame.Size = UDim2.new(0, 250, 0, 35)
            MinimizeButton.Text = "+"
        else
            ContentFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 250, 0, 335)
            MinimizeButton.Text = "-"
        end
    end)
    
    -- Dragging
    local dragging = false
    local dragInput, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    local WindowFunctions = {}
    
    function WindowFunctions:AddToggle(name, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 32)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Parent = ScrollingFrame
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 4)
        UICorner.Parent = ToggleFrame
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        ToggleLabel.Position = UDim2.new(0.05, 0, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = name
        ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextSize = 12
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ToggleFrame
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0, 36, 0, 18)
        ToggleButton.Position = UDim2.new(0.82, 0, 0, 7)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        ToggleButton.BorderSizePixel = 0
        ToggleButton.Text = ""
        ToggleButton.AutoButtonColor = false
        ToggleButton.Parent = ToggleFrame
        
        local ToggleIndicator = Instance.new("Frame")
        ToggleIndicator.Size = UDim2.new(0, 14, 0, 14)
        ToggleIndicator.Position = UDim2.new(0, 2, 0, 2)
        ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleIndicator.BorderSizePixel = 0
        ToggleIndicator.Parent = ToggleButton
        
        local UICorner2 = Instance.new("UICorner")
        UICorner2.CornerRadius = UDim.new(1, 0)
        UICorner2.Parent = ToggleIndicator
        
        local UICorner3 = Instance.new("UICorner")
        UICorner3.CornerRadius = UDim.new(1, 0)
        UICorner3.Parent = ToggleButton
        
        local enabled = false
        
        ToggleButton.MouseButton1Click:Connect(function()
            enabled = not enabled
            if enabled then
                TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 180, 0)}):Play()
                TweenService:Create(ToggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 20, 0, 2)}):Play()
            else
                TweenService:Create(ToggleButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                TweenService:Create(ToggleIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0, 2)}):Play()
            end
            callback(enabled)
        end)
    end
    
    function WindowFunctions:AddButton(name, callback)
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Size = UDim2.new(1, 0, 0, 32)
        ButtonFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ButtonFrame.BorderSizePixel = 0
        ButtonFrame.Parent = ScrollingFrame
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 4)
        UICorner.Parent = ButtonFrame
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0.9, 0, 0.75, 0)
        Button.Position = UDim2.new(0.05, 0, 0.125, 0)
        Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Button.BorderSizePixel = 0
        Button.Text = name
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.Gotham
        Button.TextSize = 12
        Button.AutoButtonColor = false
        Button.Parent = ButtonFrame
        
        local UICorner2 = Instance.new("UICorner")
        UICorner2.CornerRadius = UDim.new(0, 4)
        UICorner2.Parent = Button
        
        Button.MouseEnter:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 70)}):Play()
        end)
        
        Button.MouseLeave:Connect(function()
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
        end)
        
        Button.MouseButton1Click:Connect(function()
            spawn(callback)
        end)
    end
    
    function WindowFunctions:AddLabel(text)
        local LabelFrame = Instance.new("Frame")
        LabelFrame.Size = UDim2.new(1, 0, 0, 25)
        LabelFrame.BackgroundTransparency = 1
        LabelFrame.BorderSizePixel = 0
        LabelFrame.Parent = ScrollingFrame
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.9, 0, 1, 0)
        Label.Position = UDim2.new(0.05, 0, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(180, 180, 180)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 11
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = LabelFrame
    end
    
    return WindowFunctions
end

-- Create Windows
local MainWindow = Library:CreateWindow("Taxi Boss")
local TeleportWindow = Library:CreateWindow("Teleports")

-- ============================================
-- MAIN FUNCTIONS
-- ============================================

MainWindow:AddLabel("Auto Farming")

MainWindow:AddToggle("Auto Collect Snow Piles", function(state)
    getgenv().autoCollect = state
    spawn(function()
        while getgenv().autoCollect do
            task.wait()
            pcall(function()
                local car = nil
                for i, v in pairs(workspace.Vehicles:GetChildren()) do
                    if v:GetAttribute("owner") == Player.UserId then
                        car = v
                        break
                    end
                end
                if car and car.PrimaryPart then
                    for i, v in pairs(workspace.SpawnedSnowPiles:GetChildren()) do
                        firetouchinterest(car.PrimaryPart, v, 0)
                        firetouchinterest(car.PrimaryPart, v, 1)
                    end
                end
            end)
        end
    end)
end)

MainWindow:AddToggle("Auto Open Winter Presents", function(state)
    getgenv().openWinter = state
    spawn(function()
        while getgenv().openWinter do
            local Event = game:GetService("ReplicatedStorage").Christmas.OpenPresent
            Event:InvokeServer("winter")
            task.wait(0.2)
        end
    end)
end)

MainWindow:AddToggle("Auto Open Aurora Presents", function(state)
    getgenv().openAurora = state
    spawn(function()
        while getgenv().openAurora do
            local Event = game:GetService("ReplicatedStorage").Christmas.OpenPresent
            Event:InvokeServer("aurora")
            task.wait(0.2)
        end
    end)
end)

MainWindow:AddToggle("Auto Collect Parts", function(state)
    getgenv().partCollector = state
    spawn(function()
        while getgenv().partCollector do
            task.wait()
            for a, b in pairs(workspace.ItemSpawnLocations:GetChildren()) do
                if not getgenv().partCollector then break end
                local timer = tick()
                repeat
                    task.wait()
                    Player.Character:PivotTo(b.CFrame + Vector3.new(0, 251, 0))
                until tick() - timer >= 2
                for i, v in pairs(workspace.ItemSpawnLocations:GetDescendants()) do
                    if v.Name == "TouchInterest" then
                        firetouchinterest(Player.Character.HumanoidRootPart, v.Parent, 0)
                        firetouchinterest(Player.Character.HumanoidRootPart, v.Parent, 1)
                    end
                end
            end
        end
    end)
end)

MainWindow:AddToggle("Auto Money", function(state)
    getgenv().autoMoney = state
    spawn(function()
        pcall(function()
            game:GetService("ReplicatedStorage").Quests.Contracts.CancelContract:InvokeServer(Player.ActiveQuests:FindFirstChildOfClass("StringValue").Name)
        end)
        while getgenv().autoMoney do
            wait()
            pcall(function()
                if not Player.ActiveQuests:FindFirstChild("contractBuildMaterial") then
                    game:GetService("ReplicatedStorage").Quests.Contracts.StartContract:InvokeServer("contractBuildMaterial")
                    repeat task.wait() until Player.ActiveQuests:FindFirstChild("contractBuildMaterial")
                end
                repeat
                    task.wait()
                    spawn(function()
                        game:GetService("ReplicatedStorage").Quests.DeliveryComplete:InvokeServer("contractMaterial")
                    end)
                until Player.ActiveQuests.contractBuildMaterial.Value == "!pw5pi3ps2"
                wait()
                game:GetService("ReplicatedStorage").Quests.Contracts.CompleteContract:InvokeServer()
            end)
        end
    end)
end)

MainWindow:AddToggle("Auto Trophies", function(state)
    getgenv().autoTrophies = state
    spawn(function()
        game:GetService("ReplicatedStorage").Race.LeaveRace:InvokeServer()
        while getgenv().autoTrophies do
            task.wait()
            pcall(function()
                if Player.Character and Player.Character.Humanoid.Sit then
                    if Player.variables.race.Value == "none" then
                        task.wait()
                        game:GetService("ReplicatedStorage").Race.TimeTrial:InvokeServer("circuit", 5)
                    else
                        for a, b in pairs(workspace.Vehicles:GetDescendants()) do
                            if b.Name == "Player" and b.Value == Player then
                                for i, v in pairs(workspace.Races["circuit"].detects:GetChildren()) do
                                    if v.ClassName == "Part" and v:FindFirstChild("TouchInterest") then
                                        v.CFrame = Player.Character.HumanoidRootPart.CFrame
                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 0)
                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 1)
                                    end
                                end
                                local finishObj = workspace.Races["circuit"].timeTrial:FindFirstChildOfClass("IntValue")
                                if finishObj then
                                    finishObj.finish.CFrame = Player.Character.HumanoidRootPart.CFrame
                                    firetouchinterest(b.Parent.Parent.PrimaryPart, finishObj.finish, 0)
                                    firetouchinterest(b.Parent.Parent.PrimaryPart, finishObj.finish, 1)
                                end
                            end
                        end
                    end
                else
                    game:GetService("ReplicatedStorage").Vehicles.GetNearestSpot:InvokeServer(Player.variables.carId.Value)
                    wait(0.5)
                    game:GetService("ReplicatedStorage").Vehicles.EnterVehicleEvent:InvokeServer()
                end
            end)
        end
    end)
end)

MainWindow:AddToggle("Auto TimeTrial Medals", function(state)
    getgenv().autoMedals = state
    spawn(function()
        game:GetService("ReplicatedStorage").Race.LeaveRace:InvokeServer()
        while getgenv().autoMedals do
            task.wait()
            pcall(function()
                if Player.Character and Player.Character.Humanoid.Sit then
                    for round = 1, 3 do
                        for raceName, races in pairs(workspace.Races:GetChildren()) do
                            if races.ClassName == "Folder" and getgenv().autoMedals then
                                game:GetService("ReplicatedStorage").Race.TimeTrial:InvokeServer(raceName, round)
                                wait()
                                if Player.variables.race.Value == "none" then
                                    task.wait()
                                    game:GetService("ReplicatedStorage").Race.TimeTrial:InvokeServer(raceName, round)
                                else
                                    for a, b in pairs(workspace.Vehicles:GetDescendants()) do
                                        if b.Name == "Player" and b.Value == Player then
                                            repeat wait()
                                                for i, v in pairs(workspace.Races[raceName].detects:GetChildren()) do
                                                    if v.ClassName == "Part" and v:FindFirstChild("TouchInterest") then
                                                        v.CFrame = Player.Character.HumanoidRootPart.CFrame
                                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 0)
                                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 1)
                                                    end
                                                end
                                            until workspace.Races[raceName].timeTrial:FindFirstChildOfClass("IntValue") or not getgenv().autoMedals
                                            repeat wait()
                                                for i, v in pairs(workspace.Races[raceName].detects:GetChildren()) do
                                                    if v.ClassName == "Part" and v:FindFirstChild("TouchInterest") then
                                                        v.CFrame = Player.Character.HumanoidRootPart.CFrame
                                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 0)
                                                        firetouchinterest(b.Parent.Parent.PrimaryPart, v, 1)
                                                    end
                                                end
                                                pcall(function()
                                                    local finishObj = workspace.Races[raceName].timeTrial:FindFirstChildOfClass("IntValue")
                                                    finishObj.finish.CFrame = Player.Character.HumanoidRootPart.CFrame
                                                    firetouchinterest(b.Parent.Parent.PrimaryPart, finishObj.finish, 0)
                                                    firetouchinterest(b.Parent.Parent.PrimaryPart, finishObj.finish, 1)
                                                end)
                                            until Player.variables.race.Value == "none" or not getgenv().autoMedals
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    game:GetService("ReplicatedStorage").Vehicles.GetNearestSpot:InvokeServer(Player.variables.carId.Value)
                    wait(0.5)
                    game:GetService("ReplicatedStorage").Vehicles.EnterVehicleEvent:InvokeServer()
                end
            end)
        end
    end)
end)

MainWindow:AddToggle("Auto Upgrade Office", function(state)
    getgenv().autoOffice = state
    spawn(function()
        while getgenv().autoOffice do
            wait()
            pcall(function()
                if not Player:FindFirstChild("Office") then
                    game:GetService("ReplicatedStorage").Company.StartOffice:InvokeServer()
                    wait(0.2)
                end
                if Player.Office:GetAttribute("level") < 16 then
                    game:GetService("ReplicatedStorage").Company.SkipOfficeQuest:InvokeServer()
                    game:GetService("ReplicatedStorage").Company.UpgradeOffice:InvokeServer()
                end
            end)
        end
    end)
end)

MainWindow:AddLabel("Miscellaneous")

MainWindow:AddButton("Unlock Taxi Radar", function()
    Player.variables.vip.Value = true
end)

MainWindow:AddButton("Reset Character", function()
    if Player.Character then
        Player.Character:BreakJoints()
    end
end)

MainWindow:AddButton("Remove AI Vehicles", function()
    pcall(function()
        workspace.Tracks:Destroy()
    end)
end)

MainWindow:AddButton("Remove Locked Barriers", function()
    pcall(function()
        workspace.AreaLocked:Destroy()
    end)
end)

MainWindow:AddToggle("Donut God", function(state)
    getgenv().donutGod = state
    spawn(function()
        while getgenv().donutGod do
            task.wait()
            pcall(function()
                local part = Player.Character.Humanoid.SeatPart
                part.RotVelocity = Vector3.new(0, part.RotVelocity.Y + 10, 0)
            end)
        end
    end)
end)

-- ============================================
-- TELEPORT SYSTEM
-- ============================================

TeleportWindow:AddLabel("Beach & Coastal")

local function teleport(pos)
    local chr = Player.Character
    if not chr then return end
    local hum = chr:FindFirstChild("Humanoid")
    if not hum then return end
    
    if hum.SeatPart then
        hum.SeatPart.Parent.Parent:PivotTo(CFrame.new(pos) + Vector3.new(0, 40, 0))
    else
        chr:PivotTo(CFrame.new(pos) + Vector3.new(0, 30, 0))
    end
end

local teleportLocations = {
    ["Beechwood"] = function() teleport(game:GetService("ReplicatedStorage").Places.Beechwood.Position) end,
    ["Beechwood Beach"] = function() teleport(game:GetService("ReplicatedStorage").Places["Beechwood Beach"].Position) end,
    ["Ocean Viewpoint"] = function() teleport(game:GetService("ReplicatedStorage").Places["Ocean Viewpoint"].Position) end,
    ["the beach"] = function() teleport(game:GetService("ReplicatedStorage").Places["the beach"].Position) end,
}

for name, tpFunc in pairs(teleportLocations) do
    TeleportWindow:AddButton(name, tpFunc)
end

TeleportWindow:AddLabel("City & Urban")

local cityLocations = {
    ["Bridgeview"] = function() teleport(Vector3.new(1354.46, 10.3, 1278.8)) end,
    ["Cedar Side"] = function() teleport(game:GetService("ReplicatedStorage").Places["Cedar Side"].Position) end,
    ["Central Bank"] = function() teleport(game:GetService("ReplicatedStorage").Places["Central Bank"].Position) end,
    ["Central City"] = function() teleport(game:GetService("ReplicatedStorage").Places["Central City"].Position) end,
    ["City Park"] = function() teleport(game:GetService("ReplicatedStorage").Places["City Park"].Position) end,
    ["Coconut Park"] = function() teleport(game:GetService("ReplicatedStorage").Places["Coconut Park"].Position) end,
    ["Country Club"] = function() teleport(game:GetService("ReplicatedStorage").Places["Country Club"].Position) end,
    ["Da Hills"] = function() teleport(Vector3.new(2348.35, 73.11, -1537.32)) end,
    ["Doge Harbor"] = function() teleport(Vector3.new(3335.74, 24.96, 2773.04)) end,
    ["Harborview"] = function() teleport(game:GetService("ReplicatedStorage").Places["Harborview"].Position) end,
    ["Hawthorn Park"] = function() teleport(game:GetService("ReplicatedStorage").Places["Hawthorn Park"].Position) end,
    ["Hospital"] = function() teleport(game:GetService("ReplicatedStorage").Places["Hospital"].Position) end,
    ["Master Hotel"] = function() teleport(Vector3.new(2736.16, 15.86, -202.1)) end,
    ["Old Town"] = function() teleport(game:GetService("ReplicatedStorage").Places["Old Town"].Position) end,
    ["Popular Street"] = function() teleport(game:GetService("ReplicatedStorage").Places["Popular Street"].Position) end,
    ["Small Town"] = function() teleport(game:GetService("ReplicatedStorage").Places["Small Town"].Position) end,
    ["Sunny Elementary"] = function() teleport(game:GetService("ReplicatedStorage").Places["Sunny Elementary"].Position) end,
    ["Sunset Grove"] = function() teleport(game:GetService("ReplicatedStorage").Places["Sunset Grove"].Position) end,
    ["Taxi Central"] = function() teleport(game:GetService("ReplicatedStorage").Places["Taxi Central"].Position) end,
    ["high school"] = function() teleport(game:GetService("ReplicatedStorage").Places["high school"].Position) end,
    ["mall"] = function() teleport(game:GetService("ReplicatedStorage").Places["mall"].Position) end,
}

for name, tpFunc in pairs(cityLocations) do
    TeleportWindow:AddButton(name, tpFunc)
end

TeleportWindow:AddLabel("Industrial & Other")

local industrialLocations = {
    ["Industrial District"] = function() teleport(game:GetService("ReplicatedStorage").Places["Industrial District"].Position) end,
    ["Logistic District"] = function() teleport(Vector3.new(588.29, 53.58, 2529.95)) end,
    ["Military Base"] = function() teleport(game:GetService("ReplicatedStorage").Places["Military Base"].Position) end,
    ["Noll Cliffs"] = function() teleport(game:GetService("ReplicatedStorage").Places["Noll Cliffs"].Position) end,
    ["Nuclear Power Plant"] = function() teleport(game:GetService("ReplicatedStorage").Places["Nuclear Power Plant"].Position) end,
    ["Oil Refinery"] = function() teleport(game:GetService("ReplicatedStorage").Places["Oil Refinery"].Position) end,
    ["St. Noll Viewpoint"] = function() teleport(game:GetService("ReplicatedStorage").Places["St. Noll Viewpoint"].Position) end,
    ["Race Club"] = function() teleport(game:GetService("ReplicatedStorage").Places["🏎 Race Club"].Position) end,
    ["Gas Station"] = function() teleport(Vector3.new(103.7, 0, -640.6)) end,
    ["Gas Station 2"] = function() teleport(Vector3.new(930.7, 0, 643.4)) end,
    ["Boss Airport"] = function() teleport(Vector3.new(-637.13, 39, 4325.23)) end,
}

for name, tpFunc in pairs(industrialLocations) do
    TeleportWindow:AddButton(name, tpFunc)
end

print("Taxi Boss script loaded successfully!")
