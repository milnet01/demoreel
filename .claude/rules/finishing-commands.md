---
paths:
  - "demoreel"
  - "ci.sh"
---
# The finishing commands

`README.md` § Finishing a recording is their contract. One renderer,
`make_film`, turns a list of scenes into one ffmpeg run; `edit` reads the
scenes from a script and each shortcut builds them from its options. Add a
behaviour to the renderer, never to one shortcut, or the two ways of asking
stop agreeing.

- **Every stream in the filter graph must end.** An input that never ends is
  buffered without limit by whatever is waiting for it. An animated `.png` read
  with `-ignore_loop 0`, sitting behind another scene in a `concat`, took
  ffmpeg to 14 GB in six minutes on this machine (2026-09-30). So each scene is
  cut with `trim=end_frame`, a card's picture is read once and repeated by the
  `loop` filter, which makes a frame only when one is wanted, the output has
  its own `-t`, and `memory_cap` limits that ffmpeg's memory. Never loop a
  picture at the demuxer (`-ignore_loop 0`, `-loop 1`, `-stream_loop`), and do
  not remove any of them: each covers a mistake in the others.
- **Try a new graph under a memory limit first.** `( ulimit -v 6000000;
  timeout 40 ./demoreel edit ... )` fails a runaway in seconds with "Cannot
  allocate memory". Other sessions share this machine's memory.
- **`concat` hands on a microsecond timebase, and `xfade` refuses inputs whose
  timebases differ.** The `fps` after each `concat` puts the film's back. A
  film with a cut followed by a crossfade fails to start without it.
- **A cut is snapped to the clip's own frames.** The frame on screen at `to`
  is kept, which is what lets `motion`'s `last change` be used as a `to`. The
  seek starts half a frame early and the read ends half a frame late, so
  neither edge turns on how a float rounds. Do not replace that with `-ss` and
  `-t` at the times as given: the last frame is then kept or lost by rounding.
- **A time picks the frame on screen then, with a little slack, in one place.**
  `frame_at` serves a clip's `from` and `to` and `poster -t`. `motion` prints
  three decimals, so a frame starting at 1.33333 comes back as 1.333; without
  `TIME_SLACK` a cut there lost frame 40 of a 30-a-second clip (DEMO-0137).
  Do not go back to a bare `floor` or `ceil`, and do not snap in a second
  place.
- **A text shows up to its `to` and not on it**, so captions can sit back to
  back. A clip's `to` is inclusive and a text's is not; both are in README.
- **The bold font is passed as a file.** drawtext's `font` option takes a
  fontconfig pattern and ignores the weight in it: `Sans:bold` drew the regular
  face, measured by width. `text_font` asks `fc-match` for the file.
- **`fc-match` never says no, so a named font is checked by family.** Asked
  for a font the machine lacks it answers with another: `Noto Sans Mono` came
  back as Liberation Mono. `text_font` compares the family it answers with the
  one asked for and refuses a different one. Do not drop that comparison. A
  hyphen in a family's name is escaped first: unescaped, fontconfig reads it
  as the start of a size.
- **A text's band is the text's own box, and that is how it fades.**
  `drawbox` cannot change with time; drawtext's `boxw` box follows the text's
  `alpha`, as do its outline and shadow (measured on ffmpeg 6.1.1 and 8.1.2).
  An ffmpeg without `boxw` gets `drawbox`, and a fading band is refused there.
  No ffmpeg older than 6.1.1 has been measured.
- **Text is measured by drawing it.** `text_size` draws the line on a black
  strip and reads ffmpeg's `bbox`. The refusal of a too-wide line rests on it,
  and so does `demoreel check`'s text line.
- **"The picture changed" is one test, `NEW_FRAME` (640), for `motion` and
  the `--gpu` note.** Below 640 x264's sharpening after a change counts as new
  frames, so a stuttering video reports as smooth: on real `--gpu` recordings
  256 scored 39% new frames as 73%, and the note stayed silent (DEMO-0134). At
  640 a faint drifting gradient scores low, so the note can fire on a smooth
  video. That is the accepted side: the note never fails a run. So `ci.sh`'s
  stutter fixtures are `testsrc2`, whose movement has edges; `testsrc` moves a
  gradient and scores 39%. Do not lower the threshold for the note alone, and
  do not go back to `testsrc`. The measurements are beside the constant.
- **The film is written beside `-o` and moved into place when whole**, which
  is what makes "a failure leaves nothing at `-o`" true. Do not write to `-o`
  directly.
