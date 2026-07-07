local ChestEvent = game:GetService("ReplicatedStorage").Event.Backpack.ChestRemoteEvent
local BackpackEvent = game:GetService("ReplicatedStorage").Event.Backpack.BackpackRemoteEvent
local BackpackFunction = game:GetService("ReplicatedStorage").Event.Backpack.BackpackRemoteFunction

local currentChestId = nil
local collectedItems = {}
local isProcessingChest = false
local chestsOpened = 0
local itemsCollected = 0

local function collectAllItems(chestId, items)
    if not items or isProcessingChest then return end
    
    isProcessingChest = true
    print("Starting collection from chest: " .. chestId)
    print("Items found: " .. #items)
    
    for index, item in ipairs(items) do
        print("Collecting item " .. index .. "/" .. #items .. ": " .. item.name)
        print("Item details - ID: " .. item.id .. ", Rare: " .. item.rare .. ", Coin: " .. item.coin)
        
        local success, result = pcall(function()
            return BackpackFunction:InvokeServer(
                "TakeChestItem",
                chestId,
                item.id,
                "MyBackpackInventory"
            )
        end)
        
        if success then
            collectedItems[item.id] = {
                name = item.name,
                coin = item.coin,
                rare = item.rare,
                collected = true
            }
            itemsCollected = itemsCollected + 1
            print("Successfully collected: " .. item.name)
            print("Total items collected: " .. itemsCollected)
        else
            print("Failed to collect " .. item.name .. ": " .. tostring(result))
        end
        
        task.wait(0.05)
    end
    
    print("All items processed. Closing chest...")
    
    task.wait(0.2)
    local closeSuccess, closeResult = pcall(function()
        return BackpackFunction:InvokeServer("CloseChest")
    end)
    
    if closeSuccess then
        print("Chest closed successfully")
        chestsOpened = chestsOpened + 1
        print("Total chests opened: " .. chestsOpened)
        currentChestId = nil
    else
        print("Failed to close chest: " .. tostring(closeResult))
    end
    
    isProcessingChest = false
    print("Ready for next chest")
end

local function findAndOpenChests()
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            local chestPart = object:FindFirstChild("Chest") or 
                            object:FindFirstChild("chest") or
                            object:FindFirstChildWhichIsA("ProximityPrompt")
            
            if chestPart and not isProcessingChest then
                local player = game.Players.LocalPlayer
                local character = player.Character
                
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - object:GetPivot().Position).Magnitude
                    
                    if distance < 50 then
                        print("Chest found at distance: " .. math.floor(distance))
                        return true
                    end
                end
            end
        end
    end
    return false
end

print("Initializing chest farm hooks...")

for _, Connection in getconnections(ChestEvent.OnClientEvent) do
    local old = hookfunction(Connection.Function, function(...)
        local args = {...}
        local eventType = args[1]
        local eventData = args[2]
        
        print("Chest event received: " .. tostring(eventType))
        
        if eventType == "OpenChest" and eventData then
            currentChestId = eventData.chestId
            print("Chest opened - ID: " .. eventData.chestId .. ", Level: " .. eventData.chestLevel)
            
            task.spawn(function()
                collectAllItems(eventData.chestId, eventData.items)
            end)
        end
        
        return old(...)
    end)
    print("Chest event hook installed")
end

for _, Connection in getconnections(BackpackEvent.OnClientEvent) do
    local old = hookfunction(Connection.Function, function(...)
        local args = {...}
        local eventType = args[1]
        local eventData = args[2]
        
        print("Backpack event received: " .. tostring(eventType))
        
        if eventType == "ItemData" and eventData then
            print("Inventory data received. Items count: " .. #eventData)
            for i, item in ipairs(eventData) do
                print("Inventory item " .. i .. ": " .. item.name .. " (ID: " .. item.id .. ")")
            end
        end
        
        return old(...)
    end)
    print("Backpack event hook installed")
end

print("Starting main farm loop...")
print("Chest auto-farmer is now active")

local function mainFarmLoop()
    while true do
        if not isProcessingChest then
            local chestFound = findAndOpenChests()
            if chestFound then
                print("Approaching chest...")
            end
        else
            print("Currently processing chest: " .. (currentChestId or "Unknown"))
        end
        
        task.wait(0.5)
    end
end

mainFarmLoop()
