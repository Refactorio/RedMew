-- This module removes the non ore stacking recipes used by deadlock's beltboxes.
local Event = require 'utils.event'
local Token = require 'utils.token'
local Task = require 'utils.task'

local allowed_recipes = {
    ['deadlock-stacks-stack-iron-ore'] = true,
    ['deadlock-stacks-unstack-iron-ore'] = true,
    ['deadlock-stacks-stack-copper-ore'] = true,
    ['deadlock-stacks-unstack-copper-ore'] = true,
    ['deadlock-stacks-stack-stone'] = true,
    ['deadlock-stacks-unstack-stone'] = true,
    ['deadlock-stacks-stack-coal'] = true,
    ['deadlock-stacks-unstack-coal'] = true,
    ['deadlock-stacks-stack-uranium-ore'] = true,
    ['deadlock-stacks-unstack-uranium-ore'] = true
}

local function is_deadlock_stacks_recipe(name)
    return name:sub(1, #'deadlock-stacks') == 'deadlock-stacks'
end

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

return function()
    Event.add(defines.events.on_research_finished, function(event)
        local research = event.research
        if not research.valid then
            return
        end

        for _, effect in pairs(research.effects) do
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

    Event.on_configuration_changed(function()
        Task.set_timeout_in_ticks(1, disable_recipes_callback)
    end)
end
