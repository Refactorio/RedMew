local ModuleStore = require 'utils.test.module_store'
local Context = require 'utils.test.context'

local Public = {}

local is_init = false
local id_count = 0
-- every module and test by its id, so what goes in storage (the viewer's state, a run waiting
-- on the task queue) can refer to them by id: they hold functions, which can't be saved. The
-- tests are declared as the scenario loads, so the ids are the same after loading a save.
local by_id = {}

local function get_id()
    id_count = id_count + 1
    return id_count
end

local function init_inner(module, depth, inherited_tags)
    module.id = get_id()
    module.depth = depth
    by_id[module.id] = module

    -- a module has its own tags and those of every module above it
    local all_tags = {}
    for tag in pairs(inherited_tags) do
        all_tags[tag] = true
    end
    for tag in pairs(module.tags) do
        all_tags[tag] = true
    end
    module.all_tags = all_tags

    local count = 0

    local tests = {}
    for name, func in pairs(module.test_funcs) do
        count = count + 1
        local id = get_id()
        tests[#tests + 1] = {
            id = id,
            name = name,
            module = module,
            func = func,
            context = nil,
            current_step = nil,
            passed = nil,
            error = nil,
            skipped = nil
        }
        by_id[id] = tests[#tests]
    end
    module.tests = tests

    for _, child in pairs(module.children) do
        count = count + init_inner(child, depth + 1, all_tags)
    end

    module.count = count
    return count
end

function Public.init()
    if is_init then
        return
    end

    is_init = true
    init_inner(ModuleStore.root_module, 0, {})
end

function Public.get_root_modules()
    Public.init()
    return ModuleStore.root_module
end

--- The module or test with `id`, or nil.
function Public.get_by_id(id)
    Public.init()
    return by_id[id]
end

local function prepare_pre_module_hooks(module, runnables, player)
    local startup_func = module.startup_func
    module.startup_error = nil
    if startup_func then
        runnables[#runnables + 1] = {
            is_hook = true,
            name = 'startup',
            module = module,
            func = startup_func,
            context = Context.new(player),
            current_step = 0,
            error = nil
        }
    end
end

local function build_pre_module_hooks(module, runnables, player)
    if module == nil then
        return
    end

    build_pre_module_hooks(module.parent, runnables, player)
    prepare_pre_module_hooks(module, runnables, player)
end

local function prepare_post_module_hooks(module, runnables, player)
    local teardown_func = module.teardown_func
    module.teardown_error = nil
    if teardown_func then
        runnables[#runnables + 1] = {
            is_hook = true,
            name = 'teardown',
            module = module,
            func = teardown_func,
            context = Context.new(player),
            current_step = 0,
            error = nil
        }
    end
end

local function build_post_module_hooks(module, runnables, player)
    if module == nil then
        return
    end

    prepare_post_module_hooks(module, runnables, player)
    build_post_module_hooks(module.parent, runnables, player)
end

local function prepare_test(test, player)
    test.context = Context.new(player)
    test.current_step = 0
    test.passed = nil
    test.error = nil
    test.skipped = nil
    return test
end

--- The first of `skip_tags` the module has, if any.
local function get_skip_tag(module, skip_tags)
    if not skip_tags then
        return nil
    end
    for tag in pairs(module.all_tags) do
        if skip_tags[tag] then
            return tag
        end
    end
    return nil
end

--- Marks every test in the module and below it as skipped for `tag`, so none of them, nor the
-- modules' startup and teardown, are run.
local function skip_module(module, tag)
    module.passed = nil
    module.skipped = tag
    for _, test in pairs(module.tests) do
        test.passed = nil
        test.error = nil
        test.skipped = tag
    end
    for _, child in pairs(module.children) do
        skip_module(child, tag)
    end
end

local function prepare_module(module, runnables, player, skip_tags)
    local skip_tag = get_skip_tag(module, skip_tags)
    if skip_tag then
        skip_module(module, skip_tag)
        return
    end

    module.passed = nil
    module.skipped = nil
    prepare_pre_module_hooks(module, runnables, player)

    for _, test in pairs(module.tests) do
        prepare_test(test, player)
        runnables[#runnables + 1] = test
    end

    for _, child in pairs(module.children) do
        prepare_module(child, runnables, player, skip_tags)
    end

    prepare_post_module_hooks(module, runnables, player)
end

function Public.build_test_for_run(test, player)
    Public.init()

    local runnables = {}

    build_pre_module_hooks(test.module, runnables, player)
    runnables[#runnables + 1] = prepare_test(test, player)
    build_post_module_hooks(test.module, runnables, player)

    return runnables
end

--- @param skip_tags <table|nil> set of tags (tag => true) whose tests are skipped
function Public.build_module_for_run(module, player, skip_tags)
    Public.init()

    local runnables = {}

    build_pre_module_hooks(module.parent, runnables, player)
    prepare_module(module, runnables, player, skip_tags)
    build_post_module_hooks(module.parent, runnables, player)

    return runnables
end

return Public
