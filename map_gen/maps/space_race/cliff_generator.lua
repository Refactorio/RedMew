local cliffs = {}

local Public = {}

local orientation = {
    ['none-to-west'] = 'east-to-none',
    ['west-to-none'] = 'none-to-east',
    ['east-to-none'] = 'none-to-west',
    ['none-to-east'] = 'west-to-none',
    ['north-to-west'] = 'east-to-north',
    ['west-to-north'] = 'north-to-east',
    ['north-to-east'] = 'west-to-north',
    ['east-to-north'] = 'north-to-west',
    ['west-to-south'] = 'south-to-east',
    ['south-to-west'] = 'east-to-south',
    ['east-to-south'] = 'south-to-west',
    ['south-to-east'] = 'west-to-south',
    ['north-to-south'] = 'south-to-north',
    ['south-to-north'] = 'north-to-south',
    ['north-to-none'] = 'none-to-north',
    ['none-to-north'] = 'north-to-none',
    ['south-to-none'] = 'none-to-south',
    ['none-to-south'] = 'south-to-none'
}

function Public.cliff(_, _, world)
    local world_x = math.abs(world.x) -- 0 = 0
    local world_y = world.y + 0.5 -- 0 = 0.5

    local _x = cliffs[world_x]
    if _x then
        local _y = _x[world_y]
        if _y then
            local cliff_orientation = _y[1]
            if world.x < 0 then
                local flipped_orientation = orientation[_y[1]]
                if flipped_orientation then
                    cliff_orientation = flipped_orientation
                end
            end
            return {name = 'cliff', cliff_orientation = cliff_orientation, always_place = true, destructible = false}
        end
    end
end

function Public.generate_cliffs(surface)
    for _x, ys in pairs(cliffs) do
        for _y, cliff_orientation in pairs(ys) do
            local cliff = surface.create_entity{name = 'cliff', position = {x = _x, y = _y}, cliff_orientation = cliff_orientation[1]}
            cliff.destructible = false
            --inverting
            cliff = surface.create_entity{name = 'cliff', position = {x = -_x, y = _y}, cliff_orientation = orientation[cliff_orientation[1]] or cliff_orientation[1]}
            cliff.destructible = false
        end
    end
end

cliffs = {
    [378] = {
        [-29.5] = {'none-to-west'},
        [-17.5] = {'east-to-west'},
        [18.5] = {'west-to-east'},
        [30.5] = {'west-to-none'}
    },
    [366] = {
        [-25.5] = {'north-to-west'},
        [-29.5] = {'east-to-south'},
        [-9.5] = {'north-to-west'},
        [-13.5] = {'east-to-south'},
        [10.5] = {'west-to-south'},
        [14.5] = {'north-to-east'},
        [26.5] = {'west-to-south'},
        [30.5] = {'north-to-east'}
    },
    [370] = {
        [-29.5] = {'east-to-west'},
        [-13.5] = {'north-to-west'},
        [-17.5] = {'east-to-south'},
        [14.5] = {'west-to-south'},
        [18.5] = {'north-to-east'},
        [30.5] = {'west-to-east'}
    },
    [374] = {
        [-29.5] = {'east-to-west'},
        [-17.5] = {'east-to-west'},
        [18.5] = {'west-to-east'},
        [30.5] = {'west-to-east'}
    },
    [362] = {
        [-21.5] = {'north-to-west'},
        [-25.5] = {'east-to-south'},
        [-9.5] = {'east-to-none'},
        [-5.5] = {'north-to-none'},
        [6.5] = {'east-to-none'},
        [10.5] = {'none-to-east'},
        [22.5] = {'west-to-south'},
        [26.5] = {'north-to-east'}
    },
    [358] = {
        [-17.5] = {'north-to-west'},
        [-21.5] = {'east-to-south'},
        [18.5] = {'west-to-south'},
        [22.5] = {'north-to-east'}
    },
    [354] = {
        [-13.5] = {'north-to-west'},
        [-17.5] = {'east-to-south'},
        [14.5] = {'west-to-south'},
        [18.5] = {'north-to-east'}
    },
    [382] = {
        [-17.5] = {'east-to-west'},
        [18.5] = {'west-to-east'}
    },
    [350] = {
        [-13.5] = {'east-to-south'},
        [-9.5] = {'north-to-south'},
        [-5.5] = {'north-to-south'},
        [-1.5] = {'north-to-south'},
        [2.5] = {'north-to-south'},
        [6.5] = {'north-to-south'},
        [10.5] = {'north-to-south'},
        [14.5] = {'north-to-east'}
    }
}

return Public

--[[
  31 | 350, 2.5 | north-to-south
  32 | 350, 6.5 | north-to-south
  33 | 362, 6.5 | east-to-none
  34 | 350, 10.5 | north-to-south
  35 | 362, 10.5 | none-to-east
  36 | 366, 10.5 | west-to-south
  37 | 350, 14.5 | north-to-east
  38 | 366, 14.5 | north-to-east
  39 | 354, 14.5 | west-to-south
  40 | 370, 14.5 | west-to-south
  41 | 354, 18.5 | north-to-east
  42 | 370, 18.5 | north-to-east
  43 | 358, 18.5 | west-to-south
  44 | 374, 18.5 | west-to-east
  45 | 378, 18.5 | west-to-east
  52 | 382, 18.5 | west-to-east
  53 | 358, 22.5 | north-to-east
  54 | 362, 22.5 | west-to-south
  55 | 362, 26.5 | north-to-east
  56 | 366, 26.5 | west-to-south
  57 | 366, 30.5 | north-to-east
  58 | 370, 30.5 | west-to-east
  65 | 374, 30.5 | west-to-east
  71 | 378, 30.5 | west-to-none

  1 | 378, -29.5 | none-to-west
  2 | 366, -25.5 | north-to-west
  3 | 366, -29.5 | east-to-south
  4 | 370, -29.5 | east-to-west
  5 | 374, -29.5 | east-to-west
  6 | 362, -21.5 | north-to-west
  7 | 362, -25.5 | east-to-south
  8 | 358, -17.5 | north-to-west
  9 | 358, -21.5 | east-to-south
  10 | 354, -13.5 | north-to-west
  11 | 354, -17.5 | east-to-south
  12 | 370, -13.5 | north-to-west
  13 | 370, -17.5 | east-to-south
  14 | 374, -17.5 | east-to-west
  15 | 378, -17.5 | east-to-west
  16 | 382, -17.5 | east-to-west
  23 | 350, -13.5 | east-to-south
  24 | 366, -9.5 | north-to-west
  25 | 366, -13.5 | east-to-south
  26 | 350, -9.5 | north-to-south
  27 | 362, -9.5 | east-to-none
  28 | 350, -5.5 | north-to-south
  29 | 362, -5.5 | north-to-none
  30 | 350, -1.5 | north-to-south
]]
