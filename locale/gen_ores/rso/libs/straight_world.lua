
local blocksize=8
local blocksizem1=blocksize-1
local blocksized2=math.floor(blocksize/2)

local ti=table.insert

local function fill(surface, x0,y0,name,amount,step,shift)
  step=step or 1
  shift=shift or 0
  for y=y0+shift,y0+blocksize-1,step do
    for x=x0+shift,x0+blocksize-1,step do
      surface.create_entity{name=name,position={x,y},amount=amount}
    end
  end
end

function straightWorld(surface, leftTop, rightBottom)
  local lt = leftTop
  local rb = rightBottom
  for y0=lt.y,rb.y-1,blocksize do
    for x0=lt.x,rb.x-1,blocksize do
      local tile=surface.get_tile(x0,y0).name
      local tiles={}
      for y=y0,y0+blocksizem1 do
        for x=x0,x0+blocksizem1 do
          ti(tiles,{name=tile,position={x,y}})
        end
      end
      surface.set_tiles(tiles)
      local ent=surface.find_entities{{x0,y0},{x0+blocksize,y0+blocksize}}
      local haveTree=false
      local amount=0
      local haveResource=false
      local haveDecor=false
      for _,e in ipairs(ent) do
        if e.position.x>=x0 and e.position.y>=y0 then
          if e.type=="resource" then
            haveResource=e.name
            amount=e.amount
            e.destroy()
          elseif e.type=="tree" then
            haveTree=e.name
            e.destroy()
          elseif e.type=="decorative" then
            haveDecor=e.name
            e.destroy()
          elseif e.type=="simple-entity" then
            e.destroy()
          end
        end
      end
      if haveResource then
        if haveResource=="crude-oil"  or string.sub(haveResource,1,4) == "lava" then
          surface.create_entity{name=haveResource,amount=amount,position={x0+blocksized2,y0+blocksized2}}
        else
          fill(surface, x0,y0,haveResource,amount)
        end
      end
      if not haveResource and haveTree then
        fill(surface, x0,y0,haveTree,nil,4)
      end
      if haveDecor then
        fill(surface, x0,y0,haveDecor,nil,2,1)
      end
    end
  end
end
