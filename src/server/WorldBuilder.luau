-- WorldBuilder: builds the whole 3D world of Brainrot Bazaar out of parts.
-- Everything is made in code, so the place file stays small and the world
-- is exactly what this script says: a market plaza, a conveyor lane where
-- the brainrots march by, four player bases, stalls, trees and lamps.

local WorldBuilder = {}

local Workspace = game:GetService("Workspace")

-- Where the game happens.
WorldBuilder.LANE_START_X = -70
WorldBuilder.LANE_END_X = 70
WorldBuilder.LANE_Z = -20
WorldBuilder.LANE_Y = 1
WorldBuilder.BASE_CENTERS = {
	Vector3.new(-45, 0, 32),
	Vector3.new(-15, 0, 32),
	Vector3.new(15, 0, 32),
	Vector3.new(45, 0, 32),
}
WorldBuilder.BASE_SIZE = Vector3.new(24, 1, 20)
WorldBuilder.SPAWN_POINT = Vector3.new(0, 3, 58)

local function makePart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = Workspace
	return part
end

local function makeLabel(parent, text, face, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Top
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Parent = gui
	return label
end

function WorldBuilder.buildPlaza()
	-- A green plaza floor over the grey baseplate.
	local plaza = makePart("PlazaFloor", Vector3.new(180, 1, 120), Vector3.new(0, 0.5, 10), Color3.fromRGB(90, 180, 90), Enum.Material.Grass)
	plaza.CanCollide = true
	-- A stone path from the spawn to the lane.
	makePart("MainPath", Vector3.new(10, 0.2, 70), Vector3.new(0, 1.1, 22), Color3.fromRGB(200, 190, 170), Enum.Material.Slate)
	-- A ring of flowers around the plaza edge.
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local x = math.cos(angle) * 80
		local z = 10 + math.sin(angle) * 52
		makePart("Flower", Vector3.new(1.5, 1.5, 1.5), Vector3.new(x, 1.8, z), Color3.fromRGB(255, 120, 180), Enum.Material.Neon)
	end
end

function WorldBuilder.buildConveyorLane()
	-- The dark lane the brainrots walk along.
	makePart("ConveyorLane", Vector3.new(150, 1, 8), Vector3.new(0, WorldBuilder.LANE_Y, WorldBuilder.LANE_Z), Color3.fromRGB(50, 50, 70), Enum.Material.Metal)
	-- Bright yellow rails on both sides so the lane reads from far away.
	makePart("LaneRailNorth", Vector3.new(150, 1.5, 1), Vector3.new(0, WorldBuilder.LANE_Y + 0.5, WorldBuilder.LANE_Z - 4.5), Color3.fromRGB(255, 210, 40), Enum.Material.Neon)
	makePart("LaneRailSouth", Vector3.new(150, 1.5, 1), Vector3.new(0, WorldBuilder.LANE_Y + 0.5, WorldBuilder.LANE_Z + 4.5), Color3.fromRGB(255, 210, 40), Enum.Material.Neon)
	-- A spawn gate at the west end and an exit gate at the east end.
	local gateIn = makePart("SpawnGate", Vector3.new(2, 10, 10), Vector3.new(WorldBuilder.LANE_START_X, 6, WorldBuilder.LANE_Z), Color3.fromRGB(255, 120, 60), Enum.Material.Neon)
	gateIn.CanCollide = false
	local gateOut = makePart("ExitGate", Vector3.new(2, 10, 10), Vector3.new(WorldBuilder.LANE_END_X, 6, WorldBuilder.LANE_Z), Color3.fromRGB(120, 220, 255), Enum.Material.Neon)
	gateOut.CanCollide = false
	makeLabel(gateIn, "BRAINROTS IN", Enum.NormalId.Right, Color3.fromRGB(255, 255, 255))
end

-- One player base: a platform, a sign with the owner's name, and slot pads.
-- Returns the list of slot positions where bought brainrots stand.
function WorldBuilder.buildPlayerBase(index, center, accentColor)
	local platform = makePart("BasePlatform" .. index, WorldBuilder.BASE_SIZE, Vector3.new(center.X, 1, center.Z), Color3.fromRGB(210, 200, 180), Enum.Material.Slate)
	platform.Name = "BasePlatform" .. index
	-- A coloured trim so each base is easy to tell apart.
	makePart("BaseTrim" .. index, Vector3.new(WorldBuilder.BASE_SIZE.X + 1, 0.5, 1), Vector3.new(center.X, 1.4, center.Z - WorldBuilder.BASE_SIZE.Z / 2), accentColor, Enum.Material.Neon)
	makePart("BaseTrimBack" .. index, Vector3.new(WorldBuilder.BASE_SIZE.X + 1, 0.5, 1), Vector3.new(center.X, 1.4, center.Z + WorldBuilder.BASE_SIZE.Z / 2), accentColor, Enum.Material.Neon)
	-- The sign post at the back of the base.
	local post = makePart("BaseSign" .. index, Vector3.new(10, 6, 1), Vector3.new(center.X, 6, center.Z + WorldBuilder.BASE_SIZE.Z / 2 - 1), Color3.fromRGB(60, 60, 80), Enum.Material.Wood)
	makeLabel(post, "BASE " .. index, Enum.NormalId.Back, Color3.fromRGB(255, 255, 255))
	-- Six slot pads in two rows of three, plus two extra rows the player
	-- unlocks with the slot upgrade (nine, then twelve slots in all).
	local slots = {}
	for row = 1, 4 do
		for col = 1, 3 do
			local x = center.X + (col - 2) * 7
			local z = center.Z + (row - 2.5) * 6
			local pad = makePart("SlotPad" .. index .. "_" .. #slots + 1, Vector3.new(5, 0.4, 5), Vector3.new(x, 1.7, z), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			-- The locked rows start dimmer until the player buys the upgrade.
			pad.Transparency = row <= 2 and 0.6 or 0.85
			table.insert(slots, Vector3.new(x, 2, z))
		end
	end
	return slots
end

function WorldBuilder.buildDecor()
	-- Market stalls along the north edge.
	for i = 1, 3 do
		local x = -50 + (i - 1) * 50
		makePart("StallCounter" .. i, Vector3.new(12, 3, 6), Vector3.new(x, 2.5, -48), Color3.fromRGB(180, 120, 60), Enum.Material.Wood)
		makePart("StallRoof" .. i, Vector3.new(14, 1, 9), Vector3.new(x, 7, -48), Color3.fromRGB(255, 90, 90), Enum.Material.Fabric)
	end
	-- Trees scattered around the plaza.
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2 + 0.4
		local x = math.cos(angle) * 82
		local z = 10 + math.sin(angle) * 54
		local trunk = makePart("TreeTrunk" .. i, Vector3.new(2, 8, 2), Vector3.new(x, 5, z), Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
		trunk.CanCollide = false
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves" .. i
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(9, 9, 9)
		leaves.Position = Vector3.new(x, 12, z)
		leaves.Color = Color3.fromRGB(40, 160, 60)
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Parent = Workspace
	end
	-- Street lamps along the conveyor lane.
	for i = 1, 5 do
		local x = -56 + (i - 1) * 28
		makePart("LampPost" .. i, Vector3.new(1, 9, 1), Vector3.new(x, 5.5, WorldBuilder.LANE_Z - 8), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		makePart("LampLight" .. i, Vector3.new(3, 2, 3), Vector3.new(x, 10.5, WorldBuilder.LANE_Z - 8), Color3.fromRGB(255, 240, 150), Enum.Material.Neon)
	end
	-- The big bazaar sign over the north side.
	local sign = makePart("BazaarSign", Vector3.new(40, 10, 2), Vector3.new(0, 14, -52), Color3.fromRGB(40, 40, 70), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "BRAINROT BAZAAR"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.Parent = gui
	-- A few clouds drifting high above.
	for i = 1, 4 do
		local cloud = Instance.new("Part")
		cloud.Name = "Cloud" .. i
		cloud.Shape = Enum.PartType.Ball
		cloud.Size = Vector3.new(18, 6, 10)
		cloud.Position = Vector3.new(-60 + (i - 1) * 40, 40, -30 + (i % 2) * 40)
		cloud.Color = Color3.fromRGB(255, 255, 255)
		cloud.Material = Enum.Material.SmoothPlastic
		cloud.Anchored = true
		cloud.CanCollide = false
		cloud.Parent = Workspace
	end
end

function WorldBuilder.buildSpawn()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = WorldBuilder.SPAWN_POINT
	spawn.Color = Color3.fromRGB(120, 220, 255)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = Workspace
end

function WorldBuilder.buildAll()
	WorldBuilder.buildPlaza()
	WorldBuilder.buildConveyorLane()
	WorldBuilder.buildDecor()
	WorldBuilder.buildSpawn()
end

return WorldBuilder
