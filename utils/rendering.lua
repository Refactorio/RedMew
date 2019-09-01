local Token = require 'utils.token'
local Task = require 'utils.task'

local Public = {}

local cos = math.cos
local sin = math.sin

local rendering = rendering
local draw_polygon = rendering.draw_polygon

function Public.draw_polygon(positions, options)
    local vertices = {}

    for i = 1, #positions do
        vertices[i] = {target = positions[i]}
    end

    local args = {vertices = vertices}
    for k, v in pairs(options) do
        args[k] = v
    end

    return draw_polygon(args)
end

function Public.translate(positions, x, y)
    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        result[i] = {pos[1] + x, pos[2] + y}
    end

    return result
end

function Public.scale(positions, x, y)
    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        result[i] = {pos[1] * x, pos[2] * y}
    end

    return result
end

function Public.rotate(positions, radians)
    local qx = cos(radians)
    local qy = sin(radians)

    local result = {}

    for i = 1, #positions do
        local pos = positions[i]
        local x, y = pos[1], pos[2]
        local rot_x = qx * x - qy * y
        local rot_y = qy * x + qx * y

        result[i] = {rot_x, rot_y}
    end

    return result
end

local fade_token =
    Token.register(
    function(params)
        local id = params.id
        if rendering.is_valid(id) then
            rendering.set_color(id, params.color)
        end
    end
)

function Public.fade(id, time, ticks)
    ticks = ticks or 20
    local count = (time - time % ticks) / ticks
    if rendering.is_valid(id) then
        local color = rendering.get_color(id)
        local a = color.a or 1
        local decrement = a / count
        for i = 1, count do
            a = a - decrement
            a = a >= 0 and a or 0
            Task.set_timeout_in_ticks(ticks * i, fade_token, {id = id, color = {r = color.r, b = color.b, g = color.g, a = a}})
        end
    end
end

local blink_token =
    Token.register(
    function(params)
        local id = params.id
        if rendering.is_valid(id) then
            rendering.set_visible(id, params.visible)
        end
    end
)

function Public.blink(id, rate, time)
    local count = (time - time % rate) / rate
    rate = (time / count) * 2
    if rendering.is_valid(id) then
        local visible = rendering.get_visible(id)
        for i = 1, count do
            visible = not visible
            Task.set_timeout_in_ticks(rate * i, blink_token, {id = id, visible = visible})
        end
    end
end

return Public
