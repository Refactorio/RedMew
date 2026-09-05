# Factorio locale strings — guide for AI agents

This guide explains how player-facing strings work in this repository (and in Factorio
generally), so an AI agent can add, edit, or translate locale strings correctly.

Official references:
- <https://wiki.factorio.com/Tutorial:Localisation>
- <https://wiki.factorio.com/Rich_text>

## 1. Where strings live

- All translatable strings live in `locale/<lang>/*.cfg`, one folder per language code
  (`en`, `de`, `ru`, `pt-BR`, ...). File names inside a language folder are arbitrary;
  all `*.cfg` files in the folder are loaded by the game.
- **`locale/en/` is the source of truth.** It is also the runtime fallback: any key
  missing from a language falls back to the English text at runtime. (Fill it anyway —
  the release pipeline checks for gaps.)
- This repo splits strings by area (all names prefixed `redmew_`):

  | File | Contents |
  | --- | --- |
  | `redmew.cfg` | scenario description (shown in the map-listing UI) |
  | `redmew_command_text.cfg` | command descriptions and custom `/help` lines |
  | `redmew_common.cfg` | shared strings (`common.*` used across features) |
  | `redmew_features.cfg` | gameplay feature strings |
  | `redmew_gui.cfg` | GUI text |
  | `redmew_maps.cfg` | per-map strings |
  | `redmew_resources.cfg` | resource strings (sectionless `description=`) |
  | `redmew_utils.cfg` | utility module strings |

  Where new strings go: same file+section as sibling strings of the same feature.
  When adding new files, name them `redmew_<area>.cfg`.

## 2. File format rules

Files are INI-like (`.cfg`), UTF-8 **without BOM**, CRLF line endings in the working
tree on Windows (git stores them as LF; `.gitattributes` is empty, so this is purely a
`core.autocrlf` effect — **write the line ending style the file already uses**).

```ini
# Comment lines start with '#' (also ';' works). Comments are allowed anywhere.
[section_header]
key=value
```

- `[section]` headers begin a section; keys belong to the most recent header.
- `key=value` with **no whitespace around `=`** — whitespace is significant:
  `title =x` creates the key `title ` (with a trailing space), and lookups for
  `title` will fail. Likewise, everything after the first `=` is the value, verbatim.
- Sections can be referenced from code as `{'section.key'}`.
- Files may also contain top-level keys with **no section** (e.g. `description=...` in
  `redmew.cfg` / `redmew_resources.cfg`); these are referenced
  from code as `{'description'}` or set via metadata like `description.json`.
- Duplicate keys: the game silently uses the last one. Avoid duplicates.
- Values may contain `\n` for line breaks (literal backslash-n; the game renders it as
  a newline where newlines are supported).
- The `.travis/check_locale.sh` release check requires every non-`en` file to list its
  keys in the **same order as `en`** (it diffs key sequences). Keep order aligned with
  `en` when adding keys — do not sort alphabetically.

## 3. How keys are referenced from code

```lua
game.print({'item-name.iron-plate'})                         -- section.key
Game.player_print({'common.fail_no_target', target_name})    -- with 1 parameter
game.print({'admin_commands.regular_add_success', actor, target_name})  -- 2 parameters
{'', a, ': ', b}                                             -- concatenation form ('' key)
```

- The first element is `'section.key'` (or `''` for concatenation); the remaining
  elements are the parameters that fill `__1__`, `__2__`, ... **A LocalisedString
  accepts at most 20 parameters (`__1__`–`__20__`).**
- A section-less key like `{'description'}` is used for scenario descriptions.
- Player-facing strings should always be keys, not hardcoded English text.

## 4. Translation rules (values only)

- Translate **only the value**. Never change the key, never add/remove/reorder lines
  or sections.
- Parameter placeholders `__1__`, `__2__`, ... must be preserved (the multiset of
  placeholders must match the source). You may reorder them within the sentence when
  the target language's grammar requires it, but never drop or duplicate one, and
  don't renumber them — `__2__` always receives the 2nd parameter.
- Built-in tokens are copied verbatim (never translated, never modified):
  - `__CONTROL__name__` (e.g. `__CONTROL__toggle-console__`), `__CONTROL_KEY_SHIFT__`,
    `__CONTROL_LEFT_CLICK__`, `__CONTROL_RIGHT_CLICK__`, `__CONTROL_MODIFIER__name__`,
    `__ALT_CONTROL__n__name__`
  - `__ITEM__name__`, `__ENTITY__name__`, `__FLUID__name__`, `__TILE__name__`,
    `__PLANET__name__`
- Rich-text tags are untranslated and must stay balanced:
  `[color=...]...[/color]`, `[font=...]...[/font]`, `[item=...]`, `[entity=...]`,
  `[img=...]`, `[technology=...]`, `[planet=...]`, etc. Tag **contents are internal
  game identifiers — do not translate** (e.g. `[item=satellite]` stays as-is). Keep
  the tags around the same words they wrap in the source where possible.
- `\n` stays literally `\n` (do not replace with a real newline).
- Escape nothing else; `=` inside values is fine (only the first `=` separates).

### Plural forms

This repo uses the **standard double-underscore Factorio syntax**:

```
__plural_for_parameter__N__{selector1=text|selector2=text|rest=text}__
```

(We checked: there is **no single-underscore variant** in this repo.)

- `N` is the parameter number (e.g. `__2__`) whose value decides the plural branch.
- Selectors, in order of first match: exact number (`1=`), comma list (`2,3,4=`),
  `ends in 11`-style suffix rules (`ends in 1=`), multiple `ends in` (`ends in 1,ends in 2=`),
  `decimal=` (any fractional number), `rest=` (default). The branch text may itself
  contain `__1__`-style placeholders, including **repeating the plural parameter**
  (e.g. `few=__2__ рази|rest=__2__ раз` is valid).
- The plural parameter does not need to appear elsewhere in the string.
- Use the target language's plural rules, e.g.:
  - Russian/Ukrainian: `1=...|ends in 2,ends in 3,ends in 4=... (but not ends in 12,13,14)`...
  - For languages without grammatical number (e.g. zh-CN/zh-TW, ja, ko, tr?), a single
    `rest=` branch that ignores the number is fine (`{rest=...}`), and you may drop
    number words like "1" vs "2" distinctions.

### What stays English

Proper nouns may stay English when the target language conventionally keeps them
(player-facing map names, Discord, GitHub, RedMew, specific usernames, `/command`
names, in-game control names such as `toggle-console` inside `__CONTROL__...__`).
If in doubt, translate the sentence around them.

## 5. Pre-finish checklist

Before considering locale work done:

1. Every key in `locale/en/` exists in every `locale/<lang>/` (files too).
2. `locale/<lang>/*.cfg`:
   - UTF-8 **without BOM**;
   - keys listed in the same order as `en` (release-check requirement);
   - no whitespace around `=`;
   - CRLF/LF consistent with what the file already used (git normalizes at commit).
3. Placeholders: same multiset of `__N__` as English (reordering allowed).
4. Built-in tokens (`__ITEM__...__`, `__CONTROL__...__`, ...) identical to English.
5. Plural syntax `__plural_for_parameter__N__{...}__` with valid selectors; the
   parameter repeated across branches is fine.
6. Rich-text tags balanced and untranslated; contents (item/entity names) unchanged.
7. No duplicate keys in a section.
8. `luacheck .` passes (unrelated to locale, but it's the other CI gate).
9. Release check passes: `sh .travis/check_locale.sh` (expects key order == en order).
