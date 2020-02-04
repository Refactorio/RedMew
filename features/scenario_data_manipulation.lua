local Server = require 'features.server'
local Token = require 'utils.token'
local Command = require 'utils.command'
local Global = require 'utils.global'
local Ranks = require 'resources.ranks'
local table = require 'utils.table'

local primitives = {
    copy = nil,
    delete = nil,
    new_dataset = nil,
    lockout = nil
}

Global.register(
    {
        primitives = primitives
    },
    function(tbl)
        primitives = tbl.primitives
    end
)

--- Clears primitives
local function clear_primitives()
    primitives.copy = nil
    primitives.delete = nil
    primitives.new_dataset = nil
    primitives.lockout = nil
end

--- Writes entries to datasets
local function write_dataset(dataset, entries)
    if not dataset or not entries then
        game.print('Empty entries or dataset (This is usually due to calling the wrong data_set)')
        clear_primitives()
        return
    end

    for k, v in pairs(entries) do
        Server.set_data(dataset, k, v)
    end
end

--- Nils a dataset
local function nil_dataset(dataset, entries)
    if not dataset or not entries then
        game.print('Empty entries or dataset (This is usually due to calling the wrong data_set)')
        clear_primitives()
        return
    end

    for k in pairs(entries) do
        Server.set_data(dataset, k, nil)
    end
end

--- Callback token
local data_callback =
    Token.register(
    function(data)
        local old_dataset = data.data_set
        if not old_dataset then
            game.print('Empty entries (This is usually due to calling the wrong data_set)')
            clear_primitives()
            return
        end

        local entries = data.entries
        if not entries then
            game.print('Empty entries (This is usually due to calling the wrong data_set)')
            clear_primitives()
            return
        end

        if primitives.copy then
            write_dataset(primitives.new_dataset, entries)
        end

        if primitives.delete then
            nil_dataset(old_dataset, entries)
        end

        clear_primitives()
        game.print('Dataset operation complete.')
    end
)

--- Sets parameters to have a dataset copied
local function copy_dataset(args)
    if primitives.lockout then
        game.print('Data processing already in progress.')
        return
    end

    local dataset = args.dataset
    local destination = args.destination
    game.print('Copying: ' .. dataset .. ' to ' .. destination)

    primitives.new_dataset = destination
    primitives.copy = true
    primitives.delete = false
    primitives.lockout = true

    Server.try_get_all_data(dataset, data_callback)
end

--- Sets parameters to have a dataset moved
local function move_dataset(args)
    if primitives.lockout then
        game.print('Data processing already in progress.')
        return
    end

    local dataset = args.dataset
    local destination = args.destination
    game.print('Moving: ' .. dataset .. ' to ' .. destination)

    primitives.new_dataset = destination
    primitives.copy = true
    primitives.delete = true
    primitives.lockout = true

    Server.try_get_all_data(dataset, data_callback)
end

--- Sets parameters to have a dataset deleted
local function delete_dataset(args)
    if primitives.lockout then
        game.print('Data processing already in progress.')
        return
    end

    local dataset = args.dataset
    game.print('Deleting: ' .. dataset)

    primitives.new_dataset = nil
    primitives.copy = false
    primitives.delete = true
    primitives.lockout = true

    Server.try_get_all_data(dataset, data_callback)
end

Command.add(
    'dataset-copy',
    {
        description = {'command_description.dataset_copy'},
        arguments = {'dataset', 'destination'},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    copy_dataset
)

Command.add(
    'dataset-move',
    {
        description = {'command_description.dataset_move'},
        arguments = {'dataset', 'destination'},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    move_dataset
)

Command.add(
    'dataset-delete',
    {
        description = {'command_description.dataset_delete'},
        arguments = {'dataset'},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    delete_dataset
)

--- Callback token
local transform_callback =
    Token.register(
    function(data)
        local entries = data.entries
        if not entries then
            game.print('Empty entries (This is usually due to calling the wrong data_set)')
            clear_primitives()
            return
        end

        local returned_entries = global.transform_function(entries)

        write_dataset(primitives.new_dataset, returned_entries)

        clear_primitives()
        game.print('Transform complete.')
    end
)

--- Takes a data set, transforms it, then copies it.
local function transform_data(args)
    if primitives.lockout then
        game.print('Data processing already in progress.')
        clear_primitives()
        return
    end

    local transform_function = global.transform_function
    if not transform_function then
        game.print('No transform function set')
        clear_primitives()
        return
    end

    if type(transform_function) ~= 'function' then
        game.print('global.transform_function does not contain a function')
        clear_primitives()
        return
    end

    local destination = args.destination
    local dataset = args.dataset
    if destination == dataset then
        game.print('For transforms, you must copy the output to a different dataset')
        clear_primitives()
        return
    end

    game.print('Beginning transform...')
    primitives.new_dataset = args.destination
    primitives.lockout = true
    Server.try_get_all_data(args.dataset, transform_callback)
end

local transform_test_callback =
    Token.register(
    function(data)
        local entries = data.entries
        if not entries then
            game.print('Empty entries (This is usually due to calling the wrong data_set).')
            clear_primitives()
            return
        end

        local transform_function = global.transform_function
        if not transform_function then
            game.print('No transform function set.')
            clear_primitives()
            return
        end

        if type(transform_function) ~= 'function' then
            game.print('global.transform_function does not contain a function.')
            clear_primitives()
            return
        end

        local returned_entries = global.transform_function(entries)

        clear_primitives()

        global.transform_results = returned_entries
        local result_str = table.inspect(returned_entries)
        game.print(result_str)
        log(result_str)
        game.print('Test complete. The results can be better seen in the log or in global.transform_results')
    end
)

local function transform_data_test(args)
    game.print('Testing transform...')
    Server.try_get_all_data(args.dataset, transform_test_callback)
end

Command.add(
    'dataset-transform',
    {
        description = {'command_description.dataset_transform'},
        arguments = {'dataset', 'destination'},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    transform_data
)

Command.add(
    'dataset-transform-test',
    {
        description = {'command_description.dataset_transform_test'},
        arguments = {'dataset'},
        required_rank = Ranks.admin,
        debug_only = true,
        allowed_by_server = true
    },
    transform_data_test
)
