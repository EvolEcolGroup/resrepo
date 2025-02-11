



version_resrepo <- function (path=".") {
  git_root <- find_git_root()
  # need to check if there is a source repository in the path
  template_dir <- system.file("template",package="resrepo")
  copy_results <- file.copy(from=list.files(template_dir,full.names = TRUE,
                                            all.files=TRUE,no..=TRUE),
                            to = git_root, recursive = TRUE, overwrite = TRUE)
  # make gitignore a hidden file
  file.rename(from = file.path(git_root,"gitignore"), 
              to = file.path(git_root,".gitignore"))
  dir.create(path_resrepo("/data/raw/original"))
  if (all(copy_results)){
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
  
}