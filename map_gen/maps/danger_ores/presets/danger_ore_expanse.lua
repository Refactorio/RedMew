local DOC = require 'map_gen.maps.danger_ores.configuration'
local Config = require 'config'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'

ScenarioInfo.set_map_name('Danger Ores - Expanse')
ScenarioInfo.set_map_description([[
  DangerOres meets The Expanse!

  Clear the ore to expand the base,
  focus mining efforts on specific sectors to ensure
  proper material ratios, consume as much resources as possible!

                            -- AND --

  Feed the hungry blue chests with the materials they require.
  The Elder Tree and the Infinity Stone you find at spawn will
  provide you with all the wood and ores you ever desired.
]])
ScenarioInfo.add_map_extra_info([[
  This map is split in three sectors [item=iron-ore] [item=copper-ore] [item=coal].
  Each sector has a main resource and the other resources at a lower ratio.

  You may not build the factory on ore patches. Exceptions:
  [item=burner-mining-drill] [item=electric-mining-drill] [item=pumpjack] [item=small-electric-pole] [item=medium-electric-pole] [item=big-electric-pole] [item=substation] [item=car] [item=tank] [item=spidertron] [item=locomotive] [item=cargo-wagon] [item=fluid-wagon] [item=artillery-wagon]
  [item=transport-belt] [item=fast-transport-belt] [item=express-transport-belt]  [item=underground-belt] [item=fast-underground-belt] [item=express-underground-belt] [item=rail] [item=rail-signal] [item=rail-chain-signal] [item=train-stop]

  The map size is restricted by the Hungry Chests. Provide the requested materials to unlock new chunks.
  Use the Elder Tree [entity=tree-01], the Infinity Rock [entity=huge-rock], and the Precious Oil patch [entity=crude-oil] located at spawn [gps=0,0.redmew]
  to draw more resources when in need, but always favor Danger Ores first if you can.
  If you find yourself stuck with the requests, insert a Coin [item=coin] into the Hungry Chest [item=requester-chest] to reroll the request.
  You can fulfill part of the request & then reroll to change the remaining part (it will always reroll based on its remaining content to be fulfilled).
  Unlocking new land may or may not reward you with another Coin.
]])
ScenarioInfo.set_new_info([[
  2024-08-01:
      - Fixed allowed entities list with Mk2-3 drills
      - Fixed typos in description
  2024-04-08:
      - Forked from DO/terraforming
      - Added DO/expanse
      - Lowered tech multiplier 25 > 5
  2024-04-17:
      - Fixed incorrect request computation
      - Fixed persistent chests on new chunk unlocks
      - Added chests for each new expansion border
      - Reduced pre_multiplier from 0.33 >s 0.20
]])

Config.market.enabled = false
Config.player_rewards.enabled = true
Config.player_create.starting_items = {
  { count =  1, name = 'burner-mining-drill' },
  { count =  1, name = 'stone-furnace' },
  { count =  1, name = 'wood' },
  { count =  1, name = 'pistol' },
  { count = 20, name = 'firearm-magazine' },
  { count =  5, name = 'coin' },
}

DOC.scenario_name = 'danger-ore-expanse'
DOC.game.technology_price_multiplier = 5
DOC.rocket_launched.win_satellite_count = 100

local expanse = require 'map_gen.maps.danger_ores.modules.expanse'
expanse({ start_size = 8 * 32 }) -- 8x32

return Scenario.register(DOC)
