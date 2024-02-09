-- this file contains all information related to map generation and control of new features.
-- a new feature has a chance to be added or increased every time a research is completed
-- new_names.lua will have the player and tag names to fit in with the theme
-- icebergs.lua will contain all the features themselves


local Icebergs = require 'map_gen.maps.april_fools.modules.icebergs'
--local names = require 'new_names'
local Event = require 'utils.event'
local Toast = require 'features.gui.toast'
-- require 'map_gen.shared.silly_player_names' -- no longer in shared?
local config = global.config

-- Setup the scenario map information because everyone gets upset if you don't
local ScenarioInfo = require 'features.gui.info'
ScenarioInfo.set_map_name('Pinguin')
ScenarioInfo.set_map_description('You are Pinguins in Antarctica!')
ScenarioInfo.set_map_extra_info('Watch out for Icebergs!')

--- Config
config.currency = nil
config.market.enabled = false
config.player_rewards.enabled = false

-- start map gen
local b = require 'map_gen.shared.builders'
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'

--[[Scale the map.
    The pictures are originally quite large to preserve detail.
    Will need to scale the map differently depending on which map you use.
    Antarctica map at .5 scale: Antarctica is 46 chunks tall
    Earth map at .5 scale: Antarctica is 4 chunks tall
]]

local map_scale = 0.1 --20

local pic = require 'map_gen.maps.april_fools.modules.antarctica'
--local pic = require 'map_gen.maps.april_fools.modules.antarctica_earth'
pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, map_scale, map_scale)

local map = b.change_tile(shape, false, "deepwater")
--Override map gen selections
RS.set_map_gen_settings(
    {
        MGSP.water_very_low
    }
)
--end map gen
--call all iceberg functions to initialize their events
--These are the features that can be enabled and scaled up to 5 times with research, and 10 times with rocket launches
Icebergs.rotate_inserter() --%Chance to randomly rotate an inserter when built
Icebergs.player_rotate() -- %Chance to randomly rotate an entity when rotated by a player
Icebergs.craft_pair() --%Chance to give the player an additional single underground belt or pipe-to-ground
Icebergs.crazy_turrets() --%Chance to change turret to enemy force, and give it ammo/fuel/power
Icebergs.golden_goose() --Randomly selected players will drop coins for a time, before changing targets
Icebergs.randomize_ores() --%Chance to change an ore to a random ore when a mining drill is placed
Icebergs.rotten_egg() --Randomly selected players will produce pollution for a time, before changing targets
Icebergs.floor_is_lava() --Does minor damage to a player when afk for even a second
Icebergs.alternative_biters() --Spawns a random biter on every player that has alt-mode turned on.
    --The biter is chosen from a list that expands every time this iceberg is enabled. Research can max this feature with the following:
    --{'small-biter','small-spitter','medium-biter','medium-spitter','big-biter'}
    -- Rocket launches can further add big spitters, and behemoth biters and spitters}
Icebergs.marathon() -- enables expensive research and crafting recipes. Research costs scale
Icebergs.crazy_toolbar() -- randomizes random quickbar slots of players
Icebergs.crazy_colors() -- randomizes a players color every time they send a message, enabled by default.

local iceberg_enable_percentage = .50
local toast_duration = 10

--[[iceberg_list:
    'rotate_inserter',
    'player_rotate',
    'craft_pair',
    'crazy_turrets',
    'golden_goose',
    'randomize_ores',
    'rotten_egg',
    'floor_is_lava',
    'alternative_biters',
    'marathon',
    'crazy_toolbar'
]]

local function iterate_icebergs(value, iceberg_max)
    local toast = 0
    if value == 1 then
        if global.rotate_inserter == 0 then
            global.rotate_inserter = 1
            toast = 1
        elseif global.rotate_inserter < iceberg_max  and toast == 0 then
            global.rotate_inserter = global.rotate_inserter + 1
            toast = 2
        end
        game.print('rotate_inserter level: ' .. global.rotate_inserter)
    elseif value == 2 then
        if global.player_rotate == 0 then
            global.player_rotate = 1
            toast = 1
        elseif global.player_rotate < iceberg_max  and toast == 0 then
            global.player_rotate = global.player_rotate + 1
            toast = 2
        end
        game.print('player_rotate level: ' .. global.player_rotate)
    elseif value == 3 then
        if global.craft_pair == 0 then
            global.craft_pair = 1
            toast = 1
        elseif global.craft_pair < iceberg_max  and toast == 0 then
            global.craft_pair = global.craft_pair + 1
            toast = 2
        end
        game.print('craft_pair level: ' .. global.craft_pair)
    elseif value == 4 then
        if global.crazy_turrets == 0 then
            global.crazy_turrets = 1
            toast = 1
        elseif global.crazy_turrets < iceberg_max  and toast == 0 then
            global.crazy_turrets= global.crazy_turrets + 1
            toast = 2
        end
        game.print('crazy_turrets level: ' .. global.crazy_turrets)
    elseif value == 5 then
        if global.golden_goose == 0 then
            global.golden_goose = 1
            toast = 1
        elseif global.golden_goose < iceberg_max  and toast == 0 then
            global.golden_goose= global.golden_goose + 1
            toast = 2
        end
        game.print('golden_goose level: ' .. global.golden_goose)
    elseif value == 6 then
        if global.randomize_ores == 0 then
            global.randomize_ores = 1
            toast = 1
        elseif global.randomize_ores < iceberg_max  and toast == 0 then
            global.randomize_ores= global.randomize_ores + 1
            toast = 2
        end
        game.print('randomize_ores level: ' .. global.randomize_ores)
    elseif value == 7 then
        if global.rotten_egg == 0 then
            global.rotten_egg = 1
            toast = 1
        elseif global.rotten_egg < iceberg_max  and toast == 0 then
            global.rotten_egg= global.rotten_egg + 1
            toast = 2
        end
        game.print('rotten_egg level: ' .. global.rotten_egg)
    elseif value == 8 then
        if global.floor_is_lava == 0 then
            global.floor_is_lava = 1
            toast = 1
        elseif global.floor_is_lava < iceberg_max  and toast == 0 then
            global.floor_is_lava= global.floor_is_lava + 1
            toast = 2
        end
        game.print('floor_is_lava level: ' .. global.floor_is_lava)
    elseif value == 9 then
        if global.alternative_biters == 0 then
            global.alternative_biters = 1
            toast = 1
        elseif global.alternative_biters < iceberg_max  and toast == 0 then
            global.alternative_biters= global.alternative_biters + 1
            toast = 2
        end
        game.print('alternative_biters level: ' .. global.alternative_biters)
    elseif value == 10 then
        if global.marathon == 0 then
            global.marathon = 1
            toast = 1
        elseif global.marathon < iceberg_max  and toast == 0 then
            global.marathon= global.marathon + 1
            toast = 2
        end
        game.print('marathon level: ' .. global.marathon)
    elseif value == 11 then
        if global.crazy_toolbar == 0 then
            global.crazy_toolbar = 1
            toast = 1
        elseif global.crazy_toolbar < iceberg_max  and toast == 0 then
            global.crazy_toolbar= global.crazy_toolbar + 1
            toast = 2
        end
        game.print('crazy_toolbar level: ' .. global.crazy_toolbar)
    end

    if toast == 0 then
        Toast.toast_all_players(toast_duration,'Everything seems normal... for now.')
        game.print('There appears to be no change to the iceberg, lucky Pinguins.')
    elseif toast == 1 then
        Toast.toast_all_players(toast_duration,'More snow has fallen! A new layer has been added to the iceberg!')
    elseif toast == 2 then
        Toast.toast_all_players(toast_duration,'The iceberg shifts, but you don\'t notice anything new.')
    end
end

Event.add(
    defines.events.on_research_finished,
    function()
        if math.random(100) <=100*iceberg_enable_percentage then
            iterate_icebergs(math.random(11), 5)
        else
            Toast.toast_all_players(toast_duration,'Everything seems normal... for now.')
            game.print('There appears to be no change to the iceberg, lucky Pinguins.')
    end end
)

Event.add(
    defines.events.on_rocket_launched,
    function()
        if math.random(100) <=100*2*iceberg_enable_percentage then
            iterate_icebergs(math.random(11), 10)
        else
            Toast.toast_all_players(toast_duration,'Everything seems normal... for now.')
            game.print('There appears to be no change to the iceberg, lucky Pinguins.')
        end
    end
)

return map
