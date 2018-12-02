-- 10 minute cycle, 6s of full light, 2m light to dark, 4m full dark, 4m dark to light
local day_night_cycle = {
    ['ticks_per_day'] = 36000,
    ['dusk'] = 0,
    ['evening'] = 0.2,
    ['morning'] = 0.6,
    ['dawn'] = 0.99
}
return day_night_cycle
