-- Counts what the restart message reports that nothing else tracks: the most players online at
-- once, and per player what they took down and how much landfill they placed.
local Event = require 'utils.event'
local Global = require 'utils.global'

local Public = {}

local data = {
    peak_players = 0,
    landfill_placed = 0,
    entities_removed_by_player_index = {},
    landfill_placed_by_player_index = {}
}

Global.register(data, function(tbl)
    data = tbl
end)

local landfill = 'landfill'

local function add(counts, player_index, amount)
    counts[player_index] = math.max(0, (counts[player_index] or 0) + amount)
end

-- Only the player's own force's entities count, so trees, rocks and ore don't.
local function is_players_entity(entity, player_index)
    local player = game.get_player(player_index)
    return player ~= nil and entity.valid and entity.force == player.force
end

Event.add(defines.events.on_player_joined_game, function()
    data.peak_players = math.max(data.peak_players, #game.connected_players)
end)

-- Taking something down counts once: when it's mined by hand, or when it's marked for robots to
-- take down (and no longer if the mark is cancelled).
Event.add(defines.events.on_player_mined_entity, function(event)
    local entity = event.entity
    if entity.valid and not entity.to_be_deconstructed() and is_players_entity(entity, event.player_index) then
        add(data.entities_removed_by_player_index, event.player_index, 1)
    end
end)

Event.add(defines.events.on_marked_for_deconstruction, function(event)
    local player_index = event.player_index
    if player_index and is_players_entity(event.entity, player_index) then
        add(data.entities_removed_by_player_index, player_index, 1)
    end
end)

Event.add(defines.events.on_cancelled_deconstruction, function(event)
    local player_index = event.player_index
    if player_index and is_players_entity(event.entity, player_index) then
        add(data.entities_removed_by_player_index, player_index, -1)
    end
end)

-- A player's landfill is what they place, by hand or with the robots from their personal roboport
-- (as with entities built in features/player_stats). The total is every tile placed, including
-- by roboport networks, whose robots belong to no one.
Event.add(defines.events.on_player_built_tile, function(event)
    local item = event.item
    if item and item.name == landfill then
        local count = #event.tiles
        data.landfill_placed = data.landfill_placed + count
        add(data.landfill_placed_by_player_index, event.player_index, count)
    end
end)

-- The player whose personal roboport the robot is from, if any.
local function get_robot_player(robot)
    local network = robot.valid and robot.logistic_network
    local cell = network and network.cells[1]
    local owner = cell and cell.owner
    if owner and owner.valid and owner.type == 'character' then
        return owner.player
    end
end

Event.add(defines.events.on_robot_built_tile, function(event)
    local item = event.item
    if not (item and item.name == landfill) then
        return
    end

    local count = #event.tiles
    data.landfill_placed = data.landfill_placed + count
    local player = get_robot_player(event.robot)
    if player then
        add(data.landfill_placed_by_player_index, player.index, count)
    end
end)

--- Returns the most players that have been online at once.
function Public.get_peak_players()
    return data.peak_players
end

--- Returns how many landfill tiles have been placed, by players and robots.
function Public.get_landfill_placed()
    return data.landfill_placed
end

--- Returns what the player has taken down and the landfill they placed.
function Public.get_for_player(player_index)
    return data.entities_removed_by_player_index[player_index] or 0, data.landfill_placed_by_player_index[player_index] or 0
end

return Public
