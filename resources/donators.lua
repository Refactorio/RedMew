local Module = {}

Module.donator_perk_flags = {
    rank = 0x1,
    train = 0x2
}

local d = Module.donator_perk_flags

Module.donators = {
    ['aldldl'] = d.rank,
    ['Geostyx'] = d.rank,
    ['Linaori'] = d.rank,
    ['Xertez'] = d.rank,
    ['Chevalier1200'] = d.rank + d.train,
    ['DraugTheWhopper'] = d.rank + d.train,
    ['der-dave.com'] = d.rank + d.train,
    ['Jayefuu'] = d.rank,
    ['Valansch'] = d.rank,
    ['plague006'] = d.rank,
    ['chromaddict'] = d.rank,
    ['InphinitePhractals'] = d.rank + d.train,
    ['shoghicp'] = d.rank + d.train,
    ['DuelleuD'] = d.rank + d.train,
    ['henrycn1997'] = d.rank + d.train,
    ['Raiguard'] = d.rank + d.train
}

Module.welcome_messages = {
    ['Linaori'] = 'I present to you Linaori of house Refactorio, Lady of the Void, Remover of Spaghetti, Queen of the Endless Nauvis, Breaker of Biters and Mother of Code!',
    ['Valansch'] = 'Welcome Valansch, <insert custom welcome message here>.',
    ['der-dave.com'] = "Dave doesn't want a welcome message.",
    ['plague006'] = 'plague wrote this dumb message you have to read. If you want your own dumb on-join message be sure to donate on Patreon!',
    ['shoghicp'] = 'Need more servers!',
    ['aldldl'] = "ALo's Here",
    ['Raiguard'] = "I am... was... God. The one you call 'The Almighty'. The creator of Factories. But now, I am dead. The Biters killed me. I am sorry."
}

return Module
