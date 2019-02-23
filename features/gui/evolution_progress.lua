local Event = require 'utils.event'
local Gui = require 'utils.gui'
local Game = require 'utils.game'
local Global = require 'utils.global'
local Toast = require 'features.gui.toast'
local round = math.round
local pairs = pairs
local main_button_name = Gui.uid_name()

local memory = {
    last_percentage = 0
}

Global.register(
    memory,
    function(tbl)
        memory = tbl
    end,
    'evolution_progress'
)

local button_sprites = {
    ['small-biter'] = 0,
    ['medium-biter'] = 0.2,
    ['small-spitter'] = 0.25,
    ['medium-spitter'] = 0.4,
    ['big-spitter'] = 0.5,
    ['big-biter'] = 0.501,
    ['behemoth-spitter'] = 0.9,
    ['behemoth-biter'] = 0.901
}

local function get_evolution_percentage()
    if not game then
        return 0
    end

    local value = round(game.forces.enemy.evolution_factor * 1000) * 0.001
    if value < 0.001 then
        -- 0.00 won't be shown on the button as value
        return 0.001
    end

    return value
end

local function get_alien_name(evolution_factor)
    local last_match = 'fish'
    for name, alien_threshold in pairs(button_sprites) do
        if evolution_factor == alien_threshold then
            return name
        end

        -- next alien evolution_factor isn't reached
        if alien_threshold > evolution_factor then
            return last_match
        end

        -- surpassed this alien evolution_factor
        if alien_threshold < evolution_factor then
            last_match = name
        end
    end

    return last_match
end

local function update_gui(player)
    local button = player.gui.top[main_button_name]
    if button and button.valid then
        local evolution_factor = get_evolution_percentage()
        local evolution_button_number = evolution_factor * 100
        local current_alien = get_alien_name(evolution_factor)
        local sprite = 'entity/' .. current_alien

        button.number = evolution_button_number
        if sprite then
            button.sprite = sprite
        end
    end
end

local function player_joined(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    if player.gui.top[main_button_name] ~= nil then
        update_gui(player)
        return
    end

    local evolution_factor = get_evolution_percentage()
    local alien_name = get_alien_name(evolution_factor)

    player.gui.top.add(
            {
                name = main_button_name,
                type = 'sprite-button',
                sprite = 'entity/' .. alien_name,
                number = evolution_factor * 100
            }
        ).enabled = false
end

local function on_nth_tick()
    local previous_evolution_factor = memory.last_percentage
    local evolution_factor = get_evolution_percentage()

    if previous_evolution_factor == evolution_factor then
        return
    end

    memory.last_percentage = evolution_factor

    local previous_alien = get_alien_name(previous_evolution_factor)
    local current_alien = get_alien_name(evolution_factor)
    local sprite

    if current_alien ~= previous_alien then
        sprite = 'entity/' .. current_alien
        local caption = {'', 'Evolution notice: ', {'entity-name.' .. current_alien}, ' sighted!'}
        Toast.toast_all_players_template(
            10,
            function(container)
                container.add({type = 'sprite', sprite = sprite})
                local text = container.add({type = 'label', caption = caption, name = Toast.close_toast_name})
                local text_style = text.style
                text_style.single_line = false
                text_style.vertical_align = 'center'
            end
        )
    end

    local players = game.connected_players
    for i = 1, #players do
        update_gui(players[i])
    end
end

Gui.allow_player_to_toggle_top_element_visibility(main_button_name)

Event.add(defines.events.on_player_joined_game, player_joined)
Event.on_nth_tick(207, on_nth_tick)
