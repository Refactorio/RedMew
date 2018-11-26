local Token = require 'utils.token'

local Builders = {}

function Builders.unpack(shape)
    local token = Token.register_global(shape)
    return function(x, y, world)
        local data = Token.get_global(token)
        local func = Token.get(data.token)
        return func(x, y, world, data)
    end
end

function Builders.pack(shape)
    return {
        token = Token.register(shape)
    }
end

function Builders.run(x, y, world, shape)
    local func = Token.get(shape.token)
    return func(x, y, world, shape)
end

local tile_token =
    Token.register(
    function(_, _, _, args)
        return args.tile
    end
)

function Builders.tile(tile)
    return {
        token = tile_token,
        tile = tile
    }
end

local grid_pattern_endless_token =
    Token.register(
    function(x, y, world, args)
        local y2 = ((y + args.half_height) % args.height) - args.half_height
        local row_i = math.floor(y / args.height + 0.5) + 1

        local x2 = ((x + args.half_width) % args.width) - args.half_width
        local col_i = math.floor(x / args.width + 0.5) + 1

        local row = args.pattern[row_i]

        if not row then
            row = {}
            args.pattern[row_i] = row
        end

        local shape = row[col_i]

        if not shape then
            local func = Token.get(args.pattern_func)
            shape = func(col_i, row_i)
            row[col_i] = shape
        end

        return Builders.run(x2, y2, world, shape)
    end
)

function Builders.grid_pattern_endless(pattern, width, height, pattern_func)
    local half_width = width / 2
    local half_height = height / 2

    if type(pattern_func) ~= 'number' then
        pattern_func = Token.register(pattern_func)
    end

    return {
        pattern = pattern,
        width = width,
        height = height,
        half_width = half_width,
        half_height = half_height,
        pattern_func = pattern_func,
        token = grid_pattern_endless_token
    }
end

return Builders
