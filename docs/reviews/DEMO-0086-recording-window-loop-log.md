# DEMO-0086 — loop log

The review history of
[`docs/specs/DEMO-0086-recording-window.md`](../specs/DEMO-0086-recording-window.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-11-15 | 2 (neutral-lane; every lane held every question) | 4 | 1 | 2 | 2 | 9 verified, 9 fixed, 1 dismissed. Q1: `cmd_record`, not `main`, installs `_request_stop`; `main` also sets SIGHUP, so `cmd_window` resets it too; `progress` runs five times a second and never shows 0, so `time` events are sent on change and `left` ends at 1; `QProcess` loses a non-UTF-8 argument (measured), so the window refuses one. Q2: § 7 skipped steps that need no PySide6. Q3: a failed event write after the parent dies must not end the run (Python raised `BrokenPipeError`, measured), and INV-10's parent now reads the pipe; INV-8's table takes the raw `Exec` value. Q4: INV-4 compared timestamped paths and timing-dependent `time` events; INV-12 required ⟦⟧ on untranslated values. Dismissed: where the `error` event is written is local, under INV-2 and INV-3. Collateral: DEMO-0060 INV-2's scope line names `time` events. Before dispatch: the PySide6 version corrected to 6.12, outside the tally. Unrunnable region: the window on Windows. |
