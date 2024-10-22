local Declare = require 'utils.test.declare'
local EventFactory = require 'utils.test.event_factory'
local Assert = require 'utils.test.assert'
local Helper = require 'utils.test.helper'
local CorpseUtil = require 'features.corpse_util'
local DeathCorpseTags = require 'features.death_corpse_tags'

local function test_teardown(context)
    context:add_teardown(CorpseUtil.clear)
end

local function declare_test(name, func)
    local function test_func(context)
        test_teardown(context)
        func(context)
    end

    Declare.test(name, test_func)
end

Declare.module({'features', 'death_corpse_tags'}, function()
    local teardown

    Declare.module_startup(function(context)
        teardown = Helper.startup_test_surface(context)

        -- wait for surface to be charted, needed before a tag can be created.
        context:next(function()
            local player = context.player
            Helper.wait_for_chunk_to_be_charted(context, player.force, player.surface, {0, 0})
        end)
    end)

    Declare.module_teardown(function()
        teardown()
    end)

    local function fake_death(player, has_items)
        local surface = player.physical_surface
        local position = player.physical_position

        local entity = surface.create_entity {
            name = 'character-corpse',
            position = position,
            player_index = player.index,
            inventory_size = has_items and 1 or nil
        }

        if not entity or not entity.valid then
            error('no corpse')
        end

        if has_items then
            local inventory = entity.get_inventory(defines.inventory.character_corpse)
            inventory.insert('iron-plate')
        end

        return EventFactory.on_player_died(player.index)
    end

    declare_test('corpse removed and empty message when corpse is empty', function(context)
        -- Arrange.
        local player = context.player
        player.teleport({5, 5}, player.physical_surface)

        context:add_teardown(function()
            player.teleport({0, 0}, player.physical_surface)
        end)

        local actual_text

        Helper.modify_lua_object(context, player, 'print', function(text)
            actual_text = text
        end)

        Helper.modify_lua_object(context, game, 'get_player', function()
            return player
        end)

        local event = fake_death(player, false)

        -- Act.
        DeathCorpseTags._player_died(event)

        -- Assert.
        local corpses = player.physical_surface.find_entities_filtered({name = 'character-corpse', position = player.physical_position, radius = 1})
        Assert.equal(0, #corpses)

        local expected = {'death_corpse_tags.empty_corpse'}
        Assert.table_equal(expected, actual_text)
    end)
end)
