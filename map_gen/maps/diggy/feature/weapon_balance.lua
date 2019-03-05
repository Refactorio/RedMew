local Event = require 'utils.event'
local floor = math.floor

local player_ammo_starting_modifiers = {
    ['artillery-shell'] = -0.75,
    ['biological'] = -0.5,
    ['bullet'] = -0.25,
    ['cannon-shell'] = -0.15,
    ['capsule'] = -0.5,
    ['combat-robot-beam'] = -0.5,
    ['combat-robot-laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = -0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.33,
    ['laser-turret'] = -0.50,
    ['melee'] = 1,
    ['railgun'] = 0,
    ['rocket'] = -0.4,
    ['shotgun-shell'] = -0.20
}

local player_ammo_research_modifiers = {
    ['artillery-shell'] = -0.75,
    ['biological'] = -0.5,
    ['bullet'] = -0.20,
    ['cannon-shell'] = -0.15,
    ['capsule'] = -0.5,
    ['combat-robot-beam'] = -0.5,
    ['combat-robot-laser'] = -0.5,
    ['electric'] = -0.6,
    ['flamethrower'] = -0,
    ['grenade'] = -0.5,
    ['landmine'] = -0.5,
    ['laser-turret'] = -0.50,
    ['melee'] = -0.5,
    ['railgun'] = -0.5,
    ['rocket'] = -0.4,
    ['shotgun-shell'] = -0.20
}

local player_turrets_research_modifiers = {
    ['gun-turret'] = -0.5,
    ['laser-turret'] = -0.50,
    ['flamethrower-turret'] = -0.25
}

local function init_weapon_damage()
    local forces = game.forces
    local p_force = forces.player

    for k, v in pairs(player_ammo_starting_modifiers) do
        p_force.set_ammo_damage_modifier(k, v)
    end
end

local function research_finished(event)
    local r = event.research
    local p_force = r.force

    for _, e in ipairs(r.effects) do
        local t = e.type

        if t == 'ammo-damage' then
            local category = e.ammo_category
            local factor = player_ammo_research_modifiers[category]

            if factor then
                local current_m = p_force.get_ammo_damage_modifier(category)
                local m = e.modifier
                p_force.set_ammo_damage_modifier(category, floor((current_m + factor * m)*10)*0.1)
            end
        elseif t == 'turret-attack' then
            local category = e.turret_id
            local factor = player_turrets_research_modifiers[category]

            if factor then
                local current_m = p_force.get_turret_attack_modifier(category)
                local m = e.modifier
                p_force.set_turret_attack_modifier(category, floor((current_m + factor * m)*10)*0.1)
            end
        end
    end
end

local weapon_balance = {}

function weapon_balance.register()
    Event.on_init(init_weapon_damage)
    Event.add(defines.events.on_research_finished, research_finished)
end

return weapon_balance
