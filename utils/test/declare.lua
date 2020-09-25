local ModuleStore = require 'utils.test.module_store'

local Public = {}

Public.module = ModuleStore.module
Public.test = ModuleStore.test
Public.module_startup = ModuleStore.module_startup
Public.module_teardown = ModuleStore.module_teardown

return Public
