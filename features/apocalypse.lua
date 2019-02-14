local table = require 'utils.table'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Game = require 'utils.game'
local Toast = require 'features.gui.toast'
local RS = require 'map_gen.shared.redmew_surface'
local HailHydra = require 'map_gen.shared.hail_hydra'

local clear_table = table.clear_table

local Public = {}

local hydra_config = {
    ['behemoth-spitter'] = {['behemoth-spitter'] = 0.01},
    ['behemoth-biter'] = {['behemoth-biter'] = 0.01}
}

local biter_spawn_token =
    Token.register(
    function(data)
        local surface = data.surface
        local group = data.group
        local p_spawn = data.p_spawn

        local create_entity = surface.create_entity

        local aliens = {
            'behemoth-biter',
            'behemoth-biter',
            'behemoth-spitter',
            'behemoth-spitter'
        }

        for i = 1, #aliens do
            local spawn_pos = surface.find_non_colliding_position('behemoth-biter', p_spawn, 300, 1)
            if spawn_pos then
                local biter = create_entity {name = aliens[i], position = spawn_pos}
                group.add_member(biter)
            end
        end

        group.set_command({type = defines.command.attack_area, destination = {0, 0}, radius = 500})
        Toast.toast_all_players(500, 'The end times are here. The four biters of the apocalypse have been summoned. Repent as the aliens take back what is theirs.')
    end
)

function Public.begin_apocalypse(args, player)
    if args.confirmation ~= 'end this map' then
        Game.player_print('You must use /apocalypse end this map')
        return
    end

    if global.apocalypse_now then
        return
    end
    game.server_save('pre-apocalypse')
    global.apocalypse_now = true
    local surface
    local player_force
    local enemy_force = game.forces.enemy

    if player and player.valid then
        surface = player.surface
        player_force = player.force
    else
        surface = RS.get_surface()
        player_force = game.forces.player
    end

    local hydras = global.config.hail_hydra.hydras
    clear_table(hydras)
    for k, v in pairs(hydra_config) do
        hydras[k] = v
    end
    HailHydra.enable_hail_hydra()
    enemy_force.evolution_factor = 1

    local p_spawn = player_force.get_spawn_position(surface)
    local group = surface.create_unit_group {position = p_spawn}

    game.print('The ground begins to rumble. It seems as if the world itself is coming to an end.')

    Task.set_timeout(
        60,
        biter_spawn_token,
        {
            p_spawn = p_spawn,
            group = group,
            surface = surface
        }
    )
end

return Public
