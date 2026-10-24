# Diggy: notes for agents

Read [README.md](README.md) first: what the mode is, how it fits together and what adding a map
takes. This adds how the code behaves and what is easy to break.

## Files in more detail

- `scenario.lua`: `Scenario.register(config)` sets Diggy's RedMew config (no redmew surface, so
  Diggy runs on the default surface; no market; experience levels on) and loads every enabled
  feature: its `register(config)`, and its `on_init` and `get_extra_map_info` if it has them.
- `presets/*.lua`: each feature in the `features` table has `enabled`,
  `load = function() return require(...) end` and its settings. `map_gen/maps/diggy.lua` selects
  the normal preset.
- `template.lua`: `Template.insert(surface, tiles, entities)` raises
  `Template.events.on_void_removed` for each void tile replaced and `on_placed_entity` for each
  entity created. It also holds the rock names and `support_beam_entities`, how much each kind of
  support holds up.
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
  fire: collapse stress, scattered resources and the alien spawner all listen to them. It does the
  first few batches of tiles and entities at once and queues the rest as tasks, so a big insert
  finishes over later ticks.
- **One rock does several things:** when a rock dies, the collapse code removes its support and
  `diggy_hole` opens the void beside it, which raises `on_void_removed`, which adds stress again.
- **A feature's `load` runs while the scenario loads**, inside `Scenario.register`, so the
  `require` in it works; don't call it later.
- **Mined-tile events in Factorio 2.0** carry the mined tile's prototype as `old_tile`, with no
  hidden tile, and the game has already put back the tile underneath when the event arrives.

## Tests

Diggy's tests are in `scenario_tests.lua` and next to the features they cover
(`feature/<feature>_tests.lua`), so they run on all three presets. They dig the way a player
does, by killing every rock in an area and waiting for the void to open, and use real
construction robots for mining by robots. Collapses are counted from
`DiggyCaveCollapse.events.on_collapse`, inside the test's own room only, since an earlier test's
room can keep caving in. How to write and run tests is in `docs/TESTS.md`.
