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
  new_entry <- "/data/intermediate/test"
  expect_message(exit_status <- data_source_add(dir = new_entry,
                                   source = "onedrive",
                                   url = "your_onedrive_link.com",
                                   note = "just a test"),
                 "/data/intermediate/test does not exist; create it now.")
  expect_true(exit_status)
  # check that the dir was created
  expect_true(dir.exists(path_resrepo(new_entry)))
  expect_true(file.exists("data/data_source_list.csv"))
  edited_data_source_file<-read.csv("data/data_source_list.csv")
  expect_true(edited_data_source_file$directory[2]=="/data/intermediate/test")
  expect_true(edited_data_source_file$source[2]=="onedrive")
  # get error if we try to add the same entry
  expect_error((data_source_add(dir = new_entry,
                                     source = "onedrive",
                                     url = "your_onedrive_link.com",
                                     note = "just a test")),
               "/data/intermediate/test already exists in")
  # create a data dir first, and then add the source
  dir.create(path_resrepo("/data/raw/new_dir"))
  expect_true(data_source_add(dir = "/data/raw/new_dir",
                                   source = "zenodo",
                                   url = "your_zenodo_link.com",
                                   note = "just another test"))
  # some basic errors
  expect_error(data_source_add(source="dropbox"),
               "You need to specify a directory.")
  expect_error(data_source_add(dir = "/code/new_dir"),
               "/code/new_dir is not a valid data dir")  
  })

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
