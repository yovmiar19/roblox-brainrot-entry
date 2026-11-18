-- Game.client: the whole interface of Brainrot Bazaar.
-- A start screen, the cash and income display, the upgrade and rebirth
-- buttons, and the raid warning banner. It only shows what the server
-- sends it; every number it shows comes from the server's HudUpdate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hudUpdate = ReplicatedStorage:WaitForChild("HudUpdate")
local raidWarning = ReplicatedStorage:WaitForChild("RaidWarning")
local rebirthRequest = ReplicatedStorage:WaitForChild("RebirthRequest")
local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- The start screen: title, how to play, one big PLAY button.
local startScreen = Instance.new("Frame")
startScreen.Name = "StartScreen"
startScreen.Size = UDim2.fromScale(1, 1)
startScreen.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
startScreen.BorderSizePixel = 0
startScreen.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.12, 0)
title.Size = UDim2.new(0.9, 0, 0.14, 0)
title.BackgroundTransparency = 1
title.Text = "BRAINROT BAZAAR"
title.TextColor3 = Color3.fromRGB(255, 220, 60)
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Parent = startScreen

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(0.5, 0)
subtitle.Position = UDim2.new(0.5, 0, 0.27, 0)
subtitle.Size = UDim2.new(0.9, 0, 0.06, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Collect absurd brainrots. Earn money every second. Beware the Snatcher!"
subtitle.TextColor3 = Color3.fromRGB(230, 230, 255)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.GothamBold
subtitle.Parent = startScreen

local howTo = Instance.new("TextLabel")
howTo.Name = "HowTo"
howTo.AnchorPoint = Vector2.new(0.5, 0)
howTo.Position = UDim2.new(0.5, 0, 0.36, 0)
howTo.Size = UDim2.new(0.8, 0, 0.3, 0)
howTo.BackgroundTransparency = 1
howTo.Text = "HOW TO PLAY\n\n1. Brainrots march down the yellow lane.\n2. Click one to buy it - it moves onto your base.\n3. Every brainrot earns cash every second.\n4. Buy rarer brainrots, upgrade your base, rebirth for double income.\n5. When the Sneaky Snatcher comes, click him 3 times to bonk him away!"
howTo.TextColor3 = Color3.fromRGB(255, 255, 255)
howTo.TextSize = 20
howTo.Font = Enum.Font.Gotham
howTo.TextWrapped = true
howTo.TextYAlignment = Enum.TextYAlignment.Top
howTo.Parent = startScreen

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.AnchorPoint = Vector2.new(0.5, 0)
playButton.Position = UDim2.new(0.5, 0, 0.7, 0)
playButton.Size = UDim2.new(0.3, 0, 0.1, 0)
playButton.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.TextScaled = true
playButton.Font = Enum.Font.GothamBlack
playButton.Parent = startScreen

playButton.MouseButton1Click:Connect(function()
	startScreen.Visible = false
end)

-- The cash display, top right, clear of Roblox's own menu buttons.
local cashFrame = Instance.new("Frame")
cashFrame.Name = "CashFrame"
cashFrame.AnchorPoint = Vector2.new(1, 0)
cashFrame.Position = UDim2.new(1, -16, 0, 16)
cashFrame.Size = UDim2.new(0, 280, 0, 96)
cashFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
cashFrame.BackgroundTransparency = 0.2
cashFrame.Parent = gui

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(1, -16, 0.5, 0)
cashLabel.Position = UDim2.new(0, 8, 0, 4)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "Cash: $100"
cashLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
cashLabel.TextSize = 28
cashLabel.Font = Enum.Font.GothamBlack
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = cashFrame

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -16, 0.5, 0)
incomeLabel.Position = UDim2.new(0, 8, 0.5, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+$0/s - 0 brainrots"
incomeLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
incomeLabel.TextSize = 20
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = cashFrame

-- The raid warning banner, top centre, hidden until a raid comes.
local raidBanner = Instance.new("TextLabel")
raidBanner.Name = "RaidBanner"
raidBanner.AnchorPoint = Vector2.new(0.5, 0)
raidBanner.Position = UDim2.new(0.5, 0, 0, 16)
raidBanner.Size = UDim2.new(0.6, 0, 0, 64)
raidBanner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
raidBanner.BackgroundTransparency = 0.15
raidBanner.Text = ""
raidBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
raidBanner.TextSize = 22
raidBanner.Font = Enum.Font.GothamBlack
raidBanner.TextWrapped = true
raidBanner.Visible = false
raidBanner.Parent = gui

-- The buttons, down the right side: slots, boost, rebirth.
local function makeButton(name, y, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, y)
	button.Size = UDim2.new(0, 280, 0, 56)
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.TextWrapped = true
	button.Parent = gui
	return button
end

local slotsButton = makeButton("SlotsButton", 128, Color3.fromRGB(70, 130, 220))
local boostButton = makeButton("BoostButton", 192, Color3.fromRGB(160, 90, 220))
local rebirthButton = makeButton("RebirthButton", 256, Color3.fromRGB(220, 140, 40))

slotsButton.MouseButton1Click:Connect(function()
	upgradeRequest:FireServer("slots")
end)
boostButton.MouseButton1Click:Connect(function()
	upgradeRequest:FireServer("boost")
end)
rebirthButton.MouseButton1Click:Connect(function()
	rebirthRequest:FireServer()
end)

-- The hint bar along the bottom.
local hint = Instance.new("TextLabel")
hint.Name = "HintBar"
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -16)
hint.Size = UDim2.new(0.7, 0, 0, 44)
hint.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
hint.BackgroundTransparency = 0.2
hint.Text = "Click a brainrot on the yellow lane to buy it!"
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.TextSize = 20
hint.Font = Enum.Font.GothamBold
hint.Parent = gui

local function moneyText(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return string.format("$%d", math.floor(amount))
	end
end

-- Every number on screen comes from the server, once a second.
hudUpdate.OnClientEvent:Connect(function(data)
	cashLabel.Text = "Cash: " .. moneyText(data.cash)
	incomeLabel.Text = "+" .. moneyText(data.income) .. "/s - " .. data.owned .. " brainrots - " .. data.slots .. " slots"
	slotsButton.Text = "+3 Slots (" .. moneyText(data.slotCost) .. ")"
	boostButton.Text = "Income Boost +25% (" .. moneyText(data.boostCost) .. ")"
	if data.canRebirth then
		rebirthButton.Text = "REBIRTH NOW! (2x income)"
	else
		rebirthButton.Text = "Rebirth: earn " .. moneyText(data.rebirthCost) .. " total (" .. moneyText(data.lifetime) .. ")"
	end
end)

local bannerUntil = 0
raidWarning.OnClientEvent:Connect(function(message)
	raidBanner.Text = message
	raidBanner.Visible = true
	bannerUntil = os.clock() + 8
end)

-- Hide the banner again a few seconds after the last warning.
task.spawn(function()
	while true do
		task.wait(0.5)
		if raidBanner.Visible and os.clock() > bannerUntil then
			raidBanner.Visible = false
		end
	end
end)
