# DEMO-0068 — loop log

The review history of
[`docs/specs/DEMO-0068-linux-packages.md`](../specs/DEMO-0068-linux-packages.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-08 | 2 (neutral-lane; every lane held every question) | 1 | 2 | 1 | 1 | 5 verified, 5 fixed, 0 dismissed. One Q2 was found by the orchestrator while building the packet and fixed before dispatch: the full gate and the GitHub `packages` job would both have run the package step. Its fix was worded so that both lanes found the second Q2: a skip "where the parity leg is not applicable" could be put inside `--packages` itself, so both GitHub jobs would build nothing and the release job would pass. Now only the full gate skips; a direct call always runs and fails when it cannot. Both lanes found the Q4: INV-7's lockstep compared versions that, by design, no file holds; it now fails on a version literal under `packaging/`. Both found the Q1, that fonts were missing from the required set. Measured in containers: Arch and openSUSE had no font and `check` said text NOT READY. `ttf-font`, `font(dejavusans)` with `fontconfig`, and `fontconfig` plus `fonts-dejavu-core` are added. One lane found the Q3: a GitHub trigger is per workflow file, so the release job moves to `release.yml`. Five open questions resolved clean, by measurement in containers: `check` exits 0 headless on Debian, Ubuntu and Arch; openSUSE's OSS ffmpeg 9 has no libx264; Debian stable packages all four `--gpu` programs; `makepkg --verifysource` accepts a local tarball beside the PKGBUILD when the URL is unreachable; and the zypper row now carries the flags measured for an unsigned local rpm. Lanes disclosed arriving with the global CLAUDE.md and hook texts, with no project CLAUDE.md, memory index or git snapshot. |
