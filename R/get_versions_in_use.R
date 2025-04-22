#' Get versions of data currently in use
#'
#' This returns the versions of the raw and intermediate data that are currently
#' in use. This is determined by the information in
#' "data/version_meta/raw_in_use.meta" and
#' "data/version_meta/intermediate_in_use.meta", which can be cross-checked with
#' the links in the `data` directory. This function assumes that the current
#' working directory is within a `resrepo` repository
#'
#' @param check_links If TRUE, check that the links in the `data` directory are
#'   correct
#' @return A data.frame with columns, `raw` and `intermediate`, which are the
#'   versions of the raw and intermediate data currently in use.
#' @export

get_versions_in_use <- function (check_links = TRUE) {
  
  # read the current version
  raw_in_use <- readLines(path_resrepo("data/version_meta/raw_in_use.meta"))
  intermediate_in_use <- readLines(path_resrepo("data/version_meta/intermediate_in_use.meta"))
  # check that the version exists
  if (!version_exists(raw_in_use, quiet = FALSE)) {
    stop("The raw version ", raw_in_use, " does not exist!")
  }
  if (!version_exists(intermediate_in_use, quiet = FALSE)) {
    stop("The intermediate version ", intermediate_in_use, " does not exist!")
  }
  # check the links
  if (check_links) {

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
    version_raw_path <- path_resrepo(paste0("versions/", raw_in_use, "/raw"))
    version_intermediate_path <- path_resrepo(paste0("versions/",
                                                      intermediate_in_use, "/intermediate"))
    raw_path <- path_resrepo("data/raw")
    intermediate_path <- path_resrepo("data/intermediate")
    # check that the links point to the correct directory
    if(!identical(as.character(fs::link_path(raw_path)), version_raw_path)){
      stop("The link to the raw data is incorrect")
    }
    if(!identical(as.character(fs::link_path(intermediate_path)), 
                  version_intermediate_path)){
      stop("The link to the intermediate data is incorrect")
    }
  }
  return(list(raw = raw_in_use, intermediate = intermediate_in_use))
}