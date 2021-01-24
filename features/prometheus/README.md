<a href="http://tarantool.org">
	<img src="https://avatars2.githubusercontent.com/u/2344919?v=2&s=250" align="right">
</a>
<!--a href="https://travis-ci.org/tarantool/tarantool-prometheus">
	<img src="https://travis-ci.org/tarantool/tarantool-prometheus.png?branch=master" align="right">
</a-->

# Prometheus metric collector for Tarantool

This is a Lua library that makes it easy to collect metrics from your Tarantool
apps and databases and expose them via the Prometheus protocol. You may use the
library to instrument your code and get an insight into performance bottlenecks.

At the moment, 3 types of metrics are supported:
* Counter: a non-decreasing numeric value, used e.g. for counting the number of
  requests
* Gauge: an arbitrary numeric value, which can be used e.g. to report memory
  usage
* Histogram: for counting value distribution by user-specified buckets. Can be
  used for recording request/response times.

## Table of contents

* [Limitations](#limitations)
* [Getting started](#getting-started)
  * [Basic examples](#basic-examples)
  * [A more detailed example](#a-more-detailed-example)
* [Usage](#usage)
  * [counter(name, help, labels)](#countername-help-labels)
  * [gauge(name, help, labels)](#gaugename-help-labels)
  * [histogram(name, help, labels, buckets)](#histogramname-help-labels-buckets)
  * [Counter:inc(value, labels)](#counterincvalue-labels)
  * [Gauge:set(value, labels)](#gaugesetvalue-labels)
  * [Gauge:inc(value, labels)](#gaugeincvalue-labels)
  * [Gauge:dec(value, labels)](#gaugedecvalue-labels)
  * [Histogram:observe(value, labels)](#histogramobservevalue-labels)
  * [collect()](#collect)
  * [collect\_http()](#collect_http)
* [Development](#development)
* [Credits](#credits)
* [License](#license)

## Limitations

The Summary metric is not implemented yet. It may be implemented in future.

## Getting started

The easiest way is, of course, to use
[one of the official Docker images](https://hub.docker.com/r/tarantool/tarantool/),
which already contain the Prometheus collector. But if you run on a regular
Linux distro, first install the library from
[Tarantool Rocks server](http://rocks.tarantool.org):

```bash
$ luarocks install tarantool-prometheus
```
### Basic examples

To report the arena size, you can write the following code:

```lua
prometheus = require('tarantool-prometheus')
fiber = require('fiber')

box.cfg{}
httpd = http.new('0.0.0.0', 8080)

arena_used = prometheus.gauge("tarantool_arena_used",
                              "The amount of arena used by Tarantool")

function monitor_arena_size()
  while true do
    arena_used:set(box.slab.info().arena_used)
    fiber.sleep(5)
  end
end
fiber.create(monitor_arena_size)

httpd:route( { path = '/metrics' }, prometheus.collect_http)
httpd:start()
```

The code will periodically measure the arena size and update the `arena_used`
metric. Later, when Prometheus polls the instance, it will get the values of all
metrics the instance created.

There are 3 important bits in the code above:

```lua
arena_used = prometheus.gauge(...)
```

This creates a [Gauge](https://prometheus.io/docs/concepts/metric_types/#gauge)
object that can be set to an arbitrary numeric value. After this, the metric from
this object will be automatically collected by Prometheus every time metrics are
polled.

```lua
arena_used:set(...)
```

This sets the current value of the metric.

```lua
httpd:route( { path = '/metrics' }, prometheus.collect_http)
```

This exposes metrics over the text/plain HTTP protocol on
[http://localhost:8080/metrics](http://localhost:8080/metrics) for Prometheus to
collect. Prometheus periodically polls this endpoint and stores the results in
its time series database.

### A more detailed example

If you want a more detailed example, there is an `example.lua` file in the root
of this repo. It demonstrates the usage of each of the 3 metric types.

To run it with Docker, you can do as follows:

``` bash
$ docker build -t tarantool-prometheus .
$ docker run --rm -t -i -p8080:8080 tarantool-prometheus
```

Then visit [http://localhost:8080/metrics](http://localhost:8080/metrics) and
refresh the page a few times to see the metrics change.

## Usage

This section documents the user-facing API of the module.

### counter(name, help, labels)

Creates and registers a [Counter](https://prometheus.io/docs/concepts/metric_types/#counter).

* `name` is the name of the metric. Required.
* `help` is the metric docstring. You can use newlines and quotes here. Optional.
* `labels` is an array of label names for the metric. Optional.

Example:

```lua
num_of_logins = prometheus.counter(
    "tarantool_number_of_logins", "Total number of user logins")

http_requests = prometheus:counter(
    "tarantool_http_requests_total", "Number of HTTP requests", {"host", "status"})
```

### gauge(name, help, labels)

Creates and registers a [Gauge](https://prometheus.io/docs/concepts/metric_types/#gauge).

* `name` is the name of the metric. Required.
* `help` is the metric docstring. You can use newlines and quotes here. Optional.
* `labels` is an array of label names for the metric. Optional.

Example:

``` lua
arena_used = prometheus.gauge(
    "tarantool_arena_used_size", "Total size of the arena used")

requests_inprogress = prometheus.gauge(
    "tarantool_requests_inprogress", "Number of requests in progress", {"request_type"})
```

### histogram(name, help, labels, buckets)

Creates and registers a [Histogram](https://prometheus.io/docs/concepts/metric_types/#histogram).

* `name` is the name of the metric. Required.
* `help` is the metric docstring. You can use newlines and quotes here. Optional.
* `labels` is an array of label names for the metric. Optional.
* `buckets` is an array of numbers defining histogram buckets. Optional. Defaults to
  `{.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 7.5, 10.0, INF}`.

Example:

``` lua
request_latency = prometheus.histogram(
    "tarantool_request_latency_seconds", "Incoming request latency", {"client"})
response_size = prometheus.histogram(
    "tarantool_response_size", "Size of response, in bytes", nil, {100, 1000, 100000})
```

### Counter:inc(value, labels)

Increments a counter created by `prometheus.counter()`.

* `value` specifies by how much to increment. Optional. Defaults to `1`.
* `labels` is an array of label values. Optional.

### Gauge:set(value, labels)

Sets a value of a gauge created by `prometheus.gauge()`.

* `value` is the value to set. Optional. Defaults to `0`.
* `labels` is an array of label values. Optional.

### Gauge:inc(value, labels)

Increments a gauge created by `prometheus.gauge()`.

* `value` specifies by how much to increment. Optional. Defaults to `1`.
* `labels` is an array of label values. Optional.

### Gauge:dec(value, labels)

Decrements a gauge created by `prometheus.gauge()`.

* `value` specifies by how much to decrement. Optional. Defaults to `1`.
* `labels` is an array of label values. Optional.

### Histogram:observe(value, labels)

Records a value to a histogram created by `prometheus.histogram()`.

* `value` is the value to record. Optional. Defaults to `0`.
* `labels` is an array of label values. Optional.

### collect()

Presents all metrics in a text format compatible with Prometheus. This can be
called either by `http.server` callback or by
[Tarantool nginx_upstream_module](https://github.com/tarantool/nginx_upstream_module).

### collect_http()

Convenience function, specially for one-line registration in the Tarantool
`http.server`, as follows:

```lua
httpd:route( { path = '/metrics' }, prometheus.collect_http)
```

## Development

Contributions are welcome. Report issues and feature requests at
https://github.com/tarantool/tarantool-prometheus/issues

To run tests, do:

```bash
$ tarantool test.lua
```

NB: Tests require `luaunit` library.

## Credits

Loosely based on the implementation by @knyar: https://github.com/knyar/nginx-lua-prometheus

## License

Licensed under the BSD license. See the LICENSE file.