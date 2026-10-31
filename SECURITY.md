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
set, then `/run/user/<uid>` if the caller owns it, and `/tmp/demoreel-<uid>`
otherwise. That last name is predictable,
so on a shared machine another user can create that path first. demoreel checks
before using it: `lstat` rather than `stat`, so a planted symlink is seen rather
than followed, and the run stops unless the path is a directory the caller owns.
A desktop session sets `XDG_RUNTIME_DIR`, so the fallback is the unusual path —
which is why the hole would have gone unnoticed. A run's `--name` becomes file
names there, so it takes plain letters, digits, dots, underscores and hyphens,
and cannot start with a dot or a hyphen: it cannot leave that directory, and two
names cannot share a file. The gate covers this.

**The paths demoreel writes: `-o` and `--app-log`.** Another local user can
create a symlink at a name the caller will write to, most easily in `/tmp`.
demoreel resolves these paths itself, so the kernel's `fs.protected_symlinks`
never sees the link. Measured before the fix: a link at the `-o` path had its
target overwritten, and the run exited 0 (DEMO-0082). So demoreel follows each
link on the path itself and checks who made it:

- At the name given, it follows only a link the caller made.
- On the way up and along a chain of links, it also follows root's, because
  `/var/run -> /run` is root's. Anyone else's link stops the run.
- A regular file or a pipe another user owns stops the run, since they could read
  what is written there. A device does not, so `--app-log /dev/null` works.
- `-o` takes an ordinary file or nothing, and a path holding a control character
  is refused: a line break would break the one line on stdout.

A video or a picture is written to a part file beside `-o`, named
`.demoreel-part-<random>` and created with `O_EXCL`, so nobody can plant it first
and two runs cannot share one. It is renamed to `-o` when whole, and a rename
replaces a link there rather than following it. A name demoreel made up is
claimed with `O_EXCL` at that moment, and takes a number if it has gone.

Three things are left:

- Between the walk and the write, a link swapped into a folder on the path is
  followed. Only someone who can write to that folder can do it. In a sticky
  folder such as `/tmp` that needs a folder of theirs on the path, and the walk
  does not refuse one.
- In a folder another user can write to and which is not sticky, they can also
  replace a part file with a link while `ffmpeg` writes it. Do not write there.
- A file another user plants at `--app-log` after the walk is written to, unless
  the kernel's `fs.protected_regular` refuses it, which covers sticky folders. A
  link planted there is refused by `O_NOFOLLOW`.

The gate has one account, so it covers each rule with a stand-in for who owns a
file, and with real root-owned files. No second user has been run against it.

**Text a scripted step types.** demoreel hands it to `xdotool` on stdin, so it
is never in `xdotool`'s command line. Given with `-a`, it is in **demoreel's
own**, and a command line is readable by other local users through the process
list for the whole recording, not just the typing. `--steps` reads the steps
from a file or from stdin instead, so they are in no command line at all. The
gate checks this: a canary typed through `--steps -` reaches the app and is
absent from demoreel's command line (DEMO-0025). Use `--steps` for a password
or a token, from a file only you can read; a shell line that pipes the steps
in holds them itself. Only `type` text stays off a command line: `key` and
`hold` steps are on `xdotool`'s, even under `--steps`.

**Translation catalogs.** A message demoreel shows may come from a `.po` file
in the `po/` folder beside the script, written by a translator a reviewer may
not be able to read. So a catalog is treated as untrusted text, and the
defences are in [the translation spec](docs/specs/DEMO-0060-translation-catalogs.md)
§ 4.7. demoreel reads catalogs only from that folder, never from the working
directory or a path named by the environment. A message is filled by plain
substitution, which cannot reach an attribute or an index, and a translation
whose placeholders differ from the English is not used. A catalog holding a
control character, a text-direction character, a charset other than UTF-8,
syntax outside the subset demoreel reads, or more than 1 MiB is refused whole,
and so is anything but a regular file, a link included.
A refused catalog costs its language and one English note, never the run, and
under `LC_ALL=C` no catalog is opened at all. The gate covers each of these
with hostile catalogs (DEMO-0083).

**Files, names and scripts from someone else.** A finishing command may be given
a media file, a font, a script or a file name it did not make, so:

- A name, a script line or a program's words reach the terminal as text: each
  value in a message is escaped, a line break too, and no line of them can pass
  for one of demoreel's own. Only stdout's path is left as it is.
- A file is read from its absolute path, so its name is never a protocol or an
  option, and only as a file. A format that opens other files on a file's say, a
  playlist or a concat list, is refused.
- A measurement is never read from text a file can write: a tag or a name cannot
  set a music's level or `motion`'s report.
- Reading a file is held to half this machine's memory, and a program's output to
  its last part. A film is held to a longest length, a highest rate and a little
  free disk.

The gate covers each of these with crafted files and names (DEMO-0094). A script
can still name any file the caller can read and put it in the film, so read a
script from someone else before publishing what it makes.

**The video and the logs demoreel writes.** Whatever the app draws is in the
video, and `--app-log` keeps whatever the app printed. Both are ordinary files
with the caller's umask, and a part file has that mode from the start. A video
or a picture that replaces a file keeps that file's mode. Check what is in them
before publishing one; demoreel cannot tell a secret on screen from any other
pixels.

## Checking a download

From 0.9.0 on, a release can be checked three ways. The commands below use
0.9.0; put the version you downloaded in its place.

**The tag is signed.** Release tags are signed with an SSH key used for
nothing else. Its public half is
[`packaging/release-signers`](packaging/release-signers), and the same key
is listed as a signing key on the GitHub account, at
<https://api.github.com/users/milnet01/ssh_signing_keys>. In a clone of this
repository:

```sh
git fetch --tags
git -c gpg.ssh.allowedSignersFile=packaging/release-signers tag -v v0.9.0
```

It prints `Good "git" signature` and exits 0.

**The files are the ones listed.** Each release carries `SHA256SUMS`, which
names every other file with its SHA-256 hash. In the folder holding your
downloads:

```sh
sha256sum -c --ignore-missing SHA256SUMS
```

Each file you downloaded is reported `OK`.

**GitHub built them from that tag.** Every file, `SHA256SUMS` included, has a
build record made by the release workflow. With the GitHub CLI:

```sh
gh attestation verify demoreel_0.9.0-1_all.deb --repo milnet01/demoreel \
    --source-ref refs/tags/v0.9.0 \
    --signer-workflow milnet01/demoreel/.github/workflows/release.yml
```

A package installed from the openSUSE Build Service repositories is checked
by your package manager against that repository's own key. These steps are
for files downloaded from GitHub.

**The limit.** The tag check reads `packaging/release-signers` from the
repository it checks, so someone who could push to the repository could
change that file too. The key's listing on the GitHub account is a second
source. Compare the two for a check that does not rest on the repository
alone.

## Supported versions

Before 1.0, only the latest release. There are no maintenance branches.

## Reporting a vulnerability

Report privately through GitHub's advisory form for this repository:
<https://github.com/milnet01/demoreel/security/advisories/new>. A public issue
is the wrong channel for anything not already listed above.

The items tracked in [ROADMAP.md](ROADMAP.md) are already known and do not need
reporting. They are recorded here so that anyone deciding whether to use this
tool on a shared machine can see them before they do.
