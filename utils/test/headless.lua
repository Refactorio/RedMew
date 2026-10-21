-- Runs the in-game test suite without a player, for a headless server (CI). Load it from
-- map_selection.lua before the map, with _DEBUG set:
--     _DEBUG = true
--     require 'utils.test.headless'
--     return require '<map>'
-- .github/scripts/run-ingame-tests.sh does this in a scratch copy of the scenario.
--
-- A headless server has no players, so the player force stands in for the player the runner
-- prints to: it has print, and unlike a plain table it can be passed through the runner's
-- finished event. Tests that need a real player (a character, a GUI) can't run this way, so
-- only the map_gen tests are run, minus the modules in NEEDS_PLAYER, which are logged as
-- skipped.
--
-- Results go to the log: a TESTRESULT line per test, with the game ticks it took and its place in
-- the run (#n), then TESTS DONE with the counts. A TESTMARK n line is logged as the nth test
-- finishes (TESTMARK 0 as they start), so the log's timestamps give how long each took in real
-- time; .github/scripts/run-ingame-tests.sh puts that on the result lines.
--
-- The tests count game ticks, not seconds, so they run at the game speed in the global
-- _HEADLESS_GAME_SPEED if map_selection.lua sets one: the server then runs ticks as fast as it
-- can, up to that many times the normal rate, instead of idling between them.
local Event = require 'utils.event'
local Runner = require 'utils.test.runner'
local ModuleStore = require 'utils.test.module_store'

local ROOT = 'map_gen'
local START_TICK = 300 -- after the map's own setup

-- map_gen test modules that need a real player, as paths below map_gen: these build from the
-- player's cursor
local NEEDS_PLAYER = {
    'entity placement restriction/player builds'
}

-- Removes a test module from the tree by its path below `root`; true if it was there.
local function remove_module(root, path)
    local parent, name = root, nil
    for part in path:gmatch('[^/]+') do
        if name then
            parent = parent.children[name]
            if not parent then
                return false
            end
        end
        name = part
    end
    if parent.children[name] then
        parent.children[name] = nil
        return true
    end
    return false
end

local passed, failed = 0, 0

local function report(module, path)
    local name = module.name and (path .. '/' .. module.name) or path
    if module.startup_error then
        failed = failed + 1
        log('TESTRESULT FAIL ' .. name .. ' (startup): ' .. tostring(module.startup_error))
    end
    for _, test in pairs(module.tests or {}) do
        local took = ''
        if test.finished_tick then
            took = ' (' .. (test.finished_tick - test.started_tick) .. ' ticks, #' .. test.order .. ')'
        end
        if test.passed then
            passed = passed + 1
            log('TESTRESULT PASS ' .. name .. ' :: ' .. test.name .. took)
        else
            failed = failed + 1
            -- the time before the error, which can run over several lines
            log('TESTRESULT FAIL ' .. name .. ' :: ' .. test.name .. took .. ' :: ' .. tostring(test.error))
        end
    end
    for _, child in pairs(module.children) do
        report(child, name)
    end
end

local function done()
    log('TESTS DONE passed=' .. passed .. ' failed=' .. failed)
end

Event.add(Runner.events.test_finished, function(event)
    log('TESTMARK ' .. event.order)
end)

Event.add(Runner.events.tests_run_finished, function()
    report(ModuleStore.root_module.children[ROOT], '')
    done()
end)

Event.add(defines.events.on_tick, function(event)
    if event.tick ~= START_TICK then
        return
    end
    local root = ModuleStore.root_module.children[ROOT]
    if not root then
        log('TESTRESULT FAIL no ' .. ROOT .. ' tests were discovered')
        failed = 1
        done()
        return
    end
    game.speed = rawget(_G, '_HEADLESS_GAME_SPEED') or 1
    log('TESTMARK 0')
    for _, path in pairs(NEEDS_PLAYER) do
        if remove_module(root, path) then
            log('TESTRESULT SKIP /' .. ROOT .. '/' .. path .. ' (needs a player)')
        end
    end
    Runner.run_module(root, game.forces.player)
end)
