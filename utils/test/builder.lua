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
            module = module,
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

local function prepare_pre_module_hooks(module, runnables)
    local startup_func = module.startup_func
    if startup_func then
        runnables[#runnables + 1] = {
            is_hook = true,
            name = 'startup',
            module = module,
            func = startup_func,
            steps = Steps.new(),
            current_step = 0,
            error = nil
        }
    end
end

local function build_pre_module_hooks(module, runnables)
    if module == nil then
        return
    end

    build_pre_module_hooks(module.parent, runnables)
    prepare_pre_module_hooks(module, runnables)
end

local function prepare_post_module_hooks(module, runnables)
    local teardown_func = module.teardown_func
    if teardown_func then
        runnables[#runnables + 1] = {
            is_hook = true,
            name = 'teardown',
            module = module,
            func = teardown_func,
            steps = Steps.new(),
            current_step = 0,
            error = nil
        }
    end
end

local function build_post_module_hooks(module, runnables)
    if module == nil then
        return
    end

    prepare_post_module_hooks(module, runnables)
    build_post_module_hooks(module.parent, runnables)
end

local function prepare_test(test)
    test.steps = Steps.new()
    test.current_step = 0
    test.passed = nil
    test.error = nil
    return test
end

local function prepare_module(module, runnables)
    module.passed = nil
    prepare_pre_module_hooks(module, runnables)

    for _, test in pairs(module.tests) do
        prepare_test(test)
        runnables[#runnables + 1] = test
    end

    for _, child in pairs(module.children) do
        prepare_module(child, runnables)
    end

    prepare_post_module_hooks(module, runnables)
end

function Public.build_test_for_run(test)
    Public.init()

    local runnables = {}

    build_pre_module_hooks(test.module, runnables)
    runnables[#runnables + 1] = prepare_test(test)
    build_post_module_hooks(test.module, runnables)

    return runnables
end

function Public.build_module_for_run(module)
    Public.init()

    local runnables = {}

    build_pre_module_hooks(module.parent, runnables)
    prepare_module(module, runnables)
    build_post_module_hooks(module.parent, runnables)

    return runnables
end

return Public
