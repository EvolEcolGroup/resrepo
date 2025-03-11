#' Check that a version exists in version_resources
#' 
#' @param version The version to check
#' @param quiet Should the function be quiet?
#' @returns TRUE if the version exists, FALSE otherwise
#' @keywords internal

version_exists <- function(version, quiet = TRUE) {
  # Check if the version exists
  if (!(version %in% dir(path_resrepo("version_resources")))) {
    if (!quiet){
      message(
        "Version ",
        version,
        " does not exist in 'version_resources'; do you need to download it?"
      )      
    }
    return(FALSE)
  }
  return(TRUE)
}
