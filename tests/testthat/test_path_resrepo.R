# set up the test in a temporary directory
test_dir <- file.path(tempdir(),"resrepo_test")
# clean up the directory if it already exists
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
# create the directory (if it doesn't exist)
dir.create(test_dir, showWarnings = FALSE)
setwd(test_dir)
# initialise a git repository
git2r::init(test_dir)
init_resrepo()

test_that("initialise repository",{
  # get path of directory
  expect_true(inherits(path_resrepo("/data/raw"),"character"))
  expect_true(inherits(path_resrepo("/data/raw",check_exists = TRUE),"character"))
  # get path of file
  expect_true(inherits(path_resrepo("/data/README.md"),"character"))
  expect_true(inherits(path_resrepo("/data/README.md",check_exists = TRUE),"character"))
  # throw errors if check fails
  expect_error(path_resrepo("/data/raw/test_dir",check_exists = TRUE),
              "path ")
  expect_error(path_resrepo("/data/raw/README.dox",check_exists = TRUE),
               "path ")
  # check shortcuts
  expect_true(inherits(path_resrepo("/d/r/original",check_exists = TRUE),"character"))

})

# test that we can use the version argument in the function
test_that("version argument",{
  git2r::status()
  version_setup(quiet = TRUE)
  version_add(new_version = "test_version", source_version = "initial",
              description = "a version to test the function", quiet = TRUE)
  expect_equal(path_resrepo("/data/raw", version = "test_version"),
               path_resrepo("version_resources/test_version/data/raw"))
  expect_equal(path_resrepo("/data/raw", version = "initial"),
               path_resrepo("version_resources/initial/data/raw"))
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)

