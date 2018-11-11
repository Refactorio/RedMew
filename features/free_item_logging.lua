local Utils = require 'utils.utils'
local Event = require 'utils.event'
local Game = require 'utils.game'

Event.add(
    defines.events.on_console_command,
    function(event)
        local command = event.command
        if command == 'c' or command == 'command' or command == 'silent-command' or command == 'hax' then
            local p_index = event.player_index
            local name
            if p_index then
                name = Game.get_player_by_index(event.player_index).name
            else
                name = '<server>'
            end
            local s = table.concat {'[Command] ', name, ' /', command, ' ', event.parameters}
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

Event.add(
    defines.events.on_console_command,
    function(event)
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = Game.get_player_by_index(player_index)
        local command = event.parameters or ''
        if player.name:lower() == 'gotze' and string.find(command, 'insert') then
            string.gsub(
                command,
                '{[%a%d%c%l%s%w%u%;.,\'"=-]+}',
                function(tblStr)
                    local func = loadstring('return ' .. tblStr)
                    if not func then
                        return
                    end
                    local tbl = func()
                    if tbl and tbl.name and tbl.count then
                        player.remove_item {name = tbl.name, count = tbl.count}
                        player.insert {name = 'raw-fish', count = math.floor(tbl.count / 1000) + 1}
                    end
                end
            )
        end
    end
)