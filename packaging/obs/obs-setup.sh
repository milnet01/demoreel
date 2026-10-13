#!/usr/bin/env bash
# Create or update demoreel's OBS project and package
# (docs/specs/DEMO-0068-linux-packages.md § 4.7). The project's repositories
# come from packaging/obs/targets, the list ./ci.sh --obs-check also reads,
# so the two cannot disagree. Running it twice changes nothing; re-run it
# after editing targets.
#
#   packaging/obs/obs-setup.sh             apply the project and package
#   packaging/obs/obs-setup.sh --print     print what it would apply
#
# Needs osc, logged in. Override with OBS_API, OBS_PROJECT and OBS_USER.
set -euo pipefail

api=${OBS_API:-https://api.opensuse.org}
project=${OBS_PROJECT:-home:milnet:demoreel}
user=${OBS_USER:-milnet}
here=$(cd "$(dirname "$0")" && pwd)

repositories() {
    # One per target line: name, then <project>/<repository> to build against.
    # Every package is noarch, so one build architecture serves each.
    while read -r name path _; do
        case $name in ''|'#'*) continue ;; esac
        printf '  <repository name="%s">\n' "$name"
        printf '    <path project="%s" repository="%s"/>\n' "${path%/*}" "${path##*/}"
        printf '    <arch>x86_64</arch>\n  </repository>\n'
    done < "$here/targets"
}

project_meta() {
    cat <<EOF
<project name="$project">
  <title>demoreel</title>
  <description>Record a GUI app on a private virtual display, so nothing of your desktop ends up in frame. https://github.com/milnet01/demoreel</description>
  <person userid="$user" role="maintainer"/>
$(repositories)
</project>
EOF
}

package_meta() {
    cat <<EOF
<package name="demoreel" project="$project">
  <title>demoreel</title>
  <description>Record a GUI app on a private virtual display.</description>
</package>
EOF
}

if [ "${1:-}" = --print ]; then
    project_meta
    package_meta
    exit 0
fi

command -v osc >/dev/null || { echo "obs-setup: osc is not installed" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
project_meta > "$tmp/project.xml"
package_meta > "$tmp/package.xml"
osc -A "$api" meta prj "$project" -F "$tmp/project.xml"
osc -A "$api" meta pkg "$project" demoreel -F "$tmp/package.xml"
echo "obs-setup: $project/demoreel is ready. Next, after a release: packaging/obs/obs-submit.sh"
