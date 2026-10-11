# DEMO-0177 — loop log

The review history of
[`docs/specs/DEMO-0177-film-music.md`](../specs/DEMO-0177-film-music.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-11 | 2 review-lane via neutral-lane, every lane held every question | 3 | 0 | 4 | 2 | Verified 9, fixed 9, dismissed 0. Q1: § 4.3 said `afade` has no `enable` (orchestrator, phase 1b; both ffmpeg versions print timeline support), fixed before dispatch; a clip's sound was said to cover the picture's span, but `scene.read` stops half a frame early and limits the sound too; INV-1 said the finishing fixtures are silent, but `A.mp4` has sound and `assert_finished` asserts none (orchestrator, from both lanes' open question). Q3: where a `level` line may stand (both lanes); the sound's length against the picture's whole frames; `aloop`'s `size` rate; `trim --music` alone hits `cmd_trim`'s refusal (orchestrator, from an open question). Q4: INV-11 had no test for the `--music-*` option error; INV-2's isolation sentence named the wrong scene and leaned on a join `concat` pads (orchestrator, measured). Open questions resolved clean: INV-13's 2 GB limit (card films of 3 and 60 s finish under it), the AAC peak after the -1 dB cap (-0.6 dB measured). |
