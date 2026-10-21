#!/usr/bin/env bash
# Runs the in-game test suite (utils/test) for one map on a headless Factorio server, in a
# sandbox with its own write-data, so it never touches an installed game's saves or settings.
#
# usage: run-ingame-tests.sh <factorio dir> <map module>
#   e.g. run-ingame-tests.sh ~/factorio map_gen.maps.danger_ores.presets.danger_ore_rivers
#
# <factorio dir> is an unpacked Factorio (the headless download, or an installed game). The map
# is loaded with utils/test/headless.lua in front of it, which runs the map_gen tests and logs
# the results. Exits non-zero if any test fails or the run doesn't finish.
#
# MODS lists the expansion mods that come with the server to switch on (space-age, quality,
# elevated-rails); by default they are all off, for the vanilla maps.
#
# SPEED is the game speed the tests run at (default 100): the tests count ticks, so the server
# runs them as fast as the CPU allows instead of 60 a second.
set -euo pipefail

factorio_dir=$1
map=$2
repo=$(cd "$(dirname "$0")/../.." && pwd)
timeout_seconds=${TIMEOUT_SECONDS:-600}
port=${PORT:-34297} # set PORT to run two at once

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
    [[ " ${MODS:-} " == *" $mod "* ]] && enabled=true
    mod_list+=", {\"name\": \"$mod\", \"enabled\": $enabled}"
done
echo "{\"mods\": [$mod_list]}" > "$work/write/mods/mod-list.json"

# the scenario is a copy of the repo, so the run can't touch the working tree
tar -C "$repo" --exclude=.git -cf - . | tar -C "$scenario" -xf -
printf "_DEBUG = true\n_HEADLESS_GAME_SPEED = %s\nrequire 'utils.test.headless'\nreturn require '%s'\n" "${SPEED:-100}" "$map" > "$scenario/map_selection.lua"

log=$work/write/factorio-current.log
# stdin from /dev/null: the server reads stdin as console input
"$factorio_dir/bin/x64/factorio" --config "$work/config.ini" --port "$port" \
    --server-settings "$work/server-settings.json" --start-server-load-scenario redmew-test \
    < /dev/null > "$work/server.out" 2>&1 &
pid=$!

finished=false
for _ in $(seq 1 "$timeout_seconds"); do
    if grep -q 'TESTS DONE' "$log" 2>/dev/null; then
        finished=true
        break
    fi
    if ! kill -0 "$pid" 2>/dev/null || grep -q 'non-recoverable error' "$log" 2>/dev/null; then
        break
    fi
    sleep 1
done
kill "$pid" 2>/dev/null || true
# a server that doesn't stop within 10 seconds of being asked (it happens) is killed outright
for _ in $(seq 1 10); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 1
done
kill -9 "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

echo "== $map"
# the results, each with how long it took in real time too: the log's timestamp of the TESTMARK
# logged as it finished, less that of the one before it ("#n)" becomes "1.2 s)")
awk '
    / TESTMARK [0-9]+$/ { mark[$NF] = $1; next }
    /TESTRESULT / {
        line = substr($0, index($0, "TESTRESULT "))
        if (match(line, /#[0-9]+\)/)) {
            n = substr(line, RSTART + 1, RLENGTH - 2) + 0
            took = (n in mark && (n - 1) in mark) ? sprintf("%.1f s", mark[n] - mark[n - 1]) : "? s"
            line = substr(line, 1, RSTART - 1) took substr(line, RSTART + RLENGTH - 1)
        }
        print line
    }' "$log"

if ! $finished; then
    echo "The test run did not finish. Server log:"
    cat "$log" 2>/dev/null || cat "$work/server.out"
    exit 1
fi

grep -o 'TESTS DONE .*' "$log"
grep -q 'TESTS DONE passed=[0-9]* failed=0$' "$log"
