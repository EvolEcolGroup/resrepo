#' Find the root of a git repository
#'
#' Returns the path of the current git repository
#'
#' @param path option string giving the path to use a starting point (i.e. that is
#' part of the repository)
#'
#' @export

find_git_root <- function(path="."){
  root_found <- FALSE
  while (!root_found){
    current_files <- list.files(path, all.files = TRUE)
    if (".git" %in% current_files){
      root_found <- TRUE
      break()
    } else {
      path2 = normalizePath(file.path(path, '..'))
      if (path2==path){ # we have reached the root directory
        break()
      }
      path <- path2
    }    
  }
  if (!root_found){
    stop("not a git repository (and none found in any of the parent directories)")
  }
  if (basename(normalizePath(path))=="resrepo"){
    stop("You are in a git repository called resrepo; this name is reserved\n")
  }
  path <- gsub("\\\\", "/", path) ## changed by Lizzie 1st Feb 2023: sanitize path: convert any double backslashes to single forward slashes
  return(path)
}

