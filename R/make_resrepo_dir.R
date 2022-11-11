#' Make a data directory within a resrepo
#'
#' Make a directory within a resrepo with a short path from its root 
#' (e.g. `/data/raw/remote_sensing`). An empty directory will be added to the git
#' repository by addign a .gitkeep file to it, but .gitingore is set to avoid tracking
#' any other content. In this way, the resrepo will show all the primary level
#' directories in `/data/raw` and `/data/intermediate`, making it easier to keep
#' track of what data need downloading.
#'
#' @param directory directory within a resrepo
#'
#' @export

make_datadir <- function(directory) {
  git_root <- find_git_root()
  full_directory <- normalizePath(file.path(git_root,directory))
  dir.create(full_directory)
  file.create(file.path(full_directory,".gitkeep"))
  # now update gitignore
  gitignore_addition <- paste0("!",directory,"\n",directory,"/*",
                               "\n!",directory,"/.gitkeep")
  write(line,file=file.path(git_root,".gitignore"),append=TRUE)
}
