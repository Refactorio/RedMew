local Event = require 'utils.event'
local Game = require 'utils.game'
local Token = require 'utils.token'
local Task = require 'utils.schedule'
local Global = require 'utils.global'
local Queue = require 'utils.q'

local Map = require 'map_gen.combined.tetris.shape'
require 'map_gen.combined.tetris.tetrimino'(Map)

local insert = table.insert

local move_queue = Queue.new()
local active_tetri_position = {x = 0, y = - 160}
local tetri_spawn_position = {x = 0, y = - 160}
local collision_box = {}

Global.register({
        move_queue,
        active_tetri_position,
        tetri_spawn_position,
        collision_box,
    },
    function(tbl)
        move_queue = tbl.move_queue
        active_tetri_position = tbl.active_tetri_position
        tetri_spawn_position = tbl.tetri_spawn_position
        collision_box = tbl.collision_box
    end
)


if Map.get_map() then
    local surfaces = {
        ['nauvis'] = Map.get_map(),
    }
    require ("map_gen.shared.generate_not_threaded"){surfaces = surfaces}
end

local worker = nil
worker =
    Token.register(
    function()
        local quad =  Queue.pop(move_queue)
        if quad then
            Task.set_timeout_in_ticks(1, worker)
            local surface = quad.surface
            local direction = quad.direction
            local x = quad.x
            local y = quad.y
            local x_offset = quad.x_offset
            local y_offset = quad.y_offset
            move_qchunk(surface, x, y, x_offset, y_offset)
        end
    end
)

Event.on_nth_tick(61, function() 
        if game.tick == nil then return end
end)