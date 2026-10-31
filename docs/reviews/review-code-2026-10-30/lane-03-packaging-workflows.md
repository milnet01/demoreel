**Line counts as read:**

| File | Lines | File | Lines |
|---|---|---|---|
| `ci.yml` | 144 | `release.yml` | 66 |
| `dependabot.yml` | 20 | `pre-push` | 80 |
| `install.sh` | 66 | `PKGBUILD` | 25 |
| `demoreel.spec` | 59 | `debian-control` | 16 |
| `release-signers` | 1 | `obs-env.sh` | 8 |
| `obs-setup.sh` | 64 | `obs-status.sh` | 62 |
| `obs-submit.sh` | 131 | `targets` | 19 |
| `demoreel.dsc` | 11 | `debian/rules` | 14 |
| `debian/changelog` | 5 | `debian/copyright` | 24 |
| `debian/source/format` | 1 | `demoreel.bash` | 131 |
| `_demoreel` | 188 | `demoreel.fish` | 122 |
| `ci.sh` | range 1–1456, as assigned | | |

**Present on arrival:**
- the global `CLAUDE.md`
- the user's email address
- an environment block
- this agent's prompt
- a SessionStart note about Ants

There was no project `CLAUDE.md` and no git snapshot.

**Disagreements:** none between the brief and the lane file. I gave the dimensions outside the weighting one line each.

## Critical (0)

Nothing found.

## High (4)

- [dim 3] `SECURITY.md:127`, and `ci.sh:1204` — `--source-ref refs/tags/v0.9.0 \` — **The three checks are not bound to each other.**
  - The attestation check tests the ref's name, never the commit, so it does not tie the files to the commit the signed tag names.
  - A writer can move `v0.9.0` to their own commit, carrying their own `release.yml` with the signature step removed. They publish, let it build and attest, then move the tag back to the signed object.
  - The user's `tag -v` passes, `sha256sum` passes against the swapped `SHA256SUMS`, and `gh attestation verify` passes.
  - This is the attacker DEMO-0084 § 2 item 2 names. `SECURITY.md`'s "The limit" implies that comparing keys closes the gap, and it does not.
  - fix: add `--source-digest "$(git rev-parse 'v0.9.0^{commit}')"` to `SECURITY.md` and `--release-check`. Flag from memory of `gh`; not run.

- [dim 3] `release.yml:29` — `ref: ${{ github.event.release.tag_name }}` — **The tree built may not be the tag verified.**
  - From my memory of `actions/checkout`'s ref-helper (not opened), an unqualified ref checks for a branch first. A branch named `v0.9.0` is then what gets checked out and built.
  - Line 39 fetches and verifies the real tag, and nothing compares `HEAD` with `$TAG^{commit}`.
  - The workflow still runs from the tag and the attestation still names the tag, so unsigned branch content ships with a clean record. This defeats the `--source-digest` fix above too.
  - The same missing comparison leaves a window if the tag moves between checkout and fetch.
  - fix: use `ref: refs/tags/...`, and fail unless `HEAD` equals `$TAG^{commit}` after the fetch.

- [dim 3] `ci.sh:1073`, with `ci.sh:869` — `podman run --rm --pull=newer -v "$work:/w:z" -v "$cache/$distro:$at:z" "$image" \` — **Release files sit writable beside untrusted installs.**
  - Waves 2 and 3 only test, yet they mount `/w` read-write while it holds the built `.deb`, `.rpm`, tarball and `PKGBUILD`.
  - Each container runs a full dependency install as root, with maintainer scripts. openSUSE's runs under `zypper -q -n --no-gpg-checks`, a global option as I recall it, so it also covers repository packages and not only the local rpm.
  - `SHA256SUMS` is written at `ci.sh:1101`, after all of this, and the attestation then certifies whatever is there. INV-10's "only files that passed" does not hold against a container that changes them.
  - Spec side too: the `--no-gpg-checks` flag is in DEMO-0068 § 4.4's table.
  - fix: mount `/w:ro` on the test and source waves, hash on the host after the build wave and compare before attaching, and use `--allow-unsigned-rpm` alone.

- [dim 3] `completions/demoreel.bash:23`, `_demoreel:23`, `demoreel.fish:18` — `python3 -c 'import importlib.machinery as m, importlib.util as u, sys` — [tool: semgrep] — **Pressing Tab can run code from the current directory** (CWE-426).
  - `python3 -c` puts the current directory first on `sys.path`. On `demoreel stop <Tab>`, a planted `importlib.py`, or `argparse.py` once the script loads, runs as the user.
  - The directory can be a downloaded tarball or another user's folder in `/tmp`. Packages install this file for every user.
  - `SECURITY.md` lists no such boundary, so the document is incomplete and the code is wrong.
  - fix: `python3 -I -B -c` in all three shells.

## Medium (8)

- [dim 3] `ci.sh:1011`, called from `release.yml:40` — `git -c gpg.ssh.allowedSignersFile=packaging/release-signers tag -v "$1" >/dev/null || {` — **The workflow's signature check certifies itself.**
  - The signers file comes from the tree being checked, so a tag that adds its own key to the file passes.
  - `release.yml` also runs from the tag, so that tag can simply delete the step. INV-2 therefore stops only honest mistakes.
  - `SECURITY.md`'s limit covers the user's check, not this one.
  - fix: compare the signer against a source outside the tree, such as the fingerprint on `ssh_signing_keys`. At minimum, state the limit in DEMO-0084.

- [dim 3] `release.yml:40`, `ci.sh:1011` — `./ci.sh --verify-tag "$TAG"` — **Old signed tags can be replayed, and the tag is never compared with the version.**
  - As I recall, `git tag -v` does not compare the tag object's own name with the ref. An old signed object pushed as `v1.2.3` would pass.
  - Nothing compares `$TAG` with `__version__`, so the job attaches files named for the tree's old version and attests them under the new ref. `PKGBUILD`'s `v$pkgver` URL then points somewhere else.
  - fix: assert that the tag object's `tag` field and `v$(tool_version)` both equal `$TAG`.

- [dim 3] `obs-submit.sh:71` — `grep -q "^sha256sums=('$sum')$" "$stage/PKGBUILD" \` — **OBS gets unauthenticated files, then signs them.**
  - Tarball and `PKGBUILD` come from the same release page, so swapping both passes. The comment's "the one release.yml built and tested" is not what this proves.
  - OBS then builds and signs the result into its repositories, which launders the swap. `PKGBUILD` also runs in OBS's Arch build.
  - `--from` (line 36) skips the download altogether, and § 4.7 does not mention it.
  - fix: run `gh attestation verify` and `verify_tag` before the first `osc` call.

- [dim 3] `ci.sh:702-706` — `PKG_DEBIAN='docker.io/library/debian:stable'` — **Release builders are mutable images.**
  - This breaches `security.md` § 8 (any container image on a tag; CWE-829). The build images make the shipped `.deb`, `.rpm` and Arch package.
  - DEMO-0068 § 6 chooses floating tags for the gate's sake. That reason does not extend to the release path, so the spec is silent where it should decide. Reporting it here because the image is a build input, not a project dependency.
  - fix: pin the release builds by digest and keep floating tags in the gate.

- [dim 3] `release.yml:24` — `id-token: write` — **Too much is held while third-party code runs.**
  - From memory, the OIDC request token and URL reach every `run:` step in a job with this grant, including the one driving `podman` and the install steps.
  - `podman run` passes no `-e` for them, so a container needs an escape to reach them. The exposure is the host step.
  - fix: use separate jobs: build with `contents: read`, then attest and upload the downloaded artifact in a job with the grants.

- [dim 3] `.githooks/pre-push:20`, and line 53 — `[ -x ./ci.sh ] || { say 'no ./ci.sh here — nothing to run'; exit 0; }` — **Two things in the working tree can weaken the gate.**
  - An uncommitted `chmod -x` or delete passes every push, though the commits still hold a `ci.sh`.
  - An uncommitted `DOCS_GLOB='*'` at line 53 turns the pushed commits' gate into `--docs`. Lines 23–26 admit this, yet line 50 promises "must cost time, never coverage".
  - fix: test `git cat-file -e "$tip:ci.sh"` for each tip, and take the mode from a tip's `ci.sh`, falling back to the full gate.

- [dim 2] `ci.yml:87`, `pre-push:40` — `mode=$(git diff --name-only "$base" "$head" | ./ci.sh --docs-mode)` — **A rename skips the gate.**
  - Rename detection lists only the new name, so `git mv packaging/install.sh packaging/install.md` reads as documentation-only and runs `--docs`.
  - It also drops the `packages` job. `ci.yml:65` promises the opposite direction.
  - fix: pass `--no-renames` in both places, and at `pre-push:37`.

- [dim 16] `release.yml:66` — `run: gh release upload "$TAG" "$RUNNER_TEMP"/release/* --clobber --repo "$GITHUB_REPOSITORY"` — **Replacing files is not all-or-nothing.**
  - A failure part-way through a re-run leaves a published release mixing files and sums from two builds. Floating images mean a rebuild can differ.
  - The same applies to two runs racing, because this workflow has no `concurrency`.
  - fix: add a concurrency group and refuse to replace a release that already has a complete set unless told to.

## Low / Info

**Low**

- [dim 7] `obs-status.sh:59` — `osc -A "$api" buildlog "$project" "$package" "$repo" "$arch" 2>&1 | tail -40`. Under `set -e` and `pipefail`, a target with no log (`unresolvable`, `broken`) stops the script at the first one. Later failures are never shown. The exit is still non-zero. fix: add `|| true`.
- [dim 16] `obs-status.sh:36-37` — rows are never compared with `targets`, so a target missing from the reply reads as done, and `excluded` passes at line 56. `--obs-check` catches this later.
- [dim 2] `obs-submit.sh:30` — `workdir=${OBS_WORKDIR:-$root/build-obs}` against § 4.7's "kept outside the tree". The document is the wrong side: the header, `CONTRIBUTING.md` and `.gitignore` all agree with the code.
- [dim 2] `obs-submit.sh:126-127` — only old tarballs are removed, so a `demoreel-rpmlintrc` dropped from the tree stays on OBS.
- [dim 9] `demoreel.bash:26` (and the zsh and fish copies) — `l.exec_module(d)` writes bytecode beside the script when the shell is root. That leaves an unowned `/usr/share/demoreel/__pycache__`, exactly the file INV-8 names. `-B` fixes it.
- [dim 3] `demoreel.bash:117` — `mapfile -t COMPREPLY < <(compgen -W \`. `compgen -W` expands its word list, so a run named `$(cmd)` would execute on Tab. Same user only. Whether `--name` restricts this is in Open questions. fix: match with `[[ ]]` in a loop.
- [dim 3] `ci.sh:1208` — `git fetch --quiet --no-tags origin "+refs/tags/$tag:refs/tags/$tag"` force-overwrites the maintainer's local tag, destroying the good copy a moved tag should be compared against. fix: fetch into a scratch ref.
- [dim 2] `SECURITY.md:112` — `**The files are the ones listed.**` `SHA256SUMS` sits on the same page, so alone it detects only corruption, not the swap DEMO-0084 § 2 item 1 names. The document is the wrong side. Say that only the attestation authenticates it.
- [dim 2] `SECURITY.md:139` — `source. Compare the two for a check that does not rest on the repository` gives no command, and the other checks all give one. The document is the wrong side.
- [dim 2] `DEMO-0068 § 4.1` — `#!/usr/bin/env python3` stays. `python3` is resolved from `PATH` by the shebang and by the completions, but `SECURITY.md`'s `PATH` boundary lists only the helpers. The document is the wrong side.
- [dim 17] `install.sh:40-47` — `--uninstall` removes the list in the checkout it runs from, so a file a newer version dropped stays behind, and created parent folders stay too. DEMO-0068 § 14 covers `~/.local/bin` shadowing but not a stale `/usr/local/bin/demoreel` ahead of the package.
- [dim 7] `ci.sh:1022` — `work=$(mktemp -d)` has no trap, so any early `return` or `set -e` exit (lines 1035–36) leaves it behind.
- [dim 9] `ci.sh:1404` — `cp "$perf_now" "$PERF_BASELINE"` is not temp-plus-rename, unlike `--pot` and `--add-message`.
- [dim 2] [tool: ruff] `ci.sh:1337` — `if os.path.exists(leftover):` breaches `python.md`'s `pathlib` idiom.

**Info**

- Not run, read only: `actions/checkout`, `gh`, `zypper` and the `git tag -v` name behaviour are from memory, and each is marked above.
- My first hidden-file search skipped `.gitignore` and `.claude/bump.json`. I re-ran it with `Grep`, and `publish_precheck` is present.
- The search for `--name` validation was cut at its `head_limit`, so that check is unrun.
- Other weighted dimensions: #2b found no contract-promised entry point without a caller among those I traced; `--verify-tag`, `--release-check`, `--signing-check`, `--obs-check` and `--perf` are all reached.
- N/A by weighting: #4, #5, #8, #10, #11, #12, #13, #15.

## Covered by spec and looks correct

- **Pull requests and forks (`ci.yml`):** it uses `pull_request`, never `pull_request_target`. Permissions are `contents: read` and `persist-credentials: false` is set on both jobs. Actions are pinned by commit. A pull request runs its own `ci.sh` and can turn its own check green, so that status depends on review. `$GITHUB_OUTPUT` takes pull-request output, but only `mode` is read and it arrives through `env`.
- **Tag name and release title:** the tag reaches shell only through `env` and quoted, and in `with:` otherwise. The release title and body are read nowhere. INV-6's grants sit only in the `release` job, as read in `release.yml`.
- **Root at install or removal:** none of the `.deb` control data, the `.rpm` spec or the `PKGBUILD` defines a maintainer script, scriptlet or `install=`. Only `sudo install.sh` from source runs as root, and it copies files. I did not inspect what `dh` generates on OBS.
- **`SHA256SUMS`:** `check_sums` holds to § 4.3, and an empty file fails. The attestation step's subject path covers every file, and it precedes the upload as § 4.4 requires.
- **`--signing-check`:** it matches § 4.2, and `release-signers` matches § 4.1's shape. `publish_precheck` is set.
- **Install layout:** `install.sh` matches § 4.1. The `.rpm` and Arch recipes both use it.
- **Completions:** the three shells offer the same options, compared with each other only and not with the parser.
- **`ci.sh` Python strings:** no `shell=True` and no bare `except`.

## Open questions

- Does `actions/attest` v4.2.2 produce SLSA provenance with no predicate input? `gh attestation verify` needs that by default. I cannot settle it from the tree, and only a real release exercises it.
- Is `--name` validated? My search was cut, and it decides the `compgen` finding.
- Does git export `GIT_DIR` to the pre-push hook? If it does, `git` calls in `ci.sh` inside the worktree would address the main checkout.
- Do the openSUSE image's repositories use plain `http`? That decides how far `--no-gpg-checks` is reachable by a network attacker.
- `SECURITY.md` does not say the signing key has no passphrase (DEMO-0084 § 3, by the user's decision). Is that worth disclosing?
- Context: `python.md` names demoreel as an example in its traps, so a required reading carried project text. I used none of it as a finding.

## 3 items to fix first

1. **Bind the tree to the tag and the tag to the attestation** (`release.yml:29`, `SECURITY.md:127`, `ci.sh:1204`). Today a repository writer can pass all three published checks with malicious files, which is the whole promise of `SECURITY.md`'s section. The fix is two small changes.
2. **Stop test containers reaching the release files** (`ci.sh:1073`, `ci.sh:869`). Whatever they alter gets hashed and attested as genuine, so one bad package in any of five distros poisons a signed-looking release.
3. **Add `-I -B` to the completions' `python3`** (all three shells). It is a one-word fix for code execution on Tab, shipped to every installed user, and it also removes the INV-8 leftover.
