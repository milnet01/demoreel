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
