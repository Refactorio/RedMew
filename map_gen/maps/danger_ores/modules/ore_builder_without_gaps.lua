local b = require 'map_gen.shared.builders'
local table = require 'utils.table'
local random = math.random
local binary_search = table.binary_search
local bnot = bit32.bnot

return function(ore_builder_config)
    local start_ore_shape = ore_builder_config.start_ore_shape
    local resource_patches = ore_builder_config.resource_patches
    local no_resource_patch_shape = ore_builder_config.no_resource_patch_shape
    local dense_patches = ore_builder_config.dense_patches

    return function(ore_name, amount, ratios, weighted)
        local start_ore = b.resource(b.full_shape, ore_name, amount)
        local total = weighted.total

        return function(x, y, world)
            if start_ore_shape(x, y) then
                return start_ore(x, y, world)
            end

            if not no_resource_patch_shape(x, y) then
                local resource_patches_entity = resource_patches(x, y, world)
                if resource_patches_entity then
                    return resource_patches_entity
                end
            end

            local i = random() * total
            local index = binary_search(weighted, i)
            if index < 0 then
                index = bnot(index)
            end

            local resource = ratios[index].resource
            local entity = resource(x, y, world)
            local tries = #ratios
            while(entity == nil and tries > 0) do
                entity = ratios[tries].resource(x, y, world)
                tries = tries - 1
            end

            dense_patches(x, y, entity)
            if entity then entity.enable_tree_removal = false end

            return entity
        end
    end
end