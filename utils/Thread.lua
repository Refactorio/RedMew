-- Threading simulation module
-- Thread.sleep()
-- @author Valansch
-- github: https://github.com/Valansch/RedMew
-- ======================================================= --

local Queue = require "utils.Queue"

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
global.actions_queue =  global.actions_queue or Queue.new()
local function on_tick()
  local queue = global.actions_queue
  for i = 1, get_actions_per_tick() do
    local action = Queue.peek(queue)
    if action ~= nil then                
      function call(params) 
        return _G[action.action](params) 
      end
      local success, result = pcall(call, action.params) -- result is error if not success else result is a boolean for if the action should stay in the queue.
      if not success then 
        log(result) 
        Queue.pop(queue)     
      elseif not result then      
        Queue.pop(queue)       
      end
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

function get_actions_per_tick()  
  local size = Queue.size(global.actions_queue)
  local apt = math.floor(math.log10(size + 1))
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


function Thread.queue_action(action, params)  
  local queue = global.actions_queue
  Queue.push(queue, {action = action, params = params})
end

Event.register(defines.events.on_tick, on_tick)

return Thread
