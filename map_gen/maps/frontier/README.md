# Frontier

A ribbon world: a strip of land 36 chunks high, with water and the kraken to the west, and a
wall with the biters behind it to the east. The rocket silo starts far to the east, past the
wall; every rocket launched moves it further east, until the round's rockets are launched and
the team wins. Then a new round starts.

## Files

- `scenario.lua`: the event wiring: chunk generation, entity deaths, research, rocket launches,
  the kraken, tile placement, and the admin panel.
- `shared/core.lua`: **all of a round's state**, in one table. `Public.get()` returns it,
  `Public.get(key)` one value, `Public.set(key, value)` sets one, `Public.surface()` is the map
  surface, and `Public.reset()` starts the round's values over. The size of the world, the
  boundaries, the silo's start and step, the rockets to win and which features are on all live
  here.
- `modules/terrain.lua`: the world: water west of the left boundary, the wall at the right
  boundary, ore, rocks, the silo's pad, and blocking tiles placed past the kraken's line.
- `modules/rocket_silo.lua`: a launch counts the rocket and picks the silo's next spot further
  east. After a minute of alarms the silo moves: the old spot gets a steel chest with whatever
  was left in the rocket, then a nuclear explosion and artillery on the players' base. The rocket
  silo can't be crafted, only moved.
- `modules/enemy.lua`: the biters' attacks and waves, turret outposts under rocks east of the
  wall, and what dead nests drop.
- `modules/spawn_shop.lua`: perks bought with funds the team earns. `modules/market.lua`:
  exchange markets. `modules/lobby.lua`: the lobby between rounds. `modules/restart.lua`: the
  admin window for how the next round starts (reset the map, restart the server, or load a save
  or mods) and with which settings.
- `shared/debug.lua`, `shared/debug_terrain.lua`: debug helpers.

## Rules that are easy to break

- **Read the round's state from `core.lua` when you need it**, not at load: a new round resets
  it, and the restart settings change it between rounds. A round's rockets to win are set when it
  starts (they grow with each round).
- **Under `_DEBUG`, a round is quicker:** the silo starts at x 30 and two rockets win. Anything
  that reads those values (tests included) has to allow for it.
- **The kraken's line is `-(left_boundary * 32 + kraken_distance)`**: players and anything built
  or driven past it are eaten, and tiles placed past it are reverted. The wall at the right
  boundary has to stay unbroken, so terrain changes (rivers, lakes) leave it alone.

## Adding a map

Frontier is one map, selected by `scenario_templates/frontier/map_selection.lua`; what changes
between rounds is the state in `core.lua`. It has no next-map poll.

Its changelog is the `ScenarioInfo.set_new_info` text in `scenario.lua`, which the info window
shows: a dated entry, newest at the top, for changes players will notice.

## Tests

Frontier's tests are in `scenario_tests.lua`, loaded only with the game mode. They need no
player: a launch is raised as the game raises it, with a stand-in rocket whose cargo pod is a
chest, and the kraken is checked with poles and spidertrons placed either side of its line. Raise
the round's rockets to win before launching, or the launch ends the round, and wait for the silo
to move, which happens after the alarms. How to write and run tests is in `docs/TESTS.md`.
