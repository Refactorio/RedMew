local Event = require 'utils.event'
local Global = require 'utils.global'

local config = storage.config.popup_chat
local MIN_LIFETIME = config.min_lifetime or 06 * 60 -- 06s
local MAX_LIFETIME = config.max_lifetime or 20 * 60 -- 20s
local MIN_MESSAGE_LENGTH = config.min_length or 40
local MAX_MESSAGE_LENGTH = config.max_length or 92
local TIME_PER_CHAR = 3 -- about +1 sec every 20 chars (60/20 ticks/chars)

local data = {
  popup_chat = {}
}

Global.register(data, function(tbl)
  data = tbl
end)

---@param message string
local function get_message_lifetime(message)
  local length = message:len()
  if length <= MIN_MESSAGE_LENGTH then
    return MIN_LIFETIME
  end
  local extra_time = math.floor((length - MIN_MESSAGE_LENGTH) * TIME_PER_CHAR)
  return math.min(MIN_LIFETIME + extra_time, MAX_LIFETIME)
end

---@param message string
local function get_safe_message(message)
  local length = message:len()
  if length <= MAX_MESSAGE_LENGTH then
    return message
  end
  return string.sub(message, 1, MAX_MESSAGE_LENGTH) .. '[...]'
end

---@param event defines.event.on_console_chat
local function on_console_chat(event)
  local index = event.player_index
  local message = event.message
  if not (index and message) then
    return
  end

  local player = game.players[index]
  if not (player and player.valid and player.character) then
    return
  end

  local popup = data.popup_chat[index]
  if popup and popup.valid then
    popup.destroy()
    data.popup_chat[index] = nil
  end

  local safe_message = get_safe_message(message)
  local color = player.color
  color.a = 0.9

  data.popup_chat[index] = rendering.draw_text({
    text = safe_message,
    surface = player.surface,
    target = player.character,
    target_offset = {0, -4},
    color = color,
    font = 'compi',
    scale = 1.75,
    time_to_live = get_message_lifetime(safe_message),
    forces = { player.force },
    alignment = 'center',
    use_rich_text = true,
  })
end

Event.add(defines.events.on_console_chat, on_console_chat)
