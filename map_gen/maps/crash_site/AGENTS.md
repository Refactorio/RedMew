# Crash Site: notes for agents

Read [README.md](README.md) first: what the mode is, how it fits together and what adding a map
takes. This adds how the code behaves and what is easy to break.

## Files in more detail

- `scenario.lua`: `Public.init(config)` lays out the outpost grid, the spawn market and its
  upgrade items, the payment chests, the hidden `cutscene` surface, and Crash Site's RedMew
  config.
- `presets/*.lua`: a preset's config overrides `scenario_name`, `map_gen_settings`,
  `grid_number_of_blocks`, `bounds_shape`, which outposts are used, and so on. The picture maps
  build the world from `map_gen/data/presets/<name>`; those data files decompress themselves, so
  don't call `b.decompress` on them again (and don't read them: they're huge). The top-level
  `map_gen/maps/crash_site*.lua` files are one-line wrappers that select a preset.
- `outpost_builder.lua`: turns outpost templates into shapes, and owns everything that happens in
  an outpost: the magic crafters, turret refills, power for laser turrets, capture, markets and
  upgrades. Its callbacks are `Token.register`ed so they survive save and load.
- `outpost_data/*.lua`: about 90 templates, composed with `make_1_way`, `make_4_way`,
  `extend_1_way` and `extend_walls`; an outpost with a market has a `market` entry with its name,
  upgrade rate and costs, and the items it sells.
- `commands.lua`: `call_strike` and `call_barrage` are exposed for the commands and the tests.
- `events.lua`: destroyed enemy poles come back after a minute (and their laser turrets get power
  again), turret kills raise evolution, and some entities drop coins or spawn others.

## Outposts

- **The grid:** `grid_number_of_blocks` blocks of 180 tiles (9 by default), with the starting
  area in the middle. The outposts get bigger and better defended the further they are from the
  middle, and each is shifted a little at random. A second grid of 96-tile blocks holds mini
  outposts. The layout is random per game, seeded from the map seed.
- **Not every outpost has a market**, and a factory outpost can have machines without a market of
  its own.
- **Capture:** every turret and worm of an outpost is registered with
  `script.register_on_object_destroyed`; when the last one is gone, the outpost is captured. Its
  walls become the player's, the market is renamed after a random donator, a message goes out,
  and its upgrade goes on sale.
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
- **Anything an outpost keeps for later goes through `Global`, and its callbacks through
  `Token`**, like the rest of `outpost_builder.lua`: outposts are built during map generation and
  live for the whole game, across saves.

## Tests

Crash Site's tests are in `scenario_tests.lua`, which is only loaded with the game mode, so they
run on every Crash Site preset. They need no player: they capture an outpost by killing its
defenders, buy upgrades by raising `Retailer.events.on_market_purchase` with a stand-in buyer,
and call `/strike` and `/barrage` through `call_strike` and `call_barrage` with a stand-in caller.
What's near spawn depends on the map seed: how many outposts have markets, whether there are
laser turrets in the first ring. How to write and run tests is in `docs/TESTS.md`.
