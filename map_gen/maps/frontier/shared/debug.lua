
local Debug = {}

function Debug.print_admins(msg, color)
  for _, p in pairs(game.connected_players) do
    if p.admin then
      p.print(msg, color)
    end
  end
end

function Debug.print(msg, color)
  for _, p in pairs(game.connected_players) do
    p.print(msg, color)
  end
end

function Debug.log(data)
  log(serpent.block(data))
end

local function noise_to_tile_map(noise)
  if noise > 80 / 100 then
    return 'red-refined-concrete'
  elseif noise > 45 / 100 then
    return 'orange-refined-concrete'
  elseif noise > 10 / 100 then
    return 'yellow-refined-concrete'
  elseif noise > -10 / 100 then
    return 'green-refined-concrete'
  elseif noise > -45 / 100 then
    return 'cyan-refined-concrete'
  elseif noise > -80 / 100 then
    return 'blue-refined-concrete'
  else
    return 'black-refined-concrete'
  end
end

function Debug.show_noise_value(surface, position, noise, render_values)
  surface.set_tiles({{
    name = noise_to_tile_map(noise),
    position = position,
  }}, false, true, true, false)
  if render_values then
    rendering.draw_text{
      text = string.format('%.2f', noise),
      surface = surface,
      target = position,
      draw_on_ground = true,
      color = { 255, 255, 255 },
      only_in_alt_mode = true,
    }
  end
end

return Debug
