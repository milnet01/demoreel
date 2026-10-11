<!-- ants-spec-format: 1 -->
# DEMO-0183 — Show a clip in a smaller window, with rounded corners and a soft shadow, over a background

**Status:** accepted (2026-10-11).
**Kind:** feature.
**Source:** ROADMAP DEMO-0183 (peer-website-session-2026-10-10; the Slipcase trailer).
**Pairs with:** DEMO-0178 (a moving background behind the window), DEMO-0184 (push-in and zoom); both build on the layout this spec sets.

A clip in a film can play in a smaller window with rounded corners and a soft
shadow, centred on a coloured background, instead of filling the frame.

## 1. Goal

A `window PERCENT` word on an `edit` script's `clip` line plays that clip in a
window: fitted, its shape kept, into that share of the room a card leaves its
picture, with rounded corners and a soft shadow below it, centred on the
scene's `background` colour. A clip of a different shape from the film's is
accepted in a window, where today it is refused. A clip line without `window`
makes exactly the film it makes today.

## 2. Problem

1. A trailer shows an app as a floating window, not as a full frame. The
   Slipcase trailer did, and the user approved it (ROADMAP DEMO-0183,
   2026-10-10). Today `scene_graph` scales every clip to fill the frame, so
   that look needs a second program.
2. `check_scene` refuses a clip whose shape differs from the film's, because
   filling the frame would stretch it. Inside a window there is room round
   the picture, so the refusal has no reason to apply there.
3. The Slipcase builder made its corners and shadow with ImageMagick and
   repeated them with `-loop 1` (`/mnt/Games/Trailers/tools/trailer.py`,
   `masks` and `windowed`, scratch outside any repository). demoreel can use
   neither. README § Finishing a recording says the finishing commands *"need
   `ffmpeg` and nothing new"*, and `.claude/rules/finishing-commands.md` forbids
   looping a picture at the demuxer.

## 3. Scope decisions (agreed with the user)

- **A window, rounded corners and a soft shadow, over a background**, as the
  Slipcase trailer had (ROADMAP DEMO-0183, 2026-10-10).
- **The window is on README § What it will never do's list** (DEMO-0182,
  gated 2026-10-11): *"show a clip in a smaller window, with rounded corners
  and a soft shadow"*, and *"No clip is laid over another picture, except one
  clip's window over its background."*
- **This item gets its own spec, and DEMO-0178 and DEMO-0184 build under it
  without one** (the user, 2026-10-11).

Every other choice below follows from § 2 and is reviewed as design.

## 4. Design

### 4.1 The script words

```
clip FILE ... window PERCENT [background #RRGGBB] ...
```

- **`window PERCENT`** — a number from `20` to `100`. The clip is fitted into
  a box that share of the room's width and of its height, keeping its own
  shape, and centred in the room. It may be scaled up or down, as a clip
  filling the frame is today; it is never stretched.
- **The room** is the one `picture_room` already gives a card's picture: the
  frame inside its `CARD_MARGIN` margins, less what a text at the top or the
  bottom takes. So a windowed clip's caption sits on its band under the
  window, never over it, and `window 100` fills the room.
- **`background #RRGGBB`** on a clip line sets the colour round the window,
  as it does on a card, and is `CARD_BACKGROUND` unless given. `check_scene`
  checks it against `COLOUR_RE` for a clip as it does for a card. A clip line
  with `background` and no `window` is refused: nothing would show it.
- **A text with no band on a windowed clip takes its colour from
  `background`**, as on a card: `text_filters`' `dark` test, white on a dark
  background and near-black on a light one.
- Both words go into `SCENE_WORDS["clip"]` and are parsed by `script_words`,
  so their errors name the line as every other word's do. `Scene` gains
  `window` (`None`, or the percentage).
- **Script only.** No shortcut takes them, as no shortcut takes `font` (README
  § The shortcuts).

### 4.2 The shape check

`check_scene` keeps its refusal of a different shape for a clip without a
window, word for word. A windowed clip skips it.

### 4.3 The look

Each size follows the window's height `h`, as an outline follows its text's.
The values are the Slipcase builder's (`masks`: an 18 px radius, a 0x22 blur
and a 10 px drop on an 860 px window, at 75% opacity), as shares:

```
WINDOW_CORNER = 0.021   # corner radius, a share of h
WINDOW_BLUR   = 0.026   # the shadow's gblur sigma, a share of h
WINDOW_DROP   = 0.012   # how far the shadow falls below the window, a share of h
WINDOW_SHADOW = 0.75    # the shadow's opacity
```

The window's width and height are rounded down to even numbers.

### 4.4 The graph

`scene_graph` builds a windowed clip in four layers, from the back:

1. **Background** — a `color` source the frame's size, as a card's is.
2. **Shadow** — a black rounded rectangle, blurred with `gblur`, at
   `WINDOW_SHADOW` opacity, on a transparent canvas large enough to hold the
   blur. It sits `WINDOW_DROP · h` lower than the window.
3. **Window** — the clip scaled to the window's size, given the rounded mask
   with `alphamerge`.
4. **Texts and fades** — `text_filters` and `fade_filters` over the whole
   frame, as on every scene today. A scene's fade takes the background,
   shadow and window to black together.

The mask and the shadow are each drawn once, as one frame from a `color`
source and `geq`, and repeated by the `loop` filter. That is how a card's
picture is repeated today, and it keeps both rules of
`.claude/rules/finishing-commands.md`: no demuxer loop, and every stream ends,
since the chain still ends in `shape`'s `trim=end_frame`.

DEMO-0178 replaces layer 1. DEMO-0184 acts on layer 3, and layer 2 follows
the window's size and place as it changes. Neither changes the order.

**Measured, as a prototype** (2026-10-11, ffmpeg 9.0.2; a 6 s `testsrc2` clip at
1600x1000 in a window at 1920x1080, 30 a second; the sigma was half
`WINDOW_BLUR`): 2.86 s and 1.12 GB peak memory, against 1.56 s and 0.99 GB
for the same clip scaled to fill the frame.

### 4.5 What is unchanged

The clip's sound, its `from`, `to`, fades, `fade-at` and `crossfade`, the
plan's times, and the film's size and rate, which still come from the first
clip unless `-s` and `-r` say otherwise.

## 5. Invariants

Fixtures are `ci.sh`'s finishing ones, all 320x240 at 10 a second except
where named. `px bbox FILE IDX #RRGGBB` gives the box of what differs from
that colour by more than 60, as fractions of the frame. None of these clauses
can run until the code exists.

- **INV-1** — A windowed clip is fitted into its share of the room, centred,
  its shape kept.
  *Test:* ci.sh finishing: `edit` with `clip A.mp4 window 50`. The room is
  296x216, the box 148x108, the window 144x108 at (88, 66). `px bbox` against
  `#101418` gives `0.275 0.275 0.725 0.725`, within 0.01. The fixture
  isolates the fit: filling the frame gives `0 0 1 1`, a window sized from
  the frame is 160x120 with its left edge at `0.25`, and one not centred
  moves an edge.
  *Breaks when:* the window is sized from the frame rather than the room, or
  is not centred.

- **INV-2** — A clip of a different shape from the film's is accepted in a
  window and fitted, not stretched. Without a window it is still refused.
  *Test:* ci.sh finishing: `edit -s 320x240` with `clip W.mp4 window 50`
  (640x240) is made, and `px bbox` against `#101418` is 148 wide and 54 high
  (55.5 rounded down to even), centred: `0.269 0.388 0.731 0.613`, within
  0.02. Without a window, the existing step that refuses `join A.mp4 W.mp4`
  and `join A.mp4 T.mp4` ("join A with W.mp4, a different shape") still
  passes; `join` reaches `check_scene` as `edit` does.
  *Breaks when:* the shape check also refuses a windowed clip, or the window
  takes the box's shape rather than the clip's.

- **INV-3** — The window's corners are rounded: the background shows at a
  corner of the window's box, and the clip's picture at the middle of each
  edge.
  *Test:* ci.sh finishing: `edit -s 640x480` with `clip G.mp4 window 100`
  (flat `#808080`). The box is 576x432 at (32, 24), with a radius of about
  9 px. `px` at the box's top-left corner is within 10 of `16 20 24`; `px` at
  the middle of its top edge, 3 px inside, is within 10 of `128 128 128`. The
  fixture isolates the mask: a flat picture leaves no detail that could pass
  for the background.
  *Breaks when:* the mask is missing, or is not applied with `alphamerge`.

- **INV-4** — The window casts a shadow below it.
  *Test:* ci.sh finishing: as INV-3 with `background #c0c0c0`, where the
  blur's sigma is about 11 px and the drop about 5 px. Three `px` probes on
  the window's middle column, against `px` at the frame's top-left corner,
  where no shadow reaches. 4 px below the bottom edge is at least 20 darker
  than 4 px above the top edge, which a shadow not dropped fails. 12 px
  below the bottom edge, past where an unblurred shadow ends, is at least 15
  darker than the corner. A missing shadow fails both.
  *Breaks when:* the shadow is missing, not blurred onto the frame, or not
  dropped below the window.

- **INV-5** — A wrong `window` or `background` word stops the run before
  ffmpeg starts, and the message names the line.
  *Test:* ci.sh finishing: each refused by `expect_refused`, naming `line 1`,
  with nothing at `-o`: `window 10`, `window 101`, `window big`,
  `window 50 background red`, and `background #202830` on a clip with no
  `window`.
  *Breaks when:* any of them is accepted, or reaches ffmpeg.

- **INV-6** — A windowed scene ends where the plan says, in a film with cuts
  and a crossfade.
  *Test:* ci.sh finishing: `clip A.mp4 window 80`, then `clip B.mp4
  crossfade 0.5`, under `ulimit -v 3000000`: made, and 9.5 s long within
  0.15, as `join --crossfade 0.5` is. The limit is on virtual memory, which
  ffmpeg reserves well beyond what it uses: measured 2026-10-11, this film
  fails under 2000000 and is made under 3000000, at a resident peak near
  120 MB. Partial, as DEMO-0177's INV-13 is: the
  `loop` filter, the scene's `trim` and the output's `-t` each bound the
  others, so removing one alone may not fail it.
  *Breaks when:* the mask or shadow stream never ends and something waits on
  it.

- **INV-7** — A clip line without `window` makes the same film as before.
  *Test:* ci.sh finishing: every existing finishing step passes unchanged.
  *Breaks when:* a change to the shared code path moves an unwindowed clip.

## 6. Failure modes

- **The clip is far smaller than the window**: it is scaled up, softly, as a
  small clip filling the frame is today. Nothing refuses it.
- **Too little room**: the window, after rounding down to even, would be
  under 2 px high. Refused from `check_scene`, naming the line.
- **An ffmpeg without `gblur`, `geq` or `alphamerge`**: ffmpeg fails the run,
  and `make_film` shows its last lines, as for any filter it lacks. All three
  are in this machine's ffmpeg 9.0.2 and in the 6.1.1 of `ci.sh`'s Ubuntu
  image (`ffmpeg -filters`, 2026-10-11).
- **A large window at a large size**: the mask and shadow are one frame each,
  so their cost does not grow with the scene's length.

## 7. Tests

All in `ci.sh`'s finishing steps, so `./ci.sh --finishing` runs them.

- INV-1, INV-2: "a clip in a window is fitted into the room, any shape".
- INV-3, INV-4: "a window has rounded corners and a shadow".
- INV-5: "edit refuses a bad window or a clip's background".
- INV-6: "a windowed scene ends where the plan says".
- INV-7: the existing finishing steps, unchanged.

Each new step is seen to fail first: INV-1 by scaling to the frame, INV-2 by
leaving the shape check on, INV-3 by dropping `alphamerge`, INV-4 by dropping
the shadow's overlay, its drop and its blur in turn, INV-5 by removing one
check.

## 8. Alternatives considered (and rejected)

- **A window size in pixels.** It would tie a script to one film size, and
  `-s` changes that.
- **A window sized from the whole frame, not the room.** A caption's band
  would then lie over the window's bottom edge.
- **Knobs for the corner radius and the shadow.** One look serves a trailer;
  a knob is added when a caller needs it.
- **ImageMagick for the mask and shadow, as the builder did.** A new
  dependency, which the finishing commands promise not to have.
- **Drawing the mask with `geq` on every frame.** Its cost grows with the
  scene's length; drawn once and repeated, it does not.

## 9. Out of scope

- A moving background — DEMO-0178.
- A push-in on the window, or a zoom inside it — DEMO-0184.
- `window` on a shortcut, or on a card — deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh "a clip in a window is fitted into the room, any shape" |
| INV-2 | the same step, and the existing "join A with W.mp4, a different shape" refusal |
| INV-3 | ci.sh "a window has rounded corners and a shadow" |
| INV-4 | the same step |
| INV-5 | ci.sh "edit refuses a bad window or a clip's background" |
| INV-6 | ci.sh "a windowed scene ends where the plan says"; partial, § 5 |
| INV-7 | every existing finishing step |
| No new program | **nothing** automatic; code review. README § Finishing a recording promises it |
| New messages go through `tr` at run time | ci.sh "translation: nothing translated at import time" (DEMO-0060 INV-15), and "translation: the template matches the source", refreshed with `./ci.sh --pot` |

## 11. Cross-doc impact

- `README.md` § `edit`: a film from a script — `window` and a clip's
  `background`, and the different-shape rule's exception.
- `demoreel.1` — the clip line's words.
- `CHANGELOG.md` — one bullet.
- `po/` — the template, through `./ci.sh --pot`.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0183-clip-window-loop-log.md`.
