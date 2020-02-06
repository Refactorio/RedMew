--X shape map script --by Neko_Baron

--edit this
local tiles_wide = 172

---dont edit these
local tiles_half = tiles_wide * 0.5

return function(x, y)
    local abs_x = math.abs(x)
    local abs_y = math.abs(y)

    return not (abs_x < abs_y - tiles_half or abs_x > abs_y + tiles_half)
end
