local ModCompatibility = require 'utils.mod_compatibility'
local ScenarioInfo = require 'features.gui.info'

ModCompatibility.check {
    dependencies = {{ name = 'mine-sweeper' }}
}

ScenarioInfo.set_map_name('Minesweeper')
ScenarioInfo.set_map_description('Minesweeper - in Factorio!')
ScenarioInfo.set_map_extra_info([[
    Use [color=128,206,240][font=default-semibold]SHIFT + M[/font][/color] to use the Minesweeper tools!

    Unlimited lives, but stepping on a hidden mine triggers a nuclear explosion — walk carefully!
    Un-flagging incorrectly flagged empty tiles will reveal a small biter nest surprise.
    Correctly marking mine tiles (flagging real mines) rewards the player by spawning resources.

    Good luck, and may your wits guide you through the minefield!
    The [color=red]RedMew[/color] team
]])
ScenarioInfo.set_new_info([[
    2026-01-22
        Updated scenario to mod
]])

local Config = require 'config'
Config.market.enabled = false
Config.redmew_surface.enabled = false
Config.player_rewards.enabled = false
Config.player_shortcuts.enabled = true
Config.player_create.starting_items = {
    {  count =   4, name = 'burner-inserter' },
    {  count =   4, name = 'burner-mining-drill' },
    {  count =   2, name = 'stone-furnace' },
    {  count =  20, name = 'coal' },
    {  count =   1, name = 'pistol' },
    {  count =  32, name = 'firearm-magazine' },
    {  count =  20, name = 'wood' },
}
