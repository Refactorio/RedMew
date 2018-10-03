local Module = {}

Module.donator_perk_flags = {
    rank = 0x1,
    train = 0x2
}

local d = Module.donator_perk_flags

Module.donators = {
    ['robertkruijt'] = d.rank + d.train,
    ['aldldl'] = d.rank,
    ['Geostyx'] = d.rank,
    ['Linaori'] = d.rank,
    ['Terarink'] = d.rank + d.train,
    ['Xertez'] = d.rank,
    ['Chevalier1200'] = d.rank + d.train,
    ['DraugTheWhopper'] = d.rank + d.train,
    ['der-dave.com'] = d.rank + d.train,
    ['Jayefuu'] = d.rank,
    ['Chromaddict'] = d.rank,
    ['Valansch'] = d.rank
}

Module.welcome_messages = {
    ['Linaori'] = 'I present to you Linaori of house Refactorio, Lady of the Void, Remover of Spaghetti, Queen of the Endless Nauvis, Breaker of Biters and Mother of Code!',
    ['Valansch'] = 'Welcome Valansch, <insert custom welcome message here>.',
    ['der-dave.com'] = "Dave doesn't want a welcome message."
}

return Module
