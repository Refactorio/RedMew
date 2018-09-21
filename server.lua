local Public = {}

local discord_tag = '[CHAT]'
local discord_raw_tag = '[CHAT-RAW]'
local discord_admin_tag = '[ADMIN]'
local discord_embed_tag = '[EMBED]'

function Public.to_discord(message)
    print(discord_tag .. message)
end

function Public.to_discord_raw(message)
    print(discord_raw_tag .. message)
end

function Public.to_admin(message)
    print(discord_admin_tag .. message)
end

function Public.to_discord_embed(message)
    print(discord_embed_tag .. message)
end

return Public
