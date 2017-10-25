-- Threading simulation module
-- Thread.sleep()
-- @author Valansch
-- github: https://github.com/Valansch/RedMew
-- ======================================================= --


local Thread = {}

local function set_new_next_async_callback_time()
  global.next_async_callback_time = global.callbacks[1].time
  for index, callback in pairs(global.callbacks) do
    if callback.time < global.next_async_callback_time then
      global.next_async_callback_time = callback.time
    end
  end
end

global.callbacks = {}
global.next_async_callback_time = -1
global.actions_queue_n = 0
local function on_tick()
  for action = 1, get_actions_per_tick() do
    if global.actions_queue[1] then
        global.actions_queue_n = global.actions_queue_n - 1
       local callback = global.actions_queue[1]
       pcall(_G[callback.action], callback.params)
       table.remove(global.actions_queue, 1)
    end
  end
  if game.tick == global.next_async_callback_time then
    for index, callback in pairs(global.callbacks) do
      if game.tick == callback.time then
        pcall(callback.callback, callback.params)
        table.remove(global.callbacks, index)
        if #global.callbacks == 0 then
          global.next_async_callback_time = -1
        else
          set_new_next_async_callback_time()
        end
      end
    end
  end
end

function get_actions_per_tick(count)
  --Assert actions_queue_n > -1
  local apt = math.floor(math.log10(global.actions_queue_n + 1))
  if apt < 1 then
    return 1
  else
    return apt
  end
end

function Thread.set_timeout_in_ticks(ticks, callback, params)
  local time = game.tick + ticks
  if global.next_async_callback_time == -1 or global.next_async_callback_time > time then
    global.next_async_callback_time = time
  end
  if #global.callbacks == 0 then
  end
  table.insert(global.callbacks, {time = time, callback = callback, params = params})
end

function Thread.set_timeout(sec, callback, params)
  Thread.set_timeout_in_ticks(60 * sec, callback, params)
end

global.actions_queue = {}
function Thread.queue_action(action, params)
  global.actions_queue_n = global.actions_queue_n + 1
  table.insert(global.actions_queue, {action = action, params = params})
end

Event.register(defines.events.on_tick, on_tick)

return Thread
