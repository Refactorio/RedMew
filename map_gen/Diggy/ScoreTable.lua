-- dependencies
local Global = require 'utils.global'

-- this
local ScoreTable = {}

local scores = {}

Global.register({
    scores = scores,
}, function (tbl)
    scores = tbl.scores
end)

--[[--
    Resets the score 0 for the given name

    @param name String
]]
function ScoreTable.reset(name)
    scores[name] = 0
end

--[[--
    Adds score.

    @param name String
    @param value int amount to add

    @return int the sum for the score added by name
]]
function ScoreTable.add(name, value)
    local new = (scores[name] or 0) + value
    scores[name] = new
    return new
end

--[[--
    Increments the score by 1 for name.

    @param name String

    @return int the sum for the score incremented by name
]]
function ScoreTable.increment(name)
    return ScoreTable.add(name, 1)
end

--[[--
    Returns the score for a single key.

    @param
]]
function ScoreTable.get(name)
    return scores[name] or 0
end

--[[--
    Returns all scores.

    @return table {[string] = int}
]]
function ScoreTable.all()
    return scores
end

--[[--
    Returns all keys of table scores.

    @return table {[string] = name of key}
]]
function ScoreTable.all_keys()
    local keyset = {}
    local n = 0

    for k, v in pairs(scores) do
        n = n + 1
        keyset[n] = k
    end

    return keyset
end

return ScoreTable
