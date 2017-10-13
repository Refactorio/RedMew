    -- Copyright (c) 2016-2017 SL

    -- This file is part of SL-extended.

    -- SL-extended is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU Affero General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.

    -- SL-extended is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU Affero General Public License for more details.

    -- You should have received a copy of the GNU Affero General Public License
    -- along with SL-extended.  If not, see <http://www.gnu.org/licenses/>.


-- sl_traincolor.lua
-- 20170602
-- 
-- SL-extended, autodownload mod / savefile mod

-- https://forums.factorio.com/viewtopic.php?f=94&t=39562

-- Modified by SL.

-- Credit:
--  Sirenfal (Train_Ore_Color)

-- for k,v in pairs(ink_add_for_rgb({
--    {['r'] = 255, ['g'] = 100, ['b'] = 0},
--    {['r'] = 0, ['g'] = 0, ['b'] = 255},
-- })) do
--     print(tostring(k) .. ': ' .. tostring(v))
-- end

colors = {
  [{['coal']=true}] = {
    ['r'] = 0,
    ['g'] = 0,
    ['b'] = 0,
  },
  [{['steel-plate']=true}] = {
    ['r'] = 160,
    ['g'] = 160,
    ['b'] = 160,
  },
  [{['iron-ore']=true, ['iron-plate']=true}] = {
    ['r'] = 0,
    ['g'] = 50,
    ['b'] = 200,
  },
  [{['copper-ore']=true, ['copper-plate']=true}] = {
    ['r'] = 255,
    ['g'] = 50,
    ['b'] = 0,
  },
  [{['raw-wood']=true, ['wood']=true}] = {
    ['r'] = 116,
    ['g'] = 37,
    ['b'] = 0,
  },
  [{['stone']=true, ['stone-brick']=true}] = {
    ['r'] = 116,
    ['g'] = 37,
    ['b'] = 0,
  },
  [{['uranium-ore']=true, ['uranium-235']=true, ['uranium-238']=true}] = {
    ['r'] = 0,
    ['g'] = 179,
    ['b'] = 0,
  },
  [{['space-science-pack']=true}] = {
    ['r'] = 255,
    ['g'] = 255,
    ['b'] = 255,
  },
}

function traincolor_on_train_changed_state(event)
  local train = event.train
  if(train.state == defines.train_state.on_the_path and not train.manual_mode and #train.cargo_wagons > 0) then
    local total = 0
    local hit = 0
    calc = {}

    for name, count in pairs(train.get_contents()) do
      for key, color in pairs(colors) do
        if(key[name] ~= nil) then

          if(calc[key] ~= nil) then
            calc[key] = calc[key] + count
          else
            hit = hit + 1
            calc[key] = count
          end

          total = total + count
        end
      end
    end

    if(hit < 1) then
      return
    elseif(hit == 1) then
      -- lua is stupid...
      local asdf = nil

      for k,v in pairs(calc) do
        asdf = k
        break
      end

      if(asdf == nil) then
        error('traincolor: nil color selection')
      end

      color = colors[asdf]
    else
      color_mix = {}

      for key, count in pairs(calc) do
        r = table.deepcopy(colors[key])
        r['o'] = count / total
        table.insert(color_mix, r)
      end

      color = ink_add_for_rgb(color_mix)
    end

    final_color = {
      ['r'] = color.r / 255,
      ['g'] = color.g / 255,
      ['b'] = color.b / 255,
      ['a'] = 0.498, -- vanilla UI uses this alpha
    }

    for _, locomotive in pairs(train.locomotives['front_movers']) do
      locomotive.color = final_color
    end

    for _, locomotive in pairs(train.locomotives['back_movers']) do
      locomotive.color = final_color
    end
  end
end



-- from original colorblend.lua

local rgb_scale = 255.0
local cmyk_scale = 100.0

-- color mixing
-- http://stackoverflow.com/a/30079700/1316748

local function rgb_to_cmyk(r,g,b)
  if r == 0 and g == 0 and b == 0 then
    return {
      ['c'] = 0,
      ['m'] = 0,
      ['y'] = 0,
      ['k'] = cmyk_scale,
    }
  end

  -- rgb [0,255] -> cmy [0,1]
  c = 1 - r / rgb_scale
  m = 1 - g / rgb_scale
  y = 1 - b / rgb_scale

  -- extract out k [0,1]
  min_cmy = math.min(c, m, y)
  c = (c - min_cmy) 
  m = (m - min_cmy) 
  y = (y - min_cmy) 
  k = min_cmy

  -- rescale to the range [0,cmyk_scale]
  return {
    ['c'] = c*cmyk_scale,
    ['m'] = m*cmyk_scale,
    ['y'] = y*cmyk_scale,
    ['k'] = k*cmyk_scale,
  }
end

local function _clamp(v, min, max)
  if(v < min) then
    return min
  elseif(v > max) then
    return max
  else
    return v
  end
end

local function cmyk_to_rgb(c,m,y,k)
  r = rgb_scale*(1.0-(c+k)/cmyk_scale)
  g = rgb_scale*(1.0-(m+k)/cmyk_scale)
  b = rgb_scale*(1.0-(y+k)/cmyk_scale)

  return {
    ['r'] = _clamp(math.floor(r), 0, 255),
    ['g'] = _clamp(math.floor(g), 0, 255),
    ['b'] = _clamp(math.floor(b), 0, 255),
  }
end

function ink_add_for_rgb(colors)
  -- input: list of rgb, opacity (r,g,b,o) colours to be added, o acts as weights (may be nil)
  local C = 0
  local M = 0
  local Y = 0
  local K = 0

  for _, color in pairs(colors) do
    local cmyk = rgb_to_cmyk(color.r, color.g, color.b)
    local o = color.o or 0.5

    C = C + (o*cmyk.c)
    M = M + (o*cmyk.m)
    Y = Y + (o*cmyk.y)
    K = K + (o*cmyk.k)
  end

  return cmyk_to_rgb(C, M, Y, K)
end
