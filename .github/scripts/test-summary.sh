#!/usr/bin/env bash
# Sums up the results run-tests.sh saved (a <template>.json each) in one folder: a line per map,
# then every failed test with its error. With GITHUB_STEP_SUMMARY set (in CI), it also writes the
# full list there, every test grouped by map. test-summary.ps1 does the same in PowerShell; keep
# the two in step.
#
# usage: test-summary.sh <results dir> [templates dir]
#
# Given the scenario_templates folder, a template without results counts as a run that didn't
# finish (in CI, a job that stopped before saving them).
#
# Exits non-zero if any test failed, any run didn't finish, or there are no results.
set -euo pipefail

results_dir=$1
templates_dir=${2:-}
shopt -s nullglob
if [ -n "$templates_dir" ]; then
    for file in "$templates_dir"/*/map_selection.lua; do
        template=$(basename "$(dirname "$file")")
        if [ ! -f "$results_dir/$template.json" ]; then
            jq -n --arg map "$template" \
                '{map: $map, seed: null, seconds: 0, error: "no results", log: "", passed: 0, failed: 1, skipped: 0, tests: []}' \
                > "$results_dir/$template.json"
        fi
    done
fi
files=("$results_dir"/*.json)
if [ ${#files[@]} -eq 0 ]; then
    echo "no test results in $results_dir"
    exit 1
fi

# all the results, one array sorted by map
all=$(jq -s 'sort_by(.map | ascii_downcase)' "${files[@]}")

# a map failed if a test failed or its run didn't finish
jq -r '.[] | if .skipped_map then "skip  \(.map)  \(.skipped_map)"
    else "\(if .failed > 0 then "fail" else "pass" end)  \(.map)  passed \(.passed), failed \(.failed), skipped \(.skipped) (seed \(.seed // "?"), \(.seconds) s)" end' <<< "$all"

failures=$(jq -r '.[] | select(.failed > 0) | "\n=== \(.map) (seed \(.seed // "?"))",
    (if .error then (if (.log // "") != "" then "\(.error):\n\(.log)" else .error end) else empty end),
    (.tests[] | select(.result == "fail") | "FAIL \(.path) :: \(.name) :: \(.error)")' <<< "$all")
if [ -n "$failures" ]; then
    printf '%s\n' "$failures"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    jq -r '
        def icon: if . == "pass" then "✅" elif . == "fail" then "❌" else "⏭️" end;
        def ticks: if .ticks then " (\(.ticks) ticks)" else "" end;
        (map(select(.skipped_map | not)) | "### In-game tests: \(map(select(.failed == 0)) | length) of \(length) maps passed\n"),
        (.[] | if .skipped_map then "⏭️ **\(.map)**: skipped, \(.skipped_map)\n"
            else
                "<details\(if .failed > 0 then " open" else "" end)><summary>\(if .failed > 0 then "❌" else "✅" end) <b>\(.map)</b>: \(.passed) passed, \(.failed) failed, \(.skipped) skipped (seed \(.seed // "?"), \(.seconds) s)</summary>\n",
                (if .error then (if (.log // "") != "" then "\(.error):\n```\n\(.log)\n```\n" else "\(.error)\n" end) else empty end),
                (.tests[] | select(.result != "skip") | "- \(.result | icon) `\(.path)` \(.name)\(ticks)" +
                    (if .result == "fail" then "\n  ```\n  \(.error | gsub("\n"; "\n  "))\n  ```" else "" end)),
                # skipped tests by module, not one by one
                (.tests | map(select(.result == "skip")) | group_by(.path)[] |
                    "- ⏭️ `\(.[0].path)`: \(length) skipped, \(.[0].error)"),
                "\n</details>\n"
            end)' <<< "$all" >> "$GITHUB_STEP_SUMMARY"
fi

[ "$(jq '[.[] | select(.failed > 0)] | length' <<< "$all")" -eq 0 ]
