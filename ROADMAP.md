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
  Checked (2026-09-08): both pins are at their latest release, so nothing is
  owed today and the item stays open as the standing chore it describes.

  ruff is pinned at 0.16.6, which is what the machine has installed and what
  astral-sh/ruff reports as its latest release -- so a local run and CI lint with
  the same tool.

  actions/checkout is pinned by SHA 3d3c42e5aac5ba805825da76410c181273ba90b1,
  commented v7.0.1. Verified the comment rather than trusting it: the tag ref for
  v7.0.1 resolves to exactly that commit, and v7.0.1 is the latest release.

  Neither is held below its latest, so no hold-ledger row is owed.
  **Layman:** Two version numbers are written down in CI and will go stale unless someone bumps them
  Kind: chore.
  Source: user-request-2026-09-07.

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
  **Layman:** Every recording is written twice; the second pass buys something we may not need
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
  **Layman:** The video settings are tuned for film; a mostly-still app window compresses far better
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
  **Layman:** Half the tool's features have no automatic check behind them
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
  **Layman:** Recording a Flatpak the wrong way gives a black video and no clue why
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
  **Layman:** One exact value makes the tool say the app is there and the gate say it never arrived
  Kind: fix.
  Source: review-contract-2026-09-07 loop 2.

- 📋 [DEMO-0025] **Action text still sits in demoreel's own command line for the whole run.**
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

- 📋 [DEMO-0030] **The gate still does not exercise --settle or --cursor.**
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

- 📋 [DEMO-0042] **The gate records nine times, one after another, before every push.**
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
  **Layman:** The pre-push check runs nine separate recordings in a row, and waits for each.
  Kind: perf.
  Source: optimisation-pass-2026-09-08.

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
  **Layman:** Ask for a 3 second clip and you get just over 4 seconds, after a second of waiting
  Kind: perf.
  Source: in-session-2026-09-07.

- 📋 [DEMO-0033] **When the blank check cannot take its sample, it reports the run as fine.**
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
  **Layman:** The check that refuses an empty video quietly passes everything if its own measurement breaks.
  Kind: fix.
  Source: recommendation-2026-09-08.

- 📋 [DEMO-0034] **A run cannot be stopped until it has already started recording.**
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
  **Layman:** Start a recording and try to stop it straight away, and you are told it is not running.
  Kind: enhancement.
  Source: recommendation-2026-09-08.

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
