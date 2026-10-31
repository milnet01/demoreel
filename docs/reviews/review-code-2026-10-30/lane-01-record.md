**Subject read:** `demoreel` lines 507–2845, which is 2339 lines. I read it in two pieces, 507–1706 and 1707–2845.

**Present on arrival:**
- the global `~/.claude/CLAUDE.md`, including its Rule 14 and review-skill text
- the user's email context
- a SessionStart hook note about the Ants MCP verbs
- the review-lane prompt
- no project memory, and no git snapshot

**Limits of this review:**
- I can run nothing, so every finding comes from reading the code. None is measured.
- X server and xdotool internals are from my memory of their sources, and each such claim says so.
- I read `python.md` only as lines 42–81 plus its headings, and `security.md` only as lines 1–120 plus a grep. README was read in slices, as briefed. I did not open `ci.sh`.

## Critical (1)

- [dim 3] `demoreel:742-743` — `added = subprocess.run(["xauth", "-f", str(auth), "add", display,` / `"MIT-MAGIC-COOKIE-1", secrets.token_hex(16)],` — **The display's cookie is in `xauth`'s command line (CWE-214).**
  - Any local user without `hidepid` can read `/proc/<pid>/cmdline`. A tight poll can catch even a short-lived process.
  - With the cookie and the display number (visible in `/tmp/.X11-unix`), a stranger passes the lock. They can grab frames, and with XTEST type into the caller's app.
  - This defeats the boundary SECURITY.md calls "the whole point". `security.md` line 151 also says "Not on a command line". SECURITY.md is silent on it, so the code is wrong.
  - Rated Critical because it is exploitable with the default configuration. It is on the second-user path the gate cannot reach.
  - fix: feed `add … ` to `xauth -f F source -` on stdin.

## High (3)

- [dim 3] `demoreel:754-756` — `if not gpu:` … `proc.send_signal(signal.SIGHUP)` — **On `--gpu`, a stranger who connects before the cookie stays connected for the whole run.**
  - Your own docstring says "before the cookie both get in". `wait_until_locked` tests only new connections.
  - Nothing closes an existing one on Xwayland. There is no reset, `-noreset` is set, and SIGHUP cannot be sent because `proc` is cage.
  - From memory of the X server source, a reset kills all clients, so Xvfb's SIGHUP covers this. Xwayland has no equivalent.
  - An inotify watch on `/tmp/.X11-unix` gets the stranger inside the gap of a few milliseconds.
  - fix: write the cookie into the auth file before the server starts. As I recall, the server ignores the entry's display number, so measure this. Add the client entry once the number is known.

- [dim 3] `demoreel:2037`, `2047` — `if path.is_symlink() and path.lstat().st_uid != os.getuid():` … `return path.resolve()` — **`own_path` checks only the last path component, and `resolve()` then removes the kernel's protection.**
  - (a) An attacker's `/tmp/x` → `~victim/dir` with `-o /tmp/x/demo.mp4` is not a leaf symlink. `resolve()` follows it with `readlink`, and `protected_symlinks` does not govern `readlink`. The writer then gets the victim's path. With protection on, the `lstat` through the link may raise EACCES first, and I expect this to vary by Python version. Unmeasured.
  - (b) A link swapped in between line 2037 and line 2047 is also resolved here. SECURITY.md's "A link planted after that check is opened by the writer itself" is therefore false for that gap (CWE-367).
  - fix: refuse any foreign symlink on the way up, and return `parent.resolve() / name`, so the writer opens the leaf itself.

- [dim 16] `demoreel:2076`, `2080` — `park_pointer(env, width, height)` / `except (FileNotFoundError, PermissionError) as exc:` — **`launch` can leak the display, which breaks the "cleanup on every exit path" requirement.**
  - `server` is still `None` in the caller, so its `finally` cannot end the display.
  - A script with no shebang raises `OSError` ENOEXEC, and `NotADirectoryError` and ELOOP behave the same. An xdotool timeout in `park_pointer` calls `die`.
  - Each one leaves Xvfb in its own session, holding its display number. The auth file stays behind too.
  - fix: wrap everything after the server starts in one `try`, catching `OSError`, and end the server there.

## Medium (15)

- [dim 7] `demoreel:2280` — `note(tr("the recorder stopped early; see {log}", log=logpath))` — **An early recorder exit can still end in success.**
  - `recorder.returncode` is never read, and neither is `server.poll()` during the run.
  - A stray SIGTERM to ffmpeg makes it finish its file. A `-d 30` run then yields a short, playable video, exit 0, a printed path and `result: ok`.
  - If Xvfb dies and takes the app with it, every sample is skipped as "the app closed", with the same result.
  - fix: an early exit with neither a stop nor a deadline fails the run.

- [dim 7] `demoreel:1136`, `1145` — `xdotool(env, "click", v["button"])` / `xdotool(env, "key", *v["keys"])` — **Step results are thrown away.** No caller passes `check=True`, and stderr is captured and dropped. A step xdotool rejects vanishes from the video, and the run still exits 0. fix: check the return code in `run_action` and die with `last_said`.

- [dim 3] `demoreel:1145` — `xdotool(env, "key", *v["keys"])` — **Argument injection through a step (CWE-88).**
  - xdotool chains commands, and from memory `key` stops at the next command name. So `key a exec sh -c '…'` would run a command.
  - The step grammar promises seven verbs. A `--steps` file can be mistaken for data.
  - fix: allow only keysym-shaped tokens, and refuse xdotool's command names.

- [dim 3] `demoreel:986`, `871-873` — `return [wid for wid in ids if xdotool(env, "getwindowname", wid).stdout.strip()]` — **A window title can crash the run.**
  - `text=True` decodes strictly. A non-UTF-8 title, such as Latin-1 `WM_NAME`, raises an uncaught `UnicodeDecodeError`.
  - The run then ends with a traceback. This is the only path I found by which a title affects control flow beyond "named or not".
  - fix: `errors="replace"`.

- [dim 3] `demoreel:1266` — `return output.with_name(f".{output.stem}.demoreel-part.mp4")` — **Paths that `own_path` never checks.**
  - The part file is predictable, sits beside `-o`, and is written with `-y`. `timestamped_output` likewise gets no check, and its `exists()` follows a dangling link.
  - Only the kernel protects these, and only in sticky directories where the sysctl is on.
  - SECURITY.md lists only `-o` and `--app-log`, so both the document and the code are incomplete.
  - fix: run all written paths through the same check.

- [dim 3] `demoreel:2037` — `if path.is_symlink() and path.lstat().st_uid != os.getuid():` — **A file owned by another user passes the check.**
  - A 0666 file planted at `/tmp/demo.mp4` or at the app log's path receives the video or the app's output. The attacker can then read it.
  - The only defence is `fs.protected_regular`, where it is on. A hard link or FIFO is the same class.
  - fix: refuse an existing path not owned by the caller, using the same `lstat`.

- [dim 3] `demoreel:638`, `2417` — `statefile = state_dir() / f"{a.name}.json"` — **`--name` is not validated, and neither argparse nor `prepare` checks it.**
  - `-n ../x` or `-n /abs/x` writes the lock, state, logs and auth outside the 0700 directory, and `stop` then cannot find the run.
  - `-n a/b` gives a traceback at `os.open`.
  - `-n a.Xvfb --gpu` shares run `a`'s auth path (lines 677 and 810), and its `unlink` removes the file.
  - fix: restrict the name to `[A-Za-z0-9._-]+`.

- [dim 8] `demoreel:87` — `_stop.set()` — **The signal handler can deadlock.**
  - `Event` uses a non-reentrant `Condition(Lock())`. A signal landing while the main thread holds `_cond` makes the handler block on its own thread's lock. The main thread holds it inside `Event.wait`, before `Condition.wait` releases it.
  - The window is small, but `_stop.wait` runs five times a second.
  - The run then hangs while still recording, and `stop` waits forever because its `poll(…, None)` has no bound.
  - From reading CPython's `threading.py`, unmeasured.
  - fix: use `signal.set_wakeup_fd` or a `sigwait` thread.

- [dim 11] `demoreel:1258` — `threading.Thread(target=proc.stdout.read, daemon=True).start()` — **Unbounded buffer on `-d 0`.** The "drain" keeps everything until EOF. At `-stats_period 0.05` that is about 5 KB/s by my estimate, or some 18 MB an hour. fix: read and discard in a loop.

- [dim 2] `demoreel:869` — `timeout = CALL_TIMEOUT + TYPE_SECONDS_PER_CHAR * len(stdin_text or "")` — **The allowance is smaller than the pace.** Line 52 allows 0.05 s per character while line 1142 types with `--delay 60`. Text over about 1000 characters times out, and the run dies with the false message "stopped answering". The comment at lines 48–51 still says 12 ms. The code is wrong. fix: raise the constant to cover the 60 ms pace.

- [dim 9] `demoreel:1218` — `"-y", str(partial_video(output) if monitor else output),` — **A failed retake destroys the last good take.** The plain Xvfb path truncates an existing `-o` video the moment recording starts. A retake that then fails has already lost the previous video. The `--gpu` and `--audio` paths avoid this. fix: always record to the part file, then rename.

- [dim 9] `demoreel:2480`, `1401` — `finish_gpu_video(output, logpath)` — **Finishing runs in `finally` whether or not this run recorded anything.**
  - A part file left by a killed run gets finished by a later run that failed before recording, for example when the app exited at start. That can overwrite `-o` and delete the kept part.
  - If the stale part cannot be finished, `die` replaces the real error, because a `SystemExit` raised in `finally` wins. The same masking hits `_display_gone` runs.
  - `input_starts` (line 1343) raises `FileNotFoundError` when the log is absent, for example under another `-n`.
  - fix: finish only if this run's recorder started, and keep the first error.

- [dim 16] `demoreel:2019` — `while output.exists():` — **The default output name has a check-then-use gap.**
  - The name is checked seconds before anything creates it. Two `shot`s of one app in the same second, or two named runs, get the same file. Both exit 0 and print one path.
  - Two `--gpu` runs with one `-o` share the part file. One removes it, and at line 1370 the other returns silently and vouches for its sibling's output.
  - fix: reserve the name with `O_EXCL`.

- [dim 16] `demoreel:1593` — `if proc is None or proc.poll() is not None:` — **The app's process group is skipped once its leader has exited.**
  - A wrapper script's children therefore survive. Children that ignore SIGTERM also get no SIGKILL after the leader goes.
  - Once the sink is unloaded, a survivor's sound moves to the default output, which is against DEMO-0106 INV-9.
  - fix: signal the group regardless of the leader, by group id. Take care with reuse of the group id.

- [dim 2] `demoreel:533` — `base = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp")` — **`stop` depends on matching environments.** A `stop` from a session without the variable (cron, or SSH without PAM) looks in `/tmp/demoreel-<uid>` and answers "no recording is running" while one records. The same mismatch lets two runs hold one name. README says "in the same or another terminal". fix: `stop` also searches `/run/user/<uid>` and the fallback.

## Low / Info

- [dim 4] `demoreel:1081` — `return verb, {"seconds": float(args[0])}` — `drag` refuses `inf` and `wait` and `hold` do not. `wait inf` passes "every step is readable" and then raises `OverflowError` mid-recording. fix: share the range check.
- [dim 4] `demoreel:2506`, `2552`, `1453`, `2514` — `["ffmpeg", "-hide_banner", "-loglevel", "error",` — these lack the `-nostdin` their siblings have. They eat the caller's stdin. A backgrounded `shot` on a terminal may stop on SIGTTOU and time out with a misleading message (unmeasured). fix: add `-nostdin`.
- [dim 7] `demoreel:2773` — `with contextlib.suppress(ProcessLookupError):` — a pid reused by another user gives `PermissionError` and a traceback. fix: suppress it too.
- [dim 7] `demoreel:2003`, `2431` — `output.parent.mkdir(parents=True, exist_ok=True)` / `appout = open(applog, "wb") if applog else sys.stderr` — an unwritable path gives a traceback rather than a `die`. fix: catch `OSError`.
- [dim 7] `demoreel:1325`, `2470` — `threading.Thread(target=lambda: log.write(proc.stdout.read()),` — the thread can write after `log.close()`, which prints a thread traceback and loses the log. Also, nothing reaches the log until EOF. fix: join the thread before closing.
- [dim 16] `demoreel:2612`, `2712` — `finally:` / `except SystemExit as exc:` — on `shot` and `check`, a second SIGTERM inside `finally`, or one during `start_xvfb`, leaks the display. `display_problem` also swallows a SIGTERM as "did not start". fix: mask these signals during teardown.
- [dim 16] `demoreel:1452` — `grab = subprocess.run(` — the sampling ffmpeg shares demoreel's process group, so Ctrl+C can kill it and a clean stop fails as "could not sample". fix: `start_new_session=True`.
- [dim 15] `demoreel:1145` — `xdotool(env, "key", *v["keys"])` — key steps sit in xdotool's command line even under `--steps`. SECURITY.md's promise covers only `type`. fix: say so in SECURITY.md.
- [dim 15] `demoreel:1067` — `die(tr("cannot read the step {step}: {reason}.", step=repr(spec), reason=e))` — a mistyped `Type pass'word` line prints the whole secret to stderr. fix: name the line number instead.
- [dim 9] `demoreel:2622` — `die(f"{failed}\n  " + tr("Its display log is kept in {folder}", folder=rundir))` — failed shots keep their folders in RAM, `screen.png` included, with no eviction. fix: prune old `shot-*` folders.
- [dim 9] `demoreel:2556` — `output.unlink(missing_ok=True)` — a failed cut deletes a file that was already at `-o`. A `TimeoutExpired` from the cut can leave a partial file, despite README's promise. fix: cut to a temporary file, then rename.
- [dim 3] `demoreel:536` — `d.mkdir(parents=True, exist_ok=True)` — the directory is created at the umask's mode and tightened on line 551, so under a loose umask others can plant files first. fix: `mode=0o700`.
- [dim 2] `demoreel:2509` — `"-frames:v", "1", "-y", str(output)],` — a `%` in a `shot` path is read as an image2 pattern (unmeasured). fix: `-update 1`.
- **Doc-side:** DEMO-0106 §4.5 and §6 say `prepare` checks the pulse input. The code moved that check to `cmd_record` on purpose (DEMO-0165), and `prepare`'s docstring agrees, so the spec is wrong.
- **Doc-side:** SECURITY.md's helper list omits `pactl`, `ffprobe` and `ldd`, and `has_encoder` also loads a library chosen by `PATH` through `ctypes`.
- **INFO, by dimension:**
  - #2b: nothing found. Only the zombie's contract surfaces in my slices were checked.
  - #5: filed under #11.
  - #10, #12: N/A, no contract named.
  - #13: nothing found.
  - #17: the state file's missing-key cases are handled, and nothing further was found.

## Covered by spec and looks correct

I opened these and confirmed them by reading:
- **`proc_stat`:** the rightmost-`)` split and the field arithmetic.
- **`is_our_run`:** it refuses bad pids and a missing start time.
- **`run_succeeded`:** it requires matching pid, start time and `result`.
- **`claim_name`:** the raw fd stays open and is not inherited.
- **`state_dir`:** the `lstat` and owner check.
- **`write_state`:** the atomic replace inside the 0700 directory.
- **`sh -c` text:** only integers and `shlex.quote`d values go in (CWE-78).
- **Paths handed to ffmpeg:** always absolute, so no option or protocol injection (CWE-88).
- **`type` text:** goes by stdin only.
- **Stdout discipline:** every `Popen` and `run` in the lane sets `stdout`.
- **DEMO-0106 environment:** `Sound.env` and sink names.
- **DEMO-0106 labels:** sanitised before they reach `pactl`.
- **DEMO-0106 order:** unload order, sweep rule and the `start:` failure path.
- **gpu-backend order:** the startup sequence and `--cursor` refusal.
- **gpu-backend note:** the note's wording.
- **gpu-backend check:** the check of the finished file.
- **Blank check:** the `frame_is_flat` logic.

**How `stop` decides:** it needs the state file to name the same pid and start time, with `result: "ok"`, after that process has ended or become a zombie.
- **Processes:** a stranger cannot forge this, because the directory is 0700.
- **Same-user processes:** one can rewrite the file, as can the recorded app, which is handed `XDG_RUNTIME_DIR`. That is no privilege boundary, and SECURITY.md does not list it.
- **False successes:** the real ones are the early-recorder-exit and shared-part findings above.

**App output:** it goes only to stderr or `--app-log` and is never parsed, so it cannot steer demoreel. Recorder logs are parsed, but the app does not write to them.

## Open questions

- Does Xwayland really keep a connection made before the lock? This is the High finding above. Your docs show new clients are refused, and say nothing about existing ones.
- Should `-d N` promise a video of about N seconds? README does not say, so I cannot tell whether the early-exit finding is a contract breach or only an honest-reporting one.
- Is a `--steps` file trusted as much as the command? SECURITY.md does not say. The severity of the `exec` finding turns on this.
- Is the kernel-dependent gap for `-o` and the part file acceptable? SECURITY.md accepts it for `-o`. Whether that extends to machines with `protected_symlinks` off or to non-sticky shared directories is yours to settle.
- Arrived holding project-adjacent context: the global `CLAUDE.md`, as listed at the top.

## 3 items to fix first

1. **The cookie on `xauth`'s command line.** It is a one-call fix, and today any local user can pass the lock the tool exists to provide.
2. **The `--gpu` pre-lock connection and the `own_path` parent and gap holes.** Both are second-user paths the gate cannot reach. One breaks display privacy and the other allows overwriting a victim's files.
3. **The `launch` leak, together with the unchecked recorder exit.** The first breaks a non-negotiable requirement with a script that has no shebang. The second lets a run and `stop` report success on a truncated video.
