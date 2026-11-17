# tests/testthat/test-cores.R
library(testthat)

test_that("the tests run with at most 2 cores", {
  skip_on_cran()
  ## tests/run-tests.R sets the limit; other harnesses (e.g. upstream's tests.yml) do not
  skip_if(Sys.getenv("OMP_THREAD_LIMIT") == "", "not run by tests/run-tests.R")
  expect_identical(Sys.getenv("OMP_THREAD_LIMIT"), "2")
  expect_lte(data.table::getDTthreads(), 2L)
})

test_that("run-tests.R runs itself again only once when an Renviron file sets OMP_THREAD_LIMIT", {
  skip_on_cran()
  skip_if_not_installed("processx")
  ## tests/run-tests.R runs itself again in a new R process that has the thread limits. An Renviron
  ## file R reads at start-up can set the limit again; the new process must then set the limits
  ## back and run the tests, not run itself again without end.
  root <- withr::local_tempdir()
  dir.create(file.path(root, "tests", "testthat"), recursive = TRUE)
  file.copy(test_path("..", "run-tests.R"), file.path(root, "tests"))
  writeLines(
    c(
      'test_that("the limits are set back", {',
      '  expect_identical(Sys.getenv("OMP_THREAD_LIMIT"), "2")',
      '})'
    ),
    file.path(root, "tests", "testthat", "test-limits.R")
  )
  renviron <- file.path(root, "Renviron")
  writeLines("OMP_THREAD_LIMIT=3", renviron)

  env <- unclass(Sys.getenv())
  env <- env[!names(env) %in% c("RUN_TESTS_RERUN", "TEST_CORES")]
  env[["R_ENVIRON_USER"]] <- renviron
  env[["R_LIBS"]] <- paste(.libPaths(), collapse = .Platform$path.sep)
  res <- processx::run(
    file.path(R.home("bin"), "Rscript"), file.path("tests", "run-tests.R"),
    wd = root, env = env, timeout = 60, cleanup_tree = TRUE, error_on_status = FALSE
  )
  expect_false(res$timeout)
  expect_identical(res$status, 0L)
})
