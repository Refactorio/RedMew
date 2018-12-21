_DUMP_ENV = true

global.config = {
    map_info = {
        map_name_key = 'No name',
        map_description_key = "No description",
        map_extra_info_key = 'No info',
        new_info_key = 'Nothing new',
    },
}

require 'features.gui.info'

if _DUMP_ENV then
    require 'utils.dump_env'
end
