<!-- ants-spec-format: 1 -->
# DEMO-0086 — A window that records an app by running `demoreel record`

**Status:** accepted (2026-11-15).
**Kind:** implement.
**Source:** ROADMAP DEMO-0086 (user-request-2026-09-25; toolkit decided by the user 2026-11-15; § 3's four calls decided by the user 2026-11-15).
**Blocker for:** DEMO-0087, DEMO-0088, DEMO-0089, DEMO-0090, DEMO-0091, DEMO-0092, DEMO-0253, DEMO-0264.

Layman: a window where you pick an app, choose a few settings, press Record and Stop, and get the same video the command line makes.

## 1. Goal

`demoreel window` opens a Qt window, built with PySide6, that records an
app the way `demoreel record` does, because it runs `demoreel record`. A
person picks the app by command or from the installed applications, sets
the size, a length or until-stopped, the graphics-card mode, the pointer,
the app's own sound and a list of scripted steps, then presses Record and
Stop and opens the video. The window is usable by keyboard alone, by a
screen reader and under KWin's magnifier, and speaks every language the
catalogs carry. Every other command works as today, with or without PySide6
installed.

## 2. Problem

1. demoreel has no window. Everything is the command line `build_parser`
   builds, which suits a script or a Claude session and not a person who
   wants to press a button. README § What it will never do no longer rules a
   window out (DEMO-0085).
2. The engine reports progress only to people. `progress` draws its line on
   a terminal only, and `note` and `die` write prefixed text to stderr. A
   window reading that text would be reading meaning out of translated
   strings, which `CLAUDE.md` § Traps forbids.
3. The engine ends on errors. `die` calls `sys.exit`, and `main` and `cmd_record` install process-wide signal handlers (`_exit_on_signal`, `_request_stop`) and
   module-wide state (`_stop`, `_catalogs`). Calling `cmd_record` from inside
   a window would end or freeze the window on the first error.
4. A desktop entry's `Exec` line is quoted by its own rules, not a shell's.
   Turning one into the command to record without those rules either breaks
   paths with spaces or runs something the entry never named (DEMO-0089).

## 3. Scope decisions (agreed with the user)

All by the user, 2026-11-15:

- **Toolkit: Qt through PySide6.** Strongest screen-reader and magnifier
  support on Linux and Windows, native on KDE. It is the first dependency
  beyond the standard library, and it is the window's alone (INV-1).
- **The window runs `demoreel record` as a child process** and reads a new
  `--events` feed. It does not import and call the recording engine.
- **1.1.0's window records, with sound and scripted steps.** `shot`, `check`
  and the finishing commands stay on the command line until the 2.0.0
  editor (DEMO-0140).
- **The window remembers nothing between launches.** A settings file is the
  config file format README § What it will never do rules out. The window
  shows the equivalent command instead, for the person to keep.
- **1.1.0 is built and tested on Linux only.** The window's own code keeps
  anything Linux-only inside the functions § 4.7 names, so 2.0.0 can bring it
  to Windows.

## 4. Design

### 4.1 Where the window lives

A new subcommand, `demoreel window`, in the same `demoreel` file. Its
function `cmd_window` is the only place that imports PySide6, and imports it
inside its body. The tool stays one file, so the window's messages are
extracted by `./ci.sh --pot` like every other, catalogs load from the same
`po/` (DEMO-0060 INV-9), and the packages install no new script.

Without PySide6, `demoreel window` exits 1 with a message naming the distro's
package for it, by the same route `install_hint` names a missing program,
with the package names DEMO-0091 settles.

`cmd_window` puts SIGINT, SIGTERM and SIGHUP back to their defaults before Qt starts.
`main`'s `_exit_on_signal` runs only when Python code runs, which a Qt event
loop rarely does, so it would leave the window deaf to all three.

### 4.2 Running a recording

Each recording is one child process:

```
[sys.executable, <this script, symlinks resolved>, "record", "--events",
 "-n", <run name>, <options from the form>, ("--steps", "-")?, "--", <app argv>]
```

- **Run name:** `window-<window pid>-<n>`, `n` counting from 1 in this window.
  It passes `check_name`, and no two windows share one.
- **Working directory:** the folder the form names. Its default is
  `QStandardPaths.MoviesLocation`, or the home folder where that does not
  exist. No `-o` is passed, so the file gets the name `record` already gives
  it. The folder is not remembered.
- **Steps** go on the child's standard input through `--steps -`, which keeps
  typed text out of the process list (README § Scripted steps). No steps, no
  `--steps`.
- **The child is started with Qt's asynchronous `QProcess`.** Nothing on the
  window's thread waits on a child (INV-13).
- **If the window dies, the run finishes its video** rather than recording
  until someone runs `demoreel stop`. `record --events` sees to that itself
  (§ 4.3), because PySide6 6.12's `QProcess` has no `setChildProcessModifier`
  to set it from the window (measured: `hasattr` is false).
- **One run at a time per window.** Record is disabled while one runs.
- **Stop** runs `demoreel stop <run name>` as a second child. That keeps
  `wait_until_recording`'s rule: a stop sent while the run starts gives a short
  video, never none. If that child fails while the record child still runs,
  as when Stop comes before the run can be addressed, the window runs it
  again.
- **Closing the window during a run** does what Stop does, then closes once the
  record child has exited. The window says it is finishing the video.

The command never passes through a shell, on any path (INV-6).

### 4.3 The `--events` feed

`record --events` writes progress on **stdout**, one JSON object per line,
UTF-8, each ending `\n`. Stdout is the channel because it already carries
nothing but demoreel's own words: the app's output goes to stderr or
`--app-log` (`CLAUDE.md` § Traps, stdout), so an app cannot forge an event.
**Stderr is unchanged by `--events`**, byte for byte.

```
{"event": "note",      "text": "<message>"}
{"event": "recording"}                       # recording has begun
{"event": "time",      "left": <int>}        # once a second, -d N runs
{"event": "time",      "elapsed": <int>}     # once a second, -d 0 runs
{"event": "finishing"}                       # the countdown has ended
{"event": "done",      "path": "<output>"}   # last line, exit status 0
{"event": "error",     "text": "<message>"}  # last line, non-zero exit
```

- `text` is the message exactly as it reads after `demoreel: ` on stderr in
  the same run, translated the same way. It is for showing, never for parsing.
- `done` replaces the bare path `record` prints without `--events`. Its `path`
  is the same string, written by `json.dumps` with its default ASCII escaping,
  so a path that is not UTF-8 travels as its surrogate escapes and
  `os.fsencode` gives back the file's bytes.
- `recording` is sent where `cmd_record` writes `recording: True` to the state
  file. `time` events come from the two `progress` call sites in
  `run_countdown`, whether or not stderr is a terminal; the terminal line is
  unchanged. Those run five times a second, so a `time` event is sent only
  when its number changes.
- Each event is flushed as written. A write that fails means the reader has
  gone: the events stop, and the run finishes its video as on SIGHUP. Once
  the steps have run, a `time` event goes out each second, so this also
  catches a parent that died before the `prctl` call below.
- **On Linux, `--events` also asks the kernel for `SIGHUP` when the parent
  process exits** (`prctl(PR_SET_PDEATHSIG, SIGHUP)` through `ctypes`, which
  the script imports already). The kernel sends it when the thread that
  started the child ends, so the window starts every child from its main
  thread. `cmd_record` treats SIGHUP as "finish the video" (DEMO-0115). A
  program reading events is driving the run, so when it goes the run ends as
  it would on a closed terminal.
- An argparse error comes before `--events` is read, so it has no event. The
  window treats an exit with no last `done` or `error` as a failure and shows
  the stderr it collected.
- `--events` is `record`'s alone in 1.1.0.

### 4.4 What the form offers

| Control | Becomes | Default |
|---|---|---|
| App command, a text field | the argv after `--`, by `shlex.split` | empty |
| Installed applications, a searchable list | fills the text field (§ 4.5) | — |
| Choose a program file | fills the text field with `shlex.quote(path)` | — |
| Size, an editable list | `-s` | `record`'s default |
| Length in seconds, or until stopped | `-d N`, or `-d 0` | `record`'s default |
| Needs the graphics card | `--gpu` | off |
| Show the pointer | `--cursor`; disabled while `--gpu` is ticked, as `prepare` refuses the pair | off |
| Record the app's sound | `--audio` | off |
| Scripted steps, a list (DEMO-0088) | `--steps -` | none |
| Save in folder | the child's working directory | § 4.2 |

Every default is read from the `record` parser `build_parser` builds, never
written as a literal in the window (INV-14).

A command text `shlex.split` refuses, such as an open quote, is reported
beside the field, and Record stays disabled until it parses. So is one
holding a byte that is not UTF-8: `QProcess` carries text, and on PySide6
6.12 a lone surrogate argument arrived empty. Each step is
checked with `parse_step` before Record is enabled, and a step holding a
character `str.splitlines` breaks on is refused: `--steps` reads one step
per line. Its refusal reaches the
window as the `SystemExit` `die` raises, and its text is shown, not read.

**The equivalent command** sits under the form, as `shlex.join` of the
command a person would type: `demoreel record`, the options, each step as
`-a`, `--`, the app. A button copies it. It holds no folder: a person runs
it from the folder the form names.

**Stays on the command line:** `-o` as a file name, `-r`, `-n`, `--app-log`,
`--settle`, `--startup-timeout`, `shot`, `check`, `stop` of another run, and
the finishing commands.

**While recording:** the time left or elapsed, from `time` events; Stop.
**After:** the path, Open video and Open folder (`QDesktopServices`), or the
error text.

### 4.5 Installed applications, and Flatpak

The list reads `applications/` under `XDG_DATA_HOME` and each `XDG_DATA_DIRS`
entry, defaults as the XDG Base Directory spec gives them. Flatpak apps are
there because Flatpak puts its `exports/share` directories in
`XDG_DATA_DIRS`. An entry is listed when it is `Type=Application`, not
`NoDisplay=true` or `Hidden=true`, and its `Exec` parses. The first file found
for a desktop-file id wins, as the spec orders them.

`exec_to_argv(value) -> list[str] | None` turns an `Exec` value into argv,
by the Desktop Entry Specification's rules
(Source: https://specifications.freedesktop.org/desktop-entry/latest/exec-variables.html):

1. Undo the string escapes `\s \n \t \r \\` first.
2. Split on unquoted spaces. A double-quoted argument ends at the next
   unescaped `"`. Inside it, `\"`, `` \` ``, `\$` and `\\` stand for the
   character. An open quote, or a reserved character outside quotes, is
   invalid.
3. Remove every field code: `%f %F %u %U %i %c %k`, and the deprecated
   `%d %D %n %N %v %m`. `%%` becomes `%`. A field code inside a quoted
   argument, or any other `%` code, is invalid.
4. An empty result is invalid.

Invalid returns `None`, and the entry is not listed. The window never runs an
`Exec` value: it puts `shlex.join(argv)` in the text field, which the person
can read and change before pressing Record.

**What stops this becoming a per-app profile registry:** the window treats a
Flatpak entry as any other entry. It adds no flags, keeps no list of apps, and
stores nothing about one. When a Flatpak app shows no window, the person sees
`record`'s own error. README § Recording a Flatpak app keeps the three-flag
fallback, which the person can type into the field.

### 4.6 Accessibility

- Every control that takes focus has an accessible name: its own
  `accessibleName`, or a `QLabel` whose buddy it is (INV-11).
- Tab reaches every enabled control, in the order the form reads (INV-11).
- No font size, pixel width or pixel height is set. Text follows the system
  font, and layouts, not fixed geometry, size the window.
- Focus moves where the next action is: to Stop when a run starts, to Open
  video when it ends, to the error text when it fails. KWin's magnifier
  follows focus, so the person's view moves with it.
- Starting, finishing and failing are announced to screen readers with
  `QAccessibleAnnouncementEvent`. The countdown is not: once a second is
  noise. It stays readable as a label.
- Nothing is said by colour alone.

### 4.7 Translation and portability

- The window's messages go through `tr`, `trn` and `tr_help` inside function
  bodies, as every message does (DEMO-0060 INV-15).
- Qt's own strings, such as a file dialog's buttons, come from Qt's
  translations for the first code `chosen_languages` gives that Qt carries.
- Where the catalog in use is in `RTL_LANGUAGES`, the window's layout runs
  right to left.
- The child inherits the window's environment, so it speaks the same language.
- **Linux-only window code sits in two functions**: the installed-applications
  reader and `exec_to_argv`. Elsewhere each returns nothing. The death signal
  is the engine's (§ 4.3). The module's own top-level imports, such as
  `fcntl`, are 2.0.0's to make portable (§ 9).

## 5. Invariants

- **INV-1** — Every command but `window` runs as before when PySide6 cannot be
  imported. `demoreel window` then exits 1 with one message naming how to
  install PySide6.
  *Test:* `ci.sh` step `the window: the command line runs without PySide6` —
  `PYTHONPATH` names a folder whose `PySide6/__init__.py` raises
  `ImportError`; `demoreel --help` and a 2-second `record` of `xclock` exit 0,
  and `demoreel window` exits 1 with `PySide6` in its stderr.
  *Breaks when:* PySide6 is imported at module level, or in a function another
  command calls.

- **INV-2** — With `--events`, every stdout line is one JSON object with an
  `event` key from § 4.3's list. The last line is `done` when the exit status
  is 0, and `error` when it is not, apart from an argparse error. Without
  `--events`, stdout is the bare path as today.
  *Test:* `ci.sh` step `record --events: one JSON event per line` — a 2-second
  `xclock` run, and a run of a command that does not exist; each stdout line
  parses, the first run's last is `done` with a `path` that exists, the
  second's last is `error`. The smoke step's run without `--events` still
  prints one path.
  *Breaks when:* a message, or the path, is printed to stdout outside an event,
  or the final event is skipped on a failure path.

- **INV-3** — An `error` or `note` event's `text` equals the stderr line of the
  same run after `demoreel: `, and stderr is the same with and without
  `--events`.
  *Test:* the step of INV-2 runs the failing command with and without
  `--events`; the two stderrs are equal, and the `error` text is the stderr
  message without its prefix.
  *Breaks when:* the event is built from a separate string, or `--events`
  moves a message off stderr.

- **INV-4** — Under the pseudo-locale, every event field but `text` is the
  same bytes as under `LC_ALL=C`, `time` events apart, whose count is timing's. This narrows DEMO-0060 INV-2, which held
  stdout fixed under every locale, to runs without `--events`.
  *Test:* the step of INV-2, with a fixed `-o`, run again under DEMO-0060
  § 7's pseudo-locale; the events, with `text` removed and `time` events
  left out, compare equal.
  *Breaks when:* an event name or `path` passes through `tr`.

- **INV-5** — On a `-d N` run, `time` events carry `left`, a whole number from
  N down to 1 that never rises. On a `-d 0` run they carry `elapsed`, which
  never falls.
  *Test:* the step of INV-2 reads the 2-second run's `time` events; a
  `-d 0` run stopped after 2 seconds by `demoreel stop` is read the same way.
  *Breaks when:* the two `progress` call sites are swapped, or `left` is
  counted from the run's start rather than the countdown's.

- **INV-6** — Trust boundary: the window starts every child that runs demoreel as
  an argument list whose first two entries are `sys.executable` and the
  resolved script. No shell runs a command the window builds, and the app's argv is the one the text field
  parses to.
  *Test:* `ci.sh` step `the window: no shell` — an `ast` walk over the
  window's functions finds no `shell=True`, no `os.system`, no
  `QProcess.startCommand` and no `sh -c`.
  *Breaks when:* a command is built as one string. Partial: a string built and
  run by another route escapes the walk.

- **INV-7** — For every argv, `shlex.split(shlex.join(argv)) == argv`, so an
  installed app or a chosen file reaches the child unchanged.
  *Test:* `ci.sh` step `the window: commands survive the text field` — argvs
  holding a space, both quotes, `$`, a backslash, a newline, and `;`
  round-trip.
  *Breaks when:* the field is filled with `" ".join`, or split with
  `posix=False`.

- **INV-8** — `exec_to_argv` gives this table's results:

  | `Exec` value as written in the file, escapes and all | Result |
  |---|---|
  | `flatpak run --branch=stable org.x.App %U` | `flatpak`, `run`, `--branch=stable`, `org.x.App` |
  | `"/opt/My App/app" --new` | `/opt/My App/app`, `--new` |
  | `app "a\\\\b"` | `app`, `a\b` |
  | `app "cost \\$5"` | `app`, `cost $5` |
  | `app 100%%` | `app`, `100%` |
  | `app "%f"` | `None` |
  | `app %z` | `None` |
  | `app "open` | `None` |
  | `app a;b` | `None` |
  | `%U` | `None` |

  *Test:* `ci.sh` step `the window: desktop entries` — the function imported
  from `demoreel` and called on each row.
  *Breaks when:* the string escapes are undone after the quotes, field codes
  are kept, or an invalid line is split anyway.

- **INV-9** — The window writes nothing under `XDG_CONFIG_HOME` or
  `XDG_DATA_HOME`.
  *Test:* `ci.sh` step `the window: remembers nothing` — the window built
  offscreen (`QT_QPA_PLATFORM=offscreen`) with both pointed at empty folders,
  a field changed and the program-file dialog opened and cancelled, then
  closed; both folders are still empty, and `QSettings`
  occurs in `demoreel` only to point Qt's user settings at a folder removed
  when the window closes. A Qt file dialog writes its state there whatever
  its options (measured 2026-11-18, PySide6 6.11 and 6.12).
  *Breaks when:* `QSettings`, a recent-files list or a saved geometry is
  added, or a `QFileDialog` saves its state (measured: a stock one wrote
  `QtProject.conf` under `XDG_CONFIG_HOME`).

- **INV-10** — When the process that started `record --events` is killed
  during a `-d 0` run, the run finishes its video: its state file's `result`
  becomes `ok` and the file plays.
  *Test:* `ci.sh` step `record --events: a run outlives its parent` — a `sh`
  that reads the run's stdout through a pipe starts `record --events -d 0` of
  `xclock`, and is killed with SIGKILL once it reads `recording`; within 10 seconds the run's pid has gone, `result` is
  `ok`, and `ffprobe` reads a duration from the video.
  *Breaks when:* the death signal is dropped (the run records until stopped),
  or set to SIGKILL (the display leaks and no video is finished), or a
  failed event write fails the run.

- **INV-11** — Every focusable control has an accessible name, its own or a
  buddy label's, and the Tab chain from the first control visits every enabled
  one and returns to it.
  *Test:* `ci.sh` step `the window: every control is named and reachable` —
  built offscreen, the widget tree walked and the focus chain followed.
  *Breaks when:* an icon-only button has no name, or a control is left out of
  the Tab order.

- **INV-12** — Under a catalog, every label, button and announcement the window
  writes is translated, and under an `RTL_LANGUAGES` catalog the layout runs
  right to left.
  *Test:* the step of INV-11, run under DEMO-0060 § 7's pseudo-locale: every
  label, button and announcement text begins `⟦` and ends `⟧`, the
  equivalent command and the person's own values aside; under a pseudo `he` catalog,
  `layoutDirection()` is `RightToLeft`.
  *Breaks when:* a label is set from a literal, or translated at import.

- **INV-13** — Nothing on the window's thread waits on a child or a file.
  *Test:* the step of INV-6 also finds no `subprocess.run`, `.wait(`,
  `.communicate(`, `waitForFinished` or `waitForReadyRead` in the window's
  functions.
  *Breaks when:* a run, a stop or the app list is read synchronously. Partial:
  a slow call by another name escapes the walk; DEMO-0253 measures the rest.

- **INV-14** — The window's starting values are the `record` parser's defaults.
  *Test:* the step of INV-11 compares each control's value with
  `get_default` on the `record` parser.
  *Breaks when:* a default is written into the window as a literal and the
  parser's changes.

- **INV-15** — Focus goes to Stop when a run starts, to Open video when it
  ends, and to the error text when it fails, and each of the three is
  announced.
  *Test:* where focus goes, `ci.sh` step `the window: focus follows the run`:
  from Record, with stand-ins that succeed and fail, focus visits Stop and then
  Open video or the error text, and no other control. The announcements: an
  AT-SPI listener on a private display and accessibility bus heard all three,
  on one run that succeeded and one of a command that does not exist
  (DEMO-0090, 2026-11-18). No gate step repeats it.
  *Breaks when:* a control is disabled while it holds focus. Qt hands focus to
  the first field, which a screen reader names, before the next control takes
  it.

## 6. Failure modes

- **PySide6 missing:** INV-1's message; the command line is untouched.
- **A PySide6 too old for `QAccessibleAnnouncementEvent`** (Qt 6.8): the window
  refuses to start, naming the version it needs, rather than run without
  announcements.
- **The child cannot start** (the interpreter has gone): the window shows
  `QProcess`'s own error and enables Record again.
- **The child exits with no final event** (argparse error, SIGKILL): the
  window shows the stderr it collected and the exit status.
- **A stdout line that is not JSON:** a demoreel bug by INV-2. The window shows
  it as text and goes on reading.
- **Stop's own child fails** (the run had already ended): the record child's
  final event decides what the window shows.
- **The window is killed:** INV-10. Each run finishes its video, and its
  state file lets `demoreel stop` read how it ended.
- **No `MoviesLocation` folder:** the home folder.
- **A desktop entry with a bad `Exec`:** not listed (INV-8). A folder that
  cannot be read is skipped.
- **A single-instance app already running:** `record`'s own error names it
  (`CLAUDE.md` § Traps).
- **The window recorded by demoreel** (DEMO-0092): it runs on the gate's
  private display, and its child starts its own; `-displayfd` keeps them apart.

## 7. Tests

The steps INV-1 to INV-14 name are new `ci.sh` steps. INV-15's focus half is a
`ci.sh` step DEMO-0090 added; its announcements were checked once, by hand.
The steps of INV-9, INV-11, INV-12, INV-14 and INV-15 build the window
and need PySide6. Where it is missing, they skip and are counted on the gate's
last line, as a step that could not run is now. A skip is not a pass. The
other steps need no PySide6 and always run.

Each test is seen failing first: INV-1 against a copy that imports PySide6 at
the top; INV-2 against one that prints the path outside `done`; INV-8 with
the string escapes undone last; INV-9 with a `QSettings` write; INV-10 with
the death signal removed; INV-11 with one button's name blanked; INV-15's
focus half against the window as DEMO-0088 left it, which disabled Record and
Stop before moving focus.

`ci.sh` step `the window: recorded by demoreel, Record and Stop pressed`
(DEMO-0092) records the window with demoreel and presses Record and Stop
with `xdotool`. The window's video must appear while the window is still
open and last less than record's default length, and neither video may end
flat. It needs PySide6 and skips without it. Seen failing first against a
window whose Stop was not connected.

## 8. Alternatives considered (and rejected)

- **Import the engine and call `cmd_record`.** `die` ends the process, the
  signal handlers and `_stop` are process-wide, and a stuck X call would
  freeze the window. Fixing those is a rewrite of the engine's error paths,
  for no gain over a child process. Rejected by the user, 2026-11-15.
- **Read the state file for progress.** It holds no countdown and no message,
  and nothing documents it as a contract.
- **Events on stderr, or on a passed file descriptor.** Stderr carries the
  app's output, which could forge an event. A passed descriptor does not
  carry to Windows through `QProcess`. Stdout is clean already.
- **A second script, `demoreel-window`.** It would need the engine's `tr`
  loaded from another file, a second extraction source for the template, and a
  new path in every package. The subcommand needs none.
- **Tkinter or GTK 4.** Tkinter exposes almost nothing to screen readers; GTK
  4 is weak on Windows. Decided by the user, 2026-11-15.
- **Remember the last settings.** Needs a settings file, which the scope
  ceiling rules out. Rejected by the user, 2026-11-15.
- **Run `demoreel check` when the window opens.** Its report is for reading,
  and a missing program already fails Record with `prepare`'s own message.

## 9. Out of scope

- `shot`, `check` and the finishing commands in the window — the 2.0.0 editor,
  DEMO-0140.
- The window on Windows, and making `demoreel` import there — 2.0.0; not yet
  queued as its own item.
- Picking click positions on a live preview — named as a later step in
  DEMO-0088; not yet queued.
- Packaging PySide6, the desktop entry and the icon — DEMO-0091.
- Start-up time, idle CPU and memory — DEMO-0253.
- Click counts per task — DEMO-0264.
- The usage log and reports, which would store a file — DEMO-0274 and
  DEMO-0275 must settle that against INV-9 before they are built.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | `ci.sh` step `the window: the command line runs without PySide6` |
| INV-2 | `ci.sh` step `record --events: one JSON event per line` |
| INV-3 | `ci.sh` step `record --events: one JSON event per line` |
| INV-4 | `ci.sh` step `record --events: one JSON event per line`, under the pseudo-locale |
| INV-5 | `ci.sh` step `record --events: one JSON event per line` |
| INV-6 | Partial: `ci.sh` step `the window: no shell` walks the window's functions only |
| INV-7 | `ci.sh` step `the window: commands survive the text field` |
| INV-8 | `ci.sh` step `the window: desktop entries` |
| INV-9 | `ci.sh` step `the window: remembers nothing` |
| INV-10 | `ci.sh` step `record --events: a run outlives its parent` |
| INV-11 | `ci.sh` step `the window: every control is named and reachable` |
| INV-12 | `ci.sh` step `the window: every control is named and reachable`, under the pseudo-locale |
| INV-13 | Partial: `ci.sh` step `the window: no shell` names the known blocking calls only |
| INV-14 | `ci.sh` step `the window: every control is named and reachable` |
| INV-15 | Partial: `ci.sh` step `the window: focus follows the run` checks where focus goes; the announcements, an AT-SPI listener run once by DEMO-0090 |
| § 4.6, no fixed sizes | **nothing** automatic — DEMO-0090's check by hand under the magnifier, 2026-11-18 |
| § 4.5, no per-app knowledge | **nothing** — review; the window holds no app names to grep for |

## 11. Cross-doc impact

- `docs/specs/DEMO-0060-translation-catalogs.md` INV-2: annotated, with this
  spec, to hold for runs without `--events` (INV-4 here).
- `README.md`: `window` and `--events` under § The options, so `ci.sh`'s
  documented-flags step passes; § In plain words and § What you get name the
  window. The manual page and tab completion gain both.
- `CLAUDE.md` § State: PySide6 as the window's dependency; § Traps: stdout
  carries `--events` as well as the path.
- `docs/specs/DEMO-0068-linux-packages.md`: PySide6 is recommended, never
  required, as the `--gpu` programs are (its INV-5) — DEMO-0091 amends it.
- `./ci.sh --ci-packages`: PySide6 for the window steps; whether Ubuntu 24.04
  carries a new enough one is § 14's.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0086-recording-window-loop-log.md`.

## 13. Resource cost

One new dependency, PySide6, for the window alone. The window holds one run's
collected stderr, capped at the last 1 MiB, and one list of desktop entries.
DEMO-0253 sets its time and memory budgets.

## 14. Open questions

- Does Ubuntu 24.04 package a PySide6 of Qt 6.8 or later? This machine has
  PySide6 6.12 (`python3 -c "import PySide6; print(PySide6.__version__)"`).
  Unverified for Ubuntu, Debian, Fedora and Arch. If one lacks it, the gate's
  parity image and that distro's package take PySide6 from elsewhere, or the
  window steps skip there. Settled by DEMO-0091 before the window ships.
