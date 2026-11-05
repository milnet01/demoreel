#!/usr/bin/env bash
# Install demoreel's files: the one place that decides where each one goes
# (docs/specs/DEMO-0068-linux-packages.md § 4.1). Every package format calls
# this, and so does an install from source.
#
#   sudo packaging/install.sh                  install from source, under /usr/local
#   sudo packaging/install.sh --uninstall      remove what that installed
#   DESTDIR=<dir> PREFIX=/usr packaging/install.sh   stage a package's tree
#
# Every package build passes PREFIX=/usr; the /usr/local default is for an
# install from source (README § Install from source).
#
# The script goes in <prefix>/share/demoreel/ with po/ beside it, and
# <prefix>/bin/demoreel is a relative symlink to it. demoreel finds its
# catalogs beside the file the symlink resolves to and nowhere else
# (DEMO-0060 § 4.2), so a copy in bin/ would run in English for everyone.
#
# The script is copied as it is: no shebang rewrite, no version stamp, so a
# checksum of the tree's file also checks the installed one.
#
# The licence is left to each format, which knows where its distro wants it.
set -euo pipefail

src=$(cd "$(dirname "$0")/.." && pwd)
prefix=${PREFIX:-/usr/local}
root="${DESTDIR:-}$prefix"

# Every file but the catalogs: source, place under the prefix, mode. Install
# and --uninstall both read this list, so the two cannot drift apart.
files=(
    "demoreel                  share/demoreel/demoreel                     755"
    "demoreel.1                share/man/man1/demoreel.1                   644"
    "completions/demoreel.bash share/bash-completion/completions/demoreel  644"
    "completions/_demoreel     share/zsh/site-functions/_demoreel          644"
    "completions/demoreel.fish share/fish/vendor_completions.d/demoreel.fish 644"
)

# An install from source keeps a list of what it placed and of the folders it
# had to make (DEMO-0294): --uninstall reads it, not this checkout's list, so a
# file an older version installed and this one dropped goes too, and so does a
# folder demoreel made, once it is empty. A package's tree has no list: its
# package manager removes it.
manifest="$root/share/demoreel/installed"
listed() {  # kind: the places the manifest holds of that kind
    [ -f "$manifest" ] && sed -n "s/^$1 //p" "$manifest" || true
}

case ${1:-} in
--uninstall)
    if [ -f "$manifest" ]; then
        while read -r place; do rm -f "$root/$place"; done < <(listed file)
    else
        for entry in "${files[@]}"; do
            read -r _ place _ <<<"$entry"
            rm -f "$root/$place"
        done
    fi
    rm -f "$root/bin/demoreel"
    made=$(listed dir)
    # The folder is demoreel's alone, so it goes whole, catalogs and all.
    rm -rf "$root/share/demoreel"
    # Deepest first; a folder something else has put a file in stays.
    while read -r place; do
        [ -n "$place" ] && rmdir "$root/$place" 2>/dev/null || true
    done < <(sort -r <<<"$made")
    exit 0
    ;;
'') ;;
*)
    echo "usage: packaging/install.sh [--uninstall]" >&2
    exit 2
    ;;
esac

old_files=$(listed file) made=$(listed dir) placed=''
# Each folder above `place` that is not there yet, up to the prefix.
new_folders() {
    local dir
    dir=$(dirname "$1")
    while [ "$dir" != . ] && [ ! -d "$root/$dir" ]; do
        echo "$dir"
        dir=$(dirname "$dir")
    done
}
for entry in "${files[@]}"; do
    read -r from place mode <<<"$entry"
    made+=$'\n'$(new_folders "$place")
    install -Dm"$mode" "$src/$from" "$root/$place"
    placed+=$place$'\n'
done
# A file an earlier install placed and this version no longer has.
while read -r place; do
    [ -n "$place" ] && ! grep -qxF -- "$place" <<<"$placed" && rm -f "$root/$place" || true
done <<<"$old_files"
# A catalog dropped from po/ since the last install goes with the old ones.
rm -rf "$root/share/demoreel/po"
for po in "$src"/po/*.po; do
    install -Dm644 "$po" "$root/share/demoreel/po/$(basename "$po")"
done
made+=$'\n'$(new_folders bin/demoreel)
mkdir -p "$root/bin"
ln -sfn ../share/demoreel/demoreel "$root/bin/demoreel"
if [ -z "${DESTDIR:-}" ]; then
    {
        sed '/^$/d; s/^/file /' <<<"$placed"
        sort -u <<<"$made" | sed '/^$/d; s/^/dir /'
    } > "$manifest"
fi
