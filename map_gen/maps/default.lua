-- A blank file to allow map_selection to have a default

-- Added warning to help guide newcomers
local Event = require 'utils.event'

Event.add(
    defines.events.on_player_joined_game,
    function()
        game.print('[color=red]THIS IS THE DEFAULT MAP! IT CONTAINS NO CUSTOM MAP GEN![/color]')
        game.print('[color=yellow]Visit https://redmew.com/guide and follow step 3[/color]')
    end
)
