local Command = require 'utils.command'
local Event = require 'utils.event'
local Ranks = require 'resources.ranks'
local Global = require 'utils.global'

local data = {
  initialized_permissions = false,
}

Global.register(data, function(tbl)
  data = tbl
end)

local config = global.config.permissions
local Public = {}

-- defines.input_action listed at https://lua-api.factorio.com/latest/defines.html#defines.input_action
local DEFAULT_PRESETS_ACTIONS = {
  no_blueprints = {
    [defines.input_action.import_blueprint] = false,
    [defines.input_action.import_blueprint_string] = false,
    [defines.input_action.import_blueprints_filtered] = false,
    [defines.input_action.import_permissions_string] = false,
    [defines.input_action.open_blueprint_library_gui] = false,
    [defines.input_action.open_blueprint_record] = false,
    [defines.input_action.upgrade_opened_blueprint_by_record] = false,
  },
  no_handcraft= {
    [defines.input_action.craft] = false,
  }
}

for name, actions in pairs(DEFAULT_PRESETS_ACTIONS) do
  config.modes[name] = config.modes[name] or actions
end

---Returns config.preset.any(true)
---@return boolean
function Public.any_preset()
  for name, mode in pairs(config.presets or {}) do
    if mode and config.modes[name] ~= nil then return true end
  end
  return false
end

---Requires enabled=true and at least 1 (not nil) preset to be enabled to be true
---@return boolean
function Public.enabled()
  return config.enabled and Public.any_preset()
end

---Sets all permissions for the "Default" group to true
function Public.reset_all_permissions()
  local Default = game.permissions.get_group("Default")

  for _, action_ID in pairs(defines.input_action) do
    Default.set_allows_action(action_ID, true)
  end
end

---Sets permissions for the "Default" group
---@param params config.permissions
function Public.set_permissions(params)
  if params then
    for name, actions in pairs(params.modes or {}) do
      config.modes[name] = actions
    end

    for name, is_enabled in pairs(params.presets or {}) do
      config.presets[name] = is_enabled
    end
  end

  local Default = game.permissions.get_group("Default")

  for name, actions in pairs(config.modes or {}) do
    if config.presets[name] then
      for action, is_allowed in pairs(actions or {}) do
        Default.set_allows_action(action, is_allowed)
      end
    end
  end
end

---Init permissions
Event.on_init(function()
  if not data.initialized_permissions
    and Public.enabled()
  then
    Public.set_permissions()
    data.initialized_permissions = true
  end
end)

---Init permissions for multiplayer servers
Event.add(defines.events.on_player_joined_game, function()
  if not data.initialized_permissions
    and Public.any_preset()
    and table_size(game.connected_players) > 1
  then
    Public.set_permissions()
    data.initialized_permissions = true
  end
end)

---Use "/permissions-reset" to reset all players' permissions to default for the "Default" group (admin/server only)
Command.add(
  'permissions-reset',
  {
    description = {'command_description.permissions_reset'},
    arguments = {},
    required_rank = Ranks.admin,
    allowed_by_server = true
  },
  function()
    Public.reset_all_permissions()
  end
)

---Use "/permissions-set-scenario" to reapply scenario's permissions, if any, for the "Default" group (admin/server only)
Command.add(
  'permissions-set-scenario',
  {
    description = {'command_description.permissions_set_scenario'},
    arguments = {},
    required_rank = Ranks.admin,
    allowed_by_server = true
  },
  function()
    Public.set_permissions()
  end
)

return Public
