-- Threading simulation module
-- Task.sleep()
-- @author Valansch
-- github: https://github.com/Valansch/RedMew
-- ======================================================= --

local Queue = require "utils.Queue"
local PriorityQueue = require "utils.PriorityQueue"
local Event = require "utils.event"

local Task = {}

global.callbacks = global.callbacks or PriorityQueue.new()
global.next_async_callback_time = -1
global.task_queue = global.task_queue or Queue.new()
global.total_task_weight = 0
global.task_queue_speed = 1

local function comp(a, b)
  return a.time < b.time
end

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

  local callbacks = global.callbacks
  local callback = PriorityQueue.peek(callbacks)
  while callback ~= nil and game.tick >= callback.time do
    local success, error = pcall(_G[callback.func_name], callback.params)
    if not success then      
      log(error)
    end    
    PriorityQueue.pop(callbacks, comp)    
    callback = PriorityQueue.peek(callbacks)
  end  
end

global.tpt = global.task_queue_speed
function get_task_per_tick()  
  if game.tick % 300 == 0 then
    local size = global.total_task_weight
    global.tpt = math.floor(math.log10(size + 1)) * global.task_queue_speed
    if global.tpt < 1 then
      global.tpt = 1
    end
  end
  return global.tpt
end

function Task.set_timeout_in_ticks(ticks, func_name, params)
  local time = game.tick + ticks  
  local callback = {time = time, func_name = func_name, params = params}
  PriorityQueue.push(global.callbacks, callback, comp)
end

function Task.set_timeout(sec, func_name, params)
  Task.set_timeout_in_ticks(60 * sec, func_name, params)
end

function Task.queue_task(func_name, params, weight)
  weight = weight or 1
  global.total_task_weight = global.total_task_weight + weight
  Queue.push(global.task_queue, {func_name = func_name, params = params, weight = weight})
end

Event.add(defines.events.on_tick, on_tick)

return Task
