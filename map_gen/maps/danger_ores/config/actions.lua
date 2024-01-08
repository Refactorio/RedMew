-- defines.input_action listed at https://lua-api.factorio.com/latest/defines.html#defines.input_action

return {
  ['no-blueprints'] = {
    [defines.input_action.import_blueprint] = false,
    [defines.input_action.import_blueprint_string] = false,
    [defines.input_action.import_blueprints_filtered] = false,
    [defines.input_action.import_permissions_string] = false,
    [defines.input_action.open_blueprint_library_gui] = false,
    [defines.input_action.open_blueprint_record] = false,
    [defines.input_action.upgrade_opened_blueprint_by_record] = false,
  },
  ['no-handcraft'] = {
    [defines.input_action.craft] = false,
  }
}
