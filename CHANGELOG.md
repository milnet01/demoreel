# Changelog

All notable changes to demoreel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change here, and how the numbers move while the
leading zero is there, is
[docs/standards/versioning-overrides.md](docs/standards/versioning-overrides.md).

The `[Unreleased]` block stays at the top, always, even when empty.

## [Unreleased]

## [0.1.1] - 2026-09-08

### Added

- **demoreel records a GUI app on a private virtual display.** One command
  takes the app to run and gives back a video file: it starts the display,
  launches the app on it, sizes the window to the frame, records with `ffmpeg`,
  optionally replays scripted actions, and tears everything down. Nothing of
  the user's real desktop is in frame, because the app never runs there.
  Two display backends: `Xvfb` by default, and `--gpu` for an app that needs
  the graphics card. Everything in this block is the first release; nothing has
  been tagged yet.

- **The pre-push gate ships with the repository.** (DEMO-0027)
  `git config core.hooksPath .githooks` turns it on after cloning. The gate
  previously reached this project through settings on one machine, so a fresh
  clone had `ci.sh` and nothing that ran it.

### Fixed

- **An app that exits without a window is no longer told it is a single-instance app.** (DEMO-0026)
  That was one possible cause stated as the established one. A command that
  simply finished without needing a window got the same message. It now says
  what happened, offers the hand-over as the likely cause, and names the
  other case.

### Security

- **The private display is behind an auth cookie on both backends.** (DEMO-0017)
  Every client is handed an `MIT-MAGIC-COOKIE-1` credential through an
  Xauthority file at mode 0600. Measured before the guard existed: a local
  process with no credential read the display's geometry and grabbed a frame
  of whatever was on screen. Socket permissions were no substitute, because
  `Xvfb` also listens on an abstract socket, which has none.

- **Text passed to `-a type` no longer appears in the system process list.** (DEMO-0018)
  It reaches `xdotool` on stdin instead of as an argument. It is still on
  demoreel's own command line, because the caller wrote it there, and
  SECURITY.md keeps that as a stated boundary rather than implying it is
  closed.

- **The run-state directory is checked before it is used.** (DEMO-0019)
  Without `XDG_RUNTIME_DIR` the fallback path is predictable, so on a shared
  machine another user can create it first. demoreel now refuses anything
  that is not a directory it owns, and looks with `lstat` so a planted
  symlink is seen rather than followed.

- **`demoreel stop` no longer signals a process it did not start.** (DEMO-0036)
  A run killed abruptly leaves its state file behind, and the system reuses
  process numbers -- so stop could send a terminating signal to whatever
  inherited the number. Reproduced against an unrelated `sleep`, which died.
  The run's start time is now recorded beside its process number and checked
  first.

- **The CI workflow keeps its token off disk and its values out of shell.** (DEMO-0037)
  Checkout no longer persists the job's credentials, where every later step
  could read them, and step values are passed through the environment rather
  than pasted into the script before the shell sees them. With DEMO-0038.
