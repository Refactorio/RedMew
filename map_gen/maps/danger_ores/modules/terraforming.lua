local b = require 'map_gen.shared.builders'
local Generate = require 'map_gen.shared.generate'
local Event = require 'utils.event'
local Global = require 'utils.global'
local RS = require 'map_gen.shared.redmew_surface'
local table = require 'utils.table'

local fast_remove = table.fast_remove
local concat = table.concat
local format = string.format
local rendering = rendering

return function(config)
    Generate.enable_register_events = false

    local start_size = config.start_size
    local outer_bounds = config.bounds or b.full_shape

    local pollution_data = {
        min_pollution = config.min_pollution or 400,
        max_pollution = config.max_pollution or 3500,
        pollution_increment = config.pollution_increment or 2.5
    }

    _G.terraforming_pollution_data = pollution_data

    local chunk_list = {index = 1}
    local surface

    Global.register_init({chunk_list = chunk_list, pollution_data = pollution_data}, function(tbl)
        tbl.surface = RS.get_surface()
        game.map_settings.pollution.enabled = true
    end, function(tbl)
        chunk_list = tbl.chunk_list
        pollution_data = tbl.pollution_data
        surface = tbl.surface
    end)

    local bounds = b.rectangle(start_size, start_size)

    -- One chunk of out-of-map tiles, reused for every locked chunk: only the positions change,
    -- so filling a chunk doesn't build 2048 new tables. set_tiles doesn't keep the table.
    local void_tiles = {}
    for i = 1, 32 * 32 do
        void_tiles[i] = {name = 'out-of-map', position = {0, 0}}
    end

    local function on_chunk(event)
        if surface ~= event.surface or RS.is_clearing() then
            return
        end

        local left_top = event.area.left_top
        local x, y = left_top.x, left_top.y

        if bounds(x + 0.5, y + 0.5) then
            Generate.do_chunk(event)
        else
            local i = 1
            for x1 = x, x + 31 do
                for y1 = y, y + 31 do
                    local position = void_tiles[i].position
                    position[1], position[2] = x1, y1
                    i = i + 1
                end
            end
            surface.set_tiles(void_tiles, true)

            if (outer_bounds(x + 0.5, y + 0.5)) then
                chunk_list[#chunk_list + 1] = {left_top = left_top, id = nil}
            end
        end
    end

    local function on_tick()
        local index = chunk_list.index

        if index > #chunk_list then
            chunk_list.index = 1
            return
        end

        local data = chunk_list[index]
        local pos = data.left_top
        local x, y = pos.x, pos.y
        local pollution = surface.get_pollution(pos)

        local current_min_pollution = pollution_data.min_pollution

        if pollution > current_min_pollution then
            fast_remove(chunk_list, index)

            local obj = data.obj
            if obj.valid then
                obj.destroy()
            end

            local area = {left_top = pos, right_bottom = {x + 32, y + 32}}
            local event = {surface = surface, area = area}
            Generate.schedule_chunk(event)

            if current_min_pollution < pollution_data.max_pollution then
                pollution_data.min_pollution = current_min_pollution + pollution_data.pollution_increment
            end

            return
        else
            local text = concat {format('%i', pollution), ' / ', current_min_pollution}
            local complete = pollution / current_min_pollution
            local color = {r = 1 - complete, g = complete, b = 0}

            local obj = data.obj
            if not obj then
                data.obj = rendering.draw_text {
                    text = text,
                    surface = surface,
                    target = {x + 16, y + 16},
                    color = color,
                    scale = 5
                }
            else
                obj.text = text
                obj.color = color
            end
        end

        chunk_list.index = index + 1
    end

    Event.add(defines.events.on_chunk_generated, on_chunk)
    Event.on_nth_tick(1, on_tick)
end
