#!/usr/bin/env tarantool

luaunit = require('luaunit')
prometheus = require('tarantool-prometheus')


TestPrometheus = {}

function TestPrometheus:tearDown()
    prometheus.clear()
end

function TestPrometheus:testCounterNegativeValue()
    c = prometheus.counter("counter")
    luaunit.assertErrorMsgContains("should not be negative", c.inc, c, -1)
end

function TestPrometheus:testLabelNames()
    c = prometheus.counter("counter", "", {'a1', 'foo', "var"})
    c:inc(1, {1, '2', 'q4'})

    r = c:collect()
    luaunit.assertEquals(r[3], 'counter{a1="1",foo="2",var="q4"} 1')
end

function TestPrometheus:testLabelEscape()
    c = prometheus.counter("counter", "", {'a1', 'foo', "var"})
    c:inc(1, {'"', '\\a', '\n'})

    r = c:collect()
    luaunit.assertEquals(r[3], 'counter{a1="\\"",foo="\\\\a",var="\\n"} 1')
end

function TestPrometheus:testHelpEscape()
    c = prometheus.counter("counter", "some\" escaped\\strings\n")
    c:inc(1, {'"', '\\a', '\n'})

    r = c:collect()
    luaunit.assertEquals(r[1], '# HELP counter some\\" escaped\\\\strings\\n')
end

function TestPrometheus:testCounters()
    first = prometheus.counter("counter1", "", {"a", "b"})
    second = prometheus.counter("counter2", "", {"a", "b"})

    first:inc()
    first:inc(4)

    second:inc(1, {"v1", "v2"})
    second:inc(3, {"v1", "v3"})
    second:inc(2, {"v1", "v3"})

    r = first:collect()
    luaunit.assertEquals(r[1], "# HELP counter1 ")
    luaunit.assertEquals(r[2], "# TYPE counter1 counter")
    luaunit.assertEquals(r[3], "counter1 5")
    luaunit.assertEquals(r[4], nil)


    r = second:collect()
    luaunit.assertEquals(r[3], 'counter2{a="v1",b="v2"} 1')
    luaunit.assertEquals(r[4], 'counter2{a="v1",b="v3"} 5')
    luaunit.assertEquals(r[5], nil)

end

function TestPrometheus:testGauge()
    first = prometheus.gauge("gauge1", "", {"a", "b"})
    second = prometheus.gauge("gauge2", "", {"a", "b"})

    first:inc()
    first:inc(4)
    first:set(2)
    first:dec()

    second:set(1, {"v1", "v2"})
    second:inc(3, {"v1", "v3"})
    second:dec(1, {"v1", "v3"})
    second:inc(0, {"v1", "v3"})

    r = first:collect()
    luaunit.assertEquals(r[1], "# HELP gauge1 ")
    luaunit.assertEquals(r[2], "# TYPE gauge1 gauge")
    luaunit.assertEquals(r[3], "gauge1 1")
    luaunit.assertEquals(r[4], nil)


    r = second:collect()
    luaunit.assertEquals(r[3], 'gauge2{a="v1",b="v2"} 1')
    luaunit.assertEquals(r[4], 'gauge2{a="v1",b="v3"} 2')
    luaunit.assertEquals(r[5], nil)

end

function TestPrometheus:testSpecialValues()
    gauge = prometheus.gauge("gauge")

    gauge:set(math.huge)
    r = gauge:collect()
    luaunit.assertEquals(r[3], "gauge +Inf")

    gauge:set(-math.huge)
    r = gauge:collect()
    luaunit.assertEquals(r[3], "gauge -Inf")

    gauge:set(math.huge * 0)
    r = gauge:collect()
    luaunit.assertEquals(r[3], "gauge Nan")
end



function TestPrometheus:testHistogram()
    hist1 = prometheus.histogram("l1", "Histogram 1")
    hist2 = prometheus.histogram("l2", "Histogram 2", {"var", "site"}, {0.1, 0.2})
    hist3 = prometheus.histogram("l3", "Histogram 3", {})

    hist1:observe(0.35)
    hist1:observe(0.9)
    hist1:observe(5)
    hist1:observe(15)

    hist2:observe(0.001, {"ok", "site1"})
    hist2:observe(0.15, {"ok", "site1"})
    hist2:observe(0.15, {"ok", "site2"})

    r = hist1:collect()
    luaunit.assertEquals(r[1], "# HELP l1 Histogram 1")
    luaunit.assertEquals(r[2], "# TYPE l1 histogram")
    luaunit.assertEquals(r[3], 'l1_bucket{le="0.005"} 0')
    luaunit.assertEquals(r[4], 'l1_bucket{le="0.01"} 0')
    luaunit.assertEquals(r[5], 'l1_bucket{le="0.025"} 0')
    luaunit.assertEquals(r[6], 'l1_bucket{le="0.05"} 0')
    luaunit.assertEquals(r[7], 'l1_bucket{le="0.075"} 0')
    luaunit.assertEquals(r[8], 'l1_bucket{le="0.1"} 0')
    luaunit.assertEquals(r[9], 'l1_bucket{le="0.25"} 0')
    luaunit.assertEquals(r[10], 'l1_bucket{le="0.5"} 1')
    luaunit.assertEquals(r[11], 'l1_bucket{le="0.75"} 1')
    luaunit.assertEquals(r[12], 'l1_bucket{le="1"} 2')
    luaunit.assertEquals(r[13], 'l1_bucket{le="2.5"} 2')
    luaunit.assertEquals(r[14], 'l1_bucket{le="5"} 3')
    luaunit.assertEquals(r[15], 'l1_bucket{le="7.5"} 3')
    luaunit.assertEquals(r[16], 'l1_bucket{le="10"} 3')
    luaunit.assertEquals(r[17], 'l1_bucket{le="+Inf"} 4')
    luaunit.assertEquals(r[18], 'l1_sum 21.25')
    luaunit.assertEquals(r[19], 'l1_count 4')

    r = hist2:collect()
    luaunit.assertEquals(r[3], 'l2_bucket{var="ok",site="site1",le="0.1"} 1')
    luaunit.assertEquals(r[4], 'l2_bucket{var="ok",site="site1",le="0.2"} 2')
    luaunit.assertEquals(r[5], 'l2_bucket{var="ok",site="site1",le="+Inf"} 2')
    luaunit.assertEquals(r[6], 'l2_sum{var="ok",site="site1"} 0.151')
    luaunit.assertEquals(r[7], 'l2_count{var="ok",site="site1"} 2')
    luaunit.assertEquals(r[8], 'l2_bucket{var="ok",site="site2",le="0.1"} 0')
    luaunit.assertEquals(r[9], 'l2_bucket{var="ok",site="site2",le="0.2"} 1')
    luaunit.assertEquals(r[10], 'l2_bucket{var="ok",site="site2",le="+Inf"} 1')
    luaunit.assertEquals(r[11], 'l2_sum{var="ok",site="site2"} 0.15')
    luaunit.assertEquals(r[12], 'l2_count{var="ok",site="site2"} 1')

    r = hist3:collect()
    luaunit.assertEquals(r[3], nil)
end

function TestPrometheus:testHistogramUnorderedBuckets()
    hist = prometheus.histogram("l2", "Histogram 2", {}, {0.2, 0.1, 0.5})

    hist:observe(0.15)
    hist:observe(0.4)

    r = hist:collect()
    luaunit.assertEquals(r[3], 'l2_bucket{le="0.1"} 0')
    luaunit.assertEquals(r[4], 'l2_bucket{le="0.2"} 1')
    luaunit.assertEquals(r[5], 'l2_bucket{le="0.5"} 2')
    luaunit.assertEquals(r[6], 'l2_bucket{le="+Inf"} 2')
    luaunit.assertEquals(r[7], 'l2_sum 0.55')
    luaunit.assertEquals(r[8], 'l2_count 2')
    luaunit.assertEquals(r[9], nil)
end

os.exit(luaunit.run())
