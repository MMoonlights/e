getgenv().TargetPart = "Head"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local StarterGui = game:GetService("StarterGui")

local Holding = false
local LockedTarget = nil
local FOV_RADIUS = 120
local PredictionAmount = 0.12
local CurrentHighlight = nil
local GUIVisible = true

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = true

local function createHighlight(target)
	if CurrentHighlight then CurrentHighlight:Destroy() end
	local h = Instance.new("Highlight")
	h.FillColor = Color3.new(1, 0, 0)
	h.OutlineColor = Color3.new(1, 1, 1)
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = target.Character
	h.Parent = target.Character
	CurrentHighlight = h
end

local function removeHighlight()
	if CurrentHighlight then
		CurrentHighlight:Destroy()
		CurrentHighlight = nil
	end
end

local function GetClosest()
	local closest, shortest = nil, FOV_RADIUS
	local mousePos = UIS:GetMouseLocation()

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character and plr.Character:FindFirstChild(getgenv().TargetPart) then
			local pos, visible = Camera:WorldToViewportPoint(plr.Character[getgenv().TargetPart].Position)
			if visible then
				local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
				if dist < shortest then
					closest = plr
					shortest = dist
				end
			end
		end
	end

	return closest
end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "17Camlock_GUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0, 20, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "🎯 17 Camlock Settings"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local function createTargetButton(text, partName, yPos)
	local btn = Instance.new("TextButton", Frame)
	btn.Size = UDim2.new(0, 180, 0, 25)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = "🎯 " .. text
	btn.MouseButton1Click:Connect(function()
		getgenv().TargetPart = partName
		StarterGui:SetCore("SendNotification", {
			Title = "🎯 Camlock",
			Text = "Target Part: " .. partName,
			Duration = 2
		})
	end)
end

local function createColorButton(text, color, yPos)
	local btn = Instance.new("TextButton", Frame)
	btn.Size = UDim2.new(0, 180, 0, 25)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = text
	btn.MouseButton1Click:Connect(function()
		FOVCircle.Color = color
	end)
end

local SliderLabel = Instance.new("TextLabel", Frame)
SliderLabel.Size = UDim2.new(0, 180, 0, 20)
SliderLabel.Position = UDim2.new(0, 10, 0, 190)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "📏 FOV Radius: " .. FOV_RADIUS
SliderLabel.TextColor3 = Color3.new(1, 1, 1)
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 14

local Slider = Instance.new("TextButton", Frame)
Slider.Size = UDim2.new(0, 180, 0, 20)
Slider.Position = UDim2.new(0, 10, 0, 215)
Slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Slider.Text = "Click to Increase"
Slider.TextColor3 = Color3.new(1, 1, 1)
Slider.Font = Enum.Font.Gotham
Slider.TextSize = 14
Slider.MouseButton1Click:Connect(function()
	FOV_RADIUS = (FOV_RADIUS % 300) + 20
	FOVCircle.Radius = FOV_RADIUS
	SliderLabel.Text = "📏 FOV Radius: " .. FOV_RADIUS
end)

createTargetButton("Head", "Head", 40)
createTargetButton("HumanoidRootPart", "HumanoidRootPart", 70)
createColorButton("🔴 Red", Color3.fromRGB(255, 0, 0), 100)
createColorButton("🔵 Blue", Color3.fromRGB(0, 120, 255), 130)
createColorButton("🟢 Green", Color3.fromRGB(0, 255, 0), 160)

UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = true
	elseif input.KeyCode == Enum.KeyCode.RightShift then
		GUIVisible = not GUIVisible
		Frame.Visible = GUIVisible
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Holding = false
		LockedTarget = nil
		removeHighlight()
	end
end)

RunService.RenderStepped:Connect(function()
	local mousePos = UIS:GetMouseLocation()
	FOVCircle.Position = Vector2.new(mousePos.X, mousePos.Y)

	if Holding then
		if not LockedTarget or not LockedTarget.Character or not LockedTarget.Character:FindFirstChild(getgenv().TargetPart) then
			LockedTarget = GetClosest()
			if LockedTarget then
				createHighlight(LockedTarget)
			end
		end

		if LockedTarget and LockedTarget.Character and LockedTarget.Character:FindFirstChild(getgenv().TargetPart) then
			local part = LockedTarget.Character[getgenv().TargetPart]
			local predicted = part.Position + (part.Velocity * PredictionAmount)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
		end
	end
end)
