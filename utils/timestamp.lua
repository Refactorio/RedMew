--- source https://github.com/daurnimator/luatz/blob/master/luatz/timetable.lua
-- edited down to just what is needed.

local Public = {}

local floor = math.floor

local function borrow(tens, units, base)
    local frac = tens % 1
    units = units + frac * base
    tens = tens - frac
    return tens, units
end

local function carry(tens, units, base)
    if units >= base then
        tens = tens + floor(units / base)
        units = units % base
    elseif units < 0 then
        tens = tens + floor(units / base)
        units = (base + units) % base
    end
    return tens, units
end

local function is_leap(y)
    if (y % 4) ~= 0 then
        return false
    elseif (y % 100) ~= 0 then
        return true
    else
        return (y % 400) == 0
    end
end

local mon_lengths = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

local function month_length(m, y)
    if m == 2 then
        return is_leap(y) and 29 or 28
    else
        return mon_lengths[m]
    end
end

local function normalise(sec)
    local year = 1970
    local month = 1
    local day = 1
    local hour = 0
    local min = 0
    -- `month` and `day` start from 1, need -1 and +1 so it works modulo
    month, day = month - 1, day - 1

    -- Convert everything (except seconds) to an integer
    -- by propagating fractional components down.
    year, month = borrow(year, month, 12)
    -- Carry from month to year first, so we get month length correct in next line around leap years
    year, month = carry(year, month, 12)
    month, day = borrow(month, day, month_length(floor(month + 1), year))
    day, hour = borrow(day, hour, 24)
    hour, min = borrow(hour, min, 60)
    min, sec = borrow(min, sec, 60)

    -- Propagate out of range values up
    -- e.g. if `min` is 70, `hour` increments by 1 and `min` becomes 10
    -- This has to happen for all columns after borrowing, as lower radixes may be pushed out of range
    min, sec = carry(min, sec, 60) -- TODO: consider leap seconds?
    hour, min = carry(hour, min, 60)
    day, hour = carry(day, hour, 24)
    -- Ensure `day` is not underflowed
    -- Add a whole year of days at a time, this is later resolved by adding months
    -- TODO[OPTIMIZE]: This could be slow if `day` is far out of range
    while day < 0 do
        month = month - 1
        if month < 0 then
            year = year - 1
            month = 11
        end
        day = day + month_length(month + 1, year)
    end
    year, month = carry(year, month, 12)

    -- TODO[OPTIMIZE]: This could potentially be slow if `day` is very large
    while true do
        local i = month_length(month + 1, year)
        if day < i then
            break
        end
        day = day - i
        month = month + 1
        if month >= 12 then
            month = 0
            year = year + 1
        end
    end

    -- Now we can place `day` and `month` back in their normal ranges
    -- e.g. month as 1-12 instead of 0-11
    month, day = month + 1, day + 1

    return {year = year, month = month, day = day, hour = hour, min = min, sec = sec}
end

--- Converts unix epoch timestamp into table {year: number, month: number, day: number, hour: number, min: number, sec: number}
-- @param  sec<number> unix epoch timestamp
-- @return {year: number, month: number, day: number, hour: number, min: number, sec: number}
Public.to_timetable = normalise

--- Converts unix epoch timestamp into human readable string.
-- @param  secs<type> unix epoch timestamp
-- @return string
function Public.to_string(secs)
    local tt = normalise(secs)
    return table.concat({tt.year, '-', tt.month, '-', tt.day, ' ', tt.hour, ':', tt.min, ':', tt.sec})
end

return Public
