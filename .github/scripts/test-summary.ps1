#!/usr/bin/env pwsh
# Sums up the results run-tests.ps1 saved (a <template>.json each) in one folder: a line per map,
# then every failed test with its error. With GITHUB_STEP_SUMMARY set (in CI), it also writes the
# full list there, every test grouped by map.
#
# usage: test-summary.ps1 <results dir> [templates dir]
#
# Given the scenario_templates folder, a template without results counts as a run that didn't
# finish (in CI, a job that stopped before saving them).
#
# Exits non-zero if any test failed, any run didn't finish, or there are no results.
param(
    [Parameter(Mandatory)] [string] $ResultsDir,
    [string] $TemplatesDir
)
$ErrorActionPreference = 'Stop'

if ($TemplatesDir) {
    foreach ($template in Get-ChildItem $TemplatesDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'map_selection.lua') }) {
        $file = Join-Path $ResultsDir "$($template.Name).json"
        if (-not (Test-Path $file)) {
            ConvertTo-Json -Depth 5 -InputObject ([ordered]@{
                    map = $template.Name; seed = $null; seconds = 0; error = 'no results'; log = ''
                    passed = 0; failed = 1; skipped = 0; tests = @()
                }) | Set-Content $file
        }
    }
}

$files = @(Get-ChildItem -File (Join-Path $ResultsDir '*.json'))
if ($files.Count -eq 0) {
    "no test results in $ResultsDir"
    exit 1
}

# all the results, sorted by map
$all = @($files | ForEach-Object { Get-Content -Raw $_ | ConvertFrom-Json } | Sort-Object map)

function Get-Tests($result) {
    @(if ($result.tests -is [array]) { $result.tests })
}

# a map failed if a test failed or its run didn't finish
foreach ($result in $all) {
    if ($result.skipped_map) {
        "skip  $($result.map)  $($result.skipped_map)"
    } else {
        "$($result.failed -gt 0 ? 'fail' : 'pass')  $($result.map)  passed $($result.passed), failed $($result.failed), skipped $($result.skipped) (seed $($result.seed ?? '?'), $($result.seconds) s)"
    }
}

foreach ($result in $all | Where-Object failed -gt 0) {
    ''
    "=== $($result.map) (seed $($result.seed ?? '?'))"
    if ($result.error) {
        $result.log ? "$($result.error):`n$($result.log)" : $result.error
    }
    foreach ($test in Get-Tests $result | Where-Object result -eq 'fail') {
        "FAIL $($test.path) :: $($test.name) :: $($test.error)"
    }
}

if ($env:GITHUB_STEP_SUMMARY) {
    $fence = '```'
    $icons = @{ pass = '✅'; fail = '❌'; skip = '⏭️' }
    $tested = @($all | Where-Object { -not $_.skipped_map })
    $lines = @("### In-game tests: $(@($tested | Where-Object failed -eq 0).Count) of $($tested.Count) maps passed`n")
    foreach ($result in $all) {
        if ($result.skipped_map) {
            $lines += "⏭️ **$($result.map)**: skipped, $($result.skipped_map)`n"
            continue
        }
        $failed = $result.failed -gt 0
        $lines += "<details$($failed ? ' open' : '')><summary>$($failed ? '❌' : '✅') <b>$($result.map)</b>: $($result.passed) passed, $($result.failed) failed, $($result.skipped) skipped (seed $($result.seed ?? '?'), $($result.seconds) s)</summary>`n"
        if ($result.error) {
            $lines += $result.log ? "$($result.error):`n$fence`n$($result.log)`n$fence`n" : "$($result.error)`n"
        }
        $tests = Get-Tests $result
        foreach ($test in $tests | Where-Object result -ne 'skip') {
            $line = "- $($icons[$test.result]) ``$($test.path)`` $($test.name)"
            if ($null -ne $test.ticks) { $line += " ($($test.ticks) ticks)" }
            if ($test.result -eq 'fail') {
                $line += "`n  $fence`n  $($test.error -replace "`n", "`n  ")`n  $fence"
            }
            $lines += $line
        }
        # skipped tests by module, not one by one
        foreach ($group in $tests | Where-Object result -eq 'skip' | Group-Object path) {
            $lines += "- ⏭️ ``$($group.Name)``: $($group.Count) skipped, $($group.Group[0].error)"
        }
        $lines += "`n</details>`n"
    }
    $lines | Add-Content $env:GITHUB_STEP_SUMMARY
}

exit (@($all | Where-Object failed -gt 0).Count -eq 0 ? 0 : 1)
