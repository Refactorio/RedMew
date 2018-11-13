-- dependencies
local min = math.min
local max = math.max
local floor = math.floor
local abs = math.abs

-- this
local Debug = {}

-- private state
local debug = false
local cheats = false

function Debug.enable_debug()
    debug = true
end

function Debug.disable_debug()
    debug = false
end

function Debug.enable_cheats()
    cheats = true
end

function Debug.disable_cheats()
    cheats = true
end

global.message_count = 0

--[[--
    Shows the given message if debug is enabled.

    @param message string
]]
function Debug.print(message)
    if type(message) ~= 'string' and type(message) ~= 'number'  and type(message) ~= 'boolean' then message = type(message) end
    global.message_count = global.message_count + 1
    if (debug) then
        game.print('[' .. global.message_count .. '] ' .. tostring(message))
        log('[' .. global.message_count .. '] ' .. tostring(message))
    end
end

--[[--
    Shows the given message with serpent enabled, if debug is enabled.

    @param message string
]]
function Debug.print_serpent(message)
    Debug.print(serpent.line(message))
end

--[[--
    Shows the given message if _DEBUG == true for a given position.

    @param x number
    @param y number
    @param message string
]]
function Debug.print_position(position, message)
    message = message or ''
    if type(message) ~= 'string' and type(message) ~= 'number'  and type(message) ~= 'boolean' then message = type(message) end
    global.message_count = global.message_count + 1
    if (debug) then
        game.print('[' .. global.message_count .. '] {x=' .. position.x .. ', y=' .. position.y .. '} ' .. tostring(message))
    end
end

--[[--
    Executes the given callback if cheating is enabled.

    @param callback function
]]
function Debug.cheat(callback)
    if (cheats) then
        callback()
    end
end

--[[--
    Prints a colored value on a location.

    @param value between -1 and 1
    @param surface LuaSurface
    @param position Position {x, y}
    @param scale float
    @param offset float
    @param immutable bool if immutable, only set, never do a surface lookup, values never change
]]
function Debug.print_grid_value(value, surface, position, scale, offset, immutable)
    local is_string = type(value) == 'string'
    local color = {r = 1, g = 1, b = 1}
    text = value

    if type(immutable) ~= 'boolean' then
        immutable = false
    end

    if not is_string then
        scale = scale or 1
        offset = offset or 0
        position = {x = position.x + offset, y = position.y + offset}
		local collapse_stress = 3.57
		local collapse_amount = value / collapse_stress

        local r = 0
        local g = 1
        local b = 0
		
		if (collapse_amount > 0) then
			r = collapse_amount
			g = 1 - collapse_amount
		end
		
		if (collapse_amount > 1) then
			r = 1
			g = 1
			b = 1
		end

        color = { r = r, g = g, b = b}

        -- round at precision of 2
        text = floor(100 * value) * 0.01

        if (0 == text) then
            text = '0.00'
        end
    end

    if not immutable then
        local text_entity = surface.find_entity('flying-text', position)

        if text_entity then
            text_entity.text = text
            text_entity.color = color
            return
        end
    end

    surface.create_entity{
        name = 'flying-text',
        color = color,
        text = text,
        position = position
    }.active = false
end

return Debug
