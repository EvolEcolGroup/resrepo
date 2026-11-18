# set up the test in a temporary directory
test_dir <- file.path(tempdir(), "resrepo_test")
# clean up the directory if it already exists
if (dir.exists(test_dir)) {
  fs::dir_delete(test_dir)
}
# create the directory (if it doesn't exist)
dir.create(test_dir, showWarnings = FALSE)
withr::local_dir(as.character(test_dir))
# initialise a git repository
example_repo <- git2r::init(test_dir, branch = "main")
git2r::config(example_repo,
  user.name = "Test",
  user.email = "test@example.org"
)

test_that("initialise repository", {
  expect_true(init_resrepo())
  # check that directories and some files are there
  expect_true(length(dir(test_dir)) > 4)
})

test_that("init_resrepo keeps the files of an existing project", {
  existing_dir <- file.path(tempdir(), "resrepo_existing")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(existing_dir)) {
    fs::dir_delete(existing_dir)
  }
  dir.create(existing_dir)
  existing_repo <- git2r::init(existing_dir, branch = "main")
  git2r::config(existing_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  withr::with_dir(existing_dir, {
    # a project with its own README and .gitignore, a secret, some data, an
    # untracked script and an uncommitted edit
    writeLines("# My project", "README.md")
    writeLines(c(".Renviron", "big_data/"), ".gitignore")
    git2r::add(path = c("README.md", ".gitignore"))
    git2r::commit(message = "Start")
    writeLines("GITHUB_PAT=secret", ".Renviron")
    dir.create("big_data")
    writeLines("x", "big_data/huge.csv")
    writeLines("work in progress", "analysis.R")
    writeLines(c("# My project", "An edit"), "README.md")
    # the existing files are kept (they used to be overwritten, and
    # everything was committed, the secret included)
    expect_message(init_resrepo(), "were kept: README.md")
    expect_identical(readLines("README.md"), c("# My project", "An edit"))
    gitignore_lines <- readLines(".gitignore")
    expect_true(all(c(".Renviron", "big_data/") %in% gitignore_lines))
    expect_true("/*.Rhistory" %in% gitignore_lines)
    # only what init_resrepo() created or changed was committed
    tracked <- git2r::ls_tree(recursive = TRUE)
    tracked <- paste0(tracked$path, tracked$name)
    expect_true(all(c("code/README.md", ".gitignore") %in% tracked))
    expect_false(any(
      c(".Renviron", "big_data/huge.csv", "analysis.R") %in% tracked
    ))
    expect_true("README.md" %in% unlist(git2r::status()$unstaged))
  })
  fs::dir_delete(existing_dir)
})

test_that("init_resrepo works on the repository at path", {
  other_dir <- file.path(tempdir(), "resrepo_at_path")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(other_dir)) {
    fs::dir_delete(other_dir)
  }
  dir.create(other_dir)
  other_repo <- git2r::init(other_dir, branch = "main")
  git2r::config(other_repo, user.name = "Test", user.email = "test@example.org")
  # from a working directory outside it (path used to be ignored, and the
  # repository of the working directory initialised instead)
  withr::with_dir(tempdir(), {
    expect_true(init_resrepo(other_dir))
    expect_identical(normalizePath(getwd()), normalizePath(tempdir()))
  })
  expect_true(file.exists(file.path(other_dir, "code", "README.md")))
  fs::dir_delete(other_dir)
})

