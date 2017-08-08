require("grid_islands_builders")

-- see bottom of file for sample presets.

-- distance in tiles between island centres.
ISLAND_X_DISTANCE = nil 
ISLAND_Y_DISTANCE = nil

NOT_LAND = nil -- use "out-of-map" or "water" for non-land tiles.
PATH = nil -- the function used to make paths between islands.

-- number of columns and rows in the pattern. If lookup fails uses empty island.
PATTERN_COLS = nil
PATTERN_ROWS = nil
PATTERN = nil  -- the 2D array describing the repeating pattern of islands

-- shifts the whole map x and y number of tiles.
GLOBAL_X_SHIFT = 0
GLOBAL_Y_SHIFT = 0

REPLACE_GEN_WATER = nil -- if set will replace water from the base world generator with the specified tile.

START_BUILDER = nil --if set overrides the builder in the pattern at [1][1] but only for spawn.

local function example_preset()
    local shape1 = scale(rectangle_builder(16,16), 1, 2)
    local shape2 = rotate(scale(circle_builder(8), 1, 2),degrees(90))
    local shape3 = compound_or({shape1, shape2})

    ISLAND_X_DISTANCE = 40  
    ISLAND_Y_DISTANCE = 40   
    NOT_LAND = "out-of-map"
    PATH = path_builder(6)

    PATTERN_COLS = 6
    PATTERN_ROWS = 3
    PATTERN =
    {
        { rotate(shape1, degrees(0) ), rotate(shape1, degrees(30) ), rotate(shape1, degrees(60) ), rotate(shape1, degrees(90) ), rotate(shape1, degrees(120) ), rotate(shape1, degrees(150) ) },
        { rotate(shape2, degrees(0) ), rotate(shape2, degrees(30) ), rotate(shape2, degrees(60) ), rotate(shape2, degrees(90) ), rotate(shape2, degrees(120) ), rotate(shape2, degrees(150) ) },
        { rotate(shape3, degrees(0) ), rotate(shape3, degrees(30) ), rotate(shape3, degrees(60) ), rotate(shape3, degrees(90) ), rotate(shape3, degrees(120) ), rotate(shape3, degrees(150) ) }        
    }
end

local function square_and_circle_preset()
    local square = rectangle_builder(128,128)
    local circle = circle_builder(48)    

    ISLAND_X_DISTANCE = 256    
    ISLAND_Y_DISTANCE = 256 
    NOT_LAND = "out-of-map"    
    PATH = path_builder(16)

    PATTERN_COLS = 2
    PATTERN_ROWS = 2
    PATTERN =
    {
        { square, circle },
        { circle, square }
    }
end

local function rooms_preset()
    local square = rectangle_builder(128,128)       

    ISLAND_X_DISTANCE = 144  
    ISLAND_Y_DISTANCE = 144  
    NOT_LAND = "out-of-map"
    PATH = path_builder(8)
    --PATH = rotate(path_builder(8), degrees(45))

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        { square }      
    }
end

local function cross_preset()
    local shape1 = rectangle_diamond_builder(640, 64)
    local shape2 = rectangle_diamond_builder(64, 640)
    local shape3 = compound_or({shape1, shape2})

    ISLAND_X_DISTANCE = 241
    ISLAND_Y_DISTANCE = 241    
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { shape3 }
    }
end

local function oval_cross_preset()
    local shape1 = scale( circle_builder(32), 1, 5)
    local shape2 = rotate(shape1, degrees(45))
    local shape3 = rotate(shape1, degrees(45 + 90))
    local shape4 = compound_or({shape2, shape3})

    ISLAND_X_DISTANCE = 225  
    ISLAND_Y_DISTANCE = 225  
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { shape4 }
    }
end

local function spider_preset()
    local leg = rectangle_builder(32,480)
    local head = translate (oval_builder(32, 64), 0, -64)
    local body = translate (circle_builder(64), 0, 64)

    local count = 10
    local angle = 360 / count
    local list = { head, body }
    for i = 1, (count / 2) - 1 do
        local shape = rotate(leg, degrees(i * angle))
        table.insert( list, shape )
    end  

    local spider = compound_or(list) 
    --spider = invert(spider)  

    ISLAND_X_DISTANCE = 320  
    ISLAND_Y_DISTANCE = 320  
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
      { spider }
    }
end

local function multiple_path_preset()
    ISLAND_X_DISTANCE = 160  
    ISLAND_Y_DISTANCE = 160  
    NOT_LAND = "out-of-map"
    local path1 = path_builder(24)
    local path2 = rotate(path1, degrees(45))
    PATH = compound_or({path1, path2})

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { empty_builder }
    }
end

local function donut_preset()
    local small = invert(circle_builder(64))
    local big = circle_builder(128)
    local donut = compound_and({ small, big })

    GLOBAL_X_SHIFT = 0
    GLOBAL_Y_SHIFT = 96

    ISLAND_X_DISTANCE = 256  
    ISLAND_Y_DISTANCE = 256  
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { donut }
    }
end

local function rings_preset()

    local ring1 = compound_and({ invert(circle_builder(16)), circle_builder(32) })
    local ring2 = compound_and({ invert(circle_builder(48)), circle_builder(64) })
    local ring3 = compound_and({ invert(circle_builder(80)), circle_builder(96) })
    local ring4 = compound_and({ invert(circle_builder(112)), circle_builder(128) })    

    local path = translate(rectangle_builder(96, 8), 64, 0)

    local shape = compound_or({ ring1, ring2, ring3, ring4, path, rotate(path, degrees(90)), rotate(path, degrees(180)), rotate(path, degrees(270)) })    

    GLOBAL_X_SHIFT = 0
    GLOBAL_Y_SHIFT = 24

    ISLAND_X_DISTANCE = 256  
    ISLAND_Y_DISTANCE = 256   
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { shape }
    }
end

local function rings2_preset()

    local scale_factor = 2

    local ring1 = compound_and({invert(circle_builder(16)),circle_builder(32)})
    local ring2 = compound_and({invert(circle_builder(48)),circle_builder(64)})
    local ring3 = compound_and({invert(circle_builder(80)),circle_builder(96)})
    local ring4 = compound_and({invert(circle_builder(112)),circle_builder(128)})

    local rings = compound_or({ ring1, ring2, ring3, ring4 })
    rings = scale(rings, 2, 1)

    local path1 = translate(rectangle_builder(576, 8), 340, 0)
    local path2 = translate(rectangle_builder(576, 8), -340, 0)
    local path3 = translate(rectangle_builder(8, 384), 0, 220)
    local path4 = translate(rectangle_builder(8, 384), 0, -220)

    local shape = compound_or({rings, path1, path2, path3, path4 })
    shape = rotate(shape, degrees(45))
    shape = scale(shape, scale_factor, scale_factor)

    GLOBAL_X_SHIFT = 0
    GLOBAL_Y_SHIFT = 24 * scale_factor

    ISLAND_X_DISTANCE = 420 * scale_factor
    ISLAND_Y_DISTANCE = 420 * scale_factor    
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
       { shape }
    }
end

local function dickbutt_preset()
    ISLAND_X_DISTANCE = 600    
    ISLAND_Y_DISTANCE = 660 
    NOT_LAND = "water"
    PATH = empty_builder

    local body = rotate(oval_builder(128,256), degrees(20))
    local butt = translate(rotate(oval_builder(180, 128), degrees(30)), 130,100)

    local shaft = translate(rotate(oval_builder(32, 80), degrees(0)), 220, -80)
    local ball1 = translate(rotate(oval_builder(32,16), degrees(10)), 250,-50)
    local ball2 = translate(rotate(oval_builder(48,16), degrees(5)), 240,-40)

    local leg1 = translate(rotate(rectangle_builder(16, 80), degrees(175)), 80, 280)
    local leg2 = translate(rotate(rectangle_builder(16, 80), degrees(5)), 180, 250)
    local foot1 = translate(rotate(rectangle_builder(16, 40), degrees(65)), 65, 315)
    local foot2 = translate(rotate(rectangle_builder(16, 40), degrees(65)), 170, 285)

    local eye1 = translate(circle_builder(32),-130, -100)   

    local dickbutt = compound_or({body,butt,  shaft, ball1, ball2, leg1, leg2, foot1, foot2, eye1 })
    dickbutt = translate(dickbutt, -80, 0)

    local patch = scale(dickbutt, 0.15, 0.15)
    local iron_patch = resource_module_builder(translate(scale(dickbutt, 0.15, 0.15), 20, 0), "iron-ore")
    local copper_patch = resource_module_builder(translate(scale(dickbutt, 0.115, 0.115), -125, 50), "copper-ore")
    local coal_patch = resource_module_builder(translate(scale(dickbutt, 0.1, 0.1), -135, -90), "coal")
    local stone_patch = resource_module_builder(translate(scale(dickbutt, 0.075, 0.075), 50, 150), "stone")

    local patches = compound_or({ iron_patch, copper_patch, coal_patch, stone_patch })

    --dickbutt = invert(dickbutt) -- builder_with_resource(dickbutt, patches)

    local dickbutt2 = rotate(dickbutt, degrees(45))
    local dickbutt3 = rotate(dickbutt, degrees(90))
    local dickbutt4 = rotate(dickbutt, degrees(135))
    local dickbutt5 = rotate(dickbutt, degrees(180))


    PATTERN_COLS = 5
    PATTERN_ROWS = 5
    PATTERN =
    {
        { dickbutt, dickbutt2, dickbutt3, dickbutt4, dickbutt5 },
        { dickbutt2, dickbutt3, dickbutt4, dickbutt5, dickbutt },
        { dickbutt3, dickbutt4, dickbutt5, dickbutt, dickbutt2 },
        { dickbutt4, dickbutt5, dickbutt, dickbutt2, dickbutt3 },
        { dickbutt5, dickbutt, dickbutt2, dickbutt3, dickbutt4 },
    }
end



local function dickbutt2_preset()
    local pic = require("grid_islands_data.dickbutt2_data")    

    local dickbutt = picture_builder(pic.data, pic.width, pic.height)

    local patch = scale(dickbutt, 0.15, 0.15)
    local iron_patch = resource_module_builder(translate(scale(dickbutt, 0.2, 0.2), -50, -20), "iron-ore")
    local copper_patch = resource_module_builder(translate(scale(dickbutt, 0.17, 0.17), -75, 50), "copper-ore")
    local coal_patch = resource_module_builder(translate(scale(dickbutt, 0.15, 0.15), 25, 50), "coal")
    local stone_patch = resource_module_builder(translate(scale(dickbutt, 0.12, 0.12), -75, -100), "stone")

    local patches = compound_or({ iron_patch, copper_patch, coal_patch, stone_patch })
    dickbutt = builder_with_resource(dickbutt, patches)

    local dickbutt2 = rotate(dickbutt, degrees(45))
    local dickbutt3 = rotate(dickbutt, degrees(90))
    local dickbutt4 = rotate(dickbutt, degrees(135))
    local dickbutt5 = rotate(dickbutt, degrees(180))

    GLOBAL_X_SHIFT = 12
    GLOBAL_Y_SHIFT = 12 

    ISLAND_X_DISTANCE = 550     
    ISLAND_Y_DISTANCE = 500 
    NOT_LAND = "water"
    PATH = empty_builder

    PATTERN_COLS = 5
    PATTERN_ROWS = 5
    PATTERN =
    {
        { dickbutt, dickbutt2, dickbutt3, dickbutt4, dickbutt5 },
        { dickbutt2, dickbutt3, dickbutt4, dickbutt5, dickbutt },
        { dickbutt3, dickbutt4, dickbutt5, dickbutt, dickbutt2 },
        { dickbutt4, dickbutt5, dickbutt, dickbutt2, dickbutt3 },
        { dickbutt5, dickbutt, dickbutt2, dickbutt3, dickbutt4 },
    }   
end

local function cross_image_preset()
    local pic = require("grid_islands_data.crosses_data")    

    local scale_factor = 3
    local shape = picture_builder(pic.data, pic.width, pic.height)

    shape = scale(shape, scale_factor, scale_factor)
    shape = invert(shape)

    GLOBAL_X_SHIFT = -32 * scale_factor

    ISLAND_X_DISTANCE = 609 * scale_factor    
    ISLAND_Y_DISTANCE = 1114 * scale_factor
    NOT_LAND = "out-of-map"
    REPLACE_GEN_WATER= "grass"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function cross_image2_preset()
    local pic = require("grid_islands_data.crosses2_data")    

    local scale_factor = 20
    local shape = picture_builder(pic.data, pic.width, pic.height)

    shape = scale(shape, scale_factor, scale_factor)
    shape = invert(shape)

    GLOBAL_X_SHIFT = -10 * scale_factor

    ISLAND_X_DISTANCE = pic.width * scale_factor    
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function darthplagueis_preset()
    local pic = require("grid_islands_data.darthplagueis_data")    

    local scale_factor = 1
    local shape = picture_builder(pic.data, pic.width, pic.height)

    shape = scale(shape, scale_factor, scale_factor)
    --shape = invert(shape)

    GLOBAL_Y_SHIFT = -10 * scale_factor

    ISLAND_X_DISTANCE = pic.width * scale_factor    
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function goat_preset()   

    local pic = require("grid_islands_data.goat_data")  
    
    local goat1 = picture_builder(pic.data, pic.width, pic.height)   

    local floor = translate(rectangle_builder(pic.width, 32), 0 , (pic.height / 2) + 12)

    local goats = { floor, goat1 }

    local sf = 0.75    
    local tf = 0.7
    local s = 1
    local t = 0    
    for i = 1, 5 do
        s = s * sf
        t = t + (s * tf * pic.height)
        local goat = translate(scale(goat1, s, s), 0, -t)
        table.insert( goats, goat )        
    end

    local ceiling = translate(rectangle_builder(pic.width, 32), 0 , -t - 32)
    table.insert( goats, ceiling )     

    local shape = translate(compound_or(goats), 0, (t / 2) - 60)

-- for custom goat ores
--[[
    local function rot(table)
        local len = #table
        local copy = {}        
        for i = 1, len -1 do
            copy[i+1] = table[i]           
        end
        copy[1] = table[len]
        return copy
    end
    
    local patch = flip_x(goat1)
    --patch = throttle_xy(patch, 1, 2, 1 ,2)
    local iron_patch = resource_module_builder(scale(patch,0.12,0.12), "iron-ore", function(x,y) return 500 end)
    local copper_patch = resource_module_builder(scale(patch,0.12,0.12), "copper-ore", function(x,y) return 500 end)
    local coal_patch = resource_module_builder(scale(patch,0.12,0.12), "coal", function(x,y) return 500 end)
    local stone_patch = resource_module_builder(scale(patch,0.12,0.12), "stone", function(x,y) return 500 end)
    local uraniumn_patch = resource_module_builder(scale(patch,0.12,0.12), "uraniumn-ore", function(x,y) return 500 end)
    local oil_patch = resource_module_builder(scale(patch,0.12,0.12), "crude-oil", function(x,y) return 500 end)


    local patch1 = translate(scale(patch,0.2,0.2),0,170)
    local patch2 = translate(scale(patch,0.15,0.15),0,25)
    local patch3 = translate(scale(patch,0.12,0.12),0,-88)
    local patch4 = translate(scale(patch,0.1,0.1),0,-173)
    local patch5 = translate(scale(patch,0.08,0.08),0,-238)
    local patch6 = translate(scale(patch,0.04,0.04),0,-282)
    local patch_table = { patch1, patch2, patch3, patch4, patch5, patch6 }

    local function do_nothing(builder, x, y) return builder(x, y) end
    local function throttle(builder, x, y)         
        if x % 4 < 1 and y % 4 < 1 then     
            return builder(x, y) 
        else
            return false
        end
    end

    local function linear(base, mult) 
        return function(x, y)
            return base + (math.abs(x) + math.abs(y)) * mult
        end
    end

    local res1 = {do_nothing, "iron-ore", linear(500, 1) }
    local res2 = {do_nothing,"copper-ore", linear(400, 0.8) }
    local res3 = {do_nothing,"coal", linear(400, 0.7) }
    local res4 = {do_nothing,"stone", linear(200, 0.6) }
    local res5 = {do_nothing,"uranium-ore", linear(50, 0.1) }
    local res6 = {throttle, "crude-oil", linear(18750, 300) }    
    local res_table = { res2, res3, res4, res5, res6, res1 }
    
    local res_tables = {}    
    for i = 1, 6 do    
        table.insert(res_tables, res_table)
        res_table = rot(res_table)
    end

    local function res_builder(x, y, world_x, world_y)
        local col_pos = math.floor(world_x / ISLAND_X_DISTANCE + 0.5)  
        local row_pos = math.floor(world_y / ISLAND_Y_DISTANCE + 0.5)
        local offset = ((math.abs(col_pos) + math.abs(row_pos)) % 6) + 1

        local rt = res_tables[offset]
        for k, v in ipairs(patch_table) do
                local r = rt[k]
                local f = r[1]
                local name = r[2]
                local amount = r[3]
            if f(v,x,y) then                
                return name, amount(world_x, world_y)
            end
        end
    end

    --local patches = compound_or(patch_table)
    --local iron = resource_module_builder(patches,"iron-ore", function(x,y) return 400 end)
    --local iron_goat = builder_with_resource(shape, iron)

    local res_goat = builder_with_resource(shape, res_builder)

    shape = res_goat
--]]

    local shape2 = flip_x(shape)
    local shape3 = flip_y(shape)
    local shape4 = flip_y(shape2)    

    GLOBAL_X_SHIFT = 1

    REPLACE_GEN_WATER = "water-green"

    ISLAND_X_DISTANCE = pic.width 
    ISLAND_Y_DISTANCE = pic.height + t - 105
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 2
    PATTERN_ROWS = 2
    PATTERN =
    {
        {shape, shape2},
        {shape3, shape4},
    }  
end

local function goat_preset2()
    local pic = require("grid_islands_data.goat_data")     
    
    local scale_factor = 0.2

    --local goat1 = scale(picture_builder(pic.data, pic.width, pic.height),scale_factor,scale_factor)
    local goat1 = rectangle_builder(32,32)

    --local width = pic.width * scale_factor
    --local height = pic.height * scale_factor

    local width = 32
    local height = 32

    --goat1 = translate(goat1, 0, height / 2)

    local sf = 2     
    local tf = 1.8
    local base = 1 / sf
    local log_b = math.log(sf)

    local function builder(x, y)        
        local y2 = (y / height) + 1.5
        if y2 <= 0 then
            return false
        end

        local log_y = math.log(y2)
        local i = (math.floor(log_y / log_b)) 

        if i < 0 then 
            return false
        end

        local scale = sf ^ -i
        local trans = ((sf ^ i) * (tf ^ -i) * height) - height
        trans = math.floor( y2 ) * height

        return goat1(x * scale, (y * scale) - (trans/2) )        
    end
    
    local shape = builder

    ISLAND_X_DISTANCE = 1000000
    ISLAND_Y_DISTANCE = 1000000
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {builder}
    }  
end

local function island_map_preset()
    local square = rectangle_builder(160,160)
    local circle = circle_builder(60)  

    local leg = rectangle_builder(32,480)
    local head = translate (oval_builder(32, 64), 0, -64)
    local body = translate (circle_builder(64), 0, 64)

    local count = 10
    local angle = 360 / count
    local list = { head, body }
    for i = 1, (count / 2) - 1 do
        local shape = rotate(leg, degrees(i * angle))
        table.insert( list, shape )
    end  

    local spider = compound_or(list)   

    local patch = scale(spider, 0.125, 0.125)
    local iron_patch = resource_module_builder(patch, "iron-ore", function(x,y) return 500 + (math.abs(x) + math.abs(y)) end)
    local copper_patch = resource_module_builder(patch, "copper-ore",function(x,y) return 400 + (math.abs(x) + math.abs(y)) * 0.8  end)
    local coal_patch = resource_module_builder(patch, "coal",function(x,y) return 300 + (math.abs(x) + math.abs(y)) * 0.7  end)
    local stone_patch = resource_module_builder(patch, "stone",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.5 end)
    local uraniumn_patch = resource_module_builder(scale(patch, 0.5,0.5), "uranium-ore",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.2 end)   
    local oil_patch = resource_module_builder(patch, "crude-oil",function(x,y) return 75000 + (math.abs(x) + math.abs(y)) * 500 end)

    local iron_circle = builder_with_resource(circle, iron_patch)
    local copper_circle = builder_with_resource(circle, copper_patch)
    local coal_circle = builder_with_resource(circle, coal_patch)
    local stone_circle = builder_with_resource(circle, stone_patch)
    local uraniumn_circle = builder_with_resource(circle, uraniumn_patch)
    local oil_circle = builder_with_resource(circle, oil_patch)

    local start_patch = scale(spider, 0.0625, 0.0625)
    local start_iron_patch = resource_module_builder(translate(start_patch, 48, 0), "iron-ore", function(x,y) return 500 end)
    local start_copper_patch = resource_module_builder(translate(start_patch, 0, -48), "copper-ore", function(x,y) return 400 end)
    local start_stone_patch = resource_module_builder(translate(start_patch, -48, 0), "stone", function(x,y) return 200 end)
    local start_coal_patch = resource_module_builder(translate(start_patch, 0, 48), "coal", function(x,y) return 300 end)

    local start_resources = compound_or({ start_iron_patch, start_copper_patch, start_stone_patch, start_coal_patch })

    START_BUILDER = builder_with_resource(square_diamond_builder(224), start_resources)

    ISLAND_X_DISTANCE = 288    
    ISLAND_Y_DISTANCE = 288 
    NOT_LAND = "out-of-map"    
    PATH = path_builder(16)

    PATTERN_COLS = 6
    PATTERN_ROWS = 6
    PATTERN =
    {
        { square, iron_circle, square, iron_circle, square, stone_circle },
        { coal_circle, square, oil_circle, square, copper_circle, square },
        { square, iron_circle, square, copper_circle, square, coal_circle },
        { stone_circle, square, uraniumn_circle, square, iron_circle, square },
        { square, iron_circle, square, oil_circle, square, copper_circle },
        { copper_circle, square, iron_circle, square, coal_circle, square },
    }
end

local function broken_web_preset()
    local pic = require("grid_islands_data.broken_web_data") 
    local scale_factor = 5
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    shape = scale(shape, scale_factor, scale_factor)

    ISLAND_X_DISTANCE = pic.width * scale_factor
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "water"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function hexes_preset()
    local pic = require("grid_islands_data.hexes_data") 
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    shape = invert(shape)

    ISLAND_X_DISTANCE = pic.width
    ISLAND_Y_DISTANCE = pic.height
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function mics_stuff_preset()
    local pic = require("grid_islands_data.mics_stuff_data") 
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    local scale_factor = 5
    shape = scale(invert(shape), scale_factor, scale_factor)

    ISLAND_X_DISTANCE = pic.width * scale_factor
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "water"
    REPLACE_GEN_WATER = "grass"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function cage_preset()
    local pic = require("grid_islands_data.cage_data") 
    
    local shape = picture_builder(pic.data, pic.width, pic.height)

    ISLAND_X_DISTANCE = pic.width 
    ISLAND_Y_DISTANCE = pic.height 
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function cubes_preset()
    local pic = require("grid_islands_data.cubes_data") 
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    local scale_factor = 5

    shape = scale(shape, scale_factor, scale_factor)
    

    ISLAND_X_DISTANCE = pic.width *scale_factor
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "water"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function poop_emoji_preset()
    local pic = require("grid_islands_data.poop_emoji_data") 
    local scale_factor = 0.2
    
    local poop = picture_builder(pic.data, pic.width, pic.height)
    poop = scale(poop, scale_factor, scale_factor)

    local iron_patch = resource_module_builder(poop,"iron-ore", function(x,y) return 500 + (math.abs(x) + math.abs(y)) end)
    local copper_patch = resource_module_builder(poop, "copper-ore",function(x,y) return 400 + (math.abs(x) + math.abs(y)) * 0.8  end)
    local coal_patch = resource_module_builder(poop, "coal",function(x,y) return 300 + (math.abs(x) + math.abs(y)) * 0.7  end)
    local stone_patch = resource_module_builder(poop, "stone",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.5 end)
    local uraniumn_patch = resource_module_builder(poop, "uranium-ore",function(x,y) return 100 + (math.abs(x) + math.abs(y)) * 0.2 end)   
    local oil_patch = resource_module_builder(throttle_xy(poop, 1, 4, 1, 4), "crude-oil",function(x,y) return 75000 + (math.abs(x) + math.abs(y)) * 500 end)

    local iron_poop = builder_with_resource(full_builder, iron_patch )
    local copper_poop = builder_with_resource(full_builder, copper_patch )
    local coal_poop = builder_with_resource(full_builder, coal_patch )
    local stone_poop = builder_with_resource(full_builder, stone_patch )
    local uraniumn_poop = builder_with_resource(full_builder, uraniumn_patch )
    local oil_poop = builder_with_resource(full_builder, oil_patch )

    ISLAND_X_DISTANCE = pic.width * scale_factor * 1.5
    ISLAND_Y_DISTANCE = pic.height * scale_factor * 1.5
    NOT_LAND = "out-of-map"
    REPLACE_GEN_WATER = "grass"
    PATH = empty_builder

    PATTERN_COLS = 3
    PATTERN_ROWS = 3
    PATTERN =
    {
        {iron_poop, copper_poop, oil_poop },
        {coal_poop, iron_poop, copper_poop},
        {stone_poop, coal_poop, uraniumn_poop},
    }   
end

local function mona_lisa_preset()
    local scale_factor = 3

    local pic = require("grid_islands_data.mona_lisa_data") 
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    local up = scale(shape, scale_factor, scale_factor)

    local down = flip_y(up)
    local right = flip_x(up)
    local right_down = flip_xy(up)
    

    ISLAND_X_DISTANCE = pic.width * scale_factor
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "out-of-map"
    PATH = empty_builder
    REPLACE_GEN_WATER = "grass"
    GLOBAL_Y_SHIFT = 67 * scale_factor

    PATTERN_COLS = 2
    PATTERN_ROWS = 2
    PATTERN =
    {
        {up, right},
        {down, right_down}
    }   
end

local function creation_of_adam_preset()
    local scale_factor = 1

    local pic = require("grid_islands_data.creation_of_adam_data") 
    local outerbox = rectangle_builder(pic.width + 256, pic.height)
    local innerbox = invert( rectangle_builder(pic.width,pic.height))
    local border = compound_and({outerbox,innerbox})
    border = invert(border)
    
    local shape = picture_builder(pic.data, pic.width, pic.height)    
    shape = invert(shape)

    
    shape = compound_and({border, shape})
    local up = scale(shape, scale_factor, scale_factor)

    local down = flip_y(up)
    local right = flip_x(up)
    local right_down = flip_xy(up)
    

    ISLAND_X_DISTANCE = pic.width * scale_factor +256
    ISLAND_Y_DISTANCE = pic.height * scale_factor 
    NOT_LAND = "water"
    PATH = empty_builder
    REPLACE_GEN_WATER = "grass"
    --GLOBAL_Y_SHIFT = 67 * scale_factor

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {up, right},
        {down, right_down}
    }   
end

local function gears_preset()
    local pic = require("grid_islands_data.gears_data") 
    local scale_factor = 1
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    shape = scale(shape, scale_factor, scale_factor)
    --shape = invert(shape)

    ISLAND_X_DISTANCE = pic.width * scale_factor
    ISLAND_Y_DISTANCE = pic.height * scale_factor
    NOT_LAND = "water"
    REPLACE_GEN_WATER = "grass"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function maori_preset()
    local pic = require("grid_islands_data.maori_data") 
    local scale_factor = 3
    
    local shape = picture_builder(pic.data, pic.width, pic.height)
    shape =scale(shape, scale_factor, scale_factor)

    ISLAND_X_DISTANCE = (pic.width - 1) * scale_factor
    ISLAND_Y_DISTANCE = (pic.height - 1) * scale_factor
    NOT_LAND = "out-of-map"
    PATH = empty_builder

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }   
end

local function lines_preset()
    local scale_factor = 10

    local pic = require("grid_islands_data.lines_data")     
    
    local shape = picture_builder(pic.data, pic.width, pic.height)    
    shape = scale(shape, scale_factor, scale_factor)
    shape = invert(shape)    
    
    
    ISLAND_X_DISTANCE = (pic.width ) * scale_factor 
    ISLAND_Y_DISTANCE = (pic.height ) * scale_factor 
    NOT_LAND = "out-of-map"
    PATH = empty_builder
    REPLACE_GEN_WATER = "grass"    

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }    
end

local function test_preset()
    local scale_factor = 10

    local pic = require("grid_islands_data.test_data")     
    
    local shape = picture_builder(pic.data, pic.width, pic.height)    
    shape = scale(shape, scale_factor, scale_factor)
    --shape = invert(shape)    
    
    
    ISLAND_X_DISTANCE = (pic.width + 50) * scale_factor 
    ISLAND_Y_DISTANCE = (pic.height + 50) * scale_factor 
    NOT_LAND = "water"
    PATH = empty_builder
    REPLACE_GEN_WATER = "grass"
    --GLOBAL_Y_SHIFT = 67 * scale_factor

    PATTERN_COLS = 1
    PATTERN_ROWS = 1
    PATTERN =
    {
        {shape}
    }    
end

-- uncomment the preset you want to use.
--example_preset()
--square_and_circle_preset()
--rooms_preset()
--cross_preset()
--oval_cross_preset()
--spider_preset()
--multiple_path_preset()
--donut_preset()
--rings_preset()
--rings2_preset()
--dickbutt_preset()
--dickbutt2_preset()
--cross_image_preset()
--cross_image2_preset()
--darthplagueis_preset()
--goat_preset()
--goat_preset2()
--island_map_preset()
--broken_web_preset()
--hexes_preset()
--mics_stuff_preset()
--cage_preset()
--cubes_preset()
--poop_emoji_preset()
--mona_lisa_preset()
--creation_of_adam_preset()
--gears_preset()
--maori_preset()
lines_preset()
--test_preset()