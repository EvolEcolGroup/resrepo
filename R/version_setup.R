#' Set up versioning for data in a resrepo
#' 
#' Move over the data to a separate directory, "version_resources",
#'  and create links to the data in the repository. The first version of the data
#'  is, by default, called "initial". Later on, we can add
#'  further versions of the data, and switch between them.
#'  
#'  @param quiet If TRUE, the user will not be prompted to backup their data. Default is FALSE.
#' 
#'  @returns TRUE if the setup was successful


version_setup <- function(quiet = FALSE){
  # check if running interactively 
  if (interactive() && quiet == FALSE) {
    # check that the user has a back up of the data
    # add options for the user 
    options <- c("Yes", "No")
    # prompt the choice for the user 
    choice <- menu(options, title="To avoid data loss, it is good practice to have a backup of your raw data outside your repository before versioning.\nHave you backed up your data?")
    if (choice == 2){
      stop("Please backup your data before versioning")
    }
  } else {
    choice <- 1 # when non-run interactively for vignette building
  }
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
    # check if content of old and new directories are the same
    identical(list.files(path_resrepo("data/raw"), recursive = TRUE), list.files(path_resrepo("version_resources/initial/raw"), recursive = TRUE))
    identical(list.files(path_resrepo("data/intermediate"), recursive = TRUE), list.files(path_resrepo("version_resources/initial/intermediate"), recursive = TRUE))
    # remove the old directory
    fs::dir_delete(path_resrepo("data/raw"))
    fs::dir_delete(path_resrepo("data/intermediate"))
    # create links
    data_dir_link(target_dir = path_resrepo("version_resources/initial/raw"),link_dir = "data/raw")
    data_dir_link(path_resrepo("version_resources/initial/intermediate"),link_dir= "data/intermediate")
    # create a file with info on this version
    if (!dir.exists(path_resrepo("data/version_meta"))){
      dir.create(path_resrepo("data/version_meta"), recursive=TRUE)
    }
    version_meta <- data.frame(version = "initial", date_created = Sys.Date(), 
                               description = "the initial version", stringsAsFactors = FALSE)
    write.csv(version_meta, file = path_resrepo("data/version_meta/initial.meta"), row.names = FALSE)
    writeLines("initial", con = path_resrepo("data/version_meta/current_version_in_use_by_resrepo.meta"), sep = "\n", useBytes = FALSE)
    # commit to the repository to remove the data from the current branch
    git2r::commit(message="Move data to version_resources", all=TRUE)
    data_dir_ignore("data/raw")
    data_dir_ignore("data/intermediate")
    git2r::commit(message="Update gitignore", all=TRUE)
    # TODO create the githooks for this repository
    # copy the githooks from the package
    
    # change permissions to make them executable
    
    
  } else {
    stop("version_resources already exists")
  }
}
