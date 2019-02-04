--X shape map script --by Neko_Baron

--edit this
local tiles_wide = 128
local tiles_intersect = 384

---dont edit these
local tiles_half = tiles_wide * 0.5

return function(x, y)
    local offset_1 = x + y + tiles_half
    local offset_2 = x - y + tiles_half

    if offset_1 % tiles_intersect > tiles_wide then
        return offset_2 % tiles_intersect <= tiles_wide
    end

    return true
end
