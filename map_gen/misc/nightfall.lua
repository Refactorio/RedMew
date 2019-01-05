--[[
Softmod rewrite of https://mods.factorio.com/mod/Nightfall written by Yehn and used under the MIT license

Copyright 2018 Yehn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----

With Nightfall, biters in polluted areas become more aggressive at night.

TODO: Look into triggering existing unit groups to attack in unison with the groups we generate.
]] --

-- Dependencies
local Event = require 'utils.event'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'

local random = math.random
local insert = table.insert

-- config settings
-- basic interval for checks
local timeinterval = 2689 --2700 is ~45 seconds at 60 UPS
-- how many chunks to process in a tick
local processchunk = 5
-- end of config

-- states
local IDLE = 1
local BASE_SEARCH = 2
local ATTACKING = 3

-- create globals
local chunklist = {}
local data = {bases = {}, c_index = 1, state = 1, lastattack = 0}

Global.register(
    {
        chunklist = chunklist,
        data = data
    },
    function(tbl)
        chunklist = tbl.chunklist
        data = tbl.data
    end
)

--- Called each tick when in ATTACKING state, scans through _processchunk_ chunks
-- looking for biters and adding them to a group
local function biter_attack()
    local maxindex = #data.bases
    local surface = RS.get_surface()
    for i = data.c_index, data.c_index + processchunk, 1 do
        if i > maxindex then
            -- we reached the end of the table
            data.state = IDLE
            break
        end
        if random() < surface.darkness then
            local base = data.bases
            local group = surface.create_unit_group {position = base}

            for _, biter in pairs(surface.find_enemy_units(base, 16)) do
                group.add_member(biter)
            end

            if #group.members == 0 then
                group.destroy()
            else
                --autonomous groups will attack polluted areas independently
                group.set_autonomous()
                if _DEBUG then
                    game.print('[NIGHTFALL] sending biters to attack')
                end
            end
        end
    end
    data.c_index = data.c_index + processchunk
    --Reset if we're moving to the next state.
    if data.state == IDLE then
        data.c_index = 1
        data.lastattack = game.tick
        if _DEBUG then
            game.print('[NIGHTFALL] attack complete')
        end
    end
end

--- Called each tick when in BASE_SEARCH state, scans through _processchunk_ chunks
-- looking for unit spawners and adding them to the bases table, when done iterating
-- through chunklist it sets the state to ATTACKING
local function find_bases()
    local get_pollution = RS.get_surface().get_pollution
    local count_entities_filtered = RS.get_surface().count_entities_filtered
    if data.c_index == 1 then
        data.bases = {}
    end
    local maxindex = #chunklist
    for i = data.c_index, data.c_index + processchunk, 1 do
        if i > maxindex then
            -- we're done with the search
            data.state = ATTACKING
            break
        end
        if get_pollution(chunklist[i]) > 0.1 then
            local chunkcoord = chunklist[i]
            if
                (count_entities_filtered {
                    area = {{chunkcoord.x - 16, chunkcoord.y - 16}, {chunkcoord.x + 16, chunkcoord.y + 16}},
                    type = 'unit-spawner',
                    limit = 1
                }) > 0
             then
                insert(data.bases, chunkcoord)
            end
        end
    end
    data.c_index = data.c_index + processchunk
    --Reset our index and shuffle the table if we're moving to the next state.
    if data.state == ATTACKING then
        data.c_index = 1
        if #data.bases > 0 then
            table.shuffle_table(data.bases)
        end
        if _DEBUG then
            game.print('[NIGHTFALL] bases added: ' .. tostring(#data.bases))
            game.print('[NIGHTFALL] entering ATTACKING state')
        end
    end
end

--- When a chunk is generated, add it to the chunklist
local function on_chunk_generated(event)
    if event.surface == RS.get_surface() then
        local chunk = {}
        local coords = event.area.left_top
        chunk.x = coords.x + 16
        chunk.y = coords.y + 16
        insert(chunklist, chunk)
    end
end

--- Every tick, choose between searching for bases, preparing an attack, or doing nothing
-- See the definitions of the called function for further information
local function on_tick()
    if data.state == BASE_SEARCH then
        find_bases()
    elseif data.state == ATTACKING then
        biter_attack()
    end
end

--- Change us from idle to searching for bases if the conditions are met.
local function on_interval()
    if
        RS.get_surface().darkness > 0.5 and random() > 0.5 and data.state == IDLE and
            game.tick >= data.lastattack + timeinterval
     then
        data.state = BASE_SEARCH
        if _DEBUG then
            RS.get_surface().print('[NIGHTFALL] entering BASE_SEARCH state') --for debug
        end
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_tick, on_tick)
Event.on_nth_tick(timeinterval, on_interval)
