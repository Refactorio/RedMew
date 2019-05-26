local Task = require 'utils.task'
local Token = require 'utils.token'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Command = require 'utils.command'
local Toast = require 'features.gui.toast'
local RS = require 'map_gen.shared.redmew_surface'
local HailHydra = require 'map_gen.shared.hail_hydra'
local Color = require 'resources.color_presets'
local Ranks = require 'resources.ranks'

-- Constants
local hail_hydra_data = {
    ['behemoth-spitter'] = {['behemoth-spitter'] = 0.01},
    ['behemoth-biter'] = {['behemoth-biter'] = 0.01}
}

-- Local var
local Public = {}

-- Global vars
local second_run = {}
local primitives = {
    apocalypse_now = nil
}

Global.register(
    {
        primitives = primitives,
        second_run = second_run
    },
    function(tbl)
        primitives = tbl.primitives
        second_run = tbl.second_run
    end
)

local biter_spawn_token =
    Token.register(
    function()
        local surface
        local player_force
        local enemy_force = game.forces.enemy

        surface = RS.get_surface()
        player_force = game.forces.player

        HailHydra.set_hydras(hail_hydra_data)
        HailHydra.set_evolution_scale(1)
        HailHydra.enable_hail_hydra()
        enemy_force.evolution_factor = 1

        local p_spawn = player_force.get_spawn_position(surface)
        local group = surface.create_unit_group {position = p_spawn}

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
                local biter = create_entity({name = aliens[i], position = spawn_pos})
                group.add_member(biter)
            end
        end

        group.set_command({type = defines.command.attack_area, destination = {0, 0}, radius = 500})
        Toast.toast_all_players(500, {'apocalypse.toast_message'})
    end
)

--- Begins the apocalypse
function Public.begin_apocalypse(_, player)
    local index
    if player and player.valid then
        index = player.index
    elseif not player then
        index = 0
    end

    -- Check if the apocalypse is happening or if it's the first run of the command.
    if primitives.apocalypse_now then
        Game.player_print({'apocalypse.apocalypse_already_running'}, Color.yellow)
        return
    elseif not second_run[index] then
        second_run[index] = true
        game.server_save('pre-apocalypse-' .. index)
        Game.player_print({'apocalypse.run_twice'})
        return
    end

    primitives.apocalypse_now = true
    game.print({'apocalypse.apocalypse_begins'}, Color.pink)
    Task.set_timeout(15, biter_spawn_token, {})
end

Command.add(
    'apocalypse',
    {
        description = {'command_description.apocalypse'},
        required_rank = Ranks.admin
    },
    Public.begin_apocalypse
)

return Public
