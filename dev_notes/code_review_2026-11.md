# resrepo code review, November 2026

## Summary

- **Branch:** `codereview` (local, not pushed), from `dev` at `df64f6d`
  (Merge pull request #63).
- **Fix commits:** 22: 17 from the review (13 with a regression test, 4
  documentation or messages only), then 5 after the verifying agents'
  reports (three corrections of earlier fixes, a stronger test, and a
  further bug in `knit_to_results()`).
- **Findings not fixed:** 12 needing a decision, and 9 minor ones.
- **Optional branches:** none.

The most serious finding: after any `git checkout` or `git merge`, which runs
resrepo's own git hooks, `version_add()` stopped with "The link to the raw
data is incorrect", so the versioning workflow in the vignette broke as soon
as the user switched branch with git (`b564e56`). Several other fixes are in
`version_add()`, which could leave a half-made version on a new branch, or
nest a copy inside an existing version.

## Verification

Run on the tip of `codereview` (`5dff711`), installed with
`R CMD INSTALL` into its own library, R 4.6.1 on laptopX1, 18 Nov 2026.

| Check | Result |
|---|---|
| Full test suite (`NOT_CRAN=true`, installed package) | 128 expectations, 0 failures, 0 errors; `test_data_dir_follow_ignore.R` skipped (it starts with `skip()`, as on `dev`) |
| Same suite on `dev` (`df64f6d`), before the fixes | 87 expectations, 0 failures; same file skipped |
| `lintr::lint_package()` | no lints |
| Rd examples (`devtools::run_examples(run_donttest = TRUE)`) | nothing to run: no Rd file has `\examples` |
| Vignettes (`resrepo`, `data_versioning`, `sharing_resrepo`), rendered with the installed tip | all render; `sharing_resrepo` now makes the links. One warning, as before: its `\VignetteIndexEntry` differs from its title |
| Each test fails on the code before its fix, and passes on the fix | checked for every commit with a test, by the author and again by a separate verifying agent (see below) |
| Windows, macOS, other R versions | not run: `codereview` is not pushed, so CI has not run on it. `b564e56` relies on `fs::path_real()` resolving the Windows junctions made by the hooks (expected, as libuv resolves them, but untested): push the branch and check the windows-latest job before merging |

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

## Findings not fixed

### Decision needed

- **`path` arguments that are ignored.** `init_resrepo(path = ".")` and
  `version_add(path = ".")` never use `path`: both work on the repository of
  the working directory, so `init_resrepo("other/repo")` silently initialises
  the current one. **Decision needed:** implement `path` (switch to it for
  the call, with `on.exit()`), or deprecate it? Suggested: implement it in
  `init_resrepo()`, deprecate it in `version_add()` (the other versioning
  functions all use the working directory).
- **`init_resrepo()` in an existing repository** copies the template with
  `overwrite = TRUE` (replacing the user's `README.md`, `code/README.md`, etc.),
  renames the template `gitignore` over an existing `.gitignore`, then runs
  `git2r::add(path = ".")` and commits everything, including any untracked
  data or secrets under the working directory. **Decision needed:** refuse
  to run in a repository that already has files, or skip existing files and
  add only the template's files?
- **Absolute and relative links.** R makes absolute links
  (`data/raw -> /home/.../versions/starting/raw`), the git hooks relative ones
  (`../versions/starting/raw`). Absolute links break when the repository is
  moved, or opened through another mount point. After `b564e56` both are
  accepted. **Decision needed:** make R create relative links too?
- **A raw and an intermediate version with the same name** (allowed by
  `version_add(intermediate_new_version = "v2", raw_new_version = "v2")`)
  share `data/version_meta/v2.meta`: the raw row overwrites the intermediate
  one. **Decision needed:** refuse equal names, or write both rows to the
  meta file?
- **Remotes that are local paths, `file://` or `http://` urls** (e.g. a bare
  repository on a shared drive) stop `version_add()` with "Unsupported Git
  URL format",
  and an https remote without a token stops it even if no push is wanted.
  **Decision needed:** push to such remotes without credentials, and/or add a
  `push = TRUE` argument?
- **`version_add()` is not atomic.** If the push, or a copy, fails after the
  branch is created, the user is left on the new branch with a partial
  version (`1bf52cc` moved the argument checks before this point, but I/O
  and network errors remain). **Decision needed:** roll back on error
  (return to the old branch, delete the new branch and directories)?
- **What `resources_path` means.** `version_setup()` creates
  `<resources_path>/versions`; `version_reset()` (relink with existing links)
  accepts `<resources_path>/versions` or a directory named `versions`;
  `version_setup_cloned()` (after `5c6c900`) accepts `<resources_path>/versions`
  or the directory of the versions under any name, as in the sharing
  vignette. A `resources_path` inside the repository (other than its root)
  is accepted. **Decision needed:** one rule for all three, documented once?
- **Git hooks.** `add_git_hooks()` overwrites any existing `post-checkout` and
  `post-merge` hooks of the user; it assumes `.git` is a directory (wrong in
  worktrees and submodules, where `.git` is a file); the hooks print an
  error when checking out a commit from before versioning (no meta files);
  meta files with Windows line endings would give version names ending in
  `\r` in bash. (On Windows, the hooks remove the junctions with `rm -rf`;
  the Windows CI run of `dev` on 16 Nov passes the "versioning" test, which
  reads the data of the version the junction pointed to after the hook ran,
  so `rm -rf` removes only the junction.) **Decision needed:** append to
  existing hooks rather than overwrite them?
- **`data_dir_ignore()`, `data_dir_follow()`, `is_data_dir()`.** Their tests
  are skipped (`skip()` at the top of `test_data_dir_follow_ignore.R`); the
  guard in `data_dir_ignore()` sees only files directly in the directory, and
  never matches a path with a leading slash (as used in its tests), because
  `git2r::ls_tree()` paths have none; `is_data_dir("/data")` fails with
  "missing value where TRUE/FALSE needed"; `data_dir_follow()` and
  `is_data_dir()` are not used by the package. **Decision needed:** fix them
  and enable the tests, or remove the unused functions?
- **`versions` in `.gitignore`.** `version_setup()` adds `versions` (not
  `/versions`) to `.gitignore`, which ignores any file or directory named
  `versions` anywhere in the repository (e.g. `code/versions/`).
  **Decision needed:** write `/versions` for new set-ups?
- **Outputs left in `code/`.** `knit_to_results()` moves only `.html`, `.pdf`,
  `.md`, `.docx` and `<name>_files/`; other outputs (`.tex` with `keep_tex`,
  `.pptx`, `.odt`, `.rtf`, `.epub`) stay next to the Rmd. **Decision needed:**
  move whatever `rmarkdown::render()` reports as its output?
- **Repositories named `resrepo`.** `find_git_root()` refuses any repository
  whose directory is called `resrepo` (to protect the package's own source),
  so users cannot name a project so. **Decision needed:** keep, and document
  it?

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
- `knit_to_results()` on an Rmd whose name has spaces or shell characters
  (e.g. `my file.Rmd`), run from a working directory other than the Rmd's
  folder (e.g. from a script): rmarkdown knits its renamed copy in the
  working directory, so the outputs reach `results/my file/` but the
  figures are lost and README.md's links do not resolve (on `dev`, all the
  outputs stayed in the working directory). The verifying agent found that
  passing `intermediates_dir = dirname(input_file)` to `rmarkdown::render()`
  fixes it, with no change for other names.
- `version_setup()` and `version_relink()` refuse `resources_path = "."` with
  "cannot be the root directory of the repository" even when run from a
  subdirectory, where `"."` is not the root (refusing is harmless; the
  message is wrong).
