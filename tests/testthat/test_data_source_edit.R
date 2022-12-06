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
  expect_true(data_source_list_add(directory = "data/intermediate/test",
                                   source = "onedrive",
                                   url = "your_onedrive_link.com",
                                   note = "just a test"))
  expect_true(file.exists("data/data_source_list.csv"))
  edited_data_source_file<-read.csv("data/data_source_list.csv")
  expect_true(edited_data_source_file$directory[2]=="data/intermediate/test")
  expect_true(edited_data_source_file$source[2]=="onedrive")
  
  expect_true(data_source_edit(directory = "data/intermediate/test", 
                                    new_directory = "data/intermediate/test2",
                                    new_source = "dropbox",
                                    new_url = "your_dropbox_link.com",
                                    new_notes = "just another test"))
  edited_data_source_file<-read.csv("data/data_source_list.csv")
  expect_true(edited_data_source_file$directory[2]=="data/intermediate/test2")
  expect_true(edited_data_source_file$source[2]=="dropbox")
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
