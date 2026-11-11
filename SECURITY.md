# Security policy — demoreel

demoreel is a local command-line tool. It runs as the user who invokes it, gains
no privilege, and opens no network listener. It does have trust boundaries, and
they are listed below rather than dismissed: it starts an X display other local
processes can reach, writes state under a path other local users can predict,
passes text on a command line, and reads files someone else may have made.

Each boundary below says what demoreel does about it, what the gate checks, and
what is left.

## Trust boundaries

**The command the caller passes.** demoreel executes it with the caller's own
privileges and does not sandbox it. This is not a privilege boundary — the
caller could run the same command directly — but it does mean demoreel is not a
containment mechanism, and should not be used as one.

**Other processes of the same user.** These are not a boundary. Any of them, the
recorded app included, can read the display's auth file and rewrite a run's state
file, and what `demoreel stop` reports rests on that file. Any of them can also
list a run's private sound output and listen to it.

**The `PATH` demoreel inherits.** demoreel starts its helpers by name, so the
caller's `PATH` decides which binaries run:

- `ffmpeg`, `ffprobe`, `xdotool` and `xauth`.
- `Xvfb` by default, and on `--gpu` `cage`, `sh`, `Xwayland`, `wlr-randr` and
  `wf-recorder`.
- `pactl` for a run's private sound output.
- `fc-match` for a font asked for by name.
- `ldd` in `demoreel check`, which asks it which `libavcodec` the `wf-recorder`
  on `PATH` loads. `check` then loads that library into demoreel itself through
  `ctypes`, so `PATH` also chooses a library that runs inside demoreel.
- `python3`, which the script's first line and the shells' tab completion both
  find there.

This is deliberate. It is not a privilege boundary:
demoreel runs as the caller with no elevation, so anyone who can alter that
`PATH` can already run code as them, and resolving the names to absolute paths
would read the same `PATH` to do it. What it does mean is that demoreel inherits
its `PATH` rather than choosing one — it is meant to be started by other tools —
and a helper substituted under it would see the private display. Start demoreel
from an environment you trust as much as the one you would run `ffmpeg` in
directly. Decided under DEMO-0039; the reasoning is also recorded for the audit
tools, which flag these call sites on every run.

**Tab completion.** Pressing Tab after `demoreel stop` asks demoreel which runs
are live, in whatever folder the shell is in. That folder may be a download or
someone else's, so nothing in it is imported or run: `python3 -I` keeps it off
the import path, a command typed with a path such as `./demoreel` is not run,
and a run's name is text the shell does not expand. The gate plants a script,
modules and hostile run names, and checks each of these in bash, zsh and fish.
It reports a shell the machine lacks as skipped (DEMO-0094).

**The virtual X display.** The whole point of the tool is that what the app
draws is private to the run. Both backends put the display behind an
`MIT-MAGIC-COOKIE-1` cookie in an `Xauthority` file at mode 0600, handed to
every client through `XAUTHORITY`. The file holds a cookie before the X server
starts, so no client can connect first and stay. The cookie reaches `xauth` on
stdin, so it is on no command line. Both X servers are started with
`-nolisten tcp`. A local process without the cookie is refused, which was
measured before and after: it used to read the geometry and grab a frame of
whatever was on screen. Socket permissions would not have fixed it — `Xvfb` also
listens on an abstract socket, which has none.

The gate checks each of these on `Xvfb`, and on `--gpu` where the machine can run
it, which GitHub cannot:

- A client with no cookie is refused from the moment the app starts.
- A client holding the cookie connects, so the refusal is not a dead display.
- The auth file is at mode 0600 and holds a cookie before the server starts.
- `xauth`'s command line never holds the cookie.
- The display's TCP port has no listener.

On `--gpu` the compositor also has a Wayland socket, which the recorder reads the
picture through. It lives in `XDG_RUNTIME_DIR`, so that folder's mode decides who
can reach it. A desktop session's is 0700, which leaves the caller's own
processes. The gate does not check this socket.

**The run-state directory.** `state_dir()` uses a folder `demoreel-<uid>` in
`XDG_RUNTIME_DIR` when that is set, then in `/run/user/<uid>` if the caller owns
it, and in `/tmp` otherwise. The name in `/tmp` is predictable,
so on a shared machine another user can create that path first. demoreel checks
before using it: `lstat` rather than `stat`, so a planted symlink is seen rather
than followed, and the run stops unless the path is a directory the caller owns.
It makes that directory at mode 0700, and sets one already there to that mode.
A desktop session sets `XDG_RUNTIME_DIR`, so the fallback is the unusual path.
A run's `--name` becomes file
names there, so it takes plain letters, digits, dots, underscores and hyphens,
and cannot start with a dot or a hyphen: it cannot leave that directory, and two
names cannot share a file.

The gate checks that a link or a file at that path is refused, which folder is
chosen, and the names. It has one account, so another user's directory is a
stand-in for `lstat`.

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
from a file or from stdin instead, so they are not in demoreel's command line.
The gate checks this: a canary typed through `--steps -` reaches the app and is
absent from demoreel's command line (DEMO-0025). Use `--steps` for a password
or a token, from a file only you can read; a shell line that pipes the steps
in holds them itself. Only `type` text stays off every command line: `key` and
`hold` steps are on `xdotool`'s, even under `--steps`, so put no secret in one.

**A `--steps` file.** It is as trusted as the command. A step drives the app as
someone at its keyboard could, so read a steps file from someone else before you
run it. A `key` or `hold` step still takes key names and nothing else, because
`xdotool` reads a command's name anywhere among another command's arguments. The
gate tries a key step that would run a program, and refuses every command the
real `xdotool` lists (DEMO-0094).

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

**Files, names and scripts from someone else.** Edit scripts, media files, fonts
and file names are untrusted: a finishing command may be given one it did not
make. So:

- A name, a script line or a program's words reach the terminal as text: each
  value in a message is escaped, a line break too, and no line of them can pass
  for one of demoreel's own. Only stdout's path is left as it is.
- A media file is read from its absolute path, so its name is never a protocol or
  an option, and only as a file. A format that opens other files on a file's say, a
  playlist or a concat list, is refused.
- A measurement is never read from text a file can write: a tag or a name cannot
  set a music's level or `motion`'s report.
- Reading a file is held to half this machine's memory, and a program's output to
  its last part. A film is held to a longest length, a highest rate and a little
  free disk.

The gate covers each of these with crafted files and names, and with stand-ins
for a program that floods its output, a clip that claims a huge frame rate and a
nearly full disk (DEMO-0094).

A script holds scenes and nothing else. No line of one runs a program or says
where the film is written. Each value is checked against what its word takes, and
text reaches `ffmpeg` from a file, so no value becomes part of a filter. A font's
path holding a character `ffmpeg`'s filters read is refused, and so is text when
the state directory's path holds one. No gate step tries to
pass a filter through a script. These rest on the code, and on a probe of
2026-10-31 that put a filter in a script's text, font, colour, transition and
number values and got no file from it.

Two limits are left:

- demoreel does not sandbox `ffmpeg`. A flaw in how `ffmpeg` reads a file or a font
  runs as the caller, so keep `ffmpeg` up to date. The gate tries a font's name and
  path, and no crafted font.
- A script can name any file the caller can read and put it in the film, so read a
  script from someone else before publishing what it makes.

**The video and the logs demoreel writes.** Whatever the app draws is in the
video, and `--app-log` keeps whatever the app printed. Both are ordinary files
with the caller's umask, and a part file has that mode from the start. A video
or a picture that replaces a file of the caller's keeps that file's mode;
one replacing a file another user put there during the run keeps the umask's. A film keeps no tags or
chapters from the files it is made from, which the gate checks. Check what is in them
before publishing one; demoreel cannot tell a secret on screen from any other
pixels.

## Checking a download

From 0.9.0 on, a release can be checked three ways, and they hold together: the
signed tag names a commit, the build record names that commit and a file's hash,
and that file is the one you hold. The commands below use 1.0.0; put the version
you downloaded in its place.

**The tag is signed, with the key GitHub publishes.** Release tags are signed
with an SSH key used for nothing else. It is listed as a signing key on the
GitHub account, at <https://api.github.com/users/milnet01/ssh_signing_keys>.
In a clone of this repository, build the list of signers from that page, so
that no file in the repository takes part:

```sh
git fetch --tags
gh api users/milnet01/ssh_signing_keys \
    --jq '.[] | "milnet01@users.noreply.github.com namespaces=\"git\" " + .key' > github-signers
git -c gpg.ssh.allowedSignersFile=github-signers tag -v v1.0.0
```

It prints `Good "git" signature` and a line `tag v1.0.0`, and exits 0. Read that
line: git does not compare it with the name you asked for, so an old signed tag
put under a new name passes without it. If `git fetch` says a tag would be
clobbered, that tag has moved since you last fetched it. Stop there.

The same key is in the repository, as
[`packaging/release-signers`](packaging/release-signers). A check against that
file instead rests on the repository alone.

**GitHub built the files from that commit.** Every file, `SHA256SUMS` included,
has a build record made by the release workflow. With the GitHub CLI, in the
clone:

```sh
gh attestation verify demoreel_1.0.0-1_all.deb --repo milnet01/demoreel \
    --source-ref refs/tags/v1.0.0 \
    --source-digest "$(git rev-parse 'v1.0.0^{commit}')" \
    --signer-workflow milnet01/demoreel/.github/workflows/release.yml
```

`--source-digest` is the part that ties the file to the signed commit. The tag's
name alone would pass for a tag moved to another commit for the build and moved
back afterwards.

**Each file is the one listed.** Each release carries `SHA256SUMS`, which names
every other file with its SHA-256 hash. In the folder holding your downloads:

```sh
sha256sum -c --ignore-missing SHA256SUMS
```

Each file you downloaded is reported `OK`. `SHA256SUMS` sits on the same page as
the files, so alone it catches a damaged download and not a swapped one. The
build record is what catches a swap.

A package installed from the openSUSE Build Service repositories is checked
by your package manager against that repository's own key. These steps are
for files downloaded from GitHub.

**The limit.** The release workflow checks the tag as well, but it runs from the
tag, so a tag can remove that step or add its own key to the file it reads.
Those checks catch a mistake, and not someone who can push to the repository.
What holds against that person is your own check above, against the key on the
account. Someone holding the GitHub account itself could change that list too,
and nothing here defeats them.

## Supported versions

Only the latest release. A fix goes on `main` and ships in the next release.
An older release gets no fix, and there are no maintenance branches.

## Reporting a vulnerability

Report privately through GitHub's advisory form for this repository:
<https://github.com/milnet01/demoreel/security/advisories/new>. A public issue
is the wrong channel for anything not already listed above.

The items tracked in [ROADMAP.md](ROADMAP.md) are already known and do not need
reporting. They are recorded here so that anyone deciding whether to use this
tool on a shared machine can see them before they do.
