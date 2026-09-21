# CLAUDE.md — why the rules say what they say

`CLAUDE.md` states what is true of this project now, and what a breach looks
like. This file holds what was moved out of it: dated decisions, the wording a
rule replaced, and the argument that settled a rule. Nothing is built from this
file and nobody conforms to it. It exists so a rule can be questioned without
re-deriving the case for it.

Traps are not here. A trap is what is true now, and it stays in `CLAUDE.md`.

Review history is separate again, and stays where it is:
`docs/reviews/claude-md-loop-log.md` for this file's subject,
`docs/reviews/readme-loop-log.md` for the README.

## The line count is not a finding

Stated by the user on 2026-08-07: the number of lines is irrelevant as long as
the tool does what it is supposed to do.

The rule exists because of the wording it replaced. `CLAUDE.md` used to
describe the tool as "a few hundred lines, finished", which invited every
session to flag the file's size as if it were a defect. It is not one.

## Audio

Put to the user on 2026-08-07 and declined. It stays out of scope.

The consequence is stated in `README.md` rather than left implied: the file
demoreel produces is silent, and a trailer with sound needs a second step
elsewhere. The design that would have fitted — a per-run null sink, a second
`ffmpeg`, one mux — is recorded there too, so it does not have to be
re-derived in order to be re-declined.

## There is no third display backend

`--gpu` was added on 2026-08-07, the same day the ceiling was settled. It
replaced a "no Wayland compositor backend" line that had been written without
being tested against a GPU app. Tested, it lost: `Xvfb` has no DRI, so a Vulkan
app records black on it and no flag changes that.

Two backends is the answer to that test, not a loosening of the ceiling.

## The process-name check that was true by construction

`pgrep -x demoreel` matches nothing, because the process is named for its
interpreter. This cost most of DEMO-0029: every "no recorder left behind"
reading in that work came from that check, each one true by construction, while
a real leak went on being reported as clean.

## stdout was wrong from the start

The stdout contract — the finished path and nothing else — was broken from the
first version and fixed on 2026-08-07. It was never a regression; no session
introduced it.

## Xvfb ran without an auth cookie

Until 2026-09-08 the `Xvfb` backend installed no cookie, so any client on the
machine could read the display. Xwayland always demanded one, which is why the
`--gpu` path was never exposed this way.
