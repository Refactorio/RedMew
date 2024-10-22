local Public = {}

Public.enabled = function()
  return script.active_mods['space-age'] ~= nil
end

return Public