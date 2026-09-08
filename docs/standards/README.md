# Standards for demoreel

**The standards are global and are read in place**, at `~/.claude/standards/`.
There is one copy of each on this machine, shared by every project. Nothing
copies them here.

`~/.claude/standards/README.md` is the index, and it owns the three cases: a
project follows the global set, overrides one with a deltas-only file, or owns a
standard outright.

## This directory

demoreel follows the global set. What it declares here is listed below; nothing
else in this directory is a standard.

- [versioning-overrides.md](versioning-overrides.md) — deltas from
  `~/.claude/standards/versioning.md`. That standard refuses to name a project's
  breaking surfaces or its road to 1.0, because both differ per project; this
  file supplies them. It also declares one departure: it narrows the rule that a
  breaking-surface list does not bound the promise, so that an encoder tweak no
  flag exposes cannot owe a MINOR.

**A copy of a global standard does not belong here.** Two copies are two
standards that will disagree, and the one nobody is looking at is the one being
followed.

Two documents that look like standards are deliberately elsewhere.
[README.md](../../README.md) is this project's design contract — there is no
spec and none is wanted — and `CLAUDE.md` carries the rules a session works
under. Neither is a standard, and neither belongs in this directory.
