local Global = require 'utils.global'
local Event = require 'utils.event'

local ammos = {
    {name = 'artillery-shell', amount = -0.75},
    {name = 'biological', amount = 0},
    {name = 'bullet', amount = -0.5},
    {name = 'cannon-shell', amount = -0.5},
    {name = 'capsule', amount = -0.5},
    {name = 'combat-robot-beam', amount = -0.5},
    {name = 'combat-robot-laser', amount = -0.5},
    {name = 'electric', amount = -0.5},
    {name = 'flamethrower', amount = -0.75},
    {name = 'grenade', amount = -0.5},
    {name = 'landmine', amount = 0},
    {name = 'laser-turret', amount = -0.75},
    {name = 'melee', amount = 0},
    {name = 'railgun', amount = 0},
    {name = 'rocket', amount = -0.5},
    {name = 'shotgun-shell', amount = -0.5}
}

local function init_weapon_damage()
    local forces = game.forces
    local p_force = forces.player

    for _, a in ipairs(ammos) do
        p_force.set_ammo_damage_modifier(a.name, a.amount)
    end

    --[[ local e_force = forces.enemy

    e_force.artillery_range_modifier = -0.5 -- can't be negative :( ]]
end

local function enemy_weapon_damage()
    local f = game.forces.enemy

    local ef = game.forces.player.evolution_factor

    f.set_ammo_damage_modifier('melee', ef)
    f.set_ammo_damage_modifier('biological', ef)
end

Event.on_init(init_weapon_damage)

Event.on_nth_tick(18000, enemy_weapon_damage)
