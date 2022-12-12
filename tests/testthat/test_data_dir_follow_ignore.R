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

test_that("data_dir track and untrack",{
  # create a repository as resrepo
  expect_true(init_resrepo())
  git2r::add(path=".")
  git2r::commit(message="initialise resrepo template", all=TRUE)
  # add a data source and check that it is not tracked
  data_source_add(dir="/data/raw/test_standard")
  git2r::add(path="data/data_source_list.csv")
  git2r::commit(message="update source list")
  # create a file, but it should be ignored
  write.csv("blah", path_resrepo("/data/raw/test_standard/myfile1.csv"))
  expect_true(length(git2r::status()$untracked)==0)
  #now follow that directory
  expect_true(data_dir_follow("/data/raw/test_standard"))
  # and our file should apprear in untracked
  expect_false(length(git2r::status()$untracked)==0)
  # try to follow an already followed directory
  expect_warning(data_dir_follow("/data/raw/test_standard"),
                 "/data/raw/test_standard is already being")
  
  # and now revert it
  expect_true(data_dir_ignore("/data/raw/test_standard"))
  expect_true(length(git2r::status()$untracked)==0)
  expect_warning(data_dir_ignore("/data/raw/test_standard"),
                 "/data/raw/test_standard is already being")
  # now follow it
  expect_true(data_dir_follow("/data/raw/test_standard"))
  git2r::add(path=".")
  git2r::commit(message="add a file from data dir", all=TRUE)
  # we can't ignore as it is already tracked
  expect_error (data_dir_ignore("/data/raw/test_standard"),
         "git has tracked")
  # remove it and update git
  unlink(path_resrepo("/data/raw/test_standard/myfile1.csv"))
  git2r::add(path=".")
  git2r::commit(message="remove file from data dir", all=TRUE)
  expect_true(data_dir_ignore("/data/raw/test_standard"))
  # now re-add the file, but it should not be seen by git
  write.csv("blah", path_resrepo("/data/raw/test_standard/myfile1.csv"))
  expect_true(length(git2r::status()$untracked)==0)
  
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
