**Line counts.** Subject: `ci.sh`, lines 4414-7510, which is 3,097 lines. I read them all with `Read`.

**Present on arrival.** The global `CLAUDE.md`, the review-lane prompt, the environment block, and the user's email from harness context. No project `CLAUDE.md`, memory index or git snapshot.

**Disagreements and reading outside the slice**
- The brief bans test files, but the lane tail puts `ci.sh` in scope. I followed the tail, as it says to.
- The shared context says not to re-read `SECURITY.md`. My first batch read it anyway, in parallel with the shared context, before I had seen that line.
- Cross-references I opened:
  - `demoreel` lines 350-410, 532-556 and 2028-2050
  - `ci.sh` lines 1-40 and 640-650
  - `python.md`, Scope and Traps
  - one whole-file `ci.sh` grep and one `demoreel` grep
- I did not open `standards/security.md`, and I judged against the named CWEs instead.
- I did not read `ci.sh` before line 4414, including `finishing_checks`, except for that grep. "No step" below means no step in this range, unless I say the whole-file grep confirms it.

## Critical (0)

## High (3)

- **[dim 3] `ci.sh:6581` and `:6583`**
  - Quote: `./demoreel shot -o "$foreign" -s 320x240 -- xclock 2>"$tmp/foreign.err"`
  - The step's safety rests on `$foreign`, a root-owned link in `/usr/bin` (`:6576`), belonging to "another user". Run as root, it belongs to the caller. `demoreel:2037` (`path.lstat().st_uid != os.getuid()`) then lets it through, and `path.resolve()` hands the writer the link's target, which is whichever system file `find` lists first.
  - Nothing refuses root: the grep finds no `EUID` or uid check in `ci.sh`, and the `USER ci` at `:645-647` protects only the parity image. `sudo ./ci.sh`, or a rootful container, can overwrite or truncate a system file. The step reports "wrote through" only after that.
  - I did not open the writer. `--app-log` is the path most likely to write, because it has no output format that could fail first.
  - Fix: refuse to run the gate as root at the top of `ci.sh`, or point the link at a file in `$tmp`.

- **[dim 2] `ci.sh:6557`** (coverage claim: gate side short)
  - Quote: `ln -s /tmp "$tmp/fakerun/demoreel-$(id -u)"`
  - `SECURITY.md` says of the state directory "the run stops unless the path is a directory the caller owns. … The gate covers this." The planted link is owned by the caller, so only `S_ISDIR` on the `lstat` result trips (`demoreel:547`).
  - The `st_uid != os.getuid()` half is what stops the attack `SECURITY.md` describes, another user creating the path first, and no step reaches it. Deleting that half leaves this step green. The closing `echo` at `:6569`, "a state directory we do not own is refused", claims more than was run.
  - Neither the `/tmp` fallback nor the non-directory case is run by this step.
  - Fix: run this case as a second user in a container where `useradd` already exists, or narrow the sentence in `SECURITY.md`.

- **[dim 2] `ci.sh:6492`** (coverage claim: `SECURITY.md` overclaims)
  - Quote: `XAUTHORITY=/dev/null DISPLAY="$disp" xdotool getdisplaygeometry >/dev/null 2>&1`
  - `SECURITY.md` says "Both backends…" sit behind the cookie, and adds `-nolisten tcp`, mode 0600 and the Wayland socket's location, then "The gate covers this." Only the cookie refusal on Xvfb is exercised:
    - The `--gpu` step (`:5583-5632`) has no cookie probe, and it skips on GitHub.
    - The whole-file grep finds no `nolisten`, `ss -ltn`, `0600` or `stat -c` in `ci.sh`.
    - There is no positive control beside the probe, so any `xdotool` failure counts as a refusal.
  - Fix: add a probe that carries the cookie, repeat both probes on `--gpu`, and assert the mode and the absence of a listener. Otherwise reduce the sentence to "on Xvfb".

## Medium (6)

- **[dim 3] `ci.sh:4893`**
  - Quote: `kill -KILL "$pid" 2>/dev/null || true`
  - `gate_pids` keeps every recorder started during the run, including ones reaped long ago. `cleanup` sends SIGTERM and then an unconditional SIGKILL to each, on every exit, success included. A recycled pid means an unrelated process of the same user is killed.
  - The gate's own step at `:6431-6436` explains why this is wrong for `stop`.
  - Fix: drop a pid once it has been waited on, or signal only `jobs -p`.

- **[dim 16] `ci.sh:7498`**
  - Quote: `parity_name=''`
  - The name is cleared before `rc` is checked. On `timeout 900` (rc 124), `cleanup` can no longer remove the container, and the comment at `:4909-4910` says it outlives the client. So it keeps using four cores after the gate has failed.
  - `timeout` has no `-k`. If `podman run` forwards the TERM to a PID 1 that ignores it, `timeout` may not end the wait at all. That part is unmeasured.
  - Fix: clear the name only when `rc=0`, and add `-k`.

- **[dim 3] `ci.sh:6628`**, also `:6677` and `:6692`
  - Quote: `rm -rf "$(sed -n 's/.*display log is kept in //p' "$tmp/flat.err")"`
  - `rm -rf` runs on a path parsed from stderr of the code under test, with no check on where it points. A message that names the state directory would delete other sessions' run files.
  - The Python copy has the check: `assert kept.name.startswith("shot-")` at `:5955`, so the two copies have diverged.
  - Fix: require a `shot-*` name directly under `$statedir` before removing.

- **[dim 16] `ci.sh:4905`**
  - Quote: `| grep -q "demoreel-$(id -u)/gate"; then`
  - The sweep matches any Xvfb of this user under a name starting with `gate`. That includes another session's `-n gateway` and a second `./ci.sh`.
  - The comment at `:4899-4902` claims it reaches "only" the gate's own runs. This range holds no lock, and the fixed names (`gate`, `gatestop`, and so on) also make two gates refuse each other.
  - Fix: put the gate's pid in its run names and match on that.

- **[dim 2] `ci.sh:7401`**
  - Quote: `r = run(good, NOTHING, {**pseudo, "TEXTDOMAINDIR": str(cwd / "po")},`
  - `SECURITY.md` says catalogs are read "never from … a path named by the environment". This line tests `TEXTDOMAINDIR`, which is not the route the code exposes. The real route is `LANGUAGE`, which reaches `folder / f"{code}.po"`, and only `CODE_RE.fullmatch` (`demoreel:396`) stops `LANGUAGE=../../x`.
  - No hostile row or `chosen_languages` row uses a path, so removing that check should leave this range green.
  - Fix: add a `LANGUAGE=../cwd/po/zz` hostile case.

- **[dim 3] `ci.sh:5181`**
  - Quote: `./demoreel shot -o "$tmp/sound.png" -s 320x240 -a "wait 7" \`
  - A run without `--audio` carries on when no private output can be made (comment at `:5006-5009`). So on any desktop where `pactl info` answers but loading the sink fails, this shot plays the three tones on the real speakers. The comment at `:5145` also says `aplay`'s tone goes to the speakers if `PIPEWIRE_NODE` is lost.
  - `watch-sinks.py` catches it only after the sound has played.
  - Fix: make `tones.sh` exit unless the run's private-output variables are set.

## Low / Info

**Low**
- **[dim 16] `ci.sh:5240-5243`**, `leak_run=$!` then `wait_recording`: this `-d 0` run is never added to `gate_pids`, though the loop at `:5224-5227` does add its runs.
  - `:5183`, `:5753`, `:6439` and `:5842-5860` are also unlisted.
  - `run.kill()` at `:5922` on the `shot` hang-up leaves an Xvfb the sweep cannot match, because its folder is `shot-*`.
  - `kill "$xv"` at `:4906` stays pending on a process stopped by `:5761`.
  - `:6447-6449` leaves `gatestale.json` behind in the real state directory.
- **[dim 16] `ci.sh:4439`** (`perf_t=$(mktemp -d)`) and **`:4583`** (`ex_tmp=$(mktemp -d)`): both come before the `trap` at `:4914`, so a failing step leaks the folder (CWE-459). Fix: make one scratch folder and install the trap early.
- **[dim 3] [tool: shellcheck] `ci.sh:5408`**, `-- xterm -e sh -c "read line; printf '%s' \"\$line\" > $tmp/typed.txt;`: `$tmp`, which follows `TMPDIR`, is pasted unquoted into shell source.
  - Same pattern at `:5409`, `:5430`, `:5447` and `:5641`, in the f-strings at `:6015` and `:6079`, and with the `ffmpeg` path at `:5819`, `:6127` and `:6183`.
  - A space causes a false failure and a metacharacter runs as code (CWE-78), though only from the developer's own environment.
  - `:6470` passes it as `"$1"`, which is the fix.
- **[dim 7] [tool: bandit] `ci.sh:5161`**, `assert len(audio) == 1, f"{len(audio)} audio streams"`: with `PYTHONOPTIMIZE` set, the asserts at `:5161-5174`, `:5661-5666`, `:6614-6615`, `:6643-6648` and the `rmtree` guard at `:5955` vanish, and the steps pass unchecked. Fix: use `sys.exit`, or clear the variable at the top.
- **[dim 7] `ci.sh:4623`**, `argv = shlex.split(example)[1:]`: this sits outside the `try`, breaching `python.md`'s `shlex` trap. The failure is a traceback rather than a named example, and it leaks `ex_tmp`.
- **[dim 7] `ci.sh:4528-4532`**, `help=$(./demoreel record --help; ./demoreel shot --help; ...`: `inherit_errexit` is off, so only the last command's status counts. A page that crashes drops its flags from the flag and man checks, and those steps still pass. `mutant` has the same shape at `:6804`, but it fails closed.
- **[dim 7] `ci.sh:7437`**, `found=$(git grep -nE -- "$key_header" || true)`: this hides a `git grep` error (128) as "no key found".
- **[dim 16] `ci.sh:6602` and `:6651`**, `before=$(find "$statedir" -maxdepth 1 -name "shot-*" | wc -l)`: another session's shot changes the count and causes a false failure.
- **[dim 16] `ci.sh:7493`**, `git ls-files -coz --exclude-standard | tar --null -T - -cf - \`: a tracked file deleted from the worktree makes `tar` exit 2, reported as "the gate failed on" Ubuntu even when that run passed.
- **[dim 2] `ci.sh:7510`**, `gate_end 'all checks passed'`: this prints even after the sound, `--gpu` and Flatpak steps skipped, though `:5036` says "A skip is not a pass" and `:7459` and `:7473` do name their skips.

**`SECURITY.md` "the gate covers" claims**

| Claim | Exercised here? | Gap |
|---|---|---|
| Display | Partly (Xvfb cookie) | See the third High |
| State directory | Partly (a link only) | See the second High |
| `-o` / `--app-log` refusal | Partly (`:6578-6594`) | `shot` only, not `record` or the finishing commands. No step here tests "follows a link the caller made". `is_symlink` tests the last path component only, so a planted parent link is not tested; that defence belongs to another lane |
| `--steps` canary | Yes (`:5444-5469`) | Reads `demoreel`'s command line only, as the claim says. "In no command line at all" (`xdotool`'s) is not read |
| Catalogs | Yes, for each listed class (`:7353-7403`) | One text-direction character only (U+202E) and a single `TEXTDOMAINDIR` route (see `:7401` above) |

**Dimensions**
- Not weighted: dims 4 and 11 nothing beyond the above; dim 5 no separate findings; dim 8 only the two-gates case above; dim 9 no persistence logic beyond the state and temp-file findings above; dims 10, 12, 15 and 17 N/A or nothing found.
- Dim 13 N/A: `:25` forces `LC_ALL=C`.
- Dim 2b: no zombie entry point found in this range.
- `python.md`: only the `shlex` trap fired.

**Info (coverage of my search)**
- The items your tail names as unreachable (`--gpu` and Flatpak on GitHub, a second user, `protected_symlinks` off) were judged by reading only.
- The Flatpak step's interaction with a real GIMP install was not run.

## Covered by spec and looks correct

- The whole-file grep finds no `eval` in `ci.sh`.
- Every heredoc holding Python in this range is quoted, and values reach it through `argv`.
- All scratch comes from `mktemp -d`. I found no predictable temp path of the gate's own.
- `:6438` `chmod`s through a possible link, but the smoke run at `:4950` has already passed `state_dir()` by then.
- `:7503` requires the completion marker from the Ubuntu leg.
- The catalog steps use copies under `$tmp`, never the real `po/`.

## Open questions

- Does `podman run` under `timeout`, without `-k`, ever return when PID 1 is bash? Needs measuring.
- A sink left at `:5240` sits on the user's real sound server if a failure stops the sweep. Can it become the default output? Not checked.
- "The gate covers this": does "gate" mean any run, or a run on a machine with `--gpu`? That reading decides whether the third High is mainly a doc defect.

## 3 items to fix first

1. **The root case at `:6581`.** It is the only finding that can destroy a system file on a contributor's machine, and refusing root takes one line.
2. **The unconditional SIGKILL at `:4893`.** It fires on every gate exit, and it can hit an unrelated process with no failure needed.
3. **The false "the gate covers this" on the state directory and display.** People deciding whether to use the tool on a shared machine rely on those sentences, and the branches that matter most can break with the gate still green.
