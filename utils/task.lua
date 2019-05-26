-- Threading simulation module
-- Task.sleep()
-- @author Valansch and Grilledham
-- github: https://github.com/Refactorio/RedMew
-- ======================================================= --

local Queue = require 'utils.queue'
local PriorityQueue = require 'utils.priority_queue'
local Event = require 'utils.event'
local Token = require 'utils.token'
local ErrorLogging = require 'utils.error_logging'

local Task = {}

global.callbacks = global.callbacks or PriorityQueue.new()
global.next_async_callback_time = -1
global.task_queue = global.task_queue or Queue.new()
global.total_task_weight = 0
global.task_queue_speed = 1

local function comp(a, b)
    return a.time < b.time
end

global.tpt = global.task_queue_speed
local function get_task_per_tick()
    if game.tick % 300 == 0 then
        local size = global.total_task_weight
        global.tpt = math.floor(math.log10(size + 1)) * global.task_queue_speed
        if global.tpt < 1 then
            global.tpt = 1
        end
    end
    return global.tpt
end

local function on_tick()
    local queue = global.task_queue
    for i = 1, get_task_per_tick() do
        local task = Queue.peek(queue)
        if task ~= nil then
            -- result is error if not success else result is a boolean for if the task should stay in the queue.
            local success, result = pcall(Token.get(task.func_token), task.params)
            if not success then
                if _DEBUG then
                    error(result)
                else
                    log(result)
                    ErrorLogging.generate_error_report(result)
                end
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
        local success, result = pcall(Token.get(callback.func_token), callback.params)
        if not success then
            if _DEBUG then
                error(result)
            else
                log(result)
                ErrorLogging.generate_error_report(result)
            end
        end
        PriorityQueue.pop(callbacks, comp)
        callback = PriorityQueue.peek(callbacks)
    end
end

--- Allows you to set a timer (in ticks) after which the tokened function will be run with params given as an argument
-- Cannot be called before init
-- @param ticks <number>
-- @param func_token <number> a token for a function store via the token system
-- @param params <any> the argument to send to the tokened function
function Task.set_timeout_in_ticks(ticks, func_token, params)
    if not game then
        error('cannot call when game is not available', 2)
    end
    local time = game.tick + ticks
    local callback = {time = time, func_token = func_token, params = params}
    PriorityQueue.push(global.callbacks, callback, comp)
end

--- Allows you to set a timer (in seconds) after which the tokened function will be run with params given as an argument
-- Cannot be called before init
-- @param sec <number>
-- @param func_token <number> a token for a function store via the token system
-- @param params <any> the argument to send to the tokened function
function Task.set_timeout(sec, func_token, params)
    if not game then
        error('cannot call when game is not available', 2)
    end
    Task.set_timeout_in_ticks(60 * sec, func_token, params)
end

--- Queueing allows you to split up heavy tasks which don't need to be completed in the same tick.
-- Queued tasks are generally run 1 per tick. If the queue backs up, more tasks will be processed per tick.
-- @param func_token <number> a token for a function stored via the token system
-- If this function returns `true` it will run again the next tick, delaying other queued tasks (see weight)
-- @param params <any> the argument to send to the tokened function
-- @param weight <number> (defaults to 1) weight is the number of ticks a task is expected to take.
-- Ex. if the task is expected to repeat multiple times (ie. the function returns true and loops several ticks)
function Task.queue_task(func_token, params, weight)
    weight = weight or 1
    global.total_task_weight = global.total_task_weight + weight
    Queue.push(global.task_queue, {func_token = func_token, params = params, weight = weight})
end

Event.add(defines.events.on_tick, on_tick)

return Task
