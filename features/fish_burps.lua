-- A feature to add cute flying text of a fish when a player uses a fish to heal themselves. Useful for teamwork.
local Event = require 'utils.event'

local function capsule_used(event)
    if event.item.name ~= "raw-fish" then
        return
    end

    local player =  game.get_player(event.player_index)
    if not player or not player.valid or not player.character or not player.character.valid then
        return
    end

    local health_ratio = player.character.get_health_ratio()
    if health_ratio == 1 then -- to stop people spamming it
        return
    end

    player.surface.create_entity {
        name = 'tutorial-flying-text',
        text = '[img=item.raw-fish]',
        position = {player.position.x,player.position.y-3} -- creates the fish just above players head
    }

end

Event.add(defines.events.on_player_used_capsule, capsule_used)