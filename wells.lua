global.wells = {}

function refill_well()
    local current_tick = game.tick

    local wells = global.wells    
    -- iterate backwards to allow for removals.
    for i = #wells, 1, -1 do
        local well = wells[i]
        local entity = well.entity
        if not entity.valid then
            table.remove(wells, i)
        else
            local items_per_tick = well.items_per_tick
            local diff = current_tick - well.last_tick
            local count = diff * items_per_tick

            if count >= 1 then
                local whole = math.floor(count)
                entity.insert({ name = well.item, count = whole })

                local frac = count - whole
                well.last_tick = current_tick - frac / items_per_tick
            end  
        end      
    end    
end

local function validate(item, items_per_second)
    if not game.item_prototypes[item] then
        return "item is not valid"
    end

    if type(items_per_second) ~= "number" or items_per_second <= 0 then
        return "items per second must be a number and greater than 0"
    end
end

local function non_validating_create_well(entity, item, items_per_second)
    local well = 
    {
        entity = entity,
        item = item,
        items_per_tick = items_per_second / 60,
        last_tick = game.tick
    }

    table.insert(global.wells, well)
end

function create_well(entity, item, items_per_second)
    if not entity or entity.type ~= "container" then
        return "entity must be a container"
    end

    local error = validate(item, items_per_second)
    if error then
        return error
    end  

    non_validating_create_well(entity, item, items_per_second)  
end

function well_command(cmd)
    if not game.player.admin then
        cant_run(cmd.name)
        return
    end

    if cmd.parameter == nil then
        return
    end

    local params = {}
    for param in string.gmatch(cmd.parameter, "%S+") do table.insert(params, param) end

    if #params ~= 2 then
        game.player.print("Usage: /well <item> <items per second>.")
        return
    end

    local error = validate(params[1], tonumber(params[2]))
    if error then 
        game.player.print(error)
        return
    end

    local chest = game.player.surface.create_entity({name = "steel-chest", force = game.player.force, position = game.player.position})
    chest.minable = false;
    chest.destructible = false;

    non_validating_create_well(chest, params[1], tonumber(params[2])) 
end