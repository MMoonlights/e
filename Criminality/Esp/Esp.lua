local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local boxes = {}
local texts = {}
local healthTexts = {}

local BOX_COLOR = Color3.fromRGB(255, 0, 0)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local HEALTH_TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local TEXT_SIZE = 14
local TEXT_OFFSET = 20

local function createESP(player)
	if player == LocalPlayer then return end
	
	local box = Drawing.new("Square")
	box.Color = BOX_COLOR
	box.Thickness = 1
	box.Transparency = 1
	box.Filled = false
	box.Visible = false
	
	local text = Drawing.new("Text")
	text.Color = TEXT_COLOR
	text.Size = TEXT_SIZE
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false
	text.Text = player.Name
	
	local healthText = Drawing.new("Text")
	healthText.Color = HEALTH_TEXT_COLOR
	healthText.Size = TEXT_SIZE
	healthText.Center = true
	healthText.Outline = true
	healthText.OutlineColor = Color3.fromRGB(0, 0, 0)
	healthText.Visible = false
	
	boxes[player] = box
	texts[player] = text
	healthTexts[player] = healthText
	
	return box, text, healthText
end

for _, player in pairs(Players:GetPlayers()) do
	createESP(player)
end

Players.PlayerAdded:Connect(function(player)
	createESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
	if boxes[player] then
		boxes[player]:Remove()
		texts[player]:Remove()
		healthTexts[player]:Remove()
		boxes[player] = nil
		texts[player] = nil
		healthTexts[player] = nil
	end
end)

local function getCharacterBoundingBox(character)
	local minX, minY, minZ = math.huge, math.huge, math.huge
	local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
	
	for _, part in pairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local cf = part.CFrame
			local size = part.Size
			
			local corners = {
				cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
				cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
				cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
				cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2)
			}
			
			for _, corner in pairs(corners) do
				minX = math.min(minX, corner.X)
				minY = math.min(minY, corner.Y)
				minZ = math.min(minZ, corner.Z)
				maxX = math.max(maxX, corner.X)
				maxY = math.max(maxY, corner.Y)
				maxZ = math.max(maxZ, corner.Z)
			end
		end
	end
	
	if minX == math.huge then return nil end
	
	local center = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
	local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
	
	return center, size
end

RunService.RenderStepped:Connect(function()
	for player, box in pairs(boxes) do
		local char = player.Character
		local text = texts[player]
		local healthText = healthTexts[player]
		
		if char and char:FindFirstChild("Humanoid") then
			local humanoid = char.Humanoid
			
			local center, size = getCharacterBoundingBox(char)
			
			if center then
				local topPos = center + Vector3.new(0, size.Y/2, 0)
				local bottomPos = center - Vector3.new(0, size.Y/2, 0)
				
				local topScreenPos, topVisible = Camera:WorldToViewportPoint(topPos)
				local bottomScreenPos, bottomVisible = Camera:WorldToViewportPoint(bottomPos)
				
				if topVisible and bottomVisible then
					local height = math.abs(topScreenPos.Y - bottomScreenPos.Y)
					local width = height * (size.X / size.Y) * 0.5
					
					local boxPos = Vector2.new(
						bottomScreenPos.X - width/2,
						bottomScreenPos.Y - height
					)
					
					box.Size = Vector2.new(width, height)
					box.Position = boxPos
					box.Visible = true
					
					text.Position = Vector2.new(
						bottomScreenPos.X,
						boxPos.Y - TEXT_OFFSET
					)
					text.Visible = true
					
					local health = math.floor(humanoid.Health)
					local maxHealth = math.floor(humanoid.MaxHealth)
					healthText.Text = health .. "/" .. maxHealth
					healthText.Position = Vector2.new(
						bottomScreenPos.X,
						boxPos.Y - TEXT_OFFSET * 2
					)
					healthText.Visible = true
					
					local healthPercentage = humanoid.Health / humanoid.MaxHealth
					if healthPercentage > 0.7 then
						healthText.Color = Color3.fromRGB(0, 255, 0)
					elseif healthPercentage > 0.3 then
						healthText.Color = Color3.fromRGB(255, 255, 0)
					else
						healthText.Color = Color3.fromRGB(255, 0, 0)
					end
				else
					box.Visible = false
					text.Visible = false
					healthText.Visible = false
				end
			else
				box.Visible = false
				text.Visible = false
				healthText.Visible = false
			end
		else
			box.Visible = false
			text.Visible = false
			healthText.Visible = false
		end
	end
end)

local function updatePlayerText(player)
	if texts[player] and player.Character and player.Character:FindFirstChild("Humanoid") then
		texts[player].Text = player.Name
		
		local humanoid = player.Character.Humanoid
		local health = math.floor(humanoid.Health)
		local maxHealth = math.floor(humanoid.MaxHealth)
		healthTexts[player].Text = health .. "/" .. maxHealth
	end
end

game:GetService("RunService").Heartbeat:Connect(function()
	for player, _ in pairs(boxes) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			local health = math.floor(humanoid.Health)
			local maxHealth = math.floor(humanoid.MaxHealth)
			
			if healthTexts[player] then
				healthTexts[player].Text = health .. "/" .. maxHealth
			end
		end
	end
end)

print("ESP loaded successfully!")