local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'

local compilatrons = {}
local current_messages = {}

local messages = {
    ['spawn'] = {
        'Welcome to Redmew - Quadrants!\n\nUse the GUI in your top left corner to play!',
        'How to transfer items?\nYou can use underground belts to reach the other side\n\nYou can also drop items across, just use the ´Z´ key',
        'Welcome to Redmew - Quadrants!\n\nUse the GUI in your top left corner to play!',
        'I\'m really cute'
    },
    ['quadrant1'] = {
        'Welcome to Science and Military!\n\nCommand center of military and scientific advancement',
        'You can only research in this area\n\nYou would have to import some science packs from other areas',
        'You can only craft military items in this area\n\nOther areas depend on you sending military items to them',
        'Spare some change?\nGo spend your hard-earned coins here at the market',
        'Welcome to Science and Military!\n\nCommand center of military and scientific advancement',
        'How to transfer items?\nYou can use underground belts to reach the other side\n\nYou can also drop items across, just use the ´Z´ key',
        'You can switch area!\nAll it takes is that you have an empty inventory\n\nJust stand near me and use the gui in the top left corner to switch'
    },
    ['quadrant2'] = {
        'Welcome to Intermediate and Mining!\n\nThe only producer of steel and electronic circuits!',
        'You can only produce steel in this area\n\nOther areas depend on you sending steel to them',
        'You can only craft circuits in this area\n\nYou need to export them other areas!',
        'Rumors say:\nThis area is extra rich in resources\n\nIt\'s ideal for mining operations',
        'Welcome to Intermediate and Mining!\n\nThe only producer of steel and electronic circuits!',
        'Spare some change?\nGo spend your hard-earned coins here at the market',
        'How to transfer items?\nYou can use underground belts to reach the other side\n\nYou can also drop items across, just use the ´Z´ key',
        'You can switch area!\nAll it takes is that you have an empty inventory\n\nJust stand near me and use the gui in the top left corner to switch'
    },
    ['quadrant3'] = {
        'Welcome to Oil and High Tech!\n\nHome of oil processing and technology',
        'You can only process crude oil in this area\n\nYou may need to import crude oil from other areas',
        'You can only craft various high tech items in this ares\n\nYou may need to import a lot of intermediate products!',
        'I have heard:\nThis area is a perfect place to launch a rocket\n\nOther areas can provide you the parts you need',
        'Welcome to Oil and High Tech!\n\nHome of oil processing and technology',
        'Spare some change?\nGo spend your hard-earned coins here at the market',
        'How to transfer items?\nYou can use underground belts to reach the other side\n\nYou can also drop items across, just use the ´Z´ key',
        'You can switch area!\nAll it takes is that you have an empty inventory\n\nJust stand near me and use the gui in the top left corner to switch'
    },
    ['quadrant4'] = {
        'Welcome to Logistics and Transport\n\nHome of spaghetti and trainyards',
        'You can only produce logistical items in this area\n\nThe success of the region depends on you exporting these!',
        'Did you know?\nMy siblings and I where born here',
        'Spare some change?\nGo spend your hard-earned coins here at the market',
        'Welcome to Logistics and Transport\n\nHome of spaghetti and trainyards',
        'How to transfer items?\nYou can use underground belts to reach the other side\n\nYou can also drop items across, just use the ´Z´ key',
        'You can switch area!\nAll it takes is that you have an empty inventory\n\nJust stand near me and use the gui in the top left corner to switch'
    }
}

local callback =
    Token.register(
    function(data)
        local ent = data.ent
        local name = data.name
        local msg_number = data.msg_number
        message =
            ent.surface.create_entity(
            {name = 'compi-speech-bubble', text = messages[name][msg_number], position = {0, 0}, source = ent}
        )
        current_messages[name] = {message = message, msg_number = msg_number}
    end
)

Global.register(
    {
        compilatrons = compilatrons,
        current_messages = current_messages
    },
    function(tbl)
        compilatrons = tbl.compilatrons
        current_messages = tbl.current_messages
    end
)

local function circle_messages()
    for name, ent in pairs(compilatrons) do
        local current_message = current_messages[name]
        local msg_number
        local message
        if current_message ~= nil then
            message = current_message.message
            if message ~= nil then
                message.destroy()
            end
            msg_number = current_message.msg_number
            msg_number = (msg_number < #messages[name]) and msg_number + 1 or 1
        else
            msg_number = 1
        end
        Task.set_timeout_in_ticks(300, callback, {ent = ent, name = name, msg_number = msg_number})
    end
end

Event.on_nth_tick(899 * 2, circle_messages)

local Public = {}

function Public.add_compilatron(entity, name)
    if not entity and not entity.valid then
        return
    end
    if name == nil then
        return
    end
    compilatrons[name] = entity
    local message =
        entity.surface.create_entity(
        {name = 'compi-speech-bubble', text = messages[name][1], position = {0, 0}, source = entity}
    )
    current_messages[name] = {message = message, msg_number = 1}
end

return Public
