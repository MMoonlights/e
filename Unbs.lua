if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

local UI_URL = "https://gist.githubusercontent.com/MjContiga1/7830931c94f8ba912103072abd21df0b/raw/b41e5d567895d11aacc4b419091d29b504c985c6/Bypass.lua"

assert(type(loadstring) == "function", "[Loader] This executor does not support loadstring")

local httpOk, uiSource = pcall(function()
    return game:HttpGet(UI_URL)
end)
assert(httpOk and type(uiSource) == "string" and #uiSource > 0,
    "[Loader] Failed to download UI: " .. tostring(uiSource))

local uiChunk, compileError = loadstring(uiSource)
assert(uiChunk, "[Loader] UI compilation error: " .. tostring(compileError))

local libraryOk, Library = pcall(uiChunk)
assert(libraryOk and type(Library) == "table",
    "[Loader] UI execution error: " .. tostring(Library))

print("[Loader] UI library loaded")

local Window = Library:Window("Unboxing Simulator • By Mjcontegazxc", {UseScreenGui = true})
local MainTab = Window:Tab({"Main", "rbxassetid://7733960981"})
local AchievementsTab = Window:Tab({"Achievements", "rbxassetid://7733673987"})
local RewardTab = Window:Tab({"Reward", "rbxassetid://7733946818"})
local LocalPlayerTab = Window:Tab({"LocalPlayer", "rbxassetid://7743875962"})

local RE = nil
local RF = nil
local BoxController = nil
local BoxesZAP = nil
local ZAPFolder = nil

task.spawn(function()
    while not ReplicatedStorage:FindFirstChild("ZAP") do task.wait(0.5) end
    ZAPFolder = ReplicatedStorage:FindFirstChild("ZAP")

    while not ZAPFolder:FindFirstChild("Boxes_RELIABLE") do task.wait(0.5) end
    BoxesZAP = ZAPFolder:FindFirstChild("Boxes_RELIABLE")

    while not ReplicatedStorage:FindFirstChild("Controllers") do task.wait(0.5) end
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")

    while not controllers:FindFirstChild("BoxController") do task.wait(0.5) end
    local requireOk, controllerOrError = pcall(require, controllers:FindFirstChild("BoxController"))
    if requireOk then
        BoxController = controllerOrError
    else
        warn("[Loader] Failed to load BoxController:", controllerOrError)
    end

    while not ReplicatedStorage:FindFirstChild("RE") do task.wait(0.5) end
    RE = ReplicatedStorage:FindFirstChild("RE")

    while not ReplicatedStorage:FindFirstChild("RF") do task.wait(0.5) end
    RF = ReplicatedStorage:FindFirstChild("RF")

    print("[Success] ZAP, BoxController, RE, and RF loaded successfully!")
end)

MainTab:Label("MAIN STATS", "rbxassetid://7733960981")

local TimeParagraph = MainTab:Paragraph("Current time will appear here")

local StatsParagraph = MainTab:Paragraph("Loading statistics...")

MainTab:Label("Boxes", "rbxassetid://7733752575")

local autoAttackBoxes = false
local attackRange = 50
local attackSpeed = 0.1
local attackedBoxes = {}
local boxDebugLogged = false
local missingIdLogged = false

local bufferWarningShown = false

local function attackBox(fieldId, boxId)
    if not BoxesZAP then return end
    if not fieldId or not boxId then return end

    if type(buffer) ~= "table" or type(buffer.create) ~= "function" then
        if not bufferWarningShown then
            warn("[Boxes] This executor does not support the Luau buffer API")
            bufferWarningShown = true
        end
        return
    end

    fieldId = tonumber(fieldId)
    boxId = tonumber(boxId)
    if not fieldId or not boxId then return end

    local buf = buffer.create(17)

    buffer.writeu8(buf, 0, 0x00)
    buffer.writeu8(buf, 1, 0x04)

    buffer.writeu8(buf, 2, math.floor(fieldId / 16777216) % 256)
    buffer.writeu8(buf, 3, math.floor(fieldId / 65536) % 256)
    buffer.writeu8(buf, 4, math.floor(fieldId / 256) % 256)
    buffer.writeu8(buf, 5, fieldId % 256)

    buffer.writeu8(buf, 6, math.floor(boxId / 16777216) % 256)
    buffer.writeu8(buf, 7, math.floor(boxId / 65536) % 256)
    buffer.writeu8(buf, 8, math.floor(boxId / 256) % 256)
    buffer.writeu8(buf, 9, boxId % 256)

    buffer.writeu8(buf, 10, 0xA4)
    buffer.writeu8(buf, 11, 0x1D)
    buffer.writeu8(buf, 12, 0xC1)
    buffer.writeu8(buf, 13, 0xCD)
    buffer.writeu8(buf, 14, 0x99)
    buffer.writeu8(buf, 15, 0xDA)
    buffer.writeu8(buf, 16, 0x41)

    pcall(function()
        BoxesZAP:FireServer(buf, {})
    end)
end

local getBoxesCallMode = nil

local function getBoxesInRadiusSafe(pos, range)
    if type(BoxController) ~= "table" then
        return false, nil, "BoxController is not a table"
    end

    local getBoxesFunction = BoxController.GetBoxesInRadius
    if type(getBoxesFunction) ~= "function" then
        return false, nil, "GetBoxesInRadius is missing or is not a function"
    end

    if getBoxesCallMode == "method" then
        local ok, result = pcall(getBoxesFunction, BoxController, pos, range)
        if ok then
            return true, result
        end
        getBoxesCallMode = nil
    elseif getBoxesCallMode == "static" then
        local ok, result = pcall(getBoxesFunction, pos, range)
        if ok then
            return true, result
        end
        getBoxesCallMode = nil
    end

    local methodOk, methodResult = pcall(
        getBoxesFunction,
        BoxController,
        pos,
        range
    )

    if methodOk and (methodResult == nil or type(methodResult) == "table") then
        getBoxesCallMode = "method"
        print("[Debug] GetBoxesInRadius works with self")
        return true, methodResult
    end

    local staticOk, staticResult = pcall(
        getBoxesFunction,
        pos,
        range
    )

    if staticOk and (staticResult == nil or type(staticResult) == "table") then
        getBoxesCallMode = "static"
        print("[Debug] GetBoxesInRadius works without self")
        return true, staticResult
    end

    return false, nil,
        "with self: " .. tostring(methodResult)
        .. " | without self: " .. tostring(staticResult)
end

local function attackNearbyBoxes()
    if not autoAttackBoxes or not BoxController then
        return
    end

    local character = LocalPlayer.Character
    local rootPart = character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )

    if not rootPart then
        return
    end

    local pos = rootPart.Position
    local success, boxes, callError = getBoxesInRadiusSafe(pos, attackRange)

    if not success then
        if not missingIdLogged then
            warn("[Debug] GetBoxesInRadius failed:", callError)
            warn("[Debug] The controller may not be initialized yet, or the game API has changed.")
            missingIdLogged = true
        end
        return
    end

    if type(boxes) ~= "table" or next(boxes) == nil then
        return
    end

    for _, box in pairs(boxes) do
        if not boxDebugLogged then
            if type(box) == "table" then
                local keys = ""

                for key, value in pairs(box) do
                    keys = keys
                        .. tostring(key)
                        .. " ("
                        .. typeof(value)
                        .. "), "
                end

                print("[Debug] Box structure:", keys)

                if type(box.Field) == "table" then
                    local fieldKeys = ""

                    for key, value in pairs(box.Field) do
                        fieldKeys = fieldKeys
                            .. tostring(key)
                            .. " ("
                            .. typeof(value)
                            .. "), "
                    end

                    print("[Debug] Box.Field structure:", fieldKeys)
                end
            else
                print("[Debug] Box type:", typeof(box), tostring(box))
            end

            boxDebugLogged = true
        end

        local fieldId = nil
        local boxId = nil
        local boxCFrame = nil

        if type(box) == "table" then
            if type(box.Field) == "table" and box.Field.Id then
                fieldId = box.Field.Id
            elseif box.FieldId then
                fieldId = box.FieldId
            elseif type(box.Field) == "table" and box.Field.FieldId then
                fieldId = box.Field.FieldId
            end

            boxId = box.Id or box.BoxId
            boxCFrame = box.CFrame
        elseif typeof(box) == "Instance" then
            fieldId = box:GetAttribute("FieldId")
                or box:GetAttribute("FieldID")

            boxId = box:GetAttribute("Id")
                or box:GetAttribute("BoxId")

            if box:IsA("BasePart") then
                boxCFrame = box.CFrame
            elseif box:IsA("Model") then
                boxCFrame = box:GetPivot()
            end
        end

        if fieldId and boxId and typeof(boxCFrame) == "CFrame" then
            if (pos - boxCFrame.Position).Magnitude <= attackRange then
                attackBox(fieldId, boxId)
                task.wait(0.05)
            end
        elseif not missingIdLogged then
            warn("[Debug] Field ID, Box ID, or CFrame was not found.")
            missingIdLogged = true
        end
    end
end

MainTab:Toggle("Auto Damage All Boxes", false, function(state)
    autoAttackBoxes = state
    boxDebugLogged = false
    missingIdLogged = false
    if state then
        print("[Debug] Auto Attack Boxes enabled. Searching for boxes...")
        task.spawn(function()
            while autoAttackBoxes do
                attackNearbyBoxes()
                task.wait(attackSpeed)
            end
        end)
    end
end)

MainTab:Slider("Attack Range", 10, 100, 50, function(value)
    attackRange = value
end)

MainTab:Slider("Attack Delay (ms)", 50, 2000, 100, function(value)
    attackSpeed = math.max(value / 1000, 0.05)
end)

MainTab:Label("Weapons", "rbxassetid://7733955511")

local autoBuyWeapons = false

MainTab:Toggle("Auto Buy All Weapons", false, function(state)
    autoBuyWeapons = state
end)

local function buyAllWeapons()
    if not RF then return end
    local purchaseRemote = RF:FindFirstChild("PurchaseItem")
    if not purchaseRemote then return end

    local areas = workspace:FindFirstChild("Areas")
    if not areas then return end

    for _, area in pairs(areas:GetChildren()) do
        local weaponsFolder = area:FindFirstChild("Weapons")
        if weaponsFolder then
            local items = weaponsFolder:FindFirstChild("Items")
            if items then
                for _, item in pairs(items:GetChildren()) do
                    pcall(function()
                        purchaseRemote:InvokeServer(item)
                    end)
                    task.wait(0.5)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if autoBuyWeapons then
            pcall(buyAllWeapons)
        end
    end
end)

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local autoClaimItems = false

MainTab:Toggle("Auto Claim Items", false, function(state)
    autoClaimItems = state
end)

local function findAndClickClaim()
    for _, desc in pairs(PlayerGui:GetDescendants()) do
        if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name):find("claim") then
            if desc.Visible then
                local pos = desc.AbsolutePosition + (desc.AbsoluteSize / 2)
                VirtualUser:Button1Down(Vector2.new(pos.X, pos.Y))
                task.wait(0.05)
                VirtualUser:Button1Up(Vector2.new(pos.X, pos.Y))
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if autoClaimItems then
            pcall(findAndClickClaim)
        end
    end
end)

MainTab:Label("Auto Enchant Hat", "rbxassetid://7733955511")

local autoEnchantHat = false
local enchantDelay = 5

local function enchantHat()
    pcall(function()
        if RE and RE:FindFirstChild("EnchantStationUpgrade") then
            RE.EnchantStationUpgrade:FireServer("Hat")
        end
    end)
end

MainTab:Toggle("Auto Enchant Hat", false, function(state)
    autoEnchantHat = state
end)

MainTab:Slider("Enchant Delay (seconds)", 1, 30, 5, function(value)
    enchantDelay = value
end)

task.spawn(function()
    while true do
        task.wait(enchantDelay)
        if autoEnchantHat then
            task.wait(math.random(3, 8) / 10)
            enchantHat()
            task.wait(math.random(15, 25) / 10)
        end
    end
end)

local EnchantStatus = MainTab:Paragraph("Hat enchant status will appear here...")

MainTab:Button("⚡ Enchant Hat Now", function()
    enchantHat()
end)

AchievementsTab:Label("Achievements", "rbxassetid://7733673987")

local boxAchievements = {
    "OpenBoxes_25", "OpenBoxes_50", "OpenBoxes_100", "OpenBoxes_250", "OpenBoxes_500",
    "OpenBoxes_1000", "OpenBoxes_1500", "OpenBoxes_2500", "OpenBoxes_5000", "OpenBoxes_10000",
    "OpenBoxes_20000", "OpenBoxes_30000", "OpenBoxes_50000", "OpenBoxes_75000", "OpenBoxes_100000",
    "OpenBoxes_135000", "OpenBoxes_175000", "OpenBoxes_250000", "OpenBoxes_500000", "OpenBoxes_1000000",
    "OpenBoxes_2500000", "OpenBoxes_5000000", "OpenBoxes_10000000", "OpenBoxes_25000000",
    "OpenBoxes_50000000", "OpenBoxes_100000000"
}

local hatchAchievements = {
    "Hatch_25", "Hatch_50", "Hatch_100", "Hatch_250", "Hatch_500", "Hatch_1000",
    "Hatch_1500", "Hatch_2500", "Hatch_5000", "Hatch_10000", "Hatch_20000", "Hatch_30000",
    "Hatch_50000", "Hatch_75000", "Hatch_100000", "Hatch_135000", "Hatch_175000", "Hatch_250000",
    "Hatch_500000", "Hatch_1000000", "Hatch_2500000", "Hatch_5000000", "Hatch_10000000",
    "Hatch_25000000", "Hatch_50000000"
}

local autoClaimBoxAch = false
local autoClaimHatchAch = false

AchievementsTab:Toggle("Auto Claim Achievement: Boxes", false, function(state)
    autoClaimBoxAch = state
end)

AchievementsTab:Toggle("Auto Claim Achievement: Hatch", false, function(state)
    autoClaimHatchAch = state
end)

local function claimAchievement(achName)
    pcall(function()
        if RE and RE:FindFirstChild("ClaimAchievement") then
            RE.ClaimAchievement:FireServer(achName)
        end
    end)
end

task.spawn(function()
    while task.wait(1) do
        if autoClaimBoxAch then
            for _, ach in ipairs(boxAchievements) do
                claimAchievement(ach)
                task.wait(0.1)
            end
        end
        if autoClaimHatchAch then
            for _, ach in ipairs(hatchAchievements) do
                claimAchievement(ach)
                task.wait(0.1)
            end
        end
    end
end)

AchievementsTab:Button("🚀 Claim All Achievements Now", function()
    for _, ach in ipairs(boxAchievements) do
        claimAchievement(ach)
        task.wait(0.05)
    end
    for _, ach in ipairs(hatchAchievements) do
        claimAchievement(ach)
        task.wait(0.05)
    end
end)

RewardTab:Label("Claiming Rewards", "rbxassetid://7733946818")

local questRewards = {"Damage", "Tutorial_1", "Tutorial_2", "Tutorial_3", "Tutorial_4", "Tutorial_5", "Tutorial_6", "Tutorial_7", "Tutorial_8", "Tutorial_9", "Tutorial_10", "Tutorial_11", "Tutorial_12"}
local autoClaimQuests = false
local autoClaimPlaytime = false
local autoClaimLogin = false

RewardTab:Toggle("Auto Claim Quest Rewards", false, function(state)
    autoClaimQuests = state
end)

RewardTab:Toggle("Auto Claim Playtime Rewards", false, function(state)
    autoClaimPlaytime = state
end)

RewardTab:Toggle("Auto Claim Login Rewards", false, function(state)
    autoClaimLogin = state
end)

local function claimQuest(questName)
    pcall(function()
        if RE and RE:FindFirstChild("CollectQuest") then
            RE.CollectQuest:FireServer(questName)
        end
    end)
end

local function claimPlaytime(id)
    pcall(function()
        if RE and RE:FindFirstChild("ClaimPlaytimeReward") then
            RE.ClaimPlaytimeReward:FireServer(id)
        end
    end)
end

local function claimLogin()
    pcall(function()
        if RE and RE:FindFirstChild("ClaimLoginReward") then
            RE.ClaimLoginReward:FireServer()
        end
    end)
end

task.spawn(function()
    while task.wait(2) do
        if autoClaimQuests then
            for _, quest in ipairs(questRewards) do
                claimQuest(quest)
                task.wait(0.2)
            end
        end
        if autoClaimPlaytime then
            for i = 1, 12 do
                claimPlaytime(i)
                task.wait(0.2)
            end
        end
        if autoClaimLogin then
            claimLogin()
        end
    end
end)

RewardTab:Button("⚡ Claim All Rewards Now", function()
    for _, quest in ipairs(questRewards) do
        claimQuest(quest)
        task.wait(0.1)
    end
    for i = 1, 12 do
        claimPlaytime(i)
        task.wait(0.1)
    end
    claimLogin()
end)

local RewardStatus = RewardTab:Paragraph("Reward status will appear here...")

LocalPlayerTab:Label("LOCAL PLAYER SETTINGS", "rbxassetid://7743875962")

LocalPlayerTab:Toggle("Anti-AFK", false, function(state)
    if state then
        _G.AFKConnection = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    else
        if _G.AFKConnection then
            _G.AFKConnection:Disconnect()
            _G.AFKConnection = nil
        end
    end
end)

LocalPlayerTab:Slider("Walk Speed", 16, 100, 16, function(value)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = value
    end
end)

LocalPlayerTab:Slider("Jump Power", 50, 200, 50, function(value)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = value
    end
end)

LocalPlayerTab:Toggle("Noclip", false, function(state)
    if state then
        _G.NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if _G.NoclipConnection then
            _G.NoclipConnection:Disconnect()
            _G.NoclipConnection = nil
        end
    end
end)

LocalPlayerTab:Slider("Gravity Delay", 1, 5, 1, function(value)
    workspace.Gravity = 196.2 * value
end)

local function buildStatsText()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return "❌ Leaderstats not found!\nWaiting for the game to load..."
    end

    local stats = "📊 REAL-TIME STATS:\n\n"
    local dmg = leaderstats:FindFirstChild("💥Dmg/s")
    if dmg then stats = stats .. "• 💥 Damage/sec: " .. tostring(dmg.Value) .. "\n" end

    local coins = leaderstats:FindFirstChild("🔷World 1 Coins")
    if coins then stats = stats .. "• 🔷 Coins: " .. tostring(coins.Value) .. "\n" end

    local lvlBonus = leaderstats:FindFirstChild("🎖️Lvl Bonus")
    if lvlBonus then stats = stats .. "• 🎖️ Level bonus: " .. tostring(lvlBonus.Value) .. "\n" end

    local boxes = leaderstats:FindFirstChild("📦Boxes")
    if boxes then stats = stats .. "• 📦 Boxes opened: " .. tostring(boxes.Value) .. "\n" end

    return stats .. "\n⏰ Last update: " .. os.date("%H:%M:%S")
end

local function buildEnchantStatus()
    local status = "✨ AUTO ENCHANT HAT STATUS:\n\n"
    status = status .. "🔮 Auto Enchant: " .. (autoEnchantHat and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "⏰ Enchant Delay: " .. tostring(enchantDelay) .. " sec.\n"
    status = status .. "🎩 Enchant target: Hat\n\n"
    status = status .. "⚠️ Note: This automatically enchants your hat"
    return status
end

local function buildRewardStatus()
    local status = "🎁 AUTO CLAIM STATUS:\n\n"
    status = status .. "📜 Quest Rewards: " .. (autoClaimQuests and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "⏰ Playtime Rewards: " .. (autoClaimPlaytime and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "🔓 Login Rewards: " .. (autoClaimLogin and "✅ ENABLED" or "❌ DISABLED") .. "\n\n"
    status = status .. "⏰ Last Check: " .. os.date("%H:%M:%S")
    return status
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            TimeParagraph:SetText("Current time: " .. os.date("%H:%M:%S"))
            StatsParagraph:SetText(buildStatsText())
            EnchantStatus:SetText(buildEnchantStatus())
            RewardStatus:SetText(buildRewardStatus())
        end)
    end
end)

print("[Success] Unboxing Simulator Script Fully Loaded!")
