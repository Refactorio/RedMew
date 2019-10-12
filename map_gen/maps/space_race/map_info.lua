local ScenarioInfo = require 'features.gui.info'
local config = require 'map_gen.maps.space_race.config'

local entity_kill_rewards = config.entity_kill_rewards
local entity_drop_amount = config.entity_drop_amount

ScenarioInfo.set_map_name('RedMew - Space Race')
--ScenarioInfo.set_map_description('World at War! This is not a cold war, it is a radioative hot war')
ScenarioInfo.set_map_description('Reach space through strategy focused PVP.\nDirect and indirect PVP with safe zones and PVP areas. ')

ScenarioInfo.add_map_extra_info(
    [[
- Kill the enemy silo or launch a rocket to win
    - Build production infrastucture in your teams' safe zone
    - The enemy team can't reach you in your safe zone
    - Resources are plentiful in the wilderness
- Explore, exploit and defend the wilderness for extra resources and coins
- Engage in PVP and PVE to earn coins to enable research
    - Enemy structures:     (balance coming soon)
        Turrets             ]] .. entity_kill_rewards['gun-turret'] .. '-' .. entity_kill_rewards['artillery-turret'] ..  ' coins\n' ..
[[
        Radars              ]] .. entity_kill_rewards['radar'] .. ' coins\n' ..
[[
        Others              ]] .. entity_kill_rewards['default'] .. ' coin\n' ..
[[
    - Enemy players:        ]] .. config.player_kill_reward .. ' coins\n' ..
[[
    - Natives:
        Units               ]] .. entity_drop_amount['small-biter'].low .. '-' .. entity_drop_amount['behemoth-spitter'].high .. ' coins ' .. entity_drop_amount['small-biter'].chance * 100 .. '% chance\n' ..
[[
        Worms               ]] .. entity_drop_amount['small-worm-turret'].low .. '-' .. entity_drop_amount['behemoth-worm-turret'].high .. ' coins ' .. entity_drop_amount['small-worm-turret'].chance * 100 .. '% chance\n' ..
[[
        Spawners            ]] .. entity_drop_amount['spitter-spawner'].low .. '-' .. entity_drop_amount['biter-spawner'].high .. ' coins ' .. entity_drop_amount['biter-spawner'].chance * 100 .. '% chance\n' ..
[[
- Sabotage enemy wilderness structures to slow the enemy team

Coming Soon:
    - Balance changes
    - New research mechanics
    - Defend strategic points for free rocket parts
    - Vote on game victory conditions:
        - King of the Hill
        - Capture the Flag
        - Team Death Match (Lol. NO)

Current Version: ]] .. config.version
)

ScenarioInfo.set_new_info(
    [[
2019-10-12  v0.3
- Cliffs around rocket silo
- Market prices changed
- Wooden chests are now minable for both forces
- Refactoring of code
- Added central config file
2019-10-11  v0.2
- Added water near spawn
- Changed biter coin drop rate
- Market tank purchase warns enemy team
- Balance changes
2019-10-1   v0.01
- Initial alpha tests
]]
)
