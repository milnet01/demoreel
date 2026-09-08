# Security policy — demoreel

demoreel is a local command-line tool. It runs as the user who invokes it, gains
no privilege, and opens no network listener. It does have trust boundaries, and
they are listed below rather than dismissed: it starts an X display other local
processes can reach, writes state under a path other local users can predict,
and passes text on a command line.

`~/.claude/standards/security.md` owns what a trust boundary is and what
defending one requires. This file is what an outside reader needs.

## Trust boundaries

**The command the caller passes.** demoreel executes it with the caller's own
privileges and does not sandbox it. This is not a privilege boundary — the
caller could run the same command directly — but it does mean demoreel is not a
containment mechanism, and should not be used as one.

**The virtual X display.** The whole point of the tool is that what the app
draws is private to the run. Under the default `Xvfb` backend the display is
started with `-nolisten tcp` and **no auth cookie**, so it is closed to the
network but not to other processes on the same machine. The `--gpu` backend
does better: it writes an `Xauthority` file at mode 0600 and hands it to every
client through `XAUTHORITY`. The two backends therefore do not offer the same
protection, and the weaker one is the default. Tracked as DEMO-0017.

**The run-state directory.** `state_dir()` uses `XDG_RUNTIME_DIR` when it is
set, and `/tmp/demoreel-<uid>` when it is not. The fallback name is predictable,
so on a shared machine another user can create that path first. demoreel checks
before using it: `lstat` rather than `stat`, so a planted symlink is seen rather
than followed, and the run stops unless the path is a directory the caller owns.
A desktop session sets `XDG_RUNTIME_DIR`, so the fallback is the unusual path —
which is why the hole would have gone unnoticed. The gate covers this.

**Text given to `-a type`.** demoreel hands it to `xdotool` on stdin, so it is
not in `xdotool`'s command line. It is still in **demoreel's own**, because the
caller wrote it there, and a command line is readable by other local users
through the process list for as long as the process runs — the whole recording,
not just the typing. Measured both ways. So scripting a demo that types a
password or a token is still the case to avoid on a shared machine. Tracked as
DEMO-0025.

**The video and the logs demoreel writes.** Whatever the app draws is in the
video, and `--app-log` keeps whatever the app printed. Both are ordinary files
with the caller's umask. Check what is in them before publishing one; demoreel
cannot tell a secret on screen from any other pixels.

## Supported versions

Before 1.0, only the latest release. There are no maintenance branches.

## Reporting a vulnerability

Report privately through GitHub's advisory form for this repository:
<https://github.com/milnet01/demoreel/security/advisories/new>. A public issue
is the wrong channel for anything not already listed above.

The items tracked in [ROADMAP.md](ROADMAP.md) are already known and do not need
reporting. They are recorded here so that anyone deciding whether to use this
tool on a shared machine can see them before they do.
