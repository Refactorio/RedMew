# Frontier: notes for agents

Read [README.md](README.md) first: what the mode is and how it fits together. This adds how the
code behaves and what is easy to break.

## Files in more detail

- `scenario.lua`: chunk generation, entity deaths, research, rocket launches, the kraken, tile
  placement, and the admin panel.
- `shared/core.lua`: `Public.get()` returns the round's state table, `Public.get(key)` one value,
  `Public.set(key, value)` sets one, `Public.surface()` is the map surface, and `Public.reset()`
  starts the round's values over.
- `modules/terrain.lua`: water west of the left boundary, the wall at the right boundary, ore,
  rocks, the silo's pad, and reverting tiles placed past the kraken's line.
- `modules/rocket_silo.lua`: a launch counts the rocket and picks the silo's next spot further
  east. After a minute of alarms the silo moves: the old spot gets a steel chest with whatever was
  left in the rocket, then a nuclear explosion and artillery on the players' base. The rocket silo
  recipe is turned off again after every research, so the silo can only be moved, not built.
- `modules/enemy.lua`: the biters' attacks and waves, turret outposts under rocks east of the
  wall, and what dead nests drop.
- `modules/spawn_shop.lua`, `market.lua`, `lobby.lua`, `restart.lua`: the shop, the exchange
  markets, the lobby, and the admin window for how the next round starts (reset the map, restart
  the server, or load a save or mods) and with which settings.

## Rules that are easy to break

- **Read the round's state from `core.lua` when you need it**, not at load: a new round resets it,
  and the restart settings change it between rounds. A round's rockets to win are set when it
  starts and grow with each round.
- **Under `_DEBUG`, a round is quicker:** the silo starts at x 30 and two rockets win. Anything
  that reads those values, tests included, has to allow for it.
- **The kraken's line is `-(left_boundary * 32 + kraken_distance)`**: players and anything built
  or driven past it are eaten, and tiles placed past it are reverted.
- **The wall at the right boundary has to stay unbroken**, so terrain changes (rivers, lakes)
  leave its band alone.

## Tests

Frontier's tests are in `scenario_tests.lua`, loaded only with the game mode. They need no
player: a launch is raised as the game raises it, with a stand-in rocket whose cargo pod is a
chest, and the kraken is checked with poles and spidertrons placed either side of its line. Raise
the round's rockets to win before launching, or the launch ends the round, and wait for the silo
to move, which happens after the alarms. How to write and run tests is in `docs/TESTS.md`.
