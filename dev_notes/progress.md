# resrepo: progress

<!-- Add new entries at the top of progress.md, under its title. Never rewrite old entries. -->

## 2026-11-18 (laptopX1): the 12 decisions implemented

- **Done:** implemented Andrea's 12 decisions (the recommended options;
  for 12, refuse a folder called resrepo or a `DESCRIPTION` of resrepo), one
  commit each with its test, plus 2 lint fixes; a verifying agent then found
  problems, corrected in 10 more commits, which it checked again.
- **Where:** `codereview`, `5ad3257`..`2bf57de` (pushed, no PR).
- **Result:** full suite 211 expectations, 0 failures; lintr clean;
  vignettes render. The agent caught a serious bug in the new undo of
  `version_add()`: a reserved name ("aux") deleted every version
  (fixed in `6e4f920`).
- **Decisions:** the 12 decisions (Andrea, 18 Nov), all implemented.
- **Notes changed:** `code_review_2026-11.md`, `summary.md`, `handover.md`.

## 2026-11-18 (laptopX1): branch pushed; decisions explained

- **Done:** pushed `codereview` (no PR, at Andrea's request; CI does not run
  on it). Rewrote the 12 decisions of the review report with what happens
  now, options and consequences; reproduced several (secrets committed by
  `init_resrepo()`, empty versions made by relinking to a wrong folder,
  `version_setup()` failing in a worktree, links broken by moving the
  repository).
- **Decisions:** push without a PR (Andrea).
- **Correction:** the review has 22 fix commits, `b564e56`..`5dff711`, not 21
  as in the entry below (`5dff711` corrects a regression of `5d1c1a3`, found
  by a second verifying agent).
- **Notes changed:** `code_review_2026-11.md`, `summary.md`, `handover.md`.

## 2026-11-18 (laptopX1): whole-package code review

- **Done:** reviewed all R code, git hooks, templates, tests and vignettes of
  `dev`; confirmed each bug with a script before fixing it; 21 fix commits,
  each test checked to fail before its fix, and every commit checked again
  by a separate agent (which found 4 more issues, fixed in the last 4
  commits).
- **Where:** branch `codereview` (local, not pushed), `b564e56`..`5d1c1a3`, on
  `dev` `df64f6d`.
- **Result:** the worst bug: `version_add()` failed after any `git checkout`
  or `git merge` (the hooks' relative links were rejected). Full suite on the
  installed tip passes; lintr clean; vignettes render.
- **Decisions:** none taken; 12 findings need Andrea's decision (listed in
  the report).
- **Notes changed:** `code_review_2026-11.md` (new), `summary.md`,
  `handover.md`, `README.md`.
