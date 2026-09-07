# CLAUDE.md — review-contract loop log

`CLAUDE.md` is loaded into every session in this project, so its review history
is kept here rather than appended to it. The document carries a one-line
pointer to this file and nothing else.

Each row is one `review-contract` loop. Rows are appended, never edited.

| # | Date | Genre | Lanes | Q1 | Q2 | Q3 | Verified | Fixed | Outcome |
|---|------|-------|-------|----|----|----|----------|-------|---------|
| 1 | 2026-09-07 | standard (pinned) | 3 | 4 | 1 | 0 | 5 | 5 | Wrong pipeline order, Flatpak flag count, unconditional blank-check claim, the cwd non-negotiable the tool breaches by design, and a threshold copy that does not exist. All fixed. Three open questions, one of which became finding 4; the other two resolved clean. |
| 2 | 2026-09-07 | standard (pinned) | 3 | 2 | 0 | 1 | 3 | 3 | Loop 1's own threshold fix over-claimed: "the only other copy" is false, and two lanes said so. The concurrency non-negotiable rested entirely on display-number allocation and never mentioned that every state file is keyed off `--name`. Verifying that turned up a third: `--name` defaults to `default`, and two unnamed runs share one state file. One lane returned no findings. One of three findings landed on text loop 1 wrote. Four open questions, none became a finding. |

## Standing limitation on every row above

The lanes are not fully cold and cannot be. Claude Code injects this project's
`CLAUDE.md` into every session as project instructions, so each lane already
held the unscrubbed subject before it opened its brief. Two of the three lanes
in loop 1 disclosed this unprompted. The scrub protects the loop log and the
citation line numbers; it does not buy a reader who has never seen the
document. Read a clean loop here as weaker evidence than a clean loop on a
document the harness does not inject.
