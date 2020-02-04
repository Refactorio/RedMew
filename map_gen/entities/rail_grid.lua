local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

local mymodule = {}

local function rot_pos(pos, rot)
    local ctr = {x = 15, y = 15}
    return {
        x = ctr.x + (pos.x - ctr.x) * rot.x - (pos.y - ctr.y) * rot.y,
        y = ctr.y + (pos.x - ctr.x) * rot.y + (pos.y - ctr.y) * rot.x
    }
end

local function rot_dir(dir, rot)
    local cnt = 2 * math.atan2(rot.y, rot.x) / math.pi
    return (dir + 2 * cnt) % 8
end

local rail_grid = {
    ['allway'] = {
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 4}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 1}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 12.5, ['y'] = 0.5}, ['direction'] = 4},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 17.5, ['y'] = 0.5}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 1}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 4}, ['direction'] = 4},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 3}, ['direction'] = 0},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 15, ['y'] = 3}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 6}, ['direction'] = 4},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 3}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 6}, ['direction'] = 6},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 8}, ['direction'] = 4},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 18, ['y'] = 8}, ['direction'] = 5},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 6}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 10}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 6, ['y'] = 10}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 6, ['y'] = 10}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 7}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 15.5, ['y'] = 6.5}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 7}, ['direction'] = 5},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 10}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 15.5, ['y'] = 9.5}, ['direction'] = 1},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 14.5, ['y'] = 9.5}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 24, ['y'] = 12}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 8, ['y'] = 12}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 13}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 11}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 13}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 11}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 22, ['y'] = 12}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 0.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 15}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 15}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 13}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 12.5, ['y'] = 12.5}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 13}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 15}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 15}, ['direction'] = 1},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 17.5, ['y'] = 12.5}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 29.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 3, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 8, ['y'] = 18}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 6, ['y'] = 18}, ['direction'] = 4},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 6.5, ['y'] = 14.5}, ['direction'] = 4},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 9.5, ['y'] = 15.5}, ['direction'] = 1},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 9.5, ['y'] = 14.5}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 15}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 15}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 17}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 17}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 15}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 15}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 22, ['y'] = 18}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 20.5, ['y'] = 15.5}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 20.5, ['y'] = 14.5}, ['direction'] = 5},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 23.5, ['y'] = 15.5}, ['direction'] = 0},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 27, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 0.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 19}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 17}, ['direction'] = 5},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 12.5, ['y'] = 17.5}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 19}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 17}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 17.5, ['y'] = 17.5}, ['direction'] = 5},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 24, ['y'] = 20}, ['direction'] = 5},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 29.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 20}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 22}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 18, ['y'] = 22}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 24, ['y'] = 20}, ['direction'] = 6},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 20}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 24}, ['direction'] = 7},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 24}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 23}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 18, ['y'] = 24}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 15.5, ['y'] = 20.5}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 14.5, ['y'] = 20.5}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 23}, ['direction'] = 7},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 26}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 14.5, ['y'] = 23.5}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 26}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 15, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 29}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 12.5, ['y'] = 29.5}, ['direction'] = 4},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 17.5, ['y'] = 29.5}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 29}, ['direction'] = 0},
    },
    ['tshape'] = {
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 12}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 5, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 12}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 25, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 0.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 7.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 15}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 15}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 22.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 29.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 3, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 15}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 17}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 17}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 15}, ['direction'] = 3},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 27, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 0.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 7.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 8.5, ['y'] = 17.5}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 17}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 19}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 19}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 17}, ['direction'] = 3},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 21.5, ['y'] = 17.5}, ['direction'] = 5},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 22.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 29.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 20}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 5, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 19}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 21}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 21}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 19}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 20}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 25, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 7.5, ['y'] = 20.5}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 23}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 21}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 23}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 23}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 21}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 23}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 22.5, ['y'] = 20.5}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 26}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 26}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 18, ['y'] = 26}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 26}, ['direction'] = 1},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 15.5, ['y'] = 24.5}, ['direction'] = 7},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 14.5, ['y'] = 24.5}, ['direction'] = 5},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 15, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 12.5, ['y'] = 29.5}, ['direction'] = 4},
        {['name'] = 'rail-chain-signal', ['position'] = {['x'] = 17.5, ['y'] = 29.5}, ['direction'] = 0},
    },
    ['straight'] = {
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 5, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 25, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'rail-signal', ['position'] = {['x'] = 1.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 3, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 27, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'rail-signal', ['position'] = {['x'] = 28.5, ['y'] = 17.5}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 5, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 17, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 21, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 25, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 19}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 29, ['y'] = 19}, ['direction'] = 2},
    },
    ['corner'] = {
        {['name'] = 'straight-rail', ['position'] = {['x'] = 1, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 3, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 8, ['y'] = 12}, ['direction'] = 3},
        {['name'] = 'rail-signal', ['position'] = {['x'] = 1.5, ['y'] = 12.5}, ['direction'] = 6},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 15}, ['direction'] = 1},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 3, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 15}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 13, ['y'] = 17}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 17}, ['direction'] = 5},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 15, ['y'] = 19}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 20}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 18, ['y'] = 22}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 23}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 10, ['y'] = 26}, ['direction'] = 0},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 15, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 27}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 29}, ['direction'] = 0},
    },
    ['ushape'] = {
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 4}, ['direction'] = 6},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 4}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 7}, ['direction'] = 7},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 7}, ['direction'] = 1},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 10}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 7}, ['direction'] = 3},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 10}, ['direction'] = 0},
        {['name'] = 'rail-signal', ['position'] = {['x'] = 7.5, ['y'] = 9.5}, ['direction'] = 5},
        {['name'] = 'big-electric-pole', ['position'] = {['x'] = 3, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 27, ['y'] = 15}, ['direction'] = 0},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 26, ['y'] = 20}, ['direction'] = 5},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 4, ['y'] = 20}, ['direction'] = 3},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 7, ['y'] = 23}, ['direction'] = 1},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 9, ['y'] = 23}, ['direction'] = 5},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 12, ['y'] = 26}, ['direction'] = 7},
        {['name'] = 'curved-rail', ['position'] = {['x'] = 20, ['y'] = 26}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 23, ['y'] = 23}, ['direction'] = 3},
        {['name'] = 'train-stop', ['position'] = {['x'] = 25, ['y'] = 15}, ['direction'] = 4},
    }
}

local paddings = {
    [2] = {
        {['name'] = 'straight-rail', ['position'] = {['x'] = 31, ['y'] = 11}, ['direction'] = 2},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 31, ['y'] = 19}, ['direction'] = 2},
    },
    [4] = {
        {['name'] = 'straight-rail', ['position'] = {['x'] = 11, ['y'] = 31}, ['direction'] = 0},
        {['name'] = 'straight-rail', ['position'] = {['x'] = 19, ['y'] = 31}, ['direction'] = 0},
    }
}


local function tbl2key(tbl)
    return tbl[1] .. ',' .. tbl[2]
end

local cities = {
    [tbl2key({6, -8})] = 'Edinburgh Waverley',
    [tbl2key({11, 0})] = 'Newcastle Central',
    [tbl2key({4, 9})] = 'Liverpool Lime Street',
    [tbl2key({9, 15})] = 'Birmingham New Street',
    [tbl2key({15, 21})] = 'London Euston',
    [tbl2key({4, 21})] = 'Bristol Temple Meads',
    [tbl2key({16, 15})] = 'Cambridge',
}

local function connect_line(s, e)
    local bitmap = global.bitmap
    for i = s[1], e[1] do
        if global.bitmap[i] == nil then
            bitmap[i] = {}
        end
        bitmap[i][s[2]] = 1
    end
    for j = s[2], e[2] do
        if bitmap[e[1]] == nil then
            bitmap[e[1]] = {}
        end
        bitmap[e[1]][j] = 1
    end
end

local function on_init()
    global.bitmap = {}
    connect_line({6, -8}, {6, 0})
    connect_line({6, 0}, {11, 0})
    connect_line({9, 0}, {9, 9})
    connect_line({4, 9}, {12, 9})
    connect_line({9, 15}, {16, 15})
    connect_line({12, 9}, {12, 21})
    connect_line({4, 21}, {15, 21})
end

Event.on_init(on_init)

local function build_intersection(type, origin, rot)
    local surface = RS.get_surface()
    for _, v in pairs(rail_grid[type]) do
        local pos = rot_pos(v.position, rot)
        local dir = rot_dir(v.direction, rot)
        local ety = surface.create_entity {name = v.name, position = {origin.x + pos.x, origin.y + pos.y}, force = 'neutral', direction = dir}
        if v.name == 'train-stop' then
            ety.backer_name = cities[tbl2key({origin.x / 32, origin.y / 32})]
        end
    end
end

-- dirs : {E, S, W, N}, array of 0/1
local function build_chunk(origin, dirs)
    local surface = RS.get_surface()
    local cnt = 0
    local sum = {x = 0, y = 0}
    local delta = {x = 1, y = 0}
    for dir, b in ipairs(dirs) do
        cnt = cnt + b
        sum = {x = sum.x + delta.x * b, y = sum.y + delta.y * b}
        delta = {x = -delta.y, y = delta.x}
        if b == 1 and paddings[dir * 2] ~= nil then
            -- build paddings
            for _, v in pairs(paddings[dir * 2]) do
                surface.create_entity {name = v.name, position = {origin.x + v.position.x, origin.y + v.position.y}, force = 'neutral', direction = v.direction}
            end
        end
    end

    if cnt == 4 then
        build_intersection('allway', origin, {x = 1, y = 0})
    elseif cnt == 3 then
        build_intersection('tshape', origin, {x = sum.y, y = -sum.x})
    elseif cnt == 2 then
        if sum.x == 0 and sum.y == 0 then
            build_intersection('straight', origin, {x = dirs[1], y = dirs[2]})
        else
            build_intersection('corner', origin, {x = (sum.y - sum.x) / 2, y = -(sum.y + sum.x) / 2})
        end
    elseif cnt == 1 then
        build_intersection('ushape', origin, {x = -sum.x, y = -sum.y})
    end
end

local function is_on_grid(gx, gy)
    local bitmap = global.bitmap
    if bitmap[gx] and bitmap[gx][gy] == 1 then
        return true
    else
        return false
    end
end

local function find_connections(gx, gy)
    local dd = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
    if is_on_grid(gx, gy) then
        local c = {}
        for _, d in ipairs(dd) do
            if is_on_grid(gx + d[1], gy + d[2]) then
                table.insert(c, 1)
            else
                table.insert(c, 0)
            end
        end
        return c
    else
        return {0, 0, 0, 0}
    end
end

function mymodule.on_chunk_generated(event)
    local bd_box = event.area
    local surface = event.surface
    local chunk_size = 32
    -- assert(chunk_size == bd_box.right_bottom.x - bd_box.left_top.x)
    -- assert(chunk_size == bd_box.right_bottom.y - bd_box.left_top.y)
    if surface ~= RS.get_surface() then
        return
    end

    local gx = bd_box.left_top.x / 32
    local gy = bd_box.left_top.y / 32

    if is_on_grid(gx, gy) then
        -- remove trees and resources
        for _, e in pairs(surface.find_entities_filtered {area = bd_box, type = 'tree'}) do
            e.destroy()
        end
        for _, e in pairs(surface.find_entities_filtered {area = bd_box, type = 'resource'}) do
            e.destroy()
        end
        for _, e in pairs(surface.find_entities_filtered {area = bd_box, type = 'simple-entity'}) do
            e.destroy()
        end
        for _, e in pairs(surface.find_entities_filtered {area = bd_box, force = 'enemy'}) do
            e.destroy()
        end
        build_chunk({x = gx * chunk_size, y = gy * chunk_size}, find_connections(gx, gy))
    end
end

return mymodule
