#' Knit R Markdown file to results folder
#'
#' This function is used in the YAML of an R Markdown file so that when it is
#' knitted, the output file is sent to the \code{~/results} directory rather
#' than the directory in which the \code{.Rmd} file is located. The output file
#' can be \code{.pdf}, \code{.html}, \code{.md} etc.
#'
#' NB. This function does NOT cause any objects that are written to file in your
#' \code{.Rmd} code to be written to the new results directory by default. To
#' ensure all objects are written to the correct directories, specify an
#' \code{output_dir} directly in the code.
#'
#' The output goes to \code{results/<name>/}, where \code{<name>} is the name of
#' the \code{.Rmd} file without its extension. If the \code{.Rmd} file is in a
#' subdirectory of \code{code/}, that subdirectory is kept: the output of
#' \code{code/analysis/test.Rmd} goes to \code{results/analysis/test/}.
#' Files directly in \code{code/}, or outside it, go to \code{results/<name>/}.
#' The output of any format is moved (the file that
#' \code{rmarkdown::render()} returns), together with the \code{.md} and
#' \code{.tex} files kept by \code{keep_md} and \code{keep_tex}, and the
#' folder of figures (\code{<name>_files}).
#' The repository is the one that holds the \code{.Rmd} file, so the result
#' does not depend on the working directory, nor on whether the path is
#' relative or absolute.
#'
#' @param input_file The path to the R Markdown file to be rendered (relative
#'   to the working directory, or absolute).
#' @param encoding Ignored. The encoding is always assumed to be UTF-8.
#' @param envir The environment in which the code chunks are to be evaluated
#'   during knitting. If new.env() is used to guarantee an empty new
#'   environment, note that save.image() will not, by default save, save the
#'   objects created in the Rmd.
#' @param rename_md Logical. If TRUE, the generated .md file will be renamed to
#'   README.md to be display on GitHub.
#'
#' @export

knit_to_results <- function(input_file, encoding, envir = parent.frame(),
                            rename_md = TRUE) {
  ## check that the last 4 letters of inputFile are '.Rmd'
  if (tolower(substr(
    base::basename(input_file),
    (nchar(base::basename(input_file)) - 3),
    nchar(base::basename(input_file))
  )) != ".rmd") {
    stop(
      "Attempting to use knit_to_results on",
      "a file that is not a .Rmd or .rmd file."
    )
  }

  ## use the absolute path of the input file, so that where its output goes
  ## does not depend on how the path was written (e.g. "code/analysis/x.Rmd"
  ## or "./code/analysis/x.Rmd") or on the working directory
  input_file <- normalizePath(input_file, winslash = "/", mustWork = TRUE)
  ## find the root of the repository that holds the input file (which may
  ## not be the repository of the working directory)
  repo_root <- normalizePath(find_git_root(dirname(input_file)),
    winslash = "/", mustWork = TRUE
  )

  ## get the filename from inputFile
  input_file_no_ext <- sub(
    "([^.]+)\\.[[:alnum:]]+$", "\\1",
    base::basename(input_file)
  )
  # code from file_path_sans_ext in the {tools} package.

  ## run the rmarkdown render function (output_file is not given, as
  ## rmarkdown would read the last part of a name with a dot, e.g. ".v2" in
  ## "s01.v2", as its extension, and write a file "s01.v2" with no extension)
  output_path <- rmarkdown::render(
    input = input_file,
    envir = envir
  )
  ## find the outputs where render() put them, under the name it gave them:
  ## it replaces spaces and other shell characters with "-" ("my file.Rmd"
  ## gives "my-file.html"), and may write to the working directory
  out_dir <- dirname(output_path)
  out_name <- tools::file_path_sans_ext(basename(output_path))

  ## Now we need to move the output files to the /results/fname folder

  ## define the current and new directories as absolute paths
  cur_dir <- dirname(input_file)
  ## get the subdirectory of code/ that holds the input file, relative to the
  ## code/ directory of its repository (matching "/code/" in the path instead
  ## missed relative paths starting with "code/", and picked the wrong folder
  ## when "code" also appeared higher up in the path)
  code_sub_dir <- as.character(
    fs::path_rel(cur_dir, file.path(repo_root, "code"))
  )
  ## files directly in code/, or outside code/, go to results/<name>/;
  ## files in a subdirectory of code/ go to results/<subdirectory>/<name>/
  if (code_sub_dir %in% c(".", "..") || startsWith(code_sub_dir, "../")) {
    new_dir <- file.path(repo_root, "results", input_file_no_ext)
  } else {
    new_dir <- file.path(repo_root, "results", code_sub_dir, input_file_no_ext)
  }
  # put into a new folder under results
  ## create the new results folder if it doesn't already exist
  if (!dir.exists(new_dir)) {
    base::dir.create(new_dir, recursive = TRUE)
  }

  ## move the output file AND the associated folder
  # of images over to the output directory

  ## escape the regular expression characters in the file name (e.g. the "."
  ## in "s01.v2"), and anchor the patterns below at the start of the name, so
  ## that only the outputs of this file are matched (not e.g. "notes_test.md"
  ## when knitting "test.Rmd")
  name_regex <- gsub(
    "([.|()\\^{}+$*?\\[\\]\\\\])", "\\\\\\1", out_name,
    perl = TRUE
  )

  ## FILES TO MOVE: the output that render() returned, whatever its format
  ## (.html, .pdf, .docx, but also .pptx, .odt, .rtf, .epub...), and the
  ## files that some formats keep next to it: fname.md (keep_md, or the
  ## main output of github_document, whose .html is a preview), fname.tex
  ## (keep_tex), fname.html, fname.pdf and fname.docx
  cur_file_regex <- paste0(
    "^", name_regex,
    "(\\.html|\\.pdf|\\.md|\\.docx|\\.tex)$"
  )
  output_files <- union(
    basename(output_path),
    list.files(out_dir, pattern = cur_file_regex)
  )
  output_files <- output_files[file.exists(file.path(out_dir, output_files))]
  cur_files <- file.path(out_dir, output_files) # current filepaths
  new_files <- file.path(new_dir, output_files) # where they should go to
  base::file.rename(cur_files, new_files) # MOVES files

  ## FOLDER TO MOVE: fname_files
  cur_folder_regex <- paste0("^", name_regex, "_files$")
  # cur_folder_regex
  cur_folder <- file.path(out_dir, list.files(out_dir,
    # folder to move
    pattern = cur_folder_regex
  ))
  # if no match, cur_folder is just an empty character vector
  if (length(cur_folder) != 0) {
    ## can't just rename a folder (in windows) so we'll copy and delete instead
    base::file.copy(cur_folder, new_dir,
      recursive = TRUE
    ) # copies files to results
    fs::file_delete(cur_folder) # deletes originals
  }

  # rename the md file to README for GitHub display
  if (rename_md == TRUE) {
    md_file <- list.files(new_dir,
      pattern = paste0("^", name_regex, "\\.md$")
    )
    # check if there is a .md file in the new directory
    if (length(md_file) > 0) {
      file.rename(
        file.path(new_dir, md_file),
        file.path(new_dir, "README.md")
      )
    }
  }
}
