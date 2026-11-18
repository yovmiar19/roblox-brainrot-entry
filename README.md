# Brainrot Bazaar — roblox-brainrot-01 entry

A 3D brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
Absurd meme characters march down a yellow conveyor lane through a market plaza; click one to buy it,
it moves onto your base and earns cash every second. Climb from Noodle Ned ($5/s) to the Quantum Toaster
3000 ($5,000/s), upgrade your base, rebirth for double income — and bonk the Sneaky Snatcher away when
he comes to steal your best brainrot.

- `src/server/` — BrainrotData (the 9-character cast), WorldBuilder (the 3D plaza, lane, bases, stalls),
  GameServer (state, shop, income, raids, rebirths, upgrades), Thief (the Snatcher), init.server (boot).
- `src/client/Game.client.luau` — start screen, cash/income HUD, upgrade and rebirth buttons, raid banner.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `screenshots/` holds the captures of the game running in Roblox Studio; one of them is also the game's
  first thumbnail on Roblox. `PLAY.json` names the published place once the owner publishes it.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are in the kit's RULES.txt, which gives every command in order (Before you submit, then Enter).
