local Module = {}

Module.donator_perk_flags = {
    rank = 0x1,
    welcome = 0x2, -- not implemented
    train = 0x4,
    currency = 0x8 -- not implemented
}

local d = Module.donator_perk_flags

Module.donators = {
    ['robertkruijt'] =  d.rank + d.train,
    ['aldldl'] =        d.rank + d.train,
    ['Geostyx'] =       d.rank + d.train,
    ['Linaori'] =       d.rank + d.train,
    ['Terarink'] =      d.rank + d.train,
    ['Xertez'] =        d.rank + d.train,
}

return Module
