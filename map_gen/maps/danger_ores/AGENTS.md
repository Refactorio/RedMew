# Danger Ores: notes for agents

Read [README.md](README.md) first: what the mode is, how it fits together and what adding a map
takes. This adds how the code behaves and what is easy to break.

## How a map is built

- **A preset** requires `configuration.lua` as `DOC`, changes what it needs
  (`DOC.scenario_name`, `DOC.map_config.main_ores`, a feature's `enabled`...), sets the map's
  name and description with `features.gui.info`, and ends with `return Scenario.register(DOC)`.
  Maps with extras of their own (City Blocks, Expanse, Permanence) require those modules from
  the preset.
- **`scenario.lua`**'s `register` turns on the modules the config enables and returns the map
  shape from `modules/map.lua`.
- **`modules/map.lua`** builds the shape from `map_config` inside a `Global.register_init`
  callback, so on init and on every load, from a random generator seeded with the map seed: the
  spawn area, the tile pattern, the main ores (`main_ores_builder`, default
  `modules/main_ores.lua`), water (`map_config.water`), resource patches, dense patches, trees,
  enemies, fish, and `post_map_func` last.

What makes one map differ from another is usually one of:
- **The main ore layout:** a `main_ores_builder` from `modules/main_ores_<layout>.lua`. The pure
  geometry of the newer layouts lives in `modules/<layout>_layout.lua`, with no Factorio API in
  it, so it can be tested on its own.
- **The ore mix:** `map_config.main_ores`, from `config/`. New mixes are built with the fluent API
  in `config/main_ores_factory.lua` (`Factory.default():add_ore('stone')`, `:change_tiles`,
  `:richness`, `:scale_richness`...) rather than a new config file.
- **A terrain overlay:** `map_config.water` replaced by `modules/rivers.lua`, `archipelago.lua`,
  `citadel.lua` or `fault_lines.lua`, which lay water or void over the usual sectors.
- **A runtime rule:** the maze, Expanse's hungry chests, Permanence's ore that comes back,
  Nightfall's biters at night, City Blocks' rail corridors.

## Modules

Turned on from `configuration.lua` (all on by default unless noted):
- `allowed_entities` / `banned_entities`: the building rule, through
  `map_gen/shared/entity_placement_restriction.lua`. What isn't allowed on ore is removed and
  handed back, to a player or to the construction robot that built it.
- `terraforming`: chunks outside the starting area stay void until enough pollution reaches them.
- `rocket_launched_simple`: the satellite win condition. The Space Age preset uses
  `compatibility/space-age/victory.lua` instead (a legendary Mech Armor wins).
- `concrete_on_landfill`: refined concrete laid on landfill becomes an unminable marker tile; a
  floor built over it hands the refined concrete back.
- `container_dump`: a destroyed chest leaves its contents as ore (coal by default).
- `biter_drops`: nests drop fish.
- `mining_productivity`: mining productivity research gives robot cargo size instead.
- `prevent_quality_mining`: quality mining drills aren't allowed on ore.
- `technologies`: researching some technologies also researches others.
- `ore_mined`, `restart_command`, `restart_statistics`: the ore mined score and the end-of-map
  message on Discord, which names maps by their poll display name.
- `map_poll`: the next-map poll.
- `maze` and `radioactivity`: off by default.

## Rules that are easy to break

- **`require` only at the top of a file.** The map's builder functions (`water`,
  `main_ores_builder`, `post_map_func`...) run later, in `map.lua`'s init callback, where
  `require` fails; every chunk then errors and no Danger Ores terrain is generated.
- **A chunk only writes inside itself.** Chunks generate in any order, so anything written into a
  neighbouring chunk can be overwritten or written twice. Lay features out per chunk (City Blocks
  puts its rails at the same offsets in every corridor chunk).
- **Build the layout from the random generator `map.lua` passes in**, not from storage: it is
  re-seeded on every load, so the same layout comes back without saving it.
- **Ore regions that touch need 4 colours** to keep different ores apart along every border.
  Layouts try colours lowest first, so the 4th is rare, and give it to stone.
- **New `on_chunk_generated` handlers skip the surface while it is being cleared**
  (`RS.is_clearing()`): Danger Ores generates on `nauvis`, which is cleared at the end of the
  first tick.
- **Placement rules go through `entity_placement_restriction`**, which covers player and robot
  builds; refunds to a robot go through `map_gen/shared/robot_refund.lua`.
- **Terraforming is what reveals the map.** A preset only turns it off when the map reveals
  itself another way (Expanse, mazes, City Blocks, Gridlocked).
- **The changelog's newest entry goes at the end**, and several map PRs open at once each add to
  it, so the later ones need rebasing.

## Tests

Each module's tests sit next to it (`modules/<module>_tests.lua`) and run on every map that loads
the module, so most run on every Danger Ores template, and on Diggy's Danger Ores presets and
Safety Ores. Some modules are off on some presets (the plain `danger-ore` preset turns off biter
drops), so their tests only run where they're on. A layout's pure geometry gets tests of its own
(`modules/<layout>_layout_tests.lua`), seeded with `game.create_random_generator` as the map
seeds it. How to write and run tests is in `docs/TESTS.md`.
