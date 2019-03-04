local DebugView = require 'features.gui.debug.main_view'
local Command = require 'utils.command'

Command.add(
    'debug',
    {
        description = {'command_descriptiondebuger'},
        debug_only = true
    },
    function(_, player)
        DebugView.open_dubug(player)
    end
)
