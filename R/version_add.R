#' Add a version of the data directories
#'
#' This function will create a new version of the data directories, by copying
#' the current data directories to a new directory in `versions`, and creating
#' links to the new directories. The new version will be called `version_name`.
#'
#' `intermediate_new_version` and `raw_new_version` will be sanitised to remove
#' spaces and other characters that are not allowed in directory names. If the
#' sanitised version is different from the original version, a warning will be
#' issued. The new versions must not exist already in `versions`.
#'
#' The data are copied first; then the git branch is created, the links are
#' updated and the meta files committed; the branch is pushed last. If any
#' step before the push fails, `version_add()` undoes what it did: it
#' returns to the branch it started from, deletes the new branch, and
#' removes the new version directories and meta files. If the push fails,
#' the version is kept, with a warning, and the branch can be pushed later.
#'
#' Each version is described in `data/version_meta/<version>.meta`. If the
#' raw and intermediate versions have the same name, that file has one row
#' for each.
#'
#' @param path Deprecated, and ignored: `version_add()` works on the repository
#'   of the working directory, like the other versioning functions. It will be
#'   removed, so that the name of the new version can come first.
#' @param intermediate_new_version The name of the new version for the
#'   intermediate data
#' @param raw_new_version The name of the new version for the raw data. If NULL,
#'   the raw data will be kept in the currently used version
#' @param intermediate_source The name of the intermediate version to
#'   copy from. If NULL, it will be the current version
#' @param raw_source The name of the raw version to copy from. If NULL,
#'   it will be the current version. Ignored if `raw_new_version` is NULL.
#' @param intermediate_description A description of the new intermediate version
#' @param raw_description A description of the new raw version, required if
#'   `raw_new_version` is given. Ignored if `raw_new_version` is NULL.
#' @param git_branch The name of the git branch to create. If NULL, it will be
#'   the same as `intermediate_new_version`
#' @param push If TRUE (the default), push the new branch to the `origin`
#'   remote, if there is one. If FALSE, the version is created locally only,
#'   and no git credentials are needed.
#' @param quiet If TRUE, suppress messages
#' @returns TRUE if the version was successfully added
#' @export


version_add <- function(path = ".",
                        intermediate_new_version = NULL,
                        raw_new_version = NULL,
                        intermediate_source = NULL,
                        raw_source = NULL,
                        intermediate_description = NULL,
                        raw_description = NULL,
                        git_branch = NULL, push = TRUE, quiet = FALSE) {
  # path was never used; warn, as a positional name lands in it
  if (!missing(path)) {
    warning(
      "The argument 'path' of version_add() is deprecated and ignored: ",
      "version_add() works on the repository of the working directory",
      call. = FALSE
    )
  }
  # check for git credentials (only needed to push)
  if (push) {
    creds <- get_resrepo_git_creds()
  } else {
    creds <- list(type = "none", url = NULL, github_pat = NULL)
  }

  # check version in use
  in_use <- get_versions_in_use()

  sanitise_version <- function(x) {
    x_orig <- x
    x <- fs::path_sanitize(x)
    x <- gsub(" ", "_", x)
    # give a warning if the name was changed
    if (x != x_orig) {
      warning(x_orig, " has been sanitised to ", x)
    }
    return(x)
  }

  if (is.null(intermediate_new_version)) {
    stop("You must provide a name for the new intermediate version")
  }

  if (is.null(intermediate_description)) {
    stop("You must provide a description for the new intermediate version")
  }

  intermediate_new_version <- sanitise_version(intermediate_new_version)

  if (!is.null(raw_new_version)) {
    raw_new_version <- sanitise_version(raw_new_version)
    create_raw <- TRUE
    # a new raw version needs its own description (its meta file could not
    # be written without one)
    if (is.null(raw_description)) {
      stop("You must provide a description for the new raw version")
    }
  } else {
    # if null, use the current raw version
    raw_new_version <- in_use$raw
    create_raw <- FALSE
  }

  # check that we have a clean working directory with git
  if (!git_is_clean()) {
    stop(
      "You have uncommitted changes; please commit or stash them ",
      "before adding a new version"
    )
  }

  # check if the versions directory exists
  if (!dir.exists(path_resrepo("versions"))) {
    stop("versions does not exist; you need to use setup_version() first")
  }
  # if source versions not given, use the current one,
  # else check that they exist and hold the data to copy (before creating the
  # git branch, so that a wrong source leaves the repository untouched)
  # for raw (only used, and so only checked, if we create a new raw version)
  if (is.null(raw_source)) {
    raw_source <- in_use$raw
  } else if (create_raw) {
    if (!version_exists(raw_source)) {
      stop("source version ", raw_source, " does not exist")
    }
    if (!dir.exists(path_resrepo(paste0("versions/", raw_source, "/raw")))) {
      stop("source version ", raw_source, " has no raw data")
    }
  }
  # same for intermediate
  if (is.null(intermediate_source)) {
    intermediate_source <- in_use$intermediate
  } else {
    if (!version_exists(intermediate_source)) {
      stop("source version ", intermediate_source, " does not exist")
    }
    if (!dir.exists(path_resrepo(paste0(
      "versions/", intermediate_source, "/intermediate"
    )))) {
      stop("source version ", intermediate_source, " has no intermediate data")
    }
  }
  # the new versions must not exist yet (copying onto an existing version
  # would nest the source inside it, and overwrite its meta file)
  if (version_exists(intermediate_new_version)) {
    stop("version ", intermediate_new_version, " already exists")
  }
  if (create_raw && version_exists(raw_new_version)) {
    stop("version ", raw_new_version, " already exists")
  }
  # if no name for the git branch was given, use the same name as the version
  if (is.null(git_branch)) {
    git_branch <- intermediate_new_version
  }
  # check that the branch does not exist on git already
  if (git_branch %in% names(git2r::branches())) {
    stop("branch ", git_branch, " already exists")
  }

  # what to undo if anything fails: the branch we start from (to return to),
  # and the version directories and meta files this call creates
  old_branch <- git2r::repository_head()$name
  new_versions <- unique(c(
    intermediate_new_version,
    if (create_raw) raw_new_version
  ))
  new_dirs <- path_resrepo(paste0("versions/", new_versions))
  new_meta_files <- path_resrepo(paste0(
    "data/version_meta/", new_versions, ".meta"
  ))
  branch_created <- FALSE

  tryCatch(
    {
      # 1. copy the data first, before changing anything in git, as the copy
      # is the step most likely to fail (e.g. on a full disk). Copy only the
      # intermediate data of the source version (a version can also hold
      # raw data, which would otherwise be duplicated in the new version)
      fs::dir_copy(
        path_resrepo(paste0(
          "versions/", intermediate_source, "/intermediate"
        )),
        path_resrepo(paste0(
          "versions/", intermediate_new_version, "/intermediate"
        ))
      )
      # if we need to create a new raw version
      if (create_raw) {
        fs::dir_copy(
          path_resrepo(paste0("versions/", raw_source, "/raw")),
          path_resrepo(paste0("versions/", raw_new_version, "/raw"))
        )
      }

      # 2. create the new branch, and switch to it
      git2r::branch_create(name = git_branch)
      branch_created <- TRUE
      git2r::checkout(branch = git_branch)

      # 3. add meta information on the versions
      intermediate_meta <- data.frame(
        data = "intermediate",
        version = intermediate_new_version,
        date_created = Sys.Date(),
        description = intermediate_description,
        stringsAsFactors = FALSE
      )
      utils::write.csv(intermediate_meta,
        file = path_resrepo(paste0(
          "data/version_meta/",
          intermediate_new_version, ".meta"
        )),
        row.names = FALSE
      )
      if (create_raw) {
        version_meta <- data.frame(
          data = "raw",
          version = raw_new_version,
          date_created = Sys.Date(),
          description = raw_description,
          stringsAsFactors = FALSE
        )
        # a raw version with the same name as the new intermediate version
        # shares its meta file: keep both rows (the column data tells them
        # apart)
        if (raw_new_version == intermediate_new_version) {
          version_meta <- rbind(intermediate_meta, version_meta)
        }
        utils::write.csv(version_meta,
          file = path_resrepo(paste0(
            "data/version_meta/",
            raw_new_version, ".meta"
          )),
          row.names = FALSE
        )
      }

      # 4. update the links
      # first delete the old ones
      fs::link_delete(path_resrepo("data/raw"))
      fs::link_delete(path_resrepo("data/intermediate"))
      # then create the new ones
      data_dir_link(
        target_dir = path_resrepo(paste0(
          "versions/", raw_new_version, "/raw"
        )),
        link_dir = "data/raw"
      )
      data_dir_link(
        target_dir = path_resrepo(paste0(
          "versions/", intermediate_new_version, "/intermediate"
        )),
        link_dir = "data/intermediate"
      )
      # write the versions in use to file
      writeLines(raw_new_version,
        con = path_resrepo("data/version_meta/raw_in_use.meta"),
        sep = "\n", useBytes = FALSE
      )
      writeLines(intermediate_new_version,
        con = path_resrepo("data/version_meta/intermediate_in_use.meta"),
        sep = "\n", useBytes = FALSE
      )

      # 5. commit the meta files
      git2r::add(path = path_resrepo("data/version_meta/*"))
      commit_message <- paste("Add version", intermediate_new_version)
      if (create_raw) {
        commit_message <- paste(commit_message, "and", raw_new_version)
      }
      git2r::commit(message = commit_message, all = TRUE)
    },
    error = function(e) {
      # undo what was done, so that the repository is as before the call
      version_add_undo(
        old_branch = old_branch, new_branch = git_branch,
        branch_created = branch_created, new_dirs = new_dirs,
        new_meta_files = new_meta_files
      )
      stop(
        "version_add() failed, and its changes were undone: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )
  if (!quiet) {
    message("version ", intermediate_new_version, " created")
    if (create_raw) {
      message("raw version ", raw_new_version, " created")
    }
  }

  # 6. push the new branch, once, at the end; if that fails, the version is
  # complete locally, and can be pushed later
  if (creds$type != "none") {
    tryCatch(
      git2r::push(
        name = "origin",
        refspec = paste0("refs/heads/", git_branch),
        set_upstream = TRUE,
        credentials = creds$github_pat
      ),
      error = function(e) {
        warning(
          "version ", intermediate_new_version, " was created, but branch ",
          git_branch, " could not be pushed to origin: ",
          conditionMessage(e), "\nPush it later, e.g. with ",
          "'git push -u origin ", git_branch, "'",
          call. = FALSE
        )
      }
    )
  }
  return(TRUE)
}

#' Undo a failed version_add()
#'
#' Returns to the branch `version_add()` started from (discarding the changes
#' it made to the meta files), deletes the branch it created, removes the
#' version directories and meta files it created, and restores the links to
#' the versions in use. Branches already pushed are never deleted on the
#' remote (`version_add()` pushes only at the end, once all else succeeded).
#'
#' @param old_branch the name of the branch `version_add()` started from
#' @param new_branch the name of the branch it created
#' @param branch_created whether the new branch was created
#' @param new_dirs the version directories it created
#' @param new_meta_files the meta files it created
#' @returns NULL, invisibly
#' @keywords internal
#' @noRd

version_add_undo <- function(old_branch, new_branch, branch_created,
                             new_dirs, new_meta_files) {
  if (branch_created) {
    # back to the old branch; force discards the changes to the meta files
    # (the working directory was clean when version_add() started)
    git2r::checkout(branch = old_branch, force = TRUE)
    # and delete the new branch
    git2r::branch_delete(git2r::branches(flags = "local")[[new_branch]])
  }
  # remove the new version directories and meta files
  for (new_dir in new_dirs[dir.exists(new_dirs)]) {
    fs::dir_delete(new_dir)
  }
  unlink(new_meta_files)
  # restore the links to the versions in use on the old branch
  update_links(quiet = TRUE)
  invisible(NULL)
}
