-- init.server: the one line that boots Brainrot Bazaar.
-- It hands the whole game to GameServer, which builds the world, runs the
-- conveyor, the shop, the income, the raids, the rebirths and the upgrades.

local GameServer = require(script.Parent.GameServer)

GameServer.start()
print("Brainrot Bazaar is running: buy brainrots, earn cash, bonk the Snatcher.")
