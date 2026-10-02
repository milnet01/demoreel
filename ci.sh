#!/usr/bin/env bash
# The whole CI gate for demoreel.
#
# .github/workflows/ci.yml runs this script and nothing else, so a local run and
# a GitHub run cannot drift apart. Add a check here, never in the workflow.
#
# Run it by hand any time: ./ci.sh
#
# ./ci.sh --docs runs the documentation checks only. The pre-push hook selects
# it on a documentation-only push; it is not a skip, and it is not for you to
# pass by hand to get past a red gate.
#
# ./ci.sh --finishing runs only the checks for the finishing commands (edit,
# trim, caption, join, card, motion, poster), which need no display and take
# seconds. The full gate runs the same checks, from the same function.
set -euo pipefail
cd "$(dirname "$0")"

# Every step below matches demoreel's English messages, so every step runs in
# English whatever the developer's locale (docs/specs/DEMO-0060 § 4.8). A step
# that tests a translation removes this for its own runs, with `env -u LC_ALL`.
export LC_ALL=C
unset LANGUAGE

# The translation template: every message demoreel can show, extracted from
# the source with ast (DEMO-0060 § 4.8). The first argument of each tr() and
# tr_help() call, the first two of each trn(), every entry of ARGPARSE_MESSAGES,
# and each comment in EXAMPLES and RECORD_EXAMPLES (read with tr_listed). An
# argument that is not a string literal fails: a message the extractor cannot
# see is one no catalog can carry. A message argparse formats again with `%`
# says so in an extracted comment, which the catalog checks read. A
# `# translators:` comment on the lines just above a call is extracted beside
# its message (DEMO-0167); one anywhere else fails, rather than being lost.
pot_text() {
    python3 - <<'POTPY'
import ast, pathlib, re, sys
source = pathlib.Path("demoreel").read_text(encoding="utf-8")
tree = ast.parse(source)
lines = source.splitlines()
found, bad, used = {}, [], set()
def add(line, msgid, plural, formatted, note=None):
    key = (msgid, plural)
    first, was, had = found.get(key, (line, False, None))
    found[key] = (min(first, line), was or formatted, had or note)
def note_above(lineno):
    """The `# translators:` comment directly above line `lineno`, if any."""
    at, block = lineno - 2, []
    while at >= 0 and lines[at].strip().startswith("#"):
        block.insert(0, lines[at].strip().lstrip("#").strip())
        at -= 1
    if block and block[0].startswith("translators:"):
        used.add(at + 2)
        return " ".join(block)
for node in ast.walk(tree):
    names = {t.id for t in getattr(node, "targets", []) if isinstance(t, ast.Name)}
    if isinstance(node, ast.Assign) and names & {"ARGPARSE_MESSAGES", "EXAMPLES",
                                                 "RECORD_EXAMPLES"}:
        for item in node.value.elts:
            item = item.elts[0] if isinstance(item, ast.Tuple) else item
            if not (isinstance(item, ast.Constant) and isinstance(item.value, str)):
                bad.append(item.lineno)
                continue
            add(item.lineno, item.value, None, True)
    if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
            and node.func.id in ("tr", "trn", "tr_help")):
        continue
    wanted = 2 if node.func.id == "trn" else 1
    args = node.args[:wanted]
    if len(args) < wanted or not all(isinstance(a, ast.Constant) and isinstance(a.value, str)
                                     for a in args):
        bad.append(node.lineno)
        continue
    add(node.lineno, args[0].value, args[1].value if wanted == 2 else None,
        node.func.id == "tr_help", note_above(node.lineno))
for line in bad:
    print(f"demoreel line {line}: a translated message must be a string literal, "
          "or no catalog can carry it", file=sys.stderr)
stray = [n + 1 for n, text in enumerate(lines)
         if text.strip().startswith("# translators:") and n + 1 not in used]
for line in stray:
    print(f"demoreel line {line}: a `# translators:` comment must sit directly "
          "above the tr() call it explains", file=sys.stderr)
if bad or stray or not found:
    sys.exit(1)
def q(text):
    text = (text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t")
            .replace("\n", "\\n"))
    parts = re.findall(r".*?\\n|.+$", text)
    return f'"{text}"' if len(parts) < 2 else '""\n' + "\n".join(f'"{p}"' for p in parts)
out = ["# demoreel's messages: the template every catalog starts from.",
       "# Made by ./ci.sh --pot from the source. Do not edit it by hand.",
       'msgid ""', 'msgstr ""', '"Project-Id-Version: demoreel\\n"',
       '"Content-Type: text/plain; charset=UTF-8\\n"',
       '"Content-Transfer-Encoding: 8bit\\n"', '"Language: \\n"',
       '"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"',
       '"X-Demoreel-Review: draft\\n"']
for (msgid, plural), (_, formatted, note) in sorted(found.items(),
                                                    key=lambda kv: kv[1][0]):
    out.append("")
    if note:
        out.append(f"#. {note}")
    if formatted:
        out.append("#. argparse formats this text with %")
    out.append(f"msgid {q(msgid)}")
    if plural is None:
        out.append('msgstr ""')
    else:
        out += [f"msgid_plural {q(plural)}", 'msgstr[0] ""', 'msgstr[1] ""']
print("\n".join(out))
POTPY
}

if [ "${1:-}" = "--pot" ]; then
    mkdir -p po
    pot_text > po/demoreel.pot.tmp
    mv po/demoreel.pot.tmp po/demoreel.pot
    echo "wrote po/demoreel.pot"
    exit 0
fi

# A temporary copy of demoreel beside a catalog of its own, built from the
# template (DEMO-0060 § 7): every msgstr is its English wrapped in ⟦ ⟧, with
# placeholders and code tokens untouched. A copy, because a catalog committed
# beside the real script would be a shipped language.
# Usage: pseudo_copy DIR CODE [REVIEW] -> DIR/demoreel and DIR/po/CODE.po
pseudo_copy() {
    mkdir -p "$1/po"
    cp demoreel "$1/demoreel"
    python3 - "$1/po/$2.po" "$2" "${3:-draft}" <<'PSEUDOPY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
path, code, review = sys.argv[1:]
def q(text):
    return '"' + (text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t")
                  .replace("\n", "\\n")) + '"'
out = ['msgid ""', 'msgstr ""', q("Content-Type: text/plain; charset=UTF-8\n"),
       q(f"Language: {code}\n"), q("Plural-Forms: nplurals=2; plural=n != 1;\n"),
       q(f"X-Demoreel-Review: {review}\n")]
with open("po/demoreel.pot", encoding="utf-8") as template:
    entries = d.read_po(template.read())
for e in entries:
    if not e["msgid"]:
        continue
    out += ["", f"msgid {q(e['msgid'])}"]
    if e["plural"] is None:
        out.append(f"msgstr {q('⟦' + e['msgid'] + '⟧')}")
    else:
        out += [f"msgid_plural {q(e['plural'])}", f"msgstr[0] {q('⟦' + e['msgid'] + '⟧')}",
                f"msgstr[1] {q('⟦' + e['plural'] + '⟧')}"]
with open(path, "w", encoding="utf-8") as catalog:
    catalog.write("\n".join(out) + "\n")
PSEUDOPY
}
# The environment a translated run gets: the gate's LC_ALL removed, so that
# only what a run is testing can make it English (DEMO-0060 § 7).
PSEUDO_ENV=(env -u LC_ALL -u LC_MESSAGES LANGUAGE=zz LANG=de_DE.UTF-8)

# The catalog checks (DEMO-0060 § 4.8), each over the catalogs it is given:
#   python3 -c "$CATALOG_PY" CHECK TEMPLATE CATALOG...
# CHECK is reads, complete, placeholders, digest or print-digest. Each reads a
# catalog with demoreel's own reader and judges it with demoreel's own rules,
# so the gate and a run cannot disagree about what a catalog may hold.
CATALOG_PY=$(cat <<'CATALOGPY'
import hashlib, importlib.machinery, importlib.util, pathlib, re, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
check, template, *paths = sys.argv[1:]
if check not in ("reads", "complete", "placeholders", "digest", "print-digest"):
    sys.exit(f"no catalog check called {check!r}")
FORMATTED = "#. argparse formats this text with %"
pot = pathlib.Path(template).read_text(encoding="utf-8").split("\n")
# Every message, and whether argparse formats it again with % (§ 4.6).
wanted = {(e["msgid"], e["plural"]): pot[e["line"] - 2] == FORMATTED
          for e in d.read_po("\n".join(pot)) if e["msgid"]}
if len(wanted) < 100:
    sys.exit(f"the template holds only {len(wanted)} messages, so it was not read right")

def digest(entries):
    """§ 4.9: the first 16 hex digits of the SHA-256 of the translations."""
    h = hashlib.sha256()
    for e in sorted((e for e in entries if e["msgid"] and not e["fuzzy"]),
                    key=lambda e: (e["msgid"], e["plural"] or "")):
        h.update(b"\0".join([e["msgid"].encode(), (e["plural"] or "").encode(),
                             *(form.encode() for form in e["forms"])]) + b"\n")
    return h.hexdigest()[:16]

def header(entries):
    head = next((e for e in entries if not e["msgid"]), None)
    fields = {}
    for line in (head["forms"][0] if head else "").splitlines():
        name, colon, value = line.partition(":")
        if colon:
            fields[name.strip().lower()] = value.strip()
    return fields

problems = []
for path in map(pathlib.Path, paths):
    def say(text):
        problems.append(f"{path}: {text}")
    if check == "reads":
        # § 4.3, and the Language: header against the file name -- exactly
        # what a run would refuse. A name that is not a code is never read.
        if not d.CODE_RE.fullmatch(path.stem):
            say("its name is not a language code, so no run ever reads it")
            continue
        try:
            d.load_catalog(path, path.stem)
        except (OSError, d.CatalogError) as exc:
            say(f"a run refuses it ({exc})")
        continue
    try:
        entries = d.read_po(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, d.CatalogError) as exc:
        say(f"it cannot be read ({exc})")
        continue
    fields = header(entries)
    found = {(e["msgid"], e["plural"]): e for e in entries if e["msgid"]}
    if check == "print-digest":
        print(digest(entries))
    elif check == "digest":
        # INV-16: confirmed means unchanged since the confirmation.
        confirmed = re.fullmatch(r"confirmed ([0-9a-f]{16})",
                                 fields.get("x-demoreel-review", ""))
        if confirmed and confirmed[1] != digest(entries):
            say(f"it is marked confirmed {confirmed[1]}, but its translations now "
                f"give {digest(entries)}: it was edited after it was confirmed")
    elif check == "complete":
        # INV-5: every message, every form, not fuzzy, not empty.
        nplurals = re.search(r"nplurals\s*=\s*([0-9]+)", fields.get("plural-forms", ""))
        if not nplurals:
            say("it has no Plural-Forms, so its plural messages cannot be counted")
            continue
        for msgid, plural in wanted:
            e, name = found.get((msgid, plural)), repr(msgid[:70])
            if e is None:
                say(f"no entry for {name}")
            elif e["fuzzy"]:
                say(f"{name} is fuzzy")
            elif (len(e["forms"]) != (1 if plural is None else int(nplurals[1]))
                    or not all(e["forms"])):
                say(f"{name} is not translated in every form")
    else:
        # INV-7: a run's own rule for placeholders and %, and the same code
        # tokens as the English. A plural form may match either English form.
        for (msgid, plural), formatted in wanted.items():
            e, name = found.get((msgid, plural)), repr(msgid[:70])
            if e is None or e["fuzzy"]:
                continue
            english = msgid if plural is None else msgid + plural
            tokens = [sorted(d.CODE_TOKEN_RE.findall(t)) for t in (msgid, plural or msgid)]
            for form in filter(None, e["forms"]):
                if not d._usable(form, english, plural is not None, formatted):
                    say(f"{name}: its placeholders, or its %, are not the English "
                        f"ones: {form!r:.120}")
                if sorted(d.CODE_TOKEN_RE.findall(form)) not in tokens:
                    say(f"{name}: its code tokens are not the English ones: {form!r:.120}")
for line in problems:
    print(line, file=sys.stderr)
sys.exit(1 if problems else 0)
CATALOGPY
)

# Print a catalog's digest, for recording a confirmation (DEMO-0060 § 4.9).
if [ "${1:-}" = "--catalog-digest" ]; then
    [ $# -eq 2 ] || { echo "usage: ./ci.sh --catalog-digest po/<code>.po" >&2; exit 2; }
    case $2 in /*) catalog=$2 ;; *) catalog=$OLDPWD/$2 ;; esac
    exec python3 -c "$CATALOG_PY" print-digest po/demoreel.pot "$catalog"
fi

# The one definition of what counts as documentation here. The machine-wide
# pre-push hook reads it with `./ci.sh --docs-glob` and does its own matching.
# The GitHub workflow does not: it pipes the changed paths into
# `./ci.sh --docs-mode` below, so the decision has one home as well as its
# value.
DOCS_GLOB='docs/*|*.md|LICENSE|.github/FUNDING.yml'

# The linter version, owned here and installed from here by the workflow. A
# version pinned only in the workflow is a second copy: this script would accept
# whatever ruff happened to be on PATH, so the same commit could lint clean in
# one place and red in the other. That is the drift this file exists to prevent.
RUFF_VERSION='0.16.8'

if [ "${1:-}" = "--docs-glob" ]; then
    printf '%s\n' "$DOCS_GLOB"
    exit 0
fi

if [ "${1:-}" = "--ruff-version" ]; then
    printf '%s\n' "$RUFF_VERSION"
    exit 0
fi

# The Ubuntu packages the gate needs, owned here for the same reason as the ruff
# version: the workflow installs `./ci.sh --ci-packages`, and the parity image
# below is built from the same list, so the two cannot disagree about it.
CI_PACKAGES='ffmpeg xvfb xdotool x11-apps x11-utils x11-xkb-utils xterm zsh fish'

if [ "${1:-}" = "--ci-packages" ]; then
    printf '%s\n' "$CI_PACKAGES"
    exit 0
fi

# The parity leg: this whole gate, run again inside the Ubuntu release GitHub
# runs, with that release's ffmpeg, Xvfb and xterm. A local pass on this
# machine's newer packages once went red on GitHub (DEMO-0073: x264 in Ubuntu's
# ffmpeg 6.1 spread a tiny input change across the frame, and ffmpeg 8 here did
# not). The image is built once, by hand, and reused: a cold build is never
# started inside a push. What goes into it decides its tag, so a changed package
# list or ruff version needs a rebuild, and the gate says so.
PARITY_BASE='docker.io/library/ubuntu:24.04'
# Beyond CI_PACKAGES: what GitHub's runner image already carries and this base
# does not.
PARITY_EXTRA='python3 pipx xauth procps groff-base ca-certificates'
parity_containerfile() {
    cat <<EOF
FROM $PARITY_BASE
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \\
        $CI_PACKAGES $PARITY_EXTRA && rm -rf /var/lib/apt/lists/*
# Not root, as on GitHub: several checks turn on who owns a file.
RUN useradd -m ci
USER ci
ENV PATH=/home/ci/.local/bin:\$PATH
RUN pipx install "ruff==$RUFF_VERSION"
WORKDIR /home/ci
EOF
}
PARITY_IMAGE="localhost/demoreel-ci:$(parity_containerfile | sha256sum | cut -c1-12)"

if [ "${1:-}" = "--parity-build" ]; then
    command -v podman >/dev/null || { echo "podman is not installed" >&2; exit 1; }
    # The build needs nothing from the tree, so its context is an empty folder.
    ctx=$(mktemp -d)
    parity_containerfile | podman build -t "$PARITY_IMAGE" -f - "$ctx"
    rmdir "$ctx"
    # Older builds are superseded by this one; nothing else uses them.
    podman images --format '{{.Repository}}:{{.Tag}}' localhost/demoreel-ci \
        | grep -vxF "$PARITY_IMAGE" | xargs -r podman rmi >/dev/null || true
    echo "built $PARITY_IMAGE"
    exit 0
fi

if [ "${1:-}" = "--version-lockstep" ]; then
    # The post_check for .claude/bump.json, run after a version bump: every
    # place the version is written has to say the same thing. Same shape as
    # --ruff-version and --docs-glob above -- the caller asks this script
    # rather than restating what it would have to keep in step by hand.
    tool=$(sed -n 's/^__version__ = "\(.*\)"$/\1/p' demoreel)
    # The newest DATED section. `[Unreleased]` cannot match: the pattern needs
    # a digit first, and that is what keeps this from passing on an uncut
    # changelog.
    notes=$(sed -n 's/^## \[\([0-9][^]]*\)\].*/\1/p' CHANGELOG.md | head -1)
    if [ -z "$tool" ]; then
        echo "could not read __version__ from demoreel" >&2
        exit 1
    fi
    if [ "$tool" != "$notes" ]; then
        echo "version drift: demoreel says '$tool', CHANGELOG's newest" >&2
        echo "dated section says '${notes:-<none>}'" >&2
        exit 1
    fi
    printf 'version lockstep: %s\n' "$tool"
    exit 0
fi

if [ "${1:-}" = "--docs-mode" ]; then
    # The decision itself, not just the glob it turns on. Callers pipe the
    # changed paths in and run ./ci.sh with whatever comes out, so nobody
    # reimplements the matching. Empty input prints nothing: a change set we
    # cannot see gets the full gate.
    IFS='|' read -r -a globs <<<"$DOCS_GLOB"
    seen=false
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        seen=true
        matched=false
        for g in "${globs[@]}"; do
            # shellcheck disable=SC2053  # $g is a glob here, deliberately
            [[ $path == $g ]] && { matched=true; break; }
        done
        if ! $matched; then
            exit 0
        fi
    done
    if $seen; then
        printf '%s\n' '--docs'
    fi
    exit 0
fi

DOCS_ONLY=false
[ "${1:-}" = "--docs" ] && DOCS_ONLY=true
FINISHING_ONLY=false
[ "${1:-}" = "--finishing" ] && FINISHING_ONLY=true

step() { printf '\n=== %s ===\n' "$1"; }

# The finishing commands (edit, trim, caption, join, card, motion, poster), held
# to README.md § "Finishing a recording". One definition, run by the full gate
# and alone by `./ci.sh --finishing`. Every input is made by ffmpeg from a
# generated source, so nothing here needs a display and it takes seconds.
#
# Each check quotes the README sentence it holds. A refusal is only believed
# after a control: the same command made valid succeeded first, so "refused"
# cannot be a command that fails whatever it is given.
finishing_checks() {
    local DR="$PWD/demoreel" ft="$tmp/fin" fo fe rc
    mkdir -p "$ft/log" "$ft/out" "$ft/shim"
    fo="$ft/log/stdout"; fe="$ft/log/stderr"
    local REAL_FFMPEG; REAL_FFMPEG=$(command -v ffmpeg)

    # ---- helpers ----------------------------------------------------------
    fail() { echo "FAIL: $*" >&2; exit 1; }
    show_err() { sed 's/^/    stderr: /' "$fe" >&2; }
    # Runs demoreel from the folder holding the inputs. rc, stdout and stderr
    # are kept for the assertions. FIN_PATH lets one check put a shim first.
    run() {
        rc=0
        ( cd "$ft" && export SHIM_LOG="$ft/log/ffmpeg.calls" \
              REAL_FFMPEG="$REAL_FFMPEG" && PATH="${FIN_PATH:-$PATH}" \
              "$DR" "$@" ) >"$fo" 2>"$fe" || rc=$?
    }
    expect_ok() {
        [ "$rc" -eq 0 ] && return 0
        echo "FAIL: $1: expected exit 0, got $rc" >&2; show_err; exit 1
    }
    # Refused: non-zero, said why, and did not pretend to finish. The stub's
    # own message is not a reason.
    expect_refused() {
        [ "$rc" -ne 0 ] || fail "$1: expected it to be refused (non-zero exit), got exit 0"
        [ -s "$fe" ] || fail "$1: refused without saying why (stderr empty)"
        if grep -q 'not built yet' "$fe"; then
            echo "FAIL: $1: expected a refusal naming the mistake, got: " >&2
            show_err; exit 1
        fi
        [ ! -s "$fo" ] || fail "$1: refused but printed on stdout: $(cat "$fo")"
    }
    expect_stdout_path() {
        local got; got=$(cat "$fo")
        [ "$got" = "$2" ] || fail "$1: stdout should be the path alone
    expected: $2
    actual:   $got"
    }
    assert_eq() { [ "$2" = "$3" ] || fail "$1
    expected: $2
    actual:   $3"; }
    assert_near() {  # what expected actual tolerance
        awk -v e="$2" -v a="$3" -v t="$4" \
            'BEGIN { d = a - e; if (d < 0) d = -d; exit !(d <= t) }' \
            || fail "$1
    expected: $2 (within $4)
    actual:   $3"
    }
    assert_between() {  # what low high actual
        awk -v lo="$2" -v hi="$3" -v a="$4" 'BEGIN { exit !(a >= lo && a <= hi) }' \
            || fail "$1
    expected: between $2 and $3
    actual:   $4"
    }
    assert_absent() { [ ! -e "$2" ] || fail "$1: expected nothing at $2, but it exists"; }
    assert_file() { [ -s "$2" ] || fail "$1: expected a file at $2, none there"; }
    snap() { ( cd "$ft" && find . -type f -not -path './log/*' -print0 | sort -z \
                 | xargs -0 -r sha256sum | sha256sum ); }
    px() { python3 "$ft/px.py" "$@"; }
    v_dur() { ffprobe -v error -show_entries format=duration -of csv=p=0 "$1"; }
    v_frames() { ffprobe -v error -count_frames -select_streams v:0 \
                   -show_entries stream=nb_read_frames -of csv=p=0 "$1"; }
    v_size() { ffprobe -v error -select_streams v:0 \
                 -show_entries stream=width,height -of csv=s=x:p=0 "$1"; }
    v_rate() { ffprobe -v error -select_streams v:0 \
                 -show_entries stream=avg_frame_rate -of csv=p=0 "$1" \
                 | awk -F/ '{ printf "%.2f", $1 / $2 }'; }
    # H.264, yuv420p, silent, index before the pictures.
    assert_finished() {
        local f=$1 what=$2 codec audio atoms
        assert_file "$what" "$f"
        codec=$(ffprobe -v error -select_streams v:0 \
                  -show_entries stream=codec_name,pix_fmt -of csv=p=0 "$f")
        assert_eq "$what: video codec and pixel format" "h264,yuv420p" "$codec"
        audio=$(ffprobe -v error -select_streams a -show_entries stream=index \
                  -of csv=p=0 "$f" | wc -l)
        assert_eq "$what: number of audio streams" 0 "$audio"
        atoms=$(px atoms "$f")
        printf '%s\n' "$atoms" | awk '{ for (i = 1; i <= NF; i++) {
                if ($i == "moov" && !m) m = i; if ($i == "mdat" && !d) d = i }
                exit !(m && d && m < d) }' \
            || fail "$what: the index (moov) must come before the pictures (mdat)
    expected: moov before mdat
    actual:   top-level boxes in order: $atoms"
    }
    # Frame counts are exact; lengths are checked to a frame or so.
    assert_len() {  # what file frames rate
        assert_eq "$1: number of frames" "$3" "$(v_frames "$2")"
        assert_near "$1: length in seconds" "$(awk -v n="$3" -v r="$4" 'BEGIN{print n/r}')" \
            "$(v_dur "$2")" 0.06
    }
    # Which frame of SRC is frame IDX of FILE (argmin of picture difference).
    assert_is_frame() {  # what file idx src src_idx [lo hi]
        local got; got=$(px match "$2" "$3" "$4" "${@:6}")
        assert_eq "$1: frame $3 of $(basename "$2") should be frame $5 of $(basename "$4")" "$5" "$got"
    }
    luma() { px mean "$1" "$2"; }
    assert_dark() {  # what out idx src src_idx
        local o s; o=$(luma "$2" "$3"); s=$(luma "$4" "$5")
        awk -v o="$o" -v s="$s" 'BEGIN { exit !(o < 0.25 * s) }' \
            || fail "$1: frame $3 should be nearly black
    expected: brightness below 25% of the input's ($s), i.e. under $(awk -v s="$s" 'BEGIN{print 0.25*s}')
    actual:   $o"
    }
    assert_bright() {
        local o s; o=$(luma "$2" "$3"); s=$(luma "$4" "$5")
        awk -v o="$o" -v s="$s" 'BEGIN { exit !(o > 0.8 * s) }' \
            || fail "$1: frame $3 should be the ordinary picture
    expected: brightness above 80% of the input's ($s), i.e. over $(awk -v s="$s" 'BEGIN{print 0.8*s}')
    actual:   $o"
    }
    # Text on a clip shows as a changed bottom strip against the input.
    text_on() {  # what out idx src src_idx
        local n; n=$(px changed "$2" "$3" "$4" "$5" bottom)
        awk -v n="$n" 'BEGIN { exit !(n >= 300) }' \
            || fail "$1: text should be on screen at frame $3
    expected: at least 300 changed pixels in the bottom strip
    actual:   $n"
    }
    text_off() {
        local n; n=$(px changed "$2" "$3" "$4" "$5" bottom)
        awk -v n="$n" 'BEGIN { exit !(n <= 100) }' \
            || fail "$1: no text should be on screen at frame $3
    expected: at most 100 changed pixels in the bottom strip
    actual:   $n"
    }
    # A card's pixel near a fraction of the frame, against an expected colour.
    assert_colour() {  # what file idx fx fy r g b tol
        local got; got=$(px px "$2" "$3" "$4" "$5")
        set -- "$1" "$got" "$6" "$7" "$8" "$9"
        awk -v g="$2" -v r="$3" -v gg="$4" -v b="$5" -v t="$6" 'BEGIN {
            split(g, c, " ");
            d1 = c[1] - r; d2 = c[2] - gg; d3 = c[3] - b
            if (d1 < 0) d1 = -d1; if (d2 < 0) d2 = -d2; if (d3 < 0) d3 = -d3
            exit !(d1 <= t && d2 <= t && d3 <= t) }' \
            || fail "$1: colour
    expected: $3 $4 $5 (within $6 in each channel)
    actual:   $2"
    }
    # A 320x240 card at 10 a second, written to out/NAME.
    card() { local out=$1; shift; run card -o "$ft/out/$out" -s 320x240 -r 10 "$@"; expect_ok "card $*"; }
    # Line N of the report in $lines.
    l() { printf '%s\n' "$lines" | sed -n "$1p"; }
    # A script on standard input, made into out/NAME at 320x240 and 10 a second
    # (a script with a clip in it takes the clip's shape instead).
    ed() { local out=$1; cat > "$ft/sc.txt"; run edit sc.txt -o "$ft/out/$out" -s 320x240 -r 10; }
    ed_ok() { ed "$@"; expect_ok "edit $1 ($(tr '\n' '|' < "$ft/sc.txt"))"; }
    # How many pixels of frame IDX match SPEC (see px.py `find`); the rest of the
    # words are the region, as fractions of the frame.
    n_of() { px find "$@" | awk '{ print $1 }'; }
    # A comparison of two numbers, spelled out when it fails.
    assert_cmp() {  # what a op b
        awk "BEGIN { exit !($2 $3 $4) }" || fail "$1
    expected: $2 $3 $4
    actual:   $2 = $(awk "BEGIN { print $2 }" 2>/dev/null), wanted $3 $4"
    }
    # Refused, the message names line N, and nothing was left at -o.
    refused_naming_line() {  # what out line
        expect_refused "$1"
        grep -qiE "line[^0-9]{0,3}$3([^0-9.]|\$)" "$fe" || fail "$1: the message should name line $3
    expected: 'line $3' on stderr
    actual:   $(cat "$fe")"
        assert_absent "$1" "$ft/out/$2"
    }
    # Each check below runs on its own, so one failing does not hide the next:
    # a check that fails ends only itself, and the run fails at the end.
    fin_failed=0
    fin_step() {
        local st
        step "$1"
        set +e; ( set -e; "$2" ); st=$?; set -e
        [ "$st" -eq 0 ] || fin_failed=$((fin_failed + 1))
    }

    # ---- the pieces every check works from --------------------------------
    step "finishing: inputs are generated, not recorded"
    # A: 6 s, 320x240, 10/s, a different hue each second, a bar that moves so
    # no two frames match, and a sound track (an input's sound must be dropped).
    # C: moving 0-3 s, still 3-5, moving 5-7, still 7-9, so the stills start and
    # end at known times. B: another rate. W and T: another shape.
    cat > "$ft/px.py" <<'FINPY'
import subprocess, sys

REGIONS = {"full": (0, 1), "top": (0, .7), "bottom": (.8, 1),
           "centre": (.35, .65), "topband": (0, .3), "lower": (.6, 1)}


def run(cmd):
    return subprocess.run(cmd, capture_output=True, check=True).stdout


def size(f):
    out = run(["ffprobe", "-v", "error", "-select_streams", "v:0",
               "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0",
               f]).decode().strip()
    w, h = out.split("x")
    return int(w), int(h)


def frames(f, w=80, h=50):
    raw = run(["ffmpeg", "-v", "error", "-i", f, "-vf",
               f"scale={w}:{h}:flags=area", "-fps_mode", "passthrough",
               "-f", "rawvideo", "-pix_fmt", "rgb24", "-"])
    n = w * h * 3
    return [raw[i:i + n] for i in range(0, len(raw) - n + 1, n)]


def one(f, idx, w=80, h=50):
    fr = frames(f, w, h)
    if idx >= len(fr):
        sys.exit(f"{f} has {len(fr)} frames, no frame {idx}")
    return fr[idx]


def cut(data, w, h, name):
    a, b = REGIONS[name]
    return data[int(a * h) * w * 3:int(b * h) * w * 3]


def luma(data):
    r, g, b = data[0::3], data[1::3], data[2::3]
    return (0.299 * sum(r) + 0.587 * sum(g) + 0.114 * sum(b)) / max(len(r), 1)


def dist(x, y):
    return sum(abs(p - q) for p, q in zip(x, y)) / max(len(x), 1)


def main(argv):
    cmd = argv[0]
    if cmd == "mean":        # FILE IDX [REGION]
        d = cut(one(argv[1], int(argv[2])), 80, 50,
                argv[3] if len(argv) > 3 else "full")
        print(f"{luma(d):.2f}")
    elif cmd == "diff":      # FILE IDX FILE IDX [REGION]
        reg = argv[5] if len(argv) > 5 else "full"
        a = cut(one(argv[1], int(argv[2])), 80, 50, reg)
        b = cut(one(argv[3], int(argv[4])), 80, 50, reg)
        print(f"{dist(a, b):.2f}")
    elif cmd == "match":     # FILE IDX SRC [LO HI]: which SRC frame is FILE's IDX
        target = one(argv[1], int(argv[2]))
        src = frames(argv[3])
        lo = int(argv[4]) if len(argv) > 4 else 0
        hi = int(argv[5]) if len(argv) > 5 else len(src) - 1
        best = min(range(lo, min(hi, len(src) - 1) + 1),
                   key=lambda i: dist(target, src[i]))
        print(best)
    elif cmd == "bbox":      # FILE IDX #RRGGBB: box of what differs from the background
        f, idx, hexcol = argv[1], int(argv[2]), argv[3].lstrip("#")
        bg = tuple(int(hexcol[i:i + 2], 16) for i in (0, 2, 4))
        w, h = size(f)
        d = one(f, idx, w, h)
        xs, ys = [], []
        for y in range(h):
            row = d[y * w * 3:(y + 1) * w * 3]
            for x in range(w):
                p = row[x * 3:x * 3 + 3]
                if max(abs(p[i] - bg[i]) for i in range(3)) > 60:
                    xs.append(x)
                    ys.append(y)
        if not xs:
            print("none")
        else:
            print(min(xs) / w, min(ys) / h, (max(xs) + 1) / w, (max(ys) + 1) / h)
    elif cmd == "px":        # FILE IDX FX FY: colour near that fraction of the frame
        f, idx = argv[1], int(argv[2])
        fx, fy = float(argv[3]), float(argv[4])
        w, h = size(f)
        d = one(f, idx, w, h)
        x0, y0 = int(fx * w), int(fy * h)
        acc = [0, 0, 0]
        n = 0
        for y in range(max(y0 - 2, 0), min(y0 + 3, h)):
            for x in range(max(x0 - 2, 0), min(x0 + 3, w)):
                for i in range(3):
                    acc[i] += d[(y * w + x) * 3 + i]
                n += 1
        print(*(round(a / n) for a in acc))
    elif cmd == "minmax":    # FILE IDX REGION: darkest and brightest luma at full size
        f, idx = argv[1], int(argv[2])
        w, h = size(f)
        d = cut(one(f, idx, w, h), w, h, argv[3])
        ls = [0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2]
              for i in range(0, len(d), 3)]
        print(f"{min(ls):.0f} {max(ls):.0f}")
    elif cmd == "changed":   # FILE IDX FILE IDX REGION: pixels differing by >40
        f, idx = argv[1], int(argv[2])
        w, h = size(f)
        a = cut(one(f, idx, w, h), w, h, argv[5])
        b = cut(one(argv[3], int(argv[4]), w, h), w, h, argv[5])
        print(sum(1 for i in range(0, len(a), 3)
                  if max(abs(a[i + k] - b[i + k]) for k in range(3)) > 40))
    elif cmd == "whitened":  # FILE IDX SRC IDX REGION: pixels white here, not white there
        f, idx = argv[1], int(argv[2])
        w, h = size(f)
        a = cut(one(f, idx, w, h), w, h, argv[5])
        b = cut(one(argv[3], int(argv[4]), w, h), w, h, argv[5])
        print(sum(1 for i in range(0, len(a), 3)
                  if min(a[i:i + 3]) > 220 and min(b[i:i + 3]) <= 220))
    elif cmd == "find":      # FILE IDX SPEC [X0 Y0 X1 Y1]: count and box of matching pixels
        # SPEC is #RRGGBB:TOLERANCE (each channel within it), dark:LUMA or
        # light:LUMA. The box is in fractions of the frame; the region likewise.
        f, idx, spec = argv[1], int(argv[2]), argv[3]
        w, h = size(f)
        d = one(f, idx, w, h)
        rx0, ry0, rx1, ry1 = (float(v) for v in argv[4:8]) if len(argv) > 4 else (0, 0, 1, 1)
        kind, _, val = spec.partition(":")
        if kind.startswith("#"):
            want = tuple(int(kind[i:i + 2], 16) for i in (1, 3, 5))
            tol = float(val or 60)

            def hit(p):
                return max(abs(p[i] - want[i]) for i in range(3)) <= tol
        else:
            lim = float(val)

            def hit(p):
                y = 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
                return y < lim if kind == "dark" else y > lim
        xs, ys = [], []
        for y in range(int(ry0 * h), int(ry1 * h)):
            for x in range(int(rx0 * w), int(rx1 * w)):
                o = (y * w + x) * 3
                if hit(d[o:o + 3]):
                    xs.append(x)
                    ys.append(y)
        if not xs:
            print(0)
        else:
            print(len(xs), min(xs) / w, min(ys) / h, (max(xs) + 1) / w,
                  (max(ys) + 1) / h)
    elif cmd == "atoms":     # FILE: top-level boxes in order
        names = []
        with open(argv[1], "rb") as fh:
            while True:
                head = fh.read(8)
                if len(head) < 8:
                    break
                n = int.from_bytes(head[:4], "big")
                names.append(head[4:].decode("latin1"))
                if n == 1:
                    n = int.from_bytes(fh.read(8), "big")
                    fh.seek(n - 16, 1)
                elif n == 0:
                    break
                else:
                    fh.seek(n - 8, 1)
        print(*names)
    else:
        sys.exit(f"px.py: unknown command {cmd}")


main(sys.argv[1:])
FINPY
    ff() { ffmpeg -v error -y "$@"; }
    x264="-c:v libx264 -pix_fmt yuv420p -movflags +faststart"
    ff -f lavfi -i "testsrc2=s=320x240:r=10:d=6" -f lavfi -i "sine=d=6" \
       -f lavfi -i "color=c=white:s=16x240:r=10:d=6" \
       -filter_complex "[0:v]hue=h='floor(t)*60'[b];[b][2:v]overlay=x='mod(n*5,300)':y=0,format=yuv420p[v]" \
       -map '[v]' -map 1:a -c:a aac -shortest $x264 "$ft/A.mp4"
    ff -f lavfi -i "testsrc2=s=320x240:r=10:d=8" \
       -vf "select=eq(n\\,77),hue=h=120" -frames:v 1 "$ft/still1.png"
    ff -f lavfi -i "testsrc2=s=320x240:r=10:d=8" \
       -vf "select=eq(n\\,33),hue=h=240" -frames:v 1 "$ft/still2.png"
    ff -f lavfi -i "testsrc2=s=320x240:r=10:d=3" \
       -loop 1 -framerate 10 -t 2 -i "$ft/still1.png" \
       -f lavfi -i "testsrc2=s=320x240:r=10:d=2" \
       -loop 1 -framerate 10 -t 2 -i "$ft/still2.png" \
       -filter_complex "[0:v]setsar=1,format=yuv420p[a];[1:v]fps=10,setsar=1,format=yuv420p[b];[2:v]hue=h=200,setsar=1,format=yuv420p[c];[3:v]fps=10,setsar=1,format=yuv420p[d];[a][b][c][d]concat=n=4:v=1:a=0[v]" \
       -map '[v]' $x264 "$ft/C.mp4"
    ff -f lavfi -i "testsrc=s=320x240:r=15:d=4" $x264 "$ft/B.mp4"
    ff -f lavfi -i "testsrc2=s=640x240:r=10:d=3" $x264 "$ft/W.mp4"
    ff -f lavfi -i "testsrc2=s=320x480:r=10:d=3" $x264 "$ft/T.mp4"
    ff -f lavfi -i "testsrc=s=320x240:r=3:d=3" -r 30 $x264 "$ft/S.mp4"
    ff -f lavfi -i "color=c=#808080:s=320x240:r=10:d=4" $x264 "$ft/G.mp4"
    ff -f lavfi -i "color=c=#00C000:s=800x800" -frames:v 1 "$ft/sq.png"
    # F: 30 a second, a new picture on each frame up to number 40, then still.
    # N: 29.97 a second, where no frame starts on a whole second.
    ff -f lavfi -i "testsrc2=s=320x240:r=30:d=3" \
       -vf "select='lte(n,40)',tpad=stop_mode=clone:stop_duration=2,fps=30" -t 3 $x264 "$ft/F.mp4"
    ff -f lavfi -i "testsrc2=s=320x240:r=30000/1001:d=4" $x264 "$ft/N.mp4"
    printf 'this is not a video\n' > "$ft/bad.mp4"
    # Pictures for cards.
    ff -f lavfi -i "testsrc2=s=100x80:r=10:d=1" -vf "select=eq(n\\,3)" -frames:v 1 "$ft/small.png"
    ff -f lavfi -i "testsrc2=s=800x400:r=10:d=1" -vf "select=eq(n\\,3)" -frames:v 1 "$ft/wide.png"
    ff -f lavfi -i "color=c=red:s=100x80,format=rgba,geq=r=255:g=0:b=0:a='if(lt(X,50),255,0)'" \
       -frames:v 1 "$ft/half.png"
    ff -f lavfi -i "testsrc2=s=100x80:r=10:d=1,hue=h='n*36'" -f gif "$ft/spin.gif"
    ff -f lavfi -i "testsrc2=s=100x80:r=10:d=1,hue=h='n*36'" -plays 0 -f apng "$ft/spin.png"
    assert_eq "A has 60 frames" 60 "$(v_frames "$ft/A.mp4")"
    assert_eq "C has 90 frames" 90 "$(v_frames "$ft/C.mp4")"
    assert_eq "spin.png is animated (frames)" 10 \
        "$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 "$ft/spin.png")"
    cat > "$ft/shim/ffmpeg" <<'SHIM'
#!/bin/sh
# Logs every call, then runs the real ffmpeg. SHIM_MODE=nodraw also makes text
# drawing unavailable, as on an ffmpeg built without it.
echo "$*" >> "$SHIM_LOG"
if [ "$SHIM_MODE" = nodraw ]; then
    case " $* " in
        *" -filters "*) "$REAL_FFMPEG" "$@" | grep -v drawtext; exit 0 ;;
        *drawtext*) echo "shim: no drawtext here" >&2; exit 1 ;;
    esac
fi
exec "$REAL_FFMPEG" "$@"
SHIM
    chmod +x "$ft/shim/ffmpeg"
    echo "inputs made: A (6 s, sound), C (stills at 3-5 and 7-9), B, W, T, S, pictures"

    # ---- trim -------------------------------------------------------------
    fin_s1() {
    # README: "The frame on screen at `from` is the first one kept, and the frame
    # on screen at `to` is the last one kept." A frame every 0.1 s: 2 to 4.5 is the
    # 26 frames from number 20 to number 45.
    run trim A.mp4 -o "$ft/out/t1.mp4" --from 2 --to 4.5
    expect_ok "trim --from 2 --to 4.5"
    assert_len "trim 2 to 4.5" "$ft/out/t1.mp4" 26 10
    assert_is_frame "trim: first frame" "$ft/out/t1.mp4" 0 "$ft/A.mp4" 20
    assert_is_frame "trim: last frame" "$ft/out/t1.mp4" 25 "$ft/A.mp4" 45
    # "Leave one out and that end stays where it is."
    run trim A.mp4 -o "$ft/out/t2.mp4" --from 4
    expect_ok "trim --from 4"
    assert_len "trim from 4, no --to" "$ft/out/t2.mp4" 20 10
    assert_is_frame "trim from 4: first frame" "$ft/out/t2.mp4" 0 "$ft/A.mp4" 40
    run trim A.mp4 -o "$ft/out/t3.mp4" --to 1.9
    expect_ok "trim --to 1.9"
    assert_len "trim to 1.9, no --from" "$ft/out/t3.mp4" 20 10
    assert_is_frame "trim to 1.9: first frame" "$ft/out/t3.mp4" 0 "$ft/A.mp4" 0
    assert_is_frame "trim to 1.9: last frame" "$ft/out/t3.mp4" 19 "$ft/A.mp4" 19
    echo "trim cut on the frames asked for and kept the one at --to"

    }
    fin_s2() {
    # README: "Every command that writes a video writes a silent H.264 `.mp4`
    # with its index at the front ... Sound in an input is dropped." A has sound.
    # And: "stdout carries the finished path and nothing else."
    run trim A.mp4 -o "$ft/out/f1.mp4" --from 1 --to 3
    expect_ok "trim of a video with sound"
    expect_stdout_path "trim" "$ft/out/f1.mp4"
    assert_finished "$ft/out/f1.mp4" "trim of a video with sound"
    run caption A.mp4 -o "$ft/out/f2.mp4" --text hi
    expect_ok "caption"
    expect_stdout_path "caption" "$ft/out/f2.mp4"
    assert_finished "$ft/out/f2.mp4" caption
    run join A.mp4 B.mp4 -o "$ft/out/f3.mp4"
    expect_ok "join"
    expect_stdout_path "join" "$ft/out/f3.mp4"
    assert_finished "$ft/out/f3.mp4" join
    run card -o "$ft/out/f4.mp4" -d 1 -s 320x240 -r 10
    expect_ok "card"
    expect_stdout_path "card" "$ft/out/f4.mp4"
    assert_finished "$ft/out/f4.mp4" card
    printf 'clip A.mp4 from 1 to 2\n' > "$ft/f5.txt"
    run edit f5.txt -o "$ft/out/f5.mp4"
    expect_ok "edit"
    expect_stdout_path "edit" "$ft/out/f5.mp4"
    assert_finished "$ft/out/f5.mp4" edit
    echo "trim, caption, join, card and edit each wrote a silent yuv420p H.264 file, index first, path alone on stdout"

    }
    fin_s3() {
    # README: "-o ... may not be one of the files being read. A command never
    # writes over its own input." and "-o must end in .mp4; any other ending is
    # refused."
    cp "$ft/A.mp4" "$ft/in.mp4"; cp "$ft/B.mp4" "$ft/in2.mp4"
    ln -sf in.mp4 "$ft/alias.mp4"
    run trim in.mp4 -o "$ft/out/ctl.mp4" --to 2
    expect_ok "control: trim to another file"
    printf 'clip in.mp4 from 1 to 2\n' > "$ft/self.txt"
    before=$(snap)
    for target in "$ft/in.mp4" ./in.mp4 alias.mp4; do
        run trim in.mp4 -o "$target" --to 2
        expect_refused "trim with -o $target (the input itself)"
    done
    run caption in.mp4 -o in.mp4 --text hi
    expect_refused "caption with -o the input"
    run join in.mp4 in2.mp4 -o in2.mp4
    expect_refused "join with -o one of its inputs"
    run card -o in.mp4 -d 1 --like in.mp4
    expect_refused "card with -o the file --like reads"
    run edit self.txt -o in.mp4
    expect_refused "edit with -o a clip the script reads"
    assert_eq "an input is left untouched by a refused command" "$before" "$(snap)"
    for bad in out.mov out.txt out noext.MP4x; do
        run trim in.mp4 -o "$ft/out/$bad" --to 2
        expect_refused "trim with -o ending in the wrong way ($bad)"
        assert_absent "trim -o $bad" "$ft/out/$bad"
    done
    for cmd in caption card join; do
        case $cmd in
            caption) set -- caption in.mp4 --text hi ;;
            card)    set -- card -d 1 ;;
            join)    set -- join in.mp4 in2.mp4 ;;
        esac
        run "$@" -o "$ft/out/wrong.mov"
        expect_refused "$cmd with -o ending .mov"
        assert_absent "$cmd -o .mov" "$ft/out/wrong.mov"
    done
    run edit f5.txt -o "$ft/out/wrong.mov"
    expect_refused "edit with -o ending .mov"
    assert_absent "edit -o .mov" "$ft/out/wrong.mov"
    echo "an input is never overwritten; -o must end in .mp4"

    }
    fin_s4() {
    # README: "A time past the end of the file is an error, not a guess." and
    # "A `to` equal to the file's length, as `motion` prints it, is accepted and
    # means the last frame."
    run trim A.mp4 -o "$ft/out/e1.mp4" --to 6
    expect_ok "trim --to 6 (the length of a 6 s file)"
    assert_eq "trim --to <length>: frames (means the last frame)" 60 "$(v_frames "$ft/out/e1.mp4")"
    for args in "--to 6.5" "--to 99" "--from 6.5" "--from 99 --to 100"; do
        run trim A.mp4 -o "$ft/out/e2.mp4" $args
        expect_refused "trim $args on a 6 s file"
        assert_absent "trim $args" "$ft/out/e2.mp4"
    done
    run motion A.mp4 --to 99
    expect_refused "motion --to 99 on a 6 s file"
    run poster A.mp4 -t 99 -o "$ft/out/e3.png"
    expect_refused "poster -t 99 on a 6 s file"
    assert_absent "poster -t 99" "$ft/out/e3.png"
    printf 'clip A.mp4 from 2 to 99\n' > "$ft/e4.txt"
    run edit e4.txt -o "$ft/out/e4.mp4"
    expect_refused "edit: clip to 99 on a 6 s file"
    echo "times past the end were refused; --to at the length was accepted"

    }
    fin_s5() {
    # README: "A command that fails leaves nothing at `-o`. A file already there
    # is left as it was."
    cp "$ft/B.mp4" "$ft/out/keep.mp4"
    keep=$(sha256sum < "$ft/out/keep.mp4")
    run trim A.mp4 -o "$ft/out/keep.mp4" --to 2
    expect_ok "control: a good trim may write over an older output"
    cp "$ft/B.mp4" "$ft/out/keep.mp4"
    before=$(snap)
    for what in "trim A.mp4 --to 99" "trim bad.mp4 --to 1" "caption bad.mp4 --text hi" \
                "join A.mp4 W.mp4" "join A.mp4 bad.mp4" "join A.mp4"; do
        # shellcheck disable=SC2086
        run ${what%% *} ${what#* } -o "$ft/out/keep.mp4"
        expect_refused "$what, -o an existing file"
        assert_eq "$what: the file already at -o" "$keep" "$(sha256sum < "$ft/out/keep.mp4")"
        # shellcheck disable=SC2086
        run ${what%% *} ${what#* } -o "$ft/out/nothing.mp4"
        expect_refused "$what"
        assert_absent "$what" "$ft/out/nothing.mp4"
    done
    run edit e4.txt -o "$ft/out/keep.mp4"
    expect_refused "edit with a bad line, -o an existing file"
    assert_eq "edit: the file already at -o" "$keep" "$(sha256sum < "$ft/out/keep.mp4")"
    assert_eq "no stray file after failures" "$before" "$(snap)"
    echo "failures left nothing new and the older file byte for byte"

    # ---- motion -----------------------------------------------------------
    }
    fin_s6() {
    # README: the report is `duration`, `frames`, `new frames`, `new frames per
    # second`, `last change`, then one `still` line for each stretch.
    run motion C.mp4
    expect_ok "motion C.mp4"
    lines=$(cat "$fo")
    printf '%s\n' "$(l 1)" | grep -qE '^duration: [0-9]+\.[0-9]{3}$' \
        || fail "motion line 1: expected 'duration: N.NNN', actual: '$(l 1)'"
    printf '%s\n' "$(l 2)" | grep -qE '^frames: [0-9]+$' \
        || fail "motion line 2: expected 'frames: N', actual: '$(l 2)'"
    printf '%s\n' "$(l 3)" | grep -qE '^new frames: [0-9]+$' \
        || fail "motion line 3: expected 'new frames: N', actual: '$(l 3)'"
    printf '%s\n' "$(l 4)" | grep -qE '^new frames per second: [0-9]+\.[0-9]{2}$' \
        || fail "motion line 4: expected 'new frames per second: N.NN', actual: '$(l 4)'"
    printf '%s\n' "$(l 5)" | grep -qE '^last change: [0-9]+\.[0-9]{3}$' \
        || fail "motion line 5: expected 'last change: N.NNN', actual: '$(l 5)'"
    rest=$(printf '%s\n' "$lines" | sed -n '6,$p')
    printf '%s\n' "$rest" | grep -vE '^still: [0-9]+\.[0-9]{3} to [0-9]+\.[0-9]{3} \([0-9]+\.[0-9]{3}\)$' \
        | grep -q . && fail "motion: every line after the fifth should be 'still: N.NNN to N.NNN (N.NNN)'
    actual: $rest"
    # What the numbers mean, on a clip made to stand still at 3-5 and at 7-9.
    assert_eq "motion: frames" "$(v_frames "$ft/C.mp4")" "$(l 2 | sed 's/^frames: //')"
    assert_near "motion: duration" 9 "$(l 1 | sed 's/^duration: //')" 0.06
    new=$(l 3 | sed 's/^new frames: //')
    assert_between "motion: new frames (30 + 1 + 20 + 1 by the clip's construction)" 50 56 "$new"
    assert_near "motion: new frames per second is new frames over duration" \
        "$(awk -v n="$new" 'BEGIN { printf "%.2f", n / 9 }')" \
        "$(l 4 | sed 's/^new frames per second: //')" 0.1
    echo "the plain report has the README's lines, in its order"

    }
    fin_s7() {
    # README: "`last change` — the time of the last new frame." "`still` — one
    # line for each stretch with no change longer than `--still` seconds (1
    # unless you say). Its start is the time of the last new frame before it,
    # its end is the time of the next new frame, or the end of the video, and
    # its length is in brackets. No such stretch, no such line."
    run motion C.mp4
    expect_ok "motion C.mp4"
    lines=$(cat "$fo")
    rest=$(printf '%s\n' "$lines" | sed -n '6,$p')
    last=$(l 5 | sed 's/^last change: //')
    assert_near "motion: last change (the clip goes still for good at 7.0)" 7 "$last" 0.25
    assert_eq "motion: number of still lines (3-5 and 7-9)" 2 "$(printf '%s\n' "$rest" | grep -c '^still:')"
    s1=$(printf '%s\n' "$rest" | sed -n 1p); s2=$(printf '%s\n' "$rest" | sed -n 2p)
    read -r _ a1 _ b1 c1 <<<"$s1"; c1=${c1//[()]/}
    read -r _ a2 _ b2 c2 <<<"$s2"; c2=${c2//[()]/}
    assert_near "first still: start" 3 "$a1" 0.25
    assert_near "first still: end (the next new picture)" 5 "$b1" 0.25
    assert_near "first still: bracketed length is end minus start" "$(awk -v a="$a1" -v b="$b1" 'BEGIN{print b-a}')" "$c1" 0.002
    assert_near "second still: start" 7 "$a2" 0.25
    assert_near "second still: end (the end of the video)" 9 "$b2" 0.06
    assert_eq "the last still starts at the last change" "$last" "$a2"
    # `--still`: only stretches longer than it.
    run motion C.mp4 --still 2.5
    expect_ok "motion --still 2.5"
    assert_eq "motion --still 2.5: still lines (both stretches are 2 s)" 0 "$(grep -c '^still:' "$fo" || true)"
    run motion C.mp4 --still 1.5
    expect_ok "motion --still 1.5"
    assert_eq "motion --still 1.5: still lines" 2 "$(grep -c '^still:' "$fo")"
    # A clip that never stops has none, and its last change is its last frame.
    run motion A.mp4
    expect_ok "motion A.mp4"
    assert_eq "motion of a clip that never stands still: still lines" 0 "$(grep -c '^still:' "$fo" || true)"
    assert_eq "motion of a moving clip: new frames = frames" 60 "$(sed -n 's/^new frames: //p' "$fo")"
    assert_near "motion of a moving clip: last change is its last frame" 5.9 "$(sed -n 's/^last change: //p' "$fo")" 0.06
    assert_near "motion of a moving clip: new frames per second" 10 "$(sed -n 's/^new frames per second: //p' "$fo")" 0.05
    # `--from` and `--to` look at part; the times printed are still file times.
    run motion C.mp4 --from 6 --to 9
    expect_ok "motion --from 6 --to 9"
    assert_near "motion --from 6 --to 9: duration is the part looked at" 3 "$(sed -n 's/^duration: //p' "$fo")" 0.06
    sl=$(grep '^still:' "$fo" | tail -1)
    read -r _ a3 _ b3 _ <<<"$sl"
    assert_near "motion --from 6 --to 9: the still starts at its time in the file, not in the part" 7 "$a3" 0.25
    # README: "A file can be stored at 30 frames a second and show three new ones."
    run motion S.mp4
    expect_ok "motion of a 3-new-frames-a-second clip stored at 30"
    assert_between "motion: new frames per second of a video stored at 30 showing 3" 2.5 3.5 "$(sed -n 's/^new frames per second: //p' "$fo")"
    assert_eq "motion: frames of a video stored at 30" "$(v_frames "$ft/S.mp4")" "$(sed -n 's/^frames: //p' "$fo")"
    echo "last change and the still lines match the clip's construction"

    }
    fin_s8() {
    # README: "`--json` prints the same report as one JSON object" with keys
    # duration, frames, new_frames, new_frames_per_second, last_change, still
    # (a list of {from, to, seconds}).
    run motion C.mp4
    cp "$fo" "$ft/log/plain"
    run motion C.mp4 --json
    expect_ok "motion --json"
    python3 - "$fo" "$ft/log/plain" <<'JSONPY' || fail "motion --json disagrees with the plain report (see above)"
import json, re, sys
try:
    data = json.loads(open(sys.argv[1]).read())
except ValueError as e:
    sys.exit(f"expected one JSON object on stdout, got: {open(sys.argv[1]).read()[:200]!r} ({e})")
want = ["duration", "frames", "new_frames", "new_frames_per_second",
        "last_change", "still"]
if not isinstance(data, dict) or sorted(data) != sorted(want):
    sys.exit(f"expected keys {sorted(want)}, actual {sorted(data) if isinstance(data, dict) else data!r}")
plain = open(sys.argv[2]).read()
def field(name):
    return float(re.search(rf"^{name}: ([0-9.]+)", plain, re.M).group(1))
for key, name in [("duration", "duration"), ("frames", "frames"),
                  ("new_frames", "new frames"),
                  ("new_frames_per_second", "new frames per second"),
                  ("last_change", "last change")]:
    if abs(data[key] - field(name)) > 0.006:
        sys.exit(f"{key}: expected {field(name)} (the plain report's '{name}'), actual {data[key]}")
stills = re.findall(r"^still: ([0-9.]+) to ([0-9.]+) \(([0-9.]+)\)", plain, re.M)
if len(data["still"]) != len(stills):
    sys.exit(f"still: expected {len(stills)} entries, actual {len(data['still'])}")
for got, (a, b, c) in zip(data["still"], stills):
    if sorted(got) != ["from", "seconds", "to"]:
        sys.exit(f"a still entry should have keys from, to, seconds; actual {sorted(got)}")
    for k, v in (("from", a), ("to", b), ("seconds", c)):
        if abs(got[k] - float(v)) > 0.006:
            sys.exit(f"still {k}: expected {v}, actual {got[k]}")
JSONPY
    echo "the JSON has the README's keys and the plain report's numbers"

    }
    fin_s9() {
    # README: "Reads the video and changes nothing." "`motion` writes no file".
    before=$(snap)
    run motion C.mp4 --still 0.7 --from 1 --to 8
    expect_ok "motion --still 0.7 --from 1 --to 8"
    run motion C.mp4 --json
    expect_ok "motion --json"
    assert_eq "motion left the folder as it was" "$before" "$(snap)"
    echo "motion made and changed no file"

    }
    fin_s10() {
    # README: "So `to` set to the `last change` that `motion` prints ends the
    # scene on the last new picture."
    run motion C.mp4
    expect_ok "motion C.mp4"
    lc=$(sed -n 's/^last change: //p' "$fo")
    lcframe=$(awk -v t="$lc" 'BEGIN { printf "%d", t * 10 + 0.5 }')
    run trim C.mp4 -o "$ft/out/rt.mp4" --to "$lc"
    expect_ok "trim --to $lc"
    assert_eq "trim --to <last change>: frames (the last new picture is the last frame)" \
        "$((lcframe + 1))" "$(v_frames "$ft/out/rt.mp4")"
    assert_is_frame "trim --to <last change>: last frame is the last new picture" \
        "$ft/out/rt.mp4" "$lcframe" "$ft/C.mp4" "$lcframe" 0 "$lcframe"
    run motion "$ft/out/rt.mp4"
    expect_ok "motion of the trimmed clip"
    assert_near "motion of the trimmed clip: its last change is its last frame" \
        "$(awk -v n="$lcframe" 'BEGIN { print n / 10 }')" "$(sed -n 's/^last change: //p' "$fo")" 0.06
    printf 'clip C.mp4 to %s\n' "$lc" > "$ft/rt.txt"
    run edit rt.txt -o "$ft/out/rt2.mp4"
    expect_ok "edit: clip C.mp4 to <last change>"
    assert_eq "edit: clip to <last change>: frames" "$((lcframe + 1))" "$(v_frames "$ft/out/rt2.mp4")"
    echo "trim and edit both ended on the last new picture"

    # ---- poster -----------------------------------------------------------
    }
    fin_s11() {
    # README: "Saves the frame on screen at `-t`, or `--time`, as a picture."
    # "`-o` ends in `.png` or `.jpg`." One picture, the size of the video.
    run poster A.mp4 -t 2.5 -o "$ft/out/p1.png"
    expect_ok "poster -t 2.5 -o .png"
    expect_stdout_path "poster" "$ft/out/p1.png"
    assert_eq "poster .png: codec, size" "png,320,240" \
        "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of csv=p=0 "$ft/out/p1.png")"
    assert_eq "poster .png: one picture" 1 "$(v_frames "$ft/out/p1.png")"
    assert_is_frame "poster -t 2.5" "$ft/out/p1.png" 0 "$ft/A.mp4" 25
    run poster A.mp4 --time 2.55 -o "$ft/out/p2.png"
    expect_ok "poster --time 2.55"
    assert_is_frame "poster --time 2.55 (frame 25 is on screen from 2.5 to 2.6)" "$ft/out/p2.png" 0 "$ft/A.mp4" 25
    run poster A.mp4 -t 4.1 -o "$ft/out/p3.jpg"
    expect_ok "poster -t 4.1 -o .jpg"
    expect_stdout_path "poster .jpg" "$ft/out/p3.jpg"
    assert_eq "poster .jpg: codec, size" "mjpeg,320,240" \
        "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of csv=p=0 "$ft/out/p3.jpg")"
    assert_is_frame "poster -t 4.1 .jpg" "$ft/out/p3.jpg" 0 "$ft/A.mp4" 41
    echo "poster saved frame 25 and frame 41 as a .png and a .jpg"

    }
    fin_s12() {
    # README: "`-t` is required. `-o` ends in `.png` or `.jpg`." "A time past
    # the end of the file is an error".
    run poster A.mp4 -t 1 -o "$ft/out/ok.png"
    expect_ok "control: poster -t 1"
    for bad in p.bmp p.jpeg p.mp4 p; do
        run poster A.mp4 -t 1 -o "$ft/out/$bad"
        expect_refused "poster with -o $bad"
        assert_absent "poster -o $bad" "$ft/out/$bad"
    done
    run poster A.mp4 -t 6.5 -o "$ft/out/late.png"
    expect_refused "poster -t 6.5 on a 6 s file"
    assert_absent "poster -t 6.5" "$ft/out/late.png"
    run poster A.mp4 -o "$ft/out/notime.png"
    expect_refused "poster without -t"
    assert_absent "poster without -t" "$ft/out/notime.png"
    echo "poster refused the wrong endings, a late time and a missing -t"

    # ---- join -------------------------------------------------------------
    }
    fin_s13() {
    # README: "`--crossfade` applies at every join; without it each join is a
    # plain cut." "The two scenes overlap for that long, so the film is that
    # much shorter than its scenes added together." A is 6 s and B is 4 s.
    run join A.mp4 B.mp4 -o "$ft/out/j1.mp4"
    expect_ok "join A B"
    assert_near "join, plain cut: length (6 + 4)" 10 "$(v_dur "$ft/out/j1.mp4")" 0.15
    assert_is_frame "join: frame 10 is still A's" "$ft/out/j1.mp4" 10 "$ft/A.mp4" 10
    run join A.mp4 B.mp4 -o "$ft/out/j2.mp4" --crossfade 0.5
    expect_ok "join --crossfade 0.5"
    assert_near "join with one crossfade: length (6 + 4 - 0.5)" 9.5 "$(v_dur "$ft/out/j2.mp4")" 0.15
    run join A.mp4 B.mp4 A.mp4 -o "$ft/out/j3.mp4" --crossfade 0.5
    expect_ok "join of three, --crossfade 0.5"
    assert_near "join of three with a crossfade at each join: length (16 - 2 x 0.5)" 15 "$(v_dur "$ft/out/j3.mp4")" 0.15
    run join A.mp4 B.mp4 A.mp4 -o "$ft/out/j4.mp4"
    expect_ok "join of three, plain cuts"
    assert_near "join of three with plain cuts: length (6 + 4 + 6)" 16 "$(v_dur "$ft/out/j4.mp4")" 0.15
    echo "lengths: plain cuts add up; each crossfade takes its overlap off"

    }
    fin_s14() {
    # README: "The film's picture size and frame rate are the first clip's ...
    # Every other clip is scaled to the film's size and brought to its frame
    # rate. A clip whose shape differs from the film's, wider or taller, is
    # refused rather than stretched." "`join` takes two or more videos."
    run join B.mp4 A.mp4 -o "$ft/out/j5.mp4"
    expect_ok "join B A"
    assert_eq "join: size is the first clip's" 320x240 "$(v_size "$ft/out/j5.mp4")"
    assert_eq "join: frame rate is the first clip's (B is 15 a second)" 15.00 "$(v_rate "$ft/out/j5.mp4")"
    run join A.mp4 B.mp4 -o "$ft/out/j6.mp4"
    expect_ok "control: join A B"
    assert_eq "join: frame rate is the first clip's (A is 10 a second)" 10.00 "$(v_rate "$ft/out/j6.mp4")"
    for other in W.mp4 T.mp4; do
        run join A.mp4 "$other" -o "$ft/out/j7.mp4"
        expect_refused "join A with $other, a different shape"
        assert_absent "join with $other" "$ft/out/j7.mp4"
    done
    run join A.mp4 -o "$ft/out/j8.mp4"
    expect_refused "join of one video"
    assert_absent "join of one video" "$ft/out/j8.mp4"
    echo "join took the first clip's size and rate, and refused wider and taller clips"

    # ---- card -------------------------------------------------------------
    }
    fin_s15() {
    # README: "`card` takes `-d` for its length, which is required." "Its size
    # and frame rate come from `--like FILE`; `-s` and `-r` set them by hand and
    # win over `--like`. With none of them it is 1600x1000 at 30."
    run card -o "$ft/out/c1.mp4" -d 2 --like B.mp4
    expect_ok "card -d 2 --like B.mp4"
    assert_eq "card --like: size is the clip's" 320x240 "$(v_size "$ft/out/c1.mp4")"
    assert_eq "card --like: rate is the clip's" 15.00 "$(v_rate "$ft/out/c1.mp4")"
    assert_len "card -d 2" "$ft/out/c1.mp4" 30 15
    run card -o "$ft/out/c2.mp4" -d 1 --like B.mp4 -s 200x100 -r 12
    expect_ok "card --like with -s and -r"
    assert_eq "card: -s wins over --like" 200x100 "$(v_size "$ft/out/c2.mp4")"
    assert_eq "card: -r wins over --like" 12.00 "$(v_rate "$ft/out/c2.mp4")"
    run card -o "$ft/out/c3.mp4" -d 1
    expect_ok "card -d 1"
    assert_eq "card with none of them: size" 1600x1000 "$(v_size "$ft/out/c3.mp4")"
    assert_eq "card with none of them: rate" 30.00 "$(v_rate "$ft/out/c3.mp4")"
    run card -o "$ft/out/c4.mp4"
    expect_refused "card without -d"
    assert_absent "card without -d" "$ft/out/c4.mp4"
    echo "card took its shape from --like, -s and -r, and the defaults"

    }
    fin_s16() {
    # README: "`background #202830` sets the colour ... Without it the background
    # is `#101418`." "On a card, the text is the card's title: bold, near the
    # top when the card has a picture and in the middle when it has none. Its
    # height is 7% of the frame's. It is white on a dark background and
    # near-black on a light one."
    card k1.mp4 -d 1
    assert_colour "card with no --background: colour of the frame" "$ft/out/k1.mp4" 5 0.05 0.05 16 20 24 8
    assert_colour "card with no --background: colour of the middle" "$ft/out/k1.mp4" 5 0.5 0.5 16 20 24 8
    card k2.mp4 -d 1 --background '#204060'
    assert_colour "card --background #204060" "$ft/out/k2.mp4" 5 0.05 0.05 32 64 96 8
    card k3.mp4 -d 1 --text 'Saving'
    set -- $(px minmax "$ft/out/k3.mp4" 5 topband)
    [ "$2" -lt 60 ] || fail "card title on a dark card, no picture: the top stays plain
    expected: brightest pixel in the top band under 60
    actual:   $2"
    set -- $(px minmax "$ft/out/k3.mp4" 5 centre)
    [ "$2" -ge 200 ] || fail "card title on a dark card: white text in the middle
    expected: brightest pixel in the middle band at least 200
    actual:   $2"
    bb=$(px bbox "$ft/out/k3.mp4" 5 '#101418')
    [ "$bb" != none ] || fail "card --text: expected text on the card, found nothing"
    assert_between "card title, no picture: vertical centre of the text is the middle" 0.4 0.6 \
        "$(echo "$bb" | awk '{ print ($2 + $4) / 2 }')"
    h_default=$(echo "$bb" | awk '{ print $4 - $2 }')
    card k4.mp4 -d 1 --text 'Saving' --text-size 14
    bb2=$(px bbox "$ft/out/k4.mp4" 5 '#101418')
    assert_between "card --text-size 14 is twice the height of the default 7" 1.6 2.5 \
        "$(awk -v a="$h_default" -v b="$(echo "$bb2" | awk '{ print $4 - $2 }')" 'BEGIN { print b / a }')"
    card k5.mp4 -d 1 --text 'Saving' --background '#f0f0f0'
    set -- $(px minmax "$ft/out/k5.mp4" 5 centre)
    [ "$1" -le 70 ] || fail "card title on a light card: near-black text
    expected: darkest pixel in the middle band at most 70
    actual:   $1"
    card k6.mp4 -d 1 small.png --text 'Saving'
    set -- $(px minmax "$ft/out/k6.mp4" 5 topband)
    [ "$2" -ge 200 ] || fail "card title with a picture: text near the top
    expected: brightest pixel in the top band at least 200
    actual:   $2"
    echo "background, title colour, title place and title size are as README says"

    }
    fin_s17() {
    # README: "A file name after the seconds puts that picture on the card ...
    # It is scaled to fit and centred, never stretched and never enlarged. A
    # see-through picture shows the background through it."
    card m1.mp4 -d 1 small.png
    bb=$(px bbox "$ft/out/m1.mp4" 5 '#101418')
    [ "$bb" != none ] || fail "card with small.png: nothing but background on the card"
    set -- $bb
    assert_near "small 100x80 picture on 320x240: left edge (110/320)" 0.344 "$1" 0.05
    assert_near "small picture: top edge (80/240)" 0.333 "$2" 0.05
    assert_near "small picture: right edge (210/320)" 0.656 "$3" 0.05
    assert_near "small picture: bottom edge (160/240)" 0.667 "$4" 0.05
    card m2.mp4 -d 1 wide.png
    set -- $(px bbox "$ft/out/m2.mp4" 5 '#101418')
    assert_near "wide 800x400 picture: left edge (fits the width)" 0 "$1" 0.05
    assert_near "wide picture: right edge" 1 "$3" 0.05
    assert_near "wide picture: top edge (scaled, not stretched, to 320x160)" 0.167 "$2" 0.05
    assert_near "wide picture: bottom edge" 0.833 "$4" 0.05
    card m3.mp4 -d 1 half.png
    assert_colour "see-through picture: the opaque half is red" "$ft/out/m3.mp4" 5 0.42 0.5 255 0 0 70
    assert_colour "see-through picture: the clear half shows the background" "$ft/out/m3.mp4" 5 0.578 0.5 16 20 24 8
    echo "the picture was fitted, centred and left see-through where it is"

    }
    fin_s18() {
    # README: "An animated picture (`.gif`, or an animated `.png`) plays at its
    # own speed and starts again when it ends, until the card is over." The
    # pictures are one second long, ten frames, a different colour in each.
    for pic in spin.gif spin.png; do
        card an.mp4 -d 3 "$pic"
        assert_len "card $pic -d 3" "$ft/out/an.mp4" 30 10
        moving=$(px changed "$ft/out/an.mp4" 2 "$ft/out/an.mp4" 5 centre)
        again=$(px changed "$ft/out/an.mp4" 5 "$ft/out/an.mp4" 15 centre)
        again2=$(px changed "$ft/out/an.mp4" 5 "$ft/out/an.mp4" 25 centre)
        late=$(px changed "$ft/out/an.mp4" 22 "$ft/out/an.mp4" 25 centre)
        assert_between "$pic: the picture animates (pixels that differ, frame 2 against 5)" 1000 100000 "$moving"
        assert_between "$pic: it starts again after its own second (frame 5 against 15)" 0 500 "$again"
        assert_between "$pic: and again (frame 5 against 25)" 0 500 "$again2"
        assert_between "$pic: it is still animating past its own length (frame 22 against 25)" 1000 100000 "$late"
    done
    echo ".gif and animated .png played, looped and kept playing to the end of the card"

    }
    fin_s19() {
    # README: "Text too wide for the frame at its size is refused. Nothing is
    # shrunk without you asking."
    run card -o "$ft/out/w1.mp4" -d 1 -s 320x240 --text 'Short'
    expect_ok "control: card --text Short"
    run card -o "$ft/out/w2.mp4" -d 1 -s 320x240 --text 'This title is far too wide to ever fit across so small a picture'
    expect_refused "card with a title far wider than 320 pixels"
    assert_absent "card with too wide a title" "$ft/out/w2.mp4"
    echo "a too-wide title was refused, not shrunk"

    # ---- caption ----------------------------------------------------------
    }
    fin_s20() {
    # README: "A text shows from its `from` up to its `to` and not on the frame at
    # `to`" and "`caption` never cuts the video." "On a clip, the text sits on a
    # dark band across the bottom of the picture". Frames are compared with the
    # input's; only the bottom strip is looked at.
    run caption A.mp4 -o "$ft/out/n1.mp4" --text 'Opening a file' --from 1 --to 3
    expect_ok "caption --from 1 --to 3"
    assert_len "caption keeps the whole video" "$ft/out/n1.mp4" 60 10
    text_off "caption, before the window" "$ft/out/n1.mp4" 5 "$ft/A.mp4" 5
    text_off "caption, just before the window" "$ft/out/n1.mp4" 9 "$ft/A.mp4" 9
    text_on  "caption, first frame of the window" "$ft/out/n1.mp4" 10 "$ft/A.mp4" 10
    text_on  "caption, inside the window" "$ft/out/n1.mp4" 20 "$ft/A.mp4" 20
    text_on  "caption, last frame of the window" "$ft/out/n1.mp4" 29 "$ft/A.mp4" 29
    text_off "caption, on the frame at --to" "$ft/out/n1.mp4" 30 "$ft/A.mp4" 30
    text_off "caption, after the window" "$ft/out/n1.mp4" 50 "$ft/A.mp4" 50
    # "Left out, the text stays for the whole scene."
    run caption A.mp4 -o "$ft/out/n2.mp4" --text 'Always here'
    expect_ok "caption with no --from or --to"
    text_on "caption with no times, first frame" "$ft/out/n2.mp4" 0 "$ft/A.mp4" 0
    text_on "caption with no times, last frame" "$ft/out/n2.mp4" 59 "$ft/A.mp4" 59
    # "`size 4` sets another height, as a percentage of the frame's."
    run caption A.mp4 -o "$ft/out/n3.mp4" --text 'Big' --text-size 12
    expect_ok "caption --text-size 12"
    small=$(px whitened "$ft/out/n2.mp4" 20 "$ft/A.mp4" 20 bottom)
    big=$(px whitened "$ft/out/n3.mp4" 20 "$ft/A.mp4" 20 bottom)
    awk -v s="$small" -v b="$big" 'BEGIN { exit !(b > 1.3 * s) }' \
        || fail "caption --text-size 12 should cover more of the frame than the default 5
    expected: more than 1.3 x $small newly white pixels in the bottom strip
    actual:   $big"
    # Two texts, each with its own window; back to back is allowed.
    run caption A.mp4 -o "$ft/out/n4.mp4" --text one --from 1 --to 3 --text two --from 3 --to 5
    expect_ok "caption with back-to-back texts"
    text_on  "back to back: last frame of the first text" "$ft/out/n4.mp4" 29 "$ft/A.mp4" 29
    text_on  "back to back: first frame of the second text" "$ft/out/n4.mp4" 30 "$ft/A.mp4" 30
    text_off "back to back: after the second" "$ft/out/n4.mp4" 50 "$ft/A.mp4" 50
    echo "text showed on frames 10 to 29 only, and back-to-back texts were accepted"

    }
    fin_s21() {
    # README: "A `--from`, `--to` or `--text-size` belongs to the `--text` before
    # it, and one given before the first `--text` is refused: `caption` never
    # cuts the video." "two whose times overlap are refused".
    run caption A.mp4 -o "$ft/out/r0.mp4" --text one --from 1 --to 3
    expect_ok "control: caption with one text"
    for args in "--from 1 --text one" "--to 3 --text one" "--text-size 8 --text one"; do
        run caption A.mp4 -o "$ft/out/r1.mp4" $args
        expect_refused "caption $args"
        assert_absent "caption $args" "$ft/out/r1.mp4"
    done
    run caption A.mp4 -o "$ft/out/r2.mp4" --text one --from 1 --to 4 --text two --from 3 --to 5
    expect_refused "caption with texts overlapping between 3 and 4"
    assert_absent "caption with overlapping texts" "$ft/out/r2.mp4"
    run caption A.mp4 -o "$ft/out/r3.mp4" --text one --text two --from 2 --to 3
    expect_refused "caption with a whole-video text and another beside it"
    assert_absent "caption with a whole-video text and another" "$ft/out/r3.mp4"
    run caption A.mp4 -o "$ft/out/r4.mp4" --text 'This is far too wide to fit across a small frame at any ordinary size at all'
    expect_refused "caption with text wider than the frame"
    assert_absent "caption with too wide a text" "$ft/out/r4.mp4"
    echo "a stray --from and overlapping texts were refused"

    # ---- fades ------------------------------------------------------------
    }
    fin_s22() {
    # README: "`fade-in 1` — the scene starts black and the picture arrives over
    # a second. `fade-out 1` — the picture goes to black over the scene's last
    # second. `fade-at 12` — the picture goes to black just before that moment
    # and comes back just after. Nothing is cut and the scene keeps its length."
    run trim A.mp4 -o "$ft/out/d1.mp4" --fade-in 1 --fade-out 1 --fade-at 3
    expect_ok "trim with --fade-in 1 --fade-out 1 --fade-at 3"
    assert_len "trim with only fades cuts nothing" "$ft/out/d1.mp4" 60 10
    assert_dark   "fade-in: the first frame" "$ft/out/d1.mp4" 0 "$ft/A.mp4" 0
    assert_bright "fade-in: arrived after a second" "$ft/out/d1.mp4" 12 "$ft/A.mp4" 12
    assert_bright "before the fade-at" "$ft/out/d1.mp4" 20 "$ft/A.mp4" 20
    assert_dark   "fade-at 3: the frame at 3" "$ft/out/d1.mp4" 30 "$ft/A.mp4" 30
    assert_bright "after the fade-at" "$ft/out/d1.mp4" 40 "$ft/A.mp4" 40
    assert_bright "before the fade-out" "$ft/out/d1.mp4" 45 "$ft/A.mp4" 45
    assert_dark   "fade-out: the last frame" "$ft/out/d1.mp4" 59 "$ft/A.mp4" 59
    printf 'clip A.mp4 fade-in 1 fade-out 1 fade-at 3\n' > "$ft/d2.txt"
    run edit d2.txt -o "$ft/out/d2.mp4"
    expect_ok "edit: clip with fade-in, fade-out and fade-at"
    assert_len "edit clip with only fades" "$ft/out/d2.mp4" 60 10
    assert_dark   "edit fade-in: first frame" "$ft/out/d2.mp4" 0 "$ft/A.mp4" 0
    assert_bright "edit fade-in: arrived" "$ft/out/d2.mp4" 12 "$ft/A.mp4" 12
    assert_dark   "edit fade-at 3: the frame at 3" "$ft/out/d2.mp4" 30 "$ft/A.mp4" 30
    assert_bright "edit, between the fades" "$ft/out/d2.mp4" 45 "$ft/A.mp4" 45
    assert_dark   "edit fade-out: last frame" "$ft/out/d2.mp4" 59 "$ft/A.mp4" 59
    # "Each half takes `fade-length` seconds, half a second unless the line
    # says otherwise": a longer fade is still dark further from the moment.
    run trim A.mp4 -o "$ft/out/d3.mp4" --fade-at 3 --fade-length 1
    expect_ok "trim --fade-at 3 --fade-length 1"
    assert_dark "fade-length 1: the frame at 3" "$ft/out/d3.mp4" 30 "$ft/A.mp4" 30
    assert_bright "fade-length 1: well before" "$ft/out/d3.mp4" 15 "$ft/A.mp4" 15
    assert_bright "fade-length 1: well after" "$ft/out/d3.mp4" 45 "$ft/A.mp4" 45
    run caption A.mp4 -o "$ft/out/d4.mp4" --text hi --fade-in 1 --fade-out 1
    expect_ok "caption --fade-in 1 --fade-out 1"
    assert_dark "caption --fade-in: first frame" "$ft/out/d4.mp4" 0 "$ft/A.mp4" 0
    assert_dark "caption --fade-out: last frame" "$ft/out/d4.mp4" 59 "$ft/A.mp4" 59
    echo "the three fades darkened the frames named and left every length alone"

    # ---- edit -------------------------------------------------------------
    }
    fin_s23() {
    # README: the example script shape. "Each line is one scene, played in the
    # order written. A blank line, or a line starting with `#`, is ignored. A
    # `#` anywhere else is an ordinary character." "A file named in a script is
    # looked for from the folder you run demoreel in." The scenes, in the film:
    #   0.0-3.0  clip A from 1 to 3.9 (30 frames), fade-in, one text
    #   3.0-5.0  card 2 with a title (which has a # in it)
    #   5.0-8.0  clip C from 2 to 4.9
    #   7.5-10.4 card 2.9 with spin.png, crossfade 0.5 into the clip, fade-out
    cat > "$ft/film.txt" <<'SCRIPT'
# the opening
clip A.mp4 from 1 to 3.9 fade-in 0.5
  text "Opening a file" from 1.5 to 2.5

card 2
  text "Saving # 2"

# a clip that goes still, then a card with a picture
clip C.mp4 from 2 to 4.9

card 2.9 spin.png crossfade 0.5 fade-out 0.5
  text "The saved file"
SCRIPT
    : > "$ft/log/ffmpeg.calls"
    FIN_PATH="$ft/shim:$PATH" run edit film.txt -o "$ft/out/E1.mp4"
    expect_ok "edit film.txt"
    expect_stdout_path "edit" "$ft/out/E1.mp4"
    assert_finished "$ft/out/E1.mp4" "edit"
    assert_near "edit: length (3 + 2 + 3 + 2.9 - 0.5)" 10.4 "$(v_dur "$ft/out/E1.mp4")" 0.15
    assert_eq "edit: size is the first clip's" 320x240 "$(v_size "$ft/out/E1.mp4")"
    assert_eq "edit: rate is the first clip's" 10.00 "$(v_rate "$ft/out/E1.mp4")"
    # README: "`edit` encodes once however many scenes the film has."
    # Counted by the encoder's own name, as a whole word. A bare "264" also
    # matched digits in a temporary path, which failed this step at random.
    encodes=$(grep -cw 'libx264' "$ft/log/ffmpeg.calls" || true)
    assert_eq "edit: number of ffmpeg runs that encode H.264 (four scenes)" 1 "$encodes"
    # README: "the plan goes to stderr" - each scene, and where it ends.
    [ "$(grep -c . "$fe")" -ge 4 ] || fail "edit: the plan on stderr should list each of the 4 scenes
    expected: at least 4 lines on stderr
    actual:   $(grep -c . "$fe") lines: $(cat "$fe")"
    grep -q '10\.4' "$fe" || fail "edit: the plan should say the film ends at 10.4
    expected: '10.4' on stderr
    actual:   $(cat "$fe")"
    # The scenes, in order (a frame from inside each).
    assert_is_frame "edit scene 1 (clip A from 1): frame 20 is A's frame 30" "$ft/out/E1.mp4" 20 "$ft/A.mp4" 30
    text_on  "edit scene 1: its text, 1.5 to 2.5 in the clip, on screen at 0.5 of the film" "$ft/out/E1.mp4" 10 "$ft/A.mp4" 20
    text_off "edit scene 1: its text is gone at the clip's 2.5" "$ft/out/E1.mp4" 16 "$ft/A.mp4" 26
    set -- $(px minmax "$ft/out/E1.mp4" 32 topband)
    [ "$2" -lt 60 ] || fail "edit scene 2 (a card): the top of the card should be plain background
    actual: brightest pixel in the top band $2"
    set -- $(px minmax "$ft/out/E1.mp4" 32 centre)
    [ "$2" -ge 200 ] || fail "edit scene 2: the card's title (with a # in it) should be white in the middle
    actual: brightest pixel in the middle band $2"
    assert_is_frame "edit scene 3 (clip C from 2): frame 55 is C's frame 25" "$ft/out/E1.mp4" 55 "$ft/C.mp4" 25 0 29
    assert_colour "edit scene 4 (card): the card's own corner is the default background" "$ft/out/E1.mp4" 90 0.02 0.02 16 20 24 10
    bb=$(px bbox "$ft/out/E1.mp4" 90 '#101418')
    [ "$bb" != none ] || fail "edit scene 4: expected spin.png and a title on the card, found only background"
    # From a file and from standard input are the same film.
    run edit - -o "$ft/out/E2.mp4" < "$ft/film.txt"
    expect_ok "edit - (script on standard input)"
    expect_stdout_path "edit -" "$ft/out/E2.mp4"
    assert_eq "edit from stdin: frames, as from the file" "$(v_frames "$ft/out/E1.mp4")" "$(v_frames "$ft/out/E2.mp4")"
    assert_near "edit from stdin: length, as from the file" "$(v_dur "$ft/out/E1.mp4")" "$(v_dur "$ft/out/E2.mp4")" 0.02
    # A line is split as a shell splits it; inside double quotes \" is a quote.
    printf 'card 1\n  text "say \\"hi\\""\n' > "$ft/q.txt"
    run edit q.txt -o "$ft/out/E3.mp4" -s 320x240 -r 10
    expect_ok "edit: a text with \\\" inside double quotes"
    set -- $(px minmax "$ft/out/E3.mp4" 5 centre)
    [ "$2" -ge 200 ] || fail "edit: the quoted text should be on the card; brightest middle pixel $2"
    echo "edit made the four scenes in order in one encode, from a file and from stdin"

    }
    fin_s24() {
    # README: "The film's picture size and frame rate are the first clip's. `-s`
    # and `-r` set them by hand. A film with no clip in it, cards only, is
    # 1600x1000 at 30 unless you say." "A clip whose shape differs from the
    # film's, wider or taller, is refused rather than stretched."
    printf 'clip B.mp4\nclip A.mp4\n' > "$ft/g1.txt"
    run edit g1.txt -o "$ft/out/G1.mp4"
    expect_ok "edit: clip B then clip A"
    assert_eq "edit: size (the first clip's)" 320x240 "$(v_size "$ft/out/G1.mp4")"
    assert_eq "edit: rate (the first clip's, 15)" 15.00 "$(v_rate "$ft/out/G1.mp4")"
    assert_near "edit: length (4 + 6)" 10 "$(v_dur "$ft/out/G1.mp4")" 0.15
    run edit g1.txt -o "$ft/out/G2.mp4" -s 160x120 -r 5
    expect_ok "edit -s 160x120 -r 5"
    assert_eq "edit -s: size" 160x120 "$(v_size "$ft/out/G2.mp4")"
    assert_eq "edit -r: rate" 5.00 "$(v_rate "$ft/out/G2.mp4")"
    printf 'card 1\n' > "$ft/g2.txt"
    run edit g2.txt -o "$ft/out/G3.mp4"
    expect_ok "edit: cards only"
    assert_eq "edit, cards only: size" 1600x1000 "$(v_size "$ft/out/G3.mp4")"
    assert_eq "edit, cards only: rate" 30.00 "$(v_rate "$ft/out/G3.mp4")"
    printf 'clip A.mp4\nclip W.mp4\n' > "$ft/g3.txt"
    run edit g3.txt -o "$ft/out/G4.mp4"
    expect_refused "edit with a wider second clip"
    grep -qiE 'line[^0-9]{0,3}2([^0-9.]|$)' "$fe" || fail "edit with a wider second clip: the message should name line 2
    actual: $(cat "$fe")"
    assert_absent "edit with a wider second clip" "$ft/out/G4.mp4"
    echo "size and rate followed the first clip, -s and -r, and the cards-only default"

    }
    fin_s25() {
    # README: "Everything is checked before anything is made. A mistake in the
    # last line of a script stops the run at once, and the message names the
    # line."
    base='clip A.mp4 from 1 to 3
  text "One" from 1 to 2

# a comment
card 1
'
    printf '%s' "$base" > "$ft/h0.txt"
    run edit h0.txt -o "$ft/out/H0.mp4"
    expect_ok "control: the script without its bad last line"
    n=0
    # A time past the end (line 6); a word the language does not have (line 6);
    # a text too wide for the frame, on line 7 under the card on line 6.
    for tail in 'clip A.mp4 from 2 to 99' 'clip A.mp4 blur 3' \
                'card 1
  text "This title is far too wide to ever fit across so small a picture"'; do
        n=$((n + 1))
        printf '%s%s\n' "$base" "$tail" > "$ft/h$n.txt"
        want=6; [ $n -eq 3 ] && want=7
        : > "$ft/log/ffmpeg.calls"
        before=$(snap)
        FIN_PATH="$ft/shim:$PATH" run edit "h$n.txt" -o "$ft/out/H$n.mp4"
        expect_refused "edit with a bad last line ($tail)"
        grep -qiE "line[^0-9]{0,3}$want([^0-9.]|\$)" "$fe" || fail "edit with a bad last line: the message should name line $want
    expected: 'line $want' on stderr
    actual:   $(cat "$fe")"
        assert_eq "edit with a bad last line: ffmpeg runs that encode (nothing is made first)" 0 "$(grep -cw 'libx264' "$ft/log/ffmpeg.calls" || true)"
        assert_absent "edit with a bad last line" "$ft/out/H$n.mp4"
        assert_eq "edit with a bad last line left the folder as it was" "$before" "$(snap)"
    done
    echo "three bad last lines were named by line number and stopped the run before any encode"

    }
    fin_s26() {
    # README: "`crossfade 0.5` — fade from the scene before into this one, over
    # half a second, where a plain cut would otherwise be. The two scenes
    # overlap for that long, so the film is that much shorter than its scenes
    # added together."
    printf 'clip A.mp4 from 0 to 2.9\nclip B.mp4 from 0 to 2 crossfade 0.5\n' > "$ft/x1.txt"
    run edit x1.txt -o "$ft/out/X1.mp4"
    expect_ok "edit with a crossfade"
    assert_near "edit crossfade: length (3 + 2.07 - 0.5)" 4.5 "$(v_dur "$ft/out/X1.mp4")" 0.2
    printf 'clip A.mp4 from 0 to 2.9\nclip B.mp4 from 0 to 2\n' > "$ft/x2.txt"
    run edit x2.txt -o "$ft/out/X2.mp4"
    expect_ok "edit without a crossfade"
    assert_near "edit plain cut: length (3 + 2.07)" 5.0 "$(v_dur "$ft/out/X2.mp4")" 0.2
    awk -v c="$(v_dur "$ft/out/X1.mp4")" -v p="$(v_dur "$ft/out/X2.mp4")" \
        'BEGIN { d = p - c; exit !(d > 0.35 && d < 0.65) }' \
        || fail "edit: a crossfade 0.5 should make the film 0.5 s shorter than plain cuts
    expected: difference between 0.35 and 0.65
    actual:   plain $(v_dur "$ft/out/X2.mp4") crossfade $(v_dur "$ft/out/X1.mp4")"
    echo "the crossfade took its overlap off the film"

    }
    fin_s27() {
    # README: the shortcuts "take the script's words as options and do exactly
    # what the script would."
    run trim A.mp4 -o "$ft/out/S1.mp4" --from 1 --to 3.9
    expect_ok "trim --from 1 --to 3.9"
    printf 'clip A.mp4 from 1 to 3.9\n' > "$ft/s1.txt"
    run edit s1.txt -o "$ft/out/S2.mp4"
    expect_ok "edit: clip A.mp4 from 1 to 3.9"
    assert_eq "trim and one-line script: frames" "$(v_frames "$ft/out/S1.mp4")" "$(v_frames "$ft/out/S2.mp4")"
    assert_near "trim and one-line script: length" "$(v_dur "$ft/out/S1.mp4")" "$(v_dur "$ft/out/S2.mp4")" 0.02
    assert_eq "trim and one-line script: frames is what the times say" 30 "$(v_frames "$ft/out/S1.mp4")"
    d=$(px diff "$ft/out/S1.mp4" 10 "$ft/out/S2.mp4" 10)
    assert_between "trim and one-line script: the same picture at frame 10 (difference)" 0 3 "$d"
    run join A.mp4 B.mp4 -o "$ft/out/S3.mp4" --crossfade 0.5
    expect_ok "join --crossfade 0.5"
    printf 'clip A.mp4\nclip B.mp4 crossfade 0.5\n' > "$ft/s2.txt"
    run edit s2.txt -o "$ft/out/S4.mp4"
    expect_ok "edit: two clips with a crossfade"
    assert_near "join and its script: length" "$(v_dur "$ft/out/S3.mp4")" "$(v_dur "$ft/out/S4.mp4")" 0.05
    run card -o "$ft/out/S5.mp4" -d 2 --like B.mp4 --text 'Saving a file'
    expect_ok "card --like B.mp4 --text"
    printf 'card 2\n  text "Saving a file"\n' > "$ft/s3.txt"
    run edit s3.txt -o "$ft/out/S6.mp4" -s 320x240 -r 15
    expect_ok "edit: card 2 with a text"
    assert_eq "card and its script: frames" "$(v_frames "$ft/out/S5.mp4")" "$(v_frames "$ft/out/S6.mp4")"
    assert_eq "card and its script: size" "$(v_size "$ft/out/S5.mp4")" "$(v_size "$ft/out/S6.mp4")"
    echo "trim, join and card matched the scripts that say the same"

    # ---- check ------------------------------------------------------------
    }
    fin_s28() {
    # README: "`demoreel check` draws a line of text to find out, and reports
    # the finishing commands and their text on lines of their own. Those lines
    # never change its exit status, which still says only whether the default
    # backend can record." The shim makes drawing text impossible while
    # recording still works.
    run check
    rc_plain=$rc; cp "$fo" "$ft/log/check.out"; cat "$fe" >> "$ft/log/check.out"
    : > "$ft/log/ffmpeg.calls"
    SHIM_MODE=nodraw FIN_PATH="$ft/shim:$PATH" run check
    rc_nodraw=$rc; cp "$fo" "$ft/log/check.nodraw"; cat "$fe" >> "$ft/log/check.nodraw"
    finl=$(grep -iE 'edit|trim|caption|join|card|motion|poster|finishing' "$ft/log/check.out" || true)
    [ -n "$finl" ] || fail "check: expected a line about the finishing commands (edit, trim, ...)
    actual output: $(cat "$ft/log/check.out")"
    txtl=$(grep -i 'text' "$ft/log/check.out" || true)
    [ -n "$txtl" ] || fail "check: expected a line about drawing text
    actual output: $(cat "$ft/log/check.out")"
    grep -q 'record' "$ft/log/check.out" || fail "check: the line about recording is gone
    actual output: $(cat "$ft/log/check.out")"
    txtl2=$(grep -i 'text' "$ft/log/check.nodraw" || true)
    [ -n "$txtl2" ] && [ "$txtl2" != "$txtl" ] || fail "check with no way to draw text: its text line should say so
    with text:    $txtl
    without text: $txtl2"
    assert_eq "check: exit status with no way to draw text is the one it has with it" "$rc_plain" "$rc_nodraw"
    echo "check reported the finishing commands and their text; the exit status stayed $rc_plain"
    }
    fin_s29() {
    # README: "`colour #FFD040` sets the text's colour, written `#RRGGBB`."
    # "Text on a band is white unless `colour` says otherwise." Counted in
    # pixels near the colour, never by comparing encoded frames.
    ed_ok k1.mp4 <<'E'
card 2
  text "Hello" size 20
E
    ed_ok k2.mp4 <<'E'
card 2
  text "Hello" size 20 colour #FFD040
E
    ed_ok k3.mp4 <<'E'
card 2
  text "Hello" size 20 colour #20A0FF
E
    assert_cmp "control: a card's text with no colour is white (pixels near white)" "$(n_of "$ft/out/k1.mp4" 5 '#FFFFFF:60')" '>=' 400
    assert_cmp "control: a card's text with no colour has no #FFD040 in it" "$(n_of "$ft/out/k1.mp4" 5 '#FFD040:50')" '<=' 20
    assert_cmp "colour #FFD040: pixels near #FFD040" "$(n_of "$ft/out/k2.mp4" 5 '#FFD040:50')" '>=' 400
    assert_cmp "colour #FFD040: pixels near white (the text is not white)" "$(n_of "$ft/out/k2.mp4" 5 '#FFFFFF:60')" '<=' 20
    assert_cmp "colour #20A0FF: pixels near #20A0FF" "$(n_of "$ft/out/k3.mp4" 5 '#20A0FF:50')" '>=' 400
    assert_cmp "colour #20A0FF: pixels near #FFD040 (the colour asked for, not the last one)" "$(n_of "$ft/out/k3.mp4" 5 '#FFD040:50')" '<=' 20
    # The same on a clip, where the text sits on the band.
    ed_ok k4.mp4 <<'E'
clip G.mp4
  text "Hello" size 20
E
    ed_ok k5.mp4 <<'E'
clip G.mp4
  text "Hello" size 20 colour #FFD040
E
    assert_cmp "clip text with no colour: white pixels in the lower part" "$(n_of "$ft/out/k4.mp4" 5 '#FFFFFF:60' 0 .6 1 1)" '>=' 400
    assert_cmp "clip text with no colour: no #FFD040 pixels" "$(n_of "$ft/out/k4.mp4" 5 '#FFD040:50' 0 .6 1 1)" '<=' 20
    assert_cmp "clip text, colour #FFD040: pixels near #FFD040 in the lower part" "$(n_of "$ft/out/k5.mp4" 5 '#FFD040:50' 0 .6 1 1)" '>=' 400
    assert_cmp "clip text, colour #FFD040: white pixels in the lower part" "$(n_of "$ft/out/k5.mp4" 5 '#FFFFFF:60' 0 .6 1 1)" '<=' 20
    # "Text on a band is white unless `colour` says otherwise", on a light card,
    # where a dark text would be the default without a band.
    ed_ok k6.mp4 <<'E'
card 2 background #f0f0f0
  text "Hello" size 20 band on
E
    ed_ok k7.mp4 <<'E'
card 2 background #f0f0f0
  text "Hello" size 20 band on colour #FF2020
E
    read -r nd _ dy0 _ dy1 <<<"$(px find "$ft/out/k6.mp4" 5 dark:100)"
    assert_cmp "band on, a light card: a dark band is there (dark pixels)" "${nd:-0}" '>=' 2000
    in0=$(awk -v a="$dy0" 'BEGIN { print a + 0.03 }'); in1=$(awk -v a="$dy1" 'BEGIN { print a - 0.03 }')
    assert_cmp "text on a band, no colour, on a light card: white pixels inside the band" "$(n_of "$ft/out/k6.mp4" 5 '#FFFFFF:40' 0 "$in0" 1 "$in1")" '>=' 300
    assert_cmp "text on a band, colour #FF2020: red pixels inside the band" "$(n_of "$ft/out/k7.mp4" 5 '#FF2020:60' 0 "$in0" 1 "$in1")" '>=' 300
    assert_cmp "text on a band, colour #FF2020: white pixels inside the band" "$(n_of "$ft/out/k7.mp4" 5 '#FFFFFF:40' 0 "$in0" 1 "$in1")" '<=' 20
    echo "colour was the text's colour, on a card and on a clip, and white on a band without it"

    }
    fin_s30() {
    # README: "`outline #000000` draws a line of that colour round each letter,
    # and `shadow #000000` a shadow of that colour below and to the right of it."
    ed_ok o1.mp4 <<'E'
card 2
  text "Hello" size 20
E
    ed_ok o2.mp4 <<'E'
card 2
  text "Hello" size 20 outline #FF0000
E
    ed_ok o3.mp4 <<'E'
card 2
  text "Hello" size 20 shadow #00FF00
E
    read -r _ wx0 wy0 wx1 wy1 <<<"$(px find "$ft/out/o2.mp4" 5 '#FFFFFF:60')"
    assert_cmp "outline: the text itself is still there (white pixels)" "$(n_of "$ft/out/o2.mp4" 5 '#FFFFFF:60')" '>=' 400
    assert_cmp "control: no outline, no red pixels" "$(n_of "$ft/out/o1.mp4" 5 '#FF0000:70')" '<=' 20
    read -r rn rx0 ry0 rx1 ry1 <<<"$(px find "$ft/out/o2.mp4" 5 '#FF0000:70')"
    assert_cmp "outline #FF0000: red pixels" "${rn:-0}" '>=' 400
    assert_cmp "outline: reaches left of the text (red left edge, text left edge)" "${rx0:-1}" '<' "$wx0"
    assert_cmp "outline: reaches above the text (red top edge, text top edge)" "${ry0:-1}" '<' "$wy0"
    assert_cmp "outline: reaches right of the text (red right edge, text right edge)" "${rx1:-0}" '>' "$wx1"
    assert_cmp "outline: reaches below the text (red bottom edge, text bottom edge)" "${ry1:-0}" '>' "$wy1"
    read -r _ wx0 wy0 wx1 wy1 <<<"$(px find "$ft/out/o3.mp4" 5 '#FFFFFF:60')"
    assert_cmp "control: no shadow, no green pixels" "$(n_of "$ft/out/o1.mp4" 5 '#00FF00:90')" '<=' 20
    read -r gn gx0 gy0 gx1 gy1 <<<"$(px find "$ft/out/o3.mp4" 5 '#00FF00:90')"
    assert_cmp "shadow #00FF00: green pixels" "${gn:-0}" '>=' 300
    assert_cmp "shadow: reaches right of the text (green right edge, text right edge)" "${gx1:-0}" '>' "$wx1"
    assert_cmp "shadow: reaches below the text (green bottom edge, text bottom edge)" "${gy1:-0}" '>' "$wy1"
    # Below and to the right, not round: it starts no further left or higher
    # than the text does, give or take a pixel or two.
    assert_cmp "shadow: does not reach left of the text (green left edge, text left edge less 0.01)" "${gx0:-0}" '>=' "$(awk -v a="$wx0" 'BEGIN { print a - 0.01 }')"
    assert_cmp "shadow: does not reach above the text (green top edge, text top edge less 0.01)" "${gy0:-0}" '>=' "$(awk -v a="$wy0" 'BEGIN { print a - 0.01 }')"
    echo "outline surrounded the text and the shadow fell below and to its right"

    }
    fin_s31() {
    # README: "Text wider than the frame less a twentieth of its width at each
    # side is refused, its outline counted." The widest size that fits is found
    # by asking, so the check does not depend on which font the machine has.
    # The control is the same line at that size, accepted without the outline.
    fits() {  # size [outline words]: run rc is 0 when the line is accepted
        printf 'card 1\n  text "Hello world" size %s %s\n' "$1" "${2:-}" > "$ft/wf.txt"
        run edit wf.txt -o "$ft/out/wf.mp4" -s 320x240 -r 10
    }
    lo=5; hi=60
    fits $lo; expect_ok "control: 'Hello world' at size $lo"
    fits $hi; [ "$rc" -ne 0 ] || fail "size $hi should be too wide for 320 pixels, but it was accepted"
    for _ in 1 2 3 4 5 6 7 8 9; do
        mid=$(awk -v a="$lo" -v b="$hi" 'BEGIN { printf "%.3f", (a + b) / 2 }')
        fits "$mid"
        if [ "$rc" -eq 0 ]; then lo=$mid; else hi=$mid; fi
    done
    rm -f "$ft/out/wf.mp4"
    fits "$lo"
    expect_ok "control: the widest size that fits ($lo), no outline"
    rm -f "$ft/out/wf.mp4"
    fits "$lo" 'outline #000000'
    expect_refused "the same line at size $lo with an outline, which makes it too wide"
    grep -qiE 'line[^0-9]{0,3}2([^0-9.]|$)' "$fe" || fail "the outline refusal should name line 2
    actual: $(cat "$fe")"
    assert_absent "outline made the text too wide" "$ft/out/wf.mp4"
    fits "$(awk -v a="$lo" 'BEGIN { print a - 3 }')" 'outline #000000'
    expect_ok "control: an outline on a size that has room for it"
    echo "an outline counted toward the width: $lo fits without one and is refused with one"

    }
    fin_s32() {
    # README: "`fade-in 0.5` brings the text in over half a second from its
    # `from`, and `fade-out 0.5` takes it away over the half second before its
    # `to`." A clip of one flat grey, the text from 0.5 to 3.5 with a second of
    # fade at each end, so frame N is at N/10. "Fainter" is counted as white
    # pixels: only a text at nearly full strength has any.
    ed_ok fd1.mp4 <<'E'
clip G.mp4
  text "Hello" size 15 from 0.5 to 3.5 band off
E
    ed_ok fd2.mp4 <<'E'
clip G.mp4
  text "Hello" size 15 from 0.5 to 3.5 fade-in 1 fade-out 1 band off
E
    assert_cmp "control: with no fade the text is at full strength on its first frame (frame 5)" "$(n_of "$ft/out/fd1.mp4" 5 light:200 0 .6 1 1)" '>=' 300
    assert_cmp "fade-in 1: text fainter on its first frame (frame 5, white pixels)" "$(n_of "$ft/out/fd2.mp4" 5 light:200 0 .6 1 1)" '<=' 20
    assert_cmp "fade-in 1: text still faint at 0.3 s in (frame 8)" "$(n_of "$ft/out/fd2.mp4" 8 light:200 0 .6 1 1)" '<=' 20
    assert_cmp "fade-in 1: text at full strength just after the fade (frame 16)" "$(n_of "$ft/out/fd2.mp4" 16 light:200 0 .6 1 1)" '>=' 300
    assert_cmp "fade-in and fade-out: full strength in the middle (frame 20)" "$(n_of "$ft/out/fd2.mp4" 20 light:200 0 .6 1 1)" '>=' 300
    assert_cmp "fade-out 1: text still at full strength just before the fade (frame 24)" "$(n_of "$ft/out/fd2.mp4" 24 light:200 0 .6 1 1)" '>=' 300
    assert_cmp "fade-out 1: text faint 0.3 s before its end (frame 32)" "$(n_of "$ft/out/fd2.mp4" 32 light:200 0 .6 1 1)" '<=' 20
    assert_cmp "fade-out 1: text faint on its last frame (frame 34)" "$(n_of "$ft/out/fd2.mp4" 34 light:200 0 .6 1 1)" '<=' 20
    # "Its band fades with it, which needs an ffmpeg whose text filter can size
    # its own box (`boxw` in `ffmpeg -h filter=drawtext`). On one that cannot,
    # a text that fades with its band on is refused."
    printf 'clip G.mp4\n  text "Hello" size 15 from 0.5 to 3.5 fade-in 1 fade-out 1\n' > "$ft/fd3.txt"
    run edit fd3.txt -o "$ft/out/fd3.mp4" -s 320x240 -r 10
    dt_help=$(ffmpeg -hide_banner -h filter=drawtext 2>&1 || true)
    if grep -q boxw <<<"$dt_help"; then
        expect_ok "edit: a fading text on a band (this ffmpeg has boxw)"
        assert_cmp "control: full-strength band under a full-strength text (frame 20, dark pixels)" "$(n_of "$ft/out/fd3.mp4" 20 dark:100 0 .6 1 1)" '>=' 2000
        assert_cmp "fade-in: the band is faint with the text (frame 6, dark pixels)" "$(n_of "$ft/out/fd3.mp4" 6 dark:100 0 .6 1 1)" '<=' 20
        assert_cmp "fade-out: the band is faint with the text (frame 34, dark pixels)" "$(n_of "$ft/out/fd3.mp4" 34 dark:100 0 .6 1 1)" '<=' 20
        echo "the band faded with the text"
    else
        refused_naming_line "a fading text on a band, with an ffmpeg that has no boxw" fd3.mp4 2
        echo "this ffmpeg has no boxw: the fading text on a band was refused, as README says"
    fi
    # The same on a card, whose text counts from the card's start.
    ed_ok fd4.mp4 <<'E'
card 2
  text "Hello" size 20 fade-in 0.8 fade-out 0.8
E
    assert_cmp "card, fade-in 0.8: faint on the first frames (frame 1)" "$(n_of "$ft/out/fd4.mp4" 1 light:200)" '<=' 20
    assert_cmp "card, fade-in 0.8 fade-out 0.8: full strength in the middle (frame 10)" "$(n_of "$ft/out/fd4.mp4" 10 light:200)" '>=' 300
    assert_cmp "card, fade-out 0.8: faint on the last frames (frame 19)" "$(n_of "$ft/out/fd4.mp4" 19 light:200)" '<=' 20
    echo "the text was faint at each end of its window and full in the middle"

    }
    fin_s33() {
    # README: "The two together may not be longer than the text shows."
    ed_ok ft0.mp4 <<'E'
clip G.mp4
  text "Hello" from 1 to 2 fade-in 0.4 fade-out 0.4 band off
E
    ed ft1.mp4 <<'E'
clip G.mp4
  text "Hello" from 1 to 2 fade-in 0.7 fade-out 0.7 band off
E
    refused_naming_line "fades of 0.7 + 0.7 on a text that shows for 1" ft1.mp4 2
    ed ft2.mp4 <<'E'
clip G.mp4
  text "Hello" from 1 to 2 fade-in 1.5 band off
E
    refused_naming_line "a fade-in of 1.5 on a text that shows for 1" ft2.mp4 2
    ed ft3.mp4 <<'E'
card 2
  text "Hello" fade-in 1.5 fade-out 1 band off
E
    refused_naming_line "fades of 1.5 + 1 on a card text that shows for the card's 2" ft3.mp4 2
    ed_ok ft4.mp4 <<'E'
card 2
  text "Hello" fade-in 1.5 fade-out 0.4 band off
E
    echo "fades longer than the text shows were refused; shorter ones were not"

    }
    fin_s34() {
    # README: "`band off` takes the dark band away, and `band on` gives a card's
    # text one." "On a clip, the text sits on a dark band across the bottom of
    # the picture". A flat grey clip and a flat grey card, so a band is the dark
    # pixels and nothing else is.
    ed_ok b1.mp4 <<'E'
clip G.mp4
  text "Hello" size 15
E
    ed_ok b2.mp4 <<'E'
clip G.mp4
  text "Hello" size 15 band off
E
    assert_cmp "control: a clip's text has a dark band by default (dark pixels)" "$(n_of "$ft/out/b1.mp4" 5 dark:100)" '>=' 2000
    assert_cmp "band off on a clip: no dark pixels" "$(n_of "$ft/out/b2.mp4" 5 dark:100)" '<=' 20
    assert_cmp "band off on a clip: the text is still there (white pixels)" "$(n_of "$ft/out/b2.mp4" 5 light:200)" '>=' 300
    ed_ok b3.mp4 <<'E'
card 2 background #808080
  text "Hello" size 15
E
    ed_ok b4.mp4 <<'E'
card 2 background #808080
  text "Hello" size 15 band on
E
    ed_ok b5.mp4 <<'E'
card 2 background #808080
  text "Hello" size 15 band off
E
    assert_cmp "control: a card's text has no band by default (dark pixels)" "$(n_of "$ft/out/b3.mp4" 5 dark:100)" '<=' 20
    assert_cmp "band on for a card: a dark band across the frame (dark pixels)" "$(n_of "$ft/out/b4.mp4" 5 dark:100)" '>=' 2000
    assert_cmp "band on for a card: the band reaches the frame's left edge (dark pixels in the leftmost 2%)" "$(n_of "$ft/out/b4.mp4" 5 dark:100 0 0 .02 1)" '>=' 20
    assert_cmp "band on for a card: the band reaches the frame's right edge (dark pixels in the rightmost 2%)" "$(n_of "$ft/out/b4.mp4" 5 dark:100 .98 0 1 1)" '>=' 20
    assert_cmp "band off for a card: no dark pixels" "$(n_of "$ft/out/b5.mp4" 5 dark:100)" '<=' 20
    echo "band off took the band away and band on gave a card's text one"

    }
    fin_s35() {
    # README: "`at top`, `at middle` or `at bottom` says where it sits. With a
    # band, the band runs across the frame there, against the edge at the top or
    # bottom. Without one, the text sits a twentieth of the frame's height in
    # from that edge." Sizes are read off the drawn pixels, to within a few
    # percent, because the letters' own spacing differs from font to font.
    for at in top middle bottom; do
        ed_ok "p-$at.mp4" <<E
card 2
  text "Hello" size 10 at $at band off
E
        read -r n x0 y0 x1 y1 <<<"$(px find "$ft/out/p-$at.mp4" 5 '#FFFFFF:60')"
        assert_cmp "at $at, no band: the text is drawn (white pixels)" "${n:-0}" '>=' 200
        eval "ty0_$at=$y0 ty1_$at=$y1"
    done
    assert_cmp "at top, no band: the top of the text is about a twentieth of the height in" "$ty0_top" '>=' 0.03
    assert_cmp "at top, no band: the top of the text is about a twentieth of the height in" "$ty0_top" '<=' 0.12
    assert_cmp "at middle, no band: the text's centre is the frame's" "($ty0_middle + $ty1_middle) / 2" '>=' 0.44
    assert_cmp "at middle, no band: the text's centre is the frame's" "($ty0_middle + $ty1_middle) / 2" '<=' 0.56
    assert_cmp "at bottom, no band: the bottom of the text is about a twentieth of the height in" "$ty1_bottom" '<=' 0.96
    assert_cmp "at bottom, no band: the bottom of the text is about a twentieth of the height in" "$ty1_bottom" '>=' 0.88
    # With a band: a flat grey card, so the band is the dark pixels.
    for at in top middle bottom; do
        ed_ok "q-$at.mp4" <<E
card 2 background #808080
  text "Hello" size 10 at $at band on
E
        read -r n x0 y0 x1 y1 <<<"$(px find "$ft/out/q-$at.mp4" 5 dark:100)"
        assert_cmp "at $at, band: a band is there (dark pixels)" "${n:-0}" '>=' 2000
        assert_cmp "at $at, band: it runs across the frame (left edge)" "$x0" '<=' 0.01
        assert_cmp "at $at, band: it runs across the frame (right edge)" "$x1" '>=' 0.99
        read -r tn tx0 ty0 tx1 ty1 <<<"$(px find "$ft/out/q-$at.mp4" 5 light:200)"
        assert_cmp "at $at, band: the text is drawn (white pixels)" "${tn:-0}" '>=' 200
        assert_cmp "at $at, band: the text is inside the band (its top is not above the band's)" "${ty0:-0}" '>=' "$y0"
        assert_cmp "at $at, band: the text is inside the band (its bottom is not below the band's)" "${ty1:-1}" '<=' "$y1"
        case $at in
            top)    assert_cmp "at top, band: against the top edge" "$y0" '<=' 0.005
                    assert_cmp "at top, band: not against the bottom edge" "$y1" '<' 0.5 ;;
            bottom) assert_cmp "at bottom, band: against the bottom edge" "$y1" '>=' 0.995
                    assert_cmp "at bottom, band: not against the top edge" "$y0" '>' 0.5 ;;
            middle) assert_cmp "at middle, band: clear of the top edge" "$y0" '>' 0.15
                    assert_cmp "at middle, band: clear of the bottom edge" "$y1" '<' 0.85 ;;
        esac
    done
    # On a clip the band is at the bottom unless `at` says otherwise.
    ed_ok q-clip1.mp4 <<'E'
clip G.mp4
  text "Hello" size 10
E
    ed_ok q-clip2.mp4 <<'E'
clip G.mp4
  text "Hello" size 10 at top
E
    read -r _ _ y0 _ y1 <<<"$(px find "$ft/out/q-clip1.mp4" 5 dark:100)"
    assert_cmp "a clip's text with no at: band against the bottom edge" "${y1:-0}" '>=' 0.995
    assert_cmp "a clip's text with no at: band not against the top edge" "${y0:-0}" '>' 0.5
    read -r _ _ y0 _ y1 <<<"$(px find "$ft/out/q-clip2.mp4" 5 dark:100)"
    assert_cmp "a clip's text, at top: band against the top edge" "${y0:-1}" '<=' 0.005
    assert_cmp "a clip's text, at top: band not against the bottom edge" "${y1:-0}" '<' 0.5
    echo "the text and its band sat at the top, middle and bottom as asked"

    }
    fin_s36() {
    # README: "On a card, the picture is fitted into the room left between a text
    # at the top and a text at the bottom, and a text in the middle lies over
    # it." sq.png is a green square, larger than the card, so it fills the
    # card's height unless a text takes some of it. The texts are white and the
    # picture green, so the two are told apart by colour.
    ed_ok pf0.mp4 <<'E'
card 2 sq.png
E
    read -r _ _ full0 _ full1 <<<"$(px find "$ft/out/pf0.mp4" 5 '#00C000:60')"
    assert_cmp "control: a picture with no text is there and tall (its height)" "${full1:-0} - ${full0:-0}" '>=' 0.8
    ed_ok pf1.mp4 <<'E'
card 2 sq.png
  text "Hello" size 12 at top band off
E
    read -r _ _ ty0 _ ty1 <<<"$(px find "$ft/out/pf1.mp4" 5 '#FFFFFF:60')"
    read -r _ _ gy0 _ gy1 <<<"$(px find "$ft/out/pf1.mp4" 5 '#00C000:60')"
    assert_cmp "a text at the top: the text is drawn" "${ty1:-0}" '>' 0
    assert_cmp "a text at the top: the picture starts below the text (picture top, text bottom)" "${gy0:-0}" '>=' "${ty1:-1}"
    assert_cmp "a text at the top: the picture is smaller than it is with no text (its height)" "${gy1:-1} - ${gy0:-0}" '<' "$full1 - $full0 - 0.1"
    ed_ok pf2.mp4 <<'E'
card 2 sq.png
  text "Top" size 12 at top band off from 0 to 1
  text "Bottom" size 12 at bottom band off from 1 to 2
E
    read -r _ _ ty0 _ ty1 <<<"$(px find "$ft/out/pf2.mp4" 5 '#FFFFFF:60')"
    read -r _ _ gy0 _ gy1 <<<"$(px find "$ft/out/pf2.mp4" 5 '#00C000:60')"
    assert_cmp "top and bottom texts, while the top one shows: the picture starts below it (picture top, text bottom)" "${gy0:-0}" '>=' "${ty1:-1}"
    assert_cmp "top and bottom texts, while the top one shows: the picture is smaller than the card's height" "${gy1:-1} - ${gy0:-0}" '<' "$full1 - $full0 - 0.1"
    read -r _ _ by0 _ by1 <<<"$(px find "$ft/out/pf2.mp4" 15 '#FFFFFF:60')"
    read -r _ _ gy0 _ gy1 <<<"$(px find "$ft/out/pf2.mp4" 15 '#00C000:60')"
    assert_cmp "top and bottom texts, while the bottom one shows: the picture ends above it (picture bottom, text top)" "${gy1:-1}" '<=' "${by0:-0}"
    assert_cmp "top and bottom texts, while the bottom one shows: the picture is smaller than the card's height" "${gy1:-1} - ${gy0:-0}" '<' "$full1 - $full0 - 0.1"
    ed_ok pf3.mp4 <<'E'
card 2 sq.png
  text "Hello" size 12 at middle band off
E
    read -r wn _ ty0 _ ty1 <<<"$(px find "$ft/out/pf3.mp4" 5 '#FFFFFF:60')"
    read -r _ _ gy0 _ gy1 <<<"$(px find "$ft/out/pf3.mp4" 5 '#00C000:60')"
    assert_cmp "a text in the middle: the picture keeps the height it has with no text (top edge)" "${gy0:-1}" '<=' "$full0 + 0.02"
    assert_cmp "a text in the middle: the picture keeps the height it has with no text (bottom edge)" "${gy1:-0}" '>=' "$full1 - 0.02"
    assert_cmp "a text in the middle lies over the picture (white pixels)" "${wn:-0}" '>=' 200
    assert_cmp "a text in the middle lies over the picture (text top, picture top)" "${ty0:-0}" '>' "${gy0:-1}"
    assert_cmp "a text in the middle lies over the picture (text bottom, picture bottom)" "${ty1:-1}" '<' "${gy1:-0}"
    # With a band the room left is what the band leaves: a flat grey card, so
    # the band is the dark pixels down the frame's left edge, clear of the picture.
    ed_ok pf4.mp4 <<'E'
card 2 sq.png background #808080
  text "Hello" size 12 at top band on
E
    read -r _ _ _ _ by1 <<<"$(px find "$ft/out/pf4.mp4" 5 dark:100 0 0 .08 1)"
    read -r _ _ gy0 _ _ <<<"$(px find "$ft/out/pf4.mp4" 5 '#00C000:60')"
    assert_cmp "a text at the top with a band: the picture starts below the band (picture top, band bottom)" "${gy0:-0}" '>=' "${by1:-1}"
    echo "the picture was fitted between top and bottom texts, and left whole under a middle one"

    }
    fin_s37() {
    # README: "`font "DejaVu Serif"` draws it in that font family, by the name
    # `fc-list` gives it". The families are asked of the machine, never named
    # here: the gate also runs where only DejaVu is installed. Two families
    # that draw are found, and they have to differ from the default and from
    # each other; the same family twice has to agree, or the difference means
    # nothing.
    if ! command -v fc-match >/dev/null || ! command -v fc-list >/dev/null; then
        # README: "on a machine without that program ... a font asked for by
        # name is refused."
        ed ff0.mp4 <<'E'
card 2
  text "Hello" font "DejaVu Serif"
E
        refused_naming_line "a font asked for by name on a machine without fc-match" ff0.mp4 2
        echo "no fc-match here: a font asked for by name was refused, as README says"
        return 0
    fi
    drawn() {  # out family: a card in that family; sets rc
        ed "$1" <<E
card 2
  text "Hamburgefonts" size 12 font "$2"
E
    }
    all=$(fc-list : family | sed 's/,.*//' | sort -u \
            | grep -viE 'symbol|emoji|math|dingbat|outline|console|syriac|estrangelo|serto|special|ocr|cursor|chancery|gallant' || true)
    # Serifs and monospaces first: they look least like the default.
    fams=$( { printf '%s\n' "$all" | grep -iE 'serif|mono' || true
              printf '%s\n' "$all" | grep -viE 'serif|mono' || true; } | head -14)
    ed_ok fa0.mp4 <<'E'
card 2
  text "Hamburgefonts" size 12
E
    found=""; nfound=0
    while IFS= read -r fam; do
        [ -n "$fam" ] || continue
        drawn "fa-$nfound.mp4" "$fam"
        [ "$rc" -eq 0 ] || continue
        [ "$(n_of "$ft/out/fa-$nfound.mp4" 5 '#FFFFFF:60')" -ge 200 ] || continue
        found="$found$fam
"
        nfound=$((nfound + 1))
        [ "$nfound" -ge 2 ] && break
    done <<<"$fams"
    [ "$nfound" -ge 2 ] || fail "font: expected two installed families to draw text
    expected: two of the families \`fc-list : family\` gives are accepted and draw
    actual:   $nfound did; candidates were: $(printf '%s' "$fams" | tr '\n' ',')
    the last refusal, if any: $(cat "$fe")"
    fam1=$(printf '%s' "$found" | sed -n 1p); fam2=$(printf '%s' "$found" | sed -n 2p)
    drawn fa-again.mp4 "$fam1"; expect_ok "font \"$fam1\" a second time"
    same=$(px changed "$ft/out/fa-again.mp4" 5 "$ft/out/fa-0.mp4" 5 full)
    assert_cmp "control: the same family twice draws the same (pixels that differ)" "$same" '<=' 20
    d_def=$(px changed "$ft/out/fa-0.mp4" 5 "$ft/out/fa0.mp4" 5 full)
    assert_cmp "font \"$fam1\" draws differently from the default (pixels that differ)" "$d_def" '>=' 200
    d_def2=$(px changed "$ft/out/fa-1.mp4" 5 "$ft/out/fa0.mp4" 5 full)
    assert_cmp "font \"$fam2\" draws differently from the default (pixels that differ)" "$d_def2" '>=' 200
    d_two=$(px changed "$ft/out/fa-0.mp4" 5 "$ft/out/fa-1.mp4" 5 full)
    assert_cmp "\"$fam1\" and \"$fam2\" draw differently from each other (pixels that differ)" "$d_two" '>=' 200
    # "Anything after a colon is handed to `fc-match` as written, so
    # `font "DejaVu Serif:bold"` asks for the family's bold." Only where the
    # family has a bold to ask for.
    bolded=""
    for fam in "$fam1" "$fam2"; do
        wr=$(fc-match -f '%{weight}' "$fam"); wb=$(fc-match -f '%{weight}' "$fam:bold")
        if [ "$wr" != "$wb" ]; then bolded=$fam; break; fi
    done
    if [ -n "$bolded" ]; then
        drawn fa-b.mp4 "$bolded:bold"; expect_ok "font \"$bolded:bold\""
        drawn fa-r.mp4 "$bolded"; expect_ok "font \"$bolded\""
        d_bold=$(px changed "$ft/out/fa-b.mp4" 5 "$ft/out/fa-r.mp4" 5 full)
        assert_cmp "font \"$bolded:bold\" draws differently from \"$bolded\" (pixels that differ)" "$d_bold" '>=' 100
    else
        echo "note: neither $fam1 nor $fam2 has a bold face here, so \":bold\" was not exercised"
    fi
    # "A value with a `/` in it is a font file and is used as it is."
    file=$(fc-match -f '%{file}' "$fam1")
    case $file in /*) [ -f "$file" ] || file="" ;; *) file="" ;; esac
    if [ -n "$file" ]; then
        drawn fa-f.mp4 "$file"; expect_ok "font \"$file\""
        d_file=$(px changed "$ft/out/fa-f.mp4" 5 "$ft/out/fa0.mp4" 5 full)
        assert_cmp "font FILE ($file) draws differently from the default (pixels that differ)" "$d_file" '>=' 200
    else
        echo "note: fc-match gave no file for $fam1, so a font file was not exercised"
    fi
    # Refused: a control that succeeds first, then a family the machine lacks, a
    # general name, and a value with a / that is not a file.
    drawn fr0.mp4 "$fam1"; expect_ok "control: font \"$fam1\""
    for bad in "No Such Family Xyzzy" serif sans-serif monospace "/no/such/font.ttf" "./nofile.ttf" /usr; do
        drawn fr1.mp4 "$bad"
        refused_naming_line "font \"$bad\"" fr1.mp4 2
    done
    echo "families drew differently; a missing family, a general name and a bad path were refused"

    }
    fin_s38() {
    # README: "Each line is one scene" ... "Everything is checked before
    # anything is made ... the message names the line." "A command that fails
    # leaves nothing at `-o`. A file already there is left as it was." Each
    # value that is not one the README names is refused after a control with the
    # value that is.
    ed_ok v0.mp4 <<'E'
card 1
  text "Hi" colour #FFD040 band on at top
E
    keep=$(sha256sum < "$ft/out/v0.mp4")
    for bad in 'colour red' 'colour #FFD04' 'colour FFD040' 'colour #GGGGGG' 'band maybe' 'band 1' 'at left' 'at centre'; do
        cp "$ft/out/v0.mp4" "$ft/out/v1.mp4"
        : > "$ft/log/ffmpeg.calls"
        printf 'card 1\n  text "Hi" %s\n' "$bad" > "$ft/v1.txt"
        FIN_PATH="$ft/shim:$PATH" run edit v1.txt -o "$ft/out/v1.mp4" -s 320x240 -r 10
        expect_refused "text ... $bad"
        grep -qiE 'line[^0-9]{0,3}2([^0-9.]|$)' "$fe" || fail "text ... $bad: the message should name line 2
    expected: 'line 2' on stderr
    actual:   $(cat "$fe")"
        assert_eq "text ... $bad: the file already at -o" "$keep" "$(sha256sum < "$ft/out/v1.mp4")"
        assert_eq "text ... $bad: ffmpeg runs that encode (nothing is made first)" 0 "$(grep -cw 'libx264' "$ft/log/ffmpeg.calls" || true)"
        rm -f "$ft/out/v2.mp4"
        run edit v1.txt -o "$ft/out/v2.mp4" -s 320x240 -r 10
        assert_absent "text ... $bad" "$ft/out/v2.mp4"
    done
    # The line named is the bad one, not a neighbour: a bad value under the
    # third scene of four.
    printf 'card 1\ncard 1\n  text "ok"\ncard 1\n  text "Hi" band maybe\ncard 1\n' > "$ft/v3.txt"
    run edit v3.txt -o "$ft/out/v3.mp4" -s 320x240 -r 10
    refused_naming_line "a bad band value on line 5 of a script of six" v3.mp4 5
    echo "eight bad values were refused, named by line, and left nothing"

    }
    fin_s39() {
    # README: "A text's `font`, `colour`, `outline`, `shadow`, `band`, `at` and
    # its own fades are the script's alone. A shortcut sets a text's words,
    # times and size." Each shortcut is run first without the option, and
    # succeeds; then with it, and is refused, naming the option.
    run caption A.mp4 -o "$ft/out/sc0.mp4" --text hi --from 1 --to 2
    expect_ok "control: caption --text hi --from 1 --to 2"
    run card -o "$ft/out/sc1.mp4" -d 1 -s 320x240 -r 10 --text hi
    expect_ok "control: card -d 1 --text hi"
    for opt in "--font Sans" "--colour #FFD040" "--outline #000000" "--shadow #000000" \
               "--band off" "--at top" "--text-fade-in 0.5" "--text-fade-out 0.5"; do
        # shellcheck disable=SC2086
        run caption A.mp4 -o "$ft/out/sc2.mp4" --text hi --from 1 --to 2 $opt
        expect_refused "caption ... $opt"
        grep -q -- "${opt%% *}" "$fe" || fail "caption ... $opt: the refusal should name the option
    expected: '${opt%% *}' on stderr
    actual:   $(cat "$fe")"
        assert_absent "caption ... $opt" "$ft/out/sc2.mp4"
        # shellcheck disable=SC2086
        run card -o "$ft/out/sc3.mp4" -d 1 -s 320x240 -r 10 --text hi $opt
        expect_refused "card ... $opt"
        grep -q -- "${opt%% *}" "$fe" || fail "card ... $opt: the refusal should name the option
    expected: '${opt%% *}' on stderr
    actual:   $(cat "$fe")"
        assert_absent "card ... $opt" "$ft/out/sc3.mp4"
    done
    echo "caption and card refused each of the script-only text words"
    }
    fin_s40() {
    # README: "`motion` prints a time to a thousandth of a second, so wherever a
    # time picks a frame, one within half a thousandth before a frame's start
    # means that frame." "The frame on screen at `from` is the first one kept,
    # and the frame on screen at `to` is the last one kept." F is 30 a second
    # and moves up to frame 40, which starts at 1.33333: motion prints 1.333,
    # just short of it (DEMO-0137).
    run motion F.mp4
    expect_ok "motion F.mp4"
    lc=$(sed -n 's/^last change: //p' "$fo")
    assert_eq "motion F.mp4: last change (frame 40 of a 30-a-second clip, to three decimals)" 1.333 "$lc"
    run trim F.mp4 -o "$ft/out/z1.mp4" --to "$lc"
    expect_ok "trim F.mp4 --to $lc"
    assert_eq "trim --to <last change> at 30 a second: frames (0 to 40)" 41 "$(v_frames "$ft/out/z1.mp4")"
    assert_is_frame "trim --to <last change> at 30 a second: the last frame is the last new picture" \
        "$ft/out/z1.mp4" 40 "$ft/F.mp4" 40 30 40
    # 0.067 is frame 2's start (0.06667) rounded up, and 0.1 is frame 3's.
    run trim F.mp4 -o "$ft/out/z2.mp4" --from 0.067 --to 0.1
    expect_ok "trim F.mp4 --from 0.067 --to 0.1"
    assert_eq "trim --from 0.067 --to 0.1 at 30 a second: frames (2 and 3)" 2 "$(v_frames "$ft/out/z2.mp4")"
    assert_is_frame "trim --from 0.067: the first frame is the one on screen then" \
        "$ft/out/z2.mp4" 0 "$ft/F.mp4" 2 0 10
    # A time inside a frame keeps the frame on screen, not the next one.
    run trim F.mp4 -o "$ft/out/z3.mp4" --from 0.05 --to 0.1
    expect_ok "trim F.mp4 --from 0.05 --to 0.1"
    assert_is_frame "trim --from 0.05: the first frame is frame 1, on screen from 0.0333" \
        "$ft/out/z3.mp4" 0 "$ft/F.mp4" 1 0 10
    # 0.033 is frame 1's start (0.03333) rounded down.
    run poster F.mp4 -t 0.033 -o "$ft/out/z4.png"
    expect_ok "poster F.mp4 -t 0.033"
    assert_is_frame "poster -t 0.033 at 30 a second" "$ft/out/z4.png" 0 "$ft/F.mp4" 1 0 10
    # README: "On a clip these are times in the clip's own file, like the clip's
    # `from` and `to`": the same number works on both lines (DEMO-0136). N is
    # 29.97 a second, where no frame starts at 2.
    printf 'clip N.mp4 from 2\n  text "Hi" from 2 to 3\n' > "$ft/z5.txt"
    run edit z5.txt -o "$ft/out/z5.mp4"
    expect_ok "edit: a clip from 2 with a text from 2, at 29.97 a second"
    printf 'clip F.mp4 from 0.033\n  text "Hi" from 0.033 to 1\n' > "$ft/z6.txt"
    run edit z6.txt -o "$ft/out/z6.mp4"
    expect_ok "edit: a clip from 0.033 with a text from 0.033, at 30 a second"
    printf 'clip N.mp4 from 2\n  text "Hi" from 1 to 3\n' > "$ft/z7.txt"
    run edit z7.txt -o "$ft/out/z7.mp4"
    expect_refused "edit: a text from 1 on a clip from 2"
    assert_absent "edit: a text from 1 on a clip from 2" "$ft/out/z7.mp4"
    echo "motion's times cut on the frame they were printed for at 30 a second, and a text started with its clip"
    }
    fin_step "trim keeps the frames from --from to --to, the last one included" fin_s1
    fin_step "every video a command writes is silent H.264, yuv420p, index first" fin_s2
    fin_step "-o may not be an input, and must end in .mp4" fin_s3
    fin_step "a time past the end is an error; the file's own length is not" fin_s4
    fin_step "a failed command leaves nothing at -o, and a file already there as it was" fin_s5
    fin_step "motion prints the report README shows" fin_s6
    fin_step "motion's last change and still lines agree with where the clip goes still" fin_s7
    fin_step "motion --json is the same report as one JSON object" fin_s8
    fin_step "motion writes no file and changes nothing" fin_s9
    fin_step "a --to set to motion's last change ends the clip on the last new picture" fin_s10
    fin_step "poster saves the frame on screen at -t, as .png or .jpg" fin_s11
    fin_step "poster refuses other endings and a time past the end" fin_s12
    fin_step "join adds the lengths, less the overlap at each crossfade" fin_s13
    fin_step "join gives the first clip's size and rate, and refuses another shape" fin_s14
    fin_step "card: size, rate and length come from -d, --like, -s and -r" fin_s15
    fin_step "card: background colour, and text in the middle or near the top" fin_s16
    fin_step "card: a picture is scaled to fit, centred, never enlarged, never stretched" fin_s17
    fin_step "card: an animated picture plays at its own speed and starts again" fin_s18
    fin_step "card: text too wide for the frame is refused" fin_s19
    fin_step "caption shows text only inside its from/to window" fin_s20
    fin_step "caption refuses a --from before any --text, and texts that overlap" fin_s21
    fin_step "fade-in, fade-out and fade-at change the brightness where README says" fin_s22
    fin_step "edit makes the film in order, from a file or from standard input" fin_s23
    fin_step "edit's film size and rate: the first clip's, or -s and -r, or 1600x1000 at 30" fin_s24
    fin_step "edit checks every line before it makes anything, and names the bad one" fin_s25
    fin_step "edit: crossfade on a scene overlaps it with the one before" fin_s26
    fin_step "a shortcut and the script it stands for agree" fin_s27
    fin_step "check reports the finishing commands and their text, without changing its exit status" fin_s28
    fin_step "text colour: the text is drawn in it, and white on a band without it" fin_s29
    fin_step "text outline and shadow: a line round the letters, a shadow below and to the right" fin_s30
    fin_step "text outline counts toward the too-wide refusal" fin_s31
    fin_step "text fade-in and fade-out: fainter at the ends of its window, and its band with it" fin_s32
    fin_step "text fades longer than the text shows are refused" fin_s33
    fin_step "text band on and off" fin_s34
    fin_step "text at top, middle or bottom, with and without a band" fin_s35
    fin_step "card picture is fitted between a text at the top and one at the bottom" fin_s36
    fin_step "text font: a family the machine has draws differently; a missing one, a general name and a bad path are refused" fin_s37
    fin_step "text words with a bad value are refused, name their line and leave nothing at -o" fin_s38
    fin_step "caption and card do not take the script-only text words" fin_s39
    fin_step "a time motion prints picks the frame it was printed for, at 30 a second" fin_s40
    [ "$fin_failed" -eq 0 ] || { echo "$fin_failed finishing check(s) failed" >&2; exit 1; }
}

if $FINISHING_ONLY; then
    for prog in ffmpeg ffprobe python3; do
        command -v "$prog" >/dev/null || { echo "missing: $prog" >&2; exit 1; }
    done
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    finishing_checks
    printf '\n=== finishing checks passed ===\n'
    exit 0
fi

step "gate wiring"
# Runs in BOTH modes, and before the --docs exit on purpose: this is the check
# that catches the local glob having drifted, and the glob is what decides which
# mode we are in. Behind that exit it could never fire in the mode it guards.
configured=$(git config --get ants.gate.docsGlob 2>/dev/null || true)
if [ -n "$configured" ] && [ "$configured" != "$DOCS_GLOB" ]; then
    echo "ants.gate.docsGlob is '$configured' but ci.sh says '$DOCS_GLOB'" >&2
    echo "re-run: git config ants.gate.docsGlob \"\$(./ci.sh --docs-glob)\"" >&2
    exit 1
fi
echo "docs glob: $DOCS_GLOB"

step "documented flags exist"
# Also runs in both modes. README.md is this project's design contract, so a
# flag it documents and the tool does not accept is a defect in the contract --
# and a commit that breaks it necessarily touches code, which is exactly the
# push a documentation-only check would never see.
help=$(./demoreel record --help; ./demoreel shot --help; ./demoreel stop --help;
      for sub in edit trim caption join card motion poster; do
          ./demoreel "$sub" --help
      done
      ./demoreel --help)
undocumented=0
for flag in $(grep -oE '`-{1,2}[a-z-]+`' README.md | tr -d '`' | sort -u); do
    # Flags belonging to other programs the caller invokes THROUGH demoreel:
    # flatpak's sockets, and the -geometry demoreel forwards to Xwayland.
    case "$flag" in --socket|--nosocket|--filesystem|-geometry) continue ;; esac
    # A here-string, not a pipe: grep -q stops reading at its first match,
    # the writer then dies of SIGPIPE, and pipefail reports that as a miss.
    # A longer help text is all it takes to hit it.
    if ! grep -qF -- "$flag" <<<"$help"; then
        echo "README documents $flag, which demoreel does not accept" >&2
        undocumented=$((undocumented + 1))
    fi
done
[ "$undocumented" -eq 0 ] || exit 1
echo "every flag README documents is one demoreel accepts"

# DEMO-0044. And the other direction, which is where the drift actually was:
# six long forms were accepted and written down nowhere. The command line is a
# protected surface (docs/standards/versioning-overrides.md), so a spelling
# nobody documented is still one a caller's script can depend on, and still a
# break to remove -- a break nobody could have seen coming from the contract.
#
# -h and --help are argparse's own, added to every parser whether we ask or not.
unmentioned=0
for flag in $(printf '%s' "$help" | grep -oE '(^|[ ,])--?[a-z][a-z-]+' \
              | tr -d ' ,' | sort -u); do
    case "$flag" in -h|--help) continue ;; esac
    # Not grep -F: a bare `-o` matches inside a word, so the check would pass
    # on any README that happens to contain "read-only".
    grep -qE -- "(^|[^A-Za-z0-9_-])$flag([^A-Za-z0-9_-]|\$)" README.md || {
        echo "demoreel accepts $flag, which README.md never mentions" >&2
        unmentioned=$((unmentioned + 1))
    }
done
[ "$unmentioned" -eq 0 ] || exit 1
echo "every flag demoreel accepts is one README mentions"

step "every --help example parses"
# DEMO-0050. The examples at the end of --help are what a first-time user
# copies, so each one must be a command demoreel accepts: parsed by the tool's
# own parser, with every -a step read the way a run reads it. This also covers
# the check above, which takes its list of accepted flags from the same help
# text: a flag an example uses cannot be one the parser has dropped.
#
# DEMO-0060 INV-17: the pages are printed again by a copy under the
# pseudo-locale, and every example must come out byte for byte the same. A
# command put inside a translated message would be translated with it.
ex_tmp=$(mktemp -d)
pseudo_copy "$ex_tmp" zz
PSEUDO_COPY="$ex_tmp/demoreel" python3 - <<'EXAMPLESPY'
import importlib.machinery, importlib.util, os, shlex, subprocess, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
pseudo = {k: v for k, v in os.environ.items() if k not in ("LC_ALL", "LC_MESSAGES")}
pseudo.update(LANGUAGE="zz", LANG="de_DE.UTF-8")

def examples_on(script, page, env=None):
    text = subprocess.run([script, *page], capture_output=True, env=env,
                          text=True, check=True).stdout
    examples, lines = [], iter(text.splitlines())
    for line in lines:
        line = line.strip()
        if not line.startswith("demoreel "):
            continue
        while line.endswith("\\"):
            line = line[:-1] + " " + next(lines).strip()
        examples.append(line)
    return text, examples

bad = 0
for page in (["--help"], ["record", "--help"]):
    text, examples = examples_on("./demoreel", page)
    translated, again = examples_on(os.environ["PSEUDO_COPY"], page, pseudo)
    if "\u27e6" not in translated:
        print(f"demoreel {' '.join(page)} was not translated under the "
              "pseudo-locale, so INV-17 compared nothing", file=sys.stderr)
        bad += 1
    elif again != examples:
        print(f"demoreel {' '.join(page)}: an example differs under the "
              f"pseudo-locale:\n  {examples}\n  {again}", file=sys.stderr)
        bad += 1
    if not examples:
        print(f"demoreel {' '.join(page)} shows no examples", file=sys.stderr)
        bad += 1
    for example in examples:
        argv = shlex.split(example)[1:]
        if argv[-1:] == ["&"]:
            argv.pop()
        try:
            args = demoreel.build_parser().parse_args(argv)
            if args.cmd in ("record", "shot") and not [
                    c for c in args.command if c != "--"]:
                sys.exit("it names no app to run")
            for step in getattr(args, "action", []):
                demoreel.parse_step(step)
        except SystemExit as e:
            # argparse prints its own reason and exits with a number.
            why = e.code if isinstance(e.code, str) else "argparse says why above"
            print(f"this --help example does not parse: {example}\n  {why}",
                  file=sys.stderr)
            bad += 1
    print(f"demoreel {' '.join(page)}: {len(examples)} examples")
sys.exit(1 if bad else 0)
EXAMPLESPY
rm -rf "$ex_tmp"
echo "every example --help shows is one demoreel accepts, in every language"

step "README's install lines are the ones demoreel check prints"
# DEMO-0058. The package names have one home, PACKAGES in demoreel, which
# `demoreel check` reads to name what is missing. README § Install shows them
# too, so hold each of its lines to that table: per distro, the default
# backend's packages, and the four more --gpu needs.
python3 - <<'INSTALLPY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
readme = open("README.md", encoding="utf-8").read().splitlines()
default = demoreel.required_programs(False, True)
gpu = [p for p in demoreel.required_programs(True, True) if p not in default]
bad = 0
for family, (command, names) in demoreel.PACKAGES.items():
    for programs in (default, gpu):
        line = " ".join([command, *dict.fromkeys(
            names[p] for p in programs if p in names)])
        if line not in readme:
            print(f"README.md § Install lacks this line: {line}", file=sys.stderr)
            bad += 1
sys.exit(1 if bad else 0)
INSTALLPY
echo "every install line in README matches the package table"

step "the man page names everything demoreel accepts"
# DEMO-0057. Held to the same rule as README above: every option, subcommand
# and step demoreel accepts appears in demoreel.1, so one added to the tool and
# forgotten there fails here. roff writes a hyphen as \-, hence the sed. And it
# must render without a groff warning, where groff is installed to say.
man_text=$(sed 's/\\-/-/g' demoreel.1)
man_missing=0
for word in $(printf '%s' "$help" | grep -oE '(^|[ ,])--?[a-z][a-z-]+' \
              | tr -d ' ,' | sort -u) \
            $(python3 -c 'import importlib.machinery as m, importlib.util as u
l = m.SourceFileLoader("demoreel", "./demoreel")
d = u.module_from_spec(u.spec_from_loader("demoreel", l)); l.exec_module(d)
import argparse
sub = next(a for a in d.build_parser()._actions
           if isinstance(a, argparse._SubParsersAction))
print(*sub.choices, *d.ACTION_EXAMPLES)'); do
    # A here-string, as in the flags step: a pipe into grep -q can fail on
    # SIGPIPE under pipefail after grep has already matched.
    grep -qE -- "(^|[^A-Za-z0-9_-])$word([^A-Za-z0-9_-]|\$)" <<<"$man_text" || {
        echo "demoreel accepts $word, which demoreel.1 never mentions" >&2
        man_missing=$((man_missing + 1))
    }
done
[ "$man_missing" -eq 0 ] || exit 1
if command -v groff >/dev/null; then
    warnings=$(groff -man -ww -z demoreel.1 2>&1)
    [ -z "$warnings" ] || { echo "groff warns about demoreel.1:" >&2
                            echo "$warnings" >&2; exit 1; }
    echo "demoreel.1 names every option, command and step, and renders cleanly"
else
    echo "demoreel.1 names every option, command and step (no groff to render it)"
fi

step "README's language list matches po/"
# DEMO-0067: one place says which languages exist and which are drafts. A
# catalog added, removed or confirmed without the list following would make
# that place wrong, so the list is checked against each catalog's header.
python3 - <<'LANGLISTPY'
import pathlib, re, sys
text = pathlib.Path("README.md").read_text(encoding="utf-8")
section = re.search(r"^## Languages\n(.*?)(?=^## )", text, re.M | re.S)
rows = re.findall(r"^\|[^|\n]+\| `([A-Za-z_@]+)` \| (draft|confirmed) \|$",
                  section[1] if section else "", re.M)
listed = dict(rows)
actual = {}
for path in sorted(pathlib.Path("po").glob("*.po")):
    header = path.read_text(encoding="utf-8").split("\n\n", 1)[0]
    confirmed = re.search(r'"X-Demoreel-Review: confirmed [0-9a-f]{16}\\n"', header)
    actual[path.stem] = "confirmed" if confirmed else "draft"
bad = [f"po/{code}.po is {state}, but README lists it as {listed.get(code, 'missing')}"
       for code, state in actual.items() if listed.get(code) != state]
bad += [f"README lists {code}, but po/{code}.po does not exist"
        for code in listed if code not in actual]
if len(rows) != len(listed):
    bad.append("README lists a language more than once")
for line in bad:
    print(line, file=sys.stderr)
sys.exit(1 if bad else 0)
LANGLISTPY
echo "every catalog in po/ is in README's language list, in the state its header says"

step "each language's quick-start page has README's commands"
# DEMO-0066. docs/quickstart/<code>.md is README from § Install up to § Taking
# a picture, translated. Only its prose and the `#` lines inside its sh blocks
# are translated, so with those lines removed its blocks equal README's, and
# running README's quick start proves every page. One page per catalog, each
# linked from README's top by the name README § Languages gives it.
python3 - <<'QUICKSTARTPY'
import pathlib, re, sys
def blocks(text):
    return [[line for line in block.split("\n") if not line.lstrip().startswith("#")]
            for block in re.findall(r"^```sh\n(.*?)^```$", text, re.M | re.S)]
readme = pathlib.Path("README.md").read_text(encoding="utf-8")
part = re.search(r"^## Install\n(.*?)^## Taking a picture\n", readme, re.M | re.S)
want = blocks(part[1]) if part else []
if not want:
    sys.exit("README has no sh blocks from § Install to § Taking a picture, "
             "so it was not read right")
top = readme.split("\n## ", 1)[0]
languages = re.search(r"^## Languages\n(.*?)(?=^## )", readme, re.M | re.S)
names = {code: name.split(" — ")[-1] for name, code in re.findall(
    r"^\| ([^|\n]+?) \| `([A-Za-z_@]+)` \| (?:draft|confirmed) \|$",
    languages[1] if languages else "", re.M)}
catalogs = {p.stem for p in pathlib.Path("po").glob("*.po")}
pages = {p.stem: p for p in pathlib.Path("docs/quickstart").glob("*.md")}
bad = [f"po/{code}.po has no page at docs/quickstart/{code}.md"
       for code in sorted(catalogs - pages.keys())]
bad += [f"docs/quickstart/{code}.md has no catalog at po/{code}.po"
        for code in sorted(pages.keys() - catalogs)]
for code in sorted(catalogs & pages.keys()):
    got = blocks(pages[code].read_text(encoding="utf-8"))
    if got != want:
        n = next((i for i, (g, w) in enumerate(zip(got, want)) if g != w),
                 min(len(got), len(want)))
        bad.append(f"docs/quickstart/{code}.md: sh block {n + 1} differs from "
                   f"README's, beyond its # lines ({len(got)} blocks, README has {len(want)})")
    link = f"[{names.get(code, '?')}](docs/quickstart/{code}.md)"
    if link not in top:
        bad.append(f"README's top, above its first heading, lacks the link {link}")
for line in bad:
    print(line, file=sys.stderr)
sys.exit(1 if bad else 0)
QUICKSTARTPY
echo "every catalog has a quick-start page, linked from README, with README's commands"

step "documents are readable"
for f in README.md CLAUDE.md ROADMAP.md CHANGELOG.md SECURITY.md CONTRIBUTING.md \
         docs/standards/README.md docs/standards/versioning-overrides.md; do
    [ -s "$f" ] || { echo "missing or empty: $f" >&2; exit 1; }
    python3 -c "import sys; open(sys.argv[1], encoding='utf-8').read()" "$f"
done
echo "all present and valid UTF-8"

if $DOCS_ONLY; then
    printf '\n=== documentation checks passed ===\n'
    exit 0
fi

step "required programs"
missing=()
for prog in ruff python3 ffmpeg Xvfb xauth xdotool xclock xterm xprop; do
    command -v "$prog" >/dev/null || missing+=("$prog")
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "missing: ${missing[*]}" >&2
    echo "xclock comes from x11-apps, xterm from its own package and xprop" >&2
    echo "from x11-utils; the gate uses them to build its targets. The rest" >&2
    echo "are named in README.md." >&2
    exit 1
fi
actual=$(ruff --version | awk '{print $2}')
if [ "$actual" != "$RUFF_VERSION" ]; then
    echo "ruff $actual is installed but this gate is pinned to $RUFF_VERSION" >&2
    echo "a different linter version is drift: install $RUFF_VERSION, or change" >&2
    echo "RUFF_VERSION in ci.sh and the two will move together." >&2
    exit 1
fi
echo "ruff $actual (pinned)"

step "lint"
# The tree AND the source file by name. `ruff check .` alone selects nothing
# here: the file is called `demoreel` with no extension, and ruff's default
# include list is *.py -- so for the whole history before this line the gate
# reported "All checks passed!" about a config file. Naming the tree as well
# keeps any *.py added later covered without a second edit.
ruff check . demoreel
# Prove ruff opened the source rather than trusting that it did. Without this
# the hollow gate is one rename away from coming back, and it comes back green.
selected=$(ruff check --show-files . demoreel)
if [[ $'\n'$selected$'\n' != *$'\n'$PWD/demoreel$'\n'* ]]; then
    echo "ruff did not select demoreel, so the lint step checked nothing." >&2
    echo "it selected:" >&2
    printf '%s\n' "$selected" >&2
    exit 1
fi
echo "ruff analysed demoreel"

step "parse"
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("demoreel").read_text())'
echo "demoreel parses"

step "every recording in this gate names its run"
# DEMO-0114. A run left at the default name collides with any other session
# recording under it, and the gate then fails for a reason that is not ours.
# Continuation lines are joined, so a -n on the next line still counts. Any
# path to the script counts, quoted or not: "$OLDPWD/demoreel" once slipped
# past a check that knew only ./demoreel, and collided with another session.
python3 - <<'EOF'
import re, sys
text = re.sub(r"\\\n", " ", open("ci.sh").read())
bad = [line.strip() for line in text.splitlines()
       # Split in two so this line does not match itself.
       if re.search(r'/demoreel"?' r" record\b(?! --help)", line)
       and not line.lstrip().startswith("#")
       and not re.search(r" (-n|--name) ", line)]
for line in bad:
    print(f"records under the default name: {line[:100]}", file=sys.stderr)
sys.exit(1 if bad else 0)
EOF
echo "no recording here uses the default name"

step "smoke: record an app and prove it reached the frame"
# The check that matters. A valid video file proves nothing on its own -- a
# black recording passes every other test, so sample a frame and measure it.
tmp=$(mktemp -d)

# One teardown for the whole gate, not one per step.
#
# A -d 0 recording never ends by itself, so a step that fails between starting
# one and stopping it leaves the recorder alive. The next run then refuses that
# name, and the failure it reports is the leftover rather than the defect --
# measured during development, at a cost of two cycles to recognise. Per-step
# cleanup does not cover it: the branch most likely to fire is the assertion
# that gives up on finding the run, and that is before the step's own stop.
#
# Each step that launches a recorder appends its pid here. demoreel handles
# SIGTERM by finishing the video and running its own cleanup, so a leftover
# ends the same way `demoreel stop` would end it -- including the window before
# the run has written its state file, where stopping it by name cannot work.
gate_pids=""
cleanup() {
    for pid in $gate_pids; do
        kill "$pid" 2>/dev/null || true
    done
    # Give each one a bounded chance to run its own teardown, which is what
    # takes its Xvfb down with it.
    for pid in $gate_pids; do
        for _ in $(seq 1 50); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
        done
        kill -KILL "$pid" 2>/dev/null || true
    done
    # Then sweep. A recorder signalled before it installed its handlers dies
    # without tearing anything down, and a leaked Xvfb holds its display number
    # and poisons the pool for later runs.
    #
    # Match on the auth file, which carries the run's name, and only for the
    # gate's own `gate*` runs. Two sessions may record at once, so killing
    # every Xvfb this user owns would end someone else's recording. Never
    # widen this to the process name.
    for xv in $(pgrep -u "$(id -u)" -x Xvfb 2>/dev/null); do
        if tr '\0' ' ' < "/proc/$xv/cmdline" 2>/dev/null \
           | grep -q "demoreel-$(id -u)/gate"; then
            kill "$xv" 2>/dev/null || true
        fi
    done
    rm -rf "$tmp"
}
trap cleanup EXIT

# One definition of "sample a frame and prove something was drawn in it", used
# by every step that records something: this smoke test, the --gpu backend and
# the real Flatpak target. The threshold and its comparator still live in
# demoreel; this decides which frame to look at and what to say when it is flat.
assert_frame_drawn() {
    local video=$1 frame=$2 what=$3
    ffmpeg -v error -i "$video" -vf "select=eq(n\\,$frame)" -vframes 1 \
        "$tmp/sample.png" -y
    python3 - "$tmp/sample.png" "$what" <<'PY'
import importlib.machinery, importlib.util, subprocess, sys

# Ask the tool rather than restating its test. The threshold and its comparator
# both live in demoreel, so there is nothing here to keep in step -- the same
# answer this project reached for `ci.sh --ruff-version` and `--docs-glob`,
# pointing the other way. demoreel has no .py extension, so it is loaded by
# path; everything at its module level is imports and constants, and main() is
# behind an __name__ guard, so importing it runs nothing.
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)

raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", sys.argv[1], "-f", "rawvideo", "-pix_fmt", "gray", "-"],
    capture_output=True, check=True).stdout
if not raw:
    sys.exit("could not decode the sampled frame")
print(f"dominant grey level: {demoreel.dominant_fraction(raw):.4f}"
      f" (blank above {demoreel.BLANK_THRESHOLD})")
if demoreel.frame_is_flat(raw):
    sys.exit(f"the frame is a flat colour -- {sys.argv[2]}")
PY
}

out=$(./demoreel record -n gate -o "$tmp/smoke.mp4" -d 5 -s 640x480 -- xclock)
[ -s "$out" ] || { echo "no video written" >&2; exit 1; }
echo "wrote $out"

# -d means what it says (DEMO-0012). Blind sleeps and a sample taken while
# still recording made -d 5 a 6.17 second video; it measures 5.2 now. The
# 0.5 upper bound is room for that remainder, not for the old overshoot.
length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")
python3 -c 'import sys; n = float(sys.argv[1]); sys.exit(not 5.0 <= n <= 5.5)' "$length" || {
    echo "-d 5 produced a ${length}s video" >&2; exit 1; }
echo "-d 5 produced ${length}s"

assert_frame_drawn "$out" 60 "the app never reached the recording"
echo "the app is in the frame"

step "smoke: a blank recording is refused"
# The counterpart to the step above. That one proves a good recording succeeds;
# nothing proved a bad one fails. The behaviour is protected by
# docs/standards/versioning-overrides.md, and CLAUDE.md says not to downgrade it
# to a warning -- someone could, and the gate would have stayed green.
#
# The app maps a window and then kills it while the shell that owns it stays
# alive. That leaves the display blank with the run still going, which is the
# branch that fails; a run whose app exits first skips the check by design.
#
# The kill comes AFTER the halfway sample and before the end, so this is the
# end-of-run check alone. With -d 6 the halfway look lands about 3.5s in and
# the end about 6.5s in, a second and a half either side of the kill at 5s.
set +e
# shellcheck disable=SC2016  # $! and $p belong to the inner sh, not to us
blank_out=$(./demoreel record -n gate -o "$tmp/blank.mp4" -d 6 -s 640x480 \
    -- sh -c 'xclock & p=$!; sleep 5; kill $p; sleep 10' 2>"$tmp/blank.err")
blank_status=$?
set -e
[ "$blank_status" -ne 0 ] || { echo "a blank recording exited 0" >&2; exit 1; }
# The reason matters: a run that failed for some other cause is not this check
# passing. Any exit is non-zero, but only one of them is the guard firing.
grep -q 'was blank at the end' "$tmp/blank.err" || {
    echo "the run failed, but not on the end-of-run blank check:" >&2
    cat "$tmp/blank.err" >&2
    exit 1
}
[ -z "$blank_out" ] || { echo "a failed run printed '$blank_out' on stdout" >&2; exit 1; }
# Protected by the versioning overrides: the video already written stays.
[ -s "$tmp/blank.mp4" ] || { echo "the partial video was not left on disk" >&2; exit 1; }
echo "a blank recording exits non-zero, prints no path, and leaves its file"

step "a recording blank until its second half is refused"
# DEMO-0008. The end sample alone passed an app that drew only in the final
# moments, handing back a video mostly empty. The window goes away at 1s and
# comes back at 7s; with -d 8 the halfway look lands about 4.5s in, and the
# end about 8.5s in with the clock drawn again -- so only the halfway sample
# can fail this run. 0.1.1 returns it with exit 0.
set +e
# shellcheck disable=SC2016  # $! and $p belong to the inner sh, not to us
late_out=$(./demoreel record -n gate -o "$tmp/late.mp4" -d 8 -s 640x480 \
    -- sh -c 'xclock & p=$!; sleep 1; kill $p; sleep 6; exec xclock' 2>"$tmp/late.err")
late_status=$?
set -e
[ "$late_status" -ne 0 ] || { echo "a recording blank until its second half exited 0" >&2; exit 1; }
grep -q 'was blank halfway' "$tmp/late.err" || {
    echo "the run failed, but not on the halfway blank check:" >&2
    cat "$tmp/late.err" >&2
    exit 1
}
[ -z "$late_out" ] || { echo "a failed run printed '$late_out' on stdout" >&2; exit 1; }
echo "a recording blank at halfway fails there"

step "the blank check says when it could not look"
# DEMO-0033. A failed sample used to read as "not blank", which is the success
# path, so the guard passed everything the moment its own measurement broke.
# The realistic way it breaks is the run's environment losing the display's
# cookie, so that is the case exercised: a real, empty display, sampled once
# with the cookie and once without. The first must be blank; the second must
# raise rather than answer.
python3 - <<'SAMPLEPY'
import importlib.machinery, importlib.util, os

loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)

# The name starts with "gate" so the teardown's Xvfb sweep covers it.
displaylog = demoreel.state_dir() / "gatesample.display.log"
proc, display, auth = demoreel.start_xvfb(320, 240, "gatesample", displaylog)
try:
    env = dict(os.environ, DISPLAY=display, XAUTHORITY=str(auth))
    if demoreel.display_is_blank(env, display, 320, 240) is not True:
        raise SystemExit("an empty display did not measure as blank")
    try:
        demoreel.display_is_blank(dict(env, XAUTHORITY="/dev/null"),
                                  display, 320, 240)
    except demoreel.SampleError as exc:
        print(f"could not tell, and said why: {str(exc).splitlines()[0]}")
    else:
        raise SystemExit("a display it could not sample was given a verdict")
finally:
    proc.kill()
    proc.wait()
    auth.unlink(missing_ok=True)
    displaylog.unlink(missing_ok=True)
SAMPLEPY

step "scripted actions reach the app"
# The sharpest gap the gate had: a scripted click or keystroke that quietly
# stops landing still produces a valid-looking video of an app sitting there
# doing nothing. That is the same silent failure the blank check exists to
# catch, one level up, and no video inspection finds it.
#
# xterm runs a shell that reads one line and writes it to a file, so the app
# itself reports what arrived. wait, type and key are all exercised; move and
# click are not, because neither xclock nor xterm reports a click anywhere this
# script can read.
# The text carries both quote marks, an apostrophe and a double space, because
# `type` types the rest of its step exactly. Splitting it like a shell command
# dropped the quotes, collapsed the spaces and died on the apostrophe
# (DEMO-0101).
typed="it's \"quoted\" 'twice'  here"
./demoreel record -n gate -o "$tmp/actions.mp4" -d 12 -s 640x480 \
    -a 'wait 2' -a "type $typed" -a 'key Return' \
    -- xterm -e sh -c "read line; printf '%s' \"\$line\" > $tmp/typed.txt" >/dev/null
got=$(cat "$tmp/typed.txt" 2>/dev/null || true)
[ "$got" = "$typed" ] || {
    echo "the app received '$got', not '$typed' -- scripted actions did not land" >&2
    exit 1
}
echo "wait, type and key all reached the app"

step "--steps reaches the app and keeps typed text off the command line"
# DEMO-0025. -a puts typed text in demoreel's own command line, which any
# local user can read for the whole run. --steps reads the same steps from a
# file or stdin, so the text should arrive and never be in the process list.
# The comment and the blank line are skipped, as in an edit script.
secret="steps-canary-$$"
printf 'wait 2\n# a comment\n\ntype %s\nkey Return\n' "$secret" |
    ./demoreel record -n gate -o "$tmp/steps.mp4" -d 8 -s 640x480 --steps - \
    -- xterm -e sh -c "read line; printf '%s' \"\$line\" > $tmp/steps.txt" \
    >/dev/null &
pid=$!
gate_pids="$gate_pids $pid"
# Read the command line for as long as the run lasts, not once at a guess:
# the app exits after Return, which ends the run, and how soon that is
# depends on the machine.
args=""
while kill -0 "$pid" 2>/dev/null; do
    args+=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
    sleep 0.2
done
wait "$pid"
[ -n "$args" ] || { echo "could not read demoreel's command line" >&2; exit 1; }
case $args in *"$secret"*)
    echo "the typed text is in demoreel's command line: $args" >&2; exit 1 ;;
esac
got=$(cat "$tmp/steps.txt" 2>/dev/null || true)
[ "$got" = "$secret" ] || {
    echo "the app received '$got', not '$secret' -- --steps did not land" >&2
    exit 1
}
echo "--steps typed its text, and the text was not in the process list"

step "a window titled only by _NET_WM_NAME is found"
# DEMO-0043. The window search read only the old WM_NAME, so an app setting
# nothing but _NET_WM_NAME -- vkcube is one -- was never found: every run
# waited out the startup timeout and recorded the window unresized. This
# builds such a window without needing Vulkan: an xterm with an empty title,
# whose own shell then sets _NET_WM_NAME. 0.1.1 says "no window appeared".
# shellcheck disable=SC2016  # $WINDOWID belongs to xterm's shell, not to us
./demoreel record -n gate -o "$tmp/netwm.mp4" -d 2 -s 640x480 --startup-timeout 5 \
    -- xterm -T '' -e sh -c \
    'xprop -id "$WINDOWID" -f _NET_WM_NAME 8u -set _NET_WM_NAME gatewin; sleep 30' \
    >/dev/null 2>"$tmp/netwm.err"
if grep -q 'no window appeared' "$tmp/netwm.err"; then
    echo "a window titled only by _NET_WM_NAME was not found" >&2
    exit 1
fi
echo "found the window by its _NET_WM_NAME title"
if grep -q 'resized its window' "$tmp/netwm.err"; then
    echo "a window that kept its size was reported as resized" >&2
    exit 1
fi

step "an app that resizes itself after demoreel sizes it is warned about"
# DEMO-0099. The window is sized once, before recording; an app that then
# picks its own size records cropped or off to one side, the picture is not
# flat, and every check passed. This xterm keeps shrinking itself, as Vestige
# did. 0.2.1 records it without a word.
# shellcheck disable=SC2016  # $WINDOWID belongs to xterm's shell, not to us
./demoreel record -n gate -o "$tmp/resized.mp4" -d 2 -s 640x480 -- xterm -e sh -c \
    'while :; do sleep 0.3; xdotool windowsize "$WINDOWID" 300 200; done' \
    >/dev/null 2>"$tmp/resized.err"
if ! grep -q 'resized its window to 300x200' "$tmp/resized.err"; then
    echo "a window that resized itself was not reported:" >&2
    cat "$tmp/resized.err" >&2
    exit 1
fi
echo "the self-resized window was reported, with the size to record at"

step "an app that resizes itself once is put back to the frame size"
# DEMO-0121. Seen at halfway, the size is put back once while recording. This
# xterm shrinks itself once and then keeps the size it is given, as Vestige
# did, so the run says it was put back and gives no warning at the end. The
# xterm above, which keeps shrinking itself, still gets the warning.
# shellcheck disable=SC2016  # $WINDOWID belongs to xterm's shell, not to us
./demoreel record -n gate -o "$tmp/putback.mp4" -d 4 -s 640x480 -- xterm -e sh -c \
    'sleep 1; xdotool windowsize "$WINDOWID" 300 200; exec sleep 60' \
    >/dev/null 2>"$tmp/putback.err"
if ! grep -q 'demoreel put it back to fill the 640x480 frame' "$tmp/putback.err" \
   || grep -q 'resized its window to' "$tmp/putback.err"; then
    echo "a window that resized itself once was not put back:" >&2
    cat "$tmp/putback.err" >&2
    exit 1
fi
echo "the window was put back to the frame size, and nothing more was said"

step "the stutter measure tells a stuttering video from a smooth one"
# DEMO-0109. On --gpu a busy 3D app records as runs of repeated frames, and
# changed_share is what notices. Two made-up videos pin it without a card: a
# moving pattern made at 3 frames a second and stored at 30, and the same
# pattern at a full 30. The note's own threshold decides both, so this checks
# the measure and the line together rather than restating either.
ffmpeg -v error -f lavfi -i testsrc=size=320x240:rate=3 -t 12 -r 30 \
    -c:v libx264 -pix_fmt yuv420p -y "$tmp/stutter.mp4"
ffmpeg -v error -f lavfi -i testsrc=size=320x240:rate=30 -t 12 \
    -c:v libx264 -pix_fmt yuv420p -y "$tmp/smooth.mp4"
python3 - "$tmp/stutter.mp4" "$tmp/smooth.mp4" <<'CHANGEDPY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
stutter = demoreel.changed_share(sys.argv[1], 30)
smooth = demoreel.changed_share(sys.argv[2], 30)
print(f"stuttering video {stutter}, smooth video {smooth}, "
      f"note below {demoreel.CHANGED_NOTE_BELOW}")
if stutter is None or smooth is None:
    sys.exit("the measure could not read one of the videos")
if not stutter < demoreel.CHANGED_NOTE_BELOW <= smooth:
    sys.exit("the measure does not separate a stuttering video from a smooth one")
CHANGEDPY
echo "the stutter measure separates the two"

step "the --gpu backend records an app that needs the card"
# DEMO-0006. Xvfb has no DRI, so a GPU app records black on it whatever flags it
# is given; --gpu puts a real Xwayland on a headless cage compositor instead.
# The gate had never recorded on that backend at all, so a regression there
# reached a user before any check saw it, and the only cover was recording
# vkcube by hand and looking at the frame.
#
# It runs where the machine can reach a card and skips where it cannot: an
# ordinary GitHub runner has neither cage nor wf-recorder installed and no render
# node to open. A skip prints why. It is not a pass, and it is not a licence to
# change this path without recording on it.
gpu_missing=()
for prog in cage Xwayland wlr-randr wf-recorder vkcube; do
    command -v "$prog" >/dev/null || gpu_missing+=("$prog")
done
if [ ${#gpu_missing[@]} -gt 0 ]; then
    echo "skipped: this machine has no ${gpu_missing[*]}"
elif ! compgen -G '/dev/dri/renderD*' >/dev/null; then
    echo "skipped: no render node under /dev/dri, so there is no card to reach"
else
    gpu_started=$SECONDS
    ./demoreel record --gpu -n gategpu -o "$tmp/gpu.mp4" -d 3 -s 640x480 \
        -- vkcube >/dev/null 2>"$tmp/gpu.err" || { cat "$tmp/gpu.err" >&2; exit 1; }
    gpu_elapsed=$((SECONDS - gpu_started))
    # vkcube moves every frame and is light, so its video must not draw the
    # stutter note (DEMO-0109). A note here means the measure calls a smooth
    # video stuttering, and would cry wolf on every --gpu run.
    ! grep -q "frames in the middle" "$tmp/gpu.err" || {
        cat "$tmp/gpu.err" >&2
        echo "a smooth vkcube recording drew the stutter note" >&2; exit 1; }
    [ -s "$tmp/gpu.mp4" ] || {
        echo "no video written on the --gpu backend" >&2; exit 1; }
    # A shaded cube is not one colour; a display with nothing on it is. This is
    # the check the backend exists for -- an Xvfb recording of vkcube is a valid
    # file, exit 0 and a black picture.
    assert_frame_drawn "$tmp/gpu.mp4" 30 "vkcube never reached the frame on --gpu"
    # And the run has to have FOUND the window rather than waited out the
    # startup timeout, which is what DEMO-0043 did on this exact app: the
    # recording succeeded, took 24 seconds instead of 4, and framed the window
    # at its own size. Measured after that fix, a -d 3 run of vkcube takes about
    # 4 seconds; the bound separates that from a 20 second timeout without
    # pinning the setup cost.
    [ "$gpu_elapsed" -lt 12 ] || {
        echo "a -d 3 --gpu run took ${gpu_elapsed}s, which is startup-timeout" >&2
        echo "shaped: the window search is probably not finding vkcube." >&2
        exit 1
    }
    echo "vkcube is in the frame, and the window was found in ${gpu_elapsed}s"
    # DEMO-0111. record --gpu records the compositor's picture, which never has
    # the pointer in it, so --cursor must be refused rather than ignored.
    if ./demoreel record --gpu --cursor -n gategpu -o "$tmp/gpucur.mp4" -d 1 \
            -- vkcube >/dev/null 2>"$tmp/gpucur.err"; then
        echo "record --gpu --cursor recorded instead of refusing" >&2; exit 1
    fi
    grep -q "not available with record --gpu" "$tmp/gpucur.err" || {
        cat "$tmp/gpucur.err" >&2
        echo "record --gpu --cursor failed without saying why" >&2; exit 1; }
    echo "record --gpu refuses --cursor"
    # DEMO-0110. A blank --gpu run was told to "record it with --gpu instead".
    # Its advice must fit the backend that ran.
    if ./demoreel record --gpu -n gategpu -o "$tmp/gpublank.mp4" -d 2 \
            -s 320x240 --startup-timeout 1 -- sleep 10 \
            >/dev/null 2>"$tmp/gpublank.err"; then
        echo "a blank --gpu recording was accepted" >&2; exit 1
    fi
    if grep -q "record it with --gpu instead" "$tmp/gpublank.err" \
            || ! grep -q -- "--settle waits" "$tmp/gpublank.err"; then
        cat "$tmp/gpublank.err" >&2
        echo "a blank --gpu run was given the Xvfb advice" >&2; exit 1
    fi
    echo "a blank --gpu run gets advice for --gpu"
fi

step "the pointer starts in the corner, not over the app"
# DEMO-0103. A fresh display puts the pointer at the centre, where it lights
# up whatever the app draws under it before any step runs, drawn or not. The
# app itself reads where the pointer is as it starts. Xvfb once reset on its
# last client leaving, which put a parked pointer straight back.
./demoreel record -n gate -o "$tmp/pointer.mp4" -d 2 -s 400x300 \
    -- sh -c "xdotool getmouselocation --shell > $tmp/pointer.txt; exec xterm -e sleep 10" >/dev/null
where=$(grep -E '^[XY]=' "$tmp/pointer.txt" 2>/dev/null | tr '\n' ' ')
[ "$where" = "X=399 Y=299 " ] || {
    echo "the pointer started at '$where', not in the bottom-right corner" >&2
    exit 1
}
echo "the pointer started in the corner"

step "--cursor draws the pointer, and the default leaves it out"
# Two recordings of the same static app, one with --cursor and one without.
# Only a VISIBLE change counts: a pixel whose grey level moved by more than
# NOISE. The pointer is a small input change, and x264 may answer it by
# shifting its quantisation across the whole frame by a few levels. Ubuntu's
# ffmpeg 6.1 at four threads moved 6557 bytes that way, 28 of them by more
# than 16 -- the pointer (DEMO-0073).
# Both runs move it to the middle first: it starts parked in the bottom-right
# corner (DEMO-0103), where most of it is off the picture.
#
# xterm running `sleep`, not xclock: a clock has a moving second hand, and a
# test that compares two frames cannot tell a moving hand from a drawn pointer.
#
# The upper bound earns its place. "The frames differ" alone would pass if the
# two recordings differed for any unrelated reason; a pointer is a small local
# change, so a large difference means something else moved and the test has
# stopped measuring what it claims to.
./demoreel record -n gate -o "$tmp/nocursor.mp4" -d 3 -s 400x300 -a 'move 200 150' \
    -- xterm -e sleep 10 >/dev/null
./demoreel record -n gate -o "$tmp/cursor.mp4" -d 3 -s 400x300 --cursor -a 'move 200 150' \
    -- xterm -e sleep 10 >/dev/null
for f in nocursor cursor; do
    ffmpeg -v error -i "$tmp/$f.mp4" -vf 'select=eq(n\,30)' -vframes 1 \
        -f rawvideo -pix_fmt gray "$tmp/$f.raw" -y
done
python3 - "$tmp/nocursor.raw" "$tmp/cursor.raw" <<'CURSORPY'
import pathlib, sys
off = pathlib.Path(sys.argv[1]).read_bytes()
on = pathlib.Path(sys.argv[2]).read_bytes()
if not off or len(off) != len(on):
    sys.exit(f"could not compare the frames ({len(off)} and {len(on)} bytes)")
NOISE = 16
differing = sum(1 for a, b in zip(off, on) if abs(a - b) > NOISE)
share = differing / len(off)
print(f"--cursor visibly changed {differing} of {len(off)} bytes ({share * 100:.3f}%)")
if differing == 0:
    sys.exit("--cursor changed nothing -- the pointer was not drawn")
if share > 0.01:
    sys.exit("the frames differ too much to attribute to a pointer")
print("--cursor draws the pointer, and the default leaves it out")
CURSORPY

step "--settle waits for the app's first picture"
# DEMO-0030. The fixture is an xterm painted one colour -- background, text
# and cursor all black, the cursor hidden -- which measures flat, and which
# prints rows of white after a few seconds. An ordinary xterm is no use here:
# its cursor alone keeps it under the blank threshold. So without --settle the
# halfway sample finds the display blank and the run fails; with it the
# recording starts once the rows are drawn, and its first frame shows them.
late_app=(xterm -bg black -fg black -cr black -b 0 -e sh -c
    'printf "\033[?25l"; sleep 4; i=0; while [ $i -lt 30 ]; do printf "\033[47m%80s\033[0m\n" " "; i=$((i+1)); done; sleep 60')
if ./demoreel record -n gate -o "$tmp/unsettled.mp4" -d 3 -s 640x480 \
        -- "${late_app[@]}" >/dev/null 2>&1; then
    echo "the fixture was drawn before the halfway sample, so it cannot test --settle" >&2
    exit 1
fi
out=$(./demoreel record -n gate -o "$tmp/settled.mp4" -d 2 -s 640x480 --settle 20 \
    -- "${late_app[@]}")
assert_frame_drawn "$out" 0 "--settle started recording before the app drew"
echo "without --settle the run failed blank; with it the first frame is drawn"

step "an app that makes the display chatter does not freeze it"
# DEMO-0049. Xvfb's stderr was a pipe demoreel stopped reading after startup.
# Each keymap an app loads makes the server write xkbcomp's warnings there,
# and once the pipe filled the server blocked mid-write: the display froze,
# and so did demoreel, with no timeout reaching it. GIMP hit this in this gate.
# Sixty keymap loads fill the pipe several times over.
timeout 60 ./demoreel record -o "$tmp/chatter.mp4" -d 1 -s 320x240 \
    -n gatechatter -- sh -c \
    'i=0; while [ $i -lt 60 ]; do setxkbmap us; i=$((i+1)); done; exec xclock' \
    >/dev/null 2>&1 || {
    echo "a run whose app loads many keymaps froze or failed (exit $?)" >&2
    exit 1; }
echo "sixty keymap loads, and the display kept answering"

step "a display that stops answering fails the run instead of hanging it"
# DEMO-0079. Nothing bounded a single xdotool or frame-sample call, so a
# display that froze for any other reason hung the run with no timeout. This
# freezes the Xvfb with SIGSTOP once recording starts; the next call at the
# halfway point has to give up and fail the run. 0.2.1 hangs until `timeout`.
./demoreel record -o "$tmp/frozen.mp4" -d 6 -s 320x240 -n gatefrozen \
    -- xclock >/dev/null 2>"$tmp/frozen.err" &
frozen_run=$!
for _ in $(seq 100); do
    grep -q recording "$tmp/frozen.err" 2>/dev/null && break
    sleep 0.1
done
frozen_xvfb=$(pgrep -P "$frozen_run" -x Xvfb)
kill -STOP "$frozen_xvfb"
frozen_at=$SECONDS
rc=0
timeout 60 tail --pid="$frozen_run" -f /dev/null || rc=$?
frozen_took=$((SECONDS - frozen_at))
kill -CONT "$frozen_xvfb" 2>/dev/null || true
if [ "$rc" -ne 0 ]; then
    kill "$frozen_run" 2>/dev/null || true
    echo "a run on a frozen display was still hanging after 60s" >&2
    exit 1
fi
if wait "$frozen_run"; then
    echo "a run on a frozen display reported success" >&2
    exit 1
fi
grep -q 'stopped answering' "$tmp/frozen.err" || {
    echo "a run on a frozen display failed without saying the display stopped:" >&2
    cat "$tmp/frozen.err" >&2; exit 1; }
# DEMO-0078. Giving up takes the halfway wait and one call's timeout, about
# 13s. The recorder and the display are then ended at once: both wait on the
# frozen display, and stopping them gracefully ran out 25s more of timeouts
# for a video the run does not return. 25s is the old total's margin, not the
# new one's.
[ "$frozen_took" -le 25 ] || {
    echo "a run on a frozen display took ${frozen_took}s to give up" >&2; exit 1; }
echo "the frozen display was given up on in ${frozen_took}s, and the run failed saying why"

step "stop ends a run started with -d 0"
# record -d 0 runs until told to stop, and stop is the only way to end it. It
# is documented, and nothing proved either half worked.
./demoreel record -o "$tmp/stopped.mp4" -d 0 -n gatestop -s 640x480 \
    --app-log "$tmp/app.log" -- xclock >/dev/null 2>&1 &
recorder=$!
gate_pids="$gate_pids $recorder"
# Straight after launching it, with no retry. DEMO-0034: a run used to be
# unreachable until it was already recording, so this line said "no recording
# named gatestop" while the run carried on. stop now finds a starting run and
# waits for it to record.
stopped=$(./demoreel stop gatestop) || {
    echo "stop could not find a run launched just before it" >&2; exit 1; }
[ "$stopped" = "$tmp/stopped.mp4" ] || {
    echo "stop printed '$stopped', not the output path" >&2; exit 1; }
# Before waiting on the recorder: the path stop prints must already be a
# finished video. It used to print as soon as it signalled, while ffmpeg was
# still writing the file (DEMO-0047).
ffprobe -v error "$tmp/stopped.mp4" || {
    echo "stop returned before the video was finished" >&2; exit 1; }
wait "$recorder" || { echo "the stopped run exited non-zero" >&2; exit 1; }
[ -s "$tmp/stopped.mp4" ] || { echo "stop left no video" >&2; exit 1; }
# --app-log rode along: same run, and it is documented too.
[ -f "$tmp/app.log" ] || { echo "--app-log wrote no file" >&2; exit 1; }
echo "stop ended the run, and --app-log wrote its file"

step "Ctrl+C finishes a recording, and the blank check still runs"
# DEMO-0054. A terminal sends Ctrl+C's SIGINT to the whole foreground process
# group. Xvfb was in that group and went down with it, so the app died too and
# the end-of-run blank check was skipped as if the app had closed itself. The
# second run draws nothing: it must fail on the blank check, which it can only
# reach if the display outlived the Ctrl+C.
python3 - "$tmp" <<'CTRLCPY'
import os, signal, subprocess, sys, time

tmp = sys.argv[1]


def ctrl_c(name, app, extra=()):
    err = f"{tmp}/{name}.err"
    with open(err, "w") as errfile:
        run = subprocess.Popen(
            ["./demoreel", "record", "-n", "gate", "-o", f"{tmp}/{name}.mp4",
             "-d", "0", "-s", "320x240", *extra, "--", *app],
            stdout=subprocess.PIPE, stderr=errfile, start_new_session=True)
        for _ in range(300):
            time.sleep(0.1)
            if "recording :" in open(err).read():
                break
        else:
            run.kill()
            raise SystemExit(f"{name}: the run never started recording:\n"
                             + open(err).read())
        time.sleep(1)
        os.killpg(run.pid, signal.SIGINT)  # what a terminal's Ctrl+C sends
        out, _ = run.communicate(timeout=60)
    return run.returncode, out.decode().strip(), open(err).read()


status, out, err = ctrl_c("ctrlc", ["xclock"])
if status != 0 or out != f"{tmp}/ctrlc.mp4" or not os.path.getsize(out):
    raise SystemExit(f"Ctrl+C did not finish the video (exit {status}):\n{err}")
status, out, err = ctrl_c("ctrlcblank", ["sleep", "60"], ["--startup-timeout", "1"])
if status == 0 or "was blank at the end" not in err:
    raise SystemExit(f"after Ctrl+C the blank check did not run (exit {status}):\n{err}")
print("Ctrl+C leaves a finished video, and the end-of-run blank check still runs")
CTRLCPY

step "a closed terminal finishes the video and leaves nothing running"
# DEMO-0115. Closing a terminal sends its session SIGHUP. demoreel did not
# handle it: it died on the spot and left Xvfb running, and once it did handle
# it, ffmpeg -- in the same group -- died without writing its index, and the
# run printed the path of a file nothing could play. The run's stderr is a
# pseudo-terminal that is closed first, as a real one would be.
python3 - "$tmp" <<'HUPPY'
import os, pty, shutil, signal, subprocess, sys, time
from pathlib import Path

tmp = sys.argv[1]


def servers(marker):
    ps = subprocess.run(["pgrep", "-a", "-x", "Xvfb"], capture_output=True,
                        text=True).stdout.splitlines()
    return [line.split()[0] for line in ps if marker in line]


def hang_up(args, marker, ready):
    master, slave = pty.openpty()
    run = subprocess.Popen(["./demoreel", *args], stdout=subprocess.PIPE,
                           stderr=slave, start_new_session=True)
    os.close(slave)
    seen = b""
    for _ in range(300):
        time.sleep(0.1)
        try:
            seen += os.read(master, 4096)
        except OSError:
            pass
        if ready in seen:
            break
    else:
        run.kill()
        raise SystemExit(f"never saw {ready!r}:\n{seen.decode(errors='replace')}")
    time.sleep(1)
    started = servers(marker)
    os.close(master)                 # the terminal goes away...
    os.killpg(run.pid, signal.SIGHUP)  # ...and its session is hung up
    out, _ = run.communicate(timeout=60)
    time.sleep(1)
    left = [pid for pid in started if os.path.exists(f"/proc/{pid}")]
    if not started or left:
        raise SystemExit(f"{args[0]}: Xvfb {started}, still running after: {left}")
    return run.returncode, out.decode().strip()


video = f"{tmp}/hup.mp4"
status, out = hang_up(["record", "-n", "gate", "-o", video, "-d", "0", "-s",
                       "320x240", "--", "xclock"], "gate.Xvfb", b"recording :")
readable = subprocess.run(["ffprobe", "-v", "error", video],
                          capture_output=True).returncode == 0
if status != 0 or out != video or not readable:
    raise SystemExit(f"record: exit {status}, stdout {out!r}, playable {readable}")
# A failed shot keeps its folder, and here nobody could read where: remove it.
state = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp") / f"demoreel-{os.getuid()}"
before = set(state.glob("shot-*"))
hang_up(["shot", "-o", f"{tmp}/hup.png", "-s", "320x240", "--startup-timeout",
         "1", "--settle", "30", "--", "sleep", "60"], "/shot-", b"no window")
for kept in set(state.glob("shot-*")) - before:
    shutil.rmtree(kept)
print("a hung-up run finishes a playable video, and nothing is left running")
HUPPY

step "a terminal sees the countdown, and a script sees nothing new"
# DEMO-0053. On a terminal, one line counts down in place and a summary
# follows. Anywhere else stderr must be exactly what it was: callers such as
# Claude sessions read it, and a stream of carriage returns is noise to them.
python3 - "$tmp" <<'TTYPY'
import os, pty, subprocess, sys

tmp = sys.argv[1]
args = ["./demoreel", "record", "-n", "gate", "-d", "2", "-s", "320x240"]
master, slave = pty.openpty()
run = subprocess.Popen([*args, "-o", f"{tmp}/tty.mp4", "--", "xclock"],
                       stdout=subprocess.PIPE, stderr=slave)
os.close(slave)
seen = b""
while True:
    try:
        chunk = os.read(master, 4096)
    except OSError:  # EIO once the run has closed its end
        break
    if not chunk:
        break
    seen += chunk
run.communicate()
os.close(master)
text = seen.decode(errors="replace")
if run.returncode != 0 or "s left" not in text or "s of video" not in text:
    raise SystemExit(f"no countdown or summary on a terminal:\n{text!r}")
plain = subprocess.run([*args, "-o", f"{tmp}/plain.mp4", "--", "xclock"],
                       capture_output=True, text=True)
if plain.returncode != 0 or "\r" in plain.stderr or "left" in plain.stderr:
    raise SystemExit(f"stderr off a terminal changed:\n{plain.stderr!r}")
print("a terminal gets the countdown and summary; a pipe gets neither")
TTYPY

step "a held key is let go when a stop cuts the hold short"
# DEMO-0098. `hold KEY SECONDS` presses a key and waits. If a stop ends the
# wait and the keyup is skipped, the key stays down on the display for the
# rest of the run. A held key auto-repeats, so an xterm writing what it gets
# to a file shows it: letters arrive during the hold and must stop after.
python3 - "$tmp" <<'HOLDPY'
import importlib.machinery, importlib.util, os, signal, subprocess, sys, threading, time

tmp = sys.argv[1]
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
signal.signal(signal.SIGUSR1, demoreel._request_stop)

# The name starts with "gate" so the teardown's Xvfb sweep covers it.
displaylog = demoreel.state_dir() / "gatehold.display.log"
proc, display, auth = demoreel.start_xvfb(320, 240, "gatehold", displaylog)
env = dict(os.environ, DISPLAY=display, XAUTHORITY=str(auth))
keys = f"{tmp}/held.txt"
app = subprocess.Popen(["xterm", "-e", "sh", "-c",
                        f"stty -icanon -echo min 1; cat > {keys}"],
                       env=env, start_new_session=True)
try:
    if demoreel.wait_for_window(env, app, 10) is None:
        raise SystemExit("the xterm never showed a window")
    time.sleep(1)
    threading.Timer(1.5, lambda: os.kill(os.getpid(), signal.SIGUSR1)).start()
    demoreel.run_action("hold a 30", env)
    time.sleep(0.5)
    during = os.path.getsize(keys)
    time.sleep(1.5)
    after = os.path.getsize(keys)
finally:
    demoreel.end_process(app, group=True)
    demoreel.end_server(proc)
    auth.unlink(missing_ok=True)
    displaylog.unlink(missing_ok=True)
if during < 2:
    raise SystemExit(f"only {during} letters while held: auto-repeat is off, "
                     "so this step cannot tell a held key from a released one")
if after != during:
    raise SystemExit(f"the key was still down after the stop: {during} letters, "
                     f"then {after}")
print(f"{during} letters while held, none after the stop")
HOLDPY

step "a missing program, or an ffmpeg without libx264, says what to install"
# DEMO-0051: a missing program is named with the command that installs it on
# this distro. DEMO-0117: the distros' own ffmpeg on openSUSE and Fedora has
# no libx264, so every recording failed there; it is refused up front. Both
# use a PATH built for the test, so the machine's own tools are untouched.
mkdir -p "$tmp/noxdo" "$tmp/nox264"
for t in ffmpeg ffprobe xauth Xvfb xclock; do ln -s "$(command -v "$t")" "$tmp/noxdo/$t"; done
for t in ffprobe xdotool xauth Xvfb xclock; do ln -s "$(command -v "$t")" "$tmp/nox264/$t"; done
printf '#!/bin/sh\ncase "$*" in *-encoders*) echo " V....D libopenh264 OpenH264" ;;\n*) exec %s "$@" ;; esac\n' \
    "$(command -v ffmpeg)" >"$tmp/nox264/ffmpeg"
chmod +x "$tmp/nox264/ffmpeg"
py=$(command -v python3)
for case in noxdo nox264; do
    set +e
    PATH="$tmp/$case" "$py" ./demoreel record -n gate -o "$tmp/$case.mp4" -- xclock \
        2>"$tmp/$case.err"
    case_status=$?
    set -e
    [ "$case_status" -ne 0 ] || { echo "$case: the run did not fail" >&2; exit 1; }
done
grep -q 'missing required program(s): xdotool' "$tmp/noxdo.err" \
    && [ -n "$(sed -n '/Install with: .*xdotool/p' "$tmp/noxdo.err")" ] || {
    echo "a missing xdotool did not name its install command:" >&2
    cat "$tmp/noxdo.err" >&2
    exit 1
}
grep -q 'cannot encode H.264 with libx264' "$tmp/nox264.err" || {
    echo "an ffmpeg without libx264 was not refused:" >&2
    cat "$tmp/nox264.err" >&2
    exit 1
}
echo "a missing program names its install command; no libx264 is refused"

step "check says whether this machine can record"
# DEMO-0052. This machine can, so check must say so, exit 0 and print nothing
# on stdout. The PATH without xdotool from the step above cannot: check must
# say NOT READY with the install command, and exit non-zero.
check_out=$(./demoreel check 2>"$tmp/check.err") || {
    echo "check failed on a machine that records:" >&2; cat "$tmp/check.err" >&2; exit 1
}
[ -z "$check_out" ] && grep -q 'record and shot: ready' "$tmp/check.err" || {
    echo "check did not report ready, or wrote to stdout ('$check_out'):" >&2
    cat "$tmp/check.err" >&2
    exit 1
}
set +e
PATH="$tmp/noxdo" "$py" ./demoreel check 2>"$tmp/check-noxdo.err"
check_status=$?
set -e
[ "$check_status" -ne 0 ] && grep -q 'record and shot: NOT READY' "$tmp/check-noxdo.err" \
    && [ -n "$(sed -n '/Install with: .*xdotool/p' "$tmp/check-noxdo.err")" ] || {
    echo "check without xdotool exited $check_status:" >&2
    cat "$tmp/check-noxdo.err" >&2
    exit 1
}
echo "check reports ready here, and names the install command when it is not"

step "a malformed step is refused before anything starts"
# DEMO-0055. A step with a missing or wrong argument reached float() or args[1]
# and ended the run with a Python traceback, mid-recording when it was a late
# step. Every step is now read first, and the error shows how to write it.
set +e
./demoreel record -n gate -o "$tmp/badstep.mp4" -a 'wait 1' -a 'move 5' -- xclock \
    2>"$tmp/badstep.err"
badstep_status=$?
set -e
[ "$badstep_status" -ne 0 ] && grep -q "write it like 'move 400 300'" "$tmp/badstep.err" \
    && ! grep -q 'Traceback\|recording :' "$tmp/badstep.err" || {
    echo "a malformed step was not refused up front (exit $badstep_status):" >&2
    cat "$tmp/badstep.err" >&2
    exit 1
}
echo "a malformed step is refused before the display starts, with an example"

step "a stop is noticed at once"
# DEMO-0075. The recording loop slept between checks, and a sleep resumes after
# the signal handler runs, so a stop landed up to a fifth of a second late --
# a median 107 ms, all of it in the video. Ten stops at random moments: the
# old loop misses 50 ms on three in four, so it cannot pass all ten.
python3 - <<'STOPPY'
import importlib.machinery, importlib.util, os, random, signal, threading, time, types

loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
signal.signal(signal.SIGUSR1, demoreel._request_stop)


class Running:  # an app and a recorder that never exit on their own
    def poll(self):
        return None


worst = 0.0
for _ in range(10):
    demoreel._stop.clear()
    sent = []
    threading.Timer(random.uniform(0.05, 0.3), lambda: (
        sent.append(time.monotonic()), os.kill(os.getpid(), signal.SIGUSR1))).start()
    demoreel.run_countdown(types.SimpleNamespace(action=[], duration=0), {},
                           Running(), None, ":0", Running(), 2, 2, "log",
                           time.monotonic(), demoreel.Checks())
    worst = max(worst, time.monotonic() - sent[0])
if worst > 0.05:
    raise SystemExit(f"a stop took {worst * 1000:.0f} ms to be noticed")
print(f"a stop is noticed within {worst * 1000:.1f} ms")
STOPPY

step "a recorder killed mid-run fails the run"
# DEMO-0116. A killed ffmpeg leaves an mp4 with no index. The file is there
# and not empty, and the run used to print its path and exit 0.
set +e
./demoreel record -n gate -o "$tmp/killed.mp4" -d 6 -s 320x240 -- xclock \
    >"$tmp/killed.out" 2>"$tmp/killed.err" &
killed_rec=$!
gate_pids="$gate_pids $killed_rec"
for _ in $(seq 1 100); do
    # sed, not grep: see the cookie step -- grep's exit 1 kills a pipefail run.
    [ -n "$(sed -n '/recording :/p' "$tmp/killed.err")" ] && break
    sleep 0.1
done
sleep 1.5
pkill -KILL -f "^ffmpeg .*$tmp/killed.mp4"
wait "$killed_rec"
killed_status=$?
set -e
[ "$killed_status" -ne 0 ] && [ ! -s "$tmp/killed.out" ] || {
    echo "a run whose recorder was killed exited $killed_status and printed" \
         "'$(cat "$tmp/killed.out")'" >&2
    exit 1
}
grep -q 'the video cannot be played' "$tmp/killed.err" || {
    echo "the run failed, but not on the playable-video check:" >&2
    cat "$tmp/killed.err" >&2
    exit 1
}
echo "a run whose recorder was killed fails, and prints no path"

step "stop fails when the run it stopped fails"
# DEMO-0047. A -d 0 run that is blank when stopped fails its end-of-run check,
# and stop used to print its path anyway, so `out=$(demoreel stop ...)` held a
# path for a failed run. sleep opens no window, so the display stays blank.
./demoreel record -o "$tmp/blankstop.mp4" -d 0 -n gateblankstop -s 320x240 \
    --startup-timeout 1 -- sleep 60 >/dev/null 2>&1 &
recorder=$!
gate_pids="$gate_pids $recorder"
if blankpath=$(./demoreel stop gateblankstop 2>/dev/null); then
    echo "stop succeeded for a run that failed, printing '$blankpath'" >&2
    exit 1
fi
[ -z "$blankpath" ] || {
    echo "stop printed '$blankpath' for a run that failed" >&2; exit 1; }
if wait "$recorder"; then
    echo "the blank run succeeded, so this step tested nothing" >&2; exit 1
fi
echo "stop failed with the run, and printed no path"

step "two runs started together under one name: one records, one is refused"
# DEMO-0011. The duplicate-name check used to read the state file and write it
# much later, so two runs launched together both passed it, both recorded, and
# the later one's state file hid the earlier one from `stop`. Measured at the
# time. A lock now makes the check atomic.
./demoreel record -o "$tmp/race1.mp4" -d 3 -n gaterace -s 320x240 \
    -- xclock >/dev/null 2>"$tmp/race1.err" &
race1=$!
./demoreel record -o "$tmp/race2.mp4" -d 3 -n gaterace -s 320x240 \
    -- xclock >/dev/null 2>"$tmp/race2.err" &
race2=$!
gate_pids="$gate_pids $race1 $race2"
set +e
wait "$race1"; s1=$?
wait "$race2"; s2=$?
set -e
refused=$(cat "$tmp/race1.err" "$tmp/race2.err" | sed -n '/already running/p')
if [ $((s1 + s2)) -ne 1 ] || [ -z "$refused" ]; then
    echo "expected one run to record and one to be refused; exits were $s1 and $s2" >&2
    cat "$tmp/race1.err" "$tmp/race2.err" >&2
    exit 1
fi
echo "one recorded, and the other said: ${refused#demoreel: }"

step "stop refuses a state file whose process is not ours"
# A run killed with SIGKILL never reaches the cleanup in its `finally` block,
# so its state file outlives it -- and Linux recycles pids. Before the run's
# start time was recorded alongside the pid, stop asked only whether SOME
# process held that number and sent it SIGUSR1, whose default action is to
# terminate. Demonstrated at the time against a plain `sleep`, which died
# reporting "User defined signal 1", while stop printed a path and exited 0.
statedir="${XDG_RUNTIME_DIR:-/tmp}/demoreel-$(id -u)"
mkdir -p "$statedir" && chmod 700 "$statedir"
sleep 60 &
victim=$!
# A start time of 1 belongs to no real process: the field counts clock ticks
# since boot, so anything running now is far past it. That is the recycled-pid
# case -- right pid, wrong incarnation.
printf '{"name":"gatestale","pid":%d,"starttime":"1","display":":9","output":"%s"}\n' \
    "$victim" "$tmp/never.mp4" > "$statedir/gatestale.json"
if ./demoreel stop gatestale >/dev/null 2>&1; then
    kill "$victim" 2>/dev/null || true
    echo "stop acted on a state file whose recorded start time does not match" >&2
    exit 1
fi
if ! kill -0 "$victim" 2>/dev/null; then
    echo "stop signalled a process it never started" >&2
    exit 1
fi
kill "$victim" 2>/dev/null || true
wait "$victim" 2>/dev/null || true
rm -f "$statedir/gatestale.json"
echo "stop left the unrelated process alone"

step "the virtual display refuses a client with no cookie"
# The display is private or the tool has no point. Measured before this guard
# existed: a client with no credential at all read the geometry and grabbed a
# frame of whatever was on screen. Socket permissions cannot fix it, because
# Xvfb also listens on an abstract socket, which has none.
# The app itself probes first: the lock must already be in force when the app
# starts, not only by the time the gate looks (DEMO-0113).
./demoreel record -o "$tmp/cookie.mp4" -d 0 -n gatecookie -s 640x480 \
    -- sh -c 'XAUTHORITY=/dev/null xdotool getdisplaygeometry >/dev/null 2>&1
              echo $? >"$1"; exec xclock' sh "$tmp/cookie.atstart" \
    >/dev/null 2>"$tmp/cookie.err" &
cookie_rec=$!
gate_pids="$gate_pids $cookie_rec"
disp=""
for _ in $(seq 1 100); do
    # sed, not grep: this script runs under pipefail, and grep exits 1 when it
    # matches nothing, which kills the run silently while we are still waiting
    # for the line to appear. sed exits 0 either way.
    disp=$(sed -n 's/.*recording \(:[0-9][0-9]*\).*/\1/p' "$tmp/cookie.err" | head -1)
    [ -n "$disp" ] && break
    sleep 0.2
done
if [ -z "$disp" ]; then
    # Stop the run before failing, or it outlives the gate holding a display,
    # and the next run refuses the name it is still using.
    ./demoreel stop gatecookie >/dev/null 2>&1 || kill "$cookie_rec" 2>/dev/null || true
    echo "the run never reported its display:" >&2
    cat "$tmp/cookie.err" >&2
    exit 1
fi
set +e
XAUTHORITY=/dev/null DISPLAY="$disp" xdotool getdisplaygeometry >/dev/null 2>&1
uncredentialed=$?
set -e
./demoreel stop gatecookie >/dev/null
wait "$cookie_rec" || true
atstart=$(cat "$tmp/cookie.atstart" 2>/dev/null || echo missing)
case "$atstart" in
    missing|0)
        echo "a client with no cookie was not refused when the app started" \
             "(probe: $atstart) -- the lock was not yet in force" >&2
        exit 1 ;;
esac
[ "$uncredentialed" -ne 0 ] || {
    echo "a client with no cookie read $disp -- the display is not private" >&2
    exit 1
}
echo "a client with no cookie cannot reach the display, from the app's start on"

step "a Flatpak target missing its flags is warned about"
# Without the flags a Flatpak renders on the real compositor and the run fails
# the blank check with a message naming two possible causes. Saying which one it
# is costs nothing and saves the recording.
#
# A stub named flatpak stands in for the real one: what is under test is the
# reading of the caller's command line, not flatpak itself, and the stub keeps
# the step working on a runner with no Flatpak installed.
mkdir -p "$tmp/bin"
printf '#!/bin/sh\nexec xclock\n' > "$tmp/bin/flatpak"
chmod +x "$tmp/bin/flatpak"
PATH="$tmp/bin:$PATH" ./demoreel record -n gate -o "$tmp/fp.mp4" -d 3 -s 640x480 \
    -- flatpak run org.example.App >/dev/null 2>"$tmp/fp.err"
grep -q -- '--nosocket=wayland' "$tmp/fp.err" || {
    echo "an under-flagged Flatpak target drew no warning:" >&2
    cat "$tmp/fp.err" >&2
    exit 1
}
# And a fully-flagged one must stay quiet, or the warning is noise.
PATH="$tmp/bin:$PATH" ./demoreel record -n gate -o "$tmp/fp-ok.mp4" -d 3 -s 640x480 \
    -- flatpak run --socket=x11 --nosocket=wayland --filesystem=/tmp/.X11-unix \
    org.example.App >/dev/null 2>"$tmp/fp-ok.err"
! grep -q 'is missing' "$tmp/fp-ok.err" || {
    echo "a correctly-flagged Flatpak target was warned about anyway" >&2
    exit 1
}
echo "the missing flags are named, and a complete command is left alone"

step "a real Flatpak records with the three flags README documents"
# DEMO-0007. The step above tests demoreel's reading of a Flatpak command line,
# against a stub that is not Flatpak at all. Nothing tested the recipe itself,
# so the three flags README prints could stop working -- a Flatpak release
# changing what `--socket=x11` binds would do it -- and the gate would stay
# green.
#
# GIMP, deliberately not finbreak: a startup dialog and single-instance handover
# are the two traps README names, and a gate step is the wrong place to meet
# them. It is a plain GTK application, installed from Flathub, and it reaches
# the private display in about five seconds.
#
# What this proves is that a real Flatpak draws on the private display through
# those three flags. It is NOT a check that GIMP finished starting: at three
# seconds the window in frame is its splash, which is what a recording that
# short honestly shows.
#
# The negative case -- the same app WITHOUT --nosocket=wayland -- is deliberately
# not run here. Without it the app reaches the user's real compositor, which
# means opening a window on their desktop, and a gate that runs before every
# push must not do that. The stub step above covers the warning.
flatpak_app=org.gimp.GIMP
if ! command -v flatpak >/dev/null; then
    echo "skipped: this machine has no flatpak"
elif ! flatpak info "$flatpak_app" >/dev/null 2>&1; then
    echo "skipped: $flatpak_app is not installed"
elif flatpak ps --columns=application 2>/dev/null | grep -qx "$flatpak_app"; then
    # A running copy takes the launch over on the real desktop and the private
    # display stays empty, so the step would fail for a reason that is not
    # demoreel's. Skipping says which it is.
    echo "skipped: $flatpak_app is already running, so a launch would hand over"
else
    ./demoreel record -n gateflatpak -o "$tmp/real-fp.mp4" -d 3 -s 800x600 \
        --startup-timeout 60 \
        -- flatpak run --socket=x11 --nosocket=wayland \
           --filesystem=/tmp/.X11-unix "$flatpak_app" >/dev/null
    [ -s "$tmp/real-fp.mp4" ] || {
        echo "no video written for $flatpak_app" >&2; exit 1; }
    assert_frame_drawn "$tmp/real-fp.mp4" 45 \
        "$flatpak_app never reached the private display with the documented flags"
    echo "$flatpak_app drew on the private display with the three flags"
fi

step "the state directory must be one we own"
# The run-state directory's name is predictable, so on a shared machine another
# user can create it first and demoreel would adopt it. The check is exercised
# inside $tmp with XDG_RUNTIME_DIR pointed at it, so nothing outside this run's
# own scratch directory is touched -- planting the real name under /tmp would
# collide with any other recording on the machine.
mkdir -p "$tmp/fakerun"
ln -s /tmp "$tmp/fakerun/demoreel-$(id -u)"
set +e
XDG_RUNTIME_DIR="$tmp/fakerun" ./demoreel record -n gate -o "$tmp/planted.mp4" \
    -d 3 -s 640x480 -- xclock >"$tmp/planted.out" 2>"$tmp/planted.err"
planted_status=$?
set -e
[ "$planted_status" -ne 0 ] || { echo "demoreel used a planted symlink" >&2; exit 1; }
grep -q 'not a directory you own' "$tmp/planted.err" || {
    echo "the run failed, but not on the state-directory guard:" >&2
    cat "$tmp/planted.err" >&2
    exit 1
}
echo "a state directory we do not own is refused"

step "an output path that is another user's symlink is refused"
# DEMO-0082. demoreel resolves -o itself, so the kernel's protected_symlinks
# never sees the link: a planted /tmp/demo.mp4 had its target overwritten. A
# root-owned link in /usr/bin stands in for another user's, since the gate
# cannot make a link owned by someone else. It is refused before anything runs.
foreign=$(find /usr/bin -maxdepth 1 -type l -user 0 -print -quit)
[ -n "$foreign" ] || { echo "no root-owned symlink in /usr/bin to test with" >&2; exit 1; }
for flag in -o --app-log; do
    set +e
    if [ "$flag" = -o ]; then
        ./demoreel shot -o "$foreign" -s 320x240 -- xclock 2>"$tmp/foreign.err"
    else
        ./demoreel shot -o "$tmp/foreign.png" --app-log "$foreign" -s 320x240 \
            -- xclock 2>"$tmp/foreign.err"
    fi
    foreign_status=$?
    set -e
    [ "$foreign_status" -ne 0 ] || { echo "$flag wrote through $foreign" >&2; exit 1; }
    grep -q 'symbolic link another user made' "$tmp/foreign.err" || {
        echo "$flag failed, but not on the planted-link guard:" >&2
        cat "$tmp/foreign.err" >&2
        exit 1
    }
done
echo "-o and --app-log refuse a symlink another user made"

step "shot takes one picture, prints its path, and leaves nothing behind"
# DEMO-0100. The picture is checked by reading the saved file back, with the
# same frame_is_flat as a recording. An odd size is allowed: that rule is
# H.264's. A shot writes no state file, so `stop` cannot see one, and its
# private folder goes when it succeeds.
before=$(find "$statedir" -maxdepth 1 -name "shot-*" | wc -l)
shot=$(./demoreel shot -o "$tmp/clock.png" -s 321x241 -- xclock)
[ "$shot" = "$tmp/clock.png" ] || { echo "shot printed '$shot', not its path" >&2; exit 1; }
python3 - "$tmp/clock.png" <<'PY'
import importlib.machinery, importlib.util, subprocess, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
dr = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(dr)
raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", sys.argv[1],
                      "-pix_fmt", "gray", "-f", "rawvideo", "-"],
                     capture_output=True, check=True).stdout
assert len(raw) == 321 * 241, len(raw)
assert not dr.frame_is_flat(raw), "the picture is flat"
PY
after=$(find "$statedir" -maxdepth 1 -name "shot-*" | wc -l)
[ "$after" -eq "$before" ] || { echo "a successful shot left its folder behind" >&2; exit 1; }
echo "one 321x241 picture of the app, its path on stdout, nothing left over"

step "a flat picture is refused"
if out=$(./demoreel shot -o "$tmp/flat.png" -s 320x240 --settle 1 \
         --startup-timeout 2 -- sleep 30 2>"$tmp/flat.err"); then
    echo "a picture of nothing was accepted" >&2; exit 1
fi
[ -z "$out" ] || { echo "a refused shot still printed a path: $out" >&2; exit 1; }
grep -q 'one flat colour' "$tmp/flat.err" || { cat "$tmp/flat.err" >&2; exit 1; }
rm -rf "$(sed -n 's/.*display log is kept in //p' "$tmp/flat.err")"
echo "a flat picture failed the run and printed no path"

step "a shot that fails early names the folder it kept"
# DEMO-0107. A failed shot keeps its private folder, and that folder lives
# in RAM under /run/user. Only two failure paths said where it was, so one
# failing before the picture left it behind unnamed.
if ./demoreel shot -o "$tmp/none.png" -s 320x240 -- /nonexistent/app \
       >/dev/null 2>"$tmp/early.err"; then
    echo "a shot of an app that cannot start succeeded" >&2; exit 1
fi
kept=$(sed -n 's/.*display log is kept in //p' "$tmp/early.err")
[ -n "$kept" ] && [ -d "$kept" ] || {
    echo "an early shot failure did not name the folder it kept:" >&2
    cat "$tmp/early.err" >&2; exit 1; }
rm -rf "$kept"
echo "the early failure named its folder"

step "tab completion offers what demoreel accepts, in bash, zsh and fish"
# DEMO-0056. Each script is asked what it offers, the way the shell asks it,
# and the answer is held against demoreel's own parser: the subcommands, every
# option of record and shot, and the -a verbs. So a flag added to the tool and
# forgotten in a script fails here. `stop` must offer the runs still going and
# nothing else: every run leaves its state file behind, and a file whose pid
# has been recycled is not a run either. Three fake state files cover the
# three cases, against a sleep standing in for a live run.
sleep 300 &
fake_run=$!
gate_pids="$gate_pids $fake_run"
expected=$(XDG_RUNTIME_DIR="$tmp/xdg" python3 - "$fake_run" <<'COMPLETIONPY'
import argparse, importlib.machinery, importlib.util, json, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
demoreel = importlib.util.module_from_spec(
    importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(demoreel)
pid = int(sys.argv[1])
d = demoreel.state_dir()
for name, entry in {
        "gatelive": {"pid": pid, "starttime": demoreel.proc_starttime(pid)},
        "gaterecycled": {"pid": pid, "starttime": "1"},
        "gatefinished": {"pid": 2 ** 22 + 1, "starttime": "1"}}.items():
    (d / f"{name}.json").write_text(json.dumps({"name": name, **entry}))
sub = next(a for a in demoreel.build_parser()._actions
           if isinstance(a, argparse._SubParsersAction))
# Each line: the command line exactly as typed before Tab | what it must offer.
print("demoreel |" + " ".join(sub.choices))
for cmd in ("record", "shot"):
    print(f"demoreel {cmd} -|" + " ".join(
        o for a in sub.choices[cmd]._actions for o in a.option_strings))
print("demoreel record -a |" + " ".join(demoreel.ACTION_EXAMPLES))
print("demoreel stop |gatelive")
COMPLETIONPY
)
cat > "$tmp/zcomp.zsh" <<'ZCOMP'
# zsh completes only at an interactive prompt, so drive one through zpty and
# wrap compadd to print each candidate. The markers are split in two so that
# the terminal echoing these lines back cannot match them.
zmodload zsh/zpty
zpty z zsh -f -i
zpty -w z "PS1= fpath=($1 \$fpath); autoload -Uz compinit; compinit -u -D"
zpty -w z 'compadd () {
  if [[ ${@[1,(i)(-|--)]} == *-(O|A|D)\ * ]]; then builtin compadd "$@"; return; fi
  typeset -a __hits; builtin compadd -A __hits "$@"
  local h; for h in $__hits; print -r -- "<""HIT>$h"
  builtin compadd -Q -U ""
}'
zpty -w z 'finish () { print "<""DONE>"; zle kill-whole-line; zle -R }
zle -N finish; bindkey "^X" finish'
zpty -n -w z "$2"$'\t'
zpty -n -w z $'\C-X'
while zpty -r z line; do
  [[ $line == *'<DONE>'* ]] && break
  [[ $line == *'<HIT>'* ]] && print -r -- "${${line#*<HIT>}//[$'\r\n']/}"
done
zpty -d z
ZCOMP
offered() {  # shell, command line -> the candidates, one per line
    case $1 in
    bash) bash -c 'source completions/demoreel.bash
        read -ra COMP_WORDS <<< "$1"; [[ $1 == *" " ]] && COMP_WORDS+=("")
        COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
        _demoreel 2>/dev/null; printf "%s\n" "${COMPREPLY[@]}"' _ "$2" ;;
    zsh) timeout 20 zsh "$tmp/zcomp.zsh" "$PWD/completions" "$2" ;;
    fish) fish -c 'source completions/demoreel.fish
        complete -C $argv[1] | cut -f1' "$2" ;;
    esac
}
completion_bad=0
for shell in bash zsh fish; do
    command -v "$shell" >/dev/null || { echo "skipped $shell: not installed"; continue; }
    bad_before=$completion_bad
    while IFS='|' read -r line want; do
        # Quotes and the trailing space are how a step is offered, not what;
        # a lone - or -- is the separator, not an option.
        got=$(XDG_RUNTIME_DIR="$tmp/xdg" PATH="$PWD:$PATH" offered "$shell" "$line" \
              </dev/null | sed "s/^['\"]//; s/ *\$//; /^-\{0,2\}\$/d" | sort -u | xargs)
        want=$(printf '%s\n' $want | sort -u | xargs)
        [ "$got" = "$want" ] || {
            printf '%s offers for "%s":\n  %s\nbut demoreel accepts:\n  %s\n' \
                "$shell" "$line" "$got" "$want" >&2
            completion_bad=$((completion_bad + 1)); }
    done <<< "$expected"
    [ "$completion_bad" -eq "$bad_before" ] && echo "$shell: subcommands, options, steps and running recordings all match"
done
kill "$fake_run" 2>/dev/null
[ "$completion_bad" -eq 0 ] || exit 1

finishing_checks

# The translation checks (docs/specs/DEMO-0060-translation-catalogs.md § 4.8).
# No catalog ships yet, so they run against copies of demoreel beside catalogs
# built here: the pseudo-locale wraps every message in ⟦ ⟧, and the hostile
# ones are written by hand. The checks over shipped catalogs run on po/*.po,
# and each is also run on a pseudo catalog and on broken copies of it, so it
# is seen to fail, for the right reason, while po/ holds none.
shopt -s nullglob
committed=(po/*.po)
shopt -u nullglob
cat_base="$tmp/tr/cat/po/zz.po"  # built by the first catalog step

# catalog_check CHECK CATALOG...: one of $CATALOG_PY's checks.
catalog_check() { python3 -c "$CATALOG_PY" "$1" po/demoreel.pot "${@:2}"; }

# mutant SRC CASE OLD NEW: SRC with OLD replaced, exactly once, written as
# CASE/zz.po (the name a catalog for zz must have). Prints its path.
mutant() {
    mkdir -p "$tmp/tr/cat/$2"
    python3 - "$1" "$tmp/tr/cat/$2/zz.po" "$3" "$4" <<'MUTANTPY'
import sys
src, dst, old, new = sys.argv[1:]
text = open(src, encoding="utf-8").read()
if text.count(old) != 1:
    sys.exit(f"mutant: {old!r} is in {src} {text.count(old)} times, not once")
open(dst, "w", encoding="utf-8").write(text.replace(old, new))
MUTANTPY
    printf '%s\n' "$tmp/tr/cat/$2/zz.po"
}

# refused CHECK SRC CASE OLD NEW WHY: CHECK must fail on that mutant of SRC,
# and say WHY -- a failure for another reason would hide a check that is dead.
refused() {
    local file err
    file=$(mutant "$2" "$3" "$4" "$5")
    if err=$(catalog_check "$1" "$file" 2>&1); then
        echo "the $1 check passed a catalog with $3" >&2
        exit 1
    fi
    [[ $err == *"$6"* ]] || {
        echo "the $1 check failed a catalog with $3, but not for that reason:" >&2
        echo "$err" >&2
        exit 1; }
}

# shipped CHECK: run CHECK over the committed catalogs, and say what it saw.
shipped() {
    if [ ${#committed[@]} -eq 0 ]; then
        echo "no catalog is committed yet, so only the built ones were checked"
    else
        catalog_check "$1" "${committed[@]}"
        echo "${#committed[@]} committed catalogs checked: ${committed[*]}"
    fi
}

step "translation: the template matches the source"
# INV-6. A message added or reworded without `./ci.sh --pot` leaves the
# template behind, and every catalog starts from the template.
pot_text > "$tmp/demoreel.pot"
cmp -s "$tmp/demoreel.pot" po/demoreel.pot || {
    echo "po/demoreel.pot is not what the source extracts: run ./ci.sh --pot" >&2
    diff po/demoreel.pot "$tmp/demoreel.pot" | head -20 >&2 || true
    exit 1; }
echo "po/demoreel.pot holds every message the source has"

step "translation: nothing translated at import time"
# INV-15. The language is chosen in main(), so a message translated at import
# is always English -- and passes every check that runs in English. A default
# argument and a decorator run at import too, so they count as outside.
python3 - <<'IMPORTPY'
import ast, pathlib, sys
NAMES = ("tr", "trn", "tr_help", "tr_listed")
tree = ast.parse(pathlib.Path("demoreel").read_text(encoding="utf-8"))
calls, outside = [], []
def walk(node, inside):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)):
        args = node.args
        for part in [*args.defaults, *[d for d in args.kw_defaults if d],
                     *getattr(node, "decorator_list", [])]:
            walk(part, inside)
        body = node.body if isinstance(node.body, list) else [node.body]
        for part in body:
            walk(part, True)
        return
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) \
            and node.func.id in NAMES:
        calls.append(node.lineno)
        if not inside:
            outside.append(node.lineno)
    for child in ast.iter_child_nodes(node):
        walk(child, inside)
walk(tree, False)
for line in outside:
    print(f"demoreel line {line}: a message translated at import time", file=sys.stderr)
if len(calls) < 100:
    sys.exit(f"found only {len(calls)} translated messages, so this check saw "
             "less of the source than it should")
sys.exit(1 if outside else 0)
IMPORTPY
echo "every translated message is translated inside a function"

step "translation: argparse still has our strings"
# INV-13's first half. ARGPARSE_MESSAGES are argparse's own msgids. One this
# Python has reworded is never looked up, and nothing else would say so: the
# fix is to remove it from the list, not to reword it (DEMO-0060 § 6). This
# runs in the Ubuntu leg too, which is how both Pythons are held to it.
python3 - <<'ARGPY'
import argparse, importlib.machinery, importlib.util, inspect, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
source = inspect.getsource(argparse)
missing = [m for m in d.ARGPARSE_MESSAGES
           if f"_({m!r}" not in source and f"ngettext({m!r}" not in source]
for m in missing:
    print(f"this Python's argparse has no {m!r}", file=sys.stderr)
sys.exit(1 if missing else 0)
ARGPY
echo "argparse $(python3 -c 'import sys; print(sys.version.split()[0])') has every string demoreel translates"

step "translation: every catalog reads"
# A catalog a run refuses costs its whole language, with only a note on
# stderr to say so. The gate refuses it first: § 4.3's grammar, a charset,
# Language: matching the file name, and a name that is a language code.
pseudo_copy "$tmp/tr/cat" zz
catalog_check reads "$cat_base"
refused reads "$cat_base" "another Language" '"Language: zz\n"' '"Language: yy\n"' \
    "its Language is not zz"
refused reads "$cat_base" "an unknown escape" 'msgstr "⟦usage: ⟧"' 'msgstr "⟦usage: \q⟧"' \
    "unknown escape"
mkdir -p "$tmp/tr/cat/name"
cp "$cat_base" "$tmp/tr/cat/name/z-z.po"
if catalog_check reads "$tmp/tr/cat/name/z-z.po" 2>/dev/null; then
    echo "the reads check passed a catalog whose name is not a language code" >&2
    exit 1
fi
shipped reads

step "translation: every catalog is complete"
# INV-5. A message a catalog lacks prints in English in the middle of
# translated text; the user chose a failing gate over that (§ 3).
catalog_check complete "$cat_base"
refused complete "$cat_base" "a missing message" 'msgid "usage: "' 'msgid "usage was: "' \
    "no entry for 'usage: '"
refused complete "$cat_base" "a fuzzy message" 'msgid "options"' $'#, fuzzy\nmsgid "options"' \
    "'options' is fuzzy"
refused complete "$cat_base" "an empty translation" 'msgstr "⟦positional arguments⟧"' \
    'msgstr ""' "'positional arguments' is not translated in every form"
refused complete "$cat_base" "a plural form missing" \
    'msgstr[1] "⟦{count} recordings are running: {names}.\n  Name the one to stop, e.g. {example}⟧"' \
    '' "'{count} recording is running: {names}."
shipped complete

step "translation: the language is chosen as gettext chooses it"
# INV-3, each row of the spec's table, and INV-4, the fallback from one
# catalog to the next and then to English.
mkdir -p "$tmp/tr/chain/po"
cp demoreel "$tmp/tr/chain/demoreel"
python3 - "$tmp/tr/chain" <<'CHAINPY'
import importlib.machinery, importlib.util, pathlib, sys
here = pathlib.Path(sys.argv[1])
loader = importlib.machinery.SourceFileLoader("demoreel", str(here / "demoreel"))
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
bad = 0
for env, want in (
        ({"LANGUAGE": "de:fr", "LANG": "es_ES.UTF-8"}, ["de", "fr"]),
        ({"LC_ALL": "C", "LANGUAGE": "de"}, []),
        ({"LANG": "pt_BR.UTF-8"}, ["pt_BR", "pt"]),
        ({"LC_MESSAGES": "zh_TW.UTF-8", "LANG": "de_DE.UTF-8"}, ["zh_TW", "zh"]),
        ({"LC_ALL": "he_IL.UTF-8", "LC_MESSAGES": "de_DE.UTF-8"}, ["he_IL", "he"]),
        ({"LANGUAGE": "en:de", "LANG": "de_DE.UTF-8"}, []),
        ({"LANG": "sr_RS.UTF-8@latin"}, ["sr_RS@latin", "sr@latin", "sr_RS", "sr"]),
        ({}, [])):
    got = d.chosen_languages(env)
    if got != want:
        print(f"chosen_languages({env}) gave {got}, not {want}", file=sys.stderr)
        bad += 1
missing = "trim needs something to do: --from, --to, or a fade."
fuzzy = "join takes two or more videos; one on its own is already whole."
empty = "no recording is running, so there is nothing to stop."
kept = "the app closed; ending the recording."
neither = "give the steps with -a or with --steps, not both."
def catalog(code, entries):
    head = ('msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n'
            f'"Language: {code}\\n"\n"Plural-Forms: nplurals=2; plural=n != 1;\\n"\n')
    (here / "po" / f"{code}.po").write_text(head + "".join(entries), encoding="utf-8")
catalog("zz", [f'\n#, fuzzy\nmsgid "{fuzzy}"\nmsgstr "zz"\n',
               f'\nmsgid "{empty}"\nmsgstr ""\n', f'\nmsgid "{kept}"\nmsgstr "from zz"\n'])
catalog("yy", [f'\nmsgid "{m}"\nmsgstr "from yy"\n' for m in (missing, fuzzy, empty, kept)])
d.use_languages(["zz", "yy"])
for msgid, want in ((missing, "from yy"), (fuzzy, "from yy"), (empty, "from yy"),
                    (kept, "from zz"), (neither, neither)):
    if d.tr(msgid) != want:
        print(f"{msgid!r} came out as {d.tr(msgid)!r}, not {want!r}", file=sys.stderr)
        bad += 1
sys.exit(1 if bad else 0)
CHAINPY
echo "every row of the language table, and the fallback from catalog to catalog to English"

step "translation: placeholders and code tokens match"
# INV-12: in a right-to-left language each value and each code token is held
# in an isolate, so a path or a flag reads left to right inside the sentence.
# The marks go outside a token, never inside it. Checked in bytes; how a
# terminal draws them is DEMO-0063's. INV-7 follows.
pseudo_copy "$tmp/tr/rtl" he
pseudo_copy "$tmp/tr/rtl" zz
python3 - "$tmp/tr/rtl" <<'RTLPY'
import importlib.machinery, importlib.util, pathlib, sys
here = pathlib.Path(sys.argv[1])
loader = importlib.machinery.SourceFileLoader("demoreel", str(here / "demoreel"))
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
FSI, PDI = "⁨", "⁩"
own = ("-o is {output}, which is also a file this command reads. demoreel never "
       "writes over its own input.")
cases = [
    ((own,), {"output": "/tmp/x.mp4"},
     f"⟦{FSI}-o{PDI} is {FSI}/tmp/x.mp4{PDI}, which is also a file this command "
     "reads. demoreel never writes over its own input.⟧"),
    (("trim needs something to do: --from, --to, or a fade.",), {},
     f"⟦trim needs something to do: {FSI}--from{PDI}, {FSI}--to{PDI}, or a fade.⟧"),
    (("the private display {display} stopped answering: `xdotool {command}` did "
      "not return within {seconds}s.",), {"display": ":5", "command": "key", "seconds": "10"},
     f"⟦the private display {FSI}:5{PDI} stopped answering: {FSI}`xdotool key`{PDI} "
     f"did not return within {FSI}10{PDI}s.⟧"),
]
bad = 0
d.use_languages(["he"])
for args, values, want in cases:
    got = d.tr(*args, **values)
    if got != want:
        print(f"in he:\n  got  {got!r}\n  want {want!r}", file=sys.stderr)
        bad += 1
for codes in (["zz"], []):
    d.use_languages(codes)
    for args, values, _ in cases:
        got = d.tr(*args, **values)
        if FSI in got or PDI in got or (codes and "⟦" not in got):
            print(f"in {codes or 'English'}: {got!r}", file=sys.stderr)
            bad += 1
sys.exit(1 if bad else 0)
RTLPY
echo "right-to-left messages isolate each value and each code token, and no other language does"
# Chinese and Japanese write a flag straight against their own letters and
# punctuation. It is still a code token there, and its =value ends at the
# first character that is not ASCII.
python3 - <<'CJKPY'
import importlib.machinery, importlib.util, sys
loader = importlib.machinery.SourceFileLoader("demoreel", "./demoreel")
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
bad = 0
for text, want in (("使用--name参数", ["--name"]), ("使用-o指定", ["-o"]),
                   ("--nosocket=wayland；参见", ["--nosocket=wayland"]),
                   ("ב־--name", ["--name"]), ("e-mail --gpu, -d 3", ["--gpu", "-d"])):
    got = d.CODE_TOKEN_RE.findall(text)
    if got != want:
        print(f"code tokens in {text!r}: {got}, not {want}", file=sys.stderr)
        bad += 1
sys.exit(1 if bad else 0)
CJKPY
echo "a flag written against Chinese, Japanese or Hebrew letters is still a code token"
# INV-7, over the catalogs. A run already falls back to English for a bad
# placeholder; the gate makes it a failure, so the language never loses the
# message. A renamed placeholder, a translated flag and a bare % in text
# argparse formats are each refused; a plural form leaving out {count} is not.
catalog_check placeholders "$cat_base"
refused placeholders "$cat_base" "a renamed placeholder" \
    '"⟦the video cannot be played: {output}⟧"' '"⟦the video cannot be played: {ouput}⟧"' \
    "its placeholders, or its %, are not the English ones"
refused placeholders "$cat_base" "a translated flag" \
    '"⟦`demoreel check` says whether --gpu has what it needs.⟧"' \
    '"⟦`demoreel check` says whether --grafik has what it needs.⟧"' \
    "its code tokens are not the English ones"
refused placeholders "$cat_base" "a bare % in help" '"⟦show this help message and exit⟧"' \
    '"⟦50 % show this help message and exit⟧"' "its placeholders, or its %, are not"
catalog_check placeholders "$(mutant "$cat_base" "a plural without count" \
    'msgstr[0] "⟦{count} recording' 'msgstr[0] "⟦one recording')"
shipped placeholders

step "translation: stdout and exit status do not move"
# INV-2: whatever the language, a caller reads the same stdout and the same
# exit status -- the paths, motion's report, --version. INV-14: under the
# pseudo-locale every message demoreel writes, and every option's help, is
# translated whole, so a message left out of tr() shows up here. One
# successful and one failing run of each command, under LC_ALL=C and then
# under the pseudo-locale, from the same copy.
tr_out="$tmp/tr/out"
pseudo_copy "$tr_out" zz
ffmpeg -nostdin -loglevel error -f lavfi -i testsrc=s=320x200:r=30:d=2 \
    -pix_fmt yuv420p "$tr_out/clip.mp4"
printf 'card 1\ntext "Hello"\nclip clip.mp4 to 1\n' > "$tr_out/film.txt"
python3 - "$tr_out" <<'MOVEPY'
import json, os, pathlib, re, subprocess, sys
here = pathlib.Path(sys.argv[1])
script = str(here / "demoreel")
plain = {k: v for k, v in os.environ.items() if k not in ("LC_ALL", "LC_MESSAGES")}
english = {**plain, "LC_ALL": "C"}
pseudo = {**plain, "LANGUAGE": "zz", "LANG": "de_DE.UTF-8"}
state = (pathlib.Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp")
         / f"demoreel-{os.getuid()}" / "gatetr.json")
bad, checked = [], 0

def run(argv, env):
    return subprocess.run([script, *argv], cwd=here, env=env, capture_output=True,
                          text=True, timeout=180)

def whole(stderr, argv):
    """Each message demoreel wrote must be one translation, ⟦ to ⟧."""
    global checked
    messages = []
    for line in stderr.splitlines():
        # argparse's error line is translated whole, prog and all (DEMO-0166),
        # and its closing ⟧ lands on a line of its own after the newline.
        prefix = re.match(r"demoreel(?: [a-z]+)?: ", line)
        if re.match(r"⟦demoreel(?: [a-z]+)?: error: ", line):
            checked += 1
        elif prefix:
            messages.append(line[prefix.end():])
        elif line.startswith("  ") and messages:
            messages[-1] += "\n" + line
    for message in messages:
        checked += 1
        if not (message.startswith("⟦") and message.endswith("⟧")):
            bad.append(f"{argv}: a message not translated whole: {message!r}")

RUNS = [
    ["record", "-n", "gatetr", "-d", "1", "-s", "320x240", "-o", "rec.mp4", "--", "xclock"],
    ["shot", "-s", "320x240", "-o", "shot.png", "--", "xclock"],
    ["trim", "clip.mp4", "-o", "trim.mp4", "--to", "1"],
    ["caption", "clip.mp4", "-o", "cap.mp4", "--text", "Hi", "--to", "1"],
    ["join", "clip.mp4", "clip.mp4", "-o", "join.mp4"],
    ["card", "-d", "1", "--text", "Hi", "-o", "card.mp4", "--like", "clip.mp4"],
    ["edit", "film.txt", "-o", "film.mp4"],
    ["poster", "clip.mp4", "-o", "poster.png", "-t", "1"],
    ["motion", "clip.mp4"],
    ["motion", "clip.mp4", "--json"],
    ["--version"],
    ["record", "-n", "gatetr", "-s", "301x200", "--", "xclock"],
    ["shot", "-s", "320x240"],
    ["stop", "gatetr-nobody"],
    ["trim", "clip.mp4", "-o", "trim2.mp4"],
    ["caption", "clip.mp4", "-o", "clip.mp4", "--text", "Hi"],
    ["join", "clip.mp4", "-o", "join2.mp4"],
    ["card", "-d", "0", "-o", "card2.mp4"],
    ["edit", "nofile.txt", "-o", "film2.mp4"],
    ["poster", "clip.mp4", "-o", "poster2.png", "-t", "9"],
    ["motion", "clip.mp4", "--from", "9"],
    ["trim", "clip.mp4"],
]
for argv in RUNS:
    seen = []
    for env in (english, pseudo):
        r = run(argv, env)
        fields = None
        if argv[0] == "record" and r.returncode == 0:
            entry = json.loads(state.read_text())
            fields = (entry.get("output"), entry.get("result"))
        seen.append((r.returncode, r.stdout, fields))
        if env is pseudo:
            whole(r.stderr, argv)
    if seen[0] != seen[1]:
        bad.append(f"{argv}: C gave {seen[0]!r:.300}, the pseudo-locale {seen[1]!r:.300}")
# stop prints a path too: a -d 0 run, stopped by name, in each language.
for env in (english, pseudo):
    rec = subprocess.Popen([script, "record", "-n", "gatetr", "-d", "0", "-s", "320x240",
                            "-o", "stopped.mp4", "--", "xclock"], cwd=here, env=env,
                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    r = run(["stop", "gatetr"], env)
    rec.communicate(timeout=60)
    if (r.returncode, r.stdout) != (0, f"{here / 'stopped.mp4'}\n"):
        bad.append(f"stop under {env.get('LANGUAGE', 'C')}: {r.returncode} {r.stdout!r}")
    if env is pseudo:
        whole(r.stderr, ["stop"])

def help_entries(text):
    """The help text of each entry under the options and positional headings."""
    entries, current, reading = [], None, False
    for line in text.splitlines():
        if line and not line.startswith(" "):
            reading = line.endswith("⟧:")  # a translated section heading
            current = None
            continue
        entry = re.match(r"^( {2}| {4})(\S.*?)(?: {2,}(.*))?$", line)
        if not reading:
            continue
        if entry:
            current = [entry[3]] if entry[3] else []
            entries.append(current)
        elif current is not None and line.strip():
            current.append(line.strip())
    return [" ".join(parts) for parts in entries if parts]

pages = [[], ["record"], ["shot"], ["check"], ["stop"], ["edit"], ["trim"], ["caption"],
         ["join"], ["card"], ["motion"], ["poster"]]
for page in pages:
    r = run([*page, "--help"], pseudo)
    found = help_entries(r.stdout)
    if r.returncode or not found or "⟦usage: ⟧" not in r.stdout:
        bad.append(f"{page} --help under the pseudo-locale: status {r.returncode}, "
                   f"{len(found)} entries, usage translated: {'⟦usage: ⟧' in r.stdout}")
    for text in found:
        checked += 1
        if not (text.startswith("⟦") and text.endswith("⟧")):
            bad.append(f"{page} --help: an entry not translated whole: {text!r}")
# INV-13's second half: argparse's own error and usage, through the hook.
r_c, r_z = run(["--bogus"], english), run(["--bogus"], pseudo)
if r_c.returncode != r_z.returncode or "⟦usage: ⟧" not in r_z.stderr \
        or not re.search(r"⟦(the following arguments|unrecognized arguments)", r_z.stderr):
    bad.append(f"--bogus: C {r_c.returncode}, pseudo {r_z.returncode}: {r_z.stderr!r:.300}")
for line in bad:
    print(line, file=sys.stderr)
print(f"{len(RUNS) + 2} commands compared under both locales; "
      f"{checked} messages and help entries checked whole")
sys.exit(1 if bad or checked < 100 else 0)
MOVEPY
# INV-2 again, in each committed language as a user would choose it: a
# recording still prints the bare path, and a failing command the same
# status. The failing command's message must differ from the English one,
# which is what shows the catalog was used at all. Run on the pseudo copy
# first, so the check is seen to work while po/ holds no catalog.
# same_stdout SCRIPT CODE...
same_stdout() {
    python3 - "$tr_out" "$@" <<'LANGPY'
import os, subprocess, sys
here, script, *codes = sys.argv[1:]
plain = {k: v for k, v in os.environ.items() if k not in ("LC_ALL", "LC_MESSAGES")}
RECORD = ["record", "-n", "gatelang", "-d", "1", "-s", "320x240", "-o", "lang.mp4",
          "--", "xclock"]
FAIL = ["trim", "clip.mp4", "-o", "lang-trim.mp4"]
def run(argv, env):
    return subprocess.run([script, *argv], cwd=here, env=env, capture_output=True,
                          text=True, timeout=120)
english = {**plain, "LC_ALL": "C"}
c_rec, c_fail = run(RECORD, english), run(FAIL, english)
bad = []
if c_rec.returncode or not c_rec.stdout.endswith("lang.mp4\n") or not c_fail.returncode:
    bad.append(f"under C: record {c_rec.returncode} {c_rec.stdout!r}, trim {c_fail.returncode}")
for code in codes:
    env = {**plain, "LANGUAGE": code, "LANG": "de_DE.UTF-8"}
    rec, fail = run(RECORD, env), run(FAIL, env)
    for what, a, b in (("record", c_rec, rec), ("a failing trim", c_fail, fail)):
        if (a.returncode, a.stdout) != (b.returncode, b.stdout):
            bad.append(f"{code}: {what} gave {b.returncode} {b.stdout!r:.200}, "
                       f"not {a.returncode} {a.stdout!r:.200}")
    if fail.stderr == c_fail.stderr or "could not be read" in rec.stderr + fail.stderr:
        bad.append(f"{code}: its catalog was not used: {fail.stderr!r:.300}")
for line in bad:
    print(line, file=sys.stderr)
sys.exit(1 if bad else 0)
LANGPY
}
same_stdout "$tr_out/demoreel" zz
if [ ${#committed[@]} -eq 0 ]; then
    echo "no catalog is committed yet, so only the pseudo-locale was recorded in"
else
    codes=()
    for catalog in "${committed[@]}"; do
        codes+=("$(basename "$catalog" .po)")
    done
    same_stdout "$PWD/demoreel" "${codes[@]}"
    echo "a recording and a failing command compared in: ${codes[*]}"
fi

step "translation: confirmed means unchanged"
# INV-16's runtime half: --help says a draft is a draft, and says nothing for a
# confirmed catalog or in English. The digest follows.
pseudo_copy "$tmp/tr/draft" zz
pseudo_copy "$tmp/tr/confirmed" zz "confirmed 0123456789abcdef"
draft_line="This translation is a draft and has not yet been checked by a native speaker."
help_draft=$("${PSEUDO_ENV[@]}" "$tmp/tr/draft/demoreel" --help)
help_confirmed=$("${PSEUDO_ENV[@]}" "$tmp/tr/confirmed/demoreel" --help)
help_english=$("$tmp/tr/draft/demoreel" --help)
[[ $help_draft == *$'\n'"⟦$draft_line⟧" ]] || {
    echo "--help from a draft catalog does not end with the draft line" >&2; exit 1; }
[[ $help_confirmed == *"⟦"* && $help_confirmed != *"$draft_line"* ]] || {
    echo "--help from a confirmed catalog says it is a draft, or was not translated" >&2
    exit 1; }
[[ $help_english != *"$draft_line"* ]] || {
    echo "--help in English says a translation is a draft" >&2; exit 1; }
echo "a draft says so at the end of --help; a confirmed catalog and English do not"
# INV-16's digest: a catalog marked confirmed holds the translations that
# were confirmed. One edited afterwards fails until it says draft again or is
# confirmed anew. --catalog-digest is what a confirmation records.
cat_digest=$(./ci.sh --catalog-digest "$cat_base")
[[ $cat_digest =~ ^[0-9a-f]{16}$ ]] || {
    echo "--catalog-digest printed $cat_digest, not 16 hex digits" >&2; exit 1; }
cat_confirmed=$(mutant "$cat_base" confirmed '"X-Demoreel-Review: draft\n"' \
    "\"X-Demoreel-Review: confirmed $cat_digest\\n\"")
catalog_check digest "$cat_base" "$cat_confirmed"
refused digest "$cat_confirmed" "a translation edited after confirming" \
    'msgstr "⟦options⟧"' 'msgstr "⟦choices⟧"' "it was edited after it was confirmed"
shipped digest

step "translation: a bad catalog costs only the language"
# INV-1, INV-8, INV-9, INV-10 and INV-11. A catalog is text from someone a
# reviewer cannot check, so a broken or hostile one may cost its language and
# never the run. Each refusal is believed only beside a control: the same run
# with a good catalog shows translated text, so "English" means refused, not
# never loaded.
pseudo_copy "$tmp/tr/bad" zz
cp "$tmp/tr/bad/po/zz.po" "$tmp/tr/good.po"
python3 - "$tmp/tr" <<'BADPY'
import os, pathlib, subprocess, sys
top = pathlib.Path(sys.argv[1])
here = top / "bad"
good = (top / "good.po").read_text(encoding="utf-8")
plain = {k: v for k, v in os.environ.items() if k not in ("LC_ALL", "LC_MESSAGES")}
english = {**plain, "LC_ALL": "C"}
pseudo = {**plain, "LANGUAGE": "zz", "LANG": "de_DE.UTF-8"}
NOTHING = ["trim", "x.mp4", "-o", "y.mp4"]
NOTHING_MSG = "trim needs something to do: --from, --to, or a fade."
OWN = ["trim", "clip.mp4", "-o", "clip.mp4", "--to", "1"]
OWN_MSG = ("-o is {output}, which is also a file this command reads. demoreel never "
           "writes over its own input.")
bad = []

def run(catalog, argv, env=pseudo, script=here / "demoreel", cwd=here):
    if isinstance(catalog, str):
        catalog = catalog.encode("utf-8")
    (here / "po" / "zz.po").write_bytes(catalog)
    return subprocess.run([str(script), *argv], cwd=cwd, env=env, capture_output=True,
                          timeout=60)

def swap(msgid, msgstr):
    old = 'msgstr "⟦' + msgid + '⟧"'
    assert good.count(old) == 1, msgid
    return good.replace(old, "msgstr " + msgstr)

def expect(what, r, rc, english_text, note=None):
    err = r.stderr.decode("utf-8", "replace")
    problems = []
    if r.returncode != rc:
        problems.append(f"status {r.returncode}, not {rc}")
    if english_text not in err or "⟦" in err:
        problems.append("the message is not the English one")
    notes = err.count("could not be read")
    if note is None and notes:
        problems.append("a catalog was opened")
    if note is not None and (notes != 1 or "po/zz.po" not in err
                             or (note and "line " not in err)):
        problems.append("not exactly one note naming the file and line")
    if "class" in err:
        problems.append("a template reached an attribute")
    if problems:
        bad.append(f"{what}: {'; '.join(problems)}\n    {err!r:.400}")

rc_nothing = run(good, NOTHING, english).returncode
rc_own = run(good, OWN, english).returncode
for argv, msg in ((NOTHING, NOTHING_MSG), (OWN, "-o is ")):
    r = run(good, argv)
    if "⟦" + msg[:20] not in r.stderr.decode("utf-8", "replace"):
        bad.append(f"control: a good catalog did not translate {argv}")

# INV-1: C, and English first in LANGUAGE, open nothing under po/.
broken = "msgid\n"
if "could not be read" not in run(broken, NOTHING).stderr.decode():
    bad.append("control: the unreadable catalog was not reported under the pseudo-locale")
expect("LC_ALL=C LANGUAGE=zz", run(broken, NOTHING, {**english, "LANGUAGE": "zz"}),
       rc_nothing, NOTHING_MSG)
expect("LANGUAGE=en:zz", run(broken, NOTHING, {**plain, "LANG": "en_GB.UTF-8",
                                                "LANGUAGE": "en:zz"}),
       rc_nothing, NOTHING_MSG)
# INV-11: a terminal that cannot show the translation gets English.
expect("PYTHONIOENCODING=latin-1", run(broken, NOTHING, {**pseudo,
                                                          "PYTHONIOENCODING": "latin-1"}),
       rc_nothing, NOTHING_MSG)
# INV-10: refused whole, with one note.
hostile = {
    "an ESC": swap(NOTHING_MSG, '"\x1b[31mred"'),
    "another C0 control": swap(NOTHING_MSG, '"\x01"'),
    "a C1 control": swap(NOTHING_MSG, '"\u009b31m"'),
    "a bidi override": swap(NOTHING_MSG, '"‮evil"'),
    "an unknown escape": swap(NOTHING_MSG, '"\\x41"'),
    "msgctxt": good.replace(f'msgid "{NOTHING_MSG}"', f'msgctxt "x"\nmsgid "{NOTHING_MSG}"'),
    "a Latin-1 charset": good.replace("charset=UTF-8", "charset=ISO-8859-1"),
    "a plural expression that raises": good.replace("plural=n != 1;", "plural=n%0;"),
    "a plural expression out of range": good.replace("plural=n != 1;", "plural=n+5;"),
}
for what, text in hostile.items():
    assert text != good, what
    expect(what, run(text, NOTHING), rc_nothing, NOTHING_MSG, note=True)
expect("more than 1 MiB", run(good + "#" * (1024 * 1024) + "\n", NOTHING), rc_nothing,
       NOTHING_MSG, note=False)
# INV-8: a template reaching past plain substitution is not used -- refused
# by the check on each translation, and, behind it, filled by a substitution
# that cannot reach an attribute, an index or a conversion. Each defence is
# held on its own: through a catalog, the check hides the fill.
import importlib.machinery, importlib.util
loader = importlib.machinery.SourceFileLoader("demoreel", str(here / "demoreel"))
d = importlib.util.module_from_spec(importlib.util.spec_from_loader("demoreel", loader))
loader.exec_module(d)
for template in ("{output.__class__}", "{output[0]}", "{output!r}", "{output:>9}"):
    for marks in (False, True):
        if d._fill(template, {"output": "/x"}, marks) != template:
            bad.append(f"the fill reached past plain substitution in {template!r}")
for template in ("{output.__class__}", "{output[0]}", "{output!r}", "{unknown}",
                 "⟦{output}⟧ {output.__class__}"):
    expect(f"the template {template}", run(swap(OWN_MSG, f'"{template}"'), OWN), rc_own,
           "which is also a file this command reads")
r_c = run(good, ["--bogus"], english)
r = run(swap("usage: ", '"%(x)s usage: "'), ["--bogus"])
if r.returncode != r_c.returncode or b"usage: demoreel" not in r.stderr or b"%(x)" in r.stderr:
    bad.append(f"argparse %(x)s: {r.returncode} {r.stderr!r:.300}")
r = run(swap("end a running recording early", '"50 % ⟦end a running recording early⟧"'),
        ["--help"])
out = r.stdout.decode("utf-8", "replace")
if r.returncode != 0 or "  end a running recording early" not in out.replace(
        "  stop", "") and "end a running recording early" not in out \
        or "50 %" in out or "⟦record an app" not in out:
    bad.append(f"a bare % in help: {r.returncode} {out!r:.400}")
# INV-9: a catalog in the working directory, or named by TEXTDOMAINDIR, is
# never read -- only po/ beside the script.
cwd = top / "cwd"
(cwd / "po").mkdir(parents=True, exist_ok=True)
(cwd / "po" / "zz.po").write_text(good, encoding="utf-8")
r = run(good, NOTHING, {**pseudo, "TEXTDOMAINDIR": str(cwd / "po")},
        script=pathlib.Path("demoreel").resolve(), cwd=cwd)
expect("a catalog in the working directory", r, rc_nothing, NOTHING_MSG)
for line in bad:
    print(line, file=sys.stderr)
sys.exit(1 if bad else 0)
BADPY
echo "a broken or hostile catalog costs its language, never the run"

step "default output name"
# -o is optional; without it the file is named from the app and a timestamp.
( cd "$tmp" && "$OLDPWD/demoreel" record -n gatedefault -d 3 -s 640x480 -- xclock >/dev/null )
ls "$tmp"/xclock-*.mp4 >/dev/null

step "the same gate on GitHub's Ubuntu"
# Last, because it is the slow one and everything above is cheaper to fail on.
# It runs the files as they are here -- tracked and new, not ignored -- which is
# what the checks above just ran. Four cores, as on GitHub's runner: x264 sizes
# its threads from the cores it may use, and that is what differed last time.
if [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${DEMOREEL_PARITY_INSIDE:-}" ]; then
    echo "not applicable: this run already is on that Ubuntu"
elif ! command -v podman >/dev/null; then
    printf '\n=== checks passed; the Ubuntu leg was SKIPPED: podman is not installed ===\n'
    exit 0
elif ! podman image exists "$PARITY_IMAGE"; then
    printf '\n=== checks passed; the Ubuntu leg was SKIPPED: its image is not built ===\n'
    echo "build it once (a few minutes): ./ci.sh --parity-build"
    exit 0
else
    # GitHub's runner takes Ubuntu's package updates every week; the image keeps
    # the ones it was built with. So say when it has had time to fall behind.
    # A warning, not a rebuild: a rebuild takes minutes and does not belong
    # inside a push.
    built=$(podman image inspect --format '{{.Created.Unix}}' "$PARITY_IMAGE")
    age_days=$(( ($(date +%s) - built) / 86400 ))
    if [ "$age_days" -ge 14 ]; then
        echo "note: the image is $age_days days old, and GitHub's packages may have moved on."
        echo "      rebuild it: ./ci.sh --parity-build"
    fi
    git ls-files -coz --exclude-standard | tar --null -T - -cf - \
        | timeout 900 podman run --rm -i -e DEMOREEL_PARITY_INSIDE=1 "$PARITY_IMAGE" \
            bash -c 'mkdir w && tar -xf - -C w && cd w && taskset -c 0-3 ./ci.sh' \
        > "$tmp/parity.log" 2>&1 || {
        echo "the gate failed on $PARITY_BASE; its output:" >&2
        cat "$tmp/parity.log" >&2
        exit 1; }
    grep -q '^=== all checks passed ===$' "$tmp/parity.log" || {
        echo "the Ubuntu run exited 0 without finishing; its output:" >&2
        cat "$tmp/parity.log" >&2
        exit 1; }
    echo "every check above also passed on $PARITY_BASE"
fi

printf '\n=== all checks passed ===\n'
