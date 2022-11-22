# set up the test in a temporary directory
test_dir <- file.path(tempdir(),"resrepo_test")
# clean up the directory if it already exists
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
# create the directory (if it doesn't exist)
dir.create(test_dir,showWarnings = FALSE)
setwd(test_dir)
# initialise a git repository
git2r::init(test_dir)
# initialise the resrepo repository
init_resrepo()
git2r::add(path = ".")
git2r::commit(message="init repo", all=TRUE)

test_that("make a data directory",{
  
})

# and now clean up
unlink (file.path(test_dir,"*"), recursive = TRUE)
unlink (file.path(test_dir,".*"), recursive = TRUE)
