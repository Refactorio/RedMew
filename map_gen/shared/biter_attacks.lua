--[[
    This module allows for massive biter attacks without inflicting lag spikes by scanning large areas at once.
    There are options in the config to regulate the following:
    Attacks sent against random players on timed intervals.
    Attacks sent on the launch of rockets.

    There is a command available in admin_commands.
    There is also a public function allowing the sending of attacks by other modules.
    Public.launch_attack takes a table of arguments and will send an attack against a specific entity or position.
]]
-- Dependencies
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'
local table = require 'utils.table'
local Event = require 'utils.event'
local Game = require 'utils.game'
local Command = require 'utils.command'
local RS = require 'map_gen.shared.redmew_surface'
local Ranks = require 'resources.ranks'
local Color = require 'resources.color_presets'

local config = global.config.biter_attacks -- The local copy of config should only be used during the control stage

-- Localized functions
local random = math.random
local insert = table.insert
local ceil = math.ceil

-- Constants
local defaults = {
    total_scan_radius = 5000,
    individual_scan_radius = 500 -- a 500 radius scan is < 0.5ms on avg
}

-- Local vars
local timed_attack_token
local setup_scans_token
local biter_scan_token
local Public = {}

-- Global tokens
local Attack_data = {
    attack_lockout = nil,
    enemy_unit_group = nil,
    scan_index = 1,
    biter_count = 0,
    attack_pos = nil,
    force_name = nil
}

Global.register(
    {
        Attack_data = Attack_data
    },
    function(tbl)
        Attack_data = tbl.Attack_data
    end
)

-- Local functions

--- Cleans the primitive data for a new attack
local function init_data(surface, scan_center)
    if Attack_data.enemy_unit_group then
        Attack_data.enemy_unit_group.destroy()
        Attack_data.enemy_unit_group = nil
    end

    if not surface or not surface.valid then
        return
    end

    Attack_data.enemy_unit_group = surface.create_unit_group {position = scan_center}
    Attack_data.scan_index = 1
    Attack_data.biter_count = 0
end

--- Calculates the number of biters to send for timed attacks according to the difficulty selected
-- @return <number>
local function calculate_biters()
    local multiplier = global.config.biter_attacks.timed_attacks.attack_difficulty
    return ceil((game.forces.enemy.evolution_factor * 100 * multiplier))
end

--- Take a large scan radius and break it into smaller pieces
-- Spirals from the middle outward (right first then clockwise)
-- @param data <table> contains:
-- scan_center <table> Position
-- total_scan_radius <number> radius of total scan desired
-- individual_scan_radius <number> radius of individual scans
-- @return <table> array of Positions (centers of scans)
local function split_scan_radius(data)
    local center, scan_size = data.scan_center, data.individual_scan_radius
    local scan_centers = {}
    local scan_diameter = scan_size * 2
    local num_scan_rows = math.ceil(data.total_scan_radius / scan_size) -- number of scans per row/column
    local total_scans = num_scan_rows ^ 2
    local x_offset = center.x or center[1]
    local y_offset = center.y or center[2]
    local dx, x, y = 0, 0, 0
    local dy = -1
    local half_rows = num_scan_rows / 2

    for i = 1, total_scans do
        if (-half_rows <= x and x <= half_rows) and (-half_rows < y and y <= half_rows) then
            scan_centers[i] = {(x * scan_diameter) + x_offset, (y * scan_diameter) + y_offset}
        end
        if x == y or (x < 0 and x == -y) or (x > 0 and x == 1 - y) then
            dx, dy = -dy, dx
        end
        x, y = x + dx, y + dy
    end

    return scan_centers
end

--- Sets up a queue of scans
-- @param data <table> for specifics see data param for Public.launch_attack
local function setup_scans(data)
    -- If an attack is already being setup, try again in a minute
    if Attack_data.attack_lockout then
        Task.set_timeout(60, setup_scans_token, data)
        return
    else
        Attack_data.attack_lockout = true
    end
    -- Initialize our data for this attack
    init_data(data.surface, data.scan_center)
    Attack_data.attack_pos = data.attack_pos or data.scan_center
    Attack_data.force_name = data.force -- allowed to be nil

    -- Split the large scan into parts
    local scan_centers =
        split_scan_radius(
        {
            scan_center = data.scan_center,
            total_scan_radius = data.total_scan_radius or defaults.total_scan_radius,
            individual_scan_radius = data.individual_scan_radius or defaults.individual_scan_radius
        }
    )

    -- Queue the scans
    Task.queue_task(
        biter_scan_token,
        {
            scans = scan_centers,
            surface = data.surface,
            scan_center = data.scan_center,
            biters_to_send = data.biters_to_send or calculate_biters(),
            radius = data.individual_scan_radius or defaults.individual_scan_radius,
            target_ent = data.target_ent -- allowed to be nil
        },
        #scan_centers
    )
end

--- Sends attacks against players on launches
local function rocket_launched(event)
    local entity = event.rocket_silo

    if not entity or not entity.valid or not entity.force == 'player' then
        return
    end

    local count = game.forces.player.rockets_launched
    local data = {
        surface = entity.surface,
        scan_center = entity.position,
        attack_pos = entity.position,
        biters_to_send = 1000,
        total_scan_radius = 10000,
        force = 'player'
    }

    if not global.config.biter_attacks.launch_attacks.first_launch_only and count > 1 then
        --send attack of 1k
        setup_scans(data)
        game.print({'biter_attacks.rocket_launch_attack'})
    elseif count == 1 then
        -- send every living biter
        data.biters_to_send = math.huge
        setup_scans(data)
        game.print({'biter_attacks.first_rocket_launch_attack'})
    end
end

-- Tokens
setup_scans_token = Token.register(setup_scans)

--- Issues attack orders to the enemy unit group
-- @param data <table> contains attack_pos (a Position), target_ent (a LuaEntity)
local function set_attack_command(data)
    local command_table = {
        type = defines.command.compound,
        structure_type = defines.compound_command.return_last,
        commands = {
            {
                type = defines.command.attack_area,
                destination = data.attack_pos,
                radius = 150,
                distraction = defines.distraction.by_anything
            },
            {
                type = defines.command.attack_area,
                destination = {0, 0},
                radius = 1500,
                distraction = defines.distraction.by_anything
            }
        }
    }

    local target_ent = data.target_ent
    if target_ent and target_ent.valid then
        insert(
            command_table.commands,
            1,
            {
                type = defines.command.attack,
                target = target_ent,
                distraction = defines.distraction.by_damage
            }
        )
    end

    Attack_data.enemy_unit_group.set_command(command_table)
    Debug.print({message = 'attack sent', num_sent = #Attack_data.enemy_unit_group.members})
    Attack_data.attack_lockout = nil
end

--- Scans a segment of map and enters the biters into the unit group
-- @param data <table> contains surface (a LuaSurface), scans (a table of scan centers)
-- radius (number), scan_center (a Position), target_ent (a LuaEntity), force (string)
biter_scan_token =
    Token.register(
    function(data)
        -- Localized data not passed through to next run
        local scan_index = Attack_data.scan_index
        local biter_count = Attack_data.biter_count
        local add_member = Attack_data.enemy_unit_group.add_member

        -- Localize function
        local biters_to_send = data.biters_to_send

        -- Scan the area and enter biters into the unit group
        local ents = data.surface.find_enemy_units(data.scans[scan_index], data.radius, Attack_data.force_name or 'player')
        for i = 1, #ents do
            biter_count = biter_count + 1
            add_member(ents[i])
            if biter_count >= biters_to_send then
                Debug.print({message = 'attack ordered', biter_count = biter_count, biters_to_send = biters_to_send})
                Attack_data.biter_count = biter_count
                set_attack_command({target_ent = data.target_ent, attack_pos = data.scan_center})
                return false
            end
        end

        Attack_data.biter_count = biter_count
        if scan_index == #data.scans then
            Debug.print({message = 'attack ordered', biter_count = biter_count, biters_to_send = biters_to_send})
            set_attack_command({target_ent = data.target_ent, attack_pos = data.scan_center})
            return false
        end

        Attack_data.scan_index = scan_index + 1
        return true
    end
)

--- Sets up the parameters for an auto attack on a random player
timed_attack_token =
    Token.register(
    function()
        local surface
        local scan_center
        local target_ent
        -- Pick a random online player
        local connected_players = game.connected_players
        local player = connected_players[random(#connected_players)]
        if player and player.valid then
            surface = player.surface
            scan_center = player.position

            local character = player.character
            if character and character.valid then
                target_ent = character
            end
        else
            surface = RS.get_surface()
            scan_center = game.forces.player.get_spawn_position(surface)
        end

        local data = {
            surface = surface,
            scan_center = scan_center,
            attack_pos = scan_center,
            target_ent = target_ent,
            total_scan_radius = defaults.total_scan_radius,
            individual_scan_radius = defaults.individual_scan_radius
        }
        setup_scans(data)
        Task.set_timeout(global.config.biter_attacks.timed_attacks.attack_frequency, timed_attack_token, {})
    end
)

-- Public functions

--- Launches a biter attack
-- @param data <table> contains:
--   surface <LuaSurface>
--   scan_center <table> Position center location of total scan radius
--   attack_pos <table> (optional, defaults to using scan_center) Position for biters to attack
--   biters_to_send <number> (optional, defaults to calling calculate_biters) the maximum number of biters to send as an attack
--   target_ent <LuaEntity> (optional) the entity for attacks to target, if given, takes priority over attack_pos
--   total_scan_radius <number> (optional) the maximum radius to scan for biters
--   individual_scan_radius <number> (optional) radius of the individual scans
--   force <string> (optional, default = 'player') the force to send an attack against
function Public.launch_attack(data)
    setup_scans(
        {
            surface = data.surface,
            scan_center = data.scan_center,
            attack_pos = data.attack_pos,
            biters_to_send = data.biters_to_send,
            target_ent = data.target_ent,
            total_scan_radius = data.total_scan_radius or defaults.total_scan_radius,
            individual_scan_radius = data.individual_scan_radius or defaults.individual_scan_radius,
            force = data.force
        }
    )
end

-- Events

if config.launch_attacks.enabled then
    Event.add(defines.events.on_rocket_launched, rocket_launched)
end

if config.timed_attacks.enabled then
    Event.on_init(
        function()
            Task.set_timeout(global.config.biter_attacks.timed_attacks.attack_frequency, timed_attack_token, {})
        end
    )
end

-- Commands

--- Launches a biter attack
local function biter_attack(args)
    local target_name = args.player
    local target = game.players[target_name]
    if not target or not target.valid then
        Game.player_print({'common.fail_no_target', target_name}, Color.fail)
        return
    end

    local biters_to_send = tonumber(args.quantity)
    if not biters_to_send then
        Game.player_print('Not a number', Color.white)
        return
    end

    local target_pos = target.position
    local surface = target.surface
    local spawn_loc = target.force.get_spawn_position(surface)
    local character = target.character
    if not character or not character.valid then
        character = nil
    end

    local data = {
        surface = surface,
        scan_center = target_pos,
        attack_pos = spawn_loc,
        biters_to_send = biters_to_send,
        target_ent = character
    }

    Public.launch_attack(data)
    Game.player_print('Attack ordered', Color.success)
end

Command.add(
    'biter-attack',
    {
        description = 'Orders the provided number of biters to attack the provided player ',
        arguments = {'player', 'quantity'},
        required_rank = Ranks.admin,
        allowed_by_server = true
    },
    biter_attack
)

return Public
