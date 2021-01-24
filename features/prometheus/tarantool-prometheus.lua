-- vim: ts=2:sw=2:sts=2:expandtab

local INF = math.huge
local NAN = math.huge * 0
local DEFAULT_BUCKETS = {.005, .01, .025, .05, .075, .1, .25, .5,
                         .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}

local REGISTRY = nil

local Registry = {}
Registry.__index = Registry

function Registry.new()
    local obj = {}
    setmetatable(obj, Registry)
    obj.collectors = {}
    obj.callbacks = {}
    return obj
end

function Registry:register(collector)
    if self.collectors[collector.name]~=nil then
        return self.collectors[collector.name]
    end
    self.collectors[collector.name] = collector
    return collector
end

function Registry:unregister(collector)
    if self.collectors[collector.name]~=nil then
        table.remove(self.collectors, collector.name)
    end
end

function Registry:collect()
    for _, registered_callback in ipairs(self.callbacks) do
        registered_callback()
    end

    local result = {}
    for _, collector in pairs(self.collectors) do
        for _, metric in ipairs(collector:collect()) do
            table.insert(result, metric)
        end
        table.insert(result, '')
    end
    return result
end

function Registry:register_callback(callback)
    local found = false
    for _, registered_callback in ipairs(self.callbacks) do
        if registered_callback == calback then
            found = true
        end
    end
    if not found then
        table.insert(self.callbacks, callback)
    end
end

local function get_registry()
    if not REGISTRY then
        REGISTRY = Registry.new()
    end
    return REGISTRY
end

local function register(collector)
    local registry = get_registry()
    registry:register(collector)

    return collector
end

local function register_callback(callback)
    local registry = get_registry()
    registry:register_callback(callback)
end

function zip(lhs, rhs)
    if lhs == nil or rhs == nil then
        return {}
    end

    local len = math.min(#lhs, #rhs)
    local result = {}
    for i=1,len do
        table.insert(result, {lhs[i], rhs[i]})
    end
    return result
end

local function metric_to_string(value)
    if value == INF then
        return "+Inf"
    elseif value == -INF then
        return "-Inf"
    elseif value ~= value then
        return "Nan"
    else
        return tostring(value)
    end
end

local function escape_string(str)
    return str
        :gsub("\\", "\\\\")
        :gsub("\n", "\\n")
        :gsub('"', '\\"')
end

local function labels_to_string(label_pairs)
    if #label_pairs == 0 then
        return ""
    end
    local label_parts = {}
    for _, label in ipairs(label_pairs) do
        local label_name = label[1]
        local label_value = label[2]
        local label_value_escaped = escape_string(string.format("%s", label_value))
        table.insert(label_parts, label_name .. '="' .. label_value_escaped .. '"')
    end
    return  "{" .. table.concat(label_parts, ",") .. "}"
end


local Counter = {}
Counter.__index = Counter

function Counter.new(name, help, labels)
    local obj = {}
    setmetatable(obj, Counter)
    if not name then
        error("Name should be set for Counter")
    end
    obj.name = name
    obj.help = help or ""
    obj.labels = labels or {}
    obj.observations = {}
    obj.label_values = {}

    return obj
end

function Counter:inc(num, label_values)
    local num = num or 1
    local label_values = label_values or {}
    if num < 0 then
        error("Counter increment should not be negative")
    end
    local key = table.concat(label_values, '\0')
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_values[key] = label_values
end

function Counter:collect()
    local result = {}

    if next(self.observations) == nil then
        return {}
    end

    table.insert(result, '# HELP '..self.name..' '..escape_string(self.help))
    table.insert(result, "# TYPE "..self.name.." counter")

    for key, observation in pairs(self.observations) do
        local label_values = self.label_values[key]
        local prefix = self.name
        local labels = zip(self.labels, label_values)

        local str = prefix..labels_to_string(labels)..
            ' '..metric_to_string(observation)
        table.insert(result, str)
    end

    return result
end


local Gauge = {}
Gauge.__index = Gauge

function Gauge.new(name, help, labels)
    local obj = {}
    setmetatable(obj, Gauge)
    if not name then
        error("Name should be set for Gauge")
    end
    obj.name = name
    obj.help = help or ""
    obj.labels = labels or {}
    obj.observations = {}
    obj.label_values = {}

    return obj
end

function Gauge:inc(num, label_values)
    local num = num or 1
    local label_values = label_values or {}
    local key = table.concat(label_values, '\0')
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value + num
    self.label_values[key] = label_values
end

function Gauge:dec(num, label_values)
    local num = num or 1
    local label_values = label_values or {}
    local key = table.concat(label_values, '\0')
    local old_value = self.observations[key] or 0
    self.observations[key] = old_value - num
    self.label_values[key] = label_values
end

function Gauge:set(num, label_values)
    local num = num or 0
    local label_values = label_values or {}
    local key = table.concat(label_values, '\0')
    self.observations[key] = num
    self.label_values[key] = label_values
end

function Gauge:collect()
    local result = {}

    if next(self.observations) == nil then
        return {}
    end

    table.insert(result, '# HELP '..self.name..' '..escape_string(self.help))
    table.insert(result, "# TYPE "..self.name.." gauge")

    for key, observation in pairs(self.observations) do
        local label_values = self.label_values[key]
        local prefix = self.name
        local labels = zip(self.labels, label_values)

        local str = prefix..labels_to_string(labels)..
            ' '..metric_to_string(observation)
        table.insert(result, str)
    end

    return result
end

local Histogram = {}
Histogram.__index = Histogram

function Histogram.new(name, help, labels,
                       buckets)
    local obj = {}
    setmetatable(obj, Histogram)
    if not name then
        error("Name should be set for Histogram")
    end
    obj.name = name
    obj.help = help or ""
    obj.labels = labels or {}
    obj.buckets = buckets or DEFAULT_BUCKETS
    table.sort(obj.buckets)
    if obj.buckets[#obj.buckets] ~= INF then
        obj.buckets[#obj.buckets+1] = INF
    end
    obj.observations = {}
    obj.label_values = {}
    obj.counts = {}
    obj.sums = {}

    return obj
end

function Histogram:observe(num, label_values)
    local num = num or 0
    local label_values = label_values or {}
    local key = table.concat(label_values, '\0')

    local obs = nil
    if self.observations[key] == nil then
        obs = {}
        for i=1, #self.buckets do
            obs[i] = 0
        end
        self.observations[key] = obs
        self.label_values[key] = label_values
        self.counts[key] = 0
        self.sums[key] = 0
    else
        obs = self.observations[key]
    end

    self.counts[key] = self.counts[key] + 1
    self.sums[key] = self.sums[key] + num
    for i, bucket in ipairs(self.buckets) do
        if num <= bucket then
            obs[i] = obs[i] + 1
        end
    end
end


function Histogram:collect()
    local result = {}

    if next(self.observations) == nil then
        return {}
    end

    table.insert(result, '# HELP '..self.name..' '..escape_string(self.help))
    table.insert(result, "# TYPE "..self.name.." histogram")

    for key, observation in pairs(self.observations) do
        local label_values = self.label_values[key]
        local prefix = self.name
        local labels = zip(self.labels, label_values)
        labels[#labels+1] = {le="0"}
        for i, bucket in ipairs(self.buckets) do
            labels[#labels] = {"le", metric_to_string(bucket)}
            str = prefix.."_bucket"..labels_to_string(labels)..
                ' '..metric_to_string(observation[i])
            table.insert(result, str)
        end
        table.remove(labels, #labels)

        table.insert(result,
                     prefix.."_sum"..labels_to_string(labels)..' '..self.sums[key])
        table.insert(result,
                     prefix.."_count"..labels_to_string(labels)..' '..self.counts[key])
    end

    return result
end


-- #################### Public API ####################


local function counter(name, help, labels)
    local obj = Counter.new(name, help, labels)
    obj = register(obj)
    return obj
end

local function gauge(name, help, labels)
    local obj = Gauge.new(name, help, labels)
    obj = register(obj)
    return obj
end

local function histogram(name, help, labels, buckets)
    local obj = Histogram.new(name, help, labels, buckets)
    obj = register(obj)
    return obj
end

local function collect()
    local registry = get_registry()

    return table.concat(registry:collect(), '\n')..'\n'
end

local function collect_http()
    return {
        status = 200,
        headers = { ['content-type'] = 'text/plain; charset=utf8' },
        body = collect()
    }
end

local function clear()
    local registry = get_registry()
    registry.collectors = {}
    registry.callbacks = {}
end

local function init()
    local registry = get_registry()
    local tarantool_metrics = require('tarantool-prometheus.tarantool-metrics')
    registry:register_callback(tarantool_metrics.measure_tarantool_metrics)
end

return {counter=counter,
        gauge=gauge,
        histogram=histogram,
        collect=collect,
        collect_http=collect_http,
        clear=clear,
        init=init}
