--- Safety Ores, by R. Nukem, inspired by Zengief
-- ============================================================================

local DOC = require 'map_gen.maps.danger_ores.configuration'
local Event = require 'utils.event'
local RE = require 'map_gen.shared.entity_placement_restriction'
local SafetyOresConfig = require 'map_gen.maps.danger_ores.config.safety_ores'
local Scenario = require 'map_gen.maps.danger_ores.scenario'
local ScenarioInfo = require 'features.gui.info'
local Token = require 'utils.token'

ScenarioInfo.set_map_name('Danger Ores - Safety Ores')
ScenarioInfo.set_map_description([[
    Welcome to Safety Ores.

    Ore patches are the only stable ground on this world.
    All factory buildings must be placed on ores or they will collapse.]])
ScenarioInfo.set_map_extra_info([[
    Our engineers have only been able to build the following outside the stability of our ore patches:

    - rails
    - rail signals
    - power poles
    - offshore pumps
    - pumpjacks
    - pipes
    - vehicles
    - robots
]])

DOC.scenario_name = 'danger-ore-safety'
DOC.allowed_entities.enabled = false
DOC.container_dump.enabled = false
DOC.disable_mining_productivity.enabled = false
DOC.map_gen_settings.settings = SafetyOresConfig.map_gen_settings
DOC.prevent_quality_mining.enabled = false
DOC.rocket_launched.win_satellite_count = 100
DOC.technologies.enabled = false
DOC.terraforming.enabled = false
DOC.game.draw_resource_selection = true
DOC.game.technology_price_multiplier = 5
DOC.game.always_day = false
DOC.game.peaceful_mode = false
DOC.map_config.enabled = false

-- Whitelist allowed entities outside ore patches
RE.add_allowed(SafetyOresConfig.allowed_entities)

-- Global condition to allow an entity to be built
RE.set_keep_alive_callback(Token.register(function(entity)
    return entity.surface.count_entities_filtered{ area = entity.bounding_box, type = 'resource', limit = 1 } > 0
end))

-- Warning for players when their entities are destroyed
local function on_destroy(event)
    local player = event.player
    if not (player and player.valid) then
        return
    end
    player.create_local_flying_text{
        surface = player.surface,
        position = player.position,
        text = 'You can only build that on top of ores, the ground is too soft'
    }
end
Event.add(RE.events.on_restricted_entity_destroyed, on_destroy)

-- Spawn stone around pumpjacks so oil can be defended
local math_floor = math.floor
local SAFETY_RADIUS = 7 -- size in all directions from center. Total size = 2x+1
local SAFETY_ORE_AMOUNT = 1 -- every time a pumpjack is placed this much stone is added

local function on_built_pumpjack(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.name == 'pumpjack') then
        return
    end

    -- calculate center of bounding box
    local box = entity.bounding_box
    local center_x = math_floor((box.left_top.x + box.right_bottom.x) / 2)
    local center_y = math_floor((box.left_top.y + box.right_bottom.y) / 2)
    local get_tile = entity.surface.get_tile
    local create_entity = entity.surface.create_entity

    -- create a square of stone ore centered on the pumpjack
    for x = center_x - SAFETY_RADIUS, center_x + SAFETY_RADIUS do
        for y = center_y - SAFETY_RADIUS, center_y + SAFETY_RADIUS do
            if get_tile(x, y).collides_with('ground_tile') then
                create_entity{ name = 'stone', amount = SAFETY_ORE_AMOUNT, position = { x, y } }
            end
        end
    end
end
Event.add(defines.events.on_robot_built_entity, on_built_pumpjack)
Event.add(defines.events.on_built_entity, on_built_pumpjack)

Scenario.register(DOC)