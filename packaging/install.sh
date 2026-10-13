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

case ${1:-} in
--uninstall)
    for entry in "${files[@]}"; do
        read -r _ place _ <<<"$entry"
        rm -f "$root/$place"
    done
    rm -f "$root/bin/demoreel"
    # The folder is demoreel's alone, so it goes whole, catalogs and all.
    rm -rf "$root/share/demoreel"
    exit 0
    ;;
'') ;;
*)
    echo "usage: packaging/install.sh [--uninstall]" >&2
    exit 2
    ;;
esac

for entry in "${files[@]}"; do
    read -r from place mode <<<"$entry"
    install -Dm"$mode" "$src/$from" "$root/$place"
done
# A catalog dropped from po/ since the last install goes with the old ones.
rm -rf "$root/share/demoreel/po"
for po in "$src"/po/*.po; do
    install -Dm644 "$po" "$root/share/demoreel/po/$(basename "$po")"
done
mkdir -p "$root/bin"
ln -sfn ../share/demoreel/demoreel "$root/bin/demoreel"
