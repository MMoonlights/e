local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ChestEvent = ReplicatedStorage:WaitForChild("Event").Backpack.ChestRemoteEvent
local BackpackEvent = ReplicatedStorage.Event.Backpack.BackpackRemoteEvent
local BackpackFunction = ReplicatedStorage.Event.Backpack.BackpackRemoteFunction

local player = Players.LocalPlayer
local currentChestId = nil
local collectedItems = {}
local isProcessingChest = false
local chestsOpened = 0
local itemsCollected = 0

local function collectAllItems(chestId, items)
    if not items or isProcessingChest then return end
    
    isProcessingChest = true
    print("Сундук открыт! Начинаем сбор. ID: " .. chestId)
    print("Найдено предметов: " .. #items)
    
    for index, item in ipairs(items) do
        print("Забираем предмет " .. index .. "/" .. #items .. ": " .. item.name)
        
        local success, result = pcall(function()
            return BackpackFunction:InvokeServer(
                "TakeChestItem",
                chestId,
                item.id,
                "MyBackpackInventory"
            )
        end)
        
        if success then
            itemsCollected = itemsCollected + 1
            print("Успешно забрано: " .. item.name)
        else
            print("Ошибка при взятии " .. item.name .. ": " .. tostring(result))
        end
        
        task.wait(0.05)
    end
    
    print("Закрываем сундук...")
    task.wait(0.2)
    
    local closeSuccess, closeResult = pcall(function()
        return BackpackFunction:InvokeServer("CloseChest")
    end)
    
    if closeSuccess then
        chestsOpened = chestsOpened + 1
        print("Сундук закрыт. Всего открыто: " .. chestsOpened)
        currentChestId = nil
    else
        print("Ошибка закрытия: " .. tostring(closeResult))
    end
    
    task.wait(0.5)
    isProcessingChest = false
    print("Готово к поиску следующего сундука!")
end


for _, Connection in getconnections(ChestEvent.OnClientEvent) do
    local old = hookfunction(Connection.Function, function(...)
        local args = {...}
        local eventType = args[1]
        local eventData = args[2]
        
        if eventType == "OpenChest" and eventData then
            currentChestId = eventData.chestId
            task.spawn(function()
                collectAllItems(eventData.chestId, eventData.items)
            end)
        end
        
        return old(...)
    end)
end

local function findChest()
    local closestChest = nil
    local closestDist = math.huge
    local closestPrompt = nil
    
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
            local isChestByName = string.find(object.Name:lower(), "chest")
            
            if isChestByName or prompt then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - object:GetPivot().Position).Magnitude
                    
                    if distance < closestDist then
                        closestDist = distance
                        closestChest = object
                        closestPrompt = prompt
                    end
                end
            end
        end
    end
    
    return closestChest, closestPrompt, closestDist
end

local function mainFarmLoop()
    print("Запуск автофарма сундуков...")
    
    while true do
        if not isProcessingChest then
            local chestObject, prompt, dist = findChest()
            
            if chestObject then
                print("Найден сундук! Дистанция: " .. math.floor(dist))
                local character = player.Character
                
                if character and character:FindFirstChild("HumanoidRootPart") then

                    character.HumanoidRootPart.CFrame = chestObject:GetPivot() * CFrame.new(0, 3, 0)
                    task.wait(0.5)
                    
                    if prompt then
                        print("Нажимаем ProximityPrompt...")
                        fireproximityprompt(prompt)
                    end
                    
                    local timeout = 0
                    while not isProcessingChest and timeout < 2 do
                        task.wait(0.1)
                        timeout += 0.1
                    end
                    
                    if not isProcessingChest then
                        print("Не удалось открыть сундук (нет реакции сервера). Ищем другой...")
                        task.wait(0.5)
                    end
                end
            else
                print("Сундуков поблизости не найдено...")
            end
        end
        
        task.wait(0.5)
    end
end

-- Запуск
mainFarmLoop()
