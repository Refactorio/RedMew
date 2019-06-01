local Event = require 'utils.event'

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
    local neighbours = entity.neighbours
    local strength = 0
    for _, v in pairs(neighbours) do
        strength = strength + 1
        for _, _ in pairs(v.neighbours) do
            strength = strength + 1
        end
    end
    return strength
end

local function heal(entity, damage, percentage, max)
    percentage = percentage <= max and percentage or max
    percentage = percentage >= 0 and percentage or 0
    entity.health = entity.health + (damage * percentage)
end

local function create_damaged_alert(target, entity)
    for _, player in pairs(game.connected_players) do
        player.add_custom_alert(target, {type = 'item', name = 'stone-wall'}, {'wall_breach.alert', entity.localised_name}, true)
    end
end

local function damage(entity, strength, boost, dmg, cause)
    create_damaged_alert(entity, cause)
    local force = cause.force
    strength = strength <= 13 and strength or 13
    dmg = (dmg * boost - dmg * (-0.075 * strength))
    dmg = dmg > 0 and dmg or 0
    entity.damage(dmg, force)
end

local function entity_damaged(event)
    local entity = event.entity
    local cause = event.cause

    if not valid(entity) or not valid(cause) then
        return
    end

    local name = entity.name

    if not (name == 'stone-wall' or name == 'gate') or not is_a_biter(cause) then
        return
    end

    local cause_name = cause.name
    local force = event.force
    if not valid(force) then
        return
    end
    local strength = wall_strength(entity)
    local dmg_dealt = event.final_damage_amount
    if strength > 6 then
        if cause_name == 'behemoth-biter' and not strength > 12 then
            damage(entity, strength, 1.5, dmg_dealt, cause)
        else
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
            damage(entity, strength, 2.5, dmg_dealt, cause)
        elseif cause_name == 'big-biter' then
            damage(entity, strength, 1.5, dmg_dealt, cause)
        else
            if cause_name == 'medium-biter' then
                heal(entity, dmg_dealt, 0.035 * strength - 2, 0.75)
            elseif cause_name == 'small-biter' then
                heal(entity, dmg_dealt, 0.05 * strength - 2, 0.85)
            end
        end
    end
end

Event.add(defines.events.on_entity_damaged, entity_damaged)
