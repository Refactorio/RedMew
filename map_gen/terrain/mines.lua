local Event = require 'utils.event'
local Game = require 'utils.game'

local mines_factor = 1

local mines_factor_sq = 16384 * 16384 / mines_factor / mines_factor

local death_messages = {
    "went exploring, and didn't bring a minesweeping kit.",
    'wandered off, and found that it really is dangerous to go alone.',
    'found that minesweeper in factorio gives no hints.',
    'died, and they were only one day away from retirement',
    'is too old for this s$%t',
    "ponders the question, 'How might I avoid mines in the future'",
    'exploded with rage',
    'thought it was clear, found it was not.',
    'thought it was clear, was wrong.',
    'paved the way for expansion!',
    'sacrificed their body to the greater factory expansion',
    'no longer wonders why nobody else has built here',
    'just wants to watch the respawn timer window',
    'like life, mines are unfair, next time bring a helmet',
    'should’ve thrown a grenade before stepping over there',
    'is farming the death counter',
    'fertilized the soil',
    "found no man's land, also found it applies to them.",
    'curses the map maker',
    'does not look forward to the death march back to retreive items',
    'wont be going for a walk again',
    'really wants a map.',
    'forgot their xray goggles',
    'rather Forgot to bring x-ray goggles',
    'learned that the biters defend their territory',
    'mines 1, Ninja skills 0.'
}

local function player_died(event)
    local player = Game.get_player_by_index(event.player_index)
    if not player or not player.valid then
        return
    end

    local message = player.name .. ' ' .. death_messages[math.random(1, #death_messages)]
    game.print(message)
end
Event.add(defines.events.on_player_died, player_died)

return function(x, y)
    local distance_sq = x * x + y * y

    if distance_sq <= 44100 then
        return nil
    end

    local chance = math.floor(mines_factor_sq / distance_sq) + 1

    if math.random(chance) == 1 then
        return {name = 'land-mine', force = 'enemy'}
    end
end
