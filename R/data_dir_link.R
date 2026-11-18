#' Create a symlink to a data directory in a resrepo
#'
#' Create a symlink to a data directory in a resrepo (more details needed)
#'
#' Links to directories inside the repository (e.g. `data/raw` to
#' `versions/starting/raw`) are relative, like those made by the git hooks,
#' so that they keep working when the repository is moved; links to
#' directories outside it (external storage) are absolute. On Windows, links
#' are junctions, which are always absolute.
#'
#' @param link_dir the link, given as relative to the root
#' of the git repository (e.g. "/data/raw/my_new_dir"). If the directory exists,
#' it must be empty, as it will be deleted and removed.
#' @param target_dir path outside the git repository that we want to link to
#' (i.e. where the data will be really stored)
#'
#' @keywords internal

data_dir_link <- function(link_dir, target_dir) {
  # check that we have a target_dir
  if (!dir.exists(target_dir)) {
    stop("the linked_path ", target_dir, " does not exist!")
  }

  abs_data_path <- path_resrepo(link_dir)
  # if we have a directory with the same path as link_dir, remove it
  # but first make sure that it is empty
  if (dir.exists(abs_data_path)) {
    if (length(list.files(abs_data_path)) != 0) {
      stop(
        "the data_dir ", abs_data_path, " already exists and is not empty!\n",
        "Before creating a link, move all files to the target_dir first."
      )
    } else {
      fs::file_delete(abs_data_path)
    }
  }
  fs::link_create(
    link_target(target_dir, abs_data_path),
    abs_data_path,
    symbolic = TRUE
  )
  return(TRUE)
}

#' The target to write in a link
#'
#' A target inside the repository is given relative to the directory of the
#' link (e.g. `../versions/starting/raw` for `data/raw`), so that the link
#' keeps working when the repository is moved; a target outside the
#' repository, or any target on Windows (where links are junctions, which
#' are always absolute), is given as an absolute path.
#'
#' @param target_dir the directory the link points to
#' @param link_path the path of the link
#' @returns the target to write in the link
#' @keywords internal
#' @noRd

link_target <- function(target_dir, link_path) {
  # Windows junctions are always absolute
  if (.Platform$OS.type == "windows") {
    return(target_dir)
  }
  # compare normalised paths (no "//" or ".."), without resolving links
  repo_root <- fs::path_norm(normalizePath(find_git_root(), winslash = "/"))
  target_norm <- fs::path_norm(fs::path_abs(target_dir))
  # targets outside the repository stay absolute
  if (!fs::path_has_parent(target_norm, repo_root)) {
    return(target_dir)
  }
  # targets inside it are relative to the directory of the link
  as.character(fs::path_rel(
    target_norm,
    start = fs::path_dir(fs::path_norm(fs::path_abs(link_path)))
  ))
}
