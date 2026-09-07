# Versioning overrides — demoreel

Deltas from `~/.claude/standards/versioning.md`. That standard supplies the
rules; it deliberately refuses to supply the two answers below, because they
differ per project. Everything it does settle still applies unchanged.

## Breaking surfaces

demoreel is a command-line tool. Nothing imports it, so "the public API" has no
referent here. These are the surfaces a user or a calling script can depend on,
and changing one is a breaking change:

- **The subcommands** `record` and `stop`, and their flags. Removing a flag,
  renaming one, or changing what an existing flag means.
- **The stdout contract.** stdout carries the finished video path and nothing
  else. A caller writing `out=$(demoreel record ...)` depends on this.
- **The default output name.** Without `-o`, the file is `<app>-<timestamp>.mp4`
  in the current directory. A script that globs for it depends on the shape.
- **Exit behaviour on a blank recording.** A recording in which nothing was
  drawn fails rather than returning a file. Downgrading that to a warning would
  silently change what callers receive.
- **The scripted action grammar** passed to `-a` — the verbs and their argument
  order.

A surface nobody wrote down is still a surface. This list makes the common cases
cheap; it does not bound the promise.

## What is not a breaking surface

- The video's internal encoding parameters, beyond the file remaining playable
  H.264 in an MP4 container.
- Progress and diagnostic text on stderr.
- Which display backend is chosen internally, given the same flags.

## Reaching 1.0

**MAJOR stays 0 until the CI gate exercises both display backends and the
Flatpak invocation**, so that every documented way of reaching the tool is
covered by a check someone else can run.

Today the gate records on the `Xvfb` backend only. `--gpu` needs a runner with a
usable graphics card, and the Flatpak path needs a published application to
point at; neither is solved, and until both are, a release cannot claim the
documented paths are tested.

## While the leading zero is there

Per the standard's zero-dot-x rule, the levels shift down one inside `0.x`, and
this is the part most likely to be misread:

| Change | Bump |
|---|---|
| Breaking change to a surface listed above | MINOR — `0.1.0` → `0.2.0` |
| Everything else, a new capability included | PATCH — `0.1.0` → `0.1.1` |

So a new flag that breaks nothing is a PATCH, not a MINOR. The MINOR is spent
only on a break, which is what keeps the number meaningful before `1.0`.
