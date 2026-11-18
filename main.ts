// Brainrot Bazaar, the handoff program for roblox-brainrot-01.
// Node 22, standard library only.
//
// The game itself is the Rojo project in this directory. Running
// `rojo build default.project.json --output game.rbxl` turns src/ into
// game.rbxl, and this program is the courier that carries the finished
// entry to /output: game.rbxl, the Luau sources, the screenshots and
// PLAY.json, then it asks the vendored make.fun library to write the
// dossier the judge reads.
//
// Two rules shape every copy here. First, the grader refuses any name
// under /output that does not start with a letter, a digit or an
// underscore, or that holds anything but letters, digits, dots,
// underscores and dashes, so a stray .gitkeep or .DS_Store would sink
// the entry: src/ and screenshots/ are copied skipping every name that
// starts with a dot, at any depth. Second, the program runs twice and
// both runs must write identical bytes, so nothing here depends on the
// clock or on chance.
//
// To run it the way the grader does, outside its container:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// A name is fit to copy only when it does not start with a dot.
function isVisibleName(path: string): boolean {
  return !basename(path).startsWith('.');
}

mkdirSync(outDir, { recursive: true });
if (!existsSync(join(here, 'game.rbxl'))) {
  throw new Error('game.rbxl is missing: build it first with `rojo build default.project.json --output game.rbxl`');
}
copyFileSync(join(here, 'game.rbxl'), join(outDir, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(outDir, 'PLAY.json'));
cpSync(join(here, 'src'), join(outDir, 'src'), { recursive: true, filter: isVisibleName });
mkdirSync(join(outDir, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
  cpSync(join(here, 'screenshots'), join(outDir, 'screenshots'), { recursive: true, filter: isVisibleName });
}

// These caps match the scorer's own: at most four screenshots of 256 KiB,
// a place of at most 500000 instances, scripts of at most 8 MiB of source
// in all, and at most 1048576 characters of script paths. The dossier text
// is capped at 65536 bytes; only that one shapes the bytes written.
const dossier = buildDossier(outDir, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(outDir, 'dossier.json'), dossier);
