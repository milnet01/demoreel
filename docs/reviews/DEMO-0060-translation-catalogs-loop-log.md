# DEMO-0060 — loop log

The review history of
[`docs/specs/DEMO-0060-translation-catalogs.md`](../specs/DEMO-0060-translation-catalogs.md).

## Cold-eyes loop log

| Loop | Date | Lanes | Q1 | Q2 | Q3 | Q4 | Outcome |
|------|------|-------|----|----|----|----|---------|
| 1 | 2026-10-01 | 2 (neutral-lane; every lane held every question) | 2 | 5 | 2 | 6 | 15 verified, 15 fixed, 0 dismissed. Both lanes independently found the central defect: ci.sh's planned LC_ALL=C export makes every translation test pass vacuously, since LC_ALL=C wins under 4.4; fixed by having translation runs remove it (7). Both also found --help is stdout yet translated, against 1 and INV-2. Orchestrator measurements turned five open questions into findings: Python expands sr_RS@latin as sr_RS@latin, sr@latin, sr_RS, sr (INV-3 row was wrong); GNUTranslations returns '' for an empty msgstr rather than falling back; a Plural-Forms of n%0 raises ZeroDivisionError at call time; INV-12's test needed a message no failing record run prints; --version's help is argparse's own string. One open question resolved clean (argparse msgids differ between 3.12 and 3.13; the spec already takes only those in both). Lanes disclosed arriving with the global CLAUDE.md, the principles draft and the superpowers preamble; no project CLAUDE.md, memory index or git snapshot. |
