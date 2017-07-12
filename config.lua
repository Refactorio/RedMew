Event.register(-1, function()
    global.scenario = {}
    global.scenario.variables = {}
    global.scenario.variables.time_set_moment = 0
    global.scenario.variables.current_month = 1
    global.scenario.variables.current_day = 1
    global.scenario.variables.current_h = 0
    global.scenario.variables.current_m = 0
    global.scenario.variables.days_passed = 0
    global.scenario.config = {}
    global.scenario.config.announcements_enabled = false -- if true announcements will be shown
    global.scenario.config.announcement_delay = 1000 -- number of seconds between each announcement
    global.scenario.config.score_delay = 8 -- delay in seconds before hiding rocket score window (0 = never show)
    global.scenario.config.autolaunch_default = false -- default autolaunch option
    global.scenario.config.logistic_research_enabled = true -- if true then research for requesters and active providers will be enabled.
    global.scenario.config.mapsettings = global.scenario.config.mapsettings or {}
    global.scenario.config.mapsettings.cross_width = 200 -- total width of cross
    global.scenario.config.mapsettings.spiral_land_width = 70 -- width of land in spiral
    global.scenario.config.mapsettings.spiral_water_width = 70 -- width of water in spiral
    global.scenario.custom_functions = {}
    global.scenario.config.nuke_min_time_hours = 3 --how long a player must be on the server to be allowed to use the nuke
end)
