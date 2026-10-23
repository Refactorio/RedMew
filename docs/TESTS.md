# Tests

RedMew's tests run inside Factorio, with the framework in `utils/test/`. A module's tests go in
`<module>_tests.lua` next to it (see `utils/core_tests.lua`), and are picked up whenever the
module is loaded. They only load with `_DEBUG = true` (in `config.lua`, or `map_selection.lua`).

## Running them

- **In game:** `/test-runner` runs every test and opens the test runner, where you can rerun a
  module or a single test. `/test-runner open` opens it without running anything.
- **Headless, the way CI does:** `/test-runner headless` runs them without a player (see below)
  and writes the results to `script-output/redmew-tests.json`. It works from the server console
  too.
- **Every scenario template, on headless servers:** the PowerShell scripts in `.github/scripts`,
  which CI runs too. They need PowerShell 7 (`pwsh`), which runs on Linux, macOS and Windows; on
  Windows, `winget install Microsoft.PowerShell` (the Windows PowerShell that comes with Windows
  is too old). From the repo folder:

  ```
  pwsh .github/scripts/run-all.ps1 ~/factorio                       # every template
  pwsh .github/scripts/run-all.ps1 ~/factorio danger-ore-rivers     # some of them
  pwsh .github/scripts/run-tests.ps1 ~/factorio danger-ore-rivers   # one, with every test's result
  pwsh .github/scripts/run-tests.ps1 ~/factorio map_gen.maps.maze   # a map no template selects
  ```

  `~/factorio` is an unpacked Factorio: the headless server is a free download from
  factorio.com (Linux only), or use an installed game. Each run is a scratch copy of the
  scenario with its own write-data, so it never touches the game's saves or settings. On
  Windows, give the game's folder:

  ```
  pwsh .github/scripts/run-all.ps1 'C:\Program Files (x86)\Steam\steamapps\common\Factorio'
  pwsh .github/scripts/run-tests.ps1 'C:\Program Files\Factorio' danger-ore-rivers
  ```

  The first is Steam's install folder, the second the standalone game's. The headers of the
  scripts list their options (how many run at once, the seed, the game speed), which are
  environment variables: `SEED=random pwsh ...` in bash, or `$env:SEED = 'random'` in PowerShell
  before running.

CI runs every template on each pull request. The *in-game test results* check lists every test
grouped by map.

## Startup and teardown

A module's tests rely on its `Declare.module_startup`, and on those of the modules above it. When
a startup fails, none of the tests below it run: each fails with `startup of <module> failed`, and
neither the startups and teardowns below it nor the module's own teardown run. When a teardown
fails, the tests below it that passed fail with `teardown of <module> failed`.

## Without a player

A headless server has no player, so on a headless run `context.player` is nil. Tests that need
one (a GUI, a character, building from the cursor) are tagged, and a headless run skips them:

```lua
Declare.module({'features', 'my feature', 'gui'}, function()
    -- uses a player's GUI
    Declare.tags('skip-headless')
    ...
end)
```

Tags apply to the whole module, and to every module below it.

Where you can, write tests that don't need a player, so they run in CI: `Helper.create_test_surface`
makes a scratch surface without moving a player, and `Helper.robot_network` sets up a powered
roboport with construction robots, which then build the ghosts a test places and mine what it
marks for deconstruction, with the game's own build checks and events.

## The map and the seed

Each template is tested with its own map, its files put over the scenario as on the servers.
Every module the map loads has its tests run, so a map and the modules it uses are tested
together. `map_gen/shared/map_loader_tests.lua` checks that every map's spawn area generates.

The map seed is fixed (1), so a test that passes once passes every time. To look for tests that
only pass on some maps, set `SEED=random`; each result shows the seed it ran with, so a failure
can be run again with `SEED=<that seed>`.

## Templates that need mods

A template can have a `test-settings.json` next to its `map_selection.lua`:

```json
{"mods": ["space-age", "quality", "elevated-rails"]}
```

turns on the expansion mods that come with the server (by default they are off), and

```json
{"skip": "needs Krastorio 2"}
```

skips a template that needs mods the server doesn't have.
