# this file tests where knit_to_results() puts its output
test_that("knit_to_results keeps the subdirectory of code/", {
  skip_if_not(rmarkdown::pandoc_available())
  ############
  # set up a git repository inside a folder called "code", so that "code" also
  # appears higher up in the path than the code/ directory of the repository
  example_dir <- file.path(tempdir(), "code", "resrepo_knit")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  dir.create(file.path(example_dir, "code", "analysis", "sub"),
    recursive = TRUE, showWarnings = FALSE
  )
  git2r::init(example_dir, branch = "main")
  # write the same minimal Rmd at three depths within code/
  rmd_lines <- c("---", "title: Test", "output: html_document", "---", "Hi.")
  writeLines(rmd_lines, file.path(example_dir, "code", "top.Rmd"))
  writeLines(rmd_lines, file.path(example_dir, "code", "analysis", "mid.Rmd"))
  writeLines(
    rmd_lines,
    file.path(example_dir, "code", "analysis", "sub", "deep.Rmd")
  )
  # a file whose name ends with the name of an output (it used to be moved
  # to results/top/ and renamed README.md when knitting top.Rmd)
  writeLines("My notes", file.path(example_dir, "code", "notes_top.md"))
  ############
  # a relative path starting with "code/" (it used to lose analysis/)
  withr::with_dir(example_dir, {
    suppressMessages(capture.output(
      knit_to_results("code/analysis/mid.Rmd", encoding = "UTF-8")
    ))
  })
  expect_true(file.exists(
    file.path(example_dir, "results", "analysis", "mid", "mid.html")
  ))
  # an absolute path, with the working directory outside the repository
  # (it used to fail, as the repository was searched from the working dir)
  withr::with_dir(tempdir(), {
    suppressMessages(capture.output(
      knit_to_results(file.path(example_dir, "code", "top.Rmd"),
        encoding = "UTF-8"
      )
    ))
  })
  expect_true(file.exists(
    file.path(example_dir, "results", "top", "top.html")
  ))
  # a bare file name, from the directory that holds it
  withr::with_dir(file.path(example_dir, "code", "analysis", "sub"), {
    suppressMessages(capture.output(
      knit_to_results("deep.Rmd", encoding = "UTF-8")
    ))
  })
  expect_true(file.exists(
    file.path(example_dir, "results", "analysis", "sub", "deep", "deep.html")
  ))
  # nothing went anywhere else in results/, and nothing is left in code/
  expect_setequal(
    list.files(file.path(example_dir, "results"), recursive = TRUE),
    c("analysis/mid/mid.html", "top/top.html", "analysis/sub/deep/deep.html")
  )
  expect_false(any(grepl(
    "\\.html$", list.files(file.path(example_dir, "code"), recursive = TRUE)
  )))
  # the other files in code/ stay where they are
  expect_true(file.exists(file.path(example_dir, "code", "notes_top.md")))
  # clean up
  fs::dir_delete(file.path(tempdir(), "code"))
})
