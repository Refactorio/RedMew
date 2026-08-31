local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local table = require 'utils.table'

local MapPollUtils = require 'map_gen.maps.danger_ores.modules.map_poll_utils'

-- Synthetic maps, so the tests cover all tag combinations without depending on the real
-- map configuration.
local maps = {
    {name = 'regular_map', tags = {'regular'}},
    {name = 'overhaul_map', tags = {'overhaul'}},
    {name = 'multi_tag_map', tags = {'regular', 'event'}},
    {name = 'untagged_map'},
    {name = 'empty_tags_map', tags = {}}
}

local untagged_names = {'untagged_map', 'empty_tags_map'}
local all_names = {'regular_map', 'overhaul_map', 'multi_tag_map', 'untagged_map', 'empty_tags_map'}

local function names_for_indices(maps_list, indices)
    local names = {}
    for _, index in pairs(indices) do
        names[#names + 1] = maps_list[index].name
    end
    return names
end

local function assert_map_names(server_tags, expected_names)
    local actual_names = table.sorted_copy(names_for_indices(maps, MapPollUtils.get_map_indices(maps, server_tags)))
    local expected_sorted = table.sorted_copy(expected_names)
    Assert.table_equal(
        expected_sorted,
        actual_names,
        'expected [' .. table.concat(expected_sorted, ', ') .. '] got [' .. table.concat(actual_names, ', ') .. ']'
    )
end

Declare.module({'map_gen', 'maps', 'danger_ores', 'modules', 'map_poll_utils', 'get_map_indices'}, function()
    Declare.test('returns all maps when server tags are nil', function()
        assert_map_names(nil, all_names)
    end)

    Declare.test('returns only maps without tags when server tags are not a table', function()
        assert_map_names('regular', untagged_names)
    end)

    Declare.test('returns only maps without tags when server tags are empty', function()
        assert_map_names({}, untagged_names)
    end)

    Declare.test('matches server tags case insensitively', function()
        assert_map_names({'REGULAR'}, {'regular_map', 'multi_tag_map', 'untagged_map', 'empty_tags_map'})
    end)

    Declare.test('returns maps matching any of the server tags', function()
        assert_map_names({'event', 'overhaul'}, {'overhaul_map', 'multi_tag_map', 'untagged_map', 'empty_tags_map'})
    end)

    Declare.test('ignores non-string entries in server tags', function()
        assert_map_names({1, true, 'REGULAR'}, {'regular_map', 'multi_tag_map', 'untagged_map', 'empty_tags_map'})
    end)

    Declare.test('returns an empty array when no map matches the server tags', function()
        -- Uses maps that all have tags, as maps without tags are always included.
        local tagged_maps = {
            {name = 'a_map', tags = {'regular'}},
            {name = 'b_map', tags = {'overhaul'}}
        }

        Assert.equal(0, #MapPollUtils.get_map_indices(tagged_maps, {'no_maps_have_this_tag'}))
    end)

    Declare.test('matches map tags case insensitively', function()
        local mixed_case_maps = {
            {name = 'upper_map', tags = {'REGULAR'}},
            {name = 'other_map', tags = {'overhaul'}}
        }

        local names = names_for_indices(mixed_case_maps, MapPollUtils.get_map_indices(mixed_case_maps, {'regular'}))
        Assert.equal(1, #names)
        Assert.array_contains(names, 'upper_map')
    end)

    Declare.test('returns an empty array when there are no maps', function()
        Assert.equal(0, #MapPollUtils.get_map_indices({}, nil))
        Assert.equal(0, #MapPollUtils.get_map_indices({}, {'regular'}))
    end)

    Declare.test('includes a map only once when it matches multiple server tags', function()
        local server_tags = {'regular', 'event', 'regular'}

        assert_map_names(server_tags, {'regular_map', 'multi_tag_map', 'untagged_map', 'empty_tags_map'})
    end)
end)

Declare.module({'map_gen', 'maps', 'danger_ores', 'modules', 'map_poll_utils', 'get_next_map'}, function()
    local function answers_with_vote_counts(vote_counts)
        local answers = {}
        for _, voted_count in pairs(vote_counts) do
            answers[#answers + 1] = {voted_count = voted_count}
        end
        return answers
    end

    Declare.test('returns nil when there are no answers', function()
        local map_indices = MapPollUtils.get_map_indices(maps, nil)

        Assert.is_nil(MapPollUtils.get_next_map(maps, map_indices, {}))
    end)

    Declare.test('returns the map for the most voted answer', function()
        local map_indices = MapPollUtils.get_map_indices(maps, nil)
        local answers = answers_with_vote_counts({1, 3, 2, 4, 0})

        local next_map = MapPollUtils.get_next_map(maps, map_indices, answers)

        Assert.equal('untagged_map', next_map.name)
    end)

    Declare.test('resolves the voted answer through the map indices', function()
        -- Round trip: the maps are filtered, so the second answer must resolve to the
        -- second matching map (maps[3]), not the second map in maps.
        local map_indices = MapPollUtils.get_map_indices(maps, {'regular'})
        local answers = answers_with_vote_counts({0, 1, 0, 0})

        local next_map = MapPollUtils.get_next_map(maps, map_indices, answers)

        Assert.equal('multi_tag_map', next_map.name)
    end)

    Declare.test('uses the answer position as index when map_indices is nil', function()
        -- For polls created by older scenario versions, which predate map_indices.
        local answers = answers_with_vote_counts({0, 1})

        local next_map = MapPollUtils.get_next_map(maps, nil, answers)

        Assert.equal('overhaul_map', next_map.name)
    end)

    Declare.test('returns nil when the winning answer has no map index', function()
        -- An admin can add answers to the poll after it was created, so an answer can
        -- exist beyond the map_indices array.
        local map_indices = MapPollUtils.get_map_indices(maps, {'regular'})
        local answers = answers_with_vote_counts({0, 0, 0, 0, 1})

        Assert.is_nil(MapPollUtils.get_next_map(maps, map_indices, answers))
    end)
end)
