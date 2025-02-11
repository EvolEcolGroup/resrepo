#' Set up versioning for data in a resrepo
#' 
#' Move over the data to a separate directory, "version_resources",
#'  and create links to the data in the repository. The first version of the data
#'  is, by default, called "initial". Later on, we can add
#'  further versions of the data, and switch between them.
#' 
#'  @returns TRUE if the setup was successful


version_setup <- function(){
  git_root <- find_git_root()
  # if the version_resource path does not exist, create it
  if (!dir.exists(path_resrepo("version_resources"))){
    # create an initial version
    dir.create(path_resrepo("version_resources/initial"), recursive=TRUE)
    # ingore the version_resources directory
    data_dir_ignore("version_resources")
    # copy all raw, intermediate contents
    fs::dir_copy(path_resrepo("data/raw"),path_resrepo("version_resources/initial/raw"))
    fs::dir_copy(path_resrepo("data/intermediate"),path_resrepo("version_resources/initial/intermediate"))
    # TODO compare the old and new directories to make sure that we can proceed with deleting the old
    # remove the old directory
    fs::dir_delete(path_resrepo("data/raw"))
    fs::dir_delete(path_resrepo("data/intermediate"))
    # create links
    data_dir_link(target_dir = path_resrepo("version_resources/initial/raw"),link_dir = "data/raw")
    data_dir_link(path_resrepo("version_resources/initial/intermediate"),link_dir= "data/intermediate")
    # commit to the repository to remove the data from the current branch
    git2r::commit(message="Move data to version_resources", all=TRUE)
    data_dir_ignore("data/raw")
    data_dir_ignore("data/intermediate")
    git2r::commit(message="Update gitignore", all=TRUE)
    
  } else {
    stop("version_resources already exists")
  }
  
}
