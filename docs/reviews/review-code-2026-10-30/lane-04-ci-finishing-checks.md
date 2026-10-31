**Line counts:** `ci.sh`, the brief's part only: lines 1457–4413 (2,957 lines), all read with `Read`.

**In my context on arrival:** the global `~/.claude/CLAUDE.md`, the `review-lane` instructions, the session-start note about Ants verbs, and the user's email address. There was no project `CLAUDE.md` and no git snapshot.

**Other reads:**
- Slices of `demoreel`, because stdin handling and `-threads` were in question.
- `ci.sh` lines 1442–1454, 4414–4426, 4880–4916 and 6760–6775.
- `CLAUDE.md` § State and `CONTRIBUTING.md`.
- `python.md` § Scope and § Traps.

I hold no `Bash`, so **nothing here was run**. Runtime behaviour below comes from reading the code and from bash and ffmpeg semantics.

**No disagreement** between the brief and the lane file needed resolving.

## Critical (0)

## High (1)

- [dim 2] `ci.sh:2101` — `run edit e4.txt -o "$ft/out/keep.mp4"` — This is a check that does not test what it says, on every run.
  - **Cause:** `e4.txt` is written only at `ci.sh:2075`, inside `fin_s4`, into that check's private copy. `fin_one` (`ci.sh:1680`) gives each check a fresh copy of the base inputs, so the file does not exist when `fin_s5` runs.
  - **Effect:** the step "edit with a bad line, -o an existing file" is refused because of the missing script, not the bad line. `expect_refused` accepts any non-zero exit with stderr, so it passes. README's "a file already there is left as it was" is therefore never exercised for a failing `edit`.
  - **Same cause:** `ci.sh:2051`, `run edit f5.txt -o "$ft/out/wrong.mov"`. `f5.txt` is written only at `ci.sh:2005` in `fin_s2`. Whether `.mov` is refused before the script is opened I did not settle. If it is, this one still checks its claim.
  - **Coverage:** a search of all of `ci.sh` for these two names returned 5 rows, not truncated, and shows no other writer. I walked the other checks by reading and found no further cross-check file.
  - **Fix:** write each script inside the check that uses it, and have `fin_s5` grep the refusal for line 1.

## Medium (4)

- [dim 16] `ci.sh:1738` — `raw = run(["ffmpeg", "-v", "error", "-i", f, "-vf",` — `px.py`'s ffmpeg has no `-nostdin` and inherits stdin.
  - **Where it bites:** `ci.sh:3458` runs `n_of` inside `while IFS= read -r fam ... done <<<"$fams"`, so ffmpeg reads bytes of the remaining family list. I expect at least one byte per run, based on how ffmpeg's key check reads a non-terminal stdin. I did not measure it.
  - **Effect:** the next family name loses its first letter and is refused, and `|| continue` drops it. A `q` byte stops ffmpeg outright. On a machine with few fonts this changes which families are compared, or trips the "two families" failure at `ci.sh:3464`.
  - **Second place:** `ci.sh:1895`, `ff() { ffmpeg -v error -y "$@"; }`, runs in the main shell while the inputs are made, with the developer's terminal as stdin. A keypress can shorten an input, and only A, C and spin.png have their frame counts asserted.
  - **Fix:** add `-nostdin` to `px.py` and `ff`, as `a_level` and `md5` already have.
  - **Checked, no problem:** the `while ... <<'CASES'` loops only call `demoreel` on paths I read. Those use `-nostdin`, DEVNULL, ffprobe, or ffmpeg's `-h`/`-encoders`/`-devices` modes, so they do not lose cases.

- [dim 16] `ci.sh:1694` — `( renice -n 10 "$BASHPID" >/dev/null 2>&1 || true; fin_one "$i" ) \` — Workers are left running if the gate is stopped by a signal sent to the parent alone (CWE-459).
  - **Cause:** the `--finishing` trap at `ci.sh:4420` is only `trap 'rm -rf "$tmp"' EXIT`. The full gate's `cleanup` (`ci.sh:4882`) kills `$gate_pids`, and the finishing workers are not in that list.
  - **Effect:** on SIGTERM, up to `FIN_JOBS` workers and their ffmpeg children keep running while `rm -rf` races them, which can leave `$tmp` behind.
  - **Also outside `$tmp`:** `run` does not set `XDG_RUNTIME_DIR`, so `demoreel` makes `edit-*` work folders in the user's real state directory (`demoreel:4541`). `cleanup` does not sweep them, so a run that is SIGKILLed leaves them there. How `demoreel` tears down on SIGTERM I did not read.
  - **Fix:** record the worker PIDs and kill them in both traps, and point `XDG_RUNTIME_DIR` at a folder under `$ft` in `run`.

- [dim 7] `ci.sh:1507` — `awk -v e="$2" -v a="$3" -v t="$4" \` — `assert_near` and `assert_between` read an empty or non-numeric value as 0. Under `set -e`, a failing command substitution used as an argument does not stop the check.
  - **One way it passes:** `ci.sh:1573` compares against 0, so a `start_time` of `N/A` passes "the sound starts at 0".
  - **Another way:** `ci.sh:3751`, `assert_near "fade-in 0: full at the start" "$middle" "$(a_mean "$ft/out/mr2.mp4" 0 0.1)" 1`, passes when both sides come back empty. `a_level` prints nothing when `volumedetect` reports no line, and that exits 0.
  - **Same family, for `assert_eq`:** `ci.sh:3010` and `ci.sh:3026–3027`.
  - **Fix:** refuse a non-numeric value in these helpers, and in `assert_eq` where both sides are empty.

- [dim 16] `ci.sh:3952` — `( ulimit -v 5500000; cd "$ft" && "$DR" edit pc1.txt -o "$ft/out/pc1.mp4" ) \` — A contributor's machine can fail this for reasons unrelated to their change.
  - **Evidence for the limit:** the comment at `ci.sh:3944` says it was "measured 2026-10-30, twelve cores".
  - **Why cores matter:** `-threads 4` covers the encoder only (`demoreel:1186`), and it is the only `-threads` my search of `demoreel` found. I expect decoder and filter threads, and their stacks and arenas, to grow with core count. I did not measure this. `ci.sh:4046` and `ci.sh:4217` have the same shape.
  - **Related:** `ci.sh:3910`, `"import mmap, time; m = mmap.mmap(-1, 8 * 2**30); m[0] = 1; time.sleep(1.5)"]`. I expect the kernel's default overcommit check to refuse 8 GiB on a machine whose RAM plus swap is below that.
  - **Failure direction:** all of these fail closed, so a false failure rather than a false pass.
  - **Fix:** scale the limits with `nproc` or pin the threads, and size the reservation from the machine.

## Low / Info

- [dim 7] [tool: bandit] `ci.sh:3899` — `assert d.memory_cap() == os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") // 2` — This check (`ci.sh:3899–3914`) and `ci.sh:2498` rely only on `assert`. With `PYTHONOPTIMIZE` set in the contributor's environment they all vanish and the block still prints its success line. `ci.sh` never clears the variable (search not truncated). Fix: use explicit `sys.exit`, or clear the variable.
- [dim 16] `ci.sh:1697` — `wait || true` — Nothing limits how long a check can take. `px.py`'s `subprocess.run` (`ci.sh:1726`) has no timeout, while other gate steps use `timeout 60`. A hung ffmpeg hangs the gate. Fix: wrap each check in `timeout`.
- [dim 16] `ci.sh:1883` — `fh.seek(n - 16, 1)` — A malformed box with a 64-bit size of 0 seeks back to its own start. `atoms` then loops forever and `names` grows without limit. It only reads `demoreel`'s own output, so this is hard to reach. Fix: refuse any size below the header's.
- [dim 16] `ci.sh:1693` — `while [ "$(jobs -rp | wc -l)" -ge "$jobs" ]; do wait -n || true; done` — `FIN_JOBS=0` spins forever. A non-numeric `FIN_JOBS` makes `[` error, so the loop never throttles and every check starts at once. Fix: validate it as a positive integer.
- [dim 2] `ci.sh:1671` — `# checks (DEMO-0042, DEMO-0120): nothing in these times anything, so a busy` — The comment is wrong. `ci.sh:3906` has `assert took < 5, f"stopped after {took:.1f} s"`, which can fail on a loaded machine, and `ci.sh:3928` also depends on run length. Fix: widen the bound, and correct the comment.
- [dim 2] `ci.sh:1463` — `# after a control: the same command made valid succeeded first, so "refused"` — `fin_s56`, `fin_s60` and `fin_s64` have no control. Either the comment overclaims or those checks need a control. I cannot tell which is intended.
- [dim 7] `ci.sh:3492` — `echo "note: neither $fam1 nor $fam2 has a bold face here, so \":bold\" was not exercised"` — This check, and `ci.sh:3502`, pass with part of their claim unrun and say so only as a note. See open question 2.
- INFO — My coverage:
  - All of the assigned range was read.
  - The search for `fail`, `run` and similar calls found none after `ci.sh:4413`, so the helpers `finishing_checks` leaves defined globally change nothing later.
  - No finding came from a second local user or from `fs.protected_symlinks`, because every path here is under a `mktemp -d` folder. `--gpu` and Flatpak do not appear in this function.
- Other dimensions:
  - **3:** nothing found beyond the Medium and Low items.
  - **4, 5, 9, 11:** nothing found.
  - **8:** one finding outside the weighting is already filed under dim 16 (the workers), and no separate one.
  - **10, 12, 13, 15, 17:** N/A, as this is gate code with no such surface or contract named.

## Covered by spec and looks correct

I opened and confirmed the following:
- **Temporary files:** `tmp` comes from `mktemp -d`. `ft`, `fin-steps` and each check's copy sit under it, so no path is predictable (CWE-377).
- **Eval and heredocs:** there is no `eval` in the range. Every Python heredoc is quoted (`<<'FINPY'` and the others), so nothing expands into it.
- **Awk text:** `assert_cmp` builds awk program text only from this script's own measurements and literals. An empty value is a syntax error, which fails.
- **Failure propagation:**
  - A missing or non-zero `.rc` counts as a failure (`ci.sh:1706`).
  - `printf ... | ed_ok` keeps failing through `pipefail` and `errexit`.
  - `finishing_checks` is called unconditionally at both sites, so `set -e` holds inside its checks.
- **Other points:**
  - `LC_ALL=C` at `ci.sh:25` settles `EPOCHREALTIME`'s decimal point.
  - `ci.sh:4015`'s search of `out/` is valid, because pieces are written beside the output (`demoreel:4635`).
  - The `__pycache__` that `SourceFileLoader` writes in the clone is ignored by `.gitignore`.

Against `python.md`, the traps I read do not fire on this code.

## Open questions

1. `ci.sh:1460` says "it takes seconds". I could not check that without running it, and the number of ffmpeg-heavy checks makes me doubt it. I would compare it with a gate log's "took" line.
2. Does `./ci.sh --summary` list the `note:` lines at `ci.sh:3492` and `ci.sh:3502` as skips? I did not read its matcher. If it does not, § State's "the steps that skipped" under-reports them.
3. `fin_s3`'s `f5.txt` case depends on whether `demoreel edit` checks the `-o` ending before opening the script. I did not read that order.
4. How `demoreel` handles SIGTERM decides how much the orphaned-worker finding leaves behind. That code is outside this lane.

## 3 items to fix first

1. **`ci.sh:2101` and `ci.sh:2051`.** These are checks that report a pass on every run for the wrong reason, on README's promise not to harm an existing file.
2. **`ci.sh:1507`.** Numeric helpers that read nothing as 0 can hide any later regression. It is a one-place fix that covers many checks.
3. **`ci.sh:1694`.** Stray ffmpeg processes and leftover folders are the one thing here that touches the machine beyond the run.
