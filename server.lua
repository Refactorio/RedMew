local Public = {}

local discord_tag = '[DISCORD]'
local discord_raw_tag = '[DISCORD-RAW]'
local discord_admin_tag = '[DISCORD-ADMIN]'
local discord_admin_raw_tag = '[DISCORD-ADMIN-RAW]'
local discord_embed_tag = '[DISCORD-EMBED]'
local discord_embed_raw_tag = '[DISCORD-EMBED-RAW]'
local discord_admin_embed_tag = '[DISCORD-ADMIN-EMBED]'
local discord_admin_embed_raw_tag = '[DISCORD-ADMIN-EMBED-RAW]'
local regular_promote_tag = '[REGULAR-PROMOTE]'
local regular_deomote_tag = '[REGULAR-DEOMOTE]'

function Public.to_discord(message)
    print(discord_tag .. message)
end

function Public.to_discord_raw(message)
    print(discord_raw_tag .. message)
end

function Public.to_admin(message)
    print(discord_admin_tag .. message)
end

function Public.to_admin_raw(message)
    print(discord_admin_raw_tag .. message)
end

function Public.to_discord_embed(message)
    print(discord_embed_tag .. message)
end

function Public.to_discord_embed_raw(message)
    print(discord_embed_raw_tag .. message)
end

function Public.to_admin_embed(message)
    print(discord_admin_embed_tag .. message)
end

function Public.to_admin_embed_raw(message)
    print(discord_admin_embed_raw_tag .. message)
end

function Public.regular_promote(target, promotor)
    local message = table.concat {regular_promote_tag, target, ' ', promotor or ''}
    print(message)
end

function Public.regular_deomote(target)
    print(regular_deomote_tag .. target)
end

return Public
