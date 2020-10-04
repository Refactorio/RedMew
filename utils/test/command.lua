local Command = require 'utils.command'
local Runner = require 'utils.test.runner'
local Viewer = require 'utils.test.viewer'

Command.add(
    'test-runner',
    {
        description = "Runs tests and opens the test runner, use flag 'open' to skip running tests first.",
        arguments = {'open'},
        default_values = {open = false},
        allowed_by_server = false
    },
    function(args, player)
        local open = args.open
        if open == 'open' or open == 'o' then
            Viewer.open(player)
        else
            Runner.run_module(nil, player)
        end
    end
)
