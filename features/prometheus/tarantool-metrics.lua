#!/usr/bin/env tarantool

local prometheus = require('tarantool-prometheus')

local memory_limit_bytes = prometheus.gauge(
    'tarantool_memory_limit_bytes',
    'Maximum amount of memory Tarantool can use')
local memory_used_bytes = prometheus.gauge(
    'tarantool_memory_used_bytes',
    'Amount of memory currently used by Tarantool')
local tuples_memory_bytes = prometheus.gauge(
    'tarantool_tuples_memory_bytes',
    'Amount of memory allocated for Tarantool tuples')
local system_memory_bytes = prometheus.gauge(
    'tarantool_system_memory_bytes',
    'Amount of memory used by Tarantool indexes and system')

local requests_total = prometheus.gauge(
    'tarantool_requests_total',
    'Total number of requests by request type',
    {'request_type'})

local uptime_seconds = prometheus.gauge(
    'tarantool_uptime_seconds',
    'Number of seconds since the server started')

local tuples_total = prometheus.gauge(
    'tarantool_space_tuples_total',
    'Total number of tuples in a space',
    {'space_name'})


local function measure_tarantool_memory_usage()
    local slabs = box.slab.info()
    local memory_limit = slabs.quota_size
    local memory_used = slabs.quota_used
    local tuples_memory = slabs.arena_used
    local system_memory = memory_used - tuples_memory

    memory_limit_bytes:set(memory_limit)
    memory_used_bytes:set(memory_used)
    tuples_memory_bytes:set(tuples_memory)
    system_memory_bytes:set(system_memory)
end

local function measure_tarantool_request_stats()
    local stat = box.stat()
    local request_types = {'delete', 'select', 'insert', 'eval', 'call',
                           'replace', 'upsert', 'auth', 'error', 'update'}

    for _, request_type in ipairs(request_types) do
        requests_total:set(stat[string.upper(request_type)].total,
                           {request_type})
    end
end

local function measure_tarantool_uptime()
    uptime_seconds:set(box.info.uptime)
end

local function measure_tarantool_space_stats()
    for _, space in box.space._space:pairs() do
        local space_name = space[3]

        if string.sub(space_name, 1,1) ~= '_' then
            tuples_total:set(box.space[space_name]:len(), {space_name})
        end
    end

end

local function measure_tarantool_metrics()
    measure_tarantool_memory_usage()
    measure_tarantool_request_stats()
    measure_tarantool_uptime()
    measure_tarantool_space_stats()
end

return {measure_tarantool_metrics=measure_tarantool_metrics}
