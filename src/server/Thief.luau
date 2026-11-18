-- Thief: the Sneaky Snatcher, the threat of Brainrot Bazaar.
-- Every so often he sneaks in from the edge of the map, runs to the
-- richest player's base and tries to steal their most valuable brainrot.
-- Players click him to bonk him away: three bonks and he flees, dropping
-- a bonus. If he reaches the brainrot first, it is gone for good.

local Thief = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

Thief.BONKS_TO_FLEE = 3
Thief.STEAL_BONUS = 100
Thief.WALK_SPEED = 14

local activeThief = nil
local bonks = 0
local targetPlayer = nil
local targetBrainrot = nil
local onStolen = nil
local onFled = nil

local function buildSnatcherModel()
	local model = Instance.new("Model")
	model.Name = "SneakySnatcher"
	-- A shady body in a striped shirt, a mask and a sack.
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(3, 4, 2)
	body.Color = Color3.fromRGB(40, 40, 40)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	-- White stripes on the shirt.
	for i = 1, 2 do
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe" .. i
		stripe.Size = Vector3.new(3.1, 0.6, 2.1)
		stripe.Position = Vector3.new(0, 0.8 + (i - 1) * 1.2, 0)
		stripe.Color = Color3.fromRGB(255, 255, 255)
		stripe.Anchored = true
		stripe.CanCollide = false
		stripe.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = stripe
		weld.Parent = stripe
	end
	-- A black mask over the eyes.
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(2.6, 1, 0.4)
	mask.Position = Vector3.new(0, 1.2, 1.1)
	mask.Color = Color3.fromRGB(0, 0, 0)
	mask.Anchored = true
	mask.CanCollide = false
	mask.Parent = model
	local maskWeld = Instance.new("WeldConstraint")
	maskWeld.Part0 = body
	maskWeld.Part1 = mask
	maskWeld.Parent = mask
	-- The sack on his back.
	local sack = Instance.new("Part")
	sack.Name = "Sack"
	sack.Shape = Enum.PartType.Ball
	sack.Size = Vector3.new(2.5, 2.5, 2.5)
	sack.Position = Vector3.new(0, 0.5, -1.8)
	sack.Color = Color3.fromRGB(150, 110, 60)
	sack.Anchored = true
	sack.CanCollide = false
	sack.Parent = model
	local sackWeld = Instance.new("WeldConstraint")
	sackWeld.Part0 = body
	sackWeld.Part1 = sack
	sackWeld.Parent = sack
	-- The name tag, so every player knows who he is. Kept small and
	-- distance-honest like the brainrot tags, so it never hides the body
	-- or reads the same size from across the map.
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(160, 48)
	tag.StudsOffset = Vector3.new(0, 4, 0)
	tag.AlwaysOnTop = false
	tag.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "SNEAKY SNATCHER\nClick to bonk him!"
	label.TextColor3 = Color3.fromRGB(255, 80, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = tag
	-- Clicking him bonks him. The range is generous on purpose: he is
	-- small, he moves fast, and the player should be able to bonk him
	-- from anywhere on the plaza.
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 200
	clicker.Parent = body
	clicker.MouseClick:Connect(function(_player)
		Thief.bonkThief()
	end)
	return model
end

function Thief.isActive()
	return activeThief ~= nil
end

-- Start a raid: the Snatcher runs at one brainrot of the given player.
-- onStolenCallback runs when he steals it; onFledCallback when he is bonked away.
function Thief.startRaid(player, brainrot, onStolenCallback, onFledCallback)
	if activeThief then
		return false
	end
	targetPlayer = player
	targetBrainrot = brainrot
	onStolen = onStolenCallback
	onFled = onFledCallback
	bonks = 0
	activeThief = buildSnatcherModel()
	activeThief:PivotTo(CFrame.new(85, 4, 40))
	activeThief.Parent = Workspace
	return true
end

function Thief.bonkThief()
	if not activeThief then
		return
	end
	bonks += 1
	-- A little hop so the bonk reads on screen.
	local root = activeThief.PrimaryPart
	if root then
		root.Position += Vector3.new(0, 1, 0)
	end
	if bonks >= Thief.BONKS_TO_FLEE then
		Thief.fleeThief()
	end
end

function Thief.fleeThief()
	if not activeThief then
		return
	end
	local fled = activeThief
	activeThief = nil
	if onFled then
		onFled(targetPlayer, Thief.STEAL_BONUS)
	end
	targetPlayer = nil
	targetBrainrot = nil
	onStolen = nil
	onFled = nil
	task.delay(0.1, function()
		fled:Destroy()
	end)
end

-- Called every heartbeat by the server: walk the Snatcher toward his target.
function Thief.step(dt)
	if not activeThief or not targetBrainrot or not targetBrainrot.model then
		return
	end
	local targetPos = targetBrainrot.model:GetPivot().Position
	local current = activeThief:GetPivot().Position
	local toTarget = targetPos - current
	local distance = toTarget.Magnitude
	if distance < 4 then
		-- He reached the brainrot: he steals it and runs off with it.
		local stolen = targetBrainrot
		local player = targetPlayer
		local callback = onStolen
		local thief = activeThief
		activeThief = nil
		targetPlayer = nil
		targetBrainrot = nil
		onStolen = nil
		onFled = nil
		if callback then
			callback(player, stolen)
		end
		task.delay(0.1, function()
			thief:Destroy()
		end)
		return
	end
	local step = toTarget.Unit * Thief.WALK_SPEED * dt
	activeThief:PivotTo(CFrame.new(current + step))
end

return Thief
