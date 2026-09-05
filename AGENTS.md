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
- Player-facing strings should be translatable: add keys to `locale/en/*.cfg` (the source of truth) and keep keys in sync across locales — the release pipeline (`.travis/check_locale.sh`) checks for missing/misplaced keys.
- Whenever adding, editing, or translating strings in `locale/`, follow `docs/LOCALE.md`.
- Tests run inside Factorio using the framework in `utils/test/`: create a `<module>_tests.lua` next to the code (see `utils/core_tests.lua`) and run the `/test-runner` command in game (`_DEBUG = true` in `config.lua`).
- Keep changes surgical; feature modules should be independently disableable through `config.lua`.

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
