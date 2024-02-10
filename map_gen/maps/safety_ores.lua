--- Safety Ores, by R. Nukem, inspired by Zengief
--- all local resources
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local ScenarioInfo = require 'features.gui.info'
local config = global.config
local RE = require 'map_gen.shared.entity_placement_restriction'
local Token = require 'utils.token'
local Event = require 'utils.event'
--- local math functions
local floor = math.floor
--- Scenario Info
ScenarioInfo.set_map_name('Safety Ores')
ScenarioInfo.set_map_description('Welcome to Safety Ores.\nOre patches are the only stable ground on this world. All factory buildings must be placed on ores or they will collapse.')
ScenarioInfo.set_map_extra_info(
    'Our engineers have only been able to build the following outside the stability of our ore patches:\n -rails \n -rail signals\n -power poles\n -offshore pumps\n -pumpjacks\n -pipes\n-vehicles\n-robots')
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
--- Ore Settings. Since we can only build on ore patches high size is recommended.
--- With high size, lower richness seems intuitive. Frequency is the big ???
local ore_size = 6
local ore_richness = 0.166
local ore_freq = 0.166
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
            frequency = 0.25,
            richness = 2,
            size = 0.25
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
--- change enemy autoplace controls
local enemy_settings = {
	autoplace_controls = {
		['enemy-base'] = {
			frequency = 0.25,
			richness = 1,
			size = 1
            }
        }
}
--- Set map_gen settings
RS.set_map_gen_settings(
    {
		MGSP.default,
        ore_settings,
		enemy_settings
    }
)
--- Set Item Restrictions
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
	'offshore-pump',
	'train-stop',
	'pump',
	'car',
	'tank',
	'spidertron',
	'defender',
	'destroyer',
	'distractor',
	'construction-robot',
	'logistic-robot',
	'locomotive',
	'cargo-wagon',
	'fluid-wagon',
	'artillery-wagon'
	})
--- The logic for checking that there are resources under the entity's position
RE.set_keep_alive_callback(
        Token.register(
            function(entity)
				local box = entity.bounding_box
                if entity.surface.count_entities_filtered {area = box, type = 'resource', limit = 1} > 0 then
						return true
				end
            end
        )
    )
--- Warning for players when their entities are destroyed
local function on_destroy(event)
	local p = event.player
	if p and p.valid then
		p.surface.create_entity{name="flying-text", position = p.position, text = 'You can only build that on top of ores, the ground is too soft'}
	end
end
Event.add(RE.events.on_restricted_entity_destroyed, on_destroy)
--- Spawn stone around pumpjacks so oil can be defended
local function on_built_pumpjack(event)
	local size = 7 -- size in all directions from center. total size = 2x+1
	local density = 1 -- Every time a pumpjack is placed this much stone is added
	local entity = event.created_entity
	if not entity or not entity.valid then
		return
	end
--- calculate center of bounding box
	local box = entity.bounding_box
	local center_x = floor((box.left_top.x + box.right_bottom.x)/2)
	local center_y = floor((box.left_top.y + box.right_bottom.y)/2)
--- If a pumpjack is built, create a 2x+1 square of stone centered on the pumpjack
	if entity.name == 'pumpjack' then
		for x = center_x - size, center_x + size do
			for y = center_y - size, center_y + size do
				if entity.surface.get_tile(x, y).collides_with("ground-tile") then
					entity.surface.create_entity({name="stone", amount=density, position={x, y}})
				end
			end
		end
	end
end
Event.add(defines.events.on_robot_built_entity, on_built_pumpjack)
Event.add(defines.events.on_built_entity, on_built_pumpjack)
--- To Do:
