#' Get a file from a specific version of the data
#'
#' This function gets a file from a specific version of the data. It is useful
#' for comparing files between versions.
#'
#' @param file_path The path to the file in the version of the data you want to
#'   get. This path should be relative to the root of the repository (e.g.
#'   "data/raw/original/my_file.cvs").
#' @param version The version of the data you want to get the file from. If
#'   NULL, the current version is used.
#' @return The path to the file in the current version of the data.
#' @export

get_file_version <- function(file_path, version = NULL) {
  # check that the path starts with data
  
  # check that version exists
  
  # remove the data prefix
  version_file_path <- stringr::str_remove(file_path, "^data/")
  # add the version prefix
  version_file_path <- fs::path("version_resources", version, version_file_path)
  # check that the file exists
  if (!fs::file_exists(version_file_path)) {
    stop("File ", file_path, " does not exist in version ", version)
  } else {
    return(version_file_path)
  }
}