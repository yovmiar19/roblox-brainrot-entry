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

## Visibility fix (2026-11-18)

Playtesting showed the game ran but the player could not see it: the spawn sat 78 studs from the lane,
the name tags were big AlwaysOnTop billboards that read the same size from any distance, and the
ClickDetector was a short-range click on a tiny body. Worse, every `PivotTo` reset the model's rotation,
so the cylinder brainrots (Captain Pickle, Baron Von Banana) lay on their sides with their eyes underneath.
Fixed by moving the spawn beside the lane, shrinking the tags to 160×48 and turning off AlwaysOnTop,
giving every brainrot a larger invisible hitbox with a 200-stud click range, and carrying each model's
upright rotation through every `PivotTo` (spawn, buy, walking, bobbing).
