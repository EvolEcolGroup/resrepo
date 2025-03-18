#' Update links to the data directories
#'
#' Update links to the data directories, so that they point to the correct
#' version in the `versions` directory. If they links do not exist,
#' they will be created. If they exist, they will be updated only if the target
#' directory has changed.
#' 
#' @param quiet if TRUE, do not print messages
#' @returns TRUE if successful
#' @export

update_links <- function(quiet = FALSE) {
  # get the current version
  version <- readLines(
    path_resrepo("data/version_meta/current_version_in_use_by_resrepo.meta"))
  # check that the version exists
  if(!dir.exists(path_resrepo(paste0("versions/",version)))){
    stop("the version ", version," does not exist!")
  }
  # check that the data paths are NOT directories (they should be a link
  # or not exist)
  if(dir.exists(path_resrepo("data/raw")) && 
     !fs::is_link(path_resrepo("data/raw"))) {
    stop("data/raw should not be a directory, but a link to a directory")
  }
  if(dir.exists(path_resrepo("data/intermediate")) && 
     !fs::is_link(path_resrepo("data/intermediate"))) {
    stop("data/intermediate should not be a directory, but ",
         "a link to a directory")
  }

  # make the paths for data dirs to the version
  version_raw_path <- path_resrepo(paste0("versions/", version, "/data/raw"))
  version_intermediate_path <- path_resrepo(paste0("versions/",
                                          version, "/data/intermediate"))
  raw_path <- path_resrepo("data/raw")
  intermediate_path <- path_resrepo("data/intermediate")
  # if the link exists but points to the wrong directory, delete
  # the link
  if(fs::is_link(raw_path) &&
     !identical(fs::link_path(raw_path), version_raw_path)){
    fs::link_delete(raw_path)
  }
  if(fs::is_link(intermediate_path) &&
     !identical(fs::link_path(intermediate_path), 
                version_intermediate_path)){
    fs::link_delete(intermediate_path)
  }
  # if the link does not exist, create it
  if(!fs::is_link(raw_path)){
    fs::link_create(version_raw_path, raw_path, symbolic = TRUE)
    if (!quiet){
      message("Links updated")
    }
  }
  if(!fs::is_link(intermediate_path)){
    fs::link_create(version_intermediate_path, intermediate_path, symbolic = TRUE)
  }

  return(invisible(TRUE))
}
