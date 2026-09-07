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
- **The stdout contract.** stdout carries the finished video path and nothing
  else — one line, from `record` and from `stop` alike. A caller writing
  `out=$(demoreel record ...)` depends on this.
- **The default output name.** Without `-o`, the file is `<app>-<timestamp>.mp4`
  in the current directory. A script that globs for it depends on the shape.
- **Exit behaviour on a blank recording, and the exit status generally.** When
  the app is still running at the end and the display is blank, the run exits
  non-zero and prints no path on stdout. The video it already wrote is left on
  disk. The check is skipped when the app exited before the end of the run, so
  those recordings succeed today. Tightening any of that — sampling earlier,
  deleting the leftover file, failing a run that currently passes — is
  breaking, not a tidy-up.
- **The scripted action grammar** passed to `-a` — the verbs and their argument
  order.

A surface nobody wrote down is still a surface, except for what the next
section names. The list above makes the common cases cheap.

## What is not a breaking surface

Excluded deliberately. Reliance on these is not protected, and that is what
makes them the exception to the line above:

- The video's internal encoding parameters, beyond the file remaining playable
  H.264 in an MP4 container.
- Everything on stderr, progress and failure text alike. Only the exit status
  and whether a path reaches stdout are protected.

## Reaching 1.0

**MAJOR stays 0 until the CI gate exercises both display backends and the
Flatpak invocation.** Those two, checkable by anyone reading `ci.sh`.

Today the gate records on the `Xvfb` backend only. `--gpu` needs a runner with a
usable graphics card, and the Flatpak path needs a published application to
point at. Until both are solved, nothing shows that a change to either path
still works.

## While the leading zero is there

Per the standard's zero-dot-x rule, the levels shift down one inside `0.x`, and
this is the part most likely to be misread:

| Change | Bump |
|---|---|
| Breaking change to any protected surface — the list is not exhaustive | MINOR, and the PATCH resets — `0.1.4` → `0.2.0` |
| Everything else, a new capability included | PATCH — `0.1.0` → `0.1.1` |

So a new flag that breaks nothing is a PATCH, not a MINOR. The MINOR is spent
only on a break, which is what keeps the number meaningful before `1.0`.

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-09-07 | 3, cold — genre pinned `standard`; first gate on this document | 1 | 2 | 3 | n/a | **Six verified, six fixed; one collateral fix in README.md.** **All three lanes independently found the same defect, and it is the run's most consequential**: the blank-recording bullet claimed a run that drew nothing "fails rather than returning a file". Both halves are false. The `.mp4` is left on disk — no code path unlinks it — and the check is conditional on the app still running, so a run whose app exits early skips it and succeeds. Confirmed by running both: a blank run exits 1 and leaves the file, and an app that exits mid-run returns 0. One lane carried the materiality: a conformer implementing the already-filed early-sampling item would read the bullet as "that was always the promise" and ship it as a PATCH, when it would fail runs that pass today. **Two Q2s were the promise contradicting its own bounds** — "a surface nobody wrote down is still a surface" sat above a section whose whole job is to bound the promise, and the bump table restricted MINOR to surfaces "listed above", so a conformer breaking an unlisted surface fell through to the PATCH row. Precedence is now stated in one direction only. **Three Q3s were things a conformer could not settle**: the table omitted that a MINOR bump resets the PATCH and chose an example starting from a `.0` patch, so someone at `0.1.4` would publish `0.2.4`; neither list classified a change to a flag's *default*, while `-s` and `-r` are pulled both ways by the encoding-parameters exclusion; and the 1.0 condition named three items in bold and then a wider clause covering "every documented way of reaching the tool", which the gate does not cover — two extents, so two people cut different releases. The wider clause was deleted rather than reconciled. **The collateral is the reason 4b exists**: README.md restated the bump rule and dropped the PATCH reset in the same way, so the copy was deleted and replaced with a pointer. **One lane disagreed with the others on the bump table**, judging it to agree with the governing standard; it tested for contradiction where the others tested whether a conformer could act, and the finding was kept on the second reading. Two open questions resolved clean and are not counted: whether `--gpu`'s backend selection collides with the internal-choice exclusion (the rewrite settles it), and whether an exit-status contract exists (`die()` exits 1; now stated). |
| 2 | 2026-09-07 | 3, cold — identical brief, packet rebuilt from disk | 0 | 2 | 2 | n/a | **Four verified, four fixed. VIOLENT by § At the cap's measure — three of the four landed on text loop 1 wrote**, and all three were found by all three lanes independently. Loop 1's two fixes collided with each other: it added "changing the default an omitted flag supplies" to the breaking list and "which backend the tool picks when no flag names one" to the exclusions, and `--gpu` is `store_true`, so the backend used when it is omitted **is** that default — one act, named breaking and not-breaking. The backend bullet is deleted rather than reconciled; the flag-default rule already covers it. Loop 1 also wrote "only the next section bounds the promise", reversing `versioning.md` § 3's "not to bound the promise" while this document's own preamble claimed the standard "applies unchanged" — an undeclared delta, and § 3 specifically characterises this file as not containing one. The delta is now declared in the preamble, which `standards/README.md` § The three cases permits. Third, loop 1's "the exit behaviour above governs them" pointed at a bullet that governs exit status and stdout and says nothing about message text, so the pointer resolved to no answer; stderr is now excluded outright. **The fourth was mine, caught by executing a claim rather than reading it.** Acting on a lane's open question, the fix asserted that `stop` prints one line per stopped run. Running the refuting case disproved it: two concurrent runs with no `-n` both write the state file for the name `default`, the second overwrites the first, and `stop` printed one line. `cmd_stop` can only ever print one. **That test also found a real defect in the tool** — the first run was orphaned, still recording, with `demoreel stop` answering "no recording is running" — filed as its own item, not fixed here. |
