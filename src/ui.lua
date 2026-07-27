local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local colors = {
    Background = Color3.fromRGB(12, 14, 18),
    Surface = Color3.fromRGB(18, 21, 27),
    Hover = Color3.fromRGB(24, 28, 35),
    Border = Color3.fromRGB(43, 49, 60),
    Text = Color3.fromRGB(242, 244, 248),
    Muted = Color3.fromRGB(143, 151, 166),
    Accent = Color3.fromRGB(113, 135, 255),
    Success = Color3.fromRGB(77, 196, 128),
    Warning = Color3.fromRGB(242, 180, 72),
    Error = Color3.fromRGB(235, 91, 105)
}

local function make(className, properties, children)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = object
    end
    return object
end

local function corner(radius)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius)
    })
end

local function border()
    return make("UIStroke", {
        Color = colors.Border,
        Transparency = 0.15,
        Thickness = 1
    })
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function parent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then
            return result
        end
    end
    return CoreGui
end

local function kindColor(kind)
    if kind == "success" then
        return colors.Success
    elseif kind == "warning" then
        return colors.Warning
    elseif kind == "error" then
        return colors.Error
    end
    return colors.Accent
end

local UI = {}

function UI.new(options)
    options = options or {}
    local app = {}
    local closed = false
    local minimized = false
    local shown = true
    local onClose

    local old = parent():FindFirstChild("MoonlightsFarmUI")
    if old then
        old:Destroy()
    end

    local screen = make("ScreenGui", {
        Name = "MoonlightsFarmUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 100000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    screen.Parent = parent()

    local toasts = make("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(320, 420),
        BackgroundTransparency = 1,
        ZIndex = 50
    }, {
        make("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })
    toasts.Parent = screen

    local window = make("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(450, 506),
        BackgroundColor3 = colors.Background,
        BorderSizePixel = 0,
        GroupTransparency = 1
    }, {
        corner(16),
        border()
    })
    window.Parent = screen

    local scale = make("UIScale", {
        Scale = 0.94
    })
    scale.Parent = window

    local header = make("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
        Active = true
    })
    header.Parent = window

    local logo = make("Frame", {
        Position = UDim2.fromOffset(15, 13),
        Size = UDim2.fromOffset(38, 38),
        BackgroundColor3 = colors.Accent,
        BorderSizePixel = 0
    }, {
        corner(11)
    })
    logo.Parent = header

    make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "M",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 18
    }).Parent = logo

    make("TextLabel", {
        Position = UDim2.fromOffset(65, 13),
        Size = UDim2.new(1, -160, 0, 22),
        BackgroundTransparency = 1,
        Text = options.Title or "Moonlights",
        TextColor3 = colors.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left
    }).Parent = header

    make("TextLabel", {
        Position = UDim2.fromOffset(65, 35),
        Size = UDim2.new(1, -160, 0, 17),
        BackgroundTransparency = 1,
        Text = options.Subtitle or "Farm Boxes",
        TextColor3 = colors.Muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }).Parent = header

    local function headerButton(text, offset)
        local button = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, offset, 0, 15),
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = colors.Surface,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = text,
            TextColor3 = colors.Muted,
            Font = Enum.Font.GothamBold,
            TextSize = 16
        }, {
            corner(10),
            border()
        })
        button.Parent = header
        button.MouseEnter:Connect(function()
            tween(button, 0.15, {
                BackgroundColor3 = colors.Hover,
                TextColor3 = colors.Text
            })
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.15, {
                BackgroundColor3 = colors.Surface,
                TextColor3 = colors.Muted
            })
        end)
        return button
    end

    local closeButton = headerButton("×", -15)
    local minimizeButton = headerButton("–", -57)

    make("Frame", {
        Position = UDim2.new(0, 15, 0, 63),
        Size = UDim2.new(1, -30, 0, 1),
        BackgroundColor3 = colors.Border,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0
    }).Parent = window

    local content = make("CanvasGroup", {
        Position = UDim2.fromOffset(15, 76),
        Size = UDim2.new(1, -30, 1, -90),
        BackgroundTransparency = 1
    })
    content.Parent = window

    local list = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    list.Parent = content

    local status = make("Frame", {
        Size = UDim2.new(1, 0, 0, 102),
        BackgroundColor3 = colors.Surface,
        BorderSizePixel = 0,
        LayoutOrder = 1
    }, {
        corner(13),
        border()
    })
    status.Parent = content

    make("TextLabel", {
        Position = UDim2.fromOffset(13, 11),
        Size = UDim2.new(1, -125, 0, 20),
        BackgroundTransparency = 1,
        Text = "Farm status",
        TextColor3 = colors.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    }).Parent = status

    local badge = make("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -13, 0, 10),
        Size = UDim2.fromOffset(96, 24),
        BackgroundColor3 = colors.Accent,
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        Text = "Loading",
        TextColor3 = colors.Accent,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11
    }, {
        corner(8)
    })
    badge.Parent = status

    local metricsHost = make("Frame", {
        Position = UDim2.fromOffset(13, 42),
        Size = UDim2.new(1, -26, 0, 46),
        BackgroundTransparency = 1
    })
    metricsHost.Parent = status

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    }).Parent = metricsHost

    local metricLabels = {}
    local function metric(name, order)
        local box = make("Frame", {
            Size = UDim2.new(0.25, -6, 1, 0),
            BackgroundColor3 = colors.Background,
            BorderSizePixel = 0,
            LayoutOrder = order
        }, {
            corner(9)
        })
        box.Parent = metricsHost
        make("TextLabel", {
            Position = UDim2.fromOffset(8, 4),
            Size = UDim2.new(1, -16, 0, 14),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = colors.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left
        }).Parent = box
        local value = make("TextLabel", {
            Position = UDim2.fromOffset(8, 20),
            Size = UDim2.new(1, -16, 0, 18),
            BackgroundTransparency = 1,
            Text = "—",
            TextColor3 = colors.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
        value.Parent = box
        metricLabels[name] = value
    end

    metric("Field", 1)
    metric("Target", 2)
    metric("Distance", 3)
    metric("Boxes", 4)

    local controls = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2
    })
    controls.Parent = content

    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    }).Parent = controls

    local orderCounter = 0
    local function card(height, order)
        orderCounter += 1
        local frame = make("Frame", {
            Size = UDim2.new(1, 0, 0, height),
            BackgroundColor3 = colors.Surface,
            BorderSizePixel = 0,
            LayoutOrder = order or orderCounter
        }, {
            corner(13),
            border()
        })
        frame.Parent = controls
        return frame
    end

    local function labels(frame, title, description, right)
        make("TextLabel", {
            Position = UDim2.fromOffset(13, 10),
            Size = UDim2.new(1, -(right or 80), 0, 18),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = colors.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        }).Parent = frame
        make("TextLabel", {
            Position = UDim2.fromOffset(13, 30),
            Size = UDim2.new(1, -(right or 80), 0, 16),
            BackgroundTransparency = 1,
            Text = description or "",
            TextColor3 = colors.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        }).Parent = frame
    end

    function app:CreateToggle(config)
        local frame = card(56, config.Order)
        labels(frame, config.Title, config.Description, 82)
        local track = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -13, 0.5, 0),
            Size = UDim2.fromOffset(46, 27),
            BackgroundColor3 = colors.Border,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = ""
        }, {
            corner(14)
        })
        track.Parent = frame
        local knob = make("Frame", {
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(21, 21),
            BackgroundColor3 = colors.Text,
            BorderSizePixel = 0
        }, {
            corner(11)
        })
        knob.Parent = track
        local control = {
            Value = config.Default == true
        }
        function control:Set(value, silent)
            self.Value = value == true
            tween(track, 0.18, {
                BackgroundColor3 = self.Value and colors.Accent or colors.Border
            })
            tween(knob, 0.2, {
                Position = self.Value and UDim2.fromOffset(22, 3) or UDim2.fromOffset(3, 3)
            })
            if not silent and type(config.Callback) == "function" then
                config.Callback(self.Value, self)
            end
        end
        track.Activated:Connect(function()
            control:Set(not control.Value)
        end)
        control:Set(control.Value, true)
        return control
    end

    function app:CreateSlider(config)
        local minimum = config.Minimum or 0
        local maximum = config.Maximum or 100
        local frame = card(70, config.Order)
        labels(frame, config.Title, config.Description, 76)
        local valueLabel = make("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -13, 0, 10),
            Size = UDim2.fromOffset(55, 18),
            BackgroundTransparency = 1,
            TextColor3 = colors.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right
        })
        valueLabel.Parent = frame
        local bar = make("TextButton", {
            Position = UDim2.new(0, 13, 1, -17),
            Size = UDim2.new(1, -26, 0, 6),
            BackgroundColor3 = colors.Border,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = ""
        }, {
            corner(3)
        })
        bar.Parent = frame
        local fill = make("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = colors.Accent,
            BorderSizePixel = 0
        }, {
            corner(3)
        })
        fill.Parent = bar
        local handle = make("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.fromOffset(14, 14),
            BackgroundColor3 = colors.Text,
            BorderSizePixel = 0
        }, {
            corner(7)
        })
        handle.Parent = bar
        local dragging = false
        local control = {
            Value = minimum
        }
        function control:Set(value, silent)
            value = math.clamp(math.floor((tonumber(value) or minimum) + 0.5), minimum, maximum)
            self.Value = value
            local alpha = (value - minimum) / (maximum - minimum)
            valueLabel.Text = tostring(value)
            tween(fill, 0.14, {
                Size = UDim2.fromScale(alpha, 1)
            })
            tween(handle, 0.14, {
                Position = UDim2.fromScale(alpha, 0.5)
            })
            if not silent and type(config.Callback) == "function" then
                config.Callback(value, self)
            end
        end
        local function update(input)
            local alpha = math.clamp(
                (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
                0,
                1
            )
            control:Set(minimum + (maximum - minimum) * alpha)
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = true
                update(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                dragging = false
            end
        end)
        control:Set(config.Default or minimum, true)
        return control
    end

    function app:CreateButton(config)
        local frame = card(52, config.Order)
        labels(frame, config.Title, config.Description, 116)
        local button = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -13, 0.5, 0),
            Size = UDim2.fromOffset(90, 31),
            BackgroundColor3 = colors.Accent,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = config.ButtonText or "Run",
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamSemibold,
            TextSize = 11
        }, {
            corner(9)
        })
        button.Parent = frame
        button.MouseEnter:Connect(function()
            tween(button, 0.15, {
                BackgroundColor3 = Color3.fromRGB(132, 151, 255)
            })
        end)
        button.MouseLeave:Connect(function()
            tween(button, 0.15, {
                BackgroundColor3 = colors.Accent
            })
        end)
        button.Activated:Connect(function()
            if type(config.Callback) == "function" then
                task.spawn(config.Callback)
            end
        end)
        return button
    end

    function app:SetFarmState(state)
        local mode = tostring(state.Mode or "Idle")
        local lower = string.lower(mode)
        local kind = "info"
        if lower == "ready" or lower == "searching" or lower == "attacking" then
            kind = "success"
        elseif lower == "walking" or lower == "loading" then
            kind = "warning"
        elseif lower == "unavailable" or lower == "no field" then
            kind = "error"
        end
        local color = kindColor(kind)
        badge.Text = mode
        badge.TextColor3 = color
        tween(badge, 0.18, {
            BackgroundColor3 = color
        })
        metricLabels.Field.Text = state.FieldId and tostring(state.FieldId) or "—"
        metricLabels.Target.Text = state.TargetId and tostring(state.TargetId) or "—"
        metricLabels.Distance.Text = state.Distance and string.format("%.1f", state.Distance) or "—"
        metricLabels.Boxes.Text = tostring(state.Available or 0)
    end

    function app:Notify(title, message, kind, duration)
        if closed then
            return
        end
        local color = kindColor(kind)
        local toast = make("CanvasGroup", {
            Size = UDim2.fromOffset(305, 74),
            BackgroundColor3 = colors.Surface,
            BorderSizePixel = 0,
            GroupTransparency = 1
        }, {
            corner(12),
            border()
        })
        toast.Parent = toasts
        toast.Position = UDim2.fromOffset(24, 0)
        make("Frame", {
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(0, 4, 1, -16),
            BackgroundColor3 = color,
            BorderSizePixel = 0
        }, {
            corner(2)
        }).Parent = toast
        make("TextLabel", {
            Position = UDim2.fromOffset(21, 10),
            Size = UDim2.new(1, -32, 0, 18),
            BackgroundTransparency = 1,
            Text = tostring(title),
            TextColor3 = colors.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        }).Parent = toast
        make("TextLabel", {
            Position = UDim2.fromOffset(21, 31),
            Size = UDim2.new(1, -32, 0, 33),
            BackgroundTransparency = 1,
            Text = tostring(message),
            TextColor3 = colors.Muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top
        }).Parent = toast
        tween(toast, 0.25, {
            GroupTransparency = 0,
            Position = UDim2.fromOffset(0, 0)
        })
        task.delay(duration or 3.5, function()
            if toast.Parent then
                local animation = tween(toast, 0.22, {
                    GroupTransparency = 1,
                    Position = UDim2.fromOffset(22, 0)
                })
                animation.Completed:Wait()
                if toast.Parent then
                    toast:Destroy()
                end
            end
        end)
    end

    function app:SetOnClose(callback)
        onClose = callback
    end

    function app:SetVisible(value)
        shown = value == true
        if shown then
            screen.Enabled = true
            window.GroupTransparency = 1
            scale.Scale = 0.97
            tween(window, 0.2, {
                GroupTransparency = 0
            })
            tween(scale, 0.22, {
                Scale = 1
            })
        else
            local animation = tween(window, 0.18, {
                GroupTransparency = 1
            })
            tween(scale, 0.18, {
                Scale = 0.97
            })
            animation.Completed:Connect(function()
                if not shown and screen.Parent then
                    screen.Enabled = false
                end
            end)
        end
    end

    function app:Destroy()
        if closed then
            return
        end
        closed = true
        if type(onClose) == "function" then
            pcall(onClose)
        end
        local animation = tween(window, 0.2, {
            GroupTransparency = 1
        })
        tween(scale, 0.2, {
            Scale = 0.94
        })
        animation.Completed:Wait()
        if screen.Parent then
            screen:Destroy()
        end
    end

    minimizeButton.Activated:Connect(function()
        minimized = not minimized
        if minimized then
            content.Visible = false
            tween(window, 0.24, {
                Size = UDim2.fromOffset(450, 64)
            })
            minimizeButton.Text = "+"
        else
            content.Visible = true
            content.GroupTransparency = 1
            tween(window, 0.27, {
                Size = UDim2.fromOffset(450, 506)
            })
            task.delay(0.08, function()
                if content.Parent then
                    tween(content, 0.18, {
                        GroupTransparency = 0
                    })
                end
            end)
            minimizeButton.Text = "–"
        end
    end)

    closeButton.Activated:Connect(function()
        task.spawn(function()
            app:Destroy()
        end)
    end)

    local dragging = false
    local dragStart
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = false
        end
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightShift then
            app:SetVisible(not shown)
        end
    end)

    tween(window, 0.3, {
        GroupTransparency = 0
    })
    tween(scale, 0.33, {
        Scale = 1
    })

    return app
end

return UI
