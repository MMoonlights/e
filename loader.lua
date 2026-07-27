if not game:IsLoaded() then
    game.Loaded:Wait()
end

assert(
    type(loadstring) == "function",
    "[Moonlights] This executor does not support loadstring"
)

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local environment = type(getgenv) == "function"
    and getgenv()
    or _G

local baseUrl = "https://raw.githubusercontent.com/MMoonlights/e/main/"
environment.MoonlightsBaseUrl = baseUrl

local function getParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)

        if ok and typeof(result) == "Instance" then
            return result
        end
    end

    return CoreGui
end

local function create(className, properties, children)
    local instance = Instance.new(className)

    for key, value in pairs(properties or {}) do
        instance[key] = value
    end

    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end

    return instance
end

local function tween(instance, duration, properties)
    local animation = TweenService:Create(
        instance,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()
    return animation
end

local old = getParent():FindFirstChild("MoonlightsLoader")

if old then
    old:Destroy()
end

local screen = create("ScreenGui", {
    Name = "MoonlightsLoader",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 99999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(syn.protect_gui, screen)
end

screen.Parent = getParent()

local dim = create("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(6, 8, 11),
    BackgroundTransparency = 1,
    BorderSizePixel = 0
})

dim.Parent = screen

local card = create("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(360, 190),
    BackgroundColor3 = Color3.fromRGB(15, 18, 23),
    BorderSizePixel = 0,
    GroupTransparency = 1
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 16)
    }),
    create("UIStroke", {
        Color = Color3.fromRGB(44, 50, 62),
        Transparency = 0.1,
        Thickness = 1
    })
})

card.Parent = screen

local scale = create("UIScale", {
    Scale = 0.92
})

scale.Parent = card

local logo = create("Frame", {
    Position = UDim2.fromOffset(22, 22),
    Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = Color3.fromRGB(113, 135, 255),
    BorderSizePixel = 0
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 12)
    })
})

logo.Parent = card

create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "M",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 19
}).Parent = logo

create("TextLabel", {
    Position = UDim2.fromOffset(78, 22),
    Size = UDim2.new(1, -100, 0, 24),
    BackgroundTransparency = 1,
    Text = "Moonlights",
    TextColor3 = Color3.fromRGB(242, 244, 248),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left
}).Parent = card

create("TextLabel", {
    Position = UDim2.fromOffset(78, 46),
    Size = UDim2.new(1, -100, 0, 18),
    BackgroundTransparency = 1,
    Text = "Unboxing Simulator · Farm Boxes",
    TextColor3 = Color3.fromRGB(143, 151, 166),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
}).Parent = card

local statusLabel = create("TextLabel", {
    Position = UDim2.fromOffset(22, 92),
    Size = UDim2.new(1, -44, 0, 20),
    BackgroundTransparency = 1,
    Text = "Starting",
    TextColor3 = Color3.fromRGB(205, 210, 220),
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left
})

statusLabel.Parent = card

local percentLabel = create("TextLabel", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -22, 0, 92),
    Size = UDim2.fromOffset(50, 20),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = Color3.fromRGB(113, 135, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right
})

percentLabel.Parent = card

local bar = create("Frame", {
    Position = UDim2.fromOffset(22, 124),
    Size = UDim2.new(1, -44, 0, 8),
    BackgroundColor3 = Color3.fromRGB(39, 44, 54),
    BorderSizePixel = 0
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 4)
    })
})

bar.Parent = card

local fill = create("Frame", {
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Color3.fromRGB(113, 135, 255),
    BorderSizePixel = 0
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 4)
    })
})

fill.Parent = bar

local hint = create("TextLabel", {
    Position = UDim2.fromOffset(22, 148),
    Size = UDim2.new(1, -44, 0, 18),
    BackgroundTransparency = 1,
    Text = "Loading only the required modules",
    TextColor3 = Color3.fromRGB(107, 115, 130),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
})

hint.Parent = card

tween(dim, 0.22, {
    BackgroundTransparency = 0.28
})

tween(card, 0.3, {
    GroupTransparency = 0
})

tween(scale, 0.34, {
    Scale = 1
})

local finished = false
local loaderApi = {}

function loaderApi.SetStatus(text, progress)
    if finished or not screen.Parent then
        return
    end

    progress = math.clamp(tonumber(progress) or 0, 0, 1)
    statusLabel.Text = tostring(text)
    percentLabel.Text = tostring(math.floor(progress * 100 + 0.5)) .. "%"

    tween(fill, 0.28, {
        Size = UDim2.fromScale(progress, 1)
    })
end

function loaderApi.Finish(success, message)
    if finished then
        return
    end

    finished = true
    statusLabel.Text = tostring(message or (success and "Ready" or "Failed"))
    percentLabel.Text = success and "100%" or "!"

    if success then
        fill.BackgroundColor3 = Color3.fromRGB(77, 196, 128)
        tween(fill, 0.2, {
            Size = UDim2.fromScale(1, 1)
        })
    else
        fill.BackgroundColor3 = Color3.fromRGB(235, 91, 105)
    end

    task.delay(success and 0.35 or 2.5, function()
        if not screen.Parent then
            return
        end

        tween(dim, 0.22, {
            BackgroundTransparency = 1
        })

        tween(scale, 0.22, {
            Scale = 0.95
        })

        local animation = tween(card, 0.22, {
            GroupTransparency = 1
        })

        animation.Completed:Wait()

        if screen.Parent then
            screen:Destroy()
        end

        if environment.MoonlightsLoader == loaderApi then
            environment.MoonlightsLoader = nil
        end
    end)
end

environment.MoonlightsLoader = loaderApi
loaderApi.SetStatus("Connecting", 0.18)

local ok, source = pcall(function()
    return game:HttpGet(baseUrl .. "src/main.lua")
end)

if not ok or type(source) ~= "string" or #source == 0 then
    loaderApi.Finish(false, "Download failed")
    error("[Moonlights] Failed to download main module: " .. tostring(source))
end

loaderApi.SetStatus("Compiling", 0.38)

local chunk, compileError = loadstring(source)

if not chunk then
    loaderApi.Finish(false, "Compilation failed")
    error("[Moonlights] Main module compilation failed: " .. tostring(compileError))
end

local runOk, result = pcall(chunk)

if not runOk then
    loaderApi.Finish(false, "Startup failed")
    error("[Moonlights] Main module failed: " .. tostring(result))
end

return result
