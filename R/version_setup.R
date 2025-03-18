#' Set up versioning for data in a resrepo
#'
#' Move over the data to a separate directory, "versions", and create
#' links to the data in the repository. The first version of the data is, by
#' default, called "initial". Later on, we can add further versions of the
#' data, using [version_add()], and switch between them with [version_switch()].
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
  if (!fs::dir_exists(path_resrepo("versions"))) {
    version_setup_first(quiet = quiet, resources_path = resources_path)
  } else {
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
  if (is.null(resources_path)) {
    dir.create(path_resrepo("versions/initial"), recursive = TRUE)
  } else {
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
    dir.create(path_resrepo("versions/initial"), recursive = TRUE)
  }

  # ingore the versions directory
  data_dir_ignore("versions")
  # copy all raw, intermediate contents
  fs::dir_copy(
    path_resrepo("data/raw"),
    path_resrepo("versions/initial/raw")
  )
  fs::dir_copy(
    path_resrepo("data/intermediate"),
    path_resrepo("versions/initial/intermediate")
  )
  # check if content of old and new directories are the same
  identical(
    list.files(path_resrepo("data/raw"), recursive = TRUE),
    list.files(path_resrepo("versions/initial/raw"),
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
    target_dir = path_resrepo("versions/initial/raw"),
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
    version = "initial", date_created = Sys.Date(),
    description = "the initial version", stringsAsFactors = FALSE
  )
  utils::write.csv(version_meta,
    file = path_resrepo("data/version_meta/initial.meta"),
    row.names = FALSE
  )
  writeLines("initial",
    con = path_resrepo("data/version_meta/current_version_in_use_by_resrepo.meta"), # nolint
    sep = "\n", useBytes = FALSE
  )
  git2r::add(path=path_resrepo("data/version_meta"))
  # commit to the repository to remove the data from the current branch
  git2r::commit(message = "Move data to versions", all = TRUE)
  data_dir_ignore("data/raw")
  data_dir_ignore("data/intermediate")
  git2r::commit(message = "Update gitignore", all = TRUE)
  # create the githooks for this repository
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
  # TODO check that we successfully made the githooks executable
  return(TRUE)
}

