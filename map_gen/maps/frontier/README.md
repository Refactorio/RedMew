# Frontier

A ribbon world: a strip of land 36 chunks high, with water and the kraken to the west, and a
wall with the biters behind it to the east. The rocket silo starts far to the east, past the
wall; every rocket launched moves it further east, until the round's rockets are launched and the
team wins. Then a new round starts, with more rockets to launch. A spawn shop sells perks for
funds the team earns, and dead nests sometimes leave a market behind.

## How it fits together

- `scenario.lua` wires up the events, and holds the changelog.
- `shared/core.lua` holds all of a round's state: the size of the world, the silo, the rockets to
  win, which features are on.
- `modules/` holds the parts: the terrain, the rocket silo and how it moves, the enemies, the
  spawn shop and markets, the lobby between rounds, and the admin window for restarting.

## Adding a map

Frontier is one map, selected by `scenario_templates/frontier/map_selection.lua`; what changes
between rounds is the state in `core.lua`. It has no next-map poll.

Its changelog is the `ScenarioInfo.set_new_info` text in `scenario.lua`, which the info window
shows: a dated entry, newest at the top, for changes players will notice.

Notes for working on the code, the rules that are easy to break and how the tests work are in
[AGENTS.md](AGENTS.md).
