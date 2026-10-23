# Danger Ores

The map is covered in ore, and nothing but belts, drills, pipes, poles, rails and vehicles may
be built on it: players mine the ore out to make room for the factory. The map is revealed by
pollution, the first satellite launched kills all the biters, and launching enough satellites
(1000 by default) wins the map.

Every map is a preset in `presets/`, from the plain sectors of iron, copper and coal to mazes,
rivers, islands, rail-only city blocks and maps for mod packs. The servers offer them through a
next-map poll.

## How it fits together

- `configuration.lua` holds the defaults every map starts from: which features are on, game
  settings, and how the terrain is made.
- A preset (`presets/danger_ore_<name>.lua`) changes what its map needs and registers it with
  `scenario.lua`, which turns the features on and builds the map.
- `modules/` holds the features (the building rule, terraforming, the win condition...) and the
  ore layouts and terrain the presets choose from; `config/` holds the ore mixes.
- `changelog.lua` is what the in-game info window shows as what's new.

## Adding a map

1. The preset, `presets/danger_ore_<name>.lua`, with `DOC.scenario_name = 'danger-ore-<name>'`.
2. The scenario template, `scenario_templates/danger-ore-<name>/map_selection.lua`:
   `return require 'map_gen.maps.danger_ores.presets.danger_ore_<name>'`. If it needs mods, a
   `test-settings.json` next to it (see `docs/TESTS.md`).
3. An entry in `modules/map_poll.lua`'s `maps`, in alphabetical order:
   `{ name = 'danger-ore-<name>', display_name = '<Name> (short description)', mod_pack = mod_packs.danger_ore_normal, tags = {tags.regular} }`.
   The mod pack is the one the map runs with, and the tags (`regular`, `overhaul`) decide which
   servers offer it. The display name is also what the end-of-map message on Discord calls the
   map.
4. A dated line at the end of `changelog.lua`: `- [DO:<Name>] Added DO/<Name> preset`.
5. A preview image, `map_gen/data/.map_previews/danger_ore_<name>.png`.
6. Tests for whatever the map adds.

Notes for working on the code, the rules that are easy to break and how the tests work are in
[AGENTS.md](AGENTS.md).
