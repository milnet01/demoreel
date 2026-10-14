#!/usr/bin/env bash
# Wait until every OBS target has finished building demoreel, then print the
# end of the log of each that did not succeed
# (docs/specs/DEMO-0068-linux-packages.md § 4.7). Run it after obs-submit.sh.
# It exits non-zero on a failed build or a timeout, so neither reads as a
# success.
#
# Override with OBS_API, OBS_PROJECT, OBS_PACKAGE, POLL_SECS (default 45) and MAX_POLLS
# (default 80).
set -euo pipefail

api=${OBS_API:-https://api.opensuse.org}
project=${OBS_PROJECT:-home:milnet:demoreel}
package=${OBS_PACKAGE:-demoreel}
poll=${POLL_SECS:-45}
max=${MAX_POLLS:-80}

command -v osc >/dev/null || { echo "obs-status: osc is not installed" >&2; exit 1; }

# A target still on its way. "finished" is the step before "succeeded".
pending() {
    case $1 in
    scheduled|building|dispatching|blocked|signing|finished|unknown|'') return 0 ;;
    *) return 1 ;;
    esac
}

results=''
for ((i = 1; i <= max; i++)); do
    results=$(osc -A "$api" results "$project" "$package" 2>/dev/null || true)
    waiting=0
    # osc also lists each repository's own state, as package _repository.
    # A trailing * marks a state about to change, so it is still pending:
    # straight after a submit every target reads "broken*", left over from
    # before the upload (DEMO-0198).
    while read -r repo _arch pkg status _; do
        [ "${pkg:-}" = "$package" ] || continue
        case $status in *\*) waiting=1; continue ;; esac
        pending "$status" && waiting=1
    done <<<"$results"
    grep -qw -- "$package" <<<"$results" && [ "$waiting" = 0 ] && break
    echo "[poll $i] still building"
    sleep "$poll"
done

echo "$results"
failed=0
if [ "$waiting" != 0 ] || ! grep -qw -- "$package" <<<"$results"; then
    echo "obs-status: timed out with builds pending" >&2
    failed=1
fi
while read -r repo arch pkg status _; do
    [ "${pkg:-}" = "$package" ] || continue
    case ${status%\*} in succeeded|excluded|disabled) continue ;; esac
    failed=1
    echo "########## $repo ($status) ##########"
    osc -A "$api" buildlog "$project" "$package" "$repo" "$arch" 2>&1 | tail -40
done <<<"$results"
[ "$failed" = 0 ] || { echo "obs-status: at least one target did not build" >&2; exit 1; }
echo "obs-status: every target built. Next: ./ci.sh --obs-check"
