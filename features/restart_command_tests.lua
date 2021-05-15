local Declare = require 'utils.test.declare'
local Helper = require 'utils.test.helper'
local RestartCommand = require 'features.restart_command'
local Assert = require 'utils.test.assert'
local Gui = require 'utils.gui'
local Command = require 'utils.command'

local function test_teardown(context)
    RestartCommand.set_start_game_data({type = RestartCommand.game_types.scenario, name = '', mod_pack = nil})

    context:add_teardown(function()
        local main_frame = context.player.gui.center[RestartCommand._main_frame_name]
        if main_frame and main_frame.valid then
            Gui.destroy(main_frame)
        end
    end)
end

local function declare_test(name, func)
    local function test_func(context)
        test_teardown(context)
        func(context)
    end

    Declare.test(name, test_func)
end

local function assert_view_matches_start_game_data(player, is_save, is_scenario, name, is_mod_pack_set, mod_pack_name)
    local center = player.gui.center
    local scenario_radio_button = Helper.get_gui_element_by_name(center, RestartCommand._scenario_radio_button_name)
    local save_radio_button = Helper.get_gui_element_by_name(center, RestartCommand._save_radio_button_name)
    local name_textfield = Helper.get_gui_element_by_name(center, RestartCommand._name_textfield_name)
    local set_mod_pack_checkbox = Helper.get_gui_element_by_name(center, RestartCommand._set_mod_pack_checkbox_name)
    local mod_pack_name_textfield = Helper.get_gui_element_by_name(center, RestartCommand._mod_pack_name_textfield_name)

    Assert.equal(is_scenario, scenario_radio_button.state)
    Assert.equal(is_save, save_radio_button.state)
    Assert.equal(name, name_textfield.text)
    Assert.equal(is_mod_pack_set, set_mod_pack_checkbox.state)
    Assert.equal(mod_pack_name, mod_pack_name_textfield.text)
end

local function assert_start_game_data(type, name, mod_pack)
    local start_game_data = RestartCommand.get_start_game_data()

    Assert.equal(type, start_game_data.type)
    Assert.equal(name, start_game_data.name)
    Assert.equal(mod_pack, start_game_data.mod_pack)
end

local function run_config_command(player, parameter)
    Command._raise_command('config-restart', player.index, parameter or '')
end

local function run_restart_command(player, parameter)
    Command._raise_command('restart', player.index, parameter or '')
end

local function run_abort_command(player)
    Command._raise_command('abort', player.index)
end

Declare.module({'features', 'restart_command'}, function()
    local inital_start_game_data

    Declare.module_startup(function()
        inital_start_game_data = RestartCommand.get_start_game_data()
    end)

    Declare.module_teardown(function()
        RestartCommand.set_start_game_data(inital_start_game_data)
    end)

    declare_test('Shows start game data when scenario.', function(context)
        -- Arrange.
        local start_game_data = {
            type = RestartCommand.game_types.scenario,
            name = 'some_name',
            mod_pack = 'some_mod_pack'
        }
        RestartCommand.set_start_game_data(start_game_data)

        -- Act.
        run_config_command(context.player)

        -- Assert.
        context:next(function()
            assert_view_matches_start_game_data(context.player, false, true, start_game_data.name, true,
                start_game_data.mod_pack)
        end)
    end)

    declare_test('Shows start game data when save.', function(context)
        -- Arrange.
        local start_game_data = {type = RestartCommand.game_types.save, name = 'some_name', mod_pack = 'some_mod_pack'}
        RestartCommand.set_start_game_data(start_game_data)

        -- Act.
        run_config_command(context.player)

        -- Assert.
        context:next(function()
            assert_view_matches_start_game_data(context.player, true, false, start_game_data.name, true,
                start_game_data.mod_pack)
        end)
    end)

    declare_test('Shows start game data when no mod pack.', function(context)
        -- Arrange.
        local start_game_data = {type = RestartCommand.game_types.scenario, name = 'some_name'}
        RestartCommand.set_start_game_data(start_game_data)

        -- Act.
        run_config_command(context.player)

        -- Assert.
        context:next(function()
            assert_view_matches_start_game_data(context.player, false, true, start_game_data.name, false, '')
        end)
    end)

    declare_test('Shows start game data when mod pack empty string.', function(context)
        -- Arrange.
        local start_game_data = {type = RestartCommand.game_types.scenario, name = 'some_name', mod_pack = ''}
        RestartCommand.set_start_game_data(start_game_data)

        -- Act.
        run_config_command(context.player)

        -- Assert.
        context:next(function()
            assert_view_matches_start_game_data(context.player, false, true, start_game_data.name, true,
                start_game_data.mod_pack)
        end)
    end)

    declare_test('Requires admin to run command.', function(context)
        -- Arrange.
        local player = context.player
        Helper.modify_lua_object(context, player, 'admin', false)
        Helper.modify_lua_object(context, game, 'get_player', function()
            return player
        end)

        -- Act.
        run_config_command(player)

        -- Assert.
        local center = player.gui.center
        local main_frame = Helper.get_gui_element_by_name(center, RestartCommand._main_frame_name)
        Assert.is_nil(main_frame)
    end)

    declare_test('get returns start game data.', function(context)
        -- Arrange.
        local player = context.player
        local actual = nil
        Helper.modify_lua_object(context, player, 'print', function(str)
            actual = str
        end)
        Helper.modify_lua_object(context, game, 'get_player', function()
            return player
        end)

        local start_game_data = {
            type = RestartCommand.game_types.scenario,
            name = 'some_name',
            mod_pack = 'some_mod_pack'
        }
        RestartCommand.set_start_game_data(start_game_data)

        -- Act.
        run_config_command(player, 'get')

        -- Assert.
        local expected = [[
Start Game Data:
Type: scenario
Name: some_name
Mod Pack: some_mod_pack]]
        Assert.equal(expected, actual)
    end)

    declare_test('set does set start game data.', function(context)
        -- Act.
        run_config_command(context.player, "set {type = '" .. RestartCommand.game_types.save
            .. "', name = 'new_name', mod_pack = 'new_mod_pack_name'}")

        -- Assert.
        local start_game_data = RestartCommand.get_start_game_data()
        Assert.equal(RestartCommand.game_types.save, start_game_data.type)
        Assert.equal('new_name', start_game_data.name)
        Assert.equal('new_mod_pack_name', start_game_data.mod_pack)
    end)

    for _, data in pairs({'new_name', ' new_name ', "'new_name'", '"new_name"', " 'new_name'"}) do
        declare_test('set does set start game data for string ' .. data, function(context)
            -- Act.
            run_config_command(context.player, 'set ' .. data)

            -- Assert.
            local start_game_data = RestartCommand.get_start_game_data()
            Assert.equal(RestartCommand.game_types.scenario, start_game_data.type)
            Assert.equal('new_name', start_game_data.name)
            Assert.equal(nil, start_game_data.mod_pack)
        end)
    end

    declare_test('Close button closes gui', function(context)
        -- Arrange.
        local player = context.player
        run_config_command(player)

        local center = player.gui.center
        local close_button = Helper.get_gui_element_by_name(center, RestartCommand._close_button_name)

        -- Act.
        context:next(function()
            Helper.click(close_button)
        end)

        -- Assert
        context:next(function()
            local main_frame = Helper.get_gui_element_by_name(center, RestartCommand._main_frame_name)
            Assert.is_nil(main_frame)
        end)
    end)

    declare_test('Can change start game data from gui.', function(context)
        -- Arrange.
        local player = context.player
        run_config_command(player)

        local center = player.gui.center
        local save_radio_button = Helper.get_gui_element_by_name(center, RestartCommand._save_radio_button_name)
        local name_textfield = Helper.get_gui_element_by_name(center, RestartCommand._name_textfield_name)
        local mod_pack_checkbox = Helper.get_gui_element_by_name(center, RestartCommand._set_mod_pack_checkbox_name)
        local mod_pack_name_textfield = Helper.get_gui_element_by_name(center,
            RestartCommand._mod_pack_name_textfield_name)

        -- Act.
        Helper.click(save_radio_button)
        Helper.set_text(name_textfield, 'new_name')
        Helper.set_checkbox(mod_pack_checkbox, true)
        Helper.set_text(mod_pack_name_textfield, 'new_mod_pack_name')

        -- Assert.
        context:next(function()
            assert_start_game_data(RestartCommand.game_types.save, 'new_name', 'new_mod_pack_name')
        end)
    end)

    declare_test('Can change start game data to scenario from gui.', function(context)
        -- Arrange.
        RestartCommand.set_start_game_data({type = RestartCommand.game_types.save})
        local player = context.player
        run_config_command(player)

        local center = player.gui.center
        local scenario_radio_button = Helper.get_gui_element_by_name(center, RestartCommand._scenario_radio_button_name)

        -- Act.
        Helper.click(scenario_radio_button)

        -- Assert.
        context:next(function()
            assert_start_game_data(RestartCommand.game_types.scenario, '', nil)
        end)
    end)

    declare_test('Can change start game data to no mod pack from gui.', function(context)
        -- Arrange.
        RestartCommand.set_start_game_data({mod_pack = 'some_mod_pack'})
        local player = context.player
        run_config_command(player)

        local center = player.gui.center
        local mod_pack_checkbox = Helper.get_gui_element_by_name(center, RestartCommand._set_mod_pack_checkbox_name)
        local mod_pack_name_textfield = Helper.get_gui_element_by_name(center,
            RestartCommand._mod_pack_name_textfield_name)

        -- Act.
        Helper.set_checkbox(mod_pack_checkbox, false)

        -- Assert.
        context:next(function()
            assert_start_game_data(RestartCommand.game_types.scenario, '', nil)
            Assert.equal('some_mod_pack', mod_pack_name_textfield.text)
        end)
    end)

    declare_test('Mod pack is remembered when not set and gui is closed and reopened.', function(context)
        -- Arrange.
        RestartCommand.set_start_game_data({mod_pack = 'some_mod_pack'})
        local player = context.player
        run_config_command(player)

        local center = player.gui.center
        local mod_pack_checkbox = Helper.get_gui_element_by_name(center, RestartCommand._set_mod_pack_checkbox_name)
        local close_button = Helper.get_gui_element_by_name(center, RestartCommand._close_button_name)

        Helper.set_checkbox(mod_pack_checkbox, false)

        context:next(function()
            Helper.click(close_button)
        end):next(function()
            -- Make sure gui closed
            local main_frame = Helper.get_gui_element_by_name(center, RestartCommand._main_frame_name)
            Assert.is_nil(main_frame)
        end):next(function()
            -- Reopen gui.
            run_config_command(player)
        end):next(function()
            assert_start_game_data(RestartCommand.game_types.scenario, '', nil)

            local mod_pack_name_textfield = Helper.get_gui_element_by_name(center,
                RestartCommand._mod_pack_name_textfield_name)
            Assert.equal('some_mod_pack', mod_pack_name_textfield.text)

            -- Re-enable mod pack
            mod_pack_checkbox = Helper.get_gui_element_by_name(center, RestartCommand._set_mod_pack_checkbox_name)
            Helper.set_checkbox(mod_pack_checkbox, true)
        end):next(function()
            assert_start_game_data(RestartCommand.game_types.scenario, '', 'some_mod_pack')

            local mod_pack_name_textfield = Helper.get_gui_element_by_name(center,
                RestartCommand._mod_pack_name_textfield_name)
            Assert.equal('some_mod_pack', mod_pack_name_textfield.text)
        end)
    end)

    declare_test('restart command starts restart.', function(context)
        -- Arrange.
        RestartCommand.set_start_game_data({name = 'new_name', type = RestartCommand.game_types.scenario})

        local player = context.player

        context:add_teardown(function()
            run_abort_command(player)
        end)

        local output = {}

        local function game_print(str)
            output[#output + 1] = str
        end

        Helper.modify_lua_object(context, game, 'print', game_print)

        -- Act.
        run_restart_command(player)

        -- Assert.
        Assert.array_contains(output, 'Server restart initiated by ' .. player.name)
        Assert.array_contains(output, 'Next map: new_name')
    end)

    for _, argument in pairs({'other_game', '{name = "other_game", type = "scenario"}'}) do
        declare_test('restart command starts restart and sets start data with argument ' .. argument, function(context)
            -- Arrange.
            RestartCommand.set_start_game_data({
                name = 'new_name',
                type = RestartCommand.game_types.save,
                mod_pack = 'mod_pack'
            })

            local player = context.player

            context:add_teardown(function()
                run_abort_command(player)
            end)

            local output = {}

            local function game_print(str)
                output[#output + 1] = str
            end

            Helper.modify_lua_object(context, game, 'print', game_print)

            -- Act.
            run_restart_command(player, argument)

            -- Assert.
            Assert.array_contains(output, 'Server restart initiated by ' .. player.name)
            Assert.array_contains(output, 'Next map: other_game')
            assert_start_game_data(RestartCommand.game_types.scenario, 'other_game', nil)
        end)
    end
end)
