# Translation review notes

What each draft translator was unsure of when the catalogs in `po/` were
drafted (DEMO-0064, 2026-10-02). For the native speaker who confirms a
language (DEMO-0096); delete a language's section once it is confirmed.

## Every language

- **Edit-script words stay English**, because a user types them: `clip`,
  `card`, `text`, `font`, `band` with `on`/`off`, `from`/`to`, and the
  subcommand names. Only the quoted sample in `text "Saving a file"` was
  translated. Check the prose around them still reads naturally.
- **Placeholders whose content was a guess**: `{word}` in "a text's {word}
  is a colour" holds an option name such as `colour` or `outline`; `{share}`
  in the stutter note is a percentage; `{time}` in "recording for {time}"
  is the time elapsed so far. Grammar built on a wrong guess (gender, an
  article) needs fixing.
- **argparse's own `error:`** prefix stays English in every language; it is
  not in the template yet.

## Per language

- **de** — "Sie"; display "Bildschirm", frame "Bild"; "Strg+C"; "zur
  Halbzeit leer" for "blank halfway".
- **fr** — "vous"; card "carton", backend "mode", band "bandeau"; "seules
  {share} des images" assumes a plural share.
- **es** — "usted"; "vídeo" with the accent (Spain's form); card "rótulo";
  "compositor sin pantalla" for headless compositor.
- **it** — impersonal infinitive; card "cartello"; "compositor headless" left
  as is; "simbolo" for a character in a path, since "carattere" also means
  font.
- **pt_BR** — "você"; fade "esmaecimento", crossfade "transição cruzada";
  backend "modo de gravação".
- **af** — formal "u", not checked against an Afrikaans GNOME catalog;
  compositor "saamsteller", backend "agterkant", clip "snit"; "card teks"
  mixes the keyword with Afrikaans.
- **he** — gender-neutral forms; a flag after a prefix letter is written
  "ב־ --name" with a space that is not needed (a flag directly after the
  maqaf is recognised); the singular plural form says "one" in words.
  Konsole lays each message out left to right, since the line starts with
  `demoreel: `; judge whether the Hebrew still reads naturally there
  (docs/media/DEMO-0063-hebrew-konsole.png).
- **ja** — です/ます; film 映像 against video 動画; the three cause lines
  open in plain form.
- **zh_CN** — "用法： " keeps a space after the full-width colon; band 底条.
- **zh_TW** — Taiwan terms (影片, 視窗, 影格, 算繪); band 底色帶.

Drafted in DEMO-0065, 2026-10-02:

- **ru** — backend "способ записи"/"режим"; "{seconds} с" for seconds;
  "приложение, допускающее один экземпляр" is long.
- **uk** — "{seconds} с"; fade-in "поява з чорного"; "the recording ended
  before it started recording" says the *run* ended, to avoid repeating
  "запис".
- **pl** — "{seconds} s"; help lines in the third person; "{where} cannot
  be read" reordered so `{where}` need not inflect; gender-neutral
  "wpisał(a)byś".
- **nl** — "u"; "run" kept as is; "plain cut" as "een harde overgang".
- **ko** — -습니다/-십시오; particles after a placeholder written both
  ways, 을(를); film 영상 against video 동영상 is a thin difference.
- **ar** — Modern Standard Arabic; the forms for one and for two drop
  `{count}`; "a flat colour" as لون واحد مُسطَّح.
