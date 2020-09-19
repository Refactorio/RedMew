local Token = require 'utils.token'
local Task = require 'utils.task'

local pcall = pcall

local Public = {}

local root_module = {name = nil, children = {}, tests = {}}
local parent_module = nil

local function add_module(module_name, module_func, parent)
    local parent_children = parent.children
    local module = parent_children[module_name]

    if not module then
        module = {name = module_name, children = {}, tests = {}}
        parent_children[module_name] = module
    end

    parent_module = module
    module_func()
end

function Public.module(module_name, module_func)
    if type(module_name) ~= 'string' then
        error('module_name must be of type string.')
    end

    if type(module_func) ~= 'function' then
        error('module_func must be of type function.')
    end

    local old_parent = parent_module
    local parent = parent_module or root_module

    add_module(module_name, module_func, parent)

    parent_module = old_parent
end

function Public.test(test_name, test_func)
    if not parent_module then
        error('test can not be declared outisde of a module.')
    end

    if type(test_name) ~= 'string' then
        error('test_name must be of type string.')
    end

    if type(test_func) ~= 'function' then
        error('test_func must be of type function.')
    end

    local tests = parent_module.tests
    if tests[test_name] then
        error(
            table.concat {
                "test '",
                test_name,
                "' already exists, can not have duplicate test names in the same module."
            }
        )
    end

    tests[test_name] = test_func
end

local Context = {}
Context.__index = Context

function Context.new()
    return setmetatable({_child = nil, _func = nil, _delay = nil}, Context)
end

function Context.next(self, func, delay)
    local context = Context.new()
    self._child = context
    self._func = func
    self._delay = delay
    return context
end

local function build_tests_inner(module, tests)
    for name, func in pairs(module.tests) do
        tests[#tests + 1] = {name = name, func = func, context = Context.new()}
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
    local success, return_value = pcall(test.func, test.context)

    if not success then
        print_error(test.name, return_value)
        return false
    end

    local next_func = test.context._func
    if not next_func then
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
    data.count = data.count + 1

    if success == false then
        data.fail_count = data.fail_count + 1
        data.index = index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    if success == true then
        data.index = index + 1
        Task.set_timeout_in_ticks(1, run_tests_token, data)
        return
    end

    local context = test.context
    test.func = context._func
    test.context = context._child
    Task.set_timeout_in_ticks(context._delay or 1, run_tests_token, data)
end

run_tests_token = Token.register(run_tests)

function Public.run(module)
    local tests = build_tests(module or root_module)
    run_tests({tests = tests, index = 1, count = 0, fail_count = 0})
end

Public.root_module = root_module
_G.run_tests = Public.run

return Public
