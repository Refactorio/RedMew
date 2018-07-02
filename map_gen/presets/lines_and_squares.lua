local b = require 'map_gen.shared.builders'
local Random = require 'map_gen.shared.random'

local track_seed1 = 1000
local track_seed2 = 2000

local track_block_size = 30
local track_lines = 50
local track_chance = 6 -- 1 in x

local h_track = {
    b.line_x(2),
    b.translate(b.line_x(2), 0, -3),
    b.translate(b.line_x(2), 0, 3),
    b.rectangle(2, 10),
    b.translate(b.rectangle(2, 10), 15, 0),
    b.translate(b.rectangle(2, 10), -15, 0)
}

h_track = b.any(h_track)
h_track = b.single_x_pattern(h_track, 30)

local v_track = {
    b.line_y(2),
    b.translate(b.line_y(2), -3, 0),
    b.translate(b.line_y(2), 3, 0),
    b.rectangle(10, 2),
    b.translate(b.rectangle(10, 2), 0, 15),
    b.translate(b.rectangle(10, 2), 0, -15)
}

v_track = b.any(v_track)
v_track = b.single_y_pattern(v_track, 30)

local random = Random.new(track_seed1, track_seed2)

local function do_track_lines(track_shape)
    local track_pattern = {}

    for _ = 1, track_lines do
        local shape
        if random:next_int(1, track_chance) == 1 then
            shape = track_shape
        else
            shape = b.empty_shape()
        end

        table.insert(track_pattern, shape)
    end

    return track_pattern
end

local h_tracks = do_track_lines(h_track)
h_tracks = b.grid_y_pattern(h_tracks, track_lines, track_block_size)

local v_tracks = do_track_lines(v_track)
v_tracks = b.grid_x_pattern(v_tracks, track_lines, track_block_size)

local tracks = b.any {h_tracks, v_tracks}

return tracks
