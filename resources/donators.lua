local Module = {}

Module.donator_perk_flags = {
    rank = 0x1,
    train = 0x2
}

local d = Module.donator_perk_flags

Module.donators = {}
--[[ {
    ['aldldl'] = {perk_flags = d.rank, welcome_messages = "ALo's Here"},
    ['Geostyx'] = {perk_flags = d.rank},
    ['Linaori'] = {
        perk_flags = d.rank,
        welcome_messages = 'I present to you Linaori of house Refactorio, Lady of the Void, Remover of Spaghetti, Queen of the Endless Nauvis, Breaker of Biters and Mother of Code!'
    },
    ['Xertez'] = {perk_flags = d.rank},
    ['Chevalier1200'] = {perk_flags = d.rank + d.train},
    ['DraugTheWhopper'] = {perk_flags = d.rank + d.train},
    ['der-dave.com'] = {perk_flags = d.rank + d.train, welcome_messages = "Dave doesn't want a welcome message."},
    ['Jayefuu'] = {perk_flags = d.rank},
    ['Valansch'] = {perk_flags = d.rank, welcome_messages = 'Welcome Valansch, <insert custom welcome message here>.'},
    ['plague006'] = {
        perk_flags = d.rank,
        welcome_messages = 'plague wrote this dumb message you have to read. If you want your own dumb on-join message be sure to donate on Patreon!'
    },
    ['chromaddict'] = {perk_flags = d.rank},
    ['InphinitePhractals'] = {perk_flags = d.rank + d.train},
    ['shoghicp'] = {perk_flags = d.rank + d.train, welcome_messages = 'Need more servers!'},
    ['DuelleuD'] = {perk_flags = d.rank + d.train},
    ['henrycn1997'] = {perk_flags = d.rank + d.train},
    ['Raiguard'] = {
        perk_flags = d.rank + d.train,
        welcome_messages = "I am... was... God. The one you call 'The Almighty'. The creator of Factories. But now, I am dead. The Biters killed me. I am sorry."
    }
} ]]
return Module
