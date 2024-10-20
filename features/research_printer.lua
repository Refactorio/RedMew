local Event = require 'utils.event'
local Server = require 'features.server'

local to_discord_bold = Server.to_discord_bold
local config = storage.config.research_printer
local template = {'research_printer.research_finished', nil}

local function research_finished(event)
    if config.ignore_script and event.by_script then
        return
    end

    local research = event.research
    local research_name = research.name
    local force = research.force

    if config.print_to_force then
        template[2] = research_name
        force.print(template)
    end

    if config.print_to_discord and force.name == 'player' then
        to_discord_bold(research_name .. ' has been researched.')
    end
end

Event.add(defines.events.on_research_finished, research_finished)
