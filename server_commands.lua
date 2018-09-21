local Poll = require 'poll'

local Public = {}

function Public.get_poll_result(id)
    Poll.send_poll_result_to_discord(id)
end

return Public
