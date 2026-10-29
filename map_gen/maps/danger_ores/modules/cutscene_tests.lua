-- Tests for Danger Ores' intro cutscene, discovered when cutscene.lua is loaded (any Danger Ores
-- map). What the cards say, and where the cutscene is on (not Safety Ores, whose rule is the
-- opposite), the rule scene's stage and a new player who doesn't auto play it.
--
-- The stage is built on a scratch surface. The new player is a stand-in: a headless server has
-- none, and showing the start-up messages is recorded rather than done, since it opens the map
-- info for a real player.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local Settings = require 'utils.redmew_settings'
local PC = require 'features.player_create'
local DOC = require 'map_gen.maps.danger_ores.configuration'
local AllowedEntities = require 'map_gen.maps.danger_ores.modules.allowed_entities'
local MapPoll = require 'map_gen.maps.danger_ores.modules.map_poll'
local Cutscene = require 'map_gen.maps.danger_ores.modules.cutscene'

-- far past any real player, so the setting it changes is nobody's
local player_index = 10000

local function has_line(lines, key)
    for _, line in pairs(lines) do
        if type(line) == 'table' and line[1] == key then
            return true
        end
    end
    return false
end

Declare.module({'map_gen', 'danger ores', 'cutscene'}, function()
    Declare.test('a poll name splits into the map and its twist', function()
        -- Act
        local name, twist = Cutscene.split_display_name('Petals (iron to copper in rings)')
        local plain_name, no_twist = Cutscene.split_display_name('Default')

        -- Assert
        Assert.equal('Petals', name, 'name from a poll name with a twist')
        Assert.equal('iron to copper in rings', twist, 'twist from a poll name with a twist')
        Assert.equal('Default', plain_name, 'name from a poll name without a twist')
        Assert.is_nil(no_twist, 'twist from a poll name without a twist')
    end)

    Declare.test('the title card welcomes players to the map and says its twist', function()
        -- Act
        local lines = Cutscene.welcome_lines({name = 'Petals', twist = 'iron to copper in rings'})

        -- Assert
        Assert.equal('danger_ores.cutscene_welcome', lines[1][1], 'first line')
        Assert.equal('Petals', lines[1][2], 'map welcomed to')
        Assert.equal('Iron to copper in rings', lines[2], 'twist line, capitalized')
    end)

    Declare.test('the last card promises a satellite goal only on maps won by satellites', function()
        -- Act
        local goal_title, goal_lines = Cutscene.goal_card({win_satellite_count = 1000, poll = true})
        local other_title, other_lines = Cutscene.goal_card({poll = false})

        -- Assert
        Assert.equal('danger_ores.cutscene_goal_title', goal_title[1], 'title with a satellite goal')
        Assert.is_true(has_line(goal_lines, 'danger_ores.cutscene_goal'), 'the satellite goal is missing with a satellite goal')
        Assert.is_true(has_line(goal_lines, 'danger_ores.cutscene_poll'), 'the poll line is missing on a map with a poll')
        Assert.equal('danger_ores.cutscene_good_luck', other_title[1], 'title without a satellite goal')
        Assert.is_true(not has_line(other_lines, 'danger_ores.cutscene_goal'), 'a satellite goal is shown on a map without one')
        Assert.is_true(not has_line(other_lines, 'danger_ores.cutscene_poll'), 'the poll line is shown on a map without a poll')
    end)

    -- the rest needs the cutscene on this map: its card, its stage and its setting
    if DOC.cutscene.enabled then
        Declare.test('the cards name this map as the next-map poll does, with its goal', function()
            -- Arrange
            local expected_name
            for _, map in pairs(MapPoll.get_maps()) do
                if map.name == DOC.scenario_name then
                    expected_name = Cutscene.split_display_name(map.display_name)
                end
            end
            local expected_count = DOC.rocket_launched.enabled and DOC.rocket_launched.win_satellite_count or nil

            -- Act: the scenario filled the card when the map started
            local card = Cutscene.get_card()

            -- Assert
            if expected_name and DOC.map_poll.enabled then
                Assert.equal(expected_name, card.name, 'map name on the title card')
            end
            Assert.equal(expected_count, card.win_satellite_count, 'satellites to win on the last card')
        end)

        Declare.test('the rule scene leaves off the ore what the map refuses there', function(context)
            -- Arrange: a map that refuses cars on ore
            local surface, delete_surface = Helper.create_test_surface(context, {area = {128, 64}})
            context:add_teardown(delete_surface)
            local is_allowed = AllowedEntities.is_allowed
            Helper.modify_lua_object(context, AllowedEntities, 'is_allowed', function(entity)
                return entity.name ~= 'car' and is_allowed(entity)
            end)

            context:next(function()
                -- Act
                Cutscene.build_stage(surface, DOC.map_config.main_ores)

                -- Assert
                local function count(name)
                    return surface.count_entities_filtered {area = Cutscene.ore_area, name = name, force = Cutscene.force_name}
                end
                Assert.equal(0, count('car'), 'cars on the ore')
                Assert.is_true(count('transport-belt') > 0, 'the belts on the ore were left off too')
            end)
        end)

        Declare.test('the rule scene\'s drills feed its furnaces, and the furnaces its assemblers', function(context)
            -- Arrange
            local surface, delete_surface = Helper.create_test_surface(context, {area = {128, 64}})
            context:add_teardown(delete_surface)
            local ore = Cutscene.main_ore(DOC.map_config.main_ores)
            if not (ore and Cutscene.products[ore.name]) then
                -- only the main ores it has a line for are smelted and made into something
                return
            end
            local machines

            local function idle()
                local list = {}
                for _, machine in pairs(machines) do
                    if machine.products_finished == 0 then
                        list[#list + 1] = machine.name .. ' at ' .. serpent.line(machine.position) .. ' (' .. tostring(machine.status) .. ')'
                    end
                end
                return list
            end

            context:next(function()
                Cutscene.build_stage(surface, DOC.map_config.main_ores)
                machines = surface.find_entities_filtered {type = {'furnace', 'assembling-machine'}, force = Cutscene.force_name}
                Assert.is_true(#machines > 0, 'no furnaces or assemblers on the stage')
                -- Act: without what they start with, all they make comes down the line
                for _, machine in pairs(machines) do
                    machine.clear_items_inside()
                end
            end):wait_until(3600, function()
                -- Assert
                return #idle() == 0
            end, function()
                return 'made nothing: ' .. table.concat(idle(), ', ')
            end)
        end)

        Declare.test('a new player who does not auto play the cutscene still gets the map info', function(context)
            -- Arrange: the setting changes with the real game in place, its handlers look the player up
            Settings.set(player_index, Cutscene.auto_play_setting_name, false)

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
                Settings.set(player_index, Cutscene.auto_play_setting_name, true)
            end)

            local shown_to = {}
            Helper.modify_lua_object(context, PC, 'show_start_up', function(player)
                shown_to[#shown_to + 1] = player
            end)

            -- Act
            Cutscene.start_for_new_player(player_index)

            -- Assert
            Assert.equal(1, #shown_to, 'times the start-up messages and map info were shown')
            Assert.equal(fake_player, shown_to[1], 'player shown the start-up messages and map info')
            Assert.equal('danger_ores.replay_cutscene', messages[1] and messages[1][1], 'the /replay hint')
        end)
    end
end)
