# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

RedMew is a [Factorio](https://www.factorio.com/) scenario written in Lua. It provides custom maps, map generation, gameplay features and server tooling for the RedMew community servers.

## Repository layout

- `control.lua` — scenario entry point; loads modules based on `config.lua`
- `config.lua` — central configuration; feature toggles live here
- `map_gen/` — map generation; playable maps in `map_gen/maps/`
  - `map_gen/data/` — **do not read these files** (see warning below)
- `features/` — gameplay feature modules (each toggled via `config.lua`)
- `utils/` — shared helper modules (`math`, `string`, `event`, `global`, ...)
- `resources/` — data-stage and lifecycle helpers
- `locale/` — translations; `.cfg` files only (sorted, English first)
- `scenario_templates/` — optional per-scenario override folders (see below)
- `docs/` — additional docs (mostly moved to the project wiki)

### Context-size warning: `map_gen/data/`

Never open or read files under `map_gen/data/` (especially `map_gen/data/presets/`, e.g. `factory.lua` is ~13 MB). They hold huge generated pixel/picture data used to build image-based maps and will blow up the context window in one read. Grep with `head_limit` if you must locate something there, but do not dump file contents. (These files are also excluded from luacheck via `.luacheckrc`.)

## Working in this repo

- To run/select a map, copy `map_selection.sample.lua` to `map_selection.lua` (gitignored) and change the `require` on the first line. Never commit `map_selection.lua`. There is also a starting template at `map_gen/maps/template.lua`.
- The Factorio modding API is sandboxed; only modules loaded in `control.lua` run in the control stage. Never call `script.on_event` directly — use the wrapper in `utils/event.lua` (`Event.add`, `Event.on_init`, `Event.on_load`, `Event.on_nth_tick`).
- Never keep state that must survive save/load in plain module locals; register it with `Global.register` from `utils/global.lua`. Closures in global storage are forbidden — store a `Token.register` token instead. `Token.register` must only be called at control stage / `on_init` (desync risk otherwise).
- Define chat commands with `Command.add` from `utils/command.lua` (handles ranks, locales, server flags) rather than raw `commands.add_command`; build GUIs with the helpers in `utils/gui.lua`.
- Player-facing strings should be translatable: add keys to `locale/en/*.cfg` (the source of truth) and keep keys in sync across locales — the CI pipeline (`.github/workflows/CI.yml`, run before PRs to `develop` are merged) checks for missing/misplaced keys and rejects duplicate keys or sections.
- Whenever adding, editing, or translating strings in `locale/`, follow `docs/LOCALE.md`.
- Tests run inside Factorio using the framework in `utils/test/`: create a `<module>_tests.lua` next to the code (see `utils/core_tests.lua`) and run the `/test-runner` command in game (`_DEBUG = true` in `config.lua`). CI runs them on headless servers for every scenario template, where tests needing a player are skipped. To run them the same way, use PowerShell 7 (`pwsh`, on Linux, macOS or Windows) with a Factorio install or the free headless server: `pwsh .github/scripts/run-tests.ps1 <factorio> <template>` for one scenario template, or `run-all.ps1 <factorio>` for all of them. See `docs/TESTS.md` for the details, including its "Writing tests" section: mark each test's Arrange, Act and Assert, and test what our code decides, not Factorio's own behaviour.
- Keep changes surgical; feature modules should be independently disableable through `config.lua`.

## How the code behaves

- `require` only works while the scenario loads (while `control.lua` is parsed). A `require` inside an event handler, or inside a function called later, fails with "Require can't be used outside of control.lua parsing"; put requires at the top of the file.
- A map module (what `map_selection.lua` returns) is either a shape function, `function(x, y, world)`, that `map_gen/shared/generate.lua` fills chunks from, or `true` when the map generates itself (the game modes do). Anything else is an error.
- Map generation runs as each chunk is generated under `_DEBUG` and on tick 0, but is queued and spread over later ticks otherwise, so what a test sees at once a server sees later. Entities that can't be placed are silently skipped.
- Use `RS.get_surface()` (`map_gen/shared/redmew_surface.lua`) for the map's surface, not `game.surfaces.nauvis`; while `RS.is_clearing()`, chunk handlers must skip it.
- Event handlers run in reverse order of registration. Under `_DEBUG` an error in a handler stops the game; otherwise it is caught and only logged, and the other handlers still run, so on a server a broken handler looks like "nothing happens": look for `stack traceback` in `factorio-current.log`.
- `script.raise_event` copies its event table, so it can't carry functions or `game`.
- To hand an item back to a construction robot, use `map_gen/shared/robot_refund.lua`: inside a build event, `robot.insert` takes nothing.

## Factorio version

The scenario targets Factorio 2.0; CI tests it on the version in `.github/workflows/CI.yml`. Use `helpers.write_file`, not `game.write_file`, and the global `prototypes` for prototypes. Many old single-file maps in `map_gen/maps/` that no scenario template selects don't load in 2.0.

## Pull requests

- Open pull requests against `develop`, one fix or feature per pull request, each branched from the current `develop`.
- A game mode's `README.md` says what adding a map to it takes (for Danger Ores: a poll entry and a changelog line).

## Scenario templates (`scenario_templates/`)

If the map should be a standalone scenario, add a folder in `scenario_templates/` named after the scenario. It may contain
any files that the scenario should override or add to the base scenario — typically just a `map_selection.lua` whose first
line selects the map, e.g. `return require 'map_gen.maps.crash_site.presets.arrakis'`.

## FactorioWebInterface

The RedMew servers run these scenarios via [FactorioWebInterface](https://github.com/Refactorio/FactorioWebInterface).
If you have questions about how `features/server.lua`, `features/server_commands.lua` work, or about how scenario loading
works in general, look in that repository.

## Linting

`luacheck` (config in `.luacheckrc`) is the CI gate on PRs to `develop` (`.github/workflows/CI.yml`) and should be run before finishing:

```
luacheck .
```

Warnings are treated as errors, so the run must end with `0 warnings / 0 errors`. RedMew globals (`Debug`, `ServerCommands`, ...) are pre-declared in `.luacheckrc`.

## Style

- Follow the existing Lua style: 4-space indentation, single quotes, `snake_case` functions, `PascalCase` modules.
- Community docs (data lifecycle, style) live in the [wiki](https://github.com/Refactorio/RedMew/wiki).

## Licensing

All contributions must be licensed under [GPL-3.0](LICENSE).
