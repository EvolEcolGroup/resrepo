# resrepo: progress

<!-- Add new entries at the top of progress.md, under its title. Never rewrite old entries. -->

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
