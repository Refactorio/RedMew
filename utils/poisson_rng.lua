--Author: Valansch

local function generate_pmf_chart(l)
 chart = {[0] = math.exp(-l)}
 for k=1,(l*2 + 1) do
   chart[k]  = (chart[k - 1] * l / k)
 end
 return chart
end

local function generate_poisson_set(l, n) --n defines the resolution
 local chart = generate_pmf_chart(l)
 local set = {}
 for x,y in pairs(chart) do
  local m = math.floor(y * n + 0.5)
  for i=0,m do
   table.insert(set,x)
  end
 end
 set._n = #set
 return set
end

global.poisson_set = {}
function poisson_rng_next(l)
  if not global.poisson_set[l] then
    global.poisson_set[l] = generate_poisson_set(l, 1000)
  end
 return global.poisson_set[l][math.random(global.poisson_set[l]._n)]
end
