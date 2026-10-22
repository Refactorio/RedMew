#!/usr/bin/env bash
# Runs the in-game tests for every scenario template, or the ones given, several at a time with
# run-tests.sh, then sums them up with test-summary.sh. run-all.ps1 does the same in PowerShell;
# keep the two in step.
#
# usage: run-all.sh <factorio dir> [template ...]
#   e.g. run-all.sh ~/factorio
#        run-all.sh ~/factorio danger-ore-rivers crashsite
#
# JOBS is how many run at once (default one per CPU, and no more than fit in the free memory at
# about 512 MB each; a server peaks at around 400 MB). SHARD=i/n runs every nth template from
# the ith, which is how CI splits them over parallel jobs. RESULTS_DIR is where each template's
# results and log go (default a temporary folder). SEED and SPEED are passed on to run-tests.sh.
#
# Exits non-zero if any test fails or any run doesn't finish.
set -euo pipefail

factorio_dir=$1
shift
scripts=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$scripts/../.." && pwd)
jobs=${JOBS:-}
if [ -z "$jobs" ]; then
    jobs=$(nproc)
    free_mb=$(awk '/^MemAvailable:/ {print int($2 / 1024)}' /proc/meminfo)
    if [ $((free_mb / 512)) -lt "$jobs" ]; then
        jobs=$((free_mb / 512))
    fi
    [ "$jobs" -ge 1 ] || jobs=1
fi
results_dir=${RESULTS_DIR:-$(mktemp -d)}
mkdir -p "$results_dir"

if [ $# -gt 0 ]; then
    templates=("$@")
else
    templates=()
    for file in "$repo"/scenario_templates/*/map_selection.lua; do
        templates+=("$(basename "$(dirname "$file")")")
    done
fi

if [ -n "${SHARD:-}" ]; then
    shard=${SHARD%/*}
    shards=${SHARD#*/}
    selected=()
    for i in "${!templates[@]}"; do
        if [ $((i % shards)) -eq $((shard - 1)) ]; then
            selected+=("${templates[$i]}")
        fi
    done
    templates=("${selected[@]}")
fi

echo "running ${#templates[@]} templates, $jobs at a time"
run_one() {
    local index=$1 template=$2
    if PORT=$((34400 + index)) RESULTS="$results_dir/$template.json" "$scripts/run-tests.sh" "$factorio_dir" \
        "$template" > "$results_dir/$template.log" 2>&1; then
        echo "pass  $template"
    else
        echo "fail  $template"
    fi
}
export -f run_one
export scripts factorio_dir results_dir

for i in "${!templates[@]}"; do
    echo "$i ${templates[$i]}"
done | xargs -P "$jobs" -L1 bash -c 'run_one "$0" "$1"'

echo
"$scripts/test-summary.sh" "$results_dir"
