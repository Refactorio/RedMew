# Diggy

An underground world. Everything starts as void (`out-of-map`), and players dig through it by
mining or destroying rocks: each rock removed opens the void beside it into ground, with new rock
behind. Dig out too much with nothing holding it up and the cave collapses. The player guide is
on the wiki: https://github.com/Refactorio/RedMew/wiki/Map-guide%3A-Diggy

## Files

- `scenario.lua`: `Scenario.register(config)` sets Diggy's RedMew config (no redmew surface, so
  Diggy runs on the default surface; no market; experience levels on) and loads every enabled
  feature.
- `presets/normal.lua`, `danger_ores.lua`, `danger_ores_BnB.lua`: a map's config, mostly a
  `features` table with one entry per feature: `enabled`, `load = function() return require(...)
  end` and its settings. `map_gen/maps/diggy.lua` selects the normal one.
- `feature/*.lua`: one module per feature, each with `register(config)` and optionally
  `on_init` and `get_extra_map_info`.
- `template.lua`: `Template.insert(surface, tiles, entities)`, how features change the map. It
  raises `Template.events.on_void_removed` for each void tile replaced and `on_placed_entity` for
  each entity created. It also holds the rock names and `support_beam_entities`, how much each
  kind of support holds up.
- `orepattern/`: the ore cluster patterns for scattered resources.

## Features

- `starting_zone`: the dug-out start, stone path inside a ring of rocks, with the market in it.
- `diggy_hole`: the digging. A rock that dies, is mined, or is destroyed by script opens each void
  tile beside it into dirt, with a new rock on it. Robots wear rocks down over several trips.
  Mining a floor tile leaves the tile it was laid on; only where that is void does it get dirt.
- `diggy_cave_collapse`: a stress map per surface. Removing a support adds stress around it, and
  building one takes it away; past a threshold the cave collapses, rock falls back on the tiles
  around it, and whatever stood there dies. Stone walls, rocks, the market and nuclear reactors
  hold the ceiling up (`Template.support_beam_entities`).
- `scattered_resources`: ore turns up in freshly dug ground, more and richer further from spawn.
- `alien_spawner`: digging far from spawn can let biters out and raises evolution.
- `coin_gathering`: coins from mining and from dead enemies, and treasure chests in the rock.
- `simple_room_generator`: rooms with contents found while digging.
- Others: `night_time` (no daylight, so no solar), `setup_player`, `blueprint_tools`,
  `antigrief`, `belts_n_bullets`, `flaming_pumpjack`, `shelob`, `refresh_map`,
  `mining_productivity`, `weapon_balance`, `cutscene`, `restart_command`.

The Danger Ores presets also load Danger Ores modules (the building rule, container dump), so
those modules and their tests run on them too.

## Rules that are easy to break

- **Change the map through `Template.insert`**, so the void-removed and placed-entity events
  fire: collapse stress, scattered resources and the alien spawner all listen to them. It does
  the first few batches of tiles and entities at once and queues the rest as tasks, so a big
  insert finishes over later ticks.
- **One rock does several things:** when a rock dies, the collapse code removes its support and
  `diggy_hole` opens the void beside it, which raises `on_void_removed`, which adds stress again.
- **A feature's `load` runs while the scenario loads**, inside `Scenario.register`, so the
  `require` in it works; don't call it later.
- **Mined-tile events in Factorio 2.0** carry the mined tile's prototype as `old_tile`, with no
  hidden tile, and the game has already put back the tile underneath when the event arrives.

## Adding a map

1. A preset in `presets/<name>.lua`, a copy of `normal.lua` with its own
   `scenario_name = 'diggy-<name>'` and features.
2. The scenario template, `scenario_templates/diggy-<name>/map_selection.lua`:
   `return require 'map_gen.maps.diggy.presets.<name>'`. If it needs mods, a `test-settings.json`
   next to it (see `docs/TESTS.md`).

Diggy has no next-map poll and no changelog.

## Tests

Diggy's tests are in `scenario_tests.lua` and next to the features they cover
(`feature/<feature>_tests.lua`), so they run on all three presets. They dig the way a player does,
by killing every rock in an area and waiting for the void to open, and use real construction
robots for mining by robots. Collapses are counted from `DiggyCaveCollapse.events.on_collapse`,
inside the test's own room only, since an earlier test's room can keep caving in. How to write
and run tests is in `docs/TESTS.md`.
