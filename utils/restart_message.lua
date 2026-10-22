-- Builds the statistics message a map posts to Discord when it restarts. The message is sent as a
-- raw embed (Server.to_discord_named_embed_raw), so Discord's markdown applies: sections are bold
-- headings with a bullet list under them, and player names are escaped so they show as typed.
local Core = require 'utils.core'
local format_number = require 'util'.format_number

local Public = {}

local max_award_names = 3

--- Formats a whole number with thousands separators, e.g. 58783 as '58,783'.
function Public.format_count(value)
    return format_number(math.floor(value), false)
end

--- Returns '- label: **value**'.
function Public.statistic(label, value)
    return '- ' .. label .. ': **' .. value .. '**'
end

--- Returns the award line for whoever has the most of `key` in `player_data`, or nil if nobody
-- has any. Players who tie are all named, up to three.
-- @param player_data<table> of {name = string, [key] = number}
-- @param format<function?> formats the value, defaults to format_count
function Public.award(label, player_data, key, format)
    local best = 0
    local names = {}
    for _, data in pairs(player_data) do
        local value = data[key] or 0
        if value > best then
            best = value
            names = {data.name}
        elseif value == best and value > 0 then
            names[#names + 1] = data.name
        end
    end

    if best <= 0 then
        return nil
    end

    local shown = {}
    for i = 1, math.min(#names, max_award_names) do
        shown[i] = Core.sanitise_string_for_discord(names[i])
    end
    local names_text = '**' .. table.concat(shown, ', ') .. '**'
    if #names > max_award_names then
        names_text = names_text .. ' and ' .. (#names - max_award_names) .. ' more'
    end

    return '- ' .. label .. ': ' .. names_text .. ' (' .. (format or Public.format_count)(best) .. ')'
end

--- Returns the message: the title, then each section with a bold heading. A section is
-- {name = string, lines = {string...}}; one without lines, such as awards nobody earned, is left
-- out. `footer` goes last, after a blank line. The lines are joined with an escaped newline, as
-- Server.to_discord_* expects.
function Public.build(title, sections, footer)
    local out = {title}
    for _, section in ipairs(sections) do
        if #section.lines > 0 then
            out[#out + 1] = ''
            out[#out + 1] = '**' .. section.name .. '**'
            for _, line in ipairs(section.lines) do
                out[#out + 1] = line
            end
        end
    end
    if footer then
        out[#out + 1] = ''
        out[#out + 1] = footer
    end

    return table.concat(out, '\\n')
end

return Public
