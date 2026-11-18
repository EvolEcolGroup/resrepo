# this file tests several functions related to versioning
test_that("versioning", {
  # knits inst/vignette_example/s01_download_penguins.Rmd, whose data come
  # from palmerpenguins (only suggested)
  skip_if_not_installed("palmerpenguins")
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # create the directory for this test
  dir.create(example_dir, showWarnings = FALSE)
  example_repo <- git2r::init(example_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(example_dir))
  ############
  # initialise the repository and add the relevant files
  init_resrepo()
  expect_true(file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  ))
  expect_true(file.copy(
    from = system.file("vignette_example/s01_download_penguins.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s01_download_penguins.Rmd"),
    overwrite = TRUE
  ))
  # silence knitr
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s03_pca.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s03_pca.Rmd"))
    )
  )
  git2r::add(path = ".")
  suppressMessages(
    capture.output(
      git2r::commit(message = "Save plot", all = TRUE)
    )
  )
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # set up versioning
  expect_true(version_setup(quiet = TRUE))
  # test that the link to data raw is working correctly
  expect_true(setequal(
    list.files(path_resrepo("/data/raw")),
    c("original", "README.md", "s01_download_penguins")
  ))
  # check that we are still in main with nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all element of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  #########
  # fail to add another version if we have changes to commit
  write.csv("blah", path_resrepo("/code/random_code.R"))
  expect_error(
    version_add(
      intermediate_new_version = "new_filtering",
      intermediate_description = "Filtering out some data",
      quiet = TRUE
    ),
    "You have uncommitted changes;"
  )
  file.remove(path_resrepo("/code/random_code.R"))

  ############
  # add another version
  expect_true(version_add(
    intermediate_new_version = "new_filtering",
    intermediate_description = "Filtering out some data", quiet = TRUE
  ))
  # check that we are on a new branch and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # copy the new penguin filtering script
  file.copy(
    from = system.file("vignette_example/new_filtering/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  )
  # knit the new script
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("code/s02_merge_clean.Rmd"))
    )
  )
  # commit changes
  suppressMessages(
    capture.output(
      git2r::commit(message = "Remove penguins", all = TRUE)
    )
  )
  # check that allelement of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  # check that we created the correct resources and that the links are correct
  expect_true(dir.exists(path_resrepo("versions/new_filtering/intermediate")))
  expect_false(
    dir.exists(
      path_resrepo("versions/new_filtering/raw")
    )
  )

  # check that the links point to the right places
  write.csv("blah", path_resrepo("/data/intermediate/my_new_file1.csv"))
  expect_true(
    file.exists(
      path_resrepo(
        "/versions/new_filtering/intermediate/my_new_file1.csv"
      )
    )
  )
  # the repo should still have a clean working directory
  expect_true(git_is_clean())
  ##########
  # move back to main and check that we use the correct version (initial)
  # note that we need to use system2 to run git commands as
  # git2r::checkout does not trigger hooks
  # TODO this is noisy, we should suppress the output

  suppressMessages(
    capture.output(
      system2("git", args = c("checkout main"))
    )
  )
  expect_true(git2r::is_head(git2r::branches()$main))
  expect_true(grep("starting", fs::link_path("./data/raw")) == 1)

  cat(fs::link_path("./data/intermediate"))

  expect_true(grep("initial", fs::link_path("./data/intermediate")) == 1)
  # the links made by the git hook are relative, and must still be accepted
  # as correct (they used to give "The link to the raw data is incorrect")
  expect_identical(
    get_versions_in_use(),
    list(raw = "starting", intermediate = "initial")
  )
  # and update_links() leaves correct links alone
  expect_silent(update_links())

  # Check that data/intermediate now points to the unfiltered penguin data
  penguins_initial <- read.csv(path_resrepo(
    "data/intermediate/s02_merge_clean/penguins_na_omit.csv"
  ))
  penguins_new_filtering <- read.csv(
    "versions/new_filtering/intermediate/s02_merge_clean/penguins_na_omit.csv"
  )
  expect_true(nrow(penguins_initial) > nrow(penguins_new_filtering))
  #########
  # merge new_filtering into main
  suppressMessages(
    capture.output(
      git_res <- system2("git", args = c("merge new_filtering"))
    )
  )
  # we are still in main
  expect_true(git2r::is_head(git2r::branches()$main))
  # but the data version is new_filtering as a consequence of the merge
  expect_true(grep("new_filtering", fs::link_path("./data/intermediate")) == 1)
  expect_identical(get_versions_in_use()$intermediate, "new_filtering")
  penguins <- read.csv(path_resrepo(
    "data/intermediate/s02_merge_clean/penguins_na_omit.csv"
  ))
  expect_true(nrow(penguins) == nrow(penguins_new_filtering))
})

# this file tests several functions related to versioning
test_that("versioning with resources_path argument", {
  withr::local_dir(as.character(tempdir()))
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # create the directory for this test
  dir.create(example_dir, showWarnings = FALSE)
  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)

  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(sub_dir))
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # set up versioning
  external_data_storage <- file.path(tempdir(), "external_data_storage")
  # erase everything from the data storage folder
  if (dir.exists(external_data_storage)) {
    fs::dir_delete(external_data_storage)
  }
  # create the folder for data storage
  dir.create(external_data_storage, showWarnings = FALSE)
  expect_true(version_setup(
    resources_path = external_data_storage,
    quiet = TRUE
  ))
  # only the versions directory at the root is ignored (the line used to be
  # "versions", which ignored any directory called versions)
  expect_true("/versions" %in% readLines(path_resrepo(".gitignore")))
  dir.create(path_resrepo("results/versions"))
  write.csv("blah", path_resrepo("results/versions/table.csv"))
  expect_length(git2r::status()$untracked, 1)
  fs::dir_delete(path_resrepo("results/versions"))
  # copy in some data
  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  )
  # test that the link to data raw is working correctly
  expect_true(setequal(
    list.files(path_resrepo("/data/raw")),
    c("original", "README.md")
  ))
  # check that we are still in main with nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all element of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  ############
  # add another version
  expect_true(version_add(
    intermediate_new_version = "new_filtering",
    intermediate_description = "Filtering out some data", quiet = TRUE
  ))
  # check that we are on a new branch and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  # check that allelement of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  # check that we created the correct resources and that the links are correct
  expect_true(dir.exists(path_resrepo("versions/new_filtering/intermediate")))
  expect_true(
    dir.exists(
      path_resrepo("versions/new_filtering/intermediate")
    )
  )

  # check that the links point to the right places
  # raw should still be in the starting version
  write.csv("blah", path_resrepo("/data/raw/original/my_new_file1.csv"))
  expect_true(
    file.exists(
      path_resrepo(
        "/versions/starting/raw/original/my_new_file1.csv"
      )
    )
  )
  # the repo should still have a clean working directory
  expect_true(git_is_clean())

  # wrong arguments are caught before the git branch is created (they used
  # to leave us on a new branch, with a half-made version)
  expect_error(
    version_add(
      intermediate_new_version = "bad_source",
      intermediate_source = "not_a_version",
      intermediate_description = "A wrong source", quiet = TRUE
    ),
    "source version not_a_version does not exist"
  )
  expect_error(
    version_add(
      intermediate_new_version = "no_raw_description",
      raw_new_version = "new_raw",
      intermediate_description = "No description for raw", quiet = TRUE
    ),
    "description for the new raw version"
  )
  # no branch was created, and we are still on new_filtering
  expect_false(any(
    c("bad_source", "no_raw_description") %in% names(git2r::branches())
  ))
  expect_true(git2r::is_head(git2r::branches()$new_filtering))
  expect_true(git_is_clean())

  # an existing version cannot be added again, even on a new branch (it used
  # to be copied inside the existing version, overwriting its meta file)
  expect_error(
    version_add(
      intermediate_new_version = "initial", git_branch = "initial_again",
      intermediate_description = "An existing version", quiet = TRUE
    ),
    "version initial already exists"
  )
  expect_error(
    version_add(
      intermediate_new_version = "new_intermediate",
      raw_new_version = "starting", raw_description = "An existing version",
      intermediate_description = "A new version", quiet = TRUE
    ),
    "version starting already exists"
  )
  expect_false(any(
    c("initial_again", "new_intermediate") %in% names(git2r::branches())
  ))
  # the existing version is left untouched (the copy used to be nested in
  # it, here as versions/initial/new_filtering, and its meta file overwritten)
  expect_identical(dir(path_resrepo("versions/initial")), "intermediate")
  expect_identical(
    utils::read.csv(path_resrepo("data/version_meta/initial.meta"))$description,
    "the initial version intermediate data"
  )

  # the source must hold the data to copy (starting holds only raw data)
  expect_error(
    version_add(
      intermediate_new_version = "from_raw", intermediate_source = "starting",
      intermediate_description = "From a raw version", quiet = TRUE
    ),
    "source version starting has no intermediate data"
  )
  # raw_source is ignored without raw_new_version (it used to be checked for
  # raw data, and an intermediate version was refused)
  expect_true(version_add(
    intermediate_new_version = "ignored_raw_source", raw_source = "initial",
    intermediate_description = "raw_source is ignored", quiet = TRUE
  ))

  # a version can hold both raw and intermediate data; a new intermediate
  # version made from it gets only the intermediate data (the raw data used
  # to be copied too)
  expect_true(version_add(
    intermediate_new_version = "both", raw_new_version = "both",
    intermediate_description = "New intermediate",
    raw_description = "New raw", quiet = TRUE
  ))
  expect_true(dir.exists(path_resrepo("versions/both/raw")))
  # both versions are described in the shared meta file (the raw row used to
  # overwrite the intermediate one)
  both_meta <- utils::read.csv(path_resrepo("data/version_meta/both.meta"))
  expect_identical(both_meta$data, c("intermediate", "raw"))
  expect_identical(both_meta$description, c("New intermediate", "New raw"))
  expect_true(version_add(
    intermediate_new_version = "from_both",
    intermediate_description = "From both", quiet = TRUE
  ))
  expect_true(dir.exists(path_resrepo("versions/from_both/intermediate")))
  expect_false(dir.exists(path_resrepo("versions/from_both/raw")))
})

test_that(paste0(
  "check that you cannot add a new data raw version ",
  "without a new data intermediate version"
), {
  withr::local_dir(as.character(tempdir()))
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # create the directory for this test
  dir.create(example_dir, showWarnings = FALSE)
  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)

  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(sub_dir))
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())

  expect_true(version_setup(quiet = TRUE))

  # Try adding a version of data raw without adding a new version of
  # data intermediate
  expect_error(version_add(
    raw_new_version = "new_raw_version",
    raw_description = "A new version of raw data",
    quiet = TRUE
  ), "You must provide a name for the new intermediate version")
})


test_that("resources_path cannot be set to git root", {
  withr::local_dir(as.character(tempdir()))
  ############
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # create the directory for this test
  dir.create(example_dir, showWarnings = FALSE)
  # create a subdirectory of example_dir
  sub_dir <- file.path(example_dir, "subdir")
  dir.create(sub_dir, showWarnings = FALSE)

  example_repo <- git2r::init(sub_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(sub_dir))
  init_resrepo()
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  ######## Currently, this test does not work, see version_setup ########

  # find git root
  git_root <- find_git_root()
  expect_error(
    version_setup(git_root, quiet = TRUE),
    "resources_path cannot be the root directory of the repository"
  )
  root_full_path <- getwd()
  expect_error(
    version_setup(root_full_path, quiet = TRUE),
    "resources_path cannot be the root directory of the repository"
  )
  # the root is also refused when the working directory is a subdirectory of
  # the repository (it used to be compared with the working directory)
  withr::with_dir(path_resrepo("code"), {
    expect_error(
      version_setup(resources_path = root_full_path, quiet = TRUE),
      "resources_path cannot be the root directory of the repository"
    )
    expect_error(
      version_relink(resources_path = root_full_path, quiet = TRUE),
      "resources_path cannot be the root directory of the repository"
    )
  })
})

test_that("get_resrepo_git_creds reads the origin remote", {
  creds_dir <- file.path(tempdir(), "resrepo_creds")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(creds_dir)) {
    fs::dir_delete(creds_dir)
  }
  dir.create(creds_dir)
  git2r::init(creds_dir, branch = "main")
  # delete the repository at the end (after leaving it)
  withr::defer(fs::dir_delete(creds_dir))
  withr::local_dir(creds_dir)
  # without remotes there is nothing to push to
  expect_identical(get_resrepo_git_creds()$type, "none")
  # with several remotes, only origin is used (it used to fail with "the
  # condition has length > 1")
  git2r::remote_add(name = "origin", url = "git@github.com:user/repo.git")
  git2r::remote_add(name = "upstream", url = "git@github.com:other/repo.git")
  creds <- get_resrepo_git_creds()
  expect_identical(creds$type, "ssh")
  expect_identical(creds$url, "git@github.com:user/repo.git")
  # ssh urls can also use the ssh:// scheme (they used to be unsupported)
  git2r::remote_set_url(name = "origin", url = "ssh://git@github.com/u/r.git")
  expect_identical(get_resrepo_git_creds()$type, "ssh")
  # https: the token is found however gitcreds stores it, for any host (it
  # used to be parsed from the gitcreds cache variable, so a token given on
  # its own, or for a host other than github.com, gave empty credentials)
  git2r::remote_set_url(name = "origin", url = "https://github.com/u/r.git")
  withr::local_envvar(GITHUB_PAT_GITHUB_COM = "ghp_fake_token")
  creds <- get_resrepo_git_creds()
  expect_identical(creds$type, "https")
  expect_identical(creds$github_pat$password, "ghp_fake_token")
  git2r::remote_set_url(name = "origin", url = "https://gitlab.com/u/r.git")
  withr::local_envvar(GITHUB_PAT_GITLAB_COM = "glpat_fake_token")
  expect_identical(
    get_resrepo_git_creds()$github_pat$password, "glpat_fake_token"
  )
})

test_that("clone a versioned repo", {
  directory_penguins <- file.path(tempdir(), "resrepo_penguins")
  if (!dir.exists(directory_penguins)) dir.create(directory_penguins)

  # clone the penguin repository (public)
  git2r::clone("https://github.com/EvolEcolGroup/resrepo_penguins",
    local_path = directory_penguins,
    branch = "test_intermediate_description4",
    progress = FALSE
  )

  withr::local_dir(as.character(directory_penguins))
  expect_true(read.table("data/version_meta/intermediate_in_use.meta") ==
    "test_intermediate_description4") # nolint

  # create new external folder for data
  external_data_storage_new <- file.path(tempdir(), "external_data_storage_new")
  dir.create(external_data_storage_new)

  intermediate_path <- file.path(
    tempdir(),
    "external_data_storage_new/initial/intermediate"
  )
  raw_path <- file.path(tempdir(), "external_data_storage_new/starting/raw")
  dir.create(intermediate_path, recursive = TRUE)
  dir.create(raw_path, recursive = TRUE)

  file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = raw_path,
    overwrite = TRUE
  )

  expect_true(version_relink(
    quiet = TRUE,
    resources_path = external_data_storage_new
  ))

  # If we have cloned from a branch and then set up versioning,
  # can we merge back into
  # main
  write.csv("blah", path_resrepo("/data/intermediate/my_new_file1.csv"))
  expect_true(git_is_clean())

  # merge back into main
  suppressMessages(
    capture.output(
      system2("git", args = c("checkout main"))
    )
  )
  expect_true(git2r::is_head(git2r::branches()$main))
  # check we are back to the initial version
  expect_true(grep("initial", fs::link_path("./data/intermediate")) == 1)
})

test_that("version_relink for a cloned repo", {
  # knits inst/vignette_example/s01_download_penguins.Rmd, whose data come
  # from palmerpenguins (only suggested)
  skip_if_not_installed("palmerpenguins")
  # Steps
  ########
  # 1. Create a repository in a temp dir
  ########
  # start setting up a temp dir for the git repository
  example_dir <- file.path(tempdir(), "resrepo_example")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(example_dir)) {
    fs::dir_delete(example_dir)
  }
  # create the directory for this test
  dir.create(example_dir, showWarnings = FALSE)
  example_repo <- git2r::init(example_dir, branch = "main")
  git2r::config(example_repo,
    user.name = "Test",
    user.email = "test@example.org"
  )
  # set our working directory in the git repository
  withr::local_dir(as.character(example_dir))
  ############
  # initialise the repository and add the relevant files
  init_resrepo()
  expect_true(file.copy(
    from = system.file("vignette_example/tux_measurements.csv",
      package = "resrepo"
    ),
    to = path_resrepo("/data/raw/original/tux_measurements.csv"),
    overwrite = TRUE
  ))
  expect_true(file.copy(
    from = system.file("vignette_example/s01_download_penguins.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s01_download_penguins.Rmd"),
    overwrite = TRUE
  ))
  # silence knitr
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s01_download_penguins.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s02_merge_clean.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s02_merge_clean.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s02_merge_clean.Rmd"))
    )
  )
  expect_true(file.copy(
    from = system.file("vignette_example/s03_pca.Rmd",
      package = "resrepo"
    ),
    to = path_resrepo("/code/s03_pca.Rmd"),
    overwrite = TRUE
  ))
  suppressMessages(
    capture.output(
      knit_to_results(path_resrepo("/code/s03_pca.Rmd"))
    )
  )
  git2r::add(path = ".")
  suppressMessages(
    capture.output(
      git2r::commit(message = "Save plot", all = TRUE)
    )
  )
  # check that we are on main and there is nothing to commit
  expect_true(git2r::is_head(git2r::branches()$main))
  # check that all elements of git status are empty (i.e. we have a
  # cleaned working directory)
  expect_true(git_is_clean())
  ########

  ########
  # 2. Version this repo
  expect_true(version_setup(quiet = TRUE))
  ########

  ########
  # 3. Copy the 'versions' folder containing the data to a new location
  # start setting up a temp dir for the git repository
  versions_loc <- file.path(tempdir(), "versions_location")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(versions_loc)) {
    fs::dir_delete(versions_loc)
  }
  # create the directory for this test
  dir.create(versions_loc, showWarnings = FALSE)
  # copy the resrepo versions folder to the new location
  file.copy(
    from = path_resrepo("versions"),
    to = versions_loc,
    recursive = TRUE
  )

  ########
  # 4. Clone the repository to a new directory
  # create new directory for the clone
  clone_loc <- file.path(tempdir(), "clone_location")
  # wipe the directory in case it has been left behind from previous tests
  if (dir.exists(clone_loc)) {
    fs::dir_delete(clone_loc)
  }
  # create the directory for this test
  dir.create(clone_loc, showWarnings = FALSE)
  # clone the repository
  git2r::clone(
    url = example_dir,
    local_path = clone_loc,
    branch = "main",
    progress = FALSE
  )
  ########

  ########
  # 5. Run version_relink with the new location of the 'versions' folder
  # move to new repo location
  withr::local_dir(as.character(clone_loc))
  expect_true(version_relink(
    quiet = TRUE,
    resources_path = versions_loc
  ))

  # the data copied with versions/ are found through the links (resources_path
  # holds versions/; it used to be taken as the versions themselves, and the
  # links pointed to new, empty directories)
  expect_true(file.exists(
    path_resrepo("/data/raw/original/tux_measurements.csv")
  ))
  # check the links work
  write.csv("blah", path_resrepo("/data/intermediate/my_new_file1.csv"))
  blah <- read.csv(path_resrepo("data/intermediate/my_new_file1.csv"))
  expect_equal(as.character(blah[2]), "blah")
})
