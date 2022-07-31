-- This module removes the non ore stacking recipes used by deadlock's beltboxes.
local Event = require 'utils.event'

return function()
    local allowed_recipes = {
        ["deadlock-stacks-stack-iron-ore"] = true,
        ["deadlock-stacks-unstack-iron-ore"] = true,
        ["deadlock-stacks-stack-copper-ore"] = true,
        ["deadlock-stacks-unstack-copper-ore"] = true,
        ["deadlock-stacks-stack-stone"] = true,
        ["deadlock-stacks-unstack-stone"] = true,
        ["deadlock-stacks-stack-coal"] = true,
        ["deadlock-stacks-unstack-coal"] = true,
        ["deadlock-stacks-stack-uranium-ore"] = true,
        ["deadlock-stacks-unstack-uranium-ore"] = true
    }

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

            if name:sub(1, #'deadlock-stacks') == 'deadlock-stacks' then
                game.forces.player.recipes[name].enabled = false
            end

            ::continue::
        end
    end)
end
