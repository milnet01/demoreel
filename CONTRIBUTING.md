# Contributing to demoreel

Thank you for helping. This file says how to help with the translations.
Other ways to contribute will be added here as they open.

## Translations

demoreel's messages and `--help` are translated. Every translation started
as a draft, written without a native speaker. README.md § Languages lists
each language and whether it is still a draft.

A draft says so: `--help` ends with a line saying the translation has not
yet been checked by a native speaker.

### Where they live

Each language is one file in [`po/`](po/), named by its language code:
`po/de.po` for German, `po/pt_BR.po` for Brazilian Portuguese. Each
message appears in it as the English (`msgid`) followed by its translation
(`msgstr`). Any text editor opens it, and so do translation tools such as
Poedit.

Each language also has a quick-start page,
`docs/quickstart/<code>.md`: README's install steps and first recording,
translated. Its words are the catalog's. In its code blocks only the lines
starting with `#` are translated; the commands must stay exactly as README
has them, or the checks fail.

[`docs/translation-review-notes.md`](docs/translation-review-notes.md) lists
what the drafter of each language was unsure of. Start there.

### Seeing your language in use

Run demoreel with your language chosen:

```
LANGUAGE=de LANG=de_DE.UTF-8 demoreel --help
LANGUAGE=de LANG=de_DE.UTF-8 demoreel trim x.mp4 -o y.mp4
```

Use your own language code in place of `de`. The second command fails on
purpose, to show an error message. If `LC_ALL` is set in your shell, it
wins over both; run `unset LC_ALL` first.

### Suggesting a better wording

Either way works:

- **Open an issue** at <https://github.com/milnet01/demoreel/issues>.
  Quote the English, the current translation, and your wording.
- **Send a pull request** that edits `po/<code>.po`. Run `./ci.sh --docs`
  if you can; the full `./ci.sh` checks the catalogs too.

A translation must keep a few things exactly as the English has them, or
the checks fail and demoreel prints the English instead:

- every placeholder in braces, such as `{output}` (you may move it);
- every command-line flag and every text in backticks, untranslated;
- `%s`, `%(value)r` and similar, in the entries marked
  `#. argparse formats this text with %` (write a percent sign as `%%`
  there);
- each `\n`, and the two spaces after it that indent the next line.

Words a user types into an edit script stay in English too: `clip`,
`card`, `text`, `font`, `band`, `on`, `off`, and the command names.

### Confirming a language

When a native speaker has read a language and says it is right:

1. The maintainer runs `./ci.sh --catalog-digest po/<code>.po`. It prints a
   fingerprint of every translation in the file.
2. The header line `X-Demoreel-Review: draft` becomes
   `X-Demoreel-Review: confirmed <fingerprint>`.
3. README.md § Languages marks the language confirmed, and the language's
   section leaves `docs/translation-review-notes.md`.

From then on `--help` no longer calls it a draft. If any translation in the
file changes afterwards, the fingerprint no longer matches and the checks
fail. The header then goes back to `draft`, or a native speaker confirms
the new wording and a new fingerprint is recorded.
