-- Brainrot Lane, client side: the start screen, the cash and income
-- display, the one upgrade button, a teleport-to-lane button, and the
-- raid warning banner. It only shows what the server sends it; every
-- number on screen comes from the server's HudUpdate, the upgrade
-- button only asks the server through UpgradeRequest, and pressing
-- PLAY (or the teleport button) asks the server through
-- TeleportRequest to put the character right beside the lane.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hudUpdate = ReplicatedStorage:WaitForChild("HudUpdate")
local raidWarning = ReplicatedStorage:WaitForChild("RaidWarning")
local upgradeRequest = ReplicatedStorage:WaitForChild("UpgradeRequest")
local teleportRequest = ReplicatedStorage:WaitForChild("TeleportRequest")

local screen = Instance.new("ScreenGui")
screen.Name = "BrainrotLaneGui"
screen.ResetOnSpawn = false
screen.Parent = playerGui

-- Start screen, shown until PLAY is pressed.
local startFrame = Instance.new("Frame")
startFrame.Name = "StartScreen"
startFrame.Size = UDim2.fromScale(1, 1)
startFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
startFrame.BackgroundTransparency = 0.25
startFrame.Parent = screen

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.8, 0, 0.2, 0)
title.Position = UDim2.new(0.1, 0, 0.25, 0)
title.BackgroundTransparency = 1
title.Text = "BRAINROT LANE"
title.TextColor3 = Color3.fromRGB(255, 220, 0)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 64
title.Parent = startFrame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0.8, 0, 0.15, 0)
subtitle.Position = UDim2.new(0.1, 0, 0.45, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Hold E on a brainrot to buy it. It earns cash every second.\nBonk the Snatcher 3 times before he steals one!"
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.Font = Enum.Font.SourceSans
subtitle.TextSize = 24
subtitle.Parent = startFrame

local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
playButton.Size = UDim2.new(0.3, 0, 0.12, 0)
playButton.Position = UDim2.new(0.35, 0, 0.65, 0)
playButton.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
playButton.Text = "PLAY"
playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playButton.Font = Enum.Font.SourceSansBold
playButton.TextSize = 36
playButton.Parent = startFrame

-- HUD, top right so it stays clear of Roblox's own menu buttons.
local hud = Instance.new("Frame")
hud.Name = "Hud"
hud.Size = UDim2.new(0.32, 0, 0.32, 0)
hud.Position = UDim2.new(0.66, 0, 0.02, 0)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
hud.BackgroundTransparency = 0.3
hud.Visible = false
hud.Parent = screen

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(0.9, 0, 0.18, 0)
cashLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "Cash: $100"
cashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cashLabel.Font = Enum.Font.SourceSansBold
cashLabel.TextSize = 28
cashLabel.Parent = hud

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(0.9, 0, 0.16, 0)
incomeLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "$0/s"
incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
incomeLabel.Font = Enum.Font.SourceSans
incomeLabel.TextSize = 22
incomeLabel.Parent = hud

local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.new(0.9, 0, 0.16, 0)
countLabel.Position = UDim2.new(0.05, 0, 0.43, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "0 brainrots"
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Font = Enum.Font.SourceSans
countLabel.TextSize = 22
countLabel.Parent = hud

local upgradeButton = Instance.new("TextButton")
upgradeButton.Name = "UpgradeButton"
upgradeButton.Size = UDim2.new(0.9, 0, 0.17, 0)
upgradeButton.Position = UDim2.new(0.05, 0, 0.61, 0)
upgradeButton.BackgroundColor3 = Color3.fromRGB(80, 140, 220)
upgradeButton.Text = "Income Boost +25% ($2,500)"
upgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradeButton.Font = Enum.Font.SourceSansBold
upgradeButton.TextSize = 18
upgradeButton.Parent = hud

local teleportButton = Instance.new("TextButton")
teleportButton.Name = "TeleportButton"
teleportButton.Size = UDim2.new(0.9, 0, 0.17, 0)
teleportButton.Position = UDim2.new(0.05, 0, 0.8, 0)
teleportButton.BackgroundColor3 = Color3.fromRGB(230, 170, 40)
teleportButton.Text = "Teleport to Lane"
teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportButton.Font = Enum.Font.SourceSansBold
teleportButton.TextSize = 18
teleportButton.Parent = hud

-- Raid banner, top centre, only while a raid runs.
local banner = Instance.new("TextLabel")
banner.Name = "RaidBanner"
banner.Size = UDim2.new(0.6, 0, 0.08, 0)
banner.Position = UDim2.new(0.2, 0, 0.02, 0)
banner.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
banner.Text = ""
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.Font = Enum.Font.SourceSansBold
banner.TextSize = 24
banner.Visible = false
banner.Parent = screen

playButton.MouseButton1Click:Connect(function()
	startFrame.Visible = false
	hud.Visible = true
	teleportRequest:FireServer()
end)

teleportButton.MouseButton1Click:Connect(function()
	teleportRequest:FireServer()
end)

upgradeButton.MouseButton1Click:Connect(function()
	upgradeRequest:FireServer()
end)

hudUpdate.OnClientEvent:Connect(function(cash, rate, owned, boost)
	cashLabel.Text = "Cash: $" .. cash
	incomeLabel.Text = "$" .. rate .. "/s  (boost x" .. (1 + boost * 0.25) .. ")"
	countLabel.Text = owned .. " brainrots"
end)

raidWarning.OnClientEvent:Connect(function(message)
	banner.Text = message
	banner.Visible = true
	task.delay(5, function()
		banner.Visible = false
	end)
end)
