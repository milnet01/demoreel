# Versioning overrides — demoreel

Deltas from `~/.claude/standards/versioning.md`. That standard supplies the
rules; it deliberately refuses to supply the two answers below, because they
differ per project. Everything else it settles applies unchanged, with one
declared delta: § What is not a breaking surface narrows that standard's rule
that such a list does not bound the promise. Without it any encoder tweak could
owe a MINOR.

## Breaking surfaces

demoreel is a command-line tool. Nothing imports it, so "the public API" has no
referent here. These are the surfaces a user or a calling script can depend on,
and changing one is a breaking change:

- **The command line.** The subcommands `record` and `stop`, their flags, and
  the top-level flags. Removing one, renaming one, changing what an existing
  flag means, or changing the default an omitted flag supplies.
- **The stdout contract.** From `record` and `stop`, stdout carries one line:
  the finished video path, and nothing else. A caller writing
  `out=$(demoreel record ...)` depends on this. `--version` and `--help` print
  to stdout too, and both flags existing is protected. `--version` prints the
  name, a space, then the version — a caller takes the second field, so
  changing that shape breaks them. `--help`'s prose is not protected: rewording
  it stops nothing working, which is the governing standard's test
  (`versioning.md` § 2).
- **The default output name.** Without `-o`, the file is `<app>-<timestamp>.mp4`
  in the current directory. A script that globs for it depends on the shape.
- **Exit behaviour on a blank recording, and the exit status generally.** While
  the app is still running, the display is sampled halfway through the `-d`
  countdown and again at the end. A blank sample at either point exits
  non-zero and prints no path on stdout, and so does a sample that could not be
  taken. The video already written is left on disk. Both samples are skipped
  when the app exited first, and those recordings succeed today. A `-d 0` run
  has no halfway point, but is still sampled at the end. Tightening any of that — sampling at a third point,
  deleting the leftover file, failing a run that currently passes — is
  breaking, not a tidy-up.
- **The scripted action grammar** passed to `-a` — the verbs and their argument
  order.

A surface nobody wrote down is still a surface, except for what the next
section names. The list above makes the common cases cheap.

## What is not a breaking surface

Excluded deliberately. Reliance on these is not protected, and that is what
makes them the exception to the line above:

- The encoding parameters no flag exposes — preset, CRF, pixel format — beyond
  the video remaining playable H.264. The container of a `-o` run follows the
  caller's own name, so it is theirs rather than ours to promise; the default
  name's `.mp4` is part of the shape protected above. A flag's default,
  `-s` and `-r` included, is covered above, not here.
- Everything on stderr, progress and failure text alike. None of that text is
  protected. The surfaces listed above are untouched by this bullet.

## Reaching 1.0

**MAJOR stays 0 until a video demoreel recorded has been used outside this
repository** — published in another project's README, a store listing, or a
release page. Checkable by someone else: the roadmap names where, with a link.
Nothing has yet.

**The previous condition is met, and what it required still governs the gate.**
It held MAJOR at 0 until the gate exercised both display backends and the
Flatpak invocation; DEMO-0006 and DEMO-0007 finished that on 2026-09-20. The
rest of this section is what those steps have to keep doing, not a condition
still being waited on.

**A path is exercised when a step records on it, looks at the picture, and
fails on a flat frame.** Running the tool and getting a file back is not
exercising it: a black video is a valid file that exits 0.

**The step does not have to run on every machine.** It meets this condition
when it runs wherever its own prerequisites are met and prints why it skipped
where they are not. The prerequisites are each step's, and `ci.sh` states them:
the `--gpu` step needs `xwfb-run`, `cage`, `vkcube` and a render node under
`/dev/dri`; the Flatpak step needs `flatpak`, the application installed, and no
copy of it already running, because a launch then hands over to that copy and
leaves the private display empty. An ordinary GitHub runner meets neither set.
Holding 1.0 on cover that runs everywhere would hold it on a runner nobody is
buying.

**A skip for one of those reasons does not withdraw the condition. A skip is
still not a pass**, and it is not permission to change that path without
recording on it.

As of 2026-09-20 every path named above has a step: `Xvfb` in the smoke
recording, `--gpu` from DEMO-0006, the Flatpak invocation from DEMO-0007. All
three run on a machine with a card and with Flathub applications installed.
The last two skip on GitHub, so the checks GitHub runs still record on `Xvfb`
alone.

## While the leading zero is there

Per the standard's zero-dot-x rule, the levels shift down one inside `0.x`, and
this is the part most likely to be misread:

| Change | Bump |
|---|---|
| Breaking change to any protected surface — the list is not exhaustive, but § What is not a breaking surface bounds it | MINOR, and the PATCH resets — `0.1.4` → `0.2.0` |
| Everything else, a new capability included | PATCH — `0.1.0` → `0.1.1` |

So a new flag that breaks nothing is a PATCH, not a MINOR. The MINOR is spent
only on a break, which is what keeps the number meaningful before `1.0`.

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-09-07 | 3, cold — genre pinned `standard`; first gate on this document | 1 | 2 | 3 | n/a | **Six verified, six fixed; one collateral fix in README.md.** **All three lanes independently found the same defect, and it is the run's most consequential**: the blank-recording bullet claimed a run that drew nothing "fails rather than returning a file". Both halves are false. The `.mp4` is left on disk — no code path unlinks it — and the check is conditional on the app still running, so a run whose app exits early skips it and succeeds. Confirmed by running both: a blank run exits 1 and leaves the file, and an app that exits mid-run returns 0. One lane carried the materiality: a conformer implementing the already-filed early-sampling item would read the bullet as "that was always the promise" and ship it as a PATCH, when it would fail runs that pass today. **Two Q2s were the promise contradicting its own bounds** — "a surface nobody wrote down is still a surface" sat above a section whose whole job is to bound the promise, and the bump table restricted MINOR to surfaces "listed above", so a conformer breaking an unlisted surface fell through to the PATCH row. Precedence is now stated in one direction only. **Three Q3s were things a conformer could not settle**: the table omitted that a MINOR bump resets the PATCH and chose an example starting from a `.0` patch, so someone at `0.1.4` would publish `0.2.4`; neither list classified a change to a flag's *default*, while `-s` and `-r` are pulled both ways by the encoding-parameters exclusion; and the 1.0 condition named three items in bold and then a wider clause covering "every documented way of reaching the tool", which the gate does not cover — two extents, so two people cut different releases. The wider clause was deleted rather than reconciled. **The collateral is the reason 4b exists**: README.md restated the bump rule and dropped the PATCH reset in the same way, so the copy was deleted and replaced with a pointer. **One lane disagreed with the others on the bump table**, judging it to agree with the governing standard; it tested for contradiction where the others tested whether a conformer could act, and the finding was kept on the second reading. Two open questions resolved clean and are not counted: whether `--gpu`'s backend selection collides with the internal-choice exclusion (the rewrite settles it), and whether an exit-status contract exists (`die()` exits 1; now stated). |
| 2 | 2026-09-07 | 3, cold — identical brief, packet rebuilt from disk | 0 | 2 | 2 | n/a | **Four verified, four fixed. VIOLENT by § At the cap's measure — three of the four landed on text loop 1 wrote**, and all three were found by all three lanes independently. Loop 1's two fixes collided with each other: it added "changing the default an omitted flag supplies" to the breaking list and "which backend the tool picks when no flag names one" to the exclusions, and `--gpu` is `store_true`, so the backend used when it is omitted **is** that default — one act, named breaking and not-breaking. The backend bullet is deleted rather than reconciled; the flag-default rule already covers it. Loop 1 also wrote "only the next section bounds the promise", reversing `versioning.md` § 3's "not to bound the promise" while this document's own preamble claimed the standard "applies unchanged" — an undeclared delta, and § 3 specifically characterises this file as not containing one. The delta is now declared in the preamble, which `standards/README.md` § The three cases permits. Third, loop 1's "the exit behaviour above governs them" pointed at a bullet that governs exit status and stdout and says nothing about message text, so the pointer resolved to no answer; stderr is now excluded outright. **The fourth was mine, caught by executing a claim rather than reading it.** Acting on a lane's open question, the fix asserted that `stop` prints one line per stopped run. Running the refuting case disproved it: two concurrent runs with no `-n` both write the state file for the name `default`, the second overwrites the first, and `stop` printed one line. `cmd_stop` can only ever print one. **That test also found a real defect in the tool** — the first run was orphaned, still recording, with `demoreel stop` answering "no recording is running" — filed as its own item, not fixed here. |
| 3 | 2026-09-07 | 3, cold — identical brief, packet rebuilt from disk | 1 | 2 | 0 | n/a | **Three verified, three fixed. Cap reached (3 for a standard); the run files its tail and exits. VIOLENT — all three landed on text this run wrote**, the third consecutive loop where that is the largest class. **All three lanes independently found the same defect**: loop 2's "Only the exit status and whether a path reaches stdout are protected" was written inside the stderr bullet but read as an allowlist over the whole document, stranding the leftover video file, the default output name, the flags and the `-a` grammar — each protected by name a few lines above. One lane found it also narrowed the stdout promise itself from *one line, nothing else* to *a path reaches stdout at all*, so adding a second stdout line would satisfy the exclusion while breaking the contract. The sentence is now bounded to stderr. **The Q1 was a false absolute that had survived every loop**: "stdout carries the finished video path and nothing else" — `--version` sits on the root parser and argparse writes it to stdout, measured at 399 bytes to stdout and none to stderr for `--help`. Now scoped to `record` and `stop`, with the two named. **The remaining Q2 was loop 2's own widening**: making "the default an omitted flag supplies" breaking collided with excluding "the video's internal encoding parameters", because `-s` and `-r` are both at once — so changing the default framerate was MINOR under one bullet and PATCH under the other. The exclusion now covers only parameters no flag exposes. **Both cap measurements: every verified finding across all three loops falls inside the span that armed the gate**, this document having been created by it, so the run was gate rather than audit throughout. **Routing at the cap:** the document is short, so size is not the signal — the oscillation was fixes over-reaching, three loops running, each new absolute (*only*, *nothing else*, *all applies unchanged*) failing on a case the previous loop had not considered. Not re-run as it stands. |
| 4 | 2026-09-20 | 3, cold — genre pinned `standard`; armed by the § Reaching 1.0 rewrite in 12de9ab | 2 | 1 | 1 | n/a | **Four verified, four fixed, none dismissed; two collateral fixes outside the document.** **Two lanes independently found the exit-behaviour bullet stale**: it described a sample at the end of the run and named "sampling earlier" as a tightening still to come, when the halfway sample shipped in 0.2.0 (DEMO-0008) and the could-not-sample third answer with it (DEMO-0033) — confirmed by reading `demoreel`, where `blank = "halfway"` breaks out of the wait loop before the end sample. A conformer removing that sample would have read this bullet and published a break as a PATCH. **Two lanes also found the new skip account false**: it said `--gpu` needs a graphics card and the Flatpak step needs the application installed, where `ci.sh` requires `xwfb-run`, `cage`, `vkcube` and a render node for the first, and the second skips on a machine where the application IS present but already running. The rule and the verdict below it then disagreed, so an auditor seeing that skip could not tell whether the condition still held; the prerequisites are now named per step and the already-running skip is sanctioned. **The Q3 was the consequence of the rewrite itself**: the exit condition became satisfied and nothing said which number the next release takes, which `versioning.md` § 4 requires a `0.x` project to answer in one line. It now says the condition is met, that spending it is a release decision, and that the `0.x` ladder applies until 1.0 is deliberately cut. **The Q2 was an undeclared delta this document's own preamble denies**: "nothing here exempts their wording" made rewording `--help` a break, against `versioning.md` § 2's stopped-working test, so one conformer cut a PATCH for a typo fix and another a MINOR. Now scoped to `--version` printing a parsable version and both flags existing. **Two of the four landed inside the gated span and two were pre-existing**, so the run was half gate and half audit. Collateral, fixed at home rather than carried here: `README.md` still said no step runs `--gpu` and the Flatpak step uses a stand-in, and `CLAUDE.md` still said the gate covers `Xvfb` alone — both falsified by DEMO-0006 and DEMO-0007 earlier the same day, and both found by two lanes. **All three lanes disclosed that they were not cold**, the harness injecting this project's `CLAUDE.md`, which one lane cited as the source of a finding. |
| 5 | 2026-09-20 | 3, cold — identical brief, packet rebuilt from disk | 2 | 2 | 0 | n/a | **Four verified, four fixed, none dismissed. Two of the four landed on text loop 4 wrote**, which for a section rewritten wholesale that loop is the expected shape. **All three lanes found the same defect, and it is the run's most consequential**: loop 4 satisfied this document's own exit condition and then said spending it was a release decision, so the same change publishes `1.0.0` to one reader and `0.3.0` to another — and `versioning.md` § 4 requires a `0.x` project to carry a live exit condition checkable by someone else, which a spent one is not. Put to the user with both options; they chose a successor condition over cutting 1.0. The met condition is now recorded as history, and what it required still governs the gate steps. **Two lanes found loop 4's `-d 0` clause false, and the two disagreed about it** — one asserting the end sample is taken on a `-d 0` run, the other that the bullet matched the code. Reading `demoreel` settled it: the end sample is guarded by `blank is None and unsampled is None and app.poll() is None`, with no deadline in the condition, so only the halfway sample is absent and a stopped `-d 0` run with a blank display does fail. A conformer would have priced removing that guard as a tidy-up. **Two lanes found the bump table restating the unbounded rule without the exclusions** the preamble declares as this document's one delta, so a preset or CRF change reads as MINOR from the table and PATCH from the section above it; both lanes called it their weakest and both were right that it names a real level difference. **The fourth came from an open question rather than a finding**: a lane asked whether the file is really MP4, and the code says the muxer follows the caller's `-o` name — so the promise of "an MP4 container" was ours to make about somebody else's filename. Now scoped to the video staying playable H.264. **All three lanes disclosed that they were not cold**, and two named the injected project `CLAUDE.md` as the source of a finding. |
| 6 | 2026-09-20 | 3, cold — identical brief, packet rebuilt from disk | 0 | 2 | 0 | n/a | **Two verified, two fixed, one dismissed. Cap reached (3 for a standard); the run files its tail and exits. VIOLENT by § At the cap's measure — both findings landed on text this run wrote**, and one lane returned nothing at all. Loop 5's own container fix over-reached: "the container follows the caller's `-o` name" is true of a `-o` run and false of an `-o`-less one, where the tool picks `.mp4` and § Breaking surfaces protects that shape — so changing the default container read as MINOR from one section and PATCH from another. Now scoped to the `-o` case. Loop 4's `--version` fix over-reached the same way: "a parsable version, not the prose" splits one line that is both, so a conformer reformatting it could not tell whether they had breached. Now the shape is pinned — name, space, version, and the caller takes the second field. **Dismissed, true but immaterial**: "Nothing imports it, so the public API has no referent" is literally false, because `ci.sh` loads demoreel as a module for `BLANK_THRESHOLD` and `frame_is_flat`; that importer is in-repo and moves in lockstep, so no conformer publishes a different number and two lanes independently declined to file it. **Surfaced code-side rather than fixed here**: `demoreel stop` prints the video path immediately after signalling, so a `-d 0` run that then fails its end-of-run blank check has already handed a path to its caller — filed as DEMO-0047. **The oscillation is this document's known shape, not its size** — it is short, and the previous run's own cap read the same way: each loop's fix states a new absolute that fails on a case the last loop did not consider. So the review of this document as it stands ends here rather than earning a fourth loop. **All three lanes disclosed they were not cold**, and one named the commit subjects in its git snapshot as telling it how many loops had already run. |
