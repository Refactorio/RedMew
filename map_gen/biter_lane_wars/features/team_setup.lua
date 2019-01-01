--[[TO DO:
- Setup teams
- Set each force spawn point and enemy force spawn point
]]

-- Dependencies
local BLW = global.map.blw
local Config = require ''

-- Localise globals
local BLW = global.map.BLW
local teams = BLW.teams
local players_per_team = Config.players_per_team
local team_map_interspace = BLW.map.team_map_interspace

-- Local constants
local number_of_teams = (#game.players_connected / players_per_team)
local origin = {x = 0, y = 0}

local function make_lanes()
    table_of_teams.spectator.base_spawn = origin
    local counter_x = origin.x + spectator_base_size

    for _, team in pairs(table_of_teams) do
        -- assign position of base's spawn, everything else can be relative to that
        team.player_spawn = {x = counter_x, y = origin.y}
        team.creep_spawn = {x = counter_x, y = origin.y+200}
        base_create(team)   -- each entry in table_of_teams would have a base_spawn and things like that
                            -- three creep spawns? That would allow us to use different shaped maps
        -- increment counter
        counter_x = counter_x + team_map_interspace

        -- setup a table to keep track of team market purchases.
            -- how many biters of each type have been bought
            -- what buffs are active
    end
end

local function on_init()
    game.forces.player.research_all_technologies()

    -- We don't want to do this here. It should be done when the game changes state from lobby to playing?
    game.create_force("team_1_players")
    game.create_force("team_1_creeps")
    game.create_force("team_2_players")
    game.create_force("team_2_creeps")

    -- We do want to do this here as this force will be the default
    game.create_force("spectator")

end

event.on_init(on_init)
