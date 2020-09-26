local Token = require 'utils.token'
local Task = require 'utils.task'
local ModuleStore = require 'utils.test.module_store'
local Builder = require 'utils.test.builder'
local Event = require 'utils.event'

local pcall = pcall

local Public = {}

Public.events = {
    tests_run_finished = Event.generate_event_name('test_run_finished')
}

local run_tests_token

local function print_summary(count, fail_count)
    local pass_count = count - fail_count
    game.print(table.concat {pass_count, ' of ', count, ' tests passed.'})
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
    print_summary(data.count, data.fail_count)
    mark_modules_for_passed()
    script.raise_event(Public.events.tests_run_finished, {})
end

local function print_error(test_name, error_message)
    game.print(table.concat {"Failed - '", test_name, "': ", tostring(error_message)}, {r = 1})
end

local function print_success(test_name)
    game.print(table.concat {"Passed - '", test_name, "'"}, {g = 1})
end

local function print_hook_error(hook)
    game.print(table.concat {'Failed ', hook.name, " hook -':", tostring(hook.error)}, {r = 1})
end

local function record_hook_error_in_module(hook)
    if hook.name == 'startup' then
        hook.module.startup_error = hook.error
    elseif hook.name == 'teardown' then
        hook.module.teardown_error = hook.error
    end
end

local function run_hook(hook)
    local steps = hook.steps
    local current_step = hook.current_step
    local func
    if current_step == 0 then
        func = hook.func
    else
        func = steps[current_step].func
    end
    local success, return_value = pcall(func, steps)

    if not success then
        hook.error = return_value
        print_hook_error(hook)
        record_hook_error_in_module(hook)
        return false
    end

    if current_step == #steps then
        return true
    end

    return nil
end

local function do_hook(hook, data)
    local hook_success = run_hook(hook)
    if hook_success == nil then
        local step_index = hook.current_step + 1
        local step = hook.steps[step_index]
        hook.current_step = step_index
        Task.set_timeout_in_ticks(step.delay or 1, run_tests_token, data)
        return
    end

    data.index = data.index + 1
    Task.set_timeout_in_ticks(1, run_tests_token, data)
    return
end

local function run_test(test)
    local steps = test.steps
    local current_step = test.current_step
    local func
    if current_step == 0 then
        func = test.func
    else
        func = steps[current_step].func
    end
    local success, return_value = pcall(func, steps)

    if not success then
        print_error(test.name, return_value)
        test.passed = false
        test.error = return_value
        return false
    end

    if current_step == #steps then
        print_success(test.name)
        test.passed = true
        return true
    end

    return nil
end

local function do_test(test, data)
    local success = run_test(test)

    if success == false then
        data.count = data.count + 1
        data.fail_count = data.fail_count + 1
        data.index = data.index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    if success == true then
        data.count = data.count + 1
        data.index = data.index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    local step_index = test.current_step + 1
    test.current_step = step_index
    local step = test.steps[step_index]
    Task.set_timeout_in_ticks(step.delay or 1, run_tests_token, data)
end

local function run_tests(data)
    local index = data.index
    local runnable = data.runnables[index]

    if runnable == nil then
        finish_test_run(data)
        return
    end

    if runnable.is_hook then
        do_hook(runnable, data)
        return
    end

    do_test(runnable, data)
end

run_tests_token = Token.register(run_tests)

local function run(runnables)
    run_tests({runnables = runnables, index = 1, count = 0, fail_count = 0})
end

function Public.run_module(module)
    local runnables = Builder.build_module_for_run(module or ModuleStore.root_module)
    run(runnables)
end

function Public.run_test(test)
    local runnables = Builder.build_test_for_run(test)
    run(runnables)
end

return Public
