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

test_that("initialise repository",{
  expect_true(init_resrepo())
  # check that directories and some files are there
  expect_true(length(dir(test_dir))>4)
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
