# set up the test in a temporary directory
test_dir <- file.path(tempdir(), "resrepo_test")
mirror_dir <- file.path(tempdir(), "mirror/resrepo_test")
# clean up the directory if it already exists
unlink(file.path(test_dir, "*"), recursive = TRUE)
unlink(file.path(test_dir, ".*"), recursive = TRUE)
unlink(file.path(mirror_dir, "*"), recursive = TRUE)
unlink(file.path(mirror_dir, ".*"), recursive = TRUE)
# create the directory (if it doesn't exist)
dir.create(test_dir, showWarnings = FALSE)
dir.create(mirror_dir, recursive = TRUE, showWarnings = FALSE)
setwd(test_dir)
# initialise a git repository
this_git <- git2r::init(test_dir)
git2r::config(this_git, user.name = "Test", user.email = "test@example.org")

test_that("create links for data directories", {
  # create a repository as resrepo
  expect_true(init_resrepo()) # make all the resrepo folders
  # and now we expect an error if the link path does not exist
  expect_error(data_dir_link(
    "/data/raw/blah",
    file.path(mirror_dir, "blah2")
  ), "the linked_path")
  # create the linked path
  dir.create(file.path(mirror_dir, "blah2"))
  # but now the link_dir exists and contains a file
  # the local folder for my data (in git)
  dir.create(path_resrepo("/data/raw/blah"))
  write.csv("blah blah", path_resrepo("/data/raw/blah/problem_file.csv"))
  expect_error(data_dir_link(
    link_dir = "/data/raw/blah", # the data folder I will use
    target_dir = file.path(mirror_dir, "blah2")
  ), "the data_dir ") # where the actual data are stored
  # remove the file to allow the link to be created
  unlink(path_resrepo("/data/raw/blah/problem_file.csv"))
  expect_true(data_dir_link(
    "/data/raw/blah",
    file.path(mirror_dir, "blah2")
  ))
  # check that the link works (create a file within resrepo and find it in
  # the linked directory)
  write.csv("test my test", path_resrepo("/data/raw/blah/test_file.csv"))
  expect_true(file.exists(file.path(mirror_dir, "blah2/test_file.csv")))
})

# and now clean up
unlink(file.path(test_dir, "*"), recursive = TRUE)
unlink(file.path(test_dir, ".*"), recursive = TRUE)
