local Module = {}

local Gui = require("utils.gui")
local Utils = require("utils.utils");
local Game = require 'utils.game'
local report_frame_name = Gui.uid_name()
local report_close_button_name = Gui.uid_name()
local report_tab_button_name = Gui.uid_name()
local report_body_name = Gui.uid_name()

global.reports = {}
global.player_report_data = {}



local function draw_report(parent, report_id)
    local report = global.reports[report_id]
    if report_id == 0 or not report then
        parent.add {type = "label", caption="No reports yet."}
        return
    end
    local reported_player_name = Game.get_player_by_index(report.reported_player_index).name
    local reporting_player_name = Game.get_player_by_index(report.reporting_player_index).name
    local time = Utils.format_time(report.tick)
    local time_ago = Utils.format_time(game.tick - report.tick)

    local message = report.message
    Gui.clear(parent)

    parent.add {type="label", caption="Offender: " .. reported_player_name} 
    local msg_label_pane = parent.add {type="scroll-pane", vertical_scroll_policy = "auto-and-reserve-space", horizontal_scroll_policy="never"}
    msg_label_pane.style.maximal_height = 400
    local msg_label = msg_label_pane.add {type="label", caption="Message: " .. message}
    msg_label.style.single_line = false
    msg_label.style.maximal_width = 680
    parent.add {type="label", caption=string.format("Time: %s (%s ago)", time, time_ago)} 
    parent.add {type="label", caption="Reported by: " .. reporting_player_name}
end

Module.show_reports = function(player)
    local reports = global.reports or {}

    local center = player.gui.center

    local report_frame = center[report_frame_name]
    if report_frame and report_frame.valid then 
        Gui.destroy(report_frame)
    end
    
    report_frame = center.add {
        type = 'frame',
        name = report_frame_name,
        direction = 'vertical',
        caption = 'User reports'
    }
    report_frame.style.maximal_width = 700
    player.opened = report_frame
    
    if #reports > 1 then
        local scroll_pane = report_frame.add{type = "scroll-pane", horizontal_scroll_policy = "auto-and-reserve-space", vertical_scroll_policy="never"}
        local tab_flow = scroll_pane.add{type="flow"}
        for k,report in pairs(reports) do
            local button_cell = tab_flow.add{type="flow", caption="reportuid" .. k}
            button_cell.add {
                type="button", 
                name=report_tab_button_name, 
                caption = Game.get_player_by_index(report.reported_player_index).name
            }
        end
    end
    local report_body = report_frame.add {type = "scroll-pane", name = report_body_name, horizontal_scroll_policy = "never", vertical_scroll_policy="never"}
    report_frame.add {type = 'button', name = report_close_button_name, caption = 'Close'}
 
    draw_report(report_body, #reports)
end

function Module.report(reporting_player, reported_player, message)
    table.insert(global.reports, {reporting_player_index = reporting_player.index, reported_player_index = reported_player.index, message = message, tick = game.tick})

    local notified = false
    for _,p in pairs(game.players) do
        if p.admin and p.connected then
            Module.show_reports(p)
            if p.afk_time < 3600 then notified = true end
        end
    end
    if not notified then
        for _,p in pairs(game.players) do
            if p.admin then
                Module.show_reports(p) 
            end
        end
    end
end

Gui.on_custom_close(
    report_frame_name,
    function(event)
        Gui.destroy(event.element)
    end
)

Gui.on_click(
    report_close_button_name,
    function(event)
        Gui.destroy(event.element.parent)
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


local reporting_popup_name = Gui.uid_name()
local reporting_cancel_button_name = Gui.uid_name()
local reporting_submit_button_name = Gui.uid_name()
local reporting_input_name = Gui.uid_name()

Module.spawn_reporting_popup = function(player, reported_player)

    local center = player.gui.center    
  
    local reporting_popup = center[reporting_popup_name]
    if reporting_popup and reporting_popup.valid then 
        Gui.destroy(reporting_popup)
    end
    reporting_popup = center.add {
        type = 'frame',
        name = reporting_popup_name,
        direction = 'vertical',
        caption = 'Report player ' .. reported_player.name
    }
    Gui.set_data(reporting_popup, {reported_player_index = reported_player.index})

    reporting_popup.style.maximal_width = 500
    player.opened = reporting_popup
    reporting_popup.add {
        type = 'label',
        caption = 'Report message:'
    } 
    local input = reporting_popup.add {type = 'text-box', name=reporting_input_name}
    input.style.width = 400 
    input.style.height = 85
    local button_flow = reporting_popup.add {type = "flow"}
    local submit_button = button_flow.add {type = "button", name = reporting_submit_button_name, caption="Submit"}
    button_flow.add {type = "button", name = reporting_cancel_button_name, caption="Cancel"}

end

Gui.on_custom_close(
    reporting_popup_name,
    function(event) 
        Gui.destroy(event.element)
    end
)

Gui.on_click(
    reporting_cancel_button_name,
    function(event)
        local frame = event.element.parent.parent
        Gui.destroy(frame)
    end
)

Gui.on_click(
    reporting_submit_button_name,
    function(event)
        local frame = event.element.parent.parent
        local msg = frame[reporting_input_name].text
        local data = Gui.get_data(frame)
        local reported_player_index = data["reported_player_index"]
        
        Gui.destroy(frame)
        Module.report(event.player, Game.get_player_by_index(reported_player_index), msg)
        
        event.player.print("Sucessfully reported " .. Game.get_player_by_index(reported_player_index).name)
    end
)

return Module
