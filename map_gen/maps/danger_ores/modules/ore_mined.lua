-- Shows the ore the team has mined in the score bar, with a per-ore breakdown in its tooltip.
-- The counts come from the force's item production statistics on the map surface, so ore made by
-- other means (e.g. omnite or scrap processing) counts too.
local Config = require 'config'
local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'
local ScoreTracker = require 'utils.score_tracker'
local format_number = require 'util'.format_number

local concat = table.concat
local floor = math.floor

local score_name = 'ore-mined'
local update_interval = 60 * 10

local Public = {}

local ore_names

---Names of the items mined from solid resources, e.g. iron-ore, coal and stone, sorted by name
local function get_ore_names()
    if ore_names then
        return ore_names
    end

    local seen = {}
    ore_names = {}
    for _, resource in pairs(prototypes.get_entity_filtered({{filter = 'type', type = 'resource'}})) do
        local mineable = resource.mineable_properties
        if mineable.minable and resource.resource_category == 'basic-solid' and mineable.products then
            for _, product in pairs(mineable.products) do
                if product.type == 'item' and not seen[product.name] then
                    seen[product.name] = true
                    ore_names[#ore_names + 1] = product.name
                end
            end
        end
    end
    table.sort(ore_names)

    return ore_names
end

---Ore produced on the map surface, all qualities together
---@return table<string, number> counts by ore name
---@return number total
function Public.get_ore_mined()
    local stats = game.forces.player.get_item_production_statistics(RS.get_surface_name())
    local counts, total = {}, 0
    for _, name in pairs(get_ore_names()) do
        local count = 0
        for quality in pairs(prototypes.quality) do
            count = count + stats.get_input_count({name = name, quality = quality})
        end
        counts[name] = count
        total = total + count
    end

    return counts, total
end

---"Ore mined: 12,412,880" followed by one line per mined ore, most mined first
local function score_tooltip()
    local counts, total = Public.get_ore_mined()
    local header = {'danger_ores.ore_mined_tooltip', format_number(total)}
    if total <= 0 then
        return header
    end

    local mined = {}
    for name, count in pairs(counts) do
        if count > 0 then
            mined[#mined + 1] = name
        end
    end
    table.sort(mined, function(a, b)
        if counts[a] == counts[b] then
            return a < b
        end
        return counts[a] > counts[b]
    end)

    local lines = {}
    for i, name in ipairs(mined) do
        local count = counts[name]
        lines[i] = concat({'\n[item=', name, '] ', format_number(count, true), ' (', floor(count / total * 100 + 0.5), '%)'})
    end

    return {'', header, concat(lines)}
end

function Public.register()
    ScoreTracker.register(score_name, {'danger_ores.ore_mined'}, '[img=item.electric-mining-drill]', score_tooltip)

    -- show it next to the rocket scores
    local global_to_show = Config.score.global_to_show
    local position = #global_to_show + 1
    for i, name in ipairs(global_to_show) do
        if name == 'rockets-launched' then
            position = i + 1
        end
    end
    table.insert(global_to_show, position, score_name)

    Event.on_nth_tick(update_interval, function()
        local _, total = Public.get_ore_mined()
        ScoreTracker.set_for_global(score_name, total)
    end)
end

return Public
