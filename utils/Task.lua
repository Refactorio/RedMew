-- Threading simulation module
-- Task.sleep()
-- @author Valansch
-- github: https://github.com/Valansch/RedMew
-- ======================================================= --

local Queue = require "utils.Queue"

local Task = {}

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
global.task_queue =  global.task_queue or Queue.new()
global.total_task_weight = 0
local function on_tick()
  local queue = global.task_queue
  for i = 1, get_task_per_tick() do
    local task = Queue.peek(queue)
    if task ~= nil then                       
      local success, result = pcall(_G[task.func_name], task.params) -- result is error if not success else result is a boolean for if the task should stay in the queue.
      if not success then 
        log(result) 
        Queue.pop(queue)
        global.total_task_weight = global.total_task_weight - task.weight     
      elseif not result then      
        Queue.pop(queue)
        global.total_task_weight = global.total_task_weight - task.weight       
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

function get_task_per_tick()  
  local size = global.total_task_weight
  local apt = math.floor(math.log10(size + 1))
  if apt < 1 then
    return 1
  else
    return apt
  end
end

function Task.set_timeout_in_ticks(ticks, callback, params)
  local time = game.tick + ticks
  if global.next_async_callback_time == -1 or global.next_async_callback_time > time then
    global.next_async_callback_time = time
  end
  if #global.callbacks == 0 then
  end
  table.insert(global.callbacks, {time = time, callback = callback, params = params})
end

function Task.set_timeout(sec, callback, params)
  Task.set_timeout_in_ticks(60 * sec, callback, params)
end


function Task.queue_task(func_name, params, weight)
  weight = weight or 1
  global.total_task_weight = global.total_task_weight + weight
  Queue.push(global.task_queue, {func_name = func_name, params = params, weight = weight})
end

Event.register(defines.events.on_tick, on_tick)

return Task
