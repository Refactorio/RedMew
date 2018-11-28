local Utils = require 'utils.core'
local Event = require 'utils.event'
local Game = require 'utils.game'

Event.add(
    defines.events.on_console_command,
    function(event)
        local command = event.command
        local p_index = event.player_index
        local actor
        if p_index then
            actor = Game.get_player_by_index(event.player_index)
        else
            actor = {['admin'] = true, ['name'] = '<server>'}
        end
        if actor.admin and command ~= 'color' then --lazy approach, will not fix as this will be handle by the command wrapper
            local s = table.concat {'[Command] ', actor.name, ' /', command, ' ', event.parameters}
            log(s)
        end
    end
)

global.cheated_items = {}
global.cheated_items_by_timestamp = {}

Event.add(
    defines.events.on_player_crafted_item,
    function(event)
        local pi = event.player_index
        local p = Game.get_player_by_index(pi)

        if not p or not p.valid or not p.cheat_mode then
            return
        end

        local cheat_items = global.cheated_items

        local data = cheat_items[pi]
        if not data then
            data = {}
            cheat_items[pi] = data
        end

        local stack = event.item_stack
        local name = stack.name
        local user_item_record = data[name] or {count = 0}
        local count = user_item_record.count
        local time = user_item_record['time'] or Utils.format_time(game.tick)
        data[name] = {count = stack.count + count, time = time}
        local s = table.concat {'[Cheated item] ', p.name, ' - ', stack.count, ' x ', name}
        log(s)
    end
)

function print_cheated_items()
    local res = {}
    local players = game.players

    for pi, data in pairs(global.cheated_items) do
        res[players[pi].name] = data
    end

    game.player.print(serpent.block(res))
end
