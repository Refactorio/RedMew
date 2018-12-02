-- 10 minute cycle, 4m of full light, 4m light to dark, 6s full dark, 2m dark to light
local day_night_cycle = {
    ['ticks_per_day'] = 36000,
    ['dusk'] = 0.2,
    ['evening'] = 0.59,
    ['morning'] = 0.6,
    ['dawn'] = 0.8
}
return day_night_cycle
