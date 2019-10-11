local ScenarioInfo = require 'features.gui.info'

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
        Turrets             1 coin
        Radars              1 coin
        Others              1 coin
    - Enemy players:        25 coins
    - Natives:
        Units               1-15 coins, 5% chance
        Worms               2-15 coins, 50% chance
        Spawners            2-10 coins, 100 % chance
- Sabotage enemy wilderness structures to slow the enemy team

Coming Soon:
    - Balance changes
    - New research mechanics
    - Defend strategic points for free rocket parts
    - Vote on game victory conditions:
        - King of the Hill
        - Capture the Flag
        - Team Death Match (Lol. NO)

Current Version: v0.2
]]
)

ScenarioInfo.set_new_info(
    [[
2019-10-11  v0.2
- Added water near spawn
- Changed biter coin drop rate
- Market tank purchase warns enemy team
- Balance changes
2019-10-1   v0.01
- Initial alpha tests
]]
)
