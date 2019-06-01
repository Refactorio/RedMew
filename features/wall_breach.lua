local Event = require 'utils.event'
local RS = require 'map_gen.shared.redmew_surface'

local function valid(obj)
    return obj and obj.valid
end

local function is_a_biter(entity)
    if not valid(entity) then
        return false
    end

    if entity.name == 'small-biter' or entity.name == 'medium-biter' or entity.name == 'big-biter' or entity.name == 'behemoth-biter' then
        return true
    end
end

local function wall_strength(entity)
    return RS.get_surface().count_entities_filtered {
        position = entity.position,
        radius = 2.5,
        name = {'stone-wall', 'gate'}
    }
end

local function heal(entity, damage, percentage, max)
    percentage = percentage <= max and percentage or max
    percentage = percentage >= 0 and percentage or 0
    entity.health = entity.health + (damage * percentage)
end

local function create_damaged_alert(target, entity)
    for _, player in pairs(game.connected_players) do
        player.add_custom_alert(target, {type = 'item', name = "stone-wall"}, {'', 'a ', entity.localised_name, ' is breaking through a weak spot in our defences!'}, true)
    end
end

local function entity_damaged(event)
    local entity = event.entity
    local cause = event.cause

    if not valid(entity) and not valid(cause) then
        return
    end

    local name = entity.name

    if not (name == 'stone-wall' or name == 'gate') and not is_a_biter(cause) then
        return
    end

    local cause_name = cause.name
    local damage = entity.damage
    local force = event.force
    if not valid(force) then
        return
    end
    local strength = wall_strength(entity)
    local amount = 921 / strength --Walls and gates have resistance.
    if strength >= 6 then
        if cause_name == 'behemoth-biter' and not strength >= 10 then
            damage(amount * 0.75, force)
            create_damaged_alert(entity, cause)
        else
            local dmg_dealt = event.final_damage_amount
            if cause_name == 'behemoth-biter' then
                heal(entity, dmg_dealt, 0.035 * strength - 12, 0.5)
            elseif cause_name == 'big-biter' then
                heal(entity, dmg_dealt, 0.035 * strength - 5, 0.75)
            elseif cause_name == 'medium-biter' then
                heal(entity, dmg_dealt, 0.05 * strength, 0.85)
            elseif cause_name == 'small-biter' then
                heal(entity, dmg_dealt, 0.067 * strength, 0.9)
            end
        end
    else
        if cause_name == 'behemoth-biter' then
            damage(amount * 1.2, force)
            create_damaged_alert(entity, cause)
        elseif cause_name == 'big-biter' then
            damage(amount * 0.5, force)
            create_damaged_alert(entity, cause)
        else
            local dmg_dealt = event.final_damage_amount
            if cause_name == 'medium-biter' then
                heal(entity, dmg_dealt, 0.035 * strength - 2, 0.75)
            elseif cause_name == 'small-biter' then
                heal(entity, dmg_dealt, 0.05 * strength - 2, 0.85)
            end
        end
    end
end

Event.add(defines.events.on_entity_damaged, entity_damaged)
