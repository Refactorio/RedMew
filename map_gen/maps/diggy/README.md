# Diggy

An underground world. Everything starts as void, and players dig through it by mining or
destroying rocks: each rock removed opens the void beside it into ground, with new rock behind.
Ore, treasure, rooms and biters turn up as they dig. Dig out too much with nothing holding it up,
and the cave collapses. The player guide is on the wiki:
https://github.com/Refactorio/RedMew/wiki/Map-guide%3A-Diggy

There are three presets: the normal one, and two that add the Danger Ores building rule. One of
those, Belts 'n Bullets (BnB), also disables laser turrets, the logistic system and laser weapons
research.

## How it fits together

- `scenario.lua` sets Diggy's RedMew config and loads the features a preset turns on.
- `presets/` holds the maps' configs, mostly a list of features with their settings.
- `feature/` holds one module per feature: digging, cave collapses, the starting zone, scattered
  ore, the alien spawner, coins and treasure, rooms, and more.
- `template.lua` is how features change the map.

## Adding a map

1. A preset in `presets/<name>.lua`, a copy of `normal.lua` with its own
   `scenario_name = 'diggy-<name>'` and features.
2. The scenario template, `scenario_templates/diggy-<name>/map_selection.lua`:
   `return require 'map_gen.maps.diggy.presets.<name>'`. If it needs mods, a `test-settings.json`
   next to it (see `docs/TESTS.md`).

Diggy has no next-map poll and no changelog.

Notes for working on the code, the rules that are easy to break and how the tests work are in
[AGENTS.md](AGENTS.md).
