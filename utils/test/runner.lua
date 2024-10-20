local Token = require 'utils.token'
local Task = require 'utils.task'
local ModuleStore = require 'utils.test.module_store'
local Builder = require 'utils.test.builder'
local Event = require 'utils.event'

local pcall = pcall

local Public = {}

Public.events = {tests_run_finished = Event.generate_event_name('test_run_finished')}

local run_runnables_token

local function print_summary(data)
    local pass_count = data.count - data.fail_count
    data.player.print(table.concat {pass_count, ' of ', data.count, ' tests passed.'})
end

local function mark_module_for_passed(module)
    local any_fails = false
    local all_ran = true

    for _, child in pairs(module.children) do
        local module_any_fails, module_all_ran = mark_module_for_passed(child)
        any_fails = any_fails or module_any_fails
        all_ran = all_ran and module_all_ran
    end

    for _, test in pairs(module.tests) do
        any_fails = any_fails or (test.passed == false)
        all_ran = all_ran and (test.passed ~= nil)
    end

    if any_fails then
        module.passed = false
    elseif all_ran then
        module.passed = true
    else
        module.passed = nil
    end

    return any_fails, all_ran
end

local function mark_modules_for_passed()
    mark_module_for_passed(ModuleStore.root_module)
end

local function finish_test_run(data)
    print_summary(data)
    mark_modules_for_passed()
    script.raise_event(Public.events.tests_run_finished, {player = data.player})
end

local function print_error(player, test_name, error_message)
    player.print(table.concat {"Failed - '", test_name, "': ", tostring(error_message)}, {color = {r = 1}})
end

local function print_success(player, test_name)
    player.print(table.concat {"Passed - '", test_name, "'"}, {color = {g = 1}})
end

local function print_hook_error(hook)
    hook.context.player.print(table.concat {'Failed ', hook.name, " hook -':", tostring(hook.error)}, {color = {r = 1}})
end

local function print_teardown_error(context, name, error_message)
    context.player.print(table.concat {'Failed ', name, " teardown -':", error_message}, {color = {r = 1}})
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

    data.player.print('Test run canceled due to stop on first error policy.')
    finish_test_run(data)
    data.index = -1
    return true
end

local function run_teardown(teardown, errors)
    local success, error_message = pcall(teardown)

    if not success then
        errors[#errors + 1] = error_message
    end
end

local function do_teardowns(context, name)
    local teardowns = context._teardowns
    local errors = {}

    for i = 1, #teardowns do
        run_teardown(teardowns[i], errors)
    end

    if #errors > 0 then
        local error_message = table.concat(errors, '\n')
        print_teardown_error(context, name, error_message)

        return error_message
    end

    return nil
end

local function run_hook(hook)
    local context = hook.context
    local steps = context._steps
    local current_step = hook.current_step

    local func
    if current_step == 0 then
        func = hook.func
    else
        func = steps[current_step].func
    end

    local success, return_value = pcall(func, context)

    if not success then
        hook.error = return_value
        print_hook_error(hook)
        record_hook_error_in_module(hook)
        do_teardowns(context, hook.name)
        return false
    end

    if current_step ~= #steps then
        return nil
    end

    local error_message = do_teardowns(context, hook.name)
    if error_message then
        hook.error = error_message
        record_hook_error_in_module(hook)
        return false
    end

    return true
end

local function do_hook(hook, data)
    local hook_success = run_hook(hook)

    if hook_success == false and do_termination(data) then
        return
    end

    if hook_success == nil then
        local step_index = hook.current_step + 1
        local step = hook.context._steps[step_index]
        hook.current_step = step_index
        Task.set_timeout_in_ticks(step.delay or 1, run_runnables_token, data)
        return
    end

    data.index = data.index + 1
    Task.set_timeout_in_ticks(1, run_runnables_token, data)
    return
end

local function run_test(test)
    local context = test.context
    local steps = context._steps
    local current_step = test.current_step

    local func
    if current_step == 0 then
        func = test.func
    else
        func = steps[current_step].func
    end

    local success, return_value = pcall(func, context)

    if not success then
        print_error(context.player, test.name, return_value)
        test.passed = false
        test.error = return_value
        do_teardowns(context, test.name)
        return false
    end

    if current_step ~= #steps then
        return nil
    end

    local error_message = do_teardowns(context, test.name)
    if error_message then
        test.passed = false
        test.error = error_message
        return false
    end

    print_success(context.player, test.name)
    test.passed = true
    return true
end

local function do_test(test, data)
    local success = run_test(test)

    if success == false then
        data.count = data.count + 1
        data.fail_count = data.fail_count + 1

        if do_termination(data) then
            return
        end

        data.index = data.index + 1
        Task.set_timeout_in_ticks(1, run_runnables_token, data)
        return
    end

    if success == true then
        data.count = data.count + 1
        data.index = data.index + 1
        Task.set_timeout_in_ticks(1, run_runnables_token, data)
        return
    end

    local step_index = test.current_step + 1
    test.current_step = step_index
    local step = test.context._steps[step_index]
    Task.set_timeout_in_ticks(step.delay or 1, run_runnables_token, data)
end

local function run_runnables(data)
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
    return options
end

local function run(runnables, player, options)
    options = validate_options(options)
    run_runnables({
        runnables = runnables,
        player = player,
        index = 1,
        count = 0,
        fail_count = 0,
        stop_on_first_error = options.stop_on_first_error
    })
end

function Public.run_module(module, player, options)
    local runnables = Builder.build_module_for_run(module or ModuleStore.root_module, player)
    run(runnables, player, options)
end

function Public.run_test(test, player, options)
    local runnables = Builder.build_test_for_run(test, player)
    run(runnables, player, options)
end

return Public
