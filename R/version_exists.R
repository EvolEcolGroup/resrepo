#' Check that a version exists in versions
#'
#' @param version The version to check
#' @param quiet Should the function be quiet?
#' @returns TRUE if the version exists, FALSE otherwise
#' @keywords internal

version_exists <- function(version, quiet = TRUE) {
  # Check if the version exists
  if (!(version %in% dir(path_resrepo("versions")))) {
    if (!quiet) {
      message(
        "Version ",
        version,
        " does not exist in 'versions'; do you need to download it?"
      )
    }
    return(FALSE)
  }
  return(TRUE)
}
