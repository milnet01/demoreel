---
paths:
  - "demoreel"
  - "ci.sh"
---
# The `--gpu` backend

demoreel starts a headless `cage` compositor (`WLR_BACKENDS=headless`, and no
other `WLR_` setting: the pointer measurements below were taken so) and a
full-screen, rootful `Xwayland` on it, which reaches the GPU where `Xvfb`
cannot. It records the compositor's output with `wf-recorder`, not the X side
with `x11grab`. Under a busy 3D app the X side's copy of the picture goes stale:
`x11grab` got 156 new frames of 588 where `wf-recorder` got 643 of 643, over
the same run (DEMO-0109). All four programs are installed. The details below
are load-bearing and none is obvious:

- **The order is fixed: `cage`, then resize, then `Xwayland`, then the app.**
  `cage`'s headless output is always 1280x720 at start. `wlr-randr --output
  HEADLESS-1 --custom-mode WxH` resizes it, but an `Xwayland` already running
  keeps its first size. So `cage`'s one child is a step that resizes the
  output, then `exec`s `Xwayland -displayfd N -auth F -geometry WxH -fullscreen
  -noreset -nolisten tcp`, with `F` an empty file at that point. The app
  starts afterwards, as on the `Xvfb` path, so pointer parking happens before
  the app exists. `-noreset` is what keeps it parked, as on `Xvfb` (DEMO-0103):
  without it the server resets when the parking `xdotool` leaves. Do not go
  back to `xwfb-run`: it starts `cage` and `Xwayland` as one step, with no
  place for the resize.
- **The app still has to be pushed to X11 inside the compositor.** `cage`
  speaks Wayland, so an app left to choose renders natively on it. The recorder
  would see that window, but finding the window, sizing it, the scripted steps
  and the blank check all work through X. `vkcube` picks `wayland` there unless
  told otherwise. The app gets the same unresolvable `WAYLAND_DISPLAY` as on
  the `Xvfb` path.
- **`wf-recorder` needs `-D`, `-y`, `-r`, `-c libx264` and `-x yuv420p`.**
  Without `-D` it asks for a frame only when the screen changes, and ignores
  `SIGINT` while the screen is still. Without `-y` it asks before overwriting,
  which is a prompt. It reaches `cage` through the socket name read back, never
  the session's `WAYLAND_DISPLAY`. The finished file must match the `Xvfb`
  path's: H.264, `yuv420p`, `+faststart`. `wf-recorder` has no muxer-flag
  option, so if its file lacks faststart, a stream-copy remux adds it.
- **The countdown starts when `wf-recorder` is capturing, never after a
  guessed delay** (DEMO-0012). It prints no progress reports like `ffmpeg`'s,
  so the signal is its own start-up output. Which line proves capture has
  begun is for the build to confirm against the video's first frame.
- **`record --gpu` refuses `--cursor`.** `wf-recorder` has no pointer option,
  and with the pointer moved over the app none of a recording's 39 frames
  showed it.
- **Only the recording moves to the compositor.** `--settle`, the blank check
  and `demoreel shot` still read the X side with `x11grab`. A stale-by-a-moment
  picture answers "is anything drawn?" correctly, and one still frame shows no
  stutter. So `shot --gpu --cursor` still draws the pointer: `x11grab` draws it
  on this X screen (measured).
- **DEMO-0109's stutter note stays, but its explanation must change.** Its
  current text says `--gpu` captures a busy app only a few times a second,
  which is the defect this backend removes. `ci.sh` detects the note by the
  words `frames in the middle`: keep them, or change its grep in the same
  commit.
- **The blank check reads the X side, and the video no longer comes from
  there.** So `record --gpu` also checks the finished file with
  `frame_is_flat`: one frame for each display sample the run actually took,
  from the same moment, so the app-has-exited and `-d 0` skips carry over. A
  flat one fails the run like a blank display. Without
  it, a recorder writing black while the X side is drawn passes every check.
- **Both displays are behind an auth cookie, so the X-side readers take the
  run's `env` rather than inheriting the session's** — otherwise they fail with
  `Cannot open display`, or silently sample an empty frame. Without a cookie a
  client with no credential can read the display, and socket permissions are no
  substitute, because `Xvfb` also listens on an abstract socket. The cookie is
  installed after `-displayfd` reports the number, since the cookie is keyed to
  it: start with an empty auth file, then write the cookie. `Xvfb` is then sent
  `SIGHUP` to re-read; do not "simplify" that ordering away. `Xwayland` re-reads
  the changed file with no signal (measured: a client with no credential got in
  before the cookie and was refused after). So on both backends the lock is
  proven in force by a client *without* the cookie being refused while one with
  it connects (`wait_until_locked`). A client holding the cookie gets in before
  the lock as well as after, so it alone proves nothing (DEMO-0113); a dead
  display refuses both, so the refusal alone proves nothing either.

`weston` is also installed, from testing this. Its headless backend falls back
to software rendering here (`Failed to initialize glamor`,
`amdgpu_query_info(ACCEL_WORKING) failed`), so it is not an alternative to
`cage` — it can be removed if it is not wanted for anything else.
