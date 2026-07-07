local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ChestEvent = ReplicatedStorage:WaitForChild("Event").Backpack.ChestRemoteEvent
local BackpackEvent = ReplicatedStorage.Event.Backpack.BackpackRemoteEvent
local BackpackFunction = ReplicatedStorage.Event.Backpack.BackpackRemoteFunction

local player = Players.LocalPlayer
local currentChestId = nil
local isProcessingChest = false
local chestsOpened = 0
local itemsCollected = 0

local function collectAllItems(chestId, items)
    if not items or isProcessingChest then return end
    
    isProcessingChest = true
    print("Chest opened. Starting collection. ID: " .. tostring(chestId))
    print("Items found: " .. #items)
    
    for index, item in ipairs(items) do
        print("Collecting item " .. index .. "/" .. #items .. ": " .. tostring(item.name))
        
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
            print("Successfully collected: " .. tostring(item.name))
        else
            print("Failed to collect " .. tostring(item.name) .. ": " .. tostring(result))
        end
        
        task.wait(0.1)
    end
    
    print("Closing chest...")
    task.wait(0.2)
    
    local closeSuccess, closeResult = pcall(function()
        return BackpackFunction:InvokeServer("CloseChest")
    end)
    
    if closeSuccess then
        chestsOpened = chestsOpened + 1
        print("Chest closed. Total opened: " .. chestsOpened)
        currentChestId = nil
    else
        print("Failed to close chest: " .. tostring(closeResult))
    end
    
    task.wait(0.5)
    isProcessingChest = false
    print("Ready for next chest")
end

for _, Connection in pairs(getconnections(ChestEvent.OnClientEvent)) do
    if Connection.Function then
        local old = hookfunction(Connection.Function, function(...)
            local args = {...}
            local eventType = args[1]
            local eventData = args[2]
            
            if eventType == "OpenChest" and eventData then
                currentChestId = eventData.chestId
                task.spawn(function()
                    local s, e = pcall(collectAllItems, eventData.chestId, eventData.items)
                    if not s then
                        print("Collection error: " .. tostring(e))
                        isProcessingChest = false
                    end
                end)
            end
            
            return old(...)
        end)
    end
end

local function findChest()
    local closestChest = nil
    local closestDist = math.huge
    local closestPrompt = nil
    
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Model") or object:IsA("BasePart") then
            local lowerName = string.lower(object.Name)
            if string.find(lowerName, "chest") then
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - object:GetPivot().Position).Magnitude
                    
                    if distance < closestDist then
                        closestDist = distance
                        closestChest = object
                        closestPrompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    end
                end
            end
        end
    end
    
    return closestChest, closestPrompt, closestDist
end

task.spawn(function()
    print("Starting auto farm...")
    
    while true do
        pcall(function()
            if not isProcessingChest then
                local chestObject, prompt, dist = findChest()
                
                if chestObject then
                    print("Chest found. Distance: " .. math.floor(dist))
                    local character = player.Character
                    
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.CFrame = chestObject:GetPivot() * CFrame.new(0, 3, 0)
                        task.wait(0.5)
                        
                        if prompt then
                            print("Activating prompt...")
                            if fireproximityprompt then
                                pcall(fireproximityprompt, prompt)
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
                            print("Failed to open chest. Searching for another...")
                        end
                    end
                end
            end
        end)
        
        task.wait(0.5)
    end
end)
