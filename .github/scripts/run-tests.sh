#!/usr/bin/env bash
# Runs the in-game test suite (utils/test) on a headless Factorio server for one scenario
# template, or one map, in a scratch copy of the scenario with its own write-data, so it never
# touches an installed game. run-tests.ps1 does the same in PowerShell; keep the two in step.
#
# usage: run-tests.sh <factorio dir> <template | map module>
#   e.g. run-tests.sh ~/factorio danger-ore-rivers
#        run-tests.sh ~/factorio map_gen.maps.danger_ores.presets.danger_ore_rivers
#
# <factorio dir> is an unpacked Factorio (the headless download, or an installed game). A
# template is a folder in scenario_templates: its files are put over the scenario as on the
# servers, and its optional test-settings.json says which of the expansion mods that come with
# the server it needs ({"mods": ["space-age", "quality", "elevated-rails"]}), or that it can't be
# tested here ({"skip": "needs Krastorio 2"}).
#
# The run itself is set up in map_selection.lua (see utils/test/headless.lua), which writes the
# results to script-output/redmew-tests.json. They are printed, and with RESULTS set, also saved
# there with the map's name and how long the run took, for test-summary.sh.
#
# SPEED is the game speed (default 100), SEED the map seed (default 1, so every run of a map is
# the same; "random" for a new one each run, to turn up tests that only pass on some maps), PORT the server's port (default 34297; give each of several runs at once its own),
# TIMEOUT_SECONDS how long a run may take (default 600).
#
# Exits non-zero if a test fails or the run doesn't finish.
set -euo pipefail

factorio_dir=$1
target=$2
repo=$(cd "$(dirname "$0")/../.." && pwd)
timeout_seconds=${TIMEOUT_SECONDS:-600}
port=${PORT:-34297}
seed=${SEED:-1}
[ "$seed" = random ] && seed=$((RANDOM * 32768 + RANDOM))

template_dir=$repo/scenario_templates/$target
settings=$template_dir/test-settings.json
mods=
skip=
if [ -d "$template_dir" ] && [ -f "$settings" ]; then
    mods=$(jq -r '(.mods // []) | join(" ")' "$settings")
    skip=$(jq -r '.skip // empty' "$settings")
fi

# the result for test-summary.sh: the run's own, or one made up for a run that didn't give any
save_result() {
    [ -n "${RESULTS:-}" ] || return 0
    jq --arg map "$target" --argjson seconds "$1" --argjson seed "$seed" \
        '{map: $map, seed: $seed, seconds: $seconds} + . | .tests |= (if type == "array" then . else [] end)' \
        > "$RESULTS"
}

echo "== $target (seed $seed)"
if [ -n "$skip" ]; then
    echo "skipped: $skip"
    jq -n --arg skip "$skip" '{skipped_map: $skip, passed: 0, failed: 0, skipped: 0, tests: []}' | save_result 0
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
scenario=$work/write/scenarios/redmew-test
mkdir -p "$scenario" "$work/write/mods"

printf '[path]\nread-data=%s/data\nwrite-data=%s/write\n' "$factorio_dir" "$work" > "$work/config.ini"
# auto_pause off, or the server waits at tick 0 for a player
echo '{"name": "redmew-test", "description": "", "auto_pause": false, "visibility": {"public": false, "lan": false}, "require_user_verification": false, "autosave_interval": 0}' > "$work/server-settings.json"
mod_list='{"name": "base", "enabled": true}'
for mod in elevated-rails quality space-age; do
    enabled=false
    [[ " $mods " == *" $mod "* ]] && enabled=true
    mod_list+=", {\"name\": \"$mod\", \"enabled\": $enabled}"
done
echo "{\"mods\": [$mod_list]}" > "$work/write/mods/mod-list.json"

# the scenario is a copy of the repo, so the run can't touch the working tree
tar -C "$repo" --exclude=.git -cf - . | tar -C "$scenario" -xf -
header="_DEBUG = true
_TESTS_HEADLESS = {speed = ${SPEED:-100}}"
if [ -d "$template_dir" ]; then
    cp -r "$template_dir/." "$scenario/"
    printf '%s\n%s\n' "$header" "$(cat "$scenario/map_selection.lua")" > "$scenario/map_selection.lua"
else
    printf "%s\nreturn require '%s'\n" "$header" "$target" > "$scenario/map_selection.lua"
fi

log=$work/write/factorio-current.log
results=$work/write/script-output/redmew-tests.json
started=$SECONDS
# stdin from /dev/null: the server reads stdin as console input
"$factorio_dir/bin/x64/factorio" --config "$work/config.ini" --port "$port" \
    --server-settings "$work/server-settings.json" --start-server-load-scenario redmew-test --map-gen-seed "$seed" \
    < /dev/null > "$work/server.out" 2>&1 &
pid=$!

for _ in $(seq 1 "$timeout_seconds"); do
    [ -f "$results" ] && break
    if ! kill -0 "$pid" 2>/dev/null || grep -q 'non-recoverable error' "$log" 2>/dev/null; then
        break
    fi
    sleep 1
done
seconds=$((SECONDS - started))
kill "$pid" 2>/dev/null || true
# a server that doesn't stop within 10 seconds of being asked (it happens) is killed outright
for _ in $(seq 1 10); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
done
kill -9 "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

if [ ! -f "$results" ]; then
    echo "The test run did not finish. Server log:"
    cat "$log" 2>/dev/null || cat "$work/server.out"
    jq -n --arg log "$(tail -n 30 "$log" 2>/dev/null || tail -n 30 "$work/server.out")" \
        '{error: "the test run did not finish", log: $log, passed: 0, failed: 1, skipped: 0, tests: []}' | save_result "$seconds"
    exit 1
fi

jq -r '(.tests | if type == "array" then . else [] end)[]
    | "\(.result | ascii_upcase) \(.path) :: \(.name)\(if .ticks then " (\(.ticks) ticks)" else "" end)\(if .error then " :: \(.error)" else "" end)"' "$results"
jq -r --arg seconds "$seconds" '"passed \(.passed), failed \(.failed), skipped \(.skipped) in \($seconds) s"' "$results"
save_result "$seconds" < "$results"
[ "$(jq '.failed' "$results")" -eq 0 ]
