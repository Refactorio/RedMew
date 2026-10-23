-- Tests for how the test runner treats a module whose startup or teardown fails, and for
-- context:wait_until. Each runs a small module of its own through the runner, alongside the run it is part of; the modules
-- aren't declared, so /test-runner and headless runs never run them by themselves, and their
-- run reports to no player and isn't headless, so nothing reports their results.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Runner = require 'utils.test.runner'

local RUN_TICKS = 300

local function new_module(name, parent)
    local module = {name = name, parent = parent, children = {}, tests = {}, tags = {}, all_tags = {}}
    if parent then
        parent.children[name] = module
    end
    return module
end

local function add_test_func(module, name, func)
    module.tests[#module.tests + 1] = {name = name, module = module, func = func}
end

-- `ran` records which of the module's functions ran, by name
local function add_test(module, name, ran)
    add_test_func(module, name, function()
        ran[name] = true
    end)
end

--- Runs `module`; the returned context carries on once the run has finished, teardowns and all.
local function run(context, module)
    local id = Runner.run_module(module, nil, {})
    return context:wait_until(RUN_TICKS, function()
        return not Runner.is_running(id)
    end, 'the run did not finish')
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
        run(context, parent):next(function()
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
        run(context, broken):next(function()
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

        local second_run
        run(context, module):next(function()
            assert_failed(module.tests[1], 'startup of /flaky startup failed')

            -- Act
            second_run = Runner.run_module(module, nil, {})
        end):wait_until(RUN_TICKS, function()
            return not Runner.is_running(second_run)
        end, 'the second run did not finish'):next(function()
            -- Assert
            Assert.equal(true, module.tests[1].passed, 'the test passed on the second run')
            Assert.is_nil(module.startup_error, 'the first run\'s startup error')
        end)
    end)

    Declare.test('wait_until carries on the tick after its condition holds', function(context)
        -- Arrange: a test that waits 5 ticks, then notes when its next step ran
        local ran = {}
        local module = new_module('wait until')
        add_test_func(module, 'test', function(inner)
            ran.held = game.tick + 5
            inner:wait_until(60, function()
                return game.tick >= ran.held
            end):next(function()
                ran.next_step = game.tick
            end)
        end)

        -- Act
        run(context, module):next(function()
            -- Assert: checked every tick, so the next step runs the tick after
            Assert.equal(true, module.tests[1].passed, 'the waiting test passed')
            Assert.equal(ran.held + 1, ran.next_step, 'tick the step after wait_until ran')
        end)
    end)

    Declare.test('wait_until fails with its message when its condition never holds', function(context)
        -- Arrange
        local ran = {}
        local module = new_module('wait until never')
        add_test_func(module, 'test', function(inner)
            inner:wait_until(5, function()
                return false
            end, function()
                return 'it never held'
            end):next(function()
                ran.next_step = true
            end)
        end)

        -- Act
        run(context, module):next(function()
            -- Assert
            assert_failed(module.tests[1], 'it never held (waited 5 ticks)')
            Assert.is_nil(ran.next_step, 'the step after the failed wait_until ran')
        end)
    end)

    Declare.test('wait_until works in a module startup', function(context)
        -- Arrange: a startup that waits a few ticks before it's ready
        local ran = {}
        local module = new_module('startup wait until')
        module.startup_func = function(inner)
            local ready = game.tick + 3
            inner:wait_until(30, function()
                return game.tick >= ready
            end):next(function()
                ran.ready = true
            end)
        end
        add_test_func(module, 'test', function()
            ran.test_saw_ready = ran.ready
        end)

        -- Act
        run(context, module):next(function()
            -- Assert
            Assert.equal(true, module.tests[1].passed, 'the test passed')
            Assert.equal(true, ran.test_saw_ready, 'the test ran before the startup was ready')
        end)
    end)
end)
