# Brainrot Lane — roblox-brainrot-01 entry

A 3D brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
Absurd meme characters walk down a dark lane with yellow rails through a green plaza; click one to buy
it, it moves onto your base and earns cash every second. Climb from Noodle Ned ($5/s) to the Quantum
Toaster 3000 ($400/s), buy an income boost — and bonk the Sneaky Snatcher three times when he walks
in to steal your best brainrot, or he gets away with it.

This is a fresh, deliberately simple rebuild. The first game (Brainrot Bazaar) kept failing in Studio
for the owner, so this one is minimal by design: every body is a ball or an axis-aligned block, nothing
ever rotates, every move is a plain position change, and the whole server side is a single module. The
player spawns right beside the lane, name tags are small and honest about distance, and every brainrot
carries a big invisible hitbox with a 200-stud click range.

- `src/server/` — GameServer (the cast, the world, buying, income, the thief, the one upgrade),
  init.server (boot: requires `script.GameServer`, never `script.Parent`).
- `src/client/Game.client.luau` — start screen, cash/income HUD, upgrade button, raid banner.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `screenshots/` holds the captures of the game running in Roblox Studio; one of them is also the game's
  first thumbnail on Roblox. `PLAY.json` names the published place once the owner publishes it.

Run it as the grader does, writing `out/` in place of `/output`:
`mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`
