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

**The `PATH` demoreel inherits.** The fixed helpers — `Xvfb`, `ffmpeg`,
`xdotool`, `xauth`, and on `--gpu` `cage`, `Xwayland`, `wlr-randr` and
`wf-recorder` — are started by name, so the caller's `PATH`
decides which binaries run. This is deliberate. It is not a privilege boundary:
demoreel runs as the caller with no elevation, so anyone who can alter that
`PATH` can already run code as them, and resolving the names to absolute paths
would read the same `PATH` to do it. What it does mean is that demoreel inherits
its `PATH` rather than choosing one — it is meant to be started by other tools —
and a helper substituted under it would see the private display. Start demoreel
from an environment you trust as much as the one you would run `ffmpeg` in
directly. Decided under DEMO-0039; the reasoning is also recorded for the audit
tools, which flag these call sites on every run.

**The virtual X display.** The whole point of the tool is that what the app
draws is private to the run. Both backends now put the display behind an
`MIT-MAGIC-COOKIE-1` cookie in an `Xauthority` file at mode 0600, handed to
every client through `XAUTHORITY`. Both X servers are also started with
`-nolisten tcp`: checked with `ss -ltn` before and during a `--gpu` run, no X
server opened a TCP listener on any display port. On `--gpu` the compositor has
a Wayland socket of its own, which the recorder reads the picture through; it
lives in `XDG_RUNTIME_DIR` (mode 0700), so only the caller's own processes can
reach it. A local process without the cookie is
refused, which was measured before and after: it
used to read the geometry and grab a frame of whatever was on screen. Socket
permissions would not have fixed it — `Xvfb` also listens on an abstract socket,
which has none. The gate covers this.

**The run-state directory.** `state_dir()` uses `XDG_RUNTIME_DIR` when it is
set, and `/tmp/demoreel-<uid>` when it is not. The fallback name is predictable,
so on a shared machine another user can create that path first. demoreel checks
before using it: `lstat` rather than `stat`, so a planted symlink is seen rather
than followed, and the run stops unless the path is a directory the caller owns.
A desktop session sets `XDG_RUNTIME_DIR`, so the fallback is the unusual path —
which is why the hole would have gone unnoticed. The gate covers this.

**The paths demoreel writes: `-o` and `--app-log`.** Another local user can
create a symlink at a name the caller will write to, most easily in `/tmp`.
demoreel resolves these paths itself, so the kernel's `fs.protected_symlinks`
never sees the link. Measured before the fix: a link at the `-o` path had its
target overwritten, and the run exited 0. So demoreel refuses a path that is a
symlink owned by another user, and follows a link the caller made. A link
planted after that check is opened by the writer itself, and there the kernel's
protection applies where it is on. It is on on this machine
(`fs.protected_symlinks = 1`). The gate covers the refusal (DEMO-0082).

**Text a scripted step types.** demoreel hands it to `xdotool` on stdin, so it
is never in `xdotool`'s command line. Given with `-a`, it is in **demoreel's
own**, and a command line is readable by other local users through the process
list for the whole recording, not just the typing. `--steps` reads the steps
from a file or from stdin instead, so they are in no command line at all. The
gate checks this: a canary typed through `--steps -` reaches the app and is
absent from demoreel's command line (DEMO-0025). Use `--steps` for a password
or a token, from a file only you can read; a shell line that pipes the steps
in holds them itself.

**Translation catalogs.** A message demoreel shows may come from a `.po` file
in the `po/` folder beside the script, written by a translator a reviewer may
not be able to read. So a catalog is treated as untrusted text, and the
defences are in [the translation spec](docs/specs/DEMO-0060-translation-catalogs.md)
§ 4.7. demoreel reads catalogs only from that folder, never from the working
directory or a path named by the environment. A message is filled by plain
substitution, which cannot reach an attribute or an index, and a translation
whose placeholders differ from the English is not used. A catalog holding a
control character, a text-direction character, a charset other than UTF-8,
syntax outside the subset demoreel reads, or more than 1 MiB is refused whole.
A refused catalog costs its language and one English note, never the run, and
under `LC_ALL=C` no catalog is opened at all. The gate covers each of these
with hostile catalogs (DEMO-0083).

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
