local abs = math.abs
return function(x, y)
    local abs_x = abs(x) - 0.5
    local abs_y = abs(y) - 0.5
    if (abs_x <= 23  or abs_y <= 23) then
        if ((abs_y % 4 == 0) or (abs_x % 4 == 0)) then -- Between quadrants create land
            game.surfaces[2].set_tiles({{name="tutorial-grid", position={x, y}}}, true)
            local entities = game.surfaces[2].find_entities({{x-0.5, y-0.5}, {x+0.5, y+0.5}})

            for _, entity in ipairs(entities) do
                if entity.name ~= 'player' then
                    entity.destroy()
                end
            end
            if (abs_x <= 2 and abs_y <= 2) then --Spawn
                return true
            elseif (abs_x <= 23 and abs_y <= 23) and not (abs_x <= 2 and abs_y <= 2) then -- Around spawn, in between the quadrants
                return false
            elseif ((abs_x <= 1 or abs_x == 8 or abs_x == 9 or abs_x == 16 or abs_x == 17) and abs_y % 4 == 0) or ((abs_y <= 1 or abs_y == 8 or abs_y == 9 or abs_y == 16 or abs_y == 17) and abs_x % 4 == 0) then -- connections
                return true
            end
        end
        return false
    end
    return true
end
--8 + 9, 16 + 17