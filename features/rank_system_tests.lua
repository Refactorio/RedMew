-- In-game tests for the rank system: setting ranks, moving up and down the hierarchy, the
-- comparison helpers, and resets. They run on every map, as features.rank_system is always
-- loaded (control.lua). Ranks are stored by player name, so the tests use a made-up name and
-- never need a real player, headless included. The rank values come from resources.ranks; the
-- tests assume everyone_is_regular is false, the shipped default, else every name reads regular.
local Declare = require 'utils.test.declare'
local Assert = require 'utils.test.assert'
local Rank = require 'features.rank_system'
local Ranks = require 'resources.ranks'

local NAME = 'rank system tests'

Declare.module(
    {'features', 'rank_system'},
    function()
        Declare.module_teardown(
            function()
                -- forget the test player, wherever the last test left it
                Rank.set_player_rank(NAME, Ranks.guest)
            end
        )

        Declare.test(
            'a set rank is read back by get_player_rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.moderator)

                -- Act
                local rank = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(Ranks.moderator, rank, 'the moderator rank was not read back')
            end
        )

        Declare.test(
            'a rank is recorded in the player table',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local recorded = Rank.get_player_table()[NAME]

                -- Assert
                Assert.equal(Ranks.regular, recorded, 'the regular rank is not in the player table')
            end
        )

        Declare.test(
            'know_player is false for an unranked name',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.guest)

                -- Act
                local known = Rank.know_player(NAME)

                -- Assert
                Assert.equal(false, known, 'an unranked name is known')
            end
        )

        Declare.test(
            'know_player is true once a rank is set',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local known = Rank.know_player(NAME)

                -- Assert
                Assert.is_true(known, 'a name with a rank is not known')
            end
        )

        Declare.test(
            'setting the rank a player already has fails',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.moderator)

                -- Act
                local ok = Rank.set_player_rank(NAME, Ranks.moderator)

                -- Assert
                Assert.equal(false, ok, 'setting the same rank again reported success')
            end
        )

        Declare.test(
            'demoting a player to guest forgets them',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.moderator)

                -- Act
                local ok = Rank.set_player_rank(NAME, Ranks.guest)
                local known = Rank.know_player(NAME)

                -- Assert
                Assert.is_true(ok, 'the demotion to guest reported failure')
                Assert.equal(false, known, 'the demoted player is still known')
            end
        )

        Declare.test(
            'increase moves one rank up',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.auto_trusted)

                -- Act
                local new_rank_name = Rank.increase_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(Ranks.regular, after, 'the rank did not move from auto_trusted to regular')
                Assert.table_equal(Rank.get_rank_name(Ranks.regular), new_rank_name, 'increase did not report the new rank name')
            end
        )

        Declare.test(
            'increase at the top rank does nothing',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.admin)

                -- Act
                local new_rank_name = Rank.increase_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.is_nil(new_rank_name, 'increasing the top rank reported a new rank name')
                Assert.equal(Ranks.admin, after, 'the top rank moved up')
            end
        )

        Declare.test(
            'decrease moves one rank down',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local new_rank_name = Rank.decrease_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(Ranks.auto_trusted, after, 'the rank did not move from regular to auto_trusted')
                Assert.table_equal(Rank.get_rank_name(Ranks.auto_trusted), new_rank_name, 'decrease did not report the new rank name')
            end
        )

        Declare.test(
            'decrease at the bottom rank does nothing',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.probation)

                -- Act
                local new_rank_name = Rank.decrease_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.is_nil(new_rank_name, 'decreasing the bottom rank reported a new rank name')
                Assert.equal(Ranks.probation, after, 'the bottom rank moved down')
            end
        )

        Declare.test(
            'increase_to raises a player to the given rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.guest)

                -- Act
                local ok, rank_name = Rank.increase_player_rank_to(NAME, Ranks.moderator)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.is_true(ok, 'increase_to refused to raise a guest')
                Assert.equal(Ranks.moderator, after, 'the guest was not raised to moderator')
                Assert.table_equal(Rank.get_rank_name(Ranks.moderator), rank_name, 'increase_to did not report the new rank name')
            end
        )

        Declare.test(
            'increase_to refuses to lower a rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local ok = Rank.increase_player_rank_to(NAME, Ranks.auto_trusted)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(false, ok, 'increase_to lowered a higher rank')
                Assert.equal(Ranks.regular, after, 'increase_to changed the rank it refused')
            end
        )

        Declare.test(
            'decrease_to lowers a player to the given rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local ok, rank_name = Rank.decrease_player_rank_to(NAME, Ranks.auto_trusted)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.is_true(ok, 'decrease_to refused to lower a regular')
                Assert.equal(Ranks.auto_trusted, after, 'the regular was not lowered to auto_trusted')
                Assert.table_equal(Rank.get_rank_name(Ranks.auto_trusted), rank_name, 'decrease_to did not report the new rank name')
            end
        )

        Declare.test(
            'decrease_to refuses to raise a rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.guest)

                -- Act
                local ok = Rank.decrease_player_rank_to(NAME, Ranks.moderator)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(false, ok, 'decrease_to raised a lower rank')
                Assert.equal(Ranks.guest, after, 'decrease_to changed the rank it refused')
            end
        )

        Declare.test(
            'reset sends a ranked player back to guest',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local ok, rank_name = Rank.reset_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)
                local known = Rank.know_player(NAME)

                -- Assert: the name was never online, so reset lands on guest, not auto_trusted
                Assert.is_true(ok, 'resetting a ranked player reported failure')
                Assert.equal(Ranks.guest, after, 'the player was not reset to guest')
                Assert.equal(false, known, 'the reset player is still known')
                Assert.table_equal(Rank.get_rank_name(Ranks.guest), rank_name, 'reset did not report the rank name')
            end
        )

        Declare.test(
            'resetting a guest player fails',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.guest)

                -- Act
                local ok = Rank.reset_player_rank(NAME)
                local after = Rank.get_player_rank(NAME)

                -- Assert
                Assert.equal(false, ok, 'resetting a guest reported success')
                Assert.equal(Ranks.guest, after, 'the guest rank changed')
            end
        )

        Declare.test(
            'equal and not_equal match only the exact rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local equal_own = Rank.equal(NAME, Ranks.regular)
                local equal_other = Rank.equal(NAME, Ranks.moderator)
                local not_equal_own = Rank.not_equal(NAME, Ranks.regular)
                local not_equal_other = Rank.not_equal(NAME, Ranks.moderator)

                -- Assert
                Assert.equal(true, equal_own, 'equal did not match the set rank')
                Assert.equal(false, equal_other, 'equal matched a different rank')
                Assert.equal(false, not_equal_own, 'not_equal rejected the set rank')
                Assert.equal(true, not_equal_other, 'not_equal did not reject a different rank')
            end
        )

        Declare.test(
            'greater_than and less_than exclude the exact rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local greater_than_own = Rank.greater_than(NAME, Ranks.regular)
                local less_than_own = Rank.less_than(NAME, Ranks.regular)
                local greater_than_guest = Rank.greater_than(NAME, Ranks.guest)
                local less_than_admin = Rank.less_than(NAME, Ranks.admin)

                -- Assert
                Assert.equal(false, greater_than_own, 'greater_than matched the exact rank')
                Assert.equal(false, less_than_own, 'less_than matched the exact rank')
                Assert.is_true(greater_than_guest, 'greater_than did not match a lower rank')
                Assert.is_true(less_than_admin, 'less_than did not match a higher rank')
            end
        )

        Declare.test(
            'equal_or_greater_than and equal_or_less_than include the exact rank',
            function()
                -- Arrange
                Rank.set_player_rank(NAME, Ranks.regular)

                -- Act
                local eog_own = Rank.equal_or_greater_than(NAME, Ranks.regular)
                local eol_own = Rank.equal_or_less_than(NAME, Ranks.regular)
                local eog_admin = Rank.equal_or_greater_than(NAME, Ranks.admin)
                local eol_probation = Rank.equal_or_less_than(NAME, Ranks.probation)

                -- Assert
                Assert.is_true(eog_own, 'equal_or_greater_than rejected the exact rank')
                Assert.is_true(eol_own, 'equal_or_less_than rejected the exact rank')
                Assert.equal(false, eog_admin, 'equal_or_greater_than matched a higher rank')
                Assert.equal(false, eol_probation, 'equal_or_less_than matched a lower rank')
            end
        )
    end
)
