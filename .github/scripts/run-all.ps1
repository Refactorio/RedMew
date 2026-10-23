#!/usr/bin/env pwsh
# Runs the in-game tests for every scenario template, or the ones given, several at a time with
# run-tests.ps1, then sums them up with test-summary.ps1.
#
# usage: run-all.ps1 <factorio dir> [template ...]
#   e.g. run-all.ps1 ~/factorio
#        run-all.ps1 ~/factorio danger-ore-rivers crashsite
#
# JOBS is how many run at once (default one per CPU, and no more than fit in the free memory at
# about 512 MB each; a server peaks at around 400 MB). SHARD=i/n runs every nth template from
# the ith, which is how CI splits them over parallel jobs. RESULTS_DIR is where each template's
# results and log go (default a temporary folder). SEED and SPEED are passed on to run-tests.ps1.
#
# Exits non-zero if any test fails or any run doesn't finish.
param(
    [Parameter(Mandatory)] [string] $FactorioDir,
    [Parameter(ValueFromRemainingArguments)] [string[]] $Templates
)
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$FactorioDir = (Resolve-Path $FactorioDir).Path

$jobs = [int]($env:JOBS ?? 0)
if ($jobs -le 0) {
    $jobs = [Environment]::ProcessorCount
    $memory = Get-Content -ErrorAction SilentlyContinue /proc/meminfo | Select-String '^MemAvailable:\s+(\d+)'
    if ($memory) {
        $jobs = [Math]::Max(1, [Math]::Min($jobs, [int]([long]$memory.Matches[0].Groups[1].Value / 1024 / 512)))
    }
}

$resultsDir = $env:RESULTS_DIR ?? (Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid()))
New-Item -ItemType Directory -Force $resultsDir | Out-Null
$resultsDir = (Resolve-Path $resultsDir).Path

if (-not $Templates) {
    $Templates = @(Get-ChildItem (Join-Path $repo 'scenario_templates') -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName 'map_selection.lua') } |
            Sort-Object Name | ForEach-Object Name)
}

if ($env:SHARD) {
    $shard, $shards = $env:SHARD -split '/' | ForEach-Object { [int]$_ }
    $Templates = @(for ($i = 0; $i -lt $Templates.Count; $i++) {
            if ($i % $shards -eq $shard - 1) { $Templates[$i] }
        })
}

"running $($Templates.Count) templates, $jobs at a time"
$runTests = Join-Path $PSScriptRoot 'run-tests.ps1'
@(for ($i = 0; $i -lt $Templates.Count; $i++) { [pscustomobject]@{ index = $i; template = $Templates[$i] } }) |
    ForEach-Object -ThrottleLimit $jobs -Parallel {
        $template = $_.template
        $results = Join-Path $using:resultsDir "$template.json"
        $log = Join-Path $using:resultsDir "$template.log"
        # its own process, as the runs set their own working state
        pwsh -NoProfile -File $using:runTests $using:FactorioDir $template -Port (34400 + $_.index) -Results $results *> $log
        "$($LASTEXITCODE -eq 0 ? 'pass' : 'fail')  $template"
    }

''
& (Join-Path $PSScriptRoot 'test-summary.ps1') $resultsDir
exit $LASTEXITCODE
