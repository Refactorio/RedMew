require("config")

local blocksize=6
local blockThreshold=straightWorldPlatformsThreshold
local blocksizem1=blocksize-1
local platformName = "building-platform"

function straightWorldPlatforms(surface, leftTop, rightBottom)
  local lt = leftTop
  local rb = rightBottom
  if surface == nil then
    return
  end
  for y0=lt.y,rb.y-1,blocksize do
    for x0=lt.x,rb.x-1,blocksize do
      --Check all blocks for platforms
      local replaceBlocks = false   
      local blockCount = 0
      for y1=y0,y0+blocksizem1 do
         for x1=x0,x0+blocksizem1 do
           local tileObj = surface.get_tile(x1,y1)
           if tileObj ~= nil and tileObj.valid then 
             local tile=tileObj.name
             if tile == platformName then    
              blockCount = blockCount + 1
             end
             if blockCount > (blocksize * blocksize) * blockThreshold then
               replaceBlocks = true
              break
             end
           end
         end
         if replaceBlocks == true then break end
      end
      --if enough platforms are found, replace the blocks
      if replaceBlocks then 
        local tiles={}
        for y=y0,y0+blocksizem1 do
         for x=x0,x0+blocksizem1 do
           table.insert(tiles,{name=platformName,position={x,y}})
         end
        end
        surface.set_tiles(tiles) 
      end
    end
  end
end
