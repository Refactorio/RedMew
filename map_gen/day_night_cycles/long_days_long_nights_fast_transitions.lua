-- 20 minute cycle, 9m of full light, 1m light to dark, 9m full dark, 1m dark to light
local day_night_cycle = {
    ['ticks_per_day'] = 72000,
    ['dusk'] = 0.225,
    ['evening'] = 0.275,
    ['morning'] = 0.725,
    ['dawn'] = 0.775
}
return day_night_cycle
