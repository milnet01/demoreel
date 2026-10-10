# DEMO-0106 — loop log

The review history of
[`docs/specs/DEMO-0106-app-sound.md`](../specs/DEMO-0106-app-sound.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-10 | 2 review-lane via neutral-lane, every lane held every question | 1 | 3 | 2 | 3 | Verified 9, fixed 9, dismissed 0. Q1: wf-recorder's optional device must be attached (`--audio=`). Q2: the module index in a state file contradicted § 4.2's name sweep and `shot`'s no-state-file design (both lanes); INV-5 unscoped against § 10's "Xvfb only"; the Goal's "one frame" against INV-5's 40 ms (both lanes). Q3: `pactl` kept out of `required_programs`; its package recommended, never required (orchestrator, from an open question). Q4: INV-3's failing run could not fail; `shot` untested in INV-2 and INV-4; INV-6 compared durations, which passed a 0.5 s overrun (orchestrator, from a NEEDS MEASUREMENT run; fixed with `-shortest`, measured). Two open questions left to the builder (no PULSE_SINK without a sink; pid reuse in the sweep). |
