local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage:WaitForChild("Event"):WaitForChild("Backpack"):WaitForChild("BackpackRemoteFunction")

-- Точная папка со скриншота (можешь писать как китайскими буквами, так и кодами)
local ChestFolder = workspace:FindFirstChild("宝箱") or workspace["\229\174\157\231\174\177"]

if not ChestFolder then
    warn("Папка с сундуками не найдена!")
    return
end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

print("Найдено сундуков для фарма:", #ChestFolder:GetChildren())

-- Перебираем все объекты в папке "宝箱"
for _, chestModel in ipairs(ChestFolder:GetChildren()) do
    
    -- Проверяем, что это модель и её название "保险箱" (Ящик)
    if chestModel:IsA("Model") and chestModel.Name == "保险箱" then 
        
        -- БЕРЕМ ID ИЗ АТРИБУТОВ (как на твоем скриншоте)
        local chestId = chestModel:GetAttribute("ChestId")
        
        if chestId then
            -- На скрине видно, что PrimaryPart установлен как RootPart
            local rootPart = chestModel.PrimaryPart
            
            if rootPart then
                print("Телепортируемся к сундуку:", chestId)
                
                -- Телепортируемся прямо на сундук
                HumanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 5, 0)
                task.wait(0.5) -- Ждем, чтобы сервер понял, что мы пришли
                
                -- Отправляем команду на открытие
                local success, result = pcall(function()
                    -- ВНИМАНИЕ: "OpenChest" - это мое предположение.
                    -- Если сундук не откроется, тебе нужно будет узнать точное название команды через RemoteSpy
                    return Event:InvokeServer("OpenChest", chestId)
                end)
                
                if success then
                    print("Сервер ответил на открытие", chestId, ":", result)
                else
                    warn("ОШИБКА при открытии", chestId)
                end
                
                task.wait(1) -- Небольшая пауза, чтобы не спамить и не поймать античит
            end
        end
    end
end

print("Фарм завершен!")
