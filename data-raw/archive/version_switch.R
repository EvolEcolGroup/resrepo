#' Switch from one data version to another
#'
#' Change the soft links to `data/raw` and `data/intermediate` to point to the
#' specified version in `versions`
#'
#' @param version The version to switch to
#' @param fail_on_error Should the function stop if the version does not exist?
#' @return TRUE if the switch was successful, FALSE otherwise
#' (if `fail_on_error` is FALSE)
#' @export

version_switch <- function(version, fail_on_error = TRUE) {
  if (!version_exists(version)) {
    if (fail_on_error) {
      stop("Version ", version, " does not exist in 'versions'")
    } else {
      return(FALSE)
    }
  }
  # delete the old links
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste(
    "versions/", version, "/raw", sep = ""
  )), link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(
    paste("versions/", version, "/intermediate", sep = "")
  ), link_dir = "data/intermediate")
  writeLines(version,
             con = path_resrepo(paste0("data/version_meta/current_version",
                                       "_in_use_by_resrepo.meta")),
             sep = "\n", useBytes = FALSE)
  message("switched to ", version)
  return(TRUE)
}
