local Token = require 'utils.token'
local Task = require 'utils.task'
local ModuleStore = require 'utils.test.module_store'
local Steps = require 'utils.test.steps'

local pcall = pcall

local Public = {}

local function build_tests_inner(module, tests)
    for name, func in pairs(module.tests) do
        tests[#tests + 1] = {name = name, func = func, steps = Steps.new(), current_step = 0}
    end

    for _, child in pairs(module.children) do
        build_tests_inner(child, tests)
    end
end

local function build_tests(module)
    local tests = {}
    build_tests_inner(module, tests)
    return tests
end

local function print_error(test_name, error_message)
    game.print(table.concat {"Failed - '", test_name, "': ", tostring(error_message)}, {r = 1})
end

local function print_success(test_name)
    game.print(table.concat {"Passed - '", test_name, "'"}, {g = 1})
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
        return false
    end

    if current_step == #steps then
        print_success(test.name)
        return true
    end

    return nil
end

local function print_summary(count, fail_count)
    local pass_count = count - fail_count
    game.print(table.concat {pass_count, ' of ', count, ' tests passed.'})
end

local run_tests_token
local function run_tests(data)
    local index = data.index

    local test = data.tests[index]
    if test == nil then
        print_summary(data.count, data.fail_count)
        return
    end

    local success = run_test(test)

    if success == false then
        data.count = data.count + 1
        data.fail_count = data.fail_count + 1
        data.index = index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    if success == true then
        data.count = data.count + 1
        data.index = index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    local step_index = test.current_step + 1
    test.current_step = step_index
    local step = test.steps[step_index]
    Task.set_timeout_in_ticks(step.delay or 1, run_tests_token, data)
end

run_tests_token = Token.register(run_tests)

function Public.run(module)
    local tests = build_tests(module or ModuleStore.root_module)
    run_tests({tests = tests, index = 1, count = 0, fail_count = 0})
end

_G.run_tests = Public.run

return Public