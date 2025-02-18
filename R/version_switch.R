#' Switch from one data version to another
#' 
#' Change the soft links to `data/raw` and `data/intermediate` to point to the
#' specified version in `version_resources`
#' 
#' @param version The version to switch to
#' @return TRUE if the switch was successful, FALSE otherwise

version_switch <- function(version) {
  # Check if the version exists
  if (!(version %in% dir(path_resrepo("version_resources")))) {
    message(
      "Version ",
      version,
      " does not exist in 'version_resources'; do you need to download it?"
    )
    return(FALSE)
  }
  # delete the old links
  fs::link_delete(path_resrepo("data/raw"))
  fs::link_delete(path_resrepo("data/intermediate"))
  # then create the new ones
  data_dir_link(target_dir = path_resrepo(paste(
    "version_resources/", version, "/raw", sep = ""
  )), link_dir = "data/raw")
  data_dir_link(target_dir = path_resrepo(
    paste("version_resources/", version, "/intermediate", sep = "")
  ), link_dir = "data/intermediate")
  writeLines(version, con = path_resrepo("data/version_meta/current_version_in_use_by_resrepo.meta"), sep = "\n", useBytes = FALSE)
  message("switched to ",version)
  return(TRUE)
  
}