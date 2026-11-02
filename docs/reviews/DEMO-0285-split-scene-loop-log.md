# DEMO-0285-split-scene — review loop log

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-11-02 | 2 | 5 | 2 | 0 | 8 | 15 findings, 14 verified / 1 dismissed (INV-8's `ulimit` figure, which the builder measures). All 14 fixed; 3 of them from building the packet, 3 from running lanes' NEEDS MEASUREMENT commands. Every lane held every question. Fixes include the graph's `settb`, `shortest=1` and `tpad`, each measured on ffmpeg 6.1.1 and 9.0.2. Loop 2 dispatched. |
| 2 | 2026-11-02 | 2 | 0 | 0 | 2 | 0 | 2 findings, both verified and fixed: the slice label needed its scene number, and a border is turned off by slice and not by position (two lanes, one finding). The fixes are read by no lane; implementation is their reader. **Capped** at the two-loop limit: a calm cap, 0 of 2 on text this run wrote. Second share not reported: the armed change is the whole document. Status set to accepted. |
