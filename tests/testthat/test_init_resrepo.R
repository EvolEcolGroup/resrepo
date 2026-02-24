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

# and now clean up
if (dir.exists(test_dir)) {
  fs::file_delete(test_dir)
}

