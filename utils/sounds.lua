local default_sound_path = 'utility/console_message'

local Sounds = {}

local function play(players, sound_path)
  local sound = sound_path or default_sound_path
  if not helpers.is_valid_sound_path(sound) then
    error('Invalid sound path ' .. sound_path)
    return
  end
  for _, player in pairs(players) do
    if player and player.valid then
      player.play_sound{ path = sound, volume_modifier = 1 }
    end
  end
end

---@param player LuaPlayer
---@param sound_path string
Sounds.notify_player = function(player, sound_path)
  play({player}, sound_path)
end

---@param player LuaForce
---@param sound_path string
Sounds.notify_force = function(force, sound_path)
  play(force.connected_players, sound_path)
end

---@param sound_path string
Sounds.notify_admins = function(sound_path)
  for _, player in pairs(game.connected_players) do
    if player.admin then
      play({player}, sound_path)
    end
  end
end

---@param player LuaForce
---@param sound_path string
Sounds.notify_allies = function(force, sound_path)
  for _, f in pairs(game.forces) do
    if (f.index == force.index) or f.is_friend(force) then
      play(f.connected_players, sound_path)
    end
  end
end

---@param sound_path string
Sounds.notify_all = function(sound_path)
  play(game.connected_players, sound_path)
end

return Sounds
