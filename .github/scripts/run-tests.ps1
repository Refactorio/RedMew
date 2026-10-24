#!/usr/bin/env pwsh
# Runs the in-game test suite (utils/test) on a headless Factorio server for one scenario
# template, or one map, in a scratch copy of the scenario with its own write-data, so it never
# touches an installed game.
#
# usage: run-tests.ps1 <factorio dir> <template | map module> [-Port n] [-Results file]
#   e.g. run-tests.ps1 ~/factorio danger-ore-rivers
#        run-tests.ps1 ~/factorio map_gen.maps.danger_ores.presets.danger_ore_rivers
#
# <factorio dir> is an unpacked Factorio (the headless download, or an installed game; on macOS,
# the game's .app). A
# template is a folder in scenario_templates: its files are put over the scenario as on the
# servers, and its optional test-settings.json says which of the expansion mods that come with
# the server it needs ({"mods": ["space-age", "quality", "elevated-rails"]}), or that it can't be
# tested here ({"skip": "needs Krastorio 2"}).
#
# The run itself is set up in map_selection.lua (see utils/test/headless.lua), which writes the
# results to script-output/redmew-tests.json. They are printed, and with -Results (or RESULTS)
# set, also saved there with the map's name and how long the run took, for test-summary.ps1.
#
# SPEED is the game speed (default 100), SEED the map seed (default 1, so every run of a map is
# the same; "random" for a new one each run, to turn up tests that only pass on some maps),
# -Port or PORT the server's port (default 34297; give each of several runs at once its own),
# TIMEOUT_SECONDS how long a run may take (default 600).
#
# Exits non-zero if a test fails or the run doesn't finish.
param(
    [Parameter(Mandatory)] [string] $FactorioDir,
    [Parameter(Mandatory)] [string] $Target,
    [string] $Port = ($env:PORT ?? '34297'),
    [string] $Results = $env:RESULTS
)
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$FactorioDir = (Resolve-Path $FactorioDir).Path
# the game's executable and data. A macOS app keeps them in its Contents folder. Take the game's
# folder or app, the app's Contents folder, or the executable itself
# (.../bin/x64/factorio(.exe), or .../factorio.app/Contents/MacOS/factorio).
if (Test-Path -PathType Leaf $FactorioDir) {
    $FactorioDir = Split-Path (Split-Path (Split-Path $FactorioDir))
}
if ((Split-Path -Leaf $FactorioDir) -eq 'Contents') {
    $FactorioDir = Split-Path $FactorioDir
}
$contents = Join-Path $FactorioDir 'Contents'
if (Test-Path (Join-Path $contents 'MacOS/factorio')) {
    $executable = Join-Path $contents 'MacOS/factorio'
    $dataDir = Join-Path $contents 'data'
} else {
    $executable = Join-Path $FactorioDir ($IsWindows ? 'bin/x64/factorio.exe' : 'bin/x64/factorio')
    $dataDir = Join-Path $FactorioDir 'data'
}
$timeoutSeconds = [int]($env:TIMEOUT_SECONDS ?? 600)
$seed = $env:SEED ?? '1'
if ($seed -eq 'random') {
    $seed = Get-Random -Minimum 0 -Maximum 1073741824
}
$seed = [long]$seed
# the game's version, for the results
$factorioVersion = (Get-Content -Raw (Join-Path $FactorioDir 'data/base/info.json') | ConvertFrom-Json).version

$templateDir = Join-Path $repo "scenario_templates/$Target"
$settingsFile = Join-Path $templateDir 'test-settings.json'
$mods = @()
$skip = $null
if (Test-Path $settingsFile) {
    $settings = Get-Content -Raw $settingsFile | ConvertFrom-Json
    if ($settings.mods) { $mods = @($settings.mods) }
    $skip = $settings.skip
}

# the result for test-summary.ps1: the run's own, or one made up for a run that didn't give any
function Save-Result($result, [int] $seconds) {
    if (-not $Results) { return }
    $saved = [ordered]@{ map = $Target; seed = $seed; seconds = $seconds; factorio = $factorioVersion }
    foreach ($property in $result.PSObject.Properties) {
        $saved[$property.Name] = $property.Value
    }
    # an empty list comes out of Lua as {}
    $saved.tests = @(if ($result.tests -is [array]) { $result.tests })
    ConvertTo-Json -InputObject $saved -Depth 5 | Set-Content $Results
}

function Get-Tests($result) {
    @(if ($result.tests -is [array]) { $result.tests })
}

"== $Target (seed $seed, Factorio $factorioVersion)"
if ($skip) {
    "skipped: $skip"
    Save-Result ([pscustomobject]@{ skipped_map = $skip; passed = 0; failed = 0; skipped = 0; tests = @() }) 0
    exit 0
}

$work = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
$process = $null
try {
    $write = Join-Path $work 'write'
    $scenario = Join-Path $write 'scenarios/redmew-test'
    New-Item -ItemType Directory -Force $scenario, (Join-Path $write 'mods') | Out-Null

    $config = Join-Path $work 'config.ini'
    "[path]`nread-data=$dataDir`nwrite-data=$write`n" | Set-Content $config
    # auto_pause off, or the server waits at tick 0 for a player
    $serverSettings = Join-Path $work 'server-settings.json'
    '{"name": "redmew-test", "description": "", "auto_pause": false, "visibility": {"public": false, "lan": false}, "require_user_verification": false, "autosave_interval": 0}' | Set-Content $serverSettings
    $modList = @(@{ name = 'base'; enabled = $true })
    foreach ($mod in 'elevated-rails', 'quality', 'space-age') {
        $modList += @{ name = $mod; enabled = $mods -contains $mod }
    }
    ConvertTo-Json -InputObject @{ mods = $modList } -Depth 3 | Set-Content (Join-Path $write 'mods/mod-list.json')

    # the scenario is a copy of the repo, so the run can't touch the working tree
    Get-ChildItem -Force $repo | Where-Object Name -ne '.git' | Copy-Item -Destination $scenario -Recurse -Force
    $header = "_DEBUG = true`n_TESTS_HEADLESS = {speed = $($env:SPEED ?? 100)}"
    $mapSelection = Join-Path $scenario 'map_selection.lua'
    if (Test-Path $templateDir) {
        Get-ChildItem -Force $templateDir | Copy-Item -Destination $scenario -Recurse -Force
        "$header`n$(Get-Content -Raw $mapSelection)" | Set-Content $mapSelection
    } else {
        "$header`nreturn require '$Target'" | Set-Content $mapSelection
    }

    $log = Join-Path $write 'factorio-current.log'
    $resultsFile = Join-Path $write 'script-output/redmew-tests.json'
    $serverOut = Join-Path $work 'server.out'
    # stdin from an empty file: the server reads stdin as console input
    $stdin = Join-Path $work 'stdin'
    New-Item -ItemType File $stdin | Out-Null
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process $executable -PassThru -NoNewWindow `
        -RedirectStandardInput $stdin -RedirectStandardOutput $serverOut -RedirectStandardError (Join-Path $work 'server.err') `
        -ArgumentList '--config', $config, '--port', $Port, '--server-settings', $serverSettings, `
        '--start-server-load-scenario', 'redmew-test', '--map-gen-seed', $seed

    for ($i = 0; $i -lt $timeoutSeconds; $i++) {
        if (Test-Path $resultsFile) { break }
        if ($process.HasExited) { break }
        if ((Test-Path $log) -and (Select-String -Quiet -SimpleMatch 'non-recoverable error' $log)) { break }
        Start-Sleep -Seconds 1
    }
    $seconds = [int]$timer.Elapsed.TotalSeconds
    if (-not $process.HasExited) {
        $process.Kill($true)
    }
    $process.WaitForExit()

    if (-not (Test-Path $resultsFile)) {
        'The test run did not finish. Server log:'
        $logFile = (Test-Path $log) ? $log : $serverOut
        Get-Content $logFile
        Save-Result ([pscustomobject]@{
                error = 'the test run did not finish'; log = (Get-Content $logFile -Tail 30) -join "`n"
                passed = 0; failed = 1; skipped = 0; tests = @()
            }) $seconds
        exit 1
    }

    $result = Get-Content -Raw $resultsFile | ConvertFrom-Json
    foreach ($test in Get-Tests $result) {
        $line = "$($test.result.ToUpper()) $($test.path) :: $($test.name)"
        if ($null -ne $test.ticks) { $line += " ($($test.ticks) ticks)" }
        if ($test.error) { $line += " :: $($test.error)" }
        $line
    }
    "passed $($result.passed), failed $($result.failed), skipped $($result.skipped) in $seconds s"
    Save-Result $result $seconds
    exit ($result.failed -eq 0 ? 0 : 1)
} finally {
    if ($process -and -not $process.HasExited) {
        $process.Kill($true)
    }
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $work
}
