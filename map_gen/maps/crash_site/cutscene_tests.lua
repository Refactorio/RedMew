-- Tests for the Crash Site intro cutscene, discovered when cutscene.lua is loaded (a Crash Site map
-- is active). A new player's start-up messages and map info wait for the cutscene to end, so a
-- player who turned off auto play must get them some other way.
--
-- The player is a stand-in: a headless server has none, and showing the start-up messages is
-- recorded rather than done, since it opens the map info for a real player.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local Settings = require 'utils.redmew_settings'
local PC = require 'features.player_create'
local CrashsiteCutscene = require 'map_gen.maps.crash_site.cutscene'

local auto_play_setting_name = 'crashsite.auto_play_cutscene'

-- far past any real player, so the setting it changes is nobody's
local player_index = 10000

Declare.module({'map_gen', 'crash site', 'cutscene'}, function()
    Declare.test('a new player who does not auto play the cutscene still gets the map info', function(context)
        -- Arrange: the setting changes with the real game in place, its handlers look the player up
        Settings.set(player_index, auto_play_setting_name, false)

        local messages = {}
        local fake_player = {
            index = player_index,
            name = 'test runner',
            valid = true,
            print = function(message)
                messages[#messages + 1] = message
            end
        }
        Helper.modify_global(context, 'game', Helper.fake_lua_object(game, {
            get_player = function(index)
                return index == player_index and fake_player or nil
            end
        }))
        -- after the game's teardown, so the game is back when it runs
        context:add_teardown(function()
            Settings.set(player_index, auto_play_setting_name, true)
        end)

        local shown_to = {}
        Helper.modify_lua_object(context, PC, 'show_start_up', function(player)
            shown_to[#shown_to + 1] = player
        end)

        -- Act
        CrashsiteCutscene.start_for_new_player(player_index)

        -- Assert
        Assert.equal(1, #shown_to, 'times the start-up messages and map info were shown')
        Assert.equal(fake_player, shown_to[1], 'player shown the start-up messages and map info')
        Assert.equal('crashsite.replay_cutscene', messages[1] and messages[1][1], 'the /replay hint')
    end)
end)
