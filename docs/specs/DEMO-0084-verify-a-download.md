<!-- ants-spec-format: 1 -->
# DEMO-0084 — Sign release tags, and attach checksums and a build record to each release

**Status:** accepted (2026-10-13).
**Kind:** security.
**Source:** ROADMAP DEMO-0084 (user-request-2026-09-25; decisions 2026-10-13).
**Pairs with:** DEMO-0068 (its release job, `docs/specs/DEMO-0068-linux-packages.md` § 4.5 and INV-10, gains the steps below; that spec is amended in the same batch).

A user who downloads a demoreel release can check that the files are the
ones GitHub built from a tag the maintainer signed, and that nobody changed
them on the way.

## 1. Goal

From 0.9.0 on, every release tag is signed with a key kept for that one
job, every file attached to a release is listed in a `SHA256SUMS` file
attached beside it, and every attached file carries a GitHub build record
(a provenance attestation) saying which workflow built it from which tag.
`SECURITY.md` tells a user how to check each of the three. A release whose
tag is not signed gets no files.

## 2. Problem

1. **Nothing ties a downloaded file to this repository.** `release.yml`
   uploads the `.deb`, the `.rpm`, the tarball and the `PKGBUILD`
   (DEMO-0068 § 4.5), and nothing beside them says what their contents
   should be. A file swapped on a mirror, or on the release page by
   someone holding the token, looks the same as the real one.
2. **Tags are unsigned.** `cut-release` Phase 4 makes an annotated tag
   (`git tag -a`), and this clone has no signing configured: `git config
   --get tag.gpgSign` and `git config --get user.signingkey` print nothing,
   measured 2026-10-13. A tag pushed by anyone with write access reads the
   same as one the maintainer made.
3. **A tag cannot be signed after it is published.** Signing means
   replacing the tag object, and a tag people have fetched does not move
   for them (`cut-release` § 0d). So the first packaged release, 0.9.0, is
   the last chance to start signed. This is why 0.9.0 waits for this item
   (user, 2026-10-13).

## 3. Scope decisions (agreed with the user)

- **0.9.0 waits for this item and for DEMO-0174** (user, 2026-10-13).
- **A new SSH key used only to sign demoreel's release tags**, not the
  user's login key and not a GPG key (user, 2026-10-13).
- **No passphrase on it** (user, 2026-10-13). Anything that can read the
  key file can already push to GitHub with the login stored on this
  machine, so a passphrase would add a prompt and little protection.
- Checksums, signed tags and a provenance attestation are the three the
  roadmap item names (user-request-2026-09-25). Nothing else is added.

## 4. Design

### 4.1 The signing key and where its public half lives

- Private key: `~/.ssh/demoreel-release`, ed25519, no passphrase, comment
  `demoreel release signing`. It never enters the repository.
- Public half: `packaging/release-signers`, one line in OpenSSH's
  allowed-signers format, so `git` and `ssh-keygen` read it directly:

  ```
  milnet01@users.noreply.github.com namespaces="git" ssh-ed25519 AAAA… demoreel release signing
  ```

  The address is the one `packaging/debian-control` names as maintainer.
- The same public key is added to the GitHub account `milnet01` as a
  **signing** key, so GitHub marks each release tag *Verified*. Adding it
  needs the `admin:ssh_signing_key` scope, which the user grants once with
  `gh auth refresh -h github.com -s admin:ssh_signing_key`. GitHub then
  lists it at `https://api.github.com/users/milnet01/ssh_signing_keys`,
  which is a second place to read the key from that is not this
  repository.
- This clone signs every annotated tag with it, through its own
  `.git/config`:

  ```sh
  git config gpg.format ssh
  git config user.signingkey ~/.ssh/demoreel-release.pub
  git config tag.gpgSign true
  ```

  With `tag.gpgSign` set, `cut-release`'s unchanged `git tag -a … -F -`
  makes a signed tag. Measured 2026-10-13 in a scratch repository with a
  throwaway key: the tag object carried `BEGIN SSH SIGNATURE`, and
  `git -c gpg.ssh.allowedSignersFile=<file> tag -v` exited 0 for it, 1
  for an unsigned tag, and 1 when the file held a different key.

### 4.2 Two new `ci.sh` modes for the tag

- **`./ci.sh --signing-check`** — exits 0 only when this clone will sign
  the next tag with a key `packaging/release-signers` lists: `tag.gpgSign`
  is `true`, `gpg.format` is `ssh`, and a test message signed with
  `user.signingkey` (`ssh-keygen -Y sign -n git`) verifies against
  `packaging/release-signers` (`ssh-keygen -Y verify`). On success it
  prints the key's fingerprint. It reads local configuration, so the full
  gate does not run it.
- **`./ci.sh --verify-tag <tag>`** — runs
  `git -c gpg.ssh.allowedSignersFile=packaging/release-signers tag -v <tag>`
  and exits with its status. It needs the tag object present locally.

`.claude/bump.json` gains
`"publish_precheck": "./ci.sh --signing-check"`. `cut-release` runs it at
Phase 0h, before anything is bumped, and stops on a non-zero exit.

### 4.3 Checksums

`./ci.sh --packages --out <dir>`, after copying the four files, writes
`<dir>/SHA256SUMS` with `sha256sum` over exactly those four files, by
name with no folder. Then, in `<dir>`, it fails unless the names in
`SHA256SUMS` are exactly the other files there, none holding a `/`, and
`sha256sum -c SHA256SUMS` passes. A user checks a download with:

```sh
sha256sum -c --ignore-missing SHA256SUMS
```

### 4.4 The release job, in order

The `release` job of `.github/workflows/release.yml` (DEMO-0068 § 4.5)
becomes, in this order:

1. Check out the release's tag (unchanged).
2. Fetch the tag object itself:
   `git fetch --no-tags origin "+refs/tags/$TAG:refs/tags/$TAG"`, so step 3
   never depends on what `actions/checkout` happens to fetch.
3. `./ci.sh --verify-tag "$TAG"`. A failure stops the job: nothing is
   built and nothing is attached.
4. Install podman (unchanged).
5. `./ci.sh --packages --out "$RUNNER_TEMP/release"` (unchanged; it now
   also writes `SHA256SUMS`, § 4.3).
6. `actions/attest`, pinned by commit to v4.2.2
   (`1e69f48acb82d1966a394da916b4c1698aa569d6`, read from
   `gh api repos/actions/attest/git/ref/tags/v4.2.2` on 2026-10-13), with
   `subject-path` naming every file in `$RUNNER_TEMP/release`, `SHA256SUMS`
   included. It runs before the upload, so a failed attestation attaches
   nothing.
7. Upload every file in the folder (unchanged command).

The job's permissions become `contents: write`, `id-token: write` and
`attestations: write`. The README of `actions/attest` also lists
`artifact-metadata: write`. That one is for a storage record, which the
action makes only with `push-to-registry`, a container option this job does
not use, so it is left out. The workflow's top-level `contents: read` stays.

### 4.5 Checking a published release: `./ci.sh --release-check <tag>`

Run on this machine after each release, as `--obs-check` is (CONTRIBUTING
§ Cutting a release). It does what `SECURITY.md` tells a user to do:

1. Downloads every asset of the release with `gh release download` into a
   new folder under the run's temporary directory.
2. Fails unless the assets are exactly `SHA256SUMS` plus the files it
   names, then runs `sha256sum -c SHA256SUMS`.
3. Runs `gh attestation verify <file> --repo milnet01/demoreel
   --source-ref refs/tags/<tag> --signer-workflow
   milnet01/demoreel/.github/workflows/release.yml` on every asset.
4. Fetches the tag and runs `--verify-tag <tag>`.

It reads a live release, so the full gate does not run it.

### 4.6 What `SECURITY.md` says

A new section, *Checking a download*, in this order: where the signing
key is published (both places in § 4.1); the `git tag -v` command against
`packaging/release-signers`; the `sha256sum -c` command; the
`gh attestation verify` command with the flags in § 4.5; and that packages
installed from the OBS repositories are checked by the package manager
against OBS's own repository key, so those three steps are for files
downloaded from GitHub. It also states the limit in § 6's last bullet.

## 5. Invariants

- **INV-1** — Every release tag from 0.9.0 on is signed by a key
  `packaging/release-signers` lists.
  *Test:* `./ci.sh --verify-tag v0.9.0` after the release; and in the
  release job, step 3 of § 4.4. Not runnable before the code exists. The
  fixture that isolates the rule is a tag made with `tag.gpgSign` unset:
  only the signature check rejects it, since the tag is otherwise valid.
  *Breaks when:* a tag is cut from a clone without the § 4.1 settings, or
  signed with a key the file does not list.

- **INV-2** — A release whose tag fails INV-1 gets no files attached.
  *Test:* in `release.yml`, `--verify-tag` (§ 4.4 step 3) comes before
  the build, the attestation and the upload, and none of them runs when
  it fails. Seeded by hand once: `./ci.sh --verify-tag` against an
  unsigned tag in a scratch clone exits 1.
  *Breaks when:* the step is moved after the upload, or given
  `continue-on-error`.

- **INV-3** — `cut-release` stops before bumping anything when this clone
  would not sign the tag.
  *Test:* `.claude/bump.json`'s `publish_precheck` is
  `./ci.sh --signing-check`. Run as
  `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=tag.gpgSign GIT_CONFIG_VALUE_0=false ./ci.sh --signing-check`,
  or with a `user.signingkey` whose key is not in
  `packaging/release-signers`, the mode exits non-zero.
  *Breaks when:* the precheck is removed, or `--signing-check` passes
  without proving a signature that verifies against the file.

- **INV-4** — `SHA256SUMS` names every other attached file exactly once,
  with its correct hash, and nothing else.
  *Test:* `./ci.sh --packages --out <dir>` runs § 4.3's name and hash
  checks in `<dir>` and fails otherwise; `--release-check` fails unless the
  release's assets are exactly `SHA256SUMS` plus the names it lists.
  *Breaks when:* a file is added to `<dir>` after the sums are written, or
  a name in the file carries a folder.

- **INV-5** — Every attached file, `SHA256SUMS` included, has a build
  record from `release.yml` at that release's tag.
  *Test:* `./ci.sh --release-check <tag>` (§ 4.5 step 3) after each
  release.
  *Breaks when:* the attest step is skipped, names a narrower set of
  files, or runs after a file was changed.

- **INV-6** — Trust boundary: only the `release` job holds
  `contents: write`, `id-token: write` or `attestations: write`.
  *Test:* the full gate's "only the release job can write to the
  repository" step (DEMO-0068 INV-10) greps `.github/workflows/` for each
  of the three and requires exactly one line each, in `release.yml`,
  indented six spaces as the `release` job's own `permissions:` writes
  it, with `release:` as the nearest line above it indented two spaces.
  A grant at the workflow level is indented two, and one in a second job
  sits under that job's name, so both fail.
  *Breaks when:* any of the three moves to the workflow level or another
  job.

- **INV-7** — The private key never enters the repository.
  *Test:* the full gate fails on any tracked file with a line that is
  exactly `-----BEGIN OPENSSH PRIVATE KEY-----` and nothing else. The
  step builds that string from two parts, so `ci.sh` does not hold it,
  and prose that quotes it inside a sentence does not match.
  *Breaks when:* the key file, or a copy, is committed.

- **INV-8** — `SECURITY.md`'s *Checking a download* steps work as written
  against the latest release.
  *Test:* `verify-instructions` over that section, by hand, after 0.9.0
  is published.
  *Breaks when:* a command, flag or path in it changes and the section
  does not.

## 6. Failure modes

- **The tag was cut unsigned anyway.** The release job fails at § 4.4
  step 3 and nothing is attached. A published tag is not moved, so the
  fix is the next patch release, cut from a clone that passes
  `--signing-check`.
- **The attestation step fails** (Sigstore or GitHub unavailable). Nothing
  is attached, because the upload comes after it. Re-run the job; the
  upload's `--clobber` makes a re-run safe.
- **The key is lost or must be replaced.** Add the new key as a second
  line in `packaging/release-signers` and on the GitHub account. Keep the
  old line, with `valid-before="<date>"` from the allowed-signers format,
  so older tags still verify.
- **`actions/checkout` changes what it fetches for a tag.** § 4.4 step 2
  fetches the tag object explicitly, so step 3 does not depend on it.
- **The limit, stated in `SECURITY.md`:** the tag check reads
  `packaging/release-signers` from the repository it checks, so someone
  who can push to the repository can also change that file. The key's
  listing on the GitHub account (§ 4.1) is the second source, and a user
  who wants an independent check compares the two.

## 7. Tests

- INV-1, INV-2: `./ci.sh --verify-tag`, run by `release.yml` on every
  release and by `--release-check`. Seen to fail once, by hand, against an
  unsigned tag in a scratch clone before the first release.
- INV-3: `./ci.sh --signing-check`, run by `cut-release` at Phase 0h. Seen
  to fail by hand once with `tag.gpgSign` false, and once with a key the
  file does not list.
- INV-4: the `SHA256SUMS` check inside `./ci.sh --packages --out`, run by
  the release job and on demand; and `--release-check`.
- INV-5: `./ci.sh --release-check <tag>`, by hand after each release.
- INV-6, INV-7: steps in the full gate. Each seen to fail once with a
  seeded break: a second `id-token: write`, and a staged dummy private key.
- INV-8: `verify-instructions`, by hand, after 0.9.0.

## 8. Alternatives considered (and rejected)

- **Reuse the SSH login key.** Rejected by the user: replacing one key
  would mean replacing both.
- **A GPG key.** Rejected by the user: more setup, and Git and GitHub
  verify SSH-signed tags as well.
- **Sign `SHA256SUMS` itself with the release key.** The build record
  already ties every file, `SHA256SUMS` included, to the workflow and the
  tag, and signing on this machine would need the files here, which the
  release job builds on GitHub (DEMO-0068 § 3).
- **Write the checksums in the workflow.** `CLAUDE.md` keeps checks out of
  the workflow; `--out` already owns the files, so it writes their sums.

## 9. Out of scope

- Signing the `.deb` and `.rpm` files themselves — deferred; not yet
  queued. OBS signs its repositories; the attached files rely on the
  checksums and the build record.
- Signing commits — deferred; not yet queued.

## 10. What checks this

| Rule | What catches a breach |
|------|----------------------|
| INV-1 | `release.yml` § 4.4 step 3; `./ci.sh --release-check` |
| INV-2 | **Partial:** the step order in `release.yml`, read by nobody automatically; a seeded run by hand once |
| INV-3 | `cut-release` Phase 0h, running `./ci.sh --signing-check` |
| INV-4 | `./ci.sh --packages --out`; `./ci.sh --release-check` |
| INV-5 | `./ci.sh --release-check`, by hand after each release |
| INV-6 | full gate, "only the release job can write to the repository" |
| INV-7 | full gate, the private-key step |
| INV-8 | **nothing** automatic — `verify-instructions` by hand after 0.9.0 |
| § 4.1 key on the GitHub account | **nothing** — a missing *Verified* mark fails no check |

## 11. Cross-doc impact

- `docs/specs/DEMO-0068-linux-packages.md`: § 4.5 and INV-10 point here
  for the new steps and permissions; § 9's DEMO-0084 line points at this
  spec.
- `SECURITY.md`: the new *Checking a download* section (§ 4.6).
- `CONTRIBUTING.md` § Cutting a release: the § 4.1 settings,
  `--signing-check` and `./ci.sh --release-check <tag>`.
- `.claude/bump.json`: `publish_precheck`.
- `CHANGELOG.md`: an *Added* entry under `[Unreleased]`.

## 12. Cold-eyes loop log

Rows live in `../reviews/DEMO-0084-verify-a-download-loop-log.md`.
