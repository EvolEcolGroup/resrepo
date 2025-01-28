#' Knit RMarkdown file to results folder
#'
#' This function is used in the YAML of an RMarkdown file so that when it is 
#' knitted, the output file is sent to the \code{~/results} directory rather than 
#' the directory in which the \code{.Rmd} file is located.
#' The output file can be \code{.pdf}, \code{.html}, \code{.md} etc.
#' 
#' NB. This function does NOT cause any objects that are written to file in
#' your \code{.Rmd} code to be written to the new results directory by default. 
#' To ensure all objects are written to the correct directories, specify an
#' \code{output_dir} directly in the code.
#'
#' @param inputFile The name of the R Markdown file to be rendered.
#' @param encoding Ignored. The encoding is always assumed to be UTF-8.
#' @param envir The environment in which the code chunks are to be evaluated 
#' during knitting. If new.env() is used to guarantee an empty new environment,
#' note that save.image() will not, by default save, save the objects created
#' in the Rmd.
#'
#' @export

knit_to_results <- function(inputFile, encoding, envir=parent.frame()) {
  ## check that the last 4 letters of inputFile are '.Rmd'
  if (tolower(substr(base::basename(inputFile), (nchar(base::basename(inputFile)) - 3), nchar(base::basename(inputFile)))) != ".rmd") {
    stop("Attempting to use knit_to_results on a file that is not a .Rmd or .rmd file.")
  }
  
  ## get the filename from inputFile
  input_file_no_ext <- sub("([^.]+)\\.[[:alnum:]]+$", "\\1", base::basename(inputFile)) # code from file_path_sans_ext in the {tools} package.

  ## run the rmarkdown render function
  rmarkdown::render(
    input = inputFile,
    envir = envir,
    output_file = input_file_no_ext  # file name stays the same, folder stays the same
  )
  
  ## Now we need to move the output files to the /results/fname folder
  
  ## define the current and new directories as RELATIVE paths from CURRENT working dir
  cur_dir <- file.path(dirname(inputFile))
  ## check if we are in a subdirectory of code
  if (length(strsplit(cur_dir,"/code/")[[1]])>1){
    code_sub_dir <- strsplit(cur_dir,"/code/")[[1]][2]
  } else {
    code_sub_dir <- ""
  }
  
  new_dir <- file.path(path_relative(path_resrepo("results")),code_sub_dir, input_file_no_ext)  # put into a new folder under results
  ## create the new results folder if it doesn't already exist
  if (! dir.exists(new_dir)) {
    base::dir.create(new_dir, recursive = TRUE)
  }
  
  ## move the output file AND the associated folder of images over to the output directory
  
  ## FILES TO MOVE: fname.md or fname.pdf or fname.html etc
  # inputFile
  cur_file_regex <- paste0(input_file_no_ext, "(\\.html|\\.pdf|\\.md|\\.docx)$") ## create a regexp to find the output file
  # cur_file_regex
  
  # list.files(cur_dir)
  cur_files <- file.path(cur_dir, list.files(cur_dir, pattern = cur_file_regex)) # current filepaths
  new_files <- file.path(new_dir, list.files(cur_dir, pattern = cur_file_regex)) # where they should go to
  # base::file.copy(cur_files, new_files)  # copies files
  base::file.rename(cur_files, new_files)  # MOVES files
  
  ## FOLDER TO MOVE: fname_files
  cur_folder_regex <- paste0(input_file_no_ext, "_files$")
  # cur_folder_regex
  cur_folder <- file.path(cur_dir, list.files(cur_dir, pattern = cur_folder_regex)) # folder to move
  if ( length(cur_folder) != 0 ) {  # if no match, cur_folder is just an empty character vector
    ## can't just rename a folder (in windows) so we'll copy and delete instead
    base::file.copy(cur_folder, new_dir, recursive = TRUE)  # copies files to results
    base::unlink(cur_folder, recursive = TRUE)  # deletes originals
  }
  
  # rename the md file to README for GitHub display 
  md_file <- list.files(new_dir, pattern = paste0(input_file_no_ext, ".md"))
  # check if there is a .md file in the new directory
  if (length(md_file) > 0) {
    file.rename(file.path(new_dir, md_file), file.path(new_dir, "README.md"))
    
 }
}
