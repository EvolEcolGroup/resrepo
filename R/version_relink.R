#' Relink versions in a resrepo repository
#'
#' If a repository has been cloned, relinks the "versions" directory to the
#' "data" directory according to the version metadata. If a user wishes to move
#' the "versions" directory to a different location, this function will also
#' update the links accordingly.
#'
#' Repositories versioned with older versions of resrepo ignore any file or
#' directory called `versions` (the line `versions` in `.gitignore`):
#' `version_relink()` replaces that line with `/versions`, which ignores only
#' the directory at the root, and commits `.gitignore` when that change can
#' be committed on its own.
#'
#' The versions in use (in `data/version_meta/raw_in_use.meta` and
#' `intermediate_in_use.meta`) must be in the versions directory: if any is
#' missing (e.g. a mistyped `resources_path`, or data not yet copied there),
#' `version_relink()` stops, unless `create = TRUE`, which creates them empty.
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to a directory outside the repository that
#'   holds "versions", the directory containing versioned data (or to
#'   "versions" itself). If NULL (the default), "versions" is at the root of
#'   the repository.
#' @param create If TRUE, create the versions in use if they are missing
#'   (empty). Default is FALSE, which stops instead.
#' @returns TRUE if the relink was successful
#' @export


version_relink <- function(quiet = FALSE, resources_path = NULL,
                           create = FALSE) {
  # figure out if this repository already has data versioning

  if (!is.null(resources_path)) {
    # check that resources_path exists, and is outside the repository
    check_resources_path(resources_path)
  }
  if (!fs::file_exists(path_resrepo("data/version_meta/"))) {
    stop(
      "This resrepo repository has not been versioned. ",
      "All the data should be placed in the data folder. If you want ",
      "to version this repository, use version_setup()."
    )
  } else if (!fs::is_link(path_resrepo("data/raw")) || !fs::is_link(path_resrepo("data/intermediate"))) { # nolint
    # if data/raw and data/intermediate aren't links, then
    # this is a cloned versioned
    relinked <- version_setup_cloned(
      quiet = quiet, resources_path = resources_path, create = create
    )
  } else {
    relinked <- version_reset(
      quiet = quiet, resources_path = resources_path, create = create
    )
  }
  # older set-ups ignored any file or directory called versions: ignore only
  # the one at the root
  fix_versions_ignore(quiet = quiet)
  relinked
}

#' Ignore only the versions directory at the root of the repository
#'
#' Repositories versioned with resrepo up to 0.3.1 have the line `versions`
#' in `.gitignore`, which ignores any file or directory called `versions`
#' anywhere in the repository (e.g. `results/versions/`). This replaces it
#' with `/versions`, and commits `.gitignore` if nothing else was staged and
#' `.gitignore` had no other changes; otherwise it leaves the change for the
#' user to commit.
#'
#' @param quiet If TRUE, do not print messages
#' @returns TRUE if `.gitignore` was changed, invisibly
#' @keywords internal
#' @noRd

fix_versions_ignore <- function(quiet = FALSE) {
  gitignore <- path_resrepo(".gitignore")
  # nothing to do without a .gitignore, or without the old line
  if (!file.exists(gitignore)) {
    return(invisible(FALSE))
  }
  gitignore_lines <- readLines(gitignore)
  if (!"versions" %in% gitignore_lines) {
    return(invisible(FALSE))
  }
  # check that the commit would hold only this change: nothing staged, and
  # no other change to .gitignore
  git_status <- git2r::status()
  can_commit <- length(git_status$staged) == 0 &&
    !".gitignore" %in% unlist(git_status$unstaged)
  # replace the line
  gitignore_lines[gitignore_lines == "versions"] <- "/versions"
  writeLines(gitignore_lines, gitignore)
  if (can_commit) {
    git2r::add(path = gitignore)
    git2r::commit(message = "Ignore only the versions directory at the root")
    if (!quiet) {
      message(
        "'versions' in .gitignore was replaced with '/versions' (only the ",
        "directory at the root is ignored), and committed"
      )
    }
  } else {
    message(
      "'versions' in .gitignore was replaced with '/versions' (only the ",
      "directory at the root is ignored); please commit .gitignore"
    )
  }
  invisible(TRUE)
}


#' Reset versions
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory that holds "versions", the
#'   directory containing versioned data (or to "versions" itself).
#' @param create If TRUE, create the versions in use if they are missing.
#' @returns TRUE if the relink was successful
#' @keywords internal

version_reset <- function(quiet = FALSE, resources_path = NULL,
                          create = FALSE) {
  # if resources_path is NULL check we have a versions directory
  if (is.null(resources_path)) {
    stop(
      "Links already exist. To relocate versions, supply \n",
      "'resources_path'. This should be the path to \n",
      "the directory containing the 'versions' folder."
    )
  } else {
    # the versions directory: <resources_path>/versions, or resources_path
    # itself if it is called versions
    versions_path <- resources_versions_path(resources_path)
    if (!dir.exists(versions_path)) {
      stop("The path ", versions_path, " does not exist!")
    }
    # the versions in use must be there (or be created if create = TRUE)
    check_versions_in_use(versions_path, create = create)

    # check whether there is already a link from /versions to an external path
    # if there is an existing link, update links and exit
    if (fs::is_link(path_resrepo("versions"))) {
      # run update_links
      fs::link_delete(path_resrepo("versions"))
    }

    # create a link from the repository to the resources path
    data_dir_link(
      link_dir = "/versions",
      target_dir = file.path(versions_path)
    )
  }

  return(TRUE)
}


#' Setup versions from a cloned repository
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory that holds "versions", the
#'   directory containing versioned data (or to "versions" itself). If NULL
#'   (the default), "versions" is at the root of the repository.
#' @param create If TRUE, create the versions directory and the versions in
#'   use if they are missing (empty); if FALSE, stop instead.
#' @returns TRUE if the relink was successful
#' @keywords internal

version_setup_cloned <- function(quiet = FALSE, resources_path = NULL,
                                 create = FALSE) {
  # find the versions directory: versions/ at the root of the repository, or
  # <resources_path>/versions (resources_path itself if called versions)
  if (is.null(resources_path)) {
    versions_path <- path_resrepo("versions")
  } else {
    versions_path <- resources_versions_path(resources_path)
  }
  # without data, stop unless asked to start with empty versions (this used
  # to create them silently, e.g. when resources_path was mistyped)
  if (!dir.exists(versions_path)) {
    if (!create) {
      stop(
        "There are no versions in ", versions_path, ". Give resources_path, ",
        "the directory that holds 'versions', or use create = TRUE to ",
        "start with empty versions."
      )
    }
    dir.create(versions_path, recursive = TRUE)
  }
  # the versions in use must be there (or be created if create = TRUE)
  check_versions_in_use(versions_path, create = create)
  # link versions/ to the external versions directory
  if (!is.null(resources_path)) {
    data_dir_link(
      link_dir = "/versions",
      target_dir = versions_path
    )
  }

  # create links to 'data/raw' and 'data/intermediate' in versions
  # check the version in use
  raw_in_use <- readLines(con = path_resrepo(
    "data/version_meta/raw_in_use.meta"
  ))
  intermediate_in_use <- readLines(con = path_resrepo(
    "data/version_meta/intermediate_in_use.meta"
  ))
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
  add_git_hooks()
  return(TRUE)
}

#' Check that the versions in use are in a versions directory
#'
#' Reads the versions in use from `data/version_meta/raw_in_use.meta` and
#' `intermediate_in_use.meta`, and checks that `<versions_path>/<raw>/raw`
#' and `<versions_path>/<intermediate>/intermediate` exist. Missing ones are
#' created (empty) if `create` is TRUE; otherwise this stops, naming them.
#'
#' @param versions_path the versions directory
#' @param create whether to create missing versions
#' @returns TRUE, or an error
#' @keywords internal
#' @noRd

check_versions_in_use <- function(versions_path, create = FALSE) {
  raw_in_use <- readLines(path_resrepo("data/version_meta/raw_in_use.meta"))
  intermediate_in_use <- readLines(path_resrepo(
    "data/version_meta/intermediate_in_use.meta"
  ))
  needed <- c(
    file.path(versions_path, raw_in_use, "raw"),
    file.path(versions_path, intermediate_in_use, "intermediate")
  )
  missing_versions <- needed[!dir.exists(needed)]
  if (length(missing_versions) > 0) {
    if (!create) {
      stop(
        "The versions in use are missing: ",
        paste(missing_versions, collapse = ", "),
        ". Check resources_path, or use create = TRUE to create them empty."
      )
    }
    fs::dir_create(missing_versions)
  }
  TRUE
}
