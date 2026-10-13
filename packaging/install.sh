#!/usr/bin/env bash
# Install demoreel's files: the one place that decides where each one goes
# (docs/specs/DEMO-0068-linux-packages.md § 4.1). Every package format calls
# this, and so does an install from source.
#
#   DESTDIR=<dir> packaging/install.sh    stage the tree under <dir>, for a package
#   sudo packaging/install.sh             install for real, under /usr
#   PREFIX=/usr/local packaging/install.sh
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
prefix=${PREFIX:-/usr}
root="${DESTDIR:-}$prefix"

install -Dm755 "$src/demoreel" "$root/share/demoreel/demoreel"
for po in "$src"/po/*.po; do
    install -Dm644 "$po" "$root/share/demoreel/po/$(basename "$po")"
done
mkdir -p "$root/bin"
ln -sfn ../share/demoreel/demoreel "$root/bin/demoreel"
install -Dm644 "$src/demoreel.1" "$root/share/man/man1/demoreel.1"
install -Dm644 "$src/completions/demoreel.bash" \
    "$root/share/bash-completion/completions/demoreel"
install -Dm644 "$src/completions/_demoreel" \
    "$root/share/zsh/site-functions/_demoreel"
install -Dm644 "$src/completions/demoreel.fish" \
    "$root/share/fish/vendor_completions.d/demoreel.fish"
