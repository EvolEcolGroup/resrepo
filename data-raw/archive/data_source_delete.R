#' Delete data source
#'
#' This function deletes a data source to the data_source_list.csv file. If
#' still present, the directory is removed, but only if it is empty.
#'
#' @param dir directory of the new entry. It should be given relative to the
#'   root of the git repository. If the directory does not exist, it will be
#'   created.
#' @param git_path option string giving the path for the root of the repository
#'   (NOT the data directory). If left NULL, then the current working directory
#'   is used.
#' @returns TRUE if successful
#' @export


data_source_delete <- function(dir = NULL, git_path = NULL) {
  if (is.null(dir)) {
    stop("You need to specify a directory.")
  }
  is_data_dir(dir)

  if (is.null(git_path)) {
    git_path <- find_git_root()
  }

  if (!file.exists(file.path(git_path, "/data/data_source_list.csv"))) {
    stop(
      "data_sources_list.csv can not be found;\n",
      "are you in the root directory of your repository?"
    )
  }

  original_sources <- utils::read.csv(path_resrepo(
    "/data/data_source_list.csv"
  ))
  if (!dir %in% original_sources$directory) {
    stop(dir, " does not exists in data_source_list.csv")
  }

  # check a directory exists or not; if not, creates it
  abs_data_path <- path_resrepo(dir)
  if (dir.exists(abs_data_path)) {
    if (length(list.files(abs_data_path)) != 0) {
      stop(
        "the data_dir ", abs_data_path, " already exist and is not empty!/n",
        "Before removing the data source, empty the directory."
      )
    } else {
      unlink(abs_data_path, recursive = TRUE)
    }
  }

  original_sources <- original_sources[original_sources$directory != dir, ]
  utils::write.csv(original_sources,
    path_resrepo("./data/data_source_list.csv"),
    row.names = FALSE
  )

  return(TRUE)
}
