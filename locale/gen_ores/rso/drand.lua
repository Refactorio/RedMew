--[[------------------------------------
RandomLua v0.3.1
Pure Lua Pseudo-Random Numbers Generator
Under the MIT license.
copyright(c) 2011 linux-man
--]]------------------------------------

local _M = {}
local mod = math.fmod
local floor = math.floor
local abs = math.abs

local function normalize(n) --keep numbers at (positive) 32 bits
	return n % 0x80000000
end

local function bit_and(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) and (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_or(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if (a % 2 == 1) or (b % 2 == 1) then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function bit_xor(a, b)
	local r = 0
	local m = 0
	for m = 0, 31 do
		if a % 2 ~= b % 2 then r = r + 2^m end
		if a % 2 ~= 0 then a = a - 1 end
		if b % 2 ~= 0 then b = b - 1 end
		a = a / 2 b = b / 2
	end
	return normalize(r)
end

local function seed()
	--return normalize(tonumber(tostring(os.time()):reverse()))
	return normalize(os.time())
end

--Mersenne twister
mersenne_twister = {}
mersenne_twister.__index = mersenne_twister

function mersenne_twister:randomseed(s)
	if not s then s = seed() end
	self.mt[0] = normalize(s)
	for i = 1, 623 do
		self.mt[i] = normalize(0x6c078965 * bit_xor(self.mt[i-1], floor(self.mt[i-1] / 0x40000000)) + i)
	end
end

function mersenne_twister:random(a, b)
	local y
	if self.index == 0 then
		for i = 0, 623 do   											
			--y = bit_or(floor(self.mt[i] / 0x80000000) * 0x80000000, self.mt[(i + 1) % 624] % 0x80000000)
			y = self.mt[(i + 1) % 624] % 0x80000000
			self.mt[i] = bit_xor(self.mt[(i + 397) % 624], floor(y / 2))
			if y % 2 ~= 0 then self.mt[i] = bit_xor(self.mt[i], 0x9908b0df) end
		end
	end
	y = self.mt[self.index]
	y = bit_xor(y, floor(y / 0x800))
	y = bit_xor(y, bit_and(normalize(y * 0x80), 0x9d2c5680))
	y = bit_xor(y, bit_and(normalize(y * 0x8000), 0xefc60000))
	y = bit_xor(y, floor(y / 0x40000))
	self.index = (self.index + 1) % 624
	if not a then return y / 0x80000000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a)
		end
	else
		return a + (y % (b - a + 1))
	end
end

function _M.twister(s)
	local temp = {}
	setmetatable(temp, mersenne_twister)
	temp.mt = {}
	temp.index = 0
	temp:randomseed(s)
	return temp
end

--Linear Congruential Generator
linear_congruential_generator = {}
linear_congruential_generator.__index = linear_congruential_generator

function linear_congruential_generator:random(a, b)
	local y = (self.a * self.x + self.c) % self.m
	self.x = y
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
		return a + (y % (b - a + 1))
	end
end

function linear_congruential_generator:randomseed(s)
	if not s then s = seed() end
	self.x = normalize(s)
end

function _M.lcg(s, r)
	local temp = {}
	setmetatable(temp, linear_congruential_generator)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp:randomseed(s)
	return temp
end

-- Multiply-with-carry
multiply_with_carry = {}
multiply_with_carry.__index = multiply_with_carry

function multiply_with_carry:random(a, b)
	local m = self.m
	local t = self.a * self.x + self.c
	local y = t % m
	self.x = y
	self.c = floor(t / m)
	if not a then return y / 0x10000
	elseif not b then
		if a == 0 then return y
		else return 1 + (y % a) end
	else
    local diff = 0
    if a == b then return a end
    if a < 0 then
      diff = abs(a)
      a = a + diff
      b = b + diff
    end
		return a + (y % (b - a + 1)) - diff
	end
end

function multiply_with_carry:randomseed(s)
	if not s then s = seed() end
	self.c = self.ic
	self.x = normalize(s)
end

function _M.mwc(s, r)
	local temp = {}
	setmetatable(temp, multiply_with_carry)
	temp.a, temp.c, temp.m = 1103515245, 12345, 0x10000  --from Ansi C
	if r then
		if r == 'nr' then temp.a, temp.c, temp.m = 1664525, 1013904223, 0x10000 --from Numerical Recipes.
		elseif r == 'mvc' then temp.a, temp.c, temp.m = 214013, 2531011, 0x10000 end--from MVC
	end
	temp.ic = temp.c
	temp:randomseed(s)
	return temp
end

function _M.mwvc(s)
  return _M.mwc(s, 'mvc')
end

local B =  0x10000

-- rough adaptation of Knuth float generator
function _M.krandom( seedobj, fVal1, fVal2 )
  local ma = seedobj.ma
  local seed = seedobj.seed
  local mj, mk
  if seed < 0 or not ma then
    ma = {}
    seedobj.ma = ma
    mj = normalize( seed )
    mj = mod( mj, B )
    ma[55] = mj
    mk = 1
    for i = 1, 54 do
      local ii = mod( 21 * i,  55 )
      ma[ii] = mk
      mk = mj - mk
      if mk < 0 then mk = mk + B end
      mj = ma[ii]
    end
    for k = 1, 4 do
      for i = 1, 55 do
        ma[i] = ma[i] - ma[ 1 + mod( i + 30,  55) ]
        if ma[i] < 0 then ma[i] = ma[i] + B end
      end
    end
    seedobj.inext = 0
    seedobj.inextp = 31
    seedobj.seed = 1
  end -- if
  local inext = seedobj.inext
  local inextp = seedobj.inextp
  inext = inext + 1
  if inext == 56 then inext = 1 end
  seedobj.inext = inext
  inextp = inextp + 1
  if inextp == 56 then inextp = 1 end
  seedobj.inextp = inextp
  mj = ma[ inext ] - ma[ inextp ]
  if mj < 0 then mj = mj + B end
  ma[ inext ] = mj
  local temp_rand = mj / B
  if fVal2 then
    return floor( fVal1 + 0.5 + temp_rand * ( fVal2 - fVal1 ) )
  elseif fVal1 then
    return floor( temp_rand * fVal1 ) + 1
  else
    return temp_rand
  end
end

-- Sys rand
sys_rand = {}
sys_rand.__index = sys_rand
function sys_rand:random(a, b)
  local diff = 0
  if a and b and a == b then math.random(); return a end
  if a and b then
    if a < 0 then
      diff = abs(a)
      a = a + diff
      b = b + diff
    end
    return math.random(a, b) - diff 
  end
  if a and a == 0 then return floor(math.random() * 0x10000) end
  if a then return math.random(a) end
  return math.random()
end

function sys_rand:randomseed(s)
   -- ignore
   return
end

function _M.sys_rand(s)
	local temp = {}
	setmetatable(temp, sys_rand)
	return temp
end

return _M