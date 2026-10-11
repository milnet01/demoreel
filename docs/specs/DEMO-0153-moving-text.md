<!-- ants-spec-format: 1 -->
# DEMO-0153 — Several lines of text on screen at once, sliding and fading in

**Status:** spec draft (2026-10-11).
**Kind:** feature.
**Source:** ROADMAP DEMO-0153 (user-request-2026-10-02; the Slipcase trailer, 2026-10-10).
**Pairs with:** DEMO-0185 (a logo that grows as it fades in; an end card is that plus this). DEMO-0183 (its window sits in the room these texts leave).

A scene can show several lines of text at once, stacked, each in its own
font, size and colour, and a line can slide up into place as it fades in.

## 1. Goal

Two texts whose times overlap are no longer refused. Texts at the same place
that are on screen together form a stack: one line above another in the order
the script writes them, each keeping its place for as long as the stack
lasts. Texts at different places show together. A text line takes
`slide-in SECONDS`: it rises into its place and fades in over that time,
easing out. A scene whose texts never overlap, and use no `slide-in`, makes
exactly the film it makes today.

## 2. Problem

1. A title card in a trailer is several lines: a heading and a line under it,
   each in its own style, arriving one after another. The Slipcase trailer's
   cards were (`/mnt/Games/Trailers/tools/trailer.py`, `scene_text`, scratch
   outside any repository), and the user approved them (ROADMAP DEMO-0153).
2. `check_texts` refuses two texts whose times overlap, with the message
   *"Only one shows at a time."* So a heading and a subheading cannot share a
   card, and a card title cannot sit above a caption.
3. A text appears where it stands, or fades in there (`text_filters`). The
   Slipcase lines slid up 36 px while fading in, easing out
   (`trailer.py`, `Scene.text`).

## 3. Scope decisions (agreed with the user)

- **Lines that slide up and fade in with ease-out, staggered line by line,
  several per card, each with its own colour, size and font; the caller
  supplies every line** (ROADMAP DEMO-0153, 2026-10-10).
- **README § What it will never do lists** *"put text on or between scenes,
  in one line or several, styled as the script says, standing still or
  sliding and fading in"* (DEMO-0182, gated 2026-10-11).
- **This item gets its own spec** (the user, 2026-10-11).

Every other choice below follows from § 2 and is reviewed as design.

## 4. Design

### 4.1 The script words

```
text "WORDS" ... [slide-in SECONDS] ...
```

- **`slide-in SECONDS`** — from its `from`, over that many seconds, the text
  rises `SLIDE_RISE` of its height into its place and fades in, both easing
  out: at a share `p` of the way through, it is `(1 - p)³` of the rise below
  its place and `p` faded in. Its band rises and fades with it.
- **A text takes `slide-in` or `fade-in`, not both**, as a scene takes
  `crossfade` or `fade-in`. `slide-in` and `fade-out` together may not be
  longer than the text shows, the rule `check_texts` already applies to two
  fades.
- **A sliding text on a band needs `boxw`**, as a fading one does today
  (`box_can_be_sized`): on an ffmpeg without it, it is refused with the
  fading band's reason.
- **No word for the stagger.** Each line's own `from` is its arrival.
- **Script only.** No shortcut takes `slide-in`, as none takes a text's
  fades (README § The shortcuts).

```
SLIDE_RISE = 0.5    # how far a sliding text rises: a share of its height
LINE_GAP   = 0.3    # space between two stacked lines: a share of the taller one's height
```

Both follow the Slipcase builder: a 36 px rise on lines of 64 to 92 px, and
a 30 px gap under 92 px lines (`trailer.py`, `Scene.text` and `scene_text`).

### 4.2 Stacks

- **A stack is the texts of one scene at one place (`at top`, `middle` or
  `bottom`) that are on screen together**, joined one to the next: if A
  overlaps B and B overlaps C, all three are one stack even when A and C
  never meet. Times compare as they do today: a text shows from its `from`
  up to its `to`, and not on the frame at `to`.
- **A stack's lines run top to bottom in the order the script writes them**,
  `LINE_GAP` apart. Each line's place is fixed for the stack's whole life,
  so a line does not move when another arrives or leaves.
- **The stack sits where one text of its height sits today**: against the
  top or bottom edge, or a margin in from it, as its lines' band says, or
  centred in the middle. So a stack of one line is placed exactly as a text
  is today.
- **A stack's lines are all on a band or all off one.** A mixed stack is
  refused, naming the line that differs.
- **Texts at different places may show together**, a title at the top over
  a caption at the bottom.
- **The room a card leaves its picture, `picture_room`, takes a stack's
  height** where it takes one text's today, at the top and at the bottom. A
  windowed clip (DEMO-0183) uses the same room.

### 4.3 Refusals

Each stops the run before ffmpeg starts, naming the line:

- a stack taller than the frame less its `CARD_MARGIN` margins;
- `slide-in` with `fade-in`, or `slide-in` and `fade-out` longer than the
  text shows;
- a stack mixing lines on and off a band;
- a sliding text on a band, on an ffmpeg without `boxw`.

The overlap refusal and its message go.

### 4.4 The graph

`text_filters` gives each line its stack's `y` for that line, and for a
sliding one a `y` and an `alpha` that are expressions of `t`.

**Measured, as a prototype** (2026-10-11): a `drawtext` whose `y` is
`200+40*pow(1-clip((t-0.5)/0.6,0,1),3)`, with a band from its own `boxw`
box, on a 640x360 frame at 10 a second, ffmpeg 9.0.2. The band's top row at
t = 0.5, 0.6, 0.7, 0.8, 0.9 and 1.1 was 240, 223, 211, 205, 201 and 200: it
rose with the text, easing out. The same filter ran on the 6.1.1 of
`ci.sh`'s Ubuntu image.

## 5. Invariants

Each runs as an `edit` at `-s 640x480 -r 10` on `#101418` unless it says
otherwise, so frame `N` is at `N / 10` seconds and a text of size 10 is 48 px
high. `px find FILE IDX SPEC` gives the count and box of matching pixels as
fractions of the frame, `light:40` matching drawn text on that background.
None of these clauses can run until the code exists.

- **INV-1** — Texts at one place that are on screen together are stacked in
  the order the script writes them, the stack centred at the middle.
  *Test:* ci.sh finishing: `card 2` with `text "Heading" colour #FFFFFF size
  10`, then `text "Second" colour #FF4040 size 6 from 0.5`. At frame 10,
  `px find` for `#FFFFFF:40` ends above where `#FF4040:60` starts, and the
  midpoint of the white box's top and the red box's bottom is 0.5 within
  0.03. The colours isolate the order; today's code refuses the script.
  *Breaks when:* the overlap is still refused, the order is reversed, or the
  stack is not centred.

- **INV-2** — A stacked line keeps its place when another arrives.
  *Test:* as INV-1: the white box at frame 2, before "Second" shows, equals
  the white box at frame 10, each edge within 0.003.
  *Breaks when:* the stack is laid out from the texts on screen at each
  moment, so "Heading" jumps up when "Second" arrives.

- **INV-3** — A text that shares the screen with no other is placed as it is
  today.
  *Test:* ci.sh finishing: every existing step drawing text passes
  unchanged, the card title, caption and placement steps among them.
  *Breaks when:* a one-line stack is placed by a different rule from a text
  today.

- **INV-4** — Texts at different places show together.
  *Test:* ci.sh finishing: `card 2` with `text "Top" at top` and `text
  "Bottom" at bottom`, both for the whole card, is made, and frame 10 has
  `light:40` pixels in its top fifth and in its bottom fifth. The two
  existing `caption` steps that expect a refusal — "caption with texts
  overlapping between 3 and 4" and "caption with a whole-video text and
  another beside it" — now expect a film, the captions stacked on bands.
  *Breaks when:* any two overlapping texts are still refused.

- **INV-5** — `slide-in` rises into place and fades in, easing out.
  *Test:* ci.sh finishing: `card 2` with `text "Rise" size 10 slide-in 1`.
  The rise is 24 px. At frame 2, `p` is 0.2, so the text sits
  `24 × 0.8³` ≈ 12 px low: the `light:40` box's top is 9 to 15 px below
  its top at frame 15. A linear rise would be 19 px low. At frame 2 the
  brightest text pixel is under 120; at frame 15 it is over 200.
  *Breaks when:* the text does not move, moves down, moves linearly, or does
  not fade in.

- **INV-6** — A wrong stack or `slide-in` stops the run before ffmpeg
  starts, and the message names the line.
  *Test:* ci.sh finishing: each refused by `expect_refused`, naming its line,
  with nothing at `-o`: `slide-in 1 fade-in 1` on one text; `slide-in 1.5
  fade-out 1` on a text shown 2 s; under `-s 320x240`, four overlapping texts
  of size 30 at a card's middle, each 72 px high, taller than its room; and
  on `clip A.mp4`, `text "a" band off` with `text "b"`, both at the bottom
  over the same seconds, one off a band and one on it.
  *Breaks when:* any of them is accepted, or reaches ffmpeg.

- **INV-7** — A sliding text on a band follows the fading band's rule: made
  where ffmpeg has `boxw`, refused naming the line where it has not.
  *Test:* ci.sh finishing, beside the existing fading-band step, which
  branches on `boxw` in `ffmpeg -h filter=drawtext`. Partial: this machine
  and the Ubuntu image both have `boxw`, so only the made branch runs.
  *Breaks when:* a sliding band is drawn with `drawbox`, which stays still
  while the text moves.

- **INV-8** — A card's picture is fitted below a stack at the top, not below
  its first line alone.
  *Test:* ci.sh finishing: `card 2 sq.png` with `text "A" at top size 8` and
  `text "B" at top size 6`, both for the whole card. At frame 10, `px find`
  for `#00C000:60` starts below the bottom of the `light:40` pixels in the
  top half.
  *Breaks when:* `picture_room` counts one text's height at the top.

## 6. Failure modes

- **Two texts that touch only at a moment**: one's `to` equal to the other's
  `from`. They are not on screen together, so they are not one stack, as
  today.
- **A long chain of overlaps**: every text it reaches is one stack, and must
  fit the frame. A card that refuses for this splits the chain with a gap.
- **A line wider than the frame**: refused per line, as today.
- **A stack and a window (DEMO-0183)**: the window takes the room the stack
  leaves, through `picture_room`.

## 7. Tests

All in `ci.sh`'s finishing steps, so `./ci.sh --finishing` runs them.

- INV-1, INV-2: "texts on screen together are stacked in order and stay put".
- INV-3: the existing text steps, unchanged.
- INV-4: "texts at different places show together", and the two existing
  caption-overlap steps, changed to expect a film.
- INV-5: "slide-in rises into place and fades in".
- INV-6: "edit refuses a bad stack or slide-in".
- INV-7: the fading-band step's `boxw` branch, extended to `slide-in`.
- INV-8: "a card's picture fits below a stack".

Each new step is seen to fail first: INV-1 against today's refusal, INV-2 by
laying out from the texts on screen, INV-5 by making the rise linear, INV-6
by removing one check, INV-8 by counting one text in `picture_room`.

## 8. Alternatives considered (and rejected)

- **One `text` line holding several lines of words.** Each line needs its
  own font, size, colour and time, which one line's words cannot carry.
- **Placing each line at its own `at`, by a pixel offset.** It would tie a
  script to one frame size.
- **A `stagger` word.** Each line's `from` does the same, and is already
  understood.
- **A stack laid out from the lines on screen at each moment.** Lines would
  jump as others come and go.
- **`slide-in` that only moves, beside `fade-in`.** Every sliding line in
  the Slipcase trailer also faded in over the same time; two words would
  have to be kept equal by hand.

## 9. Out of scope

- A logo growing as it fades in — DEMO-0185.
- Slide directions other than up, and a slide out — deferred; not yet
  queued.
- `slide-in` on a shortcut — deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh "texts on screen together are stacked in order and stay put" |
| INV-2 | the same step |
| INV-3 | every existing text step |
| INV-4 | ci.sh "texts at different places show together", and the two changed caption-overlap steps |
| INV-5 | ci.sh "slide-in rises into place and fades in" |
| INV-6 | ci.sh "edit refuses a bad stack or slide-in" |
| INV-7 | the fading-band step's `boxw` branch; partial, § 5 |
| INV-8 | ci.sh "a card's picture fits below a stack" |
| New messages go through `tr` at run time | ci.sh "translation: nothing translated at import time" (DEMO-0060 INV-15), and "translation: the template matches the source", refreshed with `./ci.sh --pot` |

## 11. Cross-doc impact

- `README.md` § `edit`: a film from a script — `slide-in`, stacks, and the
  removal of *"only one on screen at a time"*.
- `demoreel.1` — the text line's words.
- `CHANGELOG.md` — one bullet.
- `po/` — the template, through `./ci.sh --pot`; the overlap message goes.
- `ci.sh` — the two caption-overlap steps change (INV-4).

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0153-moving-text-loop-log.md`.
