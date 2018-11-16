--[[
Softmod rewrite of https://mods.factorio.com/mod/Nightfall written by Yehn and used under the MIT license

Copyright 2018 Yehn

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----

Biters in polluted areas become more aggressive at night.
TODO: Look into triggering existing unit groups to attack in unison with the groups we generate.
]]--
local Event = require 'utils.event'
--basic interval for checks
local timeinterval = 2689 --2700 is ~45 seconds at 60 UPS
--how many chunks to process in a tick
local processchunk = 5

--states
local IDLE = 1
local BASE_SEARCH = 2
local ATTACKING = 3

local random = math.random
local insert = table.insert

local function biter_attack()
    local maxindex = #global.bases
    local surface = game.surfaces[1]
    for i=global.c_index, global.c_index+processchunk, 1 do
        if i > maxindex then
            -- we're done here
            global.state = IDLE
            break
        end
        if random() < surface.darkness then
            local base = global.bases[i]
            local group=surface.create_unit_group{position=base}
            for _, biter in ipairs(surface.find_enemy_units(base, 16)) do
                group.add_member(biter)
            end
            if #group.members==0 then
                group.destroy()
            else
                --autonomous groups will attack polluted areas independently
                group.set_autonomous()
                if _DEBUG then
                    game.print("sending biters")
                end
                --group.set_command{ type=defines.command.attack_area, destination=game.players[1].position, radius=200, distraction=defines.distraction.by_anything }
            end
        end
    end
    global.c_index = global.c_index + processchunk
    --Reset if we're moving to the next state.
    if global.state == IDLE then
        global.c_index = 1
        global.lastattack = game.tick
    end
end

local function shuffle_table( t )
    assert( t, "shuffle_table() expected a table, got nil" )
    local iterations = #t
    local j
    
    for i = iterations, 2, -1 do
        j = random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function find_bases()
    local get_pollution = game.surfaces[1].get_pollution
    local count_entities_filtered = game.surfaces[1].count_entities_filtered
    if global.c_index == 1 then
        global.bases = {}
    end
    local maxindex = #global.chunklist
    for i=global.c_index, global.c_index+processchunk, 1 do
        if i > maxindex then
            -- we're done with the search
            global.state = ATTACKING
            break
        end
        if get_pollution(global.chunklist[i]) > 0.1 then
            local chunkcoord = global.chunklist[i]
            if (count_entities_filtered{area={{chunkcoord.x-16, chunkcoord.y-16},{chunkcoord.x+16, chunkcoord.y+16}},
                    type = "unit-spawner"}) > 0 then                    
                insert(global.bases,chunkcoord)
            end
        end
    end
    global.c_index = global.c_index + processchunk
    --Reset if we're moving to the next state.
    if global.state == ATTACKING then
        global.c_index = 1
        shuffle_table(global.bases)
        if _DEBUG then
            game.print("bases added: " .. tostring(#global.bases))
        end
    end
end

local function on_chunk_generated(event)
    -- Track when new chunks are generated and add them on.
    -- NOTE: The game's debug menu can show potentially hundreds of ungenerated chunks
    -- It's normal for this count to lag behind chunks in the debug menu.
    if event.surface == game.surfaces[1] then
        local chunk = {}
        local coords = event.area.left_top
        chunk.x = coords.x+16
        chunk.y = coords.y+16
        insert(global.chunklist, chunk)
    end
end

local function on_tick()
    if global.state == BASE_SEARCH then
        -- This is called every tick while in this state
        -- But only a small amount of work is done per call.
        -- State will change when it's finished.
        find_bases()
    elseif global.state == ATTACKING then
        biter_attack()
    end
end

local function on_interval()
    if game.surfaces[1].darkness > 0.5
        and global.state == IDLE
        and game.tick >= global.lastattack + timeinterval
        and random() > 0.5
    then
        --  Search for bases, then attack
        global.state = BASE_SEARCH
        if _DEBUG then
            game.surfaces[1].print("entering attack mode") --for debug
        end
    end
end

local function on_init()
	global.bases = {}
	global.chunklist = {}
	global.state = IDLE
	--prevents attacks from happening too often
	global.lastattack = 0
	global.c_index=1
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_tick, on_tick)
Event.on_nth_tick(timeinterval, on_interval)
Event.on_init(on_init)
