-- dependencies
local Config = require 'map_gen.Diggy.Config'.features.MarketExchange

-- this
local MarketUnlockables = {}
local floor = math.floor
local ceil = math.ceil
local log10 = math.log10

--- Handles a truncation of numbers to create simple large numbers
-- eg. 1593251 could become 1590000 with precision 3
-- number larger than 10 million will have an precision of +1
-- @param precision number of the precision wanted (number of significant digits)
-- @param precise_number number that needs to be truncated/simplified
--
local function truncate(precision, precise_number)
    local number = precise_number
    local number_length = floor(log10(number) + 1)
    precision = (number_length >= 8) and (precision + 1) or precision
    local exponent = number_length - precision
    number = number / 10 ^ exponent
    number = floor(number) * 10 ^ exponent
    return number, number_length
end

--- Handles the level requirement to stone sent. Calculates based on a formula one number corresponding to that levels cost
-- You can configure this in Diggy.Config.lua under features.MarketExchange
-- @param level number of a level
-- @returns number of cost corresponding to the level based on a calculation
--
function MarketUnlockables.calculate_level(level) -- all configurable variables must be integers.
    local b = floor(Config.difficulty_scale) or 25 -- Default 25 <-- Controls how much stone is needed.
    local start_value = floor(Config.start_stone) or 50 -- The start value/the first level cost
    local formula = b * (level ^ 3) + (start_value - b)

    local precision = floor(Config.cost_precision) or 2 -- Sets the precision

    -- Truncates to the precision and prevents duplicates by incrementing with 5 in the third highest place.
    -- First evaluates loosely if the previous level requirement would return same number after truncating.
    -- If true evaluates down all levels to level 1 for the precise number
    -- (In case itself got incremented)
    -- Only useful if three or more values turns out to be the same after truncating, thus the loosely evaluation to save an expensive recursive function
    local number, number_lenght = truncate(precision, formula)
    local prev_number = truncate(precision, b * ((level - 1) ^ 3) + (start_value - b))
    if (level ~= 1 and number == prev_number) then
        local prev_number = MarketUnlockables.calculate_level((level - 1))
        while (prev_number >= number) do
            number = (prev_number < number) and number or ceil(number + (5 * 10 ^ (number_lenght - 3)))
        end
    end
    return number
end

return MarketUnlockables
