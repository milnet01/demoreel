**Lines read (subject):** `demoreel` 1-506 (506 lines) and 2846-5524 (2679 lines; the file ends at 5524).

**In my context on arrival:** this lane's prompt, the global `~/.claude/CLAUDE.md`, the user's email, a platform, date and model block, and a hook notice about the Ants MCP verbs. There was no project memory and no git snapshot.

**Brief and lane file:** no disagreement to resolve. Nothing was executed, because this lane holds no shell. ffmpeg and Python behaviour below is reasoned from their known semantics, not measured. Each such finding needs a one-line reproduction.

## Critical (0)

## High (2)

- [dim 3] `demoreel:251` — `            raise CatalogError(f"{keyword} comes before its msgid", number)`
  - A catalog's first line, such as `ESC]0;x BEL` with no space, reaches `note()` raw at line 403, because `read_po` (312) runs before the `REFUSED_CHARACTERS` scan (316).
  - That breaks DEMO-0060 § 4.3 (the note holds "never the catalog's own bytes") and § 1 ("never… write terminal control codes").
  - Line 259 (`unexpected {keyword!r}`) is escaped by `repr`, but it still echoes catalog bytes, up to the 1 MiB limit.
  - The code is wrong. CWE-150.
  - Fix: fixed wording with no `keyword` in either message.

- [dim 3] `demoreel:3277` — `                   "or level, not {word}.", where=where, word=repr(verb)) + f"\n  {line}")`
  - Also `demoreel:3191` — `                + f"\n  {line}")`, `demoreel:3289` — `        die(tr("{where}: there is no file {path}", where=where, path=path))` and `demoreel:4727` — `    scene = Scene("clip", Path(path).name)`.
  - A script line or file name holding ESC or C1 bytes reaches the terminal unescaped. `clip "<ESC>]52;c;…"` needs no real file, because `probe` prints the path while refusing it.
  - A real crafted file name prints on the success path too, through the plan notes (4597, 4602) and `{where}`. A newline forges a `demoreel:` line (CWE-117).
  - `repr` protects only some values.
  - Fix: escape C0, C1 and bidi characters for every value in `_fill`, and for the raw `line`.

## Medium (10)

- [dim 5] `demoreel:303` — `    data = path.read_bytes()`
  - The whole file is read before the limit at 304 is tested. § 4.3 says "refused before it is read"; § 13 bounds memory.
  - `po/de.po` as a symlink to `/dev/zero` grows until `MemoryError`, which is uncaught, so it costs the run. A FIFO hangs at startup.
  - The symlink also reads outside `po/`, against INV-9.
  - Fix: open with `O_NOFOLLOW|O_NONBLOCK`, require a regular file, and `read(CATALOG_LIMIT + 1)`.

- [dim 7] `demoreel:415` — `        if "%" in PERCENT_RE.sub("", text) or not tokens <= set(PERCENT_RE.findall(english)):`
  - Subset is not enough for a positional `%s`. A translation of `the following arguments are required: %s` or `unrecognized arguments: %s` that drops `%s` gives `"text" % "x"`, which raises `TypeError` as a traceback on any usage error.
  - That breaks § 1, § 4.7 and INV-8. § 4.6's wording permits it, so the spec needs the same tightening.
  - Fix: require a positional `%s` to be present exactly as many times as in English.

- [dim 3] `demoreel:4831` — `    every = re.findall(r"showinfo@every .* pts_time:([0-9.]+)", seen.stderr)`
  - Also `demoreel:3971` — `    mean = re.search(r"mean_volume: (-?[\d.]+) dB", done.stderr)` and `demoreel:1758` — `    found = re.search(r"max_volume: (-?[\d.]+|-inf) dB", done.stderr)`.
  - Input metadata is dumped into the same stderr at info level, and these patterns are unanchored. They read a crafted file's tag as if ffmpeg had measured it (CWE-117).
  - `title=showinfo@new x pts_time:99999` forges `motion`'s report, which is a protected surface.
  - Music tags `mean_volume: -90 dB` and `max_volume: -90 dB` give a gain of +60 dB and defeat the -1 dB cap (DEMO-0177 INV-10). `re.search` takes the first match, so the tag beats the real line.
  - `1.2.3` makes `float()` raise `ValueError` at 4832, 3978 or 1759. At 1759 the whole encode is lost.
  - Fix: anchor on `^\[showinfo@new @ ` and `^\[Parsed_volumedetect`, with `MULTILINE`.

- [dim 11] `demoreel:3790` — `        rate = first["rate"] if first and first["rate"] else 30`
  - Also `demoreel:4551` — `            lengths.append(max(1, round(length * rate)) / rate)` and `demoreel:4509` — `    made, stopped = run_capped(cmd, 60 + 20 * seconds, cap)`.
  - Nothing bounds a film's length or rate. `card 1e9`, `hold 1e9` or a crafted `avg_frame_rate` of `1000000/1` gets a timeout that scales with the same number, so it runs for practical purposes for ever and fills the disk beside `-o`. `memory_cap` bounds memory only.
  - `card 1e308` raises `OverflowError` at 4551 as a traceback.
  - Fix: a maximum for film length and rate, checked in `check_scene` and `film_shape`, and a free-space or output-size watch beside `resident()`.

- [dim 3] `demoreel:4635` — `            piece_files = [output.with_name(f".{output.stem}.demoreel-piece{i}.mp4")`
  - Also `demoreel:4907` — `    part = output.with_name(f".{output.stem}.demoreel-part{output.suffix}")`, and the same line at 4944, 5066 and 1266.
  - The names are predictable, sit beside `-o`, and are written by `ffmpeg -y` with no `own_path` check.
  - In a shared non-sticky folder, or with `fs.protected_symlinks` off, a planted link truncates its target. `os.replace` then moves the attacker's link to `-o`.
  - `SECURITY.md` claims only `-o` and `--app-log`, so the boundary is unlisted. Tests cannot reach this.
  - Two runs to one `-o` also delete each other's parts.
  - Fix: `mkstemp` in the output's folder, and write to that name.

- [dim 3] `demoreel:2037` — `    if path.is_symlink() and path.lstat().st_uid != os.getuid():`
  - Also `demoreel:2047` — `    return path.resolve()`.
  - Only the last component is checked. `resolve()` still follows a foreign link earlier in the path (`/tmp/reel/` planted, `-o /tmp/reel/demo.mp4`), or the second link in a chain, the same hole the docstring describes. The kernel never sees either.
  - `SECURITY.md`'s wording covers only "a path that is a symlink", so the code and the document share the gap.
  - Fix: walk each component and refuse any link owned by another user.

- [dim 3] `demoreel:4149` — `    return [*inputs, "-i", str(scene.path)]`
  - Also `demoreel:3295` — `             "-of", "json", str(path)],`.
  - Inputs stay relative and no `-protocol_whitelist` is set, so three things go wrong:
    - A file named `concat:a|b`, `subfile,,…:x` or `pipe:0` reaches ffmpeg's protocol layer. Python's `//`→`/` collapse probably defangs network URLs, but this is unmeasured.
    - An ordinary `12:30:05.mp4` fails with "Protocol not found".
    - `ffprobe` takes the path positionally, and `Path("./-report")` prints as `-report`, so it is read as an option (CWE-88).
  - Separately, ffmpeg picks the demuxer by content. A `.mp4` that is really an HLS playlist can pull another local video into the film, because the inherited whitelist is `file,crypto,data`. `format_name` is read at 3308 and used only for gif and apng.
  - Fix: make inputs absolute at parse time, add `-protocol_whitelist file`, and refuse playlist formats (`hls`, `concat`, `dash`, `sdp`).

- [dim 11] `demoreel:4823` — `            capture_output=True, text=True, timeout=60 + 10 * (end - start),`
  - `motion` runs at `-loglevel info` with two `showinfo` filters, so stderr holds about 600 bytes per frame in Python's memory. A file of millions of tiny frames becomes gigabytes.
  - `memory_cap` covers only `run_film_ffmpeg`, and even there `run_capped` buffers ffmpeg's stderr without limit.
  - `motion`, `grab_frame`, `music_loudness` and `picture_frames` have no memory limit at all. The timeout scales with the file's claimed duration.
  - Fix: stream stderr line by line and keep counts and a bounded tail, and run all of them under `run_capped`.

- [dim 7] `demoreel:3966` — `            capture_output=True, text=True, timeout=60 + music.length / 5,`
  - Also the runs at 4823 and 1755.
  - `text=True` decodes strictly. A non-UTF-8 tag in a Matroska file, dumped at info level, raises `UnicodeDecodeError`. Each of these catches only `TimeoutExpired`, plus `OSError` at 1756, so the result is a traceback. In `loudest` it comes after the full encode, and the `finally` deletes the film.
  - Fix: `errors="replace"`.

- [dim 2] `SECURITY.md` § Trust boundaries, and DEMO-0177 § 5: "No trust boundary is crossed: the music file is one more input the caller names".
  - The document is wrong. An edit script, a media file, a font and file names may come from someone else, and the findings above show they reach the terminal, ffmpeg's protocol layer and memory.
  - A script can also name any readable file (`clip ~/private.mp4`) and put it in a film meant for publishing.
  - This goes to `review-contract`.

## Low / Info

- [dim 3] `demoreel:4656` — `                "file '{}'\n".format(str(f).replace("'", "'\\''")) for f in piece_files))` — quotes are escaped but newlines are not, and the list runs under `-safe 0`. A newline in `-o` breaks the quote, and the next line is parsed as a concat directive. A default name is sanitised (2015), so only an explicit `-o` reaches this. Fix: refuse control characters in `-o`.
- [dim 3] `demoreel:3434` — `             "-vf", f"drawtext=textfile='{textfile}':expansion=none:"` — also 3810 and 4985. `XDG_RUNTIME_DIR` is unscreened here, though `text_font` screens font paths. A `'` breaks the graph or injects filter options, and it is reported as "cannot draw text". Fix: the same character check, at `state_dir`.
- [dim 2] `demoreel:4777` — `                       | ({"size": a.text_size} if a.text_size else {})]` — `card --text-size 0` silently takes the default, while `caption` refuses it, so one shortcut disagrees with the script. Fix: `is not None`.
- [dim 2] `demoreel:3433` — `             f"color=black:s={fontsize * 80}x{fontsize * 3}:d=1",` — the strip clips the measurement. At a small size, with the strip narrower than the room, an over-wide text passes the README's width refusal. Fix: make the strip at least room + 1 wide.
- [dim 2] `demoreel:3512` — `        if "\n" in words:` — drawtext also breaks lines on `\r`, `\f` and `\v`, so `caption --text` gets past "one line". Fix: refuse all four.
- [dim 2] `demoreel:4693` — `    make_film(scenes, output_or_default(a, "film" if a.script == "-" else a.script),` — the script is not in the read list, so `edit x.mp4 -o x.mp4` writes over it, against the README's "never writes over its own input".
- [dim 4] `demoreel:5064` — `    crop = "crop={2}:{3}:{0}:{1},".format(*region) if region else ""` — `motion`'s crop has `exact=1` (4814) for the off-by-one on odd corners; this copy does not.
- [dim 4] `demoreel:4032` — `    if not (math.isfinite(mean) and math.isfinite(peak)):` — the regex at 3971-3972 cannot yield `inf`, so this refusal never fires, while `loudest`'s copy of the regex accepts `-inf`.
- [dim 7] `demoreel:5058` — `    tall = max(2, round(height * tile / width / 2) * 2)`, and `demoreel:4268` — `        w, h = clip_w * box_h / clip_h, box_h` — a crafted stream reporting width or height 0 raises `ZeroDivisionError`.
- [dim 7] `demoreel:3763` — `        if scene.box[3] < 2:` — width is unchecked, so a very tall clip gives `s=0xN` and fails inside ffmpeg, against "everything is checked before anything is made".
- [dim 7] `demoreel:4374` — `    output.parent.mkdir(parents=True, exist_ok=True)` — an `OSError` here is a traceback, not a message.
- [dim 16] `demoreel:111` — `    if not sys.stderr.isatty() or text == _progress_line:` — under `2>&-`, `sys.stderr` is `None`, so `AttributeError` escapes `note()`, whose docstring says a note must not fail the run. Also `summarise`.
- [dim 16] `demoreel:3570` — `        textfile.write_text(words, encoding="utf-8")` — also `demoreel:4655` — `            listing.write_text("".join(` and `print(output)` at 4681. A non-UTF-8 name or `--text` (surrogate escapes) raises `UnicodeEncodeError`. At 4655 this comes after the pieces are encoded; at 4681, after the film is in place.
- [dim 16] `demoreel:95` — `    die(tr("ended by {signal} before it finished, so there is nothing to hand back.",` — `SystemExit` is raised at any point, so a second SIGTERM or SIGHUP during a `finally` leaves hidden parts and the workdir behind.
- [dim 13] `demoreel:4594` — `            name = scene.path.name if scene.path else tr("text")`, and `demoreel:4771` — `    scene = Scene("card", tr("the card"))` — translated fragments go into other messages, against § 4.1. Unconditional locale traps: nothing found; no `setlocale`, and numbers use `:f` and `float`.
- [dim 15] `demoreel:4647` — `            run_film_ffmpeg(` — no `-map_metadata -1` here or at 4659, so a source clip's tags should pass through to the published film. Not measured. No privacy contract is named, so the leak itself is the finding, not consent.
- **Other dimensions:** 2b: nothing found, by reading every subcommand and script word to its caller. 8: signal handling only (above). 9: nothing beyond the part-file finding. 10, 12, 17: N/A in this lane.
- **INFO:** no second local user, no protected-symlinks-off kernel and no execution here. The tool suspicions are `[tool: ruff]` on the `int`/`float` paths, none of them certain. `security.md` was outlined only, not read section by section.

## Covered by spec and looks correct

I read these and they match the spec; none were executed.

- **Filter-graph text:**
  - Colours pass `COLOUR_RE.fullmatch`, and transitions come from a fixed list.
  - Every drawn user text uses `textfile` with `expansion=none`; `sheet`'s text is a formatted float.
  - `fontfile` paths are screened for `':\,;[]`.
  - Numbers are formatted and NaN-safe.
  - No caller text reached a graph directly in the paths I read.
- **Shell and option safety:** the lane's subprocess calls use argv lists with no `shell=True`. `shlex.split` catches `ValueError`. A leading `-` in a font family is escaped.
- **Catalogs:**
  - `CODE_RE.fullmatch` blocks `../`, and the lookup never uses the working directory or an environment path (`Path(here).resolve()`).
  - `_fill` is plain substitution, and the brace and placeholder checks are present.
  - Fuzzy and empty entries fall through, and `LC_ALL=C` comes first.
  - The plural range check runs from 0 to 1000, with its exceptions caught.
- **Windows and music:** DEMO-0183's look constants, shape rule and `background` refusal match it. So do DEMO-0177's order of music steps, `normalize=0`, and the fact that no demuxer loop is used.

## Open questions

- **Arrival context:** I arrived holding the global `CLAUDE.md`, which names `check-code`, `review-code` and the project-session rules. It holds no demoreel history. The project `CLAUDE.md` and rules file were read as assigned contract.
- **Playlist reach:** whether a crafted HLS file reaches a local video on this ffmpeg is reasoned, not measured. Check: a `.mp4`-named `#EXTM3U` file pointing at an absolute `.mp4`.
- **Tag pass-through:** whether a clip's tags survive piece, then concat, then film decides how far the `loudest` and privacy findings reach.
- **Scripts as trusted:** I could not tell whether `edit` scripts are meant to be trusted input. No document says so, so I named the document as the wrong side.

## 3 items to fix first

1. **The two terminal-escape paths (251, and `_fill` with the raw `line`).** A catalog or a shared script alone reaches the terminal, and the catalog one breaks a stated invariant.
2. **The forged log lines (4831, 3971, 1758), with `errors="replace"`.** One crafted tag falsifies a protected report and lifts the loudness cap, and the fix is small.
3. **Input and output paths (`own_path`, part names, relative inputs).** These are the unguarded boundaries the gate cannot test with one account, and one change to path handling closes several of them.
