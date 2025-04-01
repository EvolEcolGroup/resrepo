#' Get versions of data currently in use
#' 
#' This returns the versions of the raw and intermediate data that are currently
#' in use. This is determined by the information in "data/version_meta/in_use.meta",
#' and can be cross-checked with the links in the `data` directory. This function
#' assumes that the current working directory is within a `resrepo` repository
#' 
#' @param check_links If TRUE, check that the links in the `data` directory are correct
#' @return A data.frame with columns, `raw` and `intermediate`, which are the versions
#' of the raw and intermediate data currently in use.
#' @export

get_versions_in_use <- function (check_links = TRUE) {
  
  # read the current version
  in_use <- read.csv(path_resrepo("data/version_meta/in_use.meta"))
  # check that the version exists
  if (!version_exists(in_use$raw, quiet = FALSE)) {
    stop("The raw version ", in_use$raw, " does not exist!")
  }
  if (!version_exists(in_use$intermediate, quiet = FALSE)) {
    stop("The intermediate version ", in_use$intermediate, " does not exist!")
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
    version_raw_path <- path_resrepo(paste0("versions/", in_use$raw, "/raw"))
    version_intermediate_path <- path_resrepo(paste0("versions/",
                                                      in_use$intermediate, "/intermediate"))
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
  return(in_use)
}