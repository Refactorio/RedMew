-- Tests for how the test runner treats a module whose startup or teardown fails. Each runs a
-- small module of its own through the runner, alongside the run it is part of; the modules
-- aren't declared, so /test-runner and headless runs never run them by themselves, and their
-- run reports to no player and isn't headless, so nothing reports their results.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local Runner = require 'utils.test.runner'

local RUN_TICKS = 300

local function new_module(name, parent)
    local module = {name = name, parent = parent, children = {}, tests = {}, tags = {}, all_tags = {}}
    if parent then
        parent.children[name] = module
    end
    return module
end

-- `ran` records which of the module's functions ran, by name
local function add_test(module, name, ran)
    module.tests[#module.tests + 1] = {
        name = name,
        module = module,
        func = function()
            ran[name] = true
        end
    }
end

local function all_tests(module, list)
    list = list or {}
    for _, test in pairs(module.tests) do
        list[#list + 1] = test
    end
    for _, child in pairs(module.children) do
        all_tests(child, list)
    end
    return list
end

--- Runs `module` and calls `after` when every test in it has a result.
local function run(context, module, after)
    Runner.run_module(module, nil, {})
    Helper.wait_until(context, RUN_TICKS, function()
        for _, test in pairs(all_tests(module)) do
            if test.passed == nil then
                return false
            end
        end
        return true
    end, function(finished)
        Assert.is_true(finished, 'the run did not finish in ' .. RUN_TICKS .. ' ticks')
        after()
    end)
end

local function assert_failed(test, error_start)
    Assert.equal(false, test.passed, test.name .. ' passed')
    Assert.is_true(tostring(test.error):sub(1, #error_start) == error_start,
        test.name .. ' failed with "' .. tostring(test.error) .. '", not "' .. error_start .. '..."')
end

Declare.module({'utils', 'test runner'}, function()
    Declare.test('when a startup fails, the tests below it fail without running', function(context)
        -- Arrange: a module whose startup fails, with a test, and a child module with its own
        -- startup, teardown and test; and around it, a parent whose hooks work
        local ran = {}
        local parent = new_module('parent')
        parent.startup_func = function()
            ran.parent_startup = true
        end
        parent.teardown_func = function()
            ran.parent_teardown = true
        end
        add_test(parent, 'parent test', ran)

        local broken = new_module('broken', parent)
        broken.startup_func = function()
            error('the startup broke', 0)
        end
        broken.teardown_func = function()
            ran.broken_teardown = true
        end
        add_test(broken, 'broken test', ran)

        local child = new_module('child', broken)
        child.startup_func = function()
            ran.child_startup = true
        end
        child.teardown_func = function()
            ran.child_teardown = true
        end
        add_test(child, 'child test', ran)

        -- Act
        run(context, parent, function()
            -- Assert
            Assert.equal(true, parent.tests[1].passed, 'the parent test passed')
            Assert.equal('the startup broke', broken.startup_error, 'the startup error recorded on its module')
            for _, test in pairs({broken.tests[1], child.tests[1]}) do
                assert_failed(test, 'startup of /parent/broken failed: the startup broke')
                Assert.is_nil(ran[test.name], test.name .. ' ran')
            end
            Assert.is_nil(ran.child_startup, 'the child module\'s startup ran')
            Assert.is_nil(ran.child_teardown, 'the child module\'s teardown ran')
            Assert.is_nil(ran.broken_teardown, 'the teardown of the module whose startup failed ran')
            Assert.is_true(ran.parent_startup and ran.parent_teardown, 'the parent\'s startup or teardown did not run')
        end)
    end)

    Declare.test('when a teardown fails, the tests below it that passed fail', function(context)
        -- Arrange: a module whose teardown fails, with a test and a child module with a test
        local ran = {}
        local broken = new_module('broken teardown')
        broken.teardown_func = function()
            error('the teardown broke', 0)
        end
        add_test(broken, 'test', ran)
        local child = new_module('child', broken)
        add_test(child, 'child test', ran)

        -- Act
        run(context, broken, function()
            -- Assert: both ran, then failed with the teardown
            for _, test in pairs({broken.tests[1], child.tests[1]}) do
                Assert.is_true(ran[test.name], test.name .. ' did not run')
                assert_failed(test, 'teardown of /broken teardown failed: the teardown broke')
            end
        end)
    end)

    Declare.test('a startup that failed before passes when run again', function(context)
        -- Arrange: a startup that fails on its first run only
        local ran = {}
        local runs = 0
        local module = new_module('flaky startup')
        module.startup_func = function()
            runs = runs + 1
            if runs == 1 then
                error('the first startup broke', 0)
            end
        end
        add_test(module, 'test', ran)

        run(context, module, function()
            assert_failed(module.tests[1], 'startup of /flaky startup failed')

            -- Act
            module.tests[1].passed = nil
            run(context, module, function()
                -- Assert
                Assert.equal(true, module.tests[1].passed, 'the test passed on the second run')
                Assert.is_nil(module.startup_error, 'the first run\'s startup error')
            end)
        end)
    end)
end)
