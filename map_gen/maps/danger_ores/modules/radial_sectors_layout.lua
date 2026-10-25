-- Pure geometry for sectors whose sizes change with the distance from spawn: inside `from` the
-- sectors take the `inner` weights, past `to` the `outer` weights, and in between they blend
-- linearly, so the borders between sectors bend instead of jumping. No Factorio API here.
--
-- layout = {from = number, to = number, inner = {w1, w2, ...}, outer = {w1, w2, ...}}, one weight
-- per sector, in sector order.
local sqrt = math.sqrt
local atan2 = math.atan2 or math.atan
local inv_pi = 1 / math.pi

local Public = {}

--- How far (0 to 1) the weights at distance d have moved from inner to outer. The blend eases in
-- and out (smoothstep), so borders bend gradually instead of kinking at `from` and `to`.
function Public.blend(layout, d)
    local t = (d - layout.from) / (layout.to - layout.from)
    if t <= 0 then
        return 0
    elseif t >= 1 then
        return 1
    end
    return t * t * (3 - 2 * t)
end

--- The weight of sector i at distance d.
function Public.weight_at(layout, i, d)
    local inner = layout.inner[i]
    return inner + (layout.outer[i] - inner) * Public.blend(layout, d)
end

local function totals(layout, t)
    local inner, outer = layout.inner, layout.outer
    local total_inner, total = 0, 0
    for i = 1, #inner do
        total_inner = total_inner + inner[i]
        total = total + inner[i] + (outer[i] - inner[i]) * t
    end
    return total_inner, total
end

--- How far (in turns) the whole pattern is rotated at blend t. Each border moves by how much the
-- sectors before it grew or shrank; rotating by the midpoint of the largest and smallest of
-- those moves keeps every sector centred, so no border swings more than half the spread.
function Public.offset(layout, t)
    local inner, outer = layout.inner, layout.outer
    local total_inner, total = totals(layout, t)
    local sum_inner, sum = 0, 0
    local low, high = 0, 0 -- the last border never moves
    for i = 1, #inner - 1 do
        sum_inner = sum_inner + inner[i]
        sum = sum + inner[i] + (outer[i] - inner[i]) * t
        local shift = sum / total - sum_inner / total_inner
        if shift < low then
            low = shift
        elseif shift > high then
            high = shift
        end
    end
    return -(low + high) * 0.5
end

--- The index of the sector at (x, y). Inside `from`, sectors run counter-clockwise from the
-- negative x axis in list order, as in builders' segment_weighted_pattern; further out the
-- pattern turns by offset() to keep each sector centred while it grows or shrinks.
function Public.sector_at(layout, x, y)
    local inner, outer = layout.inner, layout.outer
    local count = #inner
    local t = Public.blend(layout, sqrt(x * x + y * y))
    local _, total = totals(layout, t)

    local turn = (atan2(-y, x) * inv_pi + 1) * 0.5 - Public.offset(layout, t)
    local target = (turn % 1) * total
    local sum = 0
    for i = 1, count - 1 do
        sum = sum + inner[i] + (outer[i] - inner[i]) * t
        if target < sum then
            return i
        end
    end
    return count
end

return Public
