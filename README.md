# Brainrot Lane — roblox-brainrot-01 entry

A 3D brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
Absurd meme characters walk down a dark lane with yellow rails through a green plaza; hold E on one
to buy it, it moves onto your base and earns cash every second. Climb from Noodle Ned ($5/s) to the
Quantum Toaster 3000 ($400/s), buy an income boost — and bonk the Sneaky Snatcher three times when
he walks in to steal your best brainrot, or he gets away with it.

This is a fresh, deliberately simple rebuild. The first game (Brainrot Bazaar) kept failing in Studio
for the owner, so this one is minimal by design: every body is a ball or an axis-aligned block, nothing
ever rotates, every move is a plain position change, and the whole server side is a single module.

The spawn is bulletproof on purpose, after the owner's screenshot showed him standing on the bare
baseplate far from the lane even though the game was running: the SpawnLocation sits in the place
file itself (`default.project.json`, not built by a script), the engine loads the character on its
own (`CharacterAutoLoads` on, no `LoadCharacter` call), and the server teleports every character
to the lane the moment it appears — plus the PLAY button and a HUD button teleport there on demand.
Buying works by holding E on a ProximityPrompt (click is only the backup), name tags hang from an
attachment and are sized in studs so they shrink with distance, and the sign shows a live
"SERVER ALIVE" line with the walker count so anyone can see the server is running.

The world itself is built to be impossible to miss: the plaza is a thick green slab (top y=2), the
lane a thick bright strip (top y=3), and two tall glowing yellow beacon pillars mark the spawn and
the lane centre. And the client carries a small diagnostic panel at the bottom left that reports,
once a second, what that client can actually see — the player's position, whether the plaza, the
lane and the spawn point exist and where they are, how many tagged brainrot models are visible,
and the distance to the lane — so a single screenshot settles whether the world is really there.

- `src/server/` — GameServer (the cast, the world, buying, income, the thief, the one upgrade),
  init.server (boot: requires `script.GameServer`, never `script.Parent`).
- `src/client/Game.client.luau` — start screen, cash/income HUD, upgrade button, teleport button,
  raid banner, diagnostic readout.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `screenshots/` holds the captures of the game running in Roblox Studio; one of them is also the game's
  first thumbnail on Roblox. `PLAY.json` names the published place once the owner publishes it.

Run it as the grader does, writing `out/` in place of `/output`:
`mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`
