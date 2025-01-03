local Public = {}

local OPS = {
  ['=']  = function(v1, v2) return v1 == v2 end,
  ['=='] = function(v1, v2) return v1 == v2 end,
  ['>']  = function(v1, v2) return v1 >  v2 end,
  ['<']  = function(v1, v2) return v1 <  v2 end,
  ['≥']  = function(v1, v2) return v1 >= v2 end,
  ['>='] = function(v1, v2) return v1 >= v2 end,
  ['≤']  = function(v1, v2) return v1 <= v2 end,
  ['<='] = function(v1, v2) return v1 <= v2 end,
  ['≠']  = function(v1, v2) return v1 ~= v2 end,
  ['!='] = function(v1, v2) return v1 ~= v2 end,
  ['~='] = function(v1, v2) return v1 ~= v2 end,
}

local level = function(quality)
  if type(quality) == 'string' then
    quality = prototypes.quality[quality]
  end
  return quality and quality.level or 0
end

-- Compare two quality identifiers based on the specified comparator
---@param q1 QualityID First quality ID
---@param q2 QualityID Second quality ID
---@param comparator string Comparison operator
---@return boolean Result of comparison
local compare = function(q1, q2, comparator)
  if type(comparator) ~= 'string' then
    error('Invalid comparator: expected string, got ' .. type(comparator))
  end

  local comparison_function = OPS[comparator]
  if not comparison_function then
    error('Invalid comparator: ' .. comparator)
  end

  local l1 = level(q1)
  local l2 = level(q2)

  return comparison_function(l1, l2)
end

-- Create a wrapper function for the given comparator operation
local operation = function(comparator)
  return function(q1, q2)
    return compare(q1, q2, comparator)
  end
end

Public.compare = compare
Public.equal = operation('=')
Public.not_equal = operation('!=')
Public.greater_than = operation('>')
Public.less_than = operation('<')
Public.equal_or_greater_than = operation('>=')
Public.equal_or_less_than = operation('<=')

return Public
