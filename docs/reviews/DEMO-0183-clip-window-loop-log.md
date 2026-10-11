# DEMO-0183 — loop log

The review history of
[`docs/specs/DEMO-0183-clip-window.md`](../specs/DEMO-0183-clip-window.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-11 | 2 (`review-lane` via `neutral-lane`; every lane held every question) | 1 | 2 | 1 | 2 | 6 verified, 6 fixed, 1 dismissed. Q1 found while building the packet and fixed before dispatch: § 10 credited DEMO-0060 INV-15 with checking translation, which it does not. Q4, both lanes: INV-4's probe passed with the shadow undropped or unblurred — two probes added, all three cases run on a prototype. Q4: INV-1's 0.02 tolerance could not see a stretch or a frame-sized window — tolerance 0.01, the stretch case left to INV-2. Q2: § 6 tested the room where the window is what can reach 0 px. Q2: § 9 ruled out two windows, which a crossfade shows — bullet deleted. Q3, from an open question: a push-in growing the window left the shadow's size unstated — layer 2 follows layer 3. Dismissed: what ends the mask stream (nothing built differs). Open questions resolved clean: `make_film` shows ffmpeg's last lines; gblur's sigma does not matter for a one-frame blur. |
