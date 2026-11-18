-- Brainrot Lane starts here. Rojo turns this folder into a Script
-- called "Server", so the game module sits right beside this file as
-- a child of the script itself. That is why the require below reads
-- script.GameServer: script.Parent is ServerScriptService, which has
-- no GameServer in it, and the old game died on exactly that line.
-- From here on GameServer runs everything: the world, the lane, the
-- shop, the income, the thief and the one upgrade.

local GameServer = require(script.GameServer)

GameServer.start()
print("Brainrot Lane is live: buy brainrots off the lane and bonk the Snatcher.")
