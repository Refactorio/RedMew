-- A module to prevent recipes from being unlocked by research. Accessed via the public functions.
local Event = require 'utils.event'
local Global = require 'utils.global'

local Public = {}

local recipes = {}

Global.register(
    {
        recipes = recipes
    },
    function(tbl)
        recipes = tbl.recipes
    end
)

Event.add(
    defines.events.on_research_finished,
    function(event)
        local p_force = game.forces.player
        local r = event.research
        for _, effect in pairs(r.effects) do
            local recipe = effect.recipe
            if recipe and recipes[recipe] then
                p_force.recipes[recipe].enabled = false
            end
        end
    end
)

Event.on_init(
    function()
        for recipe in pairs(recipes) do
            game.forces.player.recipes[recipe].enabled = false
        end
    end
)

--- Locks recipes, preventing them from being enabled by research.
-- Does not check if they should be enabled/disabled by research already completed.
-- @param tbl <table> an array of recipe strings
function Public.lock_recipes(tbl)
    for i = 1, #tbl do
        recipes[tbl[i]] = true
    end
end

--- Unlocks recipes, allowing them to be enabled by research.
-- Does not check if they should be enabled/disabled by research already completed.
-- @param tbl <table> an array of recipe strings
function Public.unlock_recipes(tbl)
    for i = 1, #tbl do
        recipes[tbl[i]] = nil
    end
end

return Public
