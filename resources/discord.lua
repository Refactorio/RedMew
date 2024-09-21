--- Resources for use in interacting with discord.
return {
    --- The names of the discord channels that can be referenced by name.
    -- See features.server.to_discord_named
    channel_names = {
        bot_playground = 'bot-playground',
        map_promotion = 'map-promotion',
        moderation_log = 'moderation-log',
        helpdesk = 'helpdesk',
        danger_ores = 'danger-ores',
        crash_site = 'crash-site',
        events = 'events',
        frontier = 'frontier',
    },
    --- The strings that mention the discord role.
    -- Has to be used with features.server.to_discord_raw variants else the mention is sanitized server side.
    role_mentions = {
        test = '<@&593534612051984431>',
        crash_site = '<@&762441731194748958>',
        danger_ore = '<@&793231011144007730>',
        moderator = '<@&454192594633883658>',
        diggy = '<@&921476458076061718>',
        map_update = '<@&486532533220147203>',
        frontier = '<@&1274494225953591370>',
    }
}
