local Event = require('utils.event')

Event.on_init(function()
    storage.is_multiplayer = game.is_multiplayer()
end)

return true
