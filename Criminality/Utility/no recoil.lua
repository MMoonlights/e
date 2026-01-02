local LP = game:GetService("Players").LocalPlayer

local function removeRecoil()
    for _, tool in ipairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            for _, mod in ipairs(tool:GetDescendants()) do
                if mod:IsA("ModuleScript") and mod.Name:lower():find("settings") or mod.Name:lower():find("config") then
                    local success, result = pcall(function() return require(mod) end)
                    if success and typeof(result) == "table" then
                        for key, value in pairs(result) do
                            if type(value) == "number" and (key:lower():find("recoil") or key:lower():find("spread")) then
                                result[key] = 0
                            end
                        end
                    end
                end
            end
        end
    end
end

LP.Backpack.ChildAdded:Connect(function()
    task.wait(0.1)
    removeRecoil()
end)

removeRecoil()
