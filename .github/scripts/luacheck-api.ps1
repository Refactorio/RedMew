#!/usr/bin/env pwsh
# Regenerates the parts of .luacheckrc that come from Factorio's runtime API: the control stage
# globals (game, script, prototypes, rendering...) and defines. See docs/LUACHECK.md.
#
# usage: luacheck-api.ps1 <version | runtime-api.json>
#   e.g. luacheck-api.ps1 2.1.24
#        luacheck-api.ps1 ~/Downloads/runtime-api.json
#
# A version downloads https://lua-api.factorio.com/<version>/runtime-api.json. The script
# replaces what is between each pair of "-- luacheck-api.ps1: begin <part>" and
# "-- luacheck-api.ps1: end <part>" lines in .luacheckrc, and the version in its
# "-- Current Factorio Version" line. Everything else in the file is left as it is.
param(
    [Parameter(Mandatory)] [string] $Api
)
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$luacheckrc = Join-Path $repo '.luacheckrc'

if (Test-Path -PathType Leaf $Api) {
    $json = Get-Content -Raw $Api
} else {
    $json = (Invoke-WebRequest "https://lua-api.factorio.com/$Api/runtime-api.json").Content
}
$doc = $json | ConvertFrom-Json
if ($doc.application -ne 'factorio' -or $doc.stage -ne 'runtime') {
    throw "$Api is not a Factorio runtime API file"
}
$version = $doc.application_version

# What RedMew code must not call directly, so luacheck flags it: each has a wrapper that lets
# several modules share it. The few files that implement those wrappers say
# "-- luacheck: globals script" (or commands) at the top.
$left_out = @{
    script = @(
        'on_event', 'on_init', 'on_load', 'on_nth_tick', # Event.add, Event.on_init... (utils/event.lua)
        'set_event_filter', # a filter applies to every handler of the event (utils/event.lua)
        'generate_event_name' # Event.generate_event_name (utils/event.lua)
    )
    commands = @('add_command') # Command.add (utils/command.lua)
}

# Attributes of these types hold a value. Any other type is an object or a table, whose own
# fields luacheck doesn't know: it lets code read and write those (game.forces.player.x = 1).
$scalar_types = @(
    'boolean', 'string', 'number', 'double', 'float',
    'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'
)

$concepts = @{}
foreach ($concept in $doc.concepts) { $concepts[$concept.name] = $concept.type }

# A named type is a value if it is one of those, a define (defines.difficulty) or a concept
# that stands for a value (MapTick is a uint64).
function Test-Scalar($type, [int] $depth = 0) {
    if ($depth -gt 10) { return $false }
    if ($type -is [string]) {
        if ($scalar_types -contains $type -or $type.StartsWith('defines.')) { return $true }
        if ($concepts.ContainsKey($type)) { return Test-Scalar $concepts[$type] ($depth + 1) }
        return $false
    }
    switch ($type.complex_type) {
        'literal' { return $true }
        'type' { return Test-Scalar $type.value ($depth + 1) }
        'union' { return -not ($type.options | Where-Object { -not (Test-Scalar $_ ($depth + 1)) }) }
        default { return $false }
    }
}

# Sorts by character code, as Lua and luacheck would, not by the culture's rules.
function Sort-Ordinal($items, [scriptblock] $key = { $_ }) {
    $list = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $items) { $list.Add($item) }
    $list.Sort([System.Comparison[object]] { param($a, $b)
        [string]::CompareOrdinal(($a | ForEach-Object $key), ($b | ForEach-Object $key)) })
    return , $list.ToArray()
}

function Format-Key($name) {
    if ($name -match '^[A-Za-z_]\w*$') { $name } else { "['$name']" }
}

# Each global object (game, script...) is read only, and so are its methods, but code can write
# its writable attributes. other_fields = false makes luacheck flag a field the API doesn't have.
function Get-ControlLines {
    $lines = @()
    $classes = @{}
    foreach ($class in $doc.classes) { $classes[$class.name] = $class }
    foreach ($global in (Sort-Ordinal $doc.global_objects { $_.name })) {
        $class = $classes[$global.type]
        $skip = $left_out[$global.name] ?? @()
        $fields = @()
        foreach ($method in $class.methods) {
            if ($skip -notcontains $method.name) {
                $fields += [pscustomobject]@{ name = $method.name; line = "'$($method.name)'" }
            }
        }
        foreach ($attribute in $class.attributes) {
            $writable = $null -ne $attribute.write_type
            if (-not (Test-Scalar $attribute.read_type)) {
                $line = "$($attribute.name) = {read_only = false, other_fields = true}"
            } elseif ($writable) {
                $line = "$($attribute.name) = {read_only = false}"
            } else {
                $line = "'$($attribute.name)'"
            }
            $fields += [pscustomobject]@{ name = $attribute.name; line = $line }
        }
        $sorted = Sort-Ordinal $fields { $_.name }
        $lines += "        -- $($global.description)"
        $lines += "        $($global.name) = {"
        $lines += '            read_only = true,'
        $lines += '            other_fields = false,'
        $lines += '            fields = {'
        for ($i = 0; $i -lt $sorted.Count; $i++) {
            $comma = if ($i -lt $sorted.Count - 1) { ',' } else { '' }
            $lines += "                $($sorted[$i].line)$comma"
        }
        $lines += '            }'
        $lines += '        },'
    }
    $lines[-1] = $lines[-1].TrimEnd(',')
    return $lines
}

# Every define, with its values, and its subkeys for nested ones
# (defines.control_behavior.inserter.hand_read_mode).
function Get-DefineLines($defines, [int] $indent) {
    $pad = ' ' * $indent
    $lines = @()
    foreach ($define in (Sort-Ordinal $defines { $_.name })) {
        $lines += "$pad$(Format-Key $define.name) = {"
        $lines += "$pad    fields = {"
        $inner = @()
        if ($define.subkeys) {
            $inner = @(Get-DefineLines $define.subkeys ($indent + 8))
        }
        $values = @()
        if ($define.values) {
            $values = @((Sort-Ordinal $define.values { $_.name }) | ForEach-Object { "$pad        '$($_.name)'" })
        }
        if ($inner.Count -and $values.Count) {
            $inner[-1] += ','
        }
        for ($i = 0; $i -lt $values.Count - 1; $i++) { $values[$i] += ',' }
        $lines += $inner
        $lines += $values
        $lines += "$pad    }"
        $lines += "$pad},"
    }
    $lines[-1] = $lines[-1].TrimEnd(',')
    return $lines
}

$text = Get-Content -Raw $luacheckrc
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }

function Set-Part([string] $text, [string] $part, [string[]] $lines) {
    $pattern = "(?ms)^([ \t]*-- luacheck-api\.ps1: begin $part\r?\n).*?^([ \t]*-- luacheck-api\.ps1: end $part)$"
    if ($text -notmatch $pattern) {
        throw ".luacheckrc has no '-- luacheck-api.ps1: begin $part' ... 'end $part' lines"
    }
    $body = ($lines -join $newline) + $newline
    return [regex]::Replace($text, $pattern, { param($m) $m.Groups[1].Value + $body + $m.Groups[2].Value })
}

$text = Set-Part $text 'control' (Get-ControlLines)
$text = Set-Part $text 'defines' (Get-DefineLines $doc.defines 16)
$text = $text -replace '(?m)^(-- Current Factorio Version )[\d.]+', "`${1}$version"

[System.IO.File]::WriteAllText($luacheckrc, $text)
"Updated .luacheckrc from Factorio $version's runtime API"
