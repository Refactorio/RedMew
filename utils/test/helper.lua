local Public = {}

local surface_count = 0

local function get_surface_name()
    surface_count = surface_count + 1
    return 'test_surface' .. surface_count
end

local autoplace_settings = {
    tile = {
        treat_missing_as_default = false,
        settings = {
            ['grass-1'] = {frequency = 1, size = 1, richness = 1}
        }
    }
}

local autoplace_controls = {
    trees = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    ['enemy-base'] = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    coal = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    ['copper-ore'] = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    ['crude-oil'] = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    ['iron-ore'] = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    stone = {
        frequency = 1,
        richness = 1,
        size = 0
    },
    ['uranium-ore'] = {
        frequency = 1,
        richness = 1,
        size = 0
    }
}

local cliff_settings = {
    cliff_elevation_0 = 1024,
    cliff_elevation_interval = 10,
    name = 'cliff'
}

function Public.startup_test_surface(context, options)
    options = options or {}
    local name = options.name or get_surface_name()
    local area = options.area or {64, 64}

    local player = context.player
    local old_surface = player.surface
    local old_position = player.position
    local old_character = player.character

    local surface =
        game.create_surface(
        name,
        {
            width = area.x or area[1],
            height = area.y or area[2],
            autoplace_settings = autoplace_settings,
            autoplace_controls = autoplace_controls,
            cliff_settings = cliff_settings
        }
    )

    surface.request_to_generate_chunks({0, 0}, 32)
    surface.force_generate_chunk_requests()

    context:next(
        function()
            for k, v in pairs(surface.find_entities()) do
                v.destroy()
            end

            surface.destroy_decoratives {area = {{-32, -32}, {32, 32}}}

            player.character = nil
            player.teleport({0, 0}, surface)
            player.create_character()
        end
    )

    return function()
        player.character = nil
        player.teleport(old_position, old_surface)

        if old_character and old_character.valid then
            player.character = old_character
        end

        game.delete_surface(surface)
    end
end

return Public
