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
  local evolution_factor = game.forces.enemy.get_evolution_factor('islands')
  if evolution_factor > 10 and max > 2 then
    local new_evo = math.min(evolution_factor, max - 1)
    game.forces.enemy.set_evolution_factor(new_evo, 'islands')
    game.forces.enemy.set_evolution_factor(new_evo, 'mines')
  end
end)
