# DEMO-0153 — loop log

The review history of
[`docs/specs/DEMO-0153-moving-text.md`](../specs/DEMO-0153-moving-text.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-11 | 2 (`review-lane` via `neutral-lane`; every lane held every question) | 0 | 2 | 1 | 2 | 5 verified, 5 fixed, 3 dismissed. Q4, both lanes: INV-8 matched text by `light:40`, which the green `sq.png` also matches, so it could never pass — now `#FFFFFF:40`. Q2, both lanes: § 4.1 said the fade eased and also that it was `p` — it is linear, as Slipcase and INV-5 have it. Q3, both lanes: a stacked line's height, banded or not, was undefined while `picture_room`, the refusal and DEMO-0183 bind to it — defined, bands touch. Q4, from an open question: INV-6's tall stack had no words, so a width refusal could pass it — `"A"` to `"D"`. Q2, from an open question: INV-3 said every text step is unchanged while INV-4 changes two. Dismissed: how `px find` is called (it is `px find`); stacks at two places overlapping each other (nothing else binds to it); INV-1's centring tolerance with a descender (unmeasured, settled in the build). Measured for a lane: on 6.1.1 a fading band rises with its text (rows 223, 205, 200). |
