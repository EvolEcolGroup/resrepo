# Create a new R Markdown file from the template

Creates and writes to file a new R Markdown (.Rmd) file from the
`resrepo` template. The YAML header contains the `knit_to_results`
function, and the template includes code chunks for setting input and
output directories using resrepo functions.

## Usage

``` r
create_rmd(filename)
```

## Arguments

- filename:

  file path to new Rmd file to be created, excluding file extension. Can
  be in a subfolder, e.g. `"code/s01_process_data"`. This will be passed
  through the
  [`path_resrepo()`](https://evolecolgroup.github.io/resrepo/reference/path_resrepo.md)
  function so should be specified from the top level of the repository.
