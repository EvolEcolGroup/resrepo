test_that("is_data_dir works correctly", {
  path <- "/data/raw/default"
  expect_true(is_data_dir(path))
  path <- "data/raw/default"
  expect_error(is_data_dir(path), path)
  path <- "/data/blah/default"
  expect_error(is_data_dir(path), path)
})
