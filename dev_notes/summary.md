# resrepo: summary

Updated 2026-11-18 (laptopX1). One section: the package's issue in
dramanica/claude_jobs, with the single list of its tasks. Its first
paragraph, status and next steps are copied into the issue
(`scripts/sync_issue.py`).

## resrepo: dramanica/claude_jobs#20

Code review of resrepo (research git repositories with versioned data), and the decisions it raised.

**Status.** The whole-package review of `dev` is done: 22 fix commits on
`codereview` (pushed, no PR), each with its test checked to fail before the
fix and checked again by separate agents; the full suite passes locally (128
expectations), lintr is clean and the vignettes render. Report, with the 12
decisions explained, and next steps: `dev_notes/code_review_2026-11.md` and
`dev_notes/handover.md`.

The worst bug fixed: after any `git checkout` or `git merge`, which runs
resrepo's own git hooks, `version_add()` stopped with "The link to the raw
data is incorrect", because the hooks make relative links and R compared
the text of the link with an absolute path. Other fixes stop
`version_add()` from leaving half-made versions or nesting a copy inside an
existing version, repair `path_resrepo(version = )` (it returned a path
that never exists), credentials (several remotes, `GITHUB_PAT`, GitLab,
`ssh://`), relinking clones, `knit_to_results()` (moving other users'
files, dotted names) and the `create_rmd()` template (it could only be
knitted in RStudio).

Not fixed: 12 findings need Andrea's decision (explained in the report, with
options and consequences, several reproduced), and 9 minor ones. CI has not
run on the branch (the workflows run only on `main`, `dev` and PRs into
them): the Windows job, which checks `fs::path_real()` on junctions, is
still to be seen.

**Next steps**
- [ ] **P1** [review] Review the 22 commits on `codereview` (pushed) against `dev_notes/code_review_2026-11.md`: tick or revert each.
- [ ] **P1** [decide] `init_resrepo()` on an existing project replaces README.md and .gitignore and commits every file, secrets included (decision 1): refuse, or merge without destroying? Recommended: merge, adding only the template's files.
- [ ] **P2** [decide] Run CI on `codereview` before merging: a PR into `dev`, or `workflow_dispatch` in R-CMD-check.yaml? The Windows job checks the links fix (`fs::path_real()` on junctions).
- [ ] **P2** [decide] Relinking silently creates empty versions in a wrong `resources_path`, which has three meanings (decision 3): one rule (folder holding `versions/`) and stop on missing versions? Recommended: yes.
- [ ] **P2** [decide] `version_add()` half-way failures and git hooks replacing git-lfs hooks or failing in worktrees (decisions 4, 5): reorder with undo; find hooks with `git rev-parse` and keep existing ones? Recommended: yes to both.
- [ ] **P2** [decide] Relative links in R as in the hooks, and the ignored `path` arguments (decisions 6, 2)? Recommended: relative links; implement `path` in `init_resrepo()`, deprecate it in `version_add()`.
- [ ] **P3** [decide] Decisions 7–12 in the report (remotes and `push =`, same-name versions, `/versions` in .gitignore, outputs left in `code/`, `data_dir_*()` functions, repositories named resrepo).
- [ ] **P3** [cleanup] After the merge: delete the branches `codereview` and `fix_knit_subdir`, and `/media/andrea/annex/tmp/claude/resrepo/` (logs and probe scripts).
