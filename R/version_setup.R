#' Set up versioning for data in a resrepo
#'
#' Move over the data to a separate directory, "versions", and create links to
#' the data in the repository. The first version of the data is, by default,
#' called "initial". Later on, we can add further versions of the data, using
#' [version_add()].
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to a directory outside the repository, where
#'   "versions", the directory containing versioned data, will be created
#'   (as `<resources_path>/versions`, or `resources_path` itself if it is
#'   called `versions`), and linked to from the repository. If NULL (the
#'   default), "versions" is placed at the root of the repository.
#' @returns TRUE if the setup was successful
#' @export


version_setup <- function(quiet = FALSE, resources_path = NULL) {
  # figure out if this repository already has data versioning

  if (!is.null(resources_path)) {
    # check that resources_path exists, and is outside the repository
    check_resources_path(resources_path)
  }
  if (!fs::file_exists(path_resrepo("data/version_meta/"))) {
    version_setup_first(quiet = quiet, resources_path = resources_path)
  } else {
    message(
      "This resrepo repository has already been versioned. To update ",
      "the links to point to the data location on your machine or in an ",
      "external hard drive, please run ",
      "version_relink with the appropriate 'resources_path' argument."
    )
  }
}

#' Set up versioning for data in a resrepo for the first time
#'
#' This function is used in a repository where data were being tracked and we
#' need to move them to a separate directory, "versions", and create links to
#' the data in the repository. The first version of the data is, by default,
#' called "initial".
#'
#' @param quiet If TRUE, the user will not be prompted to backup their data.
#'   Default is FALSE.
#' @param resources_path The path to the directory where the "versions", the
#'   directory containing versioned data, will be stored. If NULL (the default),
#'   "versions" is placed at the root of the repository.
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
    # stop unless the user answered "Yes" (menu() gives 0 when cancelled)
    if (choice != 1) {
      stop("Please backup your data before versioning")
    }
  } else {
    choice <- 1 # when non-run interactively for vignette building
  }
  # create an initial version
  if (!is.null(resources_path)) {
    # the versions go to <resources_path>/versions (or to resources_path
    # itself, if it is called versions)
    versions_path <- resources_versions_path(resources_path)
    # do not mix these data with versions already there
    versions_present <- dir.exists(versions_path) &&
      length(list.files(versions_path, all.files = TRUE, no.. = TRUE)) > 0
    if (versions_present) {
      stop(
        "The directory ", versions_path, " already holds versions; to link ",
        "this repository to existing versions, use version_relink()"
      )
    }
    dir.create(versions_path, recursive = TRUE, showWarnings = FALSE)
    # create a link from the repository to the resources path
    # need to create versions directory in our repository
    dir.create(path_resrepo("versions"), recursive = TRUE)
    data_dir_link(
      link_dir = "/versions",
      target_dir = versions_path
    )
  }
  dir.create(path_resrepo("versions/starting"), recursive = TRUE)
  dir.create(path_resrepo("versions/initial"), recursive = TRUE)


  # ignore the versions directory at the root of the repository ("/versions";
  # a plain "versions" would ignore any file or directory called versions)
  data_dir_ignore("/versions")
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
  if (!isTRUE(identical(
    list.files(path_resrepo("data/raw"), recursive = TRUE),
    list.files(path_resrepo("versions/starting/raw"),
      recursive = TRUE
    )
  ))) {
    stop(
      "The content of the old and new raw data directories \n",
      "are not the same!"
    )
  }
  if (!isTRUE(identical(
    list.files(path_resrepo("data/intermediate"), recursive = TRUE),
    list.files(path_resrepo("versions/initial/intermediate"),
      recursive = TRUE
    )
  ))) {
    stop(
      "The content of the old and new intermediate data directories \n",
      "are not the same!"
    )
  }
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
    description = "the initial version intermediate data",
    stringsAsFactors = FALSE
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
    sep = "\n", useBytes = FALSE
  )
  writeLines("initial",
    con = path_resrepo("data/version_meta/intermediate_in_use.meta"),
    sep = "\n", useBytes = FALSE
  )

  # add the meta files to git
  git2r::add(path = path_resrepo("data/version_meta"))
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



#' Check that resources_path exists and is outside the repository
#'
#' The data in `resources_path` must not be inside the repository: its root
#' would mix the data with the repository's own directories, and other
#' directories would not be ignored by git. Both the path as given and the
#' path with links resolved are checked.
#'
#' @param resources_path the path given by the user
#' @returns TRUE, or an error
#' @keywords internal
#' @noRd

check_resources_path <- function(resources_path) {
  if (!dir.exists(resources_path)) {
    stop("The path ", resources_path, " does not exist!")
  }
  # the path as given and with links resolved, for the repository and for
  # resources_path
  repo_root <- find_git_root()
  repo_paths <- unique(c(
    fs::path_norm(fs::path_abs(repo_root)),
    fs::path(normalizePath(repo_root, winslash = "/"))
  ))
  resources_paths <- unique(c(
    fs::path_norm(fs::path_abs(resources_path)),
    fs::path(normalizePath(resources_path, winslash = "/"))
  ))
  # refuse the root of the repository, and any directory inside it
  for (res_path in resources_paths) {
    inside_repo <- any(res_path == repo_paths) ||
      any(fs::path_has_parent(res_path, repo_paths))
    if (inside_repo) {
      stop(
        "resources_path cannot be the root directory of the repository, ",
        "or a directory inside it"
      )
    }
  }
  TRUE
}

#' The versions directory of a resources_path
#'
#' `resources_path` is the directory that holds `versions`; a directory
#' called `versions` is taken to be the versions directory itself.
#'
#' @param resources_path the path given by the user
#' @returns the path of the versions directory
#' @keywords internal
#' @noRd

resources_versions_path <- function(resources_path) {
  if (basename(normalizePath(resources_path, winslash = "/")) == "versions") {
    resources_path
  } else {
    file.path(resources_path, "versions")
  }
}

#' Install the git hooks that keep the data links up to date
#'
#' Copies resrepo's `post-checkout` and `post-merge` hooks to the directory
#' where git looks for hooks (found with `git rev-parse --git-path hooks`, so
#' that worktrees, submodules and `core.hooksPath` work). A different hook
#' already there (e.g. from git-lfs) is kept as `<hook>.local`, which
#' resrepo's hook runs first.
#'
#' @returns NULL, invisibly
#' @keywords internal
#' @noRd

add_git_hooks <- function() {
  hooks_dir <- git_hooks_dir()
  dir.create(hooks_dir, recursive = TRUE, showWarnings = FALSE)
  for (hook in c("post-checkout", "post-merge")) {
    hook_path <- file.path(hooks_dir, hook)
    # keep a hook installed by another tool, which resrepo's hook will run
    if (file.exists(hook_path) && !is_resrepo_hook(hook_path)) {
      local_path <- paste0(hook_path, ".local")
      if (!file.exists(local_path)) {
        file.rename(hook_path, local_path)
        message(
          "The existing ", hook, " hook was kept as ", basename(local_path),
          ", which resrepo's ", hook, " hook runs first"
        )
      } else {
        # a .local hook is there already: back this one up, without running
        # it, rather than lose it
        backup_path <- paste0(
          hook_path, ".backup-", format(Sys.time(), "%Y%m%d%H%M%S")
        )
        file.rename(hook_path, backup_path)
        warning(
          "The existing ", hook, " hook was moved to ",
          basename(backup_path), " and will not be run, as ",
          basename(local_path), " exists already",
          call. = FALSE
        )
      }
    }
    # copy resrepo's hook and make it executable
    file.copy(
      system.file("githooks", hook, package = "resrepo"),
      hook_path,
      overwrite = TRUE
    )
    fs::file_chmod(hook_path, mode = "755")
  }
  invisible(NULL)
}

#' The directory where git looks for hooks
#'
#' Asks git (`git rev-parse --git-path hooks`), which gives the hooks of the
#' main repository for a worktree, those of the module for a submodule, and
#' honours `core.hooksPath`. Without git on the command line (which the hooks
#' need anyway), falls back to `.git/hooks`.
#'
#' @returns the path of the hooks directory
#' @keywords internal
#' @noRd

git_hooks_dir <- function() {
  repo_root <- normalizePath(find_git_root(), winslash = "/")
  hooks_dir <- tryCatch(
    suppressWarnings(system2(
      "git", c("-C", shQuote(repo_root), "rev-parse", "--git-path", "hooks"),
      stdout = TRUE, stderr = FALSE
    )),
    error = function(e) character(0)
  )
  if (length(hooks_dir) == 1 && is.null(attr(hooks_dir, "status")) &&
    nzchar(hooks_dir)) { # nolint
    # a relative path is relative to the root of the repository
    return(as.character(fs::path_abs(hooks_dir, start = repo_root)))
  }
  file.path(repo_root, ".git", "hooks")
}

#' Is this hook resrepo's?
#'
#' @param hook_path the path of a hook
#' @returns TRUE if the hook is resrepo's (any version)
#' @keywords internal
#' @noRd

is_resrepo_hook <- function(hook_path) {
  any(grepl(
    "version_meta/raw_in_use.meta",
    readLines(hook_path, warn = FALSE),
    fixed = TRUE
  ))
}
