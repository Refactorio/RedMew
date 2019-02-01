--local Global = require 'utils.global'
local Event = require 'utils.event'

local player_ammo_starting_modifiers = {
    ['artillery-shell'] = -0.75,
    ['biological'] = -0.5,
    ['bullet'] = -0.25,
    ['cannon-shell'] = -0.75,
    ['capsule'] = -0.5,
    ['combat-robot-beam'] = -0.5,
    ['combat-robot-laser'] = -0.5,
    ['electric'] = -0.5,
    ['flamethrower'] = -0.75,
    ['grenade'] = -0.5,
    ['landmine'] = -0.33,
    ['laser-turret'] = -0.75,
    ['melee'] = 1,
    ['railgun'] = 0,
    ['rocket'] = -0.5,
    ['shotgun-shell'] = -0.20
}

local player_ammo_research_modifiers = {
    ['artillery-shell'] = -0.75,
    ['biological'] = -0.5,
    ['bullet'] = -0.20,
    ['cannon-shell'] = -0.75,
    ['capsule'] = -0.5,
    ['combat-robot-beam'] = -0.5,
    ['combat-robot-laser'] = -0.5,
    ['electric'] = -0.6,
    ['flamethrower'] = -0.75,
    ['grenade'] = -0.5,
    ['landmine'] = -0.5,
    ['laser-turret'] = -0.75,
    ['melee'] = -0.5,
    ['railgun'] = -0.5,
    ['rocket'] = -0.5,
    ['shotgun-shell'] = -0.20
}

local player_turrets_research_modifiers = {
    ['gun-turret'] = -0.5,
    --['laser-turret'] = -0.75,
    ['flamethrower-turret'] = -0.75
}

local enemy_ammo_starting_modifiers = {
    ['artillery-shell'] = 0,
    ['biological'] = 0,
    ['bullet'] = 0,
    ['cannon-shell'] = 0,
    ['capsule'] = 0,
    ['combat-robot-beam'] = 0,
    ['combat-robot-laser'] = 0,
    ['electric'] = 0,
    ['flamethrower'] = 0,
    ['grenade'] = 0,
    ['landmine'] = 0,
    ['laser-turret'] = 0,
    ['melee'] = 0,
    ['railgun'] = 0,
    ['rocket'] = 0,
    ['shotgun-shell'] = 0
}

local enemy_ammo_evolution_modifiers = {
    ['artillery-shell'] = 1,
    ['biological'] = 2,
    ['bullet'] = 1,
    --['cannon-shell'] = 1,
    --['capsule'] = 1,
    --['combat-robot-beam'] = 1,
    --['combat-robot-laser'] = 1,
    --['electric'] = 1,
    ['flamethrower'] = 2,
    --['grenade'] = 1,
    --['landmine'] = 1,
    ['laser-turret'] = 2,
    ['melee'] = 2
    --['railgun'] = 1,
    --['rocket'] = 1,
    --['shotgun-shell'] = 1
}



local function init_weapon_damage()
    local forces = game.forces
    local p_force = forces.player
    local e_force = forces.enemy

    for k, v in pairs(player_ammo_starting_modifiers) do
        p_force.set_ammo_damage_modifier(k, v)
    end

    for k, v in pairs(enemy_ammo_starting_modifiers) do
        e_force.set_ammo_damage_modifier(k, v)
    end
end

local function enemy_weapon_damage()
    local f = game.forces.enemy

    local ef = f.evolution_factor

    for k, v in pairs(enemy_ammo_evolution_modifiers) do
        local base = enemy_ammo_starting_modifiers[k]

        local new = base + v * ef
        f.set_ammo_damage_modifier(k, new)
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
                p_force.set_ammo_damage_modifier(category, current_m + factor * m)
            end
        elseif t == 'turret-attack' then
            local category = e.turret_id
            local factor = player_turrets_research_modifiers[category]

            if factor then
                local current_m = p_force.get_turret_attack_modifier(category)
                local m = e.modifier
                p_force.set_turret_attack_modifier(category, current_m + factor * m)
            end
        end
    end
end

Event.on_init(init_weapon_damage)
Event.on_nth_tick(18000, enemy_weapon_damage)
Event.add(defines.events.on_research_finished, research_finished)
