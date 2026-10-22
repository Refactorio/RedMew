local Command = require 'utils.command'
local Runner = require 'utils.test.runner'
local Viewer = require 'utils.test.viewer'
local Headless = require 'utils.test.headless'

Command.add(
    'test-runner',
    {
        description = "Runs tests and opens the test runner, use flag 'open' to skip running tests first, or 'headless' to run them the way CI does (without a player, results in script-output).",
        arguments = {'mode'},
        default_values = {mode = false},
        allowed_by_server = true
    },
    function(args, player)
        local mode = args.mode
        if mode == 'headless' then
            Headless.run(player)
        elseif not player then
            print('Only a headless run can be started from the server: /test-runner headless')
        elseif mode == 'open' or mode == 'o' then
            Viewer.open(player)
        else
            Runner.run_module(nil, player)
        end
    end
)
