local ModuleStore = require 'utils.test.module_store'
local Steps = require 'utils.test.steps'

local Public = {}

local is_init = false

local function init_inner(module, depth)
    module.depth = depth

    local count = 0

    local tests = {}
    for name, func in pairs(module.test_funcs) do
        count = count + 1
        tests[#tests + 1] = {
            name = name,
            func = func,
            steps = nil,
            current_step = nil,
            passed = nil,
            error = nil
        }
    end
    module.tests = tests

    for _, child in pairs(module.children) do
        count = count + init_inner(child, depth + 1)
    end

    module.count = count
    return count
end

function Public.init()
    if is_init then
        return
    end

    is_init = true
    init_inner(ModuleStore.root_module, 0)
end

function Public.get_root_modules()
    Public.init()
    return ModuleStore.root_module
end

local function prepare_test(test)
    test.steps = Steps.new()
    test.current_step = 0
    test.passed = nil
    test.error = nil
end

local function prepare_module(module, tests)
    module.passed = nil

    for _, test in pairs(module.tests) do
        prepare_test(test)
        tests[#tests + 1] = test
    end

    for _, child in pairs(module.children) do
        prepare_module(child, tests)
    end
end

function Public.build_test_for_run(test)
    Public.init()
    prepare_test(test)
    return test
end

function Public.build_module_for_run(module)
    Public.init()

    local tests = {}
    prepare_module(module, tests)
    return tests
end

return Public
