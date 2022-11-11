#' Convert a path to relative
#'
#' Given an absolute path, it returns the relative path with respect to a base
#' (by default, the working directory in R)
#'
#' @param path the full path
#' @param base optional, the base with respect to which the relative path is built. It defaults
#' to the current working directory in R.
#'
#' @export

make_path_relative = function(path, base=getwd()) {
  # based on Stackoverflow:
  # https://stackoverflow.com/questions/36726186/function-for-constructing-relative-paths-in-r
  common = sub('^([^|]*)[^|]*(?:\\|\\1[^|]*)$', '^\\1/?', paste0(base, '|', path))
  
  paste0(gsub('[^/]+/?', '../', sub(common, '', base)),
         sub(common, '', path))
}
