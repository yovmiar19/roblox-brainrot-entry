-- Brainrot Lane, server side: one module runs the whole game.
-- Brainrots stroll down the lane, a player holds E on one to buy
-- it, it parks on their base and pays cash every second, and a thief
-- drops in on a timer to steal one unless players bonk him away.
--
-- Kept plain on purpose: every body is a ball or an axis-aligned
-- block, nothing ever turns, and every move is only a position
-- change. The world is built tall and bright so nobody can miss it:
-- the plaza is a thick green slab, the lane a thick bright strip,
-- and two glowing yellow beacon pillars mark the spawn and the lane
-- centre. The spawn itself needs no script: the SpawnLocation sits
-- in the place file, the engine loads the character on its own
-- (CharacterAutoLoads), and the server puts every character beside
-- the lane the moment it appears, so nobody can end up stranded on
-- the bare baseplate far from the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameServer = {}

-- Tuning ------------------------------------------------------------------

local LANE_Z = -20
local LANE_X_MIN = -70
local LANE_X_MAX = 75
local SPAWN_POS = Vector3.new(0, 3, -6)
local WALK_SPEED = 6
local THIEF_SPEED = 8
local START_CASH = 100
local BONK_BONUS = 100
local RAID_FIRST = 60
local RAID_EVERY = 90
local MAX_WALKERS = 4
local SPAWN_EVERY = 2.5
local BOOST_COST = 2500
local BOOST_STEP = 0.25
local BOOST_MAX = 4
local BASE_X = { -60, -20, 20, 60 }

-- The cast: balls and blocks only, no cylinders, no turning. --------------
local CAST = {
	{ name = "Noodle Ned", shape = Enum.PartType.Ball, size = 4, color = Color3.fromRGB(255, 220, 80), income = 5, rarity = "Common", price = 50 },
	{ name = "Captain Pickle", shape = Enum.PartType.Block, size = 4, color = Color3.fromRGB(80, 200, 90), income = 12, rarity = "Common", price = 120 },
	{ name = "Professor Toast", shape = Enum.PartType.Block, size = 4, color = Color3.fromRGB(220, 180, 120), income = 30, rarity = "Rare", price = 300 },
	{ name = "DJ Llama Drama", shape = Enum.PartType.Ball, size = 4, color = Color3.fromRGB(255, 120, 200), income = 70, rarity = "Epic", price = 700 },
	{ name = "Chairman Wobble", shape = Enum.PartType.Ball, size = 5, color = Color3.fromRGB(160, 100, 230), income = 150, rarity = "Legendary", price = 1500 },
	{ name = "Quantum Toaster 3000", shape = Enum.PartType.Block, size = 5, color = Color3.fromRGB(200, 200, 210), income = 400, rarity = "Mythic", price = 4000 },
}

local THIEF_DEF = { name = "Sneaky Snatcher", shape = Enum.PartType.Ball, size = 5, color = Color3.fromRGB(120, 20, 20), income = 0, rarity = "THIEF", price = 0, tag = "Bonk me 3x!" }

-- State ---------------------------------------------------------------------

local state = {
	walkers = {},
	players = {},
	bases = {},
	thief = nil,
	raidTimer = RAID_FIRST,
	spawnTimer = 0,
	incomeTimer = 0,
	statusTimer = 0,
	time = 0,
}

-- The sign's live status line, filled in by buildWorld. ----------------------
local signStatus = nil

-- Remotes ---------------------------------------------------------------------

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local Remotes = {
	HudUpdate = makeRemote("HudUpdate"),
	RaidWarning = makeRemote("RaidWarning"),
	UpgradeRequest = makeRemote("UpgradeRequest"),
	TeleportRequest = makeRemote("TeleportRequest"),
}

-- Small builders --------------------------------------------------------------

local function makePart(name, size, position, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = true
	part.Parent = Workspace
	return part
end

-- Name tags that are honest about distance: the tag hangs from an
-- attachment over the body and its size is in studs, so it shrinks
-- as the player walks away instead of looking the same from anywhere.
local function makeTag(body, line1, line2)
	local anchor = Instance.new("Attachment")
	anchor.Name = "TagAnchor"
	anchor.Position = Vector3.new(0, body.Size.Y / 2 + 1.2, 0)
	anchor.Parent = body

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Adornee = anchor
	tag.Size = UDim2.fromScale(8, 2.5)
	tag.MaxDistance = 150
	tag.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Name = "TagText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = line1 .. "\n" .. line2
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 14
	label.Parent = tag
	tag.Parent = body
	return tag
end

-- A brainrot: body, two eyes on the +X face (the way it walks), a
-- small tag, a big invisible hitbox, and two ways to buy it — hold E
-- on the ProximityPrompt (the main way) or click it (the backup).
-- All parts sit at plain offsets, so moving the model is only ever a
-- position change and the eyes can never end up underneath it.
local function buildBrainrot(def, position, actionText)
	local model = Instance.new("Model")
	model.Name = def.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = def.shape
	body.Size = Vector3.new(def.size, def.size, def.size)
	body.Position = position
	body.Color = def.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	model.PrimaryPart = body

	local half = def.size / 2
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Block
		eye.Size = Vector3.new(0.4, 0.8, 0.8)
		eye.Position = position + Vector3.new(half + 0.1, 0.5, side * 0.8)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model

		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Block
		pupil.Size = Vector3.new(0.2, 0.4, 0.4)
		pupil.Position = position + Vector3.new(half + 0.35, 0.5, side * 0.8)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	if def.tag then
		makeTag(body, def.name, def.tag)
	else
		makeTag(body, def.name, def.rarity .. " - $" .. def.income .. "/s")
	end

	local hit = Instance.new("Part")
	hit.Name = "Hitbox"
	hit.Shape = Enum.PartType.Block
	hit.Size = Vector3.new(def.size + 2, def.size + 2, def.size + 2)
	hit.Position = position
	hit.Transparency = 1
	hit.Anchored = true
	hit.CanCollide = false
	hit.Parent = model

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 200
	click.Parent = hit

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = hit

	model.Parent = Workspace
	return model, click, prompt
end

-- World -----------------------------------------------------------------------
-- The SpawnLocation is NOT built here: it lives in
-- default.project.json, so it exists in the place before any script
-- runs and can never fail to appear because a script errored.
-- The plaza and the lane are thick slabs that sit proud of the
-- baseplate (plaza top y=2, lane top y=3), and two tall glowing
-- beacon pillars — one beside the spawn, one on the lane centre —
-- make the game visible from anywhere in the place. The spawn
-- beacon stands a few studs east of the spawn point so the player
-- never spawns inside it; both beacons are non-collidable.
local function buildWorld()
	makePart("PlazaFloor", Vector3.new(180, 2, 120), Vector3.new(0, 1, 10), Color3.fromRGB(90, 180, 90), Enum.Material.Grass)
	makePart("ConveyorLane", Vector3.new(150, 2, 8), Vector3.new(0, 2, LANE_Z), Color3.fromRGB(90, 90, 150), Enum.Material.Metal)
	makePart("RailNorth", Vector3.new(150, 0.5, 1), Vector3.new(0, 3.25, -24), Color3.fromRGB(255, 220, 0), Enum.Material.Neon)
	makePart("RailSouth", Vector3.new(150, 0.5, 1), Vector3.new(0, 3.25, -16), Color3.fromRGB(255, 220, 0), Enum.Material.Neon)

	local spawnBeacon = makePart("BeaconSpawn", Vector3.new(2, 30, 2), Vector3.new(4, 15, -6), Color3.fromRGB(255, 220, 0), Enum.Material.Neon)
	spawnBeacon.CanCollide = false
	local laneBeacon = makePart("BeaconLane", Vector3.new(2, 30, 2), Vector3.new(0, 15, LANE_Z), Color3.fromRGB(255, 220, 0), Enum.Material.Neon)
	laneBeacon.CanCollide = false

	for _, bx in ipairs(BASE_X) do
		makePart("Base", Vector3.new(24, 1, 20), Vector3.new(bx, 0.5, 32), Color3.fromRGB(180, 180, 190), Enum.Material.SmoothPlastic)
		local base = { x = bx, slots = {} }
		for _, sx in ipairs({ -7, 0, 7 }) do
			for _, sz in ipairs({ 27, 37 }) do
				local pad = makePart("SlotPad", Vector3.new(5, 0.4, 5), Vector3.new(bx + sx, 1.2, sz), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
				pad.Transparency = 0.6
				table.insert(base.slots, { x = bx + sx, z = sz, taken = nil })
			end
		end
		table.insert(state.bases, base)
	end

	for i = 1, 8 do
		local angle = (i - 1) * math.pi / 4
		local tx = math.cos(angle) * 82
		local tz = 10 + math.sin(angle) * 54
		makePart("TreeTrunk", Vector3.new(2, 8, 2), Vector3.new(tx, 5, tz), Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves"
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(9, 9, 9)
		leaves.Position = Vector3.new(tx, 12, tz)
		leaves.Color = Color3.fromRGB(40, 160, 60)
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Parent = Workspace
	end

	local sign = makePart("LaneSign", Vector3.new(40, 10, 2), Vector3.new(0, 14, -52), Color3.fromRGB(40, 40, 70), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	local title = Instance.new("TextLabel")
	title.Name = "SignText"
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "BRAINROT LANE"
	title.TextColor3 = Color3.fromRGB(255, 220, 0)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 48
	title.Parent = gui
	local status = Instance.new("TextLabel")
	status.Name = "SignStatus"
	status.Size = UDim2.new(1, 0, 0.4, 0)
	status.Position = UDim2.new(0, 0, 0.6, 0)
	status.BackgroundTransparency = 1
	status.Text = "SERVER STARTING..."
	status.TextColor3 = Color3.fromRGB(120, 255, 120)
	status.Font = Enum.Font.SourceSansBold
	status.TextSize = 20
	status.Parent = gui
	gui.Parent = sign
	signStatus = status
end

-- Players, cash and the HUD -----------------------------------------------------

local function syncCash(player)
	local data = state.players[player]
	if data and data.cashValue then
		data.cashValue.Value = math.floor(data.cash)
	end
end

local function incomeRate(data)
	local rate = 0
	for _, owned in ipairs(data.owned) do
		rate += owned.def.income
	end
	return rate * (1 + data.boost * BOOST_STEP)
end

local function sendHud(player)
	local data = state.players[player]
	if not data then
		return
	end
	Remotes.HudUpdate:FireClient(player, math.floor(data.cash), math.floor(incomeRate(data) + 0.5), #data.owned, data.boost)
end

local function claimBase()
	local best = nil
	local bestFree = -1
	for _, base in ipairs(state.bases) do
		local free = 0
		for _, slot in ipairs(base.slots) do
			if not slot.taken then
				free += 1
			end
		end
		if free > bestFree then
			best = base
			bestFree = free
		end
	end
	return best
end

-- Put a player's character right beside the lane, facing it. The
-- default CFrame faces -Z, and the lane sits at -Z from the spawn,
-- so no rotation is needed at all.
local function teleportToLane(player)
	local character = player.Character
	if not character then
		return false
	end
	character:PivotTo(CFrame.new(SPAWN_POS))
	return true
end

local function onCharacterAdded(player, character)
	teleportToLane(player)
	local root = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
	if root then
		local p = root.Position
		print("Brainrot Lane: " .. player.Name .. " spawned at (" .. math.floor(p.X + 0.5) .. ", " .. math.floor(p.Y + 0.5) .. ", " .. math.floor(p.Z + 0.5) .. ")")
	end
end

local function onPlayerAdded(player)
	local data = { cash = START_CASH, boost = 0, base = claimBase(), owned = {} }
	state.players[player] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = START_CASH
	cashValue.Parent = leaderstats
	data.cashValue = cashValue

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		teleportToLane(player)
	end
	print("Brainrot Lane: " .. player.Name .. " joined with $" .. START_CASH)
	sendHud(player)
end

local function onTeleportRequest(player)
	if teleportToLane(player) then
		print("Brainrot Lane: teleported " .. player.Name .. " to the lane")
	end
end

-- Buying ------------------------------------------------------------------------

local function nextFreeSlot(data)
	if not data.base then
		return nil
	end
	for _, slot in ipairs(data.base.slots) do
		if not slot.taken then
			return slot
		end
	end
	return nil
end

function GameServer.buyBrainrot(player, walker)
	local data = state.players[player]
	if not data or not walker or walker.owned then
		return false
	end
	if data.cash < walker.def.price then
		return false
	end
	local slot = nextFreeSlot(data)
	if not slot then
		return false
	end
	data.cash -= walker.def.price
	walker.owned = true
	for i, w in ipairs(state.walkers) do
		if w == walker then
			table.remove(state.walkers, i)
			break
		end
	end
	if walker.click then
		walker.click.MaxActivationDistance = 0
	end
	if walker.prompt then
		walker.prompt.Enabled = false
	end
	local pos = Vector3.new(slot.x, 1 + walker.def.size / 2, slot.z)
	walker.model:PivotTo(CFrame.new(pos))
	walker.slot = slot
	slot.taken = walker
	table.insert(data.owned, walker)
	syncCash(player)
	sendHud(player)
	return true
end

-- Walking brainrots ---------------------------------------------------------------
-- Walkers stand on the lane, whose top is now y=3, so their body
-- centre sits at 3 + size/2.

local function spawnWalker()
	local def = CAST[math.random(1, #CAST)]
	local y = 3 + def.size / 2
	local model, click, prompt = buildBrainrot(def, Vector3.new(LANE_X_MIN, y, LANE_Z), "Buy $" .. def.price)
	local walker = { def = def, model = model, click = click, prompt = prompt, x = LANE_X_MIN, y = y, phase = math.random() * math.pi * 2, owned = false }
	click.MouseClick:Connect(function(player)
		GameServer.buyBrainrot(player, walker)
	end)
	prompt.Triggered:Connect(function(player)
		GameServer.buyBrainrot(player, walker)
	end)
	table.insert(state.walkers, walker)
	print("Brainrot Lane: " .. def.name .. " joined the lane (" .. #state.walkers .. " walking)")
	return walker
end

-- The thief -----------------------------------------------------------------------

local endRaid
local stealMostValuable

local function startRaid()
	if state.thief then
		return
	end
	local y = 3 + THIEF_DEF.size / 2
	local model, click, prompt = buildBrainrot(THIEF_DEF, Vector3.new(LANE_X_MAX, y, LANE_Z), "Bonk!")
	state.thief = { model = model, click = click, prompt = prompt, x = LANE_X_MAX, y = y, hits = 0 }
	click.MouseClick:Connect(function(player)
		GameServer.bonkThief(player)
	end)
	prompt.Triggered:Connect(function(player)
		GameServer.bonkThief(player)
	end)
	Remotes.RaidWarning:FireAllClients("SNEAKY SNATCHER IS COMING! Hold E on him 3 times to bonk him!")
	print("Brainrot Lane: raid started, the Snatcher is on the lane")
end

function GameServer.bonkThief(player)
	local thief = state.thief
	if not thief then
		return
	end
	thief.hits += 1
	if thief.hits >= 3 then
		local data = state.players[player]
		if data then
			data.cash += BONK_BONUS
			syncCash(player)
			sendHud(player)
		end
		endRaid("Bonked! " .. player.Name .. " earned $100!")
	end
end

stealMostValuable = function()
	local victim = nil
	local best = nil
	for player, data in pairs(state.players) do
		for _, owned in ipairs(data.owned) do
			if not best or owned.def.income > best.def.income then
				victim = player
				best = owned
			end
		end
	end
	if best then
		local data = state.players[victim]
		for i, owned in ipairs(data.owned) do
			if owned == best then
				table.remove(data.owned, i)
				break
			end
		end
		if best.slot then
			best.slot.taken = nil
		end
		best.model:Destroy()
		sendHud(victim)
	end
end

endRaid = function(message)
	if state.thief then
		state.thief.model:Destroy()
		state.thief = nil
	end
	Remotes.RaidWarning:FireAllClients(message)
end

-- The one upgrade ------------------------------------------------------------------

local function onUpgradeRequest(player)
	local data = state.players[player]
	if not data or data.boost >= BOOST_MAX or data.cash < BOOST_COST then
		return
	end
	data.cash -= BOOST_COST
	data.boost += 1
	syncCash(player)
	sendHud(player)
end

-- The tick: one Heartbeat drives everything, so there are no threads
-- to stall and no timing to get out of step. ----------------------------------------
local function onHeartbeat(dt)
	state.time += dt

	state.spawnTimer -= dt
	if state.spawnTimer <= 0 then
		state.spawnTimer = SPAWN_EVERY
		if #state.walkers < MAX_WALKERS then
			spawnWalker()
		end
	end

	for i = #state.walkers, 1, -1 do
		local walker = state.walkers[i]
		walker.x += WALK_SPEED * dt
		local bob = math.sin(state.time * 3 + walker.phase) * 0.15
		walker.model:PivotTo(CFrame.new(walker.x, walker.y + bob, LANE_Z))
		if walker.x > LANE_X_MAX then
			walker.model:Destroy()
			table.remove(state.walkers, i)
		end
	end

	if state.thief then
		local thief = state.thief
		thief.x -= THIEF_SPEED * dt
		thief.model:PivotTo(CFrame.new(thief.x, thief.y, LANE_Z))
		if thief.x < LANE_X_MIN then
			stealMostValuable()
			endRaid("The Snatcher got away with a brainrot!")
		end
	else
		state.raidTimer -= dt
		if state.raidTimer <= 0 then
			state.raidTimer = RAID_EVERY
			startRaid()
		end
	end

	state.incomeTimer += dt
	while state.incomeTimer >= 1 do
		state.incomeTimer -= 1
		for player, data in pairs(state.players) do
			local rate = incomeRate(data)
			if rate > 0 then
				data.cash += rate
				syncCash(player)
				sendHud(player)
			end
		end
	end

	state.statusTimer += dt
	if state.statusTimer >= 1 and signStatus then
		state.statusTimer = 0
		signStatus.Text = "SERVER ALIVE  •  " .. #state.walkers .. " walkers  •  " .. math.floor(state.time) .. "s"
	end
end

-- Boot ----------------------------------------------------------------------------------
function GameServer.start()
	print("Brainrot Lane: server starting")
	buildWorld()
	print("Brainrot Lane: world built — plaza top y=2, lane top y=3, 2 rails, 2 beacons, 4 bases, 24 pads, sign")
	print("Brainrot Lane: spawn is static in the place file at (0, 3, -6), CharacterAutoLoads on")
	Remotes.UpgradeRequest.OnServerEvent:Connect(onUpgradeRequest)
	Remotes.TeleportRequest.OnServerEvent:Connect(onTeleportRequest)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	RunService.Heartbeat:Connect(onHeartbeat)
	print("Brainrot Lane: live — walkers spawning, buy with E")
end

-- Called by TOUR.json so reviewers can jump straight to a raid.
function GameServer.startRaidNow()
	startRaid()
end

-- Test hooks: the headless mock test drives the game through these.
GameServer._debug = {
	state = state,
	spawnWalker = spawnWalker,
	onHeartbeat = onHeartbeat,
	onPlayerAdded = onPlayerAdded,
	teleportToLane = teleportToLane,
}

return GameServer
