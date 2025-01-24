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
  init_resrepo()
  # try to remove non-existing data source
  expect_error(data_source_delete(dir = "/data/intermediate/test"),
               "/data/intermediate/test does not exists in data_source_list.csv")
  # succeed with an existing directory
  expect_true(data_source_delete(dir = "/data/raw/default"))
  # now create a new data source
  expect_message(data_source_add(dir = "/data/intermediate/test",
                                   source = "onedrive",
                                   url = "your_onedrive_link.com",
                                   note = "just a test"))
  write.csv("some data", path_resrepo("/data/intermediate/test/my_data.csv"))
  expect_error(data_source_delete(dir = "/data/intermediate/test"),
               "the data_dir ")
  # remove the file and we shoudl succeed
  unlink(path_resrepo("/data/intermediate/test/my_data.csv"))
  expect_true(data_source_delete(dir = "/data/intermediate/test"))
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
