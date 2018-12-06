local Event = require 'utils.event'
local Game = require 'utils.game'

local drivers_group = 'Drivers'
local random = math.random

local function transfer_body(player)
    -- Remove the player from their character and place them in a car.
    local surface = player.surface
    local force = player.force
    local pos = force.get_spawn_position(surface)

    -- Choose a random direction for the car to face
    local dir = random(0, 7)

    -- Remove the players' character
    if player.character then
        player.character.destroy()
    end

    --Find a place for a car, place a car, and place fuel+ammo in it
    local car_pos = surface.find_non_colliding_position('car', pos, 0, 3)
    local car = surface.create_entity {name = 'car', position = car_pos, direction = dir, force = force}
    car.insert({name = 'coal', count = 50})
    car.insert({name = 'firearm-magazine', count = 10})
    car.set_driver(player)
end

local function player_created(event)
    local player = Game.get_player_by_index(event.player_index)
    local permissions = game.permissions

    -- We want to create a permission group to stop players leaving their vehicles.
    -- Check if the permission group exists, if it doesn't, create it.
    local permission_group = permissions.get_group(drivers_group)
    if not permission_group then
        permission_group = permissions.create_group(drivers_group)
        -- Set all permissions to enabled
        for action_name, _ in pairs(defines.input_action) do
            permission_group.set_allows_action(defines.input_action[action_name], true)
        end
        -- Disable leaving a vehicle
        permission_group.set_allows_action(defines.input_action.toggle_driving, false)
    end

    -- Add player to drivers group
    permission_group.add_player(player)

    -- Put the new player into a car.
    transfer_body(player)

    -- Disable the god mode spotlight.
    player.disable_flashlight()

    -- Welcome message to the player.
    player.print('As though a dream, you find yourself without a body and instead as a sentient car. Strange...')
end

local function revive_player(event)
    -- When a player's car dies, return them to spawn and create a new car for them.
    local player = Game.get_player_by_index(event.player_index)
    -- This check prevents a loop when we put them into a car.
    if not player.driving then
        transfer_body(player)
        player.print('Although you left one vehicle, you just find yourself in another.')
    end
end

Event.add(defines.events.on_player_created, player_created)
Event.add(defines.events.on_player_driving_changed_state, revive_player)
