#' Relink versions in a resrepo repository
#'
#' If a repository has been cloned, relinks the "versions" directory to the
#' "data" directory according to the version metadata. If a user wishes to move
#' the "versions" directory to a different location, this function will also
#' update the links accordingly.
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory where the "versions", the
#'   directory containing versioned data, will be stored. If NULL (the default),
#'   "versions" is placed at the root of the repository.
#' @returns TRUE if the relink was successful
#' @export


version_relink <- function(quiet = FALSE, resources_path = NULL) {
  # figure out if this repository already has data versioning
  # BUG this does not catch the case where we have just cloned a repository
  # that has version info, but we have yet to set up versioning on this
  # local copy

  if (!is.null(resources_path)) {
    # check that path do not point to root directory
    if (resources_path == ".") {
      stop("resources_path cannot be the root directory of the repository")
    } else if (normalizePath(resources_path) == normalizePath(getwd())) {
      stop("resources_path cannot be the root directory of the repository")
    }
  }
  if (!fs::file_exists(path_resrepo("data/version_meta/"))) {
    message("This resrepo repository has not been versioned. ",
            "All the data should be placed in the data folder. If you want ",
            "to version this repository, use version_setup().")
  } else {
    version_reset(quiet = quiet, resources_path = resources_path)

  }
}


#' Reset versions
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory where the "versions", the
#'   directory containing versioned data, will be stored. If NULL (the default),
#'   "versions" is placed at the root of the repository.
#' @returns TRUE if the relink was successful

version_reset <- function(quiet = FALSE, resources_path = NULL) {
  # if resources_path is NULL check we have a versions directory
  if (is.null(resources_path)) {
    versions_path <- path_resrepo("versions")
    if (!dir.exists(versions_path)) {
      dir.create(versions_path, recursive = TRUE)
      # need to create links to 'data/raw' and 'data/intermediate' in versions
      # create links
      # check the version in use
      raw_in_use <- readLines(con = path_resrepo(
        "data/version_meta/raw_in_use.meta"
      ))
      intermediate_in_use <- readLines(con = path_resrepo(
        "data/version_meta/intermediate_in_use.meta"
      ))
      # create substructure
      fs::dir_create(path_resrepo(paste0("versions/", raw_in_use, "/raw")))
      fs::dir_create(path_resrepo(paste0(
        "versions/", intermediate_in_use,
        "/intermediate"
      )))
      # link the directories
      data_dir_link(
        target_dir = path_resrepo(paste0("versions/", raw_in_use, "/raw")),
        link_dir = "data/raw"
      )
      data_dir_link(
        target_dir = path_resrepo(paste0(
          "versions/", intermediate_in_use,
          "/intermediate"
        )),
        link_dir = "data/intermediate"
      )
      # run git hooks
      #add_git_hooks() # perhaps we don't need this step?
      return(TRUE)
    }
  } else {
    # check that resources_path exists and is a directory
    if (!dir.exists(resources_path)) { # wrong path
      stop("The path ", resources_path, " does not exist!")
    }
    # check whether resources path ends in /versions
    if (basename(normalizePath(resources_path)) == "versions") {
      versions_path <- normalizePath(resources_path)
    } else {
      versions_path <- file.path(paste0(resources_path, "/versions"))
    }

    # check whether there is already a link from /versions to an external path
    # if there is an existing link, update links and exit
    if (fs::is_link(path_resrepo("versions"))) {
      # run update_links
      fs::link_delete(path_resrepo("versions"))
    }

    # TODO check the external /versions folder substructure has the right
    # raw and intermediate .meta versions at this point

    # create a link from the repository to the resources path
    data_dir_link(
      link_dir = "/versions",
      target_dir = file.path(versions_path)
    )
  }

  # need to create links to 'data/raw' and 'data/intermediate' in versions
  # create links
  # check the version in use
  raw_in_use <- readLines(con = path_resrepo(
    "data/version_meta/raw_in_use.meta"
  ))
  intermediate_in_use <- readLines(con = path_resrepo(
    "data/version_meta/intermediate_in_use.meta"
  ))

  # run git hooks
  #add_git_hooks() # perhaps we don't need this step?
  return(TRUE)
}


add_git_hooks <- function() {
  # create the githooks
  # copy the githooks from the package
  fs::dir_copy(system.file("githooks", package = "resrepo"),
               path_resrepo(".git/hooks"),
               overwrite = TRUE
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

