local Event = require('utils.event')

Event.on_init(function()
    global.is_multiplayer = game.is_multiplayer()
end)

return true
