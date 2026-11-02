# DEMO-0286-trailer-effects — review loop log

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-11-02 | 2 | 4 | 1 | 0 | 3 | 8 findings, 7 verified / 1 dismissed (INV-11's `ulimit` figure, which the builder measures). All 7 fixed; 3 of them from building the packet. Every lane held every question. Fixes: `noise` needs no seed, a gradient does; the ring's line widths match `ring_png` at its largest; a `tpad` keeps a ringed clip's last frame on ffmpeg 6.1.1; a ring a `hold` would freeze is refused. Loop 2 dispatched. |
