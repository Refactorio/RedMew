# Crash Site

Players crash at spawn in the middle of a grid of enemy outposts. Each outpost is defended by
turrets and worms; killing them all captures it, and a captured outpost's machines keep
producing for the team, its market sells to them, and its production can be upgraded. Biters
are active. Spawn has a market of its own, where players buy airstrikes, artillery barrages and
rocket-firing tanks to use against them. Each map is a preset.

## Files

- `scenario.lua`: the game mode. It lays out the outpost grid, the spawn market and its upgrades,
  the payment chests, the hidden cutscene surface, and Crash Site's RedMew config.
  `Public.init(config)` is what a preset calls.
- `presets/*.lua`: one per map. A preset passes its overrides to `Scenario.init(config)`:
  `scenario_name`, `map_gen_settings`, `grid_number_of_blocks`, `bounds_shape`, which outposts
  are used, and so on. The picture maps (UK, Venice, Manhattan, World) build the world from
  `map_gen/data/presets/<name>`; those data files decompress themselves, so don't call
  `b.decompress` on them again. The top-level `map_gen/maps/crash_site*.lua` files are one-line
  wrappers that select a preset.
- `outpost_builder.lua`: turns outpost templates into shapes, and runs everything that happens in
  an outpost: the magic crafters, turret refills, power for laser turrets, capture, markets and
  upgrades. Its callbacks are `Token.register`ed so they survive save and load.
- `outpost_data/*.lua`: the outpost templates, about 90 of them: walls and turret rings,
  factories, and for each outpost with a market, its market (name, upgrade rate and costs, the
  items it sells) and loot.
- `commands.lua`: `/spy`, `/strike` and `/barrage`, the spawn market's airstrike and barrage
  upgrades, and the end-of-map message on Discord.
- `events.lua`: what happens when enemy entities die: destroyed poles come back after a minute,
  turret kills raise evolution, and some entities drop coins or spawn others.
- `features/`: rocket tanks, sandworms (Arrakis), vehicle repair beams, deconstruction targeting.
- `map_poll.lua`: Crash Site's next-map poll.

## Outposts

- **The grid:** `grid_number_of_blocks` blocks of 180 tiles (9 by default), with the starting
  area in the middle. The outposts get bigger and better defended the further they are from the
  middle, and each is shifted a little at random. A second grid of 96-tile blocks holds mini
  outposts. The layout is random per game, seeded from the map seed.
- **Not every outpost has a market**, and a factory outpost can have machines without a market
  of its own.
- **Capture:** every turret and worm of an outpost is registered with
  `script.register_on_object_destroyed`; when the last one is gone, the outpost is captured. Its
  walls become the player's, the market is renamed, a message goes out, and its upgrade goes on
  sale.
- **Magic crafters:** an outpost's assemblers and furnaces are made inactive, inoperable,
  unminable and indestructible, and their products are inserted by script, a few machines each
  tick in turn. They produce whether the outpost is captured or not. Buying an upgrade raises
  every machine's rate.
- **Turrets:** gun turrets get their ammo, the first included, from a script that refills one
  turret a tick in turn. Laser turrets get power from a hidden energy interface, through the
  outpost's own poles.

## Rules that are easy to break

- **Map generation silently skips an entity it can't place** (see `map_gen/shared/generate.lua`).
  A laser turret whose pole was blocked never gets power, so don't assume every turret of an
  outpost is there or powered.
- **The payment chests are found by position:** `/strike` takes poison capsules from the chest at
  `{3.5, -7.5}` and `/barrage` explosive rockets from the one at `{-4.5, -7.5}`. Moving them in
  `scenario.lua` means changing `commands.lua` too.
- **Anything an outpost keeps for later goes through `Global` and its callbacks through
  `Token`**, like the rest of `outpost_builder.lua`: outposts are built during map generation
  and live for the whole game, across saves.

## Adding a map

1. A preset, `presets/<name>.lua`, whose config has `scenario_name = 'crashsite-<name>'` and
   which ends with `return Scenario.init(config)` (copy `presets/arrakis.lua`).
2. The scenario template, `scenario_templates/crashsite-<name>/map_selection.lua`:
   `return require 'map_gen.maps.crash_site.presets.<name>'`.
3. Its display name in `commands.lua`'s `scenario_display_name`, which the end-of-map message
   on Discord uses for this map and the next. Without one it shows the template name.
4. To offer it in the next-map poll, an entry in `map_poll.lua`'s `maps`:
   `{name = 'crashsite-<name>', display_name = '<Name>'}`. Not every map is in the poll.

Crash Site has no changelog, and its poll is separate from Danger Ores': adding a map to one
changes nothing in the other.

## Tests

Crash Site's tests are in `scenario_tests.lua`, which is only loaded with the game mode, so they
run on every Crash Site preset. They need no player: they capture an outpost by killing its
defenders, buy upgrades by raising `Retailer.events.on_market_purchase` with a stand-in buyer,
and call `/strike` and `/barrage` through `commands.lua`'s `call_strike` and `call_barrage` with
a stand-in caller. What's near spawn depends on the map seed: how many outposts have markets,
whether there are laser turrets in the first ring. How to write and run tests is in
`docs/TESTS.md`.
