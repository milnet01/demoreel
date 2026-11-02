<!-- ants-spec-format: 1 -->
# DEMO-0285 — A film scene that plays several videos as side-by-side slices, frame for frame

**Status:** accepted (2026-11-02).
**Kind:** feature.
**Source:** ROADMAP DEMO-0285 (peer-request-2026-10-30, APHW-0030; the DOOM Ants trailer).
**Pairs with:** DEMO-0286 (the same scope lift).

Layman: a film can show the same moment from several recordings next to each other, split by borders, and slide along to other recordings mid-scene.

## 1. Goal

An `edit` script gains a `split` scene. It plays two or more videos of one size,
rate and frame count at once, frame N of each in frame N of the film. Each video
is one vertical slice of the frame, with a border between slices and a label on
each. A `slide` line moves the row of slices along, eased, at a time the script
names. A script with no `split` line makes exactly the film it makes today.

## 2. Problem

1. The DOOM Ants trailer compares five renderers of one recording. Nothing in
   demoreel can do that: `scene_graph` turns one clip into one scene, and
   README § What it will never do ruled two clips on screen outside a transition
   until this item's scope lift.
2. The website session draws it with its own program,
   `/mnt/Games/Trailers/work/doom-ants-trailer/split_sample.py` (scratch outside
   any repository). That reads raw frames into Python with numpy and Pillow, and
   demoreel's finishing commands promise `ffmpeg` and nothing new (README
   § Finishing a recording).
3. The comparison is only honest if the frames match. A slice one frame late
   shows a difference the renderers did not make, and nothing in the picture says
   so. `split_sample.py` keeps them matched by reading one frame from each file in
   turn. An ffmpeg graph pairs frames by timestamp unless told otherwise.

## 3. Scope decisions (agreed with the user)

- **Take it, after DEMO-0094 and before DEMO-0095, through a scope lift** (the
  user, 2026-10-30). The lift is in README § What it will never do and
  `CLAUDE.md` § Scope ceiling.
- **The request's list is the scope** (ROADMAP DEMO-0285): N videos, frame N of
  each in one frame; refuse inputs differing in size, rate or frame count; a
  chosen part of each; a timed eased slide between sets of slices; borders; a
  label per slice; sound lines as now; five at 1080p and 60 a second within
  memory.
- **One departure from the request, the author's call for the review to test: a
  label too wide for its slice is refused, not clipped.** Clipping cuts words off
  without saying so, and README refuses a too-wide text for that reason. A label
  that fits is still cut by the frame's edge as its slice slides off.

Every other choice below follows from § 2 and is reviewed as design.

## 4. Design

### 4.1 The script

```
split from 2 to 17 show 3 crossfade 0.5
  slice scene1-classic.mp4 label "Classic"
  slice scene1-solid-raster.mp4 label "Solid, rasterised"
  slice scene1-solid-rt.mp4 label "Solid, ray traced" centre 40
  slice scene1-ultra-raster.mp4 label "Ultra, rasterised"
  slice scene1-ultra-rt.mp4 label "Ultra, ray traced" size 3
  slide 2 at 7 over 1.4
  text "Same frame, five renderers" at bottom band off
  sound whoosh.wav at 7
```

- **`split`** starts a scene. It takes `from`, `to`, `fade-in`, `fade-out`,
  `fade-at`, `fade-length` and `crossfade` as a clip does, and `show`. It takes no
  file. `from` and `to` apply to every slice, in the videos' own time.
- **`show N`** is how many slices fill the frame, from 1 to the number of slices.
  It defaults to the number of slices.
- **`slice FILE`** on its own line, under a `split`, adds a video. There are 2 to
  `SPLIT_MOST` (8) of them, and the order written is the order left to right.
  It takes:
  - `label "WORDS"` — one line. Without it the slice has no label.
  - `size 3` — the label's height, a percentage of the frame's, as a text's
    `size` is. It defaults to `SPLIT_LABEL` (4.2).
  - `centre 40` — the point of the video the slice is centred on, in percent
    across. It defaults to 50, so every slice shows the same part of its video.
- **`slide N`** on its own line, under a `split`, moves the row until slice N is
  first on the left. It takes `at`, required, a time in the videos' own time, and
  `over`, the seconds it takes, `SPLIT_SLIDE` (1.4) unless given. A scene may have
  any number of them. They are written in time order and may not overlap. N must
  leave a full set on screen, so `N + show - 1` is at most the number of slices,
  and must differ from the slice already first. The whole slide must fall inside
  the scene.
- **`text`** and **`sound`** lines work as on a clip: `check_texts` gives a text
  on a `split` a clip's band and place, and times are the videos' own
  (`scene_time`). A text stays where it is while the row slides.
- A scene takes none of `window`, `background`, `push`, `speed`, `hold`, `sound`
  or `volume` on its `split` line, and no `zoom` line.
- All of this goes in `SCENE_WORDS` and `parse_script`, so an error names its line
  as every other word's does. A `slice` or `slide` line with no `split` above it is
  refused, as a `zoom` with no clip above it is.
- **Script only.** No shortcut builds a split, as no shortcut takes `font`.

### 4.2 What is refused before anything is made

`check_scene` reads each slice with `probe`, which goes through `probe_input`. The
scene then follows a clip's path for `from` and `to`, using its first slice. A
slice is refused, naming the line and both files, when it differs from the first:

- in width or height;
- in rate, by more than 0.1%;
- in frame count. `probe` gains `frames`, from `nb_frames`, or `None` when the file's
  index does not say. If either file's is `None`, the two durations must agree
  within half a frame.

The shape check a clip has applies to the first slice, word for word. `film_shape`
counts a `split`'s first slice as it counts a first clip, so a film's size and rate
can come from it. `make_film` passes every slice to `finishing_output`, so `-o`
cannot be one of them.

### 4.3 Sizes

```
slice_w = 2 * ceil(width / show / 2)     # every slice the same width, in the film's pixels
crop_w  = max(2, even(slice_w * file_w / width)) # the part of the video it shows
crop_x  = even(clamp(centre% * file_w - crop_w / 2, 0, file_w - crop_w))
```

A row of `show` slices can be up to `2 * show` pixels wider than the frame. The
last slice on screen loses them at its right edge. So a set always fills the frame,
and every slide stops on a slice's edge.

### 4.4 The graph

`scene_graph` gets a branch for `split`, in the shape below. Each slice is read by
`clip_input`'s arguments, with its own path and its own `-ss` and `-t`: the first
slice's frame numbers over that slice's rate. § 4.2 lets rates differ by 0.1%, and
one seek time would land them frames apart.

```
[i:v]settb=1/first_rate,setpts=N,crop=crop_w:file_h:crop_x:0,scale=slice_w:height,
     setsar=1,format=yuv420p,drawtext(label)[s<number>_i]  # one per slice
[s<number>_0]...[s<number>_n]hstack=inputs=n:shortest=1,tpad=stop_mode=clone:stop=1,fps=film_rate,
     drawbox(borders),crop=width:height:x=PAN:y=0,{shape}{tail}[v<number>]
```

- **`settb=1/first_rate,setpts=N` is what makes it frame for frame** (§ 2.3): each
  frame's time is made from its number, in one time base, so `hstack` pairs frame N
  with frame N whatever the files' timestamps say. `first_rate` is the first slice's
  rate, on every slice. Do not change it to the `PTS-STARTPTS` a clip uses. Do not
  drop the `settb`: `setpts=N/(70*TB)` rounds differently in each file's time base,
  and files of 1/15360 and 1/90000 paired their last frame wrongly (ffmpeg 6.1.1 and
  9.0.2, 2026-11-02).
- **`shortest=1` is what ends the scene on a short slice** (§ 6). By default
  `hstack` holds a short input's last frame to the end (measured on both, the same day).
- **`tpad` gives `fps` a frame past the last, and `{shape}`'s `trim` takes it off.**
  `hstack` ends at its last frame's own time, and `fps` then drops that frame: 29 of
  30 on 6.1.1, and 359 of 360 from 70 to 60 a second on both before the `settb`. With
  the `tpad`, each of 70 to 30, 60, 70 and 100 and 10 to 7, 10 and 25 came out whole on
  both, and a 10-frame slice beside a 30-frame one still made 10.
- **One `fps`, after the `hstack`,** so a change of rate drops the same frame from
  every slice. A 70 a second source in a 60 a second film drops one in seven, as
  `split_sample.py` does.
- **A label is drawn on its slice before the `hstack`.** So it is cut at its
  slice's edges and goes with it when the row slides. Bold white on a box of
  `black@0.84`, centred across the slice, its top `SPLIT_LABEL_TOP` (0.052) of the
  frame's height down, from `split_sample.py`'s 75 px at 1440. `text_size` measures
  it, and one wider than the slice, less twice the border, is refused.
- **`PAN` is a slice's width times a number that eases between slide targets**,
  smoothstep (`p*p*(3-2*p)`) as `split_sample.py`'s `smooth`, written as nested
  `if`s on `t` and rounded down to an even number. `crop` works it out each frame.
- **A border is white with a dark edge at each side**, centred where two slices meet:
  white `max(2, even(0.003125 * width))` wide and each dark edge
  `max(1, round(0.00078 * width))`, from `split_sample.py`'s 8 and 2 at 2560.
  One look serves a trailer. A border is drawn in the row, so it moves with its
  slices. Its `enable` turns it off while the row rests with it just before the first
  slice shown or just after the last, where part of it would show as a stripe. The test
  is by slice, not position: a row can overrun the frame by a few pixels (§ 4.3).
- **A slice's sound is not read.** `keeps_sound` already answers no for anything
  but a clip, so the scene is silent under its `sound` lines, the film's music and
  whatever it crossfades with.
- Every chain ends: `{shape}` holds `trim=end_frame`, as on every scene.

**Measured, as a prototype** (2026-11-02, ffmpeg 9.0.2, machine load near 30; five
of `/mnt/Games/Trailers/incoming/doom-ants/scene1-*.mp4`, each 2560x1440 at 70, for
6 s, `show 3` at 1920x1080 at 60, one slide, x264 `medium`): 360 frames, 1.82 GB peak
resident memory, 29 s wall. The picture was checked by eye. ffmpeg 6.1.1 in
`ci.sh`'s Ubuntu image lists every filter used (`ffmpeg -filters`, 2026-11-02). Of the
graph, only the part up to `fps` has been run there.

### 4.5 A piece of the film

`PIECE_SCENES` counts scenes. Five decoders are worth more than one scene, so
`film_pieces` weighs them: a clip or a card is 1, a `split` is its number of
slices. A piece closes once its weight reaches `PIECE_SCENES - 1`, and a `split`
that would take it past that starts a new one. With no `split`, every
weight is 1 and the pieces come out as they do today. A crossfade over a join is
still drawn whole in one piece, as `.claude/rules/finishing-commands.md` requires,
so two crossfading splits share an ffmpeg.

### 4.6 The plan

`make_film` prints `scene 2: a split of 5 videos, 12.000 to 27.000`, a new message
through `tr`.

## 5. Invariants

Fixtures are `ci.sh`'s finishing ones (`px`, `px bbox`, `expect_refused`). Flat
sources `C1` to `C5` are five flat colours, 320x240 at 10 a second for 10 s, made
in the step. None of these clauses can run until the code exists. Each names the
rule its fixture isolates.

- **INV-1** — Frame N of the film holds frame N of every slice, whatever the files'
  timestamps say.
  *Test:* ci.sh finishing: `R.mp4` is 30 frames at 10 a second whose brightness is
  `10+8*n`. `J.mp4` is `R.mp4` copied with `-c copy -bsf:v
  setts=ts='PTS+mod(N,2)*lt(N,29)*0.06/TB'`, so its rate, count and length pass § 4.2
  (`10/1`, 30, 3.000 by `ffprobe`). `split` with `slice R.mp4`, `slice J.mp4`: at frames
  5, 15 and 25 `px` in each slice's middle agree within 6. With `-r 7` they agree too,
  at frames 3 and 15. The fixture isolates the `setpts`: under `PTS-STARTPTS` those
  three frames differ by 9 or more, and under a shift of 0.04 s by none (measured
  2026-11-02).
  Two more `split`s, with a `px` at each slice's middle: 70 frames at 70 a second that
  alternate dark and light, made with `-video_track_timescale` 15360 and 90000, whose
  last frames agree; and 1000 frames of brightness `10+8*(n%30)`, at 10 and at 10.009 a
  second, with `from 91`, whose first frames agree. One seek time for both starts them a
  frame apart.
  *Breaks when:* a slice is paired by time or in its own time base, each slice gets its
  own `fps`, or every slice takes the first slice's seek time.

- **INV-2** — A slice differing in size, rate or frame count is refused before
  ffmpeg starts, and the message names the line and both files.
  *Test:* ci.sh finishing: each by `expect_refused`, with nothing at `-o`, beside a
  slice of 100 frames at 320x240 at 10 a second: 100 frames at 640x480; 100 frames at
  20 a second; 99 frames at 10 a second. The last again with both as `.mkv`, whose
  index has no frame count, so the length check refuses it. Each fixture differs in
  one property, so only that property's check can refuse.
  *Breaks when:* a check is missing, or trusts `nb_frames` when a file lacks it.

- **INV-3** — A slice shows the part its `centre` names, by default the middle,
  fitted to the film's size and never stretched.
  *Test:* ci.sh finishing: `Q.mp4` is 640x480, four vertical stripes of red, green,
  blue and white. `edit -s 320x240` with `split show 2`, `slice Q.mp4`, `slice Q.mp4
  centre 75`, each `px` probed: the first slice (160 wide, showing 320 of Q's 640)
  is green up to x=80 then blue, as the middle half is; the second is blue from x=160
  to x=240, then white. `centre 0` is held at the edge by the clamp and shows red then
  green; `centre 100` is held at the other and matches `centre 75`.
  *Breaks when:* `crop_x` ignores `centre`, or is not clamped, or the crop is in the
  film's pixels and not the file's.

- **INV-4** — The row is still until a slide's `at`, moves eased, and stops with the
  named slice first.
  *Test:* ci.sh finishing: `split show 3` with `C1` to `C5` and `slide 3 at 2 over 2`.
  `slice_w` is 108 and the end pan 216. Frame 19: `px` at x=54 is C1 and at x=270 is
  C3. Frame 25, a quarter through, `p` .25, eases to 0.156: the pan is 32 or 34, so
  x=60 is still C1; a linear slide has panned 54 and shows C2 there. Frame 30: the
  pan is 108, so x=54 is C2. Frame 41 on: x=54 is C3, x=162 is C4 and x=270 is C5.
  *Breaks when:* the slide starts at the wrong time, is linear, or stops off a slice's
  edge.

- **INV-5** — A border lies between each pair of slices and none on the frame's edge
  at rest.
  *Test:* ci.sh finishing: as INV-4. `px` reads a 5-pixel block, so a border's columns
  are read by `px find`. Frame 19: columns x=107 and x=108 are within 60 of white, and
  x=106 and x=109 are `dark:60`. Frame 45: `px` at x=0 and x=319 are C3 and C5, not white,
  which a border on the edge fails. Frame 30 (moving): the border between C2 and C3 is
  white in those same columns. `split show 2` of `C1` to `C3`, whose border after the last
  slice shown is centred on x=320: at frame 5, `px find` over columns x=318 and x=319 finds
  nothing white or dark.
  *Breaks when:* the border is left out, or its `enable` is, or is drawn after the
  `crop` and so does not move.

- **INV-6** — A label is drawn on its slice and moves with it. One too wide for its
  slice is refused.
  *Test:* ci.sh finishing: as INV-4, with `label "X"` on slice 3 only. Frame 19: `px`
  at its slice's middle (270, at the label's height) differs from C3, and at (54, the
  same height) is C1. Frame 45: the label's mark is at x=54 and x=270 is C5. A label
  of 20 `X`s is refused by `expect_refused`, naming its line, with nothing at `-o`.
  The same label with `size 2` is made, so the refusal comes from the width.
  *Breaks when:* the label is drawn after the `crop`, or the width check is missing.

- **INV-7** — A `text` stays where it is while the row slides, and a `sound` lands
  where a clip's would.
  *Test:* ci.sh finishing: as INV-4, with `from 1`, `text "T" at top band off colour
  #FF00FF`, `text "B"` and `sound tone.wav at 3`. `px find` of that colour over the top
  strip gives one box in the same place at frames 10 and 40, whatever slices lie under
  it. `B`, with no `at` or `band`, has a clip's band: `px` at the bottom of the frame is
  darker than C1 and than C3. The plan prints the sound at 2.000, and the film's sound
  is silent up to it (`volumedetect`, as DEMO-0177's steps read it).
  *Breaks when:* the tail is put before the `crop`, a `split` takes a card's text
  defaults, or times are counted from the film.

- **INV-8** — A split scene ends where the plan says, in a film with cuts and a
  crossfade, under a memory limit.
  *Test:* ci.sh finishing: `clip A.mp4`, a three-slice `split`, a second `split` with
  `crossfade 0.5`, so both are in one ffmpeg, then `clip B.mp4 crossfade 0.5`, under
  `ulimit -v` as DEMO-0183's INV-6: made, its frame count the
  plan's. Partial, as that clause is: the `trim`, the output's `-t` and `hstack` each
  bound the others, so removing one alone may not fail it.
  *Breaks when:* a stream never ends and something waits on it.

- **INV-9** — A split takes its weight in `film_pieces`, and a film without one is
  cut as before.
  *Test:* ci.sh finishing: imported from the script, as `ci.sh` imports
  `BLANK_THRESHOLD`: `film_pieces` on two clips, a five-slice split and a clip gives
  the split a piece of its own; on eight clips, the pieces today's code gives, written
  in the step as a literal. The existing step comparing a film in pieces with the same
  film in one runs once more with a split in it.
  *Breaks when:* weights are not applied, or they move a film with no split.

- **INV-10** — A slice's file is only ever read as a video, and `-o` cannot be one.
  This is a trust boundary: a script names the files, and a slice reaches ffmpeg as a
  clip does.
  *Test:* ci.sh finishing: `expect_refused` on `slice list.m3u8` (`refuse_a_list`) and on
  `-o` naming the third slice ("also a file this command reads"). A `split` of two slices
  of one file, for each of `12:30:05.mp4`, `-report.mp4` and `concat:short.mp4|short.mp4`,
  the names DEMO-0094's step copies a video to: made, with that file's frames.
  *Breaks when:* a slice is read without `probe_input` and `media_input`, or
  `finishing_output` is not told about it.

- **INV-11** — A wrong word stops the run before ffmpeg starts, and the message names
  the line.
  *Test:* ci.sh finishing: each by `expect_refused` naming its line: one slice; nine
  slices; `show 0`; `show` above the slices; `centre 101`; `slice` and `slide` with no
  `split` above; `slide` with no `at`; a slide past the last set; a slide to the slice
  already first; two overlapping slides; slides out of order; a slide outside the
  scene; `window 50` and `speed 2` on the `split` line; a `zoom` line under it.
  *Breaks when:* any of them is accepted, or reaches ffmpeg.

- **INV-12** — A script with no `split` makes the film it made before.
  *Test:* ci.sh finishing: every existing finishing step passes unchanged.
  *Breaks when:* a change to the shared path moves a scene that is not a split.

- **INV-13** — Five videos at 1080p and 60 a second stay within the measured memory.
  *Test:* `./ci.sh --perf`, given a row for the case, against
  `docs/perf-baseline.tsv`. By hand before a release; the gate does not run it.
  *Breaks when:* a change makes the graph hold frames per slice, which fails over 1.5
  times the baseline.

## 6. Failure modes

- **A source whose timestamps are uneven, with `from`.** `setpts` pairs by number from
  where each file's read began, and `-ss` finds that place by time. So `from` above
  zero on uneven sources can start them on different frames, and nothing says so. Even
  sources are unaffected, and every recording in the request is even (each step between
  `ffprobe`'s `packet=pts_time` is 1/70, 2026-11-02). § Out of scope carries reading by
  number.
- **A file whose index lies about its frame count.** One that ends early ends the
  `hstack`, and `run_film_ffmpeg`'s frame count fails the run with ffmpeg's last lines.
- **Very large sources.** Memory grows with slices and with the sources' sizes.
  `memory_cap` stops the ffmpeg at half the machine's memory, with its own message.
- **Sources on `/tmp`.** It is RAM on this machine. README tells the caller; demoreel
  does not check it.
- **An ffmpeg without a filter it needs.** ffmpeg fails the run, and `make_film` shows
  its last lines, as for any filter it lacks.

## 7. Tests

All in `ci.sh`'s finishing steps, so `./ci.sh --finishing` runs them, except INV-13.

- INV-1: "a split scene is frame for frame".
- INV-2: "a split refuses slices that differ".
- INV-3: "a slice shows the part its centre names".
- INV-4, INV-5: "a split's row slides, eased, with its borders".
- INV-6: "a slice's label moves with it".
- INV-7: "a split's text stays and its sound lands".
- INV-8: "a split scene ends where the plan says".
- INV-9: "a split takes its weight in the pieces".
- INV-10: "a slice is read as a video and only as one".
- INV-11: "edit refuses a bad split".
- INV-12: the existing finishing steps, unchanged.
- INV-13: a new row in `perf_measure`, read by `./ci.sh --perf`.

Each new step is seen to fail first: INV-1 by `PTS-STARTPTS`, by dropping `settb` and by
one seek time, INV-2 and INV-11 by removing one check at a time, INV-3 by ignoring
`centre`, INV-4 by a linear pan, INV-5 by dropping `enable`, INV-6 by drawing after the
`crop`, INV-9 by a weight of 1.

## 8. Alternatives considered (and rejected)

- **Fixed picture and moving borders, as `split_sample.py`'s default and SAMPLE-A:**
  each slice is its own part of the frame, and the borders sway. The website chose the
  other, "same view", for its trailer (`build_cut.py` passes `--centre`). Moving a
  crop per slice with time is also a harder graph, and `centre` gives the same still
  picture.
- **`overlay` per slice, at a moving `x`.** Five full-size overlays cost more than one
  `crop` of a row, and each needs the label clipped by hand.
- **Slices of chosen, unequal widths.** No request needs one, and a slide then has no
  simple distance.
- **Reading frames in Python, as the sample does.** Not `ffmpeg` and nothing new, and a
  copy of each frame through this program's memory.
- **A slice's own sound.** The request asks for sound lines as now.
- **Knobs for a border's colour and width, and the label's font and box.** One look
  serves a trailer; a knob is added when a caller needs it.
- **A `start` word for the first set.** Writing the slices in the wanted order does it.

## 9. Out of scope

- Reading `from` by frame number, for sources with uneven timestamps — deferred; not
  yet queued.
- Horizontal slices, or a grid — deferred; not yet queued.
- A slice's own crop by rectangle, as a word — tracked by DEMO-0151.
- `split` on a shortcut — deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh "a split scene is frame for frame" |
| INV-2 | ci.sh "a split refuses slices that differ" |
| INV-3 | ci.sh "a slice shows the part its centre names" |
| INV-4 | ci.sh "a split's row slides, eased, with its borders" |
| INV-5 | the same step |
| INV-6 | ci.sh "a slice's label moves with it" |
| INV-7 | ci.sh "a split's text stays and its sound lands" |
| INV-8 | **`Partial:`** ci.sh "a split scene ends where the plan says"; § 5 says what removing one bound does |
| INV-9 | ci.sh "a split takes its weight in the pieces" |
| INV-10 | ci.sh "a slice is read as a video and only as one" |
| INV-11 | ci.sh "edit refuses a bad split" |
| INV-12 | every existing finishing step |
| INV-13 | `./ci.sh --perf`, by hand before a release; the gate does not run it |
| No new program | **nothing** automatic; code review. README § Finishing a recording promises it |
| Uneven sources with `from` start together | **nothing**: § 6 records the limit |
| New messages go through `tr` at run time | ci.sh "translation: nothing translated at import time" (DEMO-0060 INV-15), and "translation: the template matches the source", refreshed with `./ci.sh --pot` |

## 11. Cross-doc impact

- `README.md` § `edit`: a film from a script — the `split` scene; § Finishing a
  recording's sources on `/tmp` note.
- `demoreel.1` — the scene and its lines.
- `.claude/rules/finishing-commands.md` — frame for frame by number, and the weight in
  `film_pieces`.
- `docs/perf-baseline.tsv` — the new row, through `./ci.sh --perf-baseline`.
- `CHANGELOG.md` — one bullet.
- `po/` — through `./ci.sh --pot` and `./ci.sh --add-message`.
- `record-demo` skill — feedback to `claude-config`, which owns it.
- The website session, `ants-projects-hub-website`: told when split-screen is ready to
  try, and of the label refusal in § 3.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0285-split-scene-loop-log.md`.

## 13. Resource cost

No new dependency and no state kept. Memory grows with slices and the sources' size:
1.82 GB measured for five at 2560x1440 (§ 4.4), and held under `memory_cap`. Every
slice decodes for the whole scene, on screen or not.
