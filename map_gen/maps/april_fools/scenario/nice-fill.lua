local Event = require 'utils.event'

function force_debug(msg)
  for _, character in pairs(game.players) do
    character.print(msg)
  end
end

function string.starts(String, Start)
  return string.sub(String, 1, string.len(Start)) == Start
end

function tmpsurface_set(tmpsurface, x, y, value)
  if tmpsurface == nil then
    tmpsurface = {}
  end
  if tmpsurface[x] == nil then
    tmpsurface[x] = {}
  end
  tmpsurface[x][y] = value
end

function tmpsurface_get(tmpsurface, x, y)
  if tmpsurface[x] == nil then
    return nil
  end
  if tmpsurface[x][y] == nil then
    return nil
  end
  return tmpsurface[x][y]
end

function absfloor(x)
  if x > 0 then
    return math.floor(x)
  end

  return math.ceil(x)
end

function do_nicefill(game, event)
  if event.player_index == nil then
    event.player_index = 1
  end

  evtsurface = game.surfaces[event.surface_index];
  evtsurfacename = evtsurface.name;
  nicename = 'tmp_surface_' .. evtsurfacename;

  character = game.players[event.player_index]

  if event.item.name == 'landfill' then
    -- delete tmp_surface surface, we are no longer using it
    if game.surfaces['tmp_surface'] ~= nil then
      game.delete_surface('tmp_surface')
    end

    if game.surfaces[nicename] ~= nil and event.tiles ~= nil and event.tiles[1] ~= nil then

      if not game.surfaces[nicename].is_chunk_generated({ x = (event.tiles[1].position.x / 32), y = (event.tiles[1].position.y / 32) }) then
        game.surfaces[nicename].request_to_generate_chunks({ x = event.tiles[1].position.x, y = event.tiles[1].position.y }, 0)
      end

      game.surfaces[nicename].force_generate_chunk_requests()

      if string.match(game.surfaces[nicename].get_tile(event.tiles[1].position).name, 'water') ~= nil then
        -- fix incorrect surface
        log('tmp_surface surface regenerate')
        game.delete_surface(nicename)
      end
    end

    if game.surfaces[nicename] == nil then
      -- make a copy of the world, without water.
      local map_gen_settings = evtsurface.map_gen_settings

      map_gen_settings.autoplace_controls['enemy-base'] = { frequency = 'none', size = 'none', richness = 'none' }
      map_gen_settings.autoplace_controls['trees'] = { frequency = 'none', size = 'none', richness = 'none' }
      map_gen_settings.autoplace_settings = {
        entity = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } },
        decorative = { treat_missing_as_default = false, settings = { frequency = 'none', size = 'none', richness = 'none' } },
      }

      map_gen_settings.water = 'none'
      map_gen_settings.starting_area = 'none'
      map_gen_settings.starting_points = {}
      map_gen_settings.peaceful_mode = true
      map_gen_settings.cliff_settings = { cliff_elevation_0 = 0, cliff_elevation_interval = 0, name = 'cliff' }

      for name, _ in pairs(game.tile_prototypes) do
        if name:find('water') then
          map_gen_settings.property_expression_names['tile:' .. name .. ':probability'] = -1000
        end
      end

      if pcall(game.create_surface, nicename, map_gen_settings) then
      else
        log('tmp_surface surface fail.')
      end

      tmp_surface_surface = game.surfaces[nicename]
      -- character.force.print( serpent.block( map_gen_settings ) )
    else
      tmp_surface_surface = game.surfaces[nicename]
    end

    local tilelist = {} -- this list is temporary, it contains tiles that has been landfilled, and we remove ready tiles from it each round.

    -- build teporary list of landfilled tiles
    for k, vv in pairs(event.tiles) do
      local v = vv.position -- quick fix for 0.16.17
      local lc = 0;

      if not tmp_surface_surface.is_chunk_generated({ x = (v.x / 32), y = (v.y / 32) }) then
        tmp_surface_surface.request_to_generate_chunks({ x = v.x, y = v.y }, 0)
      end

      tmp_surface_surface.force_generate_chunk_requests()

      local NFSTile = tmp_surface_surface.get_tile({ x = v.x, y = v.y })

      if string.match(NFSTile.name, 'water') ~= nil then
        log('tmp_surface failed to get correct texture. Default will be used at x:' .. v.x .. ' y:' .. v.y .. ' failing source texture is: ' .. NFSTile.name)
      else
        table.insert(tilelist, { name = NFSTile.name, position = NFSTile.position })
      end
    end
    -- and update the game map. There is probably a way to cache this too, TODO?

    local waterblend_tilelist = {}
    -- local tileghosts = {}
    for k, vv in pairs(event.tiles) do
      local v = vv.position

      for i = -2, 2 do
        for j = -2, 2 do
          tmppos = { x = (v.x + j), y = (v.y + i) }
          if evtsurface.get_tile(tmppos).name == 'deepwater' then
            local tmptile = evtsurface.get_tile(tmppos)
            local tmptg = evtsurface.find_entities_filtered { position = tmppos, radius = 1, type = 'tile-ghost' }
            local preserve_ghost = false
            for tgk, tgv in pairs(tmptg) do
              preserve_ghost = true
            end

            if preserve_ghost == false then
              table.insert(waterblend_tilelist, { name = 'water', position = tmppos })
            end
          end
        end
      end
    end

    evtsurface.set_tiles(waterblend_tilelist)
    evtsurface.set_tiles(tilelist)
  end
end

Event.add(defines.events.on_robot_built_tile, function(event)
  local sfcindex = {}
  for k, v in pairs(game.surfaces) do
    sfcindex[v.name] = k
  end

  if event.robot.name == 'character' and event.robot.valid == false then
    if event.player_index ~= nil then
      event.surface_index = sfcindex[game.players[event.player_index].surface.name]
      if event.item.name == 'grass-1' then
        event.item = game.item_prototypes['landfill']
      end
    end
  else
    event.surface_index = sfcindex[event.robot.surface.name]
  end

  if not pcall(do_nicefill, game, event) then
    log('tmp_surface failed.')
  end
end)

Event.add(defines.events.on_player_built_tile, function(event)
  local sfcindex = {}
  for k, v in pairs(game.surfaces) do
    sfcindex[v.name] = k
  end

  event.surface_index = sfcindex[game.players[event.player_index].surface.name]

  if not pcall(do_nicefill, game, event) then
    log('tmp_surface failed.')
  end
end)

Event.add(defines.events.script_raised_set_tiles, function(event)
  if not event.tiles or not event.tiles[1] then
    return
  end

  event.item = game.item_prototypes[event.tiles[1].name]

  if not pcall(do_nicefill, game, event) then
    log('tmp_surface failed.')
  end
end)
