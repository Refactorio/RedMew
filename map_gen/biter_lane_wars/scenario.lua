--[[
    Everything in this project should be considered pseudocode at the moment. Theere is no functionality.
    readme.md contains the general idea for the scenario and each file contains a todo list
]]

-- This just sets up some framework and loads the Biter Lane Wars scenario.
-- To make any changes, you want config.lua located in the same directory as this file.

if not global.map then
    global.map = {}
end
if not global.map.blw then
    global.map.blw = {}
end
if not global.map.blw.config then
    global.map.blw.config = {}
end
if not global.map.blw.teams then
    global.map.blw.teams = {}
end

local BLW = global.map.blw

-- path to the BLW folder, to make it easy to potentially move in the future
-- ex: require = global.map.bwl.filepath .. 'features.gui'
BLW.filepath = 'map_gen.biter_lane_wars.'

require = BLW.filepath .. 'config'
require = BLW.filepath .. 'biter_lane_wars'
