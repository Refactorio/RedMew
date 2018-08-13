local Gui = require("utils.gui")
local Utils = require("utils.utils");
local report_frame_name = Gui.uid_name()
local report_close_button_name = Gui.uid_name()
local report_tab_button_name = Gui.uid_name()
local report_body_name = Gui.uid_name()
global.reports = {}
global.player_report_data = {}



local function draw_report(parent, report_id)
    local report = global.reports[report_id]
    local reported_player_name = game.players[report.reported_player_index].name
    local reporting_player_name = game.players[report.reporting_player_index].name
    local time = Utils.format_time(report.tick)
    local time_ago = Utils.format_time(game.tick - report.tick)

    local message = report.message
    for _,child in pairs(parent.children) do
        Gui.remove_data_recursivly(child)
        child.destroy() 
    end

    parent.add {type="label", caption="Offender: " .. reported_player_name} 
    local msg_label = parent.add {type="label", caption="Message: " .. message}
    msg_label.style.single_line = false
    msg_label.style.maximal_width = 680
    parent.add {type="label", caption=string.format("Time: %s (%s ago)", time, time_ago)} 
    parent.add {type="label", caption="Reported by: " .. reporting_player_name}
end

local function show_reports(player)
    local reports = global.reports or {}

    local center = player.gui.center
    if player.opened then --Destroy whatever is open
        Gui.remove_data_recursivly(player.opened)
        player.opened.destroy()
    end
  
  
    report_frame =
        center.add {
            type = 'frame',
            name = report_frame_name,
            direction = 'vertical',
            caption = 'User reports'
        }
        report_frame.style.maximal_width = 700
        player.opened = report_frame

    local scroll_pane = report_frame.add{type = "scroll-pane", horizontal_scroll_policy = "auto-and-reserve-space", vertical_scroll_policy="never"}
    local tab_flow = scroll_pane.add{type="flow"}
    for k,report in pairs(reports) do
        local button_cell = tab_flow.add{type="flow", caption="reportuid" .. k}
        button_cell.add {
            type="button", 
            name=report_tab_button_name, 
            caption = game.players[report.reporting_player_index].name
        }
        end

    local report_body = report_frame.add {type = "scroll-pane", name = report_body_name, horizontal_scroll_policy = "never", vertical_scroll_policy="never"}
    report_frame.add {type = 'button', name = report_close_button_name, caption = 'Close'}

    draw_report(report_body, #reports)
end

local function report(reporting_player, reported_player, message)
    table.insert(global.reports, {reporting_player_index = reporting_player.index, reported_player_index = reported_player.index, message = message, tick = game.tick})

    local notified = false
    for _,p in pairs(game.players) do
        if p.admin and p.connected then
            show_reports(p)
            if p.afk_time < 3600 then notified = true end
        end
    end
    if not notified then
        for _,p in pairs(game.players) do
            if p.admin then
                show_reports(p) 
            end
        end
    end
end

Gui.on_custom_close(
    report_frame_name,
    function(event)
        Gui.remove_data_recursivly(event.element)
        event.element.destroy()
    end
)

Gui.on_click(
    report_close_button_name,
    function(event)
        Gui.remove_data_recursivly(event.element)
        event.element.parent.destroy()
    end
)

Gui.on_click(
    report_tab_button_name,
    function(event)
        local center = event.player.gui.center
        local report_frame = center[report_frame_name]
        local report_uid_str = string.sub(event.element.parent.caption, 10)
        local report_uid = tonumber(report_uid_str)
        draw_report(report_frame[report_body_name], report_uid)
    end
)

local function report_cmd(cmd)
    if game.player then
        local params = {}
        for param in string.gmatch(cmd.parameter, '%S+') do
            table.insert(params, param)
        end
        if #params < 2 then
            game.player.print("Please enter then name of the offender and the reason for the report.")
            return nil
        end
        if not game.players[params[1]] then
            game.player.print(params[1] .. " does not exist.")
            return nil
        end
        report(game.player, game.players[params[1]], string.sub(cmd.parameter, string.len(params[1]) + 2))
    end
end

commands.add_command('report', '<griefer-name> <message> Reports a user to admins', report_cmd)
commands.add_command('showreports', 'Shows user reports (Admins only)', 
	function(event) 
		if game.player and game.player.admin then 
            show_reports(game.players[event.player_index]) 
        end
    end
)
