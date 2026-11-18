-- GameServer: the one place that keeps the state of Brainrot Bazaar.
-- It sends brainrots down the conveyor lane, sells them to players, pays
-- out their income every second, runs the Snatcher raids, and handles
-- rebirths and base upgrades. The client only shows the HUD and asks for
-- rebirths and upgrades through RemoteEvents; the server decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(script.Parent.BrainrotData)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Thief = require(script.Parent.Thief)

local GameServer = {}

-- Tuning, all in one place so every loop reads the same numbers.
GameServer.SPAWN_EVERY_SECONDS = 4
GameServer.WALK_SPEED = 3.5
GameServer.MAX_WALKING = 12
GameServer.STARTING_CASH = 100
GameServer.BASE_SLOTS = 6
GameServer.SLOT_UPGRADE_ADDS = 3
GameServer.MAX_SLOT_LEVEL = 2
GameServer.SLOT_BASE_COST = 1000
GameServer.BOOST_BASE_COST = 2500
GameServer.MAX_BOOST_LEVEL = 5
GameServer.REBIRTH_BASE_EARNINGS = 50000
GameServer.FIRST_RAID_SECONDS = 75
GameServer.RAID_EVERY_SECONDS = 100
GameServer.RAID_WARNING_SECONDS = 10

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 200, 60),
}

local stateByPlayer = {}
local baseSlotsByIndex = {}
local baseOwnerByIndex = {}
local walking = {}
local nextBrainrotId = 1

-- RemoteEvents, made here so the client can find them in ReplicatedStorage.
local hudUpdate = Instance.new("RemoteEvent")
hudUpdate.Name = "HudUpdate"
hudUpdate.Parent = ReplicatedStorage

local raidWarning = Instance.new("RemoteEvent")
raidWarning.Name = "RaidWarning"
raidWarning.Parent = ReplicatedStorage

local rebirthRequest = Instance.new("RemoteEvent")
rebirthRequest.Name = "RebirthRequest"
rebirthRequest.Parent = ReplicatedStorage

local upgradeRequest = Instance.new("RemoteEvent")
upgradeRequest.Name = "UpgradeRequest"
upgradeRequest.Parent = ReplicatedStorage

-- Keep the leaderboard cash in step with the server's own cash, so the
-- number every player sees is always the real one.
local function syncCashValue(player, playerState)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = math.floor(playerState.cash)
	end
end

-- Build one brainrot character as a Model of parts, with a name tag that
-- shows its name, its rarity and what it earns every second. Returns the
-- model, the ClickDetector that buys it, and the rotation that keeps
-- cylinder bodies standing up: a cylinder's long axis is X by default, so
-- the upright is a 90-degree roll around Z, and every place this model is
-- moved to must carry that rotation along, or a plain PivotTo would lay
-- the cylinder on its side and drag its eyes under the body.
function GameServer.buildBrainrotModel(data)
	local model = Instance.new("Model")
	model.Name = data.name

	local upright = CFrame.new()
	if data.shape == Enum.PartType.Cylinder then
		upright = CFrame.Angles(0, 0, math.rad(90))
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = data.shape
	body.Size = data.size
	body.Color = data.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body
	body.CFrame = CFrame.new(0, 0, 0) * upright

	local halfY = data.size.Y / 2
	local halfZ = data.size.Z / 2
	-- Two eyes on the front face.
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye" .. side
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.8, 0.8, 0.8)
		eye.Position = Vector3.new(side * 0.7, 0.5, halfZ + 0.2)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil" .. side
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.4, 0.4, 0.4)
		pupil.Position = Vector3.new(side * 0.7, 0.5, halfZ + 0.5)
		pupil.Color = Color3.fromRGB(0, 0, 0)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end
	-- Two little feet.
	for _, side in ipairs({ -1, 1 }) do
		local foot = Instance.new("Part")
		foot.Name = "Foot" .. side
		foot.Size = Vector3.new(1, 0.6, 1.4)
		foot.Position = Vector3.new(side * 0.8, -halfY + 0.3, 0.2)
		foot.Color = Color3.fromRGB(40, 40, 40)
		foot.Anchored = true
		foot.CanCollide = false
		foot.Parent = model
	end
	-- A crown for the rarest, a top hat for the epics, a cap for the rares.
	local accessory = nil
	if data.rarity == "Legendary" or data.rarity == "Mythic" then
		accessory = Instance.new("Part")
		accessory.Name = "Crown"
		accessory.Shape = Enum.PartType.Cylinder
		accessory.Size = Vector3.new(1.2, 2.2, 2.2)
		accessory.Color = Color3.fromRGB(255, 210, 40)
		accessory.Material = Enum.Material.Neon
	elseif data.rarity == "Epic" then
		accessory = Instance.new("Part")
		accessory.Name = "TopHat"
		accessory.Shape = Enum.PartType.Cylinder
		accessory.Size = Vector3.new(1.6, 2, 2)
		accessory.Color = Color3.fromRGB(30, 30, 30)
	elseif data.rarity == "Rare" then
		accessory = Instance.new("Part")
		accessory.Name = "Cap"
		accessory.Size = Vector3.new(2.4, 0.8, 2.4)
		accessory.Color = BrainrotData.RARITIES[data.rarity].color
	end
	if accessory then
		accessory.Position = Vector3.new(0, halfY + 0.8, 0)
		accessory.Anchored = true
		accessory.CanCollide = false
		accessory.Parent = model
	end
	-- The floating name tag: name, rarity and money a second. Small and
	-- distance-honest on purpose: a big AlwaysOnTop tag reads the same
	-- size from anywhere, hides the body behind it, and makes a faraway
	-- brainrot look close. This one shrinks with distance and lets walls
	-- hide it, so what the player sees is where the brainrot really is.
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(160, 48)
	tag.StudsOffset = Vector3.new(0, halfY + 2.5, 0)
	tag.AlwaysOnTop = false
	tag.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = data.name .. "\n" .. data.rarity .. " - " .. BrainrotData.moneyText(data.income) .. "/s"
	label.TextColor3 = BrainrotData.RARITIES[data.rarity].labelColor
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = tag
	-- A generous invisible hitbox around the body, so clicks land easily:
	-- the body itself is only a few studs across, and clicking a small
	-- moving target from a distance is fiddly. The ClickDetector lives
	-- on the hitbox, with a long reach, so buying works from anywhere on
	-- the plaza.
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Shape = Enum.PartType.Block
	hitbox.Size = data.size + Vector3.new(2, 2, 2)
	hitbox.CFrame = body.CFrame
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Parent = model
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 200
	clicker.Parent = hitbox
	return model, clicker, upright
end

function GameServer.maxSlotsFor(playerState)
	return GameServer.BASE_SLOTS + playerState.slotLevel * GameServer.SLOT_UPGRADE_ADDS
end

function GameServer.incomePerSecond(playerState)
	local total = 0
	for _, owned in ipairs(playerState.owned) do
		total += owned.data.income
	end
	return total * playerState.incomeMultiplier
end

function GameServer.slotCost(playerState)
	return math.floor(GameServer.SLOT_BASE_COST * (1.5 ^ playerState.slotLevel))
end

function GameServer.boostCost(playerState)
	return math.floor(GameServer.BOOST_BASE_COST * (2 ^ playerState.boostLevel))
end

function GameServer.rebirthCost(playerState)
	return GameServer.REBIRTH_BASE_EARNINGS * (playerState.rebirths + 1)
end

function GameServer.sendHud(player)
	local playerState = stateByPlayer[player]
	if not playerState then
		return
	end
	hudUpdate:FireClient(player, {
		cash = math.floor(playerState.cash),
		income = GameServer.incomePerSecond(playerState),
		owned = #playerState.owned,
		slots = GameServer.maxSlotsFor(playerState),
		rebirths = playerState.rebirths,
		lifetime = math.floor(playerState.lifetimeEarned),
		slotCost = GameServer.slotCost(playerState),
		boostCost = GameServer.boostCost(playerState),
		rebirthCost = GameServer.rebirthCost(playerState),
		canRebirth = playerState.lifetimeEarned >= GameServer.rebirthCost(playerState),
	})
end

function GameServer.sendHudToAll()
	for _, player in ipairs(Players:GetPlayers()) do
		GameServer.sendHud(player)
	end
end

-- Spawn one brainrot at the west end of the lane and let it walk east.
function GameServer.spawnBrainrotOnLane()
	if #walking >= GameServer.MAX_WALKING then
		return
	end
	local data = BrainrotData.rollCharacter()
	local model, clicker, upright = GameServer.buildBrainrotModel(data)
	local brainrot = {
		id = nextBrainrotId,
		data = data,
		model = model,
		upright = upright,
		x = WorldBuilder.LANE_START_X,
	}
	nextBrainrotId += 1
	-- Carry the upright rotation along: a plain CFrame.new here would
	-- reset the model to no rotation and lay cylinder bodies on their side.
	model:PivotTo(CFrame.new(brainrot.x, WorldBuilder.LANE_Y + 1 + data.size.Y / 2, WorldBuilder.LANE_Z) * upright)
	model.Parent = Workspace
	clicker.MouseClick:Connect(function(player)
		GameServer.buyBrainrot(player, brainrot.id)
	end)
	table.insert(walking, brainrot)
end

-- Sell a walking brainrot to a player: cash out, a free slot in, and the
-- character moves from the lane onto the player's base.
function GameServer.buyBrainrot(player, brainrotId)
	local playerState = stateByPlayer[player]
	if not playerState then
		return
	end
	local foundIndex = nil
	local brainrot = nil
	for i, entry in ipairs(walking) do
		if entry.id == brainrotId then
			foundIndex = i
			brainrot = entry
			break
		end
	end
	if not brainrot or not brainrot.model.Parent then
		return
	end
	if playerState.cash < brainrot.data.cost then
		return
	end
	if #playerState.owned >= GameServer.maxSlotsFor(playerState) then
		return
	end
	playerState.cash -= brainrot.data.cost
	table.remove(walking, foundIndex)
	local slotIndex = #playerState.owned + 1
	local slotPos = baseSlotsByIndex[playerState.baseIndex][slotIndex]
	brainrot.model:PivotTo(CFrame.new(slotPos + Vector3.new(0, brainrot.data.size.Y / 2, 0)) * brainrot.upright)
	brainrot.slotPos = slotPos
	-- The bob phase comes from the brainrot's id, so it is steady and
	-- varies from one brainrot to the next without a roll of the dice.
	brainrot.phase = (brainrot.id % 8) * math.pi / 4
	table.insert(playerState.owned, brainrot)
	syncCashValue(player, playerState)
	GameServer.sendHud(player)
end

function GameServer.richestPlayerWithBrainrots()
	local best = nil
	local bestCash = -1
	for _, player in ipairs(Players:GetPlayers()) do
		local playerState = stateByPlayer[player]
		if playerState and #playerState.owned > 0 and playerState.cash > bestCash then
			best = player
			bestCash = playerState.cash
		end
	end
	return best
end

function GameServer.mostValuableOwned(playerState)
	local best = nil
	local bestIncome = -1
	for _, owned in ipairs(playerState.owned) do
		if owned.data.income > bestIncome then
			best = owned
			bestIncome = owned.data.income
		end
	end
	return best
end

-- One raid: warn everyone, then send the Snatcher after the richest
-- player's most valuable brainrot.
function GameServer.runRaid()
	if Thief.isActive() then
		return
	end
	local target = GameServer.richestPlayerWithBrainrots()
	if not target then
		return
	end
	local playerState = stateByPlayer[target]
	local victim = GameServer.mostValuableOwned(playerState)
	if not victim then
		return
	end
	raidWarning:FireAllClients("THE SNEAKY SNATCHER IS COMING FOR " .. target.Name .. "'s " .. victim.data.name .. "! CLICK HIM TO BONK HIM AWAY!")
	task.wait(GameServer.RAID_WARNING_SECONDS)
	Thief.startRaid(target, victim, function(stolenPlayer, stolen)
		-- He got away with it: the brainrot is gone for good.
		local stolenState = stateByPlayer[stolenPlayer]
		if stolenState then
			for i, owned in ipairs(stolenState.owned) do
				if owned == stolen then
					table.remove(stolenState.owned, i)
					break
				end
			end
			GameServer.sendHud(stolenPlayer)
		end
		if stolen.model then
			stolen.model:Destroy()
		end
		raidWarning:FireAllClients("THE SNATCHER STOLE " .. stolen.data.name .. " FROM " .. stolenPlayer.Name .. "!")
	end, function(fledPlayer, bonus)
		-- Bonked away three times: the target keeps their brainrot and
		-- earns a bonus for chasing him off.
		local fledState = stateByPlayer[fledPlayer]
		if fledState then
			fledState.cash += bonus
			syncCashValue(fledPlayer, fledState)
			GameServer.sendHud(fledPlayer)
		end
		raidWarning:FireAllClients(fledPlayer.Name .. " BONKED THE SNATCHER AWAY! +" .. BrainrotData.moneyText(bonus))
	end)
end

-- A rebirth wipes the player's cash and brainrots and doubles their income.
function GameServer.rebirthPlayer(player)
	local playerState = stateByPlayer[player]
	if not playerState then
		return
	end
	if playerState.lifetimeEarned < GameServer.rebirthCost(playerState) then
		return
	end
	for _, owned in ipairs(playerState.owned) do
		if owned.model then
			owned.model:Destroy()
		end
	end
	playerState.owned = {}
	playerState.cash = 0
	playerState.rebirths += 1
	playerState.incomeMultiplier = 2 ^ playerState.rebirths
	-- A golden trim marks a reborn base.
	for _, trimName in ipairs({ "BaseTrim" .. playerState.baseIndex, "BaseTrimBack" .. playerState.baseIndex }) do
		local trim = Workspace:FindFirstChild(trimName)
		if trim then
			trim.Color = Color3.fromRGB(255, 210, 40)
		end
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = 0
		leaderstats.Rebirths.Value = playerState.rebirths
	end
	GameServer.sendHud(player)
end

function GameServer.buyUpgrade(player, kind)
	local playerState = stateByPlayer[player]
	if not playerState then
		return
	end
	if kind == "slots" then
		if playerState.slotLevel >= GameServer.MAX_SLOT_LEVEL then
			return
		end
		local cost = GameServer.slotCost(playerState)
		if playerState.cash < cost then
			return
		end
		playerState.cash -= cost
		playerState.slotLevel += 1
		-- Light up the newly unlocked slot pads.
		local baseIndex = playerState.baseIndex
		local firstNew = GameServer.BASE_SLOTS + (playerState.slotLevel - 1) * GameServer.SLOT_UPGRADE_ADDS + 1
		local lastNew = GameServer.BASE_SLOTS + playerState.slotLevel * GameServer.SLOT_UPGRADE_ADDS
		for i = firstNew, lastNew do
			local pad = Workspace:FindFirstChild("SlotPad" .. baseIndex .. "_" .. i)
			if pad then
				pad.Transparency = 0.6
			end
		end
	elseif kind == "boost" then
		if playerState.boostLevel >= GameServer.MAX_BOOST_LEVEL then
			return
		end
		local cost = GameServer.boostCost(playerState)
		if playerState.cash < cost then
			return
		end
		playerState.cash -= cost
		playerState.boostLevel += 1
		playerState.incomeMultiplier = (2 ^ playerState.rebirths) * (1 + 0.25 * playerState.boostLevel)
	end
	syncCashValue(player, playerState)
	GameServer.sendHud(player)
end

function GameServer.claimBase(player)
	for index = 1, #WorldBuilder.BASE_CENTERS do
		if not baseOwnerByIndex[index] then
			baseOwnerByIndex[index] = player
			local sign = Workspace:FindFirstChild("BaseSign" .. index)
			if sign then
				local gui = sign:FindFirstChildOfClass("SurfaceGui")
				if gui then
					local label = gui:FindFirstChildOfClass("TextLabel")
					if label then
						label.Text = player.Name .. "'s BASE"
					end
				end
			end
			return index
		end
	end
	return 1
end

function GameServer.onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = GameServer.STARTING_CASH
	cashValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
	local baseIndex = GameServer.claimBase(player)
	stateByPlayer[player] = {
		cash = GameServer.STARTING_CASH,
		lifetimeEarned = 0,
		rebirths = 0,
		incomeMultiplier = 1,
		slotLevel = 0,
		boostLevel = 0,
		owned = {},
		baseIndex = baseIndex,
	}
	player:LoadCharacter()
	GameServer.sendHud(player)
end

function GameServer.onPlayerRemoving(player)
	local playerState = stateByPlayer[player]
	if playerState then
		for _, owned in ipairs(playerState.owned) do
			if owned.model then
				owned.model:Destroy()
			end
		end
		baseOwnerByIndex[playerState.baseIndex] = nil
		stateByPlayer[player] = nil
	end
end

-- The debug hook the tour calls to jump straight to a raid.
function GameServer.startRaidNow(_arg)
	GameServer.runRaid()
end

function GameServer.start()
	WorldBuilder.buildAll()
	for index, center in ipairs(WorldBuilder.BASE_CENTERS) do
		baseSlotsByIndex[index] = WorldBuilder.buildPlayerBase(index, center, BASE_COLORS[index])
	end
	-- The conveyor keeps sending brainrots down the lane.
	task.spawn(function()
		while true do
			GameServer.spawnBrainrotOnLane()
			task.wait(GameServer.SPAWN_EVERY_SECONDS)
		end
	end)
	-- Every second, every owned brainrot pays its owner.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local playerState = stateByPlayer[player]
				if playerState then
					local earned = GameServer.incomePerSecond(playerState)
					playerState.cash += earned
					playerState.lifetimeEarned += earned
					syncCashValue(player, playerState)
				end
			end
			GameServer.sendHudToAll()
		end
	end)
	-- Raids on a timer, the first one a little sooner so players meet the
	-- Snatcher before they get too comfortable.
	task.spawn(function()
		task.wait(GameServer.FIRST_RAID_SECONDS)
		while true do
			GameServer.runRaid()
			task.wait(GameServer.RAID_EVERY_SECONDS)
		end
	end)
	-- One heartbeat moves the lane walkers, bobs the owned brainrots and
	-- walks the Snatcher toward his target.
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for i = #walking, 1, -1 do
			local entry = walking[i]
			if not entry.model.Parent then
				table.remove(walking, i)
			else
				entry.x += GameServer.WALK_SPEED * dt
				if entry.x >= WorldBuilder.LANE_END_X then
					entry.model:Destroy()
					table.remove(walking, i)
				else
					entry.model:PivotTo(CFrame.new(entry.x, WorldBuilder.LANE_Y + 1 + entry.data.size.Y / 2, WorldBuilder.LANE_Z) * entry.upright)
				end
			end
		end
		for _, playerState in pairs(stateByPlayer) do
			for _, owned in ipairs(playerState.owned) do
				if owned.model and owned.model.Parent and owned.slotPos then
					local bob = math.sin(now * 2 + (owned.phase or 0)) * 0.3
					owned.model:PivotTo(CFrame.new(owned.slotPos + Vector3.new(0, owned.data.size.Y / 2 + bob, 0)) * owned.upright)
				end
			end
		end
		Thief.step(dt)
	end)
	rebirthRequest.OnServerEvent:Connect(function(player)
		GameServer.rebirthPlayer(player)
	end)
	upgradeRequest.OnServerEvent:Connect(function(player, kind)
		GameServer.buyUpgrade(player, kind)
	end)
	Players.PlayerAdded:Connect(GameServer.onPlayerAdded)
	Players.PlayerRemoving:Connect(GameServer.onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		GameServer.onPlayerAdded(player)
	end
end

return GameServer
