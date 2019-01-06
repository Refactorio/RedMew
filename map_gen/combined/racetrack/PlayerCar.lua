--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 26.11.2018 17:57 via IntelliJ IDEA
--
-- main concept copied by map_gen.misc.car_body.lua!
-- edited for use with this szenario
--

local Event = require 'utils.event'
local Game = require 'utils.game'

local GameConfig = require 'map_gen.combined.racetrack.GameConfig'
local MapData = require ('map_gen.combined.racetrack.tracks.' .. GameConfig.track)

local PlayerCar = {}

local drivers_group = 'Drivers'


-- local FUNCTIONs
local function check_colliding_position(position, player)
    local position = player.surface.find_non_colliding_position(player.character.name, position, 2, 1)
    if position then
        return true
    else
        return false
    end
end
-- ---------------------------------------------------------------------------------------------------------------------


-- FUNCTIONs
function PlayerCar.transfer_body_to_car(player, pos)
    Debug.print('PlayerCar::transfer_body_to_car called')

    -- this function teleports the player into a car

    -- Remove the player from their character and place them in a car.
    local surface = player.surface
    local force = player.force

    -- Choose a random direction for the car to face
    local dir = math.random(0, 7)

    -- clear players inventory
    player.character.clear_items_inside()

    -- Remove the players' character
    if player.character then
        player.character.destroy()
    end

    -- Find a place for a car, place a car, and place fuel+ammo in it
    local car_pos = surface.find_non_colliding_position('car', pos, 0, 3)
    local car = surface.create_entity {name = 'car', position = car_pos, direction = dir, force = force}
    car.insert({name = 'coal', count = 50})
    car.insert({name = 'firearm-magazine', count = 10})
    car.set_driver(player)
end

function PlayerCar.transfer_body_to_character(player)
    Debug.print('PlayerCar::transfer_body_to_character called')

    -- this function removes the players vehicle and teleports the player into a character
    -- mainly used when player finishes game

    local surface = player.surface
    local force = player.force

    -- remove the vehicle
    if player.vehicle and player.vehicle.valid and (player.vehicle.type == 'car' or player.vehicle.type == 'tank') then
        player.vehicle.destroy()
    end

    if player.character == nil then
        -- create new character for player
        local new_charater = player.create_character()
        if new_charater == true then
            if check_colliding_position(MapData.playground, player) then
                player.teleport(MapData.playground, surface)
            else
                Debug.print('PlayerCar::transfer_body_to_character: Error: Can´t find non colliding position for character of player: ' .. player.name .. '. Please report this error to the RedMew devs.')
            end
        end
    else
        -- use existing player character
        if check_colliding_position(MapData.playground, player) then
            player.teleport(MapData.playground, surface)
        else
            Debug.print('PlayerCar::transfer_body_to_character: Error: Can´t find non colliding position for character of player: ' .. player.name .. '. Please report this error to the RedMew devs.')
        end
    end
end

function PlayerCar.remove_vehicle(player)
    Debug.print('PlayerCar::remove_vehicle called')

    -- this function destroys the leaving players vehicle
    if player.vehicle and player.vehicle.valid and (player.vehicle.type == 'car' or player.vehicle.type == 'tank') then
        player.vehicle.destroy()
    end
end
-- ---------------------------------------------------------------------------------------------------------------------

-- EVENTS
local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('PlayerCar::player_joined: event called by joining player: ' .. player.name)

    local permissions = game.permissions
    local new_force = game.create_force(player.name)

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

    -- Assign force to the player
    player.force = new_force

    -- Put the new player into a character.
    PlayerCar.transfer_body_to_character(player)
end

local function player_left(event)
    local player = Game.get_player_by_index(event.player_index)

    Debug.print('PlayerCar::player_left: event called by leaving player: ' .. player.name)

    -- remove vehicle of the player
    PlayerCar.remove_vehicle(player)
end
-- ---------------------------------------------------------------------------------------------------------------------


function PlayerCar.register(config)
    Event.add(defines.events.on_player_joined_game, player_joined)
    Event.add(defines.events.on_player_left_game, player_left)
end

return PlayerCar
