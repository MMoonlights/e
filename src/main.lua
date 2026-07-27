if not game:IsLoaded() then
    game.Loaded:Wait()
end

local environment = type(getgenv) == "function"
    and getgenv()
    or _G

local loader = environment.MoonlightsLoader
local baseUrl = environment.MoonlightsBaseUrl
    or "https://raw.githubusercontent.com/MMoonlights/e/main/"

local function setLoader(text, progress)
    if type(loader) == "table"
        and type(loader.SetStatus) == "function"
    then
        pcall(loader.SetStatus, text, progress)
    end
end

local function loadModule(path)
    local ok, source = pcall(function()
        return game:HttpGet(baseUrl .. path)
    end)

    if not ok or type(source) ~= "string" or #source == 0 then
        error("Failed to download " .. path .. ": " .. tostring(source))
    end

    local chunk, compileError = loadstring(source)

    if not chunk then
        error("Failed to compile " .. path .. ": " .. tostring(compileError))
    end

    local runOk, result = pcall(chunk)

    if not runOk then
        error("Failed to run " .. path .. ": " .. tostring(result))
    end

    return result
end

setLoader("Loading interface", 0.52)
local UI = loadModule("src/ui.lua")

setLoader("Loading farm engine", 0.72)
local Farm = loadModule("src/farm.lua")

if type(environment.MoonlightsFarmApp) == "table"
    and type(environment.MoonlightsFarmApp.Destroy) == "function"
then
    pcall(function()
        environment.MoonlightsFarmApp:Destroy()
    end)
end

setLoader("Building menu", 0.86)

local app = UI.new({
    Title = "Moonlights",
    Subtitle = "Unboxing Simulator · Farm Boxes"
})

local farm

farm = Farm({
    OnState = function(state)
        if app then
            app:SetFarmState(state)
        end
    end,
    OnNotify = function(title, message, kind)
        if app then
            app:Notify(title, message, kind)
        end
    end
})

local farmToggle

farmToggle = app:CreateToggle({
    Title = "Farm Boxes",
    Description = "Lock the current field and farm its boxes",
    Default = false,
    Order = 1,
    Callback = function(value, control)
        local success = farm:SetEnabled(value)

        if value and not success then
            control:Set(false, true)
        end
    end
})

app:CreateToggle({
    Title = "Auto Walk",
    Description = "Walk to the closest box inside the locked field",
    Default = true,
    Order = 2,
    Callback = function(value)
        farm:SetAutoWalk(value)
    end
})

app:CreateSlider({
    Title = "Attacks per second",
    Description = "Server-safe limit is 7 attacks per second",
    Minimum = 1,
    Maximum = 7,
    Default = 6,
    Decimals = 0,
    Order = 3,
    Callback = function(value)
        farm:SetAttacksPerSecond(value)
    end
})

app:CreateSlider({
    Title = "Attack range",
    Description = "Distance used before sending an attack",
    Minimum = 6,
    Maximum = 20,
    Default = 10,
    Decimals = 0,
    Order = 4,
    Callback = function(value)
        farm:SetAttackRange(value)
    end
})

app:CreateButton({
    Title = "Relock current field",
    Description = "Use after moving to another field",
    ButtonText = "Relock",
    Order = 5,
    Callback = function()
        local success = farm:Relock()

        if success then
            app:Notify(
                "Field relocked",
                "The farm now uses your current field.",
                "success"
            )
        end
    end
})

app:SetOnClose(function()
    if farm then
        farm:Destroy()
    end

    if environment.MoonlightsFarmApp == app then
        environment.MoonlightsFarmApp = nil
    end
end)

app:SetFarmState(farm:GetState())
environment.MoonlightsFarmApp = app
environment.MoonlightsFarm = farm

setLoader("Ready", 1)

if type(loader) == "table"
    and type(loader.Finish) == "function"
then
    pcall(loader.Finish, true, "Farm Boxes is ready")
end

task.delay(0.4, function()
    if app then
        app:Notify(
            "Loaded",
            "Press Right Shift to hide or show the menu.",
            "success",
            4
        )
    end
end)

return app
