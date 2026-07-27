-- [[ Сервисы ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")

-- [[ Байпасы (Anti-Kick & Anti-Detect UI) ]]
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    if self == LocalPlayer and getnamecallmethod() == "Kick" then
        return nil
    end
    return oldNamecall(self, ...)
end)

local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldIndex = mt.__index
mt.__index = function(self, key)
    if self == CoreGui and key == "AdvancedUI" then
        return nil
    end
    return oldIndex(self, key)
end
setreadonly(mt, true)

-- [[ Загрузка UI Библиотеки ]]
local Library = loadstring(game:HttpGet("https://gist.githubusercontent.com/MjContiga1/7830931c94f8ba912103072abd21df0b/raw/b41e5d567895d11aacc4b419091d29b504c985c6/Bypass.lua"))()

local Window = Library:Window("Unboxing Simulator • By Mjcontegazxc", {UseScreenGui = true})
local MainTab = Window:Tab({"Main", "rbxassetid://7733960981"})
local AchievementsTab = Window:Tab({"Achievements", "rbxassetid://7733673987"})
local RewardTab = Window:Tab({"Reward", "rbxassetid://7733946818"})
local LocalPlayerTab = Window:Tab({"LocalPlayer", "rbxassetid://7743875962"})

-- ==========================================
-- БЕЗОПАСНАЯ ФОНОВАЯ ЗАГРУЗКА (БЕЗ WaitForChild)
-- ==========================================
local RE = nil
local RF = nil
local BoxController = nil
local BoxesZAP = nil

task.spawn(function()
    -- Безопасный поиск ZAP
    while not ReplicatedStorage:FindFirstChild("ZAP") do task.wait(0.5) end
    local zapFolder = ReplicatedStorage:FindFirstChild("ZAP")
    
    while not zapFolder:FindFirstChild("Boxes_RELIABLE") do task.wait(0.5) end
    BoxesZAP = zapFolder:FindFirstChild("Boxes_RELIABLE")
    
    -- Безопасный поиск Controllers
    while not ReplicatedStorage:FindFirstChild("Controllers") do task.wait(0.5) end
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    
    while not controllers:FindFirstChild("BoxController") do task.wait(0.5) end
    BoxController = require(controllers:FindFirstChild("BoxController"))
    
    -- Фоновый поиск RE и RF (не блокируют скрипт)
    while not ReplicatedStorage:FindFirstChild("RE") do task.wait(0.5) end
    RE = ReplicatedStorage:FindFirstChild("RE")
    
    while not ReplicatedStorage:FindFirstChild("RF") do task.wait(0.5) end
    RF = ReplicatedStorage:FindFirstChild("RF")
    
    print("[Success] ZAP, BoxController, RE и RF успешно загружены в фоновом режиме!")
end)

-- ==========================================
-- MAIN TAB
-- ==========================================
MainTab:Label("MAIN STATS", "rbxassetid://7733960981")

local TimeParagraph = MainTab:Paragraph("Текущее время появится здесь")
TimeParagraph:SetUpdateFunction(function()
    return "Текущее время: " .. os.date("%H:%M:%S")
end)

local StatsParagraph = MainTab:Paragraph("Загрузка статистики...")
StatsParagraph:SetUpdateFunction(function()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then
        return "❌ Leaderstats не найдены!\nОжидайте загрузки игры..."
    end
    
    local stats = "📊 REAL-TIME STATS:\n\n"
    local dmg = leaderstats:FindFirstChild("💥Dmg/s")
    if dmg then stats = stats .. "• 💥 Урон/Сек: " .. tostring(dmg.Value) .. "\n" end
    
    local coins = leaderstats:FindFirstChild("🔷World 1 Coins")
    if coins then stats = stats .. "• 🔷 Монеты: " .. tostring(coins.Value) .. "\n" end
    
    local lvlBonus = leaderstats:FindFirstChild("🎖️Lvl Bonus")
    if lvlBonus then stats = stats .. "• 🎖️ Бонус уровня: " .. tostring(lvlBonus.Value) .. "\n" end
    
    local boxes = leaderstats:FindFirstChild("📦Boxes")
    if boxes then stats = stats .. "• 📦 Открыто боксов: " .. tostring(boxes.Value) .. "\n" end
    
    return stats .. "\n⏰ Последнее обновление: " .. os.date("%H:%M:%S")
end)

MainTab:Label("Boxes", "rbxassetid://7733752575")

-- ИСПРАВЛЕННАЯ Логика авто-атаки боксов через ZAP буфер (Event 4)
local autoAttackBoxes = false
local attackRange = 50
local attackSpeed = 0.1
local attackedBoxes = {}

local function attackBox(fieldId, boxId)
    if not BoxesZAP then return end
    if not fieldId or not boxId then return end
    
    fieldId = tonumber(fieldId)
    boxId = tonumber(boxId)
    if not fieldId or not boxId then return end
    
    -- Создаем буфер на 17 байт (как в дампах)
    local buf = buffer.create(17)
    
    -- Заголовок: \x00\x04 (Event 4 = Update/Damage)
    buffer.writeu8(buf, 0, 0x00)
    buffer.writeu8(buf, 1, 0x04)
    
    -- Записываем Field ID (4 байта, Big Endian)
    buffer.writeu8(buf, 2, math.floor(fieldId / 16777216) % 256)
    buffer.writeu8(buf, 3, math.floor(fieldId / 65536) % 256)
    buffer.writeu8(buf, 4, math.floor(fieldId / 256) % 256)
    buffer.writeu8(buf, 5, fieldId % 256)
    
    -- Записываем Box ID (4 байта, Big Endian)
    buffer.writeu8(buf, 6, math.floor(boxId / 16777216) % 256)
    buffer.writeu8(buf, 7, math.floor(boxId / 65536) % 256)
    buffer.writeu8(buf, 8, math.floor(boxId / 256) % 256)
    buffer.writeu8(buf, 9, boxId % 256)
    
    -- Статичный хвост (7 байт из вашего дампа)
    buffer.writeu8(buf, 10, 0xA4)
    buffer.writeu8(buf, 11, 0x1D)
    buffer.writeu8(buf, 12, 0xC1)
    buffer.writeu8(buf, 13, 0xCD)
    buffer.writeu8(buf, 14, 0x99)
    buffer.writeu8(buf, 15, 0xDA)
    buffer.writeu8(buf, 16, 0x41)
    
    -- Отправляем на сервер
    pcall(function()
        BoxesZAP:FireServer(buf, {})
    end)
    
    attackedBoxes[tostring(boxId)] = os.clock()
end

local function attackNearbyBoxes()
    if not autoAttackBoxes or not BoxController then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    
    local pos = LocalPlayer.Character.PrimaryPart.Position
    
    -- Очистка старых записей
    for id, timeAtk in pairs(attackedBoxes) do
        if os.clock() - timeAtk > 3 then
            attackedBoxes[id] = nil
        end
    end
    
    local success, boxes = pcall(function()
        return BoxController.GetBoxesInRadius(pos, attackRange)
    end)
    
    if not success or not boxes then return end
    
    for _, box in ipairs(boxes) do
        if box and box.Id and box.Field and box.Field.Id and not attackedBoxes[tostring(box.Id)] then
            if (pos - box.CFrame.Position).Magnitude <= attackRange then
                attackBox(box.Field.Id, box.Id)
                task.wait(0.05)
            end
        end
    end
end

MainTab:Toggle("Auto Damage All Boxes", false, function(state)
    autoAttackBoxes = state
    if state then
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

MainTab:Slider("Attack Speed", 0.05, 2, 0.1, function(value)
    attackSpeed = value
end)

task.spawn(function()
    while true do
        attackedBoxes = {}
        task.wait(5)
    end
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

-- Авто-забор предметов
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

local EnchantStatus = MainTab:Paragraph("Статус зачарования шляпы появится здесь...")
EnchantStatus:SetUpdateFunction(function()
    local status = "✨ AUTO ENCHANT HAT STATUS:\n\n"
    status = status .. "🔮 Auto Enchant: " .. (autoEnchantHat and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "⏰ Enchant Delay: " .. enchantDelay .. " сек.\n"
    status = status .. "🎩 Зачарование: Hat\n\n"
    status = status .. "⚠️ Примечание: Это автоматически зачаровывает вашу шляпу"
    return status
end)

MainTab:Button("⚡ Enchant Hat Now", function()
    enchantHat()
end)

-- ==========================================
-- ACHIEVEMENTS TAB
-- ==========================================
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

-- ==========================================
-- REWARD TAB
-- ==========================================
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

local RewardStatus = RewardTab:Paragraph("Статус наград появится здесь...")
RewardStatus:SetUpdateFunction(function()
    local status = "🎁 AUTO CLAIM STATUS:\n\n"
    status = status .. "📜 Quest Rewards: " .. (autoClaimQuests and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "⏰ Playtime Rewards: " .. (autoClaimPlaytime and "✅ ENABLED" or "❌ DISABLED") .. "\n"
    status = status .. "🔓 Login Rewards: " .. (autoClaimLogin and "✅ ENABLED" or "❌ DISABLED") .. "\n\n"
    status = status .. "⏰ Last Check: " .. os.date("%H:%M:%S")
    return status
end)

-- ==========================================
-- LOCAL PLAYER TAB
-- ==========================================
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

print("[Success] Unboxing Simulator Script Fully Loaded!")
