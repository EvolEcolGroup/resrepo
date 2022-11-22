#' Make a data directory within a resrepo
#'
#' Make a directory within a resrepo with a short path from its root 
#' (e.g. `/data/raw/remote_sensing`). An empty directory will be added to the git
#' repository by addign a .gitkeep file to it, but .gitingore is set to avoid tracking
#' any other content. In this way, the resrepo will show all the primary level
#' directories in `/data/raw` and `/data/intermediate`, making it easier to keep
#' track of what data need downloading.
#'
#' @param path data path within a resrepo
#'
#' @export

data_dir_make <- function(path, source = NULL,
                         URL = NULL, tracked = FALSE) {
  # check that path starts with the right prefix
  path_is_data_dir(path)
  # find the root of the git repository
  git_root <- normalizePath(find_git_root())
  # create the full path
  full_path <- file.path(git_root,path)
  if (dir.exists(full_path)){
    stop(path," already exists!")
  }
  dir.create(full_path)
  #data_source_add(path, source, url)
  if (tracked) {
    warning ("tracked not implemented as yet; in the future it should change .gitignore")
  }
  #file.create(file.path(full_directory,".gitkeep"))
  # now update gitignore
  #gitignore_addition <- paste0("!",directory,"\n",directory,"/*",
  #                             "\n!",directory,"/.gitkeep")
  #write(gitignore_addition,file=file.path(git_root,".gitignore"),append=TRUE)
  return(TRUE)
}
