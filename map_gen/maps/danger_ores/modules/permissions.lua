local Event = require 'utils.event'

return function(config)

  local function init_default_permissions()
    local Default = game.permissions.get_group("Default")

    for action, allow_action in pairs(config.permissions or {}) do
      Default.set_allows_action(action, allow_action)
    end
  end

  Event.on_init(init_default_permissions)
end
