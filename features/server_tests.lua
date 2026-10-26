-- Tests for features.server, discovered in every scenario (control.lua always loads it).
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Server = require 'features.server'

Declare.module({ 'features', 'server' }, function()
    Declare.module('on_server_started', function()
        Declare.test('a start without the server time, as raised by hand in a local game, sets no version', function(context)
            -- Arrange: no server time, as before the web server sends one, and no version yet
            local time_data = Server.get_time_data_raw()
            local old_secs, old_tick = time_data.secs, time_data.tick
            local old_version = storage.redmew_version
            context:add_teardown(function()
                time_data.secs, time_data.tick = old_secs, old_tick
                storage.redmew_version = old_version
            end)
            Server.set_time(nil)
            storage.redmew_version = nil

            -- Act
            Server._set_scenario_version()

            -- Assert
            Assert.is_nil(storage.redmew_version, 'scenario version')
        end)
    end)
end)
