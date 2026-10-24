-- In-game tests for price_raffle: item worths, unlocking and locking items, and rolling random
-- item stacks within a budget. They run on maps that load the module: Danger Ores Expanse and
-- Frontier. Rolls use math.random, so the tests check properties (the budget always covers what
-- comes back, blacklisted items never show up) over repeated rolls, not exact stacks. Nothing
-- leaves an item unlocked: each test that unlocks one restores the state it found.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local PriceRaffle = require 'features.price_raffle'

local WORTHS = PriceRaffle.get_items_worth()

-- unlocks restore their prior state afterwards, so the roll tests see the map's own unlocks
local function restore_unlocked(context, name)
    -- Arrange: remember where this name stood before the test touched it
    local was_unlocked = PriceRaffle.is_unlocked(name)
    local was_value = PriceRaffle.get_unlocked_item_values()[name]
    context:add_teardown(function()
        if was_unlocked then
            PriceRaffle.set_unlocked(name, true, was_value)
        else
            PriceRaffle.set_unlocked(name, false)
        end
    end)
end

local function name_listing_count(name)
    local count = 0
    for _, listed in pairs(PriceRaffle.get_unlocked_item_names()) do
        if listed == name then
            count = count + 1
        end
    end
    return count
end

Declare.module(
    {'features', 'price_raffle'},
    function()
        Declare.test(
            'get_item_worth gives the listed worth for an item',
            function()
                -- Act
                local worth = PriceRaffle.get_item_worth('iron-plate')

                -- Assert
                Assert.equal(WORTHS['iron-plate'], worth, 'the worth of iron-plate is not the listed one')
            end
        )

        Declare.test(
            'get_item_worth gives 0 for an item with no listed worth',
            function()
                -- Act
                local worth = PriceRaffle.get_item_worth('raffle test missing item')

                -- Assert
                Assert.equal(0, worth, 'an unlisted item does not have a worth of 0')
            end
        )

        Declare.test(
            'starting resources are unlocked at their listed worths',
            function()
                -- Arrange: the resources the module unlocks when it initialises
                local starting = {'coal', 'copper-ore', 'iron-ore', 'stone'}
                local values = PriceRaffle.get_unlocked_item_values()

                -- Assert: no act of ours needed; this is what the module unlocked on init
                for _, name in ipairs(starting) do
                    Assert.is_true(PriceRaffle.is_unlocked(name), name .. ' is not unlocked at the start')
                    Assert.equal(WORTHS[name], values[name], name .. ' is not unlocked at its listed worth')
                end
            end
        )

        Declare.test(
            'resources with no listed worth stay locked',
            function()
                -- Assert: wood and fish have no worth, so the module never unlocks them
                local wood_unlocked = PriceRaffle.is_unlocked('wood')
                local fish_unlocked = PriceRaffle.is_unlocked('fish')
                Assert.equal(false, wood_unlocked, 'wood is unlocked even though it has no worth')
                Assert.equal(false, fish_unlocked, 'fish is unlocked even though it has no worth')
            end
        )

        Declare.test(
            'set_unlocked unlocks an item at the given value',
            function(context)
                -- Arrange
                restore_unlocked(context, 'small-lamp')

                -- Act
                PriceRaffle.set_unlocked('small-lamp', true, 7)
                local unlocked = PriceRaffle.is_unlocked('small-lamp')
                local value = PriceRaffle.get_unlocked_item_values()['small-lamp']

                -- Assert
                Assert.is_true(unlocked, 'small-lamp was not unlocked')
                Assert.equal(7, value, 'small-lamp was not unlocked at the given value')
                Assert.is_true(name_listing_count('small-lamp') >= 1, 'small-lamp is not in the name list')
            end
        )

        Declare.test(
            'unlocking the same item twice does not list it twice',
            function(context)
                -- Arrange
                restore_unlocked(context, 'repair-pack')

                -- Act
                PriceRaffle.set_unlocked('repair-pack', true, 9)
                PriceRaffle.set_unlocked('repair-pack', true, 9)
                local count = name_listing_count('repair-pack')

                -- Assert
                Assert.equal(1, count, 'repair-pack is listed ' .. count .. ' times in the name list')
            end
        )

        Declare.test(
            'set_unlocked with no value uses the listed worth',
            function(context)
                -- Arrange
                restore_unlocked(context, 'steel-plate')

                -- Act
                PriceRaffle.set_unlocked('steel-plate', true)
                local value = PriceRaffle.get_unlocked_item_values()['steel-plate']

                -- Assert
                Assert.equal(WORTHS['steel-plate'], value, 'steel-plate was not unlocked at its listed worth')
            end
        )

        Declare.test(
            'set_unlocked with no value and no worth defaults to 64',
            function(context)
                -- Arrange: wood is a real item with no listed worth
                restore_unlocked(context, 'wood')

                -- Act
                PriceRaffle.set_unlocked('wood', true)
                local value = PriceRaffle.get_unlocked_item_values()['wood']

                -- Assert
                Assert.equal(64, value, 'an item with no listed worth was not unlocked at the default 64')
            end
        )

        Declare.test(
            'set_unlocked locks an item again',
            function(context)
                -- Arrange
                restore_unlocked(context, 'small-lamp')
                PriceRaffle.set_unlocked('small-lamp', true, 7)

                -- Act
                PriceRaffle.set_unlocked('small-lamp', false)
                local unlocked = PriceRaffle.is_unlocked('small-lamp')
                local value = PriceRaffle.get_unlocked_item_values()['small-lamp']

                -- Assert
                Assert.equal(false, unlocked, 'small-lamp is still unlocked after locking')
                Assert.is_nil(value, 'small-lamp still has a value after locking')
                Assert.equal(0, name_listing_count('small-lamp'), 'small-lamp is still in the name list')
            end
        )

        Declare.test(
            'roll_item_stack returns nothing for a zero budget',
            function()
                -- Act
                local stack = PriceRaffle.roll_item_stack(0, {}, 65536)

                -- Assert
                Assert.is_nil(stack, 'a zero budget rolled a stack')
            end
        )

        Declare.test(
            'roll_item_stack returns a stack the budget can pay for',
            function()
                -- Arrange
                local budget = 1000

                -- Act
                local stack = PriceRaffle.roll_item_stack(budget, {}, 65536)
                local value = PriceRaffle.get_unlocked_item_values()[stack.name]

                -- Assert
                Assert.is_true(stack ~= nil, 'no stack came back for a budget of ' .. budget)
                Assert.is_true(value ~= nil, 'the rolled ' .. tostring(stack.name) .. ' has no value')
                Assert.is_true(value <= budget, 'the rolled ' .. stack.name .. ' is worth ' .. value .. ', above the budget of ' .. budget)
                Assert.is_true(stack.count >= 1, 'the rolled stack is empty')
                Assert.is_true(stack.count * value <= budget, 'the rolled ' .. stack.count .. ' x ' .. stack.name .. ' is worth more than the budget')
            end
        )

        Declare.test(
            'roll_item_stack never returns a blacklisted item',
            function()
                -- Arrange
                local blacklist = {['coal'] = true}

                -- Assert: no single act; each roll of ours must skip the blacklisted name
                for _ = 1, 40 do
                    local stack = PriceRaffle.roll_item_stack(1000, blacklist, 65536)
                    Assert.is_true(stack ~= nil, 'no stack came back while coal was blacklisted')
                    Assert.is_true(stack.name ~= 'coal', 'coal came back from a roll while blacklisted')
                end
            end
        )

        Declare.test(
            'roll_item_stack stays under the value blacklist',
            function()
                -- Arrange
                local value_blacklist = 16

                -- Assert: no single act; every rolled item must sit under the cap
                for _ = 1, 40 do
                    local stack = PriceRaffle.roll_item_stack(65536, {}, value_blacklist)
                    local value = PriceRaffle.get_unlocked_item_values()[stack.name]
                    Assert.is_true(value ~= nil, 'the rolled ' .. tostring(stack.name) .. ' has no value')
                    Assert.is_true(value <= value_blacklist, 'the rolled ' .. stack.name .. ' is worth ' .. value .. ', above the cap of ' .. value_blacklist)
                end
            end
        )

        Declare.test(
            'roll returns nothing without a budget or slot count',
            function()
                -- Act
                local no_budget = PriceRaffle.roll(nil, 3)
                local no_slots = PriceRaffle.roll(100)
                local below_one = PriceRaffle.roll(0.5, 3)

                -- Assert
                Assert.is_nil(no_budget, 'a roll without a budget returned stacks')
                Assert.is_nil(no_slots, 'a roll without a slot count returned stacks')
                Assert.is_nil(below_one, 'a budget that floors to zero returned stacks')
            end
        )

        Declare.test(
            'roll fills the slots within budget',
            function()
                -- Arrange: 100003 is prime, so no listed worth divides it and no slot can spend
                -- the budget down to exactly zero; all four slots always fill
                local budget = 100003
                local max_slots = 4

                -- Act
                local stack_set = PriceRaffle.roll(budget, max_slots)
                local values = PriceRaffle.get_unlocked_item_values()
                local total = 0
                if stack_set then
                    for _, stack in ipairs(stack_set) do
                        total = total + stack.count * values[stack.name]
                    end
                end

                -- Assert
                Assert.is_true(stack_set ~= nil, 'no stack set came back for a budget of ' .. budget)
                Assert.equal(max_slots, #stack_set, 'the roll filled ' .. #stack_set .. ' slots instead of ' .. max_slots)
                Assert.is_true(total > 0, 'the rolled stacks are worth nothing')
                Assert.is_true(total <= budget, 'the rolled stacks are worth ' .. total .. ', above the budget of ' .. budget)
            end
        )

        Declare.test(
            'roll stays within a tight budget',
            function()
                -- Arrange
                local budget = 8

                -- Act
                local stack_set = PriceRaffle.roll(budget, 3)
                local values = PriceRaffle.get_unlocked_item_values()
                local total = 0
                if stack_set then
                    for _, stack in ipairs(stack_set) do
                        total = total + stack.count * values[stack.name]
                    end
                end

                -- Assert
                Assert.is_true(stack_set ~= nil, 'no stack set came back for a budget of ' .. budget)
                Assert.is_true(#stack_set >= 1 and #stack_set <= 3, 'the roll filled ' .. #stack_set .. ' slots, expected 1 to 3')
                Assert.is_true(total > 0, 'the rolled stacks are worth nothing')
                Assert.is_true(total <= budget, 'the rolled stacks are worth ' .. total .. ', above the budget of ' .. budget)
            end
        )
    end
)
