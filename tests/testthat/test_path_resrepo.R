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

init_resrepo()

test_that("initialise repository", {
  # get path of directory
  expect_true(inherits(path_resrepo("/data/raw"), "character"))
  expect_true(inherits(
    path_resrepo("/data/raw", check_exists = TRUE),
    "character"
  ))
  # get path of file
  expect_true(inherits(path_resrepo("/data/README.md"), "character"))
  expect_true(inherits(
    path_resrepo("/data/README.md", check_exists = TRUE),
    "character"
  ))
  # throw errors if check fails
  expect_error(
    path_resrepo("/data/raw/test_dir", check_exists = TRUE),
    "path "
  )
  expect_error(
    path_resrepo("/data/raw/README.dox", check_exists = TRUE),
    "path "
  )
  # check shortcuts
  expect_true(inherits(
    path_resrepo("/d/r/original", check_exists = TRUE),
    "character"
  ))
})

# test that we can use the version argument in the function
test_that("version argument", {
  git2r::status()
  version_setup(quiet = TRUE)
  version_add(
    intermediate_new_version = "test_version",
    intermediate_source = "initial",
    intermediate_description = "a version to test the function", quiet = TRUE
  )
  # we have a new version for intermediate (the paths used to keep data/,
  # e.g. versions/test_version/data/intermediate, which does not exist)
  expect_equal(
    path_resrepo("/data/intermediate", version = "test_version"),
    path_resrepo("versions/test_version/intermediate")
  )
  expect_true(dir.exists(
    path_resrepo("/data/intermediate", version = "test_version")
  ))
  # the original path should not change for raw
  expect_equal(
    path_resrepo("/data/raw", version = "starting"),
    path_resrepo("versions/starting/raw")
  )
  # shortcuts and check_exists work with versions
  expect_equal(
    path_resrepo("/d/r/original", version = "starting", check_exists = TRUE),
    path_resrepo("versions/starting/raw/original")
  )
})

test_that("path_relative compares whole directory names", {
  expect_identical(path_relative("/home/user/abc/x/y", "/home/user/abc"), "x/y")
  expect_identical(path_relative("/home/user/z", "/home/user/abc/d"), "../../z")
  # directories that share the start of their name (this used to give
  # "../d/file")
  expect_identical(
    path_relative("/home/user/abd/file", "/home/user/abc"), "../abd/file"
  )
  # characters that have a meaning in regular expressions (this used to fail)
  expect_identical(path_relative("/home/a(b/x", "/home/a(b"), "x")
})

test_that("find_git_root refuses the source of the resrepo package", {
  # a copy of the package source in a folder with another name (it used to
  # be accepted)
  src_dir <- file.path(tempdir(), "resrepo_copy")
  dir.create(src_dir, showWarnings = FALSE)
  git2r::init(src_dir)
  writeLines(
    c("Package: resrepo", "Version: 0.3.1"),
    file.path(src_dir, "DESCRIPTION")
  )
  expect_error(find_git_root(src_dir), "resrepo")
  # a repository called resrepo is still refused
  named_dir <- file.path(tempdir(), "named_repo", "resrepo")
  dir.create(named_dir, recursive = TRUE, showWarnings = FALSE)
  git2r::init(named_dir)
  expect_error(find_git_root(named_dir), "source of the resrepo package")
  # a repository holding another package is fine
  writeLines(
    c("Package: mypkg", "Version: 0.1"),
    file.path(src_dir, "DESCRIPTION")
  )
  expect_identical(find_git_root(src_dir), src_dir)
  # clean up
  fs::dir_delete(c(file.path(tempdir(), "named_repo"), src_dir))
})
