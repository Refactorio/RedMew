#!/usr/bin/env bash
# Runs the in-game tests for every preset of one game mode, several maps at a time, each with
# run-ingame-tests.sh on its own port. Prints a line per map and the output of any that failed,
# and adds a table to the GitHub job summary when there is one.
#
# usage: run-map-group.sh <factorio dir> <game mode>
#   e.g. run-map-group.sh ~/factorio danger_ores
#
# <game mode> is a folder under map_gen/maps. Every preset in its presets folder is run, except
# the ones listed in SKIP below; a game mode without presets (Frontier) runs its scenario module.
# The game mode "templates" runs the maps the scenario templates select, other than those of the
# game modes run on their own, and the one-file maps that have tests of their own
# (map_gen/maps/<name>_tests.lua) whether a template selects them or not.
# JOBS sets how many run at once (default: two per CPU).
# Exits non-zero if any map fails.
set -euo pipefail

factorio_dir=$1
group=$2
repo=$(cd "$(dirname "$0")/../.." && pwd)
jobs=${JOBS:-$(( $(nproc) * 2 ))}

# Game modes with a CI job of their own, left out of "templates", along with the one-line files
# that select their presets (crash_site_UK.lua and so on).
own_jobs='danger_ores|crash_site|diggy|frontier'

# Maps that need mods the headless server doesn't have, so they can't load here.
declare -A SKIP=(
    [danger_ores/danger_ore_angel]=1
    [danger_ores/danger_ore_bob]=1
    [danger_ores/danger_ore_bob_angel]=1
    [danger_ores/danger_ore_bz]=1
    [danger_ores/danger_ore_exotic_industries]=1
    [danger_ores/danger_ore_exotic_industries_spiral]=1
    [danger_ores/danger_ore_industrial_revolution_3]=1
    [danger_ores/danger_ore_industrial_revolution_3_grid_factory]=1
    [danger_ores/danger_ore_krastorio2]=1
    [danger_ores/danger_ore_omnimatter]=1
    [danger_ores/danger_ore_omnimatter_cages]=1
    [danger_ores/danger_ore_omnimatter_maze]=1
    [danger_ores/danger_ore_pyfe]=1
    [danger_ores/danger_ore_scrap]=1
    [danger_ores/danger_ore_scrap_maze]=1
    [templates/april_fools.2024]=1
    [templates/maze_krastorio2]=1
)

# Maps that need the expansion mods that come with the server, which are otherwise off.
declare -A MODS_FOR=(
    [danger_ores/danger_ore_space_age]='space-age quality elevated-rails'
)

results=$(mktemp -d)
trap 'rm -rf "$results"' EXIT

# Each map is a module and the short name it is reported (and skipped) by.
modules=()
names=()
skipped=()
add_map() {
    local module=$1 name=$2
    if [[ -n "${SKIP[$group/$name]:-}" ]]; then
        skipped+=("$name")
    else
        modules+=("$module")
        names+=("$name")
    fi
}

if [ "$group" = templates ]; then
    {
        for file in "$repo"/scenario_templates/*/map_selection.lua; do
            grep -m1 -oE "require ['\"]map_gen\.maps\.[^'\"]+" "$file" | sed -E "s/^require ['\"]//" || true
        done
        for file in "$repo"/map_gen/maps/*_tests.lua; do
            name=$(basename "$file" _tests.lua)
            if [ -f "$repo/map_gen/maps/$name.lua" ]; then
                echo "map_gen.maps.$name"
            fi
        done
    } | sort -u > "$results/templates"
    while read -r module; do
        name=${module#map_gen.maps.}
        if [[ ! $name =~ ^($own_jobs)([._]|$) ]]; then
            add_map "$module" "$name"
        fi
    done < "$results/templates"
elif [ -d "$repo/map_gen/maps/$group/presets" ]; then
    for file in "$repo/map_gen/maps/$group/presets/"*.lua; do
        preset=$(basename "$file" .lua)
        # a preset's tests sit next to it
        [[ $preset == *_tests ]] && continue
        add_map "map_gen.maps.$group.presets.$preset" "$preset"
    done
else
    add_map "map_gen.maps.$group.scenario" scenario
fi

run_one() {
    eval "$MODS_FOR_DEF"
    local index=$1 module=$2 name=$3
    local out=$results/$name
    if PORT=$((34400 + index)) MODS="${MODS_FOR[$group/$name]:-}" "$repo/.github/scripts/run-ingame-tests.sh" "$factorio_dir" \
        "$module" > "$out.log" 2>&1; then
        echo pass > "$out.status"
    else
        echo fail > "$out.status"
    fi
}
export -f run_one
export repo factorio_dir group results
# bash can't export arrays, so run_one gets the mods table as a definition to evaluate
MODS_FOR_DEF=$(declare -p MODS_FOR)
export MODS_FOR_DEF

for i in "${!modules[@]}"; do
    echo "$i ${modules[$i]} ${names[$i]}"
done | xargs -P "$jobs" -L1 bash -c 'run_one "$0" "$1" "$2"'

failed=0
summary="| Map | Result |\n|---|---|\n"
for name in "${names[@]}"; do
    status=$(cat "$results/$name.status")
    counts=$(grep -o 'TESTS DONE .*' "$results/$name.log" | sed 's/TESTS DONE //' || echo 'did not finish')
    echo "$status  $name  $counts"
    summary+="| $name | $([ "$status" = pass ] && echo "✅" || echo "❌") $counts |\n"
    [ "$status" = pass ] || failed=$((failed + 1))
done
echo "skipped (need mods): ${skipped[*]:-none}"

# where the time goes: the slowest tests in the group, by real time
echo "slowest tests:"
for name in "${names[@]}"; do
    grep -oE '^TESTRESULT [A-Z]+ .*\([0-9]+ ticks, [0-9.]+ s\)' "$results/$name.log" | sed "s|^|$name |" || true
done | awk '{
    match($0, /\([0-9]+ ticks, [0-9.]+ s\)/)
    split(substr($0, RSTART + 1, RLENGTH - 2), took, /[ ,]+/)
    test = substr($0, index($0, "/"), RSTART - index($0, "/") - 1)
    printf "%s\t  %5.1f s  %6d ticks  %s: %s\n", took[3], took[3], took[1], $1, test
}' | sort -rn | awk 'NR <= 5' | cut -f2-

for name in "${names[@]}"; do
    if [ "$(cat "$results/$name.status")" != pass ]; then
        echo
        echo "=== $name"
        cat "$results/$name.log"
    fi
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### $group: $((${#names[@]} - failed)) of ${#names[@]} maps passed"
        echo
        printf '%b' "$summary"
        echo
        echo "Skipped, need mods: ${skipped[*]:-none}"
    } >> "$GITHUB_STEP_SUMMARY"
fi

[ "$failed" -eq 0 ]
