local b = require "map_gen.shared.builders"
local pic = require "map_gen.data.presets.turkey"
local RS = require 'map_gen.shared.redmew_surface'
local MGSP = require 'resources.map_gen_settings'
local Event = require 'utils.event'
local turkey_message_random = require 'resources.turkey_messages'

RS.set_map_gen_settings(
    {
        MGSP.cliff_none
    }
)

Event.add(
    defines.events.on_tick,
    function(event)
	    if event.tick % 36000 == 0 then
            local message = turkey_message_random[math.random(#turkey_message_random)]
            game.print('[color=yellow][font=compi]' .. message .. '[/font][/color]')
	    end
    end
)

pic = b.decompress(pic)

local shape = b.picture(pic)
shape = b.scale(shape, 4, 4)
shape = b.translate(shape, -300, 500)

return shape
