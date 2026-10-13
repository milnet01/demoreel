<!-- ants-spec-format: 1 -->
# DEMO-0068 — Ship demoreel as .deb, .rpm and Arch packages built and tested in CI

**Status:** accepted (2026-10-10).
**Kind:** package.
**Source:** ROADMAP DEMO-0068 (user-request-2026-09-25; design decisions 2026-10-08).
**Pairs with:** DEMO-0069 and DEMO-0070 (built under this contract; no spec of their own), DEMO-0072 (the from-source install reuses § 4.1's script), DEMO-0174 (`record --gpu` on openSUSE, § 4.6).

A stranger who finds demoreel on the website or GitHub downloads one file
for their distro, installs it with their own package manager, and gets the
command, its manual page, tab completion and translations, with every
program it needs pulled in. Or they add demoreel's repository once, and each
new version arrives with their system's own updates.

## 1. Goal

From 0.9.0 on, every GitHub release carries a `.deb` for Debian and Ubuntu,
one `.rpm` for Fedora and openSUSE, and a `PKGBUILD` for Arch. All three
install the same files in the same places. Each file was built by the same
`ci.sh` step the gate runs, from the tagged tree, and was installed and run
in a clean container of every distro it targets before it was attached.

From 0.9.0 on, the openSUSE Build Service (OBS) also builds each release for
every distro version it can, and publishes a repository for each. Those
packages are built from the release's own tarball, and each is installed from
its published repository and run before the release counts as on OBS.

## 2. Problem

1. **Installing demoreel today means a `git clone` and a hand-made
   symlink** (README § Install, step 2). Tab completion and the manual page
   are further manual steps (README § The manual page, § Tab completion).
   A stranger expects their package manager to do all of it.
2. **A package can silently lose every translation.** `use_languages` looks
   for catalogs in one place only, `Path(here).resolve().parent / "po"`, and
   DEMO-0060 § 4.2 forbids any other. A package that copies the script into
   `/usr/bin` without `po/` beside it runs in English for everyone, with no
   error. Measured 2026-10-08: the script copied alone to a scratch
   directory, run with `LANG=fr_FR.UTF-8`, printed `usage:`; the checkout,
   run the same way, printed `utilisation :`.
3. **Dependency names differ per distro** (the `PACKAGES` table in
   `demoreel` names the `xauth` package three ways across its four package
   managers, and `Xvfb`'s three ways too), and the
   `--gpu` programs must not be forced on someone who never records a 3D app.
4. **On openSUSE, `record --gpu` cannot write its video with distro
   packages.** Measured 2026-10-08 in a fresh `opensuse/tumbleweed`
   container: `wf-recorder-0.6.0+git4` loads `libavcodec.so.62`, and on this
   machine `has_encoder` reports that library has no `libx264` (ffv1,
   utvideo and huffyuv are present). `zypper se` shows Packman offering no
   `libavcodec62` binary, only `libavcodec63`, which that wf-recorder cannot
   load. `cmd_check` already reports this (DEMO-0171). Packman has shipped a
   `libavcodec62` with `libx264` since 2026-10-09 (8.1.3, in its
   `Essentials` folder, listed 2026-10-13). With it installed on this
   machine, the distro's wf-recorder recorded `record --gpu -- vkcube` as
   H.264 showing a shaded cube (2026-10-13).

## 3. Scope decisions (agreed with the user)

All made by the user. The first four on 2026-10-08 in DEMO-0068's brief, the
next two on 2026-10-08 while this spec was drafted, and the OBS ones on
2026-10-11 and 2026-10-13.

- **Audience: strangers** who find demoreel on the website or GitHub, not
  this machine.
- **On openSUSE and Fedora the package depends on the distro's `ffmpeg`**,
  like any other dependency. Where that lacks `libx264`, `demoreel check`
  already names the Packman or RPM Fusion fix (`x264_advice`). The package
  does not depend on a third-party repository.
- **Debian and Ubuntu get a `.deb` attached to each release, not a PPA.**
- **Files on the release, and OBS in 0.9.0.** The OBS account exists
  (`home:milnet`, 2026-10-11), so 0.9.0 publishes there too (§ 4.7). COPR
  and the AUR follow as the user creates each account.
- **OBS builds for as many distro versions as it can** (2026-10-13). § 4.7
  says which count.
- **A script run on this machine after each release submits to OBS**
  (2026-10-13). No OBS credential is stored on GitHub.
- **OBS builds from the release's own tarball** (2026-10-13), not from a
  second copy of the source fetched from the tag.
- **openSUSE `record --gpu`: take wf-recorder's library from Packman**
  (2026-10-13), as DEMO-0174 (§ 4.6). This replaces the lossless recording
  chosen on 2026-10-08, before Packman shipped that library. Not
  "unsupported", and not a self-build guide.
- **Release files are built on GitHub when a release is published**, by a
  workflow job, not on this machine. That keeps DEMO-0084's provenance
  attestation possible later.

## 4. Design

### 4.1 One install layout, written by one script

`packaging/install.sh` stages the installed tree under `$DESTDIR`. Every
package format calls it. Nothing else decides where a file goes.

```
/usr/share/demoreel/demoreel        the script, byte-identical to the tag's, mode 755
/usr/share/demoreel/po/<code>.po    every catalog in po/ (not demoreel.pot)
/usr/bin/demoreel                   symlink -> ../share/demoreel/demoreel
/usr/share/man/man1/demoreel.1      the manual page (each format compresses it its own way)
/usr/share/bash-completion/completions/demoreel
/usr/share/zsh/site-functions/_demoreel
/usr/share/fish/vendor_completions.d/demoreel.fish
```

The symlink is what keeps DEMO-0060 § 4.2's one rule: `resolve()` follows it
to `/usr/share/demoreel/`, where `po/` is. The licence goes where each
format expects it (`%license`, `/usr/share/licenses/demoreel/`,
`/usr/share/doc/demoreel/copyright`), so it is the one file a wrapper places
itself.

**The script is not rewritten.** No shebang mangling and no version stamp:
the installed `demoreel` is the tagged file, so a checksum of the tree's
file (DEMO-0084) also checks the installed one. `#!/usr/bin/env python3` stays.

### 4.2 Dependencies

| Need | `.deb` | `.rpm` | `PKGBUILD` |
|------|--------|--------|------------|
| required | `python3, xvfb, xauth, xdotool, ffmpeg, fontconfig, fonts-dejavu-core` | `Requires: /usr/bin/python3 /usr/bin/Xvfb /usr/bin/xauth /usr/bin/xdotool /usr/bin/ffmpeg /usr/bin/fc-match font(dejavusans)` | `depends=(python xorg-server-xvfb xorg-xauth xdotool ffmpeg fontconfig ttf-font)` |
| `--gpu` | `Recommends: cage, xwayland, wlr-randr, wf-recorder` | `Recommends:` the four by `/usr/bin/` path | `optdepends=` the four |

**One `.rpm` serves Fedora and openSUSE** because it names files and a
font capability, not packages. Measured 2026-10-08 with a test package
carrying those `Requires:` and `Recommends:` lines, less the two font ones: `dnf install` in `fedora:44` exited 0
and installed all nine programs. `zypper install` in `opensuse/tumbleweed`
exited 0 and installed the five required programs. The four recommended ones
came only with `--recommends`, because the container image does not install
recommended packages by default.

`ffmpeg` is the distro's. A distro whose `ffmpeg` has no `libx264` installs
cleanly, and `demoreel check` says what to do (§ 3).

**Text on a card or a caption needs `fc-match` and a font**, which the
finishing commands ask for (`text_font`). Measured 2026-10-08 with the
other required programs installed: `archlinux:latest` and
`opensuse/tumbleweed` had no font, and `check` reported text NOT READY.
Adding `ttf-font` on Arch (pacman chose `gnu-free-fonts`), and
`font(dejavusans)` with `fontconfig` on openSUSE and on `fedora:44`, turned
it ready. Debian and Ubuntu reported it ready with `ffmpeg` alone; the `.deb`
names the two packages so that does not rest on `ffmpeg`'s own list.

### 4.3 The three formats

All live under `packaging/`, all are noarch, and all take the version from
`__version__`, release number 1.

- **`.deb`** — `demoreel_<v>-1_all.deb`. `dpkg-deb --root-owner-group
  --build` over the staged tree plus a generated `DEBIAN/control`. No
  debhelper: there is nothing to compile.
- **`.rpm`** — `demoreel-<v>-1.noarch.rpm`, from `packaging/demoreel.spec`.
  `%install` runs `install.sh`. Built with `rpmbuild` in a Fedora container,
  with shebang mangling turned off so § 4.1 holds.
- **`PKGBUILD`** — `package()` runs `install.sh`. Its `source=` is the
  release's own tarball, `demoreel-<v>.tar.gz`, attached by the same job, and
  its `sha256sums=` is that file's hash. `./ci.sh --packages --out` writes
  both into the `PKGBUILD` it leaves in `<dir>`. The tree's copy names no version or hash.

### 4.4 Build and install test: `./ci.sh --packages`

One `ci.sh` step builds all three from a `git archive` of the tree as it
stands, tracked and new files alike. On a clean tree that is `HEAD`, which is
what the release builds from its tag. It then installs each in a clean container of every
target and runs it there. Containers run under `podman`, as the parity leg
does. The full gate runs it, except on GitHub (`GITHUB_ACTIONS`), where the
`packages` job runs it instead, and inside the parity container
(`DEMOREEL_PARITY_INSIDE`). `./ci.sh --docs` does not run it.
**Called directly, `./ci.sh --packages` always runs**, and fails rather than
skips when it cannot.

| Container | Installs | With |
|-----------|----------|------|
| `ubuntu:24.04`, `debian:stable` | the `.deb` | `apt-get install ./…deb` |
| `fedora:latest` | the `.rpm` | `dnf install` |
| `opensuse/tumbleweed` | the `.rpm` | `zypper -n --no-gpg-checks install --recommends --allow-unsigned-rpm` |
| `archlinux:latest` | the package `makepkg` built from the `PKGBUILD` | `pacman -U` |

In each container, after the install: § 5's container checks, then the
package is removed and § 5's removal check runs.

`ci.yml` gains a `packages` job that runs `./ci.sh --packages`, beside
the existing `ci` job, so the gate's twenty-minute limit is not shared. Per
`CLAUDE.md` § State, the check lives in `ci.sh`, and the job only calls it.

### 4.5 Attaching to a release

A `release` job in its own workflow, `.github/workflows/release.yml`, on
`release: types: [published]`. A trigger belongs to a whole workflow file,
so the `ci` and `packages` jobs do not run on a release. The job:

1. Checks out the release's tag.
2. Runs `./ci.sh --packages --out <dir>`: the same build and install test,
   leaving the files in `<dir>`.
3. Uploads the `.deb`, the `.rpm`, the tarball and the filled `PKGBUILD`
   with `gh release upload`.

`cut-release` publishes the release with the user's token, which is what
fires `release: published`. A release created by the workflow's own token
fires nothing. **Only this job has `contents: write`.** Both workflows'
top-level `permissions: contents: read` stays. A failed test attaches
nothing. Re-running the job for the same tag replaces the files
(`--clobber`).

`docs/specs/DEMO-0084-verify-a-download.md` § 4.4 adds steps to this job
(a tag-signature check first, `SHA256SUMS`, a build record) and two
permissions; that spec governs them.

### 4.6 openSUSE and `record --gpu`

The package recommends wf-recorder on openSUSE as everywhere. openSUSE's
build of the video library it loads has no H.264, and Packman's has (§ 2,
item 4). README's openSUSE `--gpu` instructions install Packman's:

```sh
sudo zypper install --from packman --allow-vendor-change libavcodec62
```

When wf-recorder's library has no `libx264`, `check` reports
`--gpu: NOT READY` with the reason, as now, and on openSUSE also prints that
command, with the package named from the library's file name (DEMO-0174).
No package depends on Packman.

### 4.7 Publishing to OBS

OBS builds demoreel for each target below and publishes a signed repository
for each. Someone who adds that repository gets each new version with their
system's updates.

- **Where.** Project `home:milnet:demoreel`, package `demoreel`. A project
  of its own, as finbreak has, so its targets are its own.
- **Built from the release's files.** The submit script uploads the tarball
  and the filled `PKGBUILD` that `release.yml` attached (§ 4.5). No OBS
  source service fetches from GitHub. Every package, on the release page and
  on OBS, is then built from one file.
- **The recipes.** The `.rpm` targets build `packaging/demoreel.spec`; the
  copy the script commits starts with `%define ver <version>`, and the
  tree's copy is unchanged. The Arch target builds the release's `PKGBUILD`.
  The Debian and Ubuntu targets need a source package, which `dpkg-deb`
  does not make: `packaging/obs/debian/` holds its `rules`, `changelog`,
  `copyright` and `source/format`, and `packaging/obs/demoreel.dsc` names
  it. `rules` runs `install.sh` with `PREFIX=/usr`, like every other format
  (§ 4.1). The tree's `changelog` and `.dsc` carry `@VERSION@` where the
  version goes, as `debian-control` does, and the script fills it (INV-7).
  The script writes `debian/control` from `packaging/debian-control`: its
  `Package`, `Architecture`, `Section`, `Depends`, `Recommends` and
  `Description` fields make the binary stanza, and its `Maintainer`,
  `Section`, `Priority` and `Homepage` go into the source stanza. So the
  `.deb`'s dependency list keeps one home.
- **The shebang stays.** If openSUSE's `rpmlint` refuses
  `#!/usr/bin/env python3`, a `packaging/obs/demoreel-rpmlintrc` filters
  that one check (§ 4.1, INV-3). Measured 2026-10-13, it does not: it scores
  the shebang 9 against openSUSE's limit of 999, and the OBS build passes.
- **The `.rpm` owns its zsh and fish completion folders** with `%dir`. An
  OBS openSUSE build fails on a folder no package owns, and neither shell
  need be installed.
- **Targets.** `packaging/obs/targets` holds one line per target, and `#`
  starts a comment. Six fields, separated by whitespace: the OBS repository
  name, `<project>/<repository>` it builds against, the container image,
  the package manager, `demoreel check`'s expected exit status, and the
  text its output must contain, which runs to the end of the line.
  `obs-setup.sh` writes the OBS project's repositories from it, and
  `./ci.sh --obs-check` reads it, so the two cannot disagree. A target is
  listed when OBS builds for it, it is a released version its distro still
  supports, and INV-13 passes in its container. Candidates for the first
  submit: openSUSE Tumbleweed, Slowroll and Leap 16.0; Fedora 43 and 44;
  Debian 12 and 13; Ubuntu 22.04, 24.04 and 26.04; Arch; Mageia 10; Amazon
  Linux 2023; openEuler 24.03. A candidate that fails for a reason outside
  demoreel, such as a dependency its distro does not carry, is left out, and
  § 9 names it with the reason. **A `python3` too old to run demoreel is
  such a reason**: the packages name no Python version, so that target is
  left out rather than every package gaining a floor.
- **Not targets: development branches and versions past their end of
  life** (Rawhide, Debian Testing and Unstable, Ubuntu 26.10, Mageia
  Cauldron). Such a version can fail with no change to demoreel.
- **Submitting a release.** `packaging/obs/obs-submit.sh`, run on this
  machine with the user's `osc` login once `release.yml` has attached the
  files. It takes the version from the checkout's `__version__`, and:
  1. refuses unless the tag `v<version>` exists and none of the files OBS
     builds from differs from it (INV-12): `demoreel.spec`,
     `debian-control`, and `packaging/obs/`'s `debian/`, `demoreel.dsc`
     and `demoreel-rpmlintrc` where it exists. The rest comes in the
     release's tarball;
  2. downloads the release's tarball and `PKGBUILD`, and refuses unless the
     tarball's checksum is the one the `PKGBUILD` names (INV-11);
  3. updates its `osc` checkout, kept outside the tree, swaps the previous
     release's files for these, and commits one revision.

  `packaging/obs/obs-status.sh` then waits until every target has finished
  building, and `./ci.sh --obs-check` tests what was published (INV-13).
- **Credentials stay on this machine**, in the user's `osc` configuration.
  No workflow talks to OBS (INV-14).
- **`packaging/obs/obs-setup.sh`** creates the project and package, and
  re-applies the targets when `targets` changes. Running it twice changes
  nothing.

## 5. Invariants

The container checks are run by `./ci.sh --packages` in every container of
§ 4.4's table.

- **INV-1** — Every format installs the same file list. Every path from
  § 4.1 is present, and none outside it apart from the licence and
  distro-generated files.
  *Test:* `./ci.sh --packages` compares each installed package's file list
  (`dpkg -L`, `rpm -ql`, `pacman -Qlq`) against `install.sh`'s staged tree, with each
  format's compression suffix on the manual page stripped.
  *Breaks when:* a file is added to one format's wrapper and not to
  `install.sh`, or `install.sh` gains a path one format drops.

- **INV-2** — An installed demoreel finds its translations.
  *Test:* in each container, `PYTHONUTF8=1 LANG=fr_FR.UTF-8 demoreel --help | head -1`
  starts `utilisation :`. The fixture isolates § 4.1's symlink: the same
  command against a script with no `po/` beside it prints `usage:`
  (measured on the host, § 2, item 2).
  *Breaks when:* `/usr/bin/demoreel` is a copy rather than a symlink, or
  `po/` is installed anywhere but beside the script it resolves to.

- **INV-3** — The installed script is the tagged one.
  *Test:* in each container, the checksum of `/usr/share/demoreel/demoreel`
  equals that of the `demoreel` in the archive the package was built from.
  A checksum, because Arch's image has no `cmp`.
  *Breaks when:* a build step rewrites the shebang (rpm's
  `brp-mangle-shebangs`), stamps a version, or strips anything.

- **INV-4** — The required programs come from the distro's own repositories.
  *Test:* in each clean container, the install exits 0 with only the image's
  default repositories enabled, and `command -v` finds `python3`, `Xvfb`,
  `xauth`, `xdotool`, `ffmpeg`, `ffprobe` and `fc-match` afterwards.
  *Breaks when:* a dependency is misnamed, or names a package only a
  third-party repository carries.

- **INV-5** — The `--gpu` programs are recommended, never required.
  *Test:* the openSUSE container installs once without `--recommends`, and
  the Ubuntu container once with `--no-install-recommends`; after each,
  `command -v cage` finds nothing. Where § 4.4 installs with recommends, the
  four programs are present on every distro that packages them. The Arch
  package lists the four under `optdepends`.
  *Breaks when:* one of the four moves into the required set, or its name is
  wrong.

- **INV-6** — An installed demoreel can record on a distro whose `ffmpeg`
  has `libx264`, and says how to get one where it has not.
  *Test:* in every container, `demoreel check` prints `text on a card or a
  caption: ready`. In the Debian, Ubuntu and Arch containers it exits 0 and
  prints `record and shot: ready`. In the Fedora and openSUSE containers it
  exits 1, and its output carries `x264_advice`'s line for that distro.
  Measured 2026-10-08 with the required programs installed by hand: exactly
  that, once a font was present.
  *Breaks when:* a required program is missing from the dependency list, or a
  file the script reads at run time is not installed.

- **INV-7** — The package's version is the script's.
  *Test:* `./ci.sh --version-lockstep` also fails when a file under
  `packaging/` holds `__version__`'s current value as written. In each
  container, `demoreel --version` prints `demoreel <__version__>`, and the
  package manager reports version `<__version__>-1`.
  *Breaks when:* a packaging file carries its own version and a bump misses it.
  *Scope:* the release files. OBS numbers its own builds' release, so on OBS
  only the version part is checked (INV-13).

- **INV-8** — Removing the package removes everything it installed.
  *Test:* after removal in each container, none of § 4.1's paths exists, and
  neither does `/usr/share/demoreel/`.
  *Breaks when:* a file is created at install time but owned by no package,
  such as a byte-compiled cache.

- **INV-9** — The attached `PKGBUILD` builds from the attached tarball.
  *Test:* `./ci.sh --packages --out` runs `makepkg --verifysource` against
  the filled `PKGBUILD`, and the `release` job uploads only what it left.
  *Breaks when:* the hash is computed over a different file than the one
  uploaded, or the tarball is rebuilt after hashing.

- **INV-10** — Trust boundary: only the `release` job can write to the
  repository, and it uploads only files that passed INV-1 to INV-9.
  DEMO-0084 INV-4 and INV-6 extend this to `SHA256SUMS` and to the two
  permissions its build record needs.
  *Test:* `grep -rn 'contents: write' .github/workflows/` names one line,
  inside `release.yml`'s `release` job. The upload step runs after the
  `./ci.sh --packages --out` step and only if it succeeded.
  *Breaks when:* `contents: write` moves to the workflow level or another
  job, or the upload runs on failure.

- **INV-11** — OBS builds the release's own tarball.
  *Test:* by hand, once: with the downloaded tarball replaced by another
  file, `obs-submit.sh` stops before its first `osc` call and names the
  checksum mismatch. In every `--obs-check` container, INV-3's checksum
  compares the installed script with the release tarball's.
  *Breaks when:* the script makes its own tarball, fetches a different
  file, or OBS's build rewrites the script.

- **INV-12** — The recipes OBS builds are the tag's.
  *Test:* by hand, once each: with an uncommitted change to
  `packaging/demoreel.spec`, and with `__version__` naming a tag that does not exist,
  `obs-submit.sh` stops before its first `osc` call and names the cause.
  *Breaks when:* a recipe edited after the release ships under the
  release's version.

- **INV-13** — The published package installs and runs on every target.
  *Test:* `./ci.sh --obs-check` runs, in a clean container of each target
  in `packaging/obs/targets`: it adds the published repository with the
  repository's key trusted, never with signature checks off, installs
  `demoreel`, then runs INV-1's, INV-2's, INV-3's, INV-4's and INV-8's
  checks. `demoreel check` must say what `targets` records for that target,
  and `demoreel --version` must print the checkout's version, as must the
  package manager before its release part. It fails when any target fails,
  or still serves an older version. It reads a live repository, so the full
  gate does not run it. INV-5 is not repeated there: the recommended
  packages are named by the same files the release's packages use.
  *Breaks when:* a recipe differs from the release files' build, OBS's
  build changes an installed file, or a dependency is missing on one
  target.

- **INV-14** — Only this machine submits to OBS.
  *Test:* the full gate's workflow step fails when a file under
  `.github/workflows/` contains `opensuse.org`, `obs-submit` or `OBS_`, or
  `osc` as a whole word.
  *Breaks when:* a workflow is given OBS access, which needs an OBS
  credential stored on GitHub.

## 6. Failure modes

- **A distro renames a dependency.** INV-4 fails in that container on the
  next gate, before any release.
- **A container image changes underneath the gate** (`debian:stable` moves
  to a new release, `fedora:latest` too). The gate fails on a real
  incompatibility, which is the point. A floating tag is chosen over a pinned
  one for that reason.
- **No network, or a mirror is down.** The install fails and the step fails.
  It is not skipped: a skipped package test is not a pass. Without `podman`,
  the full gate skips the step and its last line says so, as the parity leg
  does; a direct `./ci.sh --packages` fails.
- **The GitHub runner lacks `podman`.** The `packages` and `release` jobs
  install it first. Whether the runner image already carries it is
  unverified.
- **`release: published` does not fire** (a release created by a bot token).
  Nothing is attached and nothing fails. The release page then has no
  packages, which the post-release website hand-off (§ 11) would notice.
- **A package step needs root in the container.** The containers run as
  root. `makepkg` refuses root, so the Arch build runs as an unprivileged
  user created inside the container.
- **The gate becomes too slow** with five installs. Measured when
  `./ci.sh --packages` first runs, and recorded in § 13.
- **Nobody runs `obs-submit.sh` after a release.** OBS keeps serving the
  previous version, and its builds stay green. `cut-release` has no step
  after publishing that could run it, so CONTRIBUTING.md's release steps
  list it, and nothing else catches the miss (§ 10). finbreak measured
  this failure on its own OBS package (FIBR-0317).
- **`release.yml` has not attached the files yet.** `obs-submit.sh` finds
  no tarball and stops before its first `osc` call.
- **One target fails to build or install.** `obs-status.sh` and
  `--obs-check` fail and name it. Fixing it is a recipe change, so it ships
  in the next release (INV-12); a target that cannot be fixed is taken out
  of `targets`.
- **A target reaches its end of life.** Its repository stops getting
  updates from OBS. It is taken out of `targets` and `obs-setup.sh` re-run.

## 7. Tests

All in `ci.sh`, in the `--packages` step, run inside each container of
§ 4.4 except where noted:

- INV-1, INV-2, INV-3, INV-4, INV-6, INV-8 — one check each, in every
  container.
- INV-5 — the openSUSE and Ubuntu no-recommends installs, plus INV-5's
  recommends check, plus a grep of the `PKGBUILD`.
- INV-7 — `./ci.sh --version-lockstep` on the host, plus `--version` in
  every container.
- INV-9 — `--packages --out`, which the `release` job runs. The gate runs the
  same `makepkg --verifysource` against a locally made tarball.
- INV-10 — a `ci.sh` grep of the workflow files, in the full gate.
- INV-11, INV-12 — by hand, once, when `obs-submit.sh` is first built: each
  seeded break named in the invariant.
- INV-13 — `./ci.sh --obs-check`, run after each OBS submit.
- INV-14 — a `ci.sh` grep of the workflow files, in the full gate.

Each check must be seen failing once against a deliberately broken package
before it is trusted: a copy instead of the symlink (INV-2), a mangled
shebang (INV-3), `cage` moved to the required set of the `.deb` and of the
`.rpm` (INV-5).

## 8. Alternatives considered (and rejected)

- **A PPA, COPR or the AUR in 0.9.0.** Each needs an account the user
  does not have yet. Files on the release need none (§ 3). OBS was in this
  list until its account existed.
- **OBS fetches the source from the tag** with its source services, as
  finbreak's does. That is a second copy of the source, made a second way,
  and the user chose the release's own tarball (§ 3).
- **A GitHub workflow submits to OBS.** It needs an OBS credential stored
  on GitHub. The user chose a script on this machine (§ 3).
- **OBS for openSUSE alone.** The user asked for as many distros as OBS
  can serve (§ 3).
- **One package per distro family, named by package.** An openSUSE `.rpm`
  and a Fedora `.rpm` differ only in dependency names, and file dependencies
  remove the difference (§ 4.2, measured).
- **nFPM or fpm to write all three from one manifest.** A new build
  dependency, downloaded in CI. `install.sh` already gives one layout, and
  each format's own tool is already in the container that tests it.
- **Install the script as `/usr/bin/demoreel` and the catalogs under
  `/usr/share/locale`.** DEMO-0060 § 4.2 rejects searching anywhere but
  beside the resolved script (the user's decision, recorded in DEMO-0071).
- **`/usr/lib/demoreel` or `/usr/libexec/demoreel` for the script.** The
  script is architecture-independent, and `/usr/share/<pkg>` is valid on all
  four families. Ants Terminal's vendored copy (DEMO-0163) chose its own path
  for its own reasons, and nothing binds the two.
- **Rewrite the shebang to `/usr/bin/python3`.** It silences one lint
  warning and breaks INV-3, which DEMO-0084's checksums will rely on.
- **Build the release files on this machine.** The user chose GitHub (§ 3).
- **Depend on Packman's or RPM Fusion's `ffmpeg`.** A package cannot name
  another vendor's repository, and the user chose the distro's `ffmpeg`
  plus `check`'s advice (§ 3).

## 9. Out of scope

- Publishing to COPR and the AUR — follows as the user creates each
  account; DEMO-0070 stays open for it.
- OBS candidates left out (measured 2026-10-13, each package installed in a
  clean container of the candidate): Amazon Linux 2023, whose repositories
  carry no `ffmpeg` and no `xdotool`; and openSUSE Slowroll, which has no
  container image to test it in.
- Other processor architectures on OBS. The targets build on x86_64.
- Checksums, signed tags and a provenance attestation — `docs/specs/DEMO-0084-verify-a-download.md`.
- The documented from-source install, and its container check — tracked by
  DEMO-0072.
- Testing the release files on openSUSE Leap, Ubuntu releases other than
  24.04, and Debian other than stable — deferred; not yet queued. OBS
  covers those versions with its own packages (§ 4.7).

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | `./ci.sh --packages`, file-list comparison |
| INV-2 | `./ci.sh --packages`, French `--help` in each container |
| INV-3 | `./ci.sh --packages`, checksum in each container |
| INV-4 | `./ci.sh --packages`, clean install with default repositories |
| INV-5 | `./ci.sh --packages`, no-recommends installs and `PKGBUILD` grep |
| INV-6 | `./ci.sh --packages`, `demoreel check` in each container |
| INV-7 | `./ci.sh --version-lockstep`, and `--version` in each container |
| INV-8 | `./ci.sh --packages`, removal check |
| INV-9 | `./ci.sh --packages --out`'s `makepkg --verifysource`; the gate's local equivalent |
| INV-10 | full gate's workflow grep. **Partial:** it reads the file, not GitHub's effective permissions |
| INV-11 | `obs-submit.sh`'s checksum check; the seeded break, by hand, once; INV-3 in `--obs-check` |
| INV-12 | `obs-submit.sh`'s tag check; the seeded breaks, by hand, once |
| INV-13 | `./ci.sh --obs-check`, after each submit. **Partial:** not in the full gate |
| INV-14 | full gate's workflow grep. **Partial:** it reads the file for names, and a workflow could reach OBS without one |
| § 4.1 one layout | INV-1 |
| § 4.5 files attached to every release | **nothing** — a release whose job never ran has no packages and nothing fails; the website hand-off is the only reader |
| § 4.7 every release submitted to OBS | **nothing** — CONTRIBUTING.md's release steps are the only reminder |

## 11. Cross-doc impact

- **README.md** — § Install leads with the package for each distro and keeps
  the clone as the from-source route. The openSUSE `--gpu` note of § 4.6.
  It also says where demoreel's OBS repository is, for updates with the
  system's own.
- **`docs/standards/versioning-overrides.md`** — the package name `demoreel`
  and the command `/usr/bin/demoreel` become breaking surfaces. The
  directory `/usr/share/demoreel/` is not one.
- **CLAUDE.md** — § State names `packaging/` and `./ci.sh --packages`.
  Its "There is no spec and none is wanted" has been false since DEMO-0060.
  That sentence is DEMO-0173's to fix.
- **CONTRIBUTING.md** — how to run the package step locally, and the OBS
  steps after a release: `obs-submit.sh`, `obs-status.sh`, then
  `./ci.sh --obs-check`.
- **CHANGELOG.md** — under DEMO-0068, DEMO-0069 and DEMO-0070.
- **`.claude/bump.json`** — no new version-bearing file, since every format
  reads `__version__` (INV-7).
- **The Ants Projects Hub website** — told when the first package is
  attached, per DEMO-0068's 2026-09-28 follow-up.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0068-linux-packages-loop-log.md`.

## 13. Resource cost

- **No new dependency for demoreel.** The build tools (`dpkg-deb`,
  `rpmbuild`, `makepkg`) live in the containers, never on a user's machine.
- **Gate time and disk:** five container images and five dependency
  installs per full gate. Measured 2026-10-13: about three minutes for the
  whole step, with the images already pulled. The largest image,
  `archlinux:latest`, is about 410 MB.
- **Release assets:** four files per release, the tarball the largest.
- **OBS:** one submit per release, run by hand on this machine. Its build
  time is OBS's. `--obs-check` pulls one container image per target, and
  `osc` is needed on this machine only.

## 14. Migration / compatibility

Someone who installed from a clone keeps working: nothing moves in the
checkout. Installing the package as well puts `/usr/bin/demoreel` on PATH
after `~/.local/bin` on most setups, so their symlink still wins until they
remove it. The README says to remove it.
