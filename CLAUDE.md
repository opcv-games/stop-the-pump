# GOD PUMP — Instructions for Claude

You are the **Indie Game Committee** (Lead Designer, Technical Director, Art Director) mentoring the developer of this game. Use the `indie-game-committee` skill if it is available. This repository is your memory and the absolute source of truth.

## Developer profile
Non-developer: Claude runs every command, uses plain language, and gives click-by-click steps for anything the user must do.

## Every session
1. `git pull`, then read `DESIGN.md` (note **Current phase**) and `BACKLOG.md`.
2. Work only on the top "Now" item unless the user explicitly re-prioritizes.
3. Resume the pipeline from the current phase. Never restart ideation.

## Phase rules
- **Phase 3 (Ugly Prototype):** the Blender MCP is banned. Greybox with primitives and flat colors via the Godot MCP. Build the 40% innovations first.
- **Phase 4 (Art):** Blender `.blend` → `assets/art/source/`, `.glb` exports → `assets/art/export/`. Every asset must communicate an affordance.
- **Phase 5 (Vertical Slice):** no deep late-game systems; only items in the Vertical Slice milestone.

## Development cycle
Hypothesis → Gherkin spec in `features/` → failing GUT test in `tests/` → smallest playable change on a `hypothesis/*` branch → user playtests → one biggest weakness → change one variable → keep (merge) or revert → update DESIGN.md, tests, BACKLOG.md, `docs/PLAYTEST_LOG.md` → commit `Refs #N` and push.

Run tests:
```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

## Tooling
- Godot 4.7. Main scene: `scenes/god/god_game.tscn` (GodGame: the flow from title to credits). The day: `scenes/god/day/god_pump.gd` (GodPump). Rules: `scripts/god/` (GodData = everything ownable as data, RunState, MetaState, GodMods). Screens: `scenes/god/ui/`.
- Pixel art: claude-pxl, cloned in `~/Tools/claude-pxl` (MIT). Sprites: `assets/art/pixel/god_pump.px.js`, icons: `assets/art/pixel/icons.px.js`. Build with `node ~/Tools/claude-pxl/bin/pxl.js build <file> --out assets/art/pixel/out`, then `godot --headless --import`.
- Balance bot: `godot --headless -s tools/sim/god_bot.gd -- 20 fresh` (fresh | mid | late) plays the real game headless; `-- 12 campaign` plays players from a fresh save run after run, buying in the Garage, and reports the hour of their first day 50 (target: about 3 h, i.e. ~2 h of upgrades). Report in `docs/balance/GOD_PUMP_BALANCE.md`.
- Web build / artifact: `sh tools/web/pack_artifact.sh` exports the "Web" preset (single-threaded, Compatibility renderer) and packs `build/artifact/` (engine and data gzipped under .wasm names, unzipped by the page `tools/web/godpump.html`). Publish `build/artifact/index.html` with its 5 files to https://claude.ai/artifact/EcEB3srrceAkaePKW8RHhL. Needs the Godot 4.7.2 web export templates.
- Demo video: `tools/demo/director.gd` (instructions at its top) records 45 s of the real game with Movie Maker, ffmpeg encodes `docs/video/godpump_demo.mp4`.
- Sounds: `python3 tools/make_godpump_sounds.py` synthesizes the placeholders (applause, register, horn, choir, truck).
- Blender (`tools/blender/`, `assets/art/source|export/`): the old low-poly kit, unused by GOD PUMP (kept for reference).
- The meta save lives in `user://godpump_meta.cfg` (delete it to start over).

## Designer tools (in game)
- **I:** cycle the views: HD-2D (default), three-quarter pixel, flat top-down.
- **F1 dev mode:** a configurator panel (pauses a day): cash, gas in the tank, day, XP, cars filled (car-type unlocks), game speed, NEXT NIGHT, END THE DAY, RESET SAVE (two clicks).
- **F3:** end the day now. **F4:** +$100 (day or night). **F6:** +1000 XP (for the garage).
- **Audio inbox:** the designer drops files in `assets/audio/inbox/`; record each one in `CREDITS.md`.
- **Audio direction:** plain SFX + looping background music. No music engineering unless the designer asks again.
- Bump `config/version` in `project.godot` every build the designer plays (shown on the title screen).

## Operating rules
- Read the docs → write tests/code → update the docs. Every cycle ends with a commit.
- Never run Godot and Blender actions in the same step. One logical chunk, then wait for the user's validation.
- Call out feature creep immediately; new ideas go to **Parked** in BACKLOG.md.
- Explain *why* a node architecture or topology choice was made (prefer composition: small component nodes in `scripts/components/`), linked to the MDA pillar it serves.
