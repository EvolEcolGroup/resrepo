# Knit R Markdown file to results folder

This function is used in the YAML of an R Markdown file so that when it
is knitted, the output file is sent to the `~/results` directory rather
than the directory in which the `.Rmd` file is located. The output file
can be `.pdf`, `.html`, `.md` etc.

## Usage

``` r
knit_to_results(input_file, encoding, envir = parent.frame(), rename_md = TRUE)
```

## Arguments

- input_file:

  The path to the R Markdown file to be rendered (relative to the
  working directory, or absolute).

- encoding:

  Ignored. The encoding is always assumed to be UTF-8.

- envir:

  The environment in which the code chunks are to be evaluated during
  knitting. If new.env() is used to guarantee an empty new environment,
  note that save.image() will not, by default save, save the objects
  created in the Rmd.

- rename_md:

  Logical. If TRUE, the generated .md file will be renamed to README.md
  to be display on GitHub.

## Details

NB. This function does NOT cause any objects that are written to file in
your `.Rmd` code to be written to the new results directory by default.
To ensure all objects are written to the correct directories, specify an
`output_dir` directly in the code.

The output goes to `results/<name>/`, where `<name>` is the name of the
`.Rmd` file without its extension. If the `.Rmd` file is in a
subdirectory of `code/`, that subdirectory is kept: the output of
`code/analysis/test.Rmd` goes to `results/analysis/test/`. Files
directly in `code/`, or outside it, go to `results/<name>/`. The
repository is the one that holds the `.Rmd` file, so the result does not
depend on the working directory, nor on whether the path is relative or
absolute.
