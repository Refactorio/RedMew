--
-- Created for RedMew (redmew.com) by der-dave (der-dave.com) @ 18.11.2018 17:23 via IntelliJ IDEA
-- Many thanks to Linaori and the Diggy scenario for inspiring me coding like this
-- Also many thanks to Valansch and grilledham showing me how to use RedMew framework
-- And, of course, greetings to the whole RedMew community. It´s a pleasure <3
--

local Config = {
    -- which track to drive, must be placed in 'tracks' directory!
    track = require 'map_gen.combined.racetrack.tracks.classic',

    -- how many players are needed to start the game? when this number is reached, the timer "time_to_start" is started (1 player would be useless ;) )
    players_to_start = 2,

    -- how many seconds to wait until game starts? (during this countdown new players can connect, countdown will be
    -- reset to this value after one player connected)
    time_to_start = 60,

    -- 1 - 100; the higher this value, the more coins are placed on track and more items could be placed by players on track
    coin_chance = 2,            -- TODO should also be calculated by number of players

    -- the zoom level which all players are using when driving on track
    player_zoom = 1.0,

    -- how many rounds need to be done until game ends?
    rounds = 1
}

return Config