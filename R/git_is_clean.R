#' Check that a git repository has a clean working directory
#'
#' @param repo a path to a repository or a git_repository
#' object. Default is '.'
#' @returns TRUE if it has a clean working directory
#' @keywords internal

git_is_clean <- function(repo = ".") {
  git_status <- git2r::status(repo = repo)
  if (sum(unlist(lapply(git_status, length))) == 0) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}
