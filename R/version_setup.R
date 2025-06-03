#' Set up versioning for data in a resrepo
#'
#' Move over the data to a separate directory, "versions", and create
#' links to the data in the repository. The first version of the data is, by
#' default, called "initial". Later on, we can add further versions of the
#' data, using [version_add()].
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory where the "versions",
#' the directory containing versioned data, will be stored. If NULL (the default),
#' "versions" is placed at the root of the repository.
#' @returns TRUE if the setup was successful
#' @export


version_setup <- function(quiet = FALSE, resources_path = NULL) {
  # figure out if this repository already has data versioning
  # BUG this does not catch the case where we have just cloned a repository
  # that has version info, but we have yet to set up versioning on this
  # local copy
  # browser()
  
  # get root of the repository 
  root <- find_git_root()
  if (!is.null(resources_path)){
    # check that path do not point to root directory 
    if (resources_path == ".") {
      stop("resources_path cannot be the root directory of the repository")
    } else if (resources_path == root){
      stop("resources_path cannot be the root directory of the repository")
    }
  }
  if (!fs::file_exists(path_resrepo("data/version_meta/"))) {
    version_setup_first(quiet = quiet, resources_path = resources_path)
  } else {
    version_setup_cloned(quiet = quiet, resources_path = resources_path)
    # TODO think carefully what we want to do here
    # this is the case when we already have versioning set up in the repository
    # so there is meta information about the versions
    stop("we dont' have a function yet!")
  }
}

#' Set up versioning for data in a resrepo for the first time
#'
#' This function is used in a repository where data were being tracked and we
#' need to move them to a separate directory, "versions", and create
#' links to the data in the repository. The first version of the data is, by
#' default, called "initial".
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory where the "versions",
#' the directory containing versioned data, will be stored. If NULL (the default),
#' "versions" is placed at the root of the repository.
#' @returns TRUE if the setup was successful
#' @keywords internal

version_setup_first <- function(quiet = FALSE, resources_path = NULL) {
   if (!git_is_clean()) {
    stop("Please commit or stash your changes before setting up versioning")
  }

  # check if running interactively
  if (interactive() && quiet == FALSE) {
    # check that the user has a back up of the data
    # add options for the user
    options <- c("Yes", "No")
    # prompt the choice for the user
    choice <- utils::menu(options,
      title = paste0(
        "To avoid data loss, it is good practice to ",
        "have a backup of your raw data outside your ",
        "repository before versioning.\nHave you ",
        "backed up your data?"
      )
    )
    if (choice == 2) {
      stop("Please backup your data before versioning")
    }
  } else {
    choice <- 1 # when non-run interactively for vignette building
  }
  # create an initial version
  if (!is.null(resources_path)) {
    # check that resources_path exists and is a directory
    if (!dir.exists(resources_path)) {
      stop("The path ", resources_path, " does not exist!")
    }
    # create a "versions" directory in the resources path
    dir.create(file.path(resources_path, "versions"),
               recursive = TRUE)
    dir.exists(file.path(resources_path, "versions"))
    # create a link from the repository to the resources path
    # need to create versions directory in our repository 
    dir.create(path_resrepo("versions"), recursive = TRUE)
    dir.exists(path_resrepo("versions"))
    data_dir_link(
      link_dir = "/versions",
      target_dir = file.path(resources_path)
    )
  }
  dir.create(path_resrepo("versions/starting"), recursive = TRUE)
  dir.create(path_resrepo("versions/initial"), recursive = TRUE)
  

  # ingore the versions directory
  data_dir_ignore("versions")
  # copy all raw, intermediate contents
  fs::dir_copy(
    path_resrepo("data/raw"),
    path_resrepo("versions/starting")
  )
  fs::dir_copy(
    path_resrepo("data/intermediate"),
    path_resrepo("versions/initial")
  )
  # check if content of old and new directories are the same
  identical(
    list.files(path_resrepo("data/raw"), recursive = TRUE),
    list.files(path_resrepo("versions/starting/raw"),
      recursive = TRUE
    )
  )
  identical(
    list.files(path_resrepo("data/intermediate"), recursive = TRUE),
    list.files(path_resrepo("versions/initial/intermediate"),
      recursive = TRUE
    )
  )
  # remove the old directory
  fs::dir_delete(path_resrepo("data/raw"))
  fs::dir_delete(path_resrepo("data/intermediate"))
  # create links
  data_dir_link(
    target_dir = path_resrepo("versions/starting/raw"),
    link_dir = "data/raw"
  )
  data_dir_link(path_resrepo("versions/initial/intermediate"),
    link_dir = "data/intermediate"
  )
  # create a file with meta info on this version
  if (!dir.exists(path_resrepo("data/version_meta"))) {
    dir.create(path_resrepo("data/version_meta"), recursive = TRUE)
  }
  version_meta <- data.frame(
    data = "intermediate", version = "initial", date_created = Sys.Date(),
    description = "the initial version intermediate data", stringsAsFactors = FALSE
  )
  utils::write.csv(version_meta,
    file = path_resrepo("data/version_meta/initial.meta"),
    row.names = FALSE
  )
  version_meta <- data.frame(
    data = "raw", version = "starting", date_created = Sys.Date(),
    description = "the starting version of raw data", stringsAsFactors = FALSE
  )
  utils::write.csv(version_meta,
                   file = path_resrepo("data/version_meta/starting.meta"),
                   row.names = FALSE
  )  
  # write the versions to file
  writeLines("starting",
             con = path_resrepo("data/version_meta/raw_in_use.meta"),
             sep = "\n", useBytes = FALSE)
  writeLines("initial",
             con = path_resrepo("data/version_meta/intermediate_in_use.meta"),
             sep = "\n", useBytes = FALSE)
  
  # add the meta files to git
  git2r::add(path=path_resrepo("data/version_meta"))
  # commit to the repository to remove the data from the current branch
  git2r::commit(message = "Move data to versions", all = TRUE)
  data_dir_ignore("data/raw")
  data_dir_ignore("data/intermediate")
  git2r::commit(message = "Update gitignore", all = TRUE)
  # TODO add gitshooks back as function 
  add_git_hooks()
  # TODO check that we successfully made the githooks executable
  return(TRUE)
}


version_setup_cloned <- function(quiet = FALSE, resources_path = NULL){
  # browser()
  # if resources_path is NULL check we have a versions directory 
  if (is.null(resources_path)) {
    versions_path <- path_resrepo("versions")
    if (!dir.exists(versions_path)) {
      stop("The path ", versions_path, " does not exist!")
    }
  } else {
  #   # check that resources_path exists and is a directory
    if (!dir.exists(resources_path)) {
      stop("The path ", resources_path, " does not exist!")
    }
  versions_path <- file.path(resources_path, "versions")
    # if (dir.exists(path_resrepo("versions"))){
    #   stop("If 'resources_path' is given, there should be no 'versions' directory in the repository!")
    # }
    if (dir.exists(versions_path)) {
      stop("If 'resources_path' is given, there should be no 'versions' directory in the repository!")
    }
    # create a "versions" directory in the resources path
    # versions_path <- file.path(resources_path, "versions")
    # dir.create(versions_path, recursive = TRUE)
    
    # create a link from the repository to the resources path
    data_dir_link(
      link_dir = "/versions",
      target_dir = file.path(resources_path)
    )
  }

  # need to create links to 'data/raw' and 'data/intermediate' in versions 
  # create links
  # check the version in use
  raw_in_use <- readLines(con = path_resrepo("data/version_meta/raw_in_use.meta"))
  intermediate_in_use <- readLines(con = path_resrepo("data/version_meta/intermediate_in_use.meta"))
  data_dir_link(
    target_dir = path_resrepo(paste0("versions/", raw_in_use, "/raw")),
    link_dir = "data/raw"
  )
  data_dir_link(path_resrepo(paste0("versions/", intermediate_in_use, "/intermediate")),
                link_dir = "data/intermediate"
  )
  # run git hooks
  add_git_hooks()
  return(TRUE)
}


add_git_hooks <- function(){
  # create the githooks
  # copy the githooks from the package
  fs::dir_copy(system.file("githooks", package = "resrepo"),
               path_resrepo(".git/hooks"), overwrite = TRUE
  )
  # change permissions to make them executable
  fs::file_chmod(
    path_resrepo(".git/hooks/post-checkout"),
    mode = "755"
  )
  # change permissions to make them executable
  fs::file_chmod(
    path_resrepo(".git/hooks/post-merge"),
    mode = "755"
  )
}





