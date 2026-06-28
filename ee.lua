local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local localPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

local flipSelectedRarities = { [0] = false, [1] = false, [2] = true, [3] = false, [4] = false, [5] = false }
local flipRunning = false

local farmSelectedRarities = { [0] = false, [1] = false, [2] = true, [3] = false, [4] = false, [5] = false }
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
    [5] = { name = "Mythical" },
}

local carRarityCache = {
    ["Acadi RVS Sedan"] = 0, ["Artho F9 RT"] = 4, ["Artho F9 ST"] = 3, ["Artho G1000"] = 0,
    ["Artho G451"] = 1, ["Artho G623"] = 2, ["Artho G672"] = 1, ["Artho G770"] = 3,
    ["Artho VS600"] = 3, ["Artho X723"] = 1, ["Bantt Rental"] = 0, ["Beressa Char"] = 5,
    ["Beressa Verona"] = 5,
    ["Bogdan 2099"] = 0, ["Chiverleta Cerano"] = 1, ["Chiverleta Cerano XZ2"] = 3,
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
    ["Ivar Manguster"] = 0, ["Konsegga Artero"] = 5,
    ["Ladammi Devil"] = 4, ["Ladammi Valor"] = 4,
    ["Land Ranger V500"] = 2, ["Lilia Exima"] = 3, ["Luxius BG600"] = 3, ["Luxius FFA"] = 4,
    ["Luxius OJ100"] = 1, ["Luxius VQ"] = 2, ["Marcalen-Denz  A500"] = 4, ["Marcalen-Denz  K413"] = 2,
    ["Marcalen-Denz  OS92 DBZ"] = 4, ["Marcalen-Denz  VT"] = 3, ["Marcalen-Denz B660"] = 1, ["Marcalen-Denz LPS"] = 3,
    ["Marcalen-Denz LPS94"] = 3, ["Marcalen-Denz M24"] = 4, ["Marcalen-Denz T600"] = 1, ["Mazuta 29"] = 1,
    ["Mazuta JO4"] = 2, ["Mazuta Mint"] = 1, ["Medallia 84F"] = 4, ["Medallia B44"] = 5,
    ["Mitta Aydens REO"] = 2, ["MoLesennen 270N"] = 4,
    ["Nikken 290S"] = 2, ["Nikken Altimata"] = 0, ["Nikken Sinata B21"] = 2,
    ["Nikken Starline S340"] = 3, ["Nikken Starline S350"] = 3, ["Preischel 311 SR3 GTK"] = 4,
    ["Preischel 313n"] = 3, ["Preischel Crayele"] = 1, ["Quantum H26"] = 1, ["Quantum N500"] = 2,
    ["Suiba Presse RST"] = 2, ["Susuri Vitality"] = 0, ["Tokina Absoluta SR 2.0"] = 3,
    ["Tokina Absoluta SR 3.0"] = 2, ["Tokina Karma"] = 1, ["Tokina RP60"] = 1, ["Volfsen Passo"] = 0,
    ["Volfsen Rolf"] = 0,
}

local AREAS = {
    { name = "East Suburbs", getPath = function() return workspace.FastTravel.Folder["East Suburbs"].Part end },
    { name = "North Suburbs", getPath = function() return workspace.FastTravel.Folder["North Suburbs"].Part end },
    { name = "West Suburbs", getPath = function() return workspace.FastTravel.Folder["West Suburbs"].Part end },
    { name = "Auction", getPath = function() return workspace.FastTravel.Locations.Auction.Part end },
    { name = "Junkyard", getPath = function() return workspace.FastTravel.Locations.Junkyard.Part end },
    { name = "Port", getPath = function() return workspace.FastTravel.Locations.Port.Part end },
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CarFlipperUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 10)
TitleFix.Position = UDim2.new(0, 0, 1, -10)
TitleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 10, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🚗 Car Flipper"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.TextSize = 16
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TitleBar
local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(0, 120, 1, -35)
TabFrame.Position = UDim2.new(0, 0, 0, 35)
TabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TabFrame.BorderSizePixel = 0
TabFrame.Parent = MainFrame

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 0)
TabCorner.Parent = TabFrame

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 2)
TabList.Parent = TabFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, -120, 1, -35)
ContentFrame.Position = UDim2.new(0, 120, 0, 35)
ContentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local UI = {}
local Tabs = {}
local CurrentTab = nil

function UI:CreateTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 35)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.TextSize = 13
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.Parent = TabFrame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = tabBtn

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, -10, 1, -10)
    tabContent.Position = UDim2.new(0, 5, 0, 5)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 4
    tabContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
    tabContent.Visible = false
    tabContent.Parent = ContentFrame
    tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 5)
    contentList.Parent = tabContent

    local tab = {
        Name = name,
        Button = tabBtn,
        Content = tabContent,
        Elements = {}
    }

    tabBtn.MouseButton1Click:Connect(function()
        if CurrentTab then
            CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            CurrentTab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
            CurrentTab.Content.Visible = false
        end
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Content.Visible = true
        CurrentTab = tab
    end)

    table.insert(Tabs, tab)
    if #Tabs == 1 then
        tabBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tab.Content.Visible = true
        CurrentTab = tab
    end

    function tab:CreateLabel(text)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 25)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(180, 180, 200)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = tabContent
        return label
    end

    function tab:CreateButton(data)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
        btn.Text = data.Name or "Button"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.Parent = tabContent
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            pcall(data.Callback)
        end)
        return btn
    end

    function tab:CreateToggle(data)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 32)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        frame.BorderSizePixel = 0
        frame.Parent = tabContent
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = data.Name or "Toggle"
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 40, 0, 20)
        toggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        toggleBtn.Text = ""
        toggleBtn.Parent = frame
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggleBtn

        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, 16, 0, 16)
        circle.Position = UDim2.new(0, 2, 0.5, -8)
        circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        circle.Parent = toggleBtn
        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = circle

        local enabled = data.CurrentValue or false
        local function updateToggle()
            if enabled then
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
                circle.Position = UDim2.new(1, -18, 0.5, -8)
            else
                toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                circle.Position = UDim2.new(0, 2, 0.5, -8)
            end
            pcall(data.Callback, enabled)
        end

        toggleBtn.MouseButton1Click:Connect(function()
            enabled = not enabled
            updateToggle()
        end)

        if enabled then updateToggle() end
        return {Value = function() return enabled end, Set = function(v) enabled = v; updateToggle() end}
    end

    function tab:CreateInput(data)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        frame.BorderSizePixel = 0
        frame.Parent = tabContent
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 2)
        label.BackgroundTransparency = 1
        label.Text = data.Name or "Input"
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -20, 0, 22)
        textBox.Position = UDim2.new(0, 10, 0, 24)
        textBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        textBox.Text = data.PlaceholderText or ""
        textBox.PlaceholderText = data.PlaceholderText or "Enter text..."
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
        textBox.TextSize = 12
        textBox.Font = Enum.Font.Gotham
        textBox.ClearTextOnFocus = false
        textBox.Parent = frame
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = textBox

        textBox.FocusLost:Connect(function()
            pcall(data.Callback, textBox.Text)
        end)

        return textBox
    end

    function tab:CreateDropdown(data)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        frame.BorderSizePixel = 0
        frame.Parent = tabContent
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.6, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = data.Name or "Dropdown"
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local dropdownBtn = Instance.new("TextButton")
        dropdownBtn.Size = UDim2.new(0.35, -5, 0, 25)
        dropdownBtn.Position = UDim2.new(0.65, 0, 0.5, -12)
        dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
        dropdownBtn.Text = "Select"
        dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownBtn.TextSize = 11
        dropdownBtn.Font = Enum.Font.Gotham
        dropdownBtn.Parent = frame
        local ddCorner = Instance.new("UICorner")
        ddCorner.CornerRadius = UDim.new(0, 4)
        ddCorner.Parent = dropdownBtn

        local dropdown = {
            Options = data.Options or {},
            Selected = data.CurrentOption and data.CurrentOption[1] or nil,
            Refresh = function(self, newOptions, selectFirst)
                self.Options = newOptions or {}
                if selectFirst and #self.Options > 0 then
                    self.Selected = self.Options[1]
                    dropdownBtn.Text = tostring(self.Selected):sub(1, 15)
                end
            end
        }

        dropdownBtn.MouseButton1Click:Connect(function()
            local menu = Instance.new("Frame")
            menu.Size = UDim2.new(0, 150, 0, math.min(#dropdown.Options * 25, 150))
            menu.Position = UDim2.new(0, dropdownBtn.AbsolutePosition.X - ContentFrame.AbsolutePosition.X, 0, dropdownBtn.AbsolutePosition.Y - ContentFrame.AbsolutePosition.Y + 30)
            menu.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            menu.BorderSizePixel = 0
            menu.ZIndex = 10
            menu.Parent = ContentFrame
            local menuCorner = Instance.new("UICorner")
            menuCorner.CornerRadius = UDim.new(0, 6)
            menuCorner.Parent = menu

            local menuList = Instance.new("UIListLayout")
            menuList.Parent = menu

            for i, opt in ipairs(dropdown.Options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 25)
                optBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
                optBtn.Text = tostring(opt)
                optBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                optBtn.TextSize = 11
                optBtn.Font = Enum.Font.Gotham
                optBtn.Parent = menu
                optBtn.MouseButton1Click:Connect(function()
                    dropdown.Selected = opt
                    dropdownBtn.Text = tostring(opt):sub(1, 15)
                    pcall(data.Callback, {opt})
                    menu:Destroy()
                end)
            end

            task.delay(3, function()
                if menu and menu.Parent then menu:Destroy() end
            end)
        end)

        return dropdown
    end

    function tab:CreateSection(name)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, 0, 0, 20)
        section.BackgroundTransparency = 1
        section.Text = "━━ " .. (name or "Section") .. " ━━"
        section.TextColor3 = Color3.fromRGB(150, 150, 170)
        section.TextSize = 12
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.Parent = tabContent
        return section
    end

    function tab:CreateParagraph(data)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        frame.BorderSizePixel = 0
        frame.Parent = tabContent
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -10, 0, 18)
        title.Position = UDim2.new(0, 10, 0, 2)
        title.BackgroundTransparency = 1
        title.Text = data.Title or "Status"
        title.TextColor3 = Color3.fromRGB(100, 150, 255)
        title.TextSize = 13
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = frame

        local content = Instance.new("TextLabel")
        content.Size = UDim2.new(1, -10, 0, 20)
        content.Position = UDim2.new(0, 10, 0, 20)
        content.BackgroundTransparency = 1
        content.Text = data.Content or "..."
        content.TextColor3 = Color3.fromRGB(200, 200, 200)
        content.TextSize = 12
        content.Font = Enum.Font.Gotham
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextWrapped = true
        content.Parent = frame

        return {
            Set = function(self, data)
                title.Text = data.Title or title.Text
                content.Text = data.Content or content.Text
            end
        }
    end

    return tab
end

local dragging = false
local dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    running = false
    flipRunning = false
    areaRotateRunning = false
    farmRunning = false
    farmAreaRotateRunning = false
    collectRunning = false
    deliveryRunning = false
    afkConnection:Disconnect()
end)

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    ContentFrame.Visible = not minimized
    TabFrame.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 500, 0, 35) or UDim2.new(0, 500, 0, 350)
end)

local QuickTab = UI:CreateTab("⚡ Quick")
local CarsTab = UI:CreateTab("🚘 Cars")
local BuyTab = UI:CreateTab("💰 Buy")
local FarmTab = UI:CreateTab("🏭 Farm")
local SettingsTab = UI:CreateTab("🔧 Settings")

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

local function safeMouseClick(element)
    if not element then return end
    local pos = element.AbsolutePosition
    local size = element.AbsoluteSize
    local cx = pos.X + size.X / 2
    local cy = pos.Y + size.Y / 2 + INSET_Y
    
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(cx, cy, game)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end)
    task.wait(1.2)
end

local function forceOpenGarage()
    local garageBtn = localPlayer.PlayerGui:FindFirstChild("RuntimeGui")
    if not garageBtn then return end
    local sidebar = garageBtn:FindFirstChild("SideBar")
    if not sidebar then return end
    local btn = sidebar:FindFirstChild("Garage")
    if not btn then return end
    safeMouseClick(btn)
end

local function forceCloseGarage()
    forceOpenGarage()
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
    Name = "Target Car Name",
    PlaceholderText = "Enter Vehicle Name",
    Callback = function(Text) currentCarName = Text end
})

QuickTab:CreateToggle({
    Name = "Auto Buy Target",
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
    Name = "Nearby Cars",
    Options = {"Click Refresh Below"},
    CurrentOption = {"Click Refresh Below"},
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
    Name = "Refresh Car List",
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
        if #newOptions == 0 then table.insert(newOptions, "No Vehicles Found") end
        CarDropdown:Refresh(newOptions, true)
    end
})

BuyTab:CreateToggle({
    Name = "Auto Buy Loop",
    CurrentValue = false,
    Callback = function(Value)
        flipRunning = Value
        if flipRunning then
            task.spawn(function()
                while flipRunning and running do
                    if not isProcessing and not isCollecting and not isDelivering then
                        buyStatus:Set({Title = "Scanner Status", Content = "Scanning Active Merchants..."})
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
    Name = "Area Rotation",
    CurrentValue = false,
    Callback = function(Value)
        areaRotateRunning = Value
        if areaRotateRunning then
            task.spawn(function()
                currentAreaIndex = 1
                while areaRotateRunning and running do
                    local area = AREAS[currentAreaIndex]
                    buyStatus:Set({Title = "Scanner Status", Content = "Rotating to: " .. area.name})
                    teleportToArea(area)
                    task.wait(3.5)
                    currentAreaIndex = (currentAreaIndex % #AREAS) + 1
                end
            end)
        end
    end
})

BuyTab:CreateSection("Rarity Filters")
for i = 0, 5 do
    BuyTab:CreateToggle({
        Name = RARITY_INFO[i].name,
        CurrentValue = flipSelectedRarities[i],
        Callback = function(Value) flipSelectedRarities[i] = Value end
    })
end

FarmTab:CreateToggle({
    Name = "Full Auto Farm",
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
                        farmStatus:Set({Title = "Automation Engine", Content = "Scanning for targets..."})
                    end
                    task.wait(2)
                end
                farmStatus:Set({Title = "Automation Engine", Content = "Status: Idle"})
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Farm Area Rotation",
    CurrentValue = false,
    Callback = function(Value)
        farmAreaRotateRunning = Value
        if farmAreaRotateRunning then
            task.spawn(function()
                farmAreaIndex = 1
                while farmAreaRotateRunning and running do
                    local area = AREAS[farmAreaIndex]
                    farmStatus:Set({Title = "Automation Engine", Content = "Teleporting to: " .. area.name})
                    teleportToArea(area)
                    task.wait(4)
                    farmAreaIndex = (farmAreaIndex % #AREAS) + 1
                end
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Auto Collect Base",
    CurrentValue = false,
    Callback = function(Value)
        collectRunning = Value
        if collectRunning then collectNextTime = os.clock() end
    end
})

FarmTab:CreateToggle({
    Name = "Auto Deliver Junk",
    CurrentValue = false,
    Callback = function(Value) deliveryRunning = Value end
})

FarmTab:CreateSection("Farm Rarity Filters")
for i = 0, 5 do
    FarmTab:CreateToggle({
        Name = RARITY_INFO[i].name,
        CurrentValue = farmSelectedRarities[i],
        Callback = function(Value) farmSelectedRarities[i] = Value end
    })
end

SettingsTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        running = false
        flipRunning = false
        areaRotateRunning = false
        farmRunning = false
        farmAreaRotateRunning = false
        collectRunning = false
        deliveryRunning = false
        afkConnection:Disconnect()
        ScreenGui:Destroy()
    end
})

local notif = Instance.new("TextLabel")
notif.Size = UDim2.new(0, 300, 0, 40)
notif.Position = UDim2.new(0.5, -150, 0, -50)
notif.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
notif.Text = "✅ Car Flipper Loaded Successfully!"
notif.TextColor3 = Color3.fromRGB(255, 255, 255)
notif.TextSize = 14
notif.Font = Enum.Font.GothamBold
notif.Parent = ScreenGui
local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notif

TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, 20)}):Play()
task.delay(3, function()
    TweenService:Create(notif, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -150, 0, -50)}):Play()
    task.wait(0.5)
    notif:Destroy()
end)
