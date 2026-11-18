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
  # a name with a dot (it used to be knitted to "top.v2", with no extension,
  # which stayed in code/)
  writeLines(rmd_lines, file.path(example_dir, "code", "top.v2.Rmd"))
  # a name with a space, which rmarkdown knits as "top-v3"
  writeLines(rmd_lines, file.path(example_dir, "code", "top v3.Rmd"))
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
  withr::with_dir(example_dir, {
    suppressMessages(capture.output(
      knit_to_results("code/top.v2.Rmd", encoding = "UTF-8")
    ))
  })
  expect_true(file.exists(
    file.path(example_dir, "results", "top.v2", "top.v2.html")
  ))
  # from the folder of the Rmd, as the Knit button of RStudio does
  withr::with_dir(file.path(example_dir, "code"), {
    suppressMessages(capture.output(
      knit_to_results("top v3.Rmd", encoding = "UTF-8")
    ))
  })
  expect_true(file.exists(
    file.path(example_dir, "results", "top v3", "top-v3.html")
  ))
  # nothing went anywhere else in results/, and nothing is left in code/
  expect_setequal(
    list.files(file.path(example_dir, "results"), recursive = TRUE),
    c(
      "analysis/mid/mid.html", "top/top.html", "analysis/sub/deep/deep.html",
      "top.v2/top.v2.html", "top v3/top-v3.html"
    )
  )
  expect_setequal(
    list.files(file.path(example_dir, "code"), recursive = TRUE),
    c(
      "top.Rmd", "top.v2.Rmd", "top v3.Rmd", "notes_top.md",
      "analysis/mid.Rmd", "analysis/sub/deep.Rmd"
    )
  )
  expect_false(any(grepl(
    "\\.html$", list.files(file.path(example_dir, "code"), recursive = TRUE)
  )))
  # the other files in code/ stay where they are
  expect_true(file.exists(file.path(example_dir, "code", "notes_top.md")))
  # clean up
  fs::dir_delete(file.path(tempdir(), "code"))
})

test_that("knit_to_results moves the output of any format", {
  skip_if_not(rmarkdown::pandoc_available())
  example_dir <- file.path(tempdir(), "resrepo_formats")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  dir.create(file.path(example_dir, "code"), recursive = TRUE)
  git2r::init(example_dir, branch = "main")
  # an rtf document (only .html, .pdf, .md and .docx used to be moved, so
  # the .rtf stayed in code/)
  writeLines(
    c("---", "title: Test", "output: rtf_document", "---", "Hi."),
    file.path(example_dir, "code", "letter.Rmd")
  )
  # a .tex written by the user, with the same name, is not an output (it
  # used to be moved too)
  user_tex <- file.path(example_dir, "code", "letter.tex")
  writeLines("\\documentclass{article}", user_tex)
  Sys.setFileTime(user_tex, Sys.time() - 3600)
  withr::with_dir(example_dir, {
    suppressMessages(capture.output(
      knit_to_results("code/letter.Rmd", encoding = "UTF-8")
    ))
  })
  expect_true(
    file.exists(file.path(example_dir, "results", "letter", "letter.rtf"))
  )
  expect_setequal(
    list.files(file.path(example_dir, "code")), c("letter.Rmd", "letter.tex")
  )
  fs::dir_delete(example_dir)
})

test_that("the create_rmd() template knits outside RStudio", {
  skip_if_not(rmarkdown::pandoc_available())
  example_dir <- file.path(tempdir(), "resrepo_template")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # the template writes to data/intermediate/plots
  dir.create(file.path(example_dir, "data", "intermediate"), recursive = TRUE)
  dir.create(file.path(example_dir, "code"))
  git2r::init(example_dir, branch = "main")
  # delete the repository at the end (after leaving it)
  withr::defer(fs::dir_delete(example_dir))
  withr::local_dir(example_dir)
  create_rmd("code/s01_template")
  # knit to html, so that LaTeX is not needed (the template knits to pdf); it
  # used to fail with "RStudio not running" when saving the R environment
  suppressMessages(capture.output(rmarkdown::render(
    path_resrepo("code/s01_template.Rmd"),
    output_format = rmarkdown::html_document(),
    output_dir = file.path(example_dir, "results"), quiet = TRUE,
    envir = new.env()
  )))
  # the R environment is saved, named after the Rmd
  expect_true(file.exists(
    path_resrepo("data/intermediate/plots/renv_s01_template.json")
  ))
})
