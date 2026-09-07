<!-- ants-roadmap-format: 1 -->
# demoreel — Roadmap

> **Format:** v1 — see
> [roadmap-format.md](docs/standards/roadmap-format.md).
> Every actionable bullet carries a stable ID; ID is identity,
> position is priority.

**Legend** — 📋 planned · 🚧 in progress · ✅ shipped · 💭 considered

## 0.1.0 — Records anything, from anywhere

Shipped. The tool is callable from any session, needs no flags for the
simplest case, and a gate proves it still records.

- ✅ [DEMO-0001] **Make demoreel reachable from every Claude Code session.**
  Two halves. A PATH symlink so it runs as one word from any
  directory, and a machine-wide record-demo skill whose description
  loads at the start of every session, so a request to record an app
  routes here on its own.

  Resolved (2026-09-07): both installed and confirmed working -- the
  skill appeared in the session's own skill list once written.
  **Layman:** Any session, in any project, can now record a video without being told this tool exists
  Kind: feature.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0002] **Make -o optional, defaulting to <app>-<timestamp>.mp4.**
  Every call previously had to name an output file. Without -o the
  file now lands in the current directory named from the app and a
  timestamp, and stdout still carries that path and nothing else.

  Resolved (2026-09-07): verified by recording xclock with no -o and
  reading the sampled frame.
  **Layman:** The simplest possible call is now `demoreel record -- kate`
  Kind: enhancement.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0003] **Add a CI gate that both a local run and GitHub execute.**
  ci.sh holds every check; the GitHub workflow installs the programs
  and calls it, so the two cannot drift. Checks are ruff against an
  in-repo ruleset, a parse, and a smoke recording that samples a frame
  and fails if the app never reached the picture.

  Wired to the machine-wide pre-push hook via ants.gate.command and
  ants.gate.docsGlob, so a code push runs it and a docs-only push does
  not.

  Resolved (2026-09-07): gate passes locally end to end.
  **Layman:** Problems get caught before a push instead of after one
  Kind: test.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0004] **Serve the roadmap from the roadmap store.**
  The project had no ROADMAP.md at all, so this was a bootstrap rather
  than a migration. ROADMAP.md is now generated from the store and
  should not be hand-edited.

  Resolved (2026-09-07): registered, and .ants/project.json declares
  the roadmap path.
  **Layman:** The roadmap is now queryable item by item rather than read whole
  Kind: chore.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0005] **Define the version scheme and what reaching 1.0 requires.**
  demoreel reports a version and accepts --version. The breaking
  surfaces and the 1.0 exit condition are in
  docs/standards/versioning-overrides.md, which is the one file the
  global versioning standard leaves each project to answer.

  Resolved (2026-09-07).
  **Layman:** It is now written down what each version number means for this tool
  Kind: doc.
  Source: user-request-2026-09-07.

## Backlog

## 0.1.1 — Before the first tag

Nothing here breaks a documented surface, so all of it lands in a PATCH.

- 📋 [DEMO-0009] **Add a CHANGELOG before cutting the first tagged release.**
  The project has no CHANGELOG.md and no tags. The version scheme is
  now defined, so the remaining piece before a v0.1.0 tag is somewhere
  to record what each release contains.
  **Layman:** There is nowhere yet to record what changed between versions
  Kind: release.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0010] **Keep the two pinned versions in step with their latest releases.**
  CI pins ruff and the checkout action. Both are pinned AT their latest
  release rather than held below one, so no hold-ledger entry is owed
  under the dependency standard -- a pin at latest is not a hold.

  They still go stale on their own. The ruff pin must move with the
  version installed on the dev machine, or a local run and CI stop
  linting with the same tool, which is the one thing the shared gate
  exists to prevent.

  If either ever has to stay below its latest release, that becomes a
  hold and needs a ledger row naming what broke, at which version, and
  what would release it.
  **Layman:** Two version numbers are written down in CI and will go stale unless someone bumps them
  Kind: chore.
  Source: user-request-2026-09-07.

- 📋 [DEMO-0013] **Drop or condition the faststart rewrite, which re-reads the whole video.**
  The recorder passes `-movflags +faststart`, which moves the index to the
  front of the file once recording finishes. That is a full extra pass
  over the output.

  It is invisible on a five second clip and grows with the recording. It
  buys progressive playback over HTTP, which matters for a file streamed
  from a web server and not for one uploaded to a submission or opened
  locally.

  Encoding parameters are explicitly not a breaking surface, so this can
  change in a PATCH. Measure a long recording first -- the cost should be
  established rather than assumed.
  **Layman:** Every recording is written twice; the second pass buys something we may not need
  Kind: perf.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0014] **Tune the encoder for screen content instead of general video.**
  The recorder uses `-preset veryfast -crf 23` with no tuning. A GUI
  recording is mostly static with sharp text, which is the case x264's
  still-image and animation tunings exist for, and it is nothing like the
  content the defaults assume.

  Likely a smaller file at the same or better legibility, which is what
  matters for a demo video of an interface. Cheap to try and cheap to
  measure: record the same app twice and compare size against how readable
  the text is.

  Encoding parameters are not a breaking surface, so this is a PATCH.
  **Layman:** The video settings are tuned for film; a mostly-still app window compresses far better
  Kind: perf.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0015] **The gate exercises recording only; stop and the scripted actions are untested.**
  ci.sh runs `record` twice and nothing else. `stop`, the `-a` scripted
  actions, `--app-log`, `--settle` and `--cursor` are all documented, and
  nothing proves any of them still works.

  The `-a` actions are the sharpest gap, because a scripted click that
  quietly stops landing still produces a valid-looking video of an app
  sitting there doing nothing -- the same silent failure the blank check
  exists to catch, one level up.

  All of it is reachable with xclock or xterm on the existing Xvfb path,
  so this needs no new infrastructure, unlike the two backend items.
  **Layman:** Half the tool's features have no automatic check behind them
  Kind: test.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0016] **Warn when a Flatpak target is missing the flags it needs.**
  A Flatpak target needs `--socket=x11`, `--nosocket=wayland` and
  `--filesystem=/tmp/.X11-unix` on its own command line. Without them the app renders on the real compositor,
  the virtual display stays empty, and the run fails the blank check with
  a message that lists the cause among two possibilities.

  Seeing `flatpak run` in the command without `--nosocket=wayland` and
  saying so up front would turn a wasted recording into an immediate,
  specific error.

  This is a guard on a documented footgun, not per-app knowledge: it reads
  the caller's own command line and hardcodes nothing about any
  application.
  **Layman:** Recording a Flatpak the wrong way gives a black video and no clue why
  Kind: enhancement.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0017] **The Xvfb display has no auth cookie, while the --gpu display does.**
  `start_gpu_display` creates an Xauthority file at mode 0600 and hands
  it to every client through XAUTHORITY. The default path starts Xvfb with
  `-nolisten tcp` and no `-auth`, and its env carries no XAUTHORITY at all.

  So the two backends do not offer the same protection, and the weaker one
  is the default. `-nolisten tcp` closes the network, not other local
  processes reaching the socket.

  That matters more here than in most tools, because the whole reason this
  display exists is to keep what is on it out of view. An app recorded on
  it may be showing exactly what the user did not want captured.

  The GPU path already shows the shape of the fix, so this is applying an
  existing pattern rather than inventing one. Measure first: confirm what
  a process running as another user can actually do with the socket on
  this system, so the fix answers a demonstrated reach rather than an
  assumed one.
  **Layman:** While a recording runs, other programs on the machine can watch that private display.
  Kind: security.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0018] **Text from `-a type` is visible in the process list while it is typed.**
  The type action runs `xdotool type --delay 60 <text>`, passing the text
  as a command-line argument. Command lines are readable by other local
  users through the process list for as long as the process runs, and the
  60ms delay means it runs for as long as the text is long.

  A demo that types into a login form is the obvious case, and it is a
  plausible thing to record.

  `xdotool type --file -` reads the text from stdin instead, which keeps
  it out of the process list. Same feature, same grammar, nothing exposed.
  **Layman:** Anything the script types can be read by other users on the machine as it happens.
  Kind: security.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0019] **The run-state directory falls back to a predictable path under /tmp.**
  `state_dir()` uses XDG_RUNTIME_DIR when set and otherwise
  `/tmp/demoreel-<uid>`, creating it with `exist_ok=True` and then setting
  mode 0700.

  The name is predictable, so on a shared machine another user can create
  that path first. `exist_ok=True` means demoreel then adopts it, and the
  chmod follows a symlink rather than refusing it.

  XDG_RUNTIME_DIR is set in a normal desktop session, so this is the
  fallback path rather than the usual one -- which is also why it would go
  unnoticed. Refusing a directory that is not already owned by the caller
  would close it.
  **Layman:** Without one environment variable set, run state lands somewhere another user could have prepared first.
  Kind: security.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0020] **The privacy promise is argued rather than demonstrated.**
  Found by a cold reader answering "how would we know it works" from the
  documents alone. Every other dimension of the stated purpose has a
  recorded measurement behind it -- the GPU path has a shaded cube, the
  blank check has grey-level figures, the scripted actions have a click
  that landed. Privacy has an argument: nothing of the user's session is on
  the display, so nothing of it can be in frame.

  The argument is sound and the property is the reason the tool exists,
  which is exactly why it should not be the one claim resting on reasoning.

  What would count, in the reader's own framing: a recording made with the
  magnifier active and private windows open on the real desktop, with the
  frames confirmed clean. Once done it belongs in README's verified list
  beside the others.
  **Layman:** The one thing this tool exists to guarantee has never been checked in an actual recording.
  Kind: test.
  Source: adopt-project-2026-09-07.

- 📋 [DEMO-0021] **Three places implement the documentation-only decision; only its value has one home.**
  `ci.sh --docs-glob` is the single definition of the pattern, and both the
  workflow and the machine-wide pre-push hook read it. But each then does
  its own matching: the workflow splits and pattern-matches in its own
  bash, and the hook does the same again in its own.

  So the value has one home and the semantics have three. Two of them
  agreeing today is not the same as them being one thing, and the drift
  would show up as a push classified differently in the two places -- the
  exact failure the shared script exists to prevent.

  Moving the classification into `ci.sh` behind a flag, so both callers ask
  it rather than reimplementing it, would close it. The hook is
  machine-wide and not this project's to change, so this may only be
  reachable for the workflow half.
  **Layman:** The rule for what counts as a docs push is written once but acted on in three separate places.
  Kind: refactor.
  Source: cold-read-2026-09-07.

- 📋 [DEMO-0022] **The gate never induces a blank recording, so the guard against one is untested.**
  The smoke step proves a good recording succeeds. Nothing proves a bad one
  fails.

  That matters more than an ordinary coverage gap because the behaviour is
  a protected surface the versioning overrides name, and CLAUDE.md says
  outright not to downgrade it to a warning. Someone could do exactly that
  and the gate would stay green.

  It is cheap to induce: an app that maps a window and then exits while its
  parent stays alive leaves the display blank with the run still live,
  which is the branch that fails. That shape was already used by hand this
  session to confirm the behaviour, so the gate can use the same one.
  **Layman:** The check that refuses an empty video has itself never been checked.
  Kind: test.
  Source: cold-read-2026-09-07.

- 📋 [DEMO-0023] **CLAUDE.md changed direction and owes an independent cold read.**
  Two edits on 2026-09-07 changed what a conforming session does: ROADMAP.md
  is generated and must not be hand-edited, and a change is verified by
  running ./ci.sh rather than by recording something by hand. Both change
  behaviour, so the global rule 14 gate applies.

  It was recorded in the commit body and deliberately not run, because the
  session had already spent three loops and nine lanes gating
  docs/standards/versioning-overrides.md. Filing it so the decision is
  visible somewhere a session will actually look.

  Run it as: review-contract CLAUDE.md --genre standard. Note that the
  CLAUDE.md class keeps its loop log OUTSIDE the document, in a dated
  record under docs/, rather than appending a table to a file every session
  loads.
  **Layman:** One document was edited in a way that changes what future sessions do, and nobody independent has checked it.
  Kind: doc.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0024] **The tool and its gate disagree about a frame measuring exactly the threshold.**
  `display_is_blank` returns `... > 0.999`, so a frame measuring exactly
  0.999 is NOT blank and the run succeeds. `ci.sh`'s smoke check exits
  non-zero `if dominant >= 0.999`, so the same frame fails the gate.

  Demonstrated rather than inferred: `0.999 > 0.999` is False and
  `0.999 >= 0.999` is True.

  CLAUDE.md calls these the same test and tells a session to move every
  copy of the threshold together. They are not quite the same test, and
  the difference sits at the one value the whole check turns on.

  Narrow in practice -- a real frame rarely lands on the boundary
  exactly -- which is why it has gone unnoticed and why it is a PATCH
  rather than urgent. Pick one comparator and use it in both places.
  **Layman:** One exact value makes the tool say the app is there and the gate say it never arrived
  Kind: fix.
  Source: review-contract-2026-09-07 loop 2.

## 0.2.0 — Stricter guards and honest durations

Each of these changes what an existing caller receives, which is what a
MINOR is spent on while the leading zero is there.

- 📋 [DEMO-0008] **The blank check samples the display once, near the end of the run.**
  The guard asks whether the display is blank after recording. An app
  that draws nothing until the final moments passes it, and hands back
  a video that is mostly empty.

  Sampling once more, early in the run, would catch that without
  changing what the check means. The threshold is shared with --settle
  and is load-bearing in both roles, so it must not be tuned for one.
  **Layman:** A video that was empty for most of its length can still pass the check
  Kind: fix.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0011] **Two concurrent runs sharing a name clobber each other's state file.**
  Measured, not inferred. Two `-d 0` recordings started together with no
  `-n` both write the state file for the name `default`, so the second
  overwrites the first. Stopping then removes the file and the first run is
  orphaned: it keeps recording, keeps its display, and `demoreel stop`
  answers "no recording is running" while it is still going. It had to be
  signalled by pid to shut down.

  This breaks the concurrency-safety requirement the README states -- the
  display number is picked safely, but the state file that makes a run
  addressable is not.

  The display number is already unique per run, so keying the state file by
  that, or by pid, would remove the collision without a new concept. Note
  that `cmd_stop` filters by name and then loops, so its loop can only ever
  print one line today; a fix here changes that, which is a stdout-contract
  change and therefore breaking.
  Progress (2026-09-07): re-measured during the CLAUDE.md gate, and the
  defect is narrower than this bullet reads. There IS a guard: a second
  unnamed run started while the first is recording exits 1 with "a
  recording named 'default' is already running (pid N). Use --name to
  tell this run apart from it." Verified by running it.

  The clobber survives only in the check-then-write race. `cmd_record`
  tests `statefile.exists()` near the start and calls
  `statefile.write_text(...)` only after `start_ffmpeg`, so two runs
  launched together both pass the check before either writes. Verified
  by running that too: both recorded on `:1` and `:2`, and
  `default.json` held the second run's pid and output.

  So the fix is the ordering, not a new guard -- adding one duplicates
  what is already there. Do not delete the existing `die()`; it covers
  every non-race case.
  **Layman:** Start two recordings at once without naming them and one becomes impossible to stop
  Kind: fix.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0012] **Requested duration overshoots, and every run pays about a second of fixed setup.**
  Measured: `-d 3 -s 1280x800 -- xclock` produced a 4.07 second video in
  5.09 seconds of wall clock. So the clip is about a third longer than
  asked for, and roughly a second goes on setup before anything is
  recorded.

  The causes are two fixed half-second sleeps around starting the app and
  the recorder, plus quarter-second polling granularity in the wait loops.
  Waiting on the actual condition rather than a fixed interval would
  recover most of it.

  The overshoot matters more than the latency: a caller stitching clips
  together gets lengths it did not choose. Note that making `-d` mean what
  it says changes what an existing flag means, which the versioning
  overrides make a breaking change.
  **Layman:** Ask for a 3 second clip and you get just over 4 seconds, after a second of waiting
  Kind: perf.
  Source: in-session-2026-09-07.

## 1.0.0 — Every documented path tested

The exit condition in docs/standards/versioning-overrides.md: the gate
covers both display backends and the Flatpak invocation.

- 📋 [DEMO-0006] **Cover the --gpu backend in the CI gate.**
  The gate records on Xvfb only, so a regression in the compositor
  path would reach a user before a check caught it. Needs a runner
  with a usable card, which an ordinary GitHub runner is not.

  This is one of the two conditions for reaching 1.0.
  **Layman:** The graphics-card recording path is not tested automatically yet
  Kind: test.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0007] **Cover a Flatpak target in the CI gate.**
  The README documents three flags a Flatpak target needs, and nothing
  checks that the recipe still works. Needs a published application to
  point at.

  This is the second of the two conditions for reaching 1.0.
  **Layman:** The Flatpak recipe in the README is documented but not tested
  Kind: test.
  Source: in-session-2026-09-07.
