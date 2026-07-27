local legacyUrl = "https://raw.githubusercontent.com/MMoonlights/e/9a3e3c37314d7469752e102bc9d271f20053bf82/Unbs.lua"

local ok, legacySource = pcall(function()
    return game:HttpGet(legacyUrl)
end)

if not ok or type(legacySource) ~= "string" then
    error("[Moonlights] Failed to download farm source: " .. tostring(legacySource))
end

local startIndex = string.find(
    legacySource,
    "local BoxController = nil",
    1,
    true
)

local endIndex = string.find(
    legacySource,
    'MainTab:Label("Weapons"',
    startIndex or 1,
    true
)

if not startIndex or not endIndex then
    error("[Moonlights] Farm source markers were not found")
end

local generatedSource = [=[return function(options)
    options = options or {}
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local controls = {}
    local state = {
        Ready = false,
        Enabled = false,
        AutoWalk = true,
        FieldId = nil,
        FieldType = nil,
        Available = 0,
        TargetId = nil,
        Distance = nil,
        Mode = "Loading",
        AttackRange = 10,
        AttacksPerSecond = 6
    }
    local nativePrint = print
    local nativeWarn = warn

    local function copy()
        local result = {}
        for key, value in pairs(state) do
            result[key] = value
        end
        return result
    end

    local function emit()
        if type(options.OnState) == "function" then
            task.defer(options.OnState, copy())
        end
    end

    local function notify(title, message, kind)
        if type(options.OnNotify) == "function" then
            task.defer(options.OnNotify, title, tostring(message), kind or "info")
        end
    end

    local function print(...)
        local args = table.pack(...)
        nativePrint(...)
        if args[1] == "[Success] BoxController state loaded"
            or args[1] == "[Success] Boxes API loaded"
        then
            state.Ready = true
            state.Mode = state.Enabled and "Searching" or "Ready"
            emit()
        elseif args[1] == "[Boxes] Locked field" then
            state.FieldId = args[2]
            state.FieldType = args[3]
            state.Mode = "Searching"
            notify("Field locked", "Farm is restricted to field " .. tostring(args[2]), "success")
            emit()
        elseif args[1] == "[Boxes] Field" then
            state.FieldId = args[2]
            state.Available = tonumber(args[4]) or 0
            state.TargetId = args[6] ~= "none" and args[6] or nil
            state.Distance = tonumber(args[8])
            state.Mode = tostring(args[9] or "Waiting")
            emit()
        end
    end

    local function warn(...)
        local args = table.pack(...)
        nativeWarn(...)
        if args[1] == "[Boxes] Could not lock the current field" then
            state.Enabled = false
            state.Mode = "No field"
            notify("Field not found", "Move into a box field and enable the farm again.", "warning")
            emit()
        elseif args[1] == "[Boxes] Attack failed:" then
            notify("Attack failed", args[2] or "Unknown error", "error")
        end
    end

    local MainTab = {}

    function MainTab:Label()
    end

    function MainTab:Paragraph()
        return {
            SetText = function()
            end,
            SetUpdateFunction = function()
            end
        }
    end

    function MainTab:Toggle(name, default, callback)
        controls[name] = {
            Value = default,
            Callback = callback
        }
    end

    function MainTab:Slider(name, minimum, maximum, default, callback)
        controls[name] = {
            Minimum = minimum,
            Maximum = maximum,
            Value = default,
            Callback = callback
        }
    end

]=]
    .. string.sub(legacySource, startIndex, endIndex - 1)
    .. [=[    local api = {}

    function api:IsReady()
        return type(boxAreaState) == "table" and BoxesAPI ~= nil
    end

    function api:GetState()
        state.Ready = self:IsReady()
        state.Enabled = autoAttackBoxes
        state.AutoWalk = autoWalkToBoxes
        state.AttackRange = attackRange
        state.AttacksPerSecond = attacksPerSecond
        return copy()
    end

    function api:SetEnabled(value)
        value = value == true
        if value and not self:IsReady() then
            notify("Still loading", "The game modules are not ready yet.", "warning")
            return false
        end
        local control = controls["Auto Farm Boxes"]
        if not control then
            return false
        end
        local ok, result = pcall(control.Callback, value)
        if not ok then
            notify("Farm error", result, "error")
            return false
        end
        state.Enabled = autoAttackBoxes
        state.Mode = state.Enabled and "Searching" or "Idle"
        if not state.Enabled then
            state.TargetId = nil
            state.Distance = nil
            state.Available = 0
        end
        emit()
        return state.Enabled == value
    end

    function api:SetAutoWalk(value)
        local control = controls["Auto Walk To Boxes"]
        if not control then
            return false
        end
        local ok, result = pcall(control.Callback, value == true)
        if not ok then
            notify("Movement error", result, "error")
            return false
        end
        state.AutoWalk = autoWalkToBoxes
        emit()
        return true
    end

    function api:SetAttackRange(value)
        local control = controls["Attack Range"]
        if not control then
            return false
        end
        value = math.clamp(math.floor(tonumber(value) or 10), control.Minimum, control.Maximum)
        local ok, result = pcall(control.Callback, value)
        if not ok then
            notify("Range error", result, "error")
            return false
        end
        state.AttackRange = attackRange
        emit()
        return true
    end

    function api:SetAttacksPerSecond(value)
        local control = controls["Attacks Per Second"]
        if not control then
            return false
        end
        value = math.clamp(math.floor(tonumber(value) or 6), control.Minimum, control.Maximum)
        local ok, result = pcall(control.Callback, value)
        if not ok then
            notify("Speed error", result, "error")
            return false
        end
        state.AttacksPerSecond = attacksPerSecond
        emit()
        return true
    end

    function api:Relock()
        if not autoAttackBoxes then
            notify("Farm is disabled", "Enable Farm Boxes before relocking the field.", "info")
            return false
        end
        local control = controls["Auto Farm Boxes"]
        local ok, result = pcall(function()
            control.Callback(false)
            task.wait(0.1)
            control.Callback(true)
        end)
        if not ok then
            notify("Relock failed", result, "error")
            return false
        end
        state.Enabled = autoAttackBoxes
        emit()
        return state.Enabled
    end

    function api:Destroy()
        if autoAttackBoxes then
            self:SetEnabled(false)
        end
    end

    task.spawn(function()
        for _ = 1, 120 do
            if api:IsReady() then
                state.Ready = true
                state.Mode = "Ready"
                emit()
                notify("Farm ready", "Box modules loaded successfully.", "success")
                return
            end
            task.wait(0.25)
        end
        state.Mode = "Unavailable"
        emit()
        notify("Farm unavailable", "The required game modules did not load.", "error")
    end)

    return api
end
]=]

local chunk, compileError = loadstring(generatedSource)

if not chunk then
    error("[Moonlights] Farm engine compilation failed: " .. tostring(compileError))
end

return chunk()
