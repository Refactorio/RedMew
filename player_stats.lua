local Event = require 'utils.event'
local Global = require 'utils.global'

local last_player_positions = {}
local player_walk_distances = {}
local player_fish_earned = {}
local player_fish_spent = {}
local player_deaths = {}

Global.register(
    {
        last_player_positions = last_player_positions,
        player_walk_distances = player_walk_distances,
        player_fish_earned = player_fish_earned,
        player_fish_spent = player_fish_spent,
        player_deaths = player_deaths
    },
    function(tbl)
        last_player_positions = tbl.last_player_positions
        player_walk_distances = tbl.player_walk_distances
        player_fish_earned = tbl.player_fish_earned
        player_fish_spent = tbl.player_fish_spent
        player_deaths = tbl.player_deaths
    end
)

local function player_created(event)
    local index = event.player_index

    last_player_positions[index] = game.players[index].position
    player_walk_distances[index] = 0
    player_fish_earned[index] = 0
    player_fish_spent[index] = 0
    player_deaths[index] = {causes = {}, count = 0}
end

local function get_cause_name(cause)
    if cause then
        local name = cause.name
        if name == 'player' then
            local player = cause.associated_player
            if player and player.valid then
                return player.name
            else
                return 'Suicide'
            end
        else
            return name
        end
    end

    return 'No cause'
end

local function player_died(event)
    local player_index = event.player_index
    local cause = get_cause_name(event.cause)

    local data = player_deaths[player_index]
    data.count = data.count + 1

    local causes = data.causes
    local cause_count = causes[cause] or 0
    causes[cause] = cause_count + 1
end

local function tick()
    for _, p in ipairs(game.connected_players) do
        if (p.afk_time < 30 or p.walking_state.walking) and p.vehicle == nil then
            local index = p.index
            local last_pos = last_player_positions[index]
            local pos = p.position

            local d_x = last_pos.x - pos.x
            local d_y = last_pos.y - pos.y

            player_walk_distances[index] = player_walk_distances[index] + math.sqrt(d_x * d_x + d_y * d_y)
            last_player_positions[index] = pos
        end
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_died, player_died)
Event.on_nth_tick(62, tick)

local Public = {}

function Public.get_walk_distance(player_index)
    return player_walk_distances[player_index]
end

function Public.get_fish_earned(player_index)
    return player_fish_earned[player_index]
end

function Public.set_fish_earned(player_index, value)
    player_fish_earned[player_index] = value
end

function Public.change_fish_earned(player_index, amount)
    player_fish_earned[player_index] = player_fish_earned[player_index] + amount
end

function Public.get_fish_spent(player_index)
    return player_fish_spent[player_index]
end

function Public.set_fish_spent(player_index, value)
    player_fish_spent[player_index] = value
end

function Public.change_fish_spent(player_index, amount)
    player_fish_spent[player_index] = player_fish_spent[player_index] + amount
end

function Public.get_death_count(player_index)
    return player_deaths[player_index].count
end

-- Returns a dictionary of casue_name -> count
function Public.get_all_death_counts_by_casue(player_index)
    return player_deaths[player_index].causes or {}
end

return Public
