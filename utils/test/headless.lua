-- Headless test runs: the whole suite without a player, for a headless server (CI), with the
-- results written where the scripts in .github/scripts read them.
--
-- A run is headless when started with `/test-runner headless` (from the server console, or in
-- game to see what CI would run), or by itself when map_selection.lua sets _TESTS_HEADLESS before
-- the map, which the scripts do:
--     _DEBUG = true
--     _TESTS_HEADLESS = {speed = 100}
--     return require '<map>'
-- `speed` is the game speed the tests run at (optional): they count ticks, so the server runs
-- them as fast as it can, up to that many times the normal rate. The map seed is fixed by the
-- scripts on the command line (--map-gen-seed), which also fixes math.random and the seeds of
-- surfaces a map creates, so every run of a map is the same.
--
-- The tests get no player, so modules tagged 'skip-headless' (Declare.tags) are skipped. Each
-- result is logged as a TESTRESULT line as the test finishes, and when the run ends the results
-- are written to script-output/redmew-tests.json:
--     {passed = n, failed = n, skipped = n, tests = {{path, name, result, ticks, error}, ...}}
-- with result 'pass', 'fail' or 'skip'.
local Event = require 'utils.event'
local Runner = require 'utils.test.runner'
local ModuleStore = require 'utils.test.module_store'

local Public = {}

Public.results_file = 'redmew-tests.json'

local START_TICK = 300 -- after the map's own setup

local settings = rawget(_G, '_TESTS_HEADLESS')

local results

local function log_result(result)
    local line = 'TESTRESULT ' .. result.result:upper() .. ' ' .. result.path .. ' :: ' .. result.name
    if result.ticks then
        line = line .. ' (' .. result.ticks .. ' ticks)'
    end
    if result.error then
        line = line .. ' :: ' .. result.error
    end
    log(line)
end

local count_names = {pass = 'passed', fail = 'failed', skip = 'skipped'}

local function add_result(result)
    results.tests[#results.tests + 1] = result
    local count_name = count_names[result.result]
    results[count_name] = results[count_name] + 1
    log_result(result)
end

--- Adds what the runner doesn't report as it goes: the skipped tests, and startup and teardown
-- errors, which belong to a module rather than a test.
local function add_module_results(module, path)
    path = module.name and (path .. '/' .. module.name) or path
    for _, hook in pairs({'startup', 'teardown'}) do
        local error_message = module[hook .. '_error']
        if error_message then
            add_result({path = path, name = '(' .. hook .. ')', result = 'fail', error = tostring(error_message)})
        end
    end
    for _, test in pairs(module.tests or {}) do
        if test.skipped then
            add_result({path = path, name = test.name, result = 'skip', error = 'tagged ' .. test.skipped})
        end
    end
    for _, child in pairs(module.children) do
        add_module_results(child, path)
    end
end

local function finish()
    add_module_results(ModuleStore.root_module, '')
    log('TESTS DONE passed=' .. results.passed .. ' failed=' .. results.failed .. ' skipped=' .. results.skipped)
    helpers.write_file(Public.results_file, helpers.table_to_json(results))
    results = nil
end

--- Starts a headless run of every test, printing progress to `player` if given.
function Public.run(player)
    results = {passed = 0, failed = 0, skipped = 0, tests = {}}
    if settings and settings.speed then
        game.speed = settings.speed
    end
    Runner.run_module(nil, player, {headless = true})
end

Event.add(Runner.events.test_finished, function(event)
    if not (event.headless and results) then
        return
    end
    add_result({path = event.path, name = event.test_name, result = event.passed and 'pass' or 'fail', ticks = event.ticks, error = event.error})
end)

Event.add(Runner.events.tests_run_finished, function(event)
    if event.headless and results then
        finish()
    end
end)

if settings then
    Event.add(defines.events.on_tick, function(event)
        if event.tick == START_TICK then
            Public.run()
        end
    end)
end

return Public
