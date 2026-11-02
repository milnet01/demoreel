<!-- ants-spec-format: 1 -->
# DEMO-0286 — Full-frame zoom, text at any position, click rings and drawn backgrounds

**Status:** spec draft (2026-11-02).
**Kind:** feature.
**Source:** ROADMAP DEMO-0286 (peer-request-2026-10-30, APHW-0030; the website's `tools/trailer.py`).
**Pairs with:** DEMO-0285 (the same scope lift).

Layman: a film script can zoom a clip that fills the frame, put text anywhere, show a ring where the pointer clicked, and use five drawn backgrounds as well as plain colours.

## 1. Goal

Four additions to `edit` scripts. A `zoom` line works on a clip with no window. A
text takes `x` and `y`. A `ring` line draws a growing, fading ring at a moment and a
point of a clip. `background` takes five names as well as colours: `record`, `log`,
`grid`, `paper` and `felt`. A script using none of them makes the film it makes today.

## 2. Problem

1. `check_scene` refuses a `zoom` on a clip with no window, so a zoom on a whole
   frame needs a second program. `/mnt/Games/Trailers/tools/trailer.py` is that
   program (`scene_clip`, its `zoom`).
2. `text_filters` centres every text across the frame, and `place_stack` gives it one
   of three heights. `trailer.py` places text at any point (`Scene.text`, its `cx`
   and `y`).
3. A viewer with the sound off cannot see a click. `trailer.py` draws a ring there
   (`ring_png`, `scene_clip`'s `rings`). README ruled out cursor highlighting until
   this item's scope lift.
4. `trailer.py` has backgrounds for an app's kind of project (`BACKGROUND`, `THEMES`).
   It draws them with ImageMagick and repeats them with `-loop 1`. demoreel can use
   neither: README § Finishing a recording promises `ffmpeg` and nothing new, and
   `.claude/rules/finishing-commands.md` forbids looping a picture at the demuxer.

## 3. Scope decisions (agreed with the user)

- **All four, in the same scope lift as DEMO-0285; crop stays DEMO-0151** (the user,
  2026-10-30). The lift is in README § What it will never do and `CLAUDE.md`
  § Scope ceiling, which now names a ring a script places.
- **"Themed backgrounds" means the backgrounds, and not a `theme` word**: the author's
  call for the review to test. A `THEMES` entry in `trailer.py` also sets fonts, text
  colours and transitions, and a script already says each of those on its own line. A
  word setting them together would be a settings bundle, and README rules out profiles.
- **A ring is placed by the script and nothing else.** Nothing watches a pointer, and
  `record` writes nothing for `edit` to read. That is what keeps it on the right side of
  "nothing follows or highlights the cursor".

Every other choice below follows from § 2 and is reviewed as design.

## 4. Design

### 4.1 Full-frame zoom

`zoom` keeps its words, range and times (README § `edit`). `check_scene` stops refusing
it with no window; `push` is still refused, as a window is what it grows. In
`scene_graph`, a clip with no window and a zoom becomes:

```
[i:v]setpts={pts},fps={fps},{zoom_filters(scene, width, height, rate)},{shape}{tail}[v]
```

`zoom_filters` is unchanged, and a text and a fade stay outside the zoom as in a window.
The clip's shape check still applies. DEMO-0183 § 9's item naming a zoom inside a
window stays true.

### 4.2 Text at any position

```
text "Bottom left" x 25 y 80
```

- `x` and `y` are percentages, 0 to 100, of the frame's width and height. They name
  where the text's middle goes. They are given together or not at all.
- Such a text takes no `at`, and no `band on`; it has no band unless asked, and asking
  is refused. A band runs across the frame, which is not what a place on it means.
- It takes `size`, `font`, `colour`, `outline`, `shadow`, `from`, `to`, `fade-in`,
  `fade-out` and `slide-in` as any text does.
- It stands alone. `text_stacks` passes it by, so it is in no stack, moves no other
  line, and takes nothing from `picture_room`. It lies over whatever is there, as a text
  in the middle does.
- It must fit: its box, as `text_size` measures it, wholly inside the frame. The existing
  width check runs first. Otherwise it is refused, naming its line.

In `text_filters`, `x={cx}-text_w/2`, and `top` is `round(y% * height) - fontsize // 2`,
which `slide-in` already rises to.

### 4.3 Click rings

```
clip demo.mp4 from 2 to 14
  ring 640 400 at 5.4
```

- **`ring X Y`** on its own line, under a clip, in the pixels of the clip's own file: the
  numbers given to `xdotool` when recording it. Each is inside the file's size. They are
  not percentages, and are not written `x` and `y`, so that a `zoom`'s meaning of those
  words does not read across.
- `at`, required, is a time in the clip's own file, as a `sound` line's is. It must fall
  in the clip's own frames. On a clip with a `hold` the whole half second must, since the
  hold would freeze the ring. A clip may have any number of rings.
- One look, from `trailer.py`'s `ring_png` on footage about 1080 high, as shares of the
  file's height: its diameter, to the line's middle, eases out over `RING_SECONDS` (0.5)
  from `RING_FROM` (0.03) to `RING_TO` (0.185) as `1-(1-p)^2`; a `#FDE047` line `RING_LINE`
  (0.00926) wide on a black edge at 75% and `RING_EDGE` (0.0157) wide, each at the ring's
  largest and thinning with it; and it fades out over the same half second.
- **It is drawn on the clip before anything scales it**, so it sits on the same point of
  the picture in a window, a zoom and at any `speed`.

Each ring is its own chain, drawn once with `geq`, repeated by `loop`, and cut to its
half second. It starts at its moment by its timestamps and leaves the graph when done:

```
color=...,format=rgba,geq=...,loop=loop=-1:size=1,trim=end_frame=RING_FRAMES,
    fade=out:st=0:d=0.5:alpha=1,scale=w=...:h=...:eval=frame,setpts=PTS+AT/TB[r]
[m][r]overlay=x=X-w/2:y=Y-h/2:eval=frame:eof_action=pass[m2]
```

The rings go between the clip's `setpts` and its `fps`, and `AT` is `scene_time`'s. After
the last ring comes `tpad=stop_mode=clone:stop=1`, and `{shape}`'s `trim` takes that frame
off. Without it, ffmpeg 6.1.1's `overlay` ends at its last frame's own time and `fps` drops
that frame: 29 of 30, as `scene_graph`'s comment on a window says, and with it 30 (ffmpeg
6.1.1 and 9.0.2, 2026-11-02).

So a ring costs only for its half second, and a scene's rings add up by their own length
and not the scene's. A ring running past its scene's end is cut there.

**Measured, as a prototype** (2026-11-02, ffmpeg 9.0.2, machine load near 30; a 1920x1080
clip at 30, 6 s, two rings and a zoom at 1600x1000, x264 `veryfast`): 180 frames, 704 MB
peak resident memory. Checked by eye: each ring at its point, under the zoom, gone when
due.

### 4.4 Drawn backgrounds

`background NAME` on a card or a windowed clip, where a colour goes today. Each is a
look from `trailer.py`'s `BACKGROUND`, in the colours its function draws, which some read
from the matching `THEMES` entry. All sizes follow the frame.

| Name | From | What it draws | Moves |
|---|---|---|---|
| `record` | `bg_record`, `studio` | gradient (`#b45309,#9d174d,#4c1d95,#0c0a09`, dark 0.36), a vinyl disc with grooves and a two-colour label low on the right, grain | the disc turns, 0.5 radians a second |
| `log` | `bg_log`, `terminal` | gradient (`#14532d,#064e3b,#0c4a6e,#020617`, dark 0.42), two columns of faint program output, scanlines | the output scrolls up |
| `grid` | `bg_grid`, `arcade` | `#0b0620` with a vignette, a striped sun at the horizon, a neon floor in perspective, scanlines | the floor runs towards you |
| `paper` | `bg_ruled`, `paper` | lined paper with a margin (`#fbf8f0` to `#efe9da`, lines `#c9d8ee`, margin `#ecb4b4`), lit from above, a little noise | nothing |
| `felt` | `bg_felt`, `table` | green baize, lit from the middle, a little noise | nothing |

- **Text with no band is white on all but `paper`, where it is near-black.** A small table
  beside the names, read by `text_filters`' `dark` test. Without it, the test reads a name
  as a colour.
- **`background_source` still returns one lavfi source**, now possibly a whole graph ending
  in `[out0]`, so `scene_graph` and `window_graph` do not change. Each picture is drawn once
  with `geq`, repeated with `loop`, and bounded by `trim=end_frame`, keeping both rules of
  `.claude/rules/finishing-commands.md`.
- **The same script makes the same film.** A gradient takes `seed` from the scene's number,
  as `background_source`'s does. `noise` needs none: with no `all_seed` it draws the same
  frames each run (`-f framemd5`, ffmpeg 6.1.1 and 9.0.2, 2026-11-02).
- `log`'s text is written once in the run's work folder. Its font is `fc-match`'s answer
  for `monospace`. It needs an ffmpeg that draws text, and `check_scene` says so through
  `TextUnavailable`, as a text does.
- **`check_scene`'s background refusal** adds the five names to its message.

**Dropped from `trailer.py`, to tell the website:** the card suits on `felt`, since drawing
them needs a font with those signs, and the sheen on `record`, which adds little.

**Measured, as a prototype** (2026-11-02, ffmpeg 9.0.2, machine load near 40; 6 s at
1600x1000 at 30, x264 `veryfast`, `log` scanlines drawn by `geq` on every frame, which
the build replaces by one frame looped): 

| Name | User CPU | Peak resident |
|---|---|---|
| `record` | 34 s | 641 MB |
| `log` | 41 s | 537 MB |
| `grid` | 22 s | 709 MB |
| `paper` | 4 s | 570 MB |
| `felt` | 4 s | 570 MB |

Checked by eye; all five read as their names. A `grid` whose floor had a line along the
master picture's edge smeared that line into a wedge, since `perspective` repeats an edge
outward; the floor's lines are offset from the edges to avoid it. ffmpeg 6.1.1 in `ci.sh`'s
Ubuntu image lists every filter used, and `eof_action` (`ffmpeg -filters`
and `-h filter=`, 2026-11-02); the graphs have not been run there.

## 5. Invariants

Fixtures are `ci.sh`'s finishing ones (`px`, `px bbox`, `expect_refused`). None of these
clauses can run until the code exists. Each names the rule its fixture isolates.

- **INV-1** — A zoom works on a clip with no window, closing in on its point.
  *Test:* ci.sh finishing: `Q.mp4` is 320x240 in four flat quarters. `clip Q.mp4` with
  `zoom 2 x 0 y 0 from 0 to 1`. Frame 0: `px` at the frame's four quarter points are the
  four colours. After 1 s, the view is the picture's top-left quarter, so all four
  probes are that quarter's colour. A caption on it in `colour #FF00FF`, a colour none of
  the quarters is, has the same box from `px find` at both frames, so the text is outside
  the zoom. Without a window `push 4` is still refused.
  *Breaks when:* the refusal stays, or the zoom is left out of the unwindowed path.

- **INV-2** — A text at `x` and `y` has its middle there.
  *Test:* ci.sh finishing: `card 2`, `text "XXXX" x 25 y 75 size 10`. `px bbox` against
  `#101418` has its centre at 0.25, 0.75, within 0.02. The fixture isolates the position:
  centred, as today, gives 0.5.
  *Breaks when:* `text_filters` keeps `(w-text_w)/2`, or `y` names the text's top.

- **INV-3** — Such a text moves no other line and takes no room.
  *Test:* ci.sh finishing: `card 2 P.png` with `text "A" at middle`, and again with a
  second text `text "B" x 50 y 5`. The picture's `px bbox` over its own area, and `A`'s,
  agree between the two within 0.01. A stack would shift `A`; `picture_room` would shrink
  the picture.
  *Breaks when:* a placed text reaches `text_stacks`.

- **INV-4** — A wrong place is refused before ffmpeg starts, naming the line.
  *Test:* ci.sh finishing: each by `expect_refused`: `x 50` with no `y`; `y 50` with no
  `x`; `x 101 y 50`; `x 50 y 50 at top`; `x 50 y 50 band on`; a wide text at `x 1 y 50`,
  which fits the width check and not the frame.
  *Breaks when:* any is accepted, or a text is drawn cut off by the frame.

- **INV-5** — A ring shows at its point and moment, then goes.
  *Test:* ci.sh finishing: `F.mp4` is flat `#808080`, 640x480 at 10 a second for 3 s,
  `clip F.mp4` with `ring 320 240 at 1`. At frame 12, `p` 0.4 and 0.64 eased, the diameter
  is `(0.03 + 0.155*0.64) * 480`, 62 px: `px` at (351, 240), on the line, has blue at least
  25 below its grey. Frame 9, before the moment, and frame 16, after the half second:
  within 10 of `#808080` there. The fixture is flat, so only a ring can move the probe.
  *Breaks when:* the moment or point is wrong.

- **INV-6** — A ring stays on its point of the picture through a window, a zoom and a speed.
  *Test:* ci.sh finishing: as INV-5 with `window 50` (`px bbox` gives the window; the
  probe is scaled by it); with `speed 2` and `at 2`, which lands at frame 10 and not 20; and
  on `Q.mp4` with a `zoom`, whose probe is worked from `zoom_filters`' own view. Each fails
  if the ring is drawn after the scaling.
  *Breaks when:* the ring goes in after `zoom_filters`, or `at` is read as the scene's time.

- **INV-7** — A wrong ring is refused before ffmpeg starts, naming the line.
  *Test:* ci.sh finishing: each by `expect_refused`: `ring 640 400` with no `at`; `ring 640`;
  `ring big 400 at 1`; a point outside the file; `at` outside the clip; `at` in its `hold`; `at`
  under half a second before the end of a clip with a `hold`; a `ring` under a card; and under
  a `split`, with words naming the ring, which whichever of this and DEMO-0285 is built second
  adds.
  *Breaks when:* any is accepted, or reaches ffmpeg.

- **INV-8** — Each named background draws its own picture, and those that should move, move.
  *Test:* ci.sh finishing: at 640x400, `card 3 background NAME` for each. None is flat
  (`frame_is_flat`, imported). `paper`: `px` at the top right has luma above 200. `felt`: at
  the middle green leads red and blue by at least 30. `record`, `log` and `grid`: frames 15 and
  60 differ by more than a noise allowance; `paper` and `felt`: they do not. A windowed clip
  takes each of them.
  *Breaks when:* a name falls through to a plain colour, or a moving one stands still.

- **INV-9** — The same script makes the same film.
  *Test:* ci.sh finishing: each named background twice: `-f framemd5` of the two films agree.
  The fixture isolates the seed: a gradient with no `seed` gives different frames, so `record`
  and `log` fail it.
  *Breaks when:* a gradient's seed is left out.

- **INV-10** — A band-less text is near-black on `paper` and white on the rest.
  *Test:* ci.sh finishing: `card 2 background paper`, and `felt`, each with a large `text`:
  `px` inside a letter is under 80 on `paper` and over 200 on `felt`.
  *Breaks when:* `text_filters`' `dark` test reads a name as a colour.

- **INV-11** — A drawn background ends where the plan says, in a film with cuts and a crossfade,
  under a memory limit.
  *Test:* ci.sh finishing: `card 2 background grid`, then `clip A.mp4 window 80 background
  record crossfade 0.5`, under `ulimit -v`, as DEMO-0183's INV-6: made, its frame count the
  plan's. Partial, as that clause is, for the same reason.
  *Breaks when:* a `loop` is left without its `trim`, and something waits on it.

- **INV-12** — A wrong name is refused before ffmpeg starts, naming the line and the names.
  *Test:* ci.sh finishing: `background stripes` on a card, and `background record` on a clip with
  no window, by `expect_refused`.
  *Breaks when:* it reaches ffmpeg as a colour.

- **INV-13** — A script using none of these makes the film it made before.
  *Test:* ci.sh finishing: every existing finishing step passes, with one case removed: the
  bad-push-and-zoom step's `clip A.mp4` with `zoom 2`, which this item makes legal.
  *Breaks when:* a change to the shared path moves another scene.

## 6. Failure modes

- **A full-frame zoom on a large clip.** `zoom_filters` makes each frame twice the film's size
  first, as in a window. `memory_cap` stops an ffmpeg that goes too far, with its own message.
- **An ffmpeg with no text filter, with `log`.** Refused before anything is made, as a text
  is (`TextUnavailable`).
- **No `monospace` font.** `fc-match` answers with another, and the faint text is drawn in that.
  It is decoration, so nothing refuses it.
- **A ring's point off the picture once a window's shape cuts it.** A window keeps the clip's
  whole picture, so this cannot happen. DEMO-0151's crop will have to answer it.
- **Many rings at one moment.** Each adds an overlay for its half second. Nothing limits them, and
  the run takes longer.
- **Another machine's `monospace`.** "The same script makes the same film" holds on one machine;
  `log` and any text differ across fonts, as they do today.

## 7. Tests

All in `ci.sh`'s finishing steps, so `./ci.sh --finishing` runs them.

- INV-1: "a clip with no window can zoom".
- INV-2, INV-3: "a text can sit at any point".
- INV-4: "edit refuses a bad place for a text".
- INV-5: "a ring shows where and when it is told".
- INV-6: "a ring stays on its point of the picture".
- INV-7: "edit refuses a bad ring".
- INV-8, INV-10: "each drawn background draws itself".
- INV-9: "a drawn background makes the same film twice".
- INV-11: "a drawn background ends where the plan says".
- INV-12: "edit refuses a background it has no name for".
- INV-13: the existing finishing steps, with the one change named.

Each new step is seen to fail first: INV-1 by keeping the refusal, INV-2 by a centred `x`, INV-3
by stacking placed texts, INV-5 by a second added to `AT`, INV-6 by drawing after the scaling, INV-8
by a plain colour under each name, INV-9 by dropping a gradient's `seed`, INV-10 by dropping the table.

## 8. Alternatives considered (and rejected)

- **A `theme` word.** § 3.
- **`push` on a clip with no window.** It grows a window. A `zoom` over the whole clip does
  the same job on a full frame.
- **Percentages for a ring's point**, as a zoom's `x` and `y`. The numbers a caller has are the
  recording's pixels (`xdotool`), and a percentage needs working out and rounds.
- **A ring from `record`'s own steps, written where `edit` can read it.** It joins the two halves
  of the tool through a file, and it is the "automatic" side of the line README draws.
- **ImageMagick for the backgrounds and the ring, as `trailer.py` does.** A new dependency, which
  the finishing commands promise not to have.
- **`geq` on every frame for what does not change.** Cost grows with the scene; drawn once and
  repeated, it does not. Measured on `log`: 41 s CPU for 6 s.
- **A ring stream as long as its scene, with `enable`.** Each ring then scales a frame for every
  frame of the scene.
- **A band on a placed text.** A band is across the frame, and a box round the text is a callout,
  which is DEMO-0233.

## 9. Out of scope

- Arrows and callouts — tracked by DEMO-0233.
- Crop — tracked by DEMO-0151.
- `ring` or text `x` and `y` on a shortcut — deferred; not yet queued.
- A ring's colour or size as a word — deferred; not yet queued.
- Backgrounds other than these five, or one from a caller's picture — deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh "a clip with no window can zoom" |
| INV-2 | ci.sh "a text can sit at any point" |
| INV-3 | the same step |
| INV-4 | ci.sh "edit refuses a bad place for a text" |
| INV-5 | ci.sh "a ring shows where and when it is told" |
| INV-6 | ci.sh "a ring stays on its point of the picture" |
| INV-7 | ci.sh "edit refuses a bad ring" |
| INV-8 | **`Partial:`** ci.sh "each drawn background draws itself"; a broken picture that moves and is not flat passes, so someone must look at it |
| INV-9 | ci.sh "a drawn background makes the same film twice" |
| INV-10 | ci.sh "each drawn background draws itself" |
| INV-11 | **`Partial:`** ci.sh "a drawn background ends where the plan says"; § 5 says why |
| INV-12 | ci.sh "edit refuses a background it has no name for" |
| INV-13 | every existing finishing step |
| No new program | **nothing** automatic; code review. README § Finishing a recording promises it |
| A ring is never automatic | **nothing** automatic; README § What it will never do, and code review |
| A ring's stream ends at its half second | **nothing** automatic; code review. With no `trim` the picture is the same, since the fade has left the ring transparent (measured on ffmpeg 9.0.2, 2026-11-02) |
| New messages go through `tr` at run time | ci.sh "translation: nothing translated at import time" (DEMO-0060 INV-15), and "translation: the template matches the source", refreshed with `./ci.sh --pot` |

## 11. Cross-doc impact

- `README.md` § `edit`: a film from a script — `zoom` with no window, a text's `x` and `y`, the
  `ring` line, the named backgrounds.
- `demoreel.1` — the same.
- `.claude/rules/finishing-commands.md` — a ring costs only its half second.
- `CHANGELOG.md` — one bullet.
- `po/` — through `./ci.sh --pot` and `./ci.sh --add-message`.
- `record-demo` skill — feedback to `claude-config`, which owns it.
- The website session, `ants-projects-hub-website`: told what `trailer.py` can hand over, and what
  § 4.4 dropped.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0286-trailer-effects-loop-log.md`.

## 13. Resource cost

No new dependency and no state kept. A drawn background is one or two frames held plus its per-frame
work; figures in § 4.4. A ring costs one small frame for its half second. A full-frame zoom holds what
a windowed one does at a larger size.
