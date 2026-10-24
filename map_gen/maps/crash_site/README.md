# Crash Site

Players crash at spawn in the middle of a grid of enemy outposts. Each outpost is defended by
turrets and worms; killing them all captures it, and a captured outpost's machines keep
producing for the team, its market sells to them, and its production can be upgraded. Biters
are active. Spawn has a market of its own, where players buy airstrikes, artillery barrages and
rocket-firing tanks to use against them.

Every map is a preset in `presets/`: the normal map, desert ones (Desert, Arrakis with its
sandworms), real-world maps built from pictures (UK, Venice, Manhattan, World), and variants with
rules of their own (no bots, no spidertrons, steam only...).

## How it fits together

- `scenario.lua` is the game mode: the outpost grid, the spawn market and its upgrades. A preset
  passes its settings to it.
- `outpost_builder.lua` builds the outposts and runs them; `outpost_data/` holds the outpost
  templates (walls, turrets, factories, markets and loot).
- `commands.lua` has `/spy`, `/strike` and `/barrage`, and the end-of-map message on Discord.
- `events.lua` handles enemy entities dying, `features/` the extras some maps use (rocket tanks,
  sandworms, repair beams).
- `map_poll.lua` is Crash Site's next-map poll.

## Adding a map

1. A preset, `presets/<name>.lua`, whose config has `scenario_name = 'crashsite-<name>'` and
   which ends with `return Scenario.init(config)` (copy `presets/arrakis.lua`).
2. The scenario template, `scenario_templates/crashsite-<name>/map_selection.lua`:
   `return require 'map_gen.maps.crash_site.presets.<name>'`.
3. Its display name in `commands.lua`'s `scenario_display_name`, which the end-of-map message on
   Discord uses for this map and the next. Without one it shows the template name.
4. To offer it in the next-map poll, an entry in `map_poll.lua`'s `maps`:
   `{name = 'crashsite-<name>', display_name = '<Name>'}`. Not every map is in the poll.

Crash Site has no changelog, and its poll is separate from Danger Ores': adding a map to one
changes nothing in the other.

Notes for working on the code, the rules that are easy to break and how the tests work are in
[AGENTS.md](AGENTS.md).
