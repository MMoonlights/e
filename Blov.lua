local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ChestEvent = ReplicatedStorage:WaitForChild("Event").Backpack.ChestRemoteEvent
local BackpackFunction = ReplicatedStorage.Event.Backpack.BackpackRemoteFunction

local player = Players.LocalPlayer
local isProcessingChest = false
local lootedChests = {}

local function collectAllItems(chestId, items)
    if not items then return end
    
    print("Chest opened. Starting collection. ID: " .. tostring(chestId))
    
    if #items == 0 then
        print("Chest is empty.")
    else
        print("Items found: " .. #items)
    end
    
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
            print("Successfully collected: " .. tostring(item.name))
        else
            print("Failed to collect " .. tostring(item.name) .. ": " .. tostring(result))
        end
        
        task.wait(0.1)
    end
end

ChestEvent.OnClientEvent:Connect(function(eventType, eventData)
    if eventType == "OpenChest" and eventData then
        isProcessingChest = true
        task.spawn(function()
            local s, e = pcall(collectAllItems, eventData.chestId, eventData.items)
            if not s then
                print("Collection error: " .. tostring(e))
            end
            
            print("Closing chest...")
            task.wait(0.2)
            
            local closeSuccess, closeResult = pcall(function()
                return BackpackFunction:InvokeServer("CloseChest")
            end)
            
            if closeSuccess then
                print("Chest closed.")
            else
                print("Failed to close chest: " .. tostring(closeResult))
            end
            
            task.wait(0.5)
            isProcessingChest = false
            print("Ready for next chest")
        end)
    end
end)

local function findChest()
    local closestPart = nil
    local closestDist = math.huge
    local closestPrompt = nil
    
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and not lootedChests[prompt] then
            local isChest = false
            local parent = prompt.Parent
            local nameStr = ""
            local objStr = (prompt.ObjectText or ""):lower()
            local actStr = (prompt.ActionText or ""):lower()
            
            local current = parent
            while current and current ~= Workspace do
                nameStr = nameStr .. (current.Name or ""):lower() .. " "
                current = current.Parent
            end
            
            if string.find(nameStr, "chest") or string.find(objStr, "chest") or string.find(actStr, "chest") or string.find(nameStr, "crate") or string.find(nameStr, "loot") then
                local targetPart = parent:IsA("BasePart") and parent or (parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart"))
                if targetPart then
                    local character = player.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        local distance = (character.HumanoidRootPart.Position - targetPart.Position).Magnitude
                        if distance < closestDist then
                            closestDist = distance
                            closestPart = targetPart
                            closestPrompt = prompt
                        end
                    end
                end
            end
        end
    end
    
    return closestPart, closestPrompt, closestDist
end

task.spawn(function()
    print("Starting auto farm...")
    
    while true do
        pcall(function()
            if not isProcessingChest then
                local chestPart, prompt, dist = findChest()
                
                if chestPart then
                    print("Chest found. Distance: " .. math.floor(dist))
                    local character = player.Character
                    
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.CFrame = chestPart.CFrame * CFrame.new(0, 3, 0)
                        task.wait(0.5)
                        
                        if prompt then
                            print("Activating prompt...")
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
                            lootedChests[prompt] = true
                        else
                            print("Chest successfully opened. Blacklisting to prevent re-looting.")
                            lootedChests[prompt] = true
                        end
                    end
                else
                    print("No chests found. Searching...")
                end
            end
        end)
        
        task.wait(0.5)
    end
end)
