-- init.server: entry point for Brainrot Bazaar.
-- Rojo turns this folder into a Script called "Server", so the sibling
-- modules (GameServer, WorldBuilder, Thief, BrainrotData) live as children
-- of this very script. That is why the require below reads script.GameServer:
-- script.Parent would be ServerScriptService, which holds no such module.
-- From here on GameServer owns everything: the world, the conveyor lane,
-- buying and income, the Snatcher raids, upgrades and rebirths.

local GameServer = require(script.GameServer)

GameServer.start()
print("Brainrot Bazaar is live: grab brainrots, watch the cash roll in, bonk the Snatcher.")
