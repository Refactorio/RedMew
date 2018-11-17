local Public = {}

local raw_print = print
function print(str)
    raw_print('[PRINT] ' .. str)
end

local discord_tag = '[DISCORD]'
local discord_raw_tag = '[DISCORD-RAW]'
local discord_bold_tag = '[DISCORD-BOLD]'
local discord_admin_tag = '[DISCORD-ADMIN]'
local discord_admin_raw_tag = '[DISCORD-ADMIN-RAW]'
local discord_embed_tag = '[DISCORD-EMBED]'
local discord_embed_raw_tag = '[DISCORD-EMBED-RAW]'
local discord_admin_embed_tag = '[DISCORD-ADMIN-EMBED]'
local discord_admin_embed_raw_tag = '[DISCORD-ADMIN-EMBED-RAW]'
local regular_promote_tag = '[REGULAR-PROMOTE]'
local regular_deomote_tag = '[REGULAR-DEOMOTE]'
local donator_set_tag = '[DONATOR-SET]'
local start_scenario_tag = '[START-SCENARIO]'

Public.raw_print = raw_print

function Public.to_discord(message)
    raw_print(discord_tag .. message)
end

function Public.to_discord_raw(message)
    raw_print(discord_raw_tag .. message)
end

function Public.to_discord_bold(message)
    raw_print(discord_bold_tag .. message)
end

function Public.to_admin(message)
    raw_print(discord_admin_tag .. message)
end

function Public.to_admin_raw(message)
    raw_print(discord_admin_raw_tag .. message)
end

function Public.to_discord_embed(message)
    raw_print(discord_embed_tag .. message)
end

function Public.to_discord_embed_raw(message)
    raw_print(discord_embed_raw_tag .. message)
end

function Public.to_admin_embed(message)
    raw_print(discord_admin_embed_tag .. message)
end

function Public.to_admin_embed_raw(message)
    raw_print(discord_admin_embed_raw_tag .. message)
end

function Public.regular_promote(target, promotor)
    local control_message = table.concat {regular_promote_tag, target, ' ', promotor}
    local discord_message = table.concat {discord_bold_tag, promotor .. ' promoted ' .. target .. ' to regular.'}

    raw_print(control_message)
    raw_print(discord_message)
end

function Public.regular_deomote(target, demotor)
    local discord_message = table.concat {discord_bold_tag, target, ' was demoted from regular by ', demotor, '.'}

    raw_print(regular_deomote_tag .. target)
    raw_print(discord_message)
end

function Public.donator_set(target, perks)
    perks = perks or 'nil'

    local message = table.concat {donator_set_tag, target, ' ', perks}

    raw_print(message)
end

function Public.start_scenario(scenario_name)
    local message = start_scenario_tag

    if type(scenario_name) == 'string' then
        message = message .. scenario_name
    end

    raw_print(message)
end

return Public
