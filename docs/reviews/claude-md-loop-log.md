# CLAUDE.md — review-contract loop log

`CLAUDE.md` is loaded into every session in this project, so its review history
is kept here rather than appended to it. The document carries a one-line
pointer to this file and nothing else.

Each row is one `review-contract` loop. Rows are appended, never edited.

| # | Date | Genre | Lanes | Q1 | Q2 | Q3 | Verified | Fixed | Outcome |
|---|------|-------|-------|----|----|----|----------|-------|---------|
| 1 | 2026-09-07 | standard (pinned) | 3 | 4 | 1 | 0 | 5 | 5 | Wrong pipeline order, Flatpak flag count, unconditional blank-check claim, the cwd non-negotiable the tool breaches by design, and a threshold copy that does not exist. All fixed. Three open questions, one of which became finding 4; the other two resolved clean. |
| 2 | 2026-09-07 | standard (pinned) | 3 | 2 | 0 | 1 | 3 | 3 | Loop 1's own threshold fix over-claimed: "the only other copy" is false, and two lanes said so. The concurrency non-negotiable rested entirely on display-number allocation and never mentioned that every state file is keyed off `--name`. Verifying that turned up a third: `--name` defaults to `default`, and two unnamed runs share one state file. One lane returned no findings. One of three findings landed on text loop 1 wrote. Four open questions, none became a finding. |
| 3 | 2026-09-07 | standard (pinned) | 3 | 1 | 0 | 0 | 1 | 1 | All three lanes found the same single defect, and it was loop 2's own fix: the concurrency bullet stated the race case as though it were the only case. Re-measured both ways and the bullet now carries both. **Cap reached, and VIOLENT by § At the cap's measure — the final loop's one finding landed entirely on text this run wrote.** The violence is concentrated in one bullet rather than spread: each loop's wording was closer to the truth, and loop 3's is the first resting on a measurement of both cases rather than one. Of the run's nine verified findings, one fell inside the change that armed the gate; the other eight were pre-existing, so this run was mostly an audit. Size is not the signal — the document is far short of the range where a split is indicated. Review of the document as it stands ends here. |
| 4 | 2026-09-26 | standard (pinned) | 3 | 2 | 0 | 4 | 6 | 6 | Armed by DEMO-0111 (f5812f0 on branch demo-0111): the `--gpu` section rewritten for capture from the compositor, ahead of the build. Loop 1 of this run. Every lane held every question. **All three lanes found the `--cursor` refusal unscoped between `record` and `shot`**, and **all three found the dependency line did not say `--gpu` still needs `xauth`**, now that demoreel writes the cookie itself; the line now lists tools per backend. **Two lanes found the `Xwayland` command line missing `-noreset`**, which the prototype passed and which keeps the parked pointer parked (DEMO-0103); now named, with its reason. Orchestrator-found from open questions: the stutter note's message blames the defect this backend removes, so the section now says its explanation must change; "is scaled into the output" was false for a resized output (the measurement shows the top-left, unscaled), deleted; "no recorded frame" narrowed to a sampled frame. Code-side, filed as DEMO-0113: `start_xvfb` proves its lock with a client holding the cookie, which on `Xwayland` connects before the lock too. Resolved clean: no muxer-flag option in `wf-recorder` 0.6. Left to the build: how the `-displayfd` descriptor reaches `Xwayland` through `cage`. Packet defect, disclosed by two lanes: the genre overlay's last line was cut when the brief was assembled; the lanes applied the test as stated above it. **All three lanes disclosed they were not cold**: the harness injected main's pre-change copy of this file. |

## Standing limitation on every row above

The lanes are not fully cold and cannot be. Claude Code injects this project's
`CLAUDE.md` into every session as project instructions, so each lane already
held the unscrubbed subject before it opened its brief. Two of the three lanes
in loop 1 disclosed this unprompted. The scrub protects the loop log and the
citation line numbers; it does not buy a reader who has never seen the
document. Read a clean loop here as weaker evidence than a clean loop on a
document the harness does not inject.
