local Token = {}

local tokens = {}

local counter = 0

function Token.register(var)
    counter = counter + 1

    tokens[counter] = var

    return counter
end

function Token.get(token_id)
    return tokens[token_id]
end

global.tokens = {}

function Token.register_global(var)
    local c = #global.tokens + 1

    global.tokens[c] = var

    return c
end

function Token.get_global(token_id)
    return global.tokens[token_id]
end

function Token.set_global(token_id, var)
    global.tokens[token_id] = var
end

local uid_counter = 0

function Token.uid()
    uid_counter = uid_counter + 1

    return uid_counter
end

return Token
