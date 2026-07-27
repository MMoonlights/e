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

local RE = ReplicatedStorage:FindFirstChild("RE")
local RF = ReplicatedStorage:FindFirstChild("RF")
local BoxController = nil
local BoxesAPI = nil
local boxAreaState = nil
local fieldList = {}
local fieldsById = {}

local function readUpvalue(target, index)
    local reader = debug and debug.getupvalue or getupvalue

    if type(reader) ~= "function" then
        return nil
    end

    local ok, first, second = pcall(reader, target, index)

    if not ok then
        return nil
    end

    if second ~= nil then
        return second
    end

    return first
end

local function loadFieldList()
    if not BoxesAPI
        or type(BoxesAPI.GetFieldList) ~= "table"
        or type(BoxesAPI.GetFieldList.Call) ~= "function"
    then
        return
    end

    local ok, result = pcall(BoxesAPI.GetFieldList.Call)

    if not ok or type(result) ~= "table" then
        warn("[Loader] Failed to load field list:", result)
        return
    end

    fieldList = result
    fieldsById = {}

    for _, field in pairs(fieldList) do
        if type(field) == "table" and tonumber(field.Id) ~= nil then
            fieldsById[tonumber(field.Id)] = field
        end
    end
end

task.spawn(function()
    local controllers = ReplicatedStorage:WaitForChild("Controllers")
    local boxModule = controllers:WaitForChild("BoxController")
    local boxOk, boxResult = pcall(require, boxModule)

    if boxOk and type(boxResult) == "table" then
        BoxController = boxResult

        if type(BoxController.GetClosestBox) == "function" then
            boxAreaState = readUpvalue(
                BoxController.GetClosestBox,
                1
            )
        end
    else
        warn("[Loader] Failed to load BoxController:", boxResult)
    end

    local modules = ReplicatedStorage:WaitForChild("Modules")
    local remotes = modules:WaitForChild("Remotes")
    local boxesModule = remotes:WaitForChild("Boxes")
    local apiOk, apiResult = pcall(require, boxesModule)

    if apiOk and type(apiResult) == "table" then
        BoxesAPI = apiResult
        loadFieldList()
    else
        warn("[Loader] Failed to load Boxes API:", apiResult)
    end

    if type(boxAreaState) == "table" then
        print("[Success] BoxController state loaded")
    else
        warn("[Loader] BoxController state unavailable")
    end

    if BoxesAPI then
        print("[Success] Boxes API loaded")
    end
end)

MainTab:Label("MAIN STATS", "rbxassetid://7733960981")

local TimeParagraph = MainTab:Paragraph("Current time will appear here")

local StatsParagraph = MainTab:Paragraph("Loading statistics...")

MainTab:Label("Boxes", "rbxassetid://7733752575")

local autoAttackBoxes = false
local attackRange = 27
local attacksPerSecond = 5
local lastStatusAt = 0
local lockedBox = nil
local lockedArea = nil

local function getRootPart()
    local character = LocalPlayer.Character

    return character and (
        character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    )
end

local function isBoxValid(box)
    return type(box) == "table"
        and tonumber(box.Id) ~= nil
        and typeof(box.CFrame) == "CFrame"
        and tonumber(box.Health) ~= nil
        and box.Health > 0
        and not box.IsDestroyed
        and not box.IsOpen
end

local function fieldContainsPosition(field, position)
    if type(field) ~= "table"
        or typeof(field.Position) ~= "Vector3"
        or typeof(field.Size) ~= "Vector3"
    then
        return false
    end

    local delta = position - field.Position
    local halfX = field.Size.X * 0.5 + 3
    local halfY = math.max(field.Size.Y * 0.5, 100)
    local halfZ = field.Size.Z * 0.5 + 3

    return math.abs(delta.X) <= halfX
        and math.abs(delta.Y) <= halfY
        and math.abs(delta.Z) <= halfZ
end

local function resolveFieldId(areaData, box)
    local candidates = {
        areaData and areaData.Id,
        areaData and areaData.FieldId,
        areaData and areaData.fieldId,
        box and box.FieldId,
        box and box.fieldId
    }

    if box and type(box.Field) == "table" then
        table.insert(candidates, box.Field.Id)
        table.insert(candidates, box.Field.FieldId)
    end

    for _, candidate in ipairs(candidates) do
        local fieldId = tonumber(candidate)

        if fieldId ~= nil then
            return fieldId
        end
    end

    if not box or typeof(box.CFrame) ~= "CFrame" then
        return nil
    end

    local position = box.CFrame.Position
    local areaType = areaData and areaData.FieldTypeId
    local bestFieldId = nil
    local bestDistance = math.huge

    for _, field in pairs(fieldList) do
        if type(field) == "table"
            and tonumber(field.Id) ~= nil
            and typeof(field.Position) == "Vector3"
        then
            local typeMatches = areaType == nil
                or field.FieldTypeId == areaType

            if typeMatches and fieldContainsPosition(field, position) then
                return tonumber(field.Id)
            end

            if typeMatches then
                local distance = (
                    position - field.Position
                ).Magnitude

                if distance < bestDistance then
                    bestDistance = distance
                    bestFieldId = tonumber(field.Id)
                end
            end
        end
    end

    return bestFieldId
end

local function getNearestBox()
    local rootPart = getRootPart()

    if not rootPart or type(boxAreaState) ~= "table" then
        return nil, nil, math.huge, 0
    end

    local nearestBox = nil
    local nearestArea = nil
    local nearestDistance = math.huge
    local nearbyCount = 0

    for _, areaData in next, boxAreaState do
        if type(areaData) == "table"
            and type(areaData.Boxes) == "table"
        then
            for _, box in next, areaData.Boxes do
                if isBoxValid(box) then
                    local distance = (
                        rootPart.Position - box.CFrame.Position
                    ).Magnitude

                    if distance <= attackRange then
                        nearbyCount += 1

                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearestBox = box
                            nearestArea = areaData
                        end
                    end
                end
            end
        end
    end

    return nearestBox, nearestArea, nearestDistance, nearbyCount
end

local function getLockedBox()
    local rootPart = getRootPart()

    if not rootPart then
        return nil, nil, math.huge
    end

    if isBoxValid(lockedBox) then
        local distance = (
            rootPart.Position - lockedBox.CFrame.Position
        ).Magnitude

        if distance <= attackRange then
            return lockedBox, lockedArea, distance
        end
    end

    lockedBox = nil
    lockedArea = nil

    local box, areaData, distance = getNearestBox()

    if box then
        lockedBox = box
        lockedArea = areaData
    end

    return lockedBox, lockedArea, distance
end

local function attackNearestBox()
    if not autoAttackBoxes
        or not BoxesAPI
        or type(BoxesAPI.AttackBox) ~= "table"
        or type(BoxesAPI.AttackBox.Fire) ~= "function"
    then
        return
    end

    local box, areaData, distance = getLockedBox()
    local _, _, _, nearbyCount = getNearestBox()

    if box then
        local fieldId = resolveFieldId(areaData, box)

        if fieldId ~= nil then
            local ok, result = pcall(
                BoxesAPI.AttackBox.Fire,
                fieldId,
                tonumber(box.Id),
                workspace:GetServerTimeNow()
            )

            if not ok then
                warn("[Boxes] Attack failed:", result)
                lockedBox = nil
                lockedArea = nil
            end
        else
            warn("[Boxes] Could not resolve field ID")
            lockedBox = nil
            lockedArea = nil
        end
    end

    if os.clock() - lastStatusAt >= 2 then
        lastStatusAt = os.clock()

        print(
            "[Boxes] Nearby",
            nearbyCount,
            "target",
            box and box.Id or "none",
            "distance",
            box and string.format("%.1f", distance) or "-"
        )
    end
end

MainTab:Toggle("Auto Damage Nearby Boxes", false, function(state)
    autoAttackBoxes = state
    lockedBox = nil
    lockedArea = nil

    if state then
        task.spawn(function()
            while autoAttackBoxes do
                attackNearestBox()
                task.wait(1 / attacksPerSecond)
            end
        end)
    end
end)

MainTab:Slider("Attack Range", 10, 28, 27, function(value)
    attackRange = math.clamp(value, 10, 28)
end)

MainTab:Slider("Attacks Per Second", 1, 7, 5, function(value)
    attacksPerSecond = math.clamp(
        math.floor(value),
        1,
        7
    )
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
