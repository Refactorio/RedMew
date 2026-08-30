local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Poll = require 'features.gui.poll'
local Restart = require 'features.restart_command'
local Server = require 'features.server'
local table = require 'utils.table'

local MapPoll = require 'map_gen.maps.danger_ores.modules.map_poll'

local maps = MapPoll.get_maps()

--- Runs the on_server_started handler, as the web server would.
local function server_started()
    MapPoll.on_server_started()
end

-- Mocks Server.try_get_data to capture the callback token map_poll requests map_poll_tags
-- with, so the web server's response can be simulated below. Other modules' requests are
-- passed through to the real function.
local original_try_get_data
local map_poll_tags_request_token

local function mock_try_get_data(data_set, key, callback_token)
    if data_set == 'map_poll_tags' then
        map_poll_tags_request_token = callback_token
        return
    end

    return original_try_get_data(data_set, key, callback_token)
end

--- Simulates the web server responding to the map_poll_tags request.
local function server_sends_tags(tags)
    Assert.is_true(map_poll_tags_request_token ~= nil, 'the server did not request map_poll_tags')

    _G.ServerCommands.raise_callback(
        map_poll_tags_request_token,
        {data_set = 'map_poll_tags', key = Server.get_server_id(), value = tags}
    )
end

--- Prepares a fresh server with the given id, ready for on_server_started to be raised.
local function setup_server(server_id)
    MapPoll.reset()
    Restart.set_use_map_poll_result_option(nil)
    Restart.set_known_modpacks_option(nil)
    Server.set_start_data({server_id = server_id, server_name = 'map_poll_tests'})

    map_poll_tags_request_token = nil
    if original_try_get_data == nil then
        original_try_get_data = Server.try_get_data
    end
    Server.try_get_data = mock_try_get_data
end

local function maps_tagged_with(tag)
    local tagged = {}
    for _, map_data in pairs(maps) do
        if table.contains(map_data.tags, tag) then
            tagged[#tagged + 1] = map_data
        end
    end
    return tagged
end

local function map_display_names(map_entries)
    local names = {}
    for _, map_data in pairs(map_entries) do
        names[#names + 1] = map_data.display_name
    end
    return names
end

--- Asserts that the created map poll contains exactly the answers of the given maps.
local function assert_poll_answers(expected_maps)
    local poll_id = MapPoll.get_map_poll_id()
    Assert.is_true(poll_id ~= nil, 'no map poll was created')

    local poll_data = Poll.get_poll_data(poll_id)
    Assert.is_true(poll_data ~= nil, 'map poll ' .. tostring(poll_id) .. ' was not found')

    local answer_names = {}
    for _, answer in pairs(poll_data.answers) do
        answer_names[#answer_names + 1] = answer.text
    end

    local expected_names = table.sorted_copy(map_display_names(expected_maps))
    answer_names = table.sorted_copy(answer_names)
    Assert.table_equal(
        expected_names,
        answer_names,
        'expected poll answers [' .. table.concat(expected_names, ', ') .. '] got [' .. table.concat(answer_names, ', ') .. ']'
    )
end

local function assert_poll_not_created()
    Assert.is_nil(MapPoll.get_map_poll_id())
    Assert.is_nil(Restart.get_use_map_poll_result_option(), 'use map poll result option should not be set')
end

Declare.module({'map_gen', 'maps', 'danger_ores', 'modules', 'map_poll'}, function()
    local initial_server_id
    local initial_server_name
    local initial_use_map_poll_result
    local initial_known_mod_packs

    Declare.module_startup(function()
        initial_server_id = Server.get_server_id()
        initial_server_name = Server.get_server_name()
        initial_use_map_poll_result = Restart.get_use_map_poll_result_option()
        initial_known_mod_packs = Restart.get_known_modpacks_option()
    end)

    Declare.module_teardown(function()
        if original_try_get_data ~= nil then
            Server.try_get_data = original_try_get_data
            original_try_get_data = nil
        end

        MapPoll.reset()
        Server.set_start_data({server_id = initial_server_id, server_name = initial_server_name})
        Restart.set_use_map_poll_result_option(initial_use_map_poll_result)
        Restart.set_known_modpacks_option(initial_known_mod_packs)
    end)

    Declare.test('creates a poll with all maps when the server has no id', function()
        -- Arrange.
        setup_server('')

        -- Act.
        server_started()

        -- Assert.
        assert_poll_answers(maps)
        Assert.equal(true, Restart.get_use_map_poll_result_option())
        Assert.is_true(Restart.get_known_modpacks_option() ~= nil, 'known mod packs option should be set')
    end)

    for _, tag in pairs(MapPoll.get_tags()) do
        Declare.test('creates a poll with the maps matching the ' .. tag .. ' server tags', function()
            -- Arrange.
            setup_server('map_poll_tests')

            -- Act.
            server_started()
            server_sends_tags({tag:upper()}) -- mixed case, to check matching is case-insensitive

            -- Assert.
            assert_poll_answers(maps_tagged_with(tag))
            Assert.equal(true, Restart.get_use_map_poll_result_option())
        end)
    end

    Declare.test('creates no poll when the server tags are empty', function()
        -- Arrange.
        setup_server('map_poll_tests')

        -- Act.
        server_started()
        server_sends_tags({})

        -- Assert.
        assert_poll_not_created()
    end)

    Declare.test('creates no poll when no map matches the server tags', function()
        -- Arrange.
        setup_server('map_poll_tests')

        -- Act.
        server_started()
        server_sends_tags({'no_maps_have_this_tag'})

        -- Assert.
        assert_poll_not_created()
    end)

    Declare.test('does not create a second poll when the server starts again', function()
        -- Arrange.
        setup_server('map_poll_tests')
        server_started()
        server_sends_tags({'regular'})
        local poll_id = MapPoll.get_map_poll_id()
        Assert.is_true(poll_id ~= nil, 'no map poll was created')

        -- Act.
        server_started()

        -- Assert.
        Assert.equal(poll_id, MapPoll.get_map_poll_id())
    end)

    Declare.test('get_next_map returns nil when no poll was created', function()
        -- Arrange.
        MapPoll.reset()

        -- Act.
        local next_map = MapPoll.get_next_map()

        -- Assert.
        Assert.is_nil(next_map)
    end)

    Declare.test('get_next_map returns the map voted for', function()
        -- Arrange.
        setup_server('')
        server_started()
        local poll_id = MapPoll.get_map_poll_id()

        -- Act. Simulates voting through the poll GUI, which sets voted_count on the answer.
        local answers = Poll.get_poll_data(poll_id).answers
        answers[3].voted_count = 2

        -- Assert.
        local next_map = MapPoll.get_next_map()
        Assert.equal(maps[3].name, next_map.name)
    end)

    for _, tag in pairs(MapPoll.get_tags()) do
        Declare.test('get_next_map resolves the voted answer to the offered ' .. tag .. ' map', function()
            -- Arrange. On a server offering only maps of one tag, the second answer must
            -- resolve to the second map with that tag, not the second map in the full maps table.
            setup_server('map_poll_tests')
            server_started()
            server_sends_tags({tag})
            local poll_id = MapPoll.get_map_poll_id()

            -- Act. Simulates voting through the poll GUI, which sets voted_count on the answer.
            local answers = Poll.get_poll_data(poll_id).answers
            answers[2].voted_count = 1

            -- Assert.
            local tagged_maps = maps_tagged_with(tag)
            local next_map = MapPoll.get_next_map()
            Assert.equal(tagged_maps[2].name, next_map.name)
        end)
    end
end)
