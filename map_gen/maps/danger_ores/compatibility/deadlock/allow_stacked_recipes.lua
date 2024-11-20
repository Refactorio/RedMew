-- This module removes the non ore stacking recipes used by deadlock's beltboxes.
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'

local default_allowed_items = require 'map_gen.maps.danger_ores.compatibility.deadlock.allowed_items'

local function get_stacked_recipes(item_list)
    local allowed_recipes = {}
    for item_name, allowed in pairs(item_list) do
        allowed_recipes['deadlock-stacks-stack-'..item_name] = allowed
        allowed_recipes['deadlock-unstacks-stack-'..item_name] = allowed
    end
    return allowed_recipes
end

local function is_deadlock_stacks_recipe(name)
    return name:sub(1, #'deadlock-stacks') == 'deadlock-stacks'
end

return function(config_allowed_items)
    if not script.active_mods['deadlock-beltboxes-loaders'] then
        return
    end

    storage.config.redmew_qol.loaders = false
    local allowed_recipes = get_stacked_recipes(config_allowed_items or default_allowed_items)

    Event.add(defines.events.on_research_finished, function(event)
        local research = event.research
        if not research.valid then
            return
        end

        for _, effect in pairs(research.prototype.effects) do
            if effect.type ~= 'unlock-recipe' then
                goto continue
            end

            local name = effect.recipe
            if allowed_recipes[name] then
                goto continue
            end

            if is_deadlock_stacks_recipe(name) then
                game.forces.player.recipes[name].enabled = false
            end

            ::continue::
        end
    end)

    local disable_recipes_callback = Token.register(function()
        local recipes = game.forces['player'].recipes
        for name, recipe in pairs(recipes) do
            if allowed_recipes[name] then
                goto continue
            end

            if is_deadlock_stacks_recipe(name) then
                recipe.enabled = false
            end

            ::continue::
        end
    end)

    Event.on_configuration_changed(function()
        Task.set_timeout_in_ticks(1, disable_recipes_callback)
    end)
end
