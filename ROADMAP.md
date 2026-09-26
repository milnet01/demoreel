<!-- ants-roadmap-format: 1 -->
<!-- Generated from the Ants Terminal roadmap store. Edit it with roadmap_log; hand edits are discarded by the next write. -->
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
  **Layman:** Any session, in any project, can now record a video without being told this tool exists.
  Kind: feature.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0002] **Make -o optional, defaulting to <app>-<timestamp>.mp4.**
  Every call previously had to name an output file. Without -o the
  file now lands in the current directory named from the app and a
  timestamp, and stdout still carries that path and nothing else.

  Resolved (2026-09-07): verified by recording xclock with no -o and
  reading the sampled frame.
  **Layman:** The simplest possible call is now `demoreel record -- kate`.
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
  **Layman:** Problems get caught before a push instead of after one.
  Kind: test.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0004] **Serve the roadmap from the roadmap store.**
  The project had no ROADMAP.md at all, so this was a bootstrap rather
  than a migration. ROADMAP.md is now generated from the store and
  should not be hand-edited.

  Resolved (2026-09-07): registered, and .ants/project.json declares
  the roadmap path.
  **Layman:** The roadmap is now queryable item by item rather than read whole.
  Kind: chore.
  Source: user-request-2026-09-07.

- ✅ [DEMO-0005] **Define the version scheme and what reaching 1.0 requires.**
  demoreel reports a version and accepts --version. The breaking
  surfaces and the 1.0 exit condition are in
  docs/standards/versioning-overrides.md, which is the one file the
  global versioning standard leaves each project to answer.

  Resolved (2026-09-07).
  **Layman:** It is now written down what each version number means for this tool.
  Kind: doc.
  Source: user-request-2026-09-07.

## Backlog

## Standing chores

Recurring work with no finished state. It is checked on a schedule and never
closes, so it sits outside every version heading.

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
  Checked (2026-09-08): both pins are at their latest release, so nothing is
  owed today and the item stays open as the standing chore it describes.

  ruff is pinned at 0.16.6, which is what the machine has installed and what
  astral-sh/ruff reports as its latest release -- so a local run and CI lint with
  the same tool.

  actions/checkout is pinned by SHA 3d3c42e5aac5ba805825da76410c181273ba90b1,
  commented v7.0.1. Verified the comment rather than trusting it: the tag ref for
  v7.0.1 resolves to exactly that commit, and v7.0.1 is the latest release.

  Neither is held below its latest, so no hold-ledger row is owed.
  Checked (2026-09-19): ruff moved 0.16.6 -> 0.16.8, its latest release,
  in ci.sh and in the machine's pipx install together. actions/checkout is
  still v7.0.1, its latest. The item stays open as the standing chore.
  **Layman:** Two version numbers are written down in CI and will go stale unless someone bumps them.
  Kind: chore.
  Source: user-request-2026-09-07.

- 📋 [DEMO-0096] **Get each draft translation confirmed by a native speaker.**
  Decided 2026-09-25: Claude drafts each translation and it stays marked as
  a draft until a native speaker confirms it. How a confirmation works is
  0.4.0's to write down. This item is the chasing, which has no end date,
  so it does not hold any release. Record each language as it is
  confirmed.
  **Layman:** Keep asking fluent speakers to check the machine-drafted translations until every one is confirmed.
  Kind: chore.
  Source: user-request-2026-09-25.

## 0.1.1 — Before the first tag

Nothing here breaks a documented surface, so all of it lands in a PATCH.

- ✅ [DEMO-0009] **Add a CHANGELOG before cutting the first tagged release.**
  The project has no CHANGELOG.md and no tags. The version scheme is
  now defined, so the remaining piece before a v0.1.0 tag is somewhere
  to record what each release contains.
  Resolved (2026-09-08): CHANGELOG.md added in Keep a Changelog format, per
  changelog-format.md section 4, with everything under [Unreleased] because
  nothing has been tagged. Verified it parses for the tooling -- changelog_query
  reads the entry back.

  Two further documents the skeleton expects were absent and were added in the
  same commit: SECURITY.md, which names this project's trust boundaries and links
  DEMO-0017, DEMO-0018 and DEMO-0019 rather than restating them; and
  docs/standards/README.md, saying the global standards are read in place and
  what this directory declares.

  Not created, deliberately: docs/design.md, because this project's CLAUDE.md
  makes README.md the design contract; docs/discovery.md, because the project was
  not built through that flow; docs/decisions/, because the decisions already
  live in README.md and CLAUDE.md.

  ci.sh's readability check covers the new documents.
  **Layman:** There is nowhere yet to record what changed between versions.
  Kind: release.
  Source: in-session-2026-09-07.

- 💭 [DEMO-0013] **Drop or condition the faststart rewrite, which re-reads the whole video.**
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
  Measured (2026-09-08), as the bullet asked, before deciding anything.

  The cost is real but small and tracks file SIZE rather than duration. On a
  20-second recording of an xterm (1.4 MB out) the difference was inside the
  noise: 2.89s without, 2.87s with. On a six-minute high-bitrate encode of the
  same content (47.8 MB out) it was 48.07s without and 51.58s with -- about 3.5
  seconds, roughly 7%.

  Method: a lossless ffv1 capture of a scrolling xterm on Xvfb, re-encoded with
  and without the flag. Both files were byte-identical in size, so the flag costs
  time and not space.

  Recommendation: keep it. 7% of encode time on a large file is a fair price for
  progressive playback, and the tool's own reason for existing is a Flathub
  submission, where the video is likely to be served over HTTP rather than opened
  locally. The bullet assumed the opposite; the assumption is what the
  measurement corrects. Not closing the item -- whether to drop or condition the
  flag is a call for the user, and the numbers are now here to make it on.
  Decided (2026-09-08) by the user, on the measurement above: keep the
  faststart rewrite. 7% of encode time on a large file is a fair price for
  progressive playback, and this tool's own reason for existing is a
  Flathub submission, where the video is served over HTTP rather than
  opened locally. Closing as considered -- measured, decided, no change.
  **Layman:** Every recording is written twice; the second pass buys something we may not need.
  Kind: perf.
  Source: in-session-2026-09-07.

- 💭 [DEMO-0014] **Tune the encoder for screen content instead of general video.**
  The recorder uses `-preset veryfast -crf 23` with no tuning. A GUI
  recording is mostly static with sharp text, which is the case x264's
  still-image and animation tunings exist for, and it is nothing like the
  content the defaults assume.

  Likely a smaller file at the same or better legibility, which is what
  matters for a demo video of an interface. Cheap to try and cheap to
  measure: record the same app twice and compare size against how readable
  the text is.

  Encoding parameters are not a breaking surface, so this is a PATCH.
  Measured (2026-09-08). The premise does not hold up, and the recommendation is
  to leave the encoder alone.

  Method: a lossless ffv1 capture of a scrolling xterm on Xvfb -- text, sharp
  edges, mostly static, which is the content the bullet is about -- encoded four
  ways at preset veryfast, and compared on size and on SSIM against the lossless
  master.

    current (crf 23)      1,395,493 bytes   SSIM 0.988
    tune stillimage       1,296,149 bytes   SSIM 0.985
    tune animation        1,594,559 bytes   SSIM 0.992
    tune zerolatency      2,448,669 bytes   SSIM 0.994

  So stillimage is about 7% smaller and marginally WORSE by SSIM, not better --
  the bullet expected "a smaller file at the same or better legibility". Looked at
  the frames rather than trusting the metric, cropping a text region from the
  current and stillimage encodes: both equally legible, no visible difference.

  The argument against changing it is what the measurement added. This tool
  records static interfaces AND spinning 3D, and one default serves both. On the
  --gpu cube recording the same tunings land within a few percent of each other,
  so there is no tuning that is right for both kinds of content and no flag to
  select one -- adding one would be a knob the scope ceiling does not want.

  Recommendation: no change. 7% on a demo clip does not earn a default that is
  wrong for half the tool's targets.
  Decided (2026-09-08) by the user, on the measurement above: leave the
  encoder alone. The premise did not hold -- `tune stillimage` is about 7%
  smaller and marginally WORSE by SSIM, not better, and the frames are
  indistinguishable. One default has to serve both static interfaces and
  spinning 3D, and no tuning is right for both. Closing as considered --
  measured, decided, no change.
  **Layman:** The video settings are tuned for film; a mostly-still app window compresses far better.
  Kind: perf.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0015] **The gate exercises recording only; stop and the scripted actions are untested.**
  ci.sh runs `record` twice and nothing else. `stop`, the `-a` scripted
  actions, `--app-log`, `--settle` and `--cursor` are all documented, and
  nothing proves any of them still works.

  The `-a` actions are the sharpest gap, because a scripted click that
  quietly stops landing still produces a valid-looking video of an app
  sitting there doing nothing -- the same silent failure the blank check
  exists to catch, one level up.

  All of it is reachable with xclock or xterm on the existing Xvfb path,
  so this needs no new infrastructure, unlike the two backend items.
  Resolved (2026-09-08): two steps added to ci.sh.

  The scripted actions are exercised by recording an xterm running a shell that
  reads one line and writes it to a file, so the app itself reports what arrived.
  wait, type and key are covered. move and click are not -- neither xclock nor
  xterm reports a click anywhere the script can read -- and the step says so
  rather than implying coverage it lacks.

  stop is exercised by starting a -d 0 run and ending it, asserting stop prints
  the output path, the run then exits zero, and a video is there. --app-log rides
  along on the same run. stop is retried rather than waited for on the video
  file: a run becomes addressable when it writes its state file, after ffmpeg
  starts, so the .mp4 exists a moment before stop can find it by name. The first
  version of the step raced exactly there.

  Both steps proved able to fail: disabling the type action reddens the first,
  making stop print a different path reddens the second.

  xterm is now a gate dependency and joins both the required-programs check and
  the workflow's apt list; x11-apps does not ship it.

  Still uncovered: --settle and --cursor. --settle needs an app that is uniformly
  black for a known interval, which neither xclock nor xterm is.
  **Layman:** Half the tool's features have no automatic check behind them.
  Kind: test.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0016] **Warn when a Flatpak target is missing the flags it needs.**
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
  Resolved (2026-09-08): demoreel reads the caller's command line and, on a
  `flatpak run` missing any of the three flags, names which before the recording
  starts.

  A warning rather than a refusal, deliberately: a manifest with no wayland socket
  does not need --nosocket=wayland, and deciding that would mean knowing the app --
  which is the per-app knowledge the scope ceiling rules out. Matched by prefix, so
  --filesystem=/tmp/.X11-unix:ro counts as present.

  Exercised in four cases: no flags names all three; only --nosocket=wayland
  missing names that one; a complete command including the :ro form is silent; a
  non-Flatpak target is silent.

  The gate covers both directions, using a stub named flatpak -- what is under test
  is the reading of the command line, and the stub keeps the step working on a
  runner with no Flatpak installed. Proved able to fail: disabling the warning
  reddens it.
  **Layman:** Recording a Flatpak the wrong way gives a black video and no clue why.
  Kind: enhancement.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0017] **The Xvfb display has no auth cookie, while the --gpu display does.**
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
  Resolved (2026-09-08): both backends now put the display behind an
  MIT-MAGIC-COOKIE-1 cookie in a 0600 Xauthority file, handed to every client
  through XAUTHORITY.

  Measured first, as the bullet asked. Before: a client with XAUTHORITY=/dev/null
  read the geometry and grabbed a frame showing the window. Socket permissions are
  not the answer -- ss shows Xvfb listening on an abstract socket as well as the
  filesystem one, and the abstract namespace has no permissions at all. After: the
  uncredentialed client is refused for both, and one holding the run's cookie
  still works.

  The ordering is deliberate. The cookie is keyed to the display number and
  -displayfd is what reports it, and dropping -displayfd would cost the
  concurrency property the README calls non-negotiable. So: start with an empty
  auth file, learn the number, write the cookie, SIGHUP the server to re-read, and
  report success only once a client holding the cookie connects. Between start and
  reset the display is open and nothing has been drawn on it.

  xauth joins the Xvfb backend's required-programs check and the workflow's apt
  list. The gate probes the live run's own reported display; removing -auth
  reddens it.
  **Layman:** While a recording runs, other programs on the machine can watch that private display.
  Kind: security.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0018] **Text from `-a type` is visible in the process list while it is typed.**
  The type action runs `xdotool type --delay 60 <text>`, passing the text
  as a command-line argument. Command lines are readable by other local
  users through the process list for as long as the process runs, and the
  60ms delay means it runs for as long as the text is long.

  A demo that types into a login form is the obvious case, and it is a
  plausible thing to record.

  `xdotool type --file -` reads the text from stdin instead, which keeps
  it out of the process list. Same feature, same grammar, nothing exposed.
  Resolved (2026-09-08): the type action now feeds xdotool on stdin via
  `type --file -`. Same feature, same grammar; the helper gained a keyword-only
  stdin_text argument, so no existing call site changed.

  Measured with a canary as the typed text, scoped to xdotool's own processes --
  the first attempt matched the test harness's own command line and reported a
  leak that was the test's. Before: the canary was in xdotool's argv. After: it
  was not. Typing still lands, checked by having an xterm write back what it
  received.

  The bullet's "nothing exposed" was half right, and the difference is now
  measured. demoreel's OWN argv still carries the text, because -a 'type SECRET'
  is how the caller wrote it, and for the whole run rather than just the typing.
  Filed as DEMO-0025; SECURITY.md states the residual rather than claiming more
  than the code does.
  **Layman:** Anything the script types can be read by other users on the machine as it happens.
  Kind: security.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0019] **The run-state directory falls back to a predictable path under /tmp.**
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
  Resolved (2026-09-08): state_dir() now lstats the path before using it -- lstat
  rather than stat, because a symlink planted at that name is followed by stat and
  by chmod alike -- and stops unless the result is a directory the caller owns. A
  pre-existing plain file at the name used to raise an uncaught FileExistsError
  and now says what is wrong.

  Exercised in four situations: a normal run with XDG_RUNTIME_DIR set still works;
  the /tmp fallback with a planted symlink is refused; a plain file at the name is
  refused readably; the clean /tmp fallback works and leaves a 0700 directory we
  own. The ownership branch cannot be reached without root, so it was checked as a
  predicate against directories that really are root-owned rather than claimed.

  The gate covers it, inside its own scratch directory with XDG_RUNTIME_DIR
  pointed there -- planting the real name under /tmp would collide with any other
  recording on the machine. Proved able to fail: with the guard removed the step
  reddens.

  One correction to this bullet's reasoning. Unguarded, demoreel did not silently
  adopt a planted path: the chmod that follows fails and the run crashes with a
  traceback. The exposure worth closing is a symlink to a directory the caller
  DOES own, where the chmod succeeds and the state writes land wherever the
  attacker pointed.
  **Layman:** Without one environment variable set, run state lands somewhere another user could have prepared first.
  Kind: security.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0020] **The privacy promise is argued rather than demonstrated.**
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
  Resolved (2026-09-08): measured, and recorded in README's verified list
  beside the others.

  KWin's Magnifier was already enabled and was not touched. A window of one
  unique colour was opened on the real desktop over the user's ordinary
  session and confirmed mapped there by wmctrl. Both backends then recorded,
  and every frame of each recording was decoded at full resolution and
  checked against that colour.

  No pixel came within 40 of it -- closest 135.8 under Xvfb, 117.8 under
  --gpu. The whole Xvfb recording measured zero saturation. The --gpu frames
  are the shaded LunarG cube, so that backend reached the card while staying
  clean.

  The detector was proved able to fire rather than assumed to be: over a clip
  that really is the marker colour, encoded the same way, it matched every
  pixel. A first attempt reported a leak through an integer overflow in the
  analysis, not in the tool; the control is what made that distinguishable.

  Not a gate step -- it needs a real desktop to be private about, and CI has
  none.
  **Layman:** The one thing this tool exists to guarantee has never been checked in an actual recording.
  Kind: test.
  Source: adopt-project-2026-09-07.

- ✅ [DEMO-0021] **Three places implement the documentation-only decision; only its value has one home.**
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
  Resolved (2026-09-08): ci.sh --docs-mode now owns the decision, not just
  the glob. The workflow pipes the changed paths in and runs whatever comes
  back, reimplementing nothing.

  The pre-push hook is machine-wide, so its copy stays -- three
  implementations become two, which is what the bullet said was reachable.

  Behaviour-preserving and measured: the removed workflow logic and
  ci.sh --docs-mode were run side by side over every commit in this
  repository's history, and no verdict moved. Edge cases checked
  separately: all-documentation, mixed, code-only, empty input, blank
  lines.
  **Layman:** The rule for what counts as a docs push is written once but acted on in three separate places.
  Kind: refactor.
  Source: cold-read-2026-09-07.

- ✅ [DEMO-0022] **The gate never induces a blank recording, so the guard against one is untested.**
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
  Resolved (2026-09-08): ci.sh gained a step that induces the failing
  branch -- an app that maps a window then kills it while the shell owning
  it stays alive, leaving the display blank with the run still live. It
  asserts a non-zero exit, that the blank-display guard was the cause, that
  no path reached stdout, and that the partial video was left on disk.

  Proved it can fail: downgrading the guard's die() to note(), the exact
  change CLAUDE.md forbids, reddens the gate with "a blank recording
  exited 0".
  **Layman:** The check that refuses an empty video has itself never been checked.
  Kind: test.
  Source: cold-read-2026-09-07.

- ✅ [DEMO-0023] **CLAUDE.md changed direction and owes an independent cold read.**
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
  Resolved (2026-09-07): review-contract, genre standard, three loops of
  three cold lanes. Nine verified findings, all nine fixed.

  Loop 1 found five: the pipeline listed the scripted actions before
  ffmpeg when the code records first; the Flatpak section was headed
  "two extra flags" while its own example passes three; the blank-check
  trap stated the frame sample unconditionally when it is skipped once
  the app has exited; "no dependence on the caller's working directory"
  is a non-negotiable the tool breaches by design; and "ci.sh holds a
  third copy" of the threshold, when there are two literals.

  Loop 2 found three, one of them loop 1's own over-claim. Loop 3 found
  one, and it was loop 2's.

  Cap reached at three, and VIOLENT -- the final loop's only finding
  landed on text this run wrote. Under the skill's own rule, review of
  the document as it stands ends here and is not to be re-run. Eight of
  the nine findings were pre-existing rather than in the change that
  armed the gate, so the run was mostly an audit.

  The loop log is at docs/reviews/claude-md-loop-log.md, kept outside
  the document because it loads into every session.

  Limitation recorded there and worth repeating: the lanes are not
  cold and cannot be. Claude Code injects this project's CLAUDE.md as
  project instructions, so every lane held the document before it read
  its brief. All six lanes across loops 2 and 3 disclosed this
  unprompted.

  Two code findings were filed rather than fixed, since this is a
  documentation gate: DEMO-0024 (the tool and its gate disagree at the
  exact threshold value) and an annotation on DEMO-0011.
  **Layman:** One document was edited in a way that changes what future sessions do, and nobody independent has checked it.
  Kind: doc.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0024] **The tool and its gate disagree about a frame measuring exactly the threshold.**
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
  Resolved (2026-09-08): ci.sh's smoke assertion now fails at > 0.999,
  matching display_is_blank. The gate is not a user-facing surface, so
  aligning it to the tool changes no protected behaviour; changing the
  tool to match the gate would have failed runs that pass today, which
  the versioning overrides call breaking. Verified by reading both
  comparators out of the two files and running a frame measuring exactly
  the threshold through each: both now say not-blank.
  **Layman:** One exact value makes the tool say the app is there and the gate say it never arrived.
  Kind: fix.
  Source: review-contract-2026-09-07 loop 2.

- 💭 [DEMO-0025] **Action text still sits in demoreel's own command line for the whole run.**
  Found while closing DEMO-0018, by measuring the fix rather than assuming
  it. That item said `xdotool type --file -` leaves "nothing exposed".
  Half true: the text is out of xdotool's argv, and it is still in
  demoreel's, because `-a 'type SECRET'` is how the caller wrote it.

  Measured both, in one run: with a canary as the typed text, xdotool's
  argv did not contain it and demoreel's did.

  The exposure is also longer than the one that was closed. xdotool held
  the text only while typing; demoreel holds it from launch to teardown.

  Closing it needs a way to pass action text off the command line -- a
  file, or stdin. That is a new interface rather than a fix, and it needs
  weighing against the scope ceiling, which rules out a config file
  format. It may also be the caller's exposure to accept rather than the
  tool's to remove: the caller chose to put a secret in a command line,
  and could pass it some other way.

  Not urgent, and worth stating plainly rather than leaving SECURITY.md
  claiming more than the code does.
  Decided (2026-09-08) by the user, with the options put: accept it, and
  record why.

  The caller wrote the secret into a command line themselves and could
  have passed it another way, so the exposure is theirs to avoid rather
  than the tool's to remove. Closing it would mean a second way to feed
  action text in -- a file, or stdin -- which is the input format the
  scope ceiling rules out, exactly as this item predicted.

  SECURITY.md now says this is a decided limit rather than pending work.
  Before, it read "Tracked as DEMO-0025", which promised a fix that is not
  coming.
  **Layman:** Text a script types is no longer visible via the typing tool, but is still visible in demoreel's own command line.
  Kind: security.
  Source: in-session-2026-09-08.

- ✅ [DEMO-0026] **Any app that exits 0 without a window is told it is a single-instance app.**
  Surfaced by a cold lane during the README gate, as a code-side note
  rather than a document finding.

  `wait_for_window` dies when the app exits with status 0 before showing a
  window, and the message names the single-instance hand-over as the
  cause: "Close that copy, then run demoreel again."

  The first sentence is a fact and is always true. The rest is a
  diagnosis, and it is a guess -- a command that legitimately does its
  work and exits, or an app that failed for some unrelated reason and
  still returned 0, gets told to close a copy that is not running.

  Small, and the hand-over case is the common one on this machine
  (FIBR-0204), which is why the message was written that way. Worth
  softening rather than rewriting: state what happened, offer the
  single-instance explanation as the likely cause rather than the
  established one.

  Not urgent and not a correctness defect -- the run fails either way, and
  it fails for a real reason.
  Resolved (2026-09-08). The message now states what happened, offers the
  hand-over as the LIKELY cause, and names the other case -- a command
  that finished without needing a window.

  Demonstrated while working on this, which is what the item predicted:
  `demoreel record -- true` was told to close a copy of itself.

  Stderr text is explicitly not a protected surface
  (versioning-overrides.md § What is not a breaking surface), so this is
  not a breaking change.
  **Layman:** One error message explains a failure with a cause that may not be the real one.
  Kind: enhancement.
  Source: review-contract-2026-09-08 loop 3.

- ✅ [DEMO-0027] **A fresh clone of this repository has no gate at all.**
  The pre-push gate reaches this project through two settings that live
  outside it. `core.hooksPath` is `/home/ants/.claude/githooks`, an
  absolute path on this machine, and `ants.gate.command` is `./ci.sh` in
  this repository's LOCAL git config. Neither is cloned, and there is no
  `.githooks/` directory here and no `.git/hooks/pre-push`.

  So the gate exists for exactly one checkout on one machine. The
  repository is public: anyone who clones it gets ci.sh and no hook that
  runs it, and nothing tells them a gate was ever expected.

  The standard the machine works to treats a project with a pipeline, a
  gate script and no reachable pre-push hook as being in breach. This
  project is only not in breach because of configuration a contributor
  cannot see.

  A repository-local `.githooks/pre-push` that execs `./ci.sh`, plus one
  line in the README telling a contributor to run `git config
  core.hooksPath .githooks`, would make the gate travel with the code.
  Resolved (2026-09-08). `.githooks/pre-push` now travels with the code,
  and README.md gives the one command that turns it on.

  Kept thin: ci.sh already owns the glob and the matching, so the hook
  only finds the push range and hands the changed paths to `./ci.sh
  --docs-mode` -- the same division the GitHub workflow uses, so the mode
  decision still has one home. It gates the pushed commits in a detached
  worktree rather than the working tree, because those are the same only
  when the tree is clean.

  Verified all three paths by feeding it a push range directly rather than
  assuming: a code push ran the full gate and exited 0, a
  documentation-only push selected `./ci.sh --docs` and exited 0, and a
  commit with a deliberately broken gate step was refused with "gate
  FAILED ... push aborted" and exit 1. shellcheck clean.

  Corrected the README while there. It claimed the gate "runs
  automatically before a push" -- true only on the machine that had
  configured it -- and described the hook as machine-wide doing its own
  glob matching, which is not true of the hook this repository now ships.

  Not enabled in this checkout: core.hooksPath here still points at the
  machine-wide hook, which is the user's setup to change.
  **Layman:** The check that runs before a push is set up on this machine, not in the project, so nobody else gets it.
  Kind: chore.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0028] **The blank threshold still has two homes; the project already solved this twice.**
  DEMO-0024 fixed the comparators disagreeing. The duplication that
  allowed it is still there: `display_is_blank` holds the threshold and
  its comparator, and ci.sh's smoke assertion holds its own copy of both.
  CLAUDE.md says to move every copy together, which is a rule a person has
  to remember.

  This project has already answered this question twice, the same way
  both times. `ci.sh --ruff-version` and `ci.sh --docs-glob` exist so that
  the workflow reads a value rather than restating it, and the comment on
  each says why. The threshold is the same shape of problem pointing the
  other way: the tool owns the value, so the gate should ask the tool.

  A read-only `demoreel --blank-threshold` that prints the number, with
  ci.sh reading it, would leave one home. That adds a flag to the
  command-line surface, which the versioning overrides make a protected
  surface -- so it is worth deciding whether a hidden argument or a
  smaller mechanism is better before adding it.
  Measured (2026-09-08): unifying the two copies means choosing a cost profile
  too, and neither copy is uniformly better.

  The tool counts with `max(frame.count(v) for v in set(frame))`, which is one
  pass per distinct byte value. The gate's copy uses `Counter(...).most_common(1)`,
  a single pass. On a 1600x1000 frame they agree exactly on the value, and their
  cost inverts with the picture: on an empty display, one distinct value, the
  tool's form is about five times FASTER; on a busy screen with 256 distinct
  values it is about twice as slow.

  That favours keeping the tool's form as the shared one. The case it wins is a
  blank display, which is exactly what `wait_until_drawn` polls against, and the
  case it loses is sampled once at the end of a run.

  So whichever direction this item takes, it should move the tool's expression
  rather than the gate's, and say why in a comment -- otherwise the next reader
  sees an obviously worse-looking loop and tidies it into the Counter form.
  Resolved (2026-09-08). The threshold and its comparator are now
  `BLANK_THRESHOLD` and `frame_is_flat` in demoreel, and ci.sh imports
  them rather than restating them -- the same answer this project reached
  for `ci.sh --ruff-version` and `--docs-glob`, pointing the other way.
  Importing runs nothing: demoreel's module level is imports and
  constants, and main() is behind an `__name__` guard.

  Kept the tool's expression rather than the gate's, as this item's
  measurement said to, and recorded why beside it -- otherwise the next
  reader tidies it into Counter.most_common and makes the polling case
  worse.

  No new flag. `demoreel --blank-threshold` was the suggestion here, but
  the command line is a protected surface and a permanent public flag is
  too much to pay for a test convenience. Loading the module by path costs
  nothing and adds no surface.

  CLAUDE.md's trap was updated: ci.sh is no longer one of the copies.
  **Layman:** One number is written down in two files, and keeping them in step is nobody's job.
  Kind: refactor.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0029] **A failing gate step can leave a recorder running and block the next run.**
  Two gate steps start a `-d 0` recording in the background. If an
  assertion between the launch and the stop fails, the step exits and the
  recorder is left running -- `-d 0` means it never ends by itself.

  Measured during this session rather than imagined. A failing step left a
  run named `gatecookie` alive; the next gate run then refused that name,
  and the failure it reported was the leftover rather than the defect. It
  cost two cycles to recognise.

  The cookie step now stops its recorder before failing. The stop step
  does not: its `stop never found the running recording` path exits with
  the recorder still up, and that is the branch most likely to fire.

  One trap at the top of the gate that stops every run it may have
  started, alongside the existing temp-directory trap, would make this
  structural rather than per-step.
  Resolved (2026-09-08). One EXIT trap, as the item asked. Each step that
  launches a recorder appends its pid to `gate_pids`; the trap signals
  them, waits for each to run its own teardown, and SIGKILLs anything that
  outlives the wait.

  The wait alone was not enough, which only appeared once the abort case
  was measured properly. A recorder signalled before it has installed its
  handlers dies without tearing anything down and leaves its Xvfb holding
  a display number. So the trap also sweeps, matching on the auth file
  path rather than the process name, and only for the gate's own `gate*`
  runs -- two sessions may record at once, and killing every Xvfb this
  user owns would end someone else's recording.

  A/B with an injected failure between the launch and the stop: the old
  ci.sh leaves an Xvfb and a state file, the new one leaves neither.

  Worth recording, because it cost most of this item: the detector was
  `pgrep -x demoreel`, which matches nothing. demoreel is a Python script,
  so its process name is `python3`, and every "no recorder left behind"
  reading that check produced was true by construction. The Xvfb count was
  the only honest signal, and it had been reporting the leak throughout.

  Checked separately, and NOT a defect: demoreel's own SIGTERM teardown is
  clean at every point in startup -- ten of ten, sampled from 0.05s to
  3.5s -- and its deliberate blank-recording failure exit cleans up too.
  **Layman:** When a check fails, it can leave a recording going that then gets in the way of the next attempt.
  Kind: test.
  Source: recommendation-2026-09-08.

- 💭 [DEMO-0030] **The gate still does not exercise --settle or --cursor.**
  Named when DEMO-0015 closed, and filed here so it is not lost with it.
  Both flags are documented in README.md, and ci.sh mentions neither.

  `--cursor` is the cheap one: record with it and without it and assert
  the frames differ, which needs no new target app.

  `--settle` is harder and that is why it was left. It needs an app that
  is uniformly one colour for a known interval and then draws, which
  neither xclock nor xterm is. A tiny X client written for the purpose
  would do it, but that is a test fixture the project would then own --
  weigh that against the value before building one.

  The README already records a hand-verification of `--settle` against
  exactly such a window, so the behaviour is not unverified; it is
  unguarded against regression.
  Progress (2026-09-08). `--cursor` is covered; `--settle` is not, and
  this item stays open for it.

  The `--cursor` step records the same static app twice, once with the
  flag and once without, and compares a sampled frame. The control was
  measured before the assertion was written: two runs WITHOUT the flag are
  byte-identical in that frame -- zero differing bytes -- and adding it
  changes 153 of 120000. Without that control the test would prove
  nothing.

  xterm running `sleep`, not xclock: a clock's second hand moves, and a
  frame comparison cannot tell a moving hand from a drawn pointer.

  Bounded at both ends. A bare "the frames differ" would pass if the two
  recordings differed for any unrelated reason, so the step also refuses a
  difference too large to be a pointer. Proved not hollow: with
  `-draw_mouse` forced to 0, the step reports "--cursor changed nothing"
  and exits 1.

  `--settle` still needs the fixture this item predicted. Checked whether
  an existing target could serve and none can: the fixture must be
  uniformly one colour for a known interval and then draw, and this
  project has already measured a real xterm at 0.977 -- below the blank
  threshold -- because it paints a cursor. So covering `--settle` means
  owning a purpose-built X client, which is the trade this item asked to
  weigh. Left for the user to decide rather than decided quietly.
  Decided (2026-09-08) by the user, with the options put: `--cursor` is
  covered by the gate, and `--settle` stays hand-verified.

  The fixture this item predicted is real and was checked rather than
  assumed: it must be uniformly one colour for a known interval and then
  draw, and nothing installed does that -- this project has already
  measured a real xterm at 0.977, below the blank threshold, because it
  paints a cursor. So covering `--settle` means owning a purpose-built X
  client for the life of the project.

  Weighed as the item asked. The behaviour is already hand-verified and
  written up in README.md, so what is missing is protection against future
  regression, not evidence that it works. Not worth a permanent fixture
  today.

  Closing as considered rather than shipped: half of what this item asked
  for is done, and saying otherwise would be a false record.
  **Layman:** Two documented options have no automatic check behind them.
  Kind: test.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0031] **Nothing mechanical keeps the pinned action in step with its latest release.**
  DEMO-0010 is a standing chore: two versions are pinned and both go stale
  on their own. Checked on 2026-09-08 and both were current, which is the
  problem -- the check happened because a session went looking.

  The ruff pin has a mechanism already, and a good one: the gate fails if
  the installed ruff is not the pinned one, so drift between the dev
  machine and CI cannot go unnoticed. The action pin has nothing. It is a
  SHA with a version comment, and only a reader comparing it against
  upstream would ever notice it aging.

  A `.github/dependabot.yml` watching `github-actions` would open a pull
  request when the action moves, turning that half of DEMO-0010 from a
  habit into a notification. It costs one small file and no CI minutes on
  a public repository.

  It does not replace DEMO-0010: the ruff pin still has to move with the
  version installed here, which no bot can know.
  Resolved (2026-09-08). `.github/dependabot.yml` watches `github-actions`
  weekly, so the checkout pin opens a pull request when it moves instead
  of aging in silence. No Actions minutes: Dependabot runs on GitHub's own
  infrastructure.

  Said in the file itself that this does NOT cover the ruff pin, so the
  next reader does not assume both halves of DEMO-0010 are now mechanical.
  RUFF_VERSION has to move with the ruff installed on the machine running
  the gate, which no bot can know, and the gate already fails when the two
  disagree.
  **Layman:** Keeping one pinned version fresh depends on somebody remembering to look.
  Kind: chore.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0032] **Decide what the first release's notes actually say before tagging.**
  CHANGELOG.md carries one entry describing what demoreel is, written on
  the grounds that nothing has been tagged, so everything belongs to the
  first release.

  That was reasonable when it was written and is now thin. Several changes
  have landed since that a reader would want named -- the private display
  gained an auth cookie, scripted text left the process list, the
  run-state directory is checked before use. Those are security
  properties, and a first release that mentions none of them undersells
  what it ships.

  The release standard warns against reconstructing a changelog from a
  commit range, so this is not a request to do that. It is a decision to
  make deliberately before the tag: either the single entry stands as the
  initial-release description, or the notable items get their own lines.

  Going forward the cheaper habit is to add each item's entry as it lands,
  using the changelog verb, rather than at release time.
  Decided (2026-09-08) by the user, with the options put: keep the "what
  this is" entry as the lead, and add named lines for the notable items.

  Six added. Five under Security -- the private display's auth cookie
  (DEMO-0017), scripted text leaving the process list (DEMO-0018), the
  run-state directory ownership check (DEMO-0019), stop no longer
  signalling a process it did not start (DEMO-0036), and the workflow's
  token and shell hardening (DEMO-0037, DEMO-0038). One under Fixed, the
  error message that named a cause it could not know (DEMO-0026). One
  under Added, the pre-push gate now shipping with the repository
  (DEMO-0027).

  Not a reconstruction from the commit range, which releases.md warns
  against: every line cites the roadmap item it came from, and the ids
  were read off the roadmap rather than recalled.

  Reordered so the headline entry leads its section -- the changelog verb
  inserts at the top of a category, which had put a contributor-facing
  line above the one describing the tool.

  The habit this item asked for starts here: an entry goes in as its item
  lands, through the changelog verb, rather than at release time.
  **Layman:** The changelog describes what the tool is, and says nothing about the fixes made since.
  Kind: release.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0035] **The gate's linter has never analysed a single source file.**
  `ci.sh` runs `ruff check .` and reports "All checks passed!". Asked
  which files that command actually selects, ruff answers with one:
  `ruff.toml`. The source file is named `demoreel` with no extension, and
  ruff's default include list is `*.py`, `*.pyi` and `*.ipynb` -- so the
  only Python in the project is invisible to the only linter.

  Not theoretical. `ruff check demoreel`, same config, reports PLW1510 on
  the `xauth` call added today: a `subprocess.run` with no explicit
  `check` argument. PLW is in the project's own select list, so this is a
  rule the project chose, breached in the tree, with the gate green.

  Every "All checks passed!" in this project's history was that command
  finding nothing to look at.

  The fix is one line either way: name the file (`ruff check demoreel
  ci.sh` style) or add `extend-include = ["demoreel"]` to `ruff.toml`.
  Naming the file in ci.sh is the more honest of the two, because the next
  source file added would silently fall out of an include list the same
  way.

  Fix the PLW1510 in the same change, or the first honest run is red.
  Resolved (2026-09-08). The lint step now names the tree and the
  source file: `ruff check . demoreel`. Naming the tree as well keeps any
  *.py added later covered without a second edit.

  The hollow gate was the failure, not the one breach it hid, so the step
  also asserts ruff selected the file and fails loudly if it did not.
  Proved the assertion fires by running it against the old invocation --
  it reports ruff selecting `ruff.toml` alone and exits 1.

  Fixed the PLW1510 breach in the same change. The `xauth` call already
  tests `added.returncode` itself, so the explicit `check=False` states
  what the code was doing. Checked the other two `subprocess.run` sites:
  both were already deliberate -- `xdotool()` takes `check` as a
  parameter, and the frame grab carries a noqa with its reason.

  Verified: ./ci.sh passes end to end, the lint step reporting "ruff
  analysed demoreel". Removed the warning paragraph from CLAUDE.md, as
  that paragraph instructed.
  **Layman:** The automatic code check passes because it is looking at nothing.
  Kind: fix.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0036] **A stale state file lets stop terminate a process it never started.**
  The state file records a pid and nothing else, and `alive()` asks only
  whether SOME process holds that pid. A run killed with SIGKILL, or lost
  to a power cut, leaves its state file behind -- the cleanup is in a
  `finally` block, which those paths never reach. Linux then recycles the
  pid.

  So `cmd_stop` reads a stale file, `alive()` says yes about a process
  that is not ours, and it sends SIGUSR1. The default action for SIGUSR1
  is to terminate.

  Demonstrated rather than reasoned about, using a process created for the
  test: a `sleep` was started, a state file naming its pid was written as
  a killed run would have left one, and `demoreel stop` ended it. The
  shell reported "User defined signal 1".

  The impact is bounded -- same user, no privilege gained -- but it is an
  unrelated process dying because a recording crashed earlier, which is
  hard to attribute and easy to blame on something else.

  Recording something that identifies the process incarnation alongside
  the pid would close it. The start time in field 22 of `/proc/<pid>/stat`
  is the usual choice: it is unique per pid incarnation, readable without
  privilege, and comparing it before signalling costs one file read.
  Resolved (2026-09-08). The run records the start time from field 22 of
  /proc/<pid>/stat alongside the pid, and `is_our_run()` compares it
  before treating a state file as ours. It replaces the bare `alive()` at
  both call sites.

  The second call site was a bug in its own right, not just a copy: the
  duplicate-name guard refused to start a new run when a stale file's pid
  had been recycled, so a crashed recording could block its own name.

  An entry with no recorded start time cannot be checked, and an entry
  that cannot be checked is the one this refuses. Nothing is released yet,
  so no state file in the wild has the old shape.

  Reproduced against both versions, using a `sleep` as the stand-in for a
  process that inherited the number. Pre-fix: stop printed a path, exited
  0, and the shell reported the sleep dying with "User defined signal 1".
  Post-fix: the no-start-time and wrong-start-time cases are both refused,
  the process survives, and the stale files are cleaned up.

  Locked in ci.sh as its own step, proved red against the pre-fix code and
  green against the fix.

  A race remains in principle -- the process could exit between the check
  and the signal -- but that window is microseconds against however long a
  stale file has been lying around. Said so in the code rather than
  implying the hole is fully closed.
  Release level (2026-09-08), decided by the user and recorded here
  because nothing else on disk carries it.

  This fix changes `stop`'s exit status in an observable case: against a
  state file whose process is not ours it used to exit 0 and print a path,
  and now exits 1 saying no recording is running. versioning-overrides.md
  protects "the exit status generally" and says its list is not
  exhaustive, so under the 0.x ladder a break would have earned 0.2.0
  rather than 0.1.1.

  Judged NOT a break, and shipped in 0.1.1. The old exit 0 was the defect
  rather than a promise: in that situation no recording IS running, so the
  tool now answers what it documents, and the old answer came bundled with
  terminating an unrelated process. Nothing could sensibly have depended
  on it.

  Written down because the next release will meet this question again and
  the reasoning is not derivable from the diff.
  **Layman:** If a recording is killed abruptly, a later stop can kill an unrelated program instead.
  Kind: security.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0037] **The workflow leaves its credentials readable to every later step.**
  Found by `zizmor` as `artipacked`, medium confidence.

  `actions/checkout` writes the job's token into `.git/config` unless it is
  told `persist-credentials: false`. The workflow does not tell it, so the
  token stays on disk for the rest of the job -- readable by every later
  step, and by anything those steps run.

  This job runs `./ci.sh`, which runs the linter, the recorder and the
  target apps. None of that needs the token, and none of it should be able
  to reach it.

  The repository is public, so the blast radius is bounded by what the
  token can do rather than by who can read the workflow -- but a public
  repository is also the one where a supply-chain step is most likely to
  be someone else's code.

  The fix is one line under the existing `with:` block. Check first that
  nothing in the gate needs to push or authenticate; nothing appears to,
  since the workflow only reads.
  Resolved (2026-09-08). `persist-credentials: false` added to the
  checkout step. Checked first that nothing in the job needs the token:
  it only reads, and fetch-depth still gets its history during checkout
  itself.

  Verified: zizmor reports no findings where it previously reported
  artipacked.
  **Layman:** The build checkout stores a token on disk where anything later in the job can read it.
  Kind: security.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0038] **A step's output is expanded straight into a shell command line.**
  Found by `zizmor` as `template-injection`, low confidence.

  The workflow's last step is `run: ./ci.sh ${{ steps.mode.outputs.mode
  }}`. GitHub substitutes that expression into the shell script before the
  shell sees it, so the value is code rather than an argument.

  Here the value comes from `ci.sh --docs-mode`, which prints `--docs` or
  nothing, so there is no live injection -- which is why the tool rates it
  low and why this is filed for hardening rather than as a breach.

  What makes it worth closing anyway is that the pattern outlives the
  reasoning. The guarantee rests on what `--docs-mode` can print, which is
  a fact about a script that will keep changing, checked by nobody.
  Passing the value through `env:` and referencing it as a shell variable
  removes the question rather than answering it.

  The same step is DEMO-0021's, so this is worth folding in if that area
  is touched again.
  Resolved (2026-09-08). The mode value now reaches the gate step through
  `env:` and is referenced as a quoted shell variable.

  Fixed the same pattern in the mode step as well, rather than only the
  one step zizmor named -- its four expressions are substituted the same
  way, and leaving them would have been fixing one copy of the defect.

  The argument is quoted and empty for a full run. Verified rather than
  assumed: `./ci.sh ""` runs past the documentation-only exit into the
  required-programs and lint steps, because ci.sh reads its argument as
  "${1:-}" and an empty one is simply not "--docs".

  Verified: actionlint clean, zizmor reports no findings.
  **Layman:** The build pastes a value into a command instead of passing it as data.
  Kind: security.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0039] **Every external tool is invoked by bare name, resolved through PATH.**
  Flagged at six call sites by both `ruff` (S607) and `bandit` (B607):
  `Xvfb`, `ffmpeg`, `xdotool`, `xauth`, `xwfb-run` and the caller's own
  command are all started by name.

  This is an investigation rather than a defect, and the honest reading is
  that it is probably fine. demoreel runs as the caller with no elevated
  privilege, so anyone who can alter that caller's PATH can already run
  code as them -- resolving absolutely would move nothing.

  What makes it worth an hour is the one asymmetry: demoreel is invoked by
  other sessions and by a skill, so its PATH is inherited rather than
  chosen, and it is the one program on this machine designed to be started
  by something else. A tool substituted under it would see the private
  display, which is the whole thing this project protects.

  Decide it deliberately: either resolve the fixed helpers once at startup
  with `shutil.which` and use the absolute paths, or record why bare names
  are correct here. The caller's own command stays a bare name whatever is
  decided -- it is the caller's to choose, and the required-programs check
  already uses `shutil.which` for its own probe.
  Decided (2026-09-08) by the user, with both options put: leave the bare
  names as they are, and record why.

  The reasoning the investigation asked for. demoreel runs as the caller
  with no elevation, so anyone who can alter that PATH can already run
  code as them; `shutil.which` resolves through the same PATH, so pinning
  would be the same trust wearing a different hat. The asymmetry that made
  it worth an hour is real and is now written down rather than re-derived:
  demoreel inherits its PATH rather than choosing one, because it is meant
  to be started by other tools, so a substituted helper would see the
  private display.

  Recorded in two places on purpose. SECURITY.md gains it as a trust
  boundary, where an outside reader looks and where the other boundaries
  already are. `.claude/audit/audit-config.json` carries the same decision
  for the next sweep, with a `revisit_if` naming what would overturn it --
  privilege, setuid, or invocation by something running as another user.
  **Layman:** The tool finds its helper programs by name, so whatever is first on the search path wins.
  Kind: investigate.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0040] **Nothing records which security findings are by design, so every run re-derives them.**
  This project has no audit config, so a security sweep starts from raw
  tool output every time.

  Most of that output is by construction. `bandit` at security-pass
  threshold returns fourteen findings, of which eleven are the subprocess
  family -- B404, B603, B607 -- on a tool whose entire job is starting
  subprocesses. `ruff --select S` reports the same sites again as S603 and
  S607. `vulture` reports the `signum` parameter of the signal handler as
  an unused variable, which is a signature the interpreter requires.

  One finding is real and already handled: `bandit` B108 on the `/tmp`
  fallback in `state_dir`, which DEMO-0019 guarded rather than removed --
  so the path is still hardcoded and the tool will keep naming it.

  A small `.claude/audit/audit-config.json` recording those as calibrated,
  with the reason beside each, would make the next run's output the part
  that is new. Without it, whoever runs the next sweep re-decides the same
  fourteen findings and may decide them differently.

  Record the reason, not just the rule id -- a suppression with no
  reasoning is indistinguishable from one added to make a report quiet.
  Resolved (2026-09-08). `.claude/audit/audit-config.json` now records the
  calibration, each entry carrying its reason as the item asked: the
  subprocess family on a tool whose job is starting subprocesses, the
  bare-name decision from DEMO-0039, B108 on the /tmp fallback that
  DEMO-0019 guarded rather than removed, and vulture's `signum`, which is
  a signature the interpreter requires.

  Ran the tools rather than copying this item's description of them, and
  two things came back different. zizmor's two "suppressed" findings are
  not its own defaults: --persona=auditor shows `anonymous-definition` and
  `concurrency-limits`, both real and both below the default threshold.
  They are recorded under `known_open` rather than `calibrated`, because
  neither is a false positive and neither was acted on. semgrep is
  installed but has never been run against this project, so it is marked
  as having no baseline rather than described as if it had one.
  **Layman:** The security tools flag the same expected things every time, and nobody has written down that they are expected.
  Kind: chore.
  Source: check-code-2026-09-08.

- ✅ [DEMO-0041] **While --settle waits for an app to draw, it competes with it for the machine.**
  `wait_until_drawn` polls `display_is_blank` every 0.25 s, and each call
  spawns a fresh ffmpeg to grab one frame off the display.

  Measured in CPU time rather than wall clock, because the machine was
  building something else at the time and a wall-clock figure from a
  contended machine is not a slow number, it is no number at all. One
  sample costs about 112 ms of CPU on a 1600x1000 display and moves 1.6 MB
  across a process boundary. Polling every 250 ms, that is most of a core
  for as long as the wait lasts.

  It bites only when `--settle` is used, and that is the sharp end of it:
  `--settle` exists for apps that spend seconds building GPU acceleration
  structures, so the sampler is burning CPU on the same machine, at the
  same moment, as the work it is waiting for. A default run samples once
  at the end and pays this no attention.

  One obvious idea was measured and does NOT work. Decimating the frame
  before counting -- `scale=128:80:flags=neighbor`, a hundredth of the
  data -- gives an all but identical answer (0.98056 against 0.98057 on a
  small window, same verdict on an empty display) and saves only about
  10%, because the cost is the process spawn and the capture, not the
  data. So a smaller frame is not the lever.

  What is left to investigate: back the poll off as the wait lengthens, or
  keep one sampler alive instead of spawning per poll. The second is
  faster and larger -- it means holding an ffmpeg open or talking X
  directly, and the project is standard-library-only by design.
  Resolved (2026-09-08). Took the first of the two options this item left
  open: back the poll off as the wait lengthens, rather than keeping a
  sampler alive. The second means holding an ffmpeg open or speaking X
  directly, and this tool is standard-library-only by design.

  The poll starts tighter than the old fixed interval and widens to a
  ceiling. From the per-sample cost measured above, a 20s settle takes 22
  samples instead of 56, and a 30s settle 31 instead of 83. A fast-drawing
  app is answered sooner than before, because the first interval is
  shorter.

  What it costs is stated in the code rather than hidden: up to the
  ceiling between the app drawing and the recorder noticing, against a
  fixed quarter-second. That is the right trade when the alternative is
  taking CPU from the app to find out a second earlier.

  The dead end this item measured is recorded beside the loop so it is not
  retried: decimating the frame gives the same answer and saves about 10%,
  because the cost is the process spawn and the capture, not the data.

  Verified directly, since the gate does not exercise --settle. Against a
  display that never draws it returns False after exactly the timeout, in
  7 samples where the old interval would have taken 12. Against one that
  draws on the third look it returns True in a quarter of a second.
  **Layman:** The check that waits for the app to appear is itself expensive, and runs four times a second.
  Kind: perf.
  Source: optimisation-pass-2026-09-08.

- 💭 [DEMO-0042] **The gate records nine times, one after another, before every push.**
  `ci.sh` now performs nine `demoreel record` invocations. Seven ask for a
  duration -- 12, 5, 4, 3, 3 seconds and two of zero -- and each pays the
  fixed setup on top. The recording steps dominate the gate's wall time,
  and the gate runs before every push as well as on CI.

  The steps are independent by construction. Each run gets its own display
  number from the server rather than choosing one, and the two that need
  naming already use distinct `-n` values, so nothing about them requires
  running in sequence.

  Against that, two real objections. Parallel recordings contend for CPU
  on the runner, and several of these steps are timing-sensitive -- the
  stop step already had to be rewritten around a race, and the cookie step
  left an orphan when it failed. Making them concurrent could trade a
  minute of wall time for a flaky gate, which is a bad trade for a check
  that gates every push.

  So this is an investigation, not a plan. Measure the gate's wall time on
  a quiet machine first -- nothing here has, because the machine was busy
  during this pass -- and if the recordings are as dominant as their
  durations suggest, try the two cheapest steps concurrently before
  reaching for the rest. DEMO-0029's teardown trap should land first;
  parallel steps make an orphan harder to attribute, not easier.
  Measured (2026-09-08), as this item asked, and DEMO-0029's teardown
  landed first as it also asked.

  The full gate takes about 54 seconds: 53.87s and 53.75s on two runs.
  Both were taken at a load average around 8, so the quiet-machine figure
  this item wanted is still missing -- something else on this machine was
  busy throughout. What the pair does show is that the number is not
  contention-sensitive: two runs under a heavy load agreed to within a
  tenth of a second, which is not what a CPU-bound gate does.

  The recordings are as dominant as their durations suggested. The gate
  makes ten recording runs; their requested durations come to about 36
  seconds, plus two `-d 0` runs that end when stopped. So roughly
  three-quarters of the gate is recording, and the remaining ~14 seconds
  is fixed setup spread over ten runs -- about 1.4s each, which agrees
  with DEMO-0012's estimate from the other direction.

  The single largest step is the scripted-actions run at 12 seconds, a
  third of all the recording time. That is a bigger lever than
  concurrency and does not risk the flakiness this item warns about.

  This item also got MORE expensive today, which is worth stating: the
  --cursor coverage added under DEMO-0030 is two further 3-second
  recordings, so about 6 of the 54 seconds is new.

  Recommendation: do not make the steps concurrent. The item's own
  objection stands -- several steps are timing-sensitive, the stop step
  already had to be rewritten around a race, and a flaky gate is a bad
  trade for a check that runs before every push. The payoff is at most
  ten to fifteen seconds. Shortening the 12-second actions run, if its
  assertions still hold, is the cheaper and safer place to look.

  Left open for the user's call rather than closed on that recommendation.
  Decided (2026-09-08) by the user, on the measurement above: leave the
  gate sequential.

  The item's own objection is what decided it. Several steps are
  timing-sensitive, the stop step already had to be rewritten around a
  race, and a check that fails at random is worse than a slow one for
  something that runs before every push. The payoff was at most ten to
  fifteen seconds of a fifty-four second run.

  The measurement stays useful whatever happens next: three-quarters of
  the gate is recording, the fixed setup is about 1.4s per run, and the
  single largest step is the twelve-second scripted-actions run. That last
  is the cheaper lever if the gate's cost ever does become a problem.
  **Layman:** The pre-push check runs nine separate recordings in a row, and waits for each.
  Kind: perf.
  Source: optimisation-pass-2026-09-08.

## 0.2.0 — Stricter guards and honest durations

Each of these changes what an existing caller receives, which is what a
MINOR is spent on while the leading zero is there.

- ✅ [DEMO-0008] **The blank check samples the display once, near the end of the run.**
  The guard asks whether the display is blank after recording. An app
  that draws nothing until the final moments passes it, and hands back
  a video that is mostly empty.

  Sampling once more, early in the run, would catch that without
  changing what the check means. The threshold is shared with --settle
  and is load-bearing in both roles, so it must not be tuned for one.
  Resolved (2026-09-19): a second sample halfway through the -d
  countdown, chosen by the user over a fixed offset or periodic sampling.
  Blank there fails the run on the spot; -d 0 keeps the end sample only.
  Threshold untouched. Gate step "a recording blank until its second half
  is refused" watched red against the build before it (exit 0).
  **Layman:** A video that was empty for most of its length can still pass the check.
  Kind: fix.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0011] **Two concurrent runs sharing a name clobber each other's state file.**
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
  Resolved (2026-09-19): the duplicate-name check is an flock on
  `<name>.lock` held for the run's life (`claim_name`), so it has no
  check-then-write gap. Ten simultaneous pairs: one records, one exits 1.
  Gate step "two runs started together under one name" watched red against
  the old code (both exited 0). stdout of `stop` is unchanged.
  **Layman:** Start two recordings at once without naming them and one becomes impossible to stop.
  Kind: fix.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0012] **Requested duration overshoots, and every run pays about a second of fixed setup.**
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
  Measured (2026-09-08) during an optimisation pass, so whoever implements this
  has the anatomy rather than the symptom.

  The fixed second is two half-second sleeps and nothing else: one in
  `start_ffmpeg` after the recorder is launched, one in `cmd_record` after the
  window is moved and sized. A third, 0.1 s, was added later in `start_xvfb`
  while waiting for the auth cookie to take effect -- that one already polls a
  real condition rather than sleeping blind, and is the shape the other two
  want.

  On top of those, the wait loops poll on a 0.25 s granularity, so a window that
  appears just after a poll costs up to another quarter second, and the duration
  loop polls at 0.2 s, which is part of the overshoot half of this item.

  One thing NOT worth pursuing, measured rather than assumed: `wait_for_window`
  spawning an xdotool per poll costs about 2.1 ms of CPU each. It is negligible
  against the sleeps, so waiting on the condition is the whole of the win here
  and the process spawns are not worth removing.
  Resolved (2026-09-19): the countdown starts at ffmpeg's first
  progress report, and the recorder stops before the end-of-run sample.
  The resize and window waits poll real conditions. -d 1/3/6 now give
  1.2/3.2/6.2 s (was +1.17 s), wall time -d + 0.93 s (was + 2.3 s). The
  remaining 0.2 s is ffmpeg's own start and stop, left rather than hidden
  behind a tuned constant. Gate asserts -d 5 lands in [5.0, 5.5].
  **Layman:** Ask for a 3 second clip and you get just over 4 seconds, after a second of waiting.
  Kind: perf.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0033] **When the blank check cannot take its sample, it reports the run as fine.**
  `display_is_blank` grabs one frame and, when the grab produces nothing,
  returns False -- with the comment that a failed sample is not evidence
  of a blank display. The reasoning is sound and the consequence is not:
  False means not blank, which is the success path.

  So the guard disarms itself precisely when it stops working, and it does
  so silently. That is the same shape of failure the guard exists to catch
  -- a valid file, exit 0, and nothing in the picture -- one level up.

  Demonstrated rather than argued: called against a display that cannot be
  sampled, the function returns False.

  It is not hypothetical. The sample takes the run's environment because
  the display now needs an auth cookie, so anything wrong with that
  environment produces an empty grab rather than an error, and the run
  succeeds. `wait_until_drawn` shares the function, so `--settle` returns
  immediately in the same conditions.

  The fix is to make the three cases distinct -- blank, not blank, could
  not tell -- and treat the third as a failure or at minimum a warning
  naming the reason. Failing a run that succeeds today is breaking under
  the versioning overrides, which is why this sits here rather than in the
  patch section.
  Resolved (2026-09-19): `display_is_blank` raises `SampleError` with
  ffmpeg's reason when no full frame comes back. The end-of-run check
  fails the run on it, and `--settle` stops the run. Gate step "the blank
  check says when it could not look" samples a real empty display with and
  without its cookie; watched red against the old `return False`.
  **Layman:** The check that refuses an empty video quietly passes everything if its own measurement breaks.
  Kind: fix.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0034] **A run cannot be stopped until it has already started recording.**
  A run becomes addressable when it writes its state file, which happens
  after the window appears and after ffmpeg starts -- so up to the startup
  timeout, twenty seconds by default, `demoreel stop` cannot find a run
  that is demonstrably launching.

  Reproduced with the two commands the README used to show side by side:
  the stop exits 1 saying no recording of that name is running, while the
  recording carries on. With `-d 0` that leaves a run nothing will ever
  end, which is how it was found.

  The README now separates the steps and shows a retry loop, and the gate
  retries for the same reason. Both are workarounds for the same gap, and
  three cold lanes independently read the original snippet as a defect.

  Two routes, and they are not equivalent. Writing the state file earlier
  makes the run addressable sooner, but the state file is also what the
  duplicate-name check reads, so moving it interacts directly with
  DEMO-0011 and should be designed with it rather than before it. Having
  `stop` wait briefly for a matching name is smaller, and changes what
  `stop` does when there is genuinely no such run -- which is a
  command-line surface the versioning overrides protect.

  Either way the observable behaviour of `stop` changes, so it sits here.
  Resolved (2026-09-19): the state file is written at the run's start with
  `recording:false` and rewritten once ffmpeg starts. `stop` waits for a
  starting run to record, and looks for up to STOP_GRACE (1 s) before
  saying none exists. Ten back-to-back record/stop pairs all produced a
  video. README's retry loop and the gate's are gone.
  **Layman:** Start a recording and try to stop it straight away, and you are told it is not running.
  Kind: enhancement.
  Source: recommendation-2026-09-08.

- ✅ [DEMO-0043] **On --gpu, vkcube's window is never found, so every run waits out the startup timeout.**
  Measured on 0.1.1 and on the DEMO-0012 build alike:
  `record -d 3 -s 640x480 --gpu -- vkcube` prints "no window appeared
  within 20s; recording anyway", takes about 24 s of wall time, and the
  cube sits unresized in the frame. The recording itself is correct.

  `wait_for_window` searches `xdotool search --onlyvisible --name .`, so
  the likely cause is that the window under rootful Xwayland on cage has
  no name or is not reported as visible. Not yet diagnosed.

  Fixing it changes no protected surface, so it is a PATCH, filed here
  because 0.2.0 is the next release. The gate cannot catch it: it records
  on Xvfb only (DEMO-0006).
  Resolved (2026-09-19): diagnosed as vkcube setting only _NET_WM_NAME,
  which `search --name` never reads; Xvfb had the same miss. The new
  `named_windows` keeps visible windows getwindowname can title. --gpu
  vkcube: 3.95 s wall (was ~24 s), window fills the frame. Gate step "a
  window titled only by _NET_WM_NAME is found" watched red against 0.1.1.
  **Layman:** Recording a graphics app takes twenty seconds longer than it should, and its window is not stretched to fill the frame.
  Kind: fix.
  Source: in-session-2026-09-19.

## 0.2.1 — The gate reaches the paths it documents

Checks for the two paths `ci.sh` has never exercised, plus the flag surface the
documentation check reads in one direction only. Nothing here changes a
protected surface, so the project's own ladder makes it a PATCH.

- ✅ [DEMO-0006] **Cover the --gpu backend in the CI gate.**
  The gate records on Xvfb only, so a regression in the compositor
  path would reach a user before a check caught it. Needs a runner
  with a usable card, which an ordinary GitHub runner is not.

  This is one of the two conditions for reaching 1.0.
  Decided (2026-09-20) by the user, with the options put: add the step now
  and let it skip where there is no card, rather than waiting for a runner
  with one. It records `--gpu -- vkcube` and fails if the sampled frame is
  flat, which is the failure a valid file hides. On a machine without
  `cage`, `xwfb-run` or a usable card the step skips and says so, so GitHub
  stays green while this machine gains the cover.

  Moved to the 0.2.1 group in the same decision: the work breaks no
  protected surface, so it is a PATCH under this project's own ladder, and
  the 1.0 question it feeds is its own item.
  Shipped (2026-09-20) in b7f152f. The step records `--gpu -- vkcube`,
  samples a frame through the same `assert_frame_drawn` helper the Xvfb
  smoke test now uses, and bounds the wall time so a window the search
  cannot find reads as a startup timeout rather than as a slow pass.

  Measured on this machine: RADV NAVI23 selected, WSI xcb -- so the app
  was pushed to X11 inside cage as the design requires -- dominant grey
  level 0.7921 against the 0.999 blank threshold, window found in 5s. The
  frame was looked at rather than only measured: a shaded cube filling the
  frame. The gate went from 55s to 65s.

  Both skip branches were exercised with the guard lifted verbatim: a
  missing program names it, and an absent render node says there is no
  card to reach. A skip prints its reason and is not a pass.
  **Layman:** The graphics-card recording path is not tested automatically yet.
  Kind: test.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0007] **Cover a Flatpak target in the CI gate.**
  The README documents three flags a Flatpak target needs, and nothing
  checks that the recipe still works. Needs a published application to
  point at.

  This is the second of the two conditions for reaching 1.0.
  Decided (2026-09-20) by the user, with the options put: point a step at a
  real installed Flatpak rather than the stub, skipping where that app is
  absent. The stub tests demoreel's reading of the caller's command line;
  nothing today tests the recipe against Flatpak itself.

  Target is a plain GTK application from Flathub rather than finbreak,
  which is the app that hit both known traps -- a startup dialog and
  single-instance handover. `flatpak list --app` on this machine shows
  several, org.gimp.GIMP among them.

  Moved to the 0.2.1 group in the same decision, on the same ground as
  DEMO-0006.
  Shipped (2026-09-20) in b00d57f. The step records org.gimp.GIMP with the
  three documented flags and samples a frame through `assert_frame_drawn`.

  Measured: the private display is reached in about five seconds, dominant
  grey level 0.7578 against the 0.999 blank threshold. What is in frame at
  three seconds is GIMP's splash, and the step says so -- it proves a real
  Flatpak drew on the private display through those flags, not that GIMP
  finished starting.

  Two candidates were measured and rejected first, rather than guessed at.
  PeaZip is Qt and could not load its platform plugin, so no window
  appeared within the startup timeout. Millionaire exited before the end of
  the run -- MESA reported no DRI3 support -- which skips the blank check by
  design, so it returned exit 0 with a flat frame.

  Three skips, all exercised: no flatpak, the application not installed,
  and a copy already running. The last was tested against a real running
  instance, because a handover leaves the private display empty and would
  fail the step for a reason that is not demoreel's.

  The negative case -- the same app without --nosocket=wayland -- is
  deliberately not run. It reaches the user's real compositor, which means
  opening a window on their desktop, and this gate runs before every push.
  The stub step above it still covers the warning.
  **Layman:** The Flatpak recipe in the README is documented but not tested.
  Kind: test.
  Source: in-session-2026-09-07.

- ✅ [DEMO-0044] **The documented-flags check reads one direction, so six long forms are undocumented.**
  `ci.sh`'s "documented flags exist" step takes every backticked flag in
  `README.md` and asserts demoreel accepts it. The reverse is unchecked, and
  the reverse is where the drift is.

  Measured 2026-09-20 by comparing the three `--help` outputs against the
  flags README backticks: `--action`, `--duration`, `--framerate`,
  `--name`, `--output` and `--size` are accepted and appear nowhere in
  README.md, which documents only their short forms. `--version` is
  documented in prose rather than backticked, so it is an artefact of the
  extraction and not drift.

  It matters because `versioning-overrides.md` § Breaking surfaces makes
  the command line and its flags protected. An alias nobody wrote down is
  still a surface a script can depend on, and removing one would be a
  break nobody could have anticipated from the contract.

  Two halves: document the long forms in README.md, and add the missing
  direction to the gate step so the next alias cannot arrive unannounced.
  The step's counter is even named `undocumented` while counting the
  opposite direction.

  Documenting an alias that already works breaks nothing, so this is a
  PATCH. Withdrawing one instead would be a MINOR.
  Shipped (2026-09-20) in a1ad64e. Both halves: README's option table
  carries both spellings per row, and the gate step checks both directions.

  The new direction matches on a word boundary rather than with grep -F --
  a bare `-o` matches inside "read-only", and the check would have passed
  on any README containing it. `-h` and `--help` are skipped as argparse's
  own. The step's help text now includes `stop --help`, which it never read
  before.

  Proved red before green: with `--output` taken back out of the table the
  gate exits 1 and names the flag; restored, it exits 0.
  **Layman:** Six spellings of existing options work but are written down nowhere.
  Kind: doc-fix.
  Source: in-session-2026-09-20.

- ✅ [DEMO-0045] **The CI runner image changes under us on 2026-10-19.**
  Run 35510735694 (the v0.2.0 release commit) carried a GitHub annotation:
  "The ubuntu-latest label will migrate to Ubuntu 26 beginning October 19,
  2026", pointing at actions/runner-images issue 14748.

  `ci.yml` asks for `ubuntu-latest` and installs ffmpeg, xvfb, xdotool,
  x11-apps, x11-utils and xterm from apt. A package renamed or dropped on
  the new image fails the gate on a commit that changed nothing, and the
  first run to find out is whichever push lands after the switch.

  Two routes, and the choice is the user's: try the new image early by
  naming it explicitly in a branch, or pin the image so the switch happens
  when we choose it. `standards/dependencies.md` counts a runner image as a
  dependency, and a pin at latest owes no hold-ledger row -- the same
  reasoning DEMO-0010 records for the other two pins.

  Nothing about the tool changes, so this is a PATCH.
  Answered (2026-09-20) by running the gate on the new image rather than
  by choosing a route blind. The user picked the try-it-early option with
  both put.

  Branch `runner-image-probe` asked for `ubuntu-26.04` by name and
  dispatched the workflow against it (run 35517113487). The label already
  exists, a runner picked the job up, the full gate ran -- "no resolvable
  range; running the full gate" -- and every check passed on
  Ubuntu2604-Readme image 20260907.131.

  So the October migration is a non-event for this project and no pin is
  needed. `ci.yml` keeps `ubuntu-latest`, unchanged.

  The run also verified the new steps' skip branches on a real GitHub
  runner, which the local harness could only simulate: "skipped: this
  machine has no xwfb-run cage vkcube" and "skipped: this machine has no
  flatpak".

  Nothing was merged. The probe branch is deleted; the evidence is the run.
  **Layman:** The machine GitHub runs our checks on is being replaced; we should try the new one before it arrives.
  Kind: chore.
  Source: in-session-2026-09-20.

- ✅ [DEMO-0047] **`stop` hands back a path for a recording that then fails its blank check.**
  Surfaced by a `review-contract` lane reading the versioning overrides, and
  confirmed in the code rather than taken from the report.

  `cmd_stop` signals the recorder with SIGUSR1 and prints `entry["output"]`
  immediately. The recording process then takes its end-of-run sample, and
  on a blank display it dies without printing a path. So a caller running
  `out=$(demoreel stop mydemo)` holds a path for a run that failed, while a
  caller running `out=$(demoreel record ...)` correctly holds nothing.

  That is the silent-failure shape this project keeps closing: a valid
  file, a path handed back, and nothing in the picture. It is not a
  documentation defect -- the standard describes `record` accurately -- so
  it was surfaced rather than fixed in that document.

  Not obvious what the fix is, which is why this is an investigation. stop
  cannot know the verdict at the moment it signals: it would have to wait
  for the recorder to exit and take its status, which changes how long a
  stop takes and what it prints. Weigh that against the exposure before
  writing anything.

  The gate's stop step uses an app that draws, so it never meets this.
  Resolved (2026-09-25): stop now waits for the run to exit and prints the
  path only if the run succeeded. The user chose this over printing
  regardless, and over documenting the gap. Measured before the fix: stop
  returned in about 0.1 s and the recorder finished 0.7-0.9 s later, so the
  path also named a file ffmpeg was still writing -- ffprobe found no moov
  atom in it. The run now writes "result": "ok" to its state file just
  before printing, and leaves that file for stop to read. A zombie counts as
  exited, since the script waiting on stop may be the one that must reap it.
  Two gate steps, both red against the old code: stop's path must already
  probe as a finished video, and stop must fail with a blank run.
  **Layman:** Stopping a recording prints the file straight away, even when the recording turns out to be empty and fails.
  Kind: investigate.
  Source: review-contract-2026-09-20.

- ✅ [DEMO-0048] **Move CLAUDE.md's dated history into docs/history/claude-md.md.**
  What stays is what is true now and what a breach looks like. What moved
  is dated provenance, the wording a rule replaced, and the argument that
  settled a rule. Traps did not move: a trap is what is true now.

  CLAUDE.md 16158 -> 15781 bytes, and docs/history/claude-md.md is 2606.
  The saving is small because the file is almost all trap and mechanism,
  which the instruction excluded from the move. Reporting the real figure
  rather than cutting content that earns its place.

  Rule 14: no line changes for a conformer, so no gate. ./ci.sh --docs
  green.
  **Layman:** The project's instructions file now says only what is true today; the story of how each rule got there moved to a separate file it links to.
  Kind: doc.
  Source: user-request-2026-09-21 (CFG-0492, relayed via claude-b1).

- ✅ [DEMO-0049] **An app that makes Xvfb print a lot freezes the display, and demoreel with it.**
  Found when the gate hung in the GIMP Flatpak step. `start_xvfb` gave the
  server a stderr pipe and read it only while starting. Every keymap an app
  loads makes Xvfb run xkbcomp, whose warnings go to that pipe. Once it
  filled, the server blocked mid-write: no window appeared, ffmpeg could not
  connect, and an `xdotool` call waited on the frozen display with no
  timeout reaching it.

  Reproduced without GIMP: an app running `setxkbmap us` sixty times froze
  a `-d 2` run until `timeout 60` killed it.

  Resolved (2026-09-25): the server's stderr now goes to the run's display
  log, the file the `--gpu` backend already writes. It is kept when a run
  fails and removed when it succeeds. The same repro records in seconds.
  ci.sh has a step running it, and CI installs x11-xkb-utils for
  `setxkbmap`.
  **Layman:** A chatty app could freeze the private screen, and the recording hung forever instead of failing.
  Kind: fix.
  Source: in-session-2026-09-25.

## 0.2.2 — Quicker and lighter

Released early on 2026-09-26 with what was done: `demoreel shot`, the 10 s bound on display calls, the self-resize warning, and the shot log-folder fix. The user chose to cut it then because the next change, typing `type` steps exactly, is breaking. The speed and memory items planned here moved to 0.3.0 unchanged.

- ✅ [DEMO-0079] **Put a timeout on every xdotool and frame-sample call.**
  Found in the DEMO-0049 hang: `xdotool getwindowname` waited on a frozen
  display for minutes, and `--startup-timeout` never fired. The deadline
  is checked between calls, and nothing bounds a single call. The wrapper
  `xdotool()` and the sampler in `display_is_blank` both call
  `subprocess.run` with no timeout.

  DEMO-0049 removed the cause found that day. Any other way a display can
  stop answering hangs the run the same way. Give each call a timeout and
  turn an expiry into an error that names the display. A sample that
  times out is the "could not tell" answer, SampleError, never "not
  blank" -- DEMO-0033's rule.
  Resolved (2026-09-25): xdotool() and display_is_blank() both pass
  CALL_TIMEOUT (10 s; a `type` step gets 0.05 s more per character).
  An xdotool expiry dies naming the display, and a grab expiry is a
  SampleError, never "not blank". ci.sh freezes Xvfb with SIGSTOP
  mid-run: 0.2.1 hung until timeout(1) killed it at 60 s, now the run
  fails saying the display stopped answering. The grab half was
  checked on its own against a frozen bare Xvfb: SampleError after
  10.0 s.
  **Layman:** If the private screen stops answering, the recording should fail with a message instead of waiting forever.
  Kind: fix.
  Source: in-session-2026-09-25.

- ✅ [DEMO-0099] **An app that resizes itself after demoreel sizes it records partly off-frame, and nothing says so.**
  Found recording Vestige, a GLFW/OpenGL editor, with `--gpu` at the
  default 1600x1000. demoreel moved and sized the window, and
  `wait_for_size` passed. Then the app set itself to 1920x1080, larger
  than the display. In one run, the whole 32 s showed the window's corner
  at about (930, 454), with black everywhere else. In a second run it sat
  at 0,0 but was cropped at the right and bottom, cutting off a panel.
  Every check passed both times: the picture was not flat.

  Recording at `-s 1920x1080`, the app's own size, gave a correct video
  from start to finish.

  Two parts. Detect it: sample the window's geometry again when the blank
  check samples the display, and warn on stderr if it no longer matches
  the frame, naming the size the app chose so the caller can pass `-s`
  with it. Then find out whether re-applying the size once the app
  settles is safe, or starts a resize fight. Not measured on Xvfb yet.
  Progress (2026-09-25): detection shipped. window_off_frame
  reads the window's geometry beside each blank sample and warns
  once, naming the size to pass to -s. ci.sh has a step with an xterm
  that keeps shrinking itself: silent on 0.2.1, warned after the fix.
  Still open: whether re-applying the size once the app settles is
  safe, or starts a resize fight. Not measured.
  Second case (2026-09-25, from doom-ants): DOOM_Ants on a 1920x1080
  xwfb-run display sized its own window to 1708x800, so a game can
  choose a frame smaller than the display too. Their other report,
  that killing xwfb-run alone leaks cage, Xwayland and the app, does
  not apply to demoreel: measured the same day, cage/Xwayland/vkcube
  counts were unchanged after a normal --gpu run, a SIGTERM and a
  timeout(1) kill, since end_process signals the whole group.
  Closed (2026-09-26) on the detection half, which ships in 0.2.2.
  The open question, re-applying the size, moved to DEMO-0108.
  **Layman:** If an app changes its own window size after demoreel has set it, the video shows it cropped or off to one side, and demoreel doesn't warn you.
  Kind: fix.
  Source: peer-request-vestige-2026-09-25.

- ✅ [DEMO-0100] **Add `demoreel shot`, which saves one picture of an app instead of a video.**
  Asked for by the user on 2026-09-25. Decided with them: a separate
  command rather than a flag on `record`, and exactly one picture per
  run. For several pictures, run it several times.

  Same private screen and window sizing as `record`. It waits for the
  app to draw, runs any `-a` steps, writes one PNG, closes the app and
  prints the path. A flat picture fails the run, as a blank recording
  does. No `-d`, `-r` or `stop`. It holds a private run name, so it
  never collides with a recording.

  README is the design contract and says the tool makes videos, so the
  README section goes through review-contract before the code.
  Resolved (2026-09-25): built to the gated README (loop-log rows 4-5).
  prepare/launch/place_window are lifted out of cmd_record and shared;
  the display starters take a file prefix instead of a run name, so a
  shot keeps its files in a mkdtemp folder under the state dir,
  removed on success and named on failure. take_picture reads the
  saved PNG back through frame_is_flat. ci.sh: the flag check reads
  `shot --help`, a 321x241 shot of xclock passes and leaves nothing,
  a flat picture fails printing no path. Checked by eye: xclock on
  Xvfb and vkcube on --gpu. The record-demo skill lives in ~/.claude
  and still needs a line on `shot`.
  **Layman:** Take a screenshot of an app on the private screen, so nothing from your real desktop is in the picture.
  Kind: feature.
  Source: user-request-2026-09-25.

- ✅ [DEMO-0107] **A `shot` that fails early keeps its private folder without naming it, and the folders pile up in RAM.**
  Album Builder reported two `demoreel shot` runs exiting 1 with no
  message, where a retry worked. Not reproduced: eight runs of the same
  shape against kcalc all succeeded. Every exit path in demoreel prints,
  so the message was probably dropped by the caller; asked for the exact
  capture. But the failures left four shot-* folders in
  /run/user/1000/demoreel-1000, which is tmpfs (RAM).

  README promises the kept folder is kept on failure "like the logs",
  and cmd_shot names it only on the settle-sample and final-picture
  paths. A die in launch() or place_window() keeps it silently. Fix:
  name the folder on every failure path, or remove it where there is
  nothing in it worth reading. Add a gate step that fails a shot early
  and checks the message names the folder.
  Settled (2026-09-25): the silent exit was the caller's. Album
  Builder's failing runs ended in `>/dev/null 2>&1`, which discarded
  demoreel's own message. Not a demoreel bug. The folder-naming half
  stands; album-builder deleted the four leftover folders itself.
  Resolved (2026-09-25): cmd_shot catches SystemExit from every die()
  inside its run and re-raises it naming the kept folder; the settle
  path's own "Kept:" line is removed so none names it twice. ci.sh
  shoots /nonexistent/app: 0.2.1-era code left shot-* unnamed in
  /run/user, now the message names it and the step deletes it. Gate
  green apart from the real-Flatpak step, which failed on this
  machine's unmounted document portal (/run/user/1000/doc empty), not
  on demoreel; run green with that step skipped.
  **Layman:** When taking a picture fails, demoreel leaves a small folder behind in memory and doesn't always say where it is.
  Kind: fix.
  Source: peer-request-album-builder-2026-09-25.

## 0.3.0 — Friendly at a terminal

A person at a terminal gets as much from demoreel as a script does. The command line keeps its rules: no prompts, no config file, and stdout carries the path and nothing else. The graphical window the user also asked for on 2026-09-25 is 0.6.0. It builds on the error wording, countdown and restructured recording loop made here.

This is a MINOR because two changes to the `-a` grammar are breaking, both chosen by the user on 2026-09-26: `type` types its text exactly (DEMO-0101), and the pointer starts in a corner rather than the centre (DEMO-0103). The speed and memory items first planned for 0.2.2 moved here too.

- 📋 [DEMO-0050] **Show worked examples at the end of `--help`.**
  `demoreel --help` and `demoreel record --help` list the flags and nothing
  else. A person meeting the tool for the first time has to go to README.md
  to learn what a working command looks like.

  Add an examples block under each: a timed recording, `-d 0` with `stop`,
  scripted actions, `--gpu`, and a Flatpak with its three flags. argparse
  carries this as an epilog with RawDescriptionHelpFormatter.

  The gate already checks that every flag README documents is one the tool
  accepts. Extend it so every example in `--help` also parses.
  **Layman:** Typing demoreel --help shows real commands you can copy, not just a list of options.
  Kind: ux.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0051] **Name the install command when a required program is missing.**
  Today a missing program stops the run with its name: `missing required
  program(s): xdotool`. A person then has to find which package provides
  it, and the name differs by distro -- `xwfb-run` comes from
  `xwayland-run`, and `setxkbmap` from `x11-xkb-utils` on Debian.

  Read /etc/os-release and name the install command for openSUSE, Debian
  and Ubuntu, Fedora and Arch, for the backend in use. An unknown distro
  gets the program names as today.

  The package table is knowledge about distros, not about apps, so it does
  not breach the per-app rule. It is shared with the setup-check item
  below, and written once.
  **Layman:** If something demoreel needs isn't installed, it tells you the exact command to install it.
  Kind: ux.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0052] **Add `demoreel check`, which tests a machine's setup without recording.**
  The only way to learn whether a machine can record is to record, and a
  missing program is reported one run at a time.

  `demoreel check` reports every program each backend needs, whether
  Xvfb starts, and for `--gpu` whether a render node exists. It names the
  install command for each gap, from the table the missing-program item
  uses. It exits non-zero if the default backend cannot record.

  A new subcommand is a MINOR change under the versioning overrides. It
  prints to stderr, so stdout keeps its one-line contract.
  **Layman:** One command tells you whether this computer is ready to record, and what to install if not.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0053] **Show a live countdown while recording, when stderr is a terminal.**
  A person running `demoreel record -d 30` sees one line saying recording
  has started, then nothing until it ends. There is no sign the run is
  alive, or how long is left.

  When stderr is a terminal, update one line in place with the time left,
  or the time so far on a `-d 0` run. End with a summary: length and file
  size. When stderr is not a terminal -- a script, a log, a Claude session
  -- print exactly what is printed today, so callers see no change.

  The display is magnified on this machine, so keep it to one short line
  and no colour.
  **Layman:** While it records, you see how many seconds are left instead of a silent wait.
  Kind: ux.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0054] **Make Ctrl+C a documented, tested way to finish a recording.**
  A person running `demoreel record -d 0` in the foreground will reach for
  Ctrl+C, not a second terminal. The code catches SIGINT and finishes the
  video, but README never says so and the gate never tests it.

  Unverified: Ctrl+C at a terminal signals the whole foreground process
  group. The app is started in its own session and escapes that. Whether
  ffmpeg does has not been checked. If ffmpeg gets SIGINT directly, it
  may stop on its own before demoreel asks it to. Measure that first.

  Then document it beside `stop` and add a gate step that sends SIGINT
  to the process group and checks for a finished video.
  **Layman:** Pressing Ctrl+C should stop the recording and still leave you a good video.
  Kind: test.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0055] **Rewrite every error so it says what happened and what to do next.**
  Some errors already do this -- the blank-display error names both
  likely causes and the fix for each. Others are terse: `--size must look
  like 1600x1000`, or `Xvfb did not start.` followed by the server's own
  output.

  Go through every `die()` and `note()` and make each one name the
  problem, the likely cause, and the next step.

  This goes before the translation work in 0.4.0, which translates these
  same messages. Rewording them after translation means translating twice.
  **Layman:** Every error message tells you in plain words what went wrong and how to fix it.
  Kind: ux.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0056] **Add tab completion for bash, zsh and fish.**
  Complete the subcommands, every flag, the `-a` action verbs, and the
  names of running recordings for `demoreel stop`, read from the state
  directory.

  Hand-written scripts, not a dependency. argcomplete would need a
  package installed, and the tool is standard library only. The gate
  checks that each script names every flag the parser accepts, the same
  check README's flags already get.
  **Layman:** Pressing Tab completes demoreel's commands and options, like it does for other programs.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0057] **Write a man page.**
  A person used to Linux tools types `man demoreel`, and there is nothing.

  Write one covering both subcommands, every flag, the action grammar,
  exit status, files under the state directory, and the Flatpak and
  `--gpu` notes. The gate checks it names every flag, like README.

  The install packages in 0.5.0 put it where `man` finds it. Until then,
  `man ./demoreel.1` reads it in place.
  **Layman:** `man demoreel` works, like it does for other command-line tools.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0058] **Give README an Install section and a quick start written for a person.**
  README has a Quick start but no Install section. It lists what must be
  installed only under Constraints already verified on this machine, which
  reads as a note to ourselves. A section headed for Claude Code sessions
  sits above the one on Flatpaks.

  Add an Install section per distro. Lead with a person's path: install,
  record, watch the video, stop a long recording. Keep the section for AI
  callers, placed after the human path.

  Verify it by running it: `verify-instructions` in a clean container per
  distro, not by reading it.
  **Layman:** The front page explains how to install it and make a first video, step by step.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0059] **Put a short demo video at the top of README.**
  A person landing on the repository reads prose about a video tool
  without seeing a video.

  Record a short clip of a real app with scripted actions, with demoreel,
  and embed it at the top of README. Keep the command that made it beside
  it, so the clip is also a working example.

  This is inside the repository, so it does not meet the 1.0 condition in
  versioning-overrides.md. That needs use outside it.
  **Layman:** The project page shows a video made with demoreel, so people see what it does before reading.
  Kind: marketing.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0081] **Split `cmd_record` into its stages before the countdown hooks into it.**
  `cmd_record` is by far the longest function in the file. It checks
  dependencies, parses the size, starts the display and app, sizes the
  window, waits for a draw, records, samples, tears down and reports, all
  inline, sharing locals across the whole span.

  The countdown in this version needs a hook in the recording loop. The
  GUI in 0.6.0 needs progress from it too. Split it into its stages, with
  the `try`/`finally` teardown kept in one place, before either lands.

  The file stays one file. Splitting it into modules would give up the
  single-executable property CLAUDE.md states, for no gain.
  **Layman:** The main recording function does everything in one long block; break it into clear steps.
  Kind: refactor.
  Source: in-session-2026-09-25.

- 📋 [DEMO-0098] **Add a held-key action, for apps that move while a key is down.**
  Asked for by the vestige session on 2026-09-25: its demo would show
  walking forward by holding W for a few seconds. The `-a` grammar has
  `key`, which presses and releases at once, and nothing that holds.

  Add `hold KEY SECONDS`, built on xdotool keydown and keyup. The keyup
  must run on every exit path, including a stop mid-hold, or the key stays
  down on the private display for the rest of the run.

  A new verb extends the grammar without changing an existing one, so it
  is MINOR under the versioning overrides. README, `--help` and the tab
  completion list it with the others.
  **Layman:** Let a demo hold a key down for a few seconds, e.g. to walk forward in a 3D scene.
  Kind: feature.
  Source: peer-request-vestige-2026-09-25.

- 📋 [DEMO-0108] **Find out whether re-applying the frame size after an app resizes itself is safe.**
  Split from DEMO-0099, whose detection half shipped in 0.2.2: demoreel
  warns once and names the size the app chose. Still open: re-apply the
  frame size once the app settles, or does that start a resize fight?
  Measure on both backends with Vestige (sets 1920x1080 on a 1600x1000
  display) and DOOM_Ants (sets 1708x800 on 1920x1080). Not measured yet.
  **Layman:** When an app changes its own window size, demoreel now warns; this checks whether it could safely put the size back instead.
  Kind: investigate.
  Source: peer-request-vestige-2026-09-25.

- 📋 [DEMO-0073] **Cap ffmpeg's encoder threads, which set most of a recording's memory.**
  Measured 2026-09-25, during a default 1600x1000 recording of xclock:
  ffmpeg 537568 kB resident, Xvfb 62472 kB, demoreel 23756 kB, the app
  9504 kB.

  ffmpeg's share follows x264's thread count, which defaults to a
  multiple of the cores -- twelve here. Encoding a 1600x1000 test pattern
  for ten seconds at the tool's own settings, peak resident memory:

    threads auto   571136 kB   1.23 s
    threads 8      377220 kB   1.58 s
    threads 4      306696 kB   2.49 s
    threads 2      267116 kB   2.49 s

  Every setting stays several times faster than real time. Fewer threads
  also leave more CPU for the app being recorded, which is what the video
  shows.

  Before choosing a number: a test pattern is harder to encode than most
  screens but is not a live capture. Record a busy app at the default
  size on a machine with fewer cores, and read ffmpeg's dropped and
  duplicated frame counts. A cap that drops frames is not worth the
  memory. Encoding parameters are not a breaking surface.
  **Layman:** The video encoder uses far more memory than it needs; limiting it roughly halves that.
  Kind: optimize.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0074] **Measure the `--gpu` backend's memory, and cut what it does not need.**
  The Xvfb path was measured on 2026-09-25; the `--gpu` path was not. It
  runs xwfb-run, cage and Xwayland in place of Xvfb, and the recorded app
  has a GPU context. Measure each process's resident memory during a
  `--gpu -- vkcube` run and compare against the Xvfb figures. File a fix
  only for what the numbers show.
  **Layman:** Find out how much memory the graphics-card recording mode uses, and trim it.
  Kind: investigate.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0075] **Notice `stop` at once, instead of up to a fifth of a second late.**
  The recording loop in `cmd_record` sleeps 0.2 s between checks, and the
  signal handler only sets a flag. Python resumes an interrupted sleep
  after a handler runs (PEP 475), so a stop lands up to 0.2 s late. That
  short extra tail ends up in the video.

  Wake the loop from the handler -- a threading.Event waited on with a
  timeout, or signal.set_wakeup_fd. Measure the time from signal to
  ffmpeg's quit, before and after.
  **Layman:** The recording reacts to a stop request immediately rather than after a short pause.
  Kind: perf.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0076] **Find where the time goes between `stop` and a finished video.**
  Measured 2026-09-25 with xclock: the recorder exits 0.7 to 0.9 s after
  `stop` signals it. Since DEMO-0047, `stop` waits that long before it
  answers. The steps in that gap: ffmpeg finishing and its faststart pass,
  the end-of-run blank sample, which starts a second ffmpeg to grab one
  frame, then ending the app and the display.

  Time each step, then shorten the largest. The faststart pass stays --
  DEMO-0013 decided that on measurement. The blank sample must stay a real
  sample of the display.
  **Layman:** Stopping takes nearly a second; find out which step is slow and speed it up.
  Kind: investigate.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0077] **Find where the time goes between launch and the first recorded frame.**
  DEMO-0042 measured about 1.4 s of fixed setup per run. The steps:
  starting Xvfb, installing the cookie and waiting for the reset,
  launching the app, polling for its window, resizing and waiting for
  the size, optional `--settle`, then ffmpeg's first frame. Several of
  these poll at a fixed interval.

  Time each step with a real app and shorten the largest. Every
  safety check stays: the cookie ordering and the window-size wait each
  fixed a real defect.
  **Layman:** Starting a recording has a fixed delay; find out which step is slow and speed it up.
  Kind: investigate.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0078] **Shorten the gate's longest step, the scripted-actions recording.**
  DEMO-0042 measured the gate and found the scripted-actions step the
  single largest, a recording of about twelve seconds. It closed the
  parallel-steps idea as considered and named this step as the cheaper
  lever. Since then, steps added for DEMO-0006, DEMO-0007, DEMO-0047 and
  DEMO-0049 have made the gate longer.

  Shorten the waits inside that step to what the assertions need, and
  check it still fails when an action is broken.
  **Layman:** The pre-push checks spend the most time in one test; make that test quicker.
  Kind: perf.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0080] **Replace the hand-written wait loops with one polling helper.**
  The file has several loops that poll with a fixed sleep and a deadline:
  waiting for the display after the cookie reset, for the window, for its
  size, for the first draw, for a starting run in `stop`, and now for a
  stopped run to exit. Each picks its own interval, and each writes its
  own deadline arithmetic.

  One helper, taking a check, a timeout and an interval. Tuning the
  intervals is then one change, which is what the launch-time item in this
  version needs, and a new wait cannot get the deadline wrong. Behaviour
  stays the same, and the gate proves it.
  **Layman:** Several bits of code each wait for something in their own way; make them share one tidy method.
  Kind: refactor.
  Source: in-session-2026-09-25.

- 📋 [DEMO-0082] **Check what happens when the output path is a symlink someone else planted.**
  ffmpeg is started with `-y`, so it overwrites whatever is at the `-o`
  path. If a caller records to a shared directory such as `/tmp`, another
  local user can create a symlink at that name first. The video would
  then be written through it, over a file the caller owns.

  Unverified: most distros set fs.protected_symlinks=1, which refuses to
  follow such a link in a sticky world-writable directory. Whether this
  machine, and the GitHub runner, do was not checked, nor what ffmpeg does
  when the open is refused. Measure it. If the protection is not
  guaranteed, refuse an output path that is a symlink the caller does not
  own, the same way `state_dir()` refuses a planted directory. SECURITY.md
  gets the result either way.
  **Layman:** Make sure another user on the same computer can't trick demoreel into overwriting one of your files.
  Kind: security.
  Source: user-request-2026-09-25.

- ✅ [DEMO-0101] **Quotes inside a `type` step are silently removed before the text is typed.**
  Found recording Ants Terminal for its session. `-a "type printf '...'"`
  typed printf and its argument with the single quotes gone, because
  run_action splits every step with shlex before joining the words back
  for `type`. The shell then ran the colour codes as commands. Wrapping
  the text in double quotes works around it.

  `type` should take the rest of the step verbatim after the verb, since
  it is text to type, not arguments. That changes what an existing step
  types, so check it against the versioning overrides first. README's
  Scripted steps list gets one line on quoting either way.
  Resolved (2026-09-26), breaking, so it opens 0.3.0 (user's choice).
  `type` now types everything after the verb and one whitespace
  character, exactly. The other verbs keep shlex, and an unbalanced
  quote there now dies with one line instead of a traceback. ci.sh's
  scripted-actions step types an apostrophe, both quotes and a double
  space; red on 0.2.2 (ValueError), and a mutant typing the joined
  args typed nothing and failed it.
  **Layman:** Typing a command with quotes in a demo loses the quotes, so the command on screen goes wrong.
  Kind: fix.
  Source: peer-request-ants-terminal-2026-09-25.

- ✅ [DEMO-0102] **A Qt app recorded with an isolated, empty config gets a half-dark palette.**
  Reported by games-hub-35. With XDG_CONFIG_HOME pointed at an empty
  directory, so the owner's settings stay out of frame, Qt takes the
  window background dark and the text light-theme: dark on dark grey,
  and a menu entry invisible. With the owner's kdeglobals it is
  readable. Reproduced by them on Xvfb at 1600x1000.

  The isolation belongs to the caller's command, not to demoreel, so
  this is documentation: README and the record-demo skill say to copy
  ~/.config/kdeglobals into an isolated config. Not verified here yet.
  Also from finbreak (2026-09-25): a single-instance app need not be
  closed on the real desktop if the caller points its XDG_* dirs at a
  temp folder, since its socket lives under them. Say that beside the
  single-instance note. And say the "Failed to create wl_display" line
  a Qt app logs is expected: it is demoreel's unresolvable
  WAYLAND_DISPLAY working. QT_QPA_PLATFORM=xcb stays declined.
  Resolved (2026-09-26) in README "Things that catch you out".
  Reproduced with kcalc on Xvfb via `demoreel shot`: XDG_CONFIG_HOME
  pointed at an empty folder gave labels too dark to read; with
  ~/.config/kdeglobals copied in, readable. README now says to copy it,
  states finbreak's XDG-lock option beside the single-instance note, and
  says a Qt app may print "Failed to create wl_display" (kcalc printed
  nothing, so "may"). The record-demo skill's half is asked of claude-04.
  **Layman:** Recording a KDE or Qt app with fresh settings can make its text dark on dark and hard to read.
  Kind: doc.
  Source: peer-request-games-hub-2026-09-25.

- ✅ [DEMO-0103] **The pointer starts in the middle of the private screen and triggers hover highlights.**
  Reported by games-hub-35: a fresh Xvfb puts the pointer at the
  centre, so the tile under it shows a hover highlight in frame before
  any step runs, even though --cursor is off and no pointer is drawn.

  Either move the pointer to a corner before the app starts, or say in
  README that a first `move` step clears it. Measure which apps it
  affects first.
  Resolved (2026-09-26), breaking, in 0.3.0 (user's choice: park it,
  not just document it). launch() parks the pointer at the bottom-right
  corner on both backends: before the app starts on Xvfb, as soon as the
  display exists on --gpu. Xvfb also needed -noreset: it reset on its last
  client leaving, which put the parked pointer back at the centre the
  moment the parking xdotool exited. Measured with an app reading
  `xdotool getmouselocation` at start: 0.2.2 X=200 Y=150, park without
  -noreset X=200 Y=150, fixed X=399 Y=299 on a 400x300 display; --gpu
  reads 399,299 a second in. ci.sh has the step; the --cursor step now
  moves the pointer mid-frame, since a cornered pointer is mostly off
  the picture.
  **Layman:** Before any scripted step, the hidden mouse pointer sits mid-screen and can light up whatever is under it.
  Kind: ux.
  Source: peer-request-games-hub-2026-09-25.

- ✅ [DEMO-0109] **A GPU-heavy app recorded with `--gpu` comes out at a few new frames a second, and nothing says so.**
  Reported by vestige-1a. Vestige's fly-through at 1920x1080 on --gpu
  recorded 83-89 unique frames of 770-910 (mpdecimate), while its own
  profiler showed 35-62 fps throughout. tblend shows exact duplicates in
  runs with a jump about every 13 frames, including where the app ran a
  steady 62 fps. glxgears at the same size records ~93% unique, so light
  apps are fine. Ruled out by them: software GL (radeonsi on an RX 6600),
  resolution, vsync, the app's own speed under the same xwfb-run+cage.
  Their hypothesis, unverified: under GPU saturation the Xwayland root
  that x11grab reads is refreshed only occasionally.

  Two parts. Find the cause and fix the capture if it can be fixed here
  (compositor-side capture is a different tool; see CLAUDE.md's
  Wayland-only note). And make it visible: a low unique-frame ratio after
  a --gpu run should be reported, as a blank video is.
  Measured (2026-09-26), GPU 0% busy before each run, doom-ants
  holding its GPU work: Vestige repro at 1920x1080, -d 25. demoreel as
  is: 756 frames, 67 unique. With -fps_mode passthrough: 753 frames, 90
  unique, so x11grab delivers ~30 grabs/s on time and ffmpeg pads
  nothing; dup_frames cannot see this. The grabs return a stale picture.
  Grabbing the app window (-window_id) beside a root grab: 361 frames,
  89 unique vs root 792/142, so the window is stale too. Next: does
  compositor-side capture (wlr-screencopy via wf-recorder, in the OSS
  repo, not installed) see every frame? The warning must compare frame
  content, not read dup_frames.
  Confirmed (2026-09-26): compositor-side capture sees every frame.
  wf-recorder (installed with the user's OK) on cage's own socket,
  12 s beside a normal demoreel run of the same Vestige fly-through:
  643 frames, 643 unique (~54 fps). demoreel's x11grab over the same
  run: 588 frames, 156 unique. GPU read 70% during it, which is Vestige
  itself. So the stale picture is Xwayland's X-side copy, and capturing
  from cage on --gpu is the fix candidate; that changes a runtime
  dependency and the README contract, so it goes to the user first.
  Switch attempted (2026-09-26, user chose "switch, plus a warning"),
  blocked on sizing. cage's headless output is always 1280x720 and
  xwfb-run starts Xwayland with -fullscreen, so the X screen is SCALED
  into it: an 800x600 xterm came out stretched, and the 643/643 Vestige
  capture above was shrunk to 1280x720. wlr-randr (installed with the
  user's OK) resizes the output, but Xwayland 24.1.13 keeps its first
  size: after resizing to 1920x1080 a red xterm filled only the top-left
  1280x720 (55.6% of the frame black, exactly the uncovered share), and
  `xrandr -s` on the X side changed nothing. Resized cage + wf-recorder
  on Vestige: 357 frames, 344 unique, but only 1280x720 of the picture.
  So the output must be sized BEFORE Xwayland starts, which xwfb-run has
  no hook for: capturing from cage means demoreel starting cage and
  Xwayland itself. wf-recorder also needs -D, or SIGINT is ignored while
  the screen is still, and -y, or it prompts before overwriting.
  Closed (2026-09-26) on the visible-failure half, the user's choice
  of "a note on --gpu runs". changed_share counts frames that differ
  (mpdecimate hi=lo=256, frac=0) over 10 s from the middle; below 70%
  a --gpu run prints a note worded "if the app was moving". Measured:
  Vestige 48%, vkcube 96%, a still xterm 1%; synthetic stutter 27%,
  smooth 100%. ci.sh pins both, and the vkcube --gpu step now fails if
  it draws the note. The capture fix itself is DEMO-0111.
  **Layman:** A demanding 3D app looks smooth on screen but its demoreel video stutters badly, and demoreel doesn't warn you.
  Kind: fix.
  Source: peer-request-vestige-2026-09-26.

- 📋 [DEMO-0110] **A blank `--gpu` recording is told to "record it with --gpu instead".**
  Seen 2026-09-26 while testing DEMO-0109: a --gpu run stopped before
  Vestige drew anything failed its blank check correctly, but
  BLANK_CAUSES says the app "needs the GPU, and Xvfb has none ...
  record it with --gpu instead". The message should know which backend
  ran and name causes that fit it — on --gpu, the app not having drawn
  yet (--settle) or rendering natively to Wayland.
  **Layman:** When a graphics-card recording comes out blank, demoreel's advice tells you to use the option you already used.
  Kind: fix.
  Source: in-session-2026-09-26.

- 📋 [DEMO-0111] **Record `--gpu` from the compositor, so busy 3D apps record smoothly at full size.**
  Decided by the user 2026-09-26: switch --gpu capture from x11grab to
  wf-recorder on cage, and design it first — README and CLAUDE.md
  change through review-contract (rule 14) before any code. Evidence and
  dead ends are in DEMO-0109's notes; read them first.

  What the design must settle, all measured on DEMO-0109:
  - cage's headless output is 1280x720 and Xwayland (-fullscreen, from
    xwfb-run) scales into it. wlr-randr resizes the output, but Xwayland
    24.1.13 keeps its start-up size, so the output must be sized BEFORE
    Xwayland starts. xwfb-run has no hook for that, so demoreel starts
    cage itself, runs wlr-randr inside it, then Xwayland — and launches
    the app afterwards, like the Xvfb path (pointer parking then happens
    before the app, too).
  - Keep CLAUDE.md's concurrency rules: the display number still comes
    from -displayfd, never a scan; cage's socket from wlroots' own
    wayland-N allocation, read back, never guessed.
  - wf-recorder needs -D (else SIGINT is ignored while the screen is
    still), -y (else it prompts before overwriting), -r <framerate> and
    -x yuv420p with libx264. It prints no "capturing now" line like
    ffmpeg's first progress report; the -d countdown needs a new start
    signal (DEMO-0012).
  - --cursor: wf-recorder 0.6 has no pointer option; measure what it
    draws.
  - New --gpu dependencies: wf-recorder and wlr-randr (both in openSUSE
    OSS, installed here with the user's OK); xwfb-run is dropped.
  - DEMO-0109's stutter note stays; after the switch it should stop
    firing on Vestige's fly-through.
  Vestige (vestige-1a) offered to test a build: their repro is in
  DEMO-0109.
  **Layman:** Games and 3D apps recorded with --gpu will come out smooth instead of as a slideshow.
  Kind: feature.
  Source: user-request-2026-09-26.

## 0.4.0 — Speaks your language

Every message, --help and the man page in the reader's language, plus a
translated quick-start page. The full README stays English. Decided 2026-09-25:
Simplified and Traditional Chinese, Japanese, Hebrew, Afrikaans, Spanish,
Brazilian Portuguese, Italian, French, German, Russian, Korean, Arabic, Dutch,
Polish and Ukrainian. Claude drafts each one, and it stays marked as a draft
until a native speaker confirms it. stdout is never translated: it carries the
path, and scripts read it.

- 📋 [DEMO-0060] **Write the translation spec, and gate it before anything is built.**
  This is a real design choice, hard to undo once catalogs exist, and it
  touches every message, the parser, the gate and the docs. It meets the
  spec triggers, so it goes through `write-spec` and `review-contract`.

  The spec has to settle:
  - Where catalogs live. The tool is one file today. gettext wants .mo
    files on disk, found from the script's own path, not the caller's.
  - Locale selection: LANGUAGE, LC_ALL, LC_MESSAGES and LANG, in the order
    gettext uses them, with English as the fallback.
  - argparse's own strings ("usage:", "options:"), which Python ships
    untranslated.
  - That stdout, the state file and `--version` are never translated.
  - How a draft translation is marked, and where that shows.
  - The gate's completeness check.
  - Right-to-left text around paths and flags.

  The GUI planned in 0.6.0 uses the same catalogs, so the spec covers it.
  **Layman:** Decide on paper how translations will work before writing any code for them.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0061] **Build the translation mechanism with English as the source language.**
  Wrap every user-facing string -- `die()`, `note()`, argparse help and
  the examples -- as the spec says. Ship English only at this step.

  The proof it is safe: under LC_ALL=C, stdout, stderr and the exit status
  of every gate step are byte-identical to before. Scripts and Claude
  sessions set no locale, or C, and must see no change.

  Depends on the translation spec, and on the error rewrite in 0.3.0
  landing first.
  **Layman:** Make every message translatable, without changing anything for English users.
  Kind: implement.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0062] **Gate every catalog for missing messages and broken placeholders.**
  Every message must exist in every catalog, and each translation must
  carry the same placeholders as the English: `{output}` renamed or
  dropped is a crash, or a path that silently disappears.

  Also run a recording under each locale and check that stdout is still
  the bare path. That is the contract a translation could most easily
  break.
  **Layman:** The automatic checks fail if any language is missing a message or would print garbled text.
  Kind: test.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0063] **Keep paths, flags and commands readable inside Hebrew and Arabic messages.**
  A right-to-left sentence containing a path such as `/tmp/demo.mp4` or a
  command such as `demoreel stop mydemo` can render with its parts
  reordered. The reader then copies something that is not the command.

  Wrap each left-to-right run in Unicode isolation marks (FSI ... PDI) as
  the spec decides. Check by eye in Konsole, which does bidi, and in one
  terminal that does not. A screenshot of each goes in the item when it
  closes.
  **Layman:** Right-to-left languages show file names and commands the right way round.
  Kind: ux.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0064] **Draft translations for the languages named in the request.**
  Simplified Chinese, Traditional Chinese, Japanese, Hebrew, Afrikaans,
  Spanish, Brazilian Portuguese, Italian, French and German. Every
  message, --help and the man page.

  Each is marked as a draft until a native speaker confirms it.
  **Layman:** First batch of translations: Chinese, Japanese, Hebrew, Afrikaans, Spanish, Portuguese, Italian, French and German.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0065] **Draft translations for Russian, Korean, Arabic, Dutch, Polish and Ukrainian.**
  Suggested on 2026-09-25 and accepted: large Linux developer communities,
  and Arabic is a second right-to-left check beside Hebrew.

  Same scope and draft marking as the first batch.
  **Layman:** Second batch of translations, chosen for large Linux developer communities.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0066] **Write a translated quick-start page for each language.**
  One short page per language: install, record, stop. Linked from the top
  of README by language name. The full README stays English. It changes
  often and is where the detail lives.

  Each page's commands are run, not read, like README's quick start.
  **Layman:** Each language gets a short getting-started page; the full README stays in English.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0067] **Say which translations are drafts, and how a native speaker confirms one.**
  A reader should know when a language is a draft. Mark it in the catalog
  and in `--help`, and list the state of every language in one place.

  Write down how a confirmation happens: what a reviewer reads, how they
  say it is right or send fixes, and what changes when they do. Chasing
  reviewers is a standing chore, not part of this version.
  **Layman:** Be honest about which translations are machine drafts, and make it easy for a fluent speaker to approve one.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0083] **Treat translation catalogs as untrusted templates.**
  A translated message is a format template. With Python's str.format, a
  template can reach attributes and indexes -- `{output.__class__}` and
  beyond -- so a malicious or careless catalog entry can print internals
  or raise mid-run.

  Fill templates with plain named substitution that does no attribute or
  index lookup. Have the catalog gate reject any placeholder the English
  message does not have. Load catalogs only from the script's own path or
  the system locale directory, never from the working directory or a path
  taken from the environment. Add catalogs to SECURITY.md's trust
  boundaries.
  **Layman:** A bad or tampered translation file must not be able to leak data or crash demoreel.
  Kind: security.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0097] **Invite readers to improve the translations, in README and a new CONTRIBUTING.md.**
  Requested 2026-09-25. Only once the translations are built: an invitation
  to a language that does not exist yet asks for work on nothing.

  README gets a short section, near the language links: the translations
  are drafts until a native speaker confirms them, and improvements are
  welcome. It lists each language's state and links to CONTRIBUTING.md.

  CONTRIBUTING.md does not exist yet. Create it with how to suggest a
  better translation: where the catalogs live, how to send a change or an
  issue, and what happens when a native speaker confirms a language -- the
  process DEMO-0067 writes down. It is the home for other contribution
  routes as they appear.

  Depends on both translation batches and on DEMO-0067.
  **Layman:** Once the languages exist, the project page and a contributor guide ask fluent speakers to suggest better wording.
  Kind: doc.
  Source: user-request-2026-09-25.

## 0.5.0 — Installs like any other program

A person installs demoreel from their distro's usual tools, and the programs it
needs come with it. The man page, tab completion and translations land where the
system looks for them.

- 📋 [DEMO-0068] **Package demoreel for openSUSE through the Open Build Service.**
  This machine's distro. The package declares Xvfb, xauth, ffmpeg and
  xdotool as requirements, and xwayland-run and cage as recommended for
  `--gpu`. It installs the man page, completions and catalogs.
  **Layman:** Install demoreel on openSUSE with zypper, dependencies included.
  Kind: package.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0069] **Package demoreel for Debian and Ubuntu.**
  The GitHub runner is Ubuntu, so the package can be built and installed
  there as a gate step. Requirements: xvfb, xauth, ffmpeg, xdotool.
  Recommends the `--gpu` pair where the distro carries it.
  **Layman:** Install demoreel on Debian or Ubuntu with apt, dependencies included.
  Kind: package.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0070] **Package demoreel for Fedora and Arch.**
  Fedora through COPR, Arch as an AUR PKGBUILD. Same file layout and
  dependency split as the other packages.
  **Layman:** Install demoreel on Fedora (dnf) or Arch (from the AUR).
  Kind: package.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0071] **Let the tool find its translations whether installed or run from a checkout.**
  A package puts catalogs under /usr/share/locale. A checkout keeps them
  beside the script. The tool finds them from its own resolved path first,
  then the system location. The caller's working directory is never used,
  which the any-project requirement in CLAUDE.md demands.
  **Layman:** Translations work the same whether demoreel was installed from a package or run from its folder.
  Kind: implement.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0072] **Document an install from source, and check it in a clean container per distro.**
  For a distro with no package: which programs to install, where to put
  the script, man page, completions and catalogs. Verified by running it
  in a fresh container for each packaged distro, which also catches a
  missing dependency in the package lists.
  **Layman:** Anyone can install it by hand with a few commands, and those commands are tested.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0084] **Let a user verify that what they installed is what was released.**
  Once demoreel ships as packages and release files, a user needs a way to
  check that what they got is what this repository built. Publish
  checksums with each GitHub release, sign release tags, and add a build
  provenance attestation from the workflow. Say in SECURITY.md how to
  check each one.
  **Layman:** Downloads come with a way to check they are genuine and untampered.
  Kind: security.
  Source: user-request-2026-09-25.

## 0.6.0 — A window for people who want one

demoreel can be used from the command line or from a graphical window. Requested
2026-09-25. This reverses the scope ceiling's "no GUI", so that rule is lifted
first, through the review gate. The command line keeps every other rule: no
prompts, stdout carries only the path, and the same guarantees hold. The window
is a front-end to the same recording engine, not a second one.

- 📋 [DEMO-0085] **Lift "no GUI" from the scope ceiling in CLAUDE.md and README, through the review gate.**
  CLAUDE.md's Scope ceiling and README's What it will never do both name a
  GUI as permanently out of scope. The user asked for one on 2026-09-25.

  Changing that changes what a conformer builds, so rule 14 applies to
  both documents. README goes through `review-contract`, as the design
  contract it is. The rest of the ceiling stays and should be restated
  beside the change: no audio, no config file format, no plugins, no
  per-app profiles, no recording the real screen.

  Nothing else in this version starts before this lands.
  **Layman:** Update the project's rules so a graphical window is allowed, and have that change independently reviewed.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0086] **Write the GUI spec, and gate it before anything is built.**
  A spec, through `write-spec` and `review-contract`. It must settle:
  - The toolkit. Tkinter is in the standard library and keeps the tool
    dependency-free, but looks dated and scales poorly. Qt is native on
    this machine's KDE desktop and is a large dependency. GTK 4 is native
    on GNOME. Weigh looks, dependency weight and accessibility.
  - Whether the window runs the `demoreel` command as a child process or
    imports the engine. A child process keeps one engine and needs a
    machine-readable progress feed; importing needs the engine to raise
    errors rather than exit.
  - What it exposes, and what stays command-line only.
  - How it offers a Flatpak app without becoming the per-app profile
    registry the ceiling still rules out.
  - Keyboard use, screen readers, large text and the magnifier.
  - Translations, from the 0.4.0 catalogs.
  **Layman:** Decide on paper how the window will look and work before building it.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0087] **Build the window: pick an app, set the options, record, stop, open the result.**
  Choose the app by command or from the installed applications. Set size,
  length or record-until-stopped, the graphics-card mode and the pointer.
  Press Record and see the countdown. Press Stop. Then open the video or
  show it in its folder.

  Errors show the same text the command line prints, translated the same
  way.
  **Layman:** A window where you choose an app, press Record, and get your video.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0088] **Edit scripted actions in the window.**
  A list of steps -- wait, move, click, type, key -- to add, remove,
  reorder and edit, producing the same `-a` actions the command line
  takes. Show the equivalent command so a person can copy it into a
  script. Picking click coordinates on a live preview is a possible later
  step, not part of this item.
  **Layman:** Build the list of clicks and key presses for a demo in the window instead of typing them out.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0089] **Run the app command from the window without a shell.**
  The window takes a command as text, so it has to become an argument
  list. Split it with shlex and run it as a list, never with shell=True,
  which is how the command line already runs it. The desktop entry's
  Exec line must quote correctly, and a file-picker path must reach the
  command as one argument, whatever characters it contains.
  **Layman:** Whatever you type as the app to record is run as-is, never interpreted in a way that could run something else.
  Kind: security.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0090] **Make the window fully usable by keyboard, screen reader and magnifier.**
  Every control reachable by Tab and working with the keyboard. Every
  control named for a screen reader. Text follows the system font size.
  The layout holds under KWin's magnifier, which the user relies on. Check
  with the keyboard alone, and with Orca.
  **Layman:** People who can't use a mouse, use a screen reader, or magnify the screen can all use the window.
  Kind: accessibility.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0091] **Ship a desktop entry and icon, so the window appears in the app menu.**
  A .desktop file and an icon, installed by the 0.5.0 packages and by the
  install from source. The command-line tool installs as before; the menu
  entry opens the window.
  **Layman:** demoreel shows up in your applications menu with its own icon.
  Kind: package.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0092] **Test the window by recording it with demoreel.**
  The gate runs the window on a private display, which demoreel already
  provides. xdotool presses Record and Stop. The step checks that a
  finished video exists and that a frame of the window itself is not
  flat.
  **Layman:** The automatic checks open the window on a private screen, press Record, and check a video comes out.
  Kind: test.
  Source: user-request-2026-09-25.

## 0.7.0 — Sound, when you ask for it

Decided by the user on 2026-09-25: audio becomes an opt-in, and every run gets a private silent sound output by default. The user then asked for sound in the videos where it is relevant, so this section is the next work after `demoreel shot` (DEMO-0100), ahead of its version number. Relevant means the app's sound is part of what the video shows: a game, a music or audio app. Everything else stays silent. The docs' "no audio, ever" is lifted through the review gate before anything is built.

- 📋 [DEMO-0104] **Lift "no audio" from the scope ceiling in CLAUDE.md and README, through the review gate.**
  README's What it will never do and CLAUDE.md's scope ceiling both
  say audio is permanently out, and README records the design that
  would fit it. Rewrite both to allow an opt-in, keep the silent
  default, and gate each document (CLAUDE.md rule 14). Nothing below
  this item is built before it lands.
  **Layman:** Change the rule book so recording sound is allowed, before any sound code is written.
  Kind: doc.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0105] **Give every run a private silent sound output, so app sounds never reach the speakers.**
  Today every caller has to set PULSE_SERVER=unix:/nonexistent, or the
  app's sounds play on the user's speakers. Give each run its own sound
  output instead, reachable only by that run's app, and discarded by
  default. Must stay concurrency-safe and be cleaned up on every exit
  path, like the private screen. Measure PipeWire and PulseAudio both.
  **Layman:** An app being recorded can never play sound through your speakers, without any setting.
  Kind: feature.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0106] **Add `--audio`, which records the app's own sound into the video.**
  Built on the private sound output above: ffmpeg records its monitor
  beside the picture, into one file. Off by default; without it the
  video stays silent as today. A new flag, so MINOR under the
  versioning overrides. The gate records a tone-playing app and checks
  the track is not silent.
  User, 2026-09-25: "Games should definitely have audio." A game is
  the plainest case of a relevant video, so the record-demo skill and
  README's guidance name games first. Test with one: a tone-only
  fixture proves the track, a real game proves it is worth having.
  **Layman:** Optionally put the app's sound into the video, for trailers.
  Kind: feature.
  Source: user-request-2026-09-25.

## 1.0.0 — Every documented path tested

The exit condition in docs/standards/versioning-overrides.md: the gate
covers both display backends and the Flatpak invocation.

- ✅ [DEMO-0046] **Reword what reaching 1.0 requires, now that coverage can be conditional.**
  `versioning-overrides.md` § Reaching 1.0 holds MAJOR at 0 until the gate
  exercises both display backends and the Flatpak invocation, and explains
  that `--gpu` needs a runner with a usable card and Flatpak needs a
  published application. DEMO-0006 and DEMO-0007 now take a different
  route: the steps run where the hardware and the app are present and skip
  where they are not.

  So the condition as written is about to be satisfied on this machine and
  not on GitHub, and nothing in the document says which of those it meant.

  Decided (2026-09-20) by the user, with the options put: reword it, so 1.0
  means the checks exist and run wherever the hardware and the application
  are there.

  That is a change of direction in a standard -- a conformer reading it
  would cut 1.0 at a different time -- so the amendment runs
  `review-contract docs/standards/versioning-overrides.md --genre standard`
  before anything is built under it, per the machine-wide rule 14. Depends
  on DEMO-0006 and DEMO-0007 landing first: until the steps exist there is
  nothing for the new wording to describe.
  Shipped (2026-09-20) across 12de9ab, 9af13d8, 4cd2796 and e762cc2 --
  the rewrite and the three `review-contract` loops that gated it, rows 4
  to 6 of the document's own loop log.

  What the section says now: a path is exercised when a step records on
  it, looks at the picture and fails on a flat frame; a step need not run
  on every machine, and each one's prerequisites are named; a skip for one
  of those reasons prints its reason and does not withdraw the condition,
  but is still not a pass.

  The gate condition it originally held is met and is recorded as history.
  The live condition is new, and the user chose it over cutting 1.0 with
  both options put: MAJOR stays 0 until a video demoreel recorded has been
  used outside this repository, with the roadmap naming where. That
  wording is this session's rendering of the choice and is worth a second
  look by whoever owns the release.

  The gate cost eight fixes over three loops and reached its cap violently
  -- the last loop's findings were both repairs of the run's own earlier
  repairs, which is the same shape the document's previous gate recorded.
  Read row 6 before re-running it.
  **Layman:** Write down what 1.0 really waits for, now that the two missing checks can run here but not on GitHub.
  Kind: doc.
  Source: user-request-2026-09-20.

- ✅ [DEMO-0093] **Get a demoreel video used outside this repository, and record where.**
  The live 1.0 condition in versioning-overrides.md: a video demoreel
  recorded, used in another project's README, a store listing or a
  release page, with the roadmap naming where and linking to it.

  Other projects on this machine have GUI apps and no demo video. Offer
  them one. The owning session places it, since that project's files are
  its own. Record the link here when one lands.
  Progress (2026-09-25): demo videos recorded for games-hub (Games Hub,
  tile grid to Klondike and back) and vestige (meadow scene, --gpu at
  1920x1080). Copies are in ~/Videos/demoreel-demos/. Neither is public yet.
  vestige plans a demoreel-recorded video on antsprojectshub.co.za as its
  3D_E-0695; that published cut waits on its scripted demo mode, 3D_E-0696.
  vestige will send the URL to this project's mailbox. games-hub's owner
  decides on its README. Offers are waiting in the finbreak and ants-terminal
  mailboxes. The games-hub take also surfaced a real accessibility defect
  there (GHUB-0197): low-contrast controls on the dark palette.
  Progress (2026-09-25): first public use. The Ants Projects Hub
  site (antsprojectshub.co.za) now shows docs/media/demoreel-demo.mp4
  on demoreel's project page, live in projects hub commit 115f3b8.
  The clip is demoreel recording vkcube on --gpu inside a terminal
  it is also recording.
  Progress (2026-09-25): second public use. finbreak recorded a 30 s
  tour with demoreel itself, going public on
  antsprojectshub.co.za/p/fin-break.html. The Ants Terminal clip
  (~/Videos/demoreel-demos/ants-terminal-demo.mp4) is with the
  ants-terminal and hub sessions for its page and README; not
  confirmed live yet.
  Confirmed (2026-09-25) by the hub session, projects hub c474ce3:
  https://antsprojectshub.co.za/p/ants-terminal.html (Ants Terminal
  clip), https://antsprojectshub.co.za/p/fin-break.html (finbreak's
  tour) and https://antsprojectshub.co.za/p/demoreel.html, each
  credited "Recorded with demoreel."
  Confirmed (2026-09-25): the Ants Terminal clip is in the public
  README of github.com/milnet01/ants-terminal, commit 97d89b2d, as
  docs/screenshots/ants-terminal-demo.gif made from demoreel's MP4,
  credited "Recorded with demoreel on a private virtual screen".
  Confirmed (2026-09-26): vestige's page
  https://antsprojectshub.co.za/p/vestige-engine.html returned HTTP 200
  and served vestige-meadow.mp4, captioned "Recorded with demoreel."
  Also in Vestige's README as docs/media/vestige-meadow.mp4, per its
  session. Closed: the 1.0 condition is met by the Ants Terminal README
  and the hub pages named above.
  **Layman:** 1.0 waits for a video made with demoreel to be used somewhere real, like another project's page.
  Kind: marketing.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0094] **Run a full security pass before 1.0 and fix what it finds.**
  Everything since the last security look: the stop verdict, translations,
  packages and the window. Run `check-code` with its security tools
  (bandit, semgrep, gitleaks), zizmor over the workflow, and a
  `review-code` lane briefed on SECURITY.md's trust boundaries. Fix every
  verified finding. Bring SECURITY.md up to date, including the
  supported-versions line, which changes at 1.0.
  **Layman:** Before calling it finished, have the code checked end to end for security holes and fix any found.
  Kind: audit-fix.
  Source: user-request-2026-09-25.

- 📋 [DEMO-0095] **Audit the whole project once before 1.0 and fix what it finds.**
  One pass per question, each by the skill that owns it: `review-code`
  for defects, `review-tests` for whether the gate tests what it claims,
  `verify-instructions` running README and every quick-start page,
  `review-ledger` for whether ROADMAP and CHANGELOG are true, and
  `check-dependencies` for the pins. Fix every verified finding before
  cutting 1.0.
  **Layman:** Before calling it finished, check that the code, tests, docs and records all hold up, and fix anything that doesn't.
  Kind: audit-fix.
  Source: user-request-2026-09-25.
