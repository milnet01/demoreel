# DEMO-0060 — Translate demoreel's messages from `.po` catalogs it reads itself

**Status:** spec draft (2026-10-01).
**Kind:** implement.
**Source:** ROADMAP DEMO-0060 (user-request-2026-09-25).
**Blocker for:** DEMO-0061, DEMO-0062, DEMO-0063, DEMO-0064, DEMO-0065, DEMO-0067.
**Pairs with:** DEMO-0083 (its defences are § 4.7 and INV-8 to INV-10), DEMO-0086 (the window reads these catalogs).

A person whose system is set to German, Hebrew or Japanese sees demoreel's
messages and `--help` in that language; scripts, Claude sessions and anyone
on an English or unset locale see exactly what they see today.

## 1. Goal

demoreel shows its stderr messages, its progress line and its `--help` in the
user's language, taken from `.po` files that sit beside the script and that
demoreel parses itself. Everything a program reads — stdout, the state file,
the exit status, `--version`, `motion`'s report — stays byte-identical in every
locale. A catalog is treated as untrusted data: a bad one can make a message
fall back to English, never crash a run, leak internals or write terminal
control codes.

## 2. Problem

Every user-facing string is an English literal today, handed to `demoreel::die()`,
`demoreel::note()` or `demoreel::progress()`, or passed as `help=` in
`demoreel::build_parser()`. There is no translation layer and no catalog.

Four things make adding one more than wrapping strings:

1. **The machine-readable surfaces must not move.**
   `docs/standards/versioning-overrides.md` § Breaking surfaces protects stdout
   (one path), `--version`'s shape, `motion`'s `name: value` report, the `-a`
   grammar and the `edit` script words. § What is not a breaking surface leaves
   stderr and `--help` prose unprotected, which is what makes translating them
   legal. A translation layer that reached any protected surface would break a
   caller that sets a locale.
2. **The code parses some of its own messages.**
   `demoreel::display_problem()` strips a `demoreel: ` prefix off a
   `SystemExit` text, and `demoreel::finishing_problems()` splits one on
   ``"\n  `demoreel check`"``. A translated message breaks the split.
   `ci.sh` also matches English message text in many steps, and nothing in it
   sets a locale (`grep -n 'LC_ALL\|LANGUAGE' ci.sh` → no output).
3. **argparse prints strings demoreel does not own.** `usage:`, `options:` and
   its error texts come from Python's `argparse`, which calls module-level
   `_` and `ngettext` imported from `gettext`
   (`python3 -c "import argparse,inspect;print([l for l in inspect.getsource(argparse).splitlines() if 'gettext' in l and 'import' in l])"`
   → `['from gettext import gettext as _, ngettext']`, Python 3.13.15).
4. **A catalog is text written by someone the reviewer cannot check.** A
   maintainer cannot read Arabic, so a malicious or careless entry passes a
   human review. Python's `str.format` reaches attributes and indexes
   (`{output.__class__}`), and a message can carry an escape sequence that a
   terminal obeys. DEMO-0083 records this.

## 3. Scope decisions (agreed with the user)

- **Catalogs are `.po` files that demoreel reads directly** — not compiled
  `.mo`, which adds a build step the project does not have, and not JSON, which
  no translation tool opens. Translators use Poedit or Weblate. The user,
  2026-10-01, recorded in DEMO-0060.
- **A changed English message fails the gate until every catalog carries it.**
  No fallback-to-English for a message the source has and a catalog lacks; a
  change to English lands with its drafts in the same commit. The user,
  2026-10-01, when asked for this spec (DEMO-0062 already said so).
- **Draft state is per language, not per message.** A confirmed language that
  receives a newly drafted message becomes a draft again until a native speaker
  checks the change. The user, 2026-10-01.
- **The man page is not in these catalogs.** How it is translated is decided in
  DEMO-0064. The user, 2026-10-01.
- **The window planned for 0.6.0 uses the same catalogs** (DEMO-0060's body,
  the user, 2026-09-25). Lifting "no GUI" from the scope ceiling is DEMO-0085's,
  not this spec's.

Every other choice below was made by the author of this spec and follows from
§ 2; each is open to the review.

## 4. Design

### 4.1 What is translated, and what never is

| Surface | Translated |
|---|---|
| Text passed to `die()`, `note()`, `progress()` | yes |
| `help=` strings, parser `description=`, the comment lines of `EXAMPLES` and `RECORD_EXAMPLES` | yes |
| argparse's own strings listed in `ARGPARSE_MESSAGES` (§ 4.6) | yes |
| The `demoreel: ` prefix on every stderr line | **no** |
| stdout: every path, `stop`'s path, `motion`'s report in both forms, `--version` | **no** |
| The state file, the exit status | **no** |
| Command lines inside `--help` examples, metavars (`SECONDS`), subcommand and flag names | **no** |
| Words a user types: the `-a` / `--steps` grammar, `edit` script words | **no** |
| Text from another program quoted inside a message (ffmpeg's last lines in `SampleError`) | **no** |
| Shell completions, the man page, README | **no** — § 9 |

A message is one whole sentence or more. Code does not build a message by
joining translated fragments, because word order differs between languages.
Where today's code concatenates pieces (`demoreel::cmd_check()` joins
`install_hint()` onto a sentence), each piece becomes a whole sentence of its
own or the whole becomes one message with placeholders.

### 4.2 Files

```
demoreel                 the script
po/demoreel.pot          the template: every msgid, no translations (generated, committed)
po/<code>.po             one catalog per language: de.po, he.po, pt_BR.po, zh_CN.po, zh_TW.po ...
```

`<code>` is `ll` or `ll_CC` — an ISO 639-1 language code, and a country code
only where the language needs one to be told apart. The catalog's `Language:`
header equals its filename without `.po`.

**Catalogs are found in one place: `Path(__file__).resolve().parent / "po"`.**
`resolve()` follows the symlink `~/.local/bin/demoreel` back to the checkout.
Nothing else is searched: not the working directory, not `/usr/share/locale`,
not a directory named by any environment variable. A package (0.5.0) installs
`po/` beside the script it symlinks to, which keeps this one rule. A script
with no `__file__` (piped to `python3 -`) has no catalogs and runs in English.

`po/demoreel.pot` is generated by `./ci.sh --pot`, from the same extraction
the gate uses (§ 4.8), and committed so translators and Weblate can start a
new language from it.

### 4.3 Catalog format — the subset demoreel reads

```
file      := entry*                       UTF-8, at most 1 MiB, no BOM
entry     := comment* [flags] msgid [msgid_plural] msgstr+
comment   := "#" rest-of-line             ignored, except "#," flags
flags     := "#," flag ("," flag)*        only "fuzzy" has meaning; others ignored
obsolete  := "#~" rest-of-line            ignored
msgid     := "msgid" string+
msgid_plural := "msgid_plural" string+
msgstr    := "msgstr" string+   |   "msgstr[" digit+ "]" string+
string    := '"' chars '"'                adjacent strings on following lines concatenate
escapes   := \n  \t  \"  \\               any other backslash sequence is an error
```

The entry with an empty `msgid` is the header. demoreel reads four of its
fields:

| Header field | Meaning |
|---|---|
| `Content-Type: text/plain; charset=UTF-8` | required; any other charset refuses the catalog |
| `Language:` | must equal the filename's `<code>` |
| `Plural-Forms:` | required; `nplurals=N; plural=<expr>;` |
| `X-Demoreel-Review:` | `draft`, or `confirmed <digest>` (§ 4.9); anything else reads as `draft` |

`msgctxt` is not supported, and a catalog using it is refused whole — a
feature demoreel does not implement must not be half-read.

**Content refused anywhere in a `msgstr`**: any C0 control character other
than `\n` and `\t`, DEL, any C1 control character (U+0080–U+009F, which
includes the 8-bit CSI), and the bidi embedding, override and isolate
characters U+202A–U+202E and U+2066–U+2069. demoreel inserts its own isolates
(§ 4.5); a catalog may not.

**A refused catalog is refused whole.** demoreel runs as if it did not exist
and writes one English note, once per run:

```
demoreel: po/de.po could not be read (line 212: unknown escape \x), so messages are in English.
```

### 4.4 Choosing the language

Read from the environment only. demoreel never calls `locale.setlocale`, so
nothing else in the process changes behaviour.

```python
def chosen_languages(env):
    """The catalog codes to try, best first; [] means English."""
    locale = next((env[k] for k in ("LC_ALL", "LC_MESSAGES", "LANG")
                   if env.get(k)), "")
    if base(locale) in ("", "C", "POSIX"):   # base() drops .codeset and @modifier
        return []                             # C wins over LANGUAGE, as in GNU gettext
    wanted = [w for w in env.get("LANGUAGE", "").split(":") if w] or [locale]
    codes = []
    for w in wanted:
        if w.split("_")[0].split(".")[0].split("@")[0] == "en":
            break                             # English asked for: stop here
        codes += expansions(w)                # ll_CC.cs@mod -> ll_CC@mod, ll_CC, ll@mod, ll
    return list(dict.fromkeys(codes))
```

Then, only if the list is not empty **and stderr's encoding is UTF-8**, each
code that has a `po/<code>.po` is loaded in order. A message is looked up in
the first loaded catalog; one that catalog lacks, or has only as `fuzzy` or
with an empty `msgstr`, is looked up in the next; English is the last
fallback. With an empty list, or a non-UTF-8 stderr, no file under `po/` is
opened at all.

Loading builds a `.mo` image in memory from the parsed entries (fuzzy entries
left out) and hands it to `gettext.GNUTranslations(io.BytesIO(image))`,
chaining the catalogs with `add_fallback()`. That reuses the standard
library's plural evaluation and fallback rules through public API rather than
reimplementing them.

### 4.5 The code-side API

```python
def tr(msgid: str, **values: str) -> str: ...
def trn(singular: str, plural: str, count: int, **values: str) -> str: ...
```

`tr` looks the message up (§ 4.4) and fills it. `trn` picks the plural form
for `count` and fills it; `count` is also available as `{count}`.

**Filling is plain named substitution.** A placeholder is `{name}` with `name`
matching `[a-z_][a-z0-9_]*`. Each is replaced by `str(values[name])`. Nothing
else is interpreted: no attribute access, no indexing, no format spec, no
conversion. A `{` that does not start a placeholder is literal text. The call
site does its own formatting — `name=repr(a.name)`, `seconds=f"{x:.3f}"`.

**At runtime a translation is used only if its placeholders are a subset of
the English message's**, and — except in a plural form, which may leave out
`{count}` — contain every one of them. Otherwise the English message is used.
The gate enforces the same rule (§ 4.8), so this is the second line of
defence.

**Right-to-left languages.** When the catalog that supplied a message has a
language code in `RTL_LANGUAGES = ("ar", "fa", "he", "ps", "ur", "yi")`,
filling wraps each substituted value, and each code token in the text, in
FIRST STRONG ISOLATE (U+2068) … POP DIRECTIONAL ISOLATE (U+2069). A code token
is a backticked span, a long flag (`--gpu`) or a short flag (`-d`) standing as
its own word. The marks go outside the token, never inside it. English and
left-to-right catalogs get no marks.

The name is `tr`, not the gettext convention `_`: `demoreel` already uses `_`
as a throwaway name, in `demoreel::display_problem()`, `demoreel::text_font()`
and `demoreel::memory_cap()` among others.

**`tr` and `trn` are never called at import time.** The language is chosen in
`main()`, and a module-level call would run before that. `EXAMPLES` and
`RECORD_EXAMPLES` become lists of `(comment, command)` pairs, and the text is
assembled inside `build_parser()`. Before `main()` chooses, `tr` returns
English, so `ci.sh`'s import of `demoreel` is unaffected.

**No code compares, splits or strips a translated string.** A caller that needs
a reason in a structured form gets it from an exception or a return value. The
`removeprefix("demoreel: ")` in `demoreel::display_problem()` is safe, since
the prefix is never translated; the split in `demoreel::finishing_problems()`
is replaced.

### 4.6 argparse

In `main()`, after the language is chosen and before `build_parser()`,
`argparse._` and `argparse.ngettext` are replaced with functions that
translate a msgid listed in `ARGPARSE_MESSAGES` and return every other one
unchanged. Replacing module attributes works because argparse looks both names
up at call time (§ 2 consequence 3).

`ARGPARSE_MESSAGES` is a tuple in `demoreel` of the argparse msgids a demoreel
user can reach — `usage: `, `options`, `positional arguments`,
`show this help message and exit`, the missing, unrecognised and invalid-choice
errors — chosen from those present in Python 3.12 (the gate's Ubuntu 24.04 leg)
and 3.13 (this machine). They are extracted into the template like demoreel's
own. An argparse string not listed prints in English. argparse fills its own
strings with `%` against a dict, which does no attribute lookup; their
placeholders (`%(prog)s`, `%s`) are checked like `{name}` ones.

### 4.7 Trust boundary: catalogs (DEMO-0083)

A catalog is untrusted input. The defences, each an invariant in § 5:

- read only from `<resolved script dir>/po/` (§ 4.2) — INV-9;
- filled by plain substitution, with its placeholders checked against English
  at runtime and at the gate (§ 4.5) — INV-7, INV-8;
- refused whole for control or bidi characters, a non-UTF-8 charset, a size
  over 1 MiB, or syntax outside § 4.3 — INV-10;
- a refused or missing catalog costs the language, never the run — INV-10.

SECURITY.md gains this boundary under § Trust boundaries (§ 11).

### 4.8 The gate

`ci.sh` exports `LC_ALL=C` and unsets `LANGUAGE` at its top, so every existing
step matches English text whatever the developer's locale. Steps that test a
translation set their own environment.

The catalog steps need no display, and run in the full gate. A change to
`po/` is not documentation (`./ci.sh --docs-glob` → `docs/*|*.md|LICENSE|.github/FUNDING.yml`),
so it runs the full gate.

**Extraction** walks `demoreel` with `ast` and collects the first argument (and
for `trn` the second) of every `tr` and `trn` call, plus `ARGPARSE_MESSAGES`.
An argument that is not a string literal fails the gate — a message the
extractor cannot see is a message no catalog can carry.

New steps:

| Step | Checks |
|---|---|
| `translation: the template matches the source` | `po/demoreel.pot` equals a fresh extraction |
| `translation: the language is chosen as gettext chooses it` | `chosen_languages` and the fallback chain, against § 5's table |
| `translation: every catalog is complete` | every extracted msgid, in every catalog, has a non-empty, non-fuzzy `msgstr` — every form, `nplurals` of them, for a plural |
| `translation: placeholders and code tokens match` | each translation's placeholders obey § 4.5's rule, and its multiset of code tokens (§ 4.5) equals the English one's |
| `translation: every catalog reads` | each catalog parses under § 4.3, its `Language:` matches its filename, and it is not refused |
| `translation: confirmed means unchanged` | a catalog marked `confirmed <digest>` has that digest (§ 4.9) |
| `translation: argparse still has our strings` | each `ARGPARSE_MESSAGES` msgid occurs in the running Python's `argparse` source |
| `translation: nothing translated at import time` | no `tr` or `trn` call sits outside a function body |
| `translation: stdout and exit status do not move` | § 7's pseudo-locale runs |
| `translation: a bad catalog costs only the language` | § 7's hostile catalogs |

### 4.9 Draft and confirmed

The header field `X-Demoreel-Review:` says which a catalog is:

```
"X-Demoreel-Review: draft\n"
"X-Demoreel-Review: confirmed 3f9a0c21d4e87b65\n"
```

The digest is the first 16 hex digits of the SHA-256 of the catalog's
translations: for each non-header, non-fuzzy entry sorted by msgid (then
msgid_plural), the UTF-8 bytes of msgid, NUL, msgid_plural, NUL, each msgstr
form joined by NUL, then a newline. `./ci.sh --catalog-digest po/de.po` prints
it. Recording a confirmation writes the digest; editing any translation
afterwards makes it wrong, and the gate fails until the field says `draft`
again or a new confirmation writes a new digest. How a native speaker
confirms is DEMO-0067's.

**Where it shows:** when a draft catalog supplied any message of a run's
`--help`, the help ends with one line, itself a translated msgid:

```
This translation is a draft and has not yet been checked by a native speaker.
```

Nothing is added to other messages. A confirmed catalog adds nothing. The list
of every language's state is DEMO-0067's.

### 4.10 The window (0.6.0)

The catalogs carry no assumption that their reader is a terminal. DEMO-0086
decides whether the window imports `tr` or runs `demoreel` as a child process.
Either way it reads these files through this reader, and its own strings go in
the same template.

## 5. Invariants

- **INV-1** — With `LC_ALL`, `LC_MESSAGES` and `LANG` all unset or empty, or
  the first set one being `C`, `POSIX` or `C.<codeset>`, or with `LANGUAGE`'s
  first entry English, demoreel opens no file under `po/`.
  *Test:* `ci.sh` step `translation: a bad catalog costs only the language` —
  a copy of `demoreel` beside a `po/zz.po` that cannot be parsed, run with
  `LC_ALL=C LANGUAGE=zz` and with `LANG=en_GB.UTF-8 LANGUAGE=en:zz`; neither
  run's stderr contains `could not be read`.
  *Breaks when:* the C rule is skipped (Python's `gettext.find` reads
  `LANGUAGE` first and would load `zz`), or English does not stop the search.

- **INV-2** — Under any locale, stdout, the state file and the exit status are
  the same bytes as under `LC_ALL=C`: `record`, `shot`, `stop` and the
  finishing commands print a bare path; `motion` prints the same report in both
  forms; `--version` prints `demoreel <version>`.
  *Test:* `ci.sh` step `translation: stdout and exit status do not move` —
  each command run under `LC_ALL=C` and under the pseudo-locale (§ 7), stdout
  and exit status compared byte for byte, and one failing run of each command
  compared the same way.
  *Breaks when:* any `print()` to stdout passes through `tr`, or a message is
  written into the state file.

- **INV-3** — `chosen_languages` returns the documented list for each row of
  this table and for no other reason.

  | Environment | Result |
  |---|---|
  | `LANGUAGE=de:fr LANG=es_ES.UTF-8` | `de, fr` |
  | `LC_ALL=C LANGUAGE=de` | *(empty)* |
  | `LANG=pt_BR.UTF-8` | `pt_BR, pt` |
  | `LC_MESSAGES=zh_TW.UTF-8 LANG=de_DE.UTF-8` | `zh_TW, zh` |
  | `LC_ALL=he_IL.UTF-8 LC_MESSAGES=de_DE.UTF-8` | `he_IL, he` |
  | `LANGUAGE=en:de LANG=de_DE.UTF-8` | *(empty)* |
  | `LANG=sr_RS.UTF-8@latin` | `sr_RS@latin, sr_RS, sr@latin, sr` |
  | nothing set | *(empty)* |

  *Test:* `ci.sh` step `translation: the language is chosen as gettext
  chooses it` → the function imported from `demoreel` and called on each row;
  every row matches.
  *Breaks when:* the variables are read in another order, `LANGUAGE` is
  honoured under `C`, or the modifier is dropped.

- **INV-4** — A message the first chosen catalog lacks, has only as `fuzzy`, or
  has with an empty `msgstr`, comes from the next chosen catalog, and from
  English after the last.
  *Test:* `ci.sh` step `translation: the language is chosen as gettext chooses
  it` — two test catalogs `zz` and `yy` in a copy's `po/`, each missing a
  different message, run with `LANGUAGE=zz:yy`; each message comes from the
  catalog that has it.
  *Breaks when:* a fuzzy entry is used, or the fallback chain stops at the
  first catalog.

- **INV-5** — Every msgid the extraction finds has, in every committed
  catalog, a non-empty, non-fuzzy translation of every form.
  *Test:* `ci.sh` step `translation: every catalog is complete` → passes on
  the committed tree.
  *Breaks when:* a new `tr("...")` lands without a catalog entry, or a catalog
  is left `fuzzy` after an English change.

- **INV-6** — `po/demoreel.pot` equals a fresh extraction.
  *Test:* `ci.sh` step `translation: the template matches the source` →
  `git diff --exit-code` after `./ci.sh --pot` is clean.
  *Breaks when:* a message is added or reworded without regenerating the
  template, or a `tr` argument is not a string literal.

- **INV-7** — No committed translation has a placeholder its English message
  lacks, drops one outside § 4.5's plural exception, or changes the multiset
  of code tokens.
  *Test:* `ci.sh` step `translation: placeholders and code tokens match` →
  passes on the committed tree, and fails on a copy where `{output}` is renamed
  `{ouput}` in one catalog, and on one where `--gpu` is translated.
  *Breaks when:* a translator renames a placeholder or translates a flag.

- **INV-8** — A catalog entry naming `{output.__class__}`, `{output[0]}`,
  `{output!r}` or `{unknown}` never reaches the terminal: the run prints the
  English message and completes with the same exit status as under `LC_ALL=C`.
  *Test:* `ci.sh` step `translation: a bad catalog costs only the language` —
  a copy whose `po/zz.po` carries each of those in a message a failing run
  prints; stderr holds the English message and no `class`.
  *Breaks when:* filling uses `str.format` or `format_map`, or the runtime
  placeholder check is removed.

- **INV-9** — Catalogs are read only from `<resolved script dir>/po/`.
  *Test:* `ci.sh` step `translation: a bad catalog costs only the language` —
  run the committed `demoreel` from a working directory holding a valid
  pseudo-locale `po/zz.po`,
  with `LANGUAGE=zz LANG=de_DE.UTF-8` and `TEXTDOMAINDIR` pointing at that
  directory; every message is English.
  *Breaks when:* the lookup uses a relative path, the working directory, or an
  environment variable.

- **INV-10** — A catalog holding ESC, another C0 control other than newline
  and tab, a C1 control, a bidi control, a non-UTF-8 charset, more than 1 MiB,
  an unknown escape, or `msgctxt`, is refused whole: every message is English,
  stderr gains exactly one `could not be read` note naming the file and line,
  and the exit status is unchanged.
  *Test:* `ci.sh` step `translation: a bad catalog costs only the language` —
  one hostile catalog per case, each in a copy's `po/zz.po`.
  *Breaks when:* the reader skips the bad entry and keeps the rest, or raises.

- **INV-11** — With a translated locale chosen but stderr's encoding not
  UTF-8, every message is English and no catalog is opened.
  *Test:* `ci.sh` step `translation: a bad catalog costs only the language` —
  `PYTHONIOENCODING=latin-1 LANGUAGE=zz LANG=de_DE.UTF-8` with an
  unparseable `zz.po`; no `could not be read`. The `LANG` is what keeps
  INV-1's rule from passing it on its own.
  *Breaks when:* the encoding check is dropped, and a translated message
  raises `UnicodeEncodeError` on a Latin-1 terminal.

- **INV-12** — In a message from an `RTL_LANGUAGES` catalog, each substituted
  value and each code token is enclosed in U+2068 … U+2069, with no mark
  inside the token; a message from any other catalog, or in English, contains
  neither character.
  *Test:* `ci.sh` step `translation: placeholders and code tokens match` — a
  copy with pseudo catalogs `he.po` and `zz.po` built from the template; a
  failing `record -o /tmp/x.mp4` run's stderr checked byte for byte for the
  marks around `/tmp/x.mp4` and `--gpu`. Rendering is DEMO-0063's manual
  check.
  *Breaks when:* the language test is wrong, a token pattern misses a short
  flag, or the marks land inside the path.

- **INV-13** — Every `ARGPARSE_MESSAGES` msgid occurs in the running Python's
  `argparse`, and each is translated in `--help` and in an argparse error under
  the pseudo-locale.
  *Test:* `ci.sh` step `translation: argparse still has our strings`, plus
  `demoreel --bogus` and `demoreel --help` under the pseudo-locale.
  *Breaks when:* a Python release rewords an argparse string, or argparse
  stops looking `_` up at call time.

- **INV-14** — Under the pseudo-locale, every stderr line demoreel itself
  writes, and every `help=` line of `--help`, carries the pseudo-locale's
  marks.
  *Test:* `ci.sh` step `translation: stdout and exit status do not move` —
  the failing runs of INV-2 and `--help` of every subcommand; any `demoreel: `
  line or help line without the marks fails the step.
  *Breaks when:* a message is written without `tr`. Partial: only the
  messages those runs reach are checked.

- **INV-15** — `tr` and `trn` are called only inside function bodies.
  *Test:* `ci.sh` step `translation: nothing translated at import time` → an
  `ast` walk finds no module-level call.
  *Breaks when:* a message constant is written as `X = tr("...")`.

- **INV-16** — A catalog marked `confirmed <digest>` has that digest, and a
  run whose `--help` used a draft catalog ends with the draft line.
  *Test:* `ci.sh` step `translation: confirmed means unchanged` — passes on
  the tree; fails on a copy of a confirmed catalog with one `msgstr` edited;
  and `--help` under a draft pseudo catalog ends with its draft line, under a
  confirmed one does not.
  *Breaks when:* the digest leaves out a form or the fuzzy rule, or the draft
  line is printed for a confirmed catalog.

- **INV-17** — Every `--help` example command, printed under the
  pseudo-locale, is byte-identical to its `LC_ALL=C` form and parses.
  *Test:* `ci.sh` step `every --help example parses`, run a second time under
  the pseudo-locale.
  *Breaks when:* a command line is put inside a msgid.

## 6. Failure modes

- **No catalog for the chosen language** — English, silently. This is the
  common case for every language not shipped.
- **A catalog is unreadable, hostile or too big** — refused whole, one note,
  English (INV-10). The note is English so that it reads even when the
  catalog it names is the broken one.
- **A catalog lacks a message in a shipped tree** — the gate forbids it
  (INV-5); in a tree edited by hand after install, the next catalog or English
  supplies it (INV-4).
- **A translation's placeholders are wrong at runtime** — English for that
  message (INV-8).
- **stderr is not UTF-8** — English (INV-11).
- **`po/` cannot be listed or read (permissions)** — as if absent: English, no
  note. A missing directory is not an error.
- **A new Python rewords an argparse string** — that string prints in English;
  the gate fails on the machine running that Python (INV-13), and
  `ARGPARSE_MESSAGES` is updated.
- **`ci.sh`'s `LC_ALL=C` changes another program's output** — `LC_ALL=C` makes
  `sort` and friends byte-ordered and messages from `ffmpeg`, `Xvfb` and the
  rest English. Every step that compares such output is re-run once after the
  change; one that differs is fixed there. Python keeps UTF-8 streams under
  `C` (`LC_ALL=C python3 -c "import sys;print(sys.flags.utf8_mode, sys.stderr.encoding)"`
  → `1 utf-8`).
- **Isolation marks copied with a path** — the marks sit outside the value,
  so selecting the path alone does not take them. A terminal whose selection
  takes them anyway gives a command that fails. DEMO-0063's manual check in
  Konsole and a non-bidi terminal is where this is looked at.
- **Loading costs startup time** — only under a translated locale, and one
  parse per chosen catalog. Measured when built (§ 13).

## 7. Tests

All in `ci.sh`, full gate, the steps listed in § 4.8. Each is seen failing
before the code it checks exists — the catalog steps against a tree with a
catalog but no reader, INV-1 and INV-11 against a reader that skips the rule.

**The pseudo-locale.** A step builds, in a temporary copy of `demoreel` with
its own `po/`, a catalog `zz.po` from the template: each `msgstr` is its
English text wrapped in `⟦` … `⟧`, placeholders and code tokens untouched, all
forms filled, `X-Demoreel-Review: draft`. It is never committed — a committed
`zz.po` would be a shipped language. Runs set `LANGUAGE=zz LANG=de_DE.UTF-8`.
An `he.po` built the same way tests INV-12.

**Hostile catalogs** (INV-8, INV-10) are small hand-written files in the step,
one per case, in the same kind of temporary copy, run with
`LANGUAGE=zz LANG=de_DE.UTF-8` so that only the catalog's content can make
the run English.

| Invariant | Step |
|---|---|
| INV-1, INV-8, INV-9, INV-10, INV-11 | `translation: a bad catalog costs only the language` |
| INV-2, INV-14 | `translation: stdout and exit status do not move` |
| INV-3, INV-4 | `translation: the language is chosen as gettext chooses it` |
| INV-5 | `translation: every catalog is complete` |
| INV-6 | `translation: the template matches the source` |
| INV-7, INV-12 | `translation: placeholders and code tokens match` |
| INV-13 | `translation: argparse still has our strings` |
| INV-15 | `translation: nothing translated at import time` |
| INV-16 | `translation: confirmed means unchanged` |
| INV-17 | `every --help example parses` |

§ 4.8's table names the step `translation: every catalog reads`, which runs
the § 4.3 parser over every committed catalog; it locks no invariant of its
own and is what makes INV-5 and INV-7 read real files.

**Manual.** Rendering of right-to-left text in Konsole and in a terminal
without bidi, with a screenshot of each, is DEMO-0063's.

## 8. Alternatives considered (and rejected)

- **Compiled `.mo` files with `gettext.translation()`** — adds a build step
  and a second copy of each catalog to keep in step. Rejected by the user.
- **JSON catalogs** — no translation tool opens them. Rejected by the user.
- **Our own lookup table and plural evaluator** — reimplements what
  `GNUTranslations` already does through public API; building its input in
  memory costs a short function.
- **Also searching `/usr/share/locale`** (DEMO-0083 named it) — that directory
  holds compiled `.mo` files by convention, and a second search path is a
  second thing to defend. A package keeps `po/` beside the script instead.
- **`gettext.find()`'s language order** — it reads `LANGUAGE` before checking
  for `C`, so `LC_ALL=C LANGUAGE=de` would translate. That breaks INV-1, the
  contract scripts rely on.
- **`locale.setlocale(LC_ALL, "")` to choose** — changes C-library behaviour
  for the whole process to decide one thing an environment read decides.
- **`str.format` or `string.Template` to fill** — `str.format` reaches
  attributes and indexes; `string.Template` is safe but uses `$name`, a second
  placeholder syntax beside the `{name}` translators know from Python projects.
- **Translators wrap code tokens in isolates themselves** — a reviewer who
  cannot read the language cannot check it; doing it at fill time is
  mechanical.
- **Falling back to English when a catalog lacks a message** — the user chose
  a failing gate instead (§ 3).
- **Per-message draft marks** — the user chose per-language (§ 3).
- **Naming the function `_`** — already a throwaway name in the file (§ 4.5).
- **Translating metavars** — they appear in usage lines a reader copies from;
  leaving them English keeps those lines one language.

## 9. Out of scope

- Translating the man page — decided in DEMO-0064.
- The translations themselves — DEMO-0064, DEMO-0065.
- The confirmation process and the one list of every language's state —
  DEMO-0067.
- Translated quick-start pages — DEMO-0066.
- Inviting translators, CONTRIBUTING.md — DEMO-0097.
- How the window reaches `tr` — DEMO-0086.
- Shell completion descriptions — deferred; not yet queued.
- `msgctxt` (one English string, two meanings) — deferred; not yet queued.
  Refused until then (§ 4.3).
- Locale-aware list separators and number formats (`, ` and `3.500`) —
  deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | `ci.sh` `translation: a bad catalog costs only the language` |
| INV-2 | `ci.sh` `translation: stdout and exit status do not move` |
| INV-3 | `ci.sh` `translation: the language is chosen as gettext chooses it` |
| INV-4 | `ci.sh` `translation: the language is chosen as gettext chooses it` |
| INV-5 | `ci.sh` `translation: every catalog is complete` |
| INV-6 | `ci.sh` `translation: the template matches the source` |
| INV-7 | `ci.sh` `translation: placeholders and code tokens match` |
| INV-8 | `ci.sh` `translation: a bad catalog costs only the language` |
| INV-9 | `ci.sh` `translation: a bad catalog costs only the language` |
| INV-10 | `ci.sh` `translation: a bad catalog costs only the language` |
| INV-11 | `ci.sh` `translation: a bad catalog costs only the language` |
| INV-12 | Partial: `ci.sh` `translation: placeholders and code tokens match` checks the bytes; how a terminal draws them is DEMO-0063's manual check |
| INV-13 | `ci.sh` `translation: argparse still has our strings` |
| INV-14 | Partial: `ci.sh` `translation: stdout and exit status do not move` — only messages its runs reach |
| INV-15 | `ci.sh` `translation: nothing translated at import time` |
| INV-16 | `ci.sh` `translation: confirmed means unchanged` |
| INV-17 | `ci.sh` `every --help example parses`, second run |
| § 4.1 whole sentences, never joined fragments | **nothing** — a joined fragment still translates and passes every check; review of each DEMO-0061 diff |
| § 4.5 no code parses a translated string | Partial: INV-2's failing runs compare exit status under both locales; a parse whose result changes only stderr is not caught |
| § 4.9 a re-confirmation is a real one | **nothing** — writing a new digest is a deliberate act the gate cannot tell from a real review; DEMO-0067's process |

## 11. Cross-doc impact

- **README.md** — a short section: messages follow `LANGUAGE`, `LC_ALL`,
  `LC_MESSAGES` and `LANG`; stdout, `motion`'s report and `--version` never
  change; `LC_ALL=C` gives English. The language list and draft state are
  DEMO-0067's and DEMO-0097's.
- **SECURITY.md** — catalogs as a trust boundary, with § 4.7's defences.
- **CLAUDE.md** — § Traps gains: `tr` never at import time; no code parses a
  translated string; `ci.sh` runs under `LC_ALL=C`.
- **`docs/standards/versioning-overrides.md`** — no change: stderr and
  `--help` prose are already outside the breaking surfaces. The `po/` location
  is not a surface either.
- **`demoreel.1`** — an ENVIRONMENT entry for the four variables.
- **CHANGELOG.md** — under DEMO-0061 and DEMO-0062 when they land.
- **0.5.0's packaging items** — install `po/` beside the script the command
  symlinks to (§ 4.2).

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0060-translation-catalogs-loop-log.md`.

## 13. Resource cost

- **No new dependency.** `gettext`, `ast`, `hashlib` and `io` are in the
  standard library.
- **Memory:** a catalog is refused above 1 MiB, and at most the chosen
  catalogs are loaded — one per `LANGUAGE` entry that has a file.
- **Time:** under `C` or English, none: no file is opened (INV-1). Under a
  translated locale, one parse per chosen catalog at startup. The smoke step's
  5.5-second bound is measured under `C` and is unaffected; the parse time of
  the largest shipped catalog is measured when DEMO-0061 lands and recorded in
  its bullet.

## 14. Migration / compatibility

Nothing a caller depends on changes (INV-2). A user who has a non-English
locale today sees translated stderr once a catalog for their language ships;
a script that matched English stderr text under such a locale was relying on
an unprotected surface (`versioning-overrides.md` § What is not a breaking
surface), and `LC_ALL=C` restores English.
