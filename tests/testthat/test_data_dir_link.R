# set up the test in a temporary directory
test_dir <- file.path(tempdir(),"resrepo_test")
mirror_dir <- file.path(tempdir(),"mirror/resrepo_test")
# clean up the directory if it already exists
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
unlink (file.path(mirror_dir,"*"), recursive = TRUE)
unlink (file.path(mirror_dir,".*"), recursive = TRUE)
# create the directory (if it doesn't exist)
dir.create(test_dir, showWarnings = FALSE)
dir.create(mirror_dir, recursive=TRUE, showWarnings = FALSE)
setwd(test_dir)
# initialise a git repository
git2r::init(test_dir)

test_that("create links for data directories",{
  # create a repository as resrepo
  expect_true(init_resrepo())
  git2r::add(path=".")
  git2r::commit(message="initialise resrepo template", all=TRUE)
  # expect an error if the data_path already exists
  dir.create(path_resrepo("/data/raw/blah"))
  expect_error(data_dir_link("/data/raw/blah",
                             file.path(mirror_dir,"blah2")),"the data_path")
  # remove the data_path to reset the test
  unlink(path_resrepo("/data/raw/blah"),recursive=TRUE)
  # expect an error if the link path does not exist
  expect_error(data_dir_link(path_resrepo("/data/raw/blah"),
                             file.path(mirror_dir,"blah2")),"the linked_path")
  # create the linked path
  dir.create(file.path(mirror_dir,"blah2"))
  expect_true(data_dir_link("/data/raw/blah",
                file.path(mirror_dir,"blah2")))
  skip_if(.Platform$OS.type!="unix")
  # check that the link works (crete a file within resrepo and find it in
  # the linked directory)
  write.csv("test my test",path_resrepo("/data/raw/blah/test_file.csv"))
  expect_true(file.exists(file.path(mirror_dir,"blah2/test_file.csv")))
  
  
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
