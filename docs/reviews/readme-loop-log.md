# README.md — review-contract loop log

`README.md` is this project's design contract, so it is gated like one. Its
review history is kept here rather than appended to it: a review table is not
what a README's readers came for, and appending one changes what the document
is.

Each row is one `review-contract` loop. Rows are appended, never edited.

| # | Date | Genre | Lanes | Q1 | Q2 | Q3 | Verified | Fixed | Outcome |
|---|------|-------|-------|----|----|----|----------|-------|---------|
| 1 | 2026-09-08 | adr (pinned) | 3 | 2 | 1 | 0 | 3 | 3 | First gate on this document, armed by the rewrite for a lay reader. **All three lanes independently found the window-selection defect**, and it is the run's most consequential: the document said demoreel "locates the window by its name" and never stated that the biggest window wins, so an implementer building from the contract would pick by search order and get a startup dialog about half the time — the exact defect the code's docstring says it avoids, and the `--window-name` filter the scope ceiling rules out. **All three also found the concurrency claim**, which this rewrite had itself over-broadened: the previous text carried the qualification and the rewrite dropped it, so the document claimed a second unnamed run always refuses, when two started together both record and only the later is reachable by `stop` (DEMO-0011). **The Q2 was against the versioning standard**: step 6 stated the blank check unconditionally while the code skips it once the app has exited, and that exception is a protected surface — a conformer would have made it unconditional believing it a bug fix, and broken runs that pass today. One dismissed as immaterial: the no-window message reports a timeout rather than a nameless window, and nothing is built differently. Three open questions resolved clean and are not counted. One out-of-scope finding, fixed at its home: a `ci.sh` comment left stale by DEMO-0021 still said the workflow matches against the glob itself. **All three lanes disclosed that they were not cold** — the harness injects this project's `CLAUDE.md`, which restates parts of this document. |
