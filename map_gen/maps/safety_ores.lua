---Safety Ores, by R. Nukem, inspired by Zengief
---all local resources
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local config = global.config
local RE = require 'map_gen.shared.entity_placement_restriction'
local Token = require 'utils.token'
---Scenario Info
ScenarioInfo.set_map_name('Safety Ores')
ScenarioInfo.set_map_description('Welcome to Safety Ores.\nOre patches are the only stable ground on this world. All factory buildings must be placed on ores or they will collapse.')
ScenarioInfo.set_map_extra_info(
    'Our engineers have only been able to build the following outside the stability of our ore patches:\n -rails \n -rail signals\n -power poles\n -offshore pumps\n -pumpjacks\n -pipes')
ScenarioInfo.set_new_info(
    [[
2024-02-08 - R. Nukem
- Initial Map Creation
]]
)
--- Market Config
config.currency = nil
config.market.enabled = false
config.player_rewards.enabled = false
config.redmew_qol.loaders = false
--- Ore Settings. Since we can only build on ore patches high size is recommended.
--- With high size, lower richness seems intuitive. Frequency is the big ???
local ore_size = 6
local ore_richness = 0.166
local ore_freq = 1
--- Create map_gen table for ores
local ore_settings = {
    autoplace_controls = {
        coal = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        },
        ['copper-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        },
        ['crude-oil'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        },
        ['iron-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        },
        stone = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        },
        ['uranium-ore'] = {
            frequency = ore_freq,
            richness = ore_richness,
            size = ore_size
        }
    }
}
--- Set map_gen settings
RS.set_map_gen_settings(
    {
		MGSP.default,
        ore_settings
    }
)
--- Set Restrictions
--- Items allowed everywhere
RE.add_allowed({
	'small-electric-pole',
	'medium-electric-pole',
	'big-electric-pole',
	'rail',
	'straight-rail',
	'curved-rail',
	'pumpjack',
	'pipe',
	'pipe-to-ground',
	'rail-signal',
	'rail-chain-signal',
	'offshore-pump'
	})
--- Everything else not allowed UNLESS on ores
RE.set_keep_alive_callback(
        Token.register(
            function(entity)
                if entity.surface.count_entities_filtered {area = entity.bounding_box, type = 'resource', limit = 1} > 0 then
                    return true
                end
            end
        )
    )
