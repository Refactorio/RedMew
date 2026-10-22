local Token = require 'utils.token'
local Task = require 'utils.task'
local ModuleStore = require 'utils.test.module_store'
local Builder = require 'utils.test.builder'
local Event = require 'utils.event'
local Global = require 'utils.global'

local xpcall = xpcall

--- Error handler for xpcall that gives an error's location its full path. Lua shortens the file
-- in it to the last 60 or so characters, '...vel__/map_gen/maps/danger_ores/modules/citadel_tests.lua:7:'
-- say, which this turns back into 'map_gen/maps/danger_ores/modules/citadel_tests.lua:7:'.
local function error_handler(message)
    if type(message) ~= 'string' then
        return message
    end

    -- The location is that of one of the functions on the stack: the one that failed, or the
    -- caller of error() at its level (Assert's callers, say).
    for level = 2, 8 do
        local info = debug.getinfo(level, 'Sl')
        if info == nil then
            break
        end

        if info.currentline > 0 then
            local location = info.short_src .. ':' .. info.currentline .. ':'
            if message:sub(1, #location) == location then
                local path = info.source:match('__level__/(.+)$') or info.short_src
                return path .. ':' .. info.currentline .. ':' .. message:sub(#location + 1)
            end
        end
    end

    return message
end

local Public = {}

Public.events = {
    -- raised when a run ends, with `player` (who started it, if anyone) and `headless`
    tests_run_finished = Event.generate_event_name('test_run_finished'),
    -- raised as each test finishes, with `path` (its module's, '/map_gen/maze' say), `test_name`,
    -- `passed`, `error`, `ticks` (how long it took), `order` (how many tests have finished, this
    -- one included) and `headless`
    test_finished = Event.generate_event_name('test_finished')
}

-- Tags whose tests a headless run skips: they need a player.
Public.skip_headless_tag = 'skip-headless'

local run_runnables_token

-- The runs in progress, by id. A run waits between steps on the task queue, which is saved, so
-- only its id goes there: a run holds the tests, whose functions can't be saved. Loading a save
-- leaves this empty, so a run that was in progress then stops. The count is saved, so a run
-- started after loading never takes the id of one still on the queue.
local runs = {}
local counts = {runs = 0}

Global.register(counts, function(tbl)
    counts = tbl
end)

local function schedule(data, ticks)
    Task.set_timeout_in_ticks(ticks, run_runnables_token, {run_id = data.id})
end

-- Prints to the player who started the run. A run started without one (a headless run from the
-- server) prints nothing: its results are in the test tree and the test_finished events.
local function print_to(player, message, options)
    if player then
        player.print(message, options)
    end
end

local function print_summary(data)
    local pass_count = data.count - data.fail_count
    print_to(data.player, table.concat {pass_count, ' of ', data.count, ' tests passed.'})
end

local function mark_module_for_passed(module)
    local any_fails = false
    local all_ran = true
    local pass_count = 0
    local ran_count = 0

    for _, child in pairs(module.children) do
        local module_any_fails, module_all_ran, module_pass_count, module_ran_count = mark_module_for_passed(child)
        any_fails = any_fails or module_any_fails
        all_ran = all_ran and module_all_ran
        pass_count = pass_count + module_pass_count
        ran_count = ran_count + module_ran_count
    end

    for _, test in pairs(module.tests) do
        any_fails = any_fails or (test.passed == false)
        all_ran = all_ran and (test.passed ~= nil or test.skipped ~= nil)
        if test.passed == true then
            pass_count = pass_count + 1
        end
        if test.passed ~= nil then
            ran_count = ran_count + 1
        end
    end

    if any_fails then
        module.passed = false
    elseif all_ran then
        module.passed = true
    else
        module.passed = nil
    end

    -- Only show a pass count for modules that have results.
    module.pass_count = ran_count > 0 and pass_count or nil

    return any_fails, all_ran, pass_count, ran_count
end

local function mark_modules_for_passed()
    mark_module_for_passed(ModuleStore.root_module)
end

local function finish_test_run(data)
    runs[data.id] = nil
    print_summary(data)
    mark_modules_for_passed()
    script.raise_event(Public.events.tests_run_finished, {player = data.player, headless = data.headless})
end

local function print_error(player, test_name, error_message)
    print_to(player, table.concat {"Failed - '", test_name, "': ", tostring(error_message)}, {color = {r = 1}})
end

local function print_success(player, test_name)
    print_to(player, table.concat {"Passed - '", test_name, "'"}, {color = {g = 1}})
end

local function print_hook_error(player, hook)
    print_to(player, table.concat {'Failed ', hook.name, " hook -':", tostring(hook.error)}, {color = {r = 1}})
end

local function print_teardown_error(player, name, error_message)
    print_to(player, table.concat {'Failed ', name, " teardown -':", error_message}, {color = {r = 1}})
end

--- A module's path, '/map_gen/maze' say.
local function get_module_path(module)
    local names = {}
    while module and module.name do
        table.insert(names, 1, module.name)
        module = module.parent
    end
    return '/' .. table.concat(names, '/')
end

local function record_hook_error_in_module(hook)
    if hook.name == 'startup' then
        hook.module.startup_error = hook.error
    elseif hook.name == 'teardown' then
        hook.module.teardown_error = hook.error
    end
end

local function do_termination(data)
    if not data.stop_on_first_error then
        return false
    end

    print_to(data.player, 'Test run canceled due to stop on first error policy.')
    finish_test_run(data)
    data.index = -1
    return true
end

local function run_teardown(teardown, errors)
    local success, error_message = xpcall(teardown, error_handler)

    if not success then
        errors[#errors + 1] = error_message
    end
end

local function do_teardowns(context, name, player)
    local teardowns = context._teardowns
    local errors = {}

    for i = 1, #teardowns do
        run_teardown(teardowns[i], errors)
    end

    if #errors > 0 then
        local error_message = table.concat(errors, '\n')
        print_teardown_error(player, name, error_message)

        return error_message
    end

    return nil
end

local function run_hook(hook, player)
    local context = hook.context
    local steps = context._steps
    local current_step = hook.current_step

    local func
    if current_step == 0 then
        func = hook.func
    else
        func = steps[current_step].func
    end

    local success, return_value = xpcall(func, error_handler, context)

    if not success then
        hook.error = return_value
        print_hook_error(player, hook)
        record_hook_error_in_module(hook)
        do_teardowns(context, hook.name, player)
        return false
    end

    if current_step ~= #steps then
        return nil
    end

    local error_message = do_teardowns(context, hook.name, player)
    if error_message then
        hook.error = error_message
        record_hook_error_in_module(hook)
        return false
    end

    return true
end

local function do_hook(hook, data)
    local hook_success = run_hook(hook, data.player)

    if hook_success == false and do_termination(data) then
        return
    end

    if hook_success == nil then
        local step_index = hook.current_step + 1
        local step = hook.context._steps[step_index]
        hook.current_step = step_index
        schedule(data, step.delay or 1)
        return
    end

    data.index = data.index + 1
    schedule(data, 1)
    return
end

local function run_test(test, player)
    local context = test.context
    local steps = context._steps
    local current_step = test.current_step

    local func
    if current_step == 0 then
        test.started_tick = game.tick
        func = test.func
    else
        func = steps[current_step].func
    end

    local success, return_value = xpcall(func, error_handler, context)

    if not success then
        print_error(player, test.name, return_value)
        test.passed = false
        test.error = return_value
        do_teardowns(context, test.name, player)
        return false
    end

    if current_step ~= #steps then
        return nil
    end

    local error_message = do_teardowns(context, test.name, player)
    if error_message then
        test.passed = false
        test.error = error_message
        return false
    end

    print_success(player, test.name)
    test.passed = true
    return true
end

local function do_test(test, data)
    local success = run_test(test, data.player)

    if success ~= nil then
        test.ticks = game.tick - test.started_tick
        script.raise_event(Public.events.test_finished, {
            path = get_module_path(test.module),
            test_name = test.name, -- `name` is the event's own
            passed = success,
            error = test.error and tostring(test.error) or nil,
            ticks = test.ticks,
            order = data.count + 1,
            headless = data.headless
        })
    end

    if success == false then
        data.count = data.count + 1
        data.fail_count = data.fail_count + 1

        if do_termination(data) then
            return
        end

        data.index = data.index + 1
        schedule(data, 1)
        return
    end

    if success == true then
        data.count = data.count + 1
        data.index = data.index + 1
        schedule(data, 1)
        return
    end

    local step_index = test.current_step + 1
    test.current_step = step_index
    local step = test.context._steps[step_index]
    schedule(data, step.delay or 1)
end

local function run_runnables(params)
    local data = runs[params.run_id]
    if not data then
        return
    end

    local index = data.index
    local runnable = data.runnables[index]

    if runnable == nil then
        finish_test_run(data)
        return
    end

    if runnable.is_hook then
        do_hook(runnable, data)
    else
        do_test(runnable, data)
    end
end

run_runnables_token = Token.register(run_runnables)

local function validate_options(options)
    options = options or {}
    options.stop_on_first_error = options.stop_on_first_error or false
    options.headless = options.headless or false
    return options
end

local function run(runnables, player, options)
    local id = counts.runs + 1
    counts.runs = id
    runs[id] = {
        id = id,
        runnables = runnables,
        player = player,
        index = 1,
        count = 0,
        fail_count = 0,
        stop_on_first_error = options.stop_on_first_error,
        headless = options.headless
    }
    run_runnables({run_id = id})
end

--- Runs the tests in `module` (all of them if nil), printing the results to `player`.
-- options.headless runs them the way a headless server (CI) does: the tests get no player, so
-- the ones tagged 'skip-headless' are skipped. `player` may then be nil.
function Public.run_module(module, player, options)
    options = validate_options(options)
    local skip_tags = options.headless and {[Public.skip_headless_tag] = true} or nil
    local test_player = (not options.headless) and player or nil
    local runnables = Builder.build_module_for_run(module or ModuleStore.root_module, test_player, skip_tags)
    run(runnables, player, options)
end

function Public.run_test(test, player, options)
    options = validate_options(options)
    local runnables = Builder.build_test_for_run(test, player)
    run(runnables, player, options)
end

return Public
