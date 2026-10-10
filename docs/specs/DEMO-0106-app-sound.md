<!-- ants-spec-format: 1 -->
# DEMO-0106 — Record an app's own sound, and keep every app's sound off the speakers

**Status:** accepted (2026-10-10).
**Kind:** feature.
**Source:** ROADMAP DEMO-0106 (user-request-2026-09-25; decisions 2026-10-10).
**Blocked by:** DEMO-0104 (the scope ceiling still says audio is out).
**Pairs with:** DEMO-0105 (built under this contract; no spec of its own), DEMO-0177 (music, and keeping a clip's sound through the finishing commands; its own spec).

Add `--audio` to `demoreel record` and the app's sound is in the video, in
step with the picture; without it nothing changes, and in neither case does
the app's sound play on the speakers.

## 1. Goal

`demoreel record --audio -- <app>` writes an `.mp4` whose sound track is the
app's own sound, in step with the picture to within 40 ms. Every
`record` and `shot` run, with or without `--audio`, gives its app a private
sound output that nothing plays, so a recorded app never sounds on the
user's speakers and two runs never hear each other. Without `--audio` the
file is exactly what it is today.

## 2. Problem

1. demoreel's videos are silent by design: `start_ffmpeg` reads only
   `x11grab`, and `README.md` § What it will never do rules sound out. The
   user's purpose for the tool is trailers of their apps, and some of those
   apps, games first, are not worth showing without their sound (user,
   2026-10-10).
2. A recorded app plays its sound through the user's speakers today. `launch`
   builds the app's environment from the session's, so the app finds the
   session's sound server and its default output. The workaround callers use
   is `PULSE_SERVER=unix:/nonexistent` (DEMO-0105's body), which every caller
   has to know.
3. Recording sound naively puts it out of step with the picture. Measured
   2026-10-10 (probe below, § 4.4): one ffmpeg reading `x11grab` and `pulse`
   put a beep 0.52 s before the screen change it was played with.

## 3. Scope decisions (agreed with the user)

All made by the user on 2026-10-10, in this session:

- **Sound in demoreel's videos is wanted.** The "no sound" rule was never the
  intent; it came from the first outline. DEMO-0104 rewrites the documents.
- **The app's sound is off unless `--audio` is given.** A film's sound is the
  caller's choice: none, the app's own, music (DEMO-0177), or both.
- **App sound should never reach the speakers if it can be avoided**, whether
  or not it is recorded. Where a private output cannot be made, normal sound
  is acceptable for a run that is not recording sound.

## 4. Design

### 4.1 The private sound output (DEMO-0105)

Every `record` and `shot` run loads a PulseAudio null sink before the app
starts, through `pactl`, which talks to PulseAudio and to PipeWire's PulseAudio
server alike:

```
pactl load-module module-null-sink sink_name=<sink> \
      sink_properties=device.description=demoreel-<name>
```

`<sink>` is `demoreel-<uid>-<pid>-<token>`, where `<token>` is 16 hex
characters from `secrets.token_hex(8)`. The server does not make sink names
unique: measured 2026-10-10, two loads of one name both succeeded and listed
two sinks of that name. So after loading, the run lists the sinks
(`pactl list short sinks`) and requires exactly one named `<sink>`. Anything
else unloads the module and fails the run. A name is never chosen to be free
in advance and then trusted; it is checked after the fact, which is the same
property `claim_name` keeps for run names.

The run keeps the module index `pactl` prints in memory, for its own
unload. `stop` never unloads a sink: the run it stops does, in its
`finally`. A sink left behind is found by name alone (§ 4.2).

`launch` adds two variables to the app's environment:

```
PULSE_SINK=<sink>        # PulseAudio clients
PIPEWIRE_NODE=<sink>     # native PipeWire clients, and ALSA through PipeWire
```

Both are needed. Measured 2026-10-10 with `aplay`, `paplay` and `pw-play`
each playing a tone: with both set, all three reached the sink; with
`PULSE_SINK` alone, `aplay`'s tone missed it and played on the speakers. A
Flatpak passes both variables into its sandbox (measured: `flatpak run
--command=sh` printed both).

The sink is unloaded with `pactl unload-module <index>` in `cmd_record`'s and
`cmd_shot`'s `finally`, after `stop_recorder` and `end_process(app)`, before
`end_server`. `launch` unloads it itself when the app fails to start, as it
already ends the display.

### 4.2 Leftover outputs

A run killed with SIGKILL runs no `finally`, and its sink stays loaded:
measured 2026-10-10, a module whose loader was killed was still listed. So
each run, before loading its own sink, unloads every module whose sink name
starts `demoreel-<uid>-` and whose `<pid>` is not a live process. `demoreel
check` does the same sweep. A sink of another user is never touched.

### 4.3 Recording the sound

`--audio` is a flag on `record`. It is refused on `shot` and with `-d`
values the run cannot record (none today). With it, `start_ffmpeg` adds a
second input and the audio encoder:

```
-thread_queue_size 1024 -f pulse -i <sink>.monitor
-c:a aac -b:a 192k -ar 48000 -ac 2
```

The x11grab input gets `-thread_queue_size 1024` too, so neither input drops
packets while the other is read.

`--gpu --audio` adds `--audio=<sink>.monitor -C aac` to
`start_wf_recorder`, as one argument: `man wf-recorder` gives the device as
optional (`-a, --audio [=DEVICE]`), so it must be attached.
Whether that track is in step is not measured: `wf-recorder` does not start
on this machine since the Packman update DEMO-0176 reports. § 13 holds it.

### 4.4 Keeping sound and picture in step

ffmpeg starts each output stream at zero, but the `pulse` input opens later
than `x11grab`. Its log (`-loglevel level+info`, which `start_ffmpeg` already
uses) prints each input's wallclock start:

```
[info] Input #0, x11grab, from ':1':
[info]   Duration: N/A, start: 1791639429.995988, bitrate: 73728 kb/s
[info] Input #1, pulse, from 'demoreel_sync_probe_1776287.monitor':
[info]   Duration: N/A, start: 1791639430.511217, bitrate: 1536 kb/s
```

This section is the Xvfb path's. `wf-recorder` logs no start times, so
`--gpu --audio` keeps `finish_gpu_video`'s plain copy until § 13 is settled.

So an Xvfb `--audio` run records into the part file `partial_video` names, and
finishing remuxes it with the sound shifted by the gap, the same shape as
`finish_gpu_video`:

```
ffmpeg -i <part> -itsoffset <audio_start - video_start> -i <part> \
       -map 0:v -map 1:a -c copy -shortest -movflags +faststart -y <output>
```

`-shortest` ends the sound with the picture. Measured 2026-10-10 on the
§ 4.4 probe: without it the shifted track ended 0.5 s after the picture
(start 0.494 s, duration 5.021 s, picture 5.0 s); with it the track ended
at 4.982 s, and the beep stayed at 1.919 s.

Measured 2026-10-10 on Xvfb, with the root window turned white and a beep
started at the same instant: before the shift the beep led by 0.53 s; after
it, the flash was at 1.933 s and the beep at 1.919 s, 14 ms apart. Setting
`-use_wallclock_as_timestamps 1 -copyts` instead did not move the gap.

A run whose log lacks either `start:` line fails rather than writing a file
it cannot vouch for.

### 4.5 When there is no private output

`pactl` missing, no sound server, or a load that fails:

- **Without `--audio`:** the run goes on, and prints one note on stderr
  that the app's sound may play on the speakers, naming the reason.
- **With `--audio`:** the run stops before launching the app, names the
  reason, and exits non-zero. `prepare` checks for `pactl` and for an
  ffmpeg with the `pulse` input device only when `--audio` is given, and
  names the install command as it does for other programs (`install_hint`).
  `pactl` never joins `required_programs`, which every run and `check`'s
  readiness lines read.

### 4.6 What the run reports

- An `--audio` video whose track is silent throughout (`volumedetect`
  `max_volume` at or below -60 dB) gets one note on stderr: the app made no
  sound that reached demoreel. It is not an error: an app may be silent.
- `demoreel check` gains a line, `--audio: ready` or `--audio: NOT READY`
  with the reason. It never changes `check`'s exit status, as `--gpu`'s does
  not.
- stdout still carries the finished path and nothing else.

Every new message goes through `tr`, and `./ci.sh --pot` regenerates the
template.

## 5. Invariants

- **INV-1** — Without `--audio`, `record` writes a file with no audio stream,
  exactly as before this change.
  *Test:* ci.sh: the existing smoke recording, plus `ffprobe -select_streams a
  -show_entries stream=index` printing nothing. The fixture isolates the
  default path; only adding a track unasked could fail it.
  *Breaks when:* the pulse input or the remux is applied to every run.

- **INV-2** — Every `record` and `shot` run gives its app `PULSE_SINK` and
  `PIPEWIRE_NODE` naming one sink that run loaded, and a tone the app plays
  through PulseAudio, ALSA or native PipeWire reaches that sink and no other.
  *Test:* ci.sh, where a sound server runs: `record --audio` an `xterm` that
  plays one tone with `paplay`, then `aplay`, then `pw-play`; each third of
  the track has `max_volume` above -40 dB, and during the run `pactl -f json
  list sink-inputs` shows every stream of the app's process group on the
  run's sink. A `shot` of the same `xterm` runs the sink-input check too.
  The three players isolate the two variables: dropping `PIPEWIRE_NODE`
  silences the `aplay` third only.
  *Breaks when:* either variable is missing, or the app inherits the
  session's default output.

- **INV-3** — Two runs at once never share a sink, and neither records the
  other's sound.
  *Test:* ci.sh: two `--audio` runs started together, one playing a tone and
  one silent; the silent run's track is at or below -60 dB, and both exit 0.
  Isolates uniqueness: with one constant name for every run, the second run
  fails § 4.1's exactly-one check and exits non-zero.
  *Breaks when:* the sink name can repeat.

- **INV-4** — No run leaves its sink loaded: not on success, on a failed
  launch, on `demoreel stop`, on Ctrl+C, or on SIGTERM or SIGHUP. A sink
  left by a SIGKILLed run is unloaded by the next run or by `check`.
  *Test:* ci.sh: after each of those exits, and after a `shot`, `pactl list short sinks` lists
  no sink starting `demoreel-<uid>-<pid>-` for that run's pid; after a
  SIGKILL, it lists one until the next run, then none.
  *Breaks when:* the unload is missing from a `finally`, `launch`'s failure
  path, or the sweep.

- **INV-5** — In an `--audio` video recorded on Xvfb, sound and picture are
  within 40 ms of each other. `--gpu` is outside it until § 13 is settled.
  *Test:* ci.sh: record an app that turns its window white and starts a beep
  at the same instant; the first bright frame's time and the beep's onset
  (`silencedetect` `silence_end`) differ by at most 0.040 s. Isolates the
  shift: without it the gap measured 0.53 s.
  *Breaks when:* the remux shift is missing, has the wrong sign, or reads the
  wrong input's `start:`.

- **INV-6** — An `--audio` video recorded on Xvfb has exactly one audio
  stream, AAC, 48000 Hz, stereo, which ends within 0.1 s of the video
  stream's end. `--gpu` is outside it until § 13 is settled.
  *Test:* ci.sh: `ffprobe -show_entries stream=codec_type,codec_name,
  sample_rate,channels,start_time,duration` on the INV-2 recording, comparing
  `start_time + duration` per stream. Comparing durations alone passed the
  § 4.4 probe without `-shortest`, whose sound overran by 0.5 s.
  *Breaks when:* the encoder options change, or the shift leaves sound past
  the picture's end.

- **INV-7** — Where no private output can be made, a run without `--audio`
  completes with a note on stderr, and a run with `--audio` exits non-zero
  before the app starts and names the reason.
  *Test:* ci.sh: both runs with `PULSE_SERVER=unix:/nonexistent` and
  `PIPEWIRE_REMOTE` pointed at a missing socket; the first exits 0 with the
  note, the second exits non-zero, and no app process was started.
  *Breaks when:* a sink failure is ignored with `--audio`, or fatal without.

- **INV-8** — `check` reports `--audio` as ready or not, with the reason,
  and its exit status depends only on the default backend.
  *Test:* ci.sh, beside the existing check step: on a machine with a sound
  server it prints `--audio: ready`; under INV-7's environment it prints `NOT
  READY` and still exits 0.
  *Breaks when:* the line is missing, or a missing sound server fails
  `check`.

- **INV-9** — An app's sound never plays on the session's default output,
  where a private output could be made.
  *Test:* covered by INV-2's sink-input listing: a stream on the default
  sink fails it. No test listens to the speakers.
  *Breaks when:* the same as INV-2.

The private sink is a trust boundary of a weak kind: any process of the same
user can list it and read its monitor. That is the same reach a user's own
processes already have over every sink in the session, and demoreel adds no
other. It does not make the sink more private than that, and says so in
README.

## 6. Failure modes

- **No sound server, `pactl` missing, or a load refused:** § 4.5.
- **The server lists two sinks of the run's name:** the run unloads its
  module and fails. A 64-bit token makes this a defect elsewhere, not luck.
- **The app picks an output by name**, ignoring both variables: its sound
  goes there. INV-2's sink-input check fails in the gate; a real app doing it
  is outside demoreel's reach and README says so.
- **The sound server restarts mid-run:** the sink and its monitor vanish,
  and ffmpeg keeps recording. Measured 2026-10-10: with the sink unloaded
  two seconds into a 15 s run, ffmpeg exited 0 at 15 s with a full-length
  sound track. The sound goes quiet from that moment, and the run cannot
  tell.
- **ffmpeg without the `pulse` device:** `prepare` refuses `--audio` and
  names the install command.
- **A Flatpak without sound permission:** it makes no sound, the track is
  silent, and § 4.6's note says so.
- **The log lacks a `start:` line:** § 4.4; the run fails.
- **`--gpu --audio`:** unmeasured, § 13.

## 7. Tests

All in `ci.sh`. INV-1, INV-7 and INV-8's NOT READY half run everywhere.
The rest are one step group after the smoke recording. They need a
sound server; where `pactl info` fails, the group prints a skip line, as the
`--gpu` steps do. On GitHub's runner the group therefore skips unless the
workflow starts a sound server (§ 13).

- INV-1: the smoke step's added `ffprobe` check (runs everywhere).
- INV-2, INV-9: "--audio records the app's sound, whichever way it plays".
- INV-3: "two --audio runs never hear each other".
- INV-4: "no run leaves a sound output behind".
- INV-5: "--audio keeps sound and picture in step".
- INV-6: checked inside INV-2's step.
- INV-7: "no sound server: record goes on, record --audio stops".
- INV-8: beside "check says whether this machine can record".

Each is seen to fail first: INV-1 by adding the pulse input to every run,
INV-2 by dropping `PIPEWIRE_NODE`, INV-3 by giving every run one constant
sink name, INV-4 by
removing the unload, INV-5 by removing the shift, INV-7 by ignoring the load
failure.

## 8. Alternatives considered (and rejected)

- **A separate sound recorder (`parec`, `pw-record`) and a merge at the
  end.** Two processes to start, stop and clean up, and the same start-gap
  problem, measured from two logs instead of one. One ffmpeg plus a shift is
  simpler and measured.
- **A private PulseAudio server per run** (`pulseaudio --daemonize` with its
  own socket). Truly private, but PipeWire systems have no `pulseaudio`
  binary, and a second server per run is heavier than a sink.
- **`PULSE_SERVER=unix:/nonexistent` for runs without `--audio`.** The current
  workaround. It silences PulseAudio clients only; ALSA through PipeWire
  would still reach the speakers, and some apps refuse to start without a
  sound server.
- **`-use_wallclock_as_timestamps 1 -copyts` to align the inputs.** Measured,
  no effect on the gap.

## 9. Out of scope

- Music, and keeping a clip's sound through `edit`, `trim`, `caption`, `join`
  and `card` — tracked by DEMO-0177. Until it ships, finishing an `--audio`
  recording drops its sound, as README says of every input today.
- Choosing which of an app's outputs to record, or a microphone — deferred;
  not yet queued.
- Volume control of the app's sound at recording time — deferred to
  DEMO-0177's mix.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | ci.sh smoke step's audio-stream check |
| INV-2 | ci.sh "--audio records the app's sound, whichever way it plays". Partial: skips where no sound server runs, including GitHub |
| INV-3 | ci.sh "two --audio runs never hear each other". Partial: same skip |
| INV-4 | ci.sh "no run leaves a sound output behind". Partial: same skip |
| INV-5 | ci.sh "--audio keeps sound and picture in step". Partial: same skip; Xvfb only |
| INV-6 | ci.sh, inside INV-2's step. Partial: same skip; Xvfb only |
| INV-7 | ci.sh "no sound server: record goes on, record --audio stops" |
| INV-8 | ci.sh check step. Partial: the ready half skips without a sound server |
| INV-9 | ci.sh INV-2's sink-input listing. Partial: same skip; nothing listens to the speakers |
| Trust boundary (§ 5, last paragraph) | **nothing** — it is a limit stated in README, not a defence |
| `--gpu --audio` sync | **nothing** — unmeasured until `wf-recorder` runs again (§ 13) |

## 11. Cross-doc impact

- `README.md`: § What you get and § What it will never do (through DEMO-0104's
  gate), a `--audio` entry in the record options, what the private output
  does and does not protect, the Flatpak note that a sandboxed app needs sound
  permission, and the finishing commands' "Sound in an input is dropped" kept
  until DEMO-0177.
- `CLAUDE.md`: § Scope ceiling (DEMO-0104), the dependency list in § State
  (`pactl`), and a trap: the app needs both `PULSE_SINK` and
  `PIPEWIRE_NODE`.
- `docs/history/claude-md.md` § Audio: corrected by DEMO-0104.
- `CHANGELOG.md`, the `po/` template and catalogs (new messages, DEMO-0060).
- `DEMO-0068` § 4.2: an `--audio` row beside `--gpu`'s, recommending
  `pactl`'s package, never requiring it, as `--gpu`'s programs are (its
  INV-5). openSUSE's is `pulseaudio-utils` (`rpm -qf /usr/bin/pactl`); the
  others are not verified here.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0106-app-sound-loop-log.md`.

## 13. Open questions

- **`--gpu --audio` sync.** `wf-recorder --audio=` records the sink's
  monitor, but whether its track is in step is not measured, because
  `wf-recorder` does not start here (DEMO-0176). Build it, and run INV-5's
  fixture on `--gpu` as a measurement, not a gate, once `wf-recorder`
  starts. If it is out of step and `wf-recorder` logs no start
  times, the fallback is the Xvfb path's shape: record the monitor with
  ffmpeg beside it and shift by the two start times.
- **`pactl`'s package on each distro.** `install_hint` leaves out any
  program its family's `PACKAGES` table does not name, so `pactl` needs an
  entry for every family before `--audio` ships. openSUSE's is
  `pulseaudio-utils`, measured; the others are unverified here, and
  DEMO-0068's container installs are where to verify them.
- **CI coverage.** Most invariants skip on GitHub, which runs no sound
  server. Starting one in the workflow (`pipewire` and `pipewire-pulse`, or
  `pulseaudio --start`) would make them run there; whether it works in the
  Ubuntu image is unmeasured.
