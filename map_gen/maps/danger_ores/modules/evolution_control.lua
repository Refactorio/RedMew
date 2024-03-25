local Event = require 'utils.event'

local relations = {
  ['logistic-science-pack'] = 10,
  ['military-science-pack'] = 20,
  ['chemical-science-pack'] = 40,
  ['production-science-pack'] = 50,
  ['utility-science-pack'] = 90,
}

Event.on_nth_tick(103, function()
  local max = 0
  local tech = game.forces.player.technologies
  for name, evo in pairs(relations) do
    if tech[name] and tech[name].researched then
      max = math.max(max, evo)
    end
  end
  if game.forces.enemy.evolution_factor > 10 and max > 2 then
    game.forces.enemy.evolution_factor = math.min(game.forces.enemy.evolution_factor, max - 1)
  end
end)
