#' Initialise a resrepo
#'
#' Initialise a resrepo, creating all the necessary files and directories.
#'
#' In a repository that already has files, nothing is overwritten: the
#' files of the template that exist already (e.g. `README.md`) are kept (and
#' listed in a message), and the rules of the template's `.gitignore` that
#' are missing are appended to the existing `.gitignore`. Only the files
#' that `init_resrepo()` created or changed are committed, so that other
#' files (data, secrets, work in progress) are left as they were.
#'
#' @param path optional path for the a resrepo; by default, we use the current
#' working directory
#' @returns TRUE if all the files of the template were created or kept
#'
#' @export

init_resrepo <- function(path = ".") {
  git_root <- find_git_root()
  # the commit must hold only what init_resrepo() creates: stop if other
  # changes are staged already
  if (length(git2r::status(untracked = FALSE)$staged) > 0) {
    stop(
      "There are staged changes in this repository; please commit or ",
      "unstage them before initialising the resrepo"
    )
  }
  template_dir <- system.file("template", package = "resrepo")
  # the files of the template, and where they go in the repository (the
  # template holds "gitignore", which becomes ".gitignore")
  template_files <- list.files(template_dir, recursive = TRUE, all.files = TRUE)
  repo_files <- ifelse(template_files == "gitignore", ".gitignore",
    template_files
  )
  # the files created or changed (to commit), and those kept as they were
  changed_files <- character(0)
  kept_files <- character(0)
  copy_results <- logical(0)
  for (i in seq_along(template_files)) {
    template_file <- file.path(template_dir, template_files[i])
    repo_file <- file.path(git_root, repo_files[i])
    if (repo_files[i] == ".gitignore" && file.exists(repo_file)) {
      # add the rules of the template that are missing from the existing
      # .gitignore (blank lines and comments are not rules)
      template_lines <- readLines(template_file)
      existing_lines <- readLines(repo_file, warn = FALSE)
      is_rule <- nzchar(trimws(template_lines)) &
        !startsWith(trimws(template_lines), "#")
      missing_rules <- template_lines[is_rule &
        !template_lines %in% existing_lines] # nolint
      if (length(missing_rules) > 0) {
        writeLines(
          c(existing_lines, "", "## added by resrepo", missing_rules),
          repo_file
        )
        changed_files <- c(changed_files, repo_files[i])
      }
      copy_results <- c(copy_results, TRUE)
    } else if (file.exists(repo_file)) {
      # keep the existing file
      kept_files <- c(kept_files, repo_files[i])
      copy_results <- c(copy_results, TRUE)
    } else {
      # copy the file of the template
      dir.create(dirname(repo_file), recursive = TRUE, showWarnings = FALSE)
      copy_results <- c(copy_results, file.copy(template_file, repo_file))
      changed_files <- c(changed_files, repo_files[i])
    }
  }
  if (length(kept_files) > 0) {
    message(
      "These files exist already, and were kept: ",
      paste(kept_files, collapse = ", ")
    )
  }
  # create hidden file with resrepo version
  # TODO add a line saying not to delete this file
  writeLines(
    text = as.character(utils::packageVersion("resrepo")),
    con = path_resrepo(".resrepo_version")
  )
  changed_files <- c(changed_files, ".resrepo_version")
  dir.create(path_resrepo("/data/raw/original"), showWarnings = FALSE)
  if (all(copy_results)) {
    # commit initial repository, with only the files created or changed
    # (without any commits version_setup will give an error)
    git2r::add(path = path_resrepo(changed_files))
    git2r::commit(message = "Initialise resrepo")
    return(TRUE)
  } else {
    warning("something went wrong; not all files were included in the template")
    return(FALSE)
  }
}
