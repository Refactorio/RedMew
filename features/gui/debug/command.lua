local DebugView = require 'features.gui.debug.main_view'
local Command = require 'utils.command'

Command.add(
    'debug',
    {
        debug_only = true,
        description = 'Opens the debugger'
    },
    function(_, player)
        DebugView.open_dubug(player)
    end
)
