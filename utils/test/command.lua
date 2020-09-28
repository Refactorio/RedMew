local Command = require 'utils.command'
local Runner = require 'utils.test.runner'
local Viewer = require 'utils.test.viewer'

Command.add(
    'test-runner',
    {
        description = "Runs tests and opens the test runner, use flag 'open' to skip running tests first.",
        arguments = {'open'},
        default_values = {open = false}
    },
    function(args, player)
        local open = args.open
        if open == 'open' or open == 'o' then
            if player == nil then
                print('Can not open test runner from server console.')
                return
            end

            Viewer.open(player)
            return
        end

        Runner.run_module(nil, player)
    end
)
