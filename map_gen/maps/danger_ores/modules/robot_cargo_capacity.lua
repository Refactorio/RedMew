-- This module replaces mining productivity research effects with robot cargo capacity effects
local Event = require 'utils.event'

local function starts_with(str, pattern)
  return str:sub(1, #pattern) == pattern
end

Event.add(defines.events.on_research_finished, function(event)
  local tech = event.research
  if not (tech and tech.valid) then
    return
  end

  if not starts_with(tech.name, 'mining-productivity') then
    return
  end

  local force = tech.force
  force.mining_drill_productivity_bonus = 0
  force.worker_robots_storage_bonus = force.worker_robots_storage_bonus + 1

  game.print(table.concat({
    '[color=orange][Mining productivity][/color]',
    '➡',
    '[color=blue][Worker robots cargo size][/color]',
    '\nReplacing technology effects. New robots cargo capacity:',
    '[color=green][font=var]+'..force.worker_robots_storage_bonus..'[/font][/color]'
  }, '\t\t'))
end)

Event.add(defines.events.on_technology_effects_reset, function(event)
  local force = event.force
  if not (force and force.valid) then
    return
  end
  force.worker_robots_storage_bonus = force.worker_robots_storage_bonus + math.floor(force.mining_drill_productivity_bonus / 0.1)
  force.mining_drill_productivity_bonus = 0
end)
