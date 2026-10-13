#!/usr/bin/env bash
# Send a published release to OBS (docs/specs/DEMO-0068-linux-packages.md
# § 4.7). Run it on this machine, with your own osc login, once release.yml
# has attached the release's files.
#
#   packaging/obs/obs-submit.sh               submit the checkout's version
#   packaging/obs/obs-submit.sh --dry-run     stage the files in OBS_WORKDIR/staged
#                                             and stop
#   packaging/obs/obs-submit.sh --from DIR    take the tarball and PKGBUILD
#                                             from DIR, not the release
#
# Then packaging/obs/obs-status.sh, then ./ci.sh --obs-check.
#
# OBS builds the release's own tarball, never a second copy of the source
# (INV-11), with the recipes as they stand at the release's tag (INV-12).
# Both are checked before the first osc call. Each recipe takes its version
# from the tarball's demoreel, filled in here; no file in the tree holds one
# (INV-7).
#
# Override with OBS_API, OBS_PROJECT and OBS_WORKDIR. The osc checkout lives
# in OBS_WORKDIR, by default build-obs/ in the tree, which git ignores.
set -euo pipefail

die() { echo "obs-submit: $*" >&2; exit 1; }

api=${OBS_API:-https://api.opensuse.org}
project=${OBS_PROJECT:-home:milnet:demoreel}
package=demoreel
root=$(cd "$(dirname "$0")/../.." && pwd)
workdir=${OBS_WORKDIR:-$root/build-obs}

dry=false from=''
while [ $# -gt 0 ]; do
    case $1 in
    --dry-run) dry=true ;;
    --from) from=$(cd "${2:?--from needs a folder}" && pwd); shift ;;
    *) die "unknown argument: $1" ;;
    esac
    shift
done

v=$(sed -n 's/^__version__ = "\(.*\)"$/\1/p' "$root/demoreel")
[ -n "$v" ] || die "could not read __version__ from demoreel"
tag=v$v

# INV-12: the files OBS builds from are the tag's. The rest of what it builds
# comes inside the release's tarball, so it is the tag's already.
git -C "$root" rev-parse -q --verify "refs/tags/$tag^{commit}" >/dev/null \
    || die "__version__ is $v, and there is no tag $tag"
shipped=(packaging/demoreel.spec packaging/debian-control packaging/obs/debian
         packaging/obs/demoreel.dsc packaging/obs/demoreel-rpmlintrc)
drift=$(git -C "$root" diff --name-only "$tag" -- "${shipped[@]}"
        git -C "$root" ls-files --others --exclude-standard -- "${shipped[@]}")
[ -z "$drift" ] || die "these differ from $tag, which OBS would build them as:
$drift
Commit them in a release, or run from a checkout of $tag."

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
tarball=demoreel-$v.tar.gz
if [ -n "$from" ]; then
    cp "$from/$tarball" "$from/PKGBUILD" "$stage/"
else
    gh release download "$tag" --repo milnet01/demoreel --dir "$stage" \
        --pattern "$tarball" --pattern PKGBUILD \
        || die "release $tag has no $tarball and PKGBUILD attached yet"
fi

# INV-11: the tarball is the one the release's PKGBUILD names, which is the
# one release.yml built and tested.
sum=$(sha256sum "$stage/$tarball" | cut -d' ' -f1)
grep -q "^sha256sums=('$sum')$" "$stage/PKGBUILD" \
    || die "$tarball's checksum ($sum) is not the one the release's PKGBUILD names"

# The .rpm recipe, with the version it otherwise gets from rpmbuild --define.
{ printf '%%define ver %s\n' "$v"; cat "$root/packaging/demoreel.spec"; } > "$stage/demoreel.spec"
[ -e "$root/packaging/obs/demoreel-rpmlintrc" ] \
    && cp "$root/packaging/obs/demoreel-rpmlintrc" "$stage/"

# The .deb recipe. Its control file is written from debian-control, so the
# dependency list has one home; the changelog and .dsc get their version here.
field() { sed -n "s/^$1: //p" "$root/packaging/debian-control"; }
maintainer=$(field Maintainer)
date=$(git -C "$root" log -1 --format=%aD "$tag")
fill() { sed -e "s|@VERSION@|$v|g" -e "s|@MAINTAINER@|$maintainer|g" -e "s|@DATE@|$date|g" "$1"; }
mkdir "$stage/debian"
cp -r "$root/packaging/obs/debian/." "$stage/debian/"
fill "$root/packaging/obs/debian/changelog" > "$stage/debian/changelog"
{
    printf 'Source: demoreel\n'
    printf '%s: %s\n' Section "$(field Section)" Priority "$(field Priority)" \
        Maintainer "$maintainer" Homepage "$(field Homepage)"
    printf 'Build-Depends: debhelper-compat (= 13)\nStandards-Version: 4.7.0\n'
    printf 'Rules-Requires-Root: no\n\n'
    # The binary stanza: debian-control's fields that belong in one. Its
    # Version and Maintainer do not; the changelog and the stanza above
    # carry those.
    awk '/^(Package|Architecture|Section|Depends|Recommends): /
         /^Description: / { d = 1; print; next }
         d && /^ / { print; next }
         { d = 0 }' "$root/packaging/debian-control"
} > "$stage/debian/control"
tar -C "$stage" -czf "$stage/debian.tar.gz" debian
rm -r "$stage/debian"
fill "$root/packaging/obs/demoreel.dsc" > "$stage/demoreel.dsc"

if $dry; then
    rm -rf "$workdir/staged" && mkdir -p "$workdir" && cp -r "$stage" "$workdir/staged"
    echo "obs-submit: dry run, nothing sent. Staged for $project/$package, version $v, in $workdir/staged:"
    ls "$workdir/staged"
    exit 0
fi

command -v osc >/dev/null || die "osc is not installed"
mkdir -p "$workdir"
checkout=$workdir/$project/$package
if [ -d "$checkout/.osc" ]; then
    (cd "$checkout" && osc -A "$api" update)
else
    (cd "$workdir" && osc -A "$api" checkout "$project" "$package")
fi
# The previous release's tarball goes: two would leave the .deb build unsure
# which is its source.
rm -f "$checkout"/demoreel-*.tar.gz
cp "$stage"/* "$checkout/"
cd "$checkout"
osc -A "$api" addremove
osc -A "$api" commit -m "demoreel $v"
echo "obs-submit: committed demoreel $v. Next: packaging/obs/obs-status.sh"
