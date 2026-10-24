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

  The first is Steam's install folder, the second the standalone game's. On macOS, give the
  game's app (`brew install powershell` for `pwsh`):

  ```
  pwsh .github/scripts/run-all.ps1 ~/Library/Application\ Support/Steam/steamapps/common/Factorio/factorio.app
  pwsh .github/scripts/run-tests.ps1 /Applications/factorio.app danger-ore-rivers
  ```

  The first is Steam's, the second the standalone game's if it was put in Applications. On any
  system the game's executable works too, e.g.
  `~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio`
  or `C:\Program Files\Factorio\bin\x64\factorio.exe`. The headers of the
  scripts list their options (how many run at once, the seed, the game speed), which are
  environment variables: `SEED=random pwsh ...` in bash, or `$env:SEED = 'random'` in PowerShell
  before running.

CI runs every template on each pull request. The *in-game test results* check lists every test
grouped by map, and the Factorio version they ran on.

CI runs the latest stable release of the Factorio version in `FACTORIO_LINE`
(`.github/workflows/CI.yml`), such as `2.0`, so it picks up patch releases by itself. Change it
in the pull request that moves the scenario to a new version.

## Startup and teardown

A module's tests rely on its `Declare.module_startup`, and on those of the modules above it. When
a startup fails, none of the tests below it run: each fails with `startup of <module> failed`, and
neither the startups and teardowns below it nor the module's own teardown run. When a teardown
fails, the tests below it that passed fail with `teardown of <module> failed`.

## Writing tests

Mark each test's steps:

```lua
Declare.test('a destroyed chest with items in it turns them into ore', function()
    -- Arrange
    local chest = surface.create_entity {name = 'iron-chest', position = position, force = 'player'}
    chest.insert {name = 'iron-plate', count = 100}

    -- Act
    chest.die()

    -- Assert
    local ore = surface.find_entities_filtered {area = spot, name = 'coal'}[1]
    Assert.equal(100, ore.amount, 'coal left by a chest of 100 plates')
end)
```

- **The Act is the thing under test:** the call for a pure function, generating the map for a
  check on the map, the event or the robots' work for a feature. A test that only checks what
  the scenario set up as it loaded just asserts. Words after a colon explain a step where it
  needs it (`-- Act: a ghost for the robots to build`).
- **Don't call what you test inside an assertion:** put the result in a local under Act, and
  assert on it after. A test that checks many things reads better as several small tests.
- **Test what our code decides, not Factorio's own behaviour.** Ask what change in our code
  would make the test fail; if nothing would, the test isn't needed. Whether a character can
  walk on shallow water is the game's business; whether the map puts shallow water between the
  land and deep water is ours.
- **Read values from the module rather than copying them into the test**, so the test can't
  drift from what it checks. Expose them from the module if you have to.
- **Say what the module's tests cover in the file's header**, and when they're discovered,
  not how they run: every test runs the same way.
- **`require` at the top of the file.** It only works while the scenario loads, never in a test.
- **Pure logic is tested in game too**, so it runs on Factorio's Lua: every number is a double
  (Lua 5.2), and `math.randomseed` does nothing. For repeatable randomness use
  `game.create_random_generator(seed)`, with seeds above 341: every seed up to 341 gives the same
  generator.

## Tests that take ticks

A test that has to let the game run (robots building, a timer running out) adds steps to its
`context`: `next` runs a function the next tick, `timeout(ticks, func)` after that many, and
`wait_until(ticks, done, message)` checks `done` every tick until it returns true, failing the
test with `message` if it doesn't within `ticks`. They chain, so what happens next follows the
wait instead of nesting in it:

```lua
Declare.test('a building robots build off ore goes back to storage', function(context)
    -- Arrange
    local storage, remove_network = Helper.robot_network(surface, {x = 0, y = 0}, {{name = 'iron-chest', count = 1}})
    context:add_teardown(remove_network)

    -- Act: a ghost for the robots to build
    surface.create_entity {name = 'entity-ghost', inner_name = 'iron-chest', position = p, force = 'player'}

    -- Assert
    context:wait_until(1800, function()
        return storage.get_item_count('iron-chest') == 1
    end, function()
        return 'the iron chest did not come back: ' .. storage.get_item_count('iron-chest') .. ' in storage'
    end):next(function()
        Assert.equal(0, surface.count_entities_filtered {position = p, radius = 0.5, name = 'iron-chest'}, 'iron chests left')
    end)
end)
```

`message` can be a function, called when the wait fails, to say what was there instead. The
step after a wait runs the tick after `done` held. Module startups can wait too.

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
