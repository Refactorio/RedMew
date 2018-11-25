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

---Resets the score 0 for the given name
---@param name string
function ScoreTable.reset(name)
    scores[name] = 0
end

---Adds score.
---@param name string
---@param value number the sum for the score added by name
---@return number the sum for the score added by the name
function ScoreTable.add(name, value)
    local new = (scores[name] or 0) + value
    scores[name] = new
    return new
end

---Sets score.
---@param name string
---@param value number the sum for the score added by name
function ScoreTable.set(name, value)
    scores[name] = value
end

---Increments the score by 1 for name.
---@param name string
---@return number the sum for the score incremented by name
function ScoreTable.increment(name)
    return ScoreTable.add(name, 1)
end

---Returns the score for a single key.
---@param name string
---@return number the sum for the score by name
function ScoreTable.get(name)
    return scores[name] or 0
end

---Returns all scores.
---@return table {[string] = int}
function ScoreTable.all()
    return scores
end

return ScoreTable
