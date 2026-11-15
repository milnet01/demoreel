# Translation review notes

What to check when reviewing a language in `po/`. A newly drafted
language may add its own section under § Per language, listing what its
drafter was unsure of; delete that section once the language is reviewed.

## Every language

- **Edit-script words stay English**, because a user types them: `clip`,
  `card`, `text`, `font`, `band` with `on`/`off`, `from`/`to`, and the
  subcommand names. This covers only a word as the user types it: in a
  script line, or a name in backticks. The same word in an ordinary
  sentence is translated, so "a card needs a length above zero" says
  "card" in the language. Only the quoted sample in `text "Saving a file"`
  was translated. Check the prose around them still reads naturally.
- **Placeholders whose content was a guess**: `{word}` in "a text's {word}
  is a colour" holds an option name such as `colour` or `outline`; `{share}`
  in the stutter note is a percentage; `{time}` in "recording for {time}"
  is the time elapsed so far. Grammar built on a wrong guess (gender, an
  article) needs fixing. `po/demoreel.pot` now says what each of these
  holds, in a `#. translators:` line above the message (DEMO-0167).
- **argparse's own `error:`** prefix was added after the drafts
  (DEMO-0166), as a single word per language. Check it reads as a
  command-line error label.

## Per language

None: every language in `po/` is reviewed.
