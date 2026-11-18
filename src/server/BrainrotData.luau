-- BrainrotData: the cast of Brainrot Bazaar, and nothing else.
-- Each character is an original absurd invention of this game: a name, a
-- look, a rarity, a price and what it pays every second. No character,
-- name or asset here is copied from any other game.

local BrainrotData = {}

-- How common each rarity is when the lane rolls a new brainrot, and the
-- colours the name tags use for it.
BrainrotData.RARITIES = {
	Common = { weight = 45, color = Color3.fromRGB(120, 200, 120), labelColor = Color3.fromRGB(220, 255, 220) },
	Uncommon = { weight = 25, color = Color3.fromRGB(100, 170, 255), labelColor = Color3.fromRGB(200, 225, 255) },
	Rare = { weight = 18, color = Color3.fromRGB(180, 120, 255), labelColor = Color3.fromRGB(230, 210, 255) },
	Epic = { weight = 8, color = Color3.fromRGB(255, 120, 220), labelColor = Color3.fromRGB(255, 210, 240) },
	Legendary = { weight = 3, color = Color3.fromRGB(255, 200, 60), labelColor = Color3.fromRGB(255, 235, 180) },
	Mythic = { weight = 1, color = Color3.fromRGB(255, 80, 80), labelColor = Color3.fromRGB(255, 200, 200) },
}

-- The nine characters, cheapest first. id, name, rarity, cost, income per
-- second, body colour, body shape, body size, and a one-line joke.
BrainrotData.CATALOGUE = {
	{
		id = "noodle_ned",
		name = "Noodle Ned",
		rarity = "Common",
		cost = 50,
		income = 5,
		color = Color3.fromRGB(255, 160, 60),
		shape = Enum.PartType.Ball,
		size = Vector3.new(3, 3, 3),
		blurb = "A noodle cup that learned to walk.",
	},
	{
		id = "chairman_wobble",
		name = "Chairman Wobble",
		rarity = "Common",
		cost = 120,
		income = 10,
		color = Color3.fromRGB(90, 90, 110),
		shape = Enum.PartType.Block,
		size = Vector3.new(3, 3.5, 3),
		blurb = "An office chair with big dreams.",
	},
	{
		id = "captain_pickle",
		name = "Captain Pickle",
		rarity = "Uncommon",
		cost = 300,
		income = 22,
		color = Color3.fromRGB(80, 200, 90),
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(3, 4, 3),
		blurb = "Sails the seven seas of brine.",
	},
	{
		id = "professor_toast",
		name = "Professor Toast",
		rarity = "Rare",
		cost = 900,
		income = 55,
		color = Color3.fromRGB(220, 180, 110),
		shape = Enum.PartType.Block,
		size = Vector3.new(3, 4, 1.5),
		blurb = "Holds three degrees in being golden.",
	},
	{
		id = "dj_llama_drama",
		name = "DJ Llama Drama",
		rarity = "Rare",
		cost = 2500,
		income = 130,
		color = Color3.fromRGB(255, 140, 200),
		shape = Enum.PartType.Ball,
		size = Vector3.new(3.5, 3.5, 3.5),
		blurb = "Drops beats, never drops the mic.",
	},
	{
		id = "baron_banana",
		name = "Baron Von Banana",
		rarity = "Epic",
		cost = 8000,
		income = 350,
		color = Color3.fromRGB(255, 220, 40),
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(3, 5, 3),
		blurb = "Peels back the curtain on wealth.",
	},
	{
		id = "sir_sock",
		name = "Sir Reginald Sock",
		rarity = "Epic",
		cost = 20000,
		income = 800,
		color = Color3.fromRGB(70, 130, 255),
		shape = Enum.PartType.Block,
		size = Vector3.new(3, 4.5, 2),
		blurb = "Lost its pair, found a fortune.",
	},
	{
		id = "noodle_emperor",
		name = "The Grand Noodle Emperor",
		rarity = "Legendary",
		cost = 60000,
		income = 2000,
		color = Color3.fromRGB(255, 200, 40),
		shape = Enum.PartType.Ball,
		size = Vector3.new(5, 5, 5),
		blurb = "All noodles bow before him.",
	},
	{
		id = "quantum_toaster",
		name = "Quantum Toaster 3000",
		rarity = "Mythic",
		cost = 150000,
		income = 5000,
		color = Color3.fromRGB(200, 210, 230),
		shape = Enum.PartType.Block,
		size = Vector3.new(4, 4, 4),
		blurb = "Toasts bread in two timelines at once.",
	},
}

-- Roll one character, weighted by rarity, the way the conveyor does.
function BrainrotData.rollCharacter()
	local total = 0
	for _, entry in ipairs(BrainrotData.CATALOGUE) do
		total += BrainrotData.RARITIES[entry.rarity].weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, entry in ipairs(BrainrotData.CATALOGUE) do
		running += BrainrotData.RARITIES[entry.rarity].weight
		if roll <= running then
			return entry
		end
	end
	return BrainrotData.CATALOGUE[1]
end

-- Look a character up by its id, or nil when there is no such id.
function BrainrotData.byId(id)
	for _, entry in ipairs(BrainrotData.CATALOGUE) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Short money text: 1250 becomes $1.3K and 2400000 becomes $2.4M.
function BrainrotData.moneyText(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return string.format("$%d", math.floor(amount))
	end
end

return BrainrotData
