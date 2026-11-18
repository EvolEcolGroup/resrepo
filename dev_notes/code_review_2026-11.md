# resrepo code review, November 2026

## Summary

- **Branch:** `codereview` (local, not pushed), from `dev` at `df64f6d`
  (Merge pull request #63).
- **Fix commits:** 22: 17 from the review (13 with a regression test, 4
  documentation or messages only), then 5 after the verifying agents'
  reports (three corrections of earlier fixes, a stronger test, and a
  further bug in `knit_to_results()`).
- **Decision commits:** 14, after Andrea took the 12 decisions on 18 Nov
  2026: one per decision (11 with a regression test, 1 removal) and two
  lint fixes; then 10 corrections after a verifying agent's report (one
  serious: a possible loss of all versions in `d0b293c`).
- **Findings not fixed:** 10 minor ones; no decision is pending.
- **Optional branches:** none.

The most serious finding: after any `git checkout` or `git merge`, which runs
resrepo's own git hooks, `version_add()` stopped with "The link to the raw
data is incorrect", so the versioning workflow in the vignette broke as soon
as the user switched branch with git (`b564e56`). Several other fixes are in
`version_add()`, which could leave a half-made version on a new branch, or
nest a copy inside an existing version.

## Verification

Run on the tip of `codereview` (`2bf57de`, after the review fixes, the
decisions and their corrections), installed with `R CMD INSTALL` into its
own library, R 4.6.1 on laptopX1, 18 Nov 2026. (At `5dff711`, the end of
the review fixes, the suite had 128 expectations, all passing.)

| Check | Result |
|---|---|
| Full test suite (`NOT_CRAN=true`, installed package) | 211 expectations, 0 failures, 0 errors, nothing skipped (`test_data_dir_follow_ignore.R`, always skipped on `dev`, was removed with its functions in `8c26a2d`) |
| Same suite on `dev` (`df64f6d`), before the fixes | 87 expectations, 0 failures; same file skipped |
| `lintr::lint_package()` | no lints |
| Rd examples (`devtools::run_examples(run_donttest = TRUE)`) | nothing to run: no Rd file has `\examples` |
| Vignettes (`resrepo`, `data_versioning`, `sharing_resrepo`), rendered with the installed tip | all render; `sharing_resrepo` now makes the links, with the `versions/` layout of decision 3. One warning, as before: its `\VignetteIndexEntry` differs from its title |
| Each test fails on the code before its fix, and passes on the fix | checked for every commit with a test, by the author and again by a separate verifying agent (see below) |
| Windows, macOS, other R versions | not run: CI runs only on `main`, `dev` and PRs into them, so not on `codereview` (pushed without a PR). `b564e56` relies on `fs::path_real()` resolving the Windows junctions made by the hooks (expected, as libuv resolves them, but untested): push the branch and check the windows-latest job before merging |

Exceptions to "each test fails before the fix": `48916d6` and `e62700d` have
no test (the changed code runs only in interactive sessions: `interactive()`
cannot be mocked, and the RStudio fallback needs RStudio); `5a9d9de`,
`b7e5320` and `b06f7df` change only documentation, messages or a vignette;
`3267ddf` changes only a test (its new expectations fail on the code before
`98302a0`).

The "clone a versioned repo" test clones `EvolEcolGroup/resrepo_penguins`
from GitHub, so the suite needs a network connection.

roxygen2 8.1.0 is installed here, while the package declares 7.3.3: running
`devtools::document()` also rewrites `RoxygenNote` in `DESCRIPTION` and adds
an "Authors" list to `man/resrepo-package.Rd`. These changes were left out of
the commits, which keep the 7.3.3 output.

## How the review was done

- Read all the R code (`R/`), the git hooks (`inst/githooks/`), the
  templates (`inst/template/`, `inst/rmarkdown/`), the tests and the three
  vignettes. The package has no compiled code.
- Confirmed every suspected bug with a small script against `dev` installed
  in its own library, before fixing it. One suspicion was not confirmed:
  re-knitting does update the figures in `results/<name>/<name>_files/`
  (`file.copy(recursive = TRUE)` overwrites).
- One commit per fix on `codereview`, each with its regression test in the
  existing test files, the regenerated `man/` pages and a `NEWS.md` line. Each
  new test was run on the code before the fix (old code, new tests) and on
  the fix.
- A separate agent then checked every commit independently: tests failing on
  the parent and passing on the commit, and the correctness and scope of
  each diff. It confirmed all 13 tests, and found two problems in the fixes
  (`a6b27c0` broke running the template chunk in RStudio; `ead9ce2` checked
  `raw_source` even when it is ignored), one expectation that passed on the
  old code (`98302a0`), and a further bug (dotted Rmd names). These were
  fixed in `e62700d`, `0b58fea`, `3267ddf` and `5d1c1a3`. A second agent
  checked these four: `5d1c1a3` broke Rmd names with spaces, corrected in
  `5dff711` (with the approach the agent suggested), which it then checked
  too.
- The message of `98302a0` gives `versions/initial/initial` as the example of
  the nested copy; the copy is in fact nested under the name of the source
  version (`versions/initial/new_filtering` in its test).
- No fix touches a hot path (the package has none), so there are no
  benchmarks.

## Changes in behaviour to check before merging

### Changes from the review fixes

- `path_resrepo(path, version = )` returns `versions/<version>/raw/...`
  instead of `versions/<version>/data/raw/...` (`03bfaf8`). The old path never
  existed, and the existing test asserted it.
- `path_relative()` returns `"."` instead of `""` when `path` is `base`, and
  drops a trailing slash (`0fbfeb0`).
- `version_add()` now stops, before creating the branch, when
  `raw_new_version` is given without `raw_description`, when a new version
  name already exists, or when a source version does not hold the data to
  copy (`1bf52cc`, `98302a0`, `ead9ce2`).
- `version_add()` pushes only to `origin`; a repository whose only remote has
  another name is now treated as having no remote (no push) instead of
  failing at the push (`60ca45e`).
- HTTPS pushes use the username "PersonalAccessToken" when the token comes on
  its own (e.g. from `GITHUB_PAT`) (`2a44fa6`).
- `version_relink()` on a cloned repository uses `<resources_path>/versions`
  when it exists, and `resources_path` itself otherwise (`5c6c900`).
- `update_links()` no longer deletes and recreates links that are already
  correct, so it no longer says "Links updated" every time (`b564e56`).
- `knit_to_results()`: the files in `results/<name>/` now have the names
  rmarkdown gives them. For names with spaces or shell characters these
  differ from the Rmd's: `my file.Rmd` gives `results/my file/my-file.html`
  (was `my file.html`), as RStudio's own Knit button does (`5d1c1a3`,
  `5dff711`).

### Changes from the decisions (18 Nov 2026)

- `init_resrepo()` no longer overwrites existing files, and commits only the
  files it creates; it stops if other changes are staged (`6669c9b`).
- `init_resrepo(path)` initialises the repository at `path`;
  `version_add(path = )` warns that `path` is deprecated (`1883fff`).
- `resources_path` must be the directory holding `versions/` (or `versions/`
  itself), outside the repository. `version_relink()` stops when the versions
  in use are missing (`create = TRUE` creates them, empty), and
  `version_setup()` refuses storage that already holds versions. The
  sharing vignette's layout gains a `versions/` level (`bb01531`).
- `version_add()` errors before the push are undone, and a failed push is a
  warning (the version is kept) instead of an error (`d0b293c`).
- Existing `post-checkout`/`post-merge` hooks are renamed `<hook>.local` and
  run by resrepo's hooks (`8ccdc9d`).
- New links from `data/` to `versions/` are relative (not on Windows); the
  error for a wrong link says to run `update_links()` (`a57dea6`).
- `version_add(push = )` is new; local, `file://` and `http://` remotes are
  pushed to (`149deac`).
- `version_relink()` may commit `.gitignore` (`versions` → `/versions`) in
  repositories set up by older versions (`bd3e521`).
- `knit_to_results()` moves outputs of every format, and `.tex` files
  (`23912b7`).
- A repository whose `DESCRIPTION` says `Package: resrepo` is refused, whatever
  its folder's name (`5ad3257`).

## Fixes by area

### Data versioning

- [ ] `b564e56` · `get_versions_in_use()`, `version_add()`, `update_links()` — links made by resrepo's git hooks (relative) were rejected as incorrect, so `version_add()` failed after any `git checkout` or `git merge`; `update_links()` always recreated the links *[high: breaks the documented workflow]*
- [ ] `1bf52cc` · `version_add()` — arguments checked only after creating and pushing the branch; a missing `raw_description` crashed half-way, leaving a new branch, new directories and an untracked meta file *[medium]*
- [ ] `98302a0` · `version_add()` — an existing version name (with another branch name) was copied inside the existing version, and its meta file overwritten *[medium: corrupts the version store]*
- [ ] `3267ddf` · test of `98302a0` — one expectation passed on the old code; the test now checks that the existing version and its meta file are untouched *[test only]*
- [ ] `ead9ce2` · `version_add()` — new intermediate versions also got a copy of the source version's raw data *[low–medium: duplicates possibly large data]*
- [ ] `0b58fea` · `version_add()` — correction of `ead9ce2`: `raw_source` was checked for raw data even without `raw_new_version`, when it is ignored; clearer messages for a source without the data to copy *[low]*
- [ ] `5c6c900` · `version_relink()`, `version_setup_cloned()` — on a clone, a `resources_path` holding `versions/` was linked as the versions themselves, so the links pointed to new, empty directories *[medium: data silently not found]*
- [ ] `8a4a7fc` · `version_setup()`, `version_relink()` — the repository root was accepted as `resources_path` when run from a subdirectory; `version_setup()` then made `versions/` a link to itself and failed half-way *[low]*
- [ ] `48916d6` · `version_setup()` — cancelling the backup question went ahead with moving the data *[low]* (no test: interactive only)

### Git remotes and credentials

- [ ] `60ca45e` · `get_resrepo_git_creds()`, `version_add()` — failed with "the condition has length > 1" in repositories with more than one remote *[medium]*
- [ ] `61b0510` · `get_resrepo_git_creds()` — `ssh://` remote urls were rejected as unsupported *[low]*
- [ ] `2a44fa6` · `get_resrepo_git_creds()` — empty https credentials when the token is in `GITHUB_PAT`/`GITHUB_TOKEN`, is a bare token, or the remote is not on github.com *[medium: pushes fail]*

### Paths

- [ ] `03bfaf8` · `path_resrepo()` — paths with `version` pointed to `versions/<v>/data/...`, which does not exist *[medium]*
- [ ] `0fbfeb0` · `path_relative()` — wrong result for directories sharing the start of their name (`../d/file` for `../abd/file`); error on names with `(` or `[` *[low–medium]*

### Knitting and the Rmd template

- [ ] `8a53554` · `knit_to_results()` — moved other files whose names end with the Rmd's name (e.g. `notes_test.md` for `test.Rmd`) to `results/`, renamed them `README.md`, or crashed with two `.md` files *[medium]*
- [ ] `5d1c1a3` · `knit_to_results()` — an Rmd with a dot in its name (`s01.v2.Rmd`) was rendered to `code/s01.v2`, with no extension, which stayed in `code/` *[low–medium]*
- [ ] `5dff711` · `knit_to_results()` — correction of `5d1c1a3`: Rmd names with spaces or shell characters (`my file.Rmd`), which rmarkdown knits as `my-file`, were left in `code/`; the outputs are now found from the path `render()` returns *[medium]*
- [ ] `a6b27c0` · template of `create_rmd()` — could only be knitted in an interactive RStudio session ("RStudio not running") *[medium]*
- [ ] `e62700d` · template of `create_rmd()` — correction of `a6b27c0`: running the chunk in RStudio (not knitting) failed, as `knitr::current_input()` is then NULL; it falls back to the open file *[low]* (no test: RStudio only)

### Documentation and messages

- [ ] `5a9d9de` · `get_versions_in_use()`, `version_add()`, `init_mirror()`, template, DESCRIPTION — wrong return type, argument names, title and argument description, output file name, a typo *[docs]* (no test)
- [ ] `b7e5320` · `data_dir_link()`, `data_dir_ignore()`, `init_mirror()` — typos in error messages (`/n`, `data_dir_ingore`, words run together) *[messages]* (no test)
- [ ] `b06f7df` · vignette `sharing_resrepo` — used `version_setup()` on a cloned repository, which only prints a message, so the links were never made *[docs]* (no test; vignette rendered)

### Decisions implemented

Commits made after Andrea's decisions of 18 Nov 2026 (section "Decisions"
below), one per decision, each with its test, plus two lint fixes.

- [ ] `6669c9b` · `init_resrepo()` — decision 1: keeps an existing project's files and `.gitignore` (appending missing rules), commits only what it created, stops if other changes are staged *[high: could commit secrets]*
- [ ] `1883fff` · `init_resrepo()`, `version_add()` — decision 2: `init_resrepo(path)` works on the repository at `path`; `path` in `version_add()` is deprecated, with a warning *[medium]*
- [ ] `bb01531` · `version_setup()`, `version_relink()` — decision 3: `resources_path` always holds `versions/` (or is it); relinking stops on missing versions unless `create = TRUE`; paths inside the repository refused; `version_setup()` refuses storage that already holds versions *[high: data silently not found]*
- [ ] `d0b293c` · `version_add()` — decision 4: copies first, pushes last, undoes everything on an error before the push; a failed push keeps the version, with a warning *[high]*
- [ ] `8ccdc9d` · `version_setup()`, `version_relink()`, git hooks — decision 5: hooks installed where git looks for them (worktrees, submodules, `core.hooksPath`); existing hooks kept as `<hook>.local` and run first *[medium]*
- [ ] `a57dea6` · `data_dir_link()`, `update_links()`, `get_versions_in_use()` — decision 6: links inside the repository are relative (not on Windows); the error says to run `update_links()` *[medium]*
- [ ] `149deac` · `version_add()`, `get_resrepo_git_creds()` — decision 7: new `push = TRUE`; remotes on local paths, `file://` and `http://` are pushed to without credentials *[medium]*
- [ ] `3b15789` · `version_add()` — decision 8: same-name raw and intermediate versions keep both rows in their meta file *[low]*
- [ ] `bd3e521` · `version_setup()`, `version_relink()` — decision 9: `.gitignore` gets `/versions`; relinking corrects older set-ups and commits `.gitignore` when that can be done on its own *[low]*
- [ ] `23912b7` · `knit_to_results()` — decision 10: moves the output of any format, and the `.tex` of `keep_tex` *[low–medium]*
- [ ] `8c26a2d` · `data_dir_follow()`, `is_data_dir()` — decision 11: removed (unused, internal), with their skipped or obsolete tests *[cleanup]* (no test)
- [ ] `5ad3257` · `find_git_root()` — decision 12: the package source is also recognised by its `DESCRIPTION` *[low]*
- [ ] `2ca1158`, `48055f5` · tests — line length and trailing blank line lints introduced by `5ad3257` and `6669c9b` *[lint]* (no test)

### Corrections of the decision commits

A separate agent checked the 14 decision commits: all their tests fail
before and pass after, but it found the problems below, one of them
serious (a reserved version name made the undo of `d0b293c` delete every
version). Each is corrected in its own commit.

- [ ] `6e4f920` · `version_add()` — names reserved by the file system (`aux`, `con`, `..`) became empty and pointed to `versions/` itself, which the undo of `d0b293c` then deleted with all the data; such names are refused, and the undo removes only new directories strictly inside `versions/` *[high: data loss, introduced by `d0b293c`]*
- [ ] `bcfab8c` · `version_add()` — the undo failed on a detached HEAD (losing the original error), stopped at its first failing step, and did not run on interrupts; now a detached HEAD is refused, the undo runs from `on.exit()`, each step is guarded and failures are listed in a warning *[medium]*
- [ ] `80d7872` · git hooks — installed through a shared `core.hooksPath`, they made `git checkout` fail in every other repository; they now do nothing without `data/version_meta/`, and installing them outside the git directory gives a warning *[medium, introduced by `8ccdc9d`]*
- [ ] `d815594` · `version_relink()` — a documentation paragraph had become part of `@param quiet` *[docs]* (no test)
- [ ] `f021892` · `resources_versions_path()` — the name of `resources_path` was read after resolving links *[low]*
- [ ] `820213a` · `link_target()` — links to external storage kept a relative `resources_path` as given (breaking on moves, and wrong from a subdirectory); they are now absolute *[low–medium]*
- [ ] `c2841d1` · `knit_to_results()` — `23912b7` also moved a user's own `<name>.tex` (or `.md`, `.html`...); extra files are now moved only if written since the knitting started *[medium]*
- [ ] `aa02670` · `init_resrepo()` — an uncommitted `.gitignore` edit was committed; a second call failed with "Nothing added to commit"; the vignette chunk that resets the example could wipe the working directory if run by hand *[low]*
- [ ] `30686be` · tests — trailing blank line lint from `f021892` *[lint]* (no test)
- [ ] `2bf57de` · `knit_to_results()` — `c2841d1` told the knitting's files from the user's by comparing times with its start, which fails with clock skew or coarse file times; it now compares snapshots of the folders taken before and after *[low]*

The same agent then checked these corrections: every test fails before and
passes after, and its probes (interrupts during `version_add()`, reserved
names with local and external `versions/`, shared hooks, relative
`resources_path` from a subdirectory, fast knits) pass at the tip.

## Decisions taken

These were the findings that needed a decision. Andrea took them on 18 Nov
2026 (the recommended options, except for decision 12), and each is
implemented in the commit named under its heading (listed in "Decisions
implemented" above). The text below describes the behaviour before those
commits.

Each decision says what happens now (the consequences marked "tested" were
reproduced on `codereview` on 18 Nov 2026), who is affected, the options
with their consequences, and a recommendation. The first five can lose,
expose or misplace data.

#### 1. `init_resrepo()` on a project that already has files

**Decided (Andrea, 18 Nov 2026):** b; implemented in `6669c9b`.

**Now (tested).** In a repository with its own `README.md`, a `.gitignore`
that ignores `.Renviron` and `big_data/`, an uncommitted edit and an
untracked script, `init_resrepo()`:

- replaced `README.md` (and the other `README.md` files) with the template's;
- replaced `.gitignore` entirely, so the user's ignore rules were lost;
- committed everything in one "Initialise resrepo" commit: `.Renviron` with
  its token, `big_data/huge.csv`, the half-edited `README.md` and the
  work-in-progress script. Once pushed, the token is in the remote history.

**Who.** Anyone converting an existing project, a natural use; a new, empty
repository is unaffected.

**Options.**

- **a. Refuse** unless the repository is empty. Safest and simplest;
  converting a project means starting a new repository and moving the
  files in.
- **b. Merge without destroying anything:** copy only the template files
  that do not exist, append the template's `.gitignore` lines to an
  existing `.gitignore`, and add and commit only the files `init_resrepo()`
  created. Converting works; the user's files and work in progress are left
  alone.
- **c. Keep, and warn** (or ask, interactively). Still dangerous in scripts.

**Recommended:** b, with a message listing the files that were kept.

#### 2. `path` is ignored by `init_resrepo()` and `version_add()`

**Decided (Andrea, 18 Nov 2026):** b; implemented in `1883fff`.

**Now.** `init_resrepo("~/new_project")` initialises the repository of the
working directory instead (with the consequences of decision 1 if it has
files), or stops with "not a git repository". In `version_add()`, `path` is
unused, and as the first argument it catches a positional name:
`version_add("v2", intermediate_description = "...")` stops with "You must
provide a name for the new intermediate version" (tested).

**Options.**

- **a. Implement `path` in both** (work in that repository for the call).
- **b. Implement it in `init_resrepo()`, deprecate it in `version_add()`**:
  warn when it is given, remove it later, so that the version name can come
  first. All the other versioning functions work on the working directory.
- **c. Remove both now**: breaks code that names `path =`.

**Recommended:** b.

#### 3. What `resources_path` means, and empty folders made silently

**Decided (Andrea, 18 Nov 2026):** a; implemented in `bb01531`.

**Now.** Three rules for one argument:

- `version_setup()` creates `<resources_path>/versions`;
- `version_relink()` on a repository with links needs
  `<resources_path>/versions`, or `resources_path` itself named `versions`;
- `version_relink()` on a fresh clone uses `<resources_path>/versions` if it
  exists, otherwise `resources_path` itself, and **creates the versions in
  use if they are missing**.

Consequences:

- **Tested:** relinking a clone to an empty folder (a typo, or the wrong
  drive) returns `TRUE` and creates empty `starting/raw` and
  `initial/intermediate` in it. Scripts then read no data, or write their
  outputs to the wrong place, without any warning.
- The layout of the sharing vignette (the versions directly in the folder)
  is accepted for a clone, but a later relink of the same repository
  rejects it ("…/versions does not exist").
- A `resources_path` inside the repository is accepted, where the data
  would not be ignored by git.

**Options.**

- **a. One rule:** `resources_path` holds `versions/` (a folder named
  `versions` is also accepted). Relinking stops if a version in use is
  missing, unless asked to create it (e.g. `create = TRUE`, for new empty
  storage). Refuse folders inside the repository, and update the sharing
  vignette. Users who followed the vignette's layout need to add a
  `versions/` level.
- **b. One rule the other way:** `resources_path` is the versions folder
  itself.
- **c. Keep the flexible rules**, but stop instead of creating missing
  versions.

**Recommended:** a; at least the stop of c.

#### 4. `version_add()` can stop half-way

**Decided (Andrea, 18 Nov 2026):** c; implemented in `d0b293c`.

**Now.** The steps run in this order:

1. create the branch, switch to it and push it;
2. copy the data (possibly gigabytes; can fail on a full disk or
   permissions);
3. write the meta files, delete and recreate the links;
4. commit and push.

An error after step 1 leaves the user on the new branch, perhaps with an
empty branch on GitHub, a partial copy in `versions/`, and possibly no
`data/raw` link at all (it is deleted before being recreated). Running it
again with the same name fails ("branch already exists" or "version already
exists"). Recovery is by hand: switch back, delete the branch locally and
on GitHub, delete `versions/<name>`, run `update_links()`.

**Options.**

- **a. Document the recovery.**
- **b. Reorder:** checks, then the copy, before touching git; then the branch,
  links and commit; push once, at the end. Most failures then happen
  before anything in git changes.
- **c. b, plus undo on error:** switch back to the old branch, delete the new
  local branch and folders, restore the links (never delete a branch on
  GitHub automatically).

**Recommended:** c (b is most of the work).

#### 5. Git hooks: other tools' hooks, and worktrees

**Decided (Andrea, 18 Nov 2026):** a and b; implemented in `8ccdc9d`.

**Now.**

- `version_setup()` and `version_relink()` copy `post-checkout` and
  `post-merge` into `.git/hooks`, replacing what is there. git-lfs installs
  hooks with these names (as do other tools), which then silently stop
  running.
- **Tested:** in a git worktree or a submodule, where `.git` is a file,
  `version_setup()` fails at its very last step ("Failed to make directory
  …/.git: file already exists"), after moving the data and making its two
  commits. The set-up is otherwise complete, but without the hooks later
  checkouts do not update the links.
- A custom `core.hooksPath` is ignored.

**Options.**

- **a.** Find the hooks folder with `git rev-parse --git-path hooks`
  (handles worktrees, submodules and `core.hooksPath`).
- **b.** When a different hook is already there, keep it: rename it (e.g.
  `post-checkout.local`) and have resrepo's hook call it.
- **c.** Back up the existing hook and warn.

**Recommended:** a and b.

#### 6. Absolute links

**Decided (Andrea, 18 Nov 2026):** b, with the clearer error message; implemented in `a57dea6`.

**Now.** R makes absolute links (`data/raw -> /home/me/proj/versions/starting/raw`),
the git hooks relative ones (`../versions/starting/raw`); which kind a
repository has depends on the last command run.

**Tested:** after moving or renaming the repository's folder, `data/raw`
points nowhere: scripts no longer find the data, and `version_add()` stops
with "The link to the raw data is incorrect" until `update_links()` is run,
which repairs the links. The same happens when the folder is reached through
another path (a container, a drive mounted elsewhere). This concerns macOS
and Linux only: Windows junctions are always absolute.

**Options.**

- **a. Keep absolute links;** document "run `update_links()` after moving the
  repository", and say so in the error message.
- **b. Relative links in R too,** for `data/raw` and `data/intermediate` only
  (the link from `versions` to external storage stays absolute). Moving the
  repository then just works.

**Recommended:** b, plus the clearer error message.

#### 7. Remotes and pushing in `version_add()`

**Decided (Andrea, 18 Nov 2026):** c; implemented in `149deac`.

**Now.** `version_add()` always pushes the new branch to `origin`, and first
needs credentials for it:

- an `origin` that is a local path or `file://` (a bare repository on a shared
  drive), or `http://`, stops it with "Unsupported Git URL format": it cannot
  be used at all;
- an `https://` origin without a token stops it with "You don't have a PAT
  set up", even when only a local version is wanted (offline, or no right to
  push);
- branches are always pushed, e.g. to a public repository.

**Options.**

- **a.** Add `push = TRUE`; with `FALSE`, no credentials and no push.
- **b.** For other urls, push without credentials (works for local and
  `file://` remotes; `http://` fails with a clear git error).
- **c.** Both.

**Recommended:** c; the default stays as now.

#### 8. Raw and intermediate versions with the same name

**Decided (Andrea, 18 Nov 2026):** b; implemented in `3b15789`.

**Now.** `version_add(intermediate_new_version = "v2", raw_new_version = "v2")`
is accepted. Both descriptions go to `data/version_meta/v2.meta`, and the raw
one overwrites the intermediate one, which loses its description and date.
Nothing in the package reads these files, so only the record is lost; the
vignette already discourages new raw versions.

**Options.**

- **a.** Refuse equal names.
- **b.** Write both rows to `v2.meta` (same columns; the `data` column tells
  them apart).
- **c.** Separate files (`v2_raw.meta`): a new format.

**Recommended:** b (or a, if distinct names are preferred).

#### 9. `versions` in `.gitignore`

**Decided (Andrea, 18 Nov 2026):** a and b; implemented in `bd3e521`.

**Now.** `version_setup()` adds the line `versions`, which matches a file or
folder called `versions` anywhere. **Tested:** `results/versions/table.csv` is
invisible to git: never committed, with no warning.

**Options.**

- **a.** Write `/versions` (the root only) in new set-ups: a one-character
  change.
- **b.** Also correct existing repositories (e.g. when relinking).

**Recommended:** a, and b (cheap).

#### 10. Outputs left in `code/`

**Decided (Andrea, 18 Nov 2026):** a; implemented in `23912b7`.

**Now.** `knit_to_results()` moves `.html`, `.pdf`, `.md`, `.docx` and the
`_files` folder. **Tested:** with `keep_tex`, the `.tex` stays in `code/`;
`.pptx`, `.odt`, `.rtf` and `.epub` outputs are not moved at all, so
`results/<name>/` stays empty and the outputs pile up in `code/`, where they
get committed.

**Options.**

- **a.** Move the file that `render()` returns (its path is now known, since
  `5dff711`), plus the `.md` (`keep_md`), the `.tex` (`keep_tex`) and the
  `_files` folder.
- **b.** Add extensions to the list.

**Recommended:** a.

#### 11. `data_dir_follow()`, `data_dir_ignore()`, `is_data_dir()`

**Decided (Andrea, 18 Nov 2026):** a; implemented in `8c26a2d`.

**Now.** Internal functions. `data_dir_ignore()` works for the three calls
`version_setup()` makes, but its check for tracked files is broken in
general; `data_dir_follow()` and `is_data_dir()` are unused; their test file
is skipped. Nothing visible to users today, but misleading code and tests.

**Options.**

- **a.** Delete the unused functions and the skipped test; keep
  `data_dir_ignore()` as `version_setup()` needs it.
- **b.** Fix them and enable the tests, if tracking subfolders of `data/` is a
  planned feature.

**Recommended:** a, unless the feature is planned.

#### 12. Repositories named `resrepo`

**Decided (Andrea, 18 Nov 2026):** refuse when the folder is called resrepo **or** the DESCRIPTION says `Package: resrepo` (Andrea's variant of b); implemented in `5ad3257`.

**Now.** Every function stops with "this name is reserved" when the
repository's folder is called `resrepo` (meant to protect the package's own
source). A user who names a project `resrepo`, e.g. following a tutorial,
cannot use the package at all.

**Options.**

- **a.** Keep, and document it.
- **b.** Recognise the package's source itself (a `DESCRIPTION` with
  `Package: resrepo` at the root) instead of the folder's name.

**Recommended:** b.

## Findings not fixed

### Minor

- `init_mirror()`: `length(list.files(mirror_path) != 0)` has a misplaced
  parenthesis; it works only because the length of the comparison equals the
  number of files.
- Vignette `data_versioning`, hidden chunk `git_merge`: it runs
  `git merge new_filtering` while still on `new_filtering`, then checks out
  `main`, so `main` never gets the merge. The chunk's output is hidden, so
  the rendered vignette does not show it.
- `path_resrepo()`: the shortcuts (`/d/r/`, `/c/`, ...) work only with a
  leading slash, and paths with a leading slash give a double slash in the
  result (`.../repo//data/raw`), which works but looks odd and defeats string
  comparisons.
- `version_setup()` on an already versioned repository returns `NULL` (from
  `message()`), while its documentation says it returns `TRUE` on success.
- `update_links()` prints "Links updated" only when the raw link is made, not
  the intermediate one.
- `test_versioning.R` ("versioning") prints a link with `cat()`, which adds
  noise to the test output.
- The `\VignetteIndexEntry` of `sharing_resrepo` ("Sharing a resrepo
  repository") differs from its title, which gives a warning when it is
  rendered.
- Links made absolute by older versions of resrepo that still resolve are
  left absolute by `update_links()`; they become relative at the next
  checkout, merge or `version_add()` (found by the verifying agent).
- `init_resrepo()` commits a `.gitignore` that the user created but never
  committed (untracked), with resrepo's rules added; only a tracked
  `.gitignore` with uncommitted changes is left to the user (found by the
  verifying agent; probably acceptable).
- `version_relink()` in a fresh clone of a repository set up by an older
  resrepo commits the `.gitignore` correction (`versions` → `/versions`)
  locally, so the clone is one commit ahead of origin (as decided in 9b).
- `knit_to_results()` on an Rmd whose name has spaces or shell characters
  (e.g. `my file.Rmd`), run from a working directory other than the Rmd's
  folder (e.g. from a script): rmarkdown knits its renamed copy in the
  working directory, so the outputs reach `results/my file/` but the
  figures are lost and README.md's links do not resolve (on `dev`, all the
  outputs stayed in the working directory). The verifying agent found that
  passing `intermediates_dir = dirname(input_file)` to `rmarkdown::render()`
  fixes it, with no change for other names.
