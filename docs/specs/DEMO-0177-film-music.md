<!-- ants-spec-format: 1 -->
# DEMO-0177 — Keep a clip's sound through the finishing commands, and put music under a film

**Status:** spec draft (2026-10-11).
**Kind:** feature.
**Source:** ROADMAP DEMO-0177 (user-request-2026-10-10; decisions 2026-10-10 and 2026-10-11).
**Pairs with:** DEMO-0106 (records the app's sound this keeps; its § 9 leaves this work here).

A film made with `edit` or a shortcut keeps the sound of the clips it is cut
from, and can carry one music track that repeats to fill it, at a level and
with changes of level the script sets.

## 1. Goal

`edit`, `trim`, `caption`, `join` and `card` keep each clip's own sound, in
step with its picture to within 40 ms, through cuts, fades and crossfades.
A `music FILE` line, or `--music` on a shortcut, lays one music track under
the whole film: repeated to fill it, faded in and out, set to average the
level the caller asks for, and made softer or louder for stretches the
script names. A film with no sound in its clips and no music is exactly what
it is today: no sound track at all.

## 2. Problem

1. The finishing commands drop sound. `make_film` maps only the film's
   picture and passes `-an`, and README § Finishing a recording says *"Sound
   in an input is dropped."* So an `--audio` recording (DEMO-0106) loses its
   sound the moment it is trimmed, captioned or joined, and DEMO-0106 § 9
   left that to this item.
2. A trailer needs music, and today that means a second program. The user
   wants demoreel to be the one tool (ROADMAP DEMO-0177, 2026-10-10).
3. Music at the file's own level is usually too loud. The approved Slipcase
   trailer's music sat at about -30 dB on average under its effects
   (ROADMAP DEMO-0177), and music files are mastered far louder than that.

## 3. Scope decisions (agreed with the user)

From the roadmap item (2026-10-10):

- **Music and app sound are independent choices.** A film may have either,
  both mixed, or neither.
- **Music comes from a `music FILE` line in an `edit` script and a
  `--music` option on `join`, `trim`, `caption` and `card`.** The file is
  always the caller's; demoreel makes no music.
- **The music repeats to fill the film and fades in and out.** The Slipcase
  trailer's shape is the default: fade in over 1.5 s, out over 3 s.
- **Its default level is low, about -30 dB average.**

From this session (2026-10-11):

- **The volume is the caller's to control, including at chosen moments.**
  Asked whether the music should sit at one low level or dip by itself under
  the app's sound, the user answered that the requestor controls it, softer
  or louder when required. So: a level on the music line, `level`
  lines that change it for a stretch of the film, and `volume` on a clip
  line. Nothing changes a level by itself.
- **Normalising applies to the music, on or off.** By default the music is
  measured and set to average the asked level, whatever the file's own
  loudness; `normalise off` uses the file as it is, and the level becomes a
  plain gain. Evening out the clips' own sound, and a whole-film loudness
  target, were offered and not chosen.
- **A clip's sound can be dropped**: `sound off` on a clip line,
  `--no-sound` on the shortcuts that take clips.
- **The shortcuts take all four music settings**: `--music`,
  `--music-level`, `--music-fade-in`, `--music-fade-out`.

Settled here without asking, each following from the above: a clip's sound
fades with its picture; `normalise`, the `level` lines and a clip's `volume`
are the script's alone, as a text's font and colour are today.

## 4. Design

Everything stays in the one renderer, `make_film`, so the script and the
shortcuts cannot disagree (`.claude/rules/finishing-commands.md`).

### 4.1 The script's new words

```
music FILE [level DB] [normalise on|off] [fade-in S] [fade-out S]
  level DB [from S] [to S] [ramp S]        # zero or more, under the music line

clip FILE ... [sound on|off] [volume DB]   # two new words on a clip line
```

- **`music FILE`** — the film's music. At most one per script, on a line of
  its own, anywhere among the scenes; it is not a scene and takes no time.
  The file is anything ffmpeg reads with a sound stream: its first sound
  stream is used and any picture in it is ignored. A file with no sound is
  refused.
- **`level DB` on the music line** — with `normalise on`, the default, the
  level the music averages in the film, in dB below full scale: `-30` unless
  given, and between `-60` and `0`. With `normalise off`, a gain on the
  file's own level: `0` unless given, and between `-60` and `20`.
- **`fade-in S`, `fade-out S` on the music line** — the music's own fades
  at the film's start and end, `1.5` and `3` unless given; `0` turns one
  off. Written fades longer together than the film are refused. The default
  fades, where they do not fit, shrink in proportion until they do.
- **A `level DB` line** — belongs to the music line, and comes straight
  after it or after another `level` line, as a `text` line follows its
  scene; an indent is only for the eye. The music sits at that level from `from`
  to `to`, which are times in the finished film, as `edit`'s plan prints
  them. `from` defaults to the film's start and `to` to its end. Over the
  `ramp` seconds before `from` the music slides from its level to this one,
  and over the `ramp` seconds after `to` it slides back; `ramp` is `0.5`
  unless given. A slide is cut short at the film's start or end. Two `level`
  lines whose spans, slides included, overlap are refused. Its `DB` means
  what the music line's `level` means, under the same `normalise`.
- **`sound off` on a clip** — the clip's span is silent. `sound on` is the
  default.
- **`volume DB` on a clip** — turns the clip's own sound up or down by that
  many dB, between `-60` and `20`. On a clip with no sound it is refused.

`level` and `volume` take a signed number. `script_number` refuses a
negative, so they get a reader of their own; every other word keeps
`script_number`. The words stay English in every language (DEMO-0060 § 4.1,
*Words a user types*).

### 4.2 The shortcuts

| Option | Script word | Taken by |
|--------|-------------|----------|
| `--music FILE` | `music FILE` | `trim`, `caption`, `join`, `card` |
| `--music-level DB` | the music line's `level` | the same |
| `--music-fade-in S` | the music line's `fade-in` | the same |
| `--music-fade-out S` | the music line's `fade-out` | the same |
| `--no-sound` | `sound off` on every clip | `trim`, `caption`, `join` |

`--music-level` and the two fades without `--music` are refused. `trim`
given only `--music` or `--no-sound` has something to do, so `cmd_trim`'s
"needs something to do" refusal does not fire; it cuts nothing. The music
file joins the files `finishing_output` refuses to write over.

### 4.3 A clip's own sound

Each scene becomes a sound stream `[a<n>]` exactly as long as its picture,
in 48000 Hz stereo float, beside its picture stream `[v<n>]`. The picture's
length is the frame count `scene_graph` keeps (`trim=end_frame`) divided by
the film's rate, which can differ from the scene's `length` by part of a
frame; the sound takes the picture's.

- **A clip with sound, `sound on`**: its first sound stream, the same span
  the picture keeps. The input's `-ss` seeks half a frame before `from`
  (`check_scene`), so the sound is trimmed by `start - seek` to begin at
  `from` itself. The input's `-t` limits the sound as well as the picture,
  and `scene.read` stops half a frame before the last kept frame ends; so
  for a clip with a `to` it reads to that frame's end, `(last + 1) * step -
  seek`, and `trim=end_frame` still bounds the picture. The sound is then
  padded with silence and trimmed to the picture's length
  (`apad=whole_dur=<p>,atrim=duration=<p>`), because a recording's sound may
  end before its picture (DEMO-0106 § 4.4).
- **A clip without sound, a clip with `sound off`, and a card**: silence of
  the picture's length (`anullsrc` with its `duration` set).
- **`volume DB`**: a `volume` filter on the clip's stream.
- **The picture's fades fade the sound with it**: `fade-in` and `fade-out`
  by `afade` over the same seconds, each `fade-at` by an `afade` out and an
  `afade` in over the same two halves, each switched on only for its own
  half, as `fade_filters` does for the picture.
- **Scenes join as their pictures do**: a cut by `concat` with `a=1`, a
  crossfade by `acrossfade` over the same seconds as the picture's `xfade`,
  which overlaps the two by that long, as `xfade` does.

### 4.4 The music

The music stream `[m]` is built from the music file in this order:

1. **Resampled** to 48000 Hz stereo float.
2. **Set to its level.** With `normalise on`, one pass of `volumedetect`
   over the music file, before the film is made, gives its `mean_volume`
   and `max_volume`; the gain is `level - mean_volume`. With `normalise off`
   the gain is `level`.
3. **Kept off full scale.** Any level, the music line's or a `level`
   line's, whose gain would put the music's `max_volume` above -1 dB is
   lowered until it does not, and stderr gets one note naming the level
   reached. With `normalise off` this needs the same `volumedetect` pass, so
   the pass always runs.
4. **Repeated to fill the film**, when it is shorter: `aloop=loop=-1`
   with `size` the file's length times 48000, rounded up: samples are counted
   after step 1's resampling. Measured
   2026-10-11: a `size` larger than the input loops what the input held,
   with no gap. Then `atrim=duration=<film length>`, which is what ends it.
   The demuxer never loops it (`-stream_loop` is banned with the rest,
   `.claude/rules/finishing-commands.md`).
5. **Made softer or louder for each `level` line**: one `volume` filter,
   `eval=frame`, whose gain in dB is the music line's, moved to each line's
   for its span and slid linearly in dB across each `ramp`.
6. **Faded** in and out by `afade`.

`aloop` holds the whole music file in memory, and only runs when the file
is shorter than the film, so what it holds is bounded by the film's length.

### 4.5 The mix and the output

- **The film has a sound track when any clip with `sound on` has a sound
  stream, or there is music.** Otherwise the ffmpeg run keeps `-an` and the
  file is what it is today.
- **Mixing**: the scenes' sound and the music by
  `amix=inputs=2:normalize=0:duration=first`. `normalize=0` keeps both at
  the levels set: the default divides each input by the number of inputs.
  Present on ffmpeg 6.1.1, the Ubuntu image, and 9.0.2 here. A film with no
  music maps the scenes' sound alone; a film whose clips are all silent maps
  the music alone.
- **Encoding**: `AUDIO_ENCODER`, as `record --audio` uses, so DEMO-0106
  INV-6's stream shape holds for a film too. The sound is trimmed to the
  film's length, and the output's `-t` bounds both streams.
- **A film whose sound reaches full scale** (`loudest` at or above -0.1 dB)
  gets one note on stderr: it may be distorted, and the music or a clip can
  be turned down. It is not an error; the caller set the levels.
- **The plan on stderr** gains a line for the music: the file, the level it
  averages (or its gain), the change the measurement made, and one line per
  `level` line with its film times.
- stdout still carries the finished path and nothing else. Every new
  message goes through `tr`, and `./ci.sh --pot` regenerates the template.

### 4.6 What is checked before anything is made

All of it, as today, naming the line or the option: a second `music` line;
a `level` line that does not follow the music line or another `level`
line; a `text` line under a `music`
or `level` line; a music file that is missing or has no sound; a `level` or
`volume` out of range or not a number; `sound` other than `on` or `off`;
`normalise` other than `on` or `off`; a `level` line's `from` not before
its `to`, or either past the film's end; two `level` lines that overlap;
written music fades that do not fit; `volume` on a clip with no sound; a
`--music-*` option without `--music`. The `volumedetect` pass is part of
the checking: it runs before the film's ffmpeg starts, and a music file it
cannot read stops the run.

## 5. Invariants

- **INV-1** — A film whose clips carry no sound, or all have `sound off`,
  and which has no music, has no sound stream.
  *Test:* ci.sh, finishing: `A.mp4` is the one finishing fixture generated
  with sound. Every existing output made from cards and the other fixtures
  has no sound stream (`assert_finished`, told to expect 0), and so has
  `join --no-sound A.mp4 B.mp4`. Only a track added unasked, or `sound off`
  ignored, fails it.
  *Breaks when:* a sound track is added to every film, or `sound off` is
  ignored.

- **INV-2** — A clip's own sound stays within 40 ms of its picture through
  a `from` cut, a `to` cut with no gap at it, a crossfade, a card before it, and a clip before it whose
  sound is shorter than its picture.
  *Test:* ci.sh, finishing: a generated clip with a white flash and a 3 kHz
  beep together at 2.0 s and 4.0 s, and a second clip whose sound ends
  0.4 s before its picture. The script is a card, the short-sound clip, then
  the first clip `from 1.3 to 5` with `crossfade 0.5`. Each flash's first
  bright frame and each beep's onset (`silencedetect` after a 1500 Hz
  high-pass) differ by at most 0.040 s. The prototype of § 4.3 measured 5 to
  11 ms on the cut and crossfade, 2026-10-11. Isolates the joins: without
  the padding, the last scene's beeps arrive 0.4 s early, because the short
  clip is joined to it by a crossfade. `concat` pads a short sound itself:
  measured 2026-10-11, a 1.6 s sound under a 2 s picture, cut to a clip
  beeping at 2.0 and 4.0 s, gave onsets at 4.005 and 6.011 s. With `concat`
  for the crossfade they arrive 0.5 s late. And `A.mp4 to 2` cut to
  `A.mp4`, at the fixture's 10 frames a second: `silencedetect` at -50 dB
  with `d=0.01` finds no silence at the join, where reading only to
  `scene.read` leaves 0.05 s.
  *Breaks when:* a scene's sound is not padded to its picture's length, a
  clip's sound is read only to `scene.read`, a card gives no silence, or a
  crossfade joins the sound by a cut.

- **INV-3** — A film with sound has exactly one sound stream, AAC, 48000
  Hz, stereo, starting at 0 and ending within 0.1 s of the picture's end.
  *Test:* ci.sh, inside INV-2's step: `ffprobe -show_entries
  stream=codec_type,codec_name,sample_rate,channels,start_time,duration`,
  comparing `start_time + duration` per stream. The prototype: both streams
  `0.000000` to `9.233333`.
  *Breaks when:* the encoder options change, or the sound is not trimmed to
  the film.

- **INV-4** — A scene's `fade-in`, `fade-out` and `fade-at` fade its sound
  with its picture.
  *Test:* ci.sh, finishing: a clip with a steady tone, `fade-in 1 fade-out 1
  fade-at 3`; the tone's level over the first and last 0.1 s, and over the
  0.1 s around 3.0, is at least 20 dB below its level at 2.0. Without the
  sound fades all three equal it.
  *Breaks when:* the sound ignores a picture fade.

- **INV-5** — `sound off` silences that clip's span and no other, and
  `volume DB` changes that clip's sound by that many dB, within 1 dB.
  *Test:* ci.sh, finishing: three clips of the same steady tone, the second
  `sound off` and the third `volume -6`; the second's span is at or below
  -60 dB, and the third's mean is 6 ± 1 dB below the first's.
  *Breaks when:* either word is ignored or applied to the wrong scene.

- **INV-6** — With `normalise on`, the music averages the asked level
  within 1 dB, whatever the file's own level.
  *Test:* ci.sh, finishing: two music files of one tone, 20 dB apart, each
  under a silent 9 s card at `level -30`, and one at `level -20`; the mean
  over 2 to 5 s is -30 ± 1 dB for both of the first, -20 ± 1 dB for the
  third. The prototype measured -30.1 dB for a -30 target.
  *Breaks when:* the gain is not applied, has the wrong sign, or is
  measured from the wrong file.

- **INV-7** — With `normalise off`, the level is a gain on the file's own
  level, within 1 dB.
  *Test:* ci.sh, finishing: the quieter INV-6 file with `normalise off
  level -6`; the mean over 2 to 5 s is 6 ± 1 dB below the file's own
  `mean_volume`.
  *Breaks when:* the file is normalised anyway, or the gain is ignored.

- **INV-8** — Music shorter than the film repeats to its end with no gap,
  and the music fades in and out over the seconds asked, 1.5 and 3 unless
  given.
  *Test:* ci.sh, finishing: 2.5 s of music under a 9 s card; `silencedetect`
  at -60 dB finds no silence between 0.1 s and 8.9 s; the mean over the
  first 0.1 s and the last 0.1 s is at least 20 dB below the mean over 2 to
  5 s; with `fade-in 0 fade-out 0` both are within 1 dB of it.
  *Breaks when:* the music plays once and stops, the loop leaves a gap, or
  a fade is missing or ignores its length.

- **INV-9** — Each `level` line holds the music at its level from `from` to
  `to`, within 1 dB, and the music is back at its own level outside the
  line's slides.
  *Test:* ci.sh, finishing: music at `level -30` under a 12 s card, with
  `level -42 from 4 to 7 ramp 0.5`; the mean over 4.2 to 6.8 s is -42 ± 1
  dB, and over 2 to 3 s and 8 to 9 s -30 ± 1 dB.
  *Breaks when:* a `level` line is ignored, applied at the wrong times, or
  never slides back.

- **INV-10** — No level puts the music's peak above -1 dB; a level lowered
  for that, and a film whose sound reaches full scale, each get one note on
  stderr, and the film is still made.
  *Test:* ci.sh, finishing: a music file whose peak sits 26 dB above its
  mean, at `level -20`, would peak at +6 dB; the film's music peaks at -1 ±
  0.5 dB, stderr has the lowered-level note, and the run exits 0. A
  full-scale tone clip at `volume 6` gives the full-scale note and exit 0.
  *Breaks when:* the cap or either note is missing, or either case fails
  the run.

- **INV-11** — Every script error in § 4.6 stops the run before ffmpeg
  makes anything, names the line or option, and leaves nothing at `-o`.
  *Test:* ci.sh, finishing, beside "edit checks every line before it makes
  anything, and names the bad one": one script per error, and one `join`
  given `--music-level` without `--music`; each exits
  non-zero, its stderr names the line, and `-o` does not exist.
  *Breaks when:* an error is found only by ffmpeg, or not at all.

- **INV-12** — A shortcut's music and `--no-sound` give the same film as
  the script that says the same.
  *Test:* ci.sh, finishing: `join a.mp4 b.mp4 --music m.wav --music-level
  -25 --music-fade-in 1 --music-fade-out 2 --no-sound` and the matching
  `edit` script; the decoded sound of the two films has one MD5
  (`ffmpeg -i <film> -map 0:a -f md5 -`). And `trim A.mp4 --music m.wav`
  alone exits 0.
  *Breaks when:* a shortcut maps an option to the wrong word, or builds its
  scenes another way.

- **INV-13** — Every sound stream in the film's graph ends.
  *Test:* ci.sh, finishing: a 2 s music file under a 60 s card, and a
  10-minute music file under a 3 s card, each finish under `ulimit -v
  2000000` and within `make_film`'s timeout, at the planned length. Partial:
  each bound (`atrim` after `aloop`, `anullsrc`'s duration, the output's
  `-t`, `memory_cap`) covers the others, so removing one alone may not fail
  it, which `.claude/rules/finishing-commands.md` says of the picture's
  bounds too.
  *Breaks when:* a stream has no end and something waits for it.

No trust boundary is crossed: the music file is one more input the caller
names, read by ffmpeg like a clip, and the `-o` guard covers it.

## 6. Failure modes

- **A music file ffmpeg cannot read, or with no sound:** refused before
  anything is made (§ 4.6).
- **A music file whose length ffprobe cannot tell:** the loop `size` cannot
  be set, so it is refused, naming the file.
- **Long silence inside the music file:** it pulls `mean_volume` down, so the
  normalised music sounds louder than the level suggests. README says the
  level is an average over the whole file.
- **The `volumedetect` pass takes too long** on a very long file: the run
  stops with a message, as `make_film` does when ffmpeg overruns.
- **The mix clips:** the full-scale note (§ 4.5); the film is still made.
- **A clip whose sound stream starts later than its picture** in its own
  file: not measured; § 14.
- **A sound stream ffmpeg reads but cannot resample** (an exotic layout):
  ffmpeg fails and `make_film` reports its last lines, as for a picture.

## 7. Tests

All in `ci.sh`'s finishing group, so `./ci.sh --finishing` runs them, they
need no display and no sound server, and they run on GitHub too. Every
fixture is generated with `lavfi`, as the group's existing inputs are.

- INV-1: `assert_finished` gains the number of sound streams it expects,
  and "join --no-sound writes no sound track". `fin_s2`, which today checks
  that `A.mp4`'s sound is dropped, checks instead that it is kept, in
  INV-3's shape.
- INV-2, INV-3: "a clip's sound stays in step through cuts, cards and
  crossfades".
- INV-4: "a scene's fades fade its sound".
- INV-5: "sound off and volume change one clip's sound".
- INV-6, INV-7: "music averages the level asked, or takes it as a gain".
- INV-8: "music repeats to fill the film and fades in and out".
- INV-9: "a level line changes the music for its stretch".
- INV-10: "music is kept off full scale, and a clipping film gets a note".
- INV-11: "edit refuses a bad music, level, sound or volume word".
- INV-12: "a shortcut's music is the script's music".
- INV-13: "music under a long and a short film both end".

Each is seen to fail first: INV-1 by mapping a sound track always, INV-2 by
dropping the padding and by joining with `concat`, INV-4 by dropping the
sound fades, INV-5 by ignoring `volume`, INV-6 by dropping the gain, INV-7
by normalising anyway, INV-8 by dropping `aloop`, INV-9 by ignoring `level`
lines, INV-10 by dropping the cap, INV-11 by removing one check, INV-12 by
mapping `--music-fade-in` to `fade-out`, INV-3 by encoding at 44100 Hz
(dropping the sound's final trim does not fail it: the output's `-t` still
ends the sound within half a frame of the picture). INV-13 has no single mutant that fails it (§ 10). INV-12's MD5
comparison rests on AAC encoding being repeatable: two encodes of one
input gave one MD5, measured 2026-10-11.

## 8. Alternatives considered (and rejected)

- **Music that dips by itself under the app's sound** (side-chain
  compression). Offered; the user chose control by the caller instead
  (§ 3). It also pumps audibly when tuned badly.
- **A whole-film loudness target** (`loudnorm` to, say, -14 LUFS), and
  **evening out each clip's sound.** Offered as normalising options; not
  chosen (§ 3).
- **A fixed gain cut instead of measuring the music.** The same level would
  sound different for every file; measuring is one extra read of the file.
- **`-stream_loop -1` on the music input.** An input with no end; banned
  with the picture's demuxer loops.
- **`amix` with its default `normalize`.** Halves both inputs, so neither
  sits at the level the caller set.
- **Times for `level` lines in the music file's own time.** The caller
  places changes against what happens on screen, and `edit`'s plan prints
  film times.

## 9. Out of scope

- Music for part of a film, more than one music track, a voice-over track,
  and starting the music partway into its file — tracked by DEMO-0156, the
  editor's sound work.
- A sound placed at a chosen moment, such as a click — tracked by
  DEMO-0186; it mixes into the same `amix`.
- Changing a level by itself in response to other sound — rejected (§ 8).
- `normalise`, `level` lines and a clip's `volume` on the shortcuts —
  deferred; not yet queued. The script has them.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh finishing: `assert_finished`'s sound-stream count, and "join --no-sound writes no sound track" |
| INV-2 | ci.sh "a clip's sound stays in step through cuts, cards and crossfades" |
| INV-3 | ci.sh, inside INV-2's step |
| INV-4 | ci.sh "a scene's fades fade its sound" |
| INV-5 | ci.sh "sound off and volume change one clip's sound" |
| INV-6 | ci.sh "music averages the level asked, or takes it as a gain" |
| INV-7 | ci.sh, the same step |
| INV-8 | ci.sh "music repeats to fill the film and fades in and out" |
| INV-9 | ci.sh "a level line changes the music for its stretch" |
| INV-10 | ci.sh "music is kept off full scale, and a clipping film gets a note" |
| INV-11 | ci.sh "edit refuses a bad music, level, sound or volume word". Partial: one script per listed error; an error not in § 4.6 is unchecked |
| INV-12 | ci.sh "a shortcut's music is the script's music". Partial: `join` is compared; `trim` is run once, and `caption` and `card` share the option code but are not compared |
| INV-13 | ci.sh "music under a long and a short film both end". Partial: the bounds cover each other, so one removed alone may pass |
| Every message through `tr` | Partial: ci.sh `translation: nothing translated at import time` (DEMO-0060 INV-15) catches a message translated at import; a message never passed through `tr` is caught by review only |
| Script words stay English | **nothing** — DEMO-0060 § 4.1 states it; no check reads the parser |

## 11. Cross-doc impact

- `README.md`: § What you get (music lands; a finished film keeps sound);
  § Finishing a recording (the silent `.mp4` bullet, the new script words,
  the shortcuts' options); § `--audio` (its last bullet); § What it will
  never do, whose list of what finishing may do gains "keep a clip's sound,
  and lay one music track under a film at levels the script sets". That
  last is the scope change, made from the decisions this spec's gate
  reviews, as DEMO-0104 was made from DEMO-0106's.
- `CLAUDE.md` § Scope ceiling: the finishing list gains the same, and the
  sound paragraph's "Music added to a film is DEMO-0177" becomes a pointer
  to this spec.
- `.claude/rules/finishing-commands.md`: "Every stream in the filter graph
  must end" names the sound bounds (`atrim` after `aloop`, `anullsrc`'s
  duration), and the `amix` `normalize=0` trap.
- `CHANGELOG.md`; the `po/` template and catalogs (new messages,
  DEMO-0060); the manual page and tab completion where they list options.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0177-film-music-loop-log.md`.

## 13. Resource cost

- **Memory:** `aloop` holds at most the music file's decoded samples, and
  runs only when the file is shorter than the film: 8 bytes a sample frame
  at 48000 Hz stereo float, so about 23 MB a minute of film. `memory_cap`
  still bounds the whole ffmpeg.
- **Time:** one `volumedetect` read of the music file before the film is
  made, and the sound's encode beside the picture's.
- **Dependencies:** none new. `aloop`, `amix`, `acrossfade`, `afade`,
  `anullsrc`, `apad`, `atrim`, `volume` and `volumedetect` are ffmpeg's own
  filters, and AAC is its own encoder.

## 14. Open questions

- **A clip whose sound stream starts later than its picture in its own
  file.** demoreel's own recordings start both at 0 (DEMO-0106 INV-6).
  Another file may carry an offset that `asetpts=PTS-STARTPTS` would throw
  away. The builder measures it with an `-itsoffset` fixture and, if the
  sound moves, keeps the offset (`aresample=async=1:first_pts=0` is the
  candidate).
- **`volume` with `eval=frame` steps once per sound frame** (1024 samples,
  about 21 ms, for AAC input). Whether that is audible on a slide is not
  measured; a faster `ramp` makes larger steps.
