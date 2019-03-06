local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local Token = require 'utils.token'

local compilatrons = {}
local current_messages = {}

local messages = {
    ['spawn'] = {
        {'quadrants.compi_spawn_welcome'},
        {'quadrants.compi_common_transfer_item'},
        {'quadrants.compi_spawn_welcome'},
        {'quadrants.compi_spawn_cute'},
        {'quadrants.compi_spawn_welcome'},
        {'quadrants.compi_common_chat'}
    },
    ['quadrant1'] = {
		{'quadrants.compi_quadrant1_welcome'},
		{'quadrants.compi_quadrant1_science'},
		{'quadrants.compi_quadrant1_military'},
		{'quadrants.compi_common_market'},
		{'quadrants.compi_quadrant1_welcome'},
		{'quadrants.compi_common_transfer_item'},
		{'quadrants.compi_common_switch'},
		{'quadrants.compi_common_chat'},
		{'quadrants.compi_common_chests'}
	},
    ['quadrant2'] = {
		{'quadrants.compi_quadrant2_welcome'},
		{'quadrants.compi_quadrant2_steel'},
		{'quadrants.compi_quadrant2_circuits'},
		{'quadrants.compi_quadrant2_resources'},
		{'quadrants.compi_common_market'},
		{'quadrants.compi_quadrant2_welcome'},
		{'quadrants.compi_common_transfer_item'},
		{'quadrants.compi_common_switch'},
		{'quadrants.compi_common_chat'},
		{'quadrants.compi_common_chests'}
    },
    ['quadrant3'] = {
		{'quadrants.compi_quadrant3_welcome'},
		{'quadrants.compi_quadrant3_oil'},
		{'quadrants.compi_quadrant3_tech'},
		{'quadrants.compi_quadrant3_rocket'},
		{'quadrants.compi_common_market'},
		{'quadrants.compi_quadrant3_welcome'},
		{'quadrants.compi_common_transfer_item'},
		{'quadrants.compi_common_switch'},
		{'quadrants.compi_common_chat'},
		{'quadrants.compi_common_chests'}
    },
    ['quadrant4'] = {
		{'quadrants.compi_quadrant4_welcome'},
		{'quadrants.compi_quadrant4_logistic'},
		{'quadrants.compi_quadrant4_born'},
		{'quadrants.compi_common_market'},
		{'quadrants.compi_quadrant4_welcome'},
		{'quadrants.compi_common_transfer_item'},
		{'quadrants.compi_common_switch'},
		{'quadrants.compi_common_chat'},
		{'quadrants.compi_common_chests'}
    }
}

local callback =
    Token.register(
    function(data)
        local ent = data.ent
        local name = data.name
        local msg_number = data.msg_number
        local message =
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
