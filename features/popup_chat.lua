local Event = require 'utils.event'
local Global = require 'utils.global'

local config = global.config.popup_chat
local MIN_LIFETIME = config.min_lifetime or 06 * 60 -- 06s
local MAX_LIFETIME = config.max_lifetime or 20 * 60 -- 20s
local MIN_MESSAGE_LENGTH = 40
local TIME_PER_CHAR = 3 -- about +1 sec every 20 chars (60/20 ticks/chars)

local data = {
  popup_chat = {}
}

Global.register(data, function(tbl)
  data = tbl
end)

---@param message string
local function message_lifetime(message)
  local length = message:len()
  if length <= MIN_MESSAGE_LENGTH then
    return MIN_LIFETIME
  end
  local extra_time = math.floor((length - MIN_MESSAGE_LENGTH) * TIME_PER_CHAR)
  return math.min(MIN_LIFETIME + extra_time, MAX_LIFETIME)
end

---@param event defines.event.on_console_chat
local function on_console_chat(event)
  local index = event.player_index
  local message = event.message
  if not (index and message) then
    return
  end

  local player = game.players[event.player_index]
  if not (player and player.character) then
    return
  end

  local popup_ID = data.popup_chat[index]
  if popup_ID then
    rendering.destroy(popup_ID)
    data.popup_chat[popup_ID] = nil
  end

  local color = table.deepcopy(player.color)
  color.a = 0.9

  popup_ID = rendering.draw_text({
    text = message,
    surface = player.surface,
    target = player.character,
    target_offset = {0, -3},
    color = color,
    font = 'compilatron-message-font',
    scale = 1.75,
    time_to_live = message_lifetime(message),
    forces = { player.force },
    alignment  = 'center',
    use_rich_text = true,
  })
  data.popup_chat[index] = popup_ID
end

Event.add(defines.events.on_console_chat, on_console_chat)
