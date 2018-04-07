local Token = {}

local tokens = {}

local counter = 1

function Token.register(var)
    local c = counter

    tokens[c] = var
    counter = c + 1

    return c
end

function Token.get(token_id)
    return tokens[token_id]
end

return Token