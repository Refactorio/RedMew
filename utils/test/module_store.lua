local Public = {}

local function new_module(module_name)
    return {
        id = nil,
        name = module_name,
        parent = nil,
        children = {},
        startup_func = nil,
        startup_steps = nil,
        startup_current_step = nil,
        startup_error = nil,
        teardown_func = nil,
        teardown_steps = nil,
        teardown_current_step = nil,
        teardown_error = nil,
        test_funcs = {},
        tests = nil,
        is_open = false,
        depth = nil,
        count = nil,
        passed = nil
    }
end

local root_module = new_module(nil)
root_module.is_open = true
Public.root_module = root_module

local parent_module = nil

local function add_module(module_name, module_func, parent)
    local parent_children = parent.children
    local module = parent_children[module_name]

    if not module then
        module = new_module(module_name)
        parent_children[module_name] = module
        module.parent = parent_module
    end

    parent_module = module
    module_func()
end

local function no_op()
end

local function add_module_range(modules_names, module_func, parent)
    for i = 1, #modules_names - 1 do
        local name = modules_names[i]
        add_module(name, no_op, parent)
        parent = parent_module
    end

    add_module(modules_names[#modules_names], module_func, parent)
end

function Public.module(module_name, module_func)
    local module_name_type = type(module_name)
    if module_name_type ~= 'string' and module_name_type ~= 'table' then
        error('module_name must be of type string or array of strings.', 2)
    end

    if module_name_type == 'table' and #module_name == 0 then
        error('when module_name is array must be non empty.', 2)
    end

    if type(module_func) ~= 'function' then
        error('module_func must be of type function.', 2)
    end

    local old_parent = parent_module
    local parent = parent_module or root_module

    if module_name_type == 'string' then
        add_module(module_name, module_func, parent)
    else
        add_module_range(module_name, module_func, parent)
    end

    parent_module = old_parent
end

function Public.test(test_name, test_func)
    if not parent_module then
        error('test can not be declared outisde of a module.', 2)
    end

    if type(test_name) ~= 'string' then
        error('test_name must be of type string.', 2)
    end

    if type(test_func) ~= 'function' then
        error('test_func must be of type function.', 2)
    end

    local test_funcs = parent_module.test_funcs
    if test_funcs[test_name] then
        error(
            table.concat {
                "test '",
                test_name,
                "' already exists, can not have duplicate test names in the same module."
            },
            2
        )
    end

    test_funcs[test_name] = test_func
end

function Public.module_startup(startup_func)
    if type(startup_func) ~= 'function' then
        error('startup_func must be of type function.', 2)
    end

    if parent_module == nil then
        error('root module can not have startup_func.', 2)
    end

    if parent_module.startup_func ~= nil then
        error('startup_func can not be declared twice for the same module.', 2)
    end

    parent_module.startup_func = startup_func
end

function Public.module_teardown(teardown_func)
    if type(teardown_func) ~= 'function' then
        error('teardown_func must be of type function.', 2)
    end

    if parent_module == nil then
        error('root module can not have teardown_func.', 2)
    end

    if parent_module.teardown_func ~= nil then
        error('teardown_func can not be declared twice for the same module.', 2)
    end

    parent_module.teardown_func = teardown_func
end

return Public
