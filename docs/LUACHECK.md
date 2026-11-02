# Luacheck

`luacheck .` is a CI gate on pull requests to `develop`, and its settings are in `.luacheckrc`.
Warnings count as errors, so a run must end with `0 warnings / 0 errors`.

Luacheck only knows the Factorio API that `.luacheckrc` lists: it flags `game.nope` or
`defines.events.on_nope` as "accessing undefined field", and lets through anything listed, even if
the game no longer has it. So when RedMew moves to a new Factorio version, update the list.

## What comes from the Factorio API

Two parts of `.luacheckrc` are generated from the runtime API, which Factorio publishes as JSON for
each version (https://lua-api.factorio.com/2.1.24/runtime-api.json):

- **The control stage globals** (`stds.factorio_control`): `game`, `script`, `prototypes`,
  `rendering`, `helpers`, `settings`, `commands`, `remote` and `rcon`, each with its methods and
  attributes. Luacheck flags a field the API doesn't have, writing to the object itself
  (`game = nil`), and writing to an attribute that is read only (`game.tick = 0`). Attributes that
  hold an object or a table (`game.forces`, `settings.global`) are left open, so code can read and
  write what is in them (`game.forces.player.manual_mining_speed_modifier = 1`).
- **`defines`** (`stds.factorio_defines`): every define, with its values.

They sit between `-- luacheck-api.ps1: begin <part>` and `-- luacheck-api.ps1: end <part>` lines.
Don't edit them by hand: run the script instead.

A few functions are left out on purpose, so that luacheck flags them in RedMew code: each has a
wrapper that lets several modules share it.

| Left out | Use instead |
| --- | --- |
| `script.on_event`, `on_init`, `on_load`, `on_nth_tick` | `Event.add`, `Event.on_init`, ... (`utils/event.lua`) |
| `script.generate_event_name` | `Event.generate_event_name` |
| `script.set_event_filter` | nothing: a filter applies to every handler of the event |
| `commands.add_command` | `Command.add` (`utils/command.lua`) |

The files that implement those wrappers start with `-- luacheck: globals script` (or `commands`).
The list is `$left_out` in the script.

## Updating it

The script needs PowerShell 7 (`pwsh`), as the other scripts in `.github/scripts` do. From the repo
folder, give it a Factorio version, or a `runtime-api.json` you have already downloaded:

```
pwsh .github/scripts/luacheck-api.ps1 2.1.24
pwsh .github/scripts/luacheck-api.ps1 ~/Downloads/runtime-api.json
```

It rewrites the generated parts and the version in `.luacheckrc`'s
`-- Current Factorio Version` line, and leaves the rest of the file as it is. Then run
`luacheck .`: what it flags now is code that uses API the new version has removed or renamed.
