--- Mod compatibility checker.
-- Lets a scenario declare which mods it needs, conflicts with, or merely works better with,
-- then handles the reporting for each case automatically.
--
-- Usage (top of a map/scenario file):
--   local ModCompatibility = require 'utils.mod_compatibility'
--   ModCompatibility.check {
--       dependencies = {{name = 'alien-biomes', version = '0.7.2'}, {name = 'redmew-data', version = '1.1.0'}},
--       incompatibles = {{name = 'some-conflicting-mod'}},
--       recommended = {{name = 'squeak-through-2'}},
--       discouraged = {{name = 'rate-calculator'}},
--   }
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Popup = require 'features.gui.popup'

local Public = {}

--- A mod to check for, with an optional minimum version.
---@class ModRef
---@field name string
---@field version string?

-- How long after a player is created before recommended/discouraged warnings are shown, in seconds.
local WARNING_DELAY_SECONDS = 10

--- Builds a human readable "name >= version" (or just "name") line per mod entry.
---@param mods ModRef[]
---@return string
local function format_mod_list(mods)
    local lines = {}
    for i, mod in pairs(mods) do
        if mod.version then
            lines[i] = ('  - %s >= %s'):format(mod.name, mod.version)
        else
            lines[i] = ('  - %s'):format(mod.name)
        end
    end
    return table.concat(lines, '\n')
end

--- Returns true if the mod is active and, when a version is given, at least that version.
---@param mod ModRef
---@return boolean
local function mod_satisfied(mod)
    local active_version = script.active_mods[mod.name]
    if not active_version then
        return false
    end
    if mod.version and helpers.compare_versions(active_version, mod.version) < 0 then
        return false
    end
    return true
end

--- Returns true if the mod is missing or below the required version.
---@param mod ModRef
---@return boolean
local function mod_missing(mod)
    return not mod_satisfied(mod)
end

--- Returns true if the mod is active (version, if given, is only used for the displayed message).
---@param mod ModRef
---@return boolean
local function mod_present(mod)
    return script.active_mods[mod.name] ~= nil
end

--- Runs `predicate` over `mods` and, if any match, throws `message` followed by the pretty-printed list.
-- Used for the two hard-fail checks (dependencies/incompatibles), which only differ in
-- which predicate selects the offending mods and what message is shown.
---@param mods ModRef[]
---@param predicate fun(mod: ModRef): boolean selects mods to report
---@param message string
local function error_if_any(mods, predicate, message)
    local matches = {}
    for _, mod in pairs(mods) do
        if predicate(mod) then
            matches[#matches + 1] = mod
        end
    end

    if #matches > 0 then
        error(('%s\n%s'):format(message, format_mod_list(matches)), 0)
    end
end

--- Soft suggestions and warnings, shown to a player as a popup dialog some time after they
-- join rather than thrown as an error, since neither of these prevent the scenario from working.
---@param player LuaPlayer
---@param recommended ModRef[]
---@param discouraged ModRef[]
local function show_soft_warnings(player, recommended, discouraged)
    if not player or not player.valid then
        return
    end

    local missing_recommended = {}
    for _, mod in pairs(recommended) do
        if not mod_satisfied(mod) then
            missing_recommended[#missing_recommended + 1] = mod
        end
    end

    local present_discouraged = {}
    for _, mod in pairs(discouraged) do
        if mod_present(mod) then
            present_discouraged[#present_discouraged + 1] = mod
        end
    end

    if #missing_recommended > 0 then
        Popup.player(
            player,
            { 'mod_compatibility.recommended_message', format_mod_list(missing_recommended) },
            { 'mod_compatibility.recommended_title' },
            'utility/warning_icon',
            'mod-compatibility-recommended'
        )
    end

    if #present_discouraged > 0 then
        Popup.player(
            player,
            { 'mod_compatibility.discouraged_message', format_mod_list(present_discouraged) },
            { 'mod_compatibility.discouraged_title' },
            'utility/danger_icon',
            'mod-compatibility-discouraged'
        )
    end
end

local show_soft_warnings_token = Token.register(function(params)
    show_soft_warnings(game.get_player(params.player_index), params.recommended, params.discouraged)
end)

--- The category keys understood by `Public.check`, each holding a `ModRef[]`.
local CATEGORIES = { 'dependencies', 'incompatibles', 'recommended', 'discouraged' }

--- Combines several mod-list tables into a single one suitable for `Public.check`.
-- Unlike `table.merge`/`table.meld`, which merge by key and therefore let the entries of one
-- list overwrite the same-indexed entries of another, this appends the arrays under each
-- category so every entry from every list is kept.
--
-- Usage:
--   ModCompatibility.check(ModCompatibility.combine(
--       require 'map_gen.maps.danger_ores.compatibility.angel.mod-list',
--       require 'map_gen.maps.danger_ores.compatibility.bob.mod-list'
--   ))
---@param ... table mod-list tables, each with any of the `CATEGORIES` keys
---@return table combined mod-list table
function Public.combine(...)
    local combined = {}
    for _, category in pairs(CATEGORIES) do
        combined[category] = {}
    end

    -- Per category, the index into `combined[category]` at which each mod name was first seen,
    -- so later duplicates can be deduped in place rather than appended again.
    local seen = {}
    for _, category in pairs(CATEGORIES) do
        seen[category] = {}
    end

    local lists = { ... }
    for _, list in pairs(lists) do
        for _, category in pairs(CATEGORIES) do
            local entries = list[category]
            if entries then
                local target = combined[category]
                local seen_category = seen[category]
                for _, mod in pairs(entries) do
                    local existing_index = seen_category[mod.name]
                    if not existing_index then
                        target[#target + 1] = mod
                        seen_category[mod.name] = #target
                    else
                        -- Same mod seen again: keep whichever pins the later version.
                        -- A missing version means "any", which loses to any pinned version.
                        local existing = target[existing_index]
                        if mod.version and (not existing.version or helpers.compare_versions(mod.version, existing.version) > 0) then
                            target[existing_index] = mod
                        end
                    end
                end
            end
        end
    end

    return combined
end

--- Validates and reports on the mods used by a scenario.
-- dependencies/incompatibles are checked immediately and error out the game if violated.
-- recommended/discouraged are checked per-player, 10 seconds after they join.
---@param args table
---@field dependencies ModRef[]? mods that MUST be enabled or the scenario breaks
---@field incompatibles ModRef[]? mods that must NOT be enabled or the scenario breaks
---@field recommended ModRef[]? mods that are not required but improve the experience
---@field discouraged ModRef[]? mods that are known to potentially cause issues but won't outright break the scenario
function Public.check(args)
    args = args or {}
    local dependencies = args.dependencies or {}
    local incompatibles = args.incompatibles or {}
    local recommended = args.recommended or {}
    local discouraged = args.discouraged or {}

    error_if_any(dependencies, mod_missing, 'Missing dependencies. Please check that the following mods have been correctly installed:')
    error_if_any(incompatibles, mod_present, 'Incompatible mods detected. Please remove the following mods:')

    if #recommended > 0 or #discouraged > 0 then
        Event.add(defines.events.on_player_created, function(event)
            Task.set_timeout(WARNING_DELAY_SECONDS, show_soft_warnings_token, { player_index = event.player_index, recommended = recommended, discouraged = discouraged })
        end)
    end
end

return Public
