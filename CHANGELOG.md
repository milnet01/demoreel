# Changelog

All notable changes to demoreel are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
What counts as a breaking change here, and how the numbers move while the
leading zero is there, is
[docs/standards/versioning-overrides.md](docs/standards/versioning-overrides.md).

The `[Unreleased]` block stays at the top, always, even when empty.

## [Unreleased]

### Added

- **demoreel records a GUI app on a private virtual display.** One command
  takes the app to run and gives back a video file: it starts the display,
  launches the app on it, sizes the window to the frame, records with `ffmpeg`,
  optionally replays scripted actions, and tears everything down. Nothing of
  the user's real desktop is in frame, because the app never runs there.
  Two display backends: `Xvfb` by default, and `--gpu` for an app that needs
  the graphics card. Everything in this block is the first release; nothing has
  been tagged yet.
